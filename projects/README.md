# Third-edition projects

Run all maintained examples and laws with `dune runtest` from the repository root.
Compiled source excerpts in the chapters are synchronized by MDX with these files.
The projects separate reusable implementations from chapter-local experiments.

| Project | Chapters | Main purpose |
|---|---|---|
| [Expressions](expressions/expr.ml) | 3, 6, 11, 12 | Direct, CPS, machine and fold evaluators; capture-avoiding substitution |
| [Lambda calculus](expressions/lambda.ml) | 4 | De Bruijn terms, two reduction strategies and fuel |
| [Parsing](expressions/parser.ml) | 11 | Full-input S-expression parsing and printer round trips |
| [Honey Islands](honey/README.md) | 6, 8 | Four solvers, exhaustive subset oracle and SVG drawing |
| [Choices](choices/search.ml) | 8 | Shared search syntax interpreted as all, first and count |
| [Streams](streams/scoped.ml) | 7 | Scoped readers and cleanup after early termination |
| [Numerical approximation](numerical/README.md) | 7 | Finite polynomial operations and a stated Taylor error bound |
| [Effects](effects/README.md) | 9 | Owned scheduler and monadic scripts using the same behavior tests |
| [Probability](probability/README.md) | 8, 9 | Finite reference enumeration, weighting and replay |
| [Reactive game](reactive/README.md) | 10 | One transition and trace across three interpreters |
| [Figure data](figures/README.md) | 3, 8, 10 | Executable data for evaluator, search, and game diagrams |
| [Plugins](plugins/README.md) | 11 | Separately compiled dynamic extension and failure cases |

Optional reading preserves larger examples outside the main route:
[symbolic differentiation](symbolic/README.md),
[type inference](type-inference/README.md), [pipes](pipes/README.md),
[zippers](zippers/README.md), and [optics and codensity](optics/README.md).
Their runnable blocks are included in `dune runtest`.
[Historical GUI material](gui/README.md) has a separate dependency and porting contract.
