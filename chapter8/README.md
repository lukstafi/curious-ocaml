## Chapter 8: Monads

This chapter explores one of functional programming's most powerful abstractions: monads. We begin with list comprehensions, introduce monadic concepts, examine monad laws and the monad-plus extension, then work through various monad instances including state, exception, and probability monads. We conclude with monad transformers and cooperative lightweight threads.

### 8.1 List Comprehensions

Recall the somewhat awkward syntax we used in the Countdown Problem example from earlier chapters. The brute-force generation of expressions looked like this:

```
let combine l r =
  List.map (fun o -> App (o, l, r)) [Add; Sub; Mul; Div]

let rec exprs = function
  | [] -> []
  | [n] -> [Val n]
  | ns ->
      split ns |-> (fun (ls, rs) ->
      exprs ls |-> (fun l ->
      exprs rs |-> (fun r ->
      combine l r)))
```

And the generate-and-test scheme used:

```
let guard p e = if p e then [e] else []

let solutions ns n =
  choices ns |-> (fun ns' ->
  exprs ns' |->
    guard (fun e -> eval e = Some n))
```

We introduced the operator `|->` defined as:

```
let ( |-> ) x f = concat_map f x
```

We can do much better with list comprehensions syntax extension. In older versions of OCaml with Camlp4, this was loaded via:

```
#load "dynlink.cma";;
#load "camlp4o.cma";;
#load "Camlp4Parsers/Camlp4ListComprehension.cmo";;
```

With list comprehensions, we can write:

```
let test = [i * 2 | i <- from_to 2 22; i mod 3 = 0]
```

The translation rules for list comprehensions are:

- `[expr | ]` translates to `[expr]`
- `[expr | v <- generator; more]` translates to `generator |-> (fun v -> [expr | more])`
- `[expr | condition; more]` translates to `if condition then [expr | more] else []`

#### Revisiting Countdown with List Comprehensions

The brute-force generation becomes cleaner:

```
let rec exprs = function
  | [] -> []
  | [n] -> [Val n]
  | ns ->
      [App (o, l, r) | (ls, rs) <- split ns;
       l <- exprs ls; r <- exprs rs;
       o <- [Add; Sub; Mul; Div]]
```

And the generate-and-test scheme simplifies to:

```
let solutions ns n =
  [e | ns' <- choices ns;
   e <- exprs ns'; eval e = Some n]
```

#### More List Comprehension Examples

Computing subsequences using list comprehensions (with some garbage generation):

```
let rec subseqs l =
  match l with
  | [] -> [[]]
  | x::xs -> [ys | px <- subseqs xs; ys <- [px; x::px]]
```

Computing permutations via insertion:

```
let rec insert x = function
  | [] -> [[x]]
  | y::ys' as ys ->
      (x::ys) :: [y::zs | zs <- insert x ys']

let rec ins_perms = function
  | [] -> [[]]
  | x::xs -> [zs | ys <- ins_perms xs; zs <- insert x ys]
```

And via selection:

```
let rec select = function
  | [x] -> [x, []]
  | x::xs -> (x, xs) :: [y, x::ys | y, ys <- select xs]

let rec sel_perms = function
  | [] -> [[]]
  | xs -> [x::ys | x, xs' <- select xs; ys <- sel_perms xs']
```

### 8.2 Generalized Comprehensions: Do-Notation

To use a more general syntax extension, we need `pa_monad`. With it, the expression generation code becomes:

```
let rec exprs = function
  | [] -> []
  | [n] -> [Val n]
  | ns ->
      perform with (|->) in
        (ls, rs) <-- split ns;
        l <-- exprs ls; r <-- exprs rs;
        o <-- [Add; Sub; Mul; Div];
        [App (o, l, r)]
```

The `perform` syntax does not directly support guards. If we try to write:

```
let solutions ns n =
  perform with (|->) in
    ns' <-- choices ns;
    e <-- exprs ns';
    eval e = Some n;  (* Error! *)
    e
```

We get an error because it expects a list, not a boolean. We can work around this by deciding whether to return anything:

```
let solutions ns n =
  perform with (|->) in
    ns' <-- choices ns;
    e <-- exprs ns';
    if eval e = Some n then [e] else []
```

For a general guard check function, we define:

```
let guard p = if p then [()] else []
```

And then:

```
let solutions ns n =
  perform with (|->) in
    ns' <-- choices ns;
    e <-- exprs ns';
    guard (eval e = Some n);
    [e]
```

### 8.3 Monads

A monad is a polymorphic type `'a monad` (or `'a Monad.t`) that supports at least two operations:

- `bind : 'a monad -> ('a -> 'b monad) -> 'b monad`
- `return : 'a -> 'a monad`
- The infix `>>=` is commonly used for `bind`: `let (>>=) a b = bind a b`

With `bind` in scope, we do not need the `with` clause in `perform`:

```ocaml
let bind a b = concat_map b a
let return x = [x]

let solutions ns n =
  perform
    ns' <-- choices ns;
    e <-- exprs ns';
    guard (eval e = Some n);
    return e
```

Why does `guard` look this way? Let us examine:

```ocaml
let fail = []
let guard p = if p then return () else fail
```

Steps in monadic computation are composed with `>>=` (like `|->` for lists). The key insight is:

- `[] |-> ...` does not produce anything -- as needed by guarding
- `[()] |-> ...` becomes `(fun _ -> ...) ()` which simply continues the computation unchanged

Throwing away the binding argument is common, with infix syntax `>>` in Haskell:

```ocaml
let (>>) m f = m >>= (fun _ -> f)
```

#### The Perform Syntax in Depth

The `perform` syntax translates as follows:

| Source | Translation |
|--------|-------------|
| `perform exp` | `exp` |
| `perform pat <-- exp; rest` | `bind exp (fun pat -> perform rest)` |
| `perform exp; rest` | `bind exp (fun _ -> perform rest)` |
| `perform let ... in rest` | `let ... in perform rest` |
| `perform rpt <-- exp; rest` | `bind exp (function \| rpt -> perform rest \| _ -> failwith "pattern match")` |
| `perform with b [and f] in body` | Uses `b` instead of `bind` and `f` instead of `failwith` |

It can be useful to redefine `let failwith _ = fail` so that pattern match failures behave like guard failures.

### 8.4 Monad Laws

A parametric data type is a monad only if its `bind` and `return` operations meet these axioms:

$$
\begin{aligned}
\text{bind}\ (\text{return}\ a)\ f &\approx f\ a & \text{(left identity)} \\
\text{bind}\ a\ (\lambda x.\text{return}\ x) &\approx a & \text{(right identity)} \\
\text{bind}\ (\text{bind}\ a\ (\lambda x.b))\ (\lambda y.c) &\approx \text{bind}\ a\ (\lambda x.\text{bind}\ b\ (\lambda y.c)) & \text{(associativity)}
\end{aligned}
$$

You should verify that these laws hold for our list monad:

```ocaml
let bind a b = concat_map b a
let return x = [x]
```

### 8.5 Monoid Laws and Monad-Plus

A monoid is a type with at least two operations:

- `mzero : 'a monoid`
- `mplus : 'a monoid -> 'a monoid -> 'a monoid`

that meet these laws:

$$
\begin{aligned}
\text{mplus}\ \text{mzero}\ a &\approx a & \text{(left identity)} \\
\text{mplus}\ a\ \text{mzero} &\approx a & \text{(right identity)} \\
\text{mplus}\ a\ (\text{mplus}\ b\ c) &\approx \text{mplus}\ (\text{mplus}\ a\ b)\ c & \text{(associativity)}
\end{aligned}
$$

We define `fail` as a synonym for `mzero` and infix `++` for `mplus`.

Fusing monads and monoids gives the most popular general flavor of monads, which we call **monad-plus** after Haskell. Monad-plus requires additional axioms relating its "addition" and "multiplication":

$$
\begin{aligned}
\text{bind}\ \text{mzero}\ f &\approx \text{mzero} \\
\text{bind}\ m\ (\lambda x.\text{mzero}) &\approx \text{mzero}
\end{aligned}
$$

Using infix notation with $\oplus$ for `mplus`, $\mathbf{0}$ for `mzero`, $\triangleright$ for `bind`, and $\mathbf{1}$ for `return`, the complete monad-plus axioms are:

$$
\begin{aligned}
\mathbf{0} \oplus a &\approx a \\
a \oplus \mathbf{0} &\approx a \\
a \oplus (b \oplus c) &\approx (a \oplus b) \oplus c \\
\mathbf{1}\ x \triangleright f &\approx f\ x \\
a \triangleright \lambda x.\mathbf{1}\ x &\approx a \\
(a \triangleright \lambda x.b) \triangleright \lambda y.c &\approx a \triangleright (\lambda x.b \triangleright \lambda y.c) \\
\mathbf{0} \triangleright f &\approx \mathbf{0} \\
a \triangleright (\lambda x.\mathbf{0}) &\approx \mathbf{0}
\end{aligned}
$$

The list type has a natural monad and monoid structure:

```ocaml
let mzero = []
let mplus = (@)
let bind a b = concat_map b a
let return a = [a]
```

We can define in any monad-plus:

```ocaml
let fail = mzero
let failwith _ = fail
let (++) = mplus
let (>>=) a b = bind a b
let guard p = if p then return () else fail
```

### 8.6 Backtracking: Computation with Choice

We have seen `mzero` (i.e., `fail`) in the countdown problem. What about `mplus`? Here is an example from a puzzle solver:

```ocaml
let find_to_eat n island_size num_islands empty_cells =
  let honey = honey_cells n empty_cells in

  let rec find_board s =
    match visit_cell s with
    | None ->
        perform
          guard (s.been_islands = num_islands);
          return s.eaten
    | Some (cell, s) ->
        perform
          s <-- find_island cell (fresh_island s);
          guard (s.been_size = island_size);
          find_board s

  and find_island current s =
    let s = keep_cell current s in
    neighbors n empty_cells current
    |> foldM
         (fun neighbor s ->
           if CellSet.mem neighbor s.visited then return s
           else
             let choose_eat =
               if s.more_to_eat <= 0 then fail
               else return (eat_cell neighbor s)
             and choose_keep =
               if s.been_size >= island_size then fail
               else find_island neighbor s in
             mplus choose_eat choose_keep)  (* Choice point! *)
         s in

  let cells_to_eat =
    List.length honey - island_size * num_islands in
  find_board (init_state honey cells_to_eat)
```

The `mplus choose_eat choose_keep` creates a choice point: either eat the cell or keep it as part of the island. The monad-plus structure handles backtracking automatically.

### 8.7 Monad Flavors

Monads "wrap around" a type, but some monads need an additional type parameter. Usually the additional type does not change while within a monad, so we stick to `'a monad` rather than `('s, 'a) monad`.

As monad-plus shows, things get interesting when we add more operations to a basic monad. Here are some common monad flavors:

**Monads with access:**

```ocaml
access : 'a monad -> 'a
```

Example: the lazy monad.

**Monad-plus (non-deterministic computation):**

```ocaml
mzero : 'a monad
mplus : 'a monad -> 'a monad -> 'a monad
```

**Monads with state (parameterized by type `store`):**

```ocaml
get : store monad
put : store -> unit monad
```

There is a "canonical" state monad. Similar monads include the writer monad (with `get` called `listen` and `put` called `tell`) and the reader monad, without `put`, but with `get` (called `ask`) and:

```ocaml
local : (store -> store) -> 'a monad -> 'a monad
```

**Exception/error monads (parameterized by type `excn`):**

```ocaml
throw : excn -> 'a monad
catch : 'a monad -> (excn -> 'a monad) -> 'a monad
```

**Continuation monad:**

```ocaml
callCC : (('a -> 'b monad) -> 'a monad) -> 'a monad
```

We will not cover continuations in detail here.

**Probabilistic computation:**

```ocaml
choose : float -> 'a monad -> 'a monad -> 'a monad
```

satisfying the laws with $a \oplus_p b$ for `choose p a b` and $p \cdot q$ for `p *. q`, where $0 \leq p, q \leq 1$:

$$
\begin{aligned}
a \oplus_0 b &\approx b \\
a \oplus_p b &\approx b \oplus_{1-p} a \\
a \oplus_p (b \oplus_q c) &\approx (a \oplus_{\frac{p}{p+q-pq}} b) \oplus_{p+q-pq} c \\
a \oplus_p a &\approx a
\end{aligned}
$$

**Parallel computation (monad with access and parallel bind):**

```ocaml
parallel : 'a monad -> 'b monad -> ('a -> 'b -> 'c monad) -> 'c monad
```

Example: lightweight threads.

### 8.8 Interlude: The Module System

OCaml's module system provides the infrastructure for defining monads in a reusable way. Here is a brief overview of the key concepts.

Modules collect related type definitions and operations together. Module values are introduced with `struct ... end` (structures), and module types with `sig ... end` (signatures). A structure is a package of definitions; a signature is an interface for packages.

A source file `source.ml` defines a module `Source`. A file `source.mli` defines its type.

In the module level, modules are defined with `module ModuleName = ...` or `module ModuleName : MODULE_TYPE = ...`, and module types with `module type MODULE_TYPE = ...`.

Locally in expressions, modules are defined with `let module M = ... in ...`.

The content of a module is made visible with `open Module`. Module `Pervasives` (now `Stdlib`) is initially visible.

Content of a module is included into another module with `include Module`.

**Functors** are module functions -- functions from modules to modules:

```ocaml
module Funct = functor (Arg : sig ... end) -> struct ... end
(* Or equivalently: *)
module Funct (Arg : sig ... end) = struct ... end
```

Functors can return functors, and modules can be parameterized by multiple modules. Functor application always uses parentheses: `Funct (struct ... end)`.

A signature `MODULE_TYPE with type t_name = ...` is like `MODULE_TYPE` but with `t_name` made more specific. We can also include signatures with `include MODULE_TYPE`.

Finally, we can pass around modules in normal functions using first-class modules:

```ocaml
module type T = sig val g : int -> int end

let f mod_v x =
  let module M = (val mod_v : T) in
  M.g x
(* val f : (module T) -> int -> int = <fun> *)

let test = f (module struct let g i = i*i end : T)
(* val test : int -> int = <fun> *)
```

### 8.9 The Two Metaphors

Monads can be understood through two complementary metaphors.

#### Monads as Containers

A monad is a **quarantine container**:

- We can put something into the container with `return`
- We can operate on it, but the result needs to stay in the container

```ocaml
let lift f m = perform x <-- m; return (f x)
(* val lift : ('a -> 'b) -> 'a monad -> 'b monad *)
```

- We can deactivate-unwrap the quarantine container but only when it is in another container so the quarantine is not broken

```ocaml
let join m = perform x <-- m; x
(* val join : ('a monad) monad -> 'a monad *)
```

The quarantine container for a **monad-plus** is more like other containers: it can be empty, or contain multiple elements.

Monads with access allow us to extract the resulting element from the container; other monads provide a `run` operation that exposes "what really happened behind the quarantine."

#### Monads as Computation

To compute the result, `perform` instructions, naming partial results. The physical metaphor is an **assembly line**:

```ocaml
let assemblyLine w =
  perform
    c <-- makeChopsticks w;   (* Worker makes chopsticks *)
    c' <-- polishChopsticks c; (* Worker polishes them *)
    c'' <-- wrapChopsticks c'; (* Worker wraps them *)
    return c''                 (* Loader returns the result *)
```

Any expression can be spread over a monad. For lambda-terms:

$$
\begin{aligned}
\llbracket N \rrbracket &= \text{return}\ N & \text{(constant)} \\
\llbracket x \rrbracket &= \text{return}\ x & \text{(variable)} \\
\llbracket \lambda x.a \rrbracket &= \text{return}\ (\lambda x.\llbracket a \rrbracket) & \text{(function)} \\
\llbracket \text{let}\ x = a\ \text{in}\ b \rrbracket &= \text{bind}\ \llbracket a \rrbracket\ (\lambda x.\llbracket b \rrbracket) & \text{(local definition)} \\
\llbracket a\ b \rrbracket &= \text{bind}\ \llbracket a \rrbracket\ (\lambda v_a.\text{bind}\ \llbracket b \rrbracket\ (\lambda v_b.v_a\ v_b)) & \text{(application)}
\end{aligned}
$$

When an expression is spread over a monad, its computation can be monitored or affected without modifying the expression.

### 8.10 Monad Classes and Instances

To implement a monad, we need to provide the implementation type, `return`, and `bind` operations.

```ocaml
module type MONAD = sig
  type 'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
end
```

Alternatively, we could start from `return`, `lift`, and `join` operations.

Based on just these two operations, we can define a suite of general-purpose functions:

```ocaml
module type MONAD_OPS = sig
  type 'a monad
  include MONAD with type 'a t := 'a monad
  val ( >>= ) : 'a monad -> ('a -> 'b monad) -> 'b monad
  val foldM : ('a -> 'b -> 'a monad) -> 'a -> 'b list -> 'a monad
  val whenM : bool -> unit monad -> unit monad
  val lift : ('a -> 'b) -> 'a monad -> 'b monad
  val (>>|) : 'a monad -> ('a -> 'b) -> 'b monad
  val join : 'a monad monad -> 'a monad
  val ( >=>) : ('a -> 'b monad) -> ('b -> 'c monad) -> 'a -> 'c monad
end

module MonadOps (M : MONAD) = struct
  open M
  type 'a monad = 'a t
  let run x = x
  let (>>=) a b = bind a b
  let rec foldM f a = function
    | [] -> return a
    | x::xs -> f a x >>= fun a' -> foldM f a' xs
  let whenM p s = if p then s else return ()
  let lift f m = perform x <-- m; return (f x)
  let (>>|) a b = lift b a
  let join m = perform x <-- m; x
  let (>=>) f g = fun x -> f x >>= g
end
```

We make the monad "safe" by keeping its type abstract, but `run` exposes "what really happened":

```ocaml
module Monad (M : MONAD) : sig
  include MONAD_OPS
  val run : 'a monad -> 'a M.t
end = struct
  include M
  include MonadOps(M)
end
```

#### Monad-Plus Classes

The monad-plus class has many implementations. They need to provide `mzero` and `mplus`:

```ocaml
module type MONAD_PLUS = sig
  include MONAD
  val mzero : 'a t
  val mplus : 'a t -> 'a t -> 'a t
end

module type MONAD_PLUS_OPS = sig
  include MONAD_OPS
  val mzero : 'a monad
  val mplus : 'a monad -> 'a monad -> 'a monad
  val fail : 'a monad
  val (++) : 'a monad -> 'a monad -> 'a monad
  val guard : bool -> unit monad
  val msum_map : ('a -> 'b monad) -> 'a list -> 'b monad
end

module MonadPlusOps (M : MONAD_PLUS) = struct
  open M
  include MonadOps(M)
  let fail = mzero
  let (++) a b = mplus a b
  let guard p = if p then return () else fail
  let msum_map f l = List.fold_right
    (fun a acc -> mplus (f a) acc) l mzero
end

module MonadPlus (M : MONAD_PLUS) : sig
  include MONAD_PLUS_OPS
  val run : 'a monad -> 'a M.t
end = struct
  include M
  include MonadPlusOps(M)
end
```

We also need a class for computations with state:

```ocaml
module type STATE = sig
  type store
  type 'a t
  val get : store t
  val put : store -> unit t
end
```

### 8.11 Monad Instances

#### The Lazy Monad

Heavy laziness notation? Try a monad (with access):

```ocaml
module LazyM = Monad (struct
  type 'a t = 'a Lazy.t
  let bind a b = lazy (Lazy.force (b (Lazy.force a)))
  let return a = lazy a
end)

let laccess m = Lazy.force (LazyM.run m)
```

#### The List Monad

Our resident list monad (monad-plus):

```ocaml
module ListM = MonadPlus (struct
  type 'a t = 'a list
  let bind a b = concat_map b a
  let return a = [a]
  let mzero = []
  let mplus = List.append
end)
```

#### Backtracking Parameterized by Monad-Plus

The Countdown module can be parameterized by any monad-plus:

```ocaml
module Countdown (M : MONAD_PLUS_OPS) = struct
  open M  (* Open the module to make monad operations visible *)

  let rec insert x = function  (* All choice-introducing operations *)
    | [] -> return [x]          (* need to happen in the monad *)
    | y::ys as xs ->
        return (x::xs) ++
          perform xys <-- insert x ys; return (y::xys)

  let rec choices = function
    | [] -> return []
    | x::xs -> perform
        cxs <-- choices xs;           (* Choosing which numbers in what order *)
        return cxs ++ insert x cxs    (* and now whether with or without x *)

  type op = Add | Sub | Mul | Div

  let apply op x y =
    match op with
    | Add -> x + y
    | Sub -> x - y
    | Mul -> x * y
    | Div -> x / y

  let valid op x y =
    match op with
    | Add -> x <= y
    | Sub -> x > y
    | Mul -> x <= y && x <> 1 && y <> 1
    | Div -> x mod y = 0 && y <> 1

  type expr = Val of int | App of op * expr * expr

  let op2str = function
    | Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/"

  let rec expr2str = function  (* We will provide solutions as strings *)
    | Val n -> string_of_int n
    | App (op, l, r) -> "(" ^ expr2str l ^ op2str op ^ expr2str r ^ ")"

  let combine (l, x) (r, y) o = perform  (* Try out an operator *)
    guard (valid o x y);
    return (App (o, l, r), apply o x y)

  let split l =  (* Another choice: which numbers go into which argument *)
    let rec aux lhs = function
      | [] | [_] -> fail                    (* Both arguments need numbers *)
      | [y; z] -> return (List.rev (y::lhs), [z])
      | hd::rhs ->
          let lhs = hd::lhs in
          return (List.rev lhs, rhs)
            ++ aux lhs rhs in
    aux [] l

  let rec results = function  (* Build possible expressions once numbers *)
    | [] -> fail                (* have been picked *)
    | [n] -> perform
        guard (n > 0); return (Val n, n)
    | ns -> perform
        (ls, rs) <-- split ns;
        lx <-- results ls;
        ly <-- results rs;  (* Collect solutions using each operator *)
        msum_map (combine lx ly) [Add; Sub; Mul; Div]

  let solutions ns n = perform  (* Solve the problem: *)
      ns' <-- choices ns;         (* pick numbers and their order, *)
      (e, m) <-- results ns';     (* build possible expressions, *)
      guard (m = n);              (* check if the expression gives target value, *)
      return (expr2str e)         (* "print" the solution *)
end
```

#### Understanding Laziness

Let us measure execution times:

```ocaml
let time f =
  let tbeg = Unix.gettimeofday () in
  let res = f () in
  let tend = Unix.gettimeofday () in
  tend -. tbeg, res
```

With the list monad:

```ocaml
module ListCountdown = Countdown (ListM)
let test1 () = ListM.run (ListCountdown.solutions [1;3;7;10;25;50] 765)
let t1, sol1 = time test1
(* val t1 : float = 2.28... *)
(* val sol1 : string list = ["((25-(3+7))*(1+50))"; "(((25-3)-7)*(1+50))"; ...] *)
```

What if we want only one solution? Laziness to the rescue! We define an "odd lazy list":

```ocaml
type 'a llist = LNil | LCons of 'a * 'a llist Lazy.t

let rec ltake n = function
  | LCons (a, lazy l) when n > 0 -> a::(ltake (n-1) l)
  | _ -> []

let rec lappend l1 l2 =
  match l1 with
  | LNil -> l2
  | LCons (hd, tl) ->
      LCons (hd, lazy (lappend (Lazy.force tl) l2))

let rec lconcat_map f = function
  | LNil -> LNil
  | LCons (a, lazy l) ->
      lappend (f a) (lconcat_map f l)

module LListM = MonadPlus (struct
  type 'a t = 'a llist
  let bind a b = lconcat_map b a
  let return a = LCons (a, lazy LNil)
  let mzero = LNil
  let mplus = lappend
end)
```

Testing shows that the odd lazy list still takes about the same time to even get the lazy list started! The elements are almost already computed once the first one is.

The **option monad** does not help either:

```ocaml
module OptionM = MonadPlus (struct
  type 'a t = 'a option
  let bind a b =
    match a with None -> None | Some x -> b x
  let return a = Some a
  let mzero = None
  let mplus a b = match a with None -> b | Some _ -> a
end)
```

This very quickly computes... nothing. The `OptionM` monad (Haskell's `Maybe` monad) is good for computations that might fail, but not for search with multiple solutions.

Our lazy list type is not lazy enough. Whenever we "make" a choice with `a ++ b` or `msum_map`, it computes the first candidate for each choice path immediately.

We need **even lazy lists** (our `llist` above are called "odd lazy lists"):

```ocaml
type 'a lazy_list = 'a lazy_list_ Lazy.t
and 'a lazy_list_ = LazNil | LazCons of 'a * 'a lazy_list

let rec laztake n = function
  | lazy (LazCons (a, l)) when n > 0 -> a::(laztake (n-1) l)
  | _ -> []

let rec append_aux l1 l2 =
  match l1 with
  | lazy LazNil -> Lazy.force l2
  | lazy (LazCons (hd, tl)) ->
      LazCons (hd, lazy (append_aux tl l2))

let lazappend l1 l2 = lazy (append_aux l1 l2)

let rec concat_map_aux f = function
  | lazy LazNil -> LazNil
  | lazy (LazCons (a, l)) ->
      append_aux (f a) (lazy (concat_map_aux f l))

let lazconcat_map f l = lazy (concat_map_aux f l)

module LazyListM = MonadPlus (struct
  type 'a t = 'a lazy_list
  let bind a b = lazconcat_map b a
  let return a = lazy (LazCons (a, lazy LazNil))
  let mzero = lazy LazNil
  let mplus = lazappend
end)
```

Now the first solution takes considerably less time than all solutions. The next 9 solutions are almost computed once the first one is. But computing all solutions takes nearly twice as long as without the overhead of lazy computation -- the price of laziness.

#### The Exception Monad

Built-in non-functional exceptions in OCaml are more efficient and more flexible. However, monadic exceptions are safer than standard exceptions in situations like multi-threading. The monadic lightweight-thread library Lwt has `throw` (called `fail` there) and `catch` operations in its monad.

```ocaml
module ExceptionM (Excn : sig type t end) : sig
  type excn = Excn.t
  type 'a t = OK of 'a | Bad of excn
  include MONAD_OPS
  val run : 'a monad -> 'a t
  val throw : excn -> 'a monad
  val catch : 'a monad -> (excn -> 'a monad) -> 'a monad
end = struct
  type excn = Excn.t
  module M = struct
    type 'a t = OK of 'a | Bad of excn
    let return a = OK a
    let bind m b = match m with
      | OK a -> b a
      | Bad e -> Bad e
  end
  include M
  include MonadOps(M)
  let throw e = Bad e
  let catch m handler = match m with
    | OK _ -> m
    | Bad e -> handler e
end
```

#### The State Monad

```ocaml
module StateM (Store : sig type t end) : sig
  type store = Store.t
  type 'a t = store -> 'a * store  (* Pass the current store value to get the next value *)
  include MONAD_OPS
  include STATE with type 'a t := 'a monad
                 and type store := store
  val run : 'a monad -> 'a t
end = struct
  type store = Store.t
  module M = struct
    type 'a t = store -> 'a * store
    let return a = fun s -> a, s     (* Keep the current value unchanged *)
    let bind m b = fun s -> let a, s' = m s in b a s'
  end                                (* To bind two steps, pass the value after first step to the second step *)
  include M
  include MonadOps(M)
  let get = fun s -> s, s            (* Keep the value unchanged but put it in monad *)
  let put s' = fun _ -> (), s'       (* Change the value; a throwaway in monad *)
end
```

The state monad is useful to hide passing-around of a "current" value. Here is an example that renames variables in lambda-terms to eliminate potential name clashes:

```ocaml
type term =
  | Var of string
  | Lam of string * term
  | App of term * term

let (!) x = Var x
let (|->) x t = Lam (x, t)
let (@) t1 t2 = App (t1, t2)
let test = "x" |-> ("x" |-> !"y" @ !"x") @ !"x"

module S = StateM (struct type t = int * (string * string) list end)
open S

let rec alpha_conv = function
  | Var x as v -> perform              (* Function from terms to StateM monad *)
      (_, env) <-- get;                (* Seeing a variable does not change state *)
      let v = try Var (List.assoc x env)  (* but we need its new name *)
        with Not_found -> v in         (* Free variables don't change name *)
      return v
  | Lam (x, t) -> perform              (* We rename each bound variable *)
      (fresh, env) <-- get;            (* We need a fresh number *)
      let x' = x ^ string_of_int fresh in
      put (fresh+1, (x, x')::env);     (* Remember new name, update number *)
      t' <-- alpha_conv t;
      (fresh', _) <-- get;             (* We need to restore names, *)
      put (fresh', env);               (* but keep the number fresh *)
      return (Lam (x', t'))
  | App (t1, t2) -> perform
      t1 <-- alpha_conv t1;            (* Passing around of names *)
      t2 <-- alpha_conv t2;            (* and the currently fresh number *)
      return (App (t1, t2))            (* is done by the monad *)

(* val test : term = Lam ("x", App (Lam ("x", App (Var "y", Var "x")), Var "x")) *)
(* # StateM.run (alpha_conv test) (5, []);;
   - : term * (int * (string * string) list) =
   (Lam ("x5", App (Lam ("x6", App (Var "y", Var "x6")), Var "x5")), (7, [])) *)
```

Note: This does not make a lambda-term safe for multiple steps of beta-reduction. Can you find a counter-example?

### 8.12 Monad Transformers

Sometimes we need merits of multiple monads at the same time, e.g., monads `AM` and `BM`. The straightforward idea is to nest one monad within another: either `'a AM.monad BM.monad` or `'a BM.monad AM.monad`. But we want a monad that has operations of both `AM` and `BM`.

It turns out that the straightforward approach does not lead to operations with the meaning we want. A **monad transformer** `AT` takes a monad `BM` and turns it into a monad `AT(BM)` which actually wraps around `BM` on both sides. `AT(BM)` has operations of both monads.

We will develop a monad transformer `StateT` which adds state to a monad-plus. The resulting monad has all: `return`, `bind`, `mzero`, `mplus`, `put`, `get`, and their supporting general-purpose functions.

We need monad transformers in OCaml because "monads are contagious": although we have built-in state and exceptions, we need to use monadic state and exceptions when we are inside a monad. This is the reason Lwt is both a concurrency and an exception monad.

The state monad uses `let x = a in ...` for binding. The transformed monad uses `M.bind` instead:

```ocaml
type 'a state = store -> ('a * store)

let return (a : 'a) : 'a state =
  fun s -> (a, s)

let bind (u : 'a state) (f : 'a -> 'b state) : 'b state =
  fun s -> (fun (a, s') -> f a s') (u s)

(* Monad M transformed to add state, in pseudo-code: *)
type 'a stateT(M) = store -> ('a * store) M
(* notice this is not an ('a M) state *)

let return (a : 'a) : 'a stateT(M) =
  fun s -> M.return (a, s)           (* Rather than returning, M.return *)

let bind (u : 'a stateT(M)) (f : 'a -> 'b stateT(M)) : 'b stateT(M) =
  fun s -> M.bind (u s) (fun (a, s') -> f a s')  (* Rather than let-binding, M.bind *)
```

#### State Transformer Implementation

```ocaml
module StateT (MP : MONAD_PLUS_OPS) (Store : sig type t end) : sig
  type store = Store.t
  type 'a t = store -> ('a * store) MP.monad
  include MONAD_PLUS_OPS         (* Exporting all monad-plus operations *)
  include STATE with type 'a t := 'a monad
                 and type store := store  (* and state operations *)
  val run : 'a monad -> 'a t     (* Expose "what happened" -- resulting states *)
  val runT : 'a monad -> store -> 'a MP.monad
end = struct                     (* Run the state transformer -- get resulting values *)
  type store = Store.t
  module M = struct
    type 'a t = store -> ('a * store) MP.monad
    let return a = fun s -> MP.return (a, s)
    let bind m b = fun s ->
      MP.bind (m s) (fun (a, s') -> b a s')
    let mzero = fun _ -> MP.mzero            (* Lift the monad-plus operations *)
    let mplus ma mb = fun s -> MP.mplus (ma s) (mb s)
  end
  include M
  include MonadPlusOps(M)
  let get = fun s -> MP.return (s, s)        (* Instead of just returning, *)
  let put s' = fun _ -> MP.return ((), s')   (* MP.return *)
  let runT m s = MP.lift fst (m s)
end
```

#### Backtracking with State

Using the state transformer with our puzzle solver:

```ocaml
module HoneyIslands (M : MONAD_PLUS_OPS) = struct
  type state = {
    been_size : int;
    been_islands : int;
    unvisited : cell list;
    visited : CellSet.t;
    eaten : cell list;
    more_to_eat : int;
  }

  let init_state unvisited more_to_eat = {
    been_size = 0;
    been_islands = 0;
    unvisited;
    visited = CellSet.empty;
    eaten = [];
    more_to_eat;
  }

  module BacktrackingM = StateT (M) (struct type t = state end)
  open BacktrackingM

  let rec visit_cell () = perform    (* State update actions *)
    s <-- get;
    match s.unvisited with
    | [] -> return None
    | c::remaining when CellSet.mem c s.visited -> perform
        put {s with unvisited=remaining};
        visit_cell ()                 (* Throwaway argument because of recursion *)
    | c::remaining -> perform
        put {s with
          unvisited=remaining;
          visited = CellSet.add c s.visited};
        return (Some c)               (* This action returns a value *)

  let eat_cell c = perform
    s <-- get;
    put {s with eaten = c::s.eaten;
         visited = CellSet.add c s.visited;
         more_to_eat = s.more_to_eat - 1};
    return ()                         (* Remaining state update actions just affect the state *)

  let keep_cell c = perform
    s <-- get;
    put {s with
      visited = CellSet.add c s.visited;
      been_size = s.been_size + 1};
    return ()

  let fresh_island = perform
    s <-- get;
    put {s with been_size = 0;
         been_islands = s.been_islands + 1};
    return ()

  let find_to_eat n island_size num_islands empty_cells =
    let honey = honey_cells n empty_cells in
    let rec find_board () = perform
      cell <-- visit_cell ();
      match cell with
      | None -> perform
          s <-- get;
          guard (s.been_islands = num_islands);
          return s.eaten
      | Some cell -> perform
          fresh_island;
          find_island cell;
          s <-- get;
          guard (s.been_size = island_size);
          find_board ()

    and find_island current = perform
      keep_cell current;
      neighbors n empty_cells current
      |> foldM
           (fun () neighbor -> perform
              s <-- get;
              whenM (not (CellSet.mem neighbor s.visited))
                (let choose_eat = perform
                   guard (s.more_to_eat > 0);
                   eat_cell neighbor
                 and choose_keep = perform
                   guard (s.been_size < island_size);
                   find_island neighbor in
                 choose_eat ++ choose_keep)) () in

    let cells_to_eat =
      List.length honey - island_size * num_islands in
    init_state honey cells_to_eat
    |> runT (find_board ())
end

module HoneyL = HoneyIslands (ListM)
let find_to_eat a b c d =
  ListM.run (HoneyL.find_to_eat a b c d)
```

### 8.13 Probabilistic Programming

Using a random number generator, we can define procedures that produce various output. This is **not functional** -- mathematical functions have a deterministic result for fixed arguments.

Similarly to how we can "simulate" (mutable) variables with state monad and non-determinism with list monad, we can "simulate" random computation with a probability monad.

The probability monad class means much more than having randomized computation. We can ask questions about probabilities of results. Monad instances can make tradeoffs of efficiency vs. accuracy (exact vs. approximate probabilities).

#### The Probability Monad

The essential functions for the probability monad class are `choose` and `distrib`. Remaining functions could be defined in terms of these but are provided by each instance for efficiency.

Inside-monad operations:

- `choose : float -> 'a monad -> 'a monad -> 'a monad`: `choose p a b` represents an event or distribution which is `a` with probability $p$ and is `b` with probability $1-p$.
- `pick : ('a * float) list -> 'a monad`: A result from the provided distribution over values. The argument must be a probability distribution: positive values summing to 1.
- `uniform : 'a list -> 'a monad`: Uniform distribution over given values.
- `flip : float -> bool monad`: Equal to `choose p (return true) (return false)`.
- `coin : bool monad`: Equal to `flip 0.5`.

Outside-monad operations:

- `prob : ('a -> bool) -> 'a monad -> float`: Returns the probability that the predicate holds.
- `distrib : 'a monad -> ('a * float) list`: Returns the distribution of probabilities over the resulting values.
- `access : 'a monad -> 'a`: Samples a random result from the distribution -- **non-functional** behavior.

```ocaml
module type PROBABILITY = sig
  include MONAD_OPS
  val choose : float -> 'a monad -> 'a monad -> 'a monad
  val pick : ('a * float) list -> 'a monad
  val uniform : 'a list -> 'a monad
  val coin : bool monad
  val flip : float -> bool monad
  val prob : ('a -> bool) -> 'a monad -> float
  val distrib : 'a monad -> ('a * float) list
  val access : 'a monad -> 'a
end
```

Helper functions:

```ocaml
let total dist =
  List.fold_left (fun a (_,b) -> a +. b) 0. dist

let merge dist = map_reduce (fun x -> x) (+.) 0. dist  (* Merge repeating elements *)

let normalize dist =                     (* Normalize a measure into a distribution *)
  let tot = total dist in
  if tot = 0. then dist
  else List.map (fun (e,w) -> e, w /. tot) dist

let roulette dist =                      (* Roulette wheel from a distribution/measure *)
  let tot = total dist in
  let rec aux r = function
    | [] -> assert false
    | (e, w)::_ when w <= r -> e
    | (_, w)::tl -> aux (r -. w) tl in
  aux (Random.float tot) dist
```

#### Exact Distribution Monad

```ocaml
module DistribM : PROBABILITY = struct
  module M = struct                      (* Exact probability distribution -- naive implementation *)
    type 'a t = ('a * float) list
    let bind a b = merge              (* x w.p. p and then y w.p. q happens = *)
      [y, q *. p | (x, p) <- a; (y, q) <- b x]  (* y results w.p. p*q *)
    let return a = [a, 1.]               (* Certainly a *)
  end
  include M
  include MonadOps (M)
  let choose p a b =
    List.map (fun (e,w) -> e, p *. w) a @
      List.map (fun (e,w) -> e, (1. -. p) *. w) b
  let pick dist = dist
  let uniform elems = normalize
    (List.map (fun e -> e, 1.) elems)
  let coin = [true, 0.5; false, 0.5]
  let flip p = [true, p; false, 1. -. p]
  let prob p m = m
    |> List.filter (fun (e,_) -> p e)    (* All cases where p holds, *)
    |> List.map snd |> List.fold_left (+.) 0.  (* add up *)
  let distrib m = m
  let access m = roulette m
end
```

#### Sampling Monad

```ocaml
module SamplingM (S : sig val samples : int end) : PROBABILITY = struct
  module M = struct                      (* Parameterized by how many samples *)
    type 'a t = unit -> 'a               (* used to approximate prob or distrib *)
    let bind a b () = b (a ()) ()        (* Randomized computation -- each call a() *)
    let return a = fun () -> a           (* is an independent sample. Always a. *)
  end
  include M
  include MonadOps (M)
  let choose p a b () =
    if Random.float 1. <= p then a () else b ()
  let pick dist = fun () -> roulette dist
  let uniform elems =
    let n = List.length elems in
    fun () -> List.nth elems (Random.int n)
  let coin = Random.bool
  let flip p = choose p (return true) (return false)
  let prob p m =
    let count = ref 0 in
    for i = 1 to S.samples do
      if p (m ()) then incr count
    done;
    float_of_int !count /. float_of_int S.samples
  let distrib m =
    let dist = ref [] in
    for i = 1 to S.samples do
      dist := (m (), 1.) :: !dist done;
    normalize (merge !dist)
  let access m = m ()
end
```

#### Example: The Monty Hall Problem

In search of a new car, the player picks a door, say 1. The game host then opens one of the other doors, say 3, to reveal a goat and offers to let the player pick door 2 instead of door 1.

```ocaml
module MontyHall (P : PROBABILITY) = struct
  open P
  type door = A | B | C
  let doors = [A; B; C]

  let monty_win switch = perform
    prize <-- uniform doors;
    chosen <-- uniform doors;
    opened <-- uniform
      (list_diff doors [prize; chosen]);
    let final =
      if switch then List.hd
        (list_diff doors [opened; chosen])
      else chosen in
    return (final = prize)
end

module MontyExact = MontyHall (DistribM)
module Sampling1000 =
  SamplingM (struct let samples = 1000 end)
module MontySimul = MontyHall (Sampling1000)

(* DistribM.distrib (MontyExact.monty_win false);;
   - : (bool * float) list = [(true, 0.333...); (false, 0.666...)]

   DistribM.distrib (MontyExact.monty_win true);;
   - : (bool * float) list = [(true, 0.666...); (false, 0.333...)] *)
```

The famous result: switching doubles your chances of winning!

#### Conditional Probabilities

Wouldn't it be nice to have a monad-plus rather than just a monad? We could use `guard` for conditional probabilities!

To compute $P(A|B)$:
1. Compute what is needed for both $A$ and $B$
2. Guard $B$
3. Return $A$

For the exact distribution monad, we just need to allow intermediate distributions to be unnormalized (sum to less than 1). For the sampling monad, we use rejection sampling (though `mplus` has no straightforward correct implementation).

```ocaml
module type COND_PROBAB = sig
  include PROBABILITY
  include MONAD_PLUS_OPS with type 'a monad := 'a monad
end

module DistribMP : COND_PROBAB = struct
  module MP = struct
    type 'a t = ('a * float) list      (* Measures no longer restricted to *)
    let bind a b = merge               (* probability distributions *)
      [y, q *. p | (x, p) <- a; (y, q) <- b x]
    let return a = [a, 1.]
    let mzero = []                     (* Measure equal 0 everywhere is OK *)
    let mplus = List.append
  end
  include MP
  include MonadPlusOps (MP)
  let choose p a b =                   (* It isn't a w.p. p & b w.p. (1-p) since a and b *)
    List.map (fun (e,w) -> e, p *. w) a @  (* are not normalized! *)
      List.map (fun (e,w) -> e, (1. -. p) *. w) b
  let pick dist = dist
  let uniform elems = normalize
    (List.map (fun e -> e, 1.) elems)
  let coin = [true, 0.5; false, 0.5]
  let flip p = [true, p; false, 1. -. p]
  let prob p m = normalize m           (* Final normalization step *)
    |> List.filter (fun (e,_) -> p e)
    |> List.map snd |> List.fold_left (+.) 0.
  let distrib m = normalize m
  let access m = roulette m
end

module SamplingMP (S : sig val samples : int end) : COND_PROBAB = struct
  exception Rejected                   (* For rejecting current sample *)
  module MP = struct                   (* Monad operations are exactly as for SamplingM *)
    type 'a t = unit -> 'a
    let bind a b () = b (a ()) ()
    let return a = fun () -> a
    let mzero = fun () -> raise Rejected  (* but now we can fail *)
    let mplus a b = fun () ->
      failwith "SamplingMP.mplus not implemented"
  end
  include MP
  include MonadPlusOps (MP)
  let choose p a b () =                (* Inside-monad operations don't change *)
    if Random.float 1. <= p then a () else b ()
  let pick dist = fun () -> roulette dist
  let uniform elems =
    let n = List.length elems in
    fun () -> List.nth elems (Random.int n)
  let coin = Random.bool
  let flip p = choose p (return true) (return false)
  let prob p m =                       (* Getting out of monad: handle rejected samples *)
    let count = ref 0 and tot = ref 0 in
    while !tot < S.samples do          (* Count up to the required *)
      try                              (* number of samples *)
        if p (m ()) then incr count;   (* m() can fail *)
        incr tot                       (* But if we got here it hasn't *)
      with Rejected -> ()              (* Rejected, keep sampling *)
    done;
    float_of_int !count /. float_of_int S.samples
  let distrib m =
    let dist = ref [] and tot = ref 0 in
    while !tot < S.samples do
      try
        dist := (m (), 1.) :: !dist;
        incr tot
      with Rejected -> ()
    done;
    normalize (merge !dist)
  let rec access m =
    try m () with Rejected -> access m
end
```

#### Burglary Example: Encoding a Bayes Net

Consider a problem with this dependency structure:

- An alarm can be due to either a burglary or an earthquake
- You are on vacation and have asked neighbors John and Mary to call if the alarm rings
- Mary only calls when she is really sure about the alarm, but John has better hearing
- Earthquakes are twice as probable as burglaries
- The alarm has about 30% chance of going off during an earthquake
- You can check on the radio if there was an earthquake, but you might miss the news

Probability tables:
- $P(\text{Burglary}) = 0.001$
- $P(\text{Earthquake}) = 0.002$
- $P(\text{Alarm}|\text{B}, \text{E})$ varies (0.001 for FF, 0.29 for FT, 0.94 for TF, 0.95 for TT)
- $P(\text{John calls}|\text{Alarm})$ is 0.9 if alarm, 0.05 otherwise
- $P(\text{Mary calls}|\text{Alarm})$ is 0.7 if alarm, 0.01 otherwise

```ocaml
module Burglary (P : COND_PROBAB) = struct
  open P
  type what_happened =
    | Safe | Burgl | Earthq | Burgl_n_earthq

  let check ~john_called ~mary_called ~radio = perform
    earthquake <-- flip 0.002;
    guard (radio = None || radio = Some earthquake);
    burglary <-- flip 0.001;
    let alarm_p =
      match burglary, earthquake with
      | false, false -> 0.001
      | false, true -> 0.29
      | true, false -> 0.94
      | true, true -> 0.95 in
    alarm <-- flip alarm_p;
    let john_p = if alarm then 0.9 else 0.05 in
    john_calls <-- flip john_p;
    guard (john_calls = john_called);
    let mary_p = if alarm then 0.7 else 0.01 in
    mary_calls <-- flip mary_p;
    guard (mary_calls = mary_called);
    match burglary, earthquake with
    | false, false -> return Safe
    | true, false -> return Burgl
    | false, true -> return Earthq
    | true, true -> return Burgl_n_earthq
end

module BurglaryExact = Burglary (DistribMP)
module Sampling2000 =
  SamplingMP (struct let samples = 2000 end)
module BurglarySimul = Burglary (Sampling2000)

(* DistribMP.distrib
     (BurglaryExact.check ~john_called:true ~mary_called:true ~radio:None);;
   - : (BurglaryExact.what_happened * float) list =
   [(Burgl_n_earthq, 0.000574...); (Earthq, 0.175...);
    (Burgl, 0.283...); (Safe, 0.540...)] *)
```

### 8.14 Lightweight Cooperative Threads

The `bind` operation is inherently sequential: `bind a (fun x -> b)` computes `a`, and resumes computing `b` only once the result `x` is known.

For concurrency, we need to "suppress" this sequentiality. We introduce:

```ocaml
parallel : 'a monad -> 'b monad -> ('a -> 'b -> 'c monad) -> 'c monad
```

where `parallel a b (fun x y -> c)` does not wait for `a` to be computed before it can start computing `b`.

If the monad starts computing right away (as in the Lwt library), `parallel ea eb c` is equivalent to:

```ocaml
perform
  let a = ea in
  let b = eb in
  x <-- a;
  y <-- b;
  c x y
```

#### Fine-Grained vs. Coarse-Grained Concurrency

Under **fine-grained** concurrency, every `bind` is suspended and computation moves to other threads. It comes back to complete the `bind` before running threads created since the `bind` was suspended.

Under **coarse-grained** concurrency, computation is only suspended when requested via a `suspend` (often called `yield`) operation. Library operations that need to wait for an event or completion of I/O should call `suspend` internally.

#### Thread Monad Signatures

```ocaml
module type THREADS = sig
  include MONAD
  val parallel :
    'a t -> 'b t -> ('a -> 'b -> 'c t) -> 'c t
end

module type THREAD_OPS = sig
  include MONAD_OPS
  include THREADS with type 'a t := 'a monad
  val parallel_map :
    'a list -> ('a -> 'b monad) -> 'b list monad
  val (>||=) :
    'a monad -> 'b monad -> ('a -> 'b -> 'c monad) -> 'c monad
  val (>||) :
    'a monad -> 'b monad -> (unit -> 'c monad) -> 'c monad
end

module type THREADSYS = sig
  include THREADS
  val access : 'a t -> 'a
  val kill_threads : unit -> unit
end

module ThreadOps (M : THREADS) = struct
  open M
  include MonadOps (M)
  let parallel_map l f =
    List.fold_right (fun a bs ->
      parallel (f a) bs
        (fun a bs -> return (a::bs))) l (return [])
  let (>||=) = parallel
  let (>||) a b c = parallel a b (fun _ _ -> c ())
end

module Threads (M : THREADSYS) : sig
  include THREAD_OPS
  val access : 'a monad -> 'a
  val kill_threads : unit -> unit
end = struct
  include M
  include ThreadOps(M)
end
```

#### Cooperative Thread Implementation

```ocaml
module Cooperative = Threads(struct
  type 'a state =
    | Return of 'a                     (* The thread has returned *)
    | Sleep of ('a -> unit) list       (* When thread returns, wake up waiters *)
    | Link of 'a t                     (* A link to the actual thread *)
  and 'a t = {mutable state : 'a state}  (* State of the thread can change *)
                                       (* -- it can return, or more waiters can be added *)
  let rec find t =                     (* Union-find style link chasing *)
    match t.state with
    | Link t -> find t
    | _ -> t

  let jobs = Queue.create ()           (* Work queue -- will store unit -> unit procedures *)

  let wakeup m a =                     (* Thread m has actually finished -- *)
    let m = find m in                  (* updating its state *)
    match m.state with
    | Return _ -> assert false
    | Sleep waiters ->
        m.state <- Return a;           (* Set the state, and only then *)
        List.iter ((|>) a) waiters     (* wake up the waiters *)
    | Link _ -> assert false

  let return a = {state = Return a}

  let connect t t' =                   (* t was a placeholder for t' *)
    let t' = find t' in
    match t'.state with
    | Sleep waiters' ->
        let t = find t in
        (match t.state with
        | Sleep waiters ->             (* If both sleep, collect their waiters *)
            t.state <- Sleep (waiters' @ waiters);
            t'.state <- Link t         (* and link one to the other *)
        | _ -> assert false)
    | Return x -> wakeup t x           (* If t' returned, wake up the placeholder *)
    | Link _ -> assert false

  let rec bind a b =
    let a = find a in
    let m = {state = Sleep []} in      (* The resulting monad *)
    (match a.state with
    | Return x ->                      (* If a returned, we suspend further work *)
        let job () = connect m (b x) in  (* (In exercise 11, this should *)
        Queue.push job jobs            (* only happen after suspend) *)
    | Sleep waiters ->                 (* If a sleeps, we wait for it to return *)
        let job x = connect m (b x) in
        a.state <- Sleep (job::waiters)
    | Link _ -> assert false);
    m

  let parallel a b c = perform         (* Since in our implementation *)
    x <-- a;                           (* the threads run as soon as they are created, *)
    y <-- b;                           (* parallel is redundant *)
    c x y

  let rec access m =                   (* Accessing not only gets the result of m, *)
    let m = find m in                  (* but spins the thread loop till m terminates *)
    match m.state with
    | Return x -> x                    (* No further work *)
    | Sleep _ ->
        (try Queue.pop jobs ()         (* Perform suspended work *)
         with Queue.Empty ->
           failwith "access: result not available");
        access m
    | Link _ -> assert false

  let kill_threads () = Queue.clear jobs  (* Remove pending work *)
end)
```

#### Testing the Thread Implementation

```ocaml
module TTest (T : THREAD_OPS) = struct
  open T
  let rec loop s n = perform
    return (Printf.printf "-- %s(%d)\n%!" s n);
    if n > 0 then loop s (n-1)         (* We cannot use whenM because *)
    else return ()                     (* the thread would be created regardless of condition *)
end

module TT = TTest (Cooperative)

let test =
  Cooperative.kill_threads ();         (* Clean-up after previous tests *)
  let thread1 = TT.loop "A" 5 in
  let thread2 = TT.loop "B" 4 in
  Cooperative.access thread1;          (* We ensure threads finish computing *)
  Cooperative.access thread2           (* before we proceed *)

(* Output:
   -- A(5)
   -- B(4)
   -- A(4)
   -- B(3)
   -- A(3)
   -- B(2)
   -- A(2)
   -- B(1)
   -- A(1)
   -- B(0)
   -- A(0)
   val test : unit = () *)
```

The output shows that the threads interleave their execution, with each `bind` causing a context switch.

### 8.15 Exercises

**Exercise 1.** (Puzzle via Oleg Kiselyov)

"U2" has a concert that starts in 17 minutes and they must all cross a bridge to get there. All four men begin on the same side of the bridge. It is night. There is one flashlight. A maximum of two people can cross at one time. Any party who crosses, either 1 or 2 people, must have the flashlight with them. The flashlight must be walked back and forth, it cannot be thrown, etc. Each band member walks at a different speed. A pair must walk together at the rate of the slower man's pace:

- Bono: 1 minute to cross
- Edge: 2 minutes to cross
- Adam: 5 minutes to cross
- Larry: 10 minutes to cross

For example: if Bono and Larry walk across first, 10 minutes have elapsed when they get to the other side of the bridge. If Larry then returns with the flashlight, a total of 20 minutes have passed and you have failed the mission.

Find all answers to the puzzle using a list comprehension. The comprehension will be a bit long but recursion is not needed.

**Exercise 2.** Assume `concat_map` as defined in lecture 6. What will the following expressions return? Why?

1. `perform with (|->) in return 5; return 7`
2. `let guard p = if p then [()] else [];; perform with (|->) in guard false; return 7;;`
3. `perform with (|->) in return 5; guard false; return 7;;`

**Exercise 3.** Define `bind` in terms of `lift` and `join`.

**Exercise 4.** Define a monad-plus implementation based on binary trees, with constant-time `mzero` and `mplus`. Starter code:

```ocaml
type 'a tree = Empty | Leaf of 'a | T of 'a tree * 'a tree

module TreeM = MonadPlus (struct
  type 'a t = 'a tree
  let bind a b = (* TODO *)
  let return a = (* TODO *)
  let mzero = (* TODO *)
  let mplus a b = (* TODO *)
end)
```

**Exercise 5.** Show the monad-plus laws for one of:
1. `TreeM` from your solution of exercise 4
2. `ListM` from lecture

**Exercise 6.** Why is the following monad-plus not lazy enough?

```ocaml
let rec badappend l1 l2 =
  match l1 with lazy LazNil -> l2
  | lazy (LazCons (hd, tl)) ->
      lazy (LazCons (hd, badappend tl l2))

let rec badconcatmap f = function
  | lazy LazNil -> lazy LazNil
  | lazy (LazCons (a, l)) ->
      badappend (f a) (badconcatmap f l)

module BadyListM = MonadPlus (struct
  type 'a t = 'a lazylist
  let bind a b = badconcatmap b a
  let return a = lazy (LazCons (a, lazy LazNil))
  let mzero = lazy LazNil
  let mplus = badappend
end)
```

**Exercise 7.** Convert a "rectangular" list of lists of strings, representing a matrix with inner lists being rows, into a string, where elements are column-aligned. (Exercise not related to monads.)

**Exercise 8.** Recall the enriched monad signature with `('s, 'a) t` type. Design the signatures for the exception monad operations to provide more flexibility than our exception monad. Does the implementation need to change?

**Exercise 9.** Implement the following constructs for *all* monads:

1. `for...to...`
2. `for...downto...`
3. `while...do...`
4. `do...while...`
5. `repeat...until...`

Explain how, when your implementation is instantiated with the StateM monad, we get the solution to exercise 2 from lecture 4.

**Exercise 10.** A canonical example of a probabilistic model is that of a lawn whose grass may be wet because it rained, because the sprinkler was on, or for some other reason. The probability tables are:

$$
\begin{aligned}
P(\text{cloudy}) &= 0.5 \\
P(\text{rain}|\text{cloudy}) &= 0.8 \\
P(\text{rain}|\neg\text{cloudy}) &= 0.2 \\
P(\text{sprinkler}|\text{cloudy}) &= 0.1 \\
P(\text{sprinkler}|\neg\text{cloudy}) &= 0.5 \\
P(\text{wet\_roof}|\neg\text{rain}) &= 0 \\
P(\text{wet\_roof}|\text{rain}) &= 0.7 \\
P(\text{wet\_grass}|\text{rain} \land \neg\text{sprinkler}) &= 0.9 \\
P(\text{wet\_grass}|\text{sprinkler} \land \neg\text{rain}) &= 0.9
\end{aligned}
$$

We observe whether the grass is wet and whether the roof is wet. What is the probability that it rained?

**Exercise 11.** Implement the coarse-grained concurrency model:

- Modify `bind` to compute the resulting monad straight away if the input monad has returned.
- Introduce `suspend` to do what in the fine-grained model was the effect of `bind (return a) b`, i.e., suspend the work although it could already be started.
- One possibility is to introduce `suspend` of type `unit monad`, introduce a "dummy" monadic value `Suspend` (besides `Return` and `Sleep`), and define `bind suspend b` to do what `bind (return ()) b` would formerly do.
