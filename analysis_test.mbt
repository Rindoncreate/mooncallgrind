///|
test "totals exclude call costs, preserve identity and use each part event order" {
  let p = @mooncallgrind.parse("part: 1\nevents: Ir Dr\nfl=a\nfn=f\n1 10 20\ncfn=g\ncalls=1 2\n2 100 200\npart: 2\nevents: Dr Ir\nfl=a\nfn=f\n1 3 4\nfl=b\nfn=f\n1 5 6\n")
  let totals = p.self_totals("Ir")
  assert_eq(totals.length(), 2)
  assert_eq(totals[0].value, 14UL)
  assert_eq(totals[1].value, 6UL)
  let changes = @mooncallgrind.diff(p, @mooncallgrind.parse("events: Ir\nfl=a\nfn=f\n1 2\n"), "Ir")
  assert_eq(changes[0].before, 14UL)
  assert_eq(changes[0].after, 2UL)
  assert_eq(changes[1].after, 0UL)
}

///|
test "unknown metrics and sum overflow are rejected" {
  let p = @mooncallgrind.parse("events: Ir\nfn=f\n1 18446744073709551615\n+1 1\n")
  let overflow = try { ignore(p.self_totals("Ir")); false } catch { _ => true }
  assert_true(overflow)
  let absent = try { ignore(p.self_totals("Cycles")); false } catch { _ => true }
  assert_true(absent)
}

///|
test "normalization preserves all supported record semantics and is idempotent" {
  let text = "events: Ir Dr\npositions: instr line\nob=(1) app\nfl=(1) a.mbt\nfn=(1) f\nfi=(2) inline.mbt\n0x20 10 5\ncfi=(1)\ncfn=(2) (123) literal\ncalls=2 +2 +5\n+1 * 9007199254740993 2\ntotals: 8 2\n"
  let normalized = @mooncallgrind.normalize(text)
  let a = @mooncallgrind.parse(text)
  let b = @mooncallgrind.parse(normalized)
  assert_eq(a.records.length(), b.records.length())
  for i = 0; i < a.records.length(); i = i + 1 {
    assert_eq(a.records[i].context, b.records[i].context)
    assert_eq(a.records[i].positions, b.records[i].positions)
    assert_eq(a.records[i].values, b.records[i].values)
    assert_eq(a.records[i].kind, b.records[i].kind)
  }
  assert_eq(@mooncallgrind.normalize(normalized), normalized)
}
