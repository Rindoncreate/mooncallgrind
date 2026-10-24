///|
/// Resolve aliases in one namespace; function and called-function IDs are shared.
fn name_value(
  text : String,
  names : Map[UInt64, String],
  line : Int32,
) -> String raise ParseError {
  if text.length() < 2 || text[0] != 40 || text[1] < 48 || text[1] > 57 {
    return text
  }
  let mut end = 1
  while end < text.length() && text[end] != 41 {
    end = end + 1
  }
  if end == text.length() {
    raise Syntax(line, "unterminated name ID")
  }
  let id = unsigned(text[1:end].to_owned(), line)
  if end + 1 == text.length() {
    match names.get(id) {
      Some(value) => value
      None => raise Syntax(line, "undefined name ID")
    }
  } else {
    if !ws(text[end + 1]) {
      raise Syntax(line, "name ID must be followed by whitespace")
    }
    let value = trim_ascii(text[end + 1:].to_owned())
    if names.length() >= 100000 && !names.contains(id) {
      raise Resource(line, "too many name IDs")
    }
    names.set(id, value)
    value
  }
}

///|
fn fields(
  text : String,
  line : Int32,
  positions~ : Bool,
) -> Array[String] raise ParseError {
  let items = words(text)
  if items.is_empty() || items.length() > 64 {
    raise Syntax(line, "expected 1..64 fields")
  }
  let seen : Map[String, Bool] = Map([])
  for item in items {
    if seen.contains(item) {
      raise Syntax(line, "duplicate field")
    }
    if positions && item != "line" && item != "instr" && item != "bb" {
      raise Unsupported(line, "unknown position field: " + item)
    }
    seen.set(item, true)
  }
  items
}

///|
/// Parse the documented cost/call profile. Jumps and unknown body directives fail closed.
pub fn parse(text : String) -> Profile raise ParseError {
  if text.length() > 16777216 {
    raise Resource(0, "input exceeds 16 Mi UTF-16 code units")
  }
  let files : Map[UInt64, String] = Map([])
  let functions : Map[UInt64, String] = Map([])
  let objects : Map[UInt64, String] = Map([])
  let parts : Array[Part] = []
  let records : Array[Record] = []
  let mut headers : Array[Header] = []
  let mut events : Array[String] = []
  let mut positions : Array[String] = ["line"]
  let mut have_positions = false
  let mut body = false
  let mut trailer = false
  let mut source = empty_context()
  let mut have_function = false
  let mut called : Context? = None
  let mut called_file : String? = None
  let mut called_object : String? = None
  let mut pending : (UInt64, Context, Array[UInt64])? = None
  let mut previous : Array[UInt64] = [0UL]
  let mut line = 0
  for view in text.split("\n") {
    line = line + 1
    if view.length() > 1048576 {
      raise Resource(line, "line exceeds 1 Mi code units")
    }
    let row = trim_ascii(view.to_owned())
    if row == "" || row.has_prefix("#") {
      continue
    }
    let first = row[0]
    let cost = (first >= 48 && first <= 57) ||
      first == 43 ||
      first == 45 ||
      first == 42
    if cost {
      if trailer {
        raise Syntax(line, "cost after totals trailer")
      }
      if events.is_empty() {
        raise Syntax(line, "missing events header")
      }
      if !have_function {
        raise Syntax(line, "cost without fn context")
      }
      let tokens = words(row)
      let n = positions.length()
      if tokens.length() < n || tokens.length() > n + events.length() {
        raise Syntax(line, "wrong number of cost columns")
      }
      let pos : Array[UInt64] = []
      for i = 0; i < n; i = i + 1 {
        pos.push(position(tokens[i], previous[i], line))
      }
      previous = pos.copy()
      let values : Array[UInt64] = []
      for i = n; i < n + events.length(); i = i + 1 {
        values.push(
          if i < tokens.length() {
            unsigned(tokens[i], line)
          } else {
            0UL
          },
        )
      }
      let kind = match pending {
        None => SelfCost
        Some((count, target, target_pos)) => Call(count, target, target_pos)
      }
      if records.length() >= 200000 {
        raise Resource(line, "too many cost records")
      }
      records.push({
        part: parts.length(),
        line,
        context: source,
        positions: pos,
        values,
        kind,
      })
      pending = None
      called_file = None
      called_object = None
      body = true
      continue
    }
    if pending is Some(_) {
      raise Syntax(line, "calls must be followed by a cost record")
    }
    let mut separator = 0
    while separator < row.length() &&
          row[separator] != 58 &&
          row[separator] != 61 {
      separator = separator + 1
    }
    if separator == row.length() {
      raise Syntax(line, "expected header or position directive")
    }
    let key = trim_ascii(row[:separator].to_owned())
    let value = trim_ascii(row[separator + 1:].to_owned())
    if row[separator] == 58 {
      if body && key != "totals" {
        if parts.length() >= 1023 {
          raise Resource(line, "too many dump parts")
        }
        parts.push({ headers, events, positions, })
        headers = []
        events = []
        positions = ["line"]
        have_positions = false
        previous = [0UL]
        source = empty_context()
        have_function = false
        called = None
        called_file = None
        called_object = None
        body = false
        trailer = false
      }
      match key {
        "events" => {
          if !events.is_empty() {
            raise Syntax(line, "repeated events header")
          }
          events = fields(value, line, positions=false)
        }
        "positions" => {
          if have_positions {
            raise Syntax(line, "repeated positions header")
          }
          positions = fields(value, line, positions=true)
          previous = positions.map(_ => 0UL)
          have_positions = true
        }
        "version" =>
          if value != "1" {
            raise Unsupported(line, "only Callgrind version 1 is supported")
          }
        "summary" | "totals" => {
          if events.is_empty() {
            raise Syntax(line, "counter header before events")
          }
          let totals = words(value)
          if totals.length() > events.length() {
            raise Syntax(line, "too many summary/totals columns")
          }
          for token in totals {
            ignore(unsigned(token, line))
          }
          if key == "totals" {
            trailer = true
          }
        }
        _ => ()
      }
      if headers.length() >= 4096 {
        raise Resource(line, "too many headers in dump part")
      }
      headers.push({ key, value, line, })
      continue
    }
    if trailer {
      raise Syntax(line, "position directive after totals trailer")
    }
    match key {
      "ob" => source = { ..source, object: name_value(value, objects, line), }
      "fl" => {
        let file = name_value(value, files, line)
        source = { ..source, cost_file: file, }
      }
      "fi" | "fe" =>
        source = { ..source, cost_file: name_value(value, files, line), }
      "fn" => {
        source = {
          ..source,
          file: source.cost_file,
          function_name: name_value(value, functions, line),
        }
        have_function = true
        called = None
      }
      "cob" => called_object = Some(name_value(value, objects, line))
      "cfl" | "cfi" => called_file = Some(name_value(value, files, line))
      "cfn" => {
        let object = match called_object {
          Some(v) => v
          None => source.object
        }
        let file = match called_file {
          Some(v) => v
          None => source.cost_file
        }
        called = Some({
          object,
          file,
          cost_file: file,
          function_name: name_value(value, functions, line),
        })
      }
      "calls" => {
        let tokens = words(value)
        if tokens.length() != positions.length() + 1 {
          raise Syntax(line, "wrong number of call target positions")
        }
        let target = match called {
          None => raise Syntax(line, "calls without cfn context")
          Some(v) => v
        }
        let target_pos : Array[UInt64] = []
        for i = 0; i < positions.length(); i = i + 1 {
          target_pos.push(position(tokens[i + 1], previous[i], line))
        }
        pending = Some((unsigned(tokens[0], line), target, target_pos))
      }
      _ => raise Unsupported(line, "unsupported body directive: " + key)
    }
  }
  if pending is Some(_) {
    raise Syntax(line, "incomplete call record at end of input")
  }
  if events.is_empty() {
    raise Syntax(line, "missing events header")
  }
  parts.push({ headers, events, positions, })
  { parts, records, }
}
