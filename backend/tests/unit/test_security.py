from datetime import timedelta

import pytest

from app.core.security import (
    create_access_token,
    create_ticket_payload,
    decode_access_token,
    get_password_hash,
    verify_password,
    verify_ticket_payload,
)
from app.exceptions.handlers import AppException


def test_password_hashing_uses_argon2():
    password = "supersecretpassword"
    hashed = get_password_hash(password)
    assert hashed.startswith("$argon2")
    assert verify_password(password, hashed)
    assert not verify_password("wrongpassword", hashed)


def test_jwt_creation_and_decoding():
    token = create_access_token(subject="user123", role="admin")
    payload = decode_access_token(token)
    assert payload["sub"] == "user123"
    assert payload["role"] == "admin"
    assert payload["type"] == "access"


def test_expired_and_invalid_jwt_are_rejected():
    expired = create_access_token(
        subject="user123",
        role="user",
        expires_delta=timedelta(seconds=-1),
    )
    for token in (expired, "invalid.token.string"):
        with pytest.raises(AppException) as exc_info:
            decode_access_token(token)
        assert exc_info.value.code == "INVALID_TOKEN"
        assert exc_info.value.status_code == 401


def test_ticket_payload_signature_detects_tampering():
    payload = create_ticket_payload("registration", "event", "user")
    assert verify_ticket_payload(payload)
    assert not verify_ticket_payload(payload.replace("event", "other"))
