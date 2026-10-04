(* A monadic syntax for the same operations, interpreted by the teaching runtime.
   Bind builds a program; it does not run an action during construction. *)
type 'a t =
  | Return : 'a -> 'a t
  | Bind : 'b t * ('b -> 'a t) -> 'a t
  | Action : (unit -> 'a) -> 'a t
  | Yield : unit t
  | Spawn : unit t -> Runtime.task t
  | Await : Runtime.task -> unit t
  | Cancel : Runtime.task -> unit t
  | Protect : 'a t * (unit -> unit) -> 'a t

let return x = Return x
let ( let* ) m f = Bind (m,f)
let rec interpret : type a. a t -> a = function
  | Return x -> x
  | Bind (m,f) -> let x = interpret m in interpret (f x)
  | Action f -> f ()
  | Yield -> Runtime.yield ()
  | Spawn m -> Runtime.spawn (fun () -> interpret m)
  | Await task -> Runtime.await task
  | Cancel task -> Runtime.cancel task
  | Protect (m, release) -> Fun.protect ~finally:release (fun () -> interpret m)
let run m = Runtime.run (fun () -> interpret m)
