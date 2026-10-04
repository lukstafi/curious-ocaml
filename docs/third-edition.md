# Third edition: representations, interpreters, and laws

This is the implementation record for the [editorial review](editorial-review-third-edition.md).
The editable manuscript remains in `intro.md` and `chapterN/README.md`.
The second-edition sources remain available at Git revision `69d7c71`;
historical lecture files are not third-edition examples.

## Attribution

The third-edition rewrite is credited to GPT-6 Astra. First-edition authors are
Lukasz Stafiniak, Claude Opus 4.5, and GPT-5.2; second-edition models are
Claude Opus 4.6 and GPT-5.3-Codex. The retained illustrations are credited separately
to Gemini 3 Nano Banana. The introduction carries this edition history.

`MD_metadata_third_edition.md` supplies the current book's author metadata;
`MD_metadata.md` remains the historical lecture compilation's metadata. Changing
the current edition's credits must not relabel historical publications.

## Editorial tone

The book should convey curiosity, delight and the appeal of a construction through
its examples and discoveries. Invite readers to notice a connection, make a
prediction or encounter a surprising counterexample; avoid prescribing their
reaction with repeated assurances that the material is beautiful or elegant.
This is not a ban on expressive language or playful illustrations.

## Reading architecture

| Part | Reading order | Thread |
|---|---|---|
| I. Reasoning about programs | 1, 2, 3, 5; optional 4 | Programs, contexts, evaluation, modules and laws |
| II. Representations and interpreters | 6, 11 | One expression language, folds, binding, parsing and extension |
| III. Computation over time and choices | 7, 8, 9, 10 | Demand, search, inference, owned continuations and reproducible time |
| IV. Mathematical synthesis | 12 | Explicit hypotheses and universal properties |

Chapter numbers and source locations stay stable so that existing links remain useful.
Within each part, prerequisites and route notes explain the dependencies.

## Implementation checklist

- [x] Practical start, audience routes, prerequisites and graded exercises.
- [x] Separate cardinality, series and isomorphisms; compare two kinds of holes.
- [x] Shared expressions: direct evaluation, CPS, defunctionalization, machine, folds.
- [x] Runnable lambda interpreter; safe evaluation-strategy experiments.
- [x] Refocused modules/specifications and executable map laws.
- [x] Search reference models and completeness checks, including Honey Islands.
- [x] Stream cost/resource model and numerical approximation contracts.
- [x] Search interpreters, choice laws and a motivated transformer comparison.
- [x] Effects project with ownership, failure, nesting, cancellation and cleanup tests.
- [x] Common finite probability models across enumeration, weighting and replay.
- [x] Common reactive transition and expected traces across three interpreters.
- [x] Binding/parser tests, extension comparison and separately compiled plugins.
- [x] Carefully derived category constructions and source review.
- [x] Reproducible Markdown/HTML/PDF, skip classification and release verification.

## Verification record

The maintained suite passes locally with OCaml 5.5.1. The commands used were:

```text
python3 scripts/check_book.py
dune runtest
dune build
dune build README.md curious.opam chapter9/sensor_fusion.exe
dune build @site/new_book @pdfs/new_book
dune exec projects/honey/draw.exe -- /tmp/honey.svg
git diff --check
```

`dune runtest` includes all twelve current chapter READMEs, the executable
optional-reading projects, and the compiled tests below. The new CI matrix runs
the core checks on OCaml 5.3.0 and 5.5.1, without a GUI or a TeX dependency.
Generated Markdown and opam metadata must agree with the checked-in files.

| Claim | Evidence |
|---|---|
| Evaluation representations agree | Generated direct/CPS/machine/fold comparisons, first-error behavior, signed zero and depth-100000 machine run |
| Binding avoids capture | Shadowing/freshness regressions, de Bruijn scope checks, strategy and Church/Scott reduction tests |
| Map implementations respect their contracts | Shared observational law functor, deletion regression, bounded-string partial-operation checks, red-black invariants |
| Search retains answers | Countdown multiset/reference comparisons; all 128 radius-one Honey occupancies across four solvers plus isolated-seed regression |
| Choice needs more than a signature | Search interpretation laws and the left-biased option distributivity counterexample |
| Demand respects scope | Early-exit, exception and escaped-reader cleanup checks, including a real temporary file |
| Numerical claims have a domain | Finite polynomial/quotient edge cases, sparse polynomial regression, Taylor grid against a separately stated truncation bound |
| Suspensions have owners | Shared effects/monadic tests for interleaving, failure, cancellation, scope exit, nesting and cleanup; deadlock and foreign-handle tests |
| Inference uses the same models | Finite enumeration, likelihood weighting and replay comparisons for observation, early completion, zero mass and impossible evidence |
| Reactive implementations agree | Recorded expected positions/events and 100 seeded traces across streams, cached signals and effects; tick/event and cleanup regressions |
| Plugins really load separately | Host links the API only; separately built native extension; missing/unregistered/duplicate/wrong-arity failures |
| Category claims have stated premises | Explicit categories and extensional equality, inductive functor/fold proofs, natural currying bijection, both Yoneda inverse laws |

The project catalogue is [projects/README.md](../projects/README.md).
[Example coverage](example-coverage.md) classifies every maintained skipped block
and distinguishes synchronized source excerpts, executable examples, display
notation and historical material.

## Proof and source review

Chapter 12 now restricts its main results to finite data and total pure maps in
Set (or explicitly named poset categories). The fold proof establishes existence
and uniqueness; the adjunction gives inverses and naturality; the Yoneda proof
uses functor laws and naturality for both round trips. Its OCaml counterexample
shows why an unrestricted polymorphic type is insufficient. These arguments were
checked against Riehl's *Category Theory in Context*, especially Theorem 2.2.4.
The distinction between element and subtree derivatives was checked against
Abbott et al., *Derivatives of Containers*. Both sources are linked in Chapter 12.
OCaml effect syntax and one-shot continuation behavior were checked against the
5.3 manual linked in Chapter 9. This is an editorial proof review, not formal
verification by a proof assistant.

## Publication status and boundaries

The combined book and HTML were regenerated, and the PDF rebuilt with Pandoc and
LuaLaTeX. Pagination was inspected across all pages as contact sheets, with
full-size checks of the cover, part titles, code and mathematical pages. The
publication fixes include an explicit cover-image dependency, single part labels,
normal section flow and wrapped code lines. The PDF has searchable text and
bookmarks, but is not a tagged PDF and has **not** passed a screen-reader or PDF/UA
audit. HTML remains the structured reading format. Full accessibility certification
is a separate release task, not established by successful compilation.

The old Bogue/Lwd/Incremental GUI is preserved as a historical optional target;
it was not run interactively or silently counted as a successful third-edition
example. Its porting contract is in [the GUI project](../projects/gui/README.md).
The new headless game supplies the shared transition and trace checks requested
by the review. Honey's current drawing consumer produces SVG without GUI packages.

Replay inference still requires pure replayable models, finite representable
weights and short traces; its comparisons are regressions, not a proof of
statistical consistency. The teaching scheduler is cooperative and single-domain,
and requires cancellation-respecting tasks and non-suspending cleanup. The
numerical project proves a truncation bound, not a floating-point total-error bound.
Those restrictions are part of the examples' contracts.

This rewrite replaces and condenses the main route; it does not claim that every
second-edition example has been ported. Larger maintained lessons moved into
optional projects, and the entire prior edition remains at revision `69d7c71`.
