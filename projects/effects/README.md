# Project: owned cooperative tasks

Run `dune runtest projects/effects`. Read Chapter 9 for the full derivation,
operation policies and ownership argument. `runtime.mli` is the public interface;
`runtime.ml` implements the scheduler; `script.ml` represents the same operations
as monadic syntax; `laws.ml` runs the shared behavioral tests.

The tested scope policy cancels unfinished children on root completion or first
failure, unwinds suspended cleanup, rejects foreign handles, and detects a blocked
run with no ready work. It is single-domain and cooperative. Task code must not
swallow cancellation indefinitely; cleanup must not suspend. No external I/O loop
or production-runtime claim is implied.

A useful extension is logical deadlines. Before implementing them, specify the
ordering of a deadline and completion on the same tick. Add that expected trace
to the shared test functor, then implement both program representations. Keep
wall-clock time out of the reference tests.
