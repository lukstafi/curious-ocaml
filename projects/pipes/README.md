# Project: circular structures, pipes and pretty printing

**Prerequisites:** Chapter 7. Run `dune runtest projects/pipes`. This optional
project retains the larger stream-processing construction from the second edition.
`Yield` below has a strict tail: this is a finite pipe syntax, not an automatically
productive representation of an infinite output source.

### 7.6 Circular Data Structures: Double-Linked Lists

OCaml permits some static cyclic values, such as `let rec ones = 1 :: ones`.
Constructing cycles dynamically is a different problem. Lazy links let us tie the
backward references below while building a finite list.

Double-linked lists are a classic example of structures with inherent cycles. Even if the list itself is not circular (it has a beginning and an end), each pair of adjacent nodes forms a cycle: node A points forward to node B, and node B points backward to node A:

```text
+--------+     +--------+     +--------+     +--------+     +--------+
| DLNil  | <-> |   a1   | <-> |   a2   | <-> |   a3   | <-> | DLNil  |
+--------+     +--------+     +--------+     +--------+     +--------+
```

To represent such structures in OCaml, we need to "break" the cycles by making some links lazy. The backward links will be lazy, allowing us to construct the structure one node at a time:

```ocaml env=ch7
type 'a dllist =
  DLNil | DLCons of 'a dllist Lazy.t * 'a * 'a dllist
```

The type has three components: a lazy backward link, the element, and a (strict) forward link. The backward link is lazy because when we create a node, its predecessor may not exist yet.

We can navigate forward through the list, dropping elements from the front:

```ocaml env=ch7
let rec dldrop n l =
  match l with
    | DLCons (_, x, xs) when n > 0 ->
       dldrop (n-1) xs
    | _ -> l
```

The tricky part is constructing a double-linked list from a regular list. Each cell must know its predecessor, but the predecessor is created first. We use a recursive lazy value to tie the knot:

```ocaml env=ch7
let dllist_of_list l =
  let rec dllist prev l =
    match l with
      | [] -> DLNil
      | x::xs ->
        let rec cell =
          lazy (DLCons (prev, x, dllist cell xs)) in
        Lazy.force cell in
  dllist (lazy DLNil) l
```

The key trick is `let rec cell = lazy (DLCons (prev, x, dllist cell xs))`. The lazy value `cell` refers to itself! When we force `cell`, it creates a `DLCons` node whose forward link (`dllist cell xs`) receives `cell` as the predecessor for the next node. This is only possible because the backward link is lazy -- when we create the next node, we do not need to evaluate `cell`, just store a reference to it.

Taking elements going forward is straightforward:

```ocaml env=ch7
let rec dltake n l =
  match l with
    | DLCons (_, x, xs) when n > 0 ->
       x :: dltake (n-1) xs
    | _ -> []
```

Taking elements going backward shows the power of the double-linked structure -- we can traverse in either direction:

```ocaml env=ch7
let rec dlbackwards n l =
  match l with
    | DLCons (lazy xs, x, _) when n > 0 ->
      x :: dlbackwards (n-1) xs
    | _ -> []
```

### 7.7 Input-Output Streams

Let us return to streams and generalize them. The stream type we defined earlier used a throwaway argument to make a suspension:

```ocaml env=ch7
type 'a stream = SNil | SCons of 'a * (unit -> 'a stream)
```

The `unit` argument serves only to delay computation. But what if we take a *real* argument -- one that provides input to the stream? This leads to a more powerful abstraction:

```ocaml env=ch7
type ('a, 'b) iostream =
  EOS | More of 'b * ('a -> ('a, 'b) iostream)
```

This is an *interactive* stream: it produces an output value of type `'b`, and when given an input value of type `'a`, produces the rest of the stream. The stream alternates between producing output and consuming input.

```ocaml env=ch7
type 'a istream = (unit, 'a) iostream  (* Input stream produces output when "asked". *)
type 'a ostream = ('a, unit) iostream  (* Output stream consumes provided input. *)
```

The terminology can be confusing. An "input stream" (`istream`) is one that produces output when asked (like reading from a file). An "output stream" (`ostream`) is one that consumes input (like writing to a file). The confusion arises from adapting the *input file / output file* terminology.

The power of this abstraction is that we can compose streams, directing the output of one to the input of another:

```ocaml env=ch7
let rec compose sf sg =
  match sg with
  | EOS -> EOS                              (* No more output from sg. *)
  | More (z, g) ->
    match sf with
    | EOS -> More (z, fun _ -> EOS)         (* No more input from sf. *)
    | More (y, f) ->
      let update x = compose (f x) (g y) in (* Feed sf's output y to sg. *)
      More (z, update)
```

Think of it as connecting boxes with wires: every box has one incoming wire and one outgoing wire. When composing `sf` and `sg`, the output of `sf` becomes the input of `sg`. Notice that the output stream is "ahead" of the input stream -- `sg` can produce its first output `z` before `sf` has produced anything.

### 7.8 Pipes

The `iostream` type has a limitation: it must alternate strictly between producing output and consuming input. In many real-world scenarios, we need more flexibility:

- A transformation might consume several inputs before producing a single output (like computing an average).
- A transformation might produce several outputs from a single input (like splitting a string).
- A transformation might produce output without needing any input (like a constant source).

Following the Haskell tradition, we call this more flexible data structure a `pipe`:

```ocaml env=ch7
type ('a, 'b) pipe =
  EOP                                       (* End of pipe -- done processing *)
| Yield of 'b * ('a, 'b) pipe               (* Produce output b, then continue *)
| Await of ('a -> ('a, 'b) pipe)            (* Wait for input a, then continue *)
```

A pipe can be in one of three states: finished (`EOP`), ready to produce output (`Yield`), or waiting for input (`Await`). The key insight is that `Yield` includes the continuation pipe directly (not wrapped in a function), so multiple outputs can be produced in sequence without requiring input. For incremental processing where outputs should be lazy, you would change `Yield` to hold a lazy pipe instead.

Again, we can specialize to input-only and output-only pipes:

```ocaml env=ch7
type 'a ipipe = (unit, 'a) pipe
type void = |
type 'a opipe = ('a, void) pipe
```

Why `void` rather than `unit`, and why only for `opipe`? Because an output pipe never yields values -- if it used `unit` as the output type, it could still yield `()` values. But `void` is an empty variant with no constructors, making it impossible for an `opipe` to yield anything. This is a type-level guarantee that output pipes only consume.

#### Pipe Composition

Composition of pipes is like "concatenating them in space" or connecting boxes. We plug the output of pipe `pf` into the input of pipe `pg`:

```ocaml env=ch7
let rec compose pf pg =
  match pg with
  | EOP -> EOP                            (* pg is done -- composition is done. *)
  | Yield (z, pg') -> Yield (z, compose pf pg')  (* pg has output -- pass it through. *)
  | Await g ->                            (* pg needs input -- try to get it from pf. *)
    match pf with
    | EOP -> EOP                          (* pf is done -- no more input for pg. *)
    | Yield (y, pf') -> compose pf' (g y)  (* pf has output -- feed it to pg. *)
    | Await f ->                          (* Both waiting -- wait for external input. *)
      let update x = compose (f x) pg in
      Await update

let (>->) pf pg = compose pf pg
```

The `>->` operator lets us chain pipes together like Unix pipes: `source >-> transform >-> sink`.

Appending pipes means "concatenating them in time" rather than in space. When the first pipe finishes, we continue with the second:

```ocaml env=ch7
let rec append pf pg =
  match pf with
  | EOP -> pg                               (* pf is exhausted -- continue with pg. *)
  | Yield (z, pf') -> Yield (z, append pf' pg)  (* pf has output -- pass it through. *)
  | Await f ->                              (* pf awaits input -- pass it through. *)
    let update x = append (f x) pg in
    Await update
```

We can also append a list of ready results in front of a pipe. This is useful for producing multiple outputs at once:

```ocaml env=ch7
let rec yield_all l tail =
  match l with
  | [] -> tail
  | x::xs -> Yield (x, yield_all xs tail)
```

Finally, the `iterate` function creates a pipe that repeatedly applies a side-effecting function to its inputs. This is **not functional** (it performs side effects), but it is useful for output:

```ocaml env=ch7
let rec iterate f : 'a opipe =
  Await (fun x -> let () = f x in iterate f)
```

### 7.9 Example: Pretty-Printing

Now let us apply pipes to a substantial example: pretty-printing. The goal is to print a hierarchically organized document with a limited line width. When a group of text fits on the current line, we keep it together; when it does not fit, we break it across multiple lines.

```ocaml env=ch7
type doc =
  Text of string | Line | Cat of doc * doc | Group of doc
```

The document type has four constructors:

- `Text s` -- literal text
- `Line` -- a potential line break (rendered as a space if the group fits, or a newline if it does not)
- `Cat (d1, d2)` -- concatenation
- `Group d` -- a group that should be kept together if possible

Some convenient operators for building documents:

```ocaml env=ch7
let (++) d1 d2 = Cat (d1, Cat (Line, d2))
let (!) s = Text s

let test_doc =
  Group (!"Document" ++
            Group (!"First part" ++ !"Second part"))
```

The pretty-printer should produce different outputs depending on the available width:

```text
# let () = print_endline (pretty 30 test_doc);;
Document
First part Second part

# let () = print_endline (pretty 20 test_doc);;
Document
First part
Second part

# let () = print_endline (pretty 60 test_doc);;
Document First part Second part
```

#### Straightforward Solution

Before diving into pipes, let us implement a straightforward recursive solution:

```ocaml env=ch7
let pretty w d =               (* Allowed width of line w. *)
  let rec width = function     (* Compute total length of subdocument. *)
    | Text z -> String.length z
    | Line -> 1                (* A line break takes 1 character (space or newline). *)
    | Cat (d1, d2) -> width d1 + width d2
    | Group d -> width d in
  let rec format f r = function  (* f: flatten (no breaks)? r: remaining space. *)
    | Text z -> z, r - String.length z
    | Line when f -> " ", r-1  (* Flatten mode: render as space. *)
    | Line -> "\n", w          (* Break mode: newline, reset remaining to full width. *)
    | Cat (d1, d2) ->
      let s1, r = format f r d1 in
      let s2, r = format f r d2 in
      s1 ^ s2, r
    | Group d -> format (f || width d <= r) r d  (* Flatten if group fits. *)
  in
  fst (format false w d)       (* Start outside any group (not flattening). *)
```

The `format` function takes a boolean `f` (are we in "flatten" mode?) and the remaining space `r`. When we enter a `Group`, we check if the whole group fits in the remaining space. If so, we format it in flatten mode (all `Line`s become spaces).

#### Stream-Based Solution

The straightforward solution works, but it has a problem: for each group, we compute `width` by traversing the entire subtree, potentially doing redundant work. The stream-based solution processes the document incrementally, computing positions as we go.

First, we define a type for document elements that can carry annotations:

```ocaml env=ch7
type ('a, 'b) doc_e =          (* Annotated nodes, special for group beginning. *)
  TE of 'a * string | LE of 'a | GBeg of 'b | GEnd of 'a
```

The type parameters `'a` and `'b` allow different annotations for different elements. `GBeg` (group beginning) has a different type because it will eventually carry the end position of the group.

Normalize a subdocument to remove empty groups:

```ocaml env=ch7
let rec norm = function
  | Group d -> norm d
  | Text "" -> None
  | Cat (Text "", d) -> norm d
  | d -> Some d
```

Generate the stream of document elements by infix traversal:

```ocaml env=ch7
let rec gen = function
  | Text z -> Yield (TE ((),z), EOP)
  | Line -> Yield (LE (), EOP)
  | Cat (d1, d2) -> append (gen d1) (gen d2)
  | Group d ->
    match norm d with
    | None -> EOP
    | Some d ->
      Yield (GBeg (),
             append (gen d) (Yield (GEnd (), EOP)))
```

The next pipe computes the position (character count from the beginning) of each element:

```ocaml env=ch7
let rec docpos curpos =
  Await (function                   (* Input from a doc_e pipe, *)
  | TE (_, z) ->
    Yield (TE (curpos, z),          (* output doc_e annotated with position. *)
           docpos (curpos + String.length z))
  | LE _ ->                         (* Spaces and line breaks: 1 character. *)
    Yield (LE curpos, docpos (curpos + 1))
  | GBeg _ ->                       (* Groups themselves have no width. *)
    Yield (GBeg curpos, docpos curpos)
  | GEnd _ ->
    Yield (GEnd curpos, docpos curpos))

let docpos = docpos 0               (* The whole document starts at position 0. *)
```

Now comes the tricky part. We want to annotate each `GBeg` with the position where the group *ends*, so we can decide whether the group fits on the line. But we see `GBeg` before we see `GEnd`! We need to buffer elements until we see the end of each group:

```ocaml env=ch7
let rec grends grstack =
  Await (function
  | TE _ | LE _ as e ->
    (match grstack with
    | [] -> Yield (e, grends [])         (* No groups waiting -- yield immediately. *)
    | gr::grs -> grends ((e::gr)::grs))  (* Inside a group -- buffer the element. *)
  | GBeg _ -> grends ([]::grstack)       (* Start a new group: push empty buffer. *)
  | GEnd endp ->
    match grstack with                   (* End the group on top of stack. *)
    | [] -> failwith "grends: unmatched group end marker"
    | [gr] ->                          (* Outermost group -- yield everything now. *)
      yield_all
        (GBeg endp::List.rev (GEnd endp::gr))  (* Annotate GBeg with end position. *)
        (grends [])
    | gr::par::grs ->                    (* Nested group -- add to parent's buffer. *)
      let par = GEnd endp::gr @ [GBeg endp] @ par in
      grends (par::grs))               (* Could use catenable lists for efficiency. *)
```

This works, but it has a problem: we wait until the entire group is processed before yielding anything. For large groups (or groups that exceed the line width), this is wasteful. We can optimize by flushing the buffer when a group clearly exceeds the line width -- if we know a group will not fit, there is no need to remember where it ends:

```ocaml env=ch7
type grp_pos = Pos of int | Too_far

let rev_concat_map ~prep f l =
  let rec cmap_f accu = function
    | [] -> accu
    | a::l -> cmap_f (prep::List.rev_append (f a) accu) l in
  cmap_f [] l

let rec grends w grstack =
  let flush tail =                   (* When a group exceeds width w, *)
    yield_all                     (* flush the stack -- yield everything buffered. *)
      (rev_concat_map ~prep:(GBeg Too_far) snd grstack)
      tail in                        (* Mark flushed groups as Too_far. *)
  Await (function
  | TE (curp, _) | LE curp as e ->
    (match grstack with              (* Track beginning position of each group. *)
    | [] -> Yield (e, grends w [])   (* No groups -- yield immediately. *)
    | (begp, _)::_ when curp-begp > w ->
      flush (Yield (e, grends w []))    (* Group too wide -- flush and yield. *)
    | (begp, gr)::grs -> grends w ((begp, e::gr)::grs))  (* Buffer element. *)
  | GBeg begp -> grends w ((begp, [])::grstack)  (* New group: remember start pos. *)
  | GEnd endp as e ->
    match grstack with               (* No longer fail when stack is empty -- *)
    | [] -> Yield (e, grends w [])   (* could have been flushed earlier. *)
    | (begp, _)::_ when endp-begp > w ->
      flush (Yield (e, grends w []))    (* Group exceeded width -- flush. *)
    | [_, gr] ->                     (* Group fits -- annotate with end position. *)
      yield_all
        (GBeg (Pos endp)::List.rev (GEnd endp::gr))
        (grends w [])
    | (_, gr)::(par_begp, par)::grs ->  (* Nested group fits -- add to parent. *)
      let par =
        GEnd endp::gr @ [GBeg (Pos endp)] @ par in
      grends w ((par_begp, par)::grs))

let grends w = grends w []           (* Initial stack is empty. *)
```

Finally, the `format` pipe produces the resulting stream of strings. It maintains a stack of booleans indicating which groups are being "flattened" (rendered inline), and the position where the current line would end:

```ocaml env=ch7
let rec format w (inline, endlpos as st) = (* inline: stack of "flatten this group?" *)
  Await (function                          (* endlpos: position where line ends *)
  | TE (_, z) -> Yield (z, format w st)    (* Text: output directly. *)
  | LE p when List.hd inline ->
    Yield (" ", format w st)               (* In flatten mode: line break -> space. *)
  | LE p -> Yield ("\n", format w (inline, p+w))  (* Break mode: update endlpos. *)
  | GBeg Too_far ->                        (* Group too wide -- don't flatten. *)
    format w (false::inline, endlpos)
  | GBeg (Pos p) ->                        (* Group fits if it ends before endlpos. *)
    format w ((p<=endlpos)::inline, endlpos)
  | GEnd _ -> format w (List.tl inline, endlpos))  (* Pop the inline stack. *)

let format w = format w ([false], w)   (* Start with no flattening, full line width. *)
```

Put the pipes together into a complete pipeline:

```text
+--------+     +-------+     +---------+     +--------+     +----------------+
| gen doc| --> |docpos | --> |grends w | --> |format w| --> |iterate print_s |
+--------+     +-------+     +---------+     +--------+     +----------------+
```

The data flows from left to right: `gen` produces document elements, `docpos` annotates them with positions, `grends` annotates group beginnings with their end positions, `format` decides where to break lines and produces strings, and `iterate print_string` prints the strings.

#### Factored Solution

For maximum flexibility, we can factorize `format` into two parts: one that decides where to break lines (producing annotated document elements), and one that converts those to strings. This allows different line breaking strategies to be plugged in:

```ocaml env=ch7
(* breaks: decides where to break, outputs annotated doc_e elements *)
let rec breaks w (inline, endlpos as st) =
  Await (function
  | TE _ as e -> Yield (e, breaks w st)          (* Pass through text. *)
  | LE p when List.hd inline ->
    Yield (TE (p, " "), breaks w st)             (* Flatten: convert to space. *)
  | LE p as e -> Yield (e, breaks w (inline, p+w))  (* Break: keep as LE. *)
  | GBeg Too_far as e ->
    Yield (e, breaks w (false::inline, endlpos))
  | GBeg (Pos p) as e ->
    Yield (e, breaks w ((p<=endlpos)::inline, endlpos))
  | GEnd _ as e ->
    Yield (e, breaks w (List.tl inline, endlpos)))

let breaks w = breaks w ([false], w)

(* emit: converts doc_e elements to strings *)
let rec emit =
  Await (function
  | TE (_, z) -> Yield (z, emit)                 (* Text: output directly. *)
  | LE _ -> Yield ("\n", emit)                   (* Line break: output newline. *)
  | GBeg _ | GEnd _ -> emit)                     (* Group markers: skip. *)

let pretty_print w doc =
  gen doc >-> docpos >-> grends w >-> breaks w >->
  emit >-> iterate print_string
```

Now `breaks` can be replaced with a different strategy (for example, one that adds indentation), and `emit` stays the same. The full pipeline reads like a description of what happens: generate elements, compute positions, annotate groups with their ends, decide where to break, convert to strings, and print.


## Acceptance criteria

Compare the direct formatter and pipe formatter on nested finite documents,
including empty groups, a single word wider than the line, and widths zero and one.
Report the output policy for an unbreakable word explicitly. Count buffered
elements for deeply nested groups; do not claim a bounded-memory algorithm
merely because its interface is called a pipe.
