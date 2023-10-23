(* Download "froc" from https://github.com/jaked/froc/downloads *)
(* cd froc-0.2a; ./configure; make all; sudo make install *)
(* *
#directory "+froc";;
#load "froc.cma";;
* *)

module F = Froc
type 'a result =
| Return of 'a
| Sleep of ('a -> unit) list * F.cancel ref list
| Cancelled
| Link of 'a state
and 'a state = {mutable state : 'a result}
type cancellable = unit state

let rec find t =
  match t.state with
  | Link t -> find t
  | _ -> t

(* since OCaml 4.0: external (|>) : 'a -> ('a -> 'b) -> 'b = "%revapply" *)
let ( |> ) x f = f x

let wakeup m a =
  let m = find m in
  match m.state with
  | Cancelled | Return _ | Link _ -> assert false
  | Sleep (waiters, _) ->
    m.state <- Return a;
    List.iter ((|>) a) waiters

let cancel a =
  let a = find a in
  (match a.state with
  | Cancelled | Return _ -> ()
  | Sleep (_, cancels) ->
    List.iter (fun c -> F.cancel !c) cancels
  | Link _ -> assert false);
  a.state <- Cancelled

let is_cancelled m = m.state = Cancelled

let connect t t' =
  let t' = find t' and t = find t in
  match t, t' with
  | {state=Cancelled}, t | t, {state=Cancelled} -> cancel t
  | _ ->
    match t'.state with
    | Sleep (waiters', cancels') ->
      let t = find t in
      (match t.state with
      | Sleep (waiters, cancels) ->
        t.state <- Sleep (waiters' @ waiters, cancels' @ cancels);
        t'.state <- Link t
      | _ -> assert false)
    | Return x ->
      wakeup t x
    | Link _ | Cancelled -> assert false

type ('a, 'b) flow = ('a -> unit) -> 'b state

let noop_flow = fun _ -> {state = Return ()}
let return x = fun _ -> {state = Return x}

let await t = fun emit ->
  let c = ref F.no_cancel in
  let m = {state=Sleep ([], [c])} in
  c :=
    F.notify_e_cancel t begin fun r ->
      F.cancel !c;
      c := F.no_cancel;
      wakeup m r
    end;
  m

let bind a b = fun emit ->
  let a = find (a emit) in
  let m = {state=Sleep ([], [])} in
  (match a.state with
  | Cancelled -> cancel m
  | Return x -> connect m (b x emit)
  | Sleep (xwaiters,xcancels) ->
    let waiter x =
      if not (is_cancelled m)
      then connect m (b x emit) in
    a.state <- Sleep (waiter::xwaiters, xcancels)
  | Link _ -> assert false);
  m

let emit x = fun emit -> {state=Return (emit x)}

let repeat ?(until=F.never) fa =
  fun emit ->
    let c = ref F.no_cancel in
    let out = {state=Sleep ([], [c])} in
    let cancel_body = ref {state=Cancelled} in
    c :=
      F.notify_e_cancel until begin fun tv ->
        F.cancel !c;
        c := F.no_cancel;
        cancel !cancel_body; wakeup out tv
      end;
    let rec loop () =
      let a = find (fa emit) in
      cancel_body := a;
      (match a.state with
      | Cancelled -> cancel out; F.cancel !c
      | Return x ->
        failwith "loop_until: not implemented for unsuspended flows"
      | Sleep (xwaiters, xcancels) ->
        a.state <- Sleep (loop::xwaiters, xcancels)
      | Link _ -> assert false) in
    loop (); out

let local f m = fun emit -> m (fun x -> emit (f x))

let local_opt f m = fun emit ->
  m (fun x -> match f x with None -> () | Some y -> emit y)

let event_flow m =
  let e, s = F.make_event () in
  e, m (F.send s)

let behavior_flow init m =
  let e, s = F.make_cell init in
  e, m s
