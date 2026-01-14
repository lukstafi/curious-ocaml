(* Chapter 8 prelude - minimal operators and Countdown types *)

(* Basic utilities *)
let flip f x y = f y x
let id x = x
let const x _ = x

(* Composition operators *)
let (-|) f g x = f (g x)
let (|-) f g x = g (f x)

(* concat_map: use stdlib version *)
let concat_map = List.concat_map

(* The |-> operator for multiple data sources *)
let ( |-> ) x f = concat_map f x

(* Countdown problem types from chapter 6 - needed for opening examples *)
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

(* List difference - needed for probability examples *)
let rec list_diff l1 l2 =
  match l1 with
  | [] -> []
  | x::xs ->
    if List.mem x l2 then list_diff xs (List.filter ((<>) x) l2)
    else x :: list_diff xs l2

(* Honey Islands types and functions - needed for backtracking examples *)
type cell = int * int

module CellSet =
  Set.Make (struct type t = cell let compare = compare end)

let cellset_of_list l =
  List.fold_right CellSet.add l CellSet.empty

let even x = x mod 2 = 0

(* Range function *)
let rec fromto a b = if a > b then [] else a :: fromto (a + 1) b

(* Guard function for filtering - single element version *)
let pred_guard pred x = if pred x then [x] else []

let inside_board n eaten (x, y) =
  even x = even y && abs y <= n &&
  abs x + abs y <= 2*n &&
  not (CellSet.mem (x, y) eaten)

let neighbors n eaten (x, y) =
  List.filter
    (inside_board n eaten)
    [x-1,y-1; x+1,y-1; x+2,y;
     x+1,y+1; x-1,y+1; x-2,y]

let honey_cells n eaten =
  fromto (-2*n) (2*n) |-> (fun x ->
    fromto (-n) n |-> (fun y ->
     pred_guard (inside_board n eaten)
        (x, y)))
