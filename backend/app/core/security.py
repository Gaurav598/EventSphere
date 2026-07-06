import hashlib
import hmac
import json
from datetime import datetime, timedelta, timezone
from typing import Any

import jwt
from passlib.context import CryptContext
from pwdlib import PasswordHash

from app.core.config import settings
from app.exceptions.handlers import AppException

password_hash = PasswordHash.recommended()
legacy_password_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return password_hash.verify(plain_password, hashed_password)
    except Exception:
        try:
            return legacy_password_context.verify(plain_password, hashed_password)
        except Exception:
            return False


def get_password_hash(password: str) -> str:
    return password_hash.hash(password)


def password_hash_needs_upgrade(hashed_password: str) -> bool:
    return not hashed_password.startswith("$argon2")


def create_access_token(
    subject: str | Any,
    role: str,
    expires_delta: timedelta | None = None,
) -> str:
    now = datetime.now(timezone.utc)
    expire = now + (
        expires_delta
        if expires_delta is not None
        else timedelta(minutes=settings.JWT_EXPIRE_MINUTES)
    )
    payload = {
        "aud": settings.JWT_AUDIENCE,
        "exp": expire,
        "iat": now,
        "iss": settings.JWT_ISSUER,
        "role": role,
        "sub": str(subject),
        "type": "access",
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def decode_access_token(token: str) -> dict[str, Any]:
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM],
            audience=settings.JWT_AUDIENCE,
            issuer=settings.JWT_ISSUER,
            options={"require": ["exp", "iat", "iss", "aud", "sub", "type"]},
        )
        if payload.get("type") != "access":
            raise jwt.InvalidTokenError("Unexpected token type")
        return payload
    except jwt.InvalidTokenError as exc:
        raise AppException(
            code="INVALID_TOKEN",
            message="Could not validate credentials",
            status_code=401,
        ) from exc


def create_ticket_payload(
    registration_id: str,
    event_id: str,
    user_id: str,
) -> str:
    claims = {
        "eventId": event_id,
        "registrationId": registration_id,
        "userId": user_id,
    }
    canonical = json.dumps(claims, separators=(",", ":"), sort_keys=True)
    signature = hmac.new(
        settings.JWT_SECRET.encode(),
        canonical.encode(),
        hashlib.sha256,
    ).hexdigest()
    return json.dumps(
        {**claims, "signature": signature},
        separators=(",", ":"),
        sort_keys=True,
    )


def verify_ticket_payload(payload: str) -> bool:
    try:
        decoded = json.loads(payload)
        signature = decoded.pop("signature")
        canonical = json.dumps(decoded, separators=(",", ":"), sort_keys=True)
        expected = hmac.new(
            settings.JWT_SECRET.encode(),
            canonical.encode(),
            hashlib.sha256,
        ).hexdigest()
        return hmac.compare_digest(signature, expected)
    except (AttributeError, KeyError, TypeError, ValueError, json.JSONDecodeError):
        return False
