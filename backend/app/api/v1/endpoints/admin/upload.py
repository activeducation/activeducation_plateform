"""Admin image upload endpoints."""

import os
import re
import uuid

from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from app.core.logging import get_logger
from app.core.security import get_current_admin
from app.core.exceptions import ValidationError
from app.core import image_upload
from app.db.supabase_client import get_supabase_client


logger = get_logger("api.admin.upload")

router = APIRouter()

# Buckets autorises. La validation des images (types, taille, octets
# magiques) vit dans app.core.image_upload, partagee avec l'upload public des
# photos de candidature mentor : deux definitions de "image valide" finiraient
# par diverger.
VALID_BUCKETS = {"schools", "careers", "tests", "announcements", "avatars", "elearning"}


@router.post("/{bucket}")
async def upload_image(
    bucket: str,
    file: UploadFile = File(...),
    admin: dict = Depends(get_current_admin),
):
    """Upload une image vers Supabase Storage."""
    if bucket not in VALID_BUCKETS:
        raise ValidationError(f"Bucket invalide. Valides: {', '.join(VALID_BUCKETS)}")

    content, ext = await image_upload.read_and_validate(file)

    try:
        stored = image_upload.store(bucket, content, ext, file.content_type)
        _log_audit(
            admin["user_id"], "upload", "image", f"{bucket}/{stored['path']}",
            {"bucket": bucket, "filename": stored["path"]},
        )
        return stored

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
        db = get_supabase_client()
        db.client.storage.from_(bucket).remove([safe_filename])

        _log_audit(admin["user_id"], "delete", "image", safe_filename, {"bucket": bucket})

        return {"success": True, "message": "Image supprimee"}

    except Exception as e:
        logger.error(f"Delete error: {e}", exc_info=True)
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
    except Exception:
        logger.error("Audit log failed, blocking action", exc_info=True)
        raise
