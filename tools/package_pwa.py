"""Finalize Flutter web output and create a standalone deployment ZIP. No dependencies."""
import hashlib
import json
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def package():
    web = ROOT / 'build/web'
    required = ['main.dart.js', 'index.html', 'flutter_bootstrap.js', 'manifest.json', 'pwa.js']
    for name in required:
        if not (web / name).is_file():
            raise SystemExit('Run flutter build web --release --no-web-resources-cdn first')
    if '$FLUTTER_BASE_HREF' in (web / 'index.html').read_text(encoding='utf8'):
        raise SystemExit('Unprocessed Flutter index')
    version = re.search(r'^version:\s*(\S+)', (ROOT / 'pubspec.yaml').read_text(encoding='utf8'), re.M)[1]
    files = sorted(p for p in web.rglob('*') if p.is_file()
                   and p.suffix not in {'.map', '.symbols'}
                   and (not p.relative_to(web).as_posix().startswith('canvaskit/')
                        or p.relative_to(web).as_posix() in {'canvaskit/canvaskit.js', 'canvaskit/canvaskit.wasm'})
                   and p.name not in {'unio-sw.js', 'flutter_service_worker.js', 'pwa-build.json', '.last_build_id'})
    paths = [p.relative_to(web).as_posix() for p in files]
    digest = hashlib.sha256()
    for path, source in zip(paths, files):
        digest.update(path.encode())
        digest.update(source.read_bytes())
    build = digest.hexdigest()[:20]
    worker = (ROOT / 'web/unio-sw.js').read_text(encoding='utf8')
    worker = worker.replace('__UNIO_BUILD_ID__', build).replace('/* UNIO_FILES */ []', json.dumps(paths))
    (web / 'unio-sw.js').write_text(worker, encoding='utf8')
    metadata = {'version': version, 'web_build': build, 'mode': 'full', 'assets': len(paths)}
    (web / 'pwa-build.json').write_text(json.dumps(metadata, indent=2), encoding='utf8')
    output = ROOT / 'build' / f'UNIO-PWA-{version.split("+")[0]}.zip'
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for source in files + [web / 'unio-sw.js', web / 'pwa-build.json']:
            archive.write(source, 'public/' + source.relative_to(web).as_posix())
        for source in (ROOT / 'deploy/pwa').iterdir():
            if source.is_file():
                archive.write(source, source.name)
    print(json.dumps({'archive': str(output), **metadata}, ensure_ascii=False))


if __name__ == '__main__':
    package()
