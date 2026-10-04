## Chapter 7: Streams, demand, and sharing

![Chapter 7 illustration](Curious_OCaml-chapter_7.jpg){.chapter-image}

**Prerequisites:** lists, folds and the cost discussion in Chapters 3 and 6.
**Route:** Part III begins here. Chapter 8 adds choice; Chapter 10 consumes a
recorded input stream. Numerical analysis and pretty printing are optional projects.

A delayed computation is a promise to do work later. It is not a promise to do
less work, or to retain less memory. We will separate four questions: what demands
a value, whether repeated demands share work, what history remains reachable,
and who closes a resource when demand stops early.

### 7.1 Call by name and call by need in a strict language

OCaml evaluates an argument to a value before entering a function. A closure is
already a value, so `fun () -> work ()` delays `work`; calling the closure twice
runs `work` twice. A lazy value `lazy (work ())` instead caches the result when
forced. This models call by need in this single-threaded example.

```ocaml env=demand
let calls = ref 0
let work () = incr calls; 42
let thunk = fun () -> work ()
let shared = lazy (work ())
let () =
  assert (!calls = 0);
  ignore (thunk ()); ignore (thunk ());
  assert (!calls = 2);
  ignore (Lazy.force shared); ignore (Lazy.force shared);
  assert (!calls = 3)
```

Passing an OCaml reference cell still passes a value. A callee can mutate that
shared cell, but cannot rebind the caller's variable. This differs from a
call-by-reference parameter that aliases the variable itself. Likewise, normal
order in Chapter 4 reduces under lambdas; a thunk here only runs when called.

### 7.2 Streams expose demand

A stream has an immediate head and a delayed tail:

```ocaml env=streams
type 'a stream = Nil | Cons of 'a * (unit -> 'a stream)
let rec from n = Cons (n, fun () -> from (n + 1))
let rec map f = function
  | Nil -> Nil
  | Cons (x, tail) -> Cons (f x, fun () -> map f (tail ()))
let rec take n = function
  | _ when n <= 0 -> []
  | Nil -> []
  | Cons (x, _) when n = 1 -> [x]
  | Cons (x, tail) -> x :: take (n - 1) (tail ())
let () =
  assert (take 4 (map (( * ) 2) (from 0)) = [0;2;4;6]);
  assert (take 1 (Cons (7, fun () -> failwith "not demanded")) = [7])
```

The `n = 1` case matters: a consumer of one element must not demand a second
one. However, the head is strict. Constructing `map f s` applies `f` to the first
head immediately. A fully suspended sequence would put the first node behind a
thunk too, as `Seq.t` does. Demand contracts belong to representations and
operations, not to the word “stream”.

A stream may be finite, infinite, or fail while producing a tail. Arithmetic in
`from` uses bounded machine integers; “infinite” describes how long it can keep
producing nodes, not an unbounded integer representation.

### 7.3 Sharing saves recomputation and retains history

```ocaml env=streams
type 'a lazy_list = End | More of 'a * 'a lazy_list Lazy.t
let rec memoize = function
  | Nil -> End
  | Cons (x, tail) -> More (x, lazy (memoize (tail ())))
let rec take_lazy n = function
  | _ when n <= 0 -> []
  | End -> []
  | More (x, _) when n = 1 -> [x]
  | More (x, tail) -> x :: take_lazy (n - 1) (Lazy.force tail)
let () =
  let calls = ref 0 in
  let s = Cons (1, fun () -> incr calls; Cons (2, fun () -> Nil)) in
  ignore (take 2 s); ignore (take 2 s);
  assert (!calls = 2);
  let cached = memoize s in
  ignore (take_lazy 2 cached); ignore (take_lazy 2 cached);
  assert (!calls = 3)
```

Keeping `cached` retains every forced node reachable through its memoized tails.
A consumer that advances and drops old roots may allow old nodes to be collected;
a closure that still captures the original head prevents that. Conversely, a
nonmemoized stream can recompute a prefix each time it is revisited. Neither
representation is uniformly faster or smaller.

| Representation | Repeated tail demand | Potential retained data |
|---|---|---|
| Thunk tail | Recomputes, or repeats effects | Whatever the closure captures |
| Lazy tail | Shares the result (or cached failure) | Forced prefix reachable from old roots |
| Mutable reader | Advances one external cursor | Open resource until its owner closes it |

A self-referential definition must be *productive*: each requested node needs to
be produced after finite work. `lazy (Lazy.force itself)` is not made productive
by the `lazy` keyword. A recurrence with a known first node and delayed recursion
can be productive, but sharing and arithmetic costs still need analysis.

### 7.4 Resource ownership is a scope

An EOF-only close leaks the resource when the consumer takes one line and stops,
or raises before EOF. Returning a lazy list does not tell us when that consumer
is finished. Instead make a callback own the whole reading scope:

```ocaml env=resource
let with_lines filename consume =
  Scoped.with_lines filename consume
```

`Scoped` is the compiled module in `projects/streams/scoped.ml`. Its implementation
is short enough to inspect in full:

<!-- $MDX file=../projects/streams/scoped.ml -->
```ocaml
(* The callback owns the resource scope; an escaped reader is invalidated. *)
let with_source ~acquire ~read ~close consume =
  let resource = acquire () in
  let active = ref true in
  let next () =
    if not !active then invalid_arg "reader used outside its scope";
    read resource in
  Fun.protect
    ~finally:(fun () -> active := false; close resource)
    (fun () -> consume next)

let with_lines filename consume =
  with_source
    ~acquire:(fun () -> open_in filename)
    ~read:(fun ch -> try Some (input_line ch) with End_of_file -> None)
    ~close:close_in_noerr consume
```

`Fun.protect` closes the source on success, early return, or exception. It also
marks an escaped `next` function inactive, so an attempted read after the callback
returns raises an error. OCaml's type here does not prevent escape statically;
the runtime check enforces the scope. Read values such as strings may safely
escape. `close_in_noerr` avoids replacing a consumer failure with a close failure.
For a general resource whose close can fail, choose and document an error policy.

The project tests an early stop, a consumer exception, an escaped reader, and an
actual file read. Reading twice from the same cursor is intentionally different
from forcing the same memoized lazy node twice.

### 7.5 Separate formal coefficients from approximation

A stream of coefficients is a representation of a formal series. A finite prefix
can be manipulated without claiming that its infinite sum converges anywhere.
To evaluate numerically, specify the domain, truncation rule and error criterion.
Small coefficients alone prove nothing about an unseen tail: at `x=1`, the
polynomial `1 + x^100` has a long stretch of unchanged partial sums before its
answer changes from one to two.

The numerical project, `projects/numerical/README.md`, provides finite polynomial
operations, a requested-length formal quotient with explicit zero-denominator
rules, and a fixed-degree approximation of `exp x` on `[0,1]`. It derives a real
truncation bound and distinguishes it from floating-point roundoff. It contains
no function called `exact` that merely checks repeated rounded values.

The larger pipe-based pretty-printer and circular-list construction are preserved
in `projects/pipes/README.md`. Use them to investigate buffering and delayed
references after the demand model above is familiar.

### 7.6 Exercises

1. **Practice.** Instrument both `map` and `take`. Count the calls for requesting
   zero, one and three outputs, including the work performed during construction.
2. **Proof.** State `take`'s demand contract and prove that a request for `n > 0`
   nodes demands at most `n-1` tails, or fewer if the stream ends.
3. **Experiment.** Traverse a memoized prefix twice. Then keep only an advanced
   tail. Explain which old nodes are unreachable; do not infer garbage collection
   from a wall-clock speed comparison.
4. **Practice.** Change the reader callback to raise after its first read and
   verify one acquisition and one close. The selected solution is the
   exception-path check in `projects/streams/laws.ml`.
5. **Project.** Implement an approximation with a domain and remainder estimate,
   following the numerical project's acceptance criteria. Explicitly account for
   rounding or limit the claim to a real-arithmetic truncation bound.
