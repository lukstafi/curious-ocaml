## Chapter 12: Categories and GADTs

<!-- ![Chapter 12 illustration](Curious_OCaml-chapter_12.jpg){.chapter-image} -->

**In this chapter, you will:**

- Learn the definition of a category and recognize categories you have been using throughout this book
- See how type isomorphisms, functors, monads, and the expression problem are all categorical concepts
- Use GADTs to enforce categorical structure (composability, type safety) at the type level
- Understand functors, natural transformations, and adjunctions as unifying abstractions
- Connect lenses and zippers to type derivatives through a categorical lens
- Encounter the Yoneda lemma and its surprisingly practical programming consequences
- Close the loop from Chapter 1: the Curry--Howard--Lambek correspondence

Throughout Chapters 1--11, we have been doing category theory without naming it. Type isomorphisms (Chapter 2), `map` and `fold` (Chapter 6), monad laws (Chapter 8), zippers (Chapter 10), and the expression problem (Chapter 11) all have precise categorical descriptions. This chapter makes the hidden structure explicit.

The distinctive quality of this chapter is not "here is some category theory" but rather "here is the hidden structure of everything you have learned" -- a retrospective unification of the whole book through a categorical lens, with GADTs as the OCaml-specific mechanism that makes categorical structure *enforceable* at the type level.

### 12.1 What Is a Category?

A **category** $\mathcal{C}$ consists of:

1. A collection of **objects**
2. For every pair of objects $A, B$, a collection of **morphisms** (or arrows) $\text{Hom}(A, B)$
3. For every object $A$, an **identity morphism** $\text{id}_A \in \text{Hom}(A, A)$
4. For compatible morphisms $f \in \text{Hom}(A, B)$ and $g \in \text{Hom}(B, C)$, a **composition** $g \circ f \in \text{Hom}(A, C)$

subject to the laws:

- **Left identity**: $\text{id}_B \circ f = f$ for all $f : A \to B$
- **Right identity**: $f \circ \text{id}_A = f$ for all $f : A \to B$
- **Associativity**: $h \circ (g \circ f) = (h \circ g) \circ f$

That is the entire definition. Its power comes from the enormous number of mathematical and computational structures that turn out to be instances.

#### Examples You Already Know

**Types and functions.** OCaml types are objects, functions `'a -> 'b` are morphisms, `Fun.id` is the identity, and `Fun.compose` (or `( -| )`) is composition. The laws hold because function composition is associative and `Fun.id` is a unit:

```ocaml env=cat
let id x = x
let compose f g x = f (g x)

(* Laws (we test on a specific case): *)
let f x = x + 1
let g x = x * 2
let h x = x - 3
let x = 7

let () = assert (compose id f x = f x)          (* left identity *)
let () = assert (compose f id x = f x)          (* right identity *)
let () = assert (compose h (compose g f) x       (* associativity *)
               = compose (compose h g) f x)
```

**A poset as a category.** Any partially ordered set $(S, \leq)$ forms a category where objects are elements of $S$, there is exactly one morphism $a \to b$ when $a \leq b$, and none otherwise. Composition is transitivity; identity is reflexivity:

```ocaml env=cat
(* The poset (int, <=) as a category: *)
(* - Objects: integers *)
(* - Morphisms: a single "witness" when a <= b *)
(* - Composition: transitivity of <= *)

(* We encode natural numbers as Peano types at the type level: *)
type zero = Zero
type 'n succ = Succ

(* A witness that n <= m: *)
type (_, _) leq =
  | Le_refl : ('n, 'n) leq                       (* n <= n *)
  | Le_step : ('n, 'm) leq -> ('n, 'm succ) leq  (* n <= m implies n <= m+1 *)

(* Composition = transitivity: if a <= b and b <= c then a <= c *)
let rec leq_trans : type a b c. (a, b) leq -> (b, c) leq -> (a, c) leq =
  fun p q -> match q with
  | Le_refl -> p
  | Le_step q' -> Le_step (leq_trans p q')

(* Example: 0 <= 2 *)
let _zero_le_two : (zero, zero succ succ) leq =
  Le_step (Le_step Le_refl)
```

In general, a poset category has *at most one morphism* between any two objects. Composition is transitivity, identity is reflexivity. This is the simplest non-trivial kind of category.

**A monoid as a category.** A monoid $(M, \cdot, e)$ forms a category with *one* object (call it $\star$), morphisms are elements of $M$, composition is the monoid operation $\cdot$, and identity is $e$. The monoid laws are exactly the category laws:

```ocaml env=cat
module type MONOID = sig
  type t
  val empty : t                (* identity morphism *)
  val append : t -> t -> t     (* composition *)
end

(* String monoid = one-object category *)
module StringMonoid : MONOID with type t = string = struct
  type t = string
  let empty = ""
  let append = ( ^ )
end

(* List monoid = one-object category *)
module ListMonoid (A : sig type t end) : MONOID with type t = A.t list = struct
  type t = A.t list
  let empty = []
  let append = ( @ )
end
```

#### The Category Module Type

We can encode the notion of a category as an OCaml module signature:

```ocaml env=cat
module type CATEGORY = sig
  type ('a, 'b) hom           (* morphisms from 'a to 'b *)
  val id : ('a, 'a) hom
  val compose : ('b, 'c) hom -> ('a, 'b) hom -> ('a, 'c) hom
end
```

The type parameters `'a` and `'b` are phantom types -- they track the source and target of morphisms at the type level, ensuring only composable morphisms can be composed. OCaml functions form the most basic instance:

```ocaml env=cat
module FunCat : CATEGORY with type ('a, 'b) hom = 'a -> 'b = struct
  type ('a, 'b) hom = 'a -> 'b
  let id x = x
  let compose f g x = f (g x)
end
```

### 12.2 Revisiting the Book Through a Categorical Lens

Before introducing new material, let us look back at what the previous chapters taught us -- now with categorical vocabulary.

| Chapter | Concept | Categorical Name |
|---------|---------|-----------------|
| 1 | Propositions and types | Objects in a category; Curry--Howard |
| 2 | Type isomorphisms (`'a * 'b ≅ 'b * 'a`) | Isomorphisms in the category of types |
| 2 | Type derivative (one-hole context) | Derivative of a functor |
| 3 | Function composition `( -\| )` | Morphism composition in **Types** |
| 4 | Church encodings | Initial algebra (catamorphism) |
| 5 | `map` preserving structure | Functor action on morphisms |
| 5 | Module functors `Map.Make` | Functors between module categories |
| 6 | `List.map`, `Option.map` | Endofunctor on **Types** |
| 6 | `List.fold_right` | Catamorphism (universal property of initial algebra) |
| 7 | Lazy streams, exponential types | Objects in a category with exponentials |
| 8 | `return`, `bind`, monad laws | Monad = endofunctor + unit + multiplication |
| 8 | Free monads | Left adjoint to the forgetful functor |
| 9 | GADTs (`'a expr`) | Reification; typed initial algebra |
| 10 | Zippers | Concrete lens (derivative made operational) |
| 11 | Expression problem | Commutativity of a naturality square |

**Type isomorphisms are categorical isomorphisms.** In Chapter 2, we showed that `'a * 'b` is isomorphic to `'b * 'a` by providing functions `swap` and `swap` that compose to the identity in both directions. This is exactly what it means for two objects to be *isomorphic* in a category: there exist morphisms $f : A \to B$ and $g : B \to A$ such that $g \circ f = \text{id}_A$ and $f \circ g = \text{id}_B$.

```ocaml env=cat
(* Type isomorphism from Chapter 2, restated categorically: *)
(* swap_pair and swap_pair are inverse morphisms in FunCat. *)
let swap_pair (a, b) = (b, a)
let () = assert (compose swap_pair swap_pair (1, "hello") = (1, "hello"))
(* swap ∘ swap = id: the round-trip is the identity morphism. *)

(* Distributivity: A * (B + C) ≅ A * B + A * C *)
let dist : 'a * ('b, 'c) result -> (('a * 'b), ('a * 'c)) result =
  function (a, Ok b) -> Ok (a, b) | (a, Error c) -> Error (a, c)
let undist : (('a * 'b), ('a * 'c)) result -> 'a * ('b, 'c) result =
  function Ok (a, b) -> (a, Ok b) | Error (a, c) -> (a, Error c)
let () = assert (undist (dist (1, Ok "yes")) = (1, Ok "yes"))
let () = assert (undist (dist (1, Error 2.0)) = (1, Error 2.0))
```

**`map` is a functor action.** In Chapter 6, we wrote `List.map f` to transform every element of a list. The function `List.map` sends each morphism $f : A \to B$ to a morphism `List.map f : 'a list -> 'b list`. It preserves identity (`List.map id = id`) and composition (`List.map (f ∘ g) = List.map f ∘ List.map g`). This is precisely a *functor* -- a structure-preserving map between categories.

**Monad laws are category laws.** In Chapter 8, we verified three monad laws (left identity, right identity, associativity). These are exactly the laws of a *monad* in category theory: an endofunctor $T$ equipped with natural transformations $\eta : \text{Id} \Rightarrow T$ (return) and $\mu : T^2 \Rightarrow T$ (join), satisfying unit and associativity laws.

**`fold` is a catamorphism.** The `fold_right` function from Chapter 6 destructs a list by replacing `(::)` with a function and `[]` with a value. This is the *catamorphism* (or *algebra morphism*) for the list functor -- the unique morphism from the initial algebra to any other algebra.

```ocaml env=cat
(* An "algebra" for the list functor is a pair (op, z): *)
(* op replaces (::) and z replaces [].                  *)
(* The catamorphism folds any list using the algebra.   *)
let cata op z xs = List.fold_right op xs z

(* length = catamorphism with algebra (fun _ n -> n+1, 0): *)
let len xs = cata (fun _ n -> n + 1) 0 xs
let () = assert (len [10; 20; 30] = 3)

(* sum = catamorphism with algebra ((+), 0): *)
let sum xs = cata ( + ) 0 xs
let () = assert (sum [1; 2; 3; 4] = 10)

(* map f = catamorphism with algebra ((fun x acc -> f x :: acc), []): *)
let map_via_cata f xs = cata (fun x acc -> f x :: acc) [] xs
let () = assert (map_via_cata (fun x -> x * 10) [1; 2; 3] = [10; 20; 30])
```

### 12.3 Typed Morphisms with GADTs

Chapter 9 introduced GADTs. Now we use them to enforce categorical structure at the type level. The key idea: a `('a, 'b) morphism` GADT makes the source and target types of a morphism visible to the compiler, so only composable morphisms can be composed.

#### The Free Category on a Typed Graph

Consider a *typed graph*: a set of edges, each with a typed source and target. The **free category** on this graph is the category whose morphisms are all paths through the graph. GADTs let us express this directly:

```ocaml env=gadt
(* A typed graph of "pipeline stages" *)
type ('a, 'b) stage =
  | Parse   : (string, string list) stage
  | Filter  : (string list, string list) stage
  | Count   : (string list, int) stage
  | Show    : (int, string) stage

(* The free category: typed paths through the graph *)
type ('a, 'b) path =
  | Nil  : ('a, 'a) path
  | Cons : ('a, 'b) stage * ('b, 'c) path -> ('a, 'c) path
```

The type `('a, 'b) path` enforces that paths are composable: each edge's target must match the next edge's source. The type checker rejects ill-formed pipelines at compile time:

```ocaml env=gadt
(* A valid pipeline: string -> string list -> int -> string *)
let my_pipeline : (string, string) path =
  Cons (Parse, Cons (Count, Cons (Show, Nil)))
```

```ocaml skip
(* This would NOT compile -- types don't match: *)
(* Cons (Parse, Cons (Show, Nil)) *)
(* Error: string list ≠ int *)
```

Without GADTs, we could build ill-formed pipelines that compile -- with GADTs, the composability invariant is enforced statically.

#### Composing Paths

Composition of paths is concatenation, which we can define by recursion on the first path:

```ocaml env=gadt
let rec concat : type a b c. (a, b) path -> (b, c) path -> (a, c) path =
  fun p q -> match p with
  | Nil -> q
  | Cons (edge, rest) -> Cons (edge, concat rest q)
```

This is a category: `Nil` is the identity, `concat` is composition, and associativity follows from the recursive definition.

#### Interpreting Paths

The power of this encoding is that we can *interpret* a typed path into actual functions. Each stage maps to a concrete computation:

```ocaml env=gadt
let interpret_stage : type a b. (a, b) stage -> a -> b = function
  | Parse  -> String.split_on_char ' '
  | Filter -> List.filter (fun s -> String.length s > 2)
  | Count  -> List.length
  | Show   -> string_of_int

let rec interpret : type a b. (a, b) path -> a -> b = function
  | Nil -> Fun.id
  | Cons (stage, rest) -> fun x -> interpret rest (interpret_stage stage x)

let () = assert (interpret my_pipeline "the quick brown fox" = "4")
```

#### Type Witnesses as Reification

GADTs also let us *reify* types as values -- a `'a ty` GADT represents the type `'a` as a first-class value:

```ocaml env=gadt
type _ ty =
  | Int    : int ty
  | String : string ty
  | Bool   : bool ty
  | List   : 'a ty -> 'a list ty
  | Pair   : 'a ty * 'b ty -> ('a * 'b) ty

let rec show_ty : type a. a ty -> string = function
  | Int -> "int"
  | String -> "string"
  | Bool -> "bool"
  | List t -> show_ty t ^ " list"
  | Pair (a, b) -> "(" ^ show_ty a ^ " * " ^ show_ty b ^ ")"

let () = assert (show_ty (List (Pair (Int, Bool))) = "(int * bool) list")
```

This reification is OCaml's version of the *Yoneda embedding* for types: each type is represented by a value that "remembers" what it is, enabling type-safe operations that depend on runtime type information.

### 12.4 Functors in OCaml: Three Views

The word "functor" appears in three distinct but related senses in OCaml. Let us untangle them.

#### View 1: Module Functors (OCaml's Built-In)

OCaml's module system has *functors*: functions from modules to modules. We used `Map.Make` in Chapter 5 to create specialized map modules:

```ocaml skip
module StringMap = Map.Make(String)
(* Map.Make is an OCaml (module) functor: *)
(* it takes a module with type t and compare, *)
(* and returns a module with map operations *)
```

These are not categorical functors in general -- they do not necessarily preserve composition. They are closer to parameterized modules. However, the *name* comes from category theory, and in some cases (like `Map.Make`) the result does respect the categorical structure.

#### View 2: The Functor Type Class Pattern

The categorical notion of a functor is an endofunctor on the category of types. In OCaml, we encode it as a module signature requiring a `map` function that preserves identity and composition:

```ocaml env=functor
module type FUNCTOR = sig
  type 'a t
  val map : ('a -> 'b) -> 'a t -> 'b t
  (* Laws (not checked by the compiler): *)
  (* map id = id *)
  (* map (f ∘ g) = map f ∘ map g *)
end
```

Many standard types are functors:

```ocaml env=functor
module ListFunctor : FUNCTOR with type 'a t = 'a list = struct
  type 'a t = 'a list
  let map = List.map
end

module OptionFunctor : FUNCTOR with type 'a t = 'a option = struct
  type 'a t = 'a option
  let map = Option.map
end

(* The "reader" functor: ('a -> _) is functorial in the return type *)
module ReaderFunctor (R : sig type t end) :
  FUNCTOR with type 'a t = R.t -> 'a = struct
  type 'a t = R.t -> 'a
  let map f g r = f (g r)    (* = compose f g *)
end
```

#### View 3: GADT-Encoded Typed Functors

Between typed categories (Section 12.3), a functor maps objects and morphisms while preserving composition and identity. With GADTs, we can express this:

```ocaml env=functor
module type CATEGORY = sig
  type ('a, 'b) hom
  val id : ('a, 'a) hom
  val compose : ('b, 'c) hom -> ('a, 'b) hom -> ('a, 'c) hom
end

module type TYPED_FUNCTOR = sig
  module Source : CATEGORY
  module Target : CATEGORY
  type 'a obj                  (* object mapping *)
  val map_hom : ('a, 'b) Source.hom -> ('a obj, 'b obj) Target.hom
  (* Laws: *)
  (* map_hom id = id *)
  (* map_hom (compose f g) = compose (map_hom f) (map_hom g) *)
end
```

```ocaml env=functor
(* FunCat: the category of OCaml functions *)
module FunCat : CATEGORY with type ('a, 'b) hom = 'a -> 'b = struct
  type ('a, 'b) hom = 'a -> 'b
  let id x = x
  let compose f g x = f (g x)
end

(* List is a typed functor from FunCat to FunCat: *)
(* - Object mapping: 'a ↦ 'a list *)
(* - Morphism mapping: (f : 'a -> 'b) ↦ (List.map f : 'a list -> 'b list) *)
module ListTypedFunctor : TYPED_FUNCTOR
  with module Source = FunCat
   and module Target = FunCat
   and type 'a obj = 'a list = struct
  module Source = FunCat
  module Target = FunCat
  type 'a obj = 'a list
  let map_hom f = List.map f
end

(* Verify functor laws: *)
let f x = x + 1
let g x = x * 2
let xs = [1; 2; 3]

(* map_hom id = id *)
let () = assert (ListTypedFunctor.map_hom FunCat.id xs = FunCat.id xs)

(* map_hom (compose f g) = compose (map_hom f) (map_hom g) *)
let () = assert (
  ListTypedFunctor.map_hom (FunCat.compose f g) xs
  = FunCat.compose (ListTypedFunctor.map_hom f)
      (ListTypedFunctor.map_hom g) xs)
```

This ties the three views together: `ListTypedFunctor.map_hom` is the same operation as `ListFunctor.map`, but expressed as a morphism-to-morphism mapping between typed categories rather than a value-level function on containers.

#### What Unites the Three Views

All three are "structure-preserving maps": module functors transform module structures, the typeclass pattern transforms values within a type constructor, and typed functors transform morphisms between categories. The categorical functor (View 2) is the one we encounter most in everyday programming.

### 12.5 Natural Transformations

A **natural transformation** $\alpha : F \Rightarrow G$ between two functors $F, G : \mathcal{C} \to \mathcal{D}$ is a family of morphisms $\alpha_A : F(A) \to G(A)$, one for each object $A$, such that the following *naturality square* commutes for every morphism $f : A \to B$:

$$F(A) \xrightarrow{\alpha_A} G(A)$$
$$\downarrow^{F(f)} \qquad\qquad \downarrow^{G(f)}$$
$$F(B) \xrightarrow{\alpha_B} G(B)$$

That is: $G(f) \circ \alpha_A = \alpha_B \circ F(f)$.

#### Polymorphic Functions Are Natural Transformations

In OCaml, a polymorphic function `'a F.t -> 'a G.t` is automatically a natural transformation, because *parametric polymorphism guarantees naturality*. This is a consequence of the "free theorems" result (Wadler, 1989): a polymorphic function cannot inspect its type argument, so it must commute with `map`.

```ocaml env=nat
(* Natural transformation: 'a list -> 'a option *)
let head_opt : 'a list -> 'a option = function
  | [] -> None
  | x :: _ -> Some x

(* Natural transformation: 'a option -> 'a list *)
let option_to_list : 'a option -> 'a list = function
  | None -> []
  | Some x -> [x]

(* Naturality: map commutes with the transformation *)
let f x = x * 2

(* head_opt ∘ List.map f = Option.map f ∘ head_opt *)
let test_input = [1; 2; 3]
let () =
  assert (head_opt (List.map f test_input)
        = Option.map f (head_opt test_input))

(* option_to_list ∘ Option.map f = List.map f ∘ option_to_list *)
let test_opt = Some 5
let () =
  assert (option_to_list (Option.map f test_opt)
        = List.map f (option_to_list test_opt))
```

This is remarkable: we did not *prove* that `head_opt` satisfies the naturality condition -- the type system *guarantees* it. Any function of type `'a list -> 'a option` is automatically natural. Parametricity gives naturality for free.

#### More Examples

```ocaml env=nat
(* length : 'a list -> int *)
(* This is a natural transformation from the List functor *)
(* to the constant functor K_int (which maps everything to int). *)
(* Naturality says: length (List.map f xs) = length xs *)
let () = assert (List.length (List.map f [1;2;3]) = List.length [1;2;3])

(* rev : 'a list -> 'a list *)
(* Natural transformation from List to List. *)
(* Naturality: List.map f (List.rev xs) = List.rev (List.map f xs) *)
let () =
  assert (List.map f (List.rev [1;2;3])
        = List.rev (List.map f [1;2;3]))

(* flatten : 'a list list -> 'a list *)
(* Natural transformation from List ∘ List to List. *)
let () =
  assert (List.flatten (List.map (List.map f) [[1;2];[3]])
        = List.map f (List.flatten [[1;2];[3]]))
```

#### Natural Transformations Compose

Natural transformations can be composed "vertically" (composing $\alpha : F \Rightarrow G$ with $\beta : G \Rightarrow H$ to get $\beta \circ \alpha : F \Rightarrow H$) and "horizontally" (composing functors). This makes functor categories themselves a category -- a higher-level structure that organizes our abstractions.

### 12.6 Adjunctions and Galois Connections

**Adjunctions** are arguably the most important concept in category theory. An adjunction between functors $F : \mathcal{C} \to \mathcal{D}$ and $G : \mathcal{D} \to \mathcal{C}$ is a natural bijection:

$$\text{Hom}_{\mathcal{D}}(F(A), B) \cong \text{Hom}_{\mathcal{C}}(A, G(B))$$

We write $F \dashv G$ and say $F$ is the **left adjoint** and $G$ is the **right adjoint**.

#### Currying Is an Adjunction

The most familiar adjunction is *currying*, which you have used since Chapter 1. For any types $A$, $B$, $C$:

$$(A \times B \to C) \cong (A \to B \to C)$$

The left adjoint is $F(A) = A \times B$ (product with $B$) and the right adjoint is $G(C) = B \to C$ (exponential by $B$). The `curry` and `uncurry` functions witness this adjunction:

```ocaml env=adj
let curry f a b = f (a, b)
let uncurry f (a, b) = f a b

(* These are inverses: *)
let f_uncurried (x, y) = x + y
let f_curried x y = x + y

let () = assert (curry f_uncurried 3 4 = 7)
let () = assert (uncurry f_curried (3, 4) = 7)
let () = assert (curry (uncurry f_curried) 3 4 = f_curried 3 4)
let () = assert (uncurry (curry f_uncurried) (3, 4) = f_uncurried (3, 4))
```

#### Free/Forgetful Adjunctions

Another important class of adjunctions: **free constructions**. The *free monoid* on a set $A$ is the list type `'a list`. The "free" functor $F$ sends a type to its list; the "forgetful" functor $U$ sends a monoid back to its underlying type. The adjunction says:

$$\text{MonoidHom}(\text{List}(A), M) \cong \text{Fun}(A, U(M))$$

A monoid homomorphism from `'a list` to $M$ is completely determined by where it sends each element -- that is, by a function `'a -> M.t`. This is exactly `List.fold_right`:

```ocaml env=adj
(* The free monoid adjunction, witnessed by fold_right: *)
(* A monoid homomorphism from 'a list is determined by *)
(* where single elements go. *)

module type MONOID = sig
  type t
  val empty : t
  val append : t -> t -> t
end

(* Given a function f : 'a -> M.t, extend it to a *)
(* monoid homomorphism 'a list -> M.t *)
let extend_to_hom
    (type m) (module M : MONOID with type t = m)
    (f : 'a -> m) (xs : 'a list) : m =
  List.fold_right (fun x acc -> M.append (f x) acc) xs M.empty

(* Example: summing a list via the (int, +, 0) monoid *)
module IntAdd : MONOID with type t = int = struct
  type t = int
  let empty = 0
  let append = ( + )
end

let sum xs = extend_to_hom (module IntAdd) Fun.id xs
let () = assert (sum [1; 2; 3; 4] = 10)

(* Example: concatenating strings *)
module StringConcat : MONOID with type t = string = struct
  type t = string
  let empty = ""
  let append = ( ^ )
end

let concat_with_spaces xs =
  extend_to_hom (module StringConcat)
    (fun s -> if s = "" then "" else s ^ " ") xs

let () = assert (String.trim (concat_with_spaces ["hello"; "world"]) = "hello world")
```

The free monad adjunction from Chapter 8 works the same way: a monad homomorphism from the free monad on effects $E$ to any monad $M$ is determined by an *interpreter* of each effect -- a function $E \to M$.

#### Galois Connections

When the categories involved are posets (at most one morphism between any two objects), an adjunction becomes a **Galois connection**. Given posets $(A, \leq)$ and $(B, \leq)$, a Galois connection is a pair of monotone functions $f : A \to B$ and $g : B \to A$ such that:

$$f(a) \leq b \iff a \leq g(b)$$

Every Galois connection induces a **closure operator** $g \circ f : A \to A$, where the *closed elements* (fixed points of $g \circ f$) form a complete lattice.

```ocaml env=adj
(* A simple Galois connection: *)
(* floor and ceiling between reals and integers *)
(* f = floor : float -> int (left adjoint) *)
(* g = embed : int -> float (right adjoint) *)
(* floor(x) <= n  iff  x <= float(n) *)

let galois_floor (x : float) : int = int_of_float (Float.floor x)
let galois_embed (n : int) : float = float_of_int n

(* Verify the Galois connection property: *)
let () =
  let x = 3.7 and n = 4 in
  assert ((galois_floor x <= n) = (x <= galois_embed n))

let () =
  let x = 4.0 and n = 3 in
  assert ((galois_floor x <= n) = (x <= galois_embed n))
```

#### Formal Concept Analysis

A deep application of Galois connections is **Formal Concept Analysis** (Wille, 1982). Given a binary relation $R \subseteq A \times B$ between objects $A$ and attributes $B$:

- $f(S) = \{ b \in B \mid \forall a \in S,\ a\, R\, b \}$ (common attributes of a set of objects)
- $g(T) = \{ a \in A \mid \forall b \in T,\ a\, R\, b \}$ (objects sharing all given attributes)

The pair $(f, g)$ is a Galois connection. The closed pairs $(S, T)$ where $S = g(T)$ and $T = f(S)$ are called **formal concepts** and form a lattice.

```ocaml env=adj
(* Formal concept analysis: a small example *)
(* Objects: animals; Attributes: properties *)
(* Relation: "animal has property" *)

let animals = [| "dog"; "cat"; "salmon"; "eagle" |]
let attributes = [| "legs"; "flies"; "swims"; "fur" |]

(* Incidence matrix: animal × attribute *)
let relation = [|
  (*         legs  flies swims fur *)
  [| true;  false; false; true  |];  (* dog *)
  [| true;  false; false; true  |];  (* cat *)
  [| false; false; true;  false |];  (* salmon *)
  [| false; true;  false; false |];  (* eagle *)
|]

let n_obj = Array.length animals
let n_att = Array.length attributes

(* f: set of objects -> common attributes *)
let common_attributes (objs : int list) : int list =
  List.init n_att Fun.id |> List.filter (fun j ->
    List.for_all (fun i -> relation.(i).(j)) objs)

(* g: set of attributes -> objects sharing all *)
let shared_objects (atts : int list) : int list =
  List.init n_obj Fun.id |> List.filter (fun i ->
    List.for_all (fun j -> relation.(i).(j)) atts)

(* Closure operator: g ∘ f *)
let closure objs = shared_objects (common_attributes objs)

(* {dog} closes to {dog, cat}: they share exactly {legs, fur} *)
let () = assert (closure [0] = [0; 1])
let () = assert (common_attributes [0; 1] = [0; 3])

(* {salmon} is already closed *)
let () = assert (closure [2] = [2])
```

**Connection to abstract interpretation.** The Cousot--Cousot framework (1977) for static analysis is built on Galois connections between concrete and abstract domains. The *soundness* of a static analysis means that the abstraction and concretization functions form a Galois connection. This retrospectively frames Chapter 3's reduction semantics: the relationship between concrete execution and abstract semantic domains is itself a Galois connection.

### 12.7 Lenses, Zippers, and the Derivative Connection

This section weaves together three threads from the book: the type derivative (Chapter 2), the zipper (Chapter 10), and a new abstraction -- the *lens*.

#### Recall: Type Derivatives and Zippers

In Chapter 2, we showed that differentiating an algebraic data type yields the type of *one-hole contexts*. For a binary tree `type 'a tree = Leaf | Node of 'a tree * 'a * 'a tree`, the derivative is the type of "a tree with one subtree removed":

$$\frac{\partial}{\partial a}\text{tree}(a) = \text{list of (direction × sibling × value)}$$

In Chapter 10, the *zipper* made this operational: a zipper is a pair (subtree, context) that allows efficient navigation and local update. The zipper *inhabits* the derivative type.

#### Lenses: The Abstract Interface

A **lens** abstracts the get/set pattern into a first-class value. Where a zipper gives you concrete navigation through a data structure, a lens specifies *how to focus* on a part without committing to a particular traversal:

```ocaml env=lens
type ('s, 'a) lens = {
  get : 's -> 'a;
  set : 'a -> 's -> 's;
}
```

Here `'s` is the "whole" type and `'a` is the "part" type. A lens must satisfy three laws:

1. **Get-Set**: `set (get s) s = s` (setting what you get changes nothing)
2. **Set-Get**: `get (set a s) = a` (you get what you set)
3. **Set-Set**: `set a' (set a s) = set a' s` (setting twice is setting once)

```ocaml env=lens
(* A record type with two lenses *)
type person = { name : string; age : int }

let name_lens : (person, string) lens = {
  get = (fun p -> p.name);
  set = (fun n p -> { p with name = n });
}

let age_lens : (person, int) lens = {
  get = (fun p -> p.age);
  set = (fun a p -> { p with age = a });
}

(* Verify lens laws *)
let alice = { name = "Alice"; age = 30 }

(* Get-Set *)
let () = assert (name_lens.set (name_lens.get alice) alice = alice)
(* Set-Get *)
let () = assert (name_lens.get (name_lens.set "Bob" alice) = "Bob")
(* Set-Set *)
let () = assert (name_lens.set "Carol" (name_lens.set "Bob" alice)
               = name_lens.set "Carol" alice)
```

#### Lens Composition

The power of lenses comes from composition. If you have a lens from $S$ to $A$, and a lens from $A$ to $B$, you can compose them to get a lens from $S$ to $B$:

```ocaml env=lens
let compose_lens (outer : ('s, 'a) lens) (inner : ('a, 'b) lens)
  : ('s, 'b) lens = {
  get = (fun s -> inner.get (outer.get s));
  set = (fun b s -> outer.set (inner.set b (outer.get s)) s);
}

(* Nested record example *)
type company = { ceo : person; founded : int }

let ceo_lens : (company, person) lens = {
  get = (fun c -> c.ceo);
  set = (fun p c -> { c with ceo = p });
}

let ceo_name : (company, string) lens = compose_lens ceo_lens name_lens

let acme = { ceo = alice; founded = 2000 }
let () = assert (ceo_name.get acme = "Alice")
let acme' = ceo_name.set "Bob" acme
let () = assert (acme'.ceo.name = "Bob")
```

#### Why Lenses Go Beyond Zippers

Zippers work for *polynomial* types -- types built from sums and products, where the algebraic derivative is well-defined. But what about types involving *exponentials* (function types)?

Consider a stream `{ head : 'a; tail : unit -> 'a stream }` from Chapter 7. Its derivative is not a simple algebraic expression -- you cannot "take the derivative" of a function type the way you can a product type. Yet a lens can still focus on the head:

```ocaml skip
(* A stream has no algebraic derivative / concrete zipper, *)
(* but we can still define lenses on it. *)
type 'a stream = { head : 'a; tail : unit -> 'a stream }

let stream_head_lens = {
  get = (fun s -> s.head);
  set = (fun a s -> { s with head = a });
}
```

This is the key advantage: lenses abstract over the *interface* to a subpart, regardless of whether the containing type has a concrete derivative.

#### Prisms: The Dual of Lenses

While lenses focus into *product types* (records, tuples), **prisms** focus into *sum types* (variants). A prism for a constructor `C` of a sum type provides a way to try to extract the value (which may fail if the value uses a different constructor) and a way to inject a value:

```ocaml env=lens
type ('s, 'a) prism = {
  preview : 's -> 'a option;     (* try to extract *)
  review  : 'a -> 's;            (* inject *)
}

(* Prism for the Some constructor of option *)
let some_prism : ('a option, 'a) prism = {
  preview = Fun.id;
  review = Option.some;
}

(* Prism for the Ok constructor of result *)
let ok_prism : (('a, 'e) result, 'a) prism = {
  preview = Result.to_option;
  review = Result.ok;
}

let () = assert (some_prism.preview (Some 42) = Some 42)
let () = assert (some_prism.preview None = None)
let () = assert (some_prism.review 42 = Some 42)
```

This connects to Chapter 11's expression problem: you want a structure with both good *lens access* (extending operations on products) and good *prism access* (extending constructors as sums). Categorically, a structure that is a colimit in both dimensions simultaneously -- which is why the problem is hard.

#### The Van Laarhoven Encoding

There is an elegant encoding of lenses as polymorphic functions, discovered by Twan van Laarhoven. A lens from `'s` to `'a` can be represented as:

$$\text{Lens}(S, A) = \forall F.\ \text{Functor}(F) \Rightarrow (A \to F(A)) \to S \to F(S)$$

This encoding composes with ordinary function composition, which is why lens libraries are so ergonomic. We will see in Section 12.8 that this is an instance of the *Yoneda lemma*.

In Haskell, a VL lens is a single rank-2 polymorphic definition:

```ocaml skip
(* Haskell-style Van Laarhoven lens (not valid OCaml): *)
(*   type Lens s a = forall f. Functor f => (a -> f a) -> s -> f s   *)
(*   _fst :: Lens (a, b) a                                          *)
(*   _fst f (x, y) = fmap (\x' -> (x', y)) (f x)                   *)
(* Instantiating f = Identity gives "set"; f = Const gives "get".   *)
```

OCaml lacks higher-rank polymorphism, so a single definition cannot quantify over the functor `f`. We can recover a single lens definition by parameterizing over the functor with an OCaml module:

```ocaml env=lens
module type VL_FUNCTOR = sig
  type 'a t
  val fmap : ('a -> 'b) -> 'a t -> 'b t
end

(* One definition of the lens logic, parameterized by the functor: *)
module VL_Fst (F : VL_FUNCTOR) = struct
  let _fst (f : 'a -> 'a F.t) (x, y) : (_ * _) F.t =
    F.fmap (fun x' -> (x', y)) (f x)
end

(* Identity functor -- instantiate for "set": *)
module IdF : VL_FUNCTOR with type 'a t = 'a = struct
  type 'a t = 'a
  let fmap f x = f x
end

(* Const functor -- instantiate for "get": *)
module ConstF (T : sig type t end) :
  VL_FUNCTOR with type 'a t = T.t = struct
  type 'a t = T.t
  let fmap _ x = x
end

module FstSet = VL_Fst(IdF)
module FstGet = VL_Fst(ConstF(struct type t = int end))

let () = assert (FstSet._fst (fun _ -> 10) (1, "hello") = (10, "hello"))
let () = assert (FstGet._fst (fun a -> a) (42, "world") = 42)
```

The lens logic lives in a single place -- `VL_Fst._fst` -- and both get and set are obtained by choosing the functor. The set direction (`FstSet._fst`) is fully polymorphic in the pair types. The get direction requires fixing the focused type when instantiating `ConstF` (here, `int`), a limitation of OCaml's module system compared to Haskell's rank-2 types. This is OCaml's module-level analogue of Haskell's rank-2 polymorphism. The key insight remains: Van Laarhoven lenses compose with ordinary function composition.

### 12.8 The Yoneda Lemma

The Yoneda lemma is one of the deepest results in category theory. It says:

$$\text{Nat}(\text{Hom}(A, -), F) \cong F(A)$$

For any functor $F$ and object $A$, the natural transformations from the representable functor $\text{Hom}(A, -)$ to $F$ are in one-to-one correspondence with elements of $F(A)$.

In programming terms: a polymorphic function `forall b. (a -> b) -> f b` is the same as a value of type `f a`. You can always convert between the two:

```ocaml env=yoneda
(* The Yoneda lemma in OCaml: *)
(* A value of type 'a F.t is equivalent to *)
(* a polymorphic function (forall 'b. ('a -> 'b) -> 'b F.t) *)

(* Forward direction: given f a, produce the natural transformation *)
let yoneda_fwd (map : ('a -> 'b) -> 'a list -> 'b list)
    (x : 'a list) : ('a -> 'b) -> 'b list =
  fun f -> map f x

(* Backward direction: given the nat trans, recover f a *)
let yoneda_bwd (phi : ('a -> 'a) -> 'a list) : 'a list =
  phi Fun.id    (* apply to the identity! *)

(* Round-trip: *)
let original = [1; 2; 3]
let phi = yoneda_fwd List.map original
let recovered = yoneda_bwd phi
let () = assert (recovered = [1; 2; 3])
```

#### The CPS Transform

The most common programming application of Yoneda is the **continuation-passing style** (CPS) transform. For the identity functor, Yoneda gives:

$$\text{Nat}(\text{Hom}(A, -), \text{Id}) \cong A$$

That is: a value of type `'a` is the same as a polymorphic function `forall 'b. ('a -> 'b) -> 'b`. This is exactly CPS:

```ocaml env=yoneda
(* CPS: a value 'a ≅ (forall 'b. ('a -> 'b) -> 'b) *)
let to_cps (x : 'a) : ('a -> 'b) -> 'b = fun k -> k x
let from_cps (f : ('a -> 'a) -> 'a) : 'a = f Fun.id

let () = assert (from_cps (to_cps 42) = 42)
```

#### Difference Lists

Another Yoneda application: **difference lists**. A list `xs` can be represented as the function `fun ys -> xs @ ys` -- that is, as "the operation of prepending `xs`". This is the Yoneda embedding for the list monoid:

```ocaml env=yoneda
(* Difference lists: represent a list as a function *)
type 'a dlist = 'a list -> 'a list

let dlist_empty : 'a dlist = Fun.id
let dlist_singleton (x : 'a) : 'a dlist = fun rest -> x :: rest
let dlist_append (f : 'a dlist) (g : 'a dlist) : 'a dlist =
  fun rest -> f (g rest)    (* O(1) append! *)
let dlist_to_list (f : 'a dlist) : 'a list = f []

(* Building a list incrementally with O(1) append *)
let result =
  dlist_append
    (dlist_append (dlist_singleton 1) (dlist_singleton 2))
    (dlist_singleton 3)
  |> dlist_to_list

let () = assert (result = [1; 2; 3])
```

Difference lists turn $O(n)$ append into $O(1)$ by delaying the actual construction. The Yoneda lemma guarantees no information is lost.

#### The Codensity Monad

For monads, the Yoneda lemma leads to the **Codensity monad**: given a monad $M$, the type `forall b. (a -> m b) -> m b` is a monad (the "Codensity monad of $M$") that often has better performance for left-associated binds:

```ocaml env=yoneda
(* The Codensity monad improves left-associated binds *)
(* Codensity M a = forall b. (a -> M b) -> M b *)

(* For lists, Codensity gives efficient left-to-right construction *)
type 'a clist = { run : 'b. ('a -> 'b list) -> 'b list }

let creturn (x : 'a) : 'a clist =
  { run = fun k -> k x }

let cbind (m : 'a clist) (f : 'a -> 'b clist) : 'b clist =
  { run = fun k -> m.run (fun a -> (f a).run k) }

let clift (xs : 'a list) : 'a clist =
  { run = fun k -> List.concat_map k xs }

let crun (m : 'a clist) : 'a list = m.run (fun x -> [x])

(* Example: all pairs from two lists *)
let pairs xs ys =
  crun (cbind (clift xs) (fun x ->
        cbind (clift ys) (fun y ->
        creturn (x, y))))

let () = assert (pairs [1;2] ["a";"b"]
               = [(1,"a"); (1,"b"); (2,"a"); (2,"b")])
```

The deep insight: every object in a category is completely determined by how other objects map *into* it. The representable functors $\text{Hom}(A, -)$ form a "coordinate system" for the category, and the Yoneda lemma says this coordinate system is faithful -- it loses no information.

### 12.9 The Expression Problem, Categorically

Let us revisit Chapter 11 with categorical vocabulary. The expression problem asks for a design where both data constructors and operations can be independently extended. The categorical formulation: we want a diagram

$$\text{new constructors} \longrightarrow \text{extended type}$$
$$\downarrow \qquad\qquad\qquad\quad \downarrow$$
$$\text{new operations} \longrightarrow \text{extended semantics}$$

that **commutes** -- the two paths through the square yield the same result. This is a *naturality condition*: extending the type and then adding operations must agree with adding operations and then extending the type.

#### Solutions as Categorical Constructions

The solutions from Chapter 11 correspond to categorical constructions:

**Ordinary ADTs (Section 11.2)** work by *initial algebra*: the type is the initial algebra of a functor, and operations are catamorphisms. Extending the type means changing the functor, which breaks existing catamorphisms -- the square does not commute because the initial algebra is defined relative to a fixed functor.

**Polymorphic variants (Section 11.7)** correspond to a *colimit* construction. Each sub-language is a type, and combining them takes their coproduct (disjoint union). The polymorphic variant system in OCaml computes this coproduct using row polymorphism -- types like `` [> `Var of string | `Num of int] `` are *open* types that can be extended. The colimit exists when the row types are compatible.

**Objects (Section 11.5)** use *subtyping*, which is a different categorical structure: morphisms in a category of types ordered by the subtype relation.

#### Operations as Natural Transformations

In the polymorphic variant approach, each operation (like `eval` or `string_of`) must be *polymorphic in the type index* -- it must work uniformly for any extension of the base type. This is exactly the requirement that the operation be a **natural transformation**:

```ocaml skip
(* Each eval function has a type like: *)
(* val eval : [> `Var of string | `Num of int ] -> value *)
(* The [> ...] means it works for any extension -- *)
(* this is naturality in the row variable. *)
```

We can see the naturality square in action with polymorphic variants. Base operations are reused unchanged when the type is extended:

```ocaml env=expr
(* Base language with eval and show: *)
let eval_base = function `Num n -> n | `Neg n -> -n
let show_base = function
  | `Num n -> string_of_int n
  | `Neg n -> "-" ^ string_of_int n

(* Extended language -- base cases reuse the base operations: *)
let eval_ext = function
  | (`Num _ | `Neg _) as e -> eval_base e    (* reuse *)
  | `Add (a, b) -> a + b
let show_ext = function
  | (`Num _ | `Neg _) as e -> show_base e    (* reuse *)
  | `Add (a, b) -> string_of_int a ^ "+" ^ string_of_int b

(* The naturality square commutes: embedding a base expression *)
(* into the extended type and then evaluating gives the same   *)
(* result as evaluating in the base language directly.         *)
let e1 = `Num 5
let e2 = `Neg 3
let () = assert (eval_ext e1 = eval_base e1)
let () = assert (eval_ext e2 = eval_base e2)
let () = assert (show_ext e1 = show_base e1)
let () = assert (show_ext e2 = show_base e2)
```

The dynamic failure when no handler covers a constructor (e.g., in the extensible GADT approach from the OCaml discussion thread) is the *colimit not existing*: we tried to form a coproduct of partial natural transformations, but the components do not cover the whole type. A fully static GADT encoding would make this a compile-time error.

### 12.10 Curry--Howard--Lambek: The Trinity

We began the book in Chapter 1 with the Curry--Howard correspondence: propositions are types, proofs are programs. We now close the loop by adding the third vertex of the triangle.

The **Curry--Howard--Lambek correspondence** states that three seemingly different worlds are the same mathematical structure:

| Logic | Type Theory | Category Theory |
|-------|------------|----------------|
| Proposition | Type | Object |
| Proof | Program (term) | Morphism |
| Implication $A \Rightarrow B$ | Function type $A \to B$ | Exponential object $B^A$ |
| Conjunction $A \wedge B$ | Product type $A \times B$ | Categorical product $A \times B$ |
| Disjunction $A \vee B$ | Sum type `A + B` | Coproduct $A + B$ |
| True ($\top$) | Unit type | Terminal object $1$ |
| False ($\bot$) | Empty type `void` | Initial object $0$ |
| Modus ponens | Function application | Evaluation morphism |
| Hypothesis | Variable | Identity morphism |
| Cut elimination | $\beta$-reduction | Composition |

#### What the Correspondence Means

A **cartesian closed category** (CCC) -- a category with products, exponentials, and a terminal object -- is simultaneously:
1. A model of propositional logic (the internal logic of the category)
2. A model of the simply-typed lambda calculus (types are objects, terms are morphisms)
3. A category with enough structure to interpret all of functional programming

The OCaml type system lives in this world. When we write `let f : 'a * 'b -> 'b * 'a = fun (x, y) -> (y, x)`, we are simultaneously:
- **Proving** the logical tautology $A \wedge B \Rightarrow B \wedge A$
- **Programming** the swap function on pairs
- **Constructing** a morphism $A \times B \to B \times A$ in a CCC

```ocaml env=cat
(* Programs that are simultaneously logical proofs *)
(* and morphisms in a cartesian closed category:   *)

(* A ∧ B ⊃ B ∧ A  (commutativity of conjunction) *)
let comm : 'a * 'b -> 'b * 'a = fun (x, y) -> (y, x)

(* A ⊃ B ⊃ A  (weakening / the K combinator) *)
let weaken : 'a -> 'b -> 'a = fun a _b -> a

(* (A ⊃ B ⊃ C) ⊃ (A ∧ B ⊃ C)  (flip of currying) *)
let uncurry' : ('a -> 'b -> 'c) -> 'a * 'b -> 'c =
  fun f (a, b) -> f a b

(* (A ⊃ B) ⊃ (B ⊃ C) ⊃ (A ⊃ C)  (transitivity = composition) *)
let trans : ('a -> 'b) -> ('b -> 'c) -> 'a -> 'c =
  fun ab bc a -> bc (ab a)

(* trans is compose with arguments reordered: *)
let () = assert (trans f g 3 = compose g f 3)
```

#### Negation and Continuations

Classical logic allows double negation elimination: $\neg\neg A \Rightarrow A$. In the Curry--Howard reading, $\neg A$ is $A \to \bot$ (a function to the empty type). Under the CCC interpretation, $\neg A = \bot^A$ is the exponential.

Double negation elimination is *not* valid in constructive logic (or in OCaml's pure fragment). But in the CPS transform from Section 12.8, we saw that `'a` is equivalent to `forall 'b. ('a -> 'b) -> 'b` -- which looks like double negation if we read `'b` as $\bot$. The connection:

- **Constructive logic** = direct-style functional programming
- **Classical logic** = continuation-passing style (every program has access to its continuation)
- **Linear logic** = resource-aware computation (each value used exactly once)

These are not analogies -- they are *theorems*. The Curry--Howard--Lambek correspondence makes precise the sense in which logic, programming, and category theory are three views of one underlying structure.

#### The Recurring Motif

Throughout this chapter, we have asked: *what is stable under crossing levels?*

- **Galois connections**: the closed elements (fixed points of $g \circ f$)
- **Adjunctions**: the unit and counit (the canonical witnesses)
- **Yoneda**: representable functors (the perfectly faithful reification)
- **Curry--Howard--Lambek**: the trinity itself (truths that appear in all three worlds simultaneously)

This also connects to **reification and reflection**: reification promotes a computational concept to a first-class value (right adjoint; conservative; loses nothing), while reflection executes it (left adjoint; may lose information). GADTs are OCaml's reification mechanism. The round-trip $\text{reflect} \circ \text{reify}$ is a closure operator -- you recover the *canonical form*, not necessarily the original.

### 12.11 Exercises

1. **Category laws.** Define a `CATEGORY` instance for the `option` type, where `('a, 'b) hom = 'a -> 'b option` (the Kleisli category of `Option`). Implement `id` and `compose`, and verify the three category laws on test cases. (Hint: this is the composition you get from `Option.bind`.)

```ocaml skip
(* Starter code for Exercise 1 *)
module KleisliOption (* : CATEGORY ... *) = struct
  type ('a, 'b) hom = 'a -> 'b option
  let id x = failwith "todo"
  let compose g f x = failwith "todo"
end

(* Test the laws with these morphisms: *)
let f x = if x > 0 then Some (x + 1) else None
let g x = if x < 100 then Some (x * 2) else None
let x = 5

(* Left identity:  compose id f x = f x *)
(* Right identity: compose f id x = f x *)
(* Associativity:  compose h (compose g f) x
                 = compose (compose h g) f x *)
```

2. **Free category.** Extend the pipeline example from Section 12.3 with two new stages (e.g., `Uppercase : (string, string) stage` and `Length : (string, int) stage`). Build three distinct paths through the graph and interpret each one. Verify that `concat` is associative: `interpret (concat (concat p q) r) x = interpret (concat p (concat q r)) x`.

```ocaml skip
(* Starter code for Exercise 2 *)
type ('a, 'b) stage =
  | Parse     : (string, string list) stage
  | Filter    : (string list, string list) stage
  | Count     : (string list, int) stage
  | Show      : (int, string) stage
  | Uppercase : (string, string) stage      (* new *)
  | Length    : (string, int) stage          (* new *)

(* Copy the path type, concat, interpret_stage, and interpret *)
(* from Section 12.3, then extend interpret_stage for the     *)
(* new constructors.                                          *)

(* Build three distinct paths and verify: *)
(* interpret (concat (concat p q) r) x                       *)
(*   = interpret (concat p (concat q r)) x                   *)
```

3. **Functor laws.** Write a functor instance for `type 'a tree = Leaf | Node of 'a tree * 'a * 'a tree` and test the functor laws (`map id = id` and `map (f ∘ g) = map f ∘ map g`) on at least two non-trivial trees.

```ocaml skip
(* Starter code for Exercise 3 *)
type 'a tree = Leaf | Node of 'a tree * 'a * 'a tree

let rec map_tree (f : 'a -> 'b) : 'a tree -> 'b tree = function
  | Leaf -> failwith "todo"
  | Node (l, v, r) -> failwith "todo"

(* Test trees: *)
let t1 = Node (Node (Leaf, 1, Leaf), 2, Node (Leaf, 3, Leaf))
let t2 = Node (Leaf, 10, Node (Node (Leaf, 20, Leaf), 30, Leaf))

let f x = x + 1
let g x = x * 2

(* Law 1: map_tree Fun.id t = t *)
(* Law 2: map_tree (fun x -> f (g x)) t *)
(*      = map_tree f (map_tree g t)      *)
```

4. **Naturality verification.** The function `List.rev` is a natural transformation from the List functor to itself. State and test the naturality condition for three different functions `f`. Then consider `List.sort compare` -- is it a natural transformation? Why or why not?

5. **Galois connection.** The functions `abs : int -> int` and `negate : int -> int` do *not* form a Galois connection on integers with the usual ordering. Explain why. Then find a pair of monotone functions between `(int, <=)` and `(int, >=)` that *does* form a Galois connection.

6. **Lens composition.** Define a type `type address = { street : string; city : string }` and `type employee = { name : string; addr : address }`. Write lenses `street_lens`, `addr_lens`, and compose them to create `employee_street_lens`. Verify all three lens laws (Get-Set, Set-Get, Set-Set) for the composed lens.

```ocaml skip
(* Starter code for Exercise 6 *)
type address = { street : string; city : string }
type employee = { name : string; addr : address }

let street_lens : (address, string) lens = {
  get = (fun a -> failwith "todo");
  set = (fun s a -> failwith "todo");
}

let addr_lens : (employee, address) lens = {
  get = (fun e -> failwith "todo");
  set = (fun a e -> failwith "todo");
}

(* Compose using compose_lens from Section 12.7: *)
let employee_street = compose_lens addr_lens street_lens

(* Test data: *)
let emp = { name = "Alice";
            addr = { street = "123 Main"; city = "NYC" } }

(* Verify all three lens laws for the composed lens. *)
```

7. **Prism round-trip.** For the type `type shape = Circle of float | Rect of float * float`, write a prism for `Circle` and a prism for `Rect`. Verify the prism law: `review a |> preview = Some a`. What happens when you `preview` a value built with the other constructor?

8. **Difference lists.** Implement a `dlist` module with `empty`, `singleton`, `append`, `cons`, `snoc`, and `to_list`. Write a function that builds a list of $n$ elements using repeated `append` with regular lists (quadratic) and with difference lists (linear). Test that both produce the same result.

9. **Codensity optimization.** Consider a computation that left-associates many `bind` operations on lists: `bind (bind (bind (return 1) f) g) h`. Implement this computation both using regular list bind and using the Codensity monad from Section 12.8, and verify they produce the same result. (The Codensity version avoids re-traversal for left-associated binds.)

10. **The trinity in action.** For each of the following OCaml types, state the corresponding logical proposition and verify it is a tautology: (a) `'a * 'b -> 'b * 'a`, (b) `'a -> 'b -> 'a`, (c) `('a -> 'b -> 'c) -> 'a * 'b -> 'c`, (d) `('a -> 'b) -> ('b -> 'c) -> 'a -> 'c`. For (d), what is the categorical interpretation?

11. **Expression problem, categorically.** Take two of the solutions from Chapter 11 (e.g., ordinary ADTs and polymorphic variants). For each, explain in categorical language *why* one direction of extension is easy and the other is hard. Use the vocabulary from Section 12.9 (initial algebra, colimit, natural transformation).

12. **Concept lattice.** Extend the Formal Concept Analysis example from Section 12.6 with two more animals and two more attributes. Compute all formal concepts (closed pairs) of the extended context. Which concepts form the top and bottom of the lattice?
