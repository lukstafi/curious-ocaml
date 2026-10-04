## Chapter 6: Folding and Backtracking

![A camel assembles expression trees in a lamplit workshop](Curious_OCaml-chapter_6-third-edition.png){.chapter-image}

**Prerequisites:** Chapter 3's expression language; Chapter 5's module interfaces.
**Route:** Part II begins here. Continue to Chapter 11 for binding and extension,
or Chapter 7 for streams.

**In this chapter, you will:**

- Identify common recursion patterns and refactor them into `map`/`fold` abstractions
- Make folds tail-recursive using accumulators (and understand the trade-offs)
- Generalize `map`/`fold` beyond lists to trees and expression grammars
- Use backtracking (via lists) to solve search problems and puzzles

This chapter explores two fundamental programming paradigms in functional programming: **folding** (also known as reduction) and **backtracking**. We begin with the classic `map` and `fold` higher-order functions, examine how they generalize to trees and other data structures, then move on to solving puzzles using backtracking with lists.

The material in this chapter draws from Martin Odersky's "Functional Programming Fundamentals," Ralf Laemmel's "Going Bananas," Graham Hutton's "Programming in Haskell" (Chapter 11 on the Countdown Problem), and Tomasz Wierzbicki's Honey Islands Puzzle Solver.

### 6.1 Basic Generic List Operations

Functional programming emphasizes identifying common patterns and abstracting them into reusable higher-order functions. Rather than writing similar code repeatedly, we extract the common structure into a single generic function. Let us see how this principle works in practice through two motivating examples.

#### The `map` Function

How do we print a comma-separated list of integers? The `String` module provides a function that joins strings with a separator:

```text
val concat : string -> string list -> string
```

But `String.concat` works on strings, not integers. So first, we need to convert numbers into strings:

```ocaml env=ch6
let rec strings_of_ints = function
  | [] -> []
  | hd::tl -> string_of_int hd :: strings_of_ints tl

let comma_sep_ints = String.concat ", " -| strings_of_ints
```

Here is another common task: how do we sort strings from shortest to longest? We can pair each string with its length and then sort by the first component. First, let us compute the lengths:

```ocaml env=ch6
let rec strings_lengths = function
  | [] -> []
  | hd::tl -> (String.length hd, hd) :: strings_lengths tl

let by_size = List.sort compare -| strings_lengths
```

Now, look carefully at `strings_of_ints` and `strings_lengths`. Do you notice the common structure? Both functions traverse a list and transform each element independently -- one applies `string_of_int`, the other applies a function that pairs a string with its length. The recursive structure is identical; only the transformation differs.

This is our cue to *extract the common pattern* into a generic higher-order function. We call it `map`:

```ocaml env=ch6
let rec list_map f = function
  | [] -> []
  | hd::tl -> f hd :: list_map f tl
```

Now we can rewrite our functions more concisely:

```ocaml env=ch6
let comma_sep_ints =
  String.concat ", " -| list_map string_of_int

let by_size =
  List.sort compare -| list_map (fun s -> String.length s, s)
```

#### The `fold` Function

Now let us consider a different kind of pattern. How do we sum all the elements of a list?

```ocaml env=ch6
let rec balance = function
  | [] -> 0
  | hd::tl -> hd + balance tl
```

And how do we multiply all the elements together (perhaps to compute a cumulative ratio)?

```ocaml env=ch6
let rec total_ratio = function
  | [] -> 1.
  | hd::tl -> hd *. total_ratio tl
```

Again, the recursive structure is the same. In both cases, we combine each element with the result of processing the rest of the list. The differences are: (1) what we return for the empty list (the "base case" or "identity element"), and (2) how we combine the head with the recursive result. This pattern is called **folding**:

```ocaml env=ch6
let rec list_fold f base = function
  | [] -> base
  | hd::tl -> f hd (list_fold f base tl)
```

**Important:** Note that `list_fold f base l` equals `List.fold_right f l base`. The OCaml standard library uses a different argument order, so be careful when using `List.fold_right`.

The key insight is understanding the fundamental difference between `map` and `fold`:

- **`map`** alters the *contents* of a data structure without changing its shape. The output list has the same length as the input; we merely transform each element.
- **`fold`** *collapses* a data structure down to a single value, using the structure itself as scaffolding for the computation.

Visually, consider what happens to the list `[a; b; c; d]`:

- `map f` transforms: `[a; b; c; d]` becomes `[f a; f b; f c; f d]` -- same structure, different contents
- `fold f accu` collapses: `[a; b; c; d]` becomes `f a (f b (f c (f d accu)))` -- structure disappears, single value remains

### 6.2 Making Fold Tail-Recursive

Our `list_fold` function above is not tail-recursive: it builds up a chain of deferred `f` applications on the call stack. For very long lists, this can cause stack overflow. Can we make folding tail-recursive?

Let us investigate some tail-recursive list functions to find a pattern. Consider reversing a list:

```ocaml env=ch6
let rec list_rev acc = function
  | [] -> acc
  | hd::tl -> list_rev (hd::acc) tl
```

The key technique here is the *accumulator* parameter `acc`. Instead of building up work to do after the recursive call returns, we do the work *before* the recursive call and pass the intermediate result along.

Here is another example -- computing an average by tracking both the running sum and the count:

```ocaml env=ch6
let rec average (sum, tot) = function
  | [] when tot = 0. -> 0.
  | [] -> sum /. tot
  | hd::tl -> average (hd +. sum, 1. +. tot) tl
```

Notice how these functions process elements from left to right, threading an accumulator through the computation. This is the pattern of `fold_left`:

```ocaml env=ch6
let rec fold_left f accu = function
  | [] -> accu
  | a::l -> fold_left f (f accu a) l
```

With `fold_left`, expressing our earlier functions becomes straightforward -- we hide the accumulator inside the initial value:

```ocaml env=ch6
let list_rev l =
  fold_left (fun t h -> h::t) [] l

let average xs =
  let sum, tot =
    fold_left (fun (sum, tot) e -> sum +. e, 1. +. tot) (0., 0.) xs in
  if tot = 0. then 0. else sum /. tot

let () = assert (average [2.; 4.; 9.] = 5.)
```

Note that the `average` example is slightly trickier than `list_rev` because we need to track two values (sum and count) rather than one.

**Why the names `fold_right` and `fold_left`?** The names reflect the associativity of the combining operation:

- `fold_right f` makes `f` **right associative**, like the list constructor `::`:
  `List.fold_right f [a1; ...; an] b` is `f a1 (f a2 (... (f an b) ...))`

- `fold_left f` makes `f` **left associative**, like function application:
  `List.fold_left f a [b1; ...; bn]` is `f (... (f (f a b1) b2) ...) bn`

This "backward" structure of `fold_left` can be visualized by comparing the shape of the input list with the shape of the computation tree. The input list has a right-leaning spine (because `::` associates to the right), while `fold_left` produces a computation tree with a left-leaning spine:

::: {.figure}
```text
    Input list              Result computation

        ::                         f
       /  \                       / \
      a    ::                    f   d
          /  \                  / \
         b    ::               f   c
             /  \             / \
            c    ::          f   b
                /  \        / \
               d    []  accu   a
```
**Figure: List spine vs. fold_left computation tree**
:::

This reversal of structure is why `fold_left` naturally reverses lists when the combining operation is `cons`.

#### Useful Derived Functions

Many common list operations can be expressed using folds. List filtering selects elements satisfying a predicate -- naturally expressed using `fold_right` to preserve order:

```ocaml env=ch6
let list_filter p l =
  List.fold_right (fun h t -> if p h then h::t else t) l []
```

When we need a tail-recursive map and can tolerate reversed output, `fold_left` gives us `rev_map`:

```ocaml env=ch6
let list_rev_map f l =
  List.fold_left (fun t h -> f h :: t) [] l
```

### 6.3 Map and Fold for Trees and Other Structures

The `map` and `fold` patterns are not limited to lists. They apply to any recursive data structure. The key insight is that `map` preserves structure while transforming contents, and `fold` collapses structure into a single value.

#### Binary Trees

Mapping binary trees is straightforward:

```ocaml env=ch6
type 'a btree = Empty | Node of 'a * 'a btree * 'a btree

let rec bt_map f = function
  | Empty -> Empty
  | Node (e, l, r) -> Node (f e, bt_map f l, bt_map f r)

let test = Node
  (3, Node (5, Empty, Empty), Node (7, Empty, Empty))
let _ = bt_map ((+) 1) test
```

**A note on terminology:** The `map` and `fold` functions we define here preserve and respect the structure of data. They are different from the `map` and `fold` operations you might find in abstract data type container libraries, which often behave more like `List.rev_map` and `List.fold_left` over container elements in arbitrary order. Here we are generalizing `List.map` and `List.fold_right` to other structures.

For binary trees, the most general form of `fold` processes each element together with the partial results already computed for its subtrees:

```ocaml env=ch6
let rec bt_fold f base = function
  | Empty -> base
  | Node (e, l, r) ->
    f e (bt_fold f base l) (bt_fold f base r)
```

Here are two examples showing how `bt_fold` can compute different properties of a tree:

```ocaml env=ch6
let sum_els = bt_fold (fun i l r -> i + l + r) 0
let depth t = bt_fold (fun _ l r -> 1 + max l r) 0 t
```

The first computes the sum of all elements (the combining function adds the current element to the sums of both subtrees). The second computes the depth -- we ignore the element value and take the maximum depth of the subtrees, adding 1 for the current level.

#### The same expression language as Chapter 3

A shape-preserving map changes the labels at existing positions, preserving
constructors. A fold may produce a number, a function, or a differently shaped
tree. Calling all these operations “map” hides the distinction.

Here is the fold for `Expressions.Expr.t`. The algebra has one field per
constructor. The two recursive positions of `Let` are its value and body; the
binding name itself is a label. This traversal handles syntax, not lexical scope.

<!-- $MDX file=../projects/expressions/expr.ml,part=fold -->
```ocaml
type 'a algebra = {
  number : float -> 'a;
  variable : string -> 'a;
  binary : op -> 'a -> 'a -> 'a;
  binding : string -> 'a -> 'a -> 'a;
}

let rec fold alg = function
  | Number n -> alg.number n
  | Variable x -> alg.variable x
  | Binary (op, a, b) ->
    let a' = fold alg a in
    let b' = fold alg b in
    alg.binary op a' b'
  | Let (x, value, body) ->
    let value' = fold alg value in
    let body' = fold alg body in
    alg.binding x value' body'

let rebuild = {
  number = (fun n -> Number n);
  variable = (fun x -> Variable x);
  binary = (fun op a b -> Binary (op, a, b));
  binding = (fun x value body -> Let (x, value, body));
}

let size = fold {
  number = (fun _ -> 1); variable = (fun _ -> 1);
  binary = (fun _ a b -> 1 + a + b);
  binding = (fun _ value body -> 1 + value + body);
}

let eval_fold = fold {
  number = (fun n _env -> n);
  variable = (fun x env -> lookup env x);
  binary = (fun op a b env ->
    let x = a env in let y = b env in apply op x y);
  binding = (fun x value body env ->
    let v = value env in body ((x, v) :: env));
}
```

The last algebra is the subtle one. A fold cannot evaluate a `Let` body to a
number before it knows the binding's value. Instead its carrier is
`environment -> float`: each subtree becomes a function waiting for an
environment. The `binding` handler then passes an extended environment to the
body function. The explicit `let`s preserve the left-to-right order of Chapter 3.

```ocaml env=expression_folds
open Expressions.Expr
let example = Let ("x", Number 3.,
  Binary (Add, Variable "x", Number 4.))
let () =
  assert (size example = 5);
  assert (fold rebuild example = example);
  assert (eval_fold example [] = eval [] example)
```

A bottom-up rewrite is a fold with carrier `t`. For example `simplify` in the
shared module folds *literal* binary operations using the same float operation
as evaluation. It does not erase a variable lookup or reassociate arithmetic.
It takes one traversal: children are already simplified when the parent is
processed. A general rewrite system may need iteration, but this one does not.

```ocaml env=expression_folds
let () =
  let e = Binary (Add, Binary (Mul, Number 2., Number 3.), Variable "x") in
  assert (simplify e = Binary (Add, Number 6., Variable "x"));
  assert (eval ["x", 1.] (simplify e) = eval ["x", 1.] e)
```

The identity algebra `rebuild` gives a useful law: `fold rebuild e = e` for finite
syntax. Prove it by induction, using one case per constructor. Chapter 12 will
identify the equations that make this fold unique.

### 6.4 Point-Free Programming

We can compose functions without naming each intermediate value.

This style is sometimes called **point-free** or **tacit** programming, because we never mention the "points" (values) that functions operate on -- we only talk about the functions themselves and how they combine.

To write in this style, we need a toolkit of **combinators** -- higher-order functions that combine other functions. Here are some common ones, similar to what you will find in the *OCaml Batteries* library:

```ocaml env=ch6
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

One way to understand point-free programming is to visualize the flow of computation as a circuit. Values flow through the circuit, being transformed by functions at each node. Cross-sections of the circuit can be represented as tuples of intermediate values.

Consider this simple function that converts a character and an integer to a string:

```ocaml env=ch6
let print2 c i =
  let a = Char.escaped c in
  let b = string_of_int i in
  a ^ b
```

We can visualize this as a circuit: `(c, i)` enters, `c` flows through `Char.escaped`, `i` flows through `string_of_int`, and the results meet at `(^)`. In point-free style, we express this directly:

```ocaml env=ch6
let print2 = curry
  ((Char.escaped *** string_of_int) |- uncurry (^))
```

Here `***` applies one function to each component of a pair (this does not start parallel execution), `|-` is forward composition, `uncurry` converts a curried function to take a pair, and `curry` converts back.

**Why the name "currying"?** Converting a C/Pascal-style function (that takes all arguments as a tuple) into one that takes arguments one at a time is called *currying*, after the logician Haskell Brooks Curry. Since OCaml functions naturally take arguments one at a time, we often need `uncurry` to interface with tuple-based operations, and `curry` to convert back.

Another approach to point-free style avoids tuples entirely, using function composition, `flip`, and the **S** combinator:

```ocaml env=ch6
let s x y z = x z (y z)
```

The S combinator allows us to pass one argument to two different functions and combine their results. This can bring a particular argument of a function to the "front" and pass it to another function.

Here is an extended example showing step-by-step transformation of a filter-map function into point-free style:

```ocaml env=ch6
let func2 f g l = List.filter f (List.map g l)
(* Step 1: Recognize that filter-after-map is composition *)
let func2 f g = (-|) (List.filter f) (List.map g)
(* Step 2: Eliminate l by composing with List.map *)
let func2 f = (-|) (List.filter f) -| List.map
(* Step 3: Rewrite without infix notation to see the structure *)
let func2 f = (-|) ((-|) (List.filter f)) List.map
(* Step 4: Use flip to rearrange arguments *)
let func2 f = flip (-|) List.map ((-|) (List.filter f))
(* Step 5: Factor out f using composition *)
let func2 f = (((|-) List.map) -| ((-|) -| List.filter)) f
(* Step 6: Finally, f disappears (eta-reduction) *)
let func2 = (|-) List.map -| ((-|) -| List.filter)
```

While point-free style can be elegant for simple cases, it can quickly become obscure. Use it judiciously!

### 6.5 Reductions and More Higher-Order Functions

Mathematics has a convenient notation for sums over intervals: $\sum_{n=a}^{b} f(n)$.

Can we express this in OCaml? The challenge is that OCaml does not have a universal addition operator -- `+` works only on integers, `+.` only on floats. So we end up writing two versions:

```ocaml env=ch6
let rec i_sum_fromto f a b =
  if a > b then 0
  else f a + i_sum_fromto f (a+1) b

let rec f_sum_fromto f a b =
  if a > b then 0.
  else f a +. f_sum_fromto f (a+1) b

let pi2_over6 =
  f_sum_fromto (fun i -> 1. /. float_of_int (i*i)) 1 5000
```

(The last example computes an approximation to $\pi^2/6$ using the Basel series.)

The natural generalization is to make the combining operation a parameter:

```ocaml env=ch6
let rec op_fromto op base f a b =
  if a > b then base
  else op (f a) (op_fromto op base f (a+1) b)
```

#### Collecting Results: concat_map

Sometimes a function produces not a single result but a *collection* of results. In mathematics, such a function is called a **multifunction** or set-valued function. If we have a multifunction $f$ and want to apply it to every element of a set $A$, we take the union of all results:

$$f(A) = \bigcup_{p \in A} f(p)$$

When we represent sets as lists, "union" becomes "append". This gives us the extremely useful `concat_map` operation:

```ocaml env=ch6
let rec concat_map f = function
  | [] -> []
  | a::l -> f a @ concat_map f l
```

For better efficiency on long lists, here is a tail-recursive version:

```ocaml env=ch6
let concat_map f l =
  let rec cmap_f accu = function
    | [] -> accu
    | a::l -> cmap_f (List.rev_append (f a) accu) l in
  List.rev (cmap_f [] l)
```

The `concat_map` function is fundamental for backtracking algorithms. We will use it extensively in the puzzle-solving sections below.

#### All Subsequences of a List

A classic example of a function that produces multiple results: given a list, generate all its subsequences (subsets that preserve order). The idea is simple: for each element, we either include it or exclude it.

```ocaml env=ch6
let rec subseqs l =
  match l with
    | [] -> [[]]
    | x::xs ->
      let pxs = subseqs xs in
      List.map (fun px -> x::px) pxs @ pxs
```

Using a tail-recursive mapping helper (the call to `subseqs` itself is still not in tail position):

```ocaml env=ch6
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

#### Permutations and Choices

Generating all permutations of a list is another classic combinatorial problem. The key insight is the `interleave` function: given an element `x` and a list, it produces all ways of inserting `x` into the list:

```ocaml env=ch6
let rec interleave x = function
  | [] -> [[x]]                 (* x can only go in one place: by itself *)
  | y::ys ->
    (x::y::ys)                  (* x goes at the front, OR *)
    :: List.map (fun zs -> y::zs) (interleave x ys)  (* x goes somewhere after y *)

let rec perms = function
  | [] -> [[]]                  (* one way to permute empty list: empty list *)
  | x::xs -> concat_map (interleave x) (perms xs)
```

For example, `interleave 1 [2;3]` produces `[[1;2;3]; [2;1;3]; [2;3;1]]` -- all positions where 1 can be inserted.

For the Countdown problem below, we will need all non-empty subsequences with all their permutations -- that is, all ways of choosing and ordering elements from a list:

```ocaml env=ch6
let choices l = concat_map perms (List.filter ((<>) []) (subseqs l))
```

### 6.6 Grouping and Map-Reduce

When processing large datasets, it is often useful to organize values by some property -- grouping all items with the same key together, then processing each group. This pattern is so common it has a name: **map-reduce** (popularized by Google for distributed computing).

#### Collecting by Key

The first step is to collect elements from an association list, grouping all values that share the same key:

```ocaml env=ch6
let collect l =
  match List.sort (fun x y -> compare (fst x) (fst y)) l with
  | [] -> []                           (* Start with associations sorted by key *)
  | (k0, v0)::tl ->
    let k0, vs, l = List.fold_left
      (fun (k0, vs, l) (kn, vn) ->     (* Collect values for current key *)
        if k0 = kn then k0, vn::vs, l  (* Same key: add value to current group *)
        else kn, [vn], (k0, List.rev vs)::l) (* New: save current group, start new *)
      (k0, [v0], []) tl in             (* Why reverse? To preserve original order *)
    List.rev ((k0, List.rev vs)::l)
```

Now we can group elements by an arbitrary property -- we just need to extract the property as the key:

```ocaml env=ch6
let group_by p l = collect (List.map (fun e -> p e, e) l)
```

#### Reduction (Aggregation)

Grouping alone is often not enough -- we want to *aggregate* each group into a summary value, like SQL's `SUM`, `COUNT`, or `AVG`. This aggregation step is called **reduction**:

```ocaml env=ch6
let aggregate_by p red base l =
  let ags = group_by p l in
  List.map (fun (k, vs) -> k, List.fold_right red vs base) ags
```

Using the **feed-forward** (pipe) operator `let ( |> ) x f = f x`:

```ocaml env=ch6
let aggregate_by p redf base l =
  group_by p l
  |> List.map (fun (k, vs) -> k, List.fold_right redf vs base)
```

Often it is cleaner to extract both the key and the value we care about upfront, before grouping. Since we first **map** elements into key-value pairs, then group and **reduce**, we call this pattern `map_reduce`:

```ocaml env=ch6
let map_reduce mapf redf base l =
  List.map mapf l
  |> collect
  |> List.map (fun (k, vs) -> k, List.fold_right redf vs base)
```

#### Map-Reduce Examples

Sometimes our mapping function produces multiple key-value pairs per input (for example, when processing documents word by word). For this we use `concat_reduce`, which uses `concat_map` instead of `map`:

```ocaml env=ch6
let concat_reduce mapf redf base l =
  concat_map mapf l
  |> collect
  |> List.map (fun (k, vs) -> k, List.fold_right redf vs base)
```

**Example 1: Word histogram.** Count how many times each word appears across a collection of documents:

```ocaml env=ch6
let histogram documents =
  let mapf doc =
    Str.split (Str.regexp "[ \t.,;]+") doc
    |> List.map (fun word -> word, 1) in
  concat_reduce mapf (+) 0 documents
```

**Example 2: Inverted index.** Build an index mapping each word to the list of documents (identified by address) containing it:

```ocaml env=ch6
let cons hd tl = hd::tl

let inverted_index documents =
  let mapf (addr, doc) =
    Str.split (Str.regexp "[ \t.,;]+") doc
    |> List.map (fun word -> word, addr) in
  concat_reduce mapf cons [] documents
  |> List.map (fun (word, addresses) -> word, List.sort_uniq compare addresses)
```

**Example 3: Simple search engine.** Once we have an inverted index, we can search for documents containing all of a given set of words. We need set intersection -- here implemented for sets represented as sorted lists:

```ocaml env=ch6
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

Now we can build a simple search function that finds all documents containing every word in a query:

```ocaml env=ch6
let search index words =
  match List.map (fun word ->
    Option.value (List.assoc_opt word index) ~default:[]) words with
  | [] -> []
  | idx::idcs -> List.fold_left intersect idx idcs
```

### 6.7 Higher-Order Functions for the Option Type

The `option` type is OCaml's way of representing values that might be absent. Rather than using null pointers (a common source of bugs), we explicitly mark possibly-missing values with `Some x` or `None`. Here are some useful higher-order functions for working with options.

First, applying a function that may fail to an optional value (this is a monadic bind, also called `flatmap`---the function `f` itself returns an `option`):

```ocaml env=ch6
let map_option f = function
  | None -> None
  | Some e -> f e
```

Second, mapping a partial function over a list and keeping only the successful results:

```ocaml env=ch6
let rec map_some f = function
  | [] -> []
  | e::l -> match f e with
    | None -> map_some f l
    | Some r -> r :: map_some f l
```

Tail-recursively:

```ocaml env=ch6
let map_some f l =
  let rec maps_f accu = function
    | [] -> accu
    | a::l -> maps_f (match f a with None -> accu
      | Some r -> r::accu) l in
  List.rev (maps_f [] l)
```

### 6.8 The Countdown Problem Puzzle

Now we turn to solving puzzles, which will showcase the power of backtracking with lists. The **Countdown Problem** is a classic puzzle from a British TV game show:

- Using a given set of numbers and arithmetic operators +, -, *, /, construct an expression with a given value.
- All numbers, including intermediate results, must be positive integers.
- Each source number can be used at most once.

**Example:**
- Source numbers: 1, 3, 7, 10, 25, 50
- Target: 765
- One possible solution: (25-10) * (50+1) = 15 * 51 = 765

We will compare solvers on small inputs before attempting this larger search.

Let us develop a solver step by step, starting with the data types.

#### Data Types

```ocaml env=ch6
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

let rec remove_one x = function
  | [] -> None
  | y::ys when x = y -> Some ys
  | y::ys -> Option.map (fun rest -> y::rest) (remove_one x ys)

let rec uses_available numbers available =
  match numbers with
  | [] -> true
  | x::xs ->
      match remove_one x available with
      | None -> false
      | Some rest -> uses_available xs rest

let solution e ns n =
  uses_available (values e) ns && eval e = Some n
```

The source numbers form a multiset: equal numbers may be used as many times as they occur, but no more.

```ocaml env=ch6
let () =
  let two = App (Add, Val 1, Val 1) in
  assert (solution two [1; 1] 2);
  assert (not (solution two [1] 2))
```

#### Brute Force Solution

Our strategy is to generate all possible expressions from the source numbers, then filter for those that evaluate to the target. To build expressions, we need to split the numbers into two groups (for the left and right operands of an operator).

First, a helper to split a list into two non-empty parts in all possible ways:

```ocaml env=ch6
let split l =
  let rec aux lhs acc = function
    | [] | [_] -> []
    | [y; z] -> (List.rev (y::lhs), [z])::acc
    | hd::rhs ->
      let lhs = hd::lhs in
      aux lhs ((List.rev lhs, rhs)::acc) rhs in
  aux [] [] l
```

We introduce a convenient operator for working with multiple data sources. The "bind" operator `|->` takes a list of values and a function that produces a list from each value, then concatenates all results:

```ocaml env=ch6
let ( |-> ) x f = concat_map f x
```

Now we can generate all expressions from a list of numbers. The structure records each branch of the backtracking search:

```ocaml env=ch6
let combine l r =                  (* Combine two expressions using each operator *)
  List.map (fun o -> App (o, l, r)) [Add; Sub; Mul; Div]

let rec exprs = function
  | [] -> []                       (* No expressions from empty list *)
  | [n] -> [Val n]                 (* Single number: just Val n *)
  | ns ->
    split ns |-> (fun (ls, rs) ->  (* For each way to split numbers... *)
      exprs ls |-> (fun l ->       (* ...for each expression l from left half... *)
        exprs rs |-> (fun r ->     (* ...for each expression r from right half... *)
          combine l r)))           (* ...produce all l op r combinations *)
```

Read the nested `|->` as "for each ... for each ... for each ...". This is the essence of backtracking: we explore all combinations systematically.

Finally, to find solutions, we try all choices of source numbers (all non-empty subsets with all orderings) and filter for expressions that evaluate to the target:

```ocaml env=ch6
let guard n =
  List.filter (fun e -> eval e = Some n)

let solutions ns n =
  choices ns |-> (fun ns' ->
    exprs ns' |> guard n)
```

#### Optimization: Fuse Generation with Testing

The brute force approach generates many invalid expressions (like `5 - 7` which gives a negative result, or `5 / 3` which is not an integer). We can do better by *fusing* generation with evaluation: instead of generating an expression and then checking if it is valid, we track the value alongside the expression and only generate valid subexpressions.

The key insight is to work with pairs `(e, eval e)` so that only valid subexpressions are ever generated:

```ocaml env=ch6
let combine' valid (l, x) (r, y) =
  [Add; Sub; Mul; Div]
  |> List.filter (fun o -> valid o x y)
  |> List.map (fun o -> App (o, l, r), apply o x y)

let rec results valid = function
  | [] -> []
  | [n] -> if n > 0 then [Val n, n] else []
  | ns ->
    split ns |-> (fun (ls, rs) ->
      results valid ls |-> (fun lx ->
        results valid rs |-> (fun ry ->
          combine' valid lx ry)))

let solutions_with valid ns n =
  choices ns |-> (fun ns' ->
    results valid ns'
    |> List.filter (fun (e, m) -> m = n)
    |> List.map fst)                        (* Discard memorized values *)

let solutions' = solutions_with valid
```

#### Eliminating Symmetric Cases

We can further improve performance by observing that addition and multiplication are commutative: `3 + 5` and `5 + 3` give the same result. Similarly, multiplying by 1 or adding/subtracting 0 are useless. We can eliminate these redundancies by strengthening the validity predicate:

```ocaml env=ch6
let valid op x y =
  match op with
  | Add -> x <= y
  | Sub -> x > y
  | Mul -> x <= y && x <> 1 && y <> 1
  | Div -> x mod y = 0 && y <> 1

let solutions_optimized = solutions_with valid
```

Passing the new predicate explicitly matters: rebinding `valid` alone would not change functions already defined with the earlier binding. `solutions_optimized` eliminates symmetrical solutions on the *semantic* level (based on values) rather than the *syntactic* level (based on expression structure). This approach is both easier to implement and more effective at pruning the search space.

```ocaml env=ch6
let () =
  let index = inverted_index [3, "cat cat dog"; 1, "dog cat"; 2, "dog"] in
  assert (search index ["cat"; "dog"] = [1; 3]);
  assert (search index ["missing"] = [])
```

### 6.9 A search contract before a speed claim

For Countdown, **soundness** says every returned expression uses an allowed
submultiset, has positive integer intermediate results, and reaches its target.
**Completeness** of the reference enumerator says every legal expression over
an allowed ordering appears. Induct on its syntax: a leaf comes from a singleton
choice; an internal node splits its leaf sequence into two nonempty parts and
chooses one of the four operators. Enumerating subsequences and permutations
supplies every allowed ordered leaf sequence. Duplicate source values can produce
duplicate syntax; they do not permit an extra use of an input occurrence.

Fusing generation with evaluation preserves all valid syntax. The stronger
predicate deliberately drops some syntax, so its claim is only preservation of
**reachable target values**, when using any nonempty submultiset. Sorting the
operands of a commutative operation preserves its value. Multiplication or division
by one can be removed by using fewer inputs. That reasoning would fail for a rule
requiring *every* input to be used. Integer overflow is outside the positive
mathematical-integer argument; use small inputs for these checks, or add checked
arithmetic before using this as a general solver.

```ocaml env=ch6
let () =
  let reachable xs =
    choices xs |> List.concat_map exprs |> List.filter_map eval
    |> List.sort_uniq compare in
  let fused xs =
    choices xs |> List.concat_map (results valid) |> List.map snd
    |> List.sort_uniq compare in
  List.iter (fun xs ->
    let expected = reachable xs in
    assert (fused xs = expected);
    List.iter (fun target ->
      assert (List.for_all (fun e -> solution e xs target)
        (solutions_optimized xs target));
      let syntax xs = List.sort_uniq compare xs in
      assert (syntax (solutions xs target) = syntax (solutions' xs target)))
      expected)
    [[1]; [1;1]; [1;2]; [2;3]; [1;2;3]; [2;2;3]]
```

The **Honey Islands project**, in `projects/honey/README.md`, compares direct,
pruned, monadic and state-transformer solvers against exhaustive subsets. It
includes a counterexample to the old “always keep the first seed” traversal.
That puzzle and its drawing infrastructure are optional; Countdown is the main
search case study here.

### 6.10 Exercises

1. **Practice.** Generate permutations of `[1;2;3]`, then of `[1;1;2]`.
   Distinguish positions from values. State whether duplicates are retained.
2. **Proof.** Prove the reconstruction law for the expression fold. Include `Let`;
   its binding name is unchanged even though both subexpressions are folded.
3. **Experiment.** Compare subtraction with `fold_left` and `fold_right` on
   `[1;2;3]` starting from zero. Explain why tail recursion alone does not justify
   replacing one fold with the other. Selected answer: the results are `-6` and `2`.
4. **Practice.** Use a fold to count syntactic variable occurrences, including
   bound occurrences. Then compute free variables: at `Let (x, value, body)`,
   remove `x` only from the body's set, not from the value's set.
5. **Proof.** Identify the induction hypotheses in the Countdown completeness
   argument. Explain why pruning `Mul 1 e` would be invalid if all inputs had
   to be used exactly once.
6. **Project.** Complete the Honey Islands project's extension and measurements.
   Its acceptance criteria require reference equivalence before performance data.
