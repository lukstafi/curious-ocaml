# Optional route: optics and deferred composition

**Prerequisites:** Chapters 2, 6 and 12. Run `dune runtest projects/optics`.
These constructions are further study; the main chapter does not rely on them.
Equations concern total pure functions with extensional equality, finite data,
and the stated representation laws.

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

Consider a stream `{ head : 'a; tail : unit -> 'a stream }` from Chapter 7. The finite polynomial calculation does not apply directly to this potentially infinite, effectful representation. A stream zipper can nevertheless store a finite prefix and a remaining stream. A lens offers a different interface: here it focuses directly on the head.

```ocaml env=lens
(* This lens needs no chosen zipper representation. *)
(* but we can still define lenses on it. *)
type 'a stream = { head : 'a; tail : unit -> 'a stream }

let stream_head_lens = {
  get = (fun s -> s.head);
  set = (fun a s -> { s with head = a });
}
```

This is the key advantage: lenses abstract over the *interface* to a subpart, regardless of whether the containing type has a concrete derivative.

#### Prisms: access to a sum case

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

The two interfaces describe different access patterns. Neither supplies a
universal-property solution to Chapter 11's separate-extension requirements.
For this prism interface, check `preview (review a) = Some a` and, whenever
`preview s = Some a`, `review a = s`. These laws need explicit hypotheses on
the chosen constructor representation.

#### The Van Laarhoven Encoding

There is an elegant encoding of lenses as polymorphic functions, discovered by Twan van Laarhoven. A lens from `'s` to `'a` can be represented as:

$$\text{Lens}(S, A) = \forall F.\ \text{Functor}(F) \Rightarrow (A \to F(A)) \to S \to F(S)$$

This encoding composes with ordinary function composition, which is why lens libraries are so ergonomic. Relating this encoding to a representation theorem requires naturality in the
functor as well as the lens laws; the executable module example below alone
does not establish that theorem.

In Haskell, a VL lens is a single rank-2 polymorphic definition:

<!-- book-skip: Haskell type notation, not OCaml source -->
```ocaml skip
(* Haskell-style Van Laarhoven lens (not valid OCaml): *)
(*   type Lens s a = forall f. Functor f => (a -> f a) -> s -> f s   *)
(*   _fst :: Lens (a, b) a                                          *)
(*   _fst f (x, y) = fmap (\x' -> (x', y)) (f x)                   *)
(* Instantiating f = Identity gives "set"; f = Const gives "get".   *)
```

OCaml supports higher-rank polymorphism through explicitly polymorphic record fields and object methods. What this encoding needs additionally is quantification over a type constructor `f`, which ordinary OCaml type variables cannot express directly. We can recover a single lens definition by parameterizing over the functor with an OCaml module:

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
  VL_FUNCTOR with type 'a t = T.t =
struct
  type 'a t = T.t
  let fmap _ x = x
end

module FstSet = VL_Fst(IdF)
module FstGet = VL_Fst(ConstF(struct type t = int end))

let () = assert (FstSet._fst (fun _ -> 10) (1, "hello") = (10, "hello"))
let () = assert (FstGet._fst (fun a -> a) (42, "world") = 42)
```

The lens logic lives in a single place -- `VL_Fst._fst` -- and both get and set are obtained by choosing the functor. The set direction (`FstSet._fst`) is fully polymorphic in the pair types. The get direction requires fixing the focused type when instantiating `ConstF` (here, `int`), a limitation of OCaml's module system compared to Haskell's rank-2 types. This is OCaml's module-level analogue of Haskell's rank-2 polymorphism. The key insight remains: Van Laarhoven lenses compose with ordinary function composition.


#### Difference Lists

**Difference lists** are a monoid representation. A list `xs` can be represented as the function `fun ys -> xs @ ys` -- that is, as "the operation of prepending `xs`". This is the Cayley representation of the list monoid, related to the representable-functor viewpoint:

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

Constructing a composed difference list costs $O(1)$; converting it to a list still performs the deferred work. The representation invariant is `f tail = prefix @ tail` for some fixed `prefix`, recoverable as `f []`. Not every function of type `'a list -> 'a list` satisfies that invariant. Long chains also require attention to stack usage.

#### The Codensity Monad

A further higher-rank construction is the **Codensity monad**: given a monad $M$, the type `forall b. (a -> m b) -> m b` is a monad (the "Codensity monad of $M$") whose performance must be measured for the chosen base representation:

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


## Acceptance criteria

Prove lens composition preserves all three lens laws, and test each law for
the nested-record example. For difference lists, prove the prefix invariant for
the exported constructors and composition, then measure deferred work at
conversion. Compare codensity on a concrete left-associated bind workload before
making a performance claim. A polymorphic type alone proves none of these laws.
