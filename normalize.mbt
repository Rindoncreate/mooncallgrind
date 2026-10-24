///|
/// Emit fresh IDs even for names that themselves look like `(123)` references.
fn write_name(
  out : StringBuilder,
  key : String,
  value : String,
  id : Int32,
) -> Unit {
  out.write_string(key + "=")
  if value != "" {
    out.write_string("(\{id}) " + value)
  }
  out.write_string("\n")
}

///|
fn write_positions(out : StringBuilder, values : Array[UInt64]) -> Unit {
  for i = 0; i < values.length(); i = i + 1 {
    if i > 0 {
      out.write_string(" ")
    }
    out.write_string(values[i].to_string())
  }
}

///| Normalize parsed text to absolute positions and fresh name IDs. Comments and

///|
/// original whitespace are not retained. Counters and all supported records are.
pub fn normalize(text : String) -> String raise ParseError {
  let profile = parse(text)
  let mut budget = 0
  for part in profile.parts {
    budget = budget + 32
    for h in part.headers {
      let size = h.key.length() + h.value.length() + 4
      if size > 16777216 - budget { raise Resource(h.line, "normalized text exceeds size budget") }
      budget = budget + size
    }
  }
  for record in profile.records {
    let size = record_size(record)
    if size > 16777216 - budget { raise Resource(record.line, "normalized text exceeds size budget") }
    budget = budget + size
  }
  let out = StringBuilder()
  let mut index = 0
  let mut id = 0
  for part_index = 0
      part_index < profile.parts.length()
      part_index = part_index + 1 {
    let part = profile.parts[part_index]
    if !part.headers.any(h => h.key == "part") {
      out.write_string("part: \{part_index + 1}\n")
    }
    for h in part.headers {
      if h.key != "totals" {
        out.write_string(h.key + ": " + h.value + "\n")
      }
    }
    while index < profile.records.length() &&
          profile.records[index].part == part_index {
      let record = profile.records[index]
      let c = record.context
      id = id + 1
      write_name(out, "ob", c.object, id)
      write_name(out, "fl", c.file, id)
      write_name(out, "fn", c.function_name, id)
      write_name(out, "fi", c.cost_file, id + 1)
      // fi uses another file ID so the function file remains available to consumers.
      id = id + 1
      match record.kind {
        SelfCost => ()
        Call(count, target, target_pos) => {
          id = id + 1
          write_name(out, "cob", target.object, id)
          write_name(out, "cfi", target.file, id)
          write_name(out, "cfn", target.function_name, id)
          out.write_string("calls=" + count.to_string() + " ")
          write_positions(out, target_pos)
          out.write_string("\n")
        }
      }
      write_positions(out, record.positions)
      for value in record.values {
        out.write_string(" " + value.to_string())
      }
      out.write_string("\n")
      index = index + 1
    }
    for h in part.headers {
      if h.key == "totals" {
        out.write_string(h.key + ": " + h.value + "\n")
      }
    }
    out.write_string("\n")
  }
  out.to_string()
}
