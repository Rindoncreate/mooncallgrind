"""Compile a fresh consumer against the packaged source, not the checkout API.
Registry installation is a separate release check; this is not publication proof.
"""
from pathlib import Path
import shutil, subprocess, tempfile, zipfile
root = Path(__file__).resolve().parents[1]
moon = shutil.which('moon')
assert moon
with tempfile.TemporaryDirectory(prefix='mooncallgrind-consumer-') as folder:
    workspace = Path(folder)
    library = workspace / 'library'
    library.mkdir()
    with zipfile.ZipFile(root / '_build/publish/Rindoncreate-mooncallgrind-0.1.0.zip') as package:
        for member in package.infolist():
            assert (library / member.filename).resolve().is_relative_to(library.resolve())
        package.extractall(library)
    consumer = workspace / 'consumer'
    consumer.mkdir()
    (workspace / 'moon.work').write_text('members = [ "library", "consumer" ]\n')
    (consumer / 'moon.mod').write_text('name = "probe/siteconsumer"\nversion = "0.1.0"\nimport { "Rindoncreate/mooncallgrind@0.1.0", }\n')
    (consumer / 'moon.pkg').write_text('import { "Rindoncreate/mooncallgrind" @cg, }\n')
    (consumer / 'consumer.mbt').write_text(r'''///|
pub fn call_targets() -> Array[UInt64] raise @cg.ParseError {
  let p = @cg.parse("events: Ir\nfl=a\nfn=f\n1 9007199254740993\ncfn=g\ncalls=2 70\n10 30\ncfn=g\ncalls=1 71\n20 40\n")
  let result : Array[UInt64] = []
  for r in p.records {
    match r.kind {
      SelfCost => ()
      Call(_, _, positions) => result.push(positions[0])
    }
  }
  let totals = p.self_totals("Ir")
  if totals[0].value != 9007199254740993UL { raise @cg.Syntax(0, "counter precision lost") }
  result
}
''')
    (consumer / 'consumer_test.mbt').write_text('''///|
test "packaged public API retains distinct target positions" {
  assert_eq(@siteconsumer.call_targets(), [70UL, 71UL])
}
''')
    for target in ['js', 'native']:
        subprocess.run([moon, 'check', '--target', target, '--deny-warn'], cwd=consumer, check=True, timeout=60)
        subprocess.run([moon, 'test', '--target', target, '--deny-warn'], cwd=consumer, check=True, timeout=60)
print('Separate source-package consumer passed on JS and native; registry publication not implied')
