# Data and analysis contract

`Profile.parts` holds per-part event/position orders and metadata. Records stay in
input order. `Record.part` is a zero-based index; `line` is the one-based cost-line
number. Position/cost arrays align with that part's field lists.

`Context.object`, `file`, `function_name` identify a function; `cost_file` tracks inline
`fi`/`fe` positions without replacing the defining file. A `Call(count,target,positions)`
retains UInt64 call count, resolved target and target positions. Self recursion stays a
call. Its inclusive edge costs must not be added to `SelfCost` records.

`self_totals` uses each part's event-name mapping and sums only self costs by
`(object,file,function_name)`, in first-seen order. It combines parts; consumers needing
thread-specific results should select records by part. Unknown physical events fail
rather than becoming zero. Counter sums raise `Resource` before overflow.

`diff` compares function identities and returns UInt64 before/after values. Missing
functions become zero; no signed cast/subtraction occurs. The same event name does not
prove comparable units, builds, workloads or collection settings. No regression verdict
or statistical significance is inferred.

Public arrays are mutable; do not mutate during an operation. Analysis validates part
indices and cost-array lengths before indexing, not every metadata field or concurrent
mutation. Text normalization reparses input rather than accepting a mutated model.

The JS bridge serializes all UInt64 values as decimal strings. Bounded part/line indices
use JSON numbers. Floating-point cost arithmetic is absent from the core.
