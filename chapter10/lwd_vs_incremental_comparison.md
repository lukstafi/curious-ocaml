# Lwd vs Incremental: A Technical Comparison

Both libraries implement **self-adjusting computation** (incremental/reactive programming) in OCaml, but with very different design philosophies.

---

## Lwd (Lightweight Reactive Documents)

**Core Philosophy**: Minimalist, focused on UI rendering with a document/tree metaphor.

### Key Design Choices

1. **Compact Node Representation**: Nodes are either `Pure` (constant), `Operator` (computed), or `Root` (observer). The `desc` type encodes what computation the node performs (Map, Map2, Pair, Join, Var, Prim, Fix).

2. **Specialized Trace Structures**: The `trace` type uses a clever optimization with `T0`, `T1`, `T2`, `T3`, `T4`, and `Tn` variants — specialized representations for 0-4 parents, only allocating an array (`Tn`) when there are 5+ parents. This is memory-efficient for trees where most nodes have few dependents.

3. **Push-based Invalidation**: When a `Var` changes, invalidation propagates *upward* through the `trace` to all ancestors, marking them `Eval_none`. The actual recomputation is pull-based — values are computed lazily during `sample`.

4. **Acquire/Release Protocol**: Lwd tracks which parts of the graph are "live" (reachable from a root observer). The `Prim` nodes have explicit `acquire`/`release` callbacks, enabling resource management (e.g., DOM nodes, subscriptions).

5. **Join for Dynamic Graphs**: The `Join` combinator enables graphs whose structure changes at runtime — the `intermediate` field caches the currently-active inner computation.

6. **Covariance Hack**: Uses `%identity` casts to convince OCaml that `'a t` is covariant, which it actually is but can't be proven due to mutable fields.

---

## Incremental (Jane Street)

**Core Philosophy**: Industrial-strength, optimized for large-scale financial systems with complex dependency graphs.

### Key Design Choices

1. **Rich Node Record**: A single massive record type with ~30 mutable fields covering:
   - Stabilization timestamps (`recomputed_at`, `changed_at`)
   - Value caching (`value_opt`, `old_value_opt`)
   - Heap positions for scheduling (`height_in_recompute_heap`, linked list pointers)
   - Parent/child indexing arrays for O(1) edge manipulation
   - Observer management, on-update handlers, debugging info

2. **Height-based Topological Ordering**: Nodes have explicit `height` ensuring children are always recomputed before parents. The "recompute heap" (a priority queue by height) processes nodes in correct order.

3. **Stabilization Numbers**: Instead of boolean "dirty" flags, uses monotonic counters. A node is stale if any child's `changed_at > parent.recomputed_at`. This enables efficient staleness checks without graph traversal.

4. **Cutoff Support**: Built-in support for short-circuiting propagation when values are "equal enough" (e.g., floating point tolerance).

5. **Specialized Kind Variants**: Has `Map`, `Map2`, ... up to `Map15`, plus specialized nodes for `Bind`, `If`, `Join`, time-based computations (`At`, `At_intervals`, `Snapshot`), array folds, step functions, and an `Expert` mode.

6. **Bidirectional Parent/Child Links**: Maintains arrays mapping child indices to parent indices and vice versa, enabling O(1) edge insertion/removal with swapping.

7. **Scopes**: Supports hierarchical scoping for invalidation boundaries and lifetime management.

---

## Comparative Analysis

| Aspect | Lwd | Incremental |
|--------|-----|-------------|
| **Memory per node** | ~5-7 blocks | ~30+ blocks |
| **Staleness check** | Boolean `Eval_none` | Timestamp comparison |
| **Invalidation** | Eager push to roots | Lazy via timestamps |
| **Recomputation** | Pull on `sample` | Push during `stabilize` |
| **Cutoff** | None built-in | First-class concept |
| **Dynamic graphs** | `Join` | `Bind` with scope tracking |
| **Time handling** | None | Alarms, step functions |
| **Target use case** | UI trees | Financial systems, large DAGs |

---

## Summary

**Lwd** is elegant and lightweight — ideal for reactive UIs where the graph is mostly tree-shaped and memory matters. The acquire/release protocol maps naturally to DOM element lifecycle.

**Incremental** is engineered for correctness and performance at scale — the timestamp-based approach avoids redundant work in deep graphs, height ordering prevents glitches, and the elaborate bookkeeping enables features like on-update handlers and scoped invalidation.
