# CLAUDE.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

"Curious OCaml" is an educational textbook about OCaml covering logic (types), algebra (values), computation (rewrite semantics), functions (lambda calculus), constraints, monads, and more. The content is organized as markdown files with embedded OCaml code blocks that are tested using mdx.

## Build Commands

```bash
# Build the project (compiles code, runs mdx tests, generates combined markdown files)
dune build

# Run mdx tests to verify code examples in markdown
dune runtest

# Build HTML output (in site/ directory)
dune build @site/old_lectures_as_book
dune build @site/new_book

# Build PDF output (requires pandoc and texlive)
dune build @pdfs/old_lectures_as_book
dune build @pdfs/new_book
```

## Architecture

### Content Structure
- `chapter1/` through `chapter11/`: Main lecture content
  - `functional-lectureNN.md`: Primary lecture content with embedded OCaml code
  - `lectureNN-exercises.md`: Exercise files
  - `README.md`: The translation and expansion of the lecture into a textbook chapter 
  - `prelude.ml`: Prelude code loaded before mdx tests for that chapter
  - `LecN*.ml`: Standalone OCaml example files (outdated)
- `exam/`: Exam problems and solutions

### Build System
- Uses dune with mdx plugin (version 0.4) for testing OCaml code blocks in markdown
- Each chapter has a `dune` file with `(mdx (files README.md) (preludes prelude.ml))`
- Root `dune` file concatenates chapter files into:
  - `README.md`: Combined textbook content i.e. READMEs (auto-generated, do not edit)
  - `old_lectures_as_book.md`: Full non-adapted content combining all outdated lectures and exercises (auto-generated)
- `site/dune`: Generates HTML via pandoc with KaTeX for math rendering
- `pdfs/dune`: Generates PDF via pandoc

### Key Dependencies
- mdx: Tests OCaml code blocks embedded in markdown
- pandoc: Converts markdown to HTML/PDF
- KaTeX: Renders LaTeX math in HTML output
- printbox, printbox-text, printbox-html: Pretty-printing libraries used in examples
- ppx_jane, ppx_expect: PPX extensions used in code examples

## Content Conventions

- Math formulas use LaTeX syntax rendered by KaTeX
- OCaml code blocks use triple backticks with `ocaml` language tag
- Auto-generated files (README.md, old_lectures_as_book.md) have a comment: `<!-- Do NOT modify this file, it is automatically generated -->`
- MD_metadata.md contains YAML frontmatter with KaTeX configuration included in generated outputs

## TeXmacs Source File Extraction

The source materials are in TeXmacs format (.tm files). Key knowledge for extracting content:

### TeXmacs Format Basics

TeXmacs uses angle-bracket meta-language syntax:
- Commands: `<command|arg>`, `<command|arg1|arg2>`, etc.
- Document structure in nested format with closing tags
- UTF-8 encoding with special characters preserved

### Custom Syntax Highlighting

The author uses a custom highlighting style with semantic commands:
- `hlkwa`: Keywords (e.g., `if`, `then`, `let`, `fun`)
- `hlstd`: Standard text/identifiers
- `hlopt`: Operators (e.g., `+`, `-`, `=`, `::`)
- `hlnum`: Numeric literals
- `hlcom`: Comments
- `hlendline`: **Margin comments** - explanatory notes appearing in the margin of code blocks

**Important**: The `hlendline` content is particularly valuable as it contains pedagogical commentary explaining what the code does. These should be preserved as inline comments in the extracted code.

### Textbook-ization Strategy

1. Use the automatically extracted `.md` files e.g. chapter1/functional-lecture01.md as scaffolding, audit them against the original `.tm` files e.g. chapter1/functional-lecture01.tm , extract **all** information to README files e.g. chapter1/README.md while adjusting the content and presentation to be more like in a textbook
2. **Use Task agents** for large files (>25k tokens) - they can handle the full document in one pass
3. **Preserve margin comments** by converting `hlendline` content to inline code comments
4. **Extract code blocks** with proper language tagging (```ocaml for this project)
5. **YAML front matter** for metadata (title, author, lecture number, etc.)
6. **Pandoc-flavored Markdown** for enhanced styling (tables, code blocks, math)
7. **Fix escape sequences** - wrap literal `\n`, `\r`, etc. in backticks to avoid LaTeX errors
8. The README.md files e.g. chapter1/README.md should contain the **complete contents**, adjusted for a more textbook-like presentation relative to the slide sources

### Custom Highlighting Command Reference

When encountering TeXmacs code blocks with highlighting:

```
<\code>
  <\with|par-mode|center|par-hyphen|normal>
    <hlkwa|let> <hlstd|x> <hlopt|=> <hlnum|42> <hlendline|This is a margin comment>
  </with>
</code>
```

Should be extracted as:

```ocaml
let x = 42  (* This is a margin comment *)
```

The semantic highlighting commands can be stripped during extraction - they're primarily for visual presentation in TeXmacs.

## Editorial Review of the Translation

### Notes after Chapter 1 pass (2026-01-17)

- **Keep OCaml syntax honest:** avoid pseudo-syntax like `a | b` as a type or constructor application `A(5)`; use real OCaml forms (`type ... = ...`, `A 5`, etc.).
- **Treat Curry–Howard as “pure-core exact”:** if using effects (`raise`, non-termination) as examples, explicitly flag that they live outside the neat proof/program correspondence.
- **Prefer an explicit empty type for $\bot$:** use `type void = |` plus the empty-match idiom `match v with _ -> .` to mirror $\frac{\bot}{a}$.
- **Use consistent proof-rule notation:** for hypothetical derivations, consistently show assumptions with `\genfrac` and an ellipsis (`\vdots`) rather than a misleading single-step fraction.
- **Be deliberate about mdx style:** mix plain ` ```ocaml` blocks (no output) and toplevel `# ...;;` blocks (with output) intentionally; avoid adding outputs in exercise statements.
- **Watch for redundancy:** when expanding lecture notes, keep the “informal explanation” and the “formal rule” but trim repeated restatements of the same idea.

### Notes after Chapter 2 pass (2026-01-17)

- **Avoid shadowing standard names in examples:** prefer `my_list`, `calendar_date`, `compare_int`, etc. over `list`, `date`, `compare` when later code or prose might rely on the standard meaning.
- **Be explicit about OCaml special cases:** constructor capitalization has exceptions (`true`/`false`, `[]`/`(::)`); call this out when teaching “constructors are capitalized” to prevent confusion.
- **Keep “type as polynomial” claims scoped:** note what is exact (finite sums/products) vs heuristic (infinite types, recursion as equations/rational forms), and separate “equal polynomials” from “isomorphic types” as a theorem/goal rather than a given.
- **Make code blocks either self-contained or clearly non-runnable:** if an example depends on earlier definitions or uses external libraries/side effects, use `ocaml skip` or an untagged block rather than letting mdx accidentally execute it.
- **Fix empty-type syntax:** use `type void = |` (and, when needed, the empty match `match v with _ -> .`) rather than an abstract `type void` declaration, which is not valid in an `.ml` context and is conceptually different.

### Notes after Chapter 3 pass (2026-01-17)

- **Separate “composition” from “pipelining”:** distinguish function composition (`Fun.compose` or custom operators like `(-|)`/`(|-)`) from forward application (`(|>)`); when using Markdown tables, remember `|` must be escaped but the OCaml operator name should still be stated explicitly.
- **Keep OCaml application syntax idiomatic:** prefer `f x` and `f (x +. dx)` over C-like `f(x)` in new prose/examples.
- **Be explicit about meta-syntax vs OCaml syntax in semantics:** if you write $C^n(a_1,\ldots,a_n)$, explain the tuple encoding (`C (a1, ..., an)`); likewise, explicitly state that substitution is capture-avoiding.
- **State evaluation-order caveats early:** simplified small-step rules may allow reducing in multiple places; clarify that OCaml is strict and uses a deterministic evaluation order, which matters with effects.
- **Mark toplevel/effectful demonstrations as non-runnable:** put `#trace`, `#install_printer`, and “intentional stack overflow” demos in `ocaml skip` (or untagged) blocks so mdx won’t execute them.
- **Keep numerical demos mdx-stable:** avoid hard-coding float outputs from approximations; prefer code-without-output or results that are robust across platforms/versions.

### Notes after Chapter 4 pass (2026-01-17)

- **Keep reduction-notation consistent:** prefer a single “one-step” arrow (e.g. `\rightsquigarrow`) and use a closure like `\rightsquigarrow^*` when you mean “many steps”, instead of mixing unrelated symbols.
- **Separate equivalence from evaluation:** when introducing full $\beta$-reduction, explicitly say it’s an *equational theory* (often on open terms), and then explain that real languages pick an evaluation strategy (call-by-value / call-by-name) for executing closed programs.
- **Be explicit about currying/η when teaching encodings:** if you say “this is the identity”, show the eta-expanded form too (`fun b t e -> b t e`) so readers don’t get confused about arity.
- **Watch bound-variable typos in math:** in formulas like `\lambda h t. ...`, ensure the bound variables match what’s used in the body; avoid `\lambda ht.` unless you really mean a single argument.
- **Label unsafe OCaml bridges loudly:** if using `Obj.magic` or `#rectypes` to simulate untyped lambda-terms, add a clear “testing-only / not real code” caveat and keep such blocks `ocaml skip` when they would diverge.
- **Keep long traces aligned with definitions:** if you rewrite a combinator (e.g. Church predecessor), update the step-by-step trace accordingly so the reader can follow mechanically.

### Notes after Chapter 5 pass (2026-01-17)

- **Keep type-checker outputs mdx-stable:** avoid asserting exact `'_weakN` names or other version-dependent printer details; prefer `ocaml skip` transcripts or prose like “`'_weak…`”.
- **Explain the value restriction precisely:** frame `'_weak…` as “will become one specific type later” and connect it explicitly to preventing unsoundness from mutation.
- **Make polymorphic recursion examples compile on modern OCaml:** consider locally-abstract types (`type a.`) or explicit polymorphism (`'a.`) and keep the notation consistent with what OCaml actually accepts.
- **Flag polymorphic comparison limits early:** when showing “polymorphic maps”, explicitly note that real-world code typically takes a comparison function (e.g. `Map.Make`) instead of relying on `<`/`=`.

### Notes after Chapter 6 pass (2026-01-17)

- **Keep higher-order utility operators accounted for:** if prose uses `(-|)`/`(|-)`/`concat_map`, ensure a prelude definition exists or use stdlib names directly.
- **Keep backtracking demos mdx-fast:** avoid running large searches or timing benchmarks in mdx; show them as `ocaml skip` transcripts or tiny instances.
- **Name the trade-off when switching folds:** emphasize that `fold_left` changes associativity (and often order) and can change results for non-associative operations.

### Notes after Chapter 7 pass (2026-01-17)

- **Be precise about strict vs lazy defaults:** OCaml is strict with *explicit* laziness; Haskell is lazy with *explicit* strictness.
- **Separate call-by-name streams from call-by-need lazy lists:** explicitly mention recomputation vs memoization, and warn about space leaks when memoizing long prefixes.
- **Treat I/O examples as linear resources:** keep file-based streams/lazy-lists as non-executed examples and mention resource handling (`close_in`) and “don’t traverse twice unless memoized”.

### Notes after Chapter 8 pass (2026-01-17)

- **Keep OCaml feature history accurate:** binding operators (`let*`/`let+`) arrived in OCaml 4.08; treat older Camlp4 syntax extensions as historical.
- **Avoid nondeterminism and expensive runs in mdx:** sampling/benchmarking code should be `ocaml skip` (or deterministically seeded) and should not execute big searches at test time.
- **Separate laws from intuitions:** state what monad (and monad-plus) laws guarantee (associativity/identity) and what they *don’t* (e.g. performance or “correctness” of an effect model).

### Notes after Chapter 9 pass (2026-01-17)

- **Keep chapter topic aligned to the source lecture:** avoid accidentally drifting into “new” topics unless the book outline has intentionally changed.
- **Prefer small runnable snippets + pointers to larger code:** use README examples for concepts and point to `Lec9*` code for full implementations.
- **Make CLI parsing testable:** prefer `Arg.parse_argv` over `Arg.parse` in mdx-tested code so examples don’t depend on real process arguments.
- **Treat external-tool pipelines as documentation:** for `ocamllex`/Menhir examples, show file references and commands as text (or `ocaml skip`) instead of trying to run toolchains inside mdx.
