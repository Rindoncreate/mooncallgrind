"""Describe and checksum the exact CI source package; does not publish it."""
from pathlib import Path
import hashlib, json, re, subprocess, zipfile

root = Path(__file__).resolve().parents[1]
manifest = (root / 'moon.mod').read_text(encoding='utf8')
name = re.search(r'^name\s*=\s*"([^"]+)"', manifest, re.M)[1]
version = re.search(r'^version\s*=\s*"([^"]+)"', manifest, re.M)[1]
archive = root / '_build/publish' / f'{name.replace("/", "-")}-{version}.zip'
sha = hashlib.sha256(archive.read_bytes()).hexdigest()
with zipfile.ZipFile(archive) as package:
    names = package.namelist()
    assert len(names) == len(set(names)), 'duplicate package member'
    assert package.read('moon.mod').decode('utf8') == manifest
    assert {'LICENSE', 'fixtures/LICENSE-APACHE', 'fixtures/NOTICE.md', 'bin/read-input.mjs'} <= set(names)
    assert package.testzip() is None, 'corrupt zip member'
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
report = {
    'module': name, 'version': version, 'source_commit': head,
    'archive': archive.name, 'sha256': sha, 'files': len(names),
    'publication_performed_by_ci': False,
}
archive.with_suffix('.release.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
(archive.parent / 'SHA256SUMS').write_text(f'{sha}  {archive.name}\n', encoding='ascii')
print(json.dumps(report))
