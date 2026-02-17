"""
Schemas Pydantic pour l'authentification.

Definit les structures de donnees pour:
- Login/Register
- Tokens
- Password reset
- User profile
"""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator


# =============================================================================
# LOGIN / REGISTER
# =============================================================================


class LoginRequest(BaseModel):
    """Requete de connexion."""

    email: EmailStr
    password: str = Field(..., min_length=1)


class RegisterRequest(BaseModel):
    """Requete d'inscription."""

    email: EmailStr
    password: str = Field(..., min_length=8)
    first_name: str = Field(..., min_length=2, max_length=50)
    last_name: str = Field(..., min_length=2, max_length=50)
    phone_number: Optional[str] = Field(None, max_length=20)

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Le mot de passe doit contenir au moins 8 caracteres")
        if not any(c.isupper() for c in v):
            raise ValueError("Le mot de passe doit contenir au moins une majuscule")
        if not any(c.islower() for c in v):
            raise ValueError("Le mot de passe doit contenir au moins une minuscule")
        if not any(c.isdigit() for c in v):
            raise ValueError("Le mot de passe doit contenir au moins un chiffre")
        return v

    @field_validator("first_name", "last_name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        if not v.replace(" ", "").replace("-", "").isalpha():
            raise ValueError("Le nom ne doit contenir que des lettres")
        return v.strip().title()


# =============================================================================
# TOKENS
# =============================================================================


class TokenResponse(BaseModel):
    """Reponse contenant les tokens."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = Field(..., description="Secondes avant expiration")


class RefreshTokenRequest(BaseModel):
    """Requete de rafraichissement de token."""

    refresh_token: str


# =============================================================================
# PASSWORD RESET
# =============================================================================


class ForgotPasswordRequest(BaseModel):
    """Requete de reinitialisation de mot de passe."""

    email: EmailStr


class ResetPasswordRequest(BaseModel):
    """Requete pour definir un nouveau mot de passe."""

    token: str
    new_password: str = Field(..., min_length=8)

    @field_validator("new_password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Le mot de passe doit contenir au moins 8 caracteres")
        if not any(c.isupper() for c in v):
            raise ValueError("Le mot de passe doit contenir au moins une majuscule")
        if not any(c.islower() for c in v):
            raise ValueError("Le mot de passe doit contenir au moins une minuscule")
        if not any(c.isdigit() for c in v):
            raise ValueError("Le mot de passe doit contenir au moins un chiffre")
        return v


class ChangePasswordRequest(BaseModel):
    """Requete de changement de mot de passe (utilisateur connecte)."""

    current_password: str
    new_password: str = Field(..., min_length=8)

    @field_validator("new_password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Le mot de passe doit contenir au moins 8 caracteres")
        return v


# =============================================================================
# USER
# =============================================================================


class UserBase(BaseModel):
    """Informations de base d'un utilisateur."""

    email: EmailStr
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone_number: Optional[str] = None


class UserCreate(UserBase):
    """Donnees pour creer un utilisateur."""

    password: str


class UserResponse(UserBase):
    """Reponse contenant les infos utilisateur."""

    id: UUID
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

    @property
    def full_name(self) -> str:
        if self.first_name and self.last_name:
            return f"{self.first_name} {self.last_name}"
        return self.display_name or self.email.split("@")[0]


class UserProfile(UserResponse):
    """Profil utilisateur complet."""

    date_of_birth: Optional[datetime] = None
    school_name: Optional[str] = None
    class_level: Optional[str] = None
    preferred_language: str = "fr"
    updated_at: Optional[datetime] = None


class UpdateProfileRequest(BaseModel):
    """Requete de mise a jour du profil."""

    first_name: Optional[str] = Field(None, min_length=2, max_length=50)
    last_name: Optional[str] = Field(None, min_length=2, max_length=50)
    display_name: Optional[str] = Field(None, max_length=100)
    phone_number: Optional[str] = Field(None, max_length=20)
    date_of_birth: Optional[datetime] = None
    school_name: Optional[str] = Field(None, max_length=200)
    class_level: Optional[str] = Field(None, max_length=50)
    preferred_language: Optional[str] = Field(None, pattern="^(fr|en)$")


# =============================================================================
# AUTH RESPONSES
# =============================================================================


class AuthResponse(BaseModel):
    """Reponse d'authentification complete."""

    user: UserResponse
    tokens: TokenResponse


class MessageResponse(BaseModel):
    """Reponse simple avec message."""

    success: bool
    message: str


class LogoutResponse(MessageResponse):
    """Reponse de deconnexion."""

    pass
