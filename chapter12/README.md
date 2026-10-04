## Chapter 12: Constructions and their laws

![Chapter 12 illustration](Curious_OCaml-chapter_12.jpg){.chapter-image}

**Prerequisites:** Chapters 2, 3, 5, 6 and 11; induction on finite data and equality
of functions at every argument. **Route:** Part IV. Optics and codensity are
optional further study in `projects/optics/README.md`.

The previous chapters changed representations and checked what survived. We now
prove a few general constructions: functor laws, the uniqueness of a fold, an
adjunction and a polymorphic Yoneda representation. For each claim we name its
objects, maps, equality and hypotheses. A type index can prevent mismatched
endpoints; it cannot prove associativity or naturality by itself.

### 12.1 Choose a category and an equality

A category has objects, arrows between objects, identity arrows and composition
of arrows with matching endpoints. Composition is associative and identities are
units. In **Set**, objects are sets, arrows are total functions, and equality of
arrows is extensional: two functions are equal when they agree at every input.
For functions `f : A -> B`, `g : B -> C`, and `h : C -> D`, both bracketings of
composition send `a` to `h (g (f a))`; either identity law reduces to `f a`.

Pure, terminating OCaml examples can illustrate this setting. General OCaml
functions may diverge, mutate state or raise exceptions. Resource exhaustion is
also ignored in this mathematical interpretation. To model a possibly missing
lookup as a total Set arrow, return an explicit option/result value rather than
silently treating a raised exception as an ordinary result.

```ocaml env=category
module type CATEGORY = sig
  type ('a, 'b) hom
  val id : ('a, 'a) hom
  val compose : ('b, 'c) hom -> ('a, 'b) hom -> ('a, 'c) hom
end
module Functions = struct
  type ('a, 'b) hom = 'a -> 'b
  let id x = x
  let compose g f x = g (f x)
end
```

This interface checks that endpoints match. An implementation could still violate
the laws; the interface is not a proof. Likewise, two OCaml function values cannot
be compared extensionally by polymorphic `=`. We test selected arguments and
prove the general equation separately.

A poset gives another category: objects are its elements and an arrow `a -> b`
exists exactly when `a <= b`, with at most one such arrow. Reflexivity supplies
identities and transitivity composition. A monoid gives a one-object category,
with monoid elements as arrows, multiplication as composition and its unit as
identity. The equality notion changes with the example: order witnesses in a
poset are unique, whereas a monoid may have many distinct arrows.

### 12.2 List mapping is a functor

A functor maps objects and arrows, preserving identities and composition. Here
`List : Set -> Set` maps a set `A` to its **finite** lists and a function `f` to
pointwise list mapping. Its laws are

$$\operatorname{map}(\mathrm{id})=\mathrm{id},\qquad
\operatorname{map}(g\circ f)=\operatorname{map}(g)\circ\operatorname{map}(f).$$

Prove identity by induction. Mapping over `[]` returns `[]`. On `x::xs`, the
mapped head is `x` and the mapped tail is `xs` by induction. For composition,
both sides on `[]` are empty; on `x::xs`, both heads are `g (f x)` and the tails
agree by induction. This proof needs total pure `f` and `g`: effect order is not
part of this Set theorem.

```ocaml env=functor
let () =
  List.iter (fun xs ->
    assert (List.map Fun.id xs = xs);
    let f x = x + 1 and g x = 2 * x in
    assert (List.map (fun x -> g (f x)) xs = List.map g (List.map f xs)))
    [[]; [1]; [1;2;3]]
```

A rewrite that changes constructors is a fold into syntax, not this
shape-preserving map. An OCaml *module functor* is a parameterized module; to call
one a categorical functor requires an independently specified category and an
action on arrows satisfying these laws. Similar names do not supply those data.

### 12.3 Why a fold is unique

Fix an element set `A` and the endofunctor $F(X)=1+A\times X$ on Set. An
**F-algebra** consists of a carrier set `X`, a chosen `z : X`, and a function
`c : A * X -> X`. An algebra morphism $h:(X,z,c)\to(Y,z',c')$ is a total function
such that $h(z)=z'$ and $h(c(a,x))=c'(a,h(x))$. Identity and composition preserve
these equations, giving a category of F-algebras.

Finite lists, with `[]` and `(::)`, form an **initial** algebra: for any target
algebra there is exactly one algebra morphism from lists to that target. The
candidate is the fold:

```ocaml env=fold
let rec fold c z = function
  | [] -> z
  | x::xs -> c x (fold c z xs)
```

Existence follows from its defining equations: `fold c z [] = z` and
`fold c z (x::xs) = c x (fold c z xs)`. To prove uniqueness, suppose `h` also
satisfies those equations. At `[]`, `h [] = z = fold c z []`. At `x::xs`,

$$h(x::xs)=c(x,h(xs))=c(x,\operatorname{fold}(c,z)(xs))
=\operatorname{fold}(c,z)(x::xs),$$

where the middle equality uses the induction hypothesis. Thus `h` and the fold
are extensionally equal on every finite list. This is the universal property;
a few tests of a recursive implementation would not establish uniqueness.

#### The expression fold has the same argument

For the common syntax, fix sets `K` of constant labels, `N` of names and `O` of
operator labels. The syntax functor is

$$E(X)=K+N+(O\times X\times X)+(N\times X\times X).$$

Its four summands are number, variable, binary operation and `Let`. On arrows,
`E(h)` applies `h` to each recursive child and leaves labels untouched. The
carrier of its initial algebra is finite `Expr.t` syntax. The algebra fields in
Chapter 6 implement the corresponding maps to an arbitrary carrier.

Existence is the four defining equations of `Expr.fold`. Uniqueness uses induction
on the same four constructors: number and variable are base cases; for binary
and binding forms use the hypotheses for both children. Names are literal labels
here. We have **not** quotiented syntax by alpha equivalence, nor claimed that
binding semantics itself is a polynomial functor on names.

The evaluation algebra in Chapter 6 uses a function carrier to handle binding.
To apply this Set theorem literally, totalize lookup failure as an explicit
result and treat arithmetic outcomes as values. The exception-raising executable
is an operational illustration with a separately stated failure contract.

#### Fusion is a consequence, with a premise

If `h` preserves a source algebra's operations into a target algebra, then
`h (fold source e) = fold target e`. Both sides are algebra morphisms from the
initial syntax algebra; uniqueness gives equality. The preservation premise is
essential: not every post-processing function can be pushed through a fold.

```ocaml env=fold
let () =
  let join xs = fold (^) "" xs in
  let total_length xs = fold (fun x n -> String.length x + n) 0 xs in
  List.iter (fun xs -> assert (String.length (join xs) = total_length xs))
    [[]; ["a";"bc"]; ["";"hello"]]
```

Here `String.length` preserves the empty string and concatenation into zero and
addition, for finite strings within machine limits. That is the exact premise
which licenses fusion in this example.

### 12.4 Derive an adjunction

Fix a set `B`. Define $L(A)=A\times B$ and $R(C)=C^B$, the set of functions from
`B` to `C`. On arrows, $L(u)(a,b)=(u(a),b)$ and $R(v)(k)=v\circ k$.
These are functors Set to Set: substitution verifies both functor laws.
The adjunction $L\dashv R$ is the natural family of bijections

$$\mathrm{Set}(A\times B,C)\cong\mathrm{Set}(A,C^B).$$

```ocaml env=adjunction
let curry f a b = f (a,b)
let uncurry g (a,b) = g a b
```

The first round trip is pointwise:
`uncurry (curry f) (a,b) = curry f a b = f (a,b)`.
The other is `curry (uncurry g) a b = uncurry g (a,b) = g a b`.
Both equalities are extensional; no function comparison is used.

A bijection of hom-sets alone is not the whole claim: it must be natural in `A`
and `C`. For `u : A' -> A` and `v : C -> C'`, start with `f : A * B -> C`.
Both ways around the naturality square evaluate at `a'` and `b` to
`v (f (u a', b))`. Precomposition on the input and postcomposition on the output
therefore commute with currying. This proves the required naturality.

```ocaml env=adjunction
let () =
  let f (a,b) = a + b and u a = 2*a and v c = string_of_int c in
  List.iter (fun a -> List.iter (fun b ->
    assert (uncurry (curry f) (a,b) = f (a,b));
    assert (curry (fun (a,b) -> v (f (u a,b))) a b = v (curry f (u a) b)))
    [0;1;2]) [0;1;2]
```

#### A boundary-sensitive order example

View the mathematical reals and integers as poset categories ordered by `<=`.
Ceiling $c:\mathbb R\to\mathbb Z$ is left adjoint to the integer embedding
$i:\mathbb Z\to\mathbb R$, because

$$c(x)\le n\quad\Longleftrightarrow\quad x\le i(n).$$

If $c(x)\le n$, then $x\le c(x)\le n$. Conversely, if $x\le n$ and `n` is an
integer, the least integer above `x` is no larger than `n`. Both maps are monotone.
In thin poset categories, the hom-set bijection is exactly this equivalence of
inequalities. Replacing ceiling by floor fails at `x=3.7,n=3`.

```ocaml env=adjunction
let () =
  List.iter (fun x -> List.iter (fun n ->
    assert ((int_of_float (Float.ceil x) <= n) = (x <= float_of_int n)))
    [-4;-3;0;3;4]) [-3.7;0.;3.7;4.]
```

This finite check uses finite floats and exactly represented small integer bounds.
It is not a theorem about converting arbitrary floats, NaNs or out-of-range
values into bounded OCaml integers.

### 12.5 Naturality and Yoneda, with both inverse laws

Let `F : Set -> Set` be a functor and fix a set `A`. The functor
$H_A(B)=\mathrm{Set}(A,B)$ acts on `g : B -> C` by postcomposition:
$H_A(g)(f)=g\circ f$. A natural transformation $\eta:H_A\Rightarrow F$ has a
component $\eta_B:(A\to B)\to F(B)$ at every `B`, with

$$F(g)(\eta_B(f))=\eta_C(g\circ f).$$

The covariant Yoneda bijection identifies these natural transformations with
`F(A)`. We can construct and prove it directly:

- Given `x : F(A)`, define $\eta^x_B(f)=F(f)(x)$. Its naturality follows from
  `F(g) (F(f) x) = F(g composed with f) x`, the composition law.
- Given a natural `eta`, recover $x=\eta_A(\mathrm{id}_A)$.

Recovering from the first construction gives $F(\mathrm{id}_A)(x)=x$, by the
identity law. For the other round trip, naturality at the arrow `f : A -> B`,
applied to `id_A`, gives

$$F(f)(\eta_A(\mathrm{id}_A))=\eta_B(f\circ\mathrm{id}_A)=\eta_B(f).$$

Thus every component is recovered on every input function. Equality of natural
transformations means precisely that componentwise extensional equality. The
proof used functor laws and naturality, not just a suggestive type abbreviation.
For the general formulation in a locally small category, see Riehl,
[*Category Theory in Context*, Theorem 2.2.4](https://emilyriehl.github.io/files/context.pdf).

#### The universal quantifier must be real

For the list functor, OCaml can encode the varying result type with a polymorphic
record field:

```ocaml env=yoneda
type 'a yoneda = { run : 'b. ('a -> 'b) -> 'b list }
let to_yoneda xs = {run = fun f -> List.map f xs}
let from_yoneda phi = phi.run Fun.id
let () =
  let phi = to_yoneda [1;2;3] in
  assert (from_yoneda phi = [1;2;3]);
  assert (phi.run string_of_int = ["1";"2";"3"]);
  assert (phi.run (fun x -> x mod 2 = 0) = [false;true;false]);
  assert ((to_yoneda (from_yoneda phi)).run ((+) 1) = phi.run ((+) 1))
```

The same stored `phi` accepts both a string-producing and a Boolean-producing
function. A monomorphic function with one fixed result type would not express
this quantifier. Nevertheless, OCaml's type alone does not enforce naturality:

```ocaml env=yoneda
let unnatural = {run = fun f -> List.sort compare (List.map f [1;2])}
let () =
  let recovered = to_yoneda (from_yoneda unnatural) in
  assert (unnatural.run (fun x -> -x) = [-2;-1]);
  assert (recovered.run (fun x -> -x) = [-1;-2])
```

Polymorphic comparison inspects the result representation, breaking uniformity;
it can also raise on function values. The reverse law therefore applies to
natural families, for example those produced by `to_yoneda`, or to a suitably
restricted total parametric language with a justified parametricity theorem.
It is false for all OCaml values of this record type.

For the identity functor, the same construction gives a polymorphic CPS value:

```ocaml env=yoneda
type 'a cps = { run_cps : 'b. ('a -> 'b) -> 'b }
let to_cps x = {run_cps = fun k -> k x}
let from_cps p = p.run_cps Fun.id
let () = assert (from_cps (to_cps 42) = 42)
```

This is the value-level representation behind the identity-continuation idea in
Chapter 3. An arbitrary fixed-answer-type continuation `(A -> R) -> R` has a
different contract; it is not this universally quantified representation.

### 12.6 What carries back to the programs

Chapter 11's plugin embedding satisfies an ordinary equation between functions:
`eval_extended (embed e) = eval e`, on its stated domain and failure semantics.
Its compiled test checks that equation. Calling it naturality would additionally
require categories, functors and a family of embeddings; extensible variants do
not supply those automatically.

Chapter 2's context derivative also has a precise scope. For finite polynomial
containers, differentiating with respect to the element parameter describes an
element hole. For $T=1+aT^2$, $T'=T^2+2aTT'$ records the removed node's children
and its ancestor path. A subtree hole instead keeps just the path. See Abbott,
Altenkirch, Ghani and McBride,
[*Derivatives of Containers*](https://people.cs.nott.ac.uk/psztxa/publ/tlca03.pdf),
for the container setting behind this calculation. It does not make every
effectful stream or arbitrary OCaml datatype a polynomial container.

For Chapter 1, the pure simply typed product/function calculus can be interpreted
in a cartesian closed category: products model pairs, a terminal object models
unit, and exponentials model functions with evaluation and currying. Adding
coproducts and an initial object models sums and the empty type. General recursion
and effects need further semantics. A correspondence restricted to that fragment
is useful precisely because its assumptions say when it applies.

### 12.7 Exercises

1. **Proof.** Prove `Option.map` preserves identities and composition. Specify
   the objects and arrows before writing the two constructor cases.
2. **Proof.** Complete the uniqueness proof for the four-constructor expression
   fold. Explain why it treats a binder name as a label, not as a quotient by
   renaming.
3. **Practice.** Test both currying round trips on a function returning a pair.
   Write the equalities pointwise; do not compare function values with `=`.
4. **Proof.** Reproduce the reverse Yoneda round trip, explicitly naming the
   naturality arrow and the argument to the component at `A`.
5. **Experiment.** Use `unnatural` to find a failed naturality square with integer
   negation. Selected answer: map negation after sorting `[1;2]` gives `[-1;-2]`,
   while sorting after mapping gives `[-2;-1]`.
6. **Project.** Continue with the optional optics route. Prove the three lens laws
   for a composed record lens before considering its higher-rank encoding.

The payoff is not a name for every program. It is a reusable proof: identify the
representation, state its laws, and know which changes those laws justify.
