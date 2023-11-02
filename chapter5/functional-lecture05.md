# Lecture 5: Polymorphism & ADTs

Parametric types. Abstract Data Types.

Example: maps using red-black trees.

If you see any error on the slides, let me know!

## 1 Type Inference

We have seen the rules that govern the assignment of types to expressions, but 
how does OCaml guess what types to use, and when no correct types exist? It 
solves equations.

* Variables play two roles: of *unknowns* and of *parameters*.
  * Inside:

    ```ocaml
    # let f = List.hd;;
    val f : 'a list -> 'a
    ```

    `'a` is a parameter: it can become any type. Mathematically we write: $f : 
    \forall \alpha . \alpha \operatorname{list} \rightarrow \alpha$ – the 
    quantified type is called a *type scheme*.
  * Inside:

    ```ocaml
    # let x = ref [];;
    val x : 'a list ref
    ```

    `'_a` is an unknown. It stands for a particular type like float  or 
    (int -> int), OCaml just doesn't yet know the type.
  * OCaml only reports unknowns like `'_a` in inferred types for reasons not 
    relevant to functional programming. When unknowns appear in inferred type 
    against our expectations, *$\eta$-expansion* may help: writing let f x = 
    expr x instead of let f = expr – for example:

    ```ocaml
    # let f = List.append [];;
    val f : 'a list -> 'a list = <fun>
    # let f l = List.append [] l;;
    val f : 'a list -> 'a list = <fun>
    ```

* A *type environment* specifies what names (corresponding to parameters and 
  definitions) are available for an expression, because they were introduced 
  above it, and it specifies their types.
* Type inference solves equations over unknowns. “What has to hold so that 
  $e : \tau$ in type environment $\Gamma$?”
  * If, for example, $f : \forall \alpha . \alpha \operatorname{list} 
    \rightarrow \alpha \in \Gamma$, then for $f : \tau$ we introduce $\gamma 
    \operatorname{list} \rightarrow \gamma = \tau$ for some fresh unknown 
    $\gamma$.
  * For $e_{1} e_{2} : \tau$ we introduce $\beta = \tau$ and ask for 
    $e_{1} : \gamma \rightarrow \beta$ and $e_{2} : \gamma$, for some fresh 
    unknowns $\beta, \gamma$.
  * For $\operatorname{fun}x \rightarrow e : \tau$ we introduce $\beta 
    \rightarrow \gamma = \tau$ and ask for $e : \gamma$ in environment 
    $\lbrace x : \beta \rbrace \cup \Gamma$, for some fresh unknowns $\beta, 
    \gamma$.
  * Case $\operatorname{let}x = e_{1} \operatorname{in}e_{2} : \tau$ is 
    different. One approach is to *first* solve the equations that we get by 
    asking for $e_{1} : \beta$, for some fresh unknown $\beta$. Let's say a 
    solution $\beta = \tau_{\beta}$ has been found, $\alpha_{1} \ldots 
    \alpha_{n} \beta_{1} \ldots \beta_{m}$ are the remaining unknowns in 
    $\tau_{\beta}$,  and $\alpha_{1} \ldots \alpha_{n}$ are all that do 
    not appear in $\Gamma$. Then we ask for $e_{2} : \tau$ in environment 
    $\lbrace x : \forall \alpha_{1} \ldots \alpha_{n} . \tau_{\beta} 
    \rbrace \cup \Gamma$.
  * Remember that whenever we establish a solution $\beta = \tau_{\beta}$ to 
    an unknown $\beta$, it takes effect everywhere!
  * To find a type for $e$ (in environment $\Gamma$), we pick a fresh unknown 
    $\beta$ and ask for $e : \beta$ (in $\Gamma$).
* The “top-level” definitions for which the system infers types with variables 
  are called *polymorphic*, which informally means “working with different 
  shapes of data”.
  * This kind of polymorphism is called *parametric polymorphism*, since the 
    types have parameters. A different kind of polymorphism is provided by 
    object-oriented programming languages.

## 2 Parametric Types

* Polymorphic functions shine when used with polymorphic data types. In:

  type 'a mylist = Empty | Cons of 'a \* 'a mylist

  we define lists that can store elements of any type `'a`. Now:

  ```ocaml
  # let tail l =  match l with    | Empty -> invalidarg "tail"    | Cons 
  (, tl) -> tl;;      val tail : 'a mylist -> 'a mylist
  ```

  is a polymorphic function: works for lists with elements of any type.
* A *parametric type* like 'a mylist *is not* itself a data type but a family 
  of data types: bool mylist, int mylist etc. *are* different types.
  * We say that the type int mylist *instantiates* the parametric type 'a 
    mylist.
* In OCaml, the syntax is a bit confusing: type parameters precede type name. 
  For example:

  type ('a, 'b) choice = Left of 'a | Right of 'b

  has two parameters. Mathematically we would write $\operatorname{choice} 
  (\alpha, \beta)$.
  * Functions do not have to be polymorphic:

    ```ocaml
    # let getint c =  match c with
        | Left i -> i
        | Right b -> if b then 1 else 0;;
    val getint : (int, bool) choice -> int
    ```

* In F#, we provide parameters (when more than one) after type name:

  type choice<`'a,'`b> = Left of `'a` | `Right of` 'b
* In Haskell, we provide type parameters similarly to function arguments:

  data Choice a b = Left a | Right b

## 3 Type Inference, Formally

* A statement that an expression has a type in an environment is called 
  a *type judgement*. For environment $\Gamma = \lbrace x : \forall \alpha 
 _{1} \ldots \alpha_{n} . \tau_{x} ; \ldots \rbrace$, expression $e$ and 
  type $\tau$ we write

  \\[ \Gamma \vdash e : \tau \\]
* We will derive the equations in one go using $\llbracket \cdot \rrbracket$, 
  to be solved later. Besides equations we will need to manage introduced 
  variables, using existential quantification.
* For local definitions we require to remember what constraints should hold 
  when the definition is used. Therefore we extend *type schemes* in the 
  environment to: $\Gamma = \lbrace x : \forall \beta_{1} \ldots \beta_{m} 
  [\exists \alpha_{1} \ldots \alpha_{n} .D] . \tau_{x} ; \ldots \rbrace$ 
  where $D$ are equations – keeping the variables $\alpha_{1} \ldots \alpha 
 _{n}$ introduced while deriving $D$ in front.
  * A simpler form would be enough: $\Gamma = \lbrace x : \forall \beta 
    [\exists \alpha_{1} \ldots \alpha_{n} .D] . \beta ; \ldots \rbrace$



$$ \begin{matrix}
  \llbracket \Gamma \vdash x : \tau \rrbracket & = & \exists \overline{\beta'}
  \bar{\alpha}' . (D [\bar{\beta} \bar{\alpha} := \overline{\beta'}
  \bar{\alpha}'] \wedge \tau_{x} [\bar{\beta} \bar{\alpha} :=
  \overline{\beta'} \bar{\alpha}'] \dot{=} \tau)\\\\\\
  &  & \text{where } \Gamma (x) = \forall \bar{\beta} [\exists \bar{\alpha}
  .D] . \tau_{x}, \overline{\beta'} \bar{\alpha}' \#\operatorname{FV}
  (\Gamma, \tau)\\\\\\
  &  &  \\\\\\
  \llbracket \Gamma \vdash \boldsymbol{\operatorname{fun}} x
  {\texttt{->}} e : \tau \rrbracket & = & \exists 
\alpha
 _{1} \alpha_{2} . (\llbracket \Gamma \lbrace x : \alpha_{1} \rbrace
  \vdash e : \alpha_{2} \rrbracket \wedge \alpha_{1} \rightarrow \alpha
 _{2} \dot{=} \tau),\\\\\\
  &  & \text{where } \alpha_{1} \alpha_{2} \#\operatorname{FV} (\Gamma,
  \tau)\\\\\\
  &  &  \\\\\\
  \llbracket \Gamma \vdash e_{1} e_{2} : \tau \rrbracket & = & \exists
  \alpha . (\llbracket \Gamma \vdash e_{1} : \alpha \rightarrow \tau
  \rrbracket \wedge \llbracket \Gamma \vdash e_{2} : \alpha \rrbracket),
  \alpha \#\operatorname{FV} (\Gamma, \tau)\\\\\\
  &  &  \\\\\\
  \llbracket \Gamma \vdash K e_{1} \ldots e_{n} : \tau \rrbracket & = &
  \exists \bar{\alpha}' . (\wedge_{i} \llbracket \Gamma \vdash e_{i} : \tau
 _{i} [\bar{\alpha} := \bar{\alpha}'] \rrbracket \wedge \varepsilon
  (\bar{\alpha}') \dot{=} \tau),\\\\\\
  &  & \text{w. } K \,:\, \forall \bar{\alpha} . \tau_{1} \times \ldots
  \times \tau_{n} \rightarrow \varepsilon (\bar{\alpha}), \bar{\alpha}'
  \#\operatorname{FV} (\Gamma, \tau)\\\\\\
  &  &  \\\\\\
  \llbracket \Gamma \vdash e : \tau \rrbracket & = & (\exists \beta .C) \wedge
  \llbracket \Gamma \lbrace x : \forall \beta [C] . \beta \rbrace \vdash
  e_{2} : \tau \rrbracket\\\\\\
  e = \boldsymbol{\operatorname{let}} x = e_{1}
  \boldsymbol{\operatorname{in}} e_{2} &  & \text{where } C =
  \llbracket \Gamma \vdash e_{1} : \beta \rrbracket\\\\\\
  &  &  \\\\\\
  \llbracket \Gamma \vdash e : \tau \rrbracket & = & (\exists \beta .C) \wedge
  \llbracket \Gamma \lbrace x : \forall \beta [C] . \beta \rbrace \vdash
  e_{2} : \tau \rrbracket\\\\\\
  e = \boldsymbol{\operatorname{letrec}} x = e_{1}
  \boldsymbol{\operatorname{in}} e_{2} &  & \text{where } C =
  \llbracket \Gamma \lbrace x : \beta \rbrace \vdash e_{1} : \beta
  \rrbracket\\\\\\
  &  &  \\\\\\
  \llbracket \Gamma \vdash e : \tau \rrbracket & = & \exists \alpha_{v} .
  \llbracket \Gamma \vdash e_{v} : \alpha_{v} \rrbracket \wedge_{i}
  \llbracket \Gamma \vdash p_{i} .e_{i} : \alpha_{v} \rightarrow \tau
  \rrbracket,\\\\\\
  e = \boldsymbol{\operatorname{match}} e_{v}
  \boldsymbol{\operatorname{with}} \bar{c} &  & \alpha_{v}
  \#\operatorname{FV} (\Gamma, \tau)\\\\\\
  \bar{c} = p_{1} .e_{1} | \ldots |p_{n} .e_{n} &  &  \\\\\\
  &  &  \\\\\\
  \llbracket \Gamma, \Sigma \vdash p.e : \tau_{1} \rightarrow \tau_{2}
  \rrbracket & = & \llbracket \Sigma \vdash p \downarrow \tau_{1} \rrbracket
  \wedge \exists \bar{\beta} . \llbracket \Gamma \Gamma' \vdash e : \tau_{2}
  \rrbracket\\\\\\
  &  & \text{where } \exists \bar{\beta} \Gamma' \text{ is } \llbracket
  \Sigma \vdash p \uparrow \tau_{1} \rrbracket, \bar{\beta}
  \#\operatorname{FV} (\Gamma, \tau_{2})\\\\\\
  &  &  \\\\\\
  \llbracket \Sigma \vdash p \downarrow \tau_{1} \rrbracket &  &
  \text{derives constraints on type of matched value}\\\\\\
  &  &  \\\\\\
  \llbracket \Sigma \vdash p \uparrow \tau_{1} \rrbracket &  & \text{derives
  environment for pattern variables}
\end{matrix} $$

* By $\bar{\alpha}$ or $\overline{\alpha_{i}}$ we denote a sequence of some 
  length: $\alpha_{1} \ldots \alpha_{n}$
* By $\wedge_{i} \varphi_{i}$ we denote a conjunction of 
  $\overline{\varphi_{i}}$: $\varphi_{1} \ldots \varphi_{n}$.

### 3.1 Polymorphic Recursion

* Note the limited polymorphism of let rec f = … – we cannot use `f` 
  polymorphically in its definition.
  * In modern OCaml we can bypass the problem if we provide type of `f` 
    upfront: let rec f : 'a. 'a -> 'a list = …
  * where 'a. 'a -> 'a list stands for $\forall \alpha . \alpha 
    \rightarrow \alpha \operatorname{list}$.
* Using the recursively defined function with different types in its 
  definition is called polymorphic recursion.
* It is most useful together with irregular recursive datatypes where the 
  recursive use has different type arguments than the actual parameters.

#### 3.1.1 Polymorphic Rec: A list alternating between two types of elements

type ('x, 'o) alterning =| Stop| One of 'x \* ('o, 'x) alterninglet rec 
tolist :    'x 'o 'a. ('x->'a) -> ('o->'a) ->           ('x, 
'o) alterning -> 'a list =  fun x2a o2a ->    function    | 
Stop -> []    | One (x, rest) -> x2a x::tolist o2a x2a restlet 
tochoicelist alt =  tolist (fun x->Left x) (fun o->Right o) altlet it 
= tochoicelist  (One (1, One ("o", One (2, One ("oo", Stop)))))

#### 3.1.2 Polymorphic Rec: Data-Structural Bootstrapping

type 'a seq = Nil | Zero of ('a \* 'a) seq | One of 'a \* ('a \* 'a) seqWe store a list of elements in exponentially increasing chunks.let example =  One (0, One ((1,2), Zero (One ((((3,4),(5,6)), ((7,8),(9,10))), Nil))))let rec cons : 'a. 'a -> 'a seq -> 'a seq =  fun x -> functionAppending an element to the datastructure is like  | Nil -> One (x, Nil)adding one to a binary number: 1+0=1  | Zero ps -> One (x, ps)1+…0=…1  | One (y, ps) -> Zero (cons (x,y) ps)1+…1=[…+1]0let rec lookup : 'a. int -> 'a seq -> 'a =  fun i s -> match i, s withRather than returning `None : 'a option`  | , Nil -> raise Notfoundwe raise exception, for convenience.  | 0, One (x, ) -> x  | i, One (, ps) -> lookup (i-1) (Zero ps)  | i, Zero ps ->Random-Access lookup works    let x, y = lookup (i / 2) ps inin logarithmic time -- much faster than    if i mod 2 = 0 then x else yin standard lists.

## 4 Algebraic Specification

* The way we introduce a data structure, like complex numbers or strings, in 
  mathematics, is by specifying an *algebraic structure*.
* Algebraic structures consist of a set (or several sets, for 
  so-called *multisorted* algebras) and a bunch of functions (aka. operations) 
  over this set (or sets).
* A *signature* is a rough description of an algebraic structure: it provides 
  sorts – names for the sets (in multisorted case) and names of the 
  functions-operations together with their arity (and what sorts of arguments 
  they take).
* We select a class of algebraic structures by providing axioms that have to 
  hold. We will call such classes *algebraic specifications*.
  * In mathematics, a rusty name for some algebraic specifications is 
    a *variety*, a more modern and name is *algebraic category*.
* Algebraic structures correspond to “implementations” and signatures to 
  “interfaces” in programming languages.
* We will say that an algebraic structure implements an algebraic 
  specification when all axioms of the specification hold in the structure.
* All algebraic specifications are implemented by multiple structures!
* We say that an algebraic structure does not have junk, when all its elements 
  (i.e. elements in the sets corresponding to sorts) can be built using 
  operations in its signature.
* We allow parametric types as sorts. In that case, strictly speaking, we 
  define a family of algebraic specifications (a different specification for 
  each instantiation of the parametric type).

### 4.1 Algebraic specifications: examples

* An algebraic specification can also use an earlier specification.
* In “impure” languages like OCaml and F# we allow that the result of any 
  operation be an $\operatorname{error}$. In Haskell we could use `Maybe`.

<table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr></tbody>
</table>  <table style="display: inline-table; vertical-align: 
middle">
  <tbody><tr>
    <td></td>
  </tr><tr>
    <td>uses , </td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr></tbody>
</table>

## 5 Homomorphisms

* Mappings between algebraic structures with the same signature preserving 
  operations.
* A *homomorphism* from algebraic structure $(A, \lbrace f^A, g^A, \ldots 
  \rbrace)$ to $(B, \lbrace f^B, g^B, \ldots \rbrace)$ is a function $h : A 
  \rightarrow B$ such that $h (f^A (a_{1}, \ldots, a_{n_{f}})) = f^B (h 
  (a_{1}), \ldots, h (a_{n_{f}}))$ for all $(a_{1}, \ldots, a_{n_{f}})$, 
  $h (g^A (a_{1}, \ldots, a_{n_{g}})) = g^B (h (a_{1}), \ldots, h 
  (a_{n_{g}}))$ for all $(a_{1}, \ldots, a_{n_{g}})$, …
* Two algebraic structures are *isomorphic* if there are homomorphisms 
  $h_{1} : A \rightarrow B, h_{2} : B \rightarrow A$ from one to the other 
  and back, that when composed in any order form identity: $\forall (b \in B) 
  h_{1} (h_{2} (b)) = b$, $\forall (a \in A) h_{2} (h_{1} (a)) = a$.
* An algebraic specification whose all implementations without junk are 
  isomorphic is called “*monomorphic*”.
  * We usually only add axioms that really matter to us to the specification, 
    so that the implementations have room for optimization. For this reason, 
    the resulting specifications will often not be monomorphic in the above 
    sense.

## 6 Example: Maps

<table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td>, or </td>
  </tr><tr>
    <td>uses , type parameters </td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td>, , </td>
  </tr><tr>
    <td></td>
  </tr></tbody>
</table>

## 7 Modules and interfaces (signatures): syntax

* In the ML family of languages, structures are given names by **module** 
  bindings, and signatures are types of modules.
* From outside of a structure or signature, we refer to the values or types it 
  provides with a dot notation: `Module.value`.
* Module (and module type) names have to start with a capital letter (in ML 
  languages).
* Since modules and module types have names, there is a tradition to name the 
  central type of a signature (the one that is “specified” by the signature), 
  for brevity, `t`.
* Module types are often named with “all-caps” (all letters upper case).



module type MAP = sig  type ('a, 'b) t  val empty : ('a, 'b) t  val member : 
'a -> ('a, 'b) t -> bool  val add : 'a -> 'b -> ('a, 'b) 
t -> ('a, 'b) t  val remove : 'a -> ('a, 'b) t -> ('a, 'b) t  val 
find : 'a -> ('a, 'b) t -> 'bendmodule ListMap : MAP = struct  type 
('a, 'b) t = ('a \* 'b) list  let empty = []  let member = List.memassoc  let 
add k v m = (k, v)::m  let remove = List.removeassoc  let find = List.assocend

## 8 Implementing maps: Association lists

Let's now build an implementation of maps from the ground up. The most 
straightforward implementation… might not be what you expected:

```ocaml
module TrivialMap : MAP = struct  type ('a, 'b) t =    | Empty    | Add of 'a 
\* 'b \* ('a, 'b) t    | Remove of 'a \* ('a, 'b) t          let empty = Empty 
 let rec member k m =    match m with      | Empty -> false      | Add 
(k2, , ) when k = k2 -> true      | Remove (k2, ) when k = k2 -> false 
     | Add (, , m2) -> member k m2      | Remove (, m2) -> member k m2 
 let add k v m = Add (k, v, m)  let remove k m = Remove (k, m)  let rec find k 
m =    match m with      | Empty -> raise Not_found      | Add (k2, v, ) 
when k = k2 -> v      | Remove (k2, ) when k = k2 -> raise Notfound    
  | Add (, , m2) -> find k m2      | Remove (, m2) -> find k m2 end
```

Here is an implementation based on association lists, i.e. on lists of 
key-value pairs.

```ocaml
module MyListMap : MAP = struct  type ('a, 'b) t = Empty | Add of 'a \* 'b \* 
('a, 'b) t  let empty = Empty  let rec member k m =    match m with      | 
Empty -> false      | Add (k2, , ) when k = k2 -> true      | Add (, , 
m2) -> member k m2  let rec add k v m =    match m with      | 
Empty -> Add (k, v, Empty)      | Add (k2, , m) when k = k2 -> Add (k, 
v, m)      | Add (k2, v2, m) -> Add (k2, v2, add k v m)

  let rec remove k m =    match m with      | Empty -> Empty      | Add 
(k2, , m) when k = k2 -> m      | Add (k2, v, m) -> Add (k2, v, remove 
k m)  let rec find k m =    match m with      | Empty -> raise Error      
| Add (k2, v, ) when k = k2 -> v      | Add (, , m2) -> find k m2 end
```

## 9 Implementing maps: Binary search trees

* Binary search trees are binary trees with elements stored at the interior 
  nodes, such that elements to the left of a node are smaller than, and 
  elements to the right bigger than, elements within a node.
* For maps, we store key-value pairs as elements in binary search trees, and 
  compare the elements by keys alone.
* On average, binary search trees are fast because they use 
  “divide-and-conquer” to search for the value associated with a key. ($O 
  (\log n)$ compl.)
  * In worst case they reduce to association lists.
* The simple polymorphic signature for maps is only possible with 
  implementations based on some total order of keys because OCaml has 
  polymorphic comparison (and equality) operators.
  * These operators work on elements of most types, but not on functions. They 
    may not work in a way you would want though!
  * Our signature for polymorphic maps is not the standard approach because of 
    the problem of needing the order of keys; it is just to keep things 
    simple.

```ocaml
module BTreeMap : MAP = struct  type ('a, 'b) t = Empty | T of ('a, 'b) t \* 
'a \* 'b \* ('a, 'b) t  let empty = Empty  let rec member k m =‘‘Divide and 
conquer'' search through the tree.    match m with      | Empty -> false   
   | T (, k2, , ) when k = k2 -> true      | T (m1, k2, , ) when k < 
k2 -> member k m1      | T (, , , m2) -> member k m2  let rec add k v 
m =Searches the tree in the same way as `member`    match m withbut copies 
every node along the way.      | Empty -> T (Empty, k, v, Empty)      | T 
(m1, k2, , m2) when k = k2 -> T (m1, k, v, m2)      | T (m1, k2, v2, m2) 
when k < k2 -> T (add k v m1, k2, v2, m2)      | T (m1, k2, v2, 
m2) -> T (m1, k2, v2, add k v m2)

let rec splitrightmost m = (* A helper 
function, it does not belong *)
   match m with (* to the ‘‘exported'' signature.     *)
 | Empty -> raise Notfound      | T (Empty, k, v, Empty) -> k, v, 
EmptyWe remove one element,      | T (m1, k, v, m2) ->the one that is on 
the bottom right.        let rk, rv, rm = splitrightmost m2 in        rk, rv, 
T (m1, k, v, rm)

  let rec remove k m =    match m with      | Empty -> Empty      | T (m1, 
k2, , Empty) when k = k2 -> m1      | T (Empty, k2, , m2) when k = 
k2 -> m2      | T (m1, k2, , m2) when k = k2 ->        let rk, rv, rm 
= splitrightmost m1 in        T (rm, rk, rv, m2)      | T (m1, k2, v, m2) when 
k < k2 -> T (remove k m1, k2, v, m2)      | T (m1, k2, v, m2) -> 
T (m1, k2, v, remove k m2)  let rec find k m =    match m with      | 
Empty -> raise Notfound      | T (, k2, v, ) when k = k2 -> v      | T 
(m1, k2, , ) when k < k2 -> find k m1      | T (, , , m2) -> find 
k m2 end
```

## 10 Implementing maps: red-black trees

Based on Wikipedia 
[http://en.wikipedia.org/wiki/Red-black\_tree](http://en.wikipedia.org/wiki/Red-black_tree), 
Chris Okasaki's “Functional Data Structures” and Matt Might's excellent blog 
post 
[http://matt.might.net/articles/red-black-delete/](http://matt.might.net/articles/red-black-delete/).

* Binary search trees are good when we encounter keys in random order, because 
  the cost of operations is limited by the depth of the tree which is small 
  relatively to the number of nodes…
* …unless the tree grows unbalanced achieving large depth (which means 
  there are sibling subtrees of vastly different sizes on some path).
* To remedy it, we rebalance the tree while building it – i.e. while adding 
  elements.
* In *red-black trees* we achieve balance by remembering one of two colors 
  with each node, keeping the same length of each root-leaf path if only black 
  nodes are counted, and not allowing a red node to have a red child.
  * This way the depth is at most twice the depth of a perfectly balanced tree 
    with the same number of nodes.

### 10.1 B-trees of order 4 (2-3-4 trees)

How can we have perfectly balanced trees without worrying about having $2^k - 
1$ elements? **2-3-4 trees** can store from 1 to 3 elements in each node and 
have 2 to 4 subtrees correspondingly. Lots of freedom!



To insert “25” into (“.” stand for leaves, ignored later)



we descend right, but it is a full node, so we move the middle up and split 
the remaining elements:



Now there is a place between 24 and 29: next to 29





To represent 2-3-4 tree as a binary tree with one element per node, we color 
the middle element of a 4-node, or the first element of 2-/3-node, black and 
make it the parent of its neighbor elements, and make them parents of the 
original subtrees. Turning this:

Red-black\_tree\_B-tree.png

into this Red-Black tree:

Red-black\_tree\_example.png

### 10.2 Red-Black trees, without deletion

* **Invariant 1.** No red node has a red child.
* **Invariant 2**. Every path from the root to an empty node contains the same 
  number of black nodes.
* First we implement Red-Black tree based sets without deletion.
* The implementation proceeds almost exactly like for unbalanced binary search 
  trees, we only need to restore invariants.
* By keeping balance at each step of constructing a node, it is enough to 
  check locally (around the root of the subtree).
* For understandable implementation of deletion, we need to introduce more 
  colors. See Matt Might's post edited in a separate file.

```ocaml
type color = R | Btype 'a t = E | T of color \* 'a t \* 'a \* 'a tlet empty = 
Elet rec member x m =  match m withLike in unbalanced binary search tree.  | 
Empty -> false  | T (, , y, ) when x = y -> true  | T (, a, y, ) when 
x < y -> member x a  | T (, , , b) -> member x blet balance = 
functionRestoring the invariants.  | B,T (R,T (R,a,x,b),y,c),z,dOn next 
figure: left,  | B,T (R,a,x,T (R,b,y,c)),z,dtop,  | B,a,x,T (R,T 
(R,b,y,c),z,d)bottom,  | B,a,x,T (R,b,y,T (R,c,z,d))right,    -> T (R,T 
(B,a,x,b),y,T (B,c,z,d))center tree.  | color,a,x,b -> T (color,a,x,b)We 
allow red-red violation for now.

let insert x s =  let rec ins = functionLike in unbalanced binary search tree, 
   | E -> T (R,E,x,E)but fix violation above created node.    | T 
(color,a,y,b) as s ->      if x<y then balance (color,ins a,y,b)      
else if x>y then balance (color,a,y,ins b)      else s in
  match ins s with (* We could still have red-red violation at root, *)
  | T (,a,y,b) -> T (B,a,y,b) (* fixed by coloring it black. *)
  | E -> failwith "insert: impossible"
```




## 11 Homework

1. Derive the equations and solve them to find the type for:

   let cadr l = List.hd (List.tl l) in cadr (1::2::[]), cadr (true::false::[])

   in environ. $\Gamma = \left\lbrace 
   \text{{\textcolor{green}{List}}{\textcolor{blue}{.}}{\textcolor{brown}{hd}}} : \forall \alpha . \alpha 
   \operatorname{list} \rightarrow \alpha ; 
   \text{{\textcolor{green}{List}}{\textcolor{blue}{.}}{\textcolor{brown}{tl}}} : \forall \alpha . \alpha 
   \operatorname{list} \rightarrow \alpha \operatorname{list} \right\rbrace$. 
   You can take “shortcuts” if it is too many equations to write down.
1. What does it mean that an implementation has junk (as an algebraic 
   structure for a given signature)? Is it bad?
1. Define a monomorphic algebraic specification (other than, but similar to, 
   $\operatorname{nat}_{p}$ or $\operatorname{string}_{p}$, some useful data 
   type).
1. Discuss an example of a (monomorphic) algebraic specification where it 
   would be useful to drop some axioms (giving up monomorphicity) to allow 
   more efficient implementations.
1. Does the example ListMap meet the requirements of the algebraic 
   specification for maps? Hint: here is the definition of List.removeassoc; 
   `compare a x` equals 0 if and only if `a` = `x`.

   ```ocaml
   let rec removeassoc x = function  | [] -> []  | (a, b as pair) :: l ->
         if compare a x = 0 then l else pair :: removeassoc x l
   ```

1. Trick question: what is the computational complexity of ListMap or 
   TrivialMap?
1. \* The implementation MyListMap is inefficient: it performs a lot of 
   copying and is not tail-recursive. Optimize it (without changing the type 
   definition).
1. Add (and specify) $\operatorname{isEmpty}: (\alpha, \beta) 
   \operatorname{map} \rightarrow \operatorname{bool}$ to the example 
   algebraic specification of maps without increasing the burden on its 
   implementations (i.e. without affecting implementations of other 
   operations). Hint: equational reasoning might be not enough; consider an 
   equivalence relation $\approx$ meaning “have the same keys”, defined and 
   used just in the axioms of the specification.
1. Design an algebraic specification and write a signature for 
   first-in-first-out queues. Provide two implementations: one straightforward 
   using a list, and another one using two lists: one for freshly added 
   elements providing efficient queueing of new elements, and “reversed” one 
   for efficient popping of old elements.
1. Design an algebraic specification and write a signature for sets. Provide 
   two implementations: one straightforward using a list, and another one 
   using a map into the unit type.
1. (Ex. 2.2 in Chris Okasaki “Purely Functional Data Structures”) In the worst 
   case, `member` performs approximately $2 d$ comparisons, where $d$ is the 
   depth of the tree. Rewrite `member` to take no mare than $d + 1$ 
   comparisons by keeping track of a candidate element that *might* be equal 
   to the query element (say, the last element for which $<$ returned 
   false) and checking for equality only when you hit the bottom of the tree.
1. (Ex. 3.10 in Chris Okasaki “Purely Functional Data Structures”) The 
   `balance` function currently performs several unnecessary tests: when e.g. 
   `ins` recurses on the left child, there are no violations on the right 
   child.
   1. Split `balance` into `lbalance` and `rbalance` that test for violations 
      of left resp. right child only. Replace calls to `balance` 
      appropriately.
   1. One of the remaining tests on grandchildren is also unnecessary. Rewrite 
      `ins` so that it never tests the color of nodes not on the search path.
1. \* Implement maps (i.e. write a module for the map signature) based on AVL 
   trees. See `http://en.wikipedia.org/wiki/AVL_tree`.
