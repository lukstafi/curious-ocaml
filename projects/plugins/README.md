# Project: separately compiled expression plugins

Run `dune runtest projects/plugins` to build and test the host and native plugin.
To run it explicitly from the repository root:

```text
dune build projects/plugins/host.exe projects/plugins/negate_plugin.cmxs
dune exec projects/plugins/host.exe -- _build/default/projects/plugins/negate_plugin.cmxs
```

The host links `plugin_api` and `Dynlink`, not `negate_plugin`. The test rule
supplies the separately built `.cmxs` path at runtime. The plugin registers unary
negation for parsing, evaluation and printing, and supports nesting with all core
arithmetic and local-binding forms. `Plugin_api.of_closed` uses the shared
expression fold to embed the closed language.

Failure checks cover syntax before registration, a constructor with no operation
handler, a missing file, wrong arity, duplicate registration and repeated loading.
An interface or compiler mismatch can also cause `Dynlink.Error`; use artifacts
built in the same switch. Loading a plugin executes trusted native code.

Extension acceptance criteria: implement an absolute-value plugin without editing
the original API, check nesting in both directions, round-trip its printed syntax,
and retain explicit missing-operation failures. Adding another operation requires
handlers for supported extensions; dynamic loading does not supply exhaustive
static coverage of an open constructor set.
