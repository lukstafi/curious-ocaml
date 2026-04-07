# Proposal: curious-ocaml PR #11 Followups

**Task**: task-69db458c
**Title**: curious-ocaml PR #11 followups: nuanced comparison table, GADT exercise, typed lambda-calculus demo, trim dune stanza

## Goal

Polish chapter 11 of the Curious OCaml book by replacing the binary comparison table with nuanced prose, adding a GADT exercise to section 11.15, inserting a typed lambda-calculus impossibility snippet in section 11.9, and removing an accidentally copied `ocamlopt_flags` from the dune build file.

## Acceptance Criteria

- The binary yes/no table (lines 1042-1046 in `chapter11/README.md`) is replaced with prose that articulates the three-way tradeoff: exhaustiveness checking vs. type precision vs. separate-compilation friendliness; no Unicode ✓/✗ symbols remain in that context (replaced with `yes`/`no` text or removed).
- A new exercise is added to section 11.15 (after the existing exercises) asking students to implement `string_of_expr` as a second `eval_layer`-style operation using the extensible GADT infrastructure, compose it with the arithmetic evaluator, and discuss what infrastructure (the `build_eval` boilerplate) must be duplicated.
- A short `ocaml skip` code snippet is inserted in section 11.9 showing an attempted typed lambda-calculus GADT declaration and the resulting type error or structural problem, making the limitation stated in the prose concrete.
- `(ocamlopt_flags (:standard -O2))` is removed from `chapter11/dune` (the library stanza for `chapter11_examples`).
- `dune build chapter11/` and `dune runtest chapter11/` both pass with no new errors.

## Context

PR #11 (`ch11: add section 11.9 on extensible GADTs as a non-solution`, merged 2026-03-25) added:
- **`chapter11/ExtGADT.ml`**: complete extensible GADT example with arithmetic/boolean sub-languages, `eval_layer`/`eval_chain` handler-composition pattern, and `build_eval` fixpoint.
- **Section 11.9** in `chapter11/README.md` (lines 900-1047): full exposition ending with a summary table comparing three approaches.
- `(ocamlopt_flags (:standard -O2))` was added to the `chapter11_examples` library stanza in `chapter11/dune` — this was noted as accidental in the coder reflection.

The existing table (README.md lines 1042-1046) uses Unicode ✓/✗, which triggers pandoc PDF font warnings:

```
| Extensible variants (11.3) | ✓ | ✓ | ✗ | Low (unindexed) |
| **Extensible GADTs (11.9)** | ✓ | ✓ | ✗ | **High (indexed)** |
| Polymorphic variants (11.7–11.8) | ✓ | ✓ | ✓ | Medium (row types) |
```

The prose already mentions (line 1038) that lambda calculus does not fit cleanly into a typed GADT, but provides no code evidence. Section 11.15 currently has 13 exercises (Exercise 1 through Exercise 13), none covering the GADT section directly.

## Approach

### Item 1: Trim dune stanza (`chapter11/dune`)

Remove the line `(ocamlopt_flags (:standard -O2))` from the library stanza. The resulting stanza should be:

```
(library
 (name chapter11_examples)
 (modules ExtGADT))
```

### Item 2: Nuanced comparison table (README.md, around line 1042)

Replace the markdown table with a prose paragraph that explicitly names the three-way tradeoff. The table columns are already present (data extensibility, functional extensibility, exhaustiveness, type precision), but the table hides nuance: all three rows share the same yes/yes for data+functional extensibility, and the interesting distinction is exhaustiveness vs. type precision vs. separate-compilation behavior. The prose replacement should:

- State that all three extensible approaches (extensible variants, extensible GADTs, polymorphic variants) support both kinds of extensibility.
- Contrast exhaustiveness: polymorphic variants give it; extensible variants and GADTs do not.
- Contrast type precision: GADTs give fine-grained type indices; polymorphic variants give row-type precision; plain extensible variants have none.
- Add the separate-compilation axis: polymorphic variants with recursive modules require tying knots across modules; extensible GADTs and variants extend cleanly across module boundaries.
- Replace any ✓/✗ with `yes`/`no` if a compact summary is retained alongside the prose.

### Item 3: Typed lambda-calculus impossibility snippet (README.md, in section 11.9)

Insert an `ocaml skip` code block immediately after the existing paragraph that explains why lambda calculus does not fit (line 1038). The snippet should show the simplest plausible attempt:

```ocaml
(* Attempt: typed lambda calculus as an extensible GADT *)
type _ expr +=
  | Var : string -> 'a expr          (* what type does a variable have? *)
  | Abs : string * 'b expr -> ('a -> 'b) expr   (* 'a is unconstrained *)
  | App : ('a -> 'b) expr * 'a expr -> 'b expr
```

The accompanying explanation should note: `Var` has no type information (a free variable could have any type `'a`), so the type parameter is unconstrained; `Abs` introduces a binding for an unknown type `'a`; without a type environment threaded through the GADT, the compiler cannot resolve `'a`. The result is that a uniform untyped `eval` is impossible — you need either a universal value type or a full type-environment-indexed GADT (de Bruijn style), both significantly more complex.

### Item 4: GADT exercise (README.md, section 11.15)

Add a new exercise after Exercise 13 (the last current exercise). The exercise should:

1. Ask the student to implement `string_of_expr : 'a expr -> string` as a second handler layer using the `eval_layer` / `build_eval` infrastructure from `ExtGADT.ml` (analogous to `eval_arith` / `eval_bool`).
2. Ask the student to compose the pretty-printer with the arithmetic evaluator in a single `build_eval` call — i.e., register both `arith_string_layer` and `arith_eval_layer`.
3. Ask the student to identify which parts of the `build_eval` boilerplate must be duplicated for the new operation (the `chain` reference, the layer registration loop) and reflect on whether this duplication is acceptable.
4. Optionally: ask the student to abstract the common boilerplate into a functor or first-class module.

The exercise number should be 14, maintaining the existing numbering convention.

## Files Changed

| File | Change |
|---|---|
| `chapter11/dune` | Remove `(ocamlopt_flags (:standard -O2))` from library stanza |
| `chapter11/README.md` | Replace ✓/✗ table with prose (near line 1042); add `ocaml skip` snippet in 11.9 (after line 1038); add Exercise 14 in 11.15 (after line 1421) |
