"""Validation et envoi d'images vers Supabase Storage.

Extrait de `api/v1/endpoints/admin/upload.py` pour etre partage avec les
endpoints publics (photo de candidature mentor). Dupliquer ces controles
reviendrait a laisser deux definitions de "image valide" diverger : la
validation par octets magiques est ce qui empeche d'envoyer un script deguise
en .jpg.
"""
import re
import uuid

from fastapi import UploadFile

from app.core.exceptions import ValidationError
from app.core.logging import get_logger
from app.db.supabase_client import get_supabase_client

logger = get_logger("core.image_upload")

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 Mo

# Octets de signature des formats acceptes. Le content-type declare par le
# client n'est pas fiable : c'est le contenu reel qui fait foi.
MAGIC_BYTES = {
    b"\xff\xd8\xff": "image/jpeg",
    b"\x89PNG\r\n\x1a\n": "image/png",
    b"RIFF": "image/webp",  # un WebP commence par RIFF....WEBP
}


def validate_magic_bytes(content: bytes) -> str:
    """Deduit le type MIME reel du contenu, ou refuse le fichier."""
    for magic, mime in MAGIC_BYTES.items():
        if content.startswith(magic):
            return mime
    raise ValidationError(
        "Le contenu du fichier ne correspond pas a un format image valide."
    )


def sanitize_extension(ext: str) -> str:
    """N'accepte qu'une extension alphanumerique courte."""
    ext = ext.lower().strip()
    if not re.fullmatch(r"[a-z0-9]{1,10}", ext):
        raise ValidationError(f"Extension de fichier invalide: {ext}")
    return ext


async def read_and_validate(file: UploadFile) -> tuple[bytes, str]:
    """Lit le fichier et verifie type declare, taille et contenu reel.

    Retourne le contenu et l'extension assainie.
    """
    if file.content_type not in ALLOWED_TYPES:
        raise ValidationError("Format invalide. Acceptes: jpg, png, webp")

    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise ValidationError("Fichier trop volumineux. Max: 5MB")

    detected = validate_magic_bytes(content)
    if detected not in ALLOWED_TYPES:
        raise ValidationError(f"Contenu image non autorise. Detecte: {detected}")

    raw_ext = (
        file.filename.rsplit(".", 1)[-1]
        if file.filename and "." in file.filename
        else "jpg"
    )
    return content, sanitize_extension(raw_ext)


def store(bucket: str, content: bytes, ext: str, content_type: str) -> dict:
    """Depose le fichier dans le bucket et retourne son URL publique."""
    filename = f"{uuid.uuid4()}.{ext}"
    db = get_supabase_client()
    db.client.storage.from_(bucket).upload(
        path=filename,
        file=content,
        file_options={"content-type": content_type},
    )
    return {
        "url": db.client.storage.from_(bucket).get_public_url(filename),
        "path": filename,
        "bucket": bucket,
    }
