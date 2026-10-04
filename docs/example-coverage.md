# Example coverage in the third edition

`dune runtest` checks all twelve current chapters and every maintained project
with a Dune test rule. Synchronized excerpts use MDX file includes, so they must
match their compiled module source; chapter assertions exercise those modules.
`scripts/check_book.py` rejects unclassified fences, unexplained skips and an
incorrect combined-manuscript order.

## Explicitly skipped OCaml blocks

| Source | Block | Reason |
|---|---:|---|
| `chapter2/README.md` | 1 | recalled list declaration; executable list examples appear earlier |
| `projects/optics/README.md` | 1 | Haskell type notation, not OCaml source |
| `projects/symbolic/README.md` | 1 | interactive printer and tracing directives; transcript is illustrative |
| `projects/type-inference/README.md` | 1 | illustrative weak-variable printer output; identifiers vary by compiler |
| `projects/type-inference/README.md` | 2 | illustrative value-restriction transcript; printer output varies by compiler |
| `projects/zippers/README.md` | 1 | recalled tree declaration from Chapter 2 |
| `projects/zippers/README.md` | 2 | recalled element-context declaration from Chapter 2 |

## Other non-executed blocks

Blocks tagged `text` are grammars, equations in program notation, commands to run
manually, diagram text, historical transcripts, signatures displayed for reading,
or incomplete exercise inputs. In particular Chapter 2's direct isomorphism
attempt is an intentional missing-case counterexample, its connection record is
an exercise input with external placeholder types, and its `work/get_plan`
pattern example illustrates scope without those application definitions.
The symbolic project's trace has implementation-dependent argument order.
The first pretty-printer transcript in the pipes project illustrates output;
the later executable formatter examples remain MDX checked.

Historical lecture files, alternate `README.claude.md`/`README.codex.md` drafts,
and old standalone `Lec*.ml` examples are preserved but not current book tests.
The historical graphical executable is an explicit `gui` profile target with
Bogue/Lwd/Incremental dependencies. It is not silently counted as passing the
headless game equivalence suite; its porting requirements are in
`projects/gui/README.md`.
