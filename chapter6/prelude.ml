(* Chapter 6 prelude - minimal operators and utilities *)

#require "bogue";;

(* Reverse function composition: (f -| g) x = f (g x) *)
let (-|) f g x = f (g x)

(* Forward function composition: (f |- g) x = g (f x) *)
let (|-) f g x = g (f x)

(* Identity function *)
let id x = x

(* Flip arguments *)
let flip f x y = f y x

(* Uncurry a function *)
let uncurry f (x, y) = f x y

(* Curry a function *)
let curry f x y = f (x, y)

(* List difference - needed for Countdown problem *)
let rec list_diff l1 l2 =
  match l1 with
  | [] -> []
  | x::xs ->
    if List.mem x l2 then list_diff xs (List.filter ((<>) x) l2)
    else x :: list_diff xs l2

(* Check if list has unique elements - needed for Countdown problem *)
let is_unique l =
  let rec check seen = function
    | [] -> true
    | x::xs -> not (List.mem x seen) && check (x::seen) xs
  in check [] l

(* Range function - used throughout chapter *)
let rec fromto a b = if a > b then [] else a :: fromto (a + 1) b

(* Guard function for filtering - single element version *)
let pred_guard pred x = if pred x then [x] else []

(* Remove element from list *)
let remove x l = List.filter ((<>) x) l

(* Honey Islands types and basic functions *)
type cell = int * int

module CellSet =
  Set.Make (struct type t = cell let compare = compare end)

let cellset_of_list l =
  List.fold_right CellSet.add l CellSet.empty

let even x = x mod 2 = 0
