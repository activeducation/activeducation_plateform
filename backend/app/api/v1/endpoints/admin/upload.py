"""Admin image upload endpoints."""

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

    ext = file.filename.split(".")[-1] if file.filename else "jpg"
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

    try:
        db = get_supabase_client()
        db.client.storage.from_(bucket).remove([filename])

        _log_audit(admin["user_id"], "delete", "image", filename, {"bucket": bucket})

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
