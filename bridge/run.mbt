///|
fn obj(entries : Array[(String, Json)]) -> Json {
  Json::object(Map(entries))
}

///|
fn text(value : String) -> Json {
  Json::string(value)
}

///|
fn index(value : Int32) -> Json {
  Json::number(value.to_double())
}

///|
fn exact(values : Array[UInt64]) -> Json {
  Json::array(values.map(v => text(v.to_string())))
}

///|
fn context(c : @cg.Context) -> Json {
  obj([
    ("object", text(c.object)),
    ("file", text(c.file)),
    ("function", text(c.function_name)),
    ("costFile", text(c.cost_file)),
  ])
}

///|
fn profile_json(p : @cg.Profile) -> Json {
  obj([
    ("format", text(@cg.profile_version())),
    (
      "parts",
      Json::array(
        p.parts.map(part => {
          obj([
            ("events", Json::array(part.events.map(text))),
            ("positions", Json::array(part.positions.map(text))),
            (
              "headers",
              Json::array(
                part.headers.map(h => {
                  obj([
                    ("key", text(h.key)),
                    ("value", text(h.value)),
                    ("line", index(h.line)),
                  ])
                }),
              ),
            ),
          ])
        }),
      ),
    ),
    (
      "records",
      Json::array(
        p.records.map(r => {
          let kind = match r.kind {
            SelfCost => obj([("type", text("self"))])
            Call(count, target, positions) =>
              obj([
                ("type", text("call")),
                ("count", text(count.to_string())),
                ("target", context(target)),
                ("targetPositions", exact(positions)),
              ])
          }
          obj([
            ("part", index(r.part)),
            ("line", index(r.line)),
            ("context", context(r.context)),
            ("positions", exact(r.positions)),
            ("values", exact(r.values)),
            ("kind", kind),
          ])
        }),
      ),
    ),
  ])
}

///|
fn failure(kind : String, line : Int32, message : String) -> Json {
  let detail = obj([
    ("kind", text(kind)),
    ("line", index(line)),
    ("message", text(message)),
  ])
  obj([("ok", Json::boolean(false)), ("error", detail)])
}

///|
/// Host transport only; all format interpretation and analysis is MoonBit.
pub fn run(
  operation : String,
  input : String,
  other : String,
  event : String,
) -> String {
  let result = try {
    let value = match operation {
      "inspect" => profile_json(@cg.parse(input))
      "normalize" => text(@cg.normalize(input))
      "totals" =>
        Json::array(
          @cg.parse(input)
          .self_totals(event)
          .map(t => {
            obj([
              ("object", text(t.object)),
              ("file", text(t.file)),
              ("function", text(t.function_name)),
              ("value", text(t.value.to_string())),
            ])
          }),
        )
      "diff" =>
        Json::array(
          @cg.diff(@cg.parse(input), @cg.parse(other), event).map(c => {
            obj([
              ("object", text(c.object)),
              ("file", text(c.file)),
              ("function", text(c.function_name)),
              ("before", text(c.before.to_string())),
              ("after", text(c.after.to_string())),
            ])
          }),
        )
      _ => raise @cg.Unsupported(0, "unknown operation")
    }
    obj([("ok", Json::boolean(true)), ("value", value)])
  } catch {
    @cg.Syntax(line, message) => failure("syntax", line, message)
    @cg.Unsupported(line, message) => failure("unsupported", line, message)
    @cg.Resource(line, message) => failure("resource", line, message)
  }
  result.stringify()
}
