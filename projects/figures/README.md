# Data behind the technical diagrams

`data.ml` uses the maintained expression, search, and game implementations to
export the evaluator's ten states, the three search observations, and the full
fourteen-tick game trace. It also checks that all three game interpretations agree.
`dune runtest` compares that output with `data.json`; CI then checks the SVGs
against the committed data and drawing source.

From the repository root, regenerate the data with
`dune exec projects/figures/data.exe > projects/figures/data.json`.
Run `python3 scripts/render_figures.py --pdf` to regenerate all five SVG/PDF
pairs. This authoring command needs Python's `reportlab` package; the normal
OCaml tests and `python3 scripts/render_figures.py --check` do not.
Use `python3 scripts/render_figures.py --check --pdf` to verify both formats
without modifying files (with the same ReportLab version used for generation).
The PDF book uses the committed vector PDF companions, so its build does not
need ReportLab or an SVG converter.

Edit the drawing primitives in `scripts/render_figures.py`, rather than changing
a generated SVG alone. The two conceptual diagrams (holes and continuation
ownership) are explanatory drawings, not execution traces. Their claims are
checked by the chapter's reconstruction examples and runtime tests respectively.
See [the illustration record](../../docs/illustrations.md) for asset credits and
publication conventions.
