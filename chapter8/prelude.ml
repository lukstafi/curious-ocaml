(* Chapter 8 prelude - Monads and related utilities *)

(* Basic utilities *)
let flip f x y = f y x
let id x = x
let const x _ = x

(* Composition operators *)
let (-|) f g x = f (g x)
let (|-) f g x = g (f x)

(* concat_map: map then flatten - use stdlib version *)
let concat_map = List.concat_map

(* Binding operators for the list monad (OCaml 5 style) *)
let ( let* ) x f = concat_map f x      (* bind *)
let ( let+ ) x f = List.map f x        (* map/fmap *)
let ( and* ) x y = concat_map (fun a -> List.map (fun b -> (a, b)) y) x
let ( and+ ) = ( and* )
let return x = [x]
let fail = []

(* The |-> operator for multiple data sources *)
let ( |-> ) x f = concat_map f x

(* Range function *)
let rec from_to a b = if a > b then [] else a :: from_to (a + 1) b

(* Countdown problem types from chapter 6 *)
type op = Add | Sub | Mul | Div

let apply op x y =
  match op with
  | Add -> x + y
  | Sub -> x - y
  | Mul -> x * y
  | Div -> x / y

let valid op x y =
  match op with
  | Add -> true
  | Sub -> x > y
  | Mul -> true
  | Div -> x mod y = 0

type expr = Val of int | App of op * expr * expr

let map_option f = function
  | None -> None
  | Some e -> f e

let rec eval = function
  | Val n -> if n > 0 then Some n else None
  | App (o, l, r) ->
    eval l |> map_option (fun x ->
      eval r |> map_option (fun y ->
      if valid o x y then Some (apply o x y)
      else None))

let rec values = function
  | Val n -> [n]
  | App (_, l, r) -> values l @ values r

(* Subsequences *)
let rec subs = function
  | [] -> [[]]
  | x::xs -> let rest = subs xs in rest @ List.map (fun ys -> x::ys) rest

(* Permutations *)
let rec interleave x = function
  | [] -> [[x]]
  | y::ys -> (x::y::ys) :: List.map (fun zs -> y::zs) (interleave x ys)

let rec perms = function
  | [] -> [[]]
  | x::xs -> concat_map (interleave x) (perms xs)

(* Choices: non-empty subsequences with permutations *)
let choices l = concat_map perms (List.filter ((<>) []) (subs l))

(* Split a list into two non-empty parts *)
let split l =
  let rec aux lhs acc = function
    | [] | [_] -> []
    | [y; z] -> (List.rev (y::lhs), [z])::acc
    | hd::rhs ->
      let lhs = hd::lhs in
      aux lhs ((List.rev lhs, rhs)::acc) rhs in
  aux [] [] l

(* Combine two expressions using each operator *)
let combine l r =
  List.map (fun o -> App (o, l, r)) [Add; Sub; Mul; Div]

(* Generate all expressions from numbers *)
let rec exprs = function
  | [] -> []
  | [n] -> [Val n]
  | ns ->
    split ns |-> (fun (ls, rs) ->
      exprs ls |-> (fun l ->
        exprs rs |-> (fun r ->
          combine l r)))

(* Guard function for filtering *)
let guard pred = List.filter pred

(* Find all solutions *)
let solutions ns n =
  choices ns |-> (fun ns' ->
    exprs ns' |> guard (fun e -> eval e = Some n))
