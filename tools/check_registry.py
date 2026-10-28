"""Run AFTER publication: install the exact version in a fresh, independent module.
There is no sibling-library workspace, source archive or local fallback here.
"""
from pathlib import Path
import shutil, subprocess, tempfile

moon = shutil.which('moon')
assert moon, 'MoonBit CLI is required'
with tempfile.TemporaryDirectory(prefix='mooncallgrind-registry-') as folder:
    consumer = Path(folder)
    (consumer / 'moon.mod').write_text('name = "probe/registryconsumer"\nversion = "0.1.0"\nimport { "Rindoncreate/mooncallgrind@0.1.0", }\n', encoding='utf8')
    (consumer / 'moon.pkg').write_text('import { "Rindoncreate/mooncallgrind" @cg, }\n', encoding='utf8')
    (consumer / 'consumer.mbt').write_text(r'''///|
pub fn targets() -> Array[UInt64] raise @cg.ParseError {
  let text = "events: Ir\nob=caller\nfl=caller.mbt\nfn=main\ncob=worker.so\ncfi=worker.mbt\n10 9007199254740993\ncfn=work\ncalls=2 70\n11 30\ncfn=work\ncalls=1 71\n20 40\n"
  let p = @cg.parse(text)
  if p.self_totals("Ir")[0].value != 9007199254740993UL {
    raise @cg.Syntax(0, "counter precision lost")
  }
  match p.records[1].kind {
    Call(_, target, _) => {
      if target.file != "worker.mbt" || target.object != "worker.so" {
        raise @cg.Syntax(0, "callee override lost")
      }
    }
    _ => raise @cg.Syntax(0, "call missing")
  }
  let positions : Array[UInt64] = []
  for record in @cg.parse(@cg.normalize(text)).records {
    match record.kind {
      SelfCost => ()
      Call(_, _, target) => positions.push(target[0])
    }
  }
  positions
}
''', encoding='utf8')
    (consumer / 'consumer_test.mbt').write_text('''///|
test "published registry API preserves targets and exact counters" {
  assert_eq(@registryconsumer.targets(), [70UL, 71UL])
}
''', encoding='utf8')
    subprocess.run([moon, 'update'], cwd=consumer, check=True, timeout=120)
    for target in ['js', 'native']:
        subprocess.run([moon, 'check', '--target', target, '--deny-warn'], cwd=consumer, check=True, timeout=120)
        subprocess.run([moon, 'test', '--target', target, '--deny-warn'], cwd=consumer, check=True, timeout=120)
print('Exact Mooncakes registry version passed on JS and native')
