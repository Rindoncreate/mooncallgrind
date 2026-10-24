"""Import an inspected public CI export; never execute paths from the payload."""
from pathlib import Path
import base64, gzip, json, sys
root = Path(__file__).resolve().parents[1]
allowed = {'model.mbt', 'numbers.mbt', 'numbers_wbtest.mbt', 'parser.mbt', 'parser_test.mbt',
           'normalize.mbt', 'analysis.mbt', 'analysis_test.mbt', 'bridge/run.mbt',
           'moon.mod', 'moon.pkg', 'bridge/moon.pkg', 'pkg.generated.mbti',
           'bridge/pkg.generated.mbti','examples/sites/main.mbt','examples/sites/moon.pkg','examples/sites/pkg.generated.mbti','robustness_test.mbt', '_build/js/debug/build/bridge/bridge.js'}
encoded = sys.stdin.read().strip()
assert len(encoded) < 1000000
with gzip.GzipFile(fileobj=__import__('io').BytesIO(base64.b64decode(encoded, validate=True))) as stream:
    raw = stream.read(5000001)
assert len(raw) <= 5000000
selected = set(sys.argv[1:])
assert selected <= allowed
for name, content in json.loads(raw)['files'].items():
    assert name in allowed and isinstance(content, str)
    if selected and name not in selected:
        continue
    path = (root / name).resolve()
    assert path.is_relative_to(root.resolve())
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding='utf8', newline='\n')
print('Received public CI source/build export.')
