///| Self-only totals, matched by event name in each part, not by column number.

///|
/// No inferred recursion or inclusive totals. Overflow is a checked error.
pub fn Profile::self_totals(
  self : Profile,
  event : String,
) -> Array[Total] raise ParseError {
  let columns : Array[Int32] = []
  for part in self.parts {
    let mut column = -1
    for i = 0; i < part.events.length(); i = i + 1 {
      if part.events[i] == event {
        column = i
      }
    }
    if column < 0 {
      raise Unsupported(0, "physical event absent from a part: " + event)
    }
    columns.push(column)
  }
  let indices : Map[(String, String, String), Int32] = Map([])
  let totals : Array[Total] = []
  for record in self.records {
    if record.part < 0 || record.part >= columns.length() {
      raise Syntax(record.line, "invalid part index in model")
    }
    let column = columns[record.part]
    if record.values.length() != self.parts[record.part].events.length() {
      raise Syntax(record.line, "invalid event values in model")
    }
    if record.kind is SelfCost {
      let c = record.context
      let key = (c.object, c.file, c.function_name)
      match indices.get(key) {
        None => {
          indices.set(key, totals.length())
          totals.push({
            object: c.object,
            file: c.file,
            function_name: c.function_name,
            value: record.values[column],
          })
        }
        Some(i) =>
          totals[i] = {
            ..totals[i],
            value: add_checked(
              totals[i].value,
              record.values[column],
              record.line,
            ),
          }
      }
    }
  }
  totals
}

///| Compare raw self counters by object/file/function. Callers must ensure that

///|
/// event meaning, build and collection conditions are comparable.
pub fn diff(
  before : Profile,
  after : Profile,
  event : String,
) -> Array[Change] raise ParseError {
  let left = before.self_totals(event)
  let right = after.self_totals(event)
  let changes : Array[Change] = []
  let indices : Map[(String, String, String), Int32] = Map([])
  for total in left {
    indices.set(
      (total.object, total.file, total.function_name),
      changes.length(),
    )
    changes.push({
      object: total.object,
      file: total.file,
      function_name: total.function_name,
      before: total.value,
      after: 0UL,
    })
  }
  for total in right {
    let key = (total.object, total.file, total.function_name)
    match indices.get(key) {
      None =>
        changes.push({
          object: total.object,
          file: total.file,
          function_name: total.function_name,
          before: 0UL,
          after: total.value,
        })
      Some(i) => changes[i] = { ..changes[i], after: total.value, }
    }
  }
  changes
}
