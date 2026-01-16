## Chapter 10: Functional Reactive Programming

How do we deal with change and interaction in functional programming? This is one of the most challenging questions in the field, and over the years programmers have developed increasingly sophisticated answers. This chapter explores a progression of techniques: we begin with *zippers*, a clever data structure for navigating and modifying positions within larger structures. We then advance to *adaptive programming* (also known as incremental computing), which automatically propagates changes through computations. Finally, we arrive at *Functional Reactive Programming* (FRP), a declarative approach to handling time-varying values and event streams. We conclude with practical examples including graphical user interfaces.

**Recommended Reading:**

- *"Zipper"* in Haskell Wikibook and *"The Zipper"* by Gerard Huet
- *"How `froc` works"* by Jacob Donham
- *"The Haskell School of Expression"* by Paul Hudak
- *"Deprecating the Observer Pattern with `Scala.React`"* by Ingo Maier, Martin Odersky

### 10.1 Zippers

Imagine you are editing a document, a tree structure, or navigating through a file system. You need to keep track of where you are, easily access and modify the data at that location, and move around efficiently. This is exactly the problem that zippers solve.

Recall from earlier chapters how we defined *context types* for datatypes -- types that represent a data structure with one of its elements missing. We discovered that taking the derivative of an algebraic datatype gives us exactly this context type. Now we will put this theory to practical use.

Consider binary trees:

```ocaml skip
type btree = Tip | Node of int * btree * btree
```

Using our algebraic datatype calculus, where $T$ represents the tree type:

$$
\begin{matrix}
T & = & 1 + xT^2 \\
\frac{\partial T}{\partial x} & = & 0 + T^2 + 2xT\frac{\partial T}{\partial x} = TT + 2xT\frac{\partial T}{\partial x}
\end{matrix}
$$

This derivative gives us the context type:

```ocaml skip
type btree_dir = LeftBranch | RightBranch
type btree_deriv =
  | Here of btree * btree
  | Below of btree_dir * int * btree * btree_deriv
```

The key insight is that **Location = context + subtree**! A location in a data structure consists of two parts: the context (everything around the focused element) and the subtree (what we are currently looking at).

However, there is a problem with the representation above: we cannot easily move the location if `Here` is at the bottom of our context representation. Think about it: if we want to move up from our current position, we need to access the innermost layer of the context first. The part closest to the location should be on top, not buried at the bottom.

#### Revisiting the Equations

Let us revisit the equations for trees and lists:

$$
\begin{matrix}
T & = & 1 + xT^2 \\
\frac{\partial T}{\partial x} & = & 0 + T^2 + 2xT\frac{\partial T}{\partial x} \\
\frac{\partial T}{\partial x} & = & \frac{T^2}{1 - 2xT} \\
L(y) & = & 1 + yL(y) \\
L(y) & = & \frac{1}{1 - y} \\
\frac{\partial T}{\partial x} & = & T^2 L(2xT)
\end{matrix}
$$

This algebraic manipulation reveals something beautiful: the context can be stored as a list with the root as the last node. The $L(2xT)$ factor tells us that we have a list where each element consists of $2xT$ -- that is, a direction indicator (left or right, hence the factor of 2), the element at that node ($x$), and the sibling subtree ($T$).

It does not matter whether we use built-in OCaml lists or define a custom type with `Above` and `Root` variants -- the structure is the same.

In practice, contexts of subtrees are more useful than contexts of single elements. Rather than tracking where a single value lives, we track the position of an entire subtree within the larger structure:

```ocaml skip
type 'a tree = Tip | Node of 'a tree * 'a * 'a tree
type tree_dir = Left_br | Right_br
type 'a context = (tree_dir * 'a * 'a tree) list
type 'a location = {sub: 'a tree; ctx: 'a context}

let access {sub} = sub       (* Get the current subtree *)
let change {ctx} sub = {sub; ctx}  (* Replace the subtree, keep context *)
let modify f {sub; ctx} = {sub = f sub; ctx}  (* Transform the subtree *)
```

There is a wonderful visual intuition for zippers: imagine taking a tree and pinning it at one of its nodes, then letting it hang down under gravity. The pinned node becomes "the current focus," and all the other parts of the tree dangle from it. This mental picture helps understand how movement works: moving to a child means letting a new node become the pin point, with the old parent now hanging above. For excellent visualizations, see http://en.wikibooks.org/wiki/Haskell/Zippers.

#### Moving Around

Navigation functions allow us to traverse the structure. Each movement operation restructures the zipper: what was context becomes part of the subtree, and vice versa. Watch how ascending rebuilds a parent node from the context, while descending breaks apart a node to create new context:

```ocaml skip
let ascend loc =
  match loc.ctx with
  | [] -> loc  (* At root already, or raise exception *)
  | (Left_br, n, l) :: up_ctx ->
    (* We were in the right subtree; rebuild the parent node *)
    {sub = Node (l, n, loc.sub); ctx = up_ctx}
  | (Right_br, n, r) :: up_ctx ->
    (* We were in the left subtree; rebuild the parent node *)
    {sub = Node (loc.sub, n, r); ctx = up_ctx}

let desc_left loc =
  match loc.sub with
  | Tip -> loc  (* Cannot descend into a tip, or raise exception *)
  | Node (l, n, r) ->
    (* Focus on left child; right sibling goes into context *)
    {sub = l; ctx = (Right_br, n, r) :: loc.ctx}

let desc_right loc =
  match loc.sub with
  | Tip -> loc  (* Cannot descend into a tip, or raise exception *)
  | Node (l, n, r) ->
    (* Focus on right child; left sibling goes into context *)
    {sub = r; ctx = (Left_br, n, l) :: loc.ctx}
```

#### Trees with Arbitrary Branching

Following *The Zipper* by Gerard Huet, let us look at a tree with an arbitrary number of branches. This is particularly useful for representing document structures where a group can contain any number of children:

```ocaml skip
type doc = Text of string | Line | Group of doc list
type context = (doc list * doc list) list  (* left siblings, right siblings *)
type location = {sub: doc; ctx: context}
```

In this design, the context at each level stores two lists: the siblings to the left of our current position (in reverse order for efficient access) and the siblings to the right. This allows us to move not just up and down, but also left and right among siblings.

The navigation functions for this more complex structure show how we reconstruct the parent when going up, and how we split the sibling list when going down:

```ocaml skip
let go_up loc =
  match loc.ctx with
  | [] -> invalid_arg "go_up: at top"
  | (left, right) :: up_ctx ->
    (* Reconstruct the Group: reverse left siblings, add current, then right *)
    {sub = Group (List.rev left @ loc.sub :: right); ctx = up_ctx}

let go_left loc =
  match loc.ctx with
  | [] -> invalid_arg "go_left: at top"
  | (l :: left, right) :: up_ctx ->
    (* Move to left sibling; current element moves to right siblings *)
    {sub = l; ctx = (left, loc.sub :: right) :: up_ctx}
  | ([], _) :: _ -> invalid_arg "go_left: at first"

let go_right loc =
  match loc.ctx with
  | [] -> invalid_arg "go_right: at top"
  | (left, r :: right) :: up_ctx ->
    (* Move to right sibling; current element moves to left siblings *)
    {sub = r; ctx = (loc.sub :: left, right) :: up_ctx}
  | (_, []) :: _ -> invalid_arg "go_right: at last"

let go_down loc =
  (* Go to the first (i.e. leftmost) subdocument *)
  match loc.sub with
  | Text _ -> invalid_arg "go_down: at text"
  | Line -> invalid_arg "go_down: at line"
  | Group [] -> invalid_arg "go_down: at empty"
  | Group (doc :: docs) ->
    (* First child becomes focus; rest become right siblings *)
    {sub = doc; ctx = ([], docs) :: loc.ctx}
```

### 10.2 Example: Context Rewriting

Let us put zippers to work on a real problem. Imagine a friend working on string theory asks us for help simplifying equations. The task is to pull out particular subexpressions as far to the left as possible, while changing the whole expression as little as possible. This kind of algebraic manipulation is common in symbolic computation.

We can illustrate our algorithm using mathematical notation. Let:
- $x$ be the thing we pull out
- $C[e]$ and $D[e]$ be big expressions with subexpression $e$
- operator $\circ$ stand for one of: $*, +$

The rewriting rules are:

$$
\begin{matrix}
D[(C[x] \circ e_1) \circ e_2] & \Rightarrow & D[C[x] \circ (e_1 \circ e_2)] \\
D[e_2 \circ (C[x] \circ e_1)] & \Rightarrow & D[C[x] \circ (e_1 \circ e_2)] \\
D[(C[x] + e_1) e_2] & \Rightarrow & D[C[x] e_2 + e_1 e_2] \\
D[e_2 (C[x] + e_1)] & \Rightarrow & D[C[x] e_2 + e_1 e_2] \\
D[e \circ C[x]] & \Rightarrow & D[C[x] \circ e]
\end{matrix}
$$

These rules encode the algebraic properties we need: associativity (first two rules), distributivity of multiplication over addition (third and fourth rules), and commutativity (last rule, which lets us swap operands). The key insight is that we can implement these transformations efficiently using a zipper, since each rule only needs to look at a small neighborhood of the current position.

First, the groundwork. We define expression types and a zipper for navigating them:

```ocaml skip
type op = Add | Mul
type expr = Val of int | Var of string | App of expr * op * expr
type expr_dir = Left_arg | Right_arg
type context = (expr_dir * op * expr) list
type location = {sub: expr; ctx: context}
```

To locate the subexpression described by predicate `p`, we search the expression tree and build up the context as we go. Notice that we build the context in reverse order during the search, then reverse it at the end so the innermost context comes first (as required for efficient navigation):

```ocaml skip
let rec find_aux p e =
  if p e then Some (e, [])
  else match e with
  | Val _ | Var _ -> None
  | App (l, op, r) ->
    match find_aux p l with
    | Some (sub, up_ctx) ->
      Some (sub, (Right_arg, op, r) :: up_ctx)
    | None ->
      match find_aux p r with
      | Some (sub, up_ctx) ->
        Some (sub, (Left_arg, op, l) :: up_ctx)
      | None -> None

let find p e =
  match find_aux p e with
  | None -> None
  | Some (sub, ctx) -> Some {sub; ctx = List.rev ctx}
```

Now we can implement the pull-out transformation. This is where the zipper shines: we pattern match on the context to decide which rewriting rule to apply, then modify the context directly. The function recursively moves the target subexpression outward until it reaches the root:

```ocaml skip
let rec pull_out loc =
  match loc.ctx with
  | [] -> loc  (* Done: reached the root *)
  | (Left_arg, op, l) :: up_ctx ->
    (* D[e . C[x]] => D[C[x] . e] -- use commutativity to swap sides *)
    pull_out {loc with ctx = (Right_arg, op, l) :: up_ctx}
  | (Right_arg, op1, e1) :: (_, op2, e2) :: up_ctx
      when op1 = op2 ->
    (* D[(C[x] . e1) . e2] => D[C[x] . (e1 . e2)] -- associativity *)
    pull_out {loc with ctx = (Right_arg, op1, App(e1, op1, e2)) :: up_ctx}
  | (Right_arg, Add, e1) :: (_, Mul, e2) :: up_ctx ->
    (* D[(C[x] + e1) * e2] => D[C[x] * e2 + e1 * e2] -- distributivity *)
    pull_out {loc with ctx =
        (Right_arg, Mul, e2) ::
          (Right_arg, Add, App(e1, Mul, e2)) :: up_ctx}
  | (Right_arg, op, r) :: up_ctx ->
    (* No rule applies: move up by incorporating current context *)
    pull_out {sub = App(loc.sub, op, r); ctx = up_ctx}
```

Since we assume operators are commutative, we can ignore the direction for the second piece of context above -- both `(C[x] . e1) . e2` and `e2 . (C[x] . e1)` are handled by the same associativity rule.

Let us test the implementation with a concrete example:

```ocaml skip
let (+) a b = App (a, Add, b)  (* Convenient syntax for building expressions *)
let ( * ) a b = App (a, Mul, b)
let (!) a = Val a
let x = Var "x"
let y = Var "y"

(* Original: 5 + y * (7 + x) * (3 + y) -- we want to pull x to the front *)
let ex = !5 + y * (!7 + x) * (!3 + y)
let loc = find (fun e -> e = x) ex
let sol =
  match loc with
  | None -> raise Not_found
  | Some loc -> pull_out loc
(* Result: "(((x*y)*(3+y))+(((7*y)*(3+y))+5))" *)
(* The x has been pulled out to the leftmost position! *)
```

The transformation successfully pulled `x` from deep inside the expression to the outermost left position. For best results on complex expressions, we can iterate the `pull_out` function until a fixpoint is reached, ensuring all instances of the target are pulled out as far as possible.

### 10.3 Adaptive Programming (Incremental Computing)

Zippers gave us a way to make *local* edits to a large structure while keeping enough context to put the structure back together. But they do not, by themselves, solve a more global problem:

> if we change an input, how do we update *all* the derived results efficiently, without rewriting the whole program to “thread the context around”?

**Incremental computing** (also called **self-adjusting computation** or **adaptive programming**) answers this by letting us write code in a direct style while the runtime system records *dependencies* between intermediate results. When an input changes, only the part of the computation graph that depends on that input is recomputed; everything else is reused.

#### A Mental Model: Traces and Change Propagation

Think of an incremental program as building a directed acyclic graph (DAG):

- **Leaves** are *changeable inputs* (mutable cells).
- **Internal nodes** are *pure computations* (maps, combinations, binds).
- **Roots** are *observers* (the results we care to keep up-to-date).

When a leaf changes, the system does two logically separate things:

1. **Invalidate** cached results that (transitively) depend on the changed leaf.
2. **Recompute** just enough of the graph to bring the observed roots back to a consistent state.

Different libraries make different choices about *when* recomputation happens (eager stabilization vs. lazy sampling), *how* they avoid redundant work (timestamps vs. boolean dirty flags), and *what* extra guarantees they provide (cutoffs, resource lifetimes, “no glitches”).

#### Conditional Dependencies (Dynamic Graphs)

The most interesting case is when the dependency graph itself depends on data:

```ocaml skip
(* Pseudocode: the dependencies of [out] depend on [use_fast]. *)
let out =
  if use_fast then fast_path input
  else slow_path input
```

If `use_fast` flips, we must stop depending on the old branch and start depending on the new one. Incremental systems support this with a *dynamic dependency* operator:

- `bind` / `join` / `switch` (names vary): pick which subgraph is active *based on a value*.

Operationally, this means: detach edges to the old branch, attach edges to the new branch, then recompute along the newly relevant dependencies. This is also where “glitch freedom” matters: we want each observed root to be updated as if we recomputed in a topological order on a single, consistent snapshot of inputs.

#### Two Modern OCaml Libraries: `lwd` and `incremental`

Many ideas above can be packaged behind a small “conceptual API”:

```ocaml skip
module type INCREMENTAL = sig
  type 'a t
  type 'a var
  type 'a obs

  val var : 'a -> 'a var
  val get : 'a var -> 'a t
  val set : 'a var -> 'a -> unit

  val map : 'a t -> f:('a -> 'b) -> 'b t
  val map2 : 'a t -> 'b t -> f:('a -> 'b -> 'c) -> 'c t
  val bind : 'a t -> f:('a -> 'b t) -> 'b t

  val observe : 'a t -> 'a obs
  val sample : 'a obs -> 'a
end
```

OCaml has at least two widely used implementations of this idea, with different priorities.

##### `Lwd` (Lightweight Reactive Documents)

`Lwd` is designed around building *reactive trees* (most famously, UI trees). Its model is **invalidate eagerly, recompute lazily**:

- `Lwd.var` / `Lwd.set` mutate leaves and immediately invalidate dependent nodes.
- Values are recomputed on demand when you `Lwd.sample` a **root** (an observer).
- It tracks *liveness*: nodes not reachable from any root are released, and `Lwd.prim` supports `acquire`/`release` for resource lifetimes (subscriptions, DOM nodes, etc.).

```ocaml skip
(* Using Lwd as an incremental engine *)
let a = Lwd.var 10
let b = Lwd.var 32

let sum : int Lwd.t =
  Lwd.map2 (Lwd.get a) (Lwd.get b) ~f:( + )

let root = Lwd.observe sum
let now () = Lwd.quick_sample root

let () =
  let s0 = now () in  (* 42 *)
  Lwd.set a 11;
  let s1 = now () in  (* 43 *)
  ignore (s0, s1)
```

##### `Incremental` (Jane Street)

`Incremental` is a general-purpose industrial incremental engine. Its model is **batch updates into a stabilization pass**:

- `Incr.Var.set` records changes to leaves.
- `Incr.stabilize` recomputes all stale *necessary* nodes in an order based on node heights (a topological schedule).
- It supports **cutoffs** (don’t propagate if “unchanged enough”), rich observer hooks, and scoping mechanisms that help manage dynamic graphs.

```ocaml skip
module Incr = Incremental.Make ()
module State = (val Incr.State.create ())

let a = Incr.Var.create State.t 10
let b = Incr.Var.create State.t 32
let sum = Incr.map2 (Incr.Var.watch a) (Incr.Var.watch b) ~f:( + )

let obs = Incr.observe sum
let now () =
  Incr.stabilize State.t;
  Incr.Observer.value_exn obs

let () =
  let s0 = now () in  (* 42 *)
  Incr.Var.set a 11;
  let s1 = now () in  (* 43 *)
  ignore (s0, s1)
```

##### Comparing Design Choices (Why Two Libraries?)

Both libraries implement self-adjusting computation, but they optimize for different problem shapes. A quick high-level summary (see `chapter10/lwd_vs_incremental_comparison.md` for more detail):

- **When recomputation happens**
  - `Lwd`: recompute on `sample` (pull), after eager invalidation (push).
  - `Incremental`: recompute during `stabilize` (push), sampling is just reading.
- **Graph shape expectations**
  - `Lwd`: typically tree-ish with occasional sharing; optimized to be small.
  - `Incremental`: arbitrary large DAGs with heavy sharing; optimized to schedule recomputation precisely.
- **Change propagation policy**
  - `Lwd`: simple invalidation flags; minimal bookkeeping.
  - `Incremental`: timestamps/heights, recompute heaps, cutoffs; more bookkeeping, more guarantees and knobs.
- **Lifetimes**
  - `Lwd`: explicit `acquire`/`release` on primitives; roots control liveness.
  - `Incremental`: observers/scopes and finalizers; “necessary” vs “unnecessary” nodes.

The moral is not “one is better”; it is that incremental computing is a *design space*. Your choice should match how you expect your graph to evolve (tree vs. DAG, dynamic dependencies, scale) and how much control you need over scheduling and cutoffs.

#### When Incremental Computing Wins (and When It Doesn’t)

Incremental computing has overhead: it builds and maintains a dependency graph and caches intermediate results. It tends to win when you have:

- a large computation that you will update *many times*,
- each update changes a *small part* of the inputs,
- and you need outputs after each update.

If you build something once and throw it away, plain recomputation can be faster and simpler.

### 10.4 Functional Reactive Programming

Incremental computing is about efficiently updating a *pure* computation when some inputs change. **Functional Reactive Programming (FRP)** is about structuring programs that interact with a changing world—key presses, network packets, sensor readings, animations—*without giving up declarative composition*.

FRP revolves around a small vocabulary:

- A **behavior** is a value that exists “at every time” (mouse position, window size, current score).
- An **event** is a discrete occurrence (a key press, a click, a timer tick).
- A **signal** is a generic name for either kind of thing (terminology varies across libraries).

Two constraints shape every FRP design:

1. **Causality**. A signal at time `t` may depend on the past and present, but not on the future. Feedback loops must include a delay (e.g. “previous value”, integration, an explicit state step).
2. **Efficiency and consistency**. We want to avoid replaying the entire history of the world on every sample, and we want to avoid *glitches*—temporarily observing inconsistent intermediate states because dependencies update in the wrong order.

In practice, FRP systems implement some notion of an **update step** (also called a tick, a frame, a stabilization pass). During an update step we incorporate all inputs that “happened simultaneously” and then recompute derived signals in a schedule that respects dependencies.

#### A Concrete Input Model

To keep the discussion concrete, we will package external inputs (user actions) together with sampling times:

```ocaml skip
type time = float

type user_action =
  | Key of char * bool
  | Button of int * int * bool * bool
  | MouseMove of int * int
  | Resize of int * int
```

We will present two implementations:

1. A **stream-processing** implementation (Section 10.5) that makes time explicit and computes signals by consuming an input stream.
2. An **incremental** implementation (Section 10.6) that represents signals as nodes in an incremental dependency graph and updates them by invalidation/stabilization.

Conceptually, in the stream-processing interpretation we will treat:

```ocaml skip
(* Conceptual types (we refine the representation in Section 10.5). *)
type 'a behavior = (user_action option * time) stream -> 'a stream
type 'a event = 'a option behavior
```

### 10.5 Reactivity by Stream Processing

Now let us implement FRP using the stream processing techniques from Chapter 7. The infrastructure should be familiar:

```ocaml skip
type 'a stream = 'a stream_ Lazy.t
and 'a stream_ = Cons of 'a * 'a stream

let rec lmap f l = lazy (
  let Cons (x, xs) = Lazy.force l in
  Cons (f x, lmap f xs))

let rec liter (f : 'a -> unit) (l : 'a stream) : unit =
  let Cons (x, xs) = Lazy.force l in
  f x; liter f xs

let rec lmap2 f xs ys = lazy (
  let Cons (x, xs) = Lazy.force xs in
  let Cons (y, ys) = Lazy.force ys in
  Cons (f x y, lmap2 f xs ys))

let rec lmap3 f xs ys zs = lazy (
  let Cons (x, xs) = Lazy.force xs in
  let Cons (y, ys) = Lazy.force ys in
  let Cons (z, zs) = Lazy.force zs in
  Cons (f x y z, lmap3 f xs ys zs))

let rec lfold acc f (l : 'a stream) = lazy (
  let Cons (x, xs) = Lazy.force l in  (* Fold a function over the stream *)
  let acc = f acc x in  (* producing a stream of partial results *)
  Cons (acc, lfold acc f xs))
```

Since a behavior is a function from the input stream to an output stream, we face a subtle sharing problem: if we apply the same behavior function twice to the "same" input, we might create two separate streams that diverge. We need to ensure that for any actual input stream, each behavior creates exactly one output stream. This requires memoization:

```ocaml skip
type ('a, 'b) memo1 =
  {memo_f : 'a -> 'b; mutable memo_r : ('a * 'b) option}

let memo1 f = {memo_f = f; memo_r = None}

let memo1_app f x =
  match f.memo_r with
  | Some (y, res) when x == y -> res  (* Physical equality check *)
  | _ ->
    let res = f.memo_f x in
    f.memo_r <- Some (x, res);  (* Cache for next call *)
    res

let ($) = memo1_app  (* Convenient infix for memoized application *)

type 'a behavior =
  ((user_action option * time) stream, 'a stream) memo1
```

We use physical equality (`==`) rather than structural equality (`=`) because the external input stream is a single physical object -- if we see the same pointer, we know it is the same stream. During debugging, we can verify that `memo_r` is `None` before the first call and `Some` afterwards.

#### Building Complex Behaviors

Now we can build the monadic/applicative functions for composing behaviors. A practical tip: when working with these higher-order types, type annotations are essential. If you do not provide type annotations in `.ml` files, work together with an `.mli` interface file to catch type problems early.

```ocaml skip
(* A constant behavior: returns the same value at all times *)
let returnB x : 'a behavior =
  let rec xs = lazy (Cons (x, xs)) in  (* Infinite stream of x *)
  memo1 (fun _ -> xs)

let ( !* ) = returnB  (* Convenient prefix operator for constants *)

(* Lift a unary function to work on behaviors *)
let liftB f fb = memo1 (fun uts -> lmap f (fb $ uts))

(* Lift binary and ternary functions similarly *)
let liftB2 f fb1 fb2 = memo1
  (fun uts -> lmap2 f (fb1 $ uts) (fb2 $ uts))

let liftB3 f fb1 fb2 fb3 = memo1
  (fun uts -> lmap3 f (fb1 $ uts) (fb2 $ uts) (fb3 $ uts))

(* Lift a function to work on events (None -> None, Some e -> Some (f e)) *)
let liftE f (fe : 'a event) : 'b event = memo1
  (fun uts -> lmap
    (function Some e -> Some (f e) | None -> None)
    (fe $ uts))

let (=>>) fe f = liftE f fe  (* Map over events, infix style *)
let (->>) e v = e =>> fun _ -> v  (* Replace event value with constant *)
```

We also need to create events from behaviors and vice versa. Creating events out of behaviors:

```ocaml skip
(* whileB: produces an event at every moment the behavior is true *)
let whileB (fb : bool behavior) : unit event =
  memo1 (fun uts ->
    lmap (function true -> Some () | false -> None)
      (fb $ uts))

(* unique: filters out duplicate consecutive events *)
let unique fe : 'a event =
  memo1 (fun uts ->
    let xs = fe $ uts in
    lmap2 (fun x y -> if x = y then None else y)
      (lazy (Cons (None, xs))) xs)  (* Compare with previous value *)

(* whenB: produces an event when the behavior becomes true (edge detection) *)
let whenB fb =
  memo1 (fun uts -> unique (whileB fb) $ uts)

(* snapshot: when an event occurs, capture both the event value and current behavior value *)
let snapshot fe fb : ('a * 'b) event =
  memo1 (fun uts -> lmap2
    (fun x -> function Some y -> Some (y, x) | None -> None)
      (fb $ uts) (fe $ uts))
```

Creating behaviors out of events:

```ocaml skip
(* step: holds the value of the most recent event, starting with 'acc' *)
let step acc fe =
  memo1 (fun uts -> lfold acc
    (fun acc -> function None -> acc | Some v -> v)
    (fe $ uts))

(* step_accum: accumulates by applying functions from events to current value *)
let step_accum acc ff =
  memo1 (fun uts ->
    lfold acc (fun acc -> function
      | None -> acc | Some f -> f acc)
      (ff $ uts))
```

For physics simulations like our upcoming paddle game, we need to integrate behaviors over time. This requires access to the sampling timestamps:

```ocaml skip
let integral fb =
  let rec loop t0 acc uts bs =
    let Cons ((_, t1), uts) = Lazy.force uts in
    let Cons (b, bs) = Lazy.force bs in
    (* Rectangle rule: b is fb(t1), acc approximates integral up to t0 *)
    let acc = acc +. (t1 -. t0) *. b in
    Cons (acc, lazy (loop t1 acc uts bs)) in
  memo1 (fun uts -> lazy (
    let Cons ((_, t), uts') = Lazy.force uts in
    Cons (0., lazy (loop t 0. uts' (fb $ uts)))))
```

In our upcoming *paddle game* example, we will express position and velocity in a mutually recursive manner -- position is the integral of velocity, but velocity changes when position hits a wall. This seems paradoxical: how can we define position in terms of velocity if velocity depends on position?

The trick is the same as we saw in Chapter 7: integration introduces one step of delay. The integral at time $t$ depends on velocities at times *before* $t$, while the bounce detection at time $t$ uses the position at time $t$. This breaks the cyclic dependency and makes the recursion well-founded.

We define behaviors for user actions by extracting them from the input stream:

```ocaml skip
(* Left button press event *)
let lbp : unit event =
  memo1 (fun uts -> lmap
    (function Some(Button(_,_)), _ -> Some() | _ -> None)
    uts)

(* Mouse movement event (carries coordinates) *)
let mm : (int * int) event =
  memo1 (fun uts -> lmap
    (function Some(MouseMove(x, y)), _ -> Some(x, y) | _ -> None)
    uts)

(* Window resize event *)
let screen : (int * int) event =
  memo1 (fun uts -> lmap
    (function Some(Resize(x, y)), _ -> Some(x, y) | _ -> None)
    uts)

(* Behaviors derived from events using step *)
let mouse_x : int behavior = step 0 (liftE fst mm)  (* Current mouse X *)
let mouse_y : int behavior = step 0 (liftE snd mm)  (* Current mouse Y *)
let width : int behavior = step 640 (liftE fst screen)  (* Window width *)
let height : int behavior = step 512 (liftE snd screen) (* Window height *)
```

#### The Paddle Game Example

Now let us put all these pieces together to build a classic paddle game (similar to Pong). A ball bounces around the screen, and the player controls a paddle at the bottom to prevent the ball from falling.

First, we define a *scene graph*, a data structure that represents a "world" which can be drawn on screen:

```ocaml skip
type scene =
  | Rect of int * int * int * int  (* position, width, height *)
  | Circle of int * int * int  (* position, radius *)
  | Group of scene list
  | Color of Graphics.color * scene  (* color of subscene objects *)
  | Translate of float * float * scene  (* additional offset of origin *)
```

The drawing function interprets the scene graph, accumulating translations as it traverses:

```ocaml skip
let draw sc =
  let f2i = int_of_float in
  let open Graphics in
  let rec aux t_x t_y = function  (* t_x, t_y accumulate translations *)
    | Rect (x, y, w, h) ->
      fill_rect (f2i t_x + x) (f2i t_y + y) w h
    | Circle (x, y, r) ->
      fill_circle (f2i t_x + x) (f2i t_y + y) r
    | Group scs ->
      List.iter (aux t_x t_y) scs
    | Color (c, sc) ->
      set_color c; aux t_x t_y sc  (* Set color, then draw *)
    | Translate (x, y, sc) ->
      aux (t_x +. x) (t_y +. y) sc in  (* Add to accumulated offset *)
  clear_graph ();  (* Clear the back buffer *)
  aux 0. 0. sc;
  synchronize ()  (* Swap buffers -- this avoids flickering *)
```

An *animation* is simply a scene behavior -- a time-varying scene. The `reactimate` function runs the animation loop: it creates the input stream (user actions paired with sampling times), feeds it to the scene behavior to get a stream of scenes, and draws each scene. We use double buffering to avoid flickering.

For the game logic, we define lifted operators so we can write behavior expressions naturally:

```ocaml skip
let (+*) = liftB2 (+)
let (-*) = liftB2 (-)
let ( *** ) = liftB2 ( * )
let (/*) = liftB2 (/)
let (&&*) = liftB2 (&&)
let (||*) = liftB2 (||)
let (<*) = liftB2 (<)
let (>*) = liftB2 (>)
```

Now we can define the game elements. The walls are drawn on the left, top and right borders of the window:

```ocaml skip
let walls =
  liftB2 (fun w h -> Color (Graphics.blue, Group
    [Rect (0, 0, 20, h-1); Rect (0, h-21, w-1, 20);
     Rect (w-21, 0, 20, h-1)]))
    width height
```

The paddle is tied to the mouse at the bottom border of the window:

```ocaml skip
let paddle = liftB (fun mx ->
  Color (Graphics.black, Rect (mx, 0, 50, 10))) mouse_x
```

The ball has a velocity in pixels per second and bounces from the walls. Unfortunately, OCaml being an eager language does not let us encode mutually recursive behaviors as elegantly as we might in a lazy language like Haskell. We need to unpack behaviors and events as explicit functions of the input stream and tie the knot manually using mutable record fields.

The key ideas in the ball implementation:

- `xbounce ->> (~-.)` -- When an `xbounce` event fires, emit the negation function `(~-.)`. This will be used to flip the velocity sign.

- `step_accum vel (xbounce ->> (~-.))` -- Start with velocity `vel`, and whenever a bounce event occurs, apply the negation function to flip the sign. This creates a velocity that bounces back and forth.

- `liftB int_of_float (integral xvel) +* width /* !*2` -- Integrate velocity to get position (as a float), truncate to integers, and offset to center the ball in the window.

- `whenB ((xpos >* width -* !*27) ||* (xpos <* !*27))` -- Fire an event the *first* time the position exceeds the wall boundaries (27 pixels from edges, accounting for wall thickness and ball radius). The `whenB` combinator produces an event only on the *transition* from false to true, ensuring we do not keep bouncing while inside the wall.

### 10.6 Reactivity by Incremental Computing (Lwd)

The stream-based implementation made time explicit and computed everything by consuming a stream. A different, often more *practical* approach is:

1. Keep the “outside world” in **mutable input cells** (mouse position, current time, a queue of clicks, …).
2. Define derived values as a **pure dependency graph** over these cells.
3. After each input update (or once per frame), **sample** the root result.

This is exactly the incremental-computing picture from Section 10.3, specialized to reactive programs.

#### Behaviors and Events in an Incremental World

One clean way to phrase this with `Lwd` is:

- A **behavior** is just an `Lwd.t`: a value recomputed when needed.
- An **event** is an `Lwd.t` that is `None` most of the time and `Some v` for one update step.

```ocaml skip
module Lwd_frp = struct
  type 'a behavior = 'a Lwd.t
  type 'a event = 'a option Lwd.t

  let returnB x = Lwd.pure x
  let mapB b ~f = Lwd.map b ~f
  let mapB2 a b ~f = Lwd.map2 a b ~f

  let mapE e ~f = Lwd.map e ~f:(Option.map f)
  let filterE e ~f =
    Lwd.map e ~f:(function None -> None | Some x -> f x)

  let mergeE a b =
    Lwd.map2 a b ~f:(fun a b -> match a with Some _ -> a | None -> b)
end
```

The missing piece is *time*. `Lwd` does not “know” about time; you supply it as another input variable and decide when to sample:

```ocaml skip
(* Inputs *)
let time_v : float Lwd.var = Lwd.var 0.0
let mouse_v : (int * int) Lwd.var = Lwd.var (0, 0)
let click_v : unit option Lwd.var = Lwd.var None  (* pulse: set to Some () for one step *)

(* Behaviors (derived values) *)
let time_b : float Lwd.t = Lwd.get time_v
let mouse_b : (int * int) Lwd.t = Lwd.get mouse_v

let mouse_x : int Lwd.t = Lwd.map mouse_b ~f:fst
let mouse_y : int Lwd.t = Lwd.map mouse_b ~f:snd

(* An event view of clicks *)
let click_e : unit option Lwd.t = Lwd.get click_v
```

Now we can define a derived “model” value (or a view tree) and observe it:

```ocaml skip
(* A toy “reactive model”: show either the mouse or the time, depending on a toggle. *)
let show_mouse_v : bool Lwd.var = Lwd.var true

let display : string Lwd.t =
  Lwd.join
    (Lwd.map (Lwd.get show_mouse_v) ~f:(function
       | true ->
         Lwd.map2 mouse_x mouse_y ~f:(fun x y -> Printf.sprintf "mouse=(%d,%d)" x y)
       | false ->
         Lwd.map time_b ~f:(fun t -> Printf.sprintf "t=%.3f" t)))

let root : string Lwd.root = Lwd.observe display
let sample () = Lwd.quick_sample root
```

An update step is then an ordinary loop:

```ocaml skip
let step ~t ~mouse ~clicked =
  Lwd.set time_v t;
  Lwd.set mouse_v mouse;
  if clicked then Lwd.set click_v (Some ());
  let s = sample () in
  (* Clear pulses after sampling (one-step event semantics). *)
  Lwd.set click_v None;
  s
```

This style is *deliberately simple*: the incremental engine is responsible for “what depends on what” and for caching; the host program is responsible for choosing the update-step boundaries and for turning external effects into input-cell updates.

#### Where `Lwd` Fits (and Where `Incremental` Fits)

The same high-level pattern works with `Incremental` too (vars + derived graph + stabilize + read observers). The big practical difference is that:

- `Lwd` is naturally **pull-based**: you update inputs and then `sample` the root(s) you care about.
- `Incremental` is naturally **push/stabilize-based**: you update inputs, call `stabilize`, and then all observers have up-to-date values.

Both can host FRP-like code; the question is which runtime model matches the rest of your application.

### 10.7 Direct Control (Effects)

FRP shines when the program is mostly “wiring”: combine signals, transform values, render a view. But many interactions are naturally **staged**:

- wait for a click,
- then track mouse movement until release,
- then wait for the next click,
- and so on.

You *can* encode staged workflows in pure FRP, but it often becomes awkward: you start building explicit state machines “in the large”. In Chapter 9 we learned that algebraic effects let us express such workflows in **direct style**, while still keeping the effectful interface abstract and interpretable by different handlers.

Here is a tiny effect-based interface for staged reactive programs:

```ocaml skip
type _ Effect.t +=
  | Await : (user_action -> 'a option) -> 'a Effect.t
  | Emit : 'o -> unit Effect.t

let await p = Effect.perform (Await p)
let emit x = Effect.perform (Emit x)
```

`Await p` means: “pause until you receive a `user_action` for which `p` returns `Some v`, then resume and return `v`.” This neatly expresses “ignore everything else until the thing I’m waiting for happens”.

#### A Handler: Replay a Script of Inputs

To make the idea testable (and independent of GUIs), we can interpret `Await` by consuming a pre-recorded list of `user_action`s:

```ocaml skip
let run_script ~(inputs : user_action list) ~(on_emit : 'o -> unit) (f : unit -> 'a) : 'a =
  let inputs = ref inputs in
  let rec handle : type a. (unit -> a) -> a =
    fun th ->
      try th () with
      | effect (Emit x), k ->
        on_emit x;
        handle (fun () -> Effect.Deep.continue k ())
      | effect (Await p), k ->
        let rec next () =
          match !inputs with
          | [] -> failwith "run_script: no more inputs"
          | u :: us ->
            inputs := us;
            match p u with
            | None -> next ()
            | Some v -> handle (fun () -> Effect.Deep.continue k v)
        in
        next ()
  in
  handle f
```

#### Example: “Click-and-Drag” in Direct Style

We can now write staged logic as straightforward recursion:

```ocaml skip
let is_down = function
  | Button (x, y, true, _) -> Some (x, y)
  | _ -> None

let is_move = function
  | MouseMove (x, y) -> Some (x, y)
  | _ -> None

let is_up = function
  | Button (_, _, false, _) -> Some ()
  | _ -> None

let rec drag_loop acc =
  match await (fun u -> match is_move u with Some p -> Some (`Move p) | None ->
                        match is_up u with Some () -> Some `Up | None -> None) with
  | `Move p ->
    let acc = p :: acc in
    emit (List.rev acc);  (* “render” the polyline *)
    drag_loop acc
  | `Up ->
    List.rev acc

let paint_once () =
  let start = await is_down in
  emit [start];
  let path = drag_loop [start] in
  emit ("done, points=" ^ string_of_int (List.length path))
```

This is the same idea as the old “flow” construction, but in OCaml 5 direct style. Crucially, the *program* `paint_once` does not commit to any particular GUI framework: it only commits to “there exists some source of `user_action`s and some place to send outputs”.

### 10.8 Notes on Practice

If you build UIs in OCaml today, you will often find incremental engines *under the hood*:

- `Lwd` is commonly used to build reactive document/view trees, with explicit resource lifetimes (`prim` acquire/release).
- Jane Street’s `Bonsai` builds on `Incremental` and adds a disciplined component model on top.

Even if you do not adopt a full FRP library, the ideas in this chapter are broadly useful: represent dependencies explicitly, choose a clear update-step boundary, and keep effectful interaction at the edge of your program.

### 10.9 Exercises

**Exercise 1.** Extend the context rewriting “pull out subexpression” example to include `-` and `/`. Remember: they are not commutative.

**Exercise 2.** Extend the stream-based paddle game:
1. add score keeping,
2. add restart,
3. add quitting (cleanly or not-so-cleanly).

**Exercise 3.** The numerical integration function in Section 10.5 uses the rectangle rule. Implement:
1. trapezoidal rule,
2. Simpson’s rule,
and design a simple accuracy test. (Hint: integrate a function with a known closed form.)

**Exercise 4.** In the stream FRP implementation, implement `switch : 'a behavior -> 'a behavior event -> 'a behavior` and use it to switch between two animations.

**Exercise 5.** Build a tiny “spreadsheet” with either `Lwd` or `Incremental`: cells are variables; other cells are formulas over them. Measure how much recomputation happens when you update a single input cell.

**Exercise 6.** Using `Lwd.join` (or `Incremental.bind`), build a reactive computation with *dynamic dependencies* (e.g. a toggle that chooses which subgraph is active). Explain what should be recomputed when the toggle flips.

**Exercise 7.** Extend the effect-based interface in Section 10.7 with a combinator `await_either : (user_action -> 'a option) -> (user_action -> 'b option) -> [\`A of 'a | \`B of 'b]` that returns whichever happens first. Implement it in direct style using just `await`.
