"""Create private backend configuration without printing credentials or keys.

Run with backend requirements installed. Upload settings through hosting secrets;
never put this file into public/ or commit the generated file.
"""
import argparse
import base64
import os
from pathlib import Path
from urllib.parse import urlsplit

from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import Encoding, PrivateFormat, PublicFormat, NoEncryption


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--origin', required=True, help='Public HTTPS origin of the PWA')
    parser.add_argument('--output', default='build/pwa-backend.private.env')
    args = parser.parse_args()
    origin = urlsplit(args.origin)
    if origin.scheme != 'https' or not origin.hostname or origin.path not in ('', '/') or origin.query or origin.fragment or origin.username or origin.password:
        parser.error('--origin must be an HTTPS origin without a path')
    private = ec.generate_private_key(ec.SECP256R1())
    encode = lambda value: base64.urlsafe_b64encode(value).rstrip(b'=').decode()
    values = {
        'WEB_PORTAL_ORIGINS': args.origin.rstrip('/'),
        'WEB_PORTAL_KEYS': Fernet.generate_key().decode(),
        'WEB_PUSH_PRIVATE_KEY': encode(private.private_bytes(Encoding.DER, PrivateFormat.PKCS8, NoEncryption())),
        'WEB_PUSH_PUBLIC_KEY': encode(private.public_key().public_bytes(Encoding.X962, PublicFormat.UncompressedPoint)),
        'WEB_PUSH_SUBJECT': 'mailto:unio.support@gmail.com',
    }
    output = Path(args.output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    descriptor = os.open(output, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, 'w', encoding='utf8', newline='\n') as file:
        file.write('\n'.join(f'{key}={value}' for key, value in values.items()) + '\n')
    print('Private configuration saved to:', output)
    print('Import into backend environment. Keep keys stable across restarts. Do not publish this file.')


if __name__ == '__main__':
    main()
