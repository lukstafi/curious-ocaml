module type PROGRAM = sig
  type 'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val action : (unit -> 'a) -> 'a t
  val yield : unit t
  val spawn : unit t -> Runtime.task t
  val await : Runtime.task -> unit t
  val cancel : Runtime.task -> unit t
  val protect : unit t -> (unit -> unit) -> unit t
  val run : unit t -> unit
end
module Direct = struct
  type 'a t = unit -> 'a
  let return x () = x
  let bind m f () = let x = m () in f x ()
  let action f = f
  let yield = Runtime.yield
  let spawn m () = Runtime.spawn m
  let await t () = Runtime.await t
  let cancel t () = Runtime.cancel t
  let protect m release () = Fun.protect ~finally:release m
  let run = Runtime.run
end
module Monadic = struct
  type 'a t = 'a Script.t
  let return = Script.return
  let bind m f = Script.Bind (m,f)
  let action f = Script.Action f
  let yield = Script.Yield
  let spawn m = Script.Spawn m
  let await t = Script.Await t
  let cancel t = Script.Cancel t
  let protect m f = Script.Protect (m,f)
  let run = Script.run
end
module Checks (P : PROGRAM) = struct
  let ( let* ) = P.bind
  let run () =
    let events = ref [] and released = ref 0 in
    let emit x = P.action (fun () -> events := x :: !events) in
    let worker name =
      let* () = emit (name ^ "1") in
      let* () = P.yield in emit (name ^ "2") in
    P.run (let* a = P.spawn (worker "A") in
      let* b = P.spawn (worker "B") in
      let* () = P.await a in P.await b);
    assert (List.rev !events = ["A1";"B1";"A2";"B2"]);
    let protected = P.protect
      (let* () = emit "open" in let* () = P.yield in emit "too late")
      (fun () -> incr released) in
    (* A yielding child is cancelled on scope exit. *)
    P.run (let* _ = P.spawn protected in P.yield);
    assert (!released = 1);
    assert (not (List.mem "too late" !events));
    P.run (let* child = P.spawn protected in
      let* () = P.yield in let* () = P.cancel child in P.cancel child);
    assert (!released = 2);
    (* Cancelling a not-yet-started child acquires no resources. *)
    P.run (let* child = P.spawn protected in P.cancel child);
    assert (!released = 2);
    (* Child failure cancels a sibling and propagates the original failure. *)
    let failed = try
      P.run (let* _ = P.spawn protected in
        let* bad = P.spawn (P.action (fun () -> failwith "child")) in P.await bad);
      false
    with Failure s -> s = "child" in
    assert failed;
    assert (!released = 3);
    let nested = P.action (fun () -> P.run (P.return ())) in
    P.run (let* () = nested in P.yield)
end
module D = Checks (Direct)
module M = Checks (Monadic)
let () =
  D.run (); M.run ();
  let escaped = ref None in
  Runtime.run (fun () -> escaped := Some (Runtime.spawn (fun () -> ())));
  let foreign = try
    Runtime.run (fun () -> Runtime.await (Option.get !escaped)); false
    with Invalid_argument _ -> true in
  assert foreign;
  let released = ref 0 in
  let deadlocked = try
    Runtime.run (fun () ->
      let self = ref None in
      let child = Runtime.spawn (fun () ->
        Fun.protect ~finally:(fun () -> incr released)
          (fun () -> Runtime.await (Option.get !self))) in
      self := Some child;
      Runtime.await child);
    false
    with Runtime.Deadlock -> true in
  assert deadlocked;
  assert (!released = 1)
