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
  
let test = Node
  (3, Node (5, Empty, Empty), Node (7, Empty, Empty))
let _ = bt_map ((+) 1) test

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

let example = Sum (Var "x", Prod (Const 2., Var "y"))
let _ = prime_vars example
let _ = subst ["x", Sum (Const 1., Var "y")] example
let _ = vars example
let _ = eval ["x", 1.; "y", 3.] example

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
let test = op_from_to ( *.) 1. (fun i->1.+.1./.i2f(i*i)) 1 5000

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

let test_subseqs = subseqs (from_to 1 2)
let test_subseqs = subseqs (from_to 0 5)

(* Higher-order functions on lists. *)

let rec concat_map f = function
  | [] -> []
  | a::l -> f a @ concat_map f l

let concat_map f l =
  let rec cmap_f accu = function
    | [] -> accu
    | a::l -> cmap_f (List.rev_append (f a) accu) l in
  List.rev (cmap_f [] l)

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

let search_bible =
  search_engine (read_lines "./bible-kjv.txt")
