## Chapter 9: Compilation, Runtime, and Parsing

**In this chapter, you will:**

- Understand the OCaml toolchain (`ocaml`, `ocamlc`, `ocamlopt`) and what “bytecode vs native” really means
- Organize multi-file programs with modules and interfaces, and know what gets produced (`.cmi`, `.cmo`, `.cmx`, …)
- Use imperative features deliberately (refs/arrays/loops) and parse command-line arguments robustly
- Build a working mental model of runtime execution: stack frames, closures, and garbage collection
- Apply the right optimization strategy (algorithm/data-structure first, micro-optimizations last) and measure improvements
- See how lexers and parsers fit in, with `ocamllex` and Menhir, through concrete examples from this repository
- Study a realistic case study: phrase search and inverted indexes

This chapter is a guided tour of “what happens around your OCaml program”: how it is built, how it runs, and how we analyze performance. The goal is not to memorize every tool flag, but to gain durable conceptual models that make you faster and more confident when projects grow beyond a single file.

### 9.1 OCaml Compilers and the Toolchain

OCaml is usually described as having two compilers:

- **`ocamlc`** compiles to **bytecode** (run by the bytecode runtime, typically via `ocamlrun`).
- **`ocamlopt`** compiles to **native code** (machine code for your platform).

The interactive REPL `ocaml` is bytecode-based; it is great for exploration, but it is not representative of optimized native performance.

OCaml compilation is multi-stage: the front end parses and typechecks your program, and the back end turns it into executable code (bytecode or native). The important “high-level” takeaway is that the language you write is not what the CPU runs; there is a pipeline in between, and learning to use it pays off (especially for profiling and performance work).

### 9.2 Multi-file Projects: Modules, Interfaces, and Build Artifacts

As soon as you have multiple files, two things matter:

1. **Module boundaries**: each `foo.ml` defines a module `Foo`.
2. **Interfaces**: `foo.mli` describes what `Foo` exports; it is compiled to `foo.cmi`.

Some common build artifacts:

- `.cmi` — compiled interface (types of exported values)
- `.cmo` — compiled bytecode object
- `.cmx`/`.o` — compiled native object + accompanying metadata
- `.exe` — final linked executable (native or bytecode wrapper)

This repository contains a tiny multi-file example in `chapter9/Lec9b/` (`main.ml`, `sub1.ml`, `sub2.ml`). Reading it is a good way to get a feel for “who can see what” across files.

In practice, you should use a build tool (this repo uses **Dune**), but it is still worth understanding what the build tool *does for you*.

### 9.3 Imperative Features (and Command-line Arguments)

OCaml is a strict language with mutation available. Mutation is not “forbidden”; it just changes how you reason:

- With immutable data, you can treat values as mathematical objects.
- With mutable data, time matters: *when* you read or write becomes relevant.

#### Parsing command-line arguments safely

For quick scripts you can read `Sys.argv`, but for robust programs use the `Arg` module. A useful trick is `Arg.parse_argv`: it lets you parse an explicit `argv` array (so you can test it without relying on the real process arguments).

```ocaml env=ch9
type config =
  { verbose : bool
  ; limit : int option
  ; files : string list
  }

let parse_argv argv =
  let verbose = ref false in
  let limit = ref None in
  let files = ref [] in
  let speclist =
    [ "-v", Arg.Set verbose, "enable verbose output"
    ; "--limit", Arg.Int (fun n -> limit := Some n), "N set a limit"
    ]
  in
  let anon file = files := file :: !files in
  let current = ref 0 in
  Arg.parse_argv ~current argv speclist anon "usage: prog [opts] files...";
  { verbose = !verbose; limit = !limit; files = List.rev !files }

let () =
  let cfg = parse_argv [| "prog"; "-v"; "--limit"; "10"; "a.txt"; "b.txt" |] in
  assert (cfg.verbose);
  assert (cfg.limit = Some 10);
  assert (cfg.files = [ "a.txt"; "b.txt" ])
```

Two practical tips:

- Keep parsing separate from “doing work” so you can test it.
- Prefer `option` or a small record to a long list of mutable globals.

### 9.4 Runtime Model: Values, Stack, Closures, and Garbage Collection

To reason about performance (and sometimes correctness), you need a rough model of where values live and how they are reclaimed.

#### Representation of values (high-level picture)

OCaml values are either:

- **Immediate** (e.g. integers), stored directly in a machine word, or
- **Pointers** to heap-allocated blocks (records, tuples, arrays, strings, closures, …).

This split is one reason OCaml can be fast: many common values are unboxed and cheap to pass around.

#### Generational garbage collection (GC)

OCaml’s GC is **generational**:

- Most allocations start in the **minor heap** (cheap allocation).
- The minor heap is collected frequently (typically with a copying collector).
- Long-lived values are promoted to the **major heap**, collected less frequently.

The mental model: optimize for the common case “allocate a lot of short-lived stuff”, which is exactly what functional code often does.

#### Stop & copy vs mark & sweep (two pictures)

The lecture materials include classic illustrations of the two phases of a mark-and-sweep collector:

![GC: marking phase](book-ora034-GC_Marking_phase.gif){width=70%}

![GC: sweep phase](book-ora035-GC_Sweep_phase.gif){width=70%}

In a copying collector, you move live objects out of the way and reclaim everything else at once; in mark-and-sweep, you *mark* reachable objects and then *sweep* the heap, reclaiming unmarked blocks.

### 9.5 Stack Frames and Closures (and Tail Recursion)

When you call a function, the runtime typically allocates a **stack frame** containing:

- return address
- spilled registers / temporary values
- local variables that need to live across calls

In OCaml, functions are first-class. A function value is a **closure**: code pointer + an environment of captured variables.

#### Tail recursion

A call is in *tail position* if its result is immediately returned. Tail calls can be optimized into jumps (no additional stack frame), which is why tail-recursive functions are crucial for large inputs.

```ocaml env=ch9
let rec sum_list = function
  | [] -> 0
  | x :: xs -> x + sum_list xs

let sum_list_tr xs =
  let rec go acc = function
    | [] -> acc
    | x :: tl -> go (acc + x) tl
  in
  go 0 xs

let () = assert (sum_list [1;2;3;4] = 10)
let () = assert (sum_list_tr [1;2;3;4] = 10)
```

For studying what the compiler actually does, `ocamlopt -S` (and friends) are useful; see Exercise 1 for a guided exploration.

### 9.6 Profiling and Optimization: What to Change First

Performance work is easiest when you follow a consistent ladder:

1. **Measure**: establish a baseline.
2. **Algorithmic changes**: often 10× improvements live here.
3. **Data structure changes**: often another 2×–10×.
4. **Low-level tuning**: helpful, but usually last.

This repository contains several “optimization steps” as separate files in `chapter9/Lec9o/` and multiple implementations of an inverted index in `chapter9/Lec9c/InvIndex*.ml`. Reading them is an excellent way to see how performance engineering proceeds in small, verifiable deltas.

### 9.7 Lexing and Parsing: `ocamllex` and Menhir

Parsers show up everywhere: compilers, data import, protocols, config files, query languages. The usual pipeline is:

1. **Lexing**: turn a character stream into tokens.
2. **Parsing**: turn tokens into a syntax tree.

#### Lexing with `ocamllex`

See `chapter9/Lec9m/Emails.mll` for a small lexer example (extracting email-like strings). An `.mll` file is turned into OCaml code by `ocamllex`.

#### Parsing with Menhir

See `chapter9/Lec9-calc-param/` for a classic example: lex and parse arithmetic expressions (`lexer.mll`, `parser.mly`, and a small driver in `calc.ml`).

There is also a “toy English grammar” example in `chapter9/Lec9e/` (`EngLexer.mll`, `EngParser.mly`), and a larger phrase-search corpus pipeline in `chapter9/Lec9c/` (including a lexer and multiple index implementations).

### 9.8 Case Study: Phrase Search (From Naive to Fast)

Phrase search is a compact case study that touches everything in this chapter:

- parsing/tokenization (to build the index),
- data structure choice (association lists vs hash tables vs ordered arrays),
- algorithmic improvements (naive merging vs ordered merging vs galloping search),
- profiling (to confirm the bottleneck you think you have).

At the simplest level, a phrase search engine builds an **inverted index** mapping each word to the (sorted) list of positions where it appears. A phrase query like `["to"; "be"]` then asks for positions `p` where `"to"` occurs at `p` and `"be"` occurs at `p+1`.

Here is a tiny, intentionally naive implementation that is good enough to explain the idea:

```ocaml env=ch9
module StringTbl = Hashtbl.Make (struct
  type t = string
  let equal = String.equal
  let hash = Hashtbl.hash
end)

let words (s : string) : string list =
  s
  |> String.split_on_char ' '
  |> List.filter (fun w -> w <> "")

let build_positions (ws : string list) : int list StringTbl.t =
  let tbl = StringTbl.create 32 in
  let add w pos =
    let old = match StringTbl.find_opt tbl w with None -> [] | Some ps -> ps in
    StringTbl.replace tbl w (pos :: old)
  in
  List.iteri (fun i w -> add w i) ws;
  StringTbl.iter (fun w ps -> StringTbl.replace tbl w (List.rev ps)) tbl;
  tbl

let phrase_positions (tbl : int list StringTbl.t) (phrase : string list) : int list =
  match phrase with
  | [] -> []
  | w0 :: ws ->
      let p0 = match StringTbl.find_opt tbl w0 with None -> [] | Some ps -> ps in
      let occurs_at w offset pos =
        match StringTbl.find_opt tbl w with
        | None -> false
        | Some ps -> List.mem (pos + offset) ps
      in
      p0
      |> List.filter (fun pos ->
           ws
           |> List.mapi (fun i w -> occurs_at w (i + 1) pos)
           |> List.for_all (fun b -> b))

let () =
  let tbl = build_positions (words "to be or not to be") in
  assert (phrase_positions tbl ["to"; "be"] = [0; 4])
```

This version uses `List.mem` inside the query, so it is quadratic-ish and will not scale. The point is to make the *specification* of phrase search concrete; the subsequent optimized versions in `chapter9/Lec9c/` and `chapter9/Lec9o/` replace the inner membership checks with ordered merging and faster search strategies.

### Exercises

The exercises for the original lecture are in `chapter9/lecture09-exercises.md`. Highlights:

1. Use `ocamlopt -S` plus optimization flags to inspect generated assembly and register allocation decisions.
2. Investigate where escaping variables are stored (stack vs closure).
3. Check whether inlining happens and how recursion affects it.
4. Write a small `ocamllex` anonymizer (mask probable full names).
5–7. Improve and refactor the English grammar lexer/parser examples.
8. Integrate the Porter stemmer (`chapter9/Lec9c/stemmer.ml`) into the phrase-search pipeline.
9–10. Revisit the search engine from Chapter 6: data-structure upgrades, query optimization, and better parsing.
