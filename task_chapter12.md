Write Chapter 12 of the book. Use the existing build system setup. Make sure code samples are validated via MDX (use the `ocaml env=...` tag in code blocks).

## Overview

Chapter 12 would be a standalone final chapter combining GADTs and Category Theory. Its distinctive quality is not "here is some category theory" but rather "here is the hidden structure of everything you have learned" — a retrospective unification of the whole book through a categorical lens, with GADTs as the OCaml-specific mechanism that makes categorical structure *enforceable* at the type level.

The book has been doing category theory implicitly throughout: type isomorphisms (Ch 2), homomorphisms (Ch 5), map/fold as functors (Ch 6), monad laws (Ch 8), zippers and contexts (Ch 10), the expression problem as a question about extensibility of morphisms (Ch 11). Chapter 12 makes all of that explicit.

---

## Proposed Structure

### 12.1 What Is a Category?
Objects, morphisms, composition, identity. Key examples the reader already knows: types and functions form a category, modules and functors, `int` with `(<=)` as a poset. Keep concrete and short.

### 12.2 Revisiting the Book Through a Categorical Lens
A retrospective section: type isomorphisms (Ch 2) were isomorphisms in the categorical sense; `map` (Ch 6) was a functor action; monad laws (Ch 8) were categorical laws of a monad. The payoff of the whole book crystallizes here.

### 12.3 Typed Morphisms with GADTs
The chapter's main new OCaml material. A `('a, 'b) morphism` GADT enforces composability at the type level. Build the **free category on a typed graph**:

```ocaml
type ('a, 'b) path =
  | Nil  : ('a, 'a) path
  | Cons : ('a, 'b) edge * ('b, 'c) path -> ('a, 'c) path
```

This is literally the free category construction expressed as a GADT — the type enforces the composability invariant. Without GADTs you can build ill-formed pipelines that compile; with GADTs you cannot. This ties Ch 9's GADTs directly to categorical structure, and illustrates **GADTs as reification** — a `'a ty` GADT reifies the type `'a` as a value, which is OCaml's Yoneda embedding for types.

### 12.4 Functors in OCaml: Three Views
(a) OCaml module functors (structural, not quite categorical), (b) the `Functor` typeclass pattern (`map` preserving structure), (c) a GADT encoding of functors between typed categories. Clarify the terminological collision and show what unites all three. Reference the [Preface library](https://github.com/xvw/preface) as a complete systematic encoding (pedagogical, not production).

### 12.5 Natural Transformations
Polymorphic functions as natural transformations (`'a list -> 'a option`, `'a option -> 'a list`). The naturality square as a free theorem. Parametricity gives naturality for free in OCaml — this is the surprising practical consequence.

### 12.6 Adjunctions and Galois Connections
Adjunctions are arguably the deepest single CT discovery (Kan, 1958). The key examples the reader already knows:
- **Currying** (`(a × b → c) ≅ (a → b → c)`) is the product/exponential adjunction — something used since Ch 1 revealed as a deep mathematical duality
- **Free/forgetful adjunctions**: free monoids, free monads (connecting to Ch 8's effects)
- **Galois connections** as adjunctions where the categories are posets (at most one morphism between any two objects)

Every relation `R ⊆ A × B` induces a Galois connection between powersets:
- `f(S) = { b | ∀ a ∈ S, a R b }` 
- `g(T) = { a | ∀ b ∈ T, a R b }`

The closed pairs form a **concept lattice** (Formal Concept Analysis). The closure operator `g∘f` is computable in OCaml. The industrial-strength application: **abstract interpretation** (Cousot & Cousot, 1977) — soundness of a static analysis *means* the abstraction/concretization pair is a Galois connection. This retrospectively frames Ch 3's reduction semantics: the relationship between concrete and abstract semantics is itself a Galois connection.

### 12.7 Lenses, Zippers, and the Derivative Connection
A retrospective thread running through Ch 2, Ch 7, and Ch 10:

- **Ch 2's derivative** gives the *type* of one-hole contexts (algebraically, for polynomial and exponential types alike — the power rule works)
- **Ch 10's zipper** *inhabits* those contexts operationally, making them navigable
- **Lens** abstracts over both: `{ get : 's -> 'a; set : 's -> 'a -> 's }` — specifies get/set without committing to representation. Works for exponential-containing types (e.g. `{ head : 'a; tail : unit -> 'a stream }` from Ch 7) where concrete zipper navigation is impossible
- **Van Laarhoven lens** encodes a lens as a natural transformation: `{ run : 'f. ('a -> 'f 'a) -> 's -> 'f 's }` — this is Yoneda made practical, and explains why lenses compose with ordinary function composition

**Prisms** are the dual of lenses — lenses focus into product types (records), prisms focus into sum types (variants). This reframes Ch 11's expression problem: you want a structure with both good lens access (extending operations) and good prism access (extending constructors) — categorically, a structure that is a colimit in both dimensions simultaneously, which is why it is hard.

The full lens hierarchy (Iso, Lens, Prism, Traversal, Fold...) is unified by **profunctors** — each optic corresponds to a class of profunctors. Traversals generalize both; `List.map` (Ch 6) is a traversal.

### 12.8 The Yoneda Lemma
`Nat(Hom(A,−), F) ≅ F(A)`. Programming instantiation: the CPS transform, difference lists, the Codensity monad. The deep insight: every object is completely determined by how other objects map into it — the "representable" objects are the fixed points of this level-crossing. This lands as the deepest and most surprising result.

### 12.9 The Expression Problem, Categorically
Revisit Ch 11. The expression problem is about finding a category where both data and operations are morphisms and the following square commutes (a **naturality condition**):

```
new constructors ──→ extended type
       ↓                    ↓
new operations  ──→ extended semantics
```

Polymorphic variants correspond to a colimit construction; the correct solution is the one that makes the diagram commute. The extensible GADT case (from the [OCaml Discuss thread](https://discuss.ocaml.org/t/best-approach-for-implementing-open-recursion-over-extensible-types/11678)) is a genuinely new point in the design space: each handler must be a **natural transformation** (polymorphic in the index type `'a`), and `build_printer` computes a colimit of partial natural transformations. The dynamic failure (loop or exception) when no handler covers a constructor is the colimit not existing — a static GADT would make this a compile-time error.

### 12.10 Curry-Howard-Lambek: The Trinity
Close the loop with Ch 1. Logic (propositions/proofs) = Type Theory (types/programs) = Category Theory (objects/morphisms). The negation-as-Galois-connection perspective shows that classical logic's double negation, linear logic's duality, and continuation types are the same structural phenomenon viewed through different lenses. This is the philosophical capstone the whole book has been building toward.

### 12.11 Exercises

---

## Recurring Motif

The chapter has a unifying question asked at each major concept: **"what is stable under crossing levels?"**
- Galois connection: closed elements (fixed points of the round-trip)
- Adjunction: the unit/counit witnesses
- Yoneda: representable functors (the perfectly faithful reification)
- Curry-Howard-Lambek: the trinity itself (truths that appear in all three worlds simultaneously)

This also connects to **reflection/reification**: reification promotes a computational concept to a first-class value (right adjoint, conservative); reflection executes it (left adjoint, may lose information). GADTs are OCaml's reification mechanism. The round-trip reify∘reflect is a closure — you recover the canonical form, not necessarily the original.

---

## Connections to Existing Chapters

| Chapter | Categorical concept retrospectively named |
|---------|------------------------------------------|
| Ch 1 | Curry-Howard correspondence (propositions as types) |
| Ch 2 | Type isomorphisms; derivative as one-hole context type |
| Ch 3 | Reduction semantics as concrete domain; abstract interpretation as Galois connection |
| Ch 4 | Church encodings as catamorphisms; untyped λ-calculus as reflexive object (Scott) |
| Ch 5 | Homomorphisms; module functors |
| Ch 6 | `map` as functor action; `fold` as algebra; traversals |
| Ch 7 | Exponential types; streams as non-polynomial types forcing the lens abstraction |
| Ch 8 | Monad laws; monads from adjunctions; free monads |
| Ch 9 | GADTs as reification; typed interpreters as functors |
| Ch 10 | Zippers as concrete lenses; derivative made operational |
| Ch 11 | Expression problem as commutativity of a naturality square; colimit constructions |

---

## Key References
- Preface library (OCaml CT abstractions, pedagogical): https://github.com/xvw/preface
- OCaml Discuss thread on extensible GADTs and the expression problem: https://discuss.ocaml.org/t/best-approach-for-implementing-open-recursion-over-extensible-types/11678
- Garrigue's papers on polymorphic variants and the expression problem
- Van Laarhoven lens encoding (natural transformation / Yoneda connection)
- Formal Concept Analysis (Wille, 1982) for Galois connections
- Abstract Interpretation (Cousot & Cousot, 1977) for Galois connections in semantics
