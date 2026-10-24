///|
test "exact unsigned values and relative positions" {
  assert_eq(unsigned("18446744073709551615", 1), 18446744073709551615UL)
  assert_eq(unsigned("0xffffffffffffffff", 1), 18446744073709551615UL)
  assert_eq(unsigned("9007199254740993", 1), 9007199254740993UL)
  assert_eq(position("+3", 10UL, 1), 13UL)
  assert_eq(position("-0x2", 10UL, 1), 8UL)
  assert_eq(position("*", 10UL, 1), 10UL)
}

///|
test "overflow and invalid integers are checked errors" {
  for bad in ["", "-1", "+1", "1.5", "0x", "0xg", "18446744073709551616"] {
    let rejected = try { ignore(unsigned(bad, 3)); false } catch { _ => true }
    assert_true(rejected)
  }
  let overflow = try { ignore(position("+1", 18446744073709551615UL, 1)); false } catch { _ => true }
  assert_true(overflow)
  let negative = try { ignore(position("-2", 1UL, 1)); false } catch { _ => true }
  assert_true(negative)
}
