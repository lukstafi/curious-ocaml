## Chapter 9: Algebraic Effects

**In this chapter, you will:**

- Learn about algebraic effects and handlers as a powerful alternative to monads
- Implement lightweight cooperative threads using effects (comparing with the monad-based version)
- Model probabilistic programming with effect handlers
- Build interpreters for probabilistic programs: rejection sampling and particle filtering
- Understand the replay-with-fast-forward pattern for efficient inference

OCaml 5 introduced a game-changing feature: algebraic effects with effect handlers. While monads provide a disciplined way to structure effectful computations, they require threading computations explicitly through bind operations. Algebraic effects offer a different approach: effects can be performed directly, and handlers define how those effects are interpreted.

This chapter explores algebraic effects through two substantial examples. First, we will reimplement the cooperative lightweight threads from the previous chapter, showing how effects simplify the code. Then we will tackle probabilistic programming, building interpreters that can answer questions about probability distributions.

### 9.1 From Monads to Effects

In the previous chapter, we saw how monads structure effectful computations. Every monadic operation had to be sequenced with `let*`:

```ocaml skip
let rec loop s n =
  let* () = return (Printf.printf "-- %s(%d)\n%!" s n) in
  if n > 0 then loop s (n-1)
  else return ()
```

This works, but it is infectious: once you are inside a monad, everything must be monadic. You cannot simply call a regular function that might perform effects -- you must lift it into the monad.

Algebraic effects take a different approach. Effects are *performed* at call sites, and *handled* at a distance. The code performing an effect does not need to know how the effect will be interpreted:

```ocaml skip
let rec loop s n =
  Printf.printf "-- %s(%d)\n%!" s n;
  if n > 0 then loop s (n-1)
```

The effect of yielding control to other threads can be performed implicitly, and a handler decides what happens when the effect occurs.

#### Declaring Effects

In OCaml 5, we declare effects using the `effect` keyword. An effect declaration specifies the type of value the effect receives and the type it returns:

```ocaml env=ch9
type _ Effect.t += Yield : unit Effect.t
```

This declares a `Yield` effect that takes no arguments (hence `unit`) and returns nothing. The `type _ Effect.t +=` syntax extends the built-in extensible type for effects, similar to how exceptions extend the `exn` type.

Effects can carry data and return values:

```ocaml env=ch9
type _ Effect.t += Get : int Effect.t
type _ Effect.t += Put : int -> unit Effect.t
```

Here `Get` is an effect that returns an `int`, and `Put` takes an `int` and returns `unit`.

#### Performing Effects

To perform an effect, we use `Effect.perform`:

```ocaml env=ch9
let yield () = Effect.perform Yield
let get () = Effect.perform Get
let put n = Effect.perform (Put n)
```

When `Effect.perform` is called, control transfers to the nearest enclosing handler for that effect. If no handler exists, an `Effect.Unhandled` exception is raised.

#### Handling Effects

Effect handlers are installed using `Effect.Deep.match_with` or `Effect.Deep.try_with`. The handler receives a *continuation* representing "the rest of the computation":

```ocaml skip
let handler = Effect.Deep.{
  retc = (fun result -> (* computation completed normally *) result);
  exnc = (fun exn -> (* exception was raised *) raise exn);
  effc = fun (type a) (eff : a Effect.t) ->
    match eff with
    | Yield -> Some (fun (k : (a, _) continuation) ->
        (* Yield was performed; k is the continuation *)
        (* We can resume k later, discard it, or invoke it multiple times *)
        Effect.Deep.continue k ())
    | _ -> None  (* Effect not handled here *)
}
```

The continuation `k` captures everything that would happen after `Effect.perform Yield` returns. We can:
- **Continue** the computation by calling `Effect.Deep.continue k value`, where `value` becomes the return value of `Effect.perform`
- **Discontinue** by calling `Effect.Deep.discontinue k exn`, raising an exception at the effect site
- **Discard** the continuation by not using it (though this may leak resources)
- **Store** the continuation and resume it later

This ability to capture and manipulate continuations is what makes algebraic effects so powerful. Let us see this in action.

### 9.2 Lightweight Threads with Effects

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

  (* Run queue: ready-to-run continuations *)
  let run_queue : (unit -> unit) Queue.t = Queue.create ()

  let enqueue f = Queue.push f run_queue

  let dequeue () =
    if Queue.is_empty run_queue then ()
    else Queue.pop run_queue ()

  (* Complete a promise and wake up waiters *)
  let fulfill p v =
    match !p with
    | Done _ -> failwith "Promise already fulfilled"
    | Pending waiters ->
        p := Done v;
        List.iter (fun k -> enqueue (fun () ->
          Effect.Deep.continue k v)) waiters

  let rec run_thread : 'a. (unit -> 'a) -> 'a promise = fun f ->
    let p = ref (Pending []) in
    let handler = Effect.Deep.{
      retc = (fun v -> fulfill p v; dequeue ());
      exnc = (fun e -> raise e);
      effc = fun (type b) (eff : b Effect.t) ->
        match eff with
        | Async g -> Some (fun (k : (b, _) continuation) ->
            let p' = run_thread g in              (* Start child thread *)
            Effect.Deep.continue k p')            (* Return promise to parent *)
        | Await p' -> Some (fun k ->
            match !p' with
            | Done v -> Effect.Deep.continue k v  (* Already done: continue *)
            | Pending ks -> p' := Pending (k :: ks); dequeue ())  (* Wait *)
        | TYield -> Some (fun k ->
            enqueue (fun () -> Effect.Deep.continue k ());  (* Re-queue self *)
            dequeue ())                           (* Run next thread *)
        | _ -> None                               (* Effect not handled here *)
    } in
    Effect.Deep.match_with f () handler;
    p

  let run f =
    Queue.clear run_queue;                 (* Clear any leftover state *)
    let p = run_thread f in
    (* Drain the queue until all threads complete *)
    while not (Queue.is_empty run_queue) do
      dequeue ()
    done;
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

### 9.3 State with Effects

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
    Effect.Deep.match_with f ()
      Effect.Deep.{ retc = Fun.id; exnc = raise;
        effc = fun (type b) (eff : b Effect.t) ->
          match eff with
          | SGet -> Some (fun (k : (b, _) Effect.Deep.continuation) ->
              Effect.Deep.continue k !state)
          | SPut n -> Some (fun (k : (b, _) Effect.Deep.continuation) ->
              state := n; Effect.Deep.continue k ())
          | _ -> None }
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

### 9.4 Probabilistic Programming with Effects

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
  let can_open = Array.of_list (
    List.filter (fun d -> d <> prize && d <> chosen) [A; B; C]) in
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

### 9.5 Rejection Sampling Interpreter

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
    try
      Effect.Deep.match_with f ()
        Effect.Deep.{ retc = Option.some; exnc = raise;
          effc = fun (type b) (eff : b Effect.t) ->
            match eff with
            | Sample (_, weights) ->
                Some (fun (k : (b, _) Effect.Deep.continuation) ->
                  Effect.Deep.continue k (sample_index weights))
            | Observe w ->
                Some (fun (k : (b, _) Effect.Deep.continuation) ->
                  if Random.float 1.0 < w
                  then Effect.Deep.continue k ()
                  else raise Rejected)
            | Fail -> Some (fun _ -> raise Rejected)
            | _ -> None }
    with Rejected -> None

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

### 9.6 Importance Sampling

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
    try
      Effect.Deep.match_with f ()
        Effect.Deep.{ retc = (fun x -> Some (x, !weight)); exnc = raise;
          effc = fun (type b) (eff : b Effect.t) ->
            match eff with
            | Sample (_, weights) ->
                Some (fun (k : (b, _) Effect.Deep.continuation) ->
                  Effect.Deep.continue k (sample_index weights))
            | Observe likelihood ->
                Some (fun (k : (b, _) Effect.Deep.continuation) ->
                  weight := !weight *. likelihood;
                  Effect.Deep.continue k ())
            | Fail -> Some (fun _ -> raise HardFail)
            | _ -> None }
    with HardFail -> None

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

### 9.7 Soft Conditioning with Observe

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

### 9.8 Particle Filter with Replay

For models where observations occur at multiple points during execution, we can do even better with *particle filtering*. The key idea is to run multiple particles in parallel, periodically *resampling* to focus computation on high-weight particles.

The challenge is that we need to "replay" particles from the beginning after resampling, but fast-forward through the choices they already made. This is the "replay with fast-forward" pattern.

```ocaml env=ch9
module ParticleFilter = struct
  type trace = int list
  exception HardFail

  let sample_index weights =
    let total = Array.fold_left (+.) 0.0 weights in
    let r = Random.float total in
    let rec find i acc =
      if i >= Array.length weights then Array.length weights - 1
      else if r < acc +. weights.(i) then i
      else find (i + 1) (acc +. weights.(i)) in
    find 0 0.0

  let run_with_trace : type a. (unit -> a) -> trace ->
                       (a * trace * float) option = fun f trace ->
    let remaining = ref trace in
    let recorded = ref [] in
    let weight = ref 1.0 in
    try
      Effect.Deep.match_with f ()
        Effect.Deep.{ retc = (fun x -> Some (x, List.rev !recorded, !weight));
          exnc = raise;
          effc = fun (type b) (eff : b Effect.t) ->
            match eff with
            | Sample (_, weights) ->
                Some (fun (k : (b, _) Effect.Deep.continuation) ->
                  let i = match !remaining with
                    | choice :: rest -> remaining := rest; choice
                    | [] -> sample_index weights in
                  recorded := i :: !recorded;
                  Effect.Deep.continue k i)
            | Observe likelihood ->
                Some (fun (k : (b, _) Effect.Deep.continuation) ->
                  weight := !weight *. likelihood;
                  Effect.Deep.continue k ())
            | Fail -> Some (fun _ -> raise HardFail)
            | _ -> None }
    with HardFail -> None

  (* Resample: select n indices according to weights *)
  let resample_indices n weights =
    let total = Array.fold_left (+.) 0.0 weights in
    if total <= 0.0 then Array.init n (fun i -> i)
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

  (* Effective sample size: measure of weight degeneracy *)
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
    (* Each particle has a trace and weight *)
    let traces = Array.make n [] in
    let weights = Array.make n (1.0 /. float_of_int n) in
    let final_results = ref [] in

    (* Keep running until all particles complete *)
    let active = ref n in
    while !active > 0 do
      (* Try to extend each particle by one more sample *)
      for i = 0 to n - 1 do
        if weights.(i) > 0.0 then begin
          match run_with_trace f traces.(i) with
          | None ->
              (* Particle failed *)
              weights.(i) <- 0.0;
              decr active
          | Some (result, new_trace, new_weight) ->
              if List.length new_trace > List.length traces.(i) then begin
                (* Made progress: record new trace and weight *)
                traces.(i) <- new_trace;
                weights.(i) <- weights.(i) *. new_weight
              end else begin
                (* Completed: record result *)
                final_results := (result, weights.(i)) :: !final_results;
                weights.(i) <- 0.0;
                decr active
              end
        end
      done;

      (* Resample if ESS is low and there are still active particles *)
      if !active > 0 && effective_sample_size weights < resample_threshold then begin
        let indices = resample_indices n weights in
        let new_traces = Array.map (fun i -> traces.(i)) indices in
        let new_weight = 1.0 /. float_of_int !active in
        Array.blit new_traces 0 traces 0 n;
        for i = 0 to n - 1 do
          if weights.(i) > 0.0 then weights.(i) <- new_weight
        done
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

1. **Initialization**: Start n particles with empty traces
2. **Extension**: Run each particle forward, either replaying recorded choices or making fresh samples
3. **Resampling**: When the effective sample size drops too low, resample particles proportional to their weights
4. **Completion**: When particles finish, record their results

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

### 9.9 Comparing Inference Methods

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

### 9.10 Summary

Algebraic effects provide a powerful alternative to monads for structuring effectful computations:

1. **Separation of concerns**: Effect declarations specify *what* effects can occur. Handlers specify *how* effects are interpreted.

2. **Direct style**: Code performing effects looks like ordinary code. No `let*` or bind operators needed.

3. **Flexibility**: The same effectful code can be interpreted different ways by different handlers.

4. **Continuations**: Handlers receive continuations, enabling sophisticated control flow patterns like coroutines, backtracking, and particle filtering.

We saw two substantial applications:

- **Lightweight threads**: Effects make cooperative concurrency straightforward. The `Yield`, `Async`, and `Await` effects are handled by a scheduler that manages continuations.

- **Probabilistic programming**: `Sample`, `Observe`, and `Fail` effects describe probabilistic models. Different handlers implement different inference strategies.

The key insight is that effects are a *programming interface* that can have multiple *implementations*. This makes code more modular and reusable.

### 9.11 Exercises

**Exercise 1.** Extend the `Threads` module to support timeouts. Add an effect `Timeout : float -> 'a promise -> 'a option Effect.t` that waits for a promise with a timeout, returning `None` if the timeout expires. You will need to track elapsed "time" (perhaps measured in yields).

**Exercise 2.** Implement a simple generator/iterator pattern using effects. Define a `YieldGen : 'a -> unit Effect.t` and write:
- A function `generate : (unit -> unit) -> 'a Seq.t` that converts a procedure using `YieldGen` into a sequence.
- Use it to implement a generator for Fibonacci numbers.

**Exercise 3.** The `State` module above only handles integer state. Generalize it to handle state of any type using a functor or first-class modules.

**Exercise 4.** Write a probabilistic program for the following scenario: You have two coins, a fair one (50% heads) and a biased one (70% heads). You pick a coin uniformly at random, flip it three times, and observe that all three flips came up heads. What is the probability that you picked the biased coin? Run inference with both `Rejection` and `Importance` and compare the results and efficiency.

**Exercise 5.** Implement a *likelihood weighting* version of inference that is between rejection sampling and full importance sampling. In likelihood weighting, we sample from the prior for `Sample` effects but weight by the likelihood for `Observe` effects. Compare with rejection sampling on the burglary example.

**Exercise 6.** Add a `Choose : 'a list -> 'a Effect.t` effect that nondeterministically picks from a list. Implement handlers that:
1. Return all possible results (like the list monad)
2. Return the first successful result (with backtracking on failure)
3. Return a random result (like importance sampling)

**Exercise 7.** The sprinkler problem: It might be cloudy (50%). If cloudy, rain is likely (80%); otherwise rain is unlikely (20%). If cloudy, the sprinkler is unlikely (10%); otherwise likely (50%). Rain wets the grass with 90% probability, and so does the sprinkler. We observe that the grass is wet. What is the probability that it rained? Encode this as a probabilistic program and run inference.

**Exercise 8.** (Harder) Implement a version of the particle filter that tracks particles as suspended continuations rather than traces. When resampling, clone the continuation rather than replaying from the start. Compare the performance.
