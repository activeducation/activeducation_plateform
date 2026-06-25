"""Service d'envoi d'email — best-effort, sans dependance externe (smtplib).

Conception :
- **Best-effort** : si SMTP n'est pas configure ou si l'envoi echoue, on log et
  on continue. L'email ne doit JAMAIS casser une requete metier (candidature,
  etc.).
- **Destinataire configurable a chaud** : l'adresse des notifications internes
  est lue depuis la cle `app_settings.notification_email` (modifiable depuis le
  back-office, sans redeploiement), avec repli sur `settings.NOTIFICATION_EMAIL`.
  Pas d'adresse codee en dur dans la logique.
- **Non bloquant** : `send_email_async` execute l'envoi SMTP (bloquant) dans un
  thread via `asyncio.to_thread`.
"""

from __future__ import annotations

import asyncio
import json
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Optional

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger("core.email")


def is_email_configured() -> bool:
    """Vrai si un serveur SMTP est configure."""
    return bool(settings.SMTP_HOST and settings.SMTP_FROM)


def get_notification_email() -> Optional[str]:
    """Adresse de reception des notifications internes.

    Priorite : app_settings.notification_email (chaud) > NOTIFICATION_EMAIL (env).
    Retourne None si rien n'est configure.
    """
    # 1. app_settings (configurable a chaud depuis le back-office)
    try:
        from app.db.supabase_client import get_supabase_client

        db = get_supabase_client()
        row = db.fetch_one(table="app_settings", id_column="key", id_value="notification_email")
        if row and row.get("value"):
            raw = row["value"]
            # Les valeurs app_settings sont stockees en JSON ("\"x@y.com\"").
            try:
                parsed = json.loads(raw)
                if isinstance(parsed, str) and parsed.strip():
                    return parsed.strip()
            except (json.JSONDecodeError, TypeError):
                if isinstance(raw, str) and raw.strip():
                    return raw.strip()
    except Exception as e:
        logger.warning(f"Could not read notification_email from app_settings: {e}")

    # 2. Fallback env
    return settings.NOTIFICATION_EMAIL


def _send_smtp(to_email: str, subject: str, html_body: str, text_body: str) -> None:
    """Envoi SMTP synchrone (appele dans un thread)."""
    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = settings.SMTP_FROM or settings.SMTP_USER or "no-reply@activeducation"
    msg["To"] = to_email
    msg.attach(MIMEText(text_body, "plain", "utf-8"))
    msg.attach(MIMEText(html_body, "html", "utf-8"))

    with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=15) as server:
        if settings.SMTP_USE_TLS:
            server.starttls()
        if settings.SMTP_USER and settings.SMTP_PASSWORD:
            server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
        server.send_message(msg)


def send_email(
    to_email: str,
    subject: str,
    html_body: str,
    text_body: Optional[str] = None,
) -> bool:
    """Envoi synchrone best-effort. Retourne True si envoye, False sinon."""
    if not is_email_configured():
        logger.info(
            "Email non envoye (SMTP non configure) — to=%s subject=%s",
            to_email,
            subject,
        )
        return False
    if not to_email:
        logger.info("Email non envoye (destinataire vide) — subject=%s", subject)
        return False
    try:
        _send_smtp(to_email, subject, html_body, text_body or _strip_html(html_body))
        logger.info("Email envoye a %s — %s", to_email, subject)
        return True
    except Exception as e:
        logger.warning("Echec envoi email a %s (%s): %s", to_email, subject, e)
        return False


async def send_email_async(
    to_email: str,
    subject: str,
    html_body: str,
    text_body: Optional[str] = None,
) -> bool:
    """Version non bloquante (thread)."""
    return await asyncio.to_thread(send_email, to_email, subject, html_body, text_body)


async def notify_internal(subject: str, html_body: str, text_body: Optional[str] = None) -> bool:
    """Envoie une notification a l'adresse interne (notification_email)."""
    to = get_notification_email()
    if not to:
        logger.info("Notification interne ignoree (aucune adresse configuree): %s", subject)
        return False
    return await send_email_async(to, subject, html_body, text_body)


def _strip_html(html: str) -> str:
    """Fallback texte tres simple a partir du HTML."""
    import re

    text = re.sub(r"<[^>]+>", "", html)
    return re.sub(r"\n{3,}", "\n\n", text).strip()
