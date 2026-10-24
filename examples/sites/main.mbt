///| A consumer keeps both sites, although the callee is the same.
fn main {
  let input = "events: Ir\nfl=main.mbt\nfn=main\n1 5\ncfn=work\ncalls=2 70\n10 30\ncfn=work\ncalls=1 71\n20 40\n"
  let p = @cg.parse(input) catch { _ => panic() }
  for record in p.records {
    match record.kind {
      SelfCost => ()
      Call(count, target, positions) => println("site=\{record.positions[0]} -> \{target.function_name}:\{positions[0]}, calls=\{count}")
    }
  }
}
