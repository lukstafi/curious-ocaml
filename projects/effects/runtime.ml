open Effect
open Effect.Deep

exception Cancelled
exception Deadlock

type task = {
  owner : int;
  mutable state : state;
  mutable cancelled : bool;
  mutable queued : bool;
  mutable waiters : task list;
}
and state =
  | New of (unit -> unit)
  | Running
  | Paused of suspension
  | Finished of (unit, exn) result
and suspension = { resume : unit -> unit; abort : exn -> unit }

type _ Effect.t +=
  | Spawn : (unit -> unit) -> task Effect.t
  | Yield : unit Effect.t
  | Await : task -> unit Effect.t
  | Cancel : task -> unit Effect.t

let spawn f = perform (Spawn f)
let yield () = perform Yield
let await task = perform (Await task)
let cancel task = perform (Cancel task)
let next_owner = ref 0

let run main =
  incr next_owner;
  let owner = !next_owner in
  let queue = Queue.create () and tasks = ref [] and failure = ref None in
  let enqueue task =
    match task.state with
    | Finished _ | Running -> ()
    | New _ | Paused _ ->
      if not task.queued then (task.queued <- true; Queue.add task queue) in
  let create f =
    let task = {owner; state=New f; cancelled=false; queued=false; waiters=[]} in
    tasks := task :: !tasks; enqueue task; task in
  let finish task result =
    task.state <- Finished result;
    (match result with
     | Error Cancelled | Ok () -> ()
     | Error exn -> if !failure = None then failure := Some exn);
    List.iter enqueue (List.rev task.waiters);
    task.waiters <- [] in
  let rec stop task =
    task.cancelled <- true;
    match task.state with
    | Finished _ -> ()
    | New _ -> finish task (Error Cancelled)
    | Running -> () (* Delivered at the next scheduler operation. *)
    | Paused continuation ->
      task.state <- Running; (* Consume the ownership slot before resuming. *)
      continuation.abort Cancelled
  and start task f =
    match_with f () {
      retc = (fun () -> finish task (Ok ()));
      exnc = (fun exn -> finish task (Error exn));
      effc = (fun (type a) (operation : a Effect.t) ->
        match operation with
        | Yield -> Some (fun (k : (a, unit) continuation) ->
          if task.cancelled then discontinue k Cancelled
          else begin
            task.state <- Paused {
              resume=(fun () -> continue k ());
              abort=(fun exn -> discontinue k exn)};
            enqueue task
          end)
        | Spawn f -> Some (fun (k : (a, unit) continuation) ->
          if task.cancelled then discontinue k Cancelled
          else let child = create f in continue k child)
        | Cancel target -> Some (fun (k : (a, unit) continuation) ->
          if target.owner <> owner then
            discontinue k (Invalid_argument "task belongs to another run")
          else if target == task || task.cancelled then begin
            task.cancelled <- true; discontinue k Cancelled
          end else (stop target; continue k ()))
        | Await target -> Some (fun (k : (a, unit) continuation) ->
          if target.owner <> owner then
            discontinue k (Invalid_argument "task belongs to another run")
          else if task.cancelled then discontinue k Cancelled
          else
            let resume () = match target.state with
              | Finished (Ok ()) -> continue k ()
              | Finished (Error exn) -> discontinue k exn
              | _ -> failwith "scheduler resumed an unfinished await" in
            (match target.state with
             | Finished _ -> resume ()
             | _ ->
               task.state <- Paused {resume; abort=(fun exn -> discontinue k exn)};
               target.waiters <- task :: target.waiters))
        | _ -> None)
    }
  in
  let root = create main in
  let rec drive () =
    match !failure, root.state with
    | Some _, _ | _, Finished _ -> ()
    | None, _ when Queue.is_empty queue -> failure := Some Deadlock
    | None, _ ->
      let task = Queue.take queue in
      task.queued <- false;
      (match task.state with
       | New f -> task.state <- Running; start task f
       | Paused continuation -> task.state <- Running; continuation.resume ()
       | Running | Finished _ -> ());
      drive () in
  (* Scope exit cancels children, including blocked awaiters. *)
  Fun.protect ~finally:(fun () -> List.iter stop !tasks) drive;
  match !failure, root.state with
  | Some exn, _ -> raise exn
  | None, Finished (Ok ()) -> ()
  | None, Finished (Error exn) -> raise exn
  | _ -> raise Deadlock
