///|
test "preserve two call sites, target positions, recursion and exact counters" {
  let p = parse("events: Ir Dr\nob=(1) app\nfl=(1) main.mbt\nfn=(1) main\n10 9007199254740993\ncfn=(2) work\ncalls=2 70\n+1 30 4\ncfn=(2)\ncalls=1 71\n+3 40 5\ncfn=(1)\ncalls=1 10\n* 9\n")
  assert_eq(p.records.length(), 4)
  assert_eq(p.records[0].values, [9007199254740993UL, 0UL])
  assert_eq(p.records[1].positions, [11UL])
  assert_eq(p.records[2].positions, [14UL])
  match p.records[1].kind {
    Call(n, target, pos) => { assert_eq(n, 2UL); assert_eq(target.function_name, "work"); assert_eq(pos, [70UL]) }
    _ => fail("missing call")
  }
  match p.records[3].kind {
    Call(_, target, _) => assert_eq(target.function_name, "main")
    _ => fail("self call was lost")
  }
}

///|
test "part boundaries keep shared dictionaries and local event order" {
  let p = parse("part: 1\npositions: instr line\nevents: Ir Dr\nfl=(1) main.mbt\nfn=(1) main\n0x10 2 3 4\ntotals: 3 4\npart: 2\nevents: Dr Ir\npositions: line\nfl=(1)\nfn=(1)\n5 6 7\n")
  assert_eq(p.parts.length(), 2)
  assert_eq(p.records[1].part, 1)
  assert_eq(p.parts[1].events, ["Dr", "Ir"])
  assert_eq(p.records[1].context.file, "main.mbt")
}

///|
test "inline file is separate from function identity and defaults for callee" {
  let p = parse("events: Ir\nfl=outer.mbt\nfn=f\nfi=inline.mbt\n1 2\ncfn=g\ncalls=1 6\n+1 3\n")
  assert_eq(p.records[0].context.file, "outer.mbt")
  assert_eq(p.records[0].context.cost_file, "inline.mbt")
  match p.records[1].kind {
    Call(_, target, _) => assert_eq(target.file, "inline.mbt")
    _ => fail("missing call")
  }
}

///|
test "malformed and unsupported input is rejected without partial success" {
  for bad in [
    "", "events: Ir Ir", "events: Ir\nfn=(9)\n1 1",
    "events: Ir\nfn=f\ncfn=g\ncalls=1 2",
    "events: Ir\nfn=f\ncfn=g\ncalls=1 2\nfn=h\n1 1",
    "events: Ir\nfn=f\n1 1 2", "events: Ir\nfn=f\njump=1 2",
    "events: Ir\nfn=f\n-1 1", "events: Ir\nfn=f\n1 18446744073709551616",
    "events: Ir\npositions: unknown\nfn=f\n1 1",
  ] {
    let rejected = try { ignore(parse(bad)); false } catch { _ => true }
    assert_true(rejected)
  }
}
