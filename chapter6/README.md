## Chapter 6: Folding and Backtracking

This chapter explores two fundamental programming paradigms in functional programming: **folding** (also known as reduction) and **backtracking**. We begin with the classic `map` and `fold` higher-order functions, examine how they generalize to trees and other data structures, then move on to solving puzzles using backtracking with lists.

### 6.1 Basic Generic List Operations

Functional programming emphasizes identifying common patterns and abstracting them into reusable higher-order functions. Let us see how this works in practice.

#### The `map` Function

Consider the problem of printing a comma-separated list of integers. The `String` module provides:

```
val concat : string -> string list -> string
```

First, we need to convert numbers into strings:

```ocaml
let rec strings_of_ints = function
  | [] -> []
  | hd::tl -> string_of_int hd :: strings_of_ints tl

let comma_sep_ints = String.concat ", " -| strings_of_ints
```

Similarly, to sort strings from shortest to longest, we first compute lengths:

```ocaml
let rec strings_lengths = function
  | [] -> []
  | hd::tl -> (String.length hd, hd) :: strings_lengths tl

let by_size = List.sort compare -| strings_lengths
```

Notice the common structure in `strings_of_ints` and `strings_lengths`: both transform each element of a list independently. We can extract this pattern into a generic function called `map`:

```ocaml
let rec list_map f = function
  | [] -> []
  | hd::tl -> f hd :: list_map f tl
```

Now we can rewrite our functions more concisely:

```ocaml
let comma_sep_ints =
  String.concat ", " -| list_map string_of_int

let by_size =
  List.sort compare -| list_map (fun s -> String.length s, s)
```

#### The `fold` Function

Consider summing elements of a list:

```ocaml
let rec balance = function
  | [] -> 0
  | hd::tl -> hd + balance tl
```

Or multiplying elements:

```ocaml
let rec total_ratio = function
  | [] -> 1.
  | hd::tl -> hd *. total_ratio tl
```

The pattern is the same: we combine each element with the result of processing the rest of the list. This is the **fold** operation:

```ocaml
let rec list_fold f base = function
  | [] -> base
  | hd::tl -> f hd (list_fold f base tl)
```

**Important:** Note that `list_fold f base l` equals `List.fold_right f l base`. The OCaml standard library uses a different argument order.

The key insight is that `map` alters the *contents* of data without changing its structure, while `fold` computes a value using the structure as scaffolding. Visually:

- `map` transforms: `[a; b; c; d]` becomes `[f a; f b; f c; f d]`
- `fold` collapses: `[a; b; c; d]` becomes `f a (f b (f c (f d accu)))`

### 6.2 Making Fold Tail-Recursive

Let us investigate tail-recursive functions. Consider reversing a list:

```ocaml
let rec list_rev acc = function
  | [] -> acc
  | hd::tl -> list_rev (hd::acc) tl
```

Or computing an average:

```ocaml
let rec average (sum, tot) = function
  | [] when tot = 0. -> 0.
  | [] -> sum /. tot
  | hd::tl -> average (hd +. sum, 1. +. tot) tl
```

The pattern here is different from `fold_right`. We process elements from left to right, accumulating a result:

```ocaml
let rec fold_left f accu = function
  | [] -> accu
  | a::l -> fold_left f (f accu a) l
```

With `fold_left`, hiding the accumulator is straightforward:

```ocaml
let list_rev l =
  fold_left (fun t h -> h::t) [] l

let average =
  fold_left (fun (sum, tot) e -> sum +. e, 1. +. tot) (0., 0.)
```

The naming convention for `fold_right` and `fold_left` reflects associativity:

- `fold_right f` makes `f` **right associative**, like the list constructor `::`:
  `List.fold_right f [a1; ...; an] b` is `f a1 (f a2 (... (f an b) ...))`

- `fold_left f` makes `f` **left associative**, like function application:
  `List.fold_left f a [b1; ...; bn]` is `f (... (f (f a b1) b2) ...) bn`

The "backward" structure of `fold_left`:
- Input: `[a; b; c; d]`
- Result: `f (f (f (f accu a) b) c) d`

#### Useful Derived Functions

List filtering is naturally expressed using `fold_right`:

```ocaml
let list_filter p l =
  List.fold_right (fun h t -> if p h then h::t else t) l []
```

A tail-recursive map that returns elements in reverse order:

```ocaml
let list_rev_map f l =
  List.fold_left (fun t h -> f h :: t) [] l
```

### 6.3 Map and Fold for Trees and Other Structures

#### Binary Trees

Mapping binary trees is straightforward:

```ocaml
type 'a btree = Empty | Node of 'a * 'a btree * 'a btree

let rec bt_map f = function
  | Empty -> Empty
  | Node (e, l, r) -> Node (f e, bt_map f l, bt_map f r)

let test = Node
  (3, Node (5, Empty, Empty), Node (7, Empty, Empty))
let _ = bt_map ((+) 1) test
```

The `map` and `fold` functions we consider here preserve/respect the structure of data. They do **not** correspond to `map` and `fold` of abstract data type containers (which are like `List.rev_map` and `List.fold_left` over container elements in arbitrary order). Here we generalize `List.map` and `List.fold_right` to other structures.

The most general form of `fold` for binary trees processes each element together with partial results from subtrees:

```ocaml
let rec bt_fold f base = function
  | Empty -> base
  | Node (e, l, r) ->
    f e (bt_fold f base l) (bt_fold f base r)
```

Examples:

```ocaml
let sum_els = bt_fold (fun i l r -> i + l + r) 0
let depth t = bt_fold (fun _ l r -> 1 + max l r) 1 t
```

#### More Complex Structures: Expressions

To demonstrate map and fold for more complex structures, we recall the expression type from Chapter 3:

```ocaml
type expression =
    Const of float
  | Var of string
  | Sum of expression * expression    (* e1 + e2 *)
  | Diff of expression * expression   (* e1 - e2 *)
  | Prod of expression * expression   (* e1 * e2 *)
  | Quot of expression * expression   (* e1 / e2 *)
```

The multitude of cases makes the datatype harder to work with. Fortunately, *or-patterns* help:

```ocaml
let rec vars = function
  | Const _ -> []
  | Var x -> [x]
  | Sum (a,b) | Diff (a,b) | Prod (a,b) | Quot (a,b) ->
    vars a @ vars b
```

Mapping and folding must be specialized for each case. We pack behaviors into records:

```ocaml
type expression_map = {
  map_const : float -> expression;
  map_var : string -> expression;
  map_sum : expression -> expression -> expression;
  map_diff : expression -> expression -> expression;
  map_prod : expression -> expression -> expression;
  map_quot : expression -> expression -> expression;
}

(* Note: 'a replaces expression because fold produces values of arbitrary type *)
type 'a expression_fold = {
  fold_const : float -> 'a;
  fold_var : string -> 'a;
  fold_sum : 'a -> 'a -> 'a;
  fold_diff : 'a -> 'a -> 'a;
  fold_prod : 'a -> 'a -> 'a;
  fold_quot : 'a -> 'a -> 'a;
}
```

We define standard behaviors that can be tailored for specific uses:

```ocaml
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
```

The actual `map` and `fold` functions:

```ocaml
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
```

Using the `{record with field = value}` syntax to customize behaviors:

```ocaml
let prime_vars = expr_map
  {identity_map with map_var = fun x -> Var (x ^ "'")}

let subst s =
  let apply x = try List.assoc x s with Not_found -> Var x in
  expr_map {identity_map with map_var = apply}

let vars =
  expr_fold {(make_fold (@) []) with fold_var = fun x -> [x]}

let size = expr_fold (make_fold (fun a b -> 1 + a + b) 1)

let eval env = expr_fold {
  fold_const = id;
  fold_var = (fun x -> List.assoc x env);
  fold_sum = (+.); fold_diff = (-.);
  fold_prod = ( *.); fold_quot = (/.);
}
```

### 6.4 Point-Free Programming

In 1977/78, John Backus designed **FP**, the first *function-level programming* language. Over the next decade it evolved into the **FL** language.

> "Clarity is achieved when programs are written at the function level--that is, by putting together existing programs to form new ones, rather than by manipulating objects and then abstracting from those objects to produce programs." -- *The FL Project: The Design of a Functional Language*

For function-level programming, we need combinators like these from *OCaml Batteries*:

```ocaml
let const x _ = x
let ( |- ) f g x = g (f x)          (* forward composition *)
let ( -| ) f g x = f (g x)          (* backward composition *)
let flip f x y = f y x
let ( *** ) f g = fun (x,y) -> (f x, g y)
let ( &&& ) f g = fun x -> (f x, g x)
let first f x = fst (f x)
let second f x = snd (f x)
let curry f x y = f (x,y)
let uncurry f (x,y) = f x y
```

The flow of computation can be viewed as a circuit where results of nodes (functions) connect to further nodes as inputs. We represent cross-sections of the circuit as tuples of intermediate values.

```ocaml
let print2 c i =
  let a = Char.escaped c in
  let b = string_of_int i in
  a ^ b
```

In point-free style:

```ocaml
let print2 = curry
  ((Char.escaped *** string_of_int) |- uncurry (^))
```

Since we usually pass arguments one at a time rather than in tuples, we need `uncurry` to access multi-argument functions. Converting a C/Pascal-like function to one that takes arguments one at a time is called *currying*, after logician Haskell Brooks Curry.

Another approach uses function composition, `flip`, and the **S** combinator:

```ocaml
let s x y z = x z (y z)
```

Example: transforming a filter-map function step by step:

```ocaml
let func2 f g l = List.filter f (List.map g l)
(* Using composition: *)
let func2 f g = (-|) (List.filter f) (List.map g)
let func2 f = (-|) (List.filter f) -| List.map
(* Eliminating f: *)
let func2 f = (-|) ((-|) (List.filter f)) List.map
let func2 f = flip (-|) List.map ((-|) (List.filter f))
let func2 f = (((|-) List.map) -| ((-|) -| List.filter)) f
let func2 = (|-) List.map -| ((-|) -| List.filter)
```

### 6.5 Reductions and More Higher-Order Functions

Mathematics has notation for sums over intervals: $\sum_{n=a}^{b} f(n)$.

In OCaml, we do not have a universal addition operator:

```ocaml
let rec i_sum_fromto f a b =
  if a > b then 0
  else f a + i_sum_fromto f (a+1) b

let rec f_sum_fromto f a b =
  if a > b then 0.
  else f a +. f_sum_fromto f (a+1) b

let pi2_over6 =
  f_sum_fromto (fun i -> 1. /. float_of_int (i*i)) 1 5000
```

The natural generalization:

```ocaml
let rec op_fromto op base f a b =
  if a > b then base
  else op (f a) (op_fromto op base f (a+1) b)
```

#### Collecting Results: concat_map

Let us collect results of a multifunction (set-valued function) for a set of arguments. In mathematical notation:

$$f(A) = \bigcup_{p \in A} f(p)$$

This translates to a useful list operation with union as append:

```ocaml
let rec concat_map f = function
  | [] -> []
  | a::l -> f a @ concat_map f l
```

More efficiently (tail-recursive):

```ocaml
let concat_map f l =
  let rec cmap_f accu = function
    | [] -> accu
    | a::l -> cmap_f (List.rev_append (f a) accu) l in
  List.rev (cmap_f [] l)
```

#### All Subsequences of a List

```ocaml
let rec subseqs l =
  match l with
    | [] -> [[]]
    | x::xs ->
      let pxs = subseqs xs in
      List.map (fun px -> x::px) pxs @ pxs
```

Tail-recursively:

```ocaml
let rec rmap_append f accu = function
  | [] -> accu
  | a::l -> rmap_append f (f a :: accu) l

let rec subseqs l =
  match l with
    | [] -> [[]]
    | x::xs ->
      let pxs = subseqs xs in
      rmap_append (fun px -> x::px) pxs pxs
```

### 6.6 Grouping and Map-Reduce

It is often useful to organize values by some property.

#### Collecting by Key

First, we collect elements from an association list by key:

```ocaml
let collect l =
  match List.sort (fun x y -> compare (fst x) (fst y)) l with
  | [] -> []                                (* Start with associations sorted by key *)
  | (k0, v0)::tl ->
    let k0, vs, l = List.fold_left
      (fun (k0, vs, l) (kn, vn) ->           (* Collect values for current key *)
        if k0 = kn then k0, vn::vs, l        (* and when the key changes, *)
        else kn, [vn], (k0, List.rev vs)::l) (* stack the collected values *)
      (k0, [v0], []) tl in                   (* Why reverse? To preserve order *)
    List.rev ((k0, List.rev vs)::l)
```

Now we can group by an arbitrary property:

```ocaml
let group_by p l = collect (List.map (fun e -> p e, e) l)
```

#### Reduction (Aggregation)

To process results like SQL aggregate operations, we add **reduction**:

```ocaml
let aggregate_by p red base l =
  let ags = group_by p l in
  List.map (fun (k, vs) -> k, List.fold_right red vs base) ags
```

Using the **feed-forward** (pipe) operator `let ( |> ) x f = f x`:

```ocaml
let aggregate_by p redf base l =
  group_by p l
  |> List.map (fun (k, vs) -> k, List.fold_right redf vs base)
```

Often it is easier to extract the property upfront. Since we first map elements into key-value pairs, we call this `map_reduce`:

```ocaml
let map_reduce mapf redf base l =
  List.map mapf l
  |> collect
  |> List.map (fun (k, vs) -> k, List.fold_right redf vs base)
```

#### Map-Reduce Examples

Sometimes we have multiple sources of information:

```ocaml
let concat_reduce mapf redf base l =
  concat_map mapf l
  |> collect
  |> List.map (fun (k, vs) -> k, List.fold_right redf vs base)
```

Computing a merged histogram of documents:

```ocaml
let histogram documents =
  let mapf doc =
    Str.split (Str.regexp "[ \t.,;]+") doc
    |> List.map (fun word -> word, 1) in
  concat_reduce mapf (+) 0 documents
```

Computing an inverted index:

```ocaml
let cons hd tl = hd::tl

let inverted_index documents =
  let mapf (addr, doc) =
    Str.split (Str.regexp "[ \t.,;]+") doc
    |> List.map (fun word -> word, addr) in
  concat_reduce mapf cons [] documents
```

A simple "search engine":

```ocaml
let search index words =
  match List.map (flip List.assoc index) words with
  | [] -> []
  | idx::idcs -> List.fold_left intersect idx idcs
```

where `intersect` computes intersection of sets represented as sorted lists:

```ocaml
let intersect xs ys =                       (* Sets as sorted lists *)
  let rec aux acc = function
    | [], _ | _, [] -> acc
    | (x::xs' as xs), (y::ys' as ys) ->
      let c = compare x y in
      if c = 0 then aux (x::acc) (xs', ys')
      else if c < 0 then aux acc (xs', ys)
      else aux acc (xs, ys') in
  List.rev (aux [] (xs, ys))
```

### 6.7 Higher-Order Functions for the Option Type

Operating on optional values:

```ocaml
let map_option f = function
  | None -> None
  | Some e -> f e
```

Mapping over a list and filtering out failures:

```ocaml
let rec map_some f = function
  | [] -> []
  | e::l -> match f e with
    | None -> map_some f l
    | Some r -> r :: map_some f l
```

Tail-recursively:

```ocaml
let map_some f l =
  let rec maps_f accu = function
    | [] -> accu
    | a::l -> maps_f (match f a with None -> accu
      | Some r -> r::accu) l in
  List.rev (maps_f [] l)
```

### 6.8 The Countdown Problem Puzzle

The Countdown Problem is a classic puzzle:

- Using a given set of numbers and arithmetic operators +, -, *, /, construct an expression with a given value.
- All numbers, including intermediate results, must be positive integers.
- Each source number can be used at most once.

**Example:**
- Numbers: 1, 3, 7, 10, 25, 50
- Target: 765
- Possible solution: (25-10) * (50+1)

There are 780 solutions for this example. Changing the target to 831 gives an example with no solutions.

#### Data Types

```ocaml
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

let solution e ns n =
  list_diff (values e) ns = [] && is_unique (values e) &&
  eval e = Some n
```

#### Brute Force Solution

Splitting a list into two non-empty parts:

```ocaml
let split l =
  let rec aux lhs acc = function
    | [] | [_] -> []
    | [y; z] -> (List.rev (y::lhs), [z])::acc
    | hd::rhs ->
      let lhs = hd::lhs in
      aux lhs ((List.rev lhs, rhs)::acc) rhs in
  aux [] [] l
```

We introduce an operator for working with multiple data sources:

```ocaml
let ( |-> ) x f = concat_map f x
```

Generating all expressions from a list of numbers:

```ocaml
let combine l r =                           (* Combine two expressions using each operator *)
  List.map (fun o -> App (o, l, r)) [Add; Sub; Mul; Div]

let rec exprs = function
  | [] -> []
  | [n] -> [Val n]
  | ns ->
    split ns |-> (fun (ls, rs) ->           (* For each split ls,rs of numbers *)
      exprs ls |-> (fun l ->                (* for each expression l over ls *)
        exprs rs |-> (fun r ->              (* and expression r over rs *)
          combine l r)))                    (* produce all l ? r expressions *)
```

Finding solutions:

```ocaml
let guard n =
  List.filter (fun e -> eval e = Some n)

let solutions ns n =
  choices ns |-> (fun ns' ->
    exprs ns' |> guard n)
```

#### Optimization: Fuse Generation with Testing

We memorize values with expressions as pairs `(e, eval e)`, so only valid subexpressions are generated:

```ocaml
let combine' (l, x) (r, y) =
  [Add; Sub; Mul; Div]
  |> List.filter (fun o -> valid o x y)
  |> List.map (fun o -> App (o, l, r), apply o x y)

let rec results = function
  | [] -> []
  | [n] -> if n > 0 then [Val n, n] else []
  | ns ->
    split ns |-> (fun (ls, rs) ->
      results ls |-> (fun lx ->
        results rs |-> (fun ry ->
          combine' lx ry)))

let solutions' ns n =
  choices ns |-> (fun ns' ->
    results ns'
    |> List.filter (fun (e, m) -> m = n)
    |> List.map fst)                        (* Discard memorized values *)
```

#### Eliminating Symmetric Cases

Strengthening the validity predicate to account for commutativity and identity:

```ocaml
let valid op x y =
  match op with
  | Add -> x <= y
  | Sub -> x > y
  | Mul -> x <= y && x <> 1 && y <> 1
  | Div -> x mod y = 0 && y <> 1
```

This eliminates repeating symmetrical solutions on the semantic level (values) rather than syntactic level (expressions)--both easier and more effective.

### 6.9 The Honey Islands Puzzle

The Honey Islands puzzle: Find cells to eat honey from so that the least amount of honey becomes sour (assuming sourness spreads through contact).

Given a honeycomb with some cells initially marked black, mark additional cells so that unmarked cells form `num_islands` disconnected components, each with `island_size` cells.

#### Representing the Honeycomb

```ocaml
type cell = int * int                       (* Cartesian coordinates *)

module CellSet =                            (* Store cells in sets *)
  Set.Make (struct type t = cell let compare = compare end)

type task = {                               (* For board size N, coordinates *)
  board_size : int;                         (* range from (-2N, -N) to (2N, N) *)
  num_islands : int;                        (* Required number of islands *)
  island_size : int;                        (* Required cells per island *)
  empty_cells : CellSet.t;                  (* Initially empty cells *)
}

let cellset_of_list l =                     (* List to set, inverse of CellSet.elements *)
  List.fold_right CellSet.add l CellSet.empty
```

**Neighborhood:** Each cell (x, y) has up to 6 neighbors:

```ocaml
let neighbors n eaten (x, y) =
  List.filter
    (inside_board n eaten)
    [x-1,y-1; x+1,y-1; x+2,y;
     x+1,y+1; x-1,y+1; x-2,y]
```

**Building the honeycomb:**

```ocaml
let even x = x mod 2 = 0

let inside_board n eaten (x, y) =
  even x = even y && abs y <= n &&
  abs x + abs y <= 2*n &&
  not (CellSet.mem (x, y) eaten)

let honey_cells n eaten =
  fromto (-2*n) (2*n) |-> (fun x ->
    fromto (-n) n |-> (fun y ->
     guard (inside_board n eaten)
        (x, y)))
```

#### Testing Correctness

We walk through each island counting cells depth-first:

```ocaml
let check_correct n island_size num_islands empty_cells =
  let honey = honey_cells n empty_cells in

  let rec check_board been_islands unvisited visited =
    match unvisited with
    | [] -> been_islands = num_islands
    | cell::remaining when CellSet.mem cell visited ->
        check_board been_islands remaining visited    (* Keep looking *)
    | cell::remaining (* when not visited *) ->
        let (been_size, unvisited, visited) =
          check_island cell                           (* Visit another island *)
            (1, remaining, CellSet.add cell visited) in
        been_size = island_size
        && check_board (been_islands+1) unvisited visited

  and check_island current state =
    neighbors n empty_cells current
    |> List.fold_left                                 (* Walk into each direction *)
      (fun (been_size, unvisited, visited as state)
        neighbor ->
        if CellSet.mem neighbor visited then state
        else
          let unvisited = remove neighbor unvisited in
          let visited = CellSet.add neighbor visited in
          let been_size = been_size + 1 in
          check_island neighbor
            (been_size, unvisited, visited))
      state in                                        (* Initial been_size is 1 *)

  check_board 0 honey empty_cells
```

#### Multiple Results per Step: concat_fold

When processing lists with potentially multiple results per step, we need `concat_fold`:

```ocaml
let rec concat_fold f a = function
  | [] -> [a]
  | x::xs ->
    f x a |-> (fun a' -> concat_fold f a' xs)
```

#### Generating Solutions

We transform the testing code into generation code by:

- Passing around the current solution `eaten`
- Returning results in a list (empty list = no solutions)
- At each neighbor, trying both eating and keeping

```ocaml
let find_to_eat n island_size num_islands empty_cells =
  let honey = honey_cells n empty_cells in

  let rec find_board been_islands unvisited visited eaten =
    match unvisited with
    | [] ->
      if been_islands = num_islands then [eaten] else []
    | cell::remaining when CellSet.mem cell visited ->
      find_board been_islands remaining visited eaten
    | cell::remaining (* when not visited *) ->
      find_island cell
        (1, remaining, CellSet.add cell visited, eaten)
      |->                                             (* Concatenate solutions *)
      (fun (been_size, unvisited, visited, eaten) ->
        if been_size = island_size
        then find_board (been_islands+1)
               unvisited visited eaten
        else [])

  and find_island current state =
    neighbors n empty_cells current
    |> concat_fold                                    (* Multiple results *)
        (fun neighbor
          (been_size, unvisited, visited, eaten as state) ->
          if CellSet.mem neighbor visited then [state]
          else
            let unvisited = remove neighbor unvisited in
            let visited = CellSet.add neighbor visited in
            (been_size, unvisited, visited,
             neighbor::eaten)::
              (* solutions where neighbor is honey *)
            find_island neighbor
              (been_size+1, unvisited, visited, eaten))
        state in

  find_board 0 honey empty_cells []
```

#### Optimizations

The main rule: **fail (drop solution candidates) as early as possible**.

We guard both choices (eating and keeping) and track how much honey needs to be eaten:

```ocaml
type state = {
  been_size: int;                           (* Honey cells in current island *)
  been_islands: int;                        (* Islands visited so far *)
  unvisited: cell list;                     (* Cells to visit *)
  visited: CellSet.t;                       (* Already visited *)
  eaten: cell list;                         (* Current solution candidate *)
  more_to_eat: int;                         (* Remaining cells to eat *)
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

let keep_cell c s =                         (* c is actually unused *)
  {s with been_size = s.been_size + 1;
    visited = CellSet.add c s.visited}

let fresh_island s =                        (* Increment been_size at start of find_island *)
  {s with been_size = 0;
    been_islands = s.been_islands + 1}

let init_state unvisited more_to_eat = {
  been_size = 0; been_islands = 0;
  unvisited; visited = CellSet.empty;
  eaten = []; more_to_eat;
}
```

The optimized island loop only tries actions that make sense:

```
  and find_island current s =
    let s = keep_cell current s in
    neighbors n empty_cells current
    |> concat_fold
        (fun neighbor s ->
          if CellSet.mem neighbor s.visited then [s]
          else
            let choose_eat =                (* Guard against failed actions *)
              if s.more_to_eat = 0 then []
              else [eat_cell neighbor s]
            and choose_keep =
              if s.been_size >= island_size then []
              else find_island neighbor s in
            choose_eat @ choose_keep)
        s in
  (* Finally, compute the required eaten cells and start searching *)
  let cells_to_eat =
    List.length honey - island_size * num_islands in
  find_board (init_state honey cells_to_eat)
```

### 6.10 Constraint-Based Puzzles

Puzzles can be presented by providing:

1. The general form of solutions
2. Additional requirements (constraints) that solutions must meet

For many puzzles, solutions decompose into a fixed number of **variables**:

- A **domain** is the set of possible values a variable can have
- In Honey Islands, variables are cells with domain {Honey, Empty}
- **Constraints** specify relationships: cells that must be empty, number and size of connected components, neighborhood graph

#### Finite Domain Constraint Programming

A general and often efficient scheme:

1. With each variable, associate a set of values (initially the full domain). The singleton containing this association is the initial set of partial solutions.

2. While there is a solution with more than one value for some variable:
   - (a) If some value for a variable fails for all possible assignments to other variables, remove it
   - (b) If a variable has an empty set of possible values, remove that solution
   - (c) Select the variable with the smallest non-singleton set. Split into similarly-sized parts. Replace the solution with two solutions for each part.

3. Build final solutions by assigning each variable its single remaining value.

Simplifications: In step (2c), instead of equal-sized splits, we can partition into singleton and remainder, or partition completely into singletons.

### 6.11 Exercises

1. Recall how we generated all subsequences of a list. Find (generate) all:
   - permutations of a list
   - ways of choosing without repetition from a list
   - combinations of K distinct objects chosen from N elements of a list

2. Using folding for the `expression` data type, compute the degree of the corresponding polynomial.

3. Implement simplification of expressions using mapping for the `expression` data type.

4. Express in terms of `fold_left` or `fold_right`:
   - `indexed : 'a list -> (int * 'a) list`, which pairs elements with their indices
   - `concat_fold` as used in Honey Islands
   - Run-length encoding of a list: `encode ['a;'a;'a;'a;'b;'c;'c;'a;'a;'d] = [4,'a; 1,'b; 2,'c; 2,'a; 1,'d]`

5. Write more efficient variants:
   - `list_diff` computing difference of sets represented as sorted lists
   - `is_unique` in constant stack space

6. Write functions `compose` and `perform` that take a list of functions and return their composition:
   - `compose [f1; ...; fn] = x -> f1 (... (fn x)...)`
   - `perform [f1; ...; fn] = x -> fn (... (f1 x)...)`

7. Write a solver for the *Tents Puzzle*.

8. **Robot Squad** (harder): Given a map with walls and lidar readings (8 directions: E, NE, N, NW, W, SW, S, SE) for multiple robots, determine possible robot positions.

9. Write a solver for the *Plinx Puzzle* (does not need to solve all levels, but should handle initial ones).
