# Optional historical GUI laboratory

The third-edition game is `projects/reactive/game.ml`, whose three interpretations
are checked against a shared trace without a display server. Chapter 10 is the
maintained explanation of its time and event semantics.

The older Bogue/Lwd/Incremental demonstration remains in `chapter10/chapter10.ml`.
It predates the shared transition and is preserved for porting/library experiments;
it is not an alternative implementation certified by the new game tests.
Install `bogue`, `lwd` and `incremental` in a compatible OCaml switch, then build
it with `dune build --profile gui chapter10/chapter10.exe`. Run it in a graphical
environment. The default book build does not include this historical executable.

A maintained GUI port should consume `Game.step` outputs, map each OS input into
a recorded logical input, and pass the same collision/event trace before drawing.
For Lwd, verify that a new tick invalidates an edge event even when the Boolean
source is unchanged, and distinguish observing an occurrence from consuming it.
A display screenshot is not evidence of the paddle collision rule.
