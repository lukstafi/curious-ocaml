# Project: finite approximations and formal coefficients

**Prerequisites:** Chapter 7; power series and elementary calculus. Run
`dune runtest projects/numerical`. The module is `polynomial.ml`.

## Two contracts

A finite coefficient list `[a0; ...; an]` denotes a polynomial. `[]`, `[0.]`, and
`[0.;0.]` denote the same zero polynomial; `trim` chooses the empty representation.
Horner evaluation processes every coefficient, including zeros. Integration adds
a supplied constant; differentiation drops the old constant. These operations use
floats, so identities inherited from exact coefficients can acquire roundoff.

A formal series quotient is a different operation. Given denominator constant
`b0 <> 0`, the first `terms` quotient coefficients are determined recursively by

$$q_n=(a_n-\sum_{k=1}^n b_k q_{n-k})/b_0,$$

with omitted finite coefficients treated as zero. `quotient` implements this
recurrence, checks finite input and output, and always terminates after the
requested prefix. A finite denominator with trailing zeros is normalized; an
all-zero denominator is rejected, even if the numerator is zero. A leading-zero
nonzero denominator is also rejected: factor cancellation or Laurent series
would require a different contract. An empty requested prefix does not waive
those denominator preconditions. The quotient may be infinite even when both
inputs are finite, as `1 / (1-x)` demonstrates.

These algebraic operations do not prove that a series converges at a real input.
The geometric series converges for `abs x < 1`; a coefficient recurrence by
itself supplies no such domain or error estimate. Roundoff can accumulate,
cancellation can destroy relative accuracy, and tiny coefficients may underflow.
Exact rational coefficients would remove those arithmetic errors but would still
not prove analytic convergence.

## A bounded numerical example

`exp_unit ~degree:n x` evaluates exactly `n+1` Taylor terms in floating-point
arithmetic, for `0 <= x <= 1` and `0 <= n <= 20`. There is no “small coefficient”
termination test. In real arithmetic, Taylor's theorem gives

$$|e^x-\sum_{k=0}^n x^k/k!| \leq 3/(n+1)!,$$

since the relevant derivative is `exp` and `exp t <= e < 3` on this interval.
For degree 12, the truncation bound is below $5\cdot10^{-10}$.
This is a **truncation** bound; it does not include floating-point rounding.
Our test compares a finite grid with the standard-library `exp`, with tolerance
$10^{-9}$. That comparison is a regression check, not a certified total-error bound.
The degree limit keeps the factorial-scale recurrence far from overflow; at
extremely small positive inputs, higher terms may still underflow harmlessly for
this absolute-error experiment. We make no relative-error claim for differences
of nearly equal approximations.

The sparse polynomial $1+x^{100}$ explains the failure of the old `exact`
heuristic. Many consecutive partial sums are one, but at `x=1` the answer is two.
No fixed number of equal partial sums certifies the unobserved tail of an
arbitrary coefficient stream.

## Project acceptance criteria

Choose either a certified floating-point error analysis or an exact-rational
coefficient implementation with a proved analytic remainder bound. State the
input domain and absolute or relative error criterion. Keep formal division's
zero/leading-zero cases separate from numerical convergence. Add sparse,
cancellation and boundary-domain tests before extending the method to an ODE.
For a power-series ODE solver, derive the coefficient recurrence and justify
local convergence; restarting at another time is a numerical algorithm requiring
its own error control.
