(* Basic operators *)
let ( |> ) x f = f x
let ( <| ) f x = f x
let ( |- ) f g x = g (f x)
let ( -| ) f g x = f (g x)
let flip f x y = f y x
let id x = x
let ( *** ) f g = fun (x,y) -> (f x, g y)
let ( &&& ) f g = fun x -> (f x, g x)
let first f x = fst (f x)
let second f x = snd (f x)
let curry f x y = f (x,y)
let uncurry f (x,y) = f x y
let const x _ = x
let s x y z = x z (y z)

(* ********** Basic generic list operations ********** *)
let rec strings_of_ints = function
  | [] -> []
  | hd::tl -> string_of_int hd :: strings_of_ints tl
let comma_sep_ints = String.concat ", " -| strings_of_ints

let rec strings_lengths = function
  | [] -> []
  | hd::tl -> (String.length hd, hd) :: strings_lengths tl
let by_size = List.sort compare -| strings_lengths

let rec list_map f = function
  | [] -> []
  | hd::tl -> f hd :: list_map f tl

let comma_sep_ints =
  String.concat ", " -| list_map string_of_int
let by_size =
  List.sort compare -| list_map (fun s->String.length s, s)

let rec balance = function
  | [] -> 0
  | hd::tl -> hd + balance tl

let rec total_ratio = function
  | [] -> 1.
  | hd::tl -> hd *. total_ratio tl

let rec list_fold f base = function
  | [] -> base
  | hd::tl -> f hd (list_fold f base tl)

let rec list_rev acc = function
  | [] -> acc
  | hd::tl -> list_rev (hd::acc) tl

let rec average (sum, tot) = function
  | [] when tot = 0. -> 0.
  | [] -> sum /. tot
  | hd::tl -> average (hd +. sum, 1. +. tot) tl

let rec fold_left f accu = function
  | [] -> accu
  | a::l -> fold_left f (f accu a) l

let list_rev l =
  fold_left (fun t h->h::t) [] l
let average =
  fold_left (fun (sum,tot) e->sum +. e, 1. +. tot) (0.,0.)

let list_filter p l =
  List.fold_right (fun h t->if p h then h::t else t) l []
let list_rev_map f l =
  List.fold_left (fun t h->f h::t) [] l

(* ********** [map] and [fold] for trees and other data structures *)

type 'a btree = Empty | Node of 'a * 'a btree * 'a btree
    
let rec bt_map f = function
  | Empty -> Empty
  | Node (e, l, r) -> Node (f e, bt_map f l, bt_map f r)
(*  
let test = Node
  (3, Node (5, Empty, Empty), Node (7, Empty, Empty))
let _ = bt_map ((+) 1) test
*)
let rec bt_fold f base = function
  | Empty -> base
  | Node (e, l, r) ->
    f e (bt_fold f base l) (bt_fold f base r)

let sum_els = bt_fold (fun i l r -> i + l + r) 0
let depth t = bt_fold (fun _ l r -> 1 + max l r) 1 t

(* ********** [map] and [fold] for more complex structures *)

type expression =
     Const of float
   | Var of string
   | Sum of expression * expression    (* e1 + e2 *)
   | Diff of expression * expression   (* e1 - e2 *)
   | Prod of expression * expression   (* e1 * e2 *)
   | Quot of expression * expression   (* e1 / e2 *)

let rec vars = function
  | Const _ -> []
  | Var x -> [x]
  | Sum (a,b) | Diff (a,b) | Prod (a,b) | Quot (a,b) ->
    vars a @ vars b

type expression_map = {
  map_const : float -> expression;
  map_var : string -> expression;
  map_sum : expression -> expression -> expression;
  map_diff : expression -> expression -> expression;
  map_prod : expression -> expression -> expression;
  map_quot : expression -> expression -> expression;
}

type 'a expression_fold = {
  fold_const : float -> 'a;
  fold_var : string -> 'a;
  fold_sum : 'a -> 'a -> 'a;
  fold_diff : 'a -> 'a -> 'a;
  fold_prod : 'a -> 'a -> 'a;
  fold_quot : 'a -> 'a -> 'a;
}

let identity_map = {
  map_const = (fun c -> Const c);
  map_var = (fun x -> Var x);
  map_sum = (fun a b -> Sum (a, b));
  map_diff = (fun a b -> Diff (a, b));
  map_prod = (fun a b -> Prod (a, b));
  map_quot = (fun a b -> Quot (a, b));
}

let make_fold op base = {
  fold_const = (fun _ -> base);
  fold_var = (fun _ -> base);
  fold_sum = op; fold_diff = op;
  fold_prod = op; fold_quot = op;
}

let rec expr_map emap = function
  | Const c -> emap.map_const c
  | Var x -> emap.map_var x
  | Sum (a,b) -> emap.map_sum (expr_map emap a) (expr_map emap b)
  | Diff (a,b) -> emap.map_diff (expr_map emap a) (expr_map emap b)
  | Prod (a,b) -> emap.map_prod (expr_map emap a) (expr_map emap b)
  | Quot (a,b) -> emap.map_quot (expr_map emap a) (expr_map emap b)

let rec expr_fold efold = function
  | Const c -> efold.fold_const c
  | Var x -> efold.fold_var x
  | Sum (a,b) -> efold.fold_sum (expr_fold efold a) (expr_fold efold b)
  | Diff (a,b) -> efold.fold_diff (expr_fold efold a) (expr_fold efold b)
  | Prod (a,b) -> efold.fold_prod (expr_fold efold a) (expr_fold efold b)
  | Quot (a,b) -> efold.fold_quot (expr_fold efold a) (expr_fold efold b)

let prime_vars = expr_map
  {identity_map with map_var = fun x -> Var (x^"'")}

let subst s =
  let apply x = try List.assoc x s with Not_found -> Var x in
  expr_map {identity_map with map_var = apply}

let vars =
  expr_fold {(make_fold (@) []) with fold_var = fun x-> [x]}

let size = expr_fold (make_fold (fun a b->1+a+b) 1)

let eval env = expr_fold {
  fold_const = id;
  fold_var = (fun x -> List.assoc x env);
  fold_sum = (+.); fold_diff = (-.);
  fold_prod = ( *.); fold_quot = (/.);
}
(*
let example = Sum (Var "x", Prod (Const 2., Var "y"))
let _ = prime_vars example
let _ = subst ["x", Sum (Const 1., Var "y")] example
let _ = vars example
let _ = eval ["x", 1.; "y", 3.] example
*)
(* ********** Point-free programming ********** *)

(* Circuit-as-transforming-tuples example *)

let print2 c i =
  let a = Char.escaped c in
  let b = string_of_int i in
  a ^ b

let print2 = curry
  ((Char.escaped *** string_of_int) |- uncurry (^))

(* Eliminating explicit parameters *)

let func2 f g l = List.filter f (List.map g (l))

let func2 f g = (-|) (List.filter f) (List.map g)
let func2 f = (-|) (List.filter f) -| List.map

let func2 f = (-|) ((-|) (List.filter f)) List.map
let func2 f = flip (-|) List.map ((-|) (List.filter f))
let func2 f = (((|-) List.map) -| ((-|) -| List.filter)) f
let func2 = (|-) List.map -| ((-|) -| List.filter)

(* From a Haskell mailing list.

Julien Oster wrote:
> While we're at it: The best thing I could come up for
> 
> func2 f g l = filter f (map g l)
> 
> is
> 
> func2p f g = (filter f) . (map g)
> 
> Which isn't exactly point-_free_. Is it possible to reduce that further?

Sure it is:

func2 f g l = filter f (map g l)
func2 f g = (filter f) . (map g)	-- definition of (.)
func2 f g = ((.) (filter f)) (map g)	-- desugaring
func2 f = ((.) (filter f)) . map   	-- definition of (.)
func2 f = flip (.) map ((.) (filter f)) -- desugaring, def. of flip
func2 = flip (.) map . (.) . filter 	-- def. of (.), twice
func2 = (. map) . (.) . filter		-- add back some sugar


The general process is called "lambda elimination" and can be done
mechanically.  Ask Goole for "Unlambda", the not-quite-serious
programming language; since it's missing the lambda, its manual explains
lambda elimination in some detail.  I think, all that's needed is flip,
(.) and liftM2.

Udo Stenzel. *)

(* ********** Reductions ********** *)

let rec i_sum_from_to f a b =
  if a > b then 0
  else f a + i_sum_from_to f (a+1) b
let rec f_sum_from_to f a b =
  if a > b then 0.
  else f a +. f_sum_from_to f (a+1) b
let i2f = float_of_int
let pi2_over6 =
  f_sum_from_to (fun i->1./.i2f (i*i)) 1 5000

let rec op_from_to op base f a b =
  if a > b then base
  else op (f a) (op_from_to op base f (a+1) b)
(*
let test = op_from_to ( *.) 1. (fun i->1.+.1./.i2f(i*i)) 1 5000
*)
(* list manipulation *)

let rec from_to m n =
  if m > n then []
  else m :: from_to (m+1) n

let rec subseqs l =
  match l with
    | [] -> [[]]
    | x::xs ->
      let pxs = subseqs xs in
      List.map (fun px -> x::px) pxs @ pxs

let rec rmap_append f accu = function
  | [] -> accu
  | a::l -> rmap_append f (f a :: accu) l

let rec subseqs l =
  match l with
    | [] -> [[]]
    | x::xs ->
      let pxs = subseqs xs in
      rmap_append (fun px -> x::px) pxs pxs
(*
let test_subseqs = subseqs (from_to 1 2)
let test_subseqs = subseqs (from_to 0 5)
*)
(* Higher-order functions on lists. *)

let rec concat_map f = function
  | [] -> []
  | a::l -> f a @ concat_map f l

let concat_map f l =
  let rec cmap_f accu = function
    | [] -> accu
    | a::l -> cmap_f (List.rev_append (f a) accu) l in
  List.rev (cmap_f [] l)

let ( |-> ) x f = concat_map f x

(* Grouping by key and processing. *)

let collect l =
  match List.sort (fun x y -> compare (fst x) (fst y)) l with
  | [] -> []
  | (k0, v0)::tl ->
    let k0, vs, l = List.fold_left
      (fun (k0, vs, l) (kn, vn) ->
        if k0 = kn then k0, vn::vs, l
        else kn, [vn], (k0,List.rev vs)::l)
      (k0, [v0], []) tl in
    List.rev ((k0,List.rev vs)::l)

let group_by p l = collect (List.map (fun e->p e, e) l)

let aggregate_by p redf base l =
  let ags = group_by p l in
  List.map (fun (k,vs)->k, List.fold_right redf vs base) ags

let aggregate_by p redf base l =
  group_by p l
  |> List.map (fun (k,vs)->k, List.fold_right redf vs base)

let map_reduce mapf redf base l =
  List.map mapf l
  |> collect
  |> List.map (fun (k,vs)->k, List.fold_right redf vs base)

(* I originally came up with this map_reduce function. *)
let map_reduce mapf redf base l =
  match List.sort (fun x y -> compare (fst x) (fst y))
    (List.map mapf l)
  with
  | [] -> []
  | (k0, v0)::tl ->
    let k0, vs, l =
      List.fold_left (fun (k0, vs, l) (kn, vn) ->
	if k0 = kn then k0, vn::vs, l
        else kn, [vn], (k0,vs)::l)
	(k0, [v0], []) tl in
    List.rev_map (fun (k,vs) -> k, List.fold_left redf base vs)
      ((k0,vs)::l)

(* Another approach to making map_reduce tail-recursive. *)
let rev_collect l =
  match List.sort (fun x y -> compare (fst x) (fst y)) l with
  | [] -> []
  | (k0, v0)::tl ->
    let k0, vs, l = List.fold_left
      (fun (k0, vs, l) (kn, vn) ->
        if k0 = kn then k0, vn::vs, l
        else kn, [vn], (k0, vs)::l)
      (k0, [v0], []) tl in
    List.rev ((k0, vs)::l)

let map_reduce mapf redf base l =
  List.map mapf l
  |> rev_collect
  |> List.rev_map (fun (k,vs)->k, List.fold_left redf base vs)

(* Reducing from several sources *)
let concat_reduce mapf redf base l =
  concat_map mapf l
  |> collect
  |> List.map (fun (k,vs)->k, List.fold_right redf vs base)
(* Tail-recursive variant: *)
let tr_concat_reduce mapf redf base l =
  concat_map mapf l
  |> rev_collect
  |> List.rev_map (fun (k,vs)->k, List.fold_left redf base vs)
;;
(* Histogram *)
#load "str.cma";;
let histogram documents =
  let mapf doc =
    Str.split (Str.regexp "[ \t.,;]+") doc
  |> List.map (fun word->word,1) in
  concat_reduce mapf (+) 0 documents

(* Inverted index *)
let rcons tl hd = hd::tl
let inverted_index documents =
  let mapf (addr, doc) =
    Str.split (Str.regexp "[ \t.,;]+") doc
  |> List.map (fun word->word,addr) in
  tr_concat_reduce mapf rcons [] documents

let intersect xs ys =
  let rec aux acc = function
    | [], _ | _, [] -> acc
    | (x::xs' as xs), (y::ys' as ys) ->
      let c = compare x y in
      if c = 0 then aux (x::acc) (xs', ys')
      else if c < 0 then aux acc (xs', ys)
      else aux acc (xs, ys') in
  List.rev (aux [] (xs, ys))

let search index words =
  match List.map (flip List.assoc index) words with
  | [] -> []
  | idx::idcs -> List.fold_left intersect idx idcs

let indexed l =
  Array.of_list l |> Array.mapi (fun i e->i,e)
  |> Array.to_list

let read_lines file =
  let input = open_in file in
  let rec read lines =
    try Scanf.fscanf input "%[^\r\n]\n"
          (fun x -> read (x :: lines))
    with End_of_file -> lines in
  List.rev (read [])

let search_engine lines =
  let lines = indexed lines in
  let index = inverted_index lines in
  fun words ->
    let ans = search index words in
    List.map (flip List.assoc lines) ans

(*
let search_bible =
  search_engine (read_lines "./bible-kjv.txt")
let test_result =
  search_bible ["Abraham"; "sons"; "wife"]
*)
(* ********** Higher-order functions on optional values ********** *)

let map_option f = function
  | None -> None
  | Some e -> f e

let rec map_some f = function
  | [] -> []
  | e::l -> match f e with
    | None -> map_some f l
    | Some r -> r :: map_some f l

let map_some f l =
  let rec maps_f accu = function
    | [] -> accu
    | a::l -> maps_f (match f a with None -> accu
      | Some r -> r::accu) l in
  List.rev (maps_f [] l)

(* ********** Nesting list concatenation inside folding. ********** *)
let rec concat_foldr f l base =
  match l with
    | [] -> base
    | x::xs -> concat_map (f x) (concat_foldr f xs base)

let rec concat_foldl f a = function
  | [] -> a
  | x::xs -> concat_foldl f (concat_map (f x) a) xs

let rec concat_fold f a = function
  | [] -> [a]
  | x::xs -> 
    f x a |-> (fun a' -> concat_fold f a' xs)


let assoc_all i = List.map snd -| List.filter (fun (k,v)->k=i)

(* ************************************************************** *)

(* ******************** The Countdown Puzzle ******************** *)

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
  | App (o,l,r) ->
    eval l |> map_option (fun x ->
      eval r |> map_option (fun y ->
      if valid o x y then Some (apply o x y)
      else None))

let list_diff a b = List.filter (fun e -> not (List.mem e b)) a
let is_unique xs =
  let rec aux = function
    | [] -> true
    | x :: xs when List.mem x xs -> false
    | x :: xs -> aux xs in
  aux xs

let rec values = function
  | Val n -> [n]
  | App (_,l,r) -> values l @ values r
    
let solution e ns n =
  list_diff (values e) ns = [] && is_unique (values e) &&
  eval e = Some n

(* Brute force solution. *)

let split l =
  let rec aux lhs acc = function
    | [] | [_] -> []
    | [y; z] -> (List.rev (y::lhs), [z])::acc
    | hd::rhs ->
      let lhs = hd::lhs in
      aux lhs ((List.rev lhs, rhs)::acc) rhs in
  aux [] [] l

let combine l r =
  List.map (fun o->App (o,l,r)) [Add; Sub; Mul; Div]
let rec exprs = function
  | [] -> []
  | [n] -> [Val n]
  | ns ->
    split ns |-> (fun (ls,rs) ->
      exprs ls |-> (fun l ->
        exprs rs |-> (fun r ->
          combine l r)))

let rec insert x = function
  | [] -> [[x]]
  | y::ys as xs -> (x::xs) :: List.map (fun xys -> y::xys) (insert x ys)

let rec choices = function (* failwith "Do as homework" *)
    | [] -> [[]]
    | x::xs ->
      let cxs = choices xs in
      List.rev_append cxs (concat_map (insert x) cxs)

let guard n =
  List.filter (fun e -> eval e = Some n)
let solutions ns n =
  choices ns |-> (fun ns' ->
    exprs ns' |> guard n)

let guard p e =
  if p e then [e] else []
let solutions ns n =
  choices ns |-> (fun ns' ->
    exprs ns' |->
      guard (fun e -> eval e = Some n))

(*
let test = solutions [1;3;7;10;25;50] 765
*)
let op2str = function
  | Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/"
let rec expr2str = function
  | Val n -> string_of_int n
  | App (op,l,r) -> "("^expr2str l^op2str op^expr2str r^")"
(*
let _ = List.map expr2str test
*)
(* Optimization 1: fuse the generate phase with the test phase. *)
let combine' (l,x) (r,y) =
  [Add; Sub; Mul; Div]
  |> List.filter (fun o->valid o x y)
  |> List.map (fun o->App (o,l,r), apply o x y)

let rec results = function
  | [] -> []
  | [n] -> if n > 0 then [Val n, n] else []
  | ns ->
    split ns |-> (fun (ls,rs) ->
      results ls |-> (fun lx ->
        results rs |-> (fun ry ->
          combine' lx ry)))

let solutions' ns n =
  choices ns |-> (fun ns' ->
    results ns' |>
        List.filter (fun (e,m)-> m=n) |>
            List.map fst)
(*
let test = solutions' [1;3;7;10;25;50] 765
let _ = List.map expr2str test
*)
(* Optimization 2: eliminate symmetric cases. *)
let valid op x y =
  match op with
  | Add -> x <= y
  | Sub -> x > y
  | Mul -> x <= y && x <> 1 && y <> 1
  | Div -> x mod y = 0 && y <> 1

(* RE-ENTER THE CODE OF OPTIMIZATION 1 *)

(* ******************** The Honey Islands Puzzle ******************** *)


type cell = int * int
module CellSet =
  Set.Make (struct type t = cell let compare = compare end)
type task = {
  board_size : int;
  num_islands : int;
  island_size : int;
  empty_cells : CellSet.t;
}

let cellset_of_list l =
  List.fold_right CellSet.add l CellSet.empty

let test_task_min = {
  board_size = 1;
  num_islands = 2;
  island_size = 2;
  empty_cells = cellset_of_list []
}

let test_task0 = {
  board_size = 2;
  num_islands = 3;
  island_size = 3;
  empty_cells = cellset_of_list
    [2, 0; 1, -1; -3, -1; 2, 2; -2, 2; -4, 0]
}

let test_task1 = {
  board_size = 4;
  num_islands = 6;
  island_size = 6;
  empty_cells = cellset_of_list
    [4, 4; -1, 3; -6, 2; 4, 2; -3, 1; 1, 1; 4, 0; -5,-1;
     -1,-1; 1,-1; 6,-2; 1,-3; -3,-3]
}

let test_task2 = {
  board_size = 4;
  num_islands = 6;
  island_size = 6;
  empty_cells = cellset_of_list
[-2, 4; -1, 3; -6, 2; 6, 2; 2, 2; 3, 1; -4, 0; 0, 0;
  6, 0; -5,-1; -1,-1; 4,-2; 6,-2;-5,-3; 0,-4]}

let test_task3 = {
  board_size = 3;
  num_islands = 4;
  island_size = 5;
  empty_cells = cellset_of_list
    [3,3;-4,2;5,-1;-5,-1;-4,-2;4,-2;-1,-3;1,-3]}

let test_task4 = {
  board_size = 6;
  num_islands = 9;
  island_size = 8;
  empty_cells = cellset_of_list
    [0,4;10,2;-11,-1;11,-1;-1,3;1,3;1,-5;-2,-2;-2,2;2,-2;2,2;-2,4;
     2,-6;-3,-1;3,1;-3,-3;3,-3;-4,0;4,0;-4,-6;-5,-1;5,1;5,-3;
     -5,-5;5,5;-6,2;6,2;6,-4;-6,-6;-6,6;-7,-1;7,-1;-7,-3;7,-3;
     7,5;8,0;-8,2;-9,-1;9,-1;-9,3;4,-2;2,-4;-7,-5;4,-4]}

let test_task5 = {
  board_size = 8;
  num_islands = 10;
  island_size = 13;
  empty_cells = cellset_of_list
    [0,4;0,-6;0,-8;0,8;-10,0;10,0;-10,4;10,-4;10,4;10,6;-1,1;1,-1;
     11,-3;11,3;-11,-5;12,0;12,-2;12,2;-12,4;1,3;-13,-1;13,1;
     -1,5;1,-5;1,5;-15,-1;2,0;2,4;-2,-6;-2,6;-3,-1;3,1;3,-3;3,3;
     -3,-5;-3,5;3,-5;-4,-2;4,2;-4,-4;4,-4;4,4;-5,-1;5,-1;
     -5,-5;-5,5;5,-5;5,5;6,-2;-6,4;-7,-1;7,1;-7,3;7,-3;7,3;
     -7,-5;7,5;7,-7;8,0;8,-2;8,6;8,-8;-9,-1;-9,1;9,-1;9,1;-9,-5;-9,5;9,-5]}

let even x = x mod 2 = 0
 
let inside_board n eaten (x, y) =
  even x = even y && abs y <= n &&
  abs x + abs y <= 2*n &&
  not (CellSet.mem (x,y) eaten)

let neighbors n eaten (x,y) =
  List.filter
    (inside_board n eaten)
    [x-1,y-1; x+1,y-1; x+2,y;
     x+1,y+1; x-1,y+1; x-2,y]

let rec remove x l =
  match l with
    | [] -> []
    | y::ys -> if x=y then remove x ys else y::remove x ys

let rec add_cells cells set =
  match cells with
    | [] -> set
    | cell::cells -> CellSet.add cell (add_cells cells set)


let honey_cells n empty_cells =
  let xs = from_to (-2 * n) (2 * n) in
  let ys = from_to (-n) n in
  List.filter (inside_board n empty_cells)
    (concat_map (fun x -> List.map (fun y -> x, y) ys) xs)

let honey_cells n eaten =
  from_to (-2*n) (2*n)|->(fun x ->
    from_to (-n) n |-> (fun y ->
     guard (inside_board n eaten)
        (x, y)))


let check_correct n island_size num_islands empty_cells =
  let honey = honey_cells n empty_cells in

  let rec check_board been_islands unvisited visited =
    match unvisited with
    | [] -> been_islands = num_islands
    | cell::remaining when CellSet.mem cell visited ->
      check_board been_islands remaining visited
    | cell::remaining (* when not visited *) ->
      let (been_size, unvisited, visited) =
        check_island cell
          (1, remaining, CellSet.add cell visited) in
      been_size = island_size
      && check_board (been_islands+1) unvisited visited

  and check_island current state =
    neighbors n empty_cells current
    |> List.fold_left
        (fun (been_size, unvisited, visited as state)
          neighbor ->
            if CellSet.mem neighbor visited then state
            else
              let unvisited = remove neighbor unvisited in
              let visited = CellSet.add neighbor visited in
              check_island neighbor
                (been_size+1, unvisited, visited))
        state in
  
  check_board 0 honey empty_cells
(*
let _ = check_correct test_task0.board_size test_task0.island_size
  test_task0.num_islands test_task0.empty_cells
let _ = check_correct test_task0.board_size test_task0.island_size
  test_task0.num_islands
  (add_cells [0, 0; -2, 0; 1, 1; 2, -2] test_task0.empty_cells)
*)
;;
(* Drawing... *)

let draw_to_svg file ~w ~h ?title ?desc curves =
  let f = open_out file in
  Printf.fprintf f "<?xml version=\"1.0\" standalone=\"no\"?>
<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" 
  \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">
<svg width=\"%d\" height=\"%d\" viewBox=\"0 0 %d %d\"
     xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">
" w h w h;
  (match title with None -> ()
  | Some title -> Printf.fprintf f "  <title>%s</title>\n" title);
  (match desc with None -> ()
  | Some desc -> Printf.fprintf f "  <desc>%s</desc>\n" desc);
  let draw_shape (points, (r,g,b)) =
    uncurry (Printf.fprintf f "  <path d=\"M %d %d") points.(0);
    Array.iteri (fun i (x, y) ->
      if i > 0 then Printf.fprintf f " L %d %d" x y) points;
    Printf.fprintf f
      "\"\n        fill=\"rgb(%d, %d, %d)\" stroke-width=\"3\" />\n"
      r g b in
  List.iter draw_shape curves;
  Printf.fprintf f "</svg>%!"
;;

#load "graphics.cma";;
let draw_to_screen ~w ~h curves =
  Graphics.open_graph (" "^string_of_int w^"x"^string_of_int h);
  Graphics.set_color (Graphics.rgb 50 50 0);
  Graphics.fill_rect 0 0 (Graphics.size_x ()) (Graphics.size_y ());
  List.iter (fun (points, (r,g,b)) ->
    Graphics.set_color (Graphics.rgb r g b);
    Graphics.fill_poly points) curves;
  if Graphics.read_key () = 'q'
  then failwith "User interrupted finding solutions.";
  Graphics.close_graph ()
  
let pi = 4.0 *. atan 1.0
  
let draw_honeycomb ~w ~h task eaten =
  let i2f = float_of_int in
  let nx = i2f (4 * task.board_size + 2) in
  let ny = i2f (2 * task.board_size + 2) in
  let radius = min (i2f w /. nx) (i2f h /. ny) in
  let x0 = w / 2 in
  let y0 = h / 2 in
  let dx = (sqrt 3. /. 2.) *. radius +. 1. in
  let dy = (3. /. 2.) *. radius +. 2. in
  let draw_cell (x,y) =
    Array.init 7
      (fun i ->
        let phi = float_of_int i *. pi /. 3. in
        x0 + int_of_float (radius *. sin phi +. float_of_int x *. dx),
        y0 + int_of_float (radius *. cos phi +. float_of_int y *. dy)) in
  let honey =
    honey_cells task.board_size (CellSet.union task.empty_cells
                     (cellset_of_list eaten))
    |> List.map (fun p->draw_cell p, (255, 255, 0)) in
  let eaten = List.map
     (fun p->draw_cell p, (50, 0, 50)) eaten in
  let old_empty = List.map
     (fun p->draw_cell p, (0, 0, 0))
     (CellSet.elements task.empty_cells) in
  honey @ eaten @ old_empty


      
let find_to_eat n island_size num_islands empty_cells =
  let honey = honey_cells n empty_cells in

  let rec find_board been_islands unvisited visited eaten =
    match unvisited with
    | [] ->
      if been_islands = num_islands then [eaten] else []
    | cell::remaining when CellSet.mem cell visited ->
      find_board been_islands
        remaining visited eaten
    | cell::remaining (* when not visited *) ->
      find_island cell
        (1, remaining, CellSet.add cell visited, eaten)
      |->
      (fun (been_size, unvisited, visited, eaten) ->
        if been_size = island_size
        then find_board (been_islands+1)
               unvisited visited eaten
        else [])

  and find_island current state =
    neighbors n empty_cells current
    |> concat_fold
        (fun neighbor
          (been_size, unvisited, visited, eaten as state) ->
          if CellSet.mem neighbor visited then [state]
          else
            let unvisited = remove neighbor unvisited in
            let visited = CellSet.add neighbor visited in
            (* solution where neighbor is eaten: no walk in this dir. *)
            (been_size, unvisited, visited,
             neighbor::eaten)::
              (* solutions where neighbor is honey *)
            find_island neighbor
              (been_size+1, unvisited, visited, eaten))
        state in
  
  find_board 0 honey empty_cells []

let w = 800 and h = 800
(*
let ans0 = find_to_eat test_task0.board_size test_task0.island_size
  test_task0.num_islands test_task0.empty_cells
let _ = draw_to_screen ~w ~h
  (draw_honeycomb ~w ~h test_task0 (List.hd ans0))
let ans1 = find_to_eat test_task1.board_size test_task1.island_size
  test_task1.num_islands test_task1.empty_cells
let _ = draw_to_screen ~w ~h
  (draw_honeycomb ~w ~h test_task1 (List.hd ans1))
*)
type state = {
  been_size: int;
  been_islands: int;
  unvisited: cell list;
  visited: CellSet.t;
  eaten: cell list;
  more_to_eat: int;
}

let cells_str cs =
  String.concat ""
    (List.map (fun (x,y)->Printf.sprintf "<%d,%d>" x y) cs)
let state_str s =
  Printf.sprintf "been_size=%d; been_islands=%d; more_to_eat=%d
unvisited=%s\neaten=%s" s.been_size s.been_islands s.more_to_eat
    (cells_str s.unvisited) (cells_str s.eaten)

let init_state unvisited more_to_eat = {
  been_size = 0;
  been_islands = 0;
  unvisited;
  visited = CellSet.empty;
  eaten = [];
  more_to_eat;
}

let rec visit_cell s =
  match s.unvisited with
  | [] -> None
  | c::remaining when CellSet.mem c s.visited ->
    visit_cell {s with unvisited=remaining}
  | c::remaining (* when c not visited *) ->
    Some (c, {s with
      unvisited=remaining;
      visited = CellSet.add c s.visited})

let eat_cell c s =
  {s with eaten = c::s.eaten;
    visited = CellSet.add c s.visited;
    more_to_eat = s.more_to_eat - 1}

let keep_cell c s =
  {s with
    visited = CellSet.add c s.visited;
    been_size = s.been_size + 1}

let fresh_island s =
  {s with been_size = 0;
    been_islands = s.been_islands + 1}


let find_to_eat n island_size num_islands empty_cells =
  let honey = honey_cells n empty_cells in

  let rec find_board s =
    (* Printf.printf "find_board: %s\n" (state_str s); *)
    match visit_cell s with
    | None ->
      if s.been_islands = num_islands then [s.eaten] else []
    | Some (cell, s) ->
      find_island cell (fresh_island s)
      |-> (fun s ->
        if s.been_size = island_size
        then find_board s
        else [])

  and find_island current s =
    let s = keep_cell current s in
    (* Printf.printf "find_island: %s\n" (state_str s); *)
    neighbors n empty_cells current
    |> concat_fold
        (fun neighbor s ->
          if CellSet.mem neighbor s.visited then [s]
          else
            let choose_eat =
              if s.more_to_eat <= 0 then []
              else [eat_cell neighbor s]
            and choose_keep =
              if s.been_size >= island_size then []
              else find_island neighbor s in
            choose_eat @ choose_keep)
        s in
  
  let cells_to_eat =
    List.length honey - island_size * num_islands in
  find_board (init_state honey cells_to_eat)

(* *
let ans0 = find_to_eat test_task0.board_size test_task0.island_size
  test_task0.num_islands test_task0.empty_cells
let _ = draw_to_screen ~w ~h
  (draw_honeycomb ~w ~h test_task0 (List.hd ans0))
let ans1 = find_to_eat test_task1.board_size test_task1.island_size
  test_task1.num_islands test_task1.empty_cells
let _ = draw_to_screen ~w ~h
  (draw_honeycomb ~w ~h test_task1 (List.hd ans1))
let ans3 = find_to_eat test_task3.board_size test_task3.island_size
  test_task3.num_islands test_task3.empty_cells
let _ = draw_to_screen ~w ~h
  (draw_honeycomb ~w ~h test_task3 (List.hd ans3))
* *)

(*
let test_min = draw_honeycomb ~w:300 ~h:300 test_task_min []
let () = draw_to_svg
  "/home/lukstafi/Dropbox/Dokumenty/FunctionalCourse/honey_min.svg"
  ~w:300 ~h:300 test_min;;
let test_0 = draw_honeycomb ~w ~h test_task0
  [0, 0; -2, 0; 1, 1; 2, -2]
;;
*)
