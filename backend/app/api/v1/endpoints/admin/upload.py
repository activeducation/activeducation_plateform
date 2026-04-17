"""Admin image upload endpoints."""

import os
import re
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, File, UploadFile, Form, HTTPException
from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.core.exceptions import ValidationError
from app.db.supabase_client import get_supabase_client


logger = get_logger("api.admin.upload")

router = APIRouter()

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
VALID_BUCKETS = {"schools", "careers", "tests", "announcements", "avatars"}

# Magic bytes for allowed image formats
MAGIC_BYTES = {
    b"\xff\xd8\xff": "image/jpeg",
    b"\x89PNG\r\n\x1a\n": "image/png",
    b"RIFF": "image/webp",  # WebP starts with RIFF....WEBP
}


def _validate_magic_bytes(content: bytes) -> str:
    """Validate file magic bytes and return the detected MIME type."""
    for magic, mime in MAGIC_BYTES.items():
        if content.startswith(magic):
            return mime
    raise ValidationError("Le contenu du fichier ne correspond pas a un format image valide.")


def _sanitize_extension(ext: str) -> str:
    """Sanitize file extension: only alphanumeric, max 10 chars."""
    ext = ext.lower().strip()
    if not re.fullmatch(r"[a-z0-9]{1,10}", ext):
        raise ValidationError(f"Extension de fichier invalide: {ext}")
    return ext


@router.post("/{bucket}")
async def upload_image(
    bucket: str,
    file: UploadFile = File(...),
    admin: dict = Depends(get_current_admin),
):
    """Upload une image vers Supabase Storage."""
    if bucket not in VALID_BUCKETS:
        raise ValidationError(f"Bucket invalide. Valides: {', '.join(VALID_BUCKETS)}")

    if file.content_type not in ALLOWED_TYPES:
        raise ValidationError(f"Format invalide. Acceptes: jpg, png, webp")

    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise ValidationError(f"Fichier trop volumineux. Max: 5MB")

    detected_type = _validate_magic_bytes(content)
    if detected_type not in ALLOWED_TYPES:
        raise ValidationError(f"Contenu image non autorise. Detecte: {detected_type}")

    raw_ext = file.filename.rsplit(".", 1)[-1] if file.filename and "." in file.filename else "jpg"
    ext = _sanitize_extension(raw_ext)
    filename = f"{uuid.uuid4()}.{ext}"
    path = f"{bucket}/{filename}"

    try:
        db = get_supabase_client()
        db.client.storage.from_(bucket).upload(
            path=filename,
            file=content,
            file_options={"content-type": file.content_type},
        )

        public_url = db.client.storage.from_(bucket).get_public_url(filename)

        # Log audit
        _log_audit(admin["user_id"], "upload", "image", path, {"bucket": bucket, "filename": filename})

        return {"url": public_url, "path": filename, "bucket": bucket}

    except Exception as e:
        logger.error(f"Upload error: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'upload: {str(e)}")


@router.delete("/{bucket}/{filename}")
async def delete_image(
    bucket: str,
    filename: str,
    admin: dict = Depends(get_current_admin),
):
    """Supprime une image de Supabase Storage."""
    if bucket not in VALID_BUCKETS:
        raise ValidationError(f"Bucket invalide")

    safe_filename = os.path.basename(filename)
    if safe_filename != filename or "/" in filename or "\\" in filename:
        raise ValidationError("Nom de fichier invalide.")

    try:
        db = get_supabase_client()
        db.client.storage.from_(bucket).remove([safe_filename])

        _log_audit(admin["user_id"], "delete", "image", safe_filename, {"bucket": bucket})

        return {"success": True, "message": "Image supprimee"}

    except Exception as e:
        logger.error(f"Delete error: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur lors de la suppression: {str(e)}")


def _log_audit(admin_id, action, entity_type, entity_id, changes):
    """Helper pour loguer les actions admin."""
    try:
        db = get_supabase_client()
        db.insert(table="admin_audit_log", data={
            "admin_id": str(admin_id),
            "action": action,
            "entity_type": entity_type,
            "entity_id": str(entity_id) if entity_id else None,
            "changes": changes,
        })
    except Exception as e:
        logger.warning(f"Audit log failed: {e}")
