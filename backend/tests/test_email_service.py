"""Tests du service email (best-effort, destinataire configurable)."""

from unittest.mock import patch, MagicMock

from app.core import email as email_service


def test_is_email_configured_false_by_default():
    # Sans SMTP_HOST/SMTP_FROM configures -> non configure
    with patch.object(email_service.settings, "SMTP_HOST", None), \
         patch.object(email_service.settings, "SMTP_FROM", None):
        assert email_service.is_email_configured() is False


def test_send_email_noop_when_not_configured():
    """Si SMTP non configure, send_email renvoie False sans lever d'exception."""
    with patch.object(email_service.settings, "SMTP_HOST", None), \
         patch.object(email_service.settings, "SMTP_FROM", None):
        assert email_service.send_email("x@y.com", "Sujet", "<p>hi</p>") is False


def test_notification_email_from_app_settings_priority():
    """La cle app_settings.notification_email est prioritaire sur l'env."""
    fake_db = MagicMock()
    fake_db.fetch_one.return_value = {"key": "notification_email", "value": '"ops@activ.com"'}

    with patch("app.db.supabase_client.get_supabase_client", return_value=fake_db), \
         patch.object(email_service.settings, "NOTIFICATION_EMAIL", "env@fallback.com"):
        assert email_service.get_notification_email() == "ops@activ.com"


def test_notification_email_falls_back_to_env():
    """Si app_settings ne contient rien, on retombe sur l'env."""
    fake_db = MagicMock()
    fake_db.fetch_one.return_value = None

    with patch("app.db.supabase_client.get_supabase_client", return_value=fake_db), \
         patch.object(email_service.settings, "NOTIFICATION_EMAIL", "env@fallback.com"):
        assert email_service.get_notification_email() == "env@fallback.com"


def test_notification_email_none_when_nothing_configured():
    fake_db = MagicMock()
    fake_db.fetch_one.return_value = None
    with patch("app.db.supabase_client.get_supabase_client", return_value=fake_db), \
         patch.object(email_service.settings, "NOTIFICATION_EMAIL", None):
        assert email_service.get_notification_email() is None
