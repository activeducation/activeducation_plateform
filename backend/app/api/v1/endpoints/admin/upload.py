"""Admin image upload endpoints."""

import os
import re
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from storage3.exceptions import StorageApiError

from app.core.exceptions import ValidationError
from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.db.supabase_client import get_admin_supabase_client

logger = get_logger("api.admin.upload")

router = APIRouter()

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
VALID_BUCKETS = {"schools", "careers", "tests", "announcements", "avatars", "elearning"}

def _ensure_bucket_exists(bucket: str) -> None:
    """Cree le bucket Supabase Storage s'il n'existe pas."""
    try:
        admin = get_admin_supabase_client()
        admin.client.storage.create_bucket(
            bucket,
            options={"public": True},
        )
        logger.info(f"Bucket '{bucket}' cree avec succes.")
    except StorageApiError as e:
        if "already exists" in str(e).lower():
            logger.debug(f"Bucket '{bucket}' existe deja.")
        else:
            logger.warning(
                f"Impossible de creer le bucket '{bucket}': {e}. "
                "L'upload avec la cle anon pourrait echouer si le bucket est manquant."
            )
    except Exception as e:
        logger.warning(
            f"Impossible de creer le bucket '{bucket}' (clavier service_role dispo ?): {e}"
        )


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

    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise ValidationError("Fichier trop volumineux. Max: 5MB")

    detected_type = _validate_magic_bytes(content)
    if file.content_type and file.content_type not in ALLOWED_TYPES:
        raise ValidationError("Format invalide. Acceptes: jpg, png, webp")

    raw_ext = file.filename.rsplit(".", 1)[-1] if file.filename and "." in file.filename else "jpg"
    ext = _sanitize_extension(raw_ext)
    filename = f"{uuid.uuid4()}.{ext}"
    path = f"{bucket}/{filename}"

    try:
        _ensure_bucket_exists(bucket)
        db = get_admin_supabase_client()
        db.client.storage.from_(bucket).upload(
            path=filename,
            file=content,
            file_options={"content-type": file.content_type},
        )

        public_url = db.client.storage.from_(bucket).get_public_url(filename)
        if public_url.endswith("?"):
            public_url = public_url[:-1]

        # Log audit
        _log_audit(
            admin["user_id"], "upload", "image", path, {"bucket": bucket, "filename": filename}
        )

        return {"url": public_url, "path": filename, "bucket": bucket}

    except Exception as e:
        logger.error(f"Upload error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'upload: {str(e)}")


@router.delete("/{bucket}/{filename}")
async def delete_image(
    bucket: str,
    filename: str,
    admin: dict = Depends(get_current_admin),
):
    """Supprime une image de Supabase Storage."""
    if bucket not in VALID_BUCKETS:
        raise ValidationError("Bucket invalide")

    safe_filename = os.path.basename(filename)
    if safe_filename != filename or "/" in filename or "\\" in filename:
        raise ValidationError("Nom de fichier invalide.")

    try:
        db = get_admin_supabase_client()
        db.client.storage.from_(bucket).remove([safe_filename])

        _log_audit(admin["user_id"], "delete", "image", safe_filename, {"bucket": bucket})

        return {"success": True, "message": "Image supprimee"}

    except Exception as e:
        logger.error(f"Delete error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Erreur lors de la suppression: {str(e)}")


def _log_audit(admin_id, action, entity_type, entity_id, changes):
    """Helper pour loguer les actions admin."""
    try:
        db = get_admin_supabase_client()
        db.insert(
            table="admin_audit_log",
            data={
                "admin_id": str(admin_id),
                "action": action,
                "entity_type": entity_type,
                "entity_id": str(entity_id) if entity_id else None,
                "changes": changes,
            },
        )
    except Exception:
        # Audit log failures must never block the admin action: the
        # underlying mutation has already been applied. Failing to
        # record the audit trail is bad, failing the user request is
        # worse. See audit #4 (2026-07-30).
        logger.warning("Audit log failed (action already applied)", exc_info=True)
