![Curious OCaml](Curious_OCaml-cover.jpg){.cover-image}

::: {.illustrator-credit}
*Original illustrations: Gemini 3 Nano Banana. Third-edition chapter art:
OpenAI image generation. Technical diagrams: GPT-6 Astra.*
:::

## About the third edition

A pair can be a proof of a conjunction. A tree with a hole can describe an editing
position. An evaluator can become a machine by turning its continuations into
data. This book follows such constructions in OCaml, asking what each
representation preserves and how we can check that claim.

The third edition is organized around **representations, interpreters, and laws**.
We use one small expression language across evaluation, folds, binding, parsing
and extension. We compare search and probability interpreters with finite
reference models. We make ownership and cleanup part of the meaning of an effects
program, and return to these concrete examples in the mathematical synthesis.

### Edition credits

Each edition builds on the preceding work. The credits distinguish the original
book from its later rewrites:

- **First edition:** Lukasz Stafiniak, Claude Opus 4.5, and GPT-5.2.
- **Second edition:** Claude Opus 4.6 and GPT-5.3-Codex.
- **Third-edition rewrite:** GPT-6 Astra.
- **Original illustrations:** Gemini 3 Nano Banana.
- **Third-edition chapter art (6, 7, 10):** OpenAI image generation.
- **Technical diagrams:** GPT-6 Astra.

### Choose a route

The chapter numbers remain stable, but the four parts give the reading order:

| Part | Chapters | Question |
|---|---|---|
| I. Reasoning about programs | 1, 2, 3, 5; optional 4 | What does a program mean, and which laws does it satisfy? |
| II. Representations and interpreters | 6, 11 | What changes when the same language gets a new representation? |
| III. Computation over time and choices | 7, 8, 9, 10 | Who chooses, when does work happen, and who owns suspended work? |
| IV. Mathematical synthesis | 12 | Which constructions have universal properties, under which hypotheses? |

- **Mathematically mature novice:** start with the first session in Chapter 1.
  Follow Part I in order; do the practice exercises before the proofs. Loading a
  file, reading a type error and inspecting a value are part of the course.
- **Experienced programmer new to OCaml:** read Chapter 1's execution and scope
  conventions, Chapter 2's variants and patterns, then Chapters 3 and 5. Return to
  the logical rules and type derivatives after writing a few small programs.
- **OCaml programmer:** use Chapters 2–3 to establish the common examples, then
  follow Parts II–IV. Chapter 4 supplies the optional lambda-calculus route.

Each chapter states its prerequisites. Exercises are labeled **practice** (write
or trace a small program), **proof** (state hypotheses and justify a claim),
**experiment** (measure or find a counterexample), or **project** (combine several
ideas with acceptance criteria). Selected answers accompany the relevant
construction. A passing test is evidence about its inputs, not a universal proof.

### Reading and running

Install the core test dependencies with `opam install . --deps-only --with-test`.
The optional GUI laboratory has separate dependencies listed in its project guide.
Use OCaml 5.3 or later; the effects chapters use its effect-pattern syntax.
From a checkout, run `dune runtest` for the maintained examples. Use
`dune runtest chapter3 projects/expressions` for the evaluator alone. The project
sources under `projects/` are ordinary compiled modules, with tests of laws,
failures and resource behavior. Chapter snippets synchronized with those modules
have MDX file references, so editing one without the other fails the checks.

A code block beginning with `#` is a toplevel transcript: type the text after the
prompt and finish it with `;;`. Other OCaml blocks contain source-file definitions;
do not copy the output of a transcript into a source file. Blocks with an `env`
label share a testing environment within their chapter. Some use the chapter's
`prelude.ml`; the surrounding text identifies additional module dependencies.
A block marked `skip` is not checked by execution and must state its reason.

Edit `intro.md` and `chapterN/README.md`, not the generated root `README.md`.
Build the combined manuscript and web edition with
`dune build README.md @site/new_book`, and the PDF with
`dune build @pdfs/new_book` (Pandoc and LuaLaTeX required).
The original `functional-lecture*.md`, `Lec*.ml`, and alternate chapter drafts
are historical sources, not part of the maintained reading route.

The implementation and publication record is in `docs/third-edition.md`.
