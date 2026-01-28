## Chapter 9: Algebraic Effects

![Chapter 9 illustration](Curious_OCaml-chapter_9.jpg){.chapter-image}

**In this chapter, you will:**

- Understand Generalized Algebraic Data Types (GADTs) and how they enable type-refined pattern matching
- Learn about algebraic effects and handlers as a powerful alternative to monads
- Implement lightweight cooperative threads using effects (comparing with the monad-based version)
- Model probabilistic programming with effect handlers
- Build interpreters for probabilistic programs: rejection sampling and particle filtering
- Understand the replay-with-fast-forward pattern for efficient inference
- Use GADTs to build a type-safe probabilistic programming interface

OCaml 5 introduced a game-changing feature: algebraic effects with effect handlers. While monads provide a disciplined way to structure effectful computations, they require threading computations explicitly through bind operations. Algebraic effects offer a different approach: effects can be performed directly, and handlers define how those effects are interpreted.

This chapter explores algebraic effects through two substantial examples. First, we will reimplement the cooperative lightweight threads from the previous chapter, showing how effects simplify the code. Then we will tackle probabilistic programming, building interpreters that can answer questions about probability distributions.

Before diving into effects, we need to understand GADTs -- they are the foundation on which OCaml's effect system is built.

### 9.1 Generalized Algebraic Data Types

Generalized Algebraic Data Types (GADTs) extend ordinary algebraic data types by allowing each constructor to specify a *more precise* return type. Where regular data types have constructors that all produce the same type, GADT constructors can refine the type parameter.

#### Basic GADT Syntax

Consider a simple expression type. With ordinary data types, we cannot distinguish integer expressions from boolean expressions at the type level:

```ocaml skip
type expr =
  | Int of int
  | Bool of bool
  | Add of expr * expr
  | If of expr * expr * expr
```

The `Add` constructor should only work with integer expressions, but the type system cannot enforce this -- we can construct `Add (Bool true, Bool false)` which is nonsensical.

GADTs solve this problem. The syntax uses explicit return type annotations:

```ocaml env=ch9
type _ expr =
  | Int : int -> int expr
  | Bool : bool -> bool expr
  | Add : int expr * int expr -> int expr
  | If : bool expr * 'a expr * 'a expr -> 'a expr
```

Each constructor now specifies its return type after the colon. `Int` constructs an `int expr`, `Bool` constructs a `bool expr`, and `Add` requires two `int expr` arguments and produces an `int expr`. The `If` constructor is polymorphic: it requires a boolean condition and two branches of the same type `'a`, producing an `'a expr`.

Now `Add (Bool true, Bool false)` is a type error -- the type checker rejects it because `Bool true` has type `bool expr`, not `int expr`.

#### Type Refinement in Pattern Matching

The real power of GADTs emerges in pattern matching. When we match on a GADT constructor, the type checker *learns* information about the type parameter:

```ocaml env=ch9
let rec eval : type a. a expr -> a = function
  | Int n -> n          (* Here a = int, so we return int *)
  | Bool b -> b         (* Here a = bool, so we return bool *)
  | Add (e1, e2) -> eval e1 + eval e2   (* Here a = int *)
  | If (cond, then_, else_) ->
      if eval cond then eval then_ else eval else_
```

The annotation `type a. a expr -> a` declares a *locally abstract type* `a`. This tells OCaml that `a` is a type variable that may be refined differently in each branch. In the `Int n` branch, the type checker knows that `a = int` because we matched the `Int` constructor which returns `int expr`. This allows us to return `n` (an `int`) where the return type is `a` -- which in this branch *is* `int`.

Without the locally abstract type annotation, the code would fail to type-check. The annotation is necessary because different branches may assign different concrete types to `a`.

#### Existential Types in GADTs

GADT constructors can introduce *existential* type variables -- types that exist within the constructor but are not exposed in the result type:

```ocaml env=ch9
type printable =
  | Printable : { value : 'a; print : 'a -> string } -> printable
```

The type variable `'a` appears in the arguments but not in the result type `printable`. This means we can pack any value together with a function that knows how to print it:

```ocaml env=ch9
let examples = [
  Printable { value = 42; print = string_of_int };
  Printable { value = "hello"; print = Fun.id };
  Printable { value = [1;2;3]; print = fun l ->
      "[" ^ String.concat "; " (List.map string_of_int l) ^ "]" }
]

let print_all items =
  List.iter (fun (Printable { value; print }) ->
    print_endline (print value)) items

let () = print_all examples
```

Within the pattern match, we can use `print value` because both refer to the same existential type `'a`. But we cannot extract `value` and use it outside the pattern -- its type is unknown.

#### Connection to Type Inference

In [Section 5.3](#type-inference-formally), we presented the formal rules for type constraint generation. The key rule for pattern clauses was:

$$[\![ \Gamma, \Sigma \vdash p.e : \tau_1 \rightarrow \tau_2 ]\!] = [\![ \Sigma \vdash p \downarrow \tau_1 ]\!] \wedge \forall \overline{\beta} . [\![ \Gamma \Gamma' \vdash e : \tau_2 ]\!]$$

where $\exists \overline{\beta} \Gamma'$ is $[\![ \Sigma \vdash p \uparrow \tau_1 ]\!]$, $\overline{\beta} \# \text{FV}(\Gamma, \tau_2)$

For ordinary data types, the constraints derived from patterns are equations. For GADTs, the pattern derivation also produces type equalities $D$, so we have $\exists \overline{\beta} [D] \Gamma'$ from $[\![ \Sigma \vdash p \uparrow \tau_1 ]\!]$, and the constraint becomes an *implication*:

$$[\![ \Gamma, \Sigma \vdash p.e : \tau_1 \rightarrow \tau_2 ]\!] = [\![ \Sigma \vdash p \downarrow \tau_1 ]\!] \wedge \forall \overline{\beta} . D \Rightarrow [\![ \Gamma \Gamma' \vdash e : \tau_2 ]\!]$$

The premise $D$ is the conjunction of type equalities that the GADT constructor establishes. The universal quantification over $\overline{\beta}$ reflects that these equalities hold for *all* values matching the pattern.

For example, when type-checking `eval` and matching the `Int n` case:

- The pattern produces the equality $D = (\text{a} \doteq \text{int})$
- The constraint becomes: $\forall \text{a} . (\text{a} \doteq \text{int}) \Rightarrow [\![ \text{n} : \text{int} \vdash \text{n} : \text{a} ]\!]$
- Under the assumption `a = int`, returning `n : int` satisfies the requirement `result : a`

This is why GADT pattern matching can have different types in different branches -- each branch operates under different type assumptions given by the implication premise. The type checker uses these *local type refinements* to verify that each branch is well-typed.

GADTs also enable the type checker to recognize *impossible* cases. If a function takes `int expr` as input, the `Bool` constructor can never match because `Bool` produces `bool expr`, not `int expr`. The compiler can use this information for exhaustiveness checking.

#### GADTs and Effects

OCaml's effect system uses GADTs in a fundamental way. The type `Effect.t` is defined roughly as:

```ocaml skip
type _ Effect.t = ..
```

This is an *extensible* GADT -- new constructors can be added anywhere in the program. The type parameter indicates what type of value the effect produces when handled:

```ocaml skip
type _ Effect.t +=
  | Get : int Effect.t           (* Returns an int *)
  | Put : int -> unit Effect.t   (* Takes an int, returns unit *)
```

When handling effects, the continuation's type is refined based on which effect was performed:

```ocaml skip
match f () with
| result -> result
| effect Get, k -> Effect.Deep.continue k 42
    (* k : (int, 'a) continuation because Get : int Effect.t *)
| effect (Put n), k -> Effect.Deep.continue k ()
    (* k : (unit, 'a) continuation because Put : unit Effect.t *)
```

The GADT structure ensures type safety: you cannot `continue k "hello"` when handling `Get` because the continuation expects an `int`. This type safety is crucial for building reliable effect handlers.

With this foundation, we can now explore how effects provide an elegant alternative to monads.

### 9.2 From Monads to Effects

In the previous chapter, we saw how monads structure effectful computations. Every monadic operation had to be sequenced with `let*`:

```ocaml skip
let rec loop s n =
  let* () = return (Printf.printf "-- %s(%d)\n%!" s n) in
  let* () = yield in  (* yielding could be implicit in the monad's bind *)
  if n > 0 then loop s (n-1)
  else return ()
```

This works, but it is infectious: once you are inside a monad, everything must be monadic. You cannot simply call a regular function that might perform effects -- you must lift it into the monad. Even a simple `Printf.printf` must be wrapped in `return`.

Algebraic effects take a different approach. Effects are *performed* as regular function calls, and *handled* at a distance:

```ocaml skip
let rec loop s n =
  Printf.printf "-- %s(%d)\n%!" s n;
  yield ();  (* explicit effect, but looks like a normal call *)
  if n > 0 then loop s (n-1)
```

The key difference is not that effects happen implicitly -- you still call `yield ()` explicitly at suspension points. The difference is that:

1. **Direct style**: Effects look like ordinary function calls, not monadic binds
2. **Non-infectious**: Code that does not perform effects (like `Printf.printf`) remains unchanged
3. **Separation of concerns**: The program says *what* effects occur; the handler decides *how* to interpret them

#### A First Example

Before diving into the full API, let us see the simplest possible effect: one that asks for an integer value.

```ocaml env=ch9
type _ Effect.t += Ask : int Effect.t

let ask () = Effect.perform Ask

let program () =
  let x = ask () in
  x + 1

let answer_42 () =
  try program () with
  | effect Ask, k -> Effect.Deep.continue k 42

let () = assert (answer_42 () = 43)
```

The `try ... with | effect Ask, k -> ...` syntax handles effects similarly to how `try ... with` handles exceptions. When the `Ask` effect is performed, the pattern `effect Ask, k` matches. The variable `k` is the *continuation*: it represents "the rest of the computation" from the point where the effect was performed. By calling `Effect.Deep.continue k 42`, we resume the computation with `42` as the result of `ask ()`.

#### Declaring Effects

Effects are declared by extending the built-in extensible GADT `Effect.t`. The type parameter indicates what the effect returns:

```ocaml env=ch9
type _ Effect.t += Yield : unit Effect.t
```

This declares a `Yield` effect that returns `unit`. The `type _ Effect.t +=` syntax is similar to how exceptions extend the `exn` type.

Effects can carry data and return values:

```ocaml env=ch9
type _ Effect.t += Get : int Effect.t
type _ Effect.t += Put : int -> unit Effect.t
```

Here `Get` is an effect that returns an `int`, and `Put` takes an `int` argument and returns `unit`.

#### Performing Effects

To perform an effect, we use `Effect.perform`:

```ocaml env=ch9
let yield () = Effect.perform Yield
let get () = Effect.perform Get
let put n = Effect.perform (Put n)
```

When `Effect.perform` is called, control transfers to the nearest enclosing handler for that effect. If no handler exists, OCaml raises `Effect.Unhandled`.

**Note:** The effect system API is marked as unstable in OCaml 5.x and may change in future versions. Effects can only be performed synchronously -- not from signal handlers, finalisers, or C callbacks.

#### Handling Effects

OCaml 5.3+ provides a convenient syntax for handling effects. The simplest form uses `try ... with` when you just want to return the result unchanged. When you need to transform the result, and especially if you want to pattern match on it, `match ... with` is more elegant.

```ocaml env=ch9
let () =
  let state = ref 0 in
  let result =
    try put 10; get () + get () with
    | effect Get, k -> Effect.Deep.continue k !state
    | effect (Put n), k -> state := n; Effect.Deep.continue k ()
  in
  assert (result = 20)
```

The `effect E, k` pattern matches when effect `E` is performed. The continuation `k` captures everything that would happen after `Effect.perform` returns. We can:

- **Continue** by calling `Effect.Deep.continue k value`, where `value` becomes the return value of `perform`
- **Discontinue** by calling `Effect.Deep.discontinue k exn`, raising an exception at the effect site
- **Store** the continuation and resume it later (useful for schedulers)

**Important:** OCaml continuations are *one-shot* -- each continuation must be resumed exactly once with `continue` or `discontinue`. Attempting to resume a continuation twice raises `Effect.Continuation_already_resumed`. Not resuming a continuation might work in specific cases but risks leaking resources (e.g. open files).

The three kinds of patterns in a handler correspond to three cases:

- Regular patterns handle normal return values
- `exception` patterns handle raised exceptions
- `effect` patterns handle performed effects

This mirrors the explicit handler record form `{ retc; exnc; effc }` used by `Effect.Deep.match_with`.

#### Deep vs Shallow Handlers

OCaml provides two kinds of handlers in `Effect.Deep` and `Effect.Shallow`:

- **Deep handlers** (which we use throughout this chapter) automatically re-install themselves when you continue a computation. Effects performed after resumption are handled by the same handler.

- **Shallow handlers** handle only the first effect encountered. After continuing, subsequent effects are not automatically handled. This gives more control but requires more explicit management.

For most use cases, deep handlers are simpler and sufficient. We will use `Effect.Deep` exclusively in this chapter.

This ability to capture and manipulate continuations is what makes algebraic effects so powerful. Let us see this in action.

### 9.3 Lightweight Threads with Effects

In the previous chapter, we implemented cooperative threads using a monad. The implementation involved mutable state to track thread status, a work queue, and careful management of continuations encoded as closures. With effects, we can write a much simpler implementation.

#### The Thread Interface

Our goal is to support concurrent computations that can yield control to other threads and eventually produce results. Here is a simple interface:

```ocaml env=ch9
module type THREADS = sig
  type 'a promise
  val async : (unit -> 'a) -> 'a promise  (* Start a new thread *)
  val await : 'a promise -> 'a            (* Wait for a thread to complete *)
  val yield : unit -> unit                (* Yield control to other threads *)
  val run : (unit -> 'a) -> 'a            (* Run the scheduler *)
end
```

A *promise* represents a computation that will eventually produce a value. We can start new threads with `async`, wait for their results with `await`, and voluntarily give up control with `yield`.

#### Declaring the Effects

We need three effects:

```ocaml env=ch9
type 'a promise_state =
  | Pending of ('a, unit) Effect.Deep.continuation list  (* Waiting continuations *)
  | Done of 'a                                           (* Completed with value *)

type 'a promise = 'a promise_state ref

type _ Effect.t +=
  | Async : (unit -> 'a) -> 'a promise Effect.t  (* Fork a new thread *)
  | Await : 'a promise -> 'a Effect.t            (* Wait for completion *)
  | TYield : unit Effect.t                       (* Give up control *)
```

The `Async` effect carries a thunk and returns a promise. The `Await` effect takes a promise and returns its value (potentially blocking). The `TYield` effect temporarily suspends the current thread.

A promise is a mutable reference that starts as `Pending` (with a list of continuations waiting for the result) and becomes `Done` once the computation completes.

#### The Scheduler

The scheduler maintains a queue of ready threads (continuations waiting to run):

```ocaml env=ch9
module Threads : THREADS = struct
  type 'a promise_state =
    | Pending of ('a, unit) Effect.Deep.continuation list
    | Done of 'a
  type 'a promise = 'a promise_state ref

  type _ Effect.t +=
    | Async : (unit -> 'a) -> 'a promise Effect.t
    | Await : 'a promise -> 'a Effect.t
    | TYield : unit Effect.t

  let async f = Effect.perform (Async f)
  let await p = Effect.perform (Await p)
  let yield () = Effect.perform TYield

  let run_queue : (unit -> unit) Queue.t = Queue.create ()
  let enqueue f = Queue.push f run_queue
  let dequeue () = if Queue.is_empty run_queue then () else Queue.pop run_queue ()

  let fulfill p v =
    match !p with
    | Done _ -> failwith "Promise already fulfilled"
    | Pending waiters ->
        p := Done v;
        List.iter (fun k -> enqueue (fun () -> Effect.Deep.continue k v)) waiters

  let rec run_thread : 'a. (unit -> 'a) -> 'a promise = fun f ->
    let p = ref (Pending []) in
    let () = match f () with
      | v -> fulfill p v; dequeue ()
      | effect (Async g), k ->
          let p' = run_thread g in
          Effect.Deep.continue k p'
      | effect (Await p'), k ->
          (match !p' with
           | Done v -> Effect.Deep.continue k v
           | Pending ks -> p' := Pending (k :: ks); dequeue ())
      | effect TYield, k ->
          enqueue (fun () -> Effect.Deep.continue k ());
          dequeue ()
    in p

  let run f =
    Queue.clear run_queue;
    let p = run_thread f in
    while not (Queue.is_empty run_queue) do dequeue () done;
    match !p with
    | Done v -> v
    | Pending _ -> failwith "Main thread did not complete"
end
```

Let us understand how each effect is handled:

**Async**: When a thread calls `async g`, we start a new thread running `g` by calling `run_thread g`. This returns a promise immediately, which we pass back to the parent thread by continuing its continuation.

**Await**: When a thread calls `await p`, we check the promise. If it is already `Done`, we continue immediately with the value. If it is `Pending`, we add the current continuation to the list of waiters and run another thread from the queue.

**TYield**: When a thread calls `yield ()`, we add the current continuation to the back of the queue and run the next thread. This implements round-robin scheduling.

#### Testing the Implementation

Let us test with a simple example:

```ocaml env=ch9
let test_threads () =
  let open Threads in
  run (fun () ->
    let rec loop s n =
      Printf.printf "-- %s(%d)\n%!" s n;
      yield ();
      if n > 0 then loop s (n-1) in
    let p1 = async (fun () -> loop "A" 3) in
    let p2 = async (fun () -> loop "B" 2) in
    await p1;
    await p2;
    Printf.printf "Done!\n%!")

let () = test_threads ()
```

This creates two threads that print messages and yield control. The output shows interleaving:

```
-- A(3)
-- B(2)
-- A(2)
-- B(1)
-- A(1)
-- B(0)
-- A(0)
Done!
```

Compare this to the monadic version from the previous chapter. The code is more direct: we write `yield ()` instead of `let* () = suspend in`, and `Printf.printf` is just a regular function call. The complexity of managing thread state has moved from the user code into the handler.

### 9.4 State with Effects

Before diving into probabilistic programming, let us see how to implement mutable state using effects. This demonstrates another common pattern.

```ocaml env=ch9
module State = struct
  type _ Effect.t +=
    | SGet : int Effect.t
    | SPut : int -> unit Effect.t

  let get () = Effect.perform SGet
  let put n = Effect.perform (SPut n)

  let run : type a. int -> (unit -> a) -> a = fun init f ->
    let state = ref init in
    try f () with
    | effect SGet, k -> Effect.Deep.continue k !state
    | effect (SPut n), k -> state := n; Effect.Deep.continue k ()
end
```

Now we can write stateful computations:

```ocaml env=ch9
let counter () =
  let open State in
  for _ = 1 to 5 do
    put (get () + 1)
  done;
  get ()

let result = State.run 0 counter  (* result = 5 *)
let () = Printf.printf "Counter result: %d\n" result
```

The key insight is that effects let us *separate the description of what effects occur* from *how those effects are implemented*. The `counter` function describes a computation that gets and puts state. The `State.run` handler interprets those effects using a mutable reference.

### 9.5 Probabilistic Programming with Effects

Now we are ready to tackle something more ambitious: probabilistic programming. In the previous chapter, we implemented probability monads that could compute exact distributions or approximate them via sampling. Effect handlers give us a different, more flexible approach.

#### The Key Idea

A probabilistic program is a program with random choices. Instead of thinking about distributions as data, we think about *sampling* and *conditioning*:

- **Sample**: Draw a value from a probability distribution
- **Observe/Condition**: Assert that a certain event occurred, affecting the posterior probability

Effect handlers let us *reify* these operations. When a program performs a `Sample` effect, the handler can decide: "run this with value X and probability P". When a program performs an `Observe` effect, the handler can adjust weights or reject samples that do not match the observation.

#### Declaring Probability Effects

```ocaml env=ch9
type _ Effect.t +=
  | Sample : (string * float array) -> int Effect.t  (* name, weights -> index *)
  | Observe : float -> unit Effect.t                 (* observe with likelihood *)
  | Fail : 'a Effect.t                               (* reject this execution *)
```

`Sample` takes a name (for debugging) and an array of weights, returning the index of the chosen alternative. `Observe` records a likelihood weight. `Fail` indicates this execution path should be abandoned.

```ocaml env=ch9
let sample name weights = Effect.perform (Sample (name, weights))
let observe likelihood = Effect.perform (Observe likelihood)
let fail () = Effect.perform Fail
```

We can build familiar probabilistic primitives:

```ocaml env=ch9
let flip p =
  let i = sample "flip" [| p; 1.0 -. p |] in
  i = 0

let uniform choices =
  let n = Array.length choices in
  let weights = Array.make n (1.0 /. float_of_int n) in
  let i = sample "uniform" weights in
  choices.(i)

let bernoulli p = flip p

let categorical weights =
  let total = Array.fold_left (+.) 0.0 weights in
  let normalized = Array.map (fun w -> w /. total) weights in
  sample "categorical" normalized
```

#### Example: Monty Hall

Let us encode the Monty Hall problem:

```ocaml env=ch9
type door = A | B | C

let monty_hall ~switch =
  let doors = [| A; B; C |] in
  let prize = uniform doors in
  let chosen = uniform doors in
  (* Host opens a door that is neither prize nor chosen *)
  let can_open =
    doors
    |> Array.to_list
    |> List.filter (fun d -> d <> prize && d <> chosen)
    |> Array.of_list
  in
  let opened = uniform can_open in
  (* Player's final choice *)
  let final =
    if switch then
      (* Switch to the remaining door *)
      List.hd (List.filter (fun d -> d <> opened && d <> chosen) [A; B; C])
    else chosen in
  final = prize
```

This is cleaner than the monadic version: we just write the generative model directly. The `uniform` calls represent random choices, and we return whether the player wins.

#### Example: Burglary Network

Here is the Bayesian network example from the previous chapter:

```ocaml env=ch9
type outcome = Safe | Burglary | Earthquake | Both

let burglary ~john_called ~mary_called =
  let earthquake = flip 0.002 in
  let burglary = flip 0.001 in
  let alarm_prob = match burglary, earthquake with
    | false, false -> 0.001
    | false, true -> 0.29
    | true, false -> 0.94
    | true, true -> 0.95 in
  let alarm = flip alarm_prob in
  let john_prob = if alarm then 0.9 else 0.05 in
  let mary_prob = if alarm then 0.7 else 0.01 in
  (* Condition on observations *)
  if flip john_prob <> john_called then fail ();
  if flip mary_prob <> mary_called then fail ();
  (* Return the outcome *)
  match burglary, earthquake with
  | false, false -> Safe
  | true, false -> Burglary
  | false, true -> Earthquake
  | true, true -> Both
```

The key difference from the monad version: we use `fail ()` to reject executions that do not match our observations. This is *rejection sampling*: we run the program many times and keep only the runs where the observations match.

### 9.6 Rejection Sampling Interpreter

Our first interpreter uses rejection sampling: run the probabilistic program many times, rejecting executions that fail, and collect statistics on the successful runs.

```ocaml env=ch9
module Rejection = struct
  exception Rejected

  let sample_index weights =
    let total = Array.fold_left (+.) 0.0 weights in
    let r = Random.float total in
    let rec find i acc =
      if i >= Array.length weights then Array.length weights - 1
      else
        let acc' = acc +. weights.(i) in
        if r < acc' then i else find (i + 1) acc'
    in
    find 0 0.0

  let run_once : type a. (unit -> a) -> a option = fun f ->
    match f () with
    | result -> Some result
    | effect (Sample (_, weights)), k ->
        Effect.Deep.continue k (sample_index weights)
    | effect (Observe w), k ->
        if Random.float 1.0 < w
        then Effect.Deep.continue k ()
        else Effect.Deep.discontinue k Rejected
    | effect Fail, k -> Effect.Deep.discontinue k Rejected
    | exception Rejected -> None

  let infer ?(samples=10000) f =
    let results = Hashtbl.create 16 in
    let successes = ref 0 in
    for _ = 1 to samples do
      match run_once f with
      | None -> ()
      | Some v ->
          incr successes;
          let count = try Hashtbl.find results v with Not_found -> 0 in
          Hashtbl.replace results v (count + 1)
    done;
    let n = float_of_int !successes in
    if n > 0.0 then
      Hashtbl.fold (fun v c acc ->
        (v, float_of_int c /. n) :: acc) results []
      |> List.sort (fun (_, p1) (_, p2) -> compare p2 p1)
    else []
end
```

Let us test it:

```ocaml env=ch9
let () =
  Printf.printf "\n=== Rejection Sampling Tests ===\n";
  Printf.printf "Monty Hall (no switch): ";
  let dist = Rejection.infer (fun () -> monty_hall ~switch:false) in
  List.iter (fun (win, p) ->
    Printf.printf "%s: %.3f  " (if win then "win" else "lose") p) dist;
  print_newline ()

let () =
  Printf.printf "Monty Hall (switch): ";
  let dist = Rejection.infer (fun () -> monty_hall ~switch:true) in
  List.iter (fun (win, p) ->
    Printf.printf "%s: %.3f  " (if win then "win" else "lose") p) dist;
  print_newline ()
```

The famous result: switching doubles your chances of winning!

#### Limitations of Rejection Sampling

Rejection sampling is simple but has a major limitation: if the observations are unlikely, most samples are rejected, making inference very slow. For example, if we observe both John and Mary called (a rare event), rejection sampling needs many attempts to find a valid sample:

```ocaml env=ch9
let () =
  Printf.printf "Burglary (john=true, mary=true):\n";
  let dist = Rejection.infer ~samples:100000 (fun () ->
    burglary ~john_called:true ~mary_called:true) in
  List.iter (fun (outcome, p) ->
    let s = match outcome with
      | Safe -> "Safe" | Burglary -> "Burglary"
      | Earthquake -> "Earthquake" | Both -> "Both" in
    Printf.printf "  %s: %.4f\n" s p) dist
```

With rare observations, we need many more samples to get accurate estimates. This is where more sophisticated inference methods help.

### 9.7 Importance Sampling

Rejection sampling throws away information: every rejected sample is wasted computation. *Importance sampling* does better by keeping track of weights. Instead of rejecting unlikely executions, we weight them by their likelihood.

The idea is simple: run particles and track a weight for each. When an observation occurs, multiply the particle's weight by the likelihood instead of rejecting.

```ocaml env=ch9
module Importance = struct
  exception HardFail

  let sample_index weights =
    let total = Array.fold_left (+.) 0.0 weights in
    let r = Random.float total in
    let rec find i acc =
      if i >= Array.length weights then Array.length weights - 1
      else if r < acc +. weights.(i) then i
      else find (i + 1) (acc +. weights.(i)) in
    find 0 0.0

  let run_once : type a. (unit -> a) -> (a * float) option = fun f ->
    let weight = ref 1.0 in
    match f () with
    | result -> Some (result, !weight)
    | effect (Sample (_, weights)), k ->
        Effect.Deep.continue k (sample_index weights)
    | effect (Observe likelihood), k ->
        weight := !weight *. likelihood;
        Effect.Deep.continue k ()
    | effect Fail, k -> Effect.Deep.discontinue k HardFail
    | exception HardFail -> None

  let infer ?(samples=10000) f =
    let results = Hashtbl.create 16 in
    let total_weight = ref 0.0 in
    for _ = 1 to samples do
      match run_once f with
      | None -> ()
      | Some (v, w) ->
          total_weight := !total_weight +. w;
          let prev = try Hashtbl.find results v with Not_found -> 0.0 in
          Hashtbl.replace results v (prev +. w)
    done;
    if !total_weight > 0.0 then
      Hashtbl.fold (fun v w acc -> (v, w /. !total_weight) :: acc) results []
      |> List.sort (fun (_, p1) (_, p2) -> compare p2 p1)
    else []
end
```

### 9.8 Soft Conditioning with Observe

So far our burglary example uses hard conditioning with `fail ()`. Let us rewrite it to use soft conditioning with `observe`:

```ocaml env=ch9
let burglary_soft ~john_called ~mary_called =
  let earthquake = flip 0.002 in
  let burglary = flip 0.001 in
  let alarm_prob = match burglary, earthquake with
    | false, false -> 0.001
    | false, true -> 0.29
    | true, false -> 0.94
    | true, true -> 0.95 in
  let alarm = flip alarm_prob in
  (* Soft conditioning: observe the likelihood of the evidence *)
  let john_prob = if alarm then 0.9 else 0.05 in
  let mary_prob = if alarm then 0.7 else 0.01 in
  let john_like = if john_called then john_prob else 1.0 -. john_prob in
  let mary_like = if mary_called then mary_prob else 1.0 -. mary_prob in
  observe john_like;
  observe mary_like;
  (* Return the outcome *)
  match burglary, earthquake with
  | false, false -> Safe
  | true, false -> Burglary
  | false, true -> Earthquake
  | true, true -> Both

let () =
  Printf.printf "\n=== Importance Sampling Tests ===\n";
  Printf.printf "Burglary soft (john=true, mary=true):\n";
  let dist = Importance.infer ~samples:50000 (fun () ->
    burglary_soft ~john_called:true ~mary_called:true) in
  List.iter (fun (outcome, p) ->
    let s = match outcome with
      | Safe -> "Safe" | Burglary -> "Burglary"
      | Earthquake -> "Earthquake" | Both -> "Both" in
    Printf.printf "  %s: %.4f\n" s p) dist
```

The soft conditioning version is more efficient because every particle contributes to the estimate, weighted by how well it matches the observations.

### 9.9 Particle Filter with Replay

For models where observations occur at multiple points during execution, we can do even better with *particle filtering*. The key idea is to run multiple particles in parallel, periodically *resampling* to focus computation on high-weight particles.

The challenge is that OCaml's continuations are one-shot, so we cannot simply "clone" a particle. Instead, we use **replay-based inference**: store the sequence of sampling choices (a *trace*), and when we need to continue a particle, re-run the program from the beginning but fast-forward through already-recorded choices. Each `Sample` effect serves as a natural synchronization point.

```ocaml env=ch9
module ParticleFilter = struct
  type trace = int list
  exception HardFail

  (* Result of running one step *)
  type 'a step =
    | Done of 'a * trace * float   (* completed with result, trace, weight *)
    | Paused of trace * float      (* paused at Sample with trace, weight *)
    | Failed                       (* hard failure *)

  let sample_index weights =
    let total = Array.fold_left (+.) 0.0 weights in
    let r = Random.float total in
    let rec find i acc =
      if i >= Array.length weights then Array.length weights - 1
      else if r < acc +. weights.(i) then i
      else find (i + 1) (acc +. weights.(i)) in
    find 0 0.0

  (* Run until the next fresh Sample, replaying recorded choices *)
  let run_one_step : type a. (unit -> a) -> trace -> a step = fun f trace ->
    let remaining = ref trace in
    let recorded = ref [] in
    let weight = ref 1.0 in
    match f () with
    | result -> Done (result, List.rev !recorded, !weight)
    | effect (Sample (_, weights)), k ->
        (match !remaining with
         | choice :: rest ->
             (* Replay: use recorded choice *)
             remaining := rest;
             recorded := choice :: !recorded;
             Effect.Deep.continue k choice
         | [] ->
             (* Fresh sample: make choice and pause *)
             let choice = sample_index weights in
             recorded := choice :: !recorded;
             Paused (List.rev !recorded, !weight))
    | effect (Observe likelihood), k ->
        weight := !weight *. likelihood;
        Effect.Deep.continue k ()
    | effect Fail, k -> Effect.Deep.discontinue k HardFail
    | exception HardFail -> Failed

  (* Resample: select n indices according to weights *)
  let resample_indices n weights =
    let total = Array.fold_left (+.) 0.0 weights in
    if total <= 0.0 then Array.init n (fun i -> i mod n)
    else begin
      let cumulative = Array.make n 0.0 in
      let acc = ref 0.0 in
      Array.iteri (fun i w ->
        acc := !acc +. w /. total;
        cumulative.(i) <- !acc) weights;
      Array.init n (fun _ ->
        let r = Random.float 1.0 in
        let rec find i =
          if i >= n - 1 || cumulative.(i) >= r then i
          else find (i + 1) in
        find 0)
    end

  (* Effective sample size relative to n (returns value in [0, 1]) *)
  let effective_sample_size weights =
    let n = float_of_int (Array.length weights) in
    let total = Array.fold_left (+.) 0.0 weights in
    if total <= 0.0 then 0.0
    else begin
      let sum_sq = Array.fold_left (fun acc w ->
        let nw = w /. total in acc +. nw *. nw) 0.0 weights in
      1.0 /. sum_sq /. n
    end

  let infer ?(n=1000) ?(resample_threshold=0.5) f =
    (* Each particle: trace, weight *)
    let traces = Array.make n [] in
    let weights = Array.make n 1.0 in
    let active = Array.make n true in
    let final_results = ref [] in
    let n_active = ref n in

    while !n_active > 0 do
      (* Advance each active particle by one Sample *)
      for i = 0 to n - 1 do
        if active.(i) then
          match run_one_step f traces.(i) with
          | Done (result, trace, w) ->
              final_results := (result, weights.(i) *. w) :: !final_results;
              active.(i) <- false;
              decr n_active
          | Paused (trace, w) ->
              traces.(i) <- trace;
              weights.(i) <- weights.(i) *. w
          | Failed ->
              active.(i) <- false;
              decr n_active
      done;

      (* Resample if ESS is low and there are still active particles *)
      if !n_active > 0 then begin
        let active_weights = Array.of_list (
          Array.to_list weights |> List.filteri (fun i _ -> active.(i))) in
        if effective_sample_size active_weights < resample_threshold then begin
          let active_indices = Array.of_list (
            List.init n (fun i -> i) |> List.filter (fun i -> active.(i))) in
          let active_n = Array.length active_indices in
          let indices = resample_indices active_n active_weights in
          let new_traces = Array.map (fun j ->
            traces.(active_indices.(j))) indices in
          let new_weight = 1.0 /. float_of_int active_n in
          Array.iteri (fun j _ ->
            traces.(active_indices.(j)) <- new_traces.(j);
            weights.(active_indices.(j)) <- new_weight) indices
        end
      end
    done;

    (* Aggregate results *)
    let combined = Hashtbl.create 16 in
    let total = ref 0.0 in
    List.iter (fun (v, w) ->
      total := !total +. w;
      let prev = try Hashtbl.find combined v with Not_found -> 0.0 in
      Hashtbl.replace combined v (prev +. w)) !final_results;
    if !total > 0.0 then
      Hashtbl.fold (fun v w acc -> (v, w /. !total) :: acc) combined []
      |> List.sort (fun (_, p1) (_, p2) -> compare p2 p1)
    else []
end
```

The particle filter works by:

1. **Initialization**: Start n particles with empty traces and equal weights
2. **Extension**: Advance each particle to the next `Sample`. During replay, recorded choices are reused; at a fresh `Sample`, we make a new choice and pause
3. **Weight accumulation**: `Observe` effects multiply the particle's weight
4. **Resampling**: If the effective sample size drops below the threshold, resample traces proportional to weights
5. **Completion**: When a particle finishes, record its result weighted by its final weight

Let us test the particle filter:

```ocaml env=ch9
let () =
  Printf.printf "\n=== Particle Filter Tests ===\n";
  Printf.printf "Monty Hall (no switch): ";
  let dist = ParticleFilter.infer ~n:5000 (fun () -> monty_hall ~switch:false) in
  List.iter (fun (win, p) ->
    Printf.printf "%s: %.3f  " (if win then "win" else "lose") p) dist;
  print_newline ()

let () =
  Printf.printf "Monty Hall (switch): ";
  let dist = ParticleFilter.infer ~n:5000 (fun () -> monty_hall ~switch:true) in
  List.iter (fun (win, p) ->
    Printf.printf "%s: %.3f  " (if win then "win" else "lose") p) dist;
  print_newline ()

let () =
  Printf.printf "Burglary soft (particle filter):\n";
  let dist = ParticleFilter.infer ~n:10000 (fun () ->
    burglary_soft ~john_called:true ~mary_called:true) in
  List.iter (fun (outcome, p) ->
    let s = match outcome with
      | Safe -> "Safe" | Burglary -> "Burglary"
      | Earthquake -> "Earthquake" | Both -> "Both" in
    Printf.printf "  %s: %.4f\n" s p) dist
```

### 9.10 Comparing Inference Methods

We have seen three approaches to probabilistic inference:

| Method | Pros | Cons |
|--------|------|------|
| Rejection Sampling | Simple, exact for accepted samples | Wasteful when observations are rare |
| Importance Sampling | Uses all samples | Can suffer from weight degeneracy |
| Particle Filtering | Adaptive resampling | More complex, replay overhead |

The effect-based approach has a key advantage: the *same probabilistic program* can be interpreted by different handlers. We write `monty_hall` once and run it with any inference engine.

```ocaml env=ch9
let () =
  Printf.printf "\n=== Comparison ===\n";
  let test name infer =
    let dist = infer (fun () -> monty_hall ~switch:true) in
    let win_prob = try List.assoc true dist with Not_found -> 0.0 in
    Printf.printf "%s: P(win|switch) = %.4f\n" name win_prob
  in
  test "Rejection" (Rejection.infer ~samples:10000);
  test "Importance" (Importance.infer ~samples:10000);
  test "Particle Filter" (ParticleFilter.infer ~n:5000)
```

### 9.11 Summary

Algebraic effects provide a powerful alternative to monads for structuring effectful computations:

1. **Separation of concerns**: Effect declarations specify *what* effects can occur. Handlers specify *how* effects are interpreted.

2. **Direct style**: Code performing effects looks like ordinary code. No `let*` or bind operators needed.

3. **Flexibility**: The same effectful code can be interpreted different ways by different handlers.

4. **Continuations**: Handlers receive continuations, enabling sophisticated control flow patterns like coroutines and particle filtering.

We saw two substantial applications:

- **Lightweight threads**: Effects make cooperative concurrency straightforward. The `Yield`, `Async`, and `Await` effects are handled by a scheduler that manages continuations.

- **Probabilistic programming**: `Sample`, `Observe`, and `Fail` effects describe probabilistic models. Different handlers implement different inference strategies.

The key insight is that effects are a *programming interface* that can have multiple *implementations*. This makes code more modular and reusable.

### 9.12 A Typed Sampling Interface with GADTs

In Section 9.5, we defined probabilistic effects using indices into arrays:

```ocaml skip
type _ Effect.t +=
  | Sample : (string * float array) -> int Effect.t  (* returns index *)
```

This works but is somewhat awkward: `flip` returns an integer 0 or 1 that we then compare to 0, and `uniform` selects from an array by index. Can we define a more direct `Choose : 'a list -> 'a Effect.t` effect that returns elements directly?

The worry is easy to overstate:

- Defining `Choose : 'a list -> 'a Effect.t` is *not* a type-system problem: `Effect.t` is already an extensible GADT, so each effect constructor can refine the return type, and the handler case `effect (Choose xs), k -> ...` is type-checked using the same GADT mechanism as any other GADT match.
- What *can* become problematic is **replay traces**: if we tried to store the *chosen values* (of many different types) in a single list, we would need some form of dynamic typing.

For replay-based inference, we can avoid that entirely: we store a trace of **type-agnostic random choices** (indices for `Choose`, floats for `Gaussian`). The program remains fully typed, and replay is straightforward: we use the stored index to select from the list passed to `Choose`.

#### A GADT-Typed Sampling API

```ocaml env=ch9
module GProb = struct
  type _ Effect.t +=
    | Choose : 'a list -> 'a Effect.t
    | Gaussian : float * float -> float Effect.t
    | GObserve : float -> unit Effect.t
    | GFail : 'a Effect.t

  let choose xs =
    match xs with
    | [] -> invalid_arg "choose: empty list"
    | _ -> Effect.perform (Choose xs)

  let gaussian ~mu ~sigma =
    if sigma <= 0.0 then invalid_arg "gaussian: sigma must be positive";
    Effect.perform (Gaussian (mu, sigma))

  let observe w =
    if w < 0.0 then invalid_arg "observe: weight must be nonnegative";
    Effect.perform (GObserve w)

  let fail () = Effect.perform GFail

  let pi = 4.0 *. atan 1.0

  let normal_pdf x ~mu ~sigma =
    let z = (x -. mu) /. sigma in
    (1.0 /. (sigma *. sqrt (2.0 *. pi))) *. exp (-0.5 *. z *. z)

  let sample_gaussian ~mu ~sigma =
    (* Box-Muller transform *)
    let u1 = max 1e-12 (Random.float 1.0) in
    let u2 = Random.float 1.0 in
    let r = sqrt (-2.0 *. log u1) in
    let theta = 2.0 *. pi *. u2 in
    mu +. sigma *. (r *. cos theta)
end
```

The `Choose` effect is polymorphic: `Choose : 'a list -> 'a Effect.t`. When we perform `Choose ["heads"; "tails"]`, the result type is `string`. When we perform `Choose [1; 2; 3; 4; 5; 6]`, the result type is `int`. The GADT ensures type safety at each use site.

The `Gaussian` effect samples from a normal distribution using the Box-Muller transform.

#### Importance Sampling for Choose + Gaussian

```ocaml env=ch9
module GImportance = struct
  exception HardFail

  let run_once : type a. (unit -> a) -> (a * float) option = fun f ->
    let weight = ref 1.0 in
    match f () with
    | result -> Some (result, !weight)
    | effect (GProb.Choose xs), k ->
        let i = Random.int (List.length xs) in
        Effect.Deep.continue k (List.nth xs i)
    | effect (GProb.Gaussian (mu, sigma)), k ->
        Effect.Deep.continue k (GProb.sample_gaussian ~mu ~sigma)
    | effect (GProb.GObserve w), k ->
        weight := !weight *. w;
        Effect.Deep.continue k ()
    | effect GProb.GFail, k -> Effect.Deep.discontinue k HardFail
    | exception HardFail -> None

  let infer ?(samples=10000) f =
    let results = Hashtbl.create 16 in
    let total_weight = ref 0.0 in
    for _ = 1 to samples do
      match run_once f with
      | None -> ()
      | Some (v, w) ->
          total_weight := !total_weight +. w;
          let prev = try Hashtbl.find results v with Not_found -> 0.0 in
          Hashtbl.replace results v (prev +. w)
    done;
    if !total_weight > 0.0 then
      Hashtbl.fold (fun v w acc -> (v, w /. !total_weight) :: acc) results []
      |> List.sort (fun (_, p1) (_, p2) -> compare p2 p1)
    else []
end
```

The handler matches `Choose xs` and samples uniformly, returning the actual value. The GADT ensures that `List.nth xs i` has type `'a` and that `continue k (List.nth xs i)` is well-typed because `k` expects type `'a`.

#### Particle Filtering with Replay for Choose + Gaussian

The key insight for replay is simple: we store only **type-agnostic random draws** -- an index for discrete choices, a float for Gaussian samples. During replay, we use the stored index to select from the list that's passed to `Choose`:

```ocaml env=ch9
module GParticleFilter = struct
  exception HardFail

  type draw =
    | DChoose of int      (* index into the list *)
    | DGaussian of float  (* sampled value *)

  type trace = draw list

  type 'a step =
    | Done of 'a * trace * float
    | Paused of trace * float
    | Failed

  let run_one_step : type a. (unit -> a) -> trace -> a step = fun f trace ->
    let remaining = ref trace in
    let recorded = ref [] in
    let weight = ref 1.0 in
    match f () with
    | result -> Done (result, List.rev !recorded, !weight)
    | effect (GProb.Choose xs), k ->
        (match !remaining with
         | DChoose i :: rest ->
             (* Replay: use recorded index to select from list *)
             remaining := rest;
             recorded := DChoose i :: !recorded;
             Effect.Deep.continue k (List.nth xs i)
         | [] ->
             (* Fresh sample: choose index and pause *)
             let i = Random.int (List.length xs) in
             recorded := DChoose i :: !recorded;
             Paused (List.rev !recorded, !weight)
         | _ :: _ ->
             (* Trace mismatch *)
             Effect.Deep.discontinue k HardFail)
    | effect (GProb.Gaussian (mu, sigma)), k ->
        (match !remaining with
         | DGaussian x :: rest ->
             (* Replay: use recorded Gaussian sample *)
             remaining := rest;
             recorded := DGaussian x :: !recorded;
             Effect.Deep.continue k x
         | [] ->
             (* Fresh Gaussian sample *)
             let x = GProb.sample_gaussian ~mu ~sigma in
             recorded := DGaussian x :: !recorded;
             Paused (List.rev !recorded, !weight)
         | _ :: _ ->
             Effect.Deep.discontinue k HardFail)
    | effect (GProb.GObserve w), k ->
        weight := !weight *. w;
        Effect.Deep.continue k ()
    | effect GProb.GFail, k -> Effect.Deep.discontinue k HardFail
    | exception HardFail -> Failed

  let resample_indices n weights =
    let total = Array.fold_left (+.) 0.0 weights in
    if total <= 0.0 then Array.init n (fun i -> i mod n)
    else begin
      let cumulative = Array.make n 0.0 in
      let acc = ref 0.0 in
      Array.iteri (fun i w ->
        acc := !acc +. w /. total;
        cumulative.(i) <- !acc) weights;
      Array.init n (fun _ ->
        let r = Random.float 1.0 in
        let rec find i =
          if i >= n - 1 || cumulative.(i) >= r then i
          else find (i + 1)
        in find 0)
    end

  let effective_sample_size weights =
    let n = float_of_int (Array.length weights) in
    let total = Array.fold_left (+.) 0.0 weights in
    if total <= 0.0 then 0.0
    else begin
      let sum_sq = Array.fold_left (fun acc w ->
        let nw = w /. total in acc +. nw *. nw) 0.0 weights in
      1.0 /. sum_sq /. n
    end

  let infer ?(n=1000) ?(resample_threshold=0.5) f =
    let traces = Array.make n [] in
    let weights = Array.make n 1.0 in
    let active = Array.make n true in
    let final_results = ref [] in
    let n_active = ref n in

    while !n_active > 0 do
      for i = 0 to n - 1 do
        if active.(i) then
          match run_one_step f traces.(i) with
          | Done (result, trace, w) ->
              final_results := (result, weights.(i) *. w) :: !final_results;
              active.(i) <- false;
              decr n_active
          | Paused (trace, w) ->
              traces.(i) <- trace;
              weights.(i) <- weights.(i) *. w
          | Failed ->
              active.(i) <- false;
              decr n_active
      done;

      if !n_active > 0 then begin
        let active_indices =
          Array.to_list (Array.init n (fun i -> i))
          |> List.filter (fun i -> active.(i))
          |> Array.of_list in
        let active_n = Array.length active_indices in
        let active_weights =
          Array.init active_n (fun j -> weights.(active_indices.(j))) in
        if active_n > 0 &&
            effective_sample_size active_weights < resample_threshold then begin
          let indices = resample_indices active_n active_weights in
          let new_traces =
            Array.map (fun j -> traces.(active_indices.(j))) indices in
          let new_weight = 1.0 /. float_of_int active_n in
          Array.iteri (fun j _ ->
            traces.(active_indices.(j)) <- new_traces.(j);
            weights.(active_indices.(j)) <- new_weight) indices
        end
      end
    done;

    let combined = Hashtbl.create 16 in
    let total = ref 0.0 in
    List.iter (fun (v, w) ->
      total := !total +. w;
      let prev = try Hashtbl.find combined v with Not_found -> 0.0 in
      Hashtbl.replace combined v (prev +. w)) !final_results;
    if !total > 0.0 then
      Hashtbl.fold (fun v w acc -> (v, w /. !total) :: acc) combined []
      |> List.sort (fun (_, p1) (_, p2) -> compare p2 p1)
    else []
end
```

The trace type `draw list` is simple and type-safe: `DChoose of int` stores only the index, `DGaussian of float` stores the sampled value. During replay, we use the stored index to select from the list passed to `Choose`. No existential types, no `Obj.magic`.

#### Example: Sensor Fusion

Here is an example using both discrete and continuous distributions. A robot can be in one of several rooms, and we receive noisy sensor readings of its position:

```ocaml env=ch9
type room = Kitchen | Living | Bedroom | Bathroom

let room_center = function
  | Kitchen -> (0.0, 0.0)
  | Living -> (5.0, 0.0)
  | Bedroom -> (0.0, 5.0)
  | Bathroom -> (5.0, 5.0)

let sensor_fusion ~observed_x ~observed_y =
  let open GProb in
  (* Prior: uniform over rooms *)
  let room = choose [Kitchen; Living; Bedroom; Bathroom] in
  let (cx, cy) = room_center room in
  (* Sensor model: noisy reading centered on true position *)
  let sensor_noise = 1.0 in
  let x = gaussian ~mu:cx ~sigma:sensor_noise in
  let y = gaussian ~mu:cy ~sigma:sensor_noise in
  (* Observe the sensor readings *)
  observe (normal_pdf observed_x ~mu:x ~sigma:0.5);
  observe (normal_pdf observed_y ~mu:y ~sigma:0.5);
  room

let () =
  Printf.printf "\n=== Typed Probabilistic Effects ===\n";
  Printf.printf "Sensor fusion (observed near Living room at 4.8, 0.2):\n";
  let dist1 = GImportance.infer ~samples:50000 (fun () ->
    sensor_fusion ~observed_x:4.8 ~observed_y:0.2) in
  let dist2 = GParticleFilter.infer ~n:5000 (fun () ->
    sensor_fusion ~observed_x:4.8 ~observed_y:0.2) in
  let show_room r = match r with
    | Kitchen -> "Kitchen" | Living -> "Living"
    | Bedroom -> "Bedroom" | Bathroom -> "Bathroom" in
  Printf.printf "  GImportance:     ";
  List.iter (fun (r, p) -> Printf.printf "%s: %.3f  " (show_room r) p) dist1;
  print_newline ();
  Printf.printf "  GParticleFilter: ";
  List.iter (fun (r, p) -> Printf.printf "%s: %.3f  " (show_room r) p) dist2;
  print_newline ()
```

#### Testing with Monty Hall

Let us verify that the typed interface produces correct results:

```ocaml env=ch9
let typed_monty_hall ~switch =
  let open GProb in
  let doors = [`A; `B; `C] in
  let prize = choose doors in
  let chosen = choose doors in
  let can_open = List.filter (fun d -> d <> prize && d <> chosen) doors in
  let opened = choose can_open in
  let final =
    if switch then
      List.hd (List.filter (fun d -> d <> opened && d <> chosen) doors)
    else chosen in
  final = prize

let () =
  Printf.printf "\nTyped Monty Hall (no switch): ";
  let dist = GImportance.infer (fun () -> typed_monty_hall ~switch:false) in
  List.iter (fun (win, p) ->
    Printf.printf "%s: %.3f  " (if win then "win" else "lose") p) dist;
  print_newline ()

let () =
  Printf.printf "Typed Monty Hall (switch): ";
  let dist = GImportance.infer (fun () -> typed_monty_hall ~switch:true) in
  List.iter (fun (win, p) ->
    Printf.printf "%s: %.3f  " (if win then "win" else "lose") p) dist;
  print_newline ()

let () =
  Printf.printf "Typed Monty Hall with Particle Filter (switch): ";
  let dist = GParticleFilter.infer ~n:5000 (fun () ->
    typed_monty_hall ~switch:true) in
  List.iter (fun (win, p) ->
    Printf.printf "%s: %.3f  " (if win then "win" else "lose") p) dist;
  print_newline ()
```

The typed interface makes probabilistic programs cleaner and more expressive while maintaining full type safety. The GADT structure of OCaml's effect system ensures that `choose` returns the right type at each call site, and the simple index-based trace representation keeps replay straightforward.

### 9.13 Exercises

**Exercise 1.** Extend the `Threads` module to support timeouts. Add an effect `Timeout : float -> 'a promise -> 'a option Effect.t` that waits for a promise with a timeout, returning `None` if the timeout expires. You will need to track elapsed "time" (perhaps measured in yields).

**Exercise 2.** Implement a simple generator/iterator pattern using effects. Define a `YieldGen : 'a -> unit Effect.t` and write:

- A function `generate : (unit -> unit) -> 'a Seq.t` that converts a procedure using `YieldGen` into a sequence.
- Use it to implement a generator for Fibonacci numbers.

**Exercise 3.** The `State` module above only handles integer state. Generalize it to handle state of any type using a functor or first-class modules.

**Exercise 4.** Write a probabilistic program for the following scenario: You have two coins, a fair one (50% heads) and a biased one (70% heads). You pick a coin uniformly at random, flip it three times, and observe that all three flips came up heads. What is the probability that you picked the biased coin? Run inference with both `Rejection` and `Importance` and compare the results and efficiency.

**Exercise 5.** Implement a *likelihood weighting* version of inference that is between rejection sampling and full importance sampling. In likelihood weighting, we sample from the prior for `Sample` effects but weight by the likelihood for `Observe` effects. Compare with rejection sampling on the burglary example.

**Exercise 6.** The particle filter currently pauses at every `Sample`, which may cause excessive resampling overhead. Modify it to pause more selectively: only pause at a `Sample` that occurs after at least one `Observe` since the last pause. This focuses resampling on points where weights have actually changed. (Hint: track whether any `Observe` has occurred since the last pause.)

**Exercise 7.** Optimize the particle filter by storing the suspended continuation alongside the trace in `Paused`. When advancing a particle, first try to resume the stored continuation directly. If resampling duplicated the particle (i.e., another particle already consumed the continuation), the resume will raise `Effect.Continuation_already_resumed` -- catch this and fall back to replay. This avoids replay overhead for particles that weren't duplicated during resampling.
