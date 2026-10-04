# Optional route: type inference and polymorphic recursion

**Prerequisites:** Chapters 1–2 and Chapter 5. These sections give the detailed
constraint derivations separated from the main lesson on module specifications.
Run `dune runtest projects/type-inference`.

### 5.1 Type Inference

We have seen the rules that govern the assignment of types to expressions, but how does OCaml actually guess what types to use? And how does it know when no correct types exist? The answer lies in a beautiful algorithm: OCaml solves equations. When you write code, the type checker generates a set of equations that must hold for the program to be well-typed, and then it solves those equations to discover the types.

#### Variables: Unknowns and Parameters

Variables in type inference play two distinct roles, and understanding this distinction is crucial for mastering OCaml's type system. A type variable can be either an *unknown* (standing for a specific but not-yet-determined type) or a *parameter* (standing for any type whatsoever).

Consider this example:

```ocaml env=ch5
# let f = List.hd;;
val f : 'a list -> 'a = <fun>
```

Here `'a` is a *parameter*: it can become any type. When you use `f` with a list of integers, `'a` becomes `int`; when you use it with a list of strings, `'a` becomes `string`. Mathematically we write: $f : \forall \alpha . \alpha \ \text{list} \rightarrow \alpha$ -- the quantified type is called a *type scheme*. The $\forall$ symbol indicates that this type works "for all" choices of $\alpha$.

In contrast, consider this example:

<!-- book-skip: illustrative weak-variable printer output; identifiers vary by compiler -->
```ocaml skip
# let x = ref [];;
val x : '_weak1 list ref = {contents = []}
```

Here `'_a` (displayed as `'_weak1` in recent OCaml versions) is an *unknown*. Unlike a parameter, it stands for a *particular* type -- perhaps `float` or `int -> int` -- but OCaml simply doesn't know which type yet. The underscore prefix signals this distinction. OCaml reports unknowns like `'_a` in inferred types for reasons related to mutable state (the "value restriction"), which can also affect pure expressions, as the partial-application examples below illustrate.

More precisely: the *value restriction* prevents unsoundness that would otherwise arise from generalizing type variables in effectful (mutable) expressions. When you see `'_weak...`, treat it as “this will become one specific type later”.

When unknowns appear in inferred types against our expectations, *$\eta$-expansion* may help. This technique involves writing `let f x = expr x` instead of `let f = expr`, essentially adding an extra parameter that gets immediately applied. For example:

<!-- book-skip: illustrative value-restriction transcript; printer output varies by compiler -->
```ocaml skip
# let f = List.append [];;
val f : '_weak2 list -> '_weak2 list = <fun>
# let f l = List.append [] l;;
val f : 'a list -> 'a list = <fun>
```

In the second definition, the eta-expanded form `let f l = List.append [] l` allows full generalization, giving us a truly polymorphic function that can work with lists of any type.

#### Type Environments

Before diving into the equation-solving process, we need to understand how the type checker keeps track of what names are available. A *type environment* specifies what names (corresponding to parameters and definitions) are available for an expression because they were introduced above it, and it specifies their types. Think of it as a dictionary that maps variable names to their types at any given point in your program.

#### Solving Type Equations

Type inference works by solving equations over unknowns. The central question the algorithm asks is: "What has to hold so that $e : \tau$ in type environment $\Gamma$?" The answer takes the form of equations that constrain the possible types.

Let us walk through how the algorithm handles different expression forms:

- If, for example, $f : \forall \alpha . \alpha \ \text{list} \rightarrow \alpha \in \Gamma$, then for $f : \tau$ we introduce $\gamma \ \text{list} \rightarrow \gamma = \tau$ for some fresh unknown $\gamma$.

- For function application $e_1 \ e_2 : \tau$, we introduce $\beta = \tau$ and ask for $e_1 : \gamma \rightarrow \beta$ and $e_2 : \gamma$, for some fresh unknowns $\beta, \gamma$.

- For a function $\text{fun} \ x \rightarrow e : \tau$, we introduce $\beta \rightarrow \gamma = \tau$ and ask for $e : \gamma$ in environment $\{x : \beta\} \cup \Gamma$, for some fresh unknowns $\beta, \gamma$.

- The case $\text{let} \ x = e_1 \ \text{in} \ e_2 : \tau$ is different. One approach is to *first* solve the equations that we get by asking for $e_1 : \beta$, for some fresh unknown $\beta$. Let us say a solution $\beta = \tau_\beta$ has been found, $\alpha_1 \ldots \alpha_n \beta_1 \ldots \beta_m$ are the remaining unknowns in $\tau_\beta$, and $\alpha_1 \ldots \alpha_n$ are all that do not appear in $\Gamma$. Then we ask for $e_2 : \tau$ in environment $\{x : \forall \alpha_1 \ldots \alpha_n . \tau_\beta\} \cup \Gamma$.

- Remember that whenever we establish a solution $\beta = \tau_\beta$ to an unknown $\beta$, it takes effect everywhere! The substitution propagates through all the equations, potentially triggering further unifications.

- To find a type for $e$ (in environment $\Gamma$), we pick a fresh unknown $\beta$ and ask for $e : \beta$ (in $\Gamma$). The algorithm then generates and solves equations until either a solution is found or a contradiction reveals a type error.

#### Polymorphism

The "top-level" definitions for which the system infers types with variables are called *polymorphic*, which informally means "working with different shapes of data." A polymorphic function like `List.hd` can operate on lists containing any type of element -- the function itself doesn't care what the elements are, only that it's working with a list.

This kind of polymorphism is called *parametric polymorphism*, since the types have parameters. The term "parametric" emphasizes that the same code works uniformly for all type instantiations. A different kind of polymorphism is provided by object-oriented programming languages (sometimes called *subtype polymorphism* or *ad-hoc polymorphism*), where different code may execute depending on the runtime type of objects.

### 5.2 Parametric Types

Polymorphic functions truly shine when used with polymorphic data types. The combination of the two is what makes ML-family languages so expressive. Consider this definition of our own list type:

```ocaml env=ch5
type 'a my_list = Empty | Cons of 'a * 'a my_list
```

We define lists that can store elements of any type `'a`. The type parameter `'a` acts as a placeholder that gets filled in when we create actual lists. Now we can write functions that work on these lists:

```ocaml env=ch5
# let tail l =
    match l with
    | Empty -> invalid_arg "tail"
    | Cons (_, tl) -> tl;;
val tail : 'a my_list -> 'a my_list = <fun>
```

This is a polymorphic function: it works for lists with elements of any type. Whether we have a list of integers, strings, or even lists of lists, the same `tail` function handles them all.

A crucial point to understand: a *parametric type* like `'a my_list` *is not* itself a data type but rather a *family* of data types. The types `bool my_list`, `int my_list`, etc. *are* different types -- you cannot mix elements of different types in a single list. We say that the type `int my_list` *instantiates* the parametric type `'a my_list`.

#### Multiple Type Parameters

Types can have multiple type parameters. In OCaml, the syntax might seem a bit unusual at first: type parameters precede the type name, enclosed in parentheses. For example:

```ocaml env=ch5
type ('a, 'b) choice = Left of 'a | Right of 'b
```

This type has two parameters and represents a value that is either something of type `'a` (wrapped in `Left`) or something of type `'b` (wrapped in `Right`). Mathematically we would write $\text{choice}(\alpha, \beta)$.

Not all functions that use parametric types need to be polymorphic. A function may constrain the type parameters to specific types:

```ocaml env=ch5
# let get_int c =
    match c with
    | Left i -> i
    | Right b -> if b then 1 else 0;;
val get_int : (int, bool) choice -> int = <fun>
```

Here, the pattern matching on `Left i` and `Right b` with arithmetic operations constrains the type to `(int, bool) choice`.

#### Syntax in Other Languages

Different functional languages have different syntactic conventions for type parameters. In F#, we provide parameters (when more than one) after the type name, using angle brackets:

```fsharp
type choice<'a,'b> = Left of 'a | Right of 'b
```

In Haskell, the syntax is arguably the cleanest -- we provide type parameters similarly to function arguments, separated by spaces:

```haskell
data Choice a b = Left a | Right b
```

Despite the syntactic differences, the underlying concept of parametric polymorphism is the same across all these languages.

### 5.3 Type Inference, Formally

Now we present a more formal treatment of type inference. A statement that an expression has a type in an environment is called a *type judgement*. For environment $\Gamma = \{x : \forall \alpha_1 \ldots \alpha_n . \tau_x ; \ldots\}$, expression $e$ and type $\tau$ we write:

$$\Gamma \vdash e : \tau$$

This notation reads: "In environment $\Gamma$, expression $e$ has type $\tau$." The turnstile symbol $\vdash$ can be thought of as "entails" or "proves."

We will derive all the constraint equations in one go using the notation $[\![ \cdot ]\!]$, to be solved later by unification. Besides equations we will need to manage introduced variables, using existential quantification to express that "there exists some type variable satisfying these constraints."

For local definitions we require remembering what constraints should hold when the definition is used. Therefore we extend *type schemes* in the environment to: $\Gamma = \{x : \forall \beta_1 \ldots \beta_m [\exists \alpha_1 \ldots \alpha_n . D] . \tau_x ; \ldots\}$ where $D$ are equations -- keeping the variables $\alpha_1 \ldots \alpha_n$ introduced while deriving $D$ in front. A simpler form would be sufficient: $\Gamma = \{x : \forall \beta [\exists \alpha_1 \ldots \alpha_n . D] . \beta ; \ldots\}$

The formal constraint generation rules are:

$$[\![ \Gamma \vdash x : \tau ]\!] = \exists \overline{\beta'} \overline{\alpha'} . (D[\overline{\beta} \overline{\alpha} := \overline{\beta'} \overline{\alpha'}] \wedge \tau_x[\overline{\beta} \overline{\alpha} := \overline{\beta'} \overline{\alpha'}] \doteq \tau)$$

where $\Gamma(x) = \forall \overline{\beta} [\exists \overline{\alpha} . D] . \tau_x$, $\overline{\beta'} \overline{\alpha'} \# \text{FV}(\Gamma, \tau)$

$$[\![ \Gamma \vdash \mathbf{fun} \ x \texttt{->} e : \tau ]\!] = \exists \alpha_1 \alpha_2 . ([\![ \Gamma \{x : \alpha_1\} \vdash e : \alpha_2 ]\!] \wedge \alpha_1 \rightarrow \alpha_2 \doteq \tau)$$

where $\alpha_1 \alpha_2 \# \text{FV}(\Gamma, \tau)$

$$[\![ \Gamma \vdash e_1 \ e_2 : \tau ]\!] = \exists \alpha . ([\![ \Gamma \vdash e_1 : \alpha \rightarrow \tau ]\!] \wedge [\![ \Gamma \vdash e_2 : \alpha ]\!]), \alpha \# \text{FV}(\Gamma, \tau)$$

$$[\![ \Gamma \vdash K \ e_1 \ldots e_n : \tau ]\!] = \exists \overline{\alpha'} . (\bigwedge_i [\![ \Gamma \vdash e_i : \tau_i[\overline{\alpha} := \overline{\alpha'}] ]\!] \wedge \varepsilon(\overline{\alpha'}) \doteq \tau)$$

where $K : \forall \overline{\alpha} . \tau_1 \times \ldots \times \tau_n \rightarrow \varepsilon(\overline{\alpha})$, $\overline{\alpha'} \# \text{FV}(\Gamma, \tau)$

For let-expressions:

$$[\![ \Gamma \vdash \mathbf{let} \ x = e_1 \ \mathbf{in} \ e_2 : \tau ]\!] = (\exists \beta . C) \wedge [\![ \Gamma \{x : \forall \beta [C] . \beta\} \vdash e_2 : \tau ]\!]$$

where $C = [\![ \Gamma \vdash e_1 : \beta ]\!]$

For recursive let-expressions:

$$[\![ \Gamma \vdash \mathbf{letrec} \ x = e_1 \ \mathbf{in} \ e_2 : \tau ]\!] = (\exists \beta . C) \wedge [\![ \Gamma \{x : \forall \beta [C] . \beta\} \vdash e_2 : \tau ]\!]$$

where $C = [\![ \Gamma \{x : \beta\} \vdash e_1 : \beta ]\!]$

For match expressions:

$$[\![ \Gamma \vdash \mathbf{match} \ e_v \ \mathbf{with} \ \overline{c} : \tau ]\!] = \exists \alpha_v . [\![ \Gamma \vdash e_v : \alpha_v ]\!] \bigwedge_i [\![ \Gamma \vdash p_i . e_i : \alpha_v \rightarrow \tau ]\!]$$

where $\overline{c} = p_1 . e_1 | \ldots | p_n . e_n$, $\alpha_v \# \text{FV}(\Gamma, \tau)$

For pattern clauses:

$$[\![ \Gamma, \Sigma \vdash p.e : \tau_1 \rightarrow \tau_2 ]\!] = [\![ \Sigma \vdash p \downarrow \tau_1 ]\!] \wedge \forall \overline{\beta} . [\![ \Gamma \Gamma' \vdash e : \tau_2 ]\!]$$

where $\exists \overline{\beta} \Gamma'$ is $[\![ \Sigma \vdash p \uparrow \tau_1 ]\!]$, $\overline{\beta} \# \text{FV}(\Gamma, \tau_2)$

The notation $[\![ \Sigma \vdash p \downarrow \tau_1 ]\!]$ derives constraints on the type of the matched value, while $[\![ \Sigma \vdash p \uparrow \tau_1 ]\!]$ derives the environment for pattern variables.

By $\overline{\alpha}$ or $\overline{\alpha_i}$ we denote a sequence of some length: $\alpha_1 \ldots \alpha_n$. By $\bigwedge_i \varphi_i$ we denote a conjunction of $\overline{\varphi_i}$: $\varphi_1 \wedge \ldots \wedge \varphi_n$.

#### Polymorphic Recursion

There is an interesting limitation in standard type inference for recursive functions. Note the limited polymorphism of `let rec f = ...` -- we cannot use `f` polymorphically within its own definition. Why? Because when type-checking the body of a recursive definition, we don't yet know the final type of `f`, so we must treat it as having a single, unknown type.

In modern OCaml we can bypass this limitation if we provide the type of `f` upfront:

```text
let rec f : 'a. 'a -> 'a list = ...
```

where `'a. 'a -> 'a list` stands for $\forall \alpha . \alpha \rightarrow \alpha \ \text{list}$.

Using the recursively defined function with different types in its definition is called *polymorphic recursion*. It is most useful together with *irregular recursive datatypes* -- data structures where the recursive use has different type arguments than the actual parameters. These "nested" or "non-uniform" datatypes enable some remarkably elegant data structures.

##### Example: A List Alternating Between Two Types of Elements

Here is a fascinating example: a list that alternates between two different types of elements. Notice how the recursive occurrence swaps the type parameters:

```ocaml env=ch5
type ('x, 'o) alternating =
  | Stop
  | One of 'x * ('o, 'x) alternating

let rec to_list :
    'x 'o 'a. ('x -> 'a) -> ('o -> 'a) ->
              ('x, 'o) alternating -> 'a list =
  fun x2a o2a ->
    function
    | Stop -> []
    | One (x, rest) -> x2a x :: to_list o2a x2a rest

let to_choice_list alt =
  to_list (fun x -> Left x) (fun o -> Right o) alt

let it = to_choice_list
  (One (1, One ("o", One (2, One ("oo", Stop)))))
```

Notice how the recursive call to `to_list` swaps `o2a` and `x2a` -- this is necessary because the alternating structure swaps the type parameters at each level. The polymorphic recursion annotation `'x 'o 'a.` tells OCaml that we need to use `to_list` at different type instantiations within its own definition.

##### Example: Data-Structural Bootstrapping

Here is another powerful example of polymorphic recursion: a sequence data structure that stores elements in exponentially increasing chunks. This technique, known as *data-structural bootstrapping*, achieves logarithmic-time random access -- much faster than standard lists which require linear time.

```ocaml env=ch5
type 'a seq =
  | Nil
  | Zero of ('a * 'a) seq
  | One of 'a * ('a * 'a) seq
```

The key insight is that this type is *non-uniform*: the recursive occurrences use `('a * 'a) seq` rather than `'a seq`. This means that as we go deeper into the structure, elements get paired together, effectively doubling the "width" at each level. We store a list of elements in exponentially increasing chunks:

```ocaml env=ch5
let example =
  One (0, One ((1,2), Zero (One ((((3,4),(5,6)), ((7,8),(9,10))), Nil))))
```

The `cons` operation adds an element to the front. Remarkably, appending an element to this data structure works exactly like adding one to a binary number:

```ocaml env=ch5
let rec cons : 'a. 'a -> 'a seq -> 'a seq =
  fun x -> function
  | Nil -> One (x, Nil)                       (* 1+0=1 *)
  | Zero ps -> One (x, ps)                    (* 1+...0=...1 *)
  | One (y, ps) -> Zero (cons (x,y) ps)       (* 1+...1=[...+1]0 *)

let rec lookup : 'a. int -> 'a seq -> 'a =
  fun i s -> match i, s with
  | _, Nil -> raise Not_found              (* Rather than returning None : 'a option *)
  | 0, One (x, _) -> x                     (* we raise exception, for convenience. *)
  | i, One (_, ps) -> lookup (i-1) (Zero ps)
  | i, Zero ps ->                          (* Random-access lookup works *)
      let x, y = lookup (i / 2) ps in      (* in logarithmic time -- much faster *)
      if i mod 2 = 0 then x else y         (* than in standard lists. *)
```

The `Zero` and `One` constructors correspond to binary digits. A `Zero` means "no singleton element at this level," while `One` carries a singleton (or pair, or quad, etc.) before recursing. The `lookup` function exploits this structure: when looking up index `i` in a `Zero ps`, it divides by 2 and looks in the paired structure, then extracts the appropriate half of the pair.


## Practice and acceptance criteria

Derive the type of `fun f x -> f (f x)` by unification. Explain why a recursive
type equation must fail an occurs check in ordinary Hindley–Milner inference.
For a unifier project, reject constructor arity mismatches, test substitution
idempotence, and distinguish fresh unknowns from universally quantified variables.
