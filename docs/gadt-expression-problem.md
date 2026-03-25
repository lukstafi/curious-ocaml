# Add GADT-based (non)solution(s) to the Expression Problem chapter

## Motivation

Chapter 11 surveys eight approaches to the expression problem but omits GADTs entirely, despite GADTs being a major OCaml feature covered in Chapter 9. Extensible GADTs (`type _ expr = ..`) combine data extensibility with type-level precision, making them a natural candidate for comparison. The GitHub issue ([#1](https://github.com/lukstafi/curious-ocaml/issues/1)) and an [OCaml Discuss thread](https://discuss.ocaml.org/t/best-approach-for-implementing-open-recursion-over-extensible-types/11678) motivate the addition.

## Current State

Chapter 11 sections:
- 11.1 Definition
- 11.2 Ordinary ADTs (non-solution)
- 11.3 Extensible Variant Types (non-solution)
- 11.4 Subtyping
- 11.5 Direct OOP (non-solution)
- 11.6 Visitor Pattern (non-solution)
- 11.7 Polymorphic Variants
- 11.8 Polymorphic Variants with Recursive Modules (verdict: best)
- 11.9--11.13 Parser Combinators capstone
- 11.14 Exercises

The running example throughout is a lambda calculus + arithmetic expression language with `eval` and `freevars` operations. Section 11.3 (`ExtV.ml`) uses extensible variant types (`type expr = ..`) and is the closest existing approach -- it shares the same extensibility mechanism but without type-level indexing.

Key files:
- `chapter11/README.md` -- full chapter text (~1232 lines, mdx-tested code blocks)
- `chapter11/ExtV.ml` -- extensible variant types example
- `chapter11/dune` -- mdx build config with `prelude.ml`

## Proposed Change

Add a new section covering extensible GADTs as a non-solution to the expression problem. The section should:

1. **Placement**: Insert after section 11.8 (Polymorphic Variants with Recursive Modules) as a new section 11.9 "Extensible GADTs". Renumber the parser combinators capstone (current 11.9--11.14) to 11.10--11.15. This placement makes sense pedagogically: it follows the "best place" polymorphic variants solution and precedes the practical capstone, letting the reader see the full spectrum of typed approaches before moving to application.

2. **New code file**: `chapter11/ExtGADT.ml` containing a standalone working example using the chapter's running expression language:
   - Define `type _ expr = ..` as an extensible GADT
   - Add lambda constructors with appropriate type indices
   - Add arithmetic constructors
   - Implement typed evaluators using open recursion / handler composition
   - Demonstrate the catch-all / exception fallback that non-exhaustive matching requires

3. **Section content in README.md**:
   - Brief reference to Chapter 9 GADTs for background
   - Show how extensible GADTs provide type-level precision that plain extensible variants (11.3) lack
   - Explain why this is still a non-solution: OCaml cannot check exhaustiveness for extensible GADTs, so pattern matches need a catch-all, producing the same runtime-failure risk as 11.3
   - Demonstrate the handler-composition pattern from the OCaml Discuss thread (composing partial handlers, with dynamic failure if no handler covers a constructor)
   - Comparative verdict: same non-exhaustiveness penalty as 11.3, but with stronger typing guarantees; weaker exhaustiveness story than polymorphic variants (11.7--11.8) but stronger type precision

4. **Build integration**: Add `ExtGADT.ml` to the `dune` file if needed (the current mdx setup may pick it up automatically).

5. **README table of contents / section list**: Update to reflect the new section and renumbered capstone sections.

### Acceptance criteria (from task file)
- New section in Ch 11 covering GADT-based approach(es)
- New `.ml` file(s) with executable GADT examples
- Explains why extensible GADTs are a non-solution (no exhaustiveness)
- Demonstrates typed-handler composition pattern
- Discusses tradeoffs vs other approaches
- Integrates with the running expression evaluator example
- Code compiles with `dune build`
- README section list updated

## Scope

**In scope:**
- One new section in chapter 11 README.md
- One new `.ml` file (`ExtGADT.ml`)
- Section renumbering of 11.9--11.14 to 11.10--11.15
- README section list update

**Out of scope:**
- Changes to Chapter 9 GADT coverage
- Changes to Chapter 12 categorical explanation (that is gh-curious-ocaml-6)
- Changes to other chapter 11 sections beyond renumbering
- Exercises (could be a follow-up)

**Edge cases to consider:**
- The running example uses an untyped lambda calculus. Fitting it into a typed GADT requires either using a universal type index (e.g., all constructors return `expr` with no type parameter variation) or simplifying to just the arithmetic sub-language for the typed portion. The section should acknowledge this tension explicitly.
- Extensible GADT syntax is less commonly used in OCaml and may need extra annotation for the reader.

**Dependencies:** None blocking. Related task gh-curious-ocaml-6 (Ch 12 categorical explanation) can reference this section once written.
