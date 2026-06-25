# Fix broken test suite: Curious-OCaml — chapter10 `Draw.grey`

## Goal

`dune runtest` fails with a single mdx diff on `chapter10/README.md`: the
evaluated code references `Draw.grey`, which the installed Bogue version
(`bogue 20260208`) does not export, producing `Error: Unbound value
Draw.grey`. Restore a green test suite by replacing the broken reference with
a value the installed Bogue actually exports.

This is a fresh instance of the recurring "Fix broken test suite:
Curious-OCaml" pattern (`subtask_of: task-3c984849`). The prior missing-package
failures are already resolved; this is now purely an API-drift fix in the
chapter text, not a dependency problem.

## Acceptance Criteria

- `cd /Users/lukstafi/curious-ocaml && dune runtest` exits 0 with no mdx diff
  on `chapter10/README.md`.
- Both occurrences of `Draw.opaque Draw.grey` in `chapter10/README.md` are
  replaced with an expression that compiles against the installed Bogue
  (`bogue 20260208`) — the mdx-evaluated `env=ch10` block (the one that
  currently errors) **and** the non-evaluated `skip` block (so the published
  text a reader would copy out is consistent and correct).
- The source `chapter10/README.md` is changed — not merely the generated
  `_build/.../README.md.corrected` artifact.
- No other chapter's tests regress.

## Context

How things work now:

- `chapter10/README.md` is the only failing file. It contains two copies of
  the offending expression `Sdl_area.fill_rectangle area ~color:(Draw.opaque
  Draw.grey) ~w ~h (0, 0);`:
  - One inside a fenced ` ```ocaml skip ` block (the `reactimate`
    animation-loop section). mdx does **not** evaluate `skip` blocks, so this
    copy does not currently error — but it carries the same broken reference.
  - One inside a fenced ` ```ocaml env=ch10 ` block (the `run_bogue`
    interpreter section, "A Bogue Interpreter for the Effects"). mdx
    **evaluates** this block, so it is the one that raises `Unbound value
    Draw.grey`.
  - Anchor for the evaluated block: the `let run_bogue ~(w : int) ~(h : int)
    (script : unit -> unit) : unit =` definition. Locate the two expressions
    by the distinctive substring `Draw.opaque Draw.grey` rather than by line
    number (mdx diff line offsets drift).
- `chapter10/dune` declares `(mdx (files README.md ...) (preludes
  prelude.ml))` plus an `executable` linking `bogue lwd incremental`. No
  change needed.
- `chapter10/prelude.ml` does `#require "bogue";; #require "lwd";; #require
  "incremental";;`. No change needed — the packages are installed
  (`bogue 20260208`, `lwd 0.5`, `incremental v0.17.0`).

Root cause: Bogue's `Draw` module (`B_draw`) exposes color *helpers*
(`Draw.opaque`, `Draw.find_color`, `Draw.transp`) but no bare `grey` value.
Named greys live in the `RGB`/`RGBA` submodules (`Bogue.RGB.grey`,
`Bogue.RGB.pale_grey`) or are reachable by name via `Draw.find_color "grey"`
(which delegates to `RGB.find_color`).

## Approach

*Suggested approach — agents may deviate if they find a better path.*

Replace `Draw.grey` with `Draw.find_color "grey"` in both occurrences:

```ocaml
Sdl_area.fill_rectangle area ~color:(Draw.opaque (Draw.find_color "grey"))
  ~w ~h (0, 0);
```

`Draw.find_color "grey"` returns the RGB triple `(100, 100, 100)`;
`Draw.opaque` adds full alpha. `Draw.` is already in scope via the block's
`let open Bogue in`. This keeps the existing `Draw.`-qualified style. An
equivalent alternative is `Draw.opaque Bogue.RGB.grey`.

Then run `dune runtest`; if mdx emits a corrected diff, promote it / re-run so
the source `README.md` (not just the `.corrected` artifact) is updated, and
confirm a clean exit.

## Scope

In scope:

- The two `Draw.opaque Draw.grey` expressions in `chapter10/README.md`.

Out of scope:

- Any other chapter or file (no other block is failing as of 2026-06-25).
- Upgrading or repinning Bogue/lwd/incremental — packages are present and
  correct.
- Broader prose edits to chapter10 beyond the two color expressions.
