(** A single-domain teaching scheduler. Cancellation is cooperative: task code
    must not swallow Cancelled indefinitely, and cleanup must not suspend. *)
type task
exception Cancelled
exception Deadlock
val run : (unit -> unit) -> unit
val spawn : (unit -> unit) -> task
val yield : unit -> unit
val await : task -> unit
val cancel : task -> unit
