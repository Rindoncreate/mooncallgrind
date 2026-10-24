///|
fn ws(c : UInt16) -> Bool { c == 32 || c == 9 || c == 13 }

///|
fn trim_ascii(text : String) -> String {
  let mut a = 0
  let mut b = text.length()
  while a < b && ws(text[a]) { a = a + 1 }
  while b > a && ws(text[b - 1]) { b = b - 1 }
  text[a:b].to_owned()
}

///|
fn words(text : String) -> Array[String] {
  let result : Array[String] = []
  let mut a = 0
  while a < text.length() {
    if ws(text[a]) { a = a + 1; continue }
    let mut b = a
    while b < text.length() && !ws(text[b]) { b = b + 1 }
    result.push(text[a:b].to_owned())
    a = b
  }
  result
}

///| Parse directly into UInt64, with pre-operation overflow checks.
fn unsigned(text : String, line : Int) -> UInt64 raise ParseError {
  let hex = text.has_prefix("0x")
  let start = if hex { 2 } else { 0 }
  if text.length() == start || text.length() - start > 20 {
    raise Syntax(line, "expected an unsigned decimal or hexadecimal integer")
  }
  let base : UInt64 = if hex { 16UL } else { 10UL }
  let mut value = 0UL
  for i = start; i < text.length(); i = i + 1 {
    let c = text[i].to_int()
    let digit = if c >= 48 && c <= 57 { c - 48 }
      else if hex && c >= 65 && c <= 70 { c - 55 }
      else if hex && c >= 97 && c <= 102 { c - 87 }
      else { raise Syntax(line, "invalid integer digit") }
    let d = digit.to_uint64()
    if value > (18446744073709551615UL - d) / base {
      raise Resource(line, "integer exceeds UInt64")
    }
    value = value * base + d
  }
  value
}

///|
fn add_checked(a : UInt64, b : UInt64, line : Int) -> UInt64 raise ParseError {
  if a > 18446744073709551615UL - b {
    raise Resource(line, "counter sum exceeds UInt64")
  }
  a + b
}

///|
fn position(token : String, previous : UInt64, line : Int) -> UInt64 raise ParseError {
  if token == "*" { return previous }
  if token.has_prefix("+") {
    return add_checked(previous, unsigned(token[1:].to_owned(), line), line)
  }
  if token.has_prefix("-") {
    let delta = unsigned(token[1:].to_owned(), line)
    if delta > previous { raise Syntax(line, "relative position is negative") }
    return previous - delta
  }
  unsigned(token, line)
}
