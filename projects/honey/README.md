# Project: complete Honey Islands search

**Prerequisites:** Chapter 6; Chapter 8 for the choice and transformer versions.
Run `dune runtest projects/honey` from the repository root. The implementation is
`honey.ml`, and the reference comparisons are in `laws.ml`. No GUI is required.

A task provides a finite list of distinct honey cells on the hexagonal lattice,
a nonnegative number of islands, and a positive island size. Eat some cells so
that the retained cells form exactly that many connected components, each of the
required size. `board n` supplies the standard radius-`n` board; initially empty
cells are simply omitted from `honey`. Two cells are adjacent when their difference
is one of the six offsets in `adjacent`.

## Specification and counterexample

`valid` floods each component of the retained set and counts its cells. It also
rejects duplicate removals and removals outside the original honey. The reference
solver enumerates all subsets of removals and filters them through this checker.
Its exponential cost is acceptable for tiny instances used as an oracle.

The old traversal started an island at the first unvisited honey cell and forced
that cell to stay. On the radius-two board containing only `(-4,0)`, `(2,0)` and
`(4,0)`, the unique answer for one island of size two is to eat `(-4,0)`.
The old traversal could not express that decision and returned no answers.

Every maintained solver now makes an eat/keep decision at **every** cell,
including the first. `direct` explores both branches. `optimized` additionally
tracks the required removals, rejecting a branch only if it needs a negative
number of removals or more than the remaining cells. Those bounds are necessary
conditions; they cannot prune a successful completion. `Monadic.solve` expresses
the same choices through a module interface. `transformer` uses `StateT(List)`,
so each branch has its own removal list.

## What is checked and why it matters

For all 128 initial occupancies of the seven-cell radius-one board, the tests
compare all four solvers with exhaustive subsets, for island sizes 1–3 and counts
0–3. They check the isolated-seed regression, reversed traversal order, impossible
cardinalities and invalid zero island size. Equality is between sets of removal
sets, so enumeration order is intentionally irrelevant.

Soundness follows from filtering with `valid`. For completeness, induct on the
remaining cell list: any target subset either contains its head or does not;
the corresponding branch represents it, and induction covers the tail. The
pruning inequalities hold for every subset of the required cardinality. For the
monadic and transformer versions, the list interpreter preserves both choices
and threads each branch's state separately. An arbitrary module matching the
signature need not satisfy that semantic claim (Chapter 8).

## Extension and acceptance criteria

Add connectivity pruning. State a necessary condition for a partial assignment
to be completable and justify it before using it. Keep the exhaustive comparisons,
add a failing example for every discovered bug, and test permutations of the input
cell list. Only then compare visited-node counts on larger boards. A faster solver
that loses a removal set has failed the project.

## Drawing a solution

Run `dune exec projects/honey/draw.exe -- /tmp/honey.svg` to render one solution.
`draw.ml` turns the hexagonal coordinates into polygons and writes a standalone
SVG with a title, description and crossed-out removals. It is a separate consumer
of the solver result and validates the result before drawing. `Fun.protect`
closes the output channel even if rendering fails. The old Bogue screen renderer
remains historical; this project needs no window system or GUI package.
