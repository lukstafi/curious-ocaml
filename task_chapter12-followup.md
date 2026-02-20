For the coder: in the first round, implement *ONLY* suggestions 1, 2, 3 and 8, they offer the most value; in later rounds address reviewer feedback. For the reviewer: in addition to verifying points 1, 2, 3 and 8, review the whole chapter as a textbook: clarity, accuracy, pedagogical flow.

# Follow-up: Solution for task_chapter12

This is a follow-up task based on feedback from PR #7.
PR: https://github.com/lukstafi/curious-ocaml/pull/7

## Original PR Description

Solution from coder for feature: task_chapter12

## PR Comments and Reviews

The comments below (most recent last) describe what needs to be done.
Focus especially on the last comment(s) for the actionable task.

### Comment by lukstafi (2026-02-20T13:55:40Z)

Addressed both review comments in commit 1723471:

**1. `leq` Step constructor (line 66)** — Fixed. The GADT now uses Peano type-level naturals (`zero`, `'n succ`) so `Le_step` correctly preserves the upper bound: `Le_step : ('n, 'm) leq -> ('n, 'm succ) leq`. Added a working `leq_trans` (composition/transitivity) and an example witness `0 <= 2`.

**2. `_fst` VL lens (line 719)** — Fixed. Replaced the single `_fst` definition (which was specialized to `Identity` via pattern match) with separate `fst_set` and `fst_get` functions that correctly instantiate the VL shape with `Identity` and `Const` respectively. Added a note explaining that OCaml's lack of higher-rank polymorphism requires this specialization, unlike Haskell where a single definition works for both.

### Comment by lukstafi (2026-02-20T14:12:24Z)

## Refactoring Suggestions

*Post-merge retrospective: what would we do differently if starting from scratch?*

# Refactoring Suggestions

## If starting from scratch, I would...

### 1. Add more runnable code to the prose-heavy sections

Sections 12.2 (Retrospective), 12.9 (Expression Problem Categorically), and 12.10 (Curry--Howard--Lambek) are mostly prose and math. The retrospective table in 12.2 would be stronger with short runnable snippets demonstrating each connection — e.g., showing `List.fold_right` as a catamorphism with the algebra made explicit, or showing a type isomorphism witness from Chapter 2 reframed as a categorical isomorphism. Section 12.10 could have a small runnable example encoding a logical proof as both a program and a morphism.

### 2. Use a GADT-based typed category for the functor section

Section 12.4 defines a `TYPED_FUNCTOR` module type but never instantiates it with a runnable example. I'd add a concrete `ListTypedFunctor` that implements the signature, mapping `FunCat` to `FunCat`. This would tie the three functor views together more concretely instead of leaving View 3 as a signature-only sketch.

### 3. Strengthen the Van Laarhoven lens section

The PR review correctly caught that OCaml can't express a single polymorphic VL lens that works for both get and set. Rather than the workaround with separate `fst_set`/`fst_get`, I'd restructure the section to: (a) show the Haskell-style type signature as a `skip` block to explain the concept, (b) demonstrate OCaml's limitation explicitly, and (c) show a functor-parameterized encoding that actually works polymorphically in OCaml (using a `FUNCTOR` module parameter). This would be more honest and more instructive.

### 4. Split the prelude more carefully

The `prelude.ml` includes full MONAD infrastructure but it's only used by the `env=yoneda` Codensity example. I'd either move the monad code into the `env=yoneda` block itself (making it self-contained), or add more monad-based examples across other sections to justify the prelude weight. Currently `env=cat`, `env=gadt`, `env=functor`, `env=nat`, `env=adj`, and `env=lens` don't use anything from the prelude except the composition operators.

### 5. Add property-based or randomized tests for the category/functor laws

The current assertions test laws on specific inputs (`x = 7`, etc.). A more robust approach would use a small QuickCheck-style loop: generate N random inputs and verify the law holds for all of them. This is especially valuable for the functor laws (`map id = id`, `map (f . g) = map f . map g`) and the lens laws, where specific-input tests can pass accidentally.

### 6. The Galois connection / FCA section could be a standalone env

The `env=adj` environment is the most overloaded — it holds currying, free/forgetful adjunctions, Galois floor/embed, and FCA. These are conceptually distinct. I'd split into `env=adj_curry`, `env=adj_free`, and `env=fca` so that a failure in one doesn't cascade and each is independently testable.

### 7. Missing: chapter illustration

The chapter image reference is commented out (`<!-- ![Chapter 12 illustration]... -->`). The task description doesn't mention generating one, but every other chapter has an illustration. This should be flagged as a follow-up task.

### 8. The exercises could include solution hints or starter code

Chapters 10 and 11 provide more scaffolding in their exercises. Chapter 12's exercises are statement-only. Adding `ocaml skip` starter code blocks for exercises 1, 2, 3, and 6 would make them more approachable, especially since this is the most abstract chapter in the book.

### Review by chatgpt-codex-connector (COMMENTED, null)


### 💡 Codex Review

Here are some automated review suggestions for this pull request.

**Reviewed commit:** `31d4b84298`
    

<details> <summary>ℹ️ About Codex in GitHub</summary>
<br/>

[Your team has set up Codex to review pull requests in this repo](http://chatgpt.com/codex/settings/general). Reviews are triggered when you
- Open a pull request for review
- Mark a draft as ready
- Comment "@codex review".

If Codex has suggestions, it will comment; otherwise it will react with 👍.




Codex can also answer questions or update the PR. Try commenting "@codex address that feedback".
            
</details>

