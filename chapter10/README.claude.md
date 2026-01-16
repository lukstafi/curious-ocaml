## Chapter 10: Functional Reactive Programming

How do we deal with change and interaction in functional programming? This is one of the most challenging questions in the field, and over the years programmers have developed increasingly sophisticated answers. This chapter explores a progression of techniques: we begin with *zippers*, a clever data structure for navigating and modifying positions within larger structures. We then advance to *adaptive programming* (also known as incremental computing), which automatically propagates changes through computations. Finally, we arrive at *Functional Reactive Programming* (FRP), a declarative approach to handling time-varying values and event streams. We conclude with practical examples including graphical user interfaces.

**Recommended Reading:**

- *"The Zipper"* by Gerard Huet -- the original paper introducing zippers
- *"Zipper"* in Haskell Wikibook -- excellent visualizations and examples
- *Lwd documentation* at https://github.com/let-def/lwd -- lightweight reactive documents for OCaml
- *Incremental documentation* at https://github.com/janestreet/incremental -- Jane Street's self-adjusting computation library
- *"The Haskell School of Expression"* by Paul Hudak -- classic introduction to FRP
- *"Deprecating the Observer Pattern with `Scala.React`"* by Ingo Maier, Martin Odersky
- *"Algebraic Effects for the Rest of Us"* by Dan Abramov -- accessible introduction to effects

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

### 10.3 Incremental Computing

While zippers are elegant for navigating and modifying data structures, they are somewhat unnatural for general-purpose programming. The fundamental problem is this: once we change something using a zipper, how do we propagate those changes through all the computations that depend on the modified data? We would need to rewrite all our algorithms to explicitly work with context changes, which defeats the purpose of clean functional programming.

*Incremental computing*, also known as *adaptive programming* or *self-adjusting computation*, offers a more elegant solution. The idea is beautifully simple: we write programs in a straightforward functional manner, but the runtime system tracks dependencies between computations. When we later modify any input data, only the minimal amount of work required to update the results is performed -- everything else is reused from before.

#### The Core Idea

Consider a simple computation:

```
let u = v / w + x * y + z
```

This creates a dependency graph where `u` depends on intermediate results (let us call them `n0 = v/w`, `n1 = x*y`, `n2 = n0+n1`), which in turn depend on the input variables. When we modify inputs -- say, both `v` and `z` simultaneously -- the runtime needs to update intermediate nodes in the correct order. Since `n2` depends on `n0`, we must update `n0` before `n2`, and both must be updated before `u`.

The key insight is that we can track dependencies automatically using a monad-like structure. The monadic type wraps values and records how they were computed:

```
let n0 = bind2 v w (fun v w -> return (v / w))
let n1 = bind2 x y (fun x y -> return (x * y))
let n2 = bind2 n0 n1 (fun n0 n1 -> return (n0 + n1))
let u = bind2 n2 z (fun n2 z -> return (n2 + z))
```

The beauty of lifting is that we can make our code look almost identical to ordinary arithmetic:

```
let (/) = lift2 (/)
let ( * ) = lift2 ( * )
let (+) = lift2 (+)
let u = v / w + x * y + z  (* Looks like normal code, but tracks dependencies! *)
```

Two OCaml libraries implement these ideas with different design philosophies: **Lwd** (Lightweight Documents) for UI rendering, and **Incremental** (from Jane Street) for large-scale financial systems.

#### Lwd: Minimalist Incremental Computing

Lwd takes a minimalist approach, focused on UI rendering with a document/tree metaphor. Its core type `'a Lwd.t` represents a computation that produces a value of type `'a` and can be efficiently updated when dependencies change.

**Key design choices in Lwd:**

1. **Compact node representation**: Nodes are either `Pure` (constant values), `Operator` (computed from other nodes), or `Root` (observer entry points). The internal representation encodes specific operations like `Map`, `Map2`, `Pair`, `Join`, and `Var`.

2. **Specialized trace structures**: Lwd uses a clever optimization for tracking which nodes depend on a given node. Instead of always using a list or array, it has specialized variants `T0`, `T1`, `T2`, `T3`, `T4` for nodes with 0-4 dependents, only allocating an array (`Tn`) when there are 5 or more. This saves memory for tree-shaped graphs where most nodes have few dependents.

3. **Push-based invalidation, pull-based recomputation**: When a `Var` changes, invalidation propagates *upward* immediately through all dependent nodes, marking them as needing recomputation. However, actual recomputation is *lazy* -- values are only computed when explicitly requested by sampling at a root.

4. **Acquire/release protocol**: Lwd tracks which parts of the graph are "live" (reachable from an observer). Special `Prim` nodes can have `acquire` and `release` callbacks, enabling resource management -- for example, creating and destroying DOM nodes as parts of the UI become visible or hidden.

5. **Join for dynamic graphs**: The `Join` combinator enables graphs whose *structure* changes at runtime. A `Join` node wraps an `'a Lwd.t Lwd.t` -- the outer computation produces an inner computation, and when the outer value changes, the whole inner graph can be replaced.

Here is how Lwd code looks in practice:

```ocaml skip
open Lwd

(* Create mutable variables *)
let x = Lwd.var 10
let y = Lwd.var 20

(* Build a computation that depends on them *)
let sum = Lwd.map2 ~f:(+) (Lwd.get x) (Lwd.get y)

(* Sample the current value *)
let () = assert (Lwd.sample sum = 30)

(* Change an input *)
let () = Lwd.set x 15

(* Sample again -- only the necessary recomputation happens *)
let () = assert (Lwd.sample sum = 35)
```

The key operations are:
- `Lwd.var : 'a -> 'a Lwd.var` -- create a mutable input
- `Lwd.get : 'a Lwd.var -> 'a Lwd.t` -- read a variable as a computation
- `Lwd.set : 'a Lwd.var -> 'a -> unit` -- update a variable
- `Lwd.map : f:('a -> 'b) -> 'a Lwd.t -> 'b Lwd.t` -- transform a computation
- `Lwd.map2 : f:('a -> 'b -> 'c) -> 'a Lwd.t -> 'b Lwd.t -> 'c Lwd.t` -- combine two computations
- `Lwd.bind : 'a Lwd.t -> ('a -> 'b Lwd.t) -> 'b Lwd.t` -- dynamic graph construction
- `Lwd.sample : 'a Lwd.t -> 'a` -- extract the current value, triggering recomputation

#### Incremental: Industrial-Strength Self-Adjusting Computation

Jane Street's Incremental library is engineered for correctness and performance at scale, originally designed for financial systems with complex dependency graphs.

**Key design choices in Incremental:**

1. **Rich node representation**: Each node is a large record with approximately 30 mutable fields, covering stabilization timestamps, value caching, heap positions for scheduling, parent/child index arrays for O(1) edge manipulation, observer management, and debugging information.

2. **Height-based topological ordering**: Nodes have explicit `height` values ensuring children are always recomputed before parents. A "recompute heap" (priority queue ordered by height) processes nodes in the correct order during stabilization.

3. **Stabilization numbers instead of dirty flags**: Rather than boolean "dirty" flags, Incremental uses monotonic counters (`recomputed_at`, `changed_at`). A node is stale if any child's `changed_at` exceeds the parent's `recomputed_at`. This enables efficient staleness checks without traversing the graph.

4. **First-class cutoff support**: Incremental has built-in support for short-circuiting propagation when values are "equal enough." For example, floating-point computations might use a tolerance-based cutoff, preventing tiny numerical differences from triggering cascading updates.

5. **Specialized node variants**: Like Lwd, Incremental has specialized variants for different arities: `Map`, `Map2`, up to `Map15`. It also has nodes for `Bind`, `If`, `Join`, time-based computations (`At`, `At_intervals`, `Snapshot`), array folds, step functions, and an `Expert` mode for advanced use cases.

6. **Bidirectional parent/child links**: Maintains arrays mapping child indices to parent indices and vice versa, enabling O(1) edge insertion and removal via swapping.

7. **Scopes**: Supports hierarchical scoping for invalidation boundaries and lifetime management.

Here is how Incremental code looks:

```ocaml skip
open Incremental

(* Create an Incremental computation context *)
let incr = Incremental.create ()

(* Create mutable variables *)
let x = Var.create incr 10
let y = Var.create incr 20

(* Build a computation *)
let sum = map2 (Var.watch x) (Var.watch y) ~f:(+)

(* Create an observer to track the result *)
let obs = observe sum

(* Stabilize the computation graph *)
let () = stabilize incr

(* Read the current value *)
let () = assert (Observer.value_exn obs = 30)

(* Change an input and restabilize *)
let () = Var.set x 15
let () = stabilize incr
let () = assert (Observer.value_exn obs = 35)
```

#### Comparing Lwd and Incremental

| Aspect | Lwd | Incremental |
|--------|-----|-------------|
| **Memory per node** | ~5-7 words | ~30+ words |
| **Staleness check** | Boolean flags | Timestamp comparison |
| **Invalidation** | Eager push to roots | Lazy via timestamps |
| **Recomputation** | Pull on `sample` | Push during `stabilize` |
| **Cutoff support** | None built-in | First-class concept |
| **Dynamic graphs** | `Join` combinator | `Bind` with scope tracking |
| **Time handling** | None | Alarms, step functions |
| **Target use case** | UI trees | Financial systems, large DAGs |

**When to use Lwd**: Choose Lwd for reactive UIs, especially when the graph is mostly tree-shaped and memory efficiency matters. The acquire/release protocol maps naturally to DOM element lifecycles. Lwd is often used with the Nottui library for terminal UIs.

**When to use Incremental**: Choose Incremental for complex computations with deep dependency graphs, when you need cutoff semantics, or when you require time-based features. Incremental's timestamp-based approach avoids redundant work in deep graphs, and height ordering prevents glitches (observing inconsistent intermediate states).

#### Handling Conditional Dependencies

A subtle issue arises with conditionals. Consider:

```ocaml skip
let b = map x ~f:(fun x -> x = 0)
let n0 = map x ~f:(fun x -> 100 / x)
let y = bind b (fun b -> if b then return 0 else n0)
```

If we naively update all nodes when `x` changes to 0, we might compute `n0 = 100 / 0` and crash -- even though the conditional would never use that result.

Both libraries handle this by tracking which nodes are actually *active* (reachable from an observer through the current structure). In Lwd, `Join` dynamically switches which inner computation is active. In Incremental, `Bind` creates a scope that tracks its current child, and switching to a different child deactivates the old one.

The key insight is that **dynamic structure requires dynamic dependency tracking**. When a conditional changes branches, the dependencies from the old branch must be deactivated and dependencies from the new branch activated.

#### Practical Considerations

Incremental computation has overhead. The tracking machinery costs memory and CPU time. For small computations or those that change completely each time, simply recomputing from scratch may be faster than maintaining the dependency graph.

The sweet spot for incremental computing is:
- **Large computations** where recomputing everything is expensive
- **Small, localized changes** where most of the computation can be reused
- **Interactive applications** where responsiveness to changes matters

For example, a spreadsheet is an ideal use case: cells form a dependency graph, and editing one cell typically only affects a small fraction of the sheet. Similarly, a UI toolkit benefits when only the changed parts of the interface need redrawing.

### 10.4 Functional Reactive Programming

We have seen how incremental computing propagates changes through dependency graphs. But what about programs that must respond to *time* itself -- animations, games, interactive applications? This is the domain of *Functional Reactive Programming* (FRP).

FRP is an attempt to declaratively deal with time. The key insight is to distinguish two kinds of time-varying values:

- **Behaviors** are continuous functions of time. A behavior has a specific value at every instant. Think of a mouse position, window size, or the current frame of an animation.

- **Events** are discrete occurrences. An event is a set of (time, value) pairs, organized into streams of actions. Think of mouse clicks, key presses, or timer ticks.

Together, behaviors and events are called **signals**.

#### Fundamental Problems in FRP

Two fundamental problems arise in any FRP system:

1. **Causality**: Behaviors and events must be well-defined, which means they cannot depend on future values. A behavior at time $t$ can only depend on events that have already occurred. This seems obvious, but it constrains what programs we can write and how we must structure computations.

2. **Efficiency**: We need to minimize the overhead of tracking time and dependencies, especially for real-time applications like games. A naive implementation that resamples everything at every frame would be too slow.

FRP systems are typically **synchronous**: multiple events can occur at exactly the same logical time, and the system handles this correctly by processing them in a consistent order. FRP is also conceptually **continuous**: behaviors can have details at arbitrary time resolution. Although actual results are *sampled* at discrete moments, there is no fixed minimal time step for specifying behavior.

(Note: "Asynchrony" in reactive programming refers to various different ideas depending on context, so always ask what people mean when they use the term.)

#### Idealized Definitions

Let us start with the idealized, mathematical definitions and then see how practical considerations force us to refine them.

In the purest form, we would define:

```ocaml skip
type time = float
type 'a behavior = time -> 'a      (* Arbitrary function of time *)
type 'a event = (time * 'a) stream  (* Stream of timestamped values *)
```

This is mathematically elegant: a behavior is literally a function from time to values, and events are a lazy stream of timestamped occurrences. However, this idealized view has problems.

Behaviors need to react to external events -- the position of a paddle should follow the mouse, not just be a predetermined function of time:

```ocaml skip
type 'a behavior = user_action event -> time -> 'a
```

Now a behavior takes both the event history and the current time. But this leads to an efficiency problem: every time we evaluate a behavior, we would need to scan through all events from the beginning of time up to the current moment.

The solution is to turn behaviors into **stream transformers**. Instead of a function that answers "what is the value at time $t$?", we produce a stream of values, one for each sampling time:

```ocaml skip
type 'a behavior = user_action event -> time stream -> 'a stream
```

The next optimization is to combine user actions and sampling times into a single stream. At each sampling moment, we either have a user action or nothing happened:

```ocaml skip
type 'a behavior = (user_action option * time) stream -> 'a stream
```

The `None` action corresponds to a sampling moment when nothing happened -- we still need to produce a value for the behavior at that time.

This transformation from functions-of-time to stream transformers is analogous to a classic algorithm optimization. Computing the intersection of two sorted lists naively checks every pair, giving $O(mn)$ time. The smart approach walks through both lists simultaneously, giving $O(m + n)$ time. Similarly, our stream-based behaviors process time and events together in a single pass.

With behaviors as stream transformers, we can elegantly define events in terms of behaviors:

```ocaml skip
type 'a event = 'a option behavior
```

An event is simply a behavior that produces `None` at most sampling times and `Some value` when the event actually occurs.

#### Behaviors as Applicative Functors

Behaviors form an applicative functor (and in fact a monad). Looking at the simple definition `type 'a behavior = time -> 'a`, we can define:

```ocaml skip
(* Pure: constant behavior, same value at all times *)
let pure a = fun _ -> a

(* Map: transform a behavior pointwise *)
let map f b = fun t -> f (b t)

(* Ap: apply a time-varying function to a time-varying argument *)
let ap bf ba = fun t -> (bf t) (ba t)
```

From `ap` we can derive lifting functions for combining behaviors:

```ocaml skip
let lift2 f ba bb = ap (map f ba) bb
let lift3 f ba bb bc = ap (lift2 f ba bb) bc
```

In practice, we mostly use lifting rather than full monadic bind. This is intentional: restricting to applicative operations makes the dependency structure static, which enables more efficient implementations.

#### Converting Between Events and Behaviors

One of the most important operations in FRP is converting between events and behaviors. The key combinators are:

- `step : 'a -> 'a event -> 'a behavior` -- Creates a "step function" behavior that holds the most recent event value, starting with an initial value.

- `switch : 'a behavior -> 'a behavior event -> 'a behavior` -- Behaves as the current behavior until an event arrives carrying a new behavior, then switches to that new behavior.

- `until : 'a behavior -> 'a behavior event -> 'a behavior` -- Like `switch`, but only switches once (the first event permanently determines the new behavior).

- `snapshot : 'a event -> 'b behavior -> ('a * 'b) event` -- When an event occurs, capture both the event value and the current value of a behavior.

These combinators bridge the discrete world of events and the continuous world of behaviors.

### 10.5 FRP by Stream Processing

Now let us implement FRP using the stream processing techniques from Chapter 7. We will build a complete system that can handle behaviors, events, and their combinations.

#### Stream Infrastructure

First, the lazy stream infrastructure:

```ocaml skip
type 'a stream = 'a stream_ Lazy.t
and 'a stream_ = Cons of 'a * 'a stream

let rec lmap f l = lazy (
  let Cons (x, xs) = Lazy.force l in
  Cons (f x, lmap f xs))

let rec lmap2 f xs ys = lazy (
  let Cons (x, xs) = Lazy.force xs in
  let Cons (y, ys) = Lazy.force ys in
  Cons (f x y, lmap2 f xs ys))

let rec lmap3 f xs ys zs = lazy (
  let Cons (x, xs) = Lazy.force xs in
  let Cons (y, ys) = Lazy.force ys in
  let Cons (z, zs) = Lazy.force zs in
  Cons (f x y z, lmap3 f xs ys zs))

let rec lfold acc f l = lazy (
  let Cons (x, xs) = Lazy.force l in
  let acc = f acc x in
  Cons (acc, lfold acc f xs))
```

#### Memoized Behaviors

Since a behavior is a function from the input stream to an output stream, we face a subtle sharing problem: if we apply the same behavior function twice to the "same" input, we might create two separate streams that diverge. We need memoization to ensure that for any actual input stream, each behavior creates exactly one output stream:

```ocaml skip
type ('a, 'b) memo1 =
  {memo_f : 'a -> 'b; mutable memo_r : ('a * 'b) option}

let memo1 f = {memo_f = f; memo_r = None}

let memo1_app m x =
  match m.memo_r with
  | Some (y, res) when x == y -> res  (* Physical equality check *)
  | _ ->
    let res = m.memo_f x in
    m.memo_r <- Some (x, res);
    res

let ($) = memo1_app  (* Convenient infix for memoized application *)
```

We use physical equality (`==`) rather than structural equality (`=`) because the external input stream is a single physical object.

Now we can define our types:

```ocaml skip
type user_action =
  | Key of char * bool           (* character, is_pressed *)
  | Button of int * int * bool   (* x, y, is_pressed *)
  | MouseMove of int * int       (* x, y *)
  | Resize of int * int          (* width, height *)

type 'a behavior =
  ((user_action option * float) stream, 'a stream) memo1

type 'a event = 'a option behavior
```

#### Building Behaviors

Here are the fundamental operations for behaviors:

```ocaml skip
(* Constant behavior: same value at all times *)
let returnB x : 'a behavior =
  let rec xs = lazy (Cons (x, xs)) in
  memo1 (fun _ -> xs)

let ( !* ) = returnB

(* Lift a unary function to work on behaviors *)
let liftB f fb : 'b behavior =
  memo1 (fun uts -> lmap f (fb $ uts))

(* Lift binary and ternary functions *)
let liftB2 f fb1 fb2 : 'c behavior =
  memo1 (fun uts -> lmap2 f (fb1 $ uts) (fb2 $ uts))

let liftB3 f fb1 fb2 fb3 : 'd behavior =
  memo1 (fun uts -> lmap3 f (fb1 $ uts) (fb2 $ uts) (fb3 $ uts))
```

For events, we can lift functions that preserve the `option` structure:

```ocaml skip
(* Lift a function to work on events *)
let liftE f (fe : 'a event) : 'b event =
  memo1 (fun uts -> lmap
    (function Some e -> Some (f e) | None -> None)
    (fe $ uts))

let (=>>) fe f = liftE f fe  (* Map over events *)
let (->>) e v = e =>> fun _ -> v  (* Replace event value with constant *)
```

#### Converting Between Events and Behaviors

Creating events from behaviors:

```ocaml skip
(* whileB: produces unit event at every moment the behavior is true *)
let whileB (fb : bool behavior) : unit event =
  memo1 (fun uts ->
    lmap (function true -> Some () | false -> None) (fb $ uts))

(* unique: filters out duplicate consecutive events *)
let unique (fe : 'a event) : 'a event =
  memo1 (fun uts ->
    let xs = fe $ uts in
    lmap2 (fun x y -> if x = y then None else y)
      (lazy (Cons (None, xs))) xs)

(* whenB: fires when behavior becomes true (rising edge) *)
let whenB fb : unit event =
  memo1 (fun uts -> unique (whileB fb) $ uts)

(* snapshot: capture behavior value when event fires *)
let snapshot (fe : 'a event) (fb : 'b behavior) : ('a * 'b) event =
  memo1 (fun uts -> lmap2
    (fun b -> function Some a -> Some (a, b) | None -> None)
    (fb $ uts) (fe $ uts))
```

Creating behaviors from events:

```ocaml skip
(* step: hold the most recent event value *)
let step acc (fe : 'a event) : 'a behavior =
  memo1 (fun uts -> lfold acc
    (fun acc -> function None -> acc | Some v -> v)
    (fe $ uts))

(* step_accum: accumulate by applying functions from events *)
let step_accum acc (ff : ('a -> 'a) event) : 'a behavior =
  memo1 (fun uts ->
    lfold acc (fun acc -> function
      | None -> acc
      | Some f -> f acc)
      (ff $ uts))
```

#### Integration for Physics

For physics simulations, we need to integrate behaviors over time:

```ocaml skip
let integral (fb : float behavior) : float behavior =
  let rec loop t0 acc uts bs =
    let Cons ((_, t1), uts) = Lazy.force uts in
    let Cons (b, bs) = Lazy.force bs in
    let acc = acc +. (t1 -. t0) *. b in
    Cons (acc, lazy (loop t1 acc uts bs)) in
  memo1 (fun uts -> lazy (
    let Cons ((_, t), uts') = Lazy.force uts in
    Cons (0., lazy (loop t 0. uts' (fb $ uts)))))
```

Note the critical property: the integral at time $t$ depends on velocities at times *before* $t$. This one-step delay breaks what would otherwise be a circular dependency when we define position in terms of velocity and velocity in terms of position (for bouncing).

#### User Input Behaviors

We define behaviors that extract information from the input stream:

```ocaml skip
(* Left button press event *)
let lbp : unit event =
  memo1 (fun uts -> lmap
    (function Some (Button (_, _, true)), _ -> Some () | _ -> None)
    uts)

(* Mouse movement event *)
let mm : (int * int) event =
  memo1 (fun uts -> lmap
    (function Some (MouseMove (x, y)), _ -> Some (x, y) | _ -> None)
    uts)

(* Window resize event *)
let resize : (int * int) event =
  memo1 (fun uts -> lmap
    (function Some (Resize (x, y)), _ -> Some (x, y) | _ -> None)
    uts)

(* Derived behaviors *)
let mouse_x : int behavior = step 0 (liftE fst mm)
let mouse_y : int behavior = step 0 (liftE snd mm)
let width : int behavior = step 640 (liftE fst resize)
let height : int behavior = step 480 (liftE snd resize)
```

#### The Paddle Game Example

Let us put all these pieces together to build a classic paddle game. First, we define a scene graph for rendering:

```ocaml skip
type scene =
  | Rect of int * int * int * int    (* x, y, width, height *)
  | Circle of int * int * int        (* x, y, radius *)
  | Group of scene list
  | Color of Graphics.color * scene
  | Translate of float * float * scene
```

The drawing function interprets the scene graph:

```ocaml skip
let draw sc =
  let f2i = int_of_float in
  let open Graphics in
  let rec aux t_x t_y = function
    | Rect (x, y, w, h) ->
        fill_rect (f2i t_x + x) (f2i t_y + y) w h
    | Circle (x, y, r) ->
        fill_circle (f2i t_x + x) (f2i t_y + y) r
    | Group scs ->
        List.iter (aux t_x t_y) scs
    | Color (c, sc) ->
        set_color c; aux t_x t_y sc
    | Translate (x, y, sc) ->
        aux (t_x +. x) (t_y +. y) sc in
  clear_graph ();
  aux 0. 0. sc;
  synchronize ()
```

Now we define the game elements. Lifted arithmetic operators make the code readable:

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

The walls form a U-shape around the play area:

```ocaml skip
let walls : scene behavior =
  liftB2 (fun w h -> Color (Graphics.blue, Group
    [Rect (0, 0, 20, h-1);       (* left wall *)
     Rect (0, h-21, w-1, 20);    (* top wall *)
     Rect (w-21, 0, 20, h-1)]))  (* right wall *)
    width height
```

The paddle follows the mouse at the bottom of the screen:

```ocaml skip
let paddle : scene behavior =
  liftB (fun mx -> Color (Graphics.black, Rect (mx, 0, 50, 10)))
    mouse_x
```

The ball bounces off walls. We express position and velocity as mutually recursive behaviors. The integration introduces the delay needed to break the cycle:

```ocaml skip
let ball : scene behavior =
  let wall_margin = 27 in  (* ball radius + wall thickness *)
  let vel = 100.0 in       (* initial velocity in pixels/sec *)

  (* Horizontal motion with bouncing *)
  let rec xvel_pos () =
    let xvel = step_accum vel (xbounce () ->> (~-.)) in
    let xpos = liftB int_of_float (integral xvel) +* width /* !*2 in
    xvel, xpos
  and xbounce () =
    let _, xpos = xvel_pos () in
    whenB ((xpos >* width -* !*wall_margin) ||* (xpos <* !*wall_margin))
  in

  (* Vertical motion with bouncing *)
  let rec yvel_pos () =
    let yvel = step_accum vel (ybounce () ->> (~-.)) in
    let ypos = liftB int_of_float (integral yvel) +* height /* !*2 in
    yvel, ypos
  and ybounce () =
    let _, ypos = yvel_pos () in
    whenB ((ypos >* height -* !*wall_margin) ||* (ypos <* !*wall_margin))
  in

  let _, xpos = xvel_pos () in
  let _, ypos = yvel_pos () in
  liftB2 (fun x y -> Color (Graphics.red, Circle (x, y, 7))) xpos ypos
```

Finally, we compose everything into the complete game scene:

```ocaml skip
let game : scene behavior =
  liftB3 (fun w p b -> Group [w; p; b]) walls paddle ball
```

The animation loop drives the system:

```ocaml skip
let reactimate (scene : scene behavior) =
  let open Graphics in
  open_graph " 640x480";
  auto_synchronize false;
  let rec loop uts =
    let Cons (sc, uts') = Lazy.force (scene $ uts) in
    draw sc;
    let t = Unix.gettimeofday () in
    let action =
      if key_pressed () then Some (Key (read_key (), true))
      else if button_down () then
        let st = wait_next_event [Poll] in
        Some (Button (st.mouse_x, st.mouse_y, true))
      else
        let st = wait_next_event [Poll] in
        Some (MouseMove (st.mouse_x, st.mouse_y))
    in
    loop (lazy (Cons ((action, t), uts')))
  in
  let t0 = Unix.gettimeofday () in
  loop (lazy (Cons ((None, t0), lazy (Cons ((None, t0), lazy assert false)))))
```

The stream-based implementation is elegant but has a limitation: OCaml being strict, we cannot easily define mutually recursive behaviors. We had to use functions (`xvel_pos`, `ybounce`) to tie the knot. In a lazy language like Haskell, this would be more natural.

### 10.6 FRP with Lwd

The stream-based implementation from the previous section works well but requires careful management of the input stream. An alternative approach is to build FRP on top of an incremental computing library like Lwd. This gives us automatic dependency tracking without explicitly threading streams.

#### Mapping FRP Concepts to Lwd

In Lwd:
- **Behaviors** are `'a Lwd.t` values -- computations that can change over time
- **Mutable inputs** (like user actions) are `'a Lwd.var` values
- **Events** can be represented as `'a option Lwd.var` that is set to `Some v` when an event occurs and reset to `None` afterwards

The key advantage is that Lwd handles dependency tracking automatically. When we change a variable, all dependent computations are invalidated and will be recomputed on the next sample.

#### Basic Setup

```ocaml skip
module LwdFrp = struct
  (* Time tracking *)
  let time_var = Lwd.var 0.0
  let time = Lwd.get time_var

  (* Update time from the environment *)
  let tick () = Lwd.set time_var (Unix.gettimeofday ())

  (* Event variables: set to Some when event fires, then reset to None *)
  type 'a event_var = {
    var: 'a option Lwd.var;
    mutable last_fire: float;  (* timestamp of last fire *)
  }

  let make_event () =
    { var = Lwd.var None; last_fire = neg_infinity }

  let fire ev value =
    ev.last_fire <- Lwd.peek time_var;
    Lwd.set ev.var (Some value)

  let clear ev =
    Lwd.set ev.var None

  let event ev = Lwd.get ev.var

  (* Behaviors are just Lwd.t values *)
  type 'a behavior = 'a Lwd.t

  let return = Lwd.return
  let map = Lwd.map
  let map2 = Lwd.map2
  let bind = Lwd.bind
end
```

#### User Input Handling

```ocaml skip
(* Mouse position *)
let mouse_x_var = Lwd.var 0
let mouse_y_var = Lwd.var 0
let mouse_x = Lwd.get mouse_x_var
let mouse_y = Lwd.get mouse_y_var

(* Mouse button event *)
let mouse_button = LwdFrp.make_event ()
let mouse_button_pressed = LwdFrp.event mouse_button

(* Window size *)
let width_var = Lwd.var 640
let height_var = Lwd.var 480
let width = Lwd.get width_var
let height = Lwd.get height_var

(* Update from GUI events *)
let on_mouse_move x y =
  Lwd.set mouse_x_var x;
  Lwd.set mouse_y_var y

let on_mouse_button pressed =
  if pressed then LwdFrp.fire mouse_button ()
  else LwdFrp.clear mouse_button

let on_resize w h =
  Lwd.set width_var w;
  Lwd.set height_var h
```

#### Step Function and Event Accumulation

The `step` function creates a behavior that holds the most recent event value:

```ocaml skip
let step init (ev : 'a option Lwd.t) : 'a Lwd.t =
  (* We need mutable state to remember the last value *)
  let last = ref init in
  Lwd.map (function
    | None -> !last
    | Some v -> last := v; v) ev

let step_accum init (ef : ('a -> 'a) option Lwd.t) : 'a Lwd.t =
  let acc = ref init in
  Lwd.map (function
    | None -> !acc
    | Some f -> acc := f !acc; !acc) ef
```

Note the use of mutable references inside the Lwd computation. This is safe because the computation is sampled sequentially. The reference stores state that persists across samples.

#### Integration

For physics, we need integration. Unlike the stream version, we must explicitly track the previous time:

```ocaml skip
let integral (fb : float Lwd.t) : float Lwd.t =
  let acc = ref 0.0 in
  let prev_t = ref (Unix.gettimeofday ()) in
  Lwd.map2 (fun v t ->
    let dt = t -. !prev_t in
    prev_t := t;
    acc := !acc +. dt *. v;
    !acc) fb LwdFrp.time
```

The integration depends on both the value being integrated and the current time, so it will be recomputed whenever either changes.

#### Bounce Detection

For the bouncing ball, we need to detect when a value crosses a boundary. This is trickier in Lwd because we do not have direct access to "the previous value":

```ocaml skip
(* Detect rising edge: was false, now true *)
let rising_edge (fb : bool Lwd.t) : unit option Lwd.t =
  let was_true = ref false in
  Lwd.map (fun b ->
    let result =
      if b && not !was_true then Some ()
      else None in
    was_true := b;
    result) fb

let whenB fb = rising_edge fb
```

#### The Paddle Game with Lwd

Now let us rebuild the paddle game using Lwd:

```ocaml skip
type scene =
  | Rect of int * int * int * int
  | Circle of int * int * int
  | Group of scene list
  | Color of int * scene  (* color as int for simplicity *)

let draw sc =
  let open Graphics in
  let rec aux = function
    | Rect (x, y, w, h) -> fill_rect x y w h
    | Circle (x, y, r) -> fill_circle x y r
    | Group scs -> List.iter aux scs
    | Color (c, sc) -> set_color c; aux sc in
  clear_graph ();
  aux sc;
  synchronize ()

(* Walls *)
let walls : scene Lwd.t =
  Lwd.map2 (fun w h ->
    Color (0x0000FF, Group [
      Rect (0, 0, 20, h-1);
      Rect (0, h-21, w-1, 20);
      Rect (w-21, 0, 20, h-1)
    ])) width height

(* Paddle follows mouse *)
let paddle : scene Lwd.t =
  Lwd.map (fun mx ->
    Color (0x000000, Rect (mx, 0, 50, 10))) mouse_x

(* Ball with bouncing physics *)
let ball : scene Lwd.t =
  let wall_margin = 27 in
  let init_vel = 100.0 in

  (* Mutable state for velocities *)
  let xvel = ref init_vel in
  let yvel = ref init_vel in

  (* Position as integral of velocity *)
  let xpos_raw = ref 0.0 in
  let ypos_raw = ref 0.0 in
  let prev_t = ref (Unix.gettimeofday ()) in

  Lwd.map2 (fun (w, h) t ->
    let dt = t -. !prev_t in
    prev_t := t;

    (* Update positions *)
    xpos_raw := !xpos_raw +. dt *. !xvel;
    ypos_raw := !ypos_raw +. dt *. !yvel;

    (* Bounce off walls *)
    let xpos = int_of_float !xpos_raw + w / 2 in
    let ypos = int_of_float !ypos_raw + h / 2 in

    if xpos > w - wall_margin || xpos < wall_margin then
      xvel := -. !xvel;
    if ypos > h - wall_margin || ypos < wall_margin then
      yvel := -. !yvel;

    Color (0xFF0000, Circle (xpos, ypos, 7)))
    (Lwd.pair width height) LwdFrp.time

(* Complete game scene *)
let game : scene Lwd.t =
  Lwd.map3 (fun w p b -> Group [w; p; b]) walls paddle ball

(* Animation loop *)
let run_game () =
  let open Graphics in
  open_graph " 640x480";
  auto_synchronize false;

  (* Create a root to observe the scene *)
  let root = Lwd.observe game in

  let rec loop () =
    (* Update time *)
    LwdFrp.tick ();

    (* Poll for events *)
    let st = wait_next_event [Poll] in
    on_mouse_move st.mouse_x st.mouse_y;

    (* Sample and draw the scene *)
    let sc = Lwd.quick_sample root in
    draw sc;

    (* Continue loop *)
    loop ()
  in
  loop ()
```

#### Comparing Stream-Based and Lwd-Based FRP

| Aspect | Stream-Based | Lwd-Based |
|--------|--------------|-----------|
| **Dependency tracking** | Explicit via stream threading | Automatic |
| **State management** | In stream transformers | Mutable refs in computations |
| **Mutual recursion** | Requires function wrapping | Natural with refs |
| **Memory model** | Streams can be garbage collected | Dependency graph persists |
| **Debugging** | Can inspect stream values | Can inspect Lwd variables |

The Lwd-based approach is more imperative in style but integrates naturally with OCaml's eager evaluation. The stream-based approach is more purely functional but requires more ceremony in strict languages.

Both approaches successfully separate the *specification* of reactive behavior from the *execution* machinery. The game logic describes relationships between inputs and outputs; the framework handles the when and how of updates.

### 10.7 Direct Control with Effects

The declarative style of FRP is elegant for continuous behaviors, but real-world interactions are often *state machines* that proceed through distinct stages. Consider a recipe: *1. Preheat the oven. 2. Put flour, sugar, eggs into a bowl. 3. Mix well. 4. Pour into pan.* Each step must complete before the next begins. How do we express this kind of sequential, staged behavior in FRP?

We want a *flow* that can proceed through events in sequence: when the first event arrives, we process it and then wait for the next event. Crucially, we *ignore* any further occurrences of the first event after we have moved on. Standard FRP constructs like mapping events do not give us this "move forward and never look back" semantics.

In Chapter 9, we saw how algebraic effects provide a powerful alternative to monads. We can use effects to implement flows that wait for events, emit values, and can be cancelled. This gives us direct-style code that reads naturally as a sequence of steps.

#### Defining Flow Effects

We need three effects:

```ocaml skip
type _ Effect.t +=
  | Await : 'a event_source -> 'a Effect.t  (* Wait for next event *)
  | Emit : 'a -> unit Effect.t              (* Output a value *)
  | Yield : unit Effect.t                   (* Give other flows a chance to run *)

type 'a event_source = {
  mutable listeners: ('a -> unit) list;
  mutable value: 'a option;
}

let make_event_source () = { listeners = []; value = None }

let fire source v =
  source.value <- Some v;
  List.iter (fun f -> f v) source.listeners;
  source.value <- None

let await src = Effect.perform (Await src)
let emit v = Effect.perform (Emit v)
let yield_flow () = Effect.perform Yield
```

The `Await` effect suspends the current flow until an event fires. The `Emit` effect outputs a value (analogous to yielding in a generator). The `Yield` effect temporarily gives up control to allow other flows to make progress.

#### The Flow Runner

The flow runner maintains a queue of suspended flows and processes events:

```ocaml skip
type 'a flow_state =
  | Running
  | Waiting of { mutable wakeup: ('a -> unit) option }
  | Completed of 'a
  | Cancelled

type 'a flow = {
  mutable state: 'a flow_state;
  mutable cancel_handlers: (unit -> unit) list;
}

let run_queue : (unit -> unit) Queue.t = Queue.create ()

let schedule f = Queue.push f run_queue

let run_pending () =
  while not (Queue.is_empty run_queue) do
    let f = Queue.pop run_queue in
    f ()
  done

let make_flow () = { state = Running; cancel_handlers = [] }

let cancel flow =
  match flow.state with
  | Cancelled -> ()
  | Completed _ -> ()
  | Running | Waiting _ ->
      flow.state <- Cancelled;
      List.iter (fun h -> h ()) flow.cancel_handlers

let is_cancelled flow =
  match flow.state with Cancelled -> true | _ -> false
```

#### Handling Flow Effects

The key is how we handle `Await`. When a flow awaits an event, we:
1. Register a listener on the event source
2. Suspend the flow by capturing its continuation
3. Resume the continuation when the event fires

```ocaml skip
let run_flow : type a b. (unit -> a) -> (a -> unit) -> b flow -> unit =
  fun f on_emit flow ->
    let rec go : type c. (unit -> c) -> (c -> unit) -> unit = fun thunk cont ->
      if is_cancelled flow then ()
      else
        match thunk () with
        | result -> cont result
        | effect (Await source), k ->
            let waiting = { wakeup = None } in
            flow.state <- Waiting waiting;
            let listener v =
              match waiting.wakeup with
              | None -> ()
              | Some wake ->
                  (* Remove ourselves from listeners *)
                  source.listeners <-
                    List.filter (fun l -> l != listener) source.listeners;
                  flow.state <- Running;
                  schedule (fun () -> wake v)
            in
            source.listeners <- listener :: source.listeners;
            waiting.wakeup <- Some (fun v ->
              go (fun () -> Effect.Deep.continue k v) cont);
            (* Register cleanup on cancellation *)
            flow.cancel_handlers <-
              (fun () ->
                source.listeners <-
                  List.filter (fun l -> l != listener) source.listeners)
              :: flow.cancel_handlers
        | effect (Emit v), k ->
            on_emit v;
            go (fun () -> Effect.Deep.continue k ()) cont
        | effect Yield, k ->
            schedule (fun () ->
              go (fun () -> Effect.Deep.continue k ()) cont)
    in
    go f (fun result ->
      flow.state <- Completed result)
```

#### Repeat and Until

The `repeat` combinator runs a flow repeatedly until an `until` event fires:

```ocaml skip
let repeat ?until body =
  let stop = ref false in
  (* Set up the until event if provided *)
  Option.iter (fun src ->
    let listener _ = stop := true in
    src.listeners <- listener :: src.listeners) until;
  (* Run the body repeatedly *)
  while not !stop do
    body ();
    run_pending ()
  done
```

But this version is too simple -- it blocks. A better version uses the effect system:

```ocaml skip
type _ Effect.t +=
  | Repeat : {
      body: unit -> unit;
      until: unit event_source option;
    } -> unit Effect.t

let repeat ?until body = Effect.perform (Repeat { body; until })

(* In the handler, we set up the until listener and schedule body iterations *)
```

#### Example: Drawing Application

Let us build a simple drawing application where the user clicks to add points to a shape:

```ocaml skip
(* Event sources *)
let mouse_click = make_event_source ()
let mouse_move = make_event_source ()
let key_press = make_event_source ()

(* Scene type *)
type point = int * int
type shape = point list

let shapes : shape list ref = ref []
let current_shape : shape ref = ref []

(* Drawing flow *)
let painter_flow () =
  (* Outer loop: one shape per iteration *)
  let rec shape_loop () =
    (* Wait for first click to start a shape *)
    let start = await mouse_click in
    current_shape := [start];
    emit !current_shape;

    (* Inner loop: add points until Enter is pressed *)
    let rec point_loop () =
      (* This is where effects shine: we can naturally express
         "wait for click OR key press" *)
      let point = await mouse_click in
      current_shape := point :: !current_shape;
      emit !current_shape;
      point_loop ()
    in

    (* Use a separate flow to watch for Enter key *)
    (* For simplicity, we'll just add points until we detect Enter *)
    point_loop ()
  in
  shape_loop ()
```

However, the above has a problem: `point_loop` runs forever. We need a way to break out when Enter is pressed. Effects make this natural:

```ocaml skip
type _ Effect.t +=
  | Race : 'a event_source * 'b event_source -> [`Left of 'a | `Right of 'b] Effect.t

let race a b = Effect.perform (Race (a, b))

let painter_flow () =
  let enter_pressed = make_event_source () in
  (* Convert key press to enter_pressed *)
  let _ = (* In practice, filter key_press for Enter *)
    () in

  let rec shape_loop () =
    let start = await mouse_click in
    current_shape := [start];
    emit !current_shape;

    let rec point_loop () =
      match race mouse_click enter_pressed with
      | `Left point ->
          current_shape := point :: !current_shape;
          emit !current_shape;
          point_loop ()
      | `Right () ->
          (* Enter was pressed, close the shape *)
          shapes := !current_shape :: !shapes;
          current_shape := [];
          emit !current_shape
    in
    point_loop ();
    shape_loop ()
  in
  shape_loop ()
```

The `race` combinator waits for either of two events and returns whichever fires first. This pattern -- waiting for one of several possible events -- is extremely common in interactive applications.

#### Implementing Race

```ocaml skip
let handle_race : type a b c. a event_source -> b event_source ->
    ([`Left of a | `Right of b], c) Effect.Deep.continuation -> unit =
  fun src_a src_b k ->
    let resolved = ref false in
    let listener_a = ref (fun _ -> ()) in
    let listener_b = ref (fun _ -> ()) in

    listener_a := (fun v ->
      if not !resolved then begin
        resolved := true;
        src_a.listeners <- List.filter (fun l -> l != !listener_a) src_a.listeners;
        src_b.listeners <- List.filter (fun l -> l != !listener_b) src_b.listeners;
        schedule (fun () -> Effect.Deep.continue k (`Left v))
      end);

    listener_b := (fun v ->
      if not !resolved then begin
        resolved := true;
        src_a.listeners <- List.filter (fun l -> l != !listener_a) src_a.listeners;
        src_b.listeners <- List.filter (fun l -> l != !listener_b) src_b.listeners;
        schedule (fun () -> Effect.Deep.continue k (`Right v))
      end);

    src_a.listeners <- !listener_a :: src_a.listeners;
    src_b.listeners <- !listener_b :: src_b.listeners
```

#### Benefits of Effects for Reactive Programming

Using effects for reactive flows has several advantages:

1. **Direct style**: The code reads as a natural sequence of steps. We write `let x = await event` rather than threading callbacks or using monadic bind.

2. **Structured concurrency**: Flows can spawn child flows and wait for them. Cancellation propagates naturally through the effect system.

3. **Composability**: The `race` combinator shows how we can build complex event patterns from simple primitives.

4. **Integration**: Effect-based flows integrate well with existing OCaml code. We can call ordinary functions and use standard control flow.

5. **Testability**: We can write test handlers that replay recorded event sequences, making it easy to test reactive logic.

The effect-based approach bridges the gap between the declarative style of FRP and the imperative style of traditional event handling. We get the expressiveness of direct-style code with the composability benefits of functional reactive programming.

### 10.8 Summary

This chapter explored a progression of techniques for handling change and interaction in functional programming:

**Zippers** provide a way to navigate and modify data structures efficiently. The key insight is that a location = context + subtree, where the context is stored as a list with the innermost layer first for efficient navigation. Zippers are particularly useful for tree editors, document processors, and algebraic manipulation as shown in our context rewriting example.

**Incremental computing** automatically tracks dependencies between computations and propagates changes efficiently. We examined two OCaml libraries:
- **Lwd** takes a minimalist approach with compact nodes, push-based invalidation, and pull-based recomputation. It is ideal for UI rendering with its acquire/release protocol for resource management.
- **Incremental** provides industrial-strength self-adjusting computation with rich node metadata, height-based ordering, timestamp-based staleness, and first-class cutoff support.

**Functional Reactive Programming** deals with time-varying values declaratively:
- **Behaviors** are continuous functions of time (e.g., mouse position)
- **Events** are discrete occurrences (e.g., mouse clicks)
- The stream-based implementation shows how FRP reduces to stream processing with memoization
- The Lwd-based implementation demonstrates building FRP on top of incremental computing

**Direct control with effects** bridges the gap between declarative FRP and imperative event handling. Using algebraic effects, we can write sequential flows that await events, emit values, and support combinators like `race` for waiting on multiple events.

Each technique has its place:
- Use zippers for structural navigation when you need efficient local modifications
- Use incremental computing when changes are small relative to total computation
- Use FRP for continuous behaviors and animations
- Use effect-based flows for sequential, state-machine-like interactions

### 10.9 Exercises

**Exercise 1.** Extend the context rewriting example from Section 10.2 to handle subtraction and division. Remember that these operators are not commutative, so the rewriting rules need to be more careful. For example, $D[e - C[x]]$ cannot simply become $D[C[x] - e]$ without negating something.

**Exercise 2.** Implement a simple text editor zipper:
1. Define a type for a text buffer as a zipper over characters, with the cursor position represented by the split between left context and right content.
2. Implement `insert_char`, `delete_char`, `move_left`, `move_right`, `move_to_start`, and `move_to_end` operations.
3. Add word-based movement: `move_word_left` and `move_word_right`.

**Exercise 3.** Implement `switch` and `until` for the stream-based FRP system:
- `switch : 'a behavior -> 'a behavior event -> 'a behavior` -- behaves as the most recent behavior from events
- `until : 'a behavior -> 'a behavior event -> 'a behavior` -- switches once on the first event

**Exercise 4.** Add the following features to the paddle game example:
1. Score keeping: increment score when the ball bounces off the paddle
2. Game over: detect when the ball falls below the paddle
3. Restart: press a key to restart after game over
4. Speed increase: gradually increase ball speed as the game progresses

**Exercise 5.** Our numerical integration function uses the rectangle rule (left endpoint). Implement and compare:
1. The midpoint rule: $\int_a^b f(x)dx \approx (b-a) \cdot f\left(\frac{a+b}{2}\right)$
2. The trapezoidal rule: $\int_a^b f(x)dx \approx (b-a) \cdot \frac{f(a) + f(b)}{2}$
3. Simpson's rule: $\int_a^b f(x)dx \approx \frac{b-a}{6} \left( f(a) + 4f\left(\frac{a+b}{2}\right) + f(b) \right)$

Test the accuracy by integrating $\sin(x)$ from 0 to $\pi$ (exact answer: 2).

**Exercise 6.** Implement a `debounce` combinator for events:
```
val debounce : float -> 'a event -> 'a event
```
The debounced event only fires if the original event has not fired for the specified time interval. This is useful for handling rapid user input like typing.

**Exercise 7.** In the Lwd-based FRP implementation, we used mutable references inside `Lwd.map` computations. This works but can be surprising. Implement a version using Lwd's `Lwd.var` for state instead:
1. Create helper functions that properly manage Lwd variables for stateful computations
2. Reimplement `step` and `step_accum` using this approach
3. Compare the two approaches in terms of behavior when the dependency graph changes

**Exercise 8.** Extend the effect-based flow system with a `timeout` combinator:
```
val timeout : float -> 'a event_source -> 'a option
```
The timeout returns `Some v` if the event fires within the timeout period, or `None` if the timeout expires first. You will need to integrate with some form of time management (e.g., a timer event source).

**Exercise 9.** Implement `parallel` for effect-based flows:
```
val parallel : (unit -> 'a) list -> 'a list
```
This should run multiple flows concurrently and collect their results. Think about:
- How do you handle flows that await events?
- What happens if one flow fails?
- How do you handle cancellation?

**Exercise 10.** The FRP implementations in this chapter handle time as wall-clock time from `Unix.gettimeofday`. Implement a version with *virtual time* that can be controlled programmatically:
1. Create a `Clock` module with `advance : float -> unit` and `now : unit -> float` functions
2. Modify the integration function to use virtual time
3. Write tests that use virtual time to verify physics behavior deterministically

This is valuable for testing animations and physics without waiting real time.

**Exercise 11.** Compare the memory characteristics of the three FRP approaches:
1. Create a benchmark that builds a dependency graph with N nodes
2. Measure memory usage for each approach (stream-based, Lwd-based, effect-based)
3. Measure update time when one input changes
4. Plot the results and explain the tradeoffs

**Exercise 12.** Implement a simple spreadsheet using Lwd:
1. Cells can contain numbers or formulas referencing other cells (e.g., `=A1+B2`)
2. The dependency graph should update automatically when cell values change
3. Detect and report circular dependencies
4. Support basic functions: `SUM`, `AVERAGE`, `MAX`, `MIN` over cell ranges

