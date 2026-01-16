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

While zippers are elegant for navigating and modifying data structures, they are somewhat unnatural for general-purpose programming. The fundamental problem is this: once we change something using a zipper, how do we propagate those changes through all the computations that depend on the modified data? We would need to rewrite all our algorithms to explicitly work with context changes, which defeats the purpose of clean functional programming.

*Adaptive Programming*, also known as *incremental computation* or *self-adjusting computation*, offers a more elegant solution. The idea is beautifully simple: we write programs in a straightforward functional manner, but the runtime system tracks dependencies between computations. When we later modify any input data, only the minimal amount of work required to update the results is performed -- everything else is reused from before.

The functional description of computation lives within a monad. We can change monadic values -- for example, parts of input -- from outside the computation, and the changes automatically propagate to all dependent results. In the *Froc* library by Jake Donham, the monadic *changeables* are represented by type `'a Froc_sa.t`, and the ability to modify them from outside is exposed by type `'a Froc_sa.u` -- the *writeables*.

#### Dependency Graphs

The key to making incremental computation work is tracking *how* a result was computed, not just *what* the result is. The monadic value `'a changeable` stores the *dependency graph* of the computation of the represented value `'a`.

Consider a simple computation:

```
let u = v / w + x * y + z
```

This creates a dependency graph where `u` depends on intermediate results (let us call them `n0 = v/w`, `n1 = x*y`, `n2 = n0+n1`), which in turn depend on the input variables. When we modify inputs -- say, both `v` and `z` simultaneously -- the runtime needs to update intermediate nodes in the correct order. Since `n2` depends on `n0`, we must update `n0` before `n2`, and both must be updated before `u`.

The order in which the computation was originally performed determines the order of updates. We record timestamps for each computation, and updates follow this timestamp order. Similar to `parallel` in the concurrency monad from Chapter 8, we provide `bind2`, `bind3`, etc., and corresponding `lift2`, `lift3`, etc., to introduce nodes that depend on several children simultaneously:

```
let n0 = bind2 v w (fun v w -> return (v / w))
let n1 = bind2 x y (fun x y -> return (x * y))
let n2 = bind2 n0 n1 (fun n0 n1 -> return (n0 + n1))
let u = bind2 n2 z (fun n2 z -> return (n2 + z))
```

The beauty of lifting is that we can make our code look almost identical to ordinary arithmetic. Do-notation is not necessary to have readable expressions:

```
let (/) = lift2 (/)
let ( * ) = lift2 ( * )
let (+) = lift2 (+)
let u = v / w + x * y + z  (* Looks like normal code, but tracks dependencies! *)
```

As in other monads, we can decrease overhead by combining multiple operations into bigger chunks. Instead of creating a dependency node for every single operation, we can batch several operations together:

```
let n0 = blift2 v w (fun v w -> v / w)
let n2 = blift3 n0 x y (fun n0 x y -> n0 + x * y)
let u = blift2 n2 z (fun n2 z -> n2 + z)
```

#### Handling Conditional Dependencies

There is a subtlety that arises with conditionals. Consider this example:

```
let b = x >>= fun x -> return (x = 0)
let n0 = x >>= fun x -> return (100 / x)
let y = bind2 b n0 (fun b n0 -> if b then return 0 else n0)
```

If we blindly recompute all nodes in their original order when `x` changes, we have a problem. If `x` becomes 0, we would compute `n0 = 100 / 0` and crash -- even though the conditional in `y` would never use that result!

The solution is to use *time intervals* rather than single timestamps. Each computation records when it began and when it ended. When updating the `y` node, we first *detach* all nodes in its time range (let us say 4-9) from the graph. The conditional is then recomputed, and it will re-attach only the nodes it actually needs. If `b` is true, the `n0` computation is never re-attached and thus never re-executed.

What if the value of `b` does not change? Then we can skip updating `y` entirely and proceed directly to updating `n0`. Since `y` contains a link to the value of `n0`, the final result of `y` will still reflect any changes to `n0`.

We also need *memoization* to efficiently re-attach the same nodes when they do not need updating. When should a detached node be considered up-to-date? When the update process has progressed past that node's timestamp range, it is safe to re-attach it unchanged.

#### Example Using Froc

Let us see adaptive programming in action with a concrete example: incrementally growing and displaying a tree. The `Froc_sa` module (for *self-adjusting*) exports the monadic type `t` for changeable computation, and a handle type `u` for updating the computation from outside.

We define a binary tree where each node stores its screen location. Crucially, the children are wrapped in the `t` type, making them changeable:

```ocaml skip
open Froc_sa

type tree =
  | Leaf of int * int              (* A leaf stores its x,y position *)
  | Node of int * int * tree t * tree t  (* Children are changeable! *)
```

Displaying the tree is itself a changeable effect. Whenever the tree changes, the display will be automatically updated. The key insight is that only *new* nodes will be drawn after an update -- unchanged parts of the tree do not trigger any drawing:

```ocaml skip
let rec display px py t =  (* px, py = parent position for drawing line *)
  match t with
  | Leaf (x, y) ->
    return
      (Graphics.draw_poly_line [|px, py; x, y|];  (* Draw line to parent *)
       Graphics.draw_circle x y 3)  (* Draw the leaf node *)
  | Node (x, y, l, r) ->
    return (Graphics.draw_poly_line [|px, py; x, y|])
    >>= fun _ -> l >>= display x y  (* Recursively display left child *)
    >>= fun _ -> r >>= display x y  (* Recursively display right child *)
```

Now the interesting part: growing the tree. The `grow_at` function replaces a leaf with a new internal node that has two leaf children. The crucial operations are `changeable` (which creates a new changeable value with a writeable handle) and `write` (which updates a changeable from outside):

```ocaml skip
let grow_at (x, depth, upd) =
  (* Calculate positions for left and right children *)
  let x_l = x - f2i (width *. (2.0 ** (~-. (i2f (depth + 1))))) in
  let l, upd_l = changeable (Leaf (x_l, (depth + 1) * 20)) in
  let x_r = x + f2i (width *. (2.0 ** (~-. (i2f (depth + 1))))) in
  let r, upd_r = changeable (Leaf (x_r, (depth + 1) * 20)) in
  (* Replace the old leaf with a new internal node *)
  write upd (Node (x, depth * 20, l, r));
  propagate ();  (* Trigger update propagation! *)
  (* Return handles for future growth at the new leaves *)
  [x_l, depth + 1, upd_l; x_r, depth + 1, upd_r]
```

The main loop grows the tree level by level, calling `grow_at` for every leaf at the current frontier:

```ocaml skip
let rec loop t subts steps =
  if steps <= 0 then ()
  else loop t (concat_map grow_at subts) (steps - 1)

let incremental steps () =
  Graphics.open_graph " 1024x600";
  let t, u = changeable (Leaf (512, 20)) in
  (* Set up the display ONCE -- it will update automatically! *)
  let d = t >>= display (f2i (width /. 2.)) 0 in
  loop t [512, 1, u] steps;  (* New nodes will be drawn automatically *)
  Graphics.close_graph ()
```

Notice the elegance: we set up the display computation once, and then as we grow the tree by writing to changeable leaves, the display automatically updates to show only the new nodes. The dependency tracking ensures that only the affected parts of the display computation are re-executed.

However, there is a practical caveat: the overhead of incremental computation is quite large. Comparing byte code execution times for growing and displaying trees of various depths:

| depth | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 |
|-------|-----|-----|-----|-----|-----|-----|-----|------|------|
| incremental | 0.66s | 1s | 2.2s | 4.4s | 9.3s | 21s | 50s | 140s | 255s |
| rebuilding | 0.5s | 0.63s | 1.3s | 3s | 5.3s | 13s | 39s | 190s | -- |

Rebuilding the entire tree from scratch is actually faster for smaller depths! Incremental computation only wins when changes are small relative to the total computation. The moral: use incremental computation when you expect to make many small updates to a large structure, not when building something from scratch.

### 10.4 Functional Reactive Programming

We have seen how zippers let us navigate structures and how adaptive programming propagates changes. But what about programs that must respond to *time* itself -- animations, games, interactive applications? This is the domain of *Functional Reactive Programming* (FRP).

FRP is an attempt to declaratively deal with time. The key insight is to distinguish two kinds of time-varying values:

- *Behaviors* are continuous functions of time. A behavior has a specific value at every instant. Think of a mouse position, window size, or the current frame of an animation.

- *Events* are discrete occurrences. An event is a set of (time, value) pairs, organized into streams of actions. Think of mouse clicks, key presses, or timer ticks.

Two fundamental problems arise in FRP:

1. **Causality**: Behaviors and events must be well-defined, which means they cannot depend on future values. A behavior at time $t$ can only depend on events that have already occurred.

2. **Efficiency**: We need to minimize the overhead of tracking time and dependencies, especially for real-time applications like games.

FRP is *synchronous*: it is possible to set up multiple events to happen at exactly the same time, and the system handles this correctly. It is also *continuous*: behaviors can have details at arbitrary time resolution. Although the actual results are *sampled* at discrete moments, there is no fixed (minimal) time step for specifying behavior -- you describe what the behavior *should be* at any time, and the system samples it as needed.

(Note: "Asynchrony" in reactive programming refers to various different ideas depending on context, so always ask what people mean when they use the term.)

#### Idealized Definitions

Let us start with the idealized, mathematical definitions and then see how practical considerations force us to refine them.

In the purest form, we would define:

```ocaml skip
type time = float
type 'a behavior = time -> 'a  (* Arbitrary function of time *)
type 'a event = ('a, time) stream  (* Stream of values at increasing time instants *)
```

This is mathematically elegant: a behavior is literally a function from time to values, and events are a lazy stream of timestamped occurrences. Forcing the stream would block until the next event arrives.

But this idealized view has problems. Behaviors need to react to external events -- the position of a paddle should follow the mouse, not just be a predetermined function of time:

```ocaml skip
type user_action =
  | Key of char * bool
  | Button of int * int * bool * bool
  | MouseMove of int * int
  | Resize of int * int

type 'a behavior = user_action event -> time -> 'a
```

Now a behavior takes both the event history and the current time. But this leads to an efficiency problem: every time we evaluate a behavior, we would need to scan through all events from the beginning of time up to the current moment. This is wasteful in both time and space.

The solution is to turn behaviors into stream transformers. Instead of a function that answers "what is the value at time $t$?", we produce a stream of values, one for each sampling time. This allows us to forget about events that are already in the past:

```ocaml skip
type 'a behavior =
  user_action event -> time stream -> 'a stream
```

The next optimization is to combine the user actions and sampling times into a single stream. At each sampling moment, we either have a user action or nothing happened:

```ocaml skip
type 'a behavior =
  (user_action option * time) stream -> 'a stream
```

The `None` action corresponds to a sampling moment when nothing happened -- we still need to produce a value for the behavior at that time, even if no event triggered it.

This transformation from functions-of-time to stream transformers is analogous to a classic algorithm optimization: computing the intersection of two sorted lists. The naive approach checks every pair, giving $O(mn)$ time. The smart approach walks through both lists simultaneously, giving $O(m + n)$ time. Similarly, our stream-based behaviors process time and events together in a single pass.

With behaviors as stream transformers, we can elegantly define events in terms of behaviors:

```ocaml skip
type 'a event = 'a option behavior
```

An event is simply a behavior that produces `None` at most sampling times and `Some value` when the event actually occurs. This unifies our treatment of behaviors and events, although it somewhat betrays the discrete character of events (they conceptually happen at points in time, not vary over intervals).

We have now arrived at something very close to the *stream processing* we discussed in Chapter 7. Recall the incremental pretty-printing example that could "react" to more input being added. The stream combinators we developed there, along with *fork* (from the exercises) and a corresponding *merge*, turn stream processing into *synchronous discrete reactive programming*. FRP is, in a sense, stream processing with explicit time.

#### Behaviors as Monads

Behaviors form a monad -- at least in the original, idealized specification. Looking at the simple definition `type 'a behavior = time -> 'a`, we can define:

```ocaml skip
type 'a behavior = time -> 'a

val return : 'a -> 'a behavior
let return a = fun _ -> a  (* Constant behavior: same value at all times *)

val bind : 'a behavior -> ('a -> 'b behavior) -> 'b behavior
let bind a f = fun t -> f (a t) t  (* Sample 'a' at time t, then sample the result *)
```

The `return` function creates a constant behavior that has the same value at all times. The `bind` function samples the first behavior at the current time, uses that value to select a second behavior, and samples *that* at the current time.

In practice, as we saw with changeables, we mostly use *lifting* rather than full monadic bind. In the Haskell world, behaviors are often called *applicative* rather than monadic. We can build our own lifting functions from the applicative `ap` combinator:

```
val ap : ('a -> 'b) monad -> 'a monad -> 'b monad
let ap fm am =
  let* f = fm in
  let* a = am in
  return (f a)
```

A word of caution: for changeables and other incremental systems, this naive implementation of `ap` will introduce unnecessary dependencies in the computation graph. If `fm` changes, we would unnecessarily recompute everything even if only `am` matters for the result. Good FRP and incremental computing libraries provide optimized variants that track dependencies more precisely. This is analogous to how we needed `parallel` (rather than sequential bind) for concurrent computing in Chapter 8.

#### Converting Between Events and Behaviors

One of the most important operations in FRP is converting between events and behaviors. Going from events to behaviors, the key combinators `until` and `switch` have type:

```
'a behavior -> 'a behavior event -> 'a behavior
```

while `step` has type:

```
'a -> 'a event -> 'a behavior
```

Here is what each does:

- `until b es` behaves as `b` until the first event in `es` occurs, then permanently switches to behaving as the behavior carried by that event. This is "one-shot" switching.

- `switch b es` behaves as the behavior from the *most recent* event in `es` (prior to current time), if any event has occurred, otherwise it behaves as `b`. Unlike `until`, this keeps switching whenever a new event arrives.

- `step a es` is the simplest: it starts as a constant behavior returning `a`, and then switches to returning the value of the most recent event in `es`. This creates a *step function* -- a behavior that jumps from value to value at discrete times.

We will use the term "*signal*" to refer to either a behavior or an event. Be aware that terminology varies across FRP libraries: some use "signal" to mean specifically what we call a behavior. Always check the documentation when working with a new FRP library.

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

### 10.6 Reactivity by Incremental Computing

In the previous section, we implemented FRP using lazy streams. An alternative approach is to use the incremental computing infrastructure from Section 10.3. The *Froc* library takes this approach.

In *Froc*, both behaviors and events are implemented as changeables, but they have different lifetimes. Behaviors *persist* -- they always have a current value. Events are *instantaneous* -- they fire, propagate their values, and then are removed from the dependency graph. This captures an intuitive distinction: a behavior like "current mouse position" always exists, while an event like "mouse button pressed" happens at a moment and is gone.

Behaviors are composed out of constants and prior events, capturing the "changeable" aspect. Events capture the "writeable" aspect -- they are how external inputs enter the system. Together, events and behaviors are called *signals*.

One important design choice in *Froc*: it does not explicitly represent time. Instead, it provides the function `changes : 'a behavior -> 'a event`, which fires an event whenever a behavior changes. This violates the continuous semantics we discussed earlier -- it breaks the illusion that behaviors vary continuously rather than at discrete points. But it simplifies the implementation by avoiding the need to synchronize global time samples with events. The result is "less continuous but more dense" in the sense that updates happen exactly when needed, not at fixed intervals.

Sending an event using `send` starts an *update cycle*. During an update cycle, all dependent signals are brought up to date. Signals themselves cannot call `send` (that would create unpredictable cascades), but they can call `send_deferred`, which schedules an event for the *next* update cycle. Things that happen in the same update cycle are considered *simultaneous*.

*Froc* provides `fix_b` and `fix_e` functions to define signals recursively. The "current value" in a recursive definition refers to the value from the *previous* update cycle, and each recursive step is deferred to the next cycle, until values converge.

Update cycles can happen "back-to-back" via `send_deferred` and `fix_b`/`fix_e`, or can be triggered from outside *Froc* by sending events at arbitrary times. With a `time` behavior that tracks a clock event, events from back-to-back update cycles can have the same clock time even though they are not simultaneous in the FRP sense. This architecture prevents *glitches*, where an outdated signal value is accidentally used before it has been updated.

#### Pure vs. Impure Style

*Froc* supports two programming styles. A behavior is written in *pure style* when its definition does not use `send`, `send_deferred`, `notify_e`, `notify_b`, or `sample`. In pure style:

- `sample`, `notify_e`, `notify_b` are used only from *outside* the behavior (from its "environment") -- analogous to observing the result of a function after it completes
- `send`, `send_deferred` are used only from outside -- analogous to providing input to a function before it runs

In *impure style*, we can freely mix signal definitions with imperative notifications and samples. This is more flexible but has an important pitfall: we must ensure that all pieces of our behavior are *referred to* from somewhere, otherwise the garbage collector will reclaim them and our behavior will mysteriously stop working!

A value is "referred to" when it has a name in the global environment, or is stored as part of a larger value that is referred to. Signals are also referred to when they are part of the dependency graph. If you define a signal, attach a notification to it, but do not keep the signal itself alive, the notification may stop working when the signal is garbage collected.

#### Reimplementing the Paddle Game Example

Let us reimplement the paddle game using *Froc* instead of lazy streams. We will follow the same structure as our stream-based FRP example: a scene behavior that represents the complete game state at each moment.

First, we introduce time explicitly (since *Froc* does not track it automatically):

```ocaml skip
open Froc
let clock, tick = make_event ()  (* clock event, tick to send it *)
let time = hold (Unix.gettimeofday ()) clock  (* Behavior: current time *)
```

The main loop will call `send tick current_time` at each frame. Now we can define integration. Note the use of `sample` to read the current value of a behavior -- this is the impure style:

```ocaml skip
let integral fb =
  let aux (sum, t0) t1 =
    sum +. (t1 -. t0) *. sample fb, t1 in
  collect_b aux (0., sample time) clock
```

For convenience, the integral remembers the current upper limit of integration. It will be useful to get the integer part:

```ocaml skip
let integ_res fb =
  lift (fun (v, _) -> int_of_float v) (integral fb)
```

We can also define integration in *pure style*, which avoids calling `sample` inside the behavior definition:

```ocaml skip
let pair fa fb = lift2 (fun x y -> x, y) fa fb

let integral_nice fb =
  let samples = changes (pair fb time) in  (* Event when either changes *)
  let aux (sum, t0) (fv, t1) =
    sum +. (t1 -. t0) *. fv, t1 in
  collect_b aux (0., sample time) samples
```

The initial value `(0., sample time)` uses `sample`, but this is evaluated *once* when setting up the behavior, not inside the behavior definition itself, so it does not spoil the pure style.

### 10.7 Direct Control

The declarative style of FRP is elegant for continuous behaviors, but real-world interactions are often *state machines* that proceed through distinct stages. Consider a recipe: *1. Preheat the oven. 2. Put flour, sugar, eggs into a bowl. 3. Mix well. 4. Pour into pan.* Each step must complete before the next begins. How do we express this kind of sequential, staged behavior in FRP?

We want a *flow* that can proceed through events in sequence: when the first event arrives, we remember its result, and then wait for the next event. Crucially, we *ignore* any further occurrences of the first event after we have moved on. Standard FRP constructs like mapping events or attaching notifications do not give us this "move forward and never look back" semantics.

We also want to be able to *repeat* or *loop* a flow. But the loop should restart from the notification of the first event that arrives *after* the previous iteration completed -- not from events that happened during the previous iteration.

The key primitive is `next e`, an event that propagates only the *first* occurrence of `e` and then goes silent. This will be the basis of our `await` function.

Additionally, the whole flow should be *cancellable* from outside at any time -- for instance, when the user quits the application.

If this sounds familiar, it should: a flow is essentially a *lightweight thread* as we discussed at the end of Chapter 8. We will make it a monad. Unlike general threads, a flow only "stores" a non-unit value when it is suspended waiting for an event (via `await`). But it has a primitive to `emit` values. We are actually implementing *coarse-grained* threads (Chapter 8 exercise 11), with `await` playing the role of `suspend`.

We build a module `Flow` with monadic type `('a, 'b) flow`. The type has two parameters: `'a` is the type of values we emit (output), and `'b` is the type of values we store (the result of awaited events):

```ocaml skip
type ('a, 'b) flow
type cancellable  (* Handle to cancel a flow and stop further computation *)

val noop_flow : ('a, unit) flow  (* Do nothing, same as return () *)
val return : 'b -> ('a, 'b) flow  (* Immediately completed flow with result 'b *)
val await : 'b Froc.event -> ('a, 'b) flow  (* Suspend until event fires *)
val bind :   (* Sequential composition of flows *)
  ('a, 'b) flow -> ('b -> ('a, 'c) flow) -> ('a, 'c) flow
val emit : 'a -> ('a, unit) flow  (* Output a value *)
val cancel : cancellable -> unit  (* Cancel a running flow *)
val repeat :  (* Loop until the 'until' event fires; return that event's value *)
  ?until:'a Froc.event -> ('b, unit) flow -> ('b, 'a) flow
val event_flow :   (* Turn a flow into an event that fires on each emit *)
  ('a, unit) flow -> 'a Froc.event * cancellable
val behavior_flow :  (* Turn a flow into a behavior; initial value + flow to update *)
  'a -> ('a, unit) flow -> 'a Froc.behavior * cancellable
val is_cancelled : cancellable -> bool  (* Check if flow was cancelled *)
```

#### Implementation Details

The implementation follows our lightweight threads from Chapter 8 (or the *Lwt* library), adapted for the needs of cancellation:

```ocaml skip
module F = Froc
type 'a result =
  | Return of 'a  (* Completed with value *)
  | Sleep of ('a -> unit) list * F.cancel ref list  (* Waiting for wakeup *)
  | Cancelled  (* Flow was cancelled *)
  | Link of 'a state  (* Indirection to another state *)
and 'a state = {mutable state : 'a result}
type cancellable = unit state  (* Handle to check/trigger cancellation *)
```

The `Sleep` state holds both waiters (callbacks to invoke when a result arrives) and a list of *Froc* cancel handles (for cancelling event notifications if the flow is cancelled).

Functions `find`, `wakeup`, `connect` are similar to Chapter 8, with the addition that connecting to a cancelled flow cancels the other flow as well.

The key insight is that our flow monad is actually a *reader monad* layered over the state. The reader environment supplies the `emit` function:

```ocaml skip
type ('a, 'b) flow = ('a -> unit) -> 'b state
```

The `return` and `bind` functions are as in our lightweight threads, but we need to handle cancelled flows: for `m = bind a b`, if `a` is cancelled then `m` is cancelled, and if `m` is cancelled then we do not wake up `b`:

```ocaml skip
let waiter x =
  if not (is_cancelled m)
  then connect m (b x emit) in
  ...
```

`await` is implemented like `next`, but it wakes up a flow:

```ocaml skip
let await t = fun emit ->
  let c = ref F.no_cancel in
  let m = {state = Sleep ([], [c])} in
  c :=
    F.notify_e_cancel t begin fun r ->
      F.cancel !c;
      c := F.no_cancel;
      wakeup m r
    end;
  m
```

`repeat` attaches the whole loop as a waiter for the loop body.

#### Example: Drawing Shapes

Let us see flows in action with a simple drawing program. The user draws shapes by pressing and dragging the mouse; releasing the mouse closes the current shape and starts a new one.

The scene is a list of shapes, where the first shape is "open" (still being drawn) and the rest are closed:

```ocaml skip
type scene = (int * int) list list  (* First element is the open shape *)

let draw sc =
  let open Graphics in
  clear_graph ();
  (match sc with
  | [] -> ()
  | opn :: cld ->
    draw_poly_line (Array.of_list opn);  (* Draw open shape as line *)
    List.iter (fill_poly -| Array.of_list) cld);  (* Fill closed shapes *)
  synchronize ()
```

Now we build the drawing flow. Notice how naturally we can express the sequential logic: wait for button press, then repeatedly add points until button release, then start over:

```ocaml skip
let painter =
  let cld = ref [] in  (* Accumulated closed shapes *)
  repeat (perform  (* Outer loop: one shape per iteration *)
      await mbutton_pressed;  (* Wait for mouse button down *)
      let opn = ref [] in     (* Points in current shape *)
      repeat (perform  (* Inner loop: points in one shape *)
          mpos <-- await mouse_move;  (* Wait for mouse movement *)
          emit (opn := mpos :: !opn; !opn :: !cld))  (* Emit updated scene *)
        ~until:mbutton_released;  (* Exit inner loop on button release *)
      emit (cld := !opn :: !cld; opn := []; [] :: !cld))  (* Close shape *)

let painter, cancel_painter = behavior_flow [] painter
let () = reactimate painter  (* Run the animation *)
```

#### Flows and State

Global state and thread-local state can both be used with flows, but you must pay careful attention to *when* expressions are evaluated. The key question is: is this computation *inside* the monad (executed when the flow runs), or is it executed *while building* the initial monadic value (executed once at setup time)?

Side effects hidden in `return` and `emit` *arguments* are evaluated immediately when constructing the flow, not when the flow runs. This leads to a subtle distinction:

```ocaml skip
let f =
  repeat (
      let* () = emit (Printf.printf "[0]\n%!"; '0') in  (* The printf runs NOW *)
      let* () = await aas in  (* Suspend until 'a' event *)
      let* () = emit (Printf.printf "[1]\n%!"; '1') in  (* Printf after resume *)
      let* () = await bs in
      let* () = emit (Printf.printf "[2]\n%!"; '2') in
      let* () = await cs in
      let* () = emit (Printf.printf "[3]\n%!"; '3') in
      let* () = await ds in
      emit (Printf.printf "[4]\n%!"; '4'))

let e, cancel_e = event_flow f
let () =
  F.notify_e e (fun c -> Printf.printf "flow: %c\n%!" c);
  Printf.printf "notification installed\n%!"

let () =
  F.send a (); F.send b (); F.send c (); F.send d ();
  F.send a (); F.send b (); F.send c (); F.send d ()
```

The output demonstrates this subtle timing:

- `[0]` -- Printed only *once*, when building the loop (not inside the monad!)
- `notification installed` -- Notification set up
- `event: a` -- First event fires
- `[1]` -- Now inside the monad, after first await returns
- `flow: 1` -- Emitted value
- ... continues through the remaining events and loop iterations

The key insight: `[0]` is in the *first line* of the loop before any `await`, so it is evaluated when constructing the `repeat` expression. The `Printf.printf` in subsequent `emit` calls is after a bind (after an `await`), so it runs each time that point in the flow is reached.

### 10.8 Graphical User Interfaces

An in-depth discussion of GUIs is beyond the scope of this course. However, GUIs are a natural application of FRP and flows, so we will cover enough to build a complete example: a calculator.

We demonstrate two OCaml GUI libraries. *LablTk* (based on the Tk toolkit from Tcl) uses optional labelled arguments (discussed in Chapter 2 exercise 2) and polymorphic variants. *LablGTk* (based on GTK+) additionally uses objects. We will learn more about objects and polymorphic variants in the next chapter.

#### Calculator Flow

The calculator is a perfect example of a state machine with sequential stages. We represent its mechanics directly as a flow:

```ocaml skip
let digits, digit = F.make_event ()  (* Events for digit button presses *)
let ops, op = F.make_event ()        (* Events for operator button presses *)
let dots, dot = F.make_event ()      (* Event for decimal point (exercise) *)

let calc =
  (* Two state variables: current number and pending operation *)
  let f = ref (fun x -> x) and now = ref 0.0 in
  repeat (
      (* Phase 1: Enter digits of a number *)
      let* op = repeat (
            let* d = await digits in  (* Wait for digit press *)
            emit (now := 10. *. !now +. d; !now))  (* Build up number *)
        ~until:ops in  (* Until operator button is pressed *)
      (* Phase 2: Apply pending operation, store new operator *)
      let* () = emit (now := !f !now; f := op !now; !now) in
      (* Phase 3: Allow user to change operator before entering next number *)
      let* d = repeat
        (let* op = await ops in return (f := op !now))
        ~until:digits in  (* Until they start entering the next number *)
      (* Phase 4: Reset for the new number *)
      emit (now := d; !now))

let calc_e, cancel_calc = event_flow calc  (* Event notifies display update *)
```

Notice how the flow structure directly mirrors the user interaction pattern: enter a number, press an operator, optionally change your mind about the operator, enter another number, and so on.

#### Tk: LablTk

The *Tk* widget toolkit originated with the Tcl language and is known for its simplicity. *LablTk* provides OCaml bindings using labelled arguments.

First, we define the layout of our calculator buttons -- this part is the same regardless of which GUI toolkit we use:

```ocaml skip
let layout = [|
  [|"7", `Di 7.; "8", `Di 8.; "9", `Di 9.; "+", `O (+.)|];
  [|"4", `Di 4.; "5", `Di 5.; "6", `Di 6.; "-", `O (-.)|];
  [|"1", `Di 1.; "2", `Di 2.; "3", `Di 3.; "*", `O ( *.)|];
  [|"0", `Di 0.; ".", `Dot;   "=",  `O sk; "/", `O (/.)|]
|]
```

Each entry is a pair of the button label and its action: `` `Di d`` means send digit `d`, `` `O f`` means send operator function `f`, and `` `Dot`` means send the decimal point event (handling this is left as an exercise).

Key GUI concepts in Tk:

- Every *widget* (window gadget) has a *parent* widget in which it is located
- *Buttons* have an action (callback function) invoked when pressed; *labels* just display information; *entries* (text fields) allow keyboard input
- Actions are *callback* functions passed as the `~command` argument
- *Frames* group related widgets together
- The parent widget is passed as the last argument, after optional labelled arguments

```ocaml skip
let top = Tk.openTk ()  (* Open the main window *)

let btn_frame =
  Frame.create ~relief:`Groove ~borderwidth:2 top  (* Container for buttons *)

let buttons =
  Array.map (Array.map (function
    | text, `Dot ->
      Button.create ~text
        ~command:(fun () -> F.send dot ()) btn_frame
    | text, `Di d ->
      Button.create ~text
        ~command:(fun () -> F.send digit d) btn_frame  (* Send digit event *)
    | text, `O f ->
      Button.create ~text
        ~command:(fun () -> F.send op f) btn_frame))  (* Send operator event *)
    layout

let result = Label.create ~text:"0" ~relief:`Sunken top  (* Result display *)
```

GUI toolkits provide layout algorithms, so we only specify *which* widgets go together and *how* they should fill space. Tk offers `pack` for sequential layout and `grid` for table-like organization:

Common layout options:

- `~fill:` how the widget fills allocated space: `` `X``, `` `Y``, `` `Both`` or `` `None``
- `~expand:` whether to request extra space (`true`) or only what is needed (`false`)
- `~anchor:` glue the widget to a direction: `` `Center``, `` `E``, `` `Ne``, etc.
- `grid` also supports `~columnspan` and `~rowspan` for multi-cell widgets
- `configure` functions change existing widgets using the same arguments as `create`

```ocaml skip
let () =
  Wm.title_set top "Calculator";
  Tk.pack [result] ~side:`Top ~fill:`X;  (* Result at top, fills width *)
  Tk.pack [btn_frame] ~side:`Bottom ~expand:true;  (* Buttons below *)
  Array.iteri (fun column -> Array.iteri (fun row button ->
    Tk.grid ~column ~row [button])) buttons;  (* Grid layout for buttons *)
  Wm.geometry_set top "200x200";
  (* Connect Froc event to update the display *)
  F.notify_e calc_e
    (fun now ->
      Label.configure ~text:(string_of_float now) result);
  Tk.mainLoop ()  (* Enter the GUI event loop *)
```

#### GTk+: LablGTk

*LablGTk* provides OCaml bindings for the *GTk+* library (written in C). Unlike LablTk, it uses an object-oriented interface: widgets are objects, and operations are method calls.

In OCaml's object system, fields are only visible to the object's own methods, and methods are called with `#` syntax: e.g., `window#show ()`.

GTk+ has its own reactive event system (confusingly, GTk+ uses "signal" where we say "event"):

- Registering a callback is called *connecting a signal handler*: `button#connect#clicked ~callback:hello` takes `~callback:(unit -> unit)` and returns a `GtkSignal.id`
- Multiple handlers can be attached to the same signal, just like *Froc* notifications
- GTk+ *events* (note: different from signals) relate to window-system events: `window#event#connect#delete ~callback:delete_event`
- Event callbacks receive more information: `~callback:(event -> unit)` for some event type

GTk+ layout is simpler than Tk's:

- Only horizontal (`hbox`) and vertical (`vbox`) boxes are available
- Grid layout is called `table`, with `~fill` and `~expand` taking `` `X``, `` `Y``, `` `BOTH``, `` `NONE``

A few API differences: `coerce` is a method that casts widget types (Tk uses a `coe` function). Labels do not have a dedicated module. Widget properties are set via `widget#set_X` methods rather than a single `configure` function.

Here is the GTk+ version of our calculator. First, setting up the window and layout:

```ocaml skip
let _ = GtkMain.Main.init ()  (* Initialize GTk+ *)
let window =
  GWindow.window ~width:200 ~height:200 ~title:"Calculator" ()
let top = GPack.vbox ~packing:window#add ()  (* Vertical box container *)
let result = GMisc.label ~text:"0" ~packing:top#add ()  (* Result display *)
let btn_frame =
  GPack.table ~rows:(Array.length layout)
   ~columns:(Array.length layout.(0)) ~packing:top#add ()  (* Button grid *)
```

Creating the buttons and connecting their click handlers to *Froc* events:

```ocaml skip
let buttons =
  Array.map (Array.map (function
    | label, `Dot ->
      let b = GButton.button ~label () in
      let _ = b#connect#clicked
        ~callback:(fun () -> F.send dot ()) in b
    | label, `Di d ->
      let b = GButton.button ~label () in
      let _ = b#connect#clicked
        ~callback:(fun () -> F.send digit d) in b
    | label, `O f ->
      let b = GButton.button ~label () in
      let _ = b#connect#clicked
        ~callback:(fun () -> F.send op f) in b)) layout
```

Finally, we attach buttons to the grid, connect the result notification, and start the application:

```ocaml skip
let delete_event _ = GMain.Main.quit (); false  (* Handle window close *)

let () =
  let _ = window#event#connect#delete ~callback:delete_event in
  Array.iteri (fun column -> Array.iteri (fun row button ->
    btn_frame#attach ~left:column ~top:row
      ~fill:`BOTH ~expand:`BOTH (button#coerce))  (* Attach to grid *)
  ) buttons;
  (* Connect Froc event to update the display *)
  F.notify_e calc_e
    (fun now -> result#set_label (string_of_float now));
  window#show ();  (* Make window visible *)
  GMain.Main.main ()  (* Enter the GTk+ event loop *)
```

### 10.9 Exercises

**Exercise 1:** Introduce operators $-, /$ into the context rewriting "pull out subexpression" example. Remember that they are not commutative.

**Exercise 2:** Add to the *paddle game* example:
1. game restart,
2. score keeping,
3. game quitting (in more-or-less elegant way).

**Exercise 3:** Our numerical integration function roughly corresponds to the rectangle rule. Modify the rule and write a test for the accuracy of:
1. the trapezoidal rule;
2. the Simpson's rule. See http://en.wikipedia.org/wiki/Simpson%27s_rule

**Exercise 4:** Explain the recursive behavior of integration:
1. In *paddle game* implemented by stream processing (`Lec10b.ml`), do we look at past velocity to determine current position, at past position to determine current velocity, both, or neither?
2. What is the difference between `integral` and `integral_nice` in `Lec10c.ml`, what happens when we replace the former with the latter in the `pbal` function? How about after rewriting `pbal` into pure style as in the following exercise?

**Exercise 5:** Reimplement the *Froc* based paddle ball example in a pure style: rewrite the `pbal` function to not use `notify_e`.

**Exercise 6:** Our implementation of flows is a bit heavy. One alternative approach is to use continuations, as in `Scala.React`. OCaml has a continuations library *Delimcc*; for how it can cooperate with *Froc*, see http://ambassadortothecomputers.blogspot.com/2010/08/mixing-monadic-and-direct-style-code.html

**Exercise 7:** Implement `parallel` for flows, retaining coarse-grained implementation and using the event queue from *Froc* somehow (instead of introducing a new job queue).

**Exercise 8:** Add quitting, e.g. via a `'q'` key press, to the *painter* example. Use the `is_cancelled` function.

**Exercise 9:** Our calculator example is not finished. Implement entering decimal fractions: add handling of the `dots` event.

**Exercise 10:** The Flow module has reader monad functions that have not been discussed in this chapter:

```
let local f m = fun emit -> m (fun x -> emit (f x))
let local_opt f m = fun emit ->
  m (fun x -> match f x with None -> () | Some y -> emit y)

val local : ('a -> 'b) -> ('a, 'c) flow -> ('b, 'c) flow
val local_opt : ('a -> 'b option) -> ('a, 'c) flow -> ('b, 'c) flow
```

Implement an example that uses this compositionality-increasing capability.
