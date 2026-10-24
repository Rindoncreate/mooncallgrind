///|
test "empty parts, literal alias-looking names and function changes retain semantics" {
  let text = "part: 1\nevents: Ir\npart: 2\nevents: Ir\nfn=(1) (99) literal\n10 1\nfn=g\n+2 2\npart: 3\nevents: Ir\n"
  let p = @mooncallgrind.parse(text)
  let q = @mooncallgrind.parse(@mooncallgrind.normalize(text))
  assert_eq(p.parts.length(), 3)
  assert_eq(q.parts.length(), 3)
  assert_eq(p.records[0].context.function_name, "(99) literal")
  assert_eq(p.records[1].positions, [12UL])
  assert_eq(q.records[0].context, p.records[0].context)
  assert_eq(q.records[1].positions, p.records[1].positions)
}

///|
test "deterministic malformed corpus cannot escape as a partial parse" {
  let alphabet = [
    "\n", "#", ":", "=", "*", "+", "-", "(", ")", "0", "a", " ", "\t",
  ]
  let mut seed = 17
  for i = 0; i < 400; i = i + 1 {
    let out = StringBuilder()
    out.write_string("events: Ir\nfn=f\n")
    for j = 0; j < i % 80; j = j + 1 {
      seed = (seed * 73 + 19) % 65521
      out.write_string(alphabet[seed % alphabet.length()])
    }
    let text = out.to_string()
    let accepted = Some(@mooncallgrind.parse(text)) catch {
      @mooncallgrind.Syntax(_, _) => None
      @mooncallgrind.Unsupported(_, _) => None
      @mooncallgrind.Resource(_, _) => None
    }
    if accepted is Some(p) {
      let q = @mooncallgrind.parse(@mooncallgrind.normalize(text))
      assert_eq(p.records.length(), q.records.length())
      for r = 0; r < p.records.length(); r = r + 1 {
        assert_eq(p.records[r].context, q.records[r].context)
        assert_eq(p.records[r].positions, q.records[r].positions)
        assert_eq(p.records[r].values, q.records[r].values)
        assert_eq(p.records[r].kind, q.records[r].kind)
      }
    }
  }
}

///|
test "overlong lines and compressed-name expansion are bounded" {
  let out = StringBuilder()
  for i = 0; i < 1048577; i = i + 1 {
    out.write_string("x")
  }
  let large = try {
    ignore(@mooncallgrind.parse(out.to_string()))
    false
  } catch {
    @mooncallgrind.Resource(_, _) => true
    _ => false
  }
  assert_true(large)
  let names = StringBuilder()
  names.write_string("events: Ir\nfn=(1) ")
  for i = 0; i < 10000; i = i + 1 {
    names.write_string("x")
  }
  names.write_string("\n")
  for i = 0; i < 1800; i = i + 1 {
    names.write_string("1 0\n")
  }
  let expansion = try {
    ignore(@mooncallgrind.parse(names.to_string()))
    false
  } catch {
    @mooncallgrind.Resource(_, _) => true
    _ => false
  }
  assert_true(expansion)
}

///|
test "mutated public models are rejected before indexed access" {
  let p = @mooncallgrind.parse("events: Ir\nfn=f\n1 1\n")
  p.records[0] = { ..p.records[0], part: -1, }
  let bad_part = try {
    ignore(p.self_totals("Ir"))
    false
  } catch {
    @mooncallgrind.Syntax(_, _) => true
    _ => false
  }
  assert_true(bad_part)
  let q = @mooncallgrind.parse("events: Ir\nfn=f\n1 1\n")
  q.records[0].values.clear()
  let bad_values = try {
    ignore(q.self_totals("Ir"))
    false
  } catch {
    @mooncallgrind.Syntax(_, _) => true
    _ => false
  }
  assert_true(bad_values)
}
