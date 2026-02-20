# Agent Learnings (Staging)

This file collects agent-discovered learnings for later curation into CLAUDE.md / AGENTS.md.

<!-- Entry: task_chapter12-coder | 2026-02-20 -->
### Chapter 12 build and MDX gotchas

- **Float.round API**: OCaml's `Float.round` takes only one argument (the float). It does not accept a rounding direction parameter. Use `Float.floor`, `Float.ceil`, or `Float.round` (rounds to nearest even) directly.
- **MDX env isolation**: Each `env=` tag creates a fully isolated toplevel. The prelude is loaded into every environment, but definitions from one `env=` block are invisible to blocks with a different tag. Plan environment grouping carefully before writing code.
- **Root dune concatenation**: When adding a new chapter, update both the `deps` list and the `action` body in the root `dune` file's README.md rule. Missing either causes a build failure.
- **Pipeline assertion values**: When writing test assertions for multi-stage pipelines, trace through each stage manually. A common error is asserting the wrong intermediate count (e.g., counting words after split without accounting for all tokens).
- **Unicode in code comments**: Characters like `∘`, `≅`, `≠` in OCaml code comments or markdown prose trigger PDF font warnings (`Missing character` from lualatex). These are non-fatal but noisy. Prefer ASCII equivalents in code comments; Unicode is fine in markdown prose where KaTeX/pandoc handles rendering.

<!-- End entry -->

<!-- Entry: task_chapter12-followup-coder | 2026-02-20 -->
### Polymorphic variants in mdx and task artifact hygiene

- **Polymorphic variant naturality examples compile cleanly**: Patterns like `(`Num _ | `Neg _) as e -> eval_base e` in an extended eval function work without type annotation issues in mdx. OCaml infers the correct closed variant type from the pattern match.
- **`env=expr` is available**: No chapter currently claims it, so it can be used for standalone expression-problem examples without conflicting with other env blocks.
- **Task artifact files get committed by automated workflows**: Even if `git status` shows a file as untracked at one point, the agent-pair commit step may stage all new files. Always check `git diff main...HEAD --name-only` to verify no workflow artifacts (e.g., `task_*.md`) made it into the branch before signaling for review.
- **VL lens functor-parameterized encoding**: When demonstrating Van Laarhoven lenses in OCaml, the `ConstF` module functor must be instantiated with a concrete focused type (e.g., `struct type t = int end`). The set direction via `IdF` remains fully polymorphic. This is the cleanest OCaml workaround for the lack of rank-2 polymorphism.

<!-- End entry -->
