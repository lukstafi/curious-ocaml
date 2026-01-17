## Chapter 5: Polymorphism and Abstract Data Types

**In this chapter, you will:**

- Understand “unknowns vs parameters” in OCaml’s inferred types (and why the value restriction exists)
- Connect type inference to solving constraint systems (unification intuition)
- Use parametric types to design reusable, type-safe data structures
- Specify ADTs algebraically and implement maps with increasing efficiency (lists → BSTs → red-black trees)

This chapter explores how OCaml's type system supports generic programming through parametric polymorphism, and how abstract data types provide clean interfaces for data structures. We begin by examining how type inference actually works -- the process by which OCaml determines types for your code. Then we explore parametric types and show how they enable polymorphic functions to work with data of any shape. The second half of the chapter introduces algebraic specifications, the mathematical foundation for describing data structures, and applies these concepts to build progressively more sophisticated implementations of the map (dictionary) data structure, culminating in the elegant red-black tree.

*Reader feedback welcome: if you spot an error or unclear passage, please report it.*

### 5.1 Type Inference

We have seen the rules that govern the assignment of types to expressions, but how does OCaml actually guess what types to use? And how does it know when no correct types exist? The answer lies in a beautiful algorithm: OCaml solves equations. When you write code, the type checker generates a set of equations that must hold for the program to be well-typed, and then it solves those equations to discover the types.

#### Variables: Unknowns and Parameters

Variables in type inference play two distinct roles, and understanding this distinction is crucial for mastering OCaml's type system. A type variable can be either an *unknown* (standing for a specific but not-yet-determined type) or a *parameter* (standing for any type whatsoever).

Consider this example:

```ocaml
# let f = List.hd;;
val f : 'a list -> 'a = <fun>
```

Here `'a` is a *parameter*: it can become any type. When you use `f` with a list of integers, `'a` becomes `int`; when you use it with a list of strings, `'a` becomes `string`. Mathematically we write: $f : \forall \alpha . \alpha \ \text{list} \rightarrow \alpha$ -- the quantified type is called a *type scheme*. The $\forall$ symbol indicates that this type works "for all" choices of $\alpha$.

In contrast, consider this example:

```ocaml skip
# let x = ref [];;
val x : '_weak1 list ref = {contents = []}
```

Here `'_a` (displayed as `'_weak1` in recent OCaml versions) is an *unknown*. Unlike a parameter, it stands for a *particular* type -- perhaps `float` or `int -> int` -- but OCaml simply doesn't know which type yet. The underscore prefix signals this distinction. OCaml reports unknowns like `'_a` in inferred types for reasons related to mutable state (the "value restriction"), which are not relevant to purely functional programming.

More precisely: the *value restriction* prevents unsoundness that would otherwise arise from generalizing type variables in effectful (mutable) expressions. When you see `'_weak...`, treat it as “this will become one specific type later”.

When unknowns appear in inferred types against our expectations, *$\eta$-expansion* may help. This technique involves writing `let f x = expr x` instead of `let f = expr`, essentially adding an extra parameter that gets immediately applied. For example:

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

```ocaml
type 'a my_list = Empty | Cons of 'a * 'a my_list
```

We define lists that can store elements of any type `'a`. The type parameter `'a` acts as a placeholder that gets filled in when we create actual lists. Now we can write functions that work on these lists:

```ocaml
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

```ocaml
type ('a, 'b) choice = Left of 'a | Right of 'b
```

This type has two parameters and represents a value that is either something of type `'a` (wrapped in `Left`) or something of type `'b` (wrapped in `Right`). Mathematically we would write $\text{choice}(\alpha, \beta)$.

Not all functions that use parametric types need to be polymorphic. A function may constrain the type parameters to specific types:

```ocaml
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

$$[\![ \Gamma, \Sigma \vdash p.e : \tau_1 \rightarrow \tau_2 ]\!] = [\![ \Sigma \vdash p \downarrow \tau_1 ]\!] \wedge \exists \overline{\beta} . [\![ \Gamma \Gamma' \vdash e : \tau_2 ]\!]$$

where $\exists \overline{\beta} \Gamma'$ is $[\![ \Sigma \vdash p \uparrow \tau_1 ]\!]$, $\overline{\beta} \# \text{FV}(\Gamma, \tau_2)$

The notation $[\![ \Sigma \vdash p \downarrow \tau_1 ]\!]$ derives constraints on the type of the matched value, while $[\![ \Sigma \vdash p \uparrow \tau_1 ]\!]$ derives the environment for pattern variables.

By $\overline{\alpha}$ or $\overline{\alpha_i}$ we denote a sequence of some length: $\alpha_1 \ldots \alpha_n$. By $\bigwedge_i \varphi_i$ we denote a conjunction of $\overline{\varphi_i}$: $\varphi_1 \wedge \ldots \wedge \varphi_n$.

#### Polymorphic Recursion

There is an interesting limitation in standard type inference for recursive functions. Note the limited polymorphism of `let rec f = ...` -- we cannot use `f` polymorphically within its own definition. Why? Because when type-checking the body of a recursive definition, we don't yet know the final type of `f`, so we must treat it as having a single, unknown type.

In modern OCaml we can bypass this limitation if we provide the type of `f` upfront:

```
let rec f : 'a. 'a -> 'a list = ...
```

where `'a. 'a -> 'a list` stands for $\forall \alpha . \alpha \rightarrow \alpha \ \text{list}$.

Using the recursively defined function with different types in its definition is called *polymorphic recursion*. It is most useful together with *irregular recursive datatypes* -- data structures where the recursive use has different type arguments than the actual parameters. These "nested" or "non-uniform" datatypes enable some remarkably elegant data structures.

##### Example: A List Alternating Between Two Types of Elements

Here is a fascinating example: a list that alternates between two different types of elements. Notice how the recursive occurrence swaps the type parameters:

```ocaml
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

```ocaml
type 'a seq =
  | Nil
  | Zero of ('a * 'a) seq
  | One of 'a * ('a * 'a) seq
```

The key insight is that this type is *non-uniform*: the recursive occurrences use `('a * 'a) seq` rather than `'a seq`. This means that as we go deeper into the structure, elements get paired together, effectively doubling the "width" at each level. We store a list of elements in exponentially increasing chunks:

```ocaml
let example =
  One (0, One ((1,2), Zero (One ((((3,4),(5,6)), ((7,8),(9,10))), Nil))))
```

The `cons` operation adds an element to the front. Remarkably, appending an element to this data structure works exactly like adding one to a binary number:

```ocaml
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

### 5.4 Algebraic Specification

Now we turn to a fundamental question in computer science: how do we formally describe what a data structure *is* and what it should *do*? The mathematical answer is *algebraic specification*.

The way we introduce a data structure, like complex numbers or strings, in mathematics is by specifying an *algebraic structure*. This approach gives us a precise language for describing data structures independent of any particular implementation.

Algebraic structures consist of a set (or several sets, for so-called *multisorted* algebras) and a bunch of functions (also known as operations) over this set (or sets). Think of integers with addition and multiplication, or strings with concatenation and character access.

A *signature* is a rough description of an algebraic structure: it provides *sorts* -- names for the sets (in the multisorted case) -- and names of the functions-operations together with their arity (and what sorts of arguments they take). A signature tells us what operations exist, but not how they behave.

We select a class of algebraic structures by providing axioms that have to hold. We will call such classes *algebraic specifications*. In mathematics, a rusty name for some algebraic specifications is a *variety*; a more modern name is *algebraic category*.

Here is the key connection to programming: algebraic structures correspond to "implementations" and signatures to "interfaces" in programming languages. We will say that an algebraic structure *implements* an algebraic specification when all axioms of the specification hold in the structure. An important point: all algebraic specifications are implemented by multiple structures! This is precisely what we want -- it gives us the freedom to choose different implementations with different performance characteristics while maintaining the same interface.

We say that an algebraic structure does not have *junk* when all its elements (i.e., elements in the sets corresponding to sorts) can be built using operations in its signature. Junk-free structures are "minimal" in some sense -- they contain only the values that can be constructed using the provided operations.

We allow parametric types as sorts. In that case, strictly speaking, we define a family of algebraic specifications (a different specification for each instantiation of the parametric type).

#### Algebraic Specifications: Examples

Let us look at some concrete examples to make these abstract ideas tangible. An algebraic specification can also use an earlier specification, building up complexity layer by layer. In "impure" languages like OCaml and F# we allow that the result of any operation be an $\text{error}$. In Haskell we would use `Maybe` to explicitly model potential failure.

**Specification $\text{nat}_p$ (bounded natural numbers):**

This specification describes natural numbers that wrap around at some bound $p$ (like machine integers):

| $\text{nat}_p$ |
|----------------|
| $0 : \text{nat}_p$ |
| $\text{succ} : \text{nat}_p \rightarrow \text{nat}_p$ |
| $+ : \text{nat}_p \rightarrow \text{nat}_p \rightarrow \text{nat}_p$ |
| $* : \text{nat}_p \rightarrow \text{nat}_p \rightarrow \text{nat}_p$ |
| Variables: $n, m : \text{nat}_p$ |
| Axioms: |
| $0 + n = n$, $n + 0 = n$ |
| $m + \text{succ}(n) = \text{succ}(m + n)$ |
| $0 * n = 0$, $n * 0 = 0$ |
| $m * \text{succ}(n) = m + (m * n)$ |
| $\underbrace{\text{succ}(\ldots\text{succ}(0))}_{\text{less than } p \text{ times}} \neq 0$ |
| $\underbrace{\text{succ}(\ldots\text{succ}(0))}_{p \text{ times}} = 0$ |

The axioms define how addition and multiplication work recursively, and the last two axioms capture the bounded nature: applying $\text{succ}$ less than $p$ times never gives zero, but exactly $p$ times wraps around to zero.

**Specification $\text{string}_p$ (bounded strings):**

This specification describes strings with a maximum length $p$:

| $\text{string}_p$ |
|-------------------|
| uses $\text{char}$, $\text{nat}_p$ |
| `""` $: \text{string}_p$ |
| `"c"` $: \text{char} \rightarrow \text{string}_p$ |
| $\hat{\ } : \text{string}_p \rightarrow \text{string}_p \rightarrow \text{string}_p$ |
| $\cdot[\cdot] : \text{string}_p \rightarrow \text{nat}_p \rightarrow \text{char}$ |
| Variables: $s : \text{string}_p$, $c, c_1, \ldots, c_p : \text{char}$, $n : \text{nat}_p$ |
| Axioms: |
| `""` $\hat{\ } s = s$, $s \hat{\ }$ `""` $= s$ |
| $\underbrace{\text{``}c_1\text{''} \hat{\ } (\ldots \hat{\ } \text{``}c_p\text{''})}_{p \text{ times}} = \text{error}$ |
| $r \hat{\ } (s \hat{\ } t) = (r \hat{\ } s) \hat{\ } t$ |
| $(\text{``}c\text{''} \hat{\ } s)[0] = c$ |
| $(\text{``}c\text{''} \hat{\ } s)[\text{succ}(n)] = s[n]$ |
| `""`$[n] = \text{error}$ |

The axioms specify that concatenation is associative, that the empty string is an identity for concatenation, that exceeding the length limit produces an error, and that indexing works by stripping characters from the front.

### 5.5 Homomorphisms

When do two implementations of the same specification "behave the same"? The mathematical answer involves *homomorphisms* -- structure-preserving mappings between algebraic structures.

Homomorphisms are mappings between algebraic structures with the same signature that preserve operations. Intuitively, if you apply an operation and then map, you get the same result as mapping first and then applying the corresponding operation.

A *homomorphism* from algebraic structure $(A, \{f^A, g^A, \ldots\})$ to $(B, \{f^B, g^B, \ldots\})$ is a function $h : A \rightarrow B$ such that:
- $h(f^A(a_1, \ldots, a_{n_f})) = f^B(h(a_1), \ldots, h(a_{n_f}))$ for all $(a_1, \ldots, a_{n_f})$
- $h(g^A(a_1, \ldots, a_{n_g})) = g^B(h(a_1), \ldots, h(a_{n_g}))$ for all $(a_1, \ldots, a_{n_g})$
- and so on for all operations.

Two algebraic structures are *isomorphic* if there are homomorphisms $h_1 : A \rightarrow B$, $h_2 : B \rightarrow A$ from one to the other and back, that when composed in any order form identity: $\forall (b \in B) \ h_1(h_2(b)) = b$ and $\forall (a \in A) \ h_2(h_1(a)) = a$.

An algebraic specification whose all implementations without junk are isomorphic is called "*monomorphic*". This means the specification pins down the structure so precisely that there's essentially only one way to implement it (up to isomorphism).

We usually only add axioms that really matter to us to the specification, so that the implementations have room for optimization. For this reason, the resulting specifications will often not be monomorphic in the above sense -- and that's intentional! A non-monomorphic specification allows for multiple genuinely different implementations, which may have different performance characteristics.

### 5.6 Example: Maps

Now let us look at a practical example that will guide the rest of this chapter. A *map* (also called dictionary or associative array) associates keys with values. This is one of the most fundamental data structures in programming -- think of Python's dictionaries, Java's `HashMap`, or OCaml's `Map` module.

Here is an algebraic specification that captures the essential behavior of maps:

| $(\alpha, \beta) \ \text{map}$ |
|--------------------------------|
| uses $\text{bool}$, type parameters $\alpha, \beta$ |
| $\text{empty} : (\alpha, \beta) \ \text{map}$ |
| $\text{member} : \alpha \rightarrow (\alpha, \beta) \ \text{map} \rightarrow \text{bool}$ |
| $\text{add} : \alpha \rightarrow \beta \rightarrow (\alpha, \beta) \ \text{map} \rightarrow (\alpha, \beta) \ \text{map}$ |
| $\text{remove} : \alpha \rightarrow (\alpha, \beta) \ \text{map} \rightarrow (\alpha, \beta) \ \text{map}$ |
| $\text{find} : \alpha \rightarrow (\alpha, \beta) \ \text{map} \rightarrow \beta$ |
| Variables: $k, k_2 : \alpha$, $v, v_2 : \beta$, $m : (\alpha, \beta) \ \text{map}$ |
| Axioms: |
| $\text{member}(k, \text{add}(k, v, m)) = \text{true}$ |
| $\text{member}(k, \text{remove}(k, m)) = \text{false}$ |
| $\text{member}(k, \text{add}(k_2, v, m)) = \text{true} \wedge k \neq k_2 \Leftrightarrow \text{member}(k, m) = \text{true} \wedge k \neq k_2$ |
| $\text{member}(k, \text{remove}(k_2, m)) = \text{true} \wedge k \neq k_2 \Leftrightarrow \text{member}(k, m) = \text{true} \wedge k \neq k_2$ |
| $\text{find}(k, \text{add}(k, v, m)) = v$ |
| $\text{find}(k, \text{remove}(k, m)) = \text{error}$, $\text{find}(k, \text{empty}) = \text{error}$ |
| $\text{find}(k, \text{add}(k_2, v_2, m)) = v \wedge k \neq k_2 \Leftrightarrow \text{find}(k, m) = v \wedge k \neq k_2$ |
| $\text{find}(k, \text{remove}(k_2, m)) = v \wedge k \neq k_2 \Leftrightarrow \text{find}(k, m) = v \wedge k \neq k_2$ |
| $\text{remove}(k, \text{empty}) = \text{empty}$ |

The axioms capture the intuitive behavior: adding a key-value pair makes that key findable, removing a key makes it unfindable, and operations on different keys don't interfere with each other. Notice how the specification says nothing about *how* the map is implemented -- only about *what* behavior it must exhibit.

### 5.7 Modules and Interfaces (Signatures): Syntax

How do we express algebraic specifications in OCaml? The answer is the *module system*. In the ML family of languages, structures are given names by **module** bindings, and signatures are types of modules. From outside of a structure or signature, we refer to the values or types it provides with a dot notation: `Module.value`.

Module (and module type) names have to start with a capital letter (in ML languages). Since modules and module types have names, there is a convention to name the central type of a signature (the one that is "specified" by the signature), for brevity, `t`. Module types are often named with "all-caps" (all letters upper case).

Here is how we translate our map specification into an OCaml module signature:

```ocaml
module type MAP = sig
  type ('a, 'b) t
  val empty : ('a, 'b) t
  val member : 'a -> ('a, 'b) t -> bool
  val add : 'a -> 'b -> ('a, 'b) t -> ('a, 'b) t
  val remove : 'a -> ('a, 'b) t -> ('a, 'b) t
  val find : 'a -> ('a, 'b) t -> 'b
end

module ListMap : MAP = struct
  type ('a, 'b) t = ('a * 'b) list
  let empty = []
  let member = List.mem_assoc
  let add k v m = (k, v)::m
  let remove = List.remove_assoc
  let find = List.assoc
end
```

The `ListMap` module implements `MAP` using OCaml's built-in list functions for association lists. The type annotation `: MAP` after the module name tells OCaml to check that the implementation provides everything the signature requires, and hides any additional details.

### 5.8 Implementing Maps: Association Lists

Let us now build an implementation of maps from the ground up, exploring different approaches and their trade-offs. The most straightforward implementation... might not be what you expected:

```ocaml
module TrivialMap : MAP = struct
  type ('a, 'b) t =
    | Empty
    | Add of 'a * 'b * ('a, 'b) t
    | Remove of 'a * ('a, 'b) t

  let empty = Empty

  let rec member k m =
    match m with
    | Empty -> false
    | Add (k2, _, _) when k = k2 -> true
    | Remove (k2, _) when k = k2 -> false
    | Add (_, _, m2) -> member k m2
    | Remove (_, m2) -> member k m2

  let add k v m = Add (k, v, m)
  let remove k m = Remove (k, m)

  let rec find k m =
    match m with
    | Empty -> raise Not_found
    | Add (k2, v, _) when k = k2 -> v
    | Remove (k2, _) when k = k2 -> raise Not_found
    | Add (_, _, m2) -> find k m2
    | Remove (_, m2) -> find k m2
end
```

This "trivial" implementation is quite clever in its own way: it simply records all operations as a log! The data structure itself is a history of everything that has been done to it. The `add` and `remove` operations are $O(1)$ -- they just prepend a new node. However, `member` and `find` must traverse the entire history to determine the current state, giving them $O(n)$ complexity where $n$ is the number of operations performed.

This implementation illustrates an important point: there are many ways to satisfy the same specification, with very different performance characteristics.

Here is a more conventional implementation based on association lists, i.e., on lists of key-value pairs without the `Remove` constructor:

```ocaml
module MyListMap : MAP = struct
  type ('a, 'b) t = Empty | Add of 'a * 'b * ('a, 'b) t

  let empty = Empty

  let rec member k m =
    match m with
    | Empty -> false
    | Add (k2, _, _) when k = k2 -> true
    | Add (_, _, m2) -> member k m2

  let rec add k v m =
    match m with
    | Empty -> Add (k, v, Empty)
    | Add (k2, _, m) when k = k2 -> Add (k, v, m)
    | Add (k2, v2, m) -> Add (k2, v2, add k v m)

  let rec remove k m =
    match m with
    | Empty -> Empty
    | Add (k2, _, m) when k = k2 -> m
    | Add (k2, v, m) -> Add (k2, v, remove k m)

  let rec find k m =
    match m with
    | Empty -> raise Not_found
    | Add (k2, v, _) when k = k2 -> v
    | Add (_, _, m2) -> find k m2
end
```

This implementation maintains the invariant that each key appears at most once in the structure. The `add` function replaces an existing key's value rather than creating a duplicate, and `remove` actually removes the key-value pair. All operations are still $O(n)$ in the worst case, but the structure stays cleaner.

### 5.9 Implementing Maps: Binary Search Trees

Can we do better than linear time? Yes, by using a smarter data structure. Binary search trees are binary trees with elements stored at the interior nodes, such that elements to the left of a node are smaller than, and elements to the right bigger than, elements within a node. This ordering property is what makes them efficient.

For maps, we store key-value pairs as elements in binary search trees, and compare the elements by keys alone. The tree structure allows us to use "divide-and-conquer" to search for the value associated with a key.

On average, binary search trees are fast -- $O(\log n)$ complexity for all operations. At each node, we can eliminate half the remaining elements from consideration. However, in the worst case (when keys are inserted in sorted order), the tree degenerates into a linked list and operations become $O(n)$.

A note on our design: the simple polymorphic signature for maps is only possible because OCaml provides polymorphic comparison (and equality) operators that work on elements of most types (but not on functions). These operators may not behave as you expect for all types! Our signature for polymorphic maps is not the standard approach because of this limitation; it is just to keep things simple for pedagogical purposes.

```ocaml
module BTreeMap : MAP = struct
  type ('a, 'b) t = Empty | T of ('a, 'b) t * 'a * 'b * ('a, 'b) t

  let empty = Empty

  let rec member k m =              (* "Divide and conquer" search through the tree. *)
    match m with
    | Empty -> false
    | T (_, k2, _, _) when k = k2 -> true
    | T (m1, k2, _, _) when k < k2 -> member k m1
    | T (_, _, _, m2) -> member k m2

  let rec add k v m =               (* Searches the tree in the same way as member *)
    match m with                    (* but copies every node along the way. *)
    | Empty -> T (Empty, k, v, Empty)
    | T (m1, k2, _, m2) when k = k2 -> T (m1, k, v, m2)
    | T (m1, k2, v2, m2) when k < k2 -> T (add k v m1, k2, v2, m2)
    | T (m1, k2, v2, m2) -> T (m1, k2, v2, add k v m2)

  let rec split_rightmost m =       (* A helper function, it does not belong *)
    match m with                    (* to the "exported" signature. *)
    | Empty -> raise Not_found
    | T (Empty, k, v, Empty) -> k, v, Empty   (* We remove one element, *)
    | T (m1, k, v, m2) ->           (* the one that is on the bottom right. *)
        let rk, rv, rm = split_rightmost m2 in
        rk, rv, T (m1, k, v, rm)

  let rec remove k m =
    match m with
    | Empty -> Empty
    | T (m1, k2, _, Empty) when k = k2 -> m1
    | T (Empty, k2, _, m2) when k = k2 -> m2
    | T (m1, k2, _, m2) when k = k2 ->
        let rk, rv, rm = split_rightmost m1 in
        T (rm, rk, rv, m2)
    | T (m1, k2, v, m2) when k < k2 -> T (remove k m1, k2, v, m2)
    | T (m1, k2, v, m2) -> T (m1, k2, v, remove k m2)

  let rec find k m =
    match m with
    | Empty -> raise Not_found
    | T (_, k2, v, _) when k = k2 -> v
    | T (m1, k2, _, _) when k < k2 -> find k m1
    | T (_, _, _, m2) -> find k m2
end
```

The `member` and `find` functions use the "divide-and-conquer" strategy: compare the target key with the key at the current node, and recursively search in the appropriate subtree. The `add` function searches the tree in the same way but copies every node along the path to create the new tree (since we're using immutable data structures).

The `remove` function is trickier. When removing a node with two children, we need to replace it with another value that maintains the ordering property. The `split_rightmost` helper function finds and removes the rightmost (largest) element from a subtree -- this element is guaranteed to be smaller than everything in the right subtree and larger than everything remaining in the left subtree, making it the perfect replacement.

### 5.10 Implementing Maps: Red-Black Trees

The fatal weakness of ordinary binary search trees is that they can become unbalanced. If keys arrive in sorted order, each insertion adds a node at the bottom of a long chain, and we lose the logarithmic performance guarantee. How can we maintain balance automatically?

This section is based on Wikipedia's [Red-black tree article](http://en.wikipedia.org/wiki/Red-black_tree), Chris Okasaki's "Purely Functional Data Structures" and Matt Might's excellent blog post on [red-black tree deletion](http://matt.might.net/articles/red-black-delete/).

Binary search trees are good when we encounter keys in random order, because the cost of operations is limited by the depth of the tree which is small relative to the number of nodes... unless the tree grows unbalanced achieving large depth (which means there are sibling subtrees of vastly different sizes on some path).

To remedy this, we *rebalance* the tree while building it -- i.e., while adding elements. The key insight is to detect when the tree is becoming unbalanced and perform local rotations to restore balance.

In *red-black trees* we achieve balance by:
1. Remembering one of two colors (red or black) with each node
2. Keeping the same number of black nodes on every path from the root to a leaf
3. Not allowing a red node to have a red child

These invariants together guarantee that the tree cannot become too unbalanced: the depth is at most twice the depth of a perfectly balanced tree with the same number of nodes. Why? The "black height" (number of black nodes on any root-to-leaf path) is the same everywhere, and red nodes can only appear between black nodes, so the longest path can have at most twice as many nodes as the shortest.

#### B-trees of Order 4 (2-3-4 Trees)

To understand where red-black trees come from, it helps to first understand 2-3-4 trees (also known as B-trees of order 4).

How can we have perfectly balanced trees without worrying about having exactly $2^k - 1$ elements? The answer is to allow variable-width nodes. **2-3-4 trees** can store from 1 to 3 elements in each node and have 2 to 4 subtrees correspondingly. This flexibility lets us maintain perfect balance!

- A **2-node** contains one element and has two children
- A **3-node** contains two elements and has three children
- A **4-node** contains three elements and has four children

To insert into a 2-3-4 tree, we descend toward the appropriate leaf position. But if we encounter a full node (4-node) along the way, we "split" it: move the middle element up to the parent and split the remaining two elements into separate 2-nodes. This maintains perfect balance at all times -- all leaves are at the same depth.

The remarkable fact is that red-black trees are just a clever way to represent 2-3-4 trees as binary trees! To represent a 2-3-4 tree as a binary tree with one element per node, we color the "primary" element of each node black (the middle element of a 4-node, or the first element of a 2-/3-node) and make it the parent of its neighbor elements colored red. The red elements then become parents of the original subtrees. This correspondence provides the deep intuition behind red-black trees: the colors encode the structure of the underlying 2-3-4 tree.

#### Red-Black Trees, Without Deletion

Now let us implement red-black trees in OCaml. Red-black trees maintain two invariants:

**Invariant 1.** No red node has a red child. (No two consecutive red nodes on any path.)

**Invariant 2.** Every path from the root to an empty node contains the same number of black nodes. (The "black height" is uniform.)

For simplicity, we first implement red-black tree based *sets* (not maps) without deletion. The implementation proceeds almost exactly like for unbalanced binary search trees; we only need to add code to restore the invariants after each insertion.

The beautiful insight of Okasaki's approach is that by keeping balance at each step of constructing a node, it is enough to check *locally* (around the root of the subtree) whether a violation has occurred. We never need to examine the entire tree. For an understandable implementation of deletion, we need to introduce more colors -- see Matt Might's post for details.

```ocaml
type color = R | B
type 'a t = E | T of color * 'a t * 'a * 'a t

let empty = E

let rec member x m =                     (* Like in unbalanced binary search tree. *)
  match m with
  | E -> false
  | T (_, _, y, _) when x = y -> true
  | T (_, a, y, _) when x < y -> member x a
  | T (_, _, _, b) -> member x b

let balance = function                   (* Restoring the invariants. *)
  | B, T (R, T (R,a,x,b), y, c), z, d    (* On next figure: left, *)
  | B, T (R, a, x, T (R,b,y,c)), z, d    (* top, *)
  | B, a, x, T (R, T (R,b,y,c), z, d)    (* bottom, *)
  | B, a, x, T (R, b, y, T (R,c,z,d))    (* right, *)
      -> T (R, T (B,a,x,b), y, T (B,c,z,d))    (* center tree. *)
  | color, a, x, b -> T (color, a, x, b)   (* We allow red-red violation for now. *)

let insert x s =
  let rec ins = function                 (* Like in unbalanced binary search tree, *)
    | E -> T (R, E, x, E)                (* but fix violation above created node. *)
    | T (color, a, y, b) as s ->
        if x < y then balance (color, ins a, y, b)
        else if x > y then balance (color, a, y, ins b)
        else s
  in
  match ins s with                       (* We could still have red-red violation *)
  | T (_, a, y, b) -> T (B, a, y, b)     (* at root, fixed by coloring it black. *)
  | E -> failwith "insert: impossible"
```

The `balance` function is the heart of the algorithm. It handles four cases where a red-red violation occurs (a red node with a red child). The four cases correspond to different positions of the violation:

- A red left child with a red left grandchild
- A red left child with a red right grandchild
- A red right child with a red left grandchild
- A red right child with a red right grandchild

In each case, we perform a "rotation" that restructures the tree to eliminate the violation while maintaining the binary search tree property. Remarkably, all four cases produce the same balanced result: a red root with two black children, with the subtrees `a`, `b`, `c`, `d` properly distributed.

The `insert` function works like insertion into an ordinary binary search tree, but calls `balance` after each recursive step to fix any violations that may have been introduced. New nodes are always created red (which might create a red-red violation that `balance` will fix). At the very end, we color the root black -- this can never create a violation and ensures the root is always black.

### Exercises

**Exercise 1.** Derive the equations and solve them to find the type for:

```ocaml
let cadr l = List.hd (List.tl l) in cadr (1::2::[]), cadr (true::false::[])
```

in environment $\Gamma = \{ \text{List.hd} : \forall \alpha . \alpha \ \text{list} \rightarrow \alpha ; \text{List.tl} : \forall \alpha . \alpha \ \text{list} \rightarrow \alpha \ \text{list} \}$. You can take "shortcuts" if it is too many equations to write down.

**Exercise 2.** *Terms* $t_1, t_2, \ldots \in T(\Sigma, X)$ are built out of variables $x, y, \ldots \in X$ and function symbols $f, g, \ldots \in \Sigma$ the way you build values out of functions:

- $X \subset T(\Sigma, X)$ -- variables are terms; usually an infinite set,
- for terms $t_1, \ldots, t_n \in T(\Sigma, X)$ and a function symbol $f \in \Sigma_n$ of arity $n$, $f(t_1, \ldots, t_n) \in T(\Sigma, X)$ -- bigger terms arise from applying function symbols to smaller terms; $\Sigma = \dot{\cup}_n \Sigma_n$ is called a signature.

In OCaml, we can define terms as: `type term = V of string | T of string * term list`, where for example `V("x")` is a variable $x$ and `T("f", [V("x"); V("y")])` is the term $f(x, y)$.

By *substitutions* $\sigma, \rho, \ldots$ we mean finite sets of variable-term pairs which we can write as $\{x_1 \mapsto t_1, \ldots, x_k \mapsto t_k\}$ or $[x_1 := t_1; \ldots; x_k := t_k]$, but also functions from terms to terms $\sigma : T(\Sigma, X) \rightarrow T(\Sigma, X)$ related to the pairs as follows: if $\sigma = \{x_1 \mapsto t_1, \ldots, x_k \mapsto t_k\}$, then

- $\sigma(x_i) = t_i$ for $x_i \in \{x_1, \ldots, x_k\}$,
- $\sigma(x) = x$ for $x \in X \setminus \{x_1, \ldots, x_k\}$,
- $\sigma(f(t_1, \ldots, t_n)) = f(\sigma(t_1), \ldots, \sigma(t_n))$.

In OCaml, we can define substitutions $\sigma$ as: `type subst = (string * term) list`, together with a function `apply : subst -> term -> term` which computes $\sigma(\cdot)$.

We say that a substitution $\sigma$ is *more general* than all substitutions $\rho \circ \sigma$, where $(\rho \circ \sigma)(x) = \rho(\sigma(x))$. In type inference, we are interested in most general solutions.

A *unification problem* is a finite set of equations $S = \{s_1 =^? t_1, \ldots, s_n =^? t_n\}$. A solution, or *unifier* of $S$, is a substitution $\sigma$ such that $\sigma(s_i) = \sigma(t_i)$ for $i = 1, \ldots, n$. A *most general unifier*, or *MGU*, is a most general such substitution.

1. Implement an algorithm that, given a set of equations represented as a list of pairs of terms, computes an idempotent most general unifier of the equations.

2. (Ex. 4.22 in Franz Baader and Tobias Nipkow "Term Rewriting and All That", p. 82.) Modify the implementation of unification to achieve linear space complexity by working with what could be called iterated substitutions.

**Exercise 3.**

1. What does it mean that an implementation has junk (as an algebraic structure for a given signature)? Is it bad?
2. Define a monomorphic algebraic specification (other than, but similar to, $\text{nat}_p$ or $\text{string}_p$, some useful data type).
3. Discuss an example of a (monomorphic) algebraic specification where it would be useful to drop some axioms (giving up monomorphicity) to allow more efficient implementations.

**Exercise 4.**

1. Does the example `ListMap` meet the requirements of the algebraic specification for maps? Hint: here is the definition of `List.remove_assoc`; `compare a x` equals `0` if and only if `a = x`.

   ```ocaml
   let rec remove_assoc x = function
     | [] -> []
     | (a, b as pair) :: l ->
         if compare a x = 0 then l else pair :: remove_assoc x l
   ```

2. Trick question: what is the computational complexity of `ListMap` or `TrivialMap`?

3. (*) The implementation `MyListMap` is inefficient: it performs a lot of copying and is not tail-recursive. Optimize it (without changing the type definition).

4. Add (and specify) $\text{isEmpty} : (\alpha, \beta) \ \text{map} \rightarrow \text{bool}$ to the example algebraic specification of maps without increasing the burden on its implementations. Hint: equational reasoning might be not enough; consider an equivalence relation $\approx$ meaning "have the same keys".

**Exercise 5.** Design an algebraic specification and write a signature for first-in-first-out queues. Provide two implementations: one straightforward using a list, and another one using two lists: one for freshly added elements providing efficient queueing of new elements, and "reversed" one for efficient popping of old elements.

**Exercise 6.** Design an algebraic specification and write a signature for sets. Provide two implementations: one straightforward using a list, and another one using a map into the unit type.

**Exercise 7.**

1. (Ex. 2.2 in Chris Okasaki "Purely Functional Data Structures") In the worst case, `member` performs approximately $2d$ comparisons, where $d$ is the depth of the tree. Rewrite `member` to take no more than $d + 1$ comparisons by keeping track of a candidate element that *might* be equal to the query element (say, the last element for which $<$ returned false) and checking for equality only when you hit the bottom of the tree.

2. (Ex. 3.10 in Chris Okasaki "Purely Functional Data Structures") The `balance` function currently performs several unnecessary tests: when e.g. `ins` recurses on the left child, there are no violations on the right child.
   - Split `balance` into `lbalance` and `rbalance` that test for violations of left resp. right child only. Replace calls to `balance` appropriately.
   - One of the remaining tests on grandchildren is also unnecessary. Rewrite `ins` so that it never tests the color of nodes not on the search path.

**Exercise 8.** (*) Implement maps (i.e. write a module for the map signature) based on AVL trees. See `http://en.wikipedia.org/wiki/AVL_tree`.
