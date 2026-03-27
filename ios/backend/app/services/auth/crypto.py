import base64
import hashlib


def xor_encrypt(value: str, secret: str) -> str:
    key = hashlib.sha256(secret.encode("utf-8")).digest()
    raw = value.encode("utf-8")
    encrypted = bytes(byte ^ key[index % len(key)] for index, byte in enumerate(raw))
    return base64.urlsafe_b64encode(encrypted).decode("utf-8")


def xor_decrypt(value: str, secret: str) -> str:
    key = hashlib.sha256(secret.encode("utf-8")).digest()
    raw = base64.urlsafe_b64decode(value.encode("utf-8"))
    decrypted = bytes(byte ^ key[index % len(key)] for index, byte in enumerate(raw))
    return decrypted.decode("utf-8")

