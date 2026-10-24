///|
pub(all) suberror ParseError {
  Syntax(Int32, String)
  Unsupported(Int32, String)
  Resource(Int32, String)
} derive(Debug)

///|
pub extend ParseError with @debug.Debug::{to_repr}

///|
/// Function identity and the actual source file of this record (including inlining).
pub(all) struct Context {
  object : String
  file : String
  function_name : String
  cost_file : String
} derive(Eq, Debug)

///|
pub(all) struct Header {
  key : String
  value : String
  line : Int32
} derive(Eq, Debug)

///|
/// Physical event order and subposition order are local to each dump part.
pub(all) struct Part {
  headers : Array[Header]
  events : Array[String]
  positions : Array[String]
} derive(Eq, Debug)

///|
/// Call records retain the count, target identity and target subpositions.
pub(all) enum RecordKind {
  SelfCost
  Call(UInt64, Context, Array[UInt64])
} derive(Eq, Debug)

///|
/// Values are raw counters, not time estimates. Costs of calls are not self costs.
pub(all) struct Record {
  part : Int32
  line : Int32
  context : Context
  positions : Array[UInt64]
  values : Array[UInt64]
  kind : RecordKind
} derive(Eq, Debug)

///|
/// Arrays are caller-owned; do not mutate them during an operation.
pub(all) struct Profile {
  parts : Array[Part]
  records : Array[Record]
} derive(Eq, Debug)

///|
pub(all) struct Total {
  object : String
  file : String
  function_name : String
  value : UInt64
} derive(Eq, Debug)

///|
pub(all) struct Change {
  object : String
  file : String
  function_name : String
  before : UInt64
  after : UInt64
} derive(Eq, Debug)

///|
fn empty_context() -> Context {
  { object: "", file: "", function_name: "", cost_file: "", }
}

///|
pub fn profile_version() -> String {
  "callgrind-records-v1"
}

///|
pub extend Context with Eq::{equal, not_equal}

///|
pub extend Context with @debug.Debug::{to_repr}

///|
pub extend Header with Eq::{equal, not_equal}

///|
pub extend Header with @debug.Debug::{to_repr}

///|
pub extend Part with Eq::{equal, not_equal}

///|
pub extend Part with @debug.Debug::{to_repr}

///|
pub extend RecordKind with Eq::{equal, not_equal}

///|
pub extend RecordKind with @debug.Debug::{to_repr}

///|
pub extend Record with Eq::{equal, not_equal}

///|
pub extend Record with @debug.Debug::{to_repr}

///|
pub extend Profile with Eq::{equal, not_equal}

///|
pub extend Profile with @debug.Debug::{to_repr}

///|
pub extend Total with Eq::{equal, not_equal}

///|
pub extend Total with @debug.Debug::{to_repr}

///|
pub extend Change with Eq::{equal, not_equal}

///|
pub extend Change with @debug.Debug::{to_repr}
