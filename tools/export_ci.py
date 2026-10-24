"""Export an exact allowlist of public sources and compiled JS; never credentials."""
from pathlib import Path
import base64,gzip,json
root=Path(__file__).resolve().parents[1]
names=['model.mbt','numbers.mbt','numbers_wbtest.mbt','parser.mbt','parser_test.mbt','normalize.mbt','analysis.mbt','analysis_test.mbt','bridge/run.mbt','moon.mod','moon.pkg','bridge/moon.pkg','pkg.generated.mbti','bridge/pkg.generated.mbti','examples/sites/main.mbt','examples/sites/moon.pkg','examples/sites/pkg.generated.mbti','robustness_test.mbt']
files={name:(root/name).read_text(encoding='utf8') for name in names if (root/name).is_file()}
bridge=root/'_build/js/debug/build/bridge/bridge.js'
if bridge.is_file(): files['_build/js/debug/build/bridge/bridge.js']=bridge.read_text(encoding='utf8')
encoded=base64.b64encode(gzip.compress(json.dumps({'files':files}).encode(),mtime=0)).decode()
assert len(encoded)<1000000
print('MOONCALLGRIND_CI_PAYLOAD_BEGIN')
print(encoded)
print('MOONCALLGRIND_CI_PAYLOAD_END')
