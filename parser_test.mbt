///|
test "preserve two call sites, target positions, recursion and exact counters" {
  let p = @mooncallgrind.parse(
    "events: Ir Dr\nob=(1) app\nfl=(1) main.mbt\nfn=(1) main\n10 9007199254740993\ncfn=(2) work\ncalls=2 70\n+1 30 4\ncfn=(2)\ncalls=1 71\n+3 40 5\ncfn=(1)\ncalls=1 10\n* 9\n",
  )
  assert_eq(p.records.length(), 4)
  assert_eq(p.records[0].values, [9007199254740993UL, 0UL])
  assert_eq(p.records[1].positions, [11UL])
  assert_eq(p.records[2].positions, [14UL])
  match p.records[1].kind {
    Call(n, target, pos) => {
      assert_eq(n, 2UL)
      assert_eq(target.function_name, "work")
      assert_eq(pos, [70UL])
    }
    _ => fail("missing call")
  }
  match p.records[3].kind {
    Call(_, target, _) => assert_eq(target.function_name, "main")
    _ => fail("self call was lost")
  }
}

///|
test "part boundaries keep shared dictionaries and local event order" {
  let p = @mooncallgrind.parse(
    "part: 1\npositions: instr line\nevents: Ir Dr\nfl=(1) main.mbt\nfn=(1) main\n0x10 2 3 4\ntotals: 3 4\npart: 2\nevents: Dr Ir\npositions: line\nfl=(1)\nfn=(1)\n5 6 7\n",
  )
  assert_eq(p.parts.length(), 2)
  assert_eq(p.records[1].part, 1)
  assert_eq(p.parts[1].events, ["Dr", "Ir"])
  assert_eq(p.records[1].context.file, "main.mbt")
}

///|
test "inline file is separate from function identity and defaults for callee" {
  let p = @mooncallgrind.parse(
    "events: Ir\nfl=outer.mbt\nfn=f\nfi=inline.mbt\n1 2\ncfn=g\ncalls=1 6\n+1 3\n",
  )
  assert_eq(p.records[0].context.file, "outer.mbt")
  assert_eq(p.records[0].context.cost_file, "inline.mbt")
  match p.records[1].kind {
    Call(_, target, _) => assert_eq(target.file, "inline.mbt")
    _ => fail("missing call")
  }
}

///|
test "malformed and unsupported input is rejected without partial success" {
  for
    bad in [
      "", "events: Ir Ir", "events: Ir\nfn=(9)\n1 1", "events: Ir\nfn=f\ncfn=g\ncalls=1 2",
      "events: Ir\nfn=f\ncfn=g\ncalls=1 2\nfn=h\n1 1", "events: Ir\nfn=f\n1 1 2",
      "events: Ir\nfn=f\njump=1 2", "events: Ir\nfn=f\n-1 1", "events: Ir\nfn=f\n1 18446744073709551616",
      "events: Ir\npositions: unknown\nfn=f\n1 1",
    ] {
    let rejected = try {
      ignore(@mooncallgrind.parse(bad))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}

///|
test "callee file and object survive self costs and reset after a call" {
  let p = @mooncallgrind.parse(
    "events: Ir\nob=caller\nfl=caller.mbt\nfn=main\ncob=worker.so\ncfi=worker.mbt\n10 1\ncfn=work\ncalls=1 70\n+1 4\ncfn=local\ncalls=1 20\n+1 3\n",
  )
  match p.records[1].kind {
    Call(_, target, _) => {
      assert_eq(target.object, "worker.so")
      assert_eq(target.file, "worker.mbt")
    }
    _ => fail("missing first call")
  }
  match p.records[2].kind {
    Call(_, target, _) => {
      assert_eq(target.object, "caller")
      assert_eq(target.file, "caller.mbt")
    }
    _ => fail("missing second call")
  }
}

///|
test "canonical position order includes instruction basic-block and line" {
  let text = "positions: instr bb line\nevents: Ir\nfn=f\n0x10 2 7 1\n+1 * +1 2\ncfn=g\ncalls=1 +5 +2 +10\n+1 +1 +1 3\n"
  let p = @mooncallgrind.parse(text)
  assert_eq(p.records[2].positions, [18UL, 3UL, 9UL])
  match p.records[2].kind {
    Call(_, _, target) => assert_eq(target, [22UL, 4UL, 18UL])
    _ => fail("missing call")
  }
  let q = @mooncallgrind.parse(@mooncallgrind.normalize(text))
  assert_eq(q.records[2].kind, p.records[2].kind)
  for bad in ["line instr", "bb instr", "line bb", "instr line bb"] {
    let rejected = try {
      ignore(@mooncallgrind.parse("positions: " + bad + "\nevents: Ir\n"))
      false
    } catch {
      @mooncallgrind.Syntax(_, _) => true
      _ => false
    }
    assert_true(rejected)
  }
}
