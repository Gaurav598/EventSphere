import pytest
from app.core.security import get_password_hash, verify_password, create_access_token, decode_access_token
from app.exceptions.handlers import AppException

def test_password_hashing():
    password = "supersecretpassword"
    hashed = get_password_hash(password)
    
    assert hashed != password
    assert verify_password(password, hashed) is True
    assert verify_password("wrongpassword", hashed) is False

def test_jwt_creation_and_decoding():
    subject = "user123"
    role = "admin"
    
    token = create_access_token(subject=subject, role=role)
    assert isinstance(token, str)
    
    payload = decode_access_token(token)
    assert payload["sub"] == subject
    assert payload["role"] == role
    assert "exp" in payload

def test_jwt_invalid_token():
    with pytest.raises(AppException) as excinfo:
        decode_access_token("invalid.token.string")
    
    assert excinfo.value.status_code == 401
    assert excinfo.value.code == "INVALID_TOKEN"
