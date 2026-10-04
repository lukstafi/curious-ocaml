# Project: inference against finite reference models

Run `dune runtest projects/probability`. Build the larger application with
`dune build chapter9/sensor_fusion.exe`. Both use `probability.ml`; there is no
separate copied filter in the application. Chapters 8–9 explain the operations,
likelihood semantics and continuation ownership.

| Model | Derivation of P(true) | Regression it detects |
|---|---|---|
| Observation, then irrelevant draw | `(0.5 * 0.8) / (0.5 * 0.8 + 0.5 * 0.2) = 0.8` | Multiplying the same observation again during replay |
| True finishes; false gets weight 0.25 and another draw | `0.5 / (0.5 + 0.5 * 0.25) = 0.8` | Changing active mass relative to finished mass |
| False has zero weight before another draw | `0.5 / (0.5 + 0) = 1` | Resurrecting zero-weight particles |
| All paths have zero weight | No posterior | Treating impossible evidence as a distribution |

The reference enumerator replays every finite choice prefix and only aggregates
likelihood at completed leaves. Its budget bounds attempted prefixes; exhaustion
is explicit. Likelihood weighting samples whole traces. The particle filter
replays prefixes, avoids recounting old observations and optionally resamples
active particles while preserving their total mass.

Tests compare all methods on these same models with fixed seeds and an absolute
posterior tolerance of 0.035 for 20,000 samples/particles. The reference values
are also checked analytically, so agreement between implementations alone cannot
silently establish the wrong target. A fixed-seed tolerance test catches particular
regressions; it is not a proof of statistical consistency or a universal error
bound. Finite enumeration still uses floating-point weights.

Models must be pure apart from handled choices/observations, terminating on each
explored trace, with deterministic control and support for a fixed trace. They
must not catch the interpreter's internal pause/rejection exceptions. Likelihoods
and Gaussian parameters must be finite; weights are nonnegative, sigma is positive,
and sampling supports and sample counts are nonempty/positive. Impossible evidence
returns `[]`. Continuous draws are rejected by the finite enumerator.

The current application uses short float-weight traces. Underflow, extreme density
values and accumulated rounding are outside its numerical guarantees. A project
extension should move weights to the log domain and specify handling of all-zero
mass, then compare ordinary-range cases to this finite oracle and add extreme
likelihood tests. Do not interpret an underflowed total as evidence of mathematical
impossibility.
