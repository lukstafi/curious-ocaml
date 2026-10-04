# Third-edition illustrations

The cover and most chapter openers retain Gemini 3 Nano Banana's earlier art.
Three openers were refreshed with OpenAI image generation, using their previous
illustrations as visual references. The tool did not expose a model name.
The original JPEGs remain available for the historical editions.

| Chapter | New asset | Scene |
|---|---|---|
| 6 | `chapter6/Curious_OCaml-chapter_6-third-edition.png` | A camel builds expression trees in a lamplit workshop |
| 7 | `chapter7/Curious_OCaml-chapter_7-third-edition.png` | Opening one sluice draws one cup; earlier cups remain nearby |
| 10 | `chapter10/Curious_OCaml-chapter_10-third-edition.png` | A tabletop paddle game seen through three translucent views |

These scenes invite curiosity without prescribing an emotional response. They
carry no technical labels or claims. The five diagrams below do the explanatory
work, with editable vector text and corresponding explanations in the manuscript.

| Chapter | SVG (with a same-named PDF companion) | What it explains |
|---|---|---|
| 2 | `element-subtree-holes.svg` | Removing an element keeps its children; removing a subtree takes them along |
| 3 | `evaluator-frames.svg` | The actual machine states for `(2 + 3) * 4`, including pending frames |
| 8 | `search-interpretations.svg` | The nine leaves of `pairs 4`, observed as all, first, and count |
| 9 | `continuation-ownership.svg` | Clearing the owner's slot before continuing or cancelling |
| 10 | `shared-game-trace.svg` | Four selected event ticks from the identical fourteen-tick traces |

GPT-6 Astra authored the diagrams. Their source is `scripts/render_figures.py`;
SVG and PDF use the same drawing primitives. SVGs include titles and descriptions,
and the chapter captions and surrounding text explain the content independently
of color. PDF labels remain text rather than raster pixels. The HTML uses SVGs;
`pdfs/vector-figures.lua` selects the vector PDF companions for print.

The evaluator, search, and game data come from the compiled implementations via
`projects/figures/data.ml`. Regeneration and checking commands are documented in
[the figure data project](../projects/figures/README.md). The ownership diagram
assumes the runtime's cooperative cancellation contract: finalizers do not
suspend, and tasks respect cancellation. It is not a general claim that arbitrary
effect handlers always terminate cleanup.
