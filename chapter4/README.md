## Chapter 4: Functions

*Programming in untyped lambda-calculus*

This chapter explores the theoretical foundations of functional programming through the untyped lambda-calculus. We begin with a review of computation by hand using our reduction semantics, then introduce the lambda-calculus notation and show how to encode fundamental data types---booleans, pairs, and natural numbers---using only functions. The chapter concludes with an examination of recursion through fixpoint combinators and practical considerations for avoiding infinite loops in eager evaluation.

**References:**

- "Introduction to Lambda Calculus" by Henk Barendregt and Erik Barendsen
- "Lecture Notes on the Lambda Calculus" by Peter Selinger

### 4.1 Review: Computation by Hand

Before diving into the lambda-calculus, let us work through a complete example of evaluation using the reduction rules from Chapter 3. This exercise reinforces our understanding of how computation proceeds and prepares us for the more abstract setting of lambda-calculus.

Recall that we use `fix` instead of `let rec` to simplify rules for recursion. Also remember our syntactic conventions: `fun x y -> e` stands for `fun x -> (fun y -> e)`, and so forth.

Consider the following recursive `length` function applied to a two-element list:

```
let rec fix f x = f (fix f) x

type int_list = Nil | Cons of int * int_list

let length =
  fix (fun f l ->
    match l with
      | Nil -> 0
      | Cons (x, xs) -> 1 + f xs)

length (Cons (1, (Cons (2, Nil))))
```

Let us trace through this computation step by step. First, we eliminate the `let` binding:

$$\texttt{let } x = v \texttt{ in } a \Downarrow a[x := v]$$

This gives us:

```
fix (fun f l ->
    match l with
      | Nil -> 0
      | Cons (x, xs) -> 1 + f xs) (Cons (1, (Cons (2, Nil))))
```

Next, we apply the `fix` rule:

$$\texttt{fix}^2 \; v_1 \; v_2 \Downarrow v_1 \; (\texttt{fix}^2 \; v_1) \; v_2$$

This unfolds to:

```
(fun f l ->
    match l with
      | Nil -> 0
      | Cons (x, xs) -> 1 + f xs)
    (fix (fun f l ->
      match l with
        | Nil -> 0
        | Cons (x, xs) -> 1 + f xs))
    (Cons (1, (Cons (2, Nil))))
```

Function application reduces according to:

$$(\texttt{fun } x \texttt{ -> } a) \; v \rightsquigarrow a[x := v]$$

After substituting both `f` and `l`, we get:

```
(match Cons (1, (Cons (2, Nil))) with
    | Nil -> 0
    | Cons (x, xs) -> 1 + (fix (fun f l ->
      match l with
        | Nil -> 0
        | Cons (x, xs) -> 1 + f xs)) xs)
```

Pattern matching against a non-matching constructor moves to the next branch:

$$
\begin{aligned}
& \texttt{match } C_1^n(v_1, \ldots, v_n) \texttt{ with} \\
& C_2^n(p_1, \ldots, p_k) \texttt{ -> } a \texttt{ | } pm \Downarrow \texttt{match } C_1^n(v_1, \ldots, v_n) \texttt{ with } pm
\end{aligned}
$$

Pattern matching against a matching constructor performs substitution:

$$
\begin{aligned}
& \texttt{match } C_1^n(v_1, \ldots, v_n) \texttt{ with} \\
& C_1^n(x_1, \ldots, x_n) \texttt{ -> } a \texttt{ | } \ldots \Downarrow a[x_1 := v_1; \ldots; x_n := v_n]
\end{aligned}
$$

After matching and substitution:

```
1 + (fix (fun f l ->
      match l with
        | Nil -> 0
        | Cons (x, xs) -> 1 + f xs)) (Cons (2, Nil))
```

Continuing the evaluation, we apply `fix` again and work through the pattern match for `Cons (2, Nil)`, eventually reaching:

```
1 + (1 + (fix (fun f l ->
             match l with
               | Nil -> 0
               | Cons (x, xs) -> 1 + f xs)) Nil)
```

One more unfolding and pattern match against `Nil` gives:

```
1 + (1 + 0)
```

Finally, applying the built-in addition:

$$f^n \; v_1 \; \ldots \; v_n \Downarrow f(v_1, \ldots, v_n)$$

We obtain the result: `2`.

### 4.2 Language and Rules of the Untyped Lambda-Calculus

The lambda-calculus, introduced by Alonzo Church in the 1930s, is a minimal formal system for expressing computation. To work with it, we first simplify our language:

1. **Forget about types.** In pure lambda-calculus, there is no type system constraining which terms can be combined.

2. **Introduce notation.** We write $\lambda x.a$ for `fun x -> a`, and $\lambda xy.a$ for `fun x y -> a`, and so forth.

3. **Reduce to essentials.** We keep only functions (lambda abstractions) and variables---no constructors, no built-in primitives.

The core reduction rule of lambda-calculus is called **$\beta$-reduction**:

$$(\texttt{fun } x \texttt{ -> } a_1) \; a_2 \rightsquigarrow a_1[x := a_2]$$

Note that this rule is more general than the one we use for OCaml evaluation. In our OCaml semantics, we require the argument to be a value: $(\texttt{fun } x \texttt{ -> } a) \; v \rightsquigarrow a[x := v]$. The general $\beta$-reduction rule allows substituting any expression, not just values.

Lambda-calculus also uses **$\alpha$-conversion** (bound variable renaming), or equivalent techniques, to avoid **variable capture**---the unintended binding of free variables during substitution. We will explore $\beta$-reduction further in the chapter on laziness.

Why is $\beta$-reduction more general than our evaluation rule? Consider the expression $(\lambda x. x) \; ((\lambda y. y) \; z)$. With $\beta$-reduction, we could reduce the outer application first, obtaining $((\lambda y. y) \; z)$. Our evaluation rule would require first reducing the argument to a value.

### 4.3 Booleans

Alonzo Church introduced lambda-calculus to encode logic. There are multiple ways to encode various sorts of data in lambda-calculus, though not all of them work well in a typed setting---the straightforward encode/decode functions may not type-check.

The **Church encoding** of booleans represents truth values as selector functions:

- **True** selects the first argument: `c_true` $= \lambda xy.x$
- **False** selects the second argument: `c_false` $= \lambda xy.y$

In OCaml syntax:

```ocaml
let c_true = fun x y -> x   (* "True" is projection on the first argument *)
let c_false = fun x y -> y  (* And "false" on the second argument *)
```

Logical conjunction can be defined as:

$$\texttt{c\_and} = \lambda xy. x \; y \; \texttt{c\_false}$$

The logic is: if `x` is true, return `y` (so the result is true only if both are true); if `x` is false, return false immediately.

```ocaml
let c_and = fun x y -> x y c_false  (* If one is false, then return false *)
```

Let us verify this works. For `c_and c_true c_true`:

$$(\lambda xy. x \; y \; \texttt{c\_false}) \; (\lambda xy.x) \; (\lambda xy.x)$$

reduces to:

$$(\lambda xy.x) \; (\lambda xy.x) \; \texttt{c\_false}$$

which gives us $\lambda xy.x$ = `c_true`. For any other combination involving `c_false`, the result is `c_false`.

To verify our encodings in OCaml, we need encode and decode functions:

```ocaml
let encode_bool b = if b then c_true else c_false
let decode_bool c = c true false  (* Test the functions in the toplevel *)
```

**Exercise:** Define `c_or` and `c_not` yourself!

### 4.4 If-then-else and Pairs

From now on, we will use OCaml syntax for our lambda-calculus programs. An important observation is that our encoded booleans already implement conditional selection:

```ocaml
let if_then_else = fun b -> b  (* Booleans select the argument! *)
```

Since `c_true` returns its first argument and `c_false` returns its second, `if_then_else b then_branch else_branch` simply applies `b` to the two branches. Remember to play with these functions in the toplevel to build intuition.

#### Pairs

Pairs (ordered tuples of two elements) can be encoded similarly:

```ocaml
let c_pair m n = fun x -> x m n  (* We couple things *)
let c_first = fun p -> p c_true  (* by passing them together *)
let c_second = fun p -> p c_false  (* Check that it works! *)
```

A pair is a function that, when given a selector, applies that selector to both components. To extract the first component, we pass `c_true` (which selects the first argument); to extract the second, we pass `c_false`.

For verification:

```ocaml
let encode_pair enc_fst enc_snd (a, b) =
  c_pair (enc_fst a) (enc_snd b)
let decode_pair de_fst de_snd c = c (fun x y -> de_fst x, de_snd y)
let decode_bool_pair c = decode_pair decode_bool decode_bool c
```

We can define larger tuples in the same manner:

```ocaml
let c_triple l m n = fun x -> x l m n
```

### 4.5 Pair-Encoded Natural Numbers

Our first encoding of natural numbers uses nested pairs. The representation is based on the depth of nested pairs whose rightmost leaf is the identity function $\lambda x.x$ and whose left elements are `c_false`.

```ocaml
let pn0 = fun x -> x           (* Start with the identity function *)
let pn_succ n = c_pair c_false n  (* Stack another pair *)

let pn_pred = fun x -> x c_false  (* Extract the nested number *)
let pn_is_zero = fun x -> x c_true  (* Check if it's the base case *)
```

The number 0 is represented as the identity function. The number 1 is `c_pair c_false pn0`, the number 2 is `c_pair c_false (c_pair c_false pn0)`, and so on. The `pn_is_zero` function works because:
- For `pn0`, applying it to `c_true` gives `c_true` (since `pn0` is the identity).
- For any successor, applying `c_pair c_false n` to `c_true` applies the pair to `c_true`, which selects `c_false`.

We program in untyped lambda-calculus as an exercise, and we need encoding/decoding to verify our exercises. Using `Obj.magic` to bypass the type system for encoding/decoding is "fair game":

```ocaml
let rec encode_pnat n =                (* We use Obj.magic to forget types *)
  if n <= 0 then Obj.magic pn0
  else pn_succ (Obj.magic (encode_pnat (n-1)))  (* Disregarding types, *)
let rec decode_pnat pn =               (* these functions are straightforward! *)
  if decode_bool (pn_is_zero pn) then 0
  else 1 + decode_pnat (pn_pred (Obj.magic pn))
```

### 4.6 Church Numerals

Do you remember our function `power f n` from Chapter 3? We will use a similar idea for a different representation of numbers. **Church numerals** represent a natural number $n$ as a function that applies its first argument $n$ times to its second argument:

```ocaml
let cn0 = fun f x -> x        (* The same as c_false *)
let cn1 = fun f x -> f x      (* Behaves like identity when f = id *)
let cn2 = fun f x -> f (f x)
let cn3 = fun f x -> f (f (f x))
```

This is the original Alonzo Church encoding. The number $n$ is represented as $\lambda fx. f^n(x)$, where $f^n$ denotes $n$-fold composition.

The successor function adds one more application of `f`:

```ocaml
let cn_succ = fun n f x -> f (n f x)
```

**Exercise:** Define addition, multiplication, comparing to zero, and the predecessor function "-1" for Church numerals.

It turns out even Alonzo Church could not define predecessor right away! His student Stephen Kleene eventually found it. Try to make some progress before looking at the solution below.

```ocaml
let (-|) f g x = f (g x)  (* Backward composition operator *)

let rec encode_cnat n f =
  if n <= 0 then (fun x -> x) else f -| encode_cnat (n-1) f
let decode_cnat n = n ((+) 1) 0
let cn7 f x = encode_cnat 7 f x   (* We need to eta-expand these definitions *)
let cn13 f x = encode_cnat 13 f x  (* for type-system reasons *)
                                   (* (because OCaml allows side-effects) *)
let cn_add = fun n m f x -> n f (m f x)  (* Put n of f in front *)
let cn_mult = fun n m f -> n (m f)       (* Repeat n times *)
                                          (* putting m of f in front *)
let cn_prev n =
  fun f x ->                  (* This is the "Church numeral signature" *)
    n                         (* The only thing we have is an n-step loop *)
      (fun g v -> v (g f))    (* We need sth that operates on f *)
      (fun z -> x)            (* We need to ignore the innermost step *)
      (fun z -> z)            (* We've built a "machine" not results -- start the machine *)
```

The predecessor function is ingenious. It builds up a chain of functions that, when "started" with the identity, yields $n-1$ applications of `f`. The key insight is to delay the actual application of `f` and skip the first one.

`cn_is_zero` is left as an exercise.

#### Tracing `cn_prev cn3`

Let us trace through `decode_cnat (cn_prev cn3)`:

$$\Downarrow$$

```
(cn_prev cn3) ((+) 1) 0
```

$$\Downarrow$$

```
(fun f x ->
    cn3
      (fun g v -> v (g f))
      (fun z -> x)
      (fun z -> z)) ((+) 1) 0
```

$$\Downarrow$$

```
((fun f x -> f (f (f x)))
      (fun g v -> v (g ((+) 1)))
      (fun z -> 0)
      (fun z -> z))
```

$$\Downarrow$$

```
((fun g v -> v (g ((+) 1)))
  ((fun g v -> v (g ((+) 1)))
    ((fun g v -> v (g ((+) 1)))
      (fun z -> 0))))
  (fun z -> z))
```

$$\Downarrow$$

```
((fun z -> z)
  (((fun g v -> v (g ((+) 1)))
    ((fun g v -> v (g ((+) 1)))
      (fun z -> 0)))) ((+) 1)))
```

$$\Downarrow$$

```
(fun g v -> v (g ((+) 1)))
  ((fun g v -> v (g ((+) 1)))
    (fun z -> 0)) ((+) 1)
```

$$\Downarrow$$

```
((+) 1) ((fun g v -> v (g ((+) 1)))
          (fun z -> 0) ((+) 1))
```

$$\Downarrow$$

```
((+) 1) (((+) 1) ((fun z -> 0) ((+) 1)))
```

$$\Downarrow$$

```
((+) 1) (((+) 1) (0))
```

$$\Downarrow$$

```
((+) 1) 1
```

$$\Downarrow$$

```
2
```

### 4.7 Recursion: Fixpoint Combinators

In lambda-calculus, recursion is achieved through **fixpoint combinators**---lambda terms that compute fixed points of functions.

#### Turing's Fixpoint Combinator

$$\Theta = (\lambda xy. y \; (x \; x \; y)) \; (\lambda xy. y \; (x \; x \; y))$$

Let us verify it computes fixed points. Define $N = \Theta F$:

$$
\begin{aligned}
N &= \Theta F \\
&= (\lambda xy. y \; (x \; x \; y)) \; (\lambda xy. y \; (x \; x \; y)) \; F \\
&=_{\rightarrow\rightarrow} F \; ((\lambda xy. y \; (x \; x \; y)) \; (\lambda xy. y \; (x \; x \; y)) \; F) \\
&= F \; (\Theta F) = F \; N
\end{aligned}
$$

So $N = F \; N$, meaning $N$ is a fixed point of $F$.

#### Curry's Fixpoint Combinator (Y Combinator)

$$\mathbf{Y} = \lambda f. (\lambda x. f \; (x \; x)) \; (\lambda x. f \; (x \; x))$$

$$
\begin{aligned}
N &= \mathbf{Y} F \\
&= (\lambda f. (\lambda x. f \; (x \; x)) \; (\lambda x. f \; (x \; x))) \; F \\
&=_{\rightarrow} (\lambda x. F \; (x \; x)) \; (\lambda x. F \; (x \; x)) \\
&=_{\rightarrow} F \; ((\lambda x. F \; (x \; x)) \; (\lambda x. F \; (x \; x))) \\
&=_{\leftarrow} F \; ((\lambda f. (\lambda x. f \; (x \; x)) \; (\lambda x. f \; (x \; x))) \; F) \\
&= F \; (\mathbf{Y} F) = F \; N
\end{aligned}
$$

#### Call-by-Value Fixpoint Combinator

$$\texttt{fix} = \lambda f'. (\lambda fx. f' \; (f \; f) \; x) \; (\lambda fx. f' \; (f \; f) \; x)$$

$$
\begin{aligned}
N &= \texttt{fix} \; F \\
&= (\lambda f'. (\lambda fx. f' \; (f \; f) \; x) \; (\lambda fx. f' \; (f \; f) \; x)) \; F \\
&=_{\rightarrow} (\lambda fx. F \; (f \; f) \; x) \; (\lambda fx. F \; (f \; f) \; x) \\
&=_{\rightarrow} \lambda x. F \; ((\lambda fx. F \; (f \; f) \; x) \; (\lambda fx. F \; (f \; f) \; x)) \; x \\
&=_{\leftarrow} \lambda x. F \; ((\lambda f'. (\lambda fx. f' \; (f \; f) \; x) \; (\lambda fx. f' \; (f \; f) \; x)) \; F) \; x \\
&= \lambda x. F \; (\texttt{fix} \; F) \; x = \lambda x. F \; N \; x \\
&=_{\eta} F \; N
\end{aligned}
$$

#### The Problem with the First Two Combinators

What is the problem with Turing's and Curry's combinators? Consider what happens when we try to evaluate $\Theta F$:

$$
\begin{aligned}
\Theta F &\rightsquigarrow\rightsquigarrow F \; ((\lambda xy. y \; (x \; x \; y)) \; (\lambda xy. y \; (x \; x \; y)) \; F) \\
&\rightsquigarrow\rightsquigarrow F \; (F \; ((\lambda xy. y \; (x \; x \; y)) \; (\lambda xy. y \; (x \; x \; y)) \; F)) \\
&\rightsquigarrow\rightsquigarrow F \; (F \; (F \; ((\lambda xy. y \; (x \; x \; y)) \; (\lambda xy. y \; (x \; x \; y)) \; F))) \\
&\rightsquigarrow\rightsquigarrow \ldots
\end{aligned}
$$

Recall the distinction between *expressions* and *values* from Chapter 3 on Computation. The reduction rule for lambda-calculus is meant to determine which expressions are considered "equal"---it is highly *non-deterministic*, while on a computer, computation needs to go one way or another.

Using the general reduction rule of lambda-calculus, for a recursive definition, it is always possible to find an infinite reduction sequence. This means a naive lambda-calculus compiler could legitimately generate infinite loops for all recursive definitions!

Therefore, we need more specific rules. Most languages use **call-by-value** (also called **eager** evaluation):

$$(\texttt{fun } x \texttt{ -> } a) \; v \rightsquigarrow a[x := v]$$

The program *eagerly* computes arguments before starting to compute the function body. This is exactly the rule we introduced in the Computation chapter.

#### Call-by-Value Fixpoint Combinator in Action

What happens with the call-by-value fixpoint combinator?

$$
\begin{aligned}
\texttt{fix} \; F &\rightsquigarrow (\lambda fx. F \; (f \; f) \; x) \; (\lambda fx. F \; (f \; f) \; x) \\
&\rightsquigarrow \lambda x. F \; ((\lambda fx. F \; (f \; f) \; x) \; (\lambda fx. F \; (f \; f) \; x)) \; x
\end{aligned}
$$

The computation stops because we use the rule $(\texttt{fun } x \texttt{ -> } a) \; v \rightsquigarrow a[x := v]$ rather than $(\texttt{fun } x \texttt{ -> } a_1) \; a_2 \rightsquigarrow a_1[x := a_2]$. The expression inside the lambda is not evaluated until the function is applied.

Let us compute the function on some input:

$$
\begin{aligned}
\texttt{fix} \; F \; v &\rightsquigarrow (\lambda fx. F \; (f \; f) \; x) \; (\lambda fx. F \; (f \; f) \; x) \; v \\
&\rightsquigarrow (\lambda x. F \; ((\lambda fx. F \; (f \; f) \; x) \; (\lambda fx. F \; (f \; f) \; x)) \; x) \; v \\
&\rightsquigarrow F \; ((\lambda fx. F \; (f \; f) \; x) \; (\lambda fx. F \; (f \; f) \; x)) \; v \\
&\rightsquigarrow F \; (\lambda x. F \; ((\lambda fx. F \; (f \; f) \; x) \; (\lambda fx. F \; (f \; f) \; x)) \; x) \; v \\
&\rightsquigarrow \text{depends on } F
\end{aligned}
$$

#### Why "Fixpoint"?

If you examine our derivations, you will see they establish $x = f(x)$. Such values $x$ are called **fixpoints** of $f$. An arithmetic function can have several fixpoints---for example, $f(x) = x^2$ has fixpoints 0 and 1---or no fixpoints, such as $f(x) = x + 1$.

When you define a function (or another object) by recursion, it has similar meaning: the name appears on both sides of the equality. In lambda-calculus, functions like $\Theta$ and $\mathbf{Y}$ take *any* function as an argument and return its fixpoint.

We turn a specification of a recursive object into a definition by solving it with respect to the recurring name: deriving $x = f(x)$ where $x$ is the recurring name. We then have $x = \texttt{fix}(f)$.

#### Deriving Factorial

Let us walk through this for the factorial function. We omit the prefix `cn_` (could be `pn_` if using pair-encoded numbers) and shorten `if_then_else` to `if_t_e`:

$$
\begin{aligned}
\texttt{fact} \; n &= \texttt{if\_t\_e} \; (\texttt{is\_zero} \; n) \; \texttt{cn1} \; (\texttt{mult} \; n \; (\texttt{fact} \; (\texttt{pred} \; n))) \\
\texttt{fact} &= \lambda n. \texttt{if\_t\_e} \; (\texttt{is\_zero} \; n) \; \texttt{cn1} \; (\texttt{mult} \; n \; (\texttt{fact} \; (\texttt{pred} \; n))) \\
\texttt{fact} &= (\lambda fn. \texttt{if\_t\_e} \; (\texttt{is\_zero} \; n) \; \texttt{cn1} \; (\texttt{mult} \; n \; (f \; (\texttt{pred} \; n)))) \; \texttt{fact} \\
\texttt{fact} &= \texttt{fix} \; (\lambda fn. \texttt{if\_t\_e} \; (\texttt{is\_zero} \; n) \; \texttt{cn1} \; (\texttt{mult} \; n \; (f \; (\texttt{pred} \; n))))
\end{aligned}
$$

The last line is a valid definition: we simply give a name to a *ground* (also called *closed*) expression---one with no free variables.

**Exercise:** Compute `fact cn2`.

**Exercise:** What does `fix (fun x -> cn_succ x)` mean?

### 4.8 Encoding Lists and Trees

A **list** is either empty (often called `Empty` or `Nil`) or consists of an element followed by another list (the "tail"), called `Cons`.

Define:
- `nil` $= \lambda xy.y$
- `cons` $H \; T = \lambda xy. x \; H \; T$

To add numbers stored inside a list:

$$\texttt{addlist} \; l = l \; (\lambda ht. \texttt{cn\_add} \; h \; (\texttt{addlist} \; t)) \; \texttt{cn0}$$

To make a proper definition, we apply $\texttt{fix}$ to the solution of the above equation:

$$\texttt{addlist} = \texttt{fix} \; (\lambda fl. l \; (\lambda ht. \texttt{cn\_add} \; h \; (f \; t)) \; \texttt{cn0})$$

For **trees**, let us use a different form of binary trees: instead of keeping elements in inner nodes, we keep elements in leaves.

Define:
- `leaf` $n = \lambda xy. x \; n$
- `node` $L \; R = \lambda xy. y \; L \; R$

To add numbers stored inside a tree:

$$\texttt{addtree} \; t = t \; (\lambda n.n) \; (\lambda lr. \texttt{cn\_add} \; (\texttt{addtree} \; l) \; (\texttt{addtree} \; r))$$

And in solved form:

$$\texttt{addtree} = \texttt{fix} \; (\lambda ft. t \; (\lambda n.n) \; (\lambda lr. \texttt{cn\_add} \; (f \; l) \; (f \; r)))$$

```ocaml
let rec fix f x = f (fix f) x
let nil = fun x y -> y
let cons h t = fun x y -> x h t
let addlist l =
  fix (fun f l -> l (fun h t -> cn_add h (f t)) cn0) l
;;
decode_cnat
  (addlist (cons cn1 (cons cn2 (cons cn7 nil))));;
let leaf n = fun x y -> x n
let node l r = fun x y -> y l r
let addtree t =
  fix (fun f t ->
    t (fun n -> n) (fun l r -> cn_add (f l) (f r))
  ) t
;;
decode_cnat
  (addtree (node (node (leaf cn3) (leaf cn7))
              (leaf cn1)));;
```

#### The General Pattern

Observe a regularity: when we encode a variant type with $n$ variants, for each variant we define a function that takes $n$ arguments.

If the $k$th variant $C_k$ has $m_k$ parameters, then the function $c_k$ that encodes it has the form:

$$C_k(v_1, \ldots, v_{m_k}) \sim c_k \; v_1 \; \ldots \; v_{m_k} = \lambda x_1 \ldots x_n. x_k \; v_1 \; \ldots \; v_{m_k}$$

The encoded variants serve as shallow pattern matching with guaranteed exhaustiveness: the $k$th argument corresponds to the $k$th branch of pattern matching.

### 4.9 Looping Recursion

Let us return to pair-encoded numbers and define addition:

```
let pn_add m n =
  fix (fun f m n ->
    if_then_else (pn_is_zero m)
      n (pn_succ (f (pn_pred m) n))
  ) m n;;
decode_pnat (pn_add pn3 pn3);;
```

Oops... OCaml says: `Stack overflow during evaluation (looping recursion?).`

What went wrong? Nothing as far as lambda-calculus is concerned. But OCaml (and F#) always compute arguments before calling a function. By definition of `fix`, `f` corresponds to recursively calling `pn_add`. Therefore, `(pn_succ (f (pn_pred m) n))` will be evaluated regardless of what `(pn_is_zero m)` returns!

Why do `addlist` and `addtree` work? Because their recursive calls are "guarded" by corresponding `fun`. What is inside of `fun` is not computed immediately---only when the function is applied to argument(s).

To avoid looping recursion, you need to guard all recursive calls. Besides putting them inside `fun`, in OCaml or F# you can also put them in branches of a `match` clause, as long as one of the branches does not have unguarded recursive calls.

The trick for functions like `if_then_else` is to guard their arguments with `fun x ->`, where `x` is not used, and apply the *result* of `if_then_else` to some dummy value:

```
let id x = x
let rec fix f x = f (fix f) x
let pn1 x = pn_succ pn0 x
let pn2 x = pn_succ pn1 x
let pn3 x = pn_succ pn2 x
let pn7 x = encode_pnat 7 x
let pn_add m n =
  fix (fun f m n ->
    (if_then_else (pn_is_zero m)
       (fun x -> n) (fun x -> pn_succ (f (pn_pred m) n)))
      id
  ) m n;;
decode_pnat (pn_add pn3 pn3);;
decode_pnat (pn_add pn3 pn7);;
```

In OCaml or F# we would typically guard by `fun () ->` and then apply to `()`, but we do not have datatypes like `unit` in pure lambda-calculus.

### 4.10 Exercises

**Exercise 1:** Define (implement) and test on a couple of examples functions corresponding to or computing:

1. `c_or` and `c_not`;
2. exponentiation for Church numerals;
3. is-zero predicate for Church numerals;
4. even-number predicate for Church numerals;
5. multiplication for pair-encoded natural numbers;
6. factorial $n!$ for pair-encoded natural numbers;
7. the length of a list (in Church numerals);
8. `cn_max` -- maximum of two Church numerals;
9. the depth of a tree (in Church numerals).

**Exercise 2:** Construct lambda-terms $m_0, m_1, \ldots$ such that for all $n$ one has:

$$
\begin{aligned}
m_0 &= x \\
m_{n+1} &= m_{n+2} \; m_n
\end{aligned}
$$

(where equality is after performing $\beta$-reductions).

**Exercise 3:** Representing side-effects as an explicitly "passed around" state value, write (higher-order) functions that represent the imperative constructs:

1. `for`...`to`...
2. `for`...`downto`...
3. `while`...`do`...
4. `do`...`while`...
5. `repeat`...`until`...

Rather than writing a lambda-term using the encodings that we have learnt, just implement the functions in OCaml / F#, using built-in `int` and `bool` types. You can use `let rec` instead of `fix`.

- For example, in exercise (a), write a function `let rec for_to f beg_i end_i s = ...` where `f` takes arguments `i` ranging from `beg_i` to `end_i`, state `s` at given step, and returns state `s` at next step; the `for_to` function returns the state after the last step.
- And in exercise (c), write a function `let rec while_do p f s = ...` where both `p` and `f` take state `s` at given step, and if `p s` returns true, then `f s` is computed to obtain state at next step; the `while_do` function returns the state after the last step.

Do not use the imperative features of OCaml and F#!

Although we will not cover imperative features in this course, it is instructive to see the implementation using them, to better understand what is actually required of a solution to Exercise 3:

```ocaml
(* (a) *)
let for_to f beg_i end_i s =
  let s = ref s in
  for i = beg_i to end_i do
    s := f i !s
  done;
  !s

(* (b) *)
let for_downto f beg_i end_i s =
  let s = ref s in
  for i = beg_i downto end_i do
    s := f i !s
  done;
  !s

(* (c) *)
let while_do p f s =
  let s = ref s in
  while p !s do
    s := f !s
  done;
  !s

(* (d) *)
let do_while p f s =
  let s = ref (f s) in
  while p !s do
    s := f !s
  done;
  !s

(* (e) *)
let repeat_until p f s =
  let s = ref (f s) in
  while not (p !s) do
    s := f !s
  done;
  !s
```
