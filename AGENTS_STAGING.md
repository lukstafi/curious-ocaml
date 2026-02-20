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
