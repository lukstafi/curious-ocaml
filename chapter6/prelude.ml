(* Chapter 6 prelude - composition operators and common utilities *)

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

(* concat_map: map then flatten *)
let concat_map f l = List.concat (List.map f l)

(* Range function *)
let rec fromto a b = if a > b then [] else a :: fromto (a + 1) b

(* Set intersection for sorted lists *)
let intersect xs ys =
  let rec aux acc = function
    | [], _ | _, [] -> acc
    | (x::xs' as xs), (y::ys' as ys) ->
      let c = compare x y in
      if c = 0 then aux (x::acc) (xs', ys')
      else if c < 0 then aux acc (xs', ys)
      else aux acc (xs, ys') in
  List.rev (aux [] (xs, ys))

(* Map/bind for option type *)
let map_option f = function
  | None -> None
  | Some e -> f e

(* List difference *)
let rec list_diff l1 l2 =
  match l1 with
  | [] -> []
  | x::xs ->
    if List.mem x l2 then list_diff xs (List.filter ((<>) x) l2)
    else x :: list_diff xs l2

(* Check if list has unique elements *)
let is_unique l =
  let rec check seen = function
    | [] -> true
    | x::xs -> not (List.mem x seen) && check (x::seen) xs
  in check [] l

(* All subsequences of a list *)
let rec subs = function
  | [] -> [[]]
  | x::xs -> let rest = subs xs in rest @ List.map (fun ys -> x::ys) rest

(* All permutations of a list *)
let rec interleave x = function
  | [] -> [[x]]
  | y::ys -> (x::y::ys) :: List.map (fun zs -> y::zs) (interleave x ys)

let rec perms = function
  | [] -> [[]]
  | x::xs -> concat_map (interleave x) (perms xs)

(* All choices: non-empty subsequences with permutations *)
let choices l = concat_map perms (List.filter ((<>) []) (subs l))

(* Countdown problem types *)
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

(* Split a list into two non-empty parts *)
let split l =
  let rec aux lhs acc = function
    | [] | [_] -> []
    | [y; z] -> (List.rev (y::lhs), [z])::acc
    | hd::rhs ->
      let lhs = hd::lhs in
      aux lhs ((List.rev lhs, rhs)::acc) rhs in
  aux [] [] l

(* Operator for working with multiple data sources *)
let ( |-> ) x f = concat_map f x

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

(* Filter expressions by target value *)
let guard n =
  List.filter (fun e -> eval e = Some n)

(* Find all solutions *)
let solutions ns n =
  choices ns |-> (fun ns' ->
    exprs ns' |> guard n)

(* MapReduce style concat_reduce *)
let concat_reduce mapf reducef base l =
  List.fold_left reducef base (concat_map mapf l)

(* cons helper *)
let cons x xs = x :: xs

(* Guard function for filtering - single element version *)
let pred_guard pred x = if pred x then [x] else []

(* Remove element from list *)
let remove x l = List.filter ((<>) x) l

(* Honey Islands puzzle types and functions *)
type cell = int * int

module CellSet =
  Set.Make (struct type t = cell let compare = compare end)

let cellset_of_list l =
  List.fold_right CellSet.add l CellSet.empty

let even x = x mod 2 = 0

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
