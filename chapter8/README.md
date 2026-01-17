## Chapter 8: Monads

**In this chapter, you will:**

- Recognize the “bind + return” pattern behind list comprehensions and other effects
- Learn the monad laws (and what they do and do not guarantee)
- Use monad-plus for nondeterministic/backtracking computation
- Work through several concrete monads (lazy, list, exception, state, probability)
- Combine effects with monad transformers and model cooperative concurrency

This chapter explores one of functional programming's most powerful abstractions: monads. We begin with equivalents of list comprehensions as a motivating example, then introduce monadic concepts and examine the monad laws. We explore the monad-plus extension that adds non-determinism, then work through various monad instances including the lazy, list, state, exception, and probability monads. We conclude with monad transformers for combining monads and cooperative lightweight threads for concurrency.

The material draws on several excellent resources: Jeff Newbern's "All About Monads," Martin Erwig and Steve Kollmansberger's "Probabilistic Functional Programming in Haskell," and Jerome Vouillon's "Lwt: a Cooperative Thread Library."

### 8.1 List Comprehensions

Recall the somewhat awkward syntax we used in the Countdown Problem example from earlier chapters. The nested callback style, while functional, is hard to read and understand at a glance. The brute-force generation of expressions looked like this:

```ocaml env=ch8
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

Notice how the nested callbacks pile up: each `|->` introduces another level of indentation. The generate-and-test scheme used similar nesting:

```ocaml env=ch8
let guard p e = if p e then [e] else []

let solutions ns n =
  choices ns |-> (fun ns' ->
  exprs ns' |->
    guard (fun e -> eval e = Some n))
```

The key insight is that we introduced the operator `|->` defined as:

```ocaml env=ch8
let ( |-> ) x f = concat_map f x
```

This pattern of "for each element in a list, apply a function that returns a list, then flatten the results" is so common that many languages provide special syntax for it. We can express such computations much more elegantly with *list comprehensions*, a syntax that originated in languages like Haskell and Python.

With list comprehensions, we can write expressions that read almost like set-builder notation in mathematics:

```ocaml skip
let test = [i * 2 | i <- from_to 2 22; i mod 3 = 0]
```

This reads as: "the list of `i * 2` for each `i` drawn from `from_to 2 22` where `i mod 3 = 0`." The `<-` arrow draws elements from a generator, and conditions filter which elements are kept.

The translation rules that define list comprehension semantics are straightforward:

- `[expr | ]` translates to `[expr]` -- the base case, a singleton list
- `[expr | v <- generator; more]` translates to `generator |-> (fun v -> [expr | more])` -- draw from a generator, then recurse
- `[expr | condition; more]` translates to `if condition then [expr | more] else []` -- filter by a condition

The list comprehension syntax has not caught on in modern OCaml; there were a couple syntax extensions providing it, but none gained popularity. It is a nice syntax to build intuition but the examples in this section need additional setup to compile, you can treat them as pseudo-code.

#### Revisiting Countdown with List Comprehensions

Now let us revisit the Countdown Problem code with list comprehensions. The brute-force generation becomes dramatically cleaner -- compare this to the deeply nested version above:

```ocaml skip
let rec exprs = function
  | [] -> []
  | [n] -> [Val n]
  | ns ->
      [App (o, l, r) | (ls, rs) <- split ns;
       l <- exprs ls; r <- exprs rs;
       o <- [Add; Sub; Mul; Div]]
```

The intent is immediately clear: we split the numbers, recursively build expressions for left and right parts, and try each operator. The generate-and-test scheme becomes equally elegant:

```ocaml skip
let solutions ns n =
  [e | ns' <- choices ns;
   e <- exprs ns'; eval e = Some n]
```

The guard condition `eval e = Some n` filters out expressions that do not evaluate to the target value.

#### More List Comprehension Examples

List comprehensions shine when expressing combinatorial algorithms. Here is computing all subsequences of a list (note that this generates some intermediate garbage, but the intent is clear):

```ocaml skip
let rec subseqs l =
  match l with
  | [] -> [[]]
  | x::xs -> [ys | px <- subseqs xs; ys <- [px; x::px]]
```

For each element `x`, we recursively compute subsequences of the tail, then for each such subsequence we include both the version without `x` and the version with `x` prepended.

Computing permutations can be done via insertion -- inserting an element at every possible position:

```ocaml skip
let rec insert x = function
  | [] -> [[x]]
  | y::ys' as ys ->
      (x::ys) :: [y::zs | zs <- insert x ys']

let rec ins_perms = function
  | [] -> [[]]
  | x::xs -> [zs | ys <- ins_perms xs; zs <- insert x ys]
```

The `insert` function generates all ways to insert `x` into a list. Then `ins_perms` recursively permutes the tail and inserts the head at every position.

Alternatively, we can compute permutations via selection -- repeatedly choosing which element comes first:

```ocaml skip
let rec select = function
  | [x] -> [x, []]
  | x::xs -> (x, xs) :: [y, x::ys | y, ys <- select xs]

let rec sel_perms = function
  | [] -> [[]]
  | xs -> [x::ys | x, xs' <- select xs; ys <- sel_perms xs']
```

The `select` function returns all ways to pick one element from a list, along with the remaining elements. Then `sel_perms` chooses a first element and recursively permutes the rest.

### 8.2 Generalized Comprehensions: Binding Operators

The pattern we saw with list comprehensions is remarkably general. In fact, the same `|->` pattern (applying a function that returns a container, then flattening) works for many types beyond lists. This is the essence of monads.

OCaml 4.08 introduced **binding operators** (`let*`, `let+`, `and*`, …) that provide a clean, native syntax for such computations. Instead of external syntax extensions like the old Camlp4-based `pa_monad`, we can now define custom operators that integrate naturally with the language.

For the list monad, we define these binding operators:

```ocaml env=ch8
let ( let* ) x f = concat_map f x      (* bind: sequence computations *)
let ( let+ ) x f = List.map f x        (* map: apply pure function *)
let ( and* ) x y = concat_map (fun a -> List.map (fun b -> (a, b)) y) x
let ( and+ ) = ( and* )                (* parallel binding *)
let return x = [x]                     (* inject a value into the monad *)
let fail = []                          (* the empty computation *)
```

The `let*` operator is the key: it sequences computations where each step can produce multiple results. The `and*` operator allows binding multiple values in parallel. With these operators, the expression generation code becomes:

```
let rec exprs = function
  | [] -> []
  | [n] -> [Val n]
  | ns ->
      let* (ls, rs) = split ns in
      let* l = exprs ls in
      let* r = exprs rs in
      let* o = [Add; Sub; Mul; Div] in
      [App (o, l, r)]
```

Each `let*` introduces a binding: the variable on the left is bound to each value produced by the expression on the right, and the computation continues with `in`. This is much more readable than the nested callbacks we started with.

However, the `let*` syntax does not directly support guards (conditions that filter results). If we try to write:

```
let solutions ns n =
  let* ns' = choices ns in
  let* e = exprs ns' in
  eval e = Some n;  (* Error! *)
  e
```

We get a type error: the expression expects a list, but `eval e = Some n` is a boolean. What can we do?

One approach is to explicitly decide whether to return anything:

```
let solutions ns n =
  let* ns' = choices ns in
  let* e = exprs ns' in
  if eval e = Some n then [e] else []
```

But what if we want to check a condition earlier in the computation, or check multiple conditions? We need a general "guard check" function. The key insight is that we can use the monad itself to represent success or failure:

```ocaml env=ch8
let guard p = if p then [()] else []
```

When the condition `p` is true, `guard` returns `[()]` -- a list with one element (the unit value). When false, it returns `[]` -- an empty list. Now we can use it in a binding:

```
let solutions ns n =
  let* ns' = choices ns in
  let* e = exprs ns' in
  let* () = guard (eval e = Some n) in
  [e]
```

Why does this work? When the guard succeeds, `let* () = [()]` binds unit and continues. When it fails, `let* () = []` produces no results -- the empty list -- so the rest of the computation is never reached for that branch. This is exactly the filtering behavior we want!

### 8.3 Monads

Now we are ready to define monads properly. A **monad** is a polymorphic type `'a monad` (or `'a Monad.t`) that supports at least two operations:

- `bind : 'a monad -> ('a -> 'b monad) -> 'b monad` -- sequence two computations, passing the result of the first to the second
- `return : 'a -> 'a monad` -- inject a pure value into the monad
- The infix `>>=` is commonly used for `bind`: `let (>>=) a b = bind a b`

The `bind` operation is the heart of the monad: it takes a computation that produces an `'a`, and a function that takes an `'a` and produces a new computation yielding `'b`. The result is a combined computation that yields `'b`.

With OCaml 5's binding operators, we define `let*` as an alias for `bind`:

```ocaml env=ch8
let bind a b = concat_map b a
let return x = [x]
let ( let* ) = bind

let solutions ns n =
  let* ns' = choices ns in
  let* e = exprs ns' in
  let* () = guard (eval e = Some n) in
  return e
```

But why does `guard` look the way it does? Let us examine more carefully:

```ocaml env=ch8
let fail = []
let guard p = if p then return () else fail
```

Steps in monadic computation are composed with `let*` (or `>>=`, which is like `|->` for lists). The key insight is understanding what happens when we bind with an empty list versus a singleton:

- `let* _ = [] in ...` does not produce anything -- the continuation is never called, so the computation fails (produces no results)
- `let* _ = [()] in ...` calls the continuation once with `()`, which simply continues the computation unchanged

This is why `guard` works: returning `[()]` means "succeed with unit" and returning `[]` means "fail with no results." The unit value itself is a dummy -- we only care whether the list is empty or not.

Throwing away the binding argument is a common pattern. With binding operators, we use `let* () = ...` or `let* _ = ...` to indicate we do not need the bound value:

```ocaml env=ch8
let (>>=) a b = bind a b
let (>>) m f = m >>= (fun _ -> f)
```

The `>>` operator (called "sequence" or "then") is useful when you want to perform a computation for its effect but discard its result.

#### The Binding Operator Syntax

For reference, OCaml 5's binding operators translate as follows:

| Source | Translation |
|--------|-------------|
| `let* x = exp in body` | `bind exp (fun x -> body)` |
| `let+ x = exp in body` | `map (fun x -> body) exp` |
| `let* () = exp in body` | `bind exp (fun () -> body)` |
| `let* x = e1 and* y = e2 in body` | `bind (and* e1 e2) (fun (x, y) -> body)` |

The binding operators `let*`, `let+`, `and*`, and `and+` must be defined in scope. These are regular OCaml operators and require no syntax extensions -- a significant improvement over the old Camlp4 approach.

Note: For pattern matching in bindings, if the pattern is refutable (can fail to match), the monadic operation should handle the failure appropriately. For example, `let* Some x = e in body` requires a way to handle the `None` case.

### 8.4 Monad Laws

Not every type with `bind` and `return` operations is a proper monad. A parametric data type is a monad only if its `bind` and `return` operations meet three fundamental axioms:

$$
\begin{aligned}
\text{bind}\ (\text{return}\ a)\ f &\approx f\ a & \text{(left identity)} \\
\text{bind}\ a\ (\lambda x.\text{return}\ x) &\approx a & \text{(right identity)} \\
\text{bind}\ (\text{bind}\ a\ (\lambda x.b))\ (\lambda y.c) &\approx \text{bind}\ a\ (\lambda x.\text{bind}\ b\ (\lambda y.c)) & \text{(associativity)}
\end{aligned}
$$

Let us understand what these laws mean:

- **Left identity**: If you inject a value with `return` and immediately bind it to a function, you get the same result as just applying the function. The `return` operation should not add any extra "effects."
- **Right identity**: If you bind a computation to `return`, you get back the same computation. The `return` operation is neutral.
- **Associativity**: Binding is associative -- it does not matter how you group nested binds. This means `let* x = (let* y = a in b) in c` is equivalent to `let* y = a in let* x = b in c` (when `x` does not appear free in `b`).

You should verify that these laws hold for our list monad:

```ocaml env=ch8
let bind a b = concat_map b a
let return x = [x]
```

For example, to verify left identity: `bind (return a) f` = `bind [a] f` = `concat_map f [a]` = `f a`. The other laws can be verified similarly.

### 8.5 Monoid Laws and Monad-Plus

The list monad has an additional structure beyond just `bind` and `return`: it supports combining multiple computations and representing failure. This leads us to the concept of a **monoid**.

A monoid is a type with at least two operations:

- `mzero : 'a monoid` -- an identity element (think: zero, or the empty container)
- `mplus : 'a monoid -> 'a monoid -> 'a monoid` -- a combining operation (think: addition, or concatenation)

These operations must meet the standard monoid laws:

$$
\begin{aligned}
\text{mplus}\ \text{mzero}\ a &\approx a & \text{(left identity)} \\
\text{mplus}\ a\ \text{mzero} &\approx a & \text{(right identity)} \\
\text{mplus}\ a\ (\text{mplus}\ b\ c) &\approx \text{mplus}\ (\text{mplus}\ a\ b)\ c & \text{(associativity)}
\end{aligned}
$$

We define `fail` as a synonym for `mzero` and infix `++` for `mplus`. For lists, `mzero` is `[]` and `mplus` is `@` (append).

Fusing monads and monoids gives the most popular general flavor of monads, which we call **monad-plus** after Haskell. A monad-plus is a monad that also has monoid structure, with additional axioms relating the "addition" (`mplus`) and "multiplication" (`bind`):

$$
\begin{aligned}
\text{bind}\ \text{mzero}\ f &\approx \text{mzero} \\
\text{bind}\ m\ (\lambda x.\text{mzero}) &\approx \text{mzero}
\end{aligned}
$$

These laws say that `mzero` acts like a "zero" for `bind`: binding from zero produces zero, and binding to a function that always returns zero also produces zero. This is analogous to how $0 \times x = 0$ and $x \times 0 = 0$ in arithmetic.

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

```ocaml env=ch8
let mzero = []
let mplus = (@)
let bind a b = concat_map b a
let return a = [a]
```

Given any monad-plus, we can define useful derived operations:

```ocaml env=ch8
let fail = mzero
let (++) = mplus
let (>>=) a b = bind a b
let guard p = if p then return () else fail
```

Now we can see that `guard` is defined in terms of the monad-plus structure: it returns the identity element (`return ()`) on success, or the zero element (`fail`) on failure.

### 8.6 Backtracking: Computation with Choice

We have seen `mzero` (i.e., `fail`) in the countdown problem -- it represents a computation that produces no results. But what about `mplus`? The `mplus` operation combines two computations, giving us a way to express *choice*: try this computation, or try that one.

Here is an example from a puzzle solver where `mplus` creates a choice point:

```ocaml skip
let find_to_eat n island_size num_islands empty_cells =
  let honey = honey_cells n empty_cells in

  let rec find_board s =
    match visit_cell s with
    | None ->
        let* () = guard (s.been_islands = num_islands) in
        return s.eaten
    | Some (cell, s) ->
        let* s = find_island cell (fresh_island s) in
        let* () = guard (s.been_size = island_size) in
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

The line `mplus choose_eat choose_keep` creates a choice point: the algorithm can either eat the cell (removing it from consideration) or keep it as part of the current island. When we use the list monad as our monad-plus, this explores *all* possible choices, collecting all solutions. The monad-plus structure handles the bookkeeping of backtracking automatically -- we just express the choices declaratively.

### 8.7 Monad Flavors

Monads "wrap around" a type, but some monads need an additional type parameter. For example, a state monad might be parameterized by the type of state it carries. Usually the additional type does not change while within a monad, so we stick to `'a monad` rather than `('s, 'a) monad`.

As monad-plus shows, things get interesting when we add more operations to a basic monad. Different "flavors" of monads provide different capabilities. Here are the most common ones:

**Monads with access:**

```
access : 'a monad -> 'a
```

An `access` operation lets you extract the value from the monad. Not all monads support this -- some only allow you to "run" the monad at the top level. Example: the lazy monad, where `access` is `Lazy.force`.

**Monad-plus (non-deterministic computation):**

```
mzero : 'a monad
mplus : 'a monad -> 'a monad -> 'a monad
```

We have already seen this. The monad-plus flavor supports failure and choice, enabling backtracking search.

**Monads with state (parameterized by type `store`):**

```
get : store monad
put : store -> unit monad
```

These operations let you read and write a piece of state that is threaded through the computation. There is a "canonical" state monad we will examine later. Related monads include:
- The **writer monad**: has `tell` (append to a log) and `listen` (read the log)
- The **reader monad**: has `ask` (read an environment) and `local` to modify the environment for a sub-computation:

```
local : (store -> store) -> 'a monad -> 'a monad
```

**Exception/error monads (parameterized by type `excn`):**

```
throw : excn -> 'a monad
catch : 'a monad -> (excn -> 'a monad) -> 'a monad
```

These provide structured error handling within the monad. The `throw` operation raises an exception; `catch` handles it.

**Continuation monad:**

```
callCC : (('a -> 'b monad) -> 'a monad) -> 'a monad
```

The continuation monad gives you access to the "rest of the computation" as a first-class value. This is powerful but complex; we will not cover continuations in detail here.

**Probabilistic computation:**

```
choose : float -> 'a monad -> 'a monad -> 'a monad
```

The `choose p a b` operation selects `a` with probability `p` and `b` with probability `1-p`. This enables reasoning about probability distributions. The laws ensure that probability behaves correctly:

$$
\begin{aligned}
a \oplus_0 b &\approx b \\
a \oplus_p b &\approx b \oplus_{1-p} a \\
a \oplus_p (b \oplus_q c) &\approx (a \oplus_{\frac{p}{p+q-pq}} b) \oplus_{p+q-pq} c \\
a \oplus_p a &\approx a
\end{aligned}
$$

**Parallel computation (monad with access and parallel bind):**

```
parallel : 'a monad -> 'b monad -> ('a -> 'b -> 'c monad) -> 'c monad
```

The `parallel` operation runs two computations concurrently and combines their results. Example: lightweight threads like in the Lwt library.

### 8.8 Interlude: The Module System

Before we implement various monads, we need to understand OCaml's module system, which provides the infrastructure for defining monads in a reusable, generic way. This section provides a brief overview of the key concepts.

Modules collect related type definitions and operations together. Module values are introduced with `struct ... end` (called *structures*), and module types with `sig ... end` (called *signatures*). A structure is a package of definitions; a signature is an interface that specifies what a structure must provide.

A source file `source.ml` defines a module `Source`. A file `source.mli` defines its type.

In the module level, modules are defined with `module ModuleName = ...` or `module ModuleName : MODULE_TYPE = ...`, and module types with `module type MODULE_TYPE = ...`.

Locally in expressions, modules are defined with `let module M = ... in ...`.

The content of a module is made visible with `open Module`. Module `Pervasives` (now `Stdlib`) is initially visible.

Content of a module is included into another module with `include Module`.

**Functors** are module functions -- functions from modules to modules. They are the key to writing generic code that works with any monad:

```
module Funct = functor (Arg : sig ... end) -> struct ... end
(* Or equivalently: *)
module Funct (Arg : sig ... end) = struct ... end
```

Functors can return functors, and modules can be parameterized by multiple modules. Functor application always uses parentheses: `Funct (struct ... end)`.

A signature `MODULE_TYPE with type t_name = ...` is like `MODULE_TYPE` but with `t_name` made more specific. This is useful when you want to expose the concrete type after applying a functor. We can also include signatures with `include MODULE_TYPE`.

Finally, we can pass around modules in normal functions using first-class modules:

```ocaml env=ch8
module type T = sig val g : int -> int end

let f mod_v x =
  let module M = (val mod_v : T) in
  M.g x
(* val f : (module T) -> int -> int = <fun> *)

let test = f (module struct let g i = i*i end : T)
(* val test : int -> int = <fun> *)
```

### 8.9 The Two Metaphors

Monads are abstract, but two complementary metaphors can help build intuition for what they are and how they work.

#### Monads as Containers

The first metaphor views a monad as a **quarantine container**. Think of it like a sealed box:

- We can put something into the container with `return` -- this "seals" a pure value inside the monad
- We can operate on the contents, but the result must stay in the container -- we cannot simply extract values

The `lift` function applies a pure function to the contents of a monad, keeping the result wrapped:

```ocaml env=ch8
let lift f m =
  let* x = m in
  return (f x)
(* val lift : ('a -> 'b) -> 'a monad -> 'b monad *)
```

We can also "flatten" nested containers. If we have a monad containing another monad, `join` unwraps one layer -- but the result is still in a monad, so the quarantine is not broken:

```ocaml env=ch8
let join m =
  let* x = m in
  x
(* val join : ('a monad) monad -> 'a monad *)
```

The quarantine container for a **monad-plus** is more like a collection: it can be empty (failure), contain one element (success), or contain multiple elements (multiple solutions).

Monads with access allow us to extract the resulting element from the container. Other monads provide a `run` operation that exposes "what really happened behind the quarantine" -- for example, the state monad's `run` takes an initial state and returns both the final value and the final state.

#### Monads as Computation

The second metaphor views a monad as a way to structure computation. Each `let*` binding is a step in a sequence, and the monad controls how steps are connected. The physical metaphor is an **assembly line**:

```
let assemblyLine w =
  let* c = makeChopsticks w in    (* Worker makes chopsticks *)
  let* c' = polishChopsticks c in (* Worker polishes them *)
  let* c'' = wrapChopsticks c' in (* Worker wraps them *)
  return c''                       (* Final product goes out *)
```

Each worker (operation) takes material from the previous step and produces something for the next step. The monad defines what happens between steps -- for lists, it means "do this for each element"; for state, it means "thread the state through"; for exceptions, it means "propagate errors."

Any expression can be systematically translated into a monadic form. For lambda-terms:

$$
\begin{aligned}
[\![ N ]\!] &= \text{return}\ N & \text{(constant)} \\
[\![ x ]\!] &= \text{return}\ x & \text{(variable)} \\
[\![ \lambda x.a ]\!] &= \text{return}\ (\lambda x.[\![ a ]\!]) & \text{(function)} \\
[\![ \text{let}\ x = a\ \text{in}\ b ]\!] &= \text{bind}\ [\![ a ]\!]\ (\lambda x.[\![ b ]\!]) & \text{(local definition)} \\
[\![ a\ b ]\!] &= \text{bind}\ [\![ a ]\!]\ (\lambda v_a.\text{bind}\ [\![ b ]\!]\ (\lambda v_b.v_a\ v_b)) & \text{(application)}
\end{aligned}
$$

This translation inserts `bind` at every point where execution flows from one subexpression to another. The beauty of this approach is that once an expression is spread over a monad, its computation can be monitored, logged, or affected without modifying the expression itself. This is the key to implementing effects like state, exceptions, or non-determinism in a purely functional way.

### 8.10 Monad Classes and Instances

Now we will see how to implement monads in OCaml using the module system. To implement a monad, we need to provide the implementation type, `return`, and `bind` operations. Here is the minimal signature:

```ocaml env=ch8
module type MONAD = sig
  type 'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
end
```

This is the "class" that all monads must implement. Alternatively, we could start from `return`, `lift`, and `join` operations -- these are mathematically equivalent starting points.

The power of functors is that we can define a suite of general-purpose functions that work for *any* monad, just based on these two operations:

```ocaml env=ch8
module type MONAD_OPS = sig
  type 'a monad
  include MONAD with type 'a t := 'a monad
  val ( let* ) : 'a monad -> ('a -> 'b monad) -> 'b monad
  val ( let+ ) : 'a monad -> ('a -> 'b) -> 'b monad
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
  let ( let* ) a b = bind a b
  let ( let+ ) a f = bind a (fun x -> return (f x))
  let (>>=) a b = bind a b
  let rec foldM f a = function
    | [] -> return a
    | x::xs ->
        let* a' = f a x in
        foldM f a' xs
  let whenM p s = if p then s else return ()
  let lift f m =
    let* x = m in
    return (f x)
  let (>>|) a b = lift b a
  let join m =
    let* x = m in
    x
  let (>=>) f g = fun x ->
    let* y = f x in
    g y
end
```

We make the monad "safe" by keeping its type abstract. The `run` function exposes the underlying representation -- "what really happened behind the scenes":

```ocaml env=ch8
module Monad (M : MONAD) : sig
  include MONAD_OPS
  val run : 'a monad -> 'a M.t
end = struct
  include M
  include MonadOps(M)
end
```

The pattern here is important: we take a minimal implementation (`M : MONAD`) and produce a full-featured monad module with all the derived operations.

#### Monad-Plus Classes

The monad-plus class extends the basic monad with failure and choice. Implementations need to provide `mzero` and `mplus` in addition to `return` and `bind`:

```ocaml env=ch8
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

We also need a class for computations with state. This signature will be included in state monads:

```ocaml env=ch8
module type STATE = sig
  type store
  type 'a t
  val get : store t
  val put : store -> unit t
end
```

### 8.11 Monad Instances

Now let us see concrete implementations of various monads.

#### The Lazy Monad

If you find OCaml's laziness notation (with `lazy` and `Lazy.force` everywhere) too heavy, you can use a monad! The lazy monad wraps lazy computations:

```ocaml env=ch8
module LazyM = Monad (struct
  type 'a t = 'a Lazy.t
  let bind a b = lazy (Lazy.force (b (Lazy.force a)))
  let return a = lazy a
end)

let laccess m = Lazy.force (LazyM.run m)
```

The `bind` operation creates a new lazy value that, when forced, forces `a`, passes the result to `b`, and forces the result. The `laccess` function forces the final lazy value to get the result.

#### The List Monad

Our familiar list monad is a monad-plus, supporting non-deterministic computation:

```ocaml env=ch8
module ListM = MonadPlus (struct
  type 'a t = 'a list
  let bind a b = concat_map b a
  let return a = [a]
  let mzero = []
  let mplus = List.append
end)
```

#### Backtracking Parameterized by Monad-Plus

Here is the power of abstraction: we can write the Countdown solver parameterized by *any* monad-plus. The same code works with lists (exploring all solutions), lazy lists (computing solutions on demand), or any other monad-plus implementation:

```ocaml env=ch8
module Countdown (M : MONAD_PLUS_OPS) = struct
  open M  (* Open the module to make monad operations visible *)

  let rec insert x = function  (* All choice-introducing operations *)
    | [] -> return [x]          (* need to happen in the monad *)
    | y::ys as xs ->
        let* xys = insert x ys in
        return (x::xs) ++ return (y::xys)

  let rec choices = function
    | [] -> return []
    | x::xs ->
        let* cxs = choices xs in           (* Choosing which numbers in what order *)
        return cxs ++ insert x cxs         (* and now whether with or without x *)

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

  let combine (l, x) (r, y) o =  (* Try out an operator *)
    let* () = guard (valid o x y) in
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
    | [n] ->
        let* () = guard (n > 0) in
        return (Val n, n)
    | ns ->
        let* (ls, rs) = split ns in
        let* lx = results ls in
        let* ly = results rs in  (* Collect solutions using each operator *)
        msum_map (combine lx ly) [Add; Sub; Mul; Div]

  let solutions ns n =  (* Solve the problem: *)
    let* ns' = choices ns in         (* pick numbers and their order, *)
    let* (e, m) = results ns' in     (* build possible expressions, *)
    let* () = guard (m = n) in       (* check if the expression gives target value, *)
    return (expr2str e)              (* "print" the solution *)
end
```

#### Understanding Laziness

Now let us explore a practical question: what if we only want *one* solution, not all of them? With the list monad, we compute all solutions even if we only look at the first one. Can laziness help?

Let us sketch how you might measure execution times to find out (the numbers will vary wildly between machines, and the full Countdown search is expensive enough that it is better left out of mdx tests):

```ocaml env=ch8
let time f =
  let tbeg = Sys.time () in
  let res = f () in
  let tend = Sys.time () in
  tend -. tbeg, res
```

With the list monad:

```ocaml skip
module ListCountdown = Countdown (ListM)
let test1 () = ListM.run (ListCountdown.solutions [1;3;7;10;25;50] 765)
let t1, sol1 = time test1
(* val t1 : float = 2.28... *)
(* val sol1 : string list = ["((25-(3+7))*(1+50))"; "(((25-3)-7)*(1+50))"; ...] *)
```

Finding all 49 solutions takes about 2.3 seconds. What if we want only one solution? Laziness to the rescue!

Our first attempt uses an "odd lazy list" -- a list where the tail is lazy but the head is strict:

```ocaml env=ch8
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

But testing shows disappointing results: the odd lazy list still takes about 2.5 seconds just to create the lazy list! The elements are almost all computed by the time we get the first one.

Why? Because whenever we pattern match on `LCons (hd, tl)`, we have already evaluated the head. And when building lists with `mplus`, the head of the first list is computed immediately.

What about using the **option monad** to find just the first solution?

```ocaml env=ch8
module OptionM = MonadPlus (struct
  type 'a t = 'a option
  let bind a b =
    match a with None -> None | Some x -> b x
  let return a = Some a
  let mzero = None
  let mplus a b = match a with None -> b | Some _ -> a
end)
```

This very quickly computes... nothing! The option monad returns `None`.

Why? The `OptionM` monad (Haskell's `Maybe` monad) is good for computations that might fail, but it does not *search* -- its `mplus` just picks the first non-`None` value. Since our search often needs to backtrack when a choice leads to failure, option gives up too early.

Our odd lazy list type is not lazy *enough*. Whenever we "make" a choice with `a ++ b` or `msum_map`, it computes the first candidate for each choice path immediately. We need **even lazy lists** -- lists where even the outermost constructor is wrapped in `lazy`:

```ocaml env=ch8
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

Now the first solution takes only about 0.37 seconds -- considerably less time than the 2.3 seconds for all solutions! The next 9 solutions are almost computed once the first one is (just 0.23 seconds more). But computing all 49 solutions takes about 4 seconds -- nearly twice as long as without laziness. This is the price we pay for lazy computation: overhead when we do need all results.

The lesson: even lazy lists enable true lazy search, but they come with overhead. Choose the right monad for your use case.

#### The Exception Monad

OCaml has built-in exceptions that are efficient and flexible. However, monadic exceptions have advantages in certain situations:

- They are safer in multi-threading contexts (no risk of unhandled exceptions escaping)
- They compose well with other monads (via monad transformers)
- They make the possibility of failure explicit in the type

The monadic lightweight-thread library Lwt has `throw` (called `fail` there) and `catch` operations in its monad for exactly these reasons.

```ocaml env=ch8
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

The state monad threads a piece of mutable state through a computation without actually using mutation. The key insight is that a stateful computation can be represented as a *function* from the current state to a pair of (result, new state):

```ocaml env=ch8
module StateM (Store : sig type t end) : sig
  type store = Store.t
  type 'a t = store -> 'a * store  (* A stateful computation *)
  include MONAD_OPS
  include STATE with type 'a t := 'a monad
                 and type store := store
  val run : 'a monad -> 'a t
end = struct
  type store = Store.t
  module M = struct
    type 'a t = store -> 'a * store
    let return a = fun s -> a, s     (* Return value, keep state unchanged *)
    let bind m b = fun s -> let a, s' = m s in b a s'
  end                          (* Run m, then pass result and new state to b *)
  include M
  include MonadOps(M)
  let get = fun s -> s, s            (* Return the current state *)
  let put s' = fun _ -> (), s'       (* Replace the state, return unit *)
end
```

The `bind` operation sequences two stateful computations: it runs the first one with the initial state, then passes both the result and the new state to the second computation.

The state monad is useful to hide the threading of a "current" value through a computation. Here is an example that renames variables in lambda-terms to eliminate potential name clashes (alpha-conversion):

```ocaml env=ch8
type term =
  | Var of string
  | Lam of string * term
  | App of term * term

module TermOps = struct
  let (!) x = Var x
  let (|->) x t = Lam (x, t)
  let (@) t1 t2 = App (t1, t2)
end
let test = TermOps.("x" |-> ("x" |-> !"y" @ !"x") @ !"x")

module S = StateM (struct type t = int * (string * string) list end)
open S

let rec alpha_conv = function
  | Var x as v ->                      (* Function from terms to StateM monad *)
      let* (_, env) = get in           (* Seeing a variable does not change state *)
      let v = try Var (List.assoc x env)  (* but we need its new name *)
        with Not_found -> v in         (* Free variables don't change name *)
      return v
  | Lam (x, t) ->                      (* We rename each bound variable *)
      let* (fresh, env) = get in       (* We need a fresh number *)
      let x' = x ^ string_of_int fresh in
      let* () = put (fresh+1, (x, x')::env) in  (* Remember new name, update number *)
      let* t' = alpha_conv t in
      let* (fresh', _) = get in        (* We need to restore names, *)
      let* () = put (fresh', env) in   (* but keep the number fresh *)
      return (Lam (x', t'))
  | App (t1, t2) ->
      let* t1 = alpha_conv t1 in       (* Passing around of names *)
      let* t2 = alpha_conv t2 in       (* and the currently fresh number *)
      return (App (t1, t2))            (* is done by the monad *)

(* # StateM.run (alpha_conv test) (5, []);; *)
```

The state consists of a fresh counter and an environment mapping old names to new names. The `get` and `put` operations access and modify this state, while `let*` sequences the operations. Without the state monad, we would have to explicitly pass the state through every recursive call -- tedious and error-prone.

Note: This alpha-conversion does not make a lambda-term safe for multiple steps of beta-reduction. Can you find a counter-example?

### 8.12 Monad Transformers

Sometimes we need the capabilities of multiple monads at the same time. For example, we might want both state (to track information) and non-determinism (to explore choices). The straightforward idea is to nest one monad within another: either `'a AM.monad BM.monad` or `'a BM.monad AM.monad`. But this does not work well -- we want a single monad that has operations of *both* `AM` and `BM`.

The solution is a **monad transformer**. A monad transformer `AT` takes a monad `BM` and produces a new monad `AT(BM)` that has operations of both. The transformed monad wraps around `BM` in a specific way to make the operations interact correctly.

We will develop a monad transformer `StateT` which adds state to any monad-plus. The resulting monad has all the operations: `return`, `bind`, `mzero`, `mplus`, `put`, `get`, and all their derived functions.

Why do we need monad transformers in OCaml? Because "monads are contagious": although we have built-in state and exceptions, we need to use *monadic* state and exceptions when we are inside a monad. For example, using OCaml's native `ref` cells inside a list monad would give the wrong semantics for backtracking. This is also why Lwt is both a concurrency monad and an exception monad -- it needs monadic exceptions to interact correctly with its concurrency model.

To understand how the transformer works, let us compare the regular state monad with the transformed version. The regular state monad uses ordinary OCaml binding:

```ocaml skip
type 'a state = store -> ('a * store)

let return (a : 'a) : 'a state =
  fun s -> (a, s)

let bind (u : 'a state) (f : 'a -> 'b state) : 'b state =
  fun s -> let (a, s') = u s in f a s'
```

The transformed version wraps everything in the underlying monad `M`:

```ocaml skip
(* Monad M transformed to add state, in pseudo-code: *)
type 'a stateT(M) = store -> ('a * store) M
(* Note: this is store -> ('a * store) M, not ('a M) state *)

let return (a : 'a) : 'a stateT(M) =
  fun s -> M.return (a, s)           (* Use M.return instead of just returning *)

let bind (u : 'a stateT(M)) (f : 'a -> 'b stateT(M)) : 'b stateT(M) =
  fun s -> M.bind (u s) (fun (a, s') -> f a s')  (* Use M.bind instead of let *)
```

The key insight is that the result type is `('a * store) M` -- the result and state are wrapped *together* in the underlying monad. This ensures that backtracking (in a monad-plus) correctly restores the state.

#### State Transformer Implementation

```ocaml env=ch8
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

Now we can combine backtracking with state for our puzzle solver. The state tracks which cells have been visited, eaten, and how many islands we have found. The monad-plus structure handles the backtracking when a choice leads to a dead end:

```ocaml env=ch8
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

  let rec visit_cell () =           (* State update actions *)
    let* s = get in
    match s.unvisited with
    | [] -> return None
    | c::remaining when CellSet.mem c s.visited ->
        let* () = put {s with unvisited=remaining} in
        visit_cell ()               (* Throwaway argument because of recursion *)
    | c::remaining ->
        let* () = put {s with
          unvisited=remaining;
          visited = CellSet.add c s.visited} in
        return (Some c)             (* This action returns a value *)

  let eat_cell c =
    let* s = get in
    let* () = put {s with eaten = c::s.eaten;
         visited = CellSet.add c s.visited;
         more_to_eat = s.more_to_eat - 1} in
    return ()              (* Remaining state update actions just affect the state *)

  let keep_cell c =
    let* s = get in
    let* () = put {s with
      visited = CellSet.add c s.visited;
      been_size = s.been_size + 1} in
    return ()

  let fresh_island =
    let* s = get in
    let* () = put {s with been_size = 0;
         been_islands = s.been_islands + 1} in
    return ()

  let find_to_eat n island_size num_islands empty_cells =
    let honey = honey_cells n empty_cells in
    let rec find_board () =
      let* cell = visit_cell () in
      match cell with
      | None ->
          let* s = get in
          let* () = guard (s.been_islands = num_islands) in
          return s.eaten
      | Some cell ->
          let* () = fresh_island in
          let* () = find_island cell in
          let* s = get in
          let* () = guard (s.been_size = island_size) in
          find_board ()

    and find_island current =
      let* () = keep_cell current in
      neighbors n empty_cells current
      |> foldM
           (fun () neighbor ->
              let* s = get in
              whenM (not (CellSet.mem neighbor s.visited))
                (let choose_eat =
                   let* () = guard (s.more_to_eat > 0) in
                   eat_cell neighbor
                 and choose_keep =
                   let* () = guard (s.been_size < island_size) in
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

Using a random number generator, we can define procedures that produce various outputs. This is **not functional** in the mathematical sense -- mathematical functions have deterministic results for fixed arguments.

Just as we can "simulate" mutable variables with the state monad and non-determinism with the list monad, we can "simulate" random computation with a **probability monad**. But the probability monad is more than just randomized computation -- it lets us *reason* about probabilities. We can ask questions like "what is the probability of this outcome?" or "what is the distribution of possible results?"

Different monad implementations make different tradeoffs:
- **Exact distribution**: Track all possible outcomes and their probabilities precisely
- **Sampling (Monte Carlo)**: Approximate probabilities by running many random trials

#### The Probability Monad

The essential functions for the probability monad class are `choose` (for making probabilistic choices) and `distrib` (for extracting the probability distribution). Other operations could be defined in terms of these but are provided by each instance for efficiency.

**Inside-monad operations** (building probabilistic computations):

- `choose : float -> 'a monad -> 'a monad -> 'a monad`: `choose p a b` represents an event which is `a` with probability $p$ and `b` with probability $1-p$.
- `pick : ('a * float) list -> 'a monad`: Draw a result from a given probability distribution. The argument must be a valid distribution: positive probabilities summing to 1.
- `uniform : 'a list -> 'a monad`: Uniform distribution -- each element equally likely.
- `flip : float -> bool monad`: A biased coin: `true` with probability `p`, `false` otherwise.
- `coin : bool monad`: A fair coin: `flip 0.5`.

**Outside-monad operations** (querying probabilistic computations):

- `prob : ('a -> bool) -> 'a monad -> float`: Returns the probability that a predicate holds.
- `distrib : 'a monad -> ('a * float) list`: Returns the full distribution of probabilities over outcomes.
- `access : 'a monad -> 'a`: Samples a random result from the distribution -- this is **non-functional** behavior (different calls may return different results).

```ocaml env=ch8
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

```ocaml env=ch8
let total dist =
  List.fold_left (fun a (_,b) -> a +. b) 0. dist

let merge dist = map_reduce (fun x -> x) (+.) 0. dist  (* Merge repeating elements *)

let normalize dist =                 (* Normalize a measure into a distribution *)
  let tot = total dist in
  if tot = 0. then dist
  else List.map (fun (e,w) -> e, w /. tot) dist

let roulette dist =                  (* Roulette wheel from a distribution/measure *)
  let tot = total dist in
  let rec aux r = function
    | [] -> assert false
    | (e, w)::_ when w <= r -> e
    | (_, w)::tl -> aux (r -. w) tl in
  aux (Random.float tot) dist
```

#### Exact Distribution Monad

```ocaml env=ch8
module DistribM : PROBABILITY = struct
  module M = struct       (* Exact probability distribution -- naive implementation *)
    type 'a t = ('a * float) list
    let bind a b = merge             (* x w.p. p and then y w.p. q happens = *)
      (List.concat_map (fun (x, p) ->
        List.map (fun (y, q) -> (y, q *. p)) (b x)) a)  (* y results w.p. p*q *)
    let return a = [a, 1.]           (* Certainly a *)
  end
  include M
  include MonadOps (M)
  let choose p a b =
    List.append
      (List.map (fun (e,w) -> e, p *. w) a)
      (List.map (fun (e,w) -> e, (1. -. p) *. w) b)
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

```ocaml env=ch8
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

The Monty Hall problem is a famous probability puzzle. In search of a new car, the player picks a door, say 1. The game host (who knows what is behind each door) then opens one of the other doors, say 3, to reveal a goat and offers to let the player switch to door 2 instead of door 1. Should the player switch?

Most people's intuition says it does not matter, but let us compute the actual probabilities:

```ocaml env=ch8
module MontyHall (P : PROBABILITY) = struct
  open P
  type door = A | B | C
  let doors = [A; B; C]

  let monty_win switch =
    let* prize = uniform doors in
    let* chosen = uniform doors in
    let* opened = uniform (list_diff doors [prize; chosen]) in
    let final =
      if switch then List.hd (list_diff doors [opened; chosen])
      else chosen in
    return (final = prize)
end

module MontyExact = MontyHall (DistribM)
module Sampling1000 =
  SamplingM (struct let samples = 1000 end)
module MontySimul = MontyHall (Sampling1000)

(* DistribM.distrib (MontyExact.monty_win false);; *)
(* DistribM.distrib (MontyExact.monty_win true);; *)
```

The famous result: switching doubles your chances of winning! Counter-intuitively, the host's choice of which door to open gives you information -- by switching, you are betting that your initial choice was wrong (which it is 2/3 of the time).

#### Conditional Probabilities

So far we have computed unconditional probabilities. But what if we want to answer questions like "given that X happened, what is the probability of Y?" This is a conditional probability $P(Y|X)$.

Wouldn't it be nice to have a monad-plus rather than just a monad? Then we could use `guard` for conditional probabilities!

To compute $P(A|B)$:
1. Compute what is needed for both $A$ and $B$
2. Guard $B$
3. Return $A$

For the exact distribution monad, we allow intermediate distributions to be *unnormalized* (probabilities sum to less than 1) and normalize at the end. For the sampling monad, we use *rejection sampling*: generate samples and discard those that do not satisfy the condition (though `mplus` has no straightforward correct implementation in this approach).

```ocaml env=ch8
module type COND_PROBAB = sig
  include PROBABILITY
  include MONAD_PLUS_OPS with type 'a monad := 'a monad
end

module DistribMP : COND_PROBAB = struct
  module MP = struct
    type 'a t = ('a * float) list      (* Measures no longer restricted to *)
    let bind a b = merge               (* probability distributions *)
      (List.concat_map (fun (x, p) ->
        List.map (fun (y, q) -> (y, q *. p)) (b x)) a)
    let return a = [a, 1.]
    let mzero = []                     (* Measure equal 0 everywhere is OK *)
    let mplus = List.append
  end
  include MP
  include MonadPlusOps (MP)
  let choose p a b =              (* It isn't a w.p. p & b w.p. (1-p) since a and b *)
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
  exception Rejected              (* For rejecting current sample *)
  module MP = struct              (* Monad operations are exactly as for SamplingM *)
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
  let prob p m =                  (* Getting out of monad: handle rejected samples *)
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

```ocaml env=ch8
module Burglary (P : COND_PROBAB) = struct
  open P
  type what_happened =
    | Safe | Burgl | Earthq | Burgl_n_earthq

  let check ~john_called ~mary_called ~radio =
    let* earthquake = flip 0.002 in
    let* () = guard (radio = None || radio = Some earthquake) in
    let* burglary = flip 0.001 in
    let alarm_p =
      match burglary, earthquake with
      | false, false -> 0.001
      | false, true -> 0.29
      | true, false -> 0.94
      | true, true -> 0.95 in
    let* alarm = flip alarm_p in
    let john_p = if alarm then 0.9 else 0.05 in
    let* john_calls = flip john_p in
    let* () = guard (john_calls = john_called) in
    let mary_p = if alarm then 0.7 else 0.01 in
    let* mary_calls = flip mary_p in
    let* () = guard (mary_calls = mary_called) in
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
```

### 8.14 Lightweight Cooperative Threads

Running multiple tasks asynchronously can hide I/O latency and utilize multi-core architectures. Traditional operating system threads are "heavyweight" -- they have significant overhead for context switching and memory. **Lightweight threads** are managed by the application rather than the OS, allowing many concurrent tasks with lower overhead.

Lightweight threads can be:
- **Preemptive**: The scheduler interrupts running threads to switch between them
- **Cooperative**: Threads voluntarily give up control at specific points (like I/O operations)

**Lwt** is a popular OCaml library for lightweight cooperative threads, implemented as a monad. The monadic structure ensures that thread switching happens at well-defined points (whenever you use `let*`), making the code easier to reason about.

The `bind` operation is inherently sequential: `bind a (fun x -> b)` computes `a`, and only resumes computing `b` once the result `x` is known.

For concurrency, we need to "suppress" this sequentiality. We introduce a parallel bind:

```
parallel : 'a monad -> 'b monad -> ('a -> 'b -> 'c monad) -> 'c monad
```

With `parallel a b (fun x y -> c)`, computations `a` and `b` can proceed concurrently. The continuation `c` runs once both results are available.

If the monad starts computing right away (as in the Lwt library), `parallel ea eb c` is equivalent to:

```
let a = ea in
let b = eb in
let* x = a in
let* y = b in
c x y
```

#### Fine-Grained vs. Coarse-Grained Concurrency

There are two approaches to when threads switch:

**Fine-grained** concurrency suspends at every `bind`. The scheduler runs other threads and comes back to complete the `bind` before running threads created since the suspension. This gives maximum interleaving but has higher overhead.

**Coarse-grained** concurrency only suspends when explicitly requested via a `suspend` (often called `yield`) operation. Library operations that need to wait for I/O should call `suspend` internally. This is more efficient but requires careful placement of suspension points.

#### Thread Monad Signatures

The thread monad extends the basic monad with parallel composition:

```ocaml env=ch8
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

The implementation uses a mutable state to track thread progress. Each thread is in one of three states: completed (`Return`), waiting (`Sleep` with a list of callbacks to invoke when done), or forwarded to another thread (`Link`):

```ocaml env=ch8
module Cooperative = Threads(struct
  type 'a state =
    | Return of 'a                 (* The thread has returned *)
    | Sleep of ('a -> unit) list   (* When thread returns, wake up waiters *)
    | Link of 'a t                 (* A link to the actual thread *)
  and 'a t = {mutable state : 'a state}  (* State of the thread can change *)
                                   (* -- it can return, or more waiters added *)
  let rec find t =                 (* Union-find style link chasing *)
    match t.state with
    | Link t -> find t
    | _ -> t

  let jobs = Queue.create ()       (* Work queue -- will store unit -> unit procedures *)

  let wakeup m a =                 (* Thread m has actually finished -- *)
    let m = find m in              (* updating its state *)
    match m.state with
    | Return _ -> assert false
    | Sleep waiters ->
        m.state <- Return a;       (* Set the state, and only then *)
        List.iter ((|>) a) waiters (* wake up the waiters *)
    | Link _ -> assert false

  let return a = {state = Return a}

  let connect t t' =               (* t was a placeholder for t' *)
    let t' = find t' in
    match t'.state with
    | Sleep waiters' ->
        let t = find t in
        (match t.state with
        | Sleep waiters ->         (* If both sleep, collect their waiters *)
            t.state <- Sleep (waiters' @ waiters);
            t'.state <- Link t     (* and link one to the other *)
        | _ -> assert false)
    | Return x -> wakeup t x       (* If t' returned, wake up the placeholder *)
    | Link _ -> assert false

  let rec bind a b =
    let a = find a in
    let m = {state = Sleep []} in  (* The resulting monad *)
    (match a.state with
    | Return x ->                  (* If a returned, we suspend further work *)
        let job () = connect m (b x) in  (* (In exercise 11, this should *)
        Queue.push job jobs        (* only happen after suspend) *)
    | Sleep waiters ->             (* If a sleeps, we wait for it to return *)
        let job x = connect m (b x) in
        a.state <- Sleep (job::waiters)
    | Link _ -> assert false);
    m

  let parallel a b c =             (* Since in our implementation *)
    bind a (fun x ->               (* the threads run as soon as they are created, *)
    bind b (fun y ->               (* parallel is redundant *)
    c x y))

  let rec access m =               (* Accessing not only gets the result of m, *)
    let m = find m in              (* but spins the thread loop till m terminates *)
    match m.state with
    | Return x -> x                (* No further work *)
    | Sleep _ ->
        (try Queue.pop jobs ()     (* Perform suspended work *)
         with Queue.Empty ->
           failwith "access: result not available");
        access m
    | Link _ -> assert false

  let kill_threads () = Queue.clear jobs  (* Remove pending work *)
end)
```

#### Testing the Thread Implementation

Let us test the implementation with two threads that each print a sequence of numbers:

```ocaml env=ch8
module TTest (T : THREAD_OPS) = struct
  open T
  let rec loop s n =
    let* () = return (Printf.printf "-- %s(%d)\n%!" s n) in
    if n > 0 then loop s (n-1)     (* We cannot use whenM because the thread *)
    else return ()                 (* would be created regardless of condition *)
end

module TT = TTest (Cooperative)

let test =
  Cooperative.kill_threads ();     (* Clean-up after previous tests *)
  let thread1 = TT.loop "A" 5 in
  let thread2 = TT.loop "B" 4 in
  Cooperative.access thread1;      (* We ensure threads finish computing *)
  Cooperative.access thread2       (* before we proceed *)
```

The output shows that the threads interleave their execution beautifully: A(5), B(4), A(4), B(3), and so on. Each `bind` (the `let*`) causes a context switch to the other thread. This is fine-grained concurrency in action.

The key insight is that monadic structure gives us precise control over concurrency. Every `let*` is a potential suspension point, making the code's behavior predictable and debuggable -- a significant advantage over preemptive threading where context switches can happen anywhere.

### 8.15 Exercises

**Exercise 1.** (Puzzle via Oleg Kiselyov)

"U2" has a concert that starts in 17 minutes and they must all cross a bridge to get there. All four men begin on the same side of the bridge. It is night. There is one flashlight. A maximum of two people can cross at one time. Any party who crosses, either 1 or 2 people, must have the flashlight with them. The flashlight must be walked back and forth, it cannot be thrown, etc. Each band member walks at a different speed. A pair must walk together at the rate of the slower man's pace:

- Bono: 1 minute to cross
- Edge: 2 minutes to cross
- Adam: 5 minutes to cross
- Larry: 10 minutes to cross

For example: if Bono and Larry walk across first, 10 minutes have elapsed when they get to the other side of the bridge. If Larry then returns with the flashlight, a total of 20 minutes have passed and you have failed the mission.

Find all answers to the puzzle using `let*` notation. The expression will be a bit long but recursion is not needed.

**Exercise 2.** Assume `concat_map` as defined in lecture 6 and the binding operators defined above. What will the following expressions return? Why?

1. `let* _ = return 5 in return 7`
2. `let guard p = if p then [()] else [] in let* () = guard false in return 7`
3. `let* _ = return 5 in let* () = guard false in return 7`

**Exercise 3.** Define `bind` in terms of `lift` and `join`.

**Exercise 4.** Define a monad-plus implementation based on binary trees, with constant-time `mzero` and `mplus`. Starter code:

```ocaml skip
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

```ocaml skip
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
