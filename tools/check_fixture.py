"""Independent inventory of one pinned line/Ir fixture; not a general parser.
Counts literal body counters without resolving names or positions. In particular,
the declared summary is NOT assumed to equal body self costs.
"""
from pathlib import Path
import hashlib, json
root = Path(__file__).resolve().parents[1]
raw = (root / 'fixtures/http_server.callgrind').read_bytes()
expected = json.loads((root / 'fixtures/http_server.inventory.json').read_text())
assert hashlib.sha256(raw).hexdigest() == expected['sha256']
lines = raw.decode('utf8').splitlines()
assert [s for s in lines if s.startswith('positions:')] == ['positions: line']
assert [s for s in lines if s.startswith('events:')] == ['events: Ir']
self_ir = call_ir = calls = records = 0
pending = False
summary = None
for line in lines:
    row = line.strip()
    if not row or row.startswith('#'):
        continue
    if row.startswith('summary:'):
        summary = row.split(':', 1)[1].strip()
    if row.startswith('calls='):
        assert not pending
        pending = True
        calls += 1
        continue
    if row[0] in '0123456789+-*':
        cells = row.split()
        assert 1 <= len(cells) <= 2
        value = int(cells[1], 16 if cells[1].startswith('0x') else 10) if len(cells) > 1 else 0
        if pending:
            call_ir += value
        else:
            self_ir += value
        pending = False
        records += 1
assert not pending
assert (records, calls, str(self_ir), str(call_ir), summary) == (
    expected['records'], expected['calls'], expected['selfIr'], expected['callIr'], expected['declaredSummaryIr'])
print(f'Pinned body inventory: {records} records, {calls} calls; self Ir={self_ir}, declared summary={summary}')
