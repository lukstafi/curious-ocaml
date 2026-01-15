## Chapter 9: Algebraic Effects

**In this chapter, you will:**

- Learn the basic idea of *algebraic effects* and *handlers* (in OCaml 5)
- See how handlers act as *interpreters* for effectful programs
- Rebuild a lightweight cooperative “threads” library in direct style
- Define effects for probabilistic programming (sampling, conditioning, time steps)
- Write a simple rejection-sampling interpreter
- Write a particle filter using *replay with fast-forward* (no checkpointing)

Chapter 8 used *monads* to structure effectful code. In OCaml 5 we also have a second (complementary) tool: **algebraic effects**. The slogan is:

> Instead of building an “effectful computation” as a value (a monad), we *write the computation in direct style* and then provide its meaning using a *handler*.

This chapter focuses on small, runnable libraries and interpreters. The goal is not to build a production inference engine or a production scheduler, but to see how the *same program* can be given different meanings by changing only the handler.

### 9.1 What Is an Algebraic Effect?

An algebraic effect is a user-defined operation that can be *performed* (requested) inside a computation. A **handler** decides what to do when that operation is performed.

In OCaml, effects live in the extensible GADT `Effect.t`. You **declare** an effect by extending `Effect.t`, you **perform** it with `Effect.perform`, and you **handle** it either with handler records (`Effect.Deep.match_with`) or, more conveniently, with the *effect pattern* syntax in `match`/`try` (syntax sugar for deep handlers). In this syntax, regular cases correspond to `retc`, `exception ...` cases correspond to `exnc`, and `effect ...` cases correspond to `effc`.

Here is the smallest possible example: an effect that asks for an `int`.

```ocaml env=ch9_intro
type _ Effect.t += Ask : int Effect.t

let ask () = Effect.perform Ask

let program () =
  let x = ask () in
  x + 1

let answer_42 () =
  try program () with
  | effect Ask, k -> Effect.Deep.continue k 42

let _ = assert (answer_42 () = 43)
```

The key new ingredient here is the *continuation* `k`: it represents “the rest of the computation” from the point where the effect was performed. The handler can decide whether to:

- resume it once (`continue k ...`), which is the common case in OCaml’s one-shot setting
- stop the computation by not resuming (but then you must ensure this does not leak resources; in many cases, `discontinue` is the safer choice)
- resume it with an exception (`Effect.Deep.discontinue k exn`)
- (importantly) it must not resume it twice: resuming a continuation more than once raises `Effect.Continuation_already_resumed`

If an effect `e` is performed and no enclosing handler handles it, `Effect.perform e` raises `Effect.Unhandled e`.

#### Deep vs. shallow handlers

OCaml provides two handler APIs:

- `Effect.Deep` handlers are **deep**: once installed, they handle all effects performed by the computation *and by any continuations resumed under the handler*, until the computation finishes.
- `Effect.Shallow` handlers are **shallow**: they handle at most one effect, and resuming a continuation requires specifying the handler again (e.g. `Effect.Shallow.continue_with`).

The surface language also supports *effect patterns* in `match`/`try` (introduced for deep handlers in OCaml 5.3). For example, the manual’s “exchange” effect can be written as:

```ocaml skip
open Effect
open Effect.Deep

type _ Effect.t += Xchg : int -> int t

let comp () = perform (Xchg 0) + perform (Xchg 1)

let _ =
  try comp () with
  | effect (Xchg n), k -> continue k (n + 1)
```

### 9.2 Lightweight Cooperative Threads, Revisited (Effects Edition)

Chapter 8 ended with a monadic sketch of cooperative threads (Lwt-style). Effects let us write the *user code* in direct style:

- `async f` starts `f` “in the background” and returns a promise
- `await p` waits for a promise
- `yield ()` gives other fibers a chance to run

We will implement a tiny scheduler with a FIFO queue. This is *cooperative*: a fiber only stops running at well-defined suspension points (`yield` or `await`).

#### A tiny fiber + promise library

```ocaml env=ch9_threads
module Fiber = struct
  type 'a promise_state =
    | Done of ('a, exn) result
    | Waiting of (('a, unit) Effect.Deep.continuation) list

  type 'a promise = { mutable state : 'a promise_state }

  type packed_promise = P : 'a promise -> packed_promise
  type packed_waiter = W : ('a, unit) Effect.Deep.continuation -> packed_waiter

  exception Deadlock

  type _ Effect.t += Yield : unit Effect.t
  type _ Effect.t += Async : (unit -> 'a) -> 'a promise Effect.t
  type _ Effect.t += Await : 'a promise -> 'a Effect.t

  let yield () = Effect.perform Yield
  let async f = Effect.perform (Async f)
  let await p = Effect.perform (Await p)

  let run (main : unit -> unit) : unit =
    let jobs : (unit -> unit) Queue.t = Queue.create () in
    let promises : packed_promise list ref = ref [] in

    let enqueue job = Queue.push job jobs in

    let rec exec (thunk : unit -> unit) : unit =
      match thunk () with
      | () -> ()
      | effect Yield, k ->
          enqueue (fun () -> exec (fun () -> Effect.Deep.continue k ()));
          ()
      | effect (Async f), k ->
          let p = { state = Waiting [] } in
          promises := P p :: !promises;

          let resolve r =
            match p.state with
            | Done _ -> invalid_arg "Fiber: promise resolved twice"
            | Waiting waiters ->
                p.state <- Done r;
                List.iter
                  (fun waiter ->
                    enqueue (fun () ->
                      exec (fun () ->
                        match r with
                        | Ok x -> Effect.Deep.continue waiter x
                        | Error exn -> Effect.Deep.discontinue waiter exn)))
                  waiters
          in

          (* Enqueue continuation first: the parent keeps running and can spawn
             more work before children start. *)
          enqueue (fun () -> exec (fun () -> Effect.Deep.continue k p));
          enqueue (fun () ->
            exec (fun () ->
              let r =
                try Ok (f ()) with
                | exn -> Error exn
              in
              resolve r));
          ()
      | effect (Await p), k -> (
          match p.state with
          | Done (Ok x) ->
              enqueue (fun () -> exec (fun () -> Effect.Deep.continue k x));
              ()
          | Done (Error exn) ->
              enqueue (fun () -> exec (fun () -> Effect.Deep.discontinue k exn));
              ()
          | Waiting waiters ->
              p.state <- Waiting (k :: waiters);
              ())
    in

    enqueue (fun () -> exec main);
    let rec drain () =
      while not (Queue.is_empty jobs) do
        (Queue.pop jobs) ()
      done
    in
    drain ();

    (* In general, every captured continuation should eventually be either
       continued or discontinued; otherwise resources protected by
       exception-based cleanup (e.g. Fun.protect) may be leaked. If the run queue
       is empty but some fibers are still waiting, we are deadlocked. *)
    let deadlocked_waiters =
      List.filter_map
        (fun (P p) ->
          match p.state with
          | Done _ -> None
          | Waiting waiters ->
              p.state <- Done (Error Deadlock);
              Some (List.map (fun k -> W k) waiters))
        !promises
      |> List.concat
    in
    if deadlocked_waiters <> [] then begin
      List.iter
        (fun (W waiter) ->
          enqueue (fun () ->
            try ignore (Effect.Deep.discontinue waiter Deadlock) with
            | _ -> ()))
        deadlocked_waiters;
      drain ();
      raise Deadlock
    end
end

let _ =
  let open Fiber in
  let log = ref [] in
  run (fun () ->
    let pa =
      async (fun () ->
        log := "A1" :: !log;
        yield ();
        log := "A2" :: !log;
        10)
    in
    let pb =
      async (fun () ->
        log := "B1" :: !log;
        yield ();
        log := "B2" :: !log;
        20)
    in
    let _ = await pa in
    let _ = await pb in
    ());
  assert (List.rev !log = [ "A1"; "B1"; "A2"; "B2" ])
```

This is already enough to express many “Lwt-like” patterns, without monadic `bind` and without callbacks.

### 9.3 Probabilistic Programming as Effects

In Chapter 8, probabilistic programs were built inside a probability monad (exact distributions, sampling, conditioning via rejection, …).

Here we will write probabilistic programs in direct style and represent the *probabilistic primitives* as effects:

- `Sample d : 'a` draws from a discrete distribution `d`
- `Reject : 'a` aborts the current execution (hard constraints, like `guard false`)
- `Factor w : unit` multiplies the current execution weight by `w` (soft evidence)
- `Tick : unit` marks a time step boundary (for particle filtering)

Then we will write *interpreters* (handlers) that implement:

- rejection sampling (simple, but can be inefficient)
- particle filtering (sequential Monte Carlo), using replay with fast-forward

#### Discrete distributions (just enough for the chapter)

```ocaml env=ch9_prob
module Dist = struct
  type 'a t = ('a * float) list

  let total (d : 'a t) =
    List.fold_left (fun acc (_, w) -> acc +. w) 0.0 d

  let normalize (d : 'a t) : 'a t =
    let z = total d in
    if z = 0.0 then d else List.map (fun (x, w) -> (x, w /. z)) d

  let prob_of (eq : 'a -> bool) (d : 'a t) : float =
    List.fold_left (fun acc (x, w) -> if eq x then acc +. w else acc) 0.0 d

  let roulette (rng : Random.State.t) (d : 'a t) : 'a =
    let z = total d in
    if z <= 0.0 then invalid_arg "Dist.roulette: non-positive total weight";
    let r0 = Random.State.float rng z in
    let rec go r = function
      | [] -> invalid_arg "Dist.roulette: empty distribution"
      | (x, w) :: _ when r <= w -> x
      | (_, w) :: xs -> go (r -. w) xs
    in
    go r0 d

  let bernoulli p : bool t = [ (true, p); (false, 1.0 -. p) ]
  let uniform (xs : 'a list) : 'a t = List.map (fun x -> (x, 1.0)) xs
end
```

#### Effects and the “surface language”

```ocaml env=ch9_prob
type _ Effect.t += Sample : 'a Dist.t -> 'a Effect.t
type _ Effect.t += Factor : float -> unit Effect.t
type _ Effect.t += Reject : 'a Effect.t
type _ Effect.t += Tick : unit Effect.t

let sample (d : 'a Dist.t) : 'a = Effect.perform (Sample d)
let flip p : bool = sample (Dist.bernoulli p)
let pick (d : 'a Dist.t) : 'a = sample d

let assume (b : bool) : unit =
  if b then () else Effect.perform Reject

let factor (w : float) : unit =
  if w < 0.0 then invalid_arg "factor: negative weight";
  Effect.perform (Factor w)

let tick () : unit = Effect.perform Tick
```

With these primitives, the “monadic” code from Chapter 8 becomes ordinary direct-style OCaml:

- `let* x = flip p in ...` becomes `let x = flip p in ...`
- `guard b` becomes `assume b`
- conditioning by likelihood becomes `factor (likelihood ...)`

### 9.4 A Simple Rejection Sampling Interpreter

Rejection sampling is the simplest way to interpret `assume`:

1. run the program, sampling whenever it asks (`Sample`)
2. if it performs `Reject`, discard the whole run and restart
3. if it returns a value, accept it as one sample

This corresponds closely to `SamplingMP` from Chapter 8 (which used an exception to represent “rejected” runs).

```ocaml env=ch9_prob
module Rejection = struct
  let rec run_once (rng : Random.State.t) (thunk : unit -> 'a) : 'a option =
    match thunk () with
    | v -> Some v
    | effect (Sample d), k ->
        let x = Dist.roulette rng d in
        Effect.Deep.continue k x
    | effect (Factor _w), k ->
        (* Rejection sampling does not use soft weights; we just ignore them. *)
        Effect.Deep.continue k ()
    | effect Tick, k ->
        Effect.Deep.continue k ()
    | effect Reject, _k ->
        None

  let rec sample (rng : Random.State.t) (thunk : unit -> 'a) : 'a =
    match run_once rng thunk with
    | Some v -> v
    | None -> sample rng thunk

  let samples (rng : Random.State.t) ~(n : int) (thunk : unit -> 'a) : 'a list =
    List.init n (fun _ -> sample rng thunk)
end
```

#### Example: condition a coin flip with `assume`

```ocaml env=ch9_prob
let conditioned_coin () =
  let a = flip 0.5 in
  let b = flip 0.5 in
  assume (a = b);
  a

let _ =
  let rng = Random.State.make [| 9; 1; 9 |] in
  let xs = Rejection.samples rng ~n:200 conditioned_coin in
  let count_true = List.fold_left (fun acc x -> if x then acc + 1 else acc) 0 xs in
  (* With the constraint a=b, the result should be close to fair. *)
  assert (count_true > 50 && count_true < 150)
```

Rejection sampling is easy to implement and conceptually clean, but it can be very inefficient when constraints are rare.

### 9.5 A Particle Filter via Replay with Fast-Forward

Particle filtering (sequential Monte Carlo) is designed for *time-structured* probabilistic programs: a model produces a stream of latent states and observations. At each time step we:

1. extend each particle with new random choices
2. multiply its weight by the likelihood of the observation
3. resample particles according to weights (to focus on likely trajectories)

In an effect handler, we face a practical issue:

- OCaml effect continuations are **one-shot**
- particle filtering wants to “branch” and “clone” computations during resampling

One classic solution is **replay-based inference**:

- store the sequence of random choices made so far (a *trace*)
- when we need to “continue” a particle, we simply re-run the whole program
  from the beginning, but **fast-forward** through already-recorded choices

This avoids checkpointing and avoids multi-shot continuations. It is slower than
checkpointing, but it is small and robust, and for a textbook it is perfect.

#### A replay runner that stops at the next `tick`

To keep the code small, we store sampled values using `Obj.t` and assume the
program makes the same kind of `sample` requests in the same order on replay.

```ocaml env=ch9_prob
module Replay = struct
  type event =
    | Tick
    | Sample of Obj.t

  type trace = event list

  type 'a step =
    | Done of { value : 'a; trace : trace; log_w : float }
    | Paused of { trace : trace; log_w : float }

  let ( +! ) a b = if Float.is_infinite a then a else a +. b

  exception Pause of trace * float
  exception Rejected

  let run_until_next_tick
      (rng : Random.State.t)
      ~(replay : trace)
      (thunk : unit -> 'a) : 'a step =
    let suffix = ref replay in
    let prefix_rev : trace ref = ref [] in
    let log_w = ref 0.0 in
    let rec go (th : unit -> 'a) : 'a =
      match th () with
      | v -> v
      | effect (Sample d), k -> (
          match !suffix with
          | Sample x :: suffix' ->
              suffix := suffix';
              prefix_rev := Sample x :: !prefix_rev;
              let xv = Obj.obj x in
              go (fun () -> Effect.Deep.continue k xv)
          | Tick :: _ ->
              invalid_arg "Replay.run: trace mismatch (expected Tick, got Sample)"
          | [] ->
              let x = Dist.roulette rng d in
              prefix_rev := Sample (Obj.repr x) :: !prefix_rev;
              go (fun () -> Effect.Deep.continue k x))
      | effect (Factor w), k ->
          let lw = if w <= 0.0 then neg_infinity else !log_w +! Float.log w in
          log_w := lw;
          go (fun () -> Effect.Deep.continue k ())
      | effect Reject, _k ->
          raise Rejected
      | effect Tick, k -> (
          match !suffix with
          | Tick :: suffix' ->
              suffix := suffix';
              prefix_rev := Tick :: !prefix_rev;
              log_w := 0.0;
              go (fun () -> Effect.Deep.continue k ())
          | Sample _ :: _ ->
              invalid_arg "Replay.run: trace mismatch (expected Sample, got Tick)"
          | [] ->
              prefix_rev := Tick :: !prefix_rev;
              raise (Pause (List.rev !prefix_rev, !log_w)))
    in
    (try
       let value = go thunk in
       Done { value; trace = List.rev_append !prefix_rev !suffix; log_w = !log_w }
     with
    | Pause (trace, log_w) -> Paused { trace; log_w }
    | Rejected ->
        Paused { trace = List.rev_append !prefix_rev !suffix; log_w = neg_infinity })

  let run_to_end
      (rng : Random.State.t)
      ~(replay : trace)
      (thunk : unit -> 'a) : 'a * trace =
    let suffix = ref replay in
    let prefix_rev : trace ref = ref [] in
    let rec go (th : unit -> 'a) : 'a =
      match th () with
      | v -> v
      | effect (Sample d), k -> (
          match !suffix with
          | Sample x :: suffix' ->
              suffix := suffix';
              prefix_rev := Sample x :: !prefix_rev;
              let xv = Obj.obj x in
              go (fun () -> Effect.Deep.continue k xv)
          | Tick :: _ ->
              invalid_arg
                "Replay.run_to_end: trace mismatch (expected Tick, got Sample)"
          | [] ->
              let x = Dist.roulette rng d in
              prefix_rev := Sample (Obj.repr x) :: !prefix_rev;
              go (fun () -> Effect.Deep.continue k x))
      | effect (Factor _w), k ->
          go (fun () -> Effect.Deep.continue k ())
      | effect Reject, _k ->
          invalid_arg "Replay.run_to_end: rejection after final resampling"
      | effect Tick, k -> (
          match !suffix with
          | Tick :: suffix' ->
              suffix := suffix';
              prefix_rev := Tick :: !prefix_rev;
              go (fun () -> Effect.Deep.continue k ())
          | _ ->
              invalid_arg "Replay.run_to_end: missing Tick in replay trace")
    in
    let value = go thunk in
    (value, List.rev_append !prefix_rev !suffix)
end
```

#### The particle filter driver

We run the program from the beginning for each particle and stop at each `tick`.
After each step we resample traces according to their incremental weights.

```ocaml env=ch9_prob
module Particle_filter = struct
  let multinomial_resample
      (rng : Random.State.t)
      ~(traces : Replay.trace array)
      ~(log_ws : float array) : Replay.trace array =
    let n = Array.length traces in
    if n = 0 then [||] else
    let max_log_w =
      Array.fold_left (fun acc x -> Float.max acc x) neg_infinity log_ws
    in
    let weights =
      if Float.is_infinite max_log_w then Array.make n 1.0
      else Array.map (fun lw -> Float.exp (lw -. max_log_w)) log_ws
    in
    let z = Array.fold_left ( +. ) 0.0 weights in
    let weights =
      if z = 0.0 then Array.make n (1.0 /. Float.of_int n)
      else Array.map (fun w -> w /. z) weights
    in
    let cdf = Array.make n 0.0 in
    let () =
      let acc = ref 0.0 in
      for i = 0 to n - 1 do
        acc := !acc +. weights.(i);
        cdf.(i) <- !acc
      done
    in
    let pick () =
      let r = Random.State.float rng 1.0 in
      let rec go i =
        if i >= n then n - 1
        else if r <= cdf.(i) then i
        else go (i + 1)
      in
      go 0
    in
    Array.init n (fun _ -> traces.(pick ()))

  let run
      (rng : Random.State.t)
      ~(n_particles : int)
      ~(n_steps : int)
      (model : unit -> 'a) : 'a list =
    let particles = Array.make n_particles ([] : Replay.trace) in
    for _step = 1 to n_steps do
      let traces = Array.make n_particles ([] : Replay.trace) in
      let log_ws = Array.make n_particles neg_infinity in
      for i = 0 to n_particles - 1 do
        match Replay.run_until_next_tick rng ~replay:particles.(i) model with
        | Replay.Paused { trace; log_w } ->
            traces.(i) <- trace;
            log_ws.(i) <- log_w
        | Replay.Done _ ->
            invalid_arg "Particle_filter.run: model terminated before enough ticks"
      done;
      let resampled = multinomial_resample rng ~traces ~log_ws in
      Array.blit resampled 0 particles 0 n_particles
    done;
    let values =
      Array.to_list
        (Array.init n_particles (fun i ->
           let v, _trace = Replay.run_to_end rng ~replay:particles.(i) model in
           v))
    in
    values
end
```

#### A tiny hidden Markov model example

We will model a random walk on integers and “sensor readings” that are usually correct but sometimes off by 1.

```ocaml env=ch9_prob
let step_dist : int Dist.t = [ (-1, 1.0); (0, 2.0); (1, 1.0) ]

let sensor_noise : int Dist.t = [ (-1, 1.0); (0, 8.0); (1, 1.0) ]

let sensor_likelihood ~(state : int) ~(obs : int) : float =
  let obs_dist = List.map (fun (n, w) -> (state + n, w)) sensor_noise in
  Dist.prob_of (fun x -> x = obs) (Dist.normalize obs_dist)

let rec hmm ~(state : int) ~(observations : int list) : int =
  match observations with
  | [] -> state
  | obs :: rest ->
      let step = sample step_dist in
      let state' = state + step in
      factor (sensor_likelihood ~state:state' ~obs);
      tick ();
      hmm ~state:state' ~observations:rest

let model observations () = hmm ~state:0 ~observations

let _ =
  let rng = Random.State.make [| 2; 0; 2; 6 |] in
  let observations = [ 0; 1; 1; 2; 2 ] in
  let particles =
    Particle_filter.run rng ~n_particles:200 ~n_steps:(List.length observations)
      (model observations)
  in
  assert (List.length particles = 200);
  (* A very weak sanity check: with these observations, states near 2 should be
     plausible for many particles. *)
  let near_2 =
    List.fold_left (fun acc x -> if x >= 0 && x <= 4 then acc + 1 else acc) 0 particles
  in
  assert (near_2 > 50)
```

This particle filter:

- does not use checkpointing
- does not clone continuations
- replays the model from the beginning for each particle at each time step

Despite being “slow but simple”, it captures the central idea: **a handler can be an inference engine**, and changing the handler changes the meaning of the same direct-style probabilistic program.
