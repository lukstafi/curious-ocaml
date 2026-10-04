# Project: a reproducible reactive game

Run `dune runtest projects/reactive`. `game.ml` contains the common transition,
recorded input, expected positions, stream scan, revision-cached signal graph,
effect script, edge detector and per-consumer event cursor. `laws.ml` compares
full state/event traces and checks demand, cleanup and publication failures.

The transition is defined for states reachable from `initial`, valid moves -1/0/1,
and a tick count that fits an OCaml integer. Its deterministic discrete collision
policy is given in Chapter 10. Incremental updates require sampling every tick;
rendering a cached state never advances the game. The direct-style session is
single-threaded and must not be reentered from its publication callback.

A renderer extension must pass the shared trace first, map external input to
logical ticks explicitly, and close the script when observation ends. Preserve
per-consumer event cursors if multiple observers need the same occurrence.
