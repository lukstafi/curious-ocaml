(* Bound variables use de Bruijn indices: zero is the nearest enclosing binder. *)
(* $MDX part-begin=terms *)
type t = Bound of int | Free of string | Lam of t | App of t * t

let rec shift amount cutoff = function
  | Bound k -> Bound (if k >= cutoff then k + amount else k)
  | Free _ as x -> x
  | Lam body -> Lam (shift amount (cutoff + 1) body)
  | App (f, x) -> App (shift amount cutoff f, shift amount cutoff x)

let rec substitute index value = function
  | Bound k as x -> if k = index then value else x
  | Free _ as x -> x
  | Lam body -> Lam (substitute (index + 1) (shift 1 0 value) body)
  | App (f, x) -> App (substitute index value f, substitute index value x)

let beta body argument =
  shift (-1) 0 (substitute 0 (shift 1 0 argument) body)
(* $MDX part-end *)

(* $MDX part-begin=strategies *)
let rec normal_step = function
  | App (Lam body, argument) -> Some (beta body argument)
  | App (f, x) ->
    (match normal_step f with
     | Some f' -> Some (App (f', x))
     | None -> Option.map (fun x' -> App (f, x')) (normal_step x))
  | Lam body -> Option.map (fun body -> Lam body) (normal_step body)
  | Bound _ | Free _ -> None

let rec value_step = function
  | App (Lam body, (Lam _ as argument)) -> Some (beta body argument)
  | App ((Lam _ as f), x) ->
    Option.map (fun x -> App (f, x)) (value_step x)
  | App (f, x) -> Option.map (fun f -> App (f, x)) (value_step f)
  | Bound _ | Free _ | Lam _ -> None

type result = Done of t | Limit of t
let reduce ~fuel step term =
  if fuel < 0 then invalid_arg "negative reduction fuel";
  let rec loop fuel term =
    match step term with
    | None -> Done term
    | Some _ when fuel = 0 -> Limit term
    | Some term -> loop (fuel - 1) term in
  loop fuel term
(* $MDX part-end *)

let well_scoped term =
  let rec check depth = function
    | Bound k -> k >= 0 && k < depth
    | Free _ -> true
    | Lam t -> check (depth + 1) t
    | App (f,x) -> check depth f && check depth x in
  check 0 term
