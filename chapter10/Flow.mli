(* Flows are "state machines"  *)

type ('a, 'b) flow
type cancellable
val noop_flow : ('a, unit) flow
val return : 'b -> ('a, 'b) flow
val await : 'b Froc.event -> ('a, 'b) flow
val bind :
  ('a, 'b) flow -> ('b -> ('a, 'c) flow) -> ('a, 'c) flow
val emit : 'a -> ('a, unit) flow
val cancel : cancellable -> unit
val repeat :
  ?until:'a Froc.event -> ('b, unit) flow -> ('b, 'a) flow
val local : ('a -> 'b) -> ('a, 'c) flow -> ('b, 'c) flow
val local_opt : ('a -> 'b option) -> ('a, 'c) flow -> ('b, 'c) flow
val event_flow :
  ('a, unit) flow -> 'a Froc.event * cancellable
val behavior_flow :
  'a -> ('a, unit) flow -> 'a Froc.behavior * cancellable
val is_cancelled : cancellable -> bool
