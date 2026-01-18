## Chapter 4: Functions

*Programming in untyped lambda-calculus*

**In this chapter, you will:**

- Rehearse reduction-by-hand on a non-trivial recursive program
- Learn the syntax and $\beta$-reduction rules of the untyped lambda-calculus
- Encode booleans, pairs, naturals, lists, and trees using functions alone
- Understand recursion via fixpoint combinators (and how evaluation order matters)

This chapter explores the theoretical foundations of functional programming through the untyped lambda-calculus. We embark on a fascinating journey that reveals a surprising truth: every computation can be expressed using nothing but functions. No numbers, no booleans, no data structures---just functions all the way down.

We begin with a review of computation by hand using our reduction semantics, then introduce the lambda-calculus notation and show how to encode fundamental data types---booleans, pairs, and natural numbers---using only functions. The chapter concludes with an examination of recursion through fixpoint combinators and practical considerations for avoiding infinite loops in eager evaluation.

**References:**

- "Introduction to Lambda Calculus" by Henk Barendregt and Erik Barendsen
- "Lecture Notes on the Lambda Calculus" by Peter Selinger

### 4.1 Review: Computation by Hand

Before diving into the lambda-calculus, let us work through a complete example of evaluation using the reduction rules from Chapter 3. Computing a larger, recursive program by hand will solidify our understanding of how computation proceeds step by step and prepare us for the more abstract setting of lambda-calculus.

Recall that we use `fix` instead of `let rec` to simplify our rules for recursion. Also remember our syntactic conventions: `fun x y -> e` stands for `fun x -> (fun y -> e)`, and so forth.

Consider the following recursive `length` function applied to a two-element list:

```ocaml skip
let rec fix f x = f (fix f) x

type int_list = Nil | Cons of int * int_list

let length =
  fix (fun f l ->
    match l with
    | Nil -> 0
    | Cons (_x, xs) -> 1 + f xs)
in
length (Cons (1, (Cons (2, Nil))))
```

Let us trace through this computation step by step. First, we eliminate the `let ... in ...` binding for `length`:

$$\texttt{let } x = v \texttt{ in } a \rightsquigarrow a[x := v]$$

This gives us:

```
fix (fun f l ->
    match l with
      | Nil -> 0
      | Cons (x, xs) -> 1 + f xs) (Cons (1, (Cons (2, Nil))))
```

Next, we apply the `fix` rule:

$$\texttt{fix}^2 \; v_1 \; v_2 \rightsquigarrow v_1 \; (\texttt{fix}^2 \; v_1) \; v_2$$

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
& C_2^n(p_1, \ldots, p_k) \texttt{ -> } a \texttt{ | } pm \rightsquigarrow \texttt{match } C_1^n(v_1, \ldots, v_n) \texttt{ with } pm
\end{aligned}
$$

Pattern matching against a matching constructor performs substitution:

$$
\begin{aligned}
& \texttt{match } C_1^n(v_1, \ldots, v_n) \texttt{ with} \\
& C_1^n(x_1, \ldots, x_n) \texttt{ -> } a \texttt{ | } \ldots \rightsquigarrow a[x_1 := v_1; \ldots; x_n := v_n]
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

$$f^n \; v_1 \; \ldots \; v_n \rightsquigarrow f(v_1, \ldots, v_n)$$

We obtain the result: `2`.

### 4.2 Language and Rules of the Untyped Lambda-Calculus

The lambda-calculus, introduced by Alonzo Church in the 1930s, is a minimal formal system for expressing computation. It may seem surprising that such a stripped-down language can be computationally complete, but that is precisely what we will demonstrate in this chapter. To work with lambda-calculus, we first simplify our language in several ways:

1. **Forget about types.** In pure lambda-calculus, there is no type system constraining which terms can be combined. Any function can be applied to any argument---including itself!

2. **Introduce notation.** We write $\lambda x.a$ for `fun x -> a`, and $\lambda xy.a$ for `fun x y -> a`, and so forth. This notation is more compact and traditional in the literature.

3. **Reduce to essentials.** We keep only functions (lambda abstractions) and variables---no constructors, no built-in primitives. Everything else will be *encoded* using functions.

The core reduction rule of lambda-calculus is called **$\beta$-reduction**:

$$(\texttt{fun } x \texttt{ -> } a_1) \; a_2 \rightsquigarrow a_1[x := a_2]$$

Note that this rule is more general than the one we use for OCaml evaluation. In our OCaml semantics, we require the argument to be a value: $(\texttt{fun } x \texttt{ -> } a) \; v \rightsquigarrow a[x := v]$. The general $\beta$-reduction rule allows substituting any expression, not just values.

Lambda-calculus also uses **$\alpha$-conversion** (bound variable renaming), or equivalent techniques, to avoid **variable capture**---the unintended binding of free variables during substitution. We will explore the implications of $\beta$-reduction more deeply in the chapter on laziness.

Why is $\beta$-reduction more general than our evaluation rule? Consider the expression $(\lambda x. x) \; ((\lambda y. y) \; z)$. With $\beta$-reduction, we could reduce the outer application first, obtaining $((\lambda y. y) \; z)$. Our evaluation rule would require first reducing the argument to a value---but here `z` is a free variable, not a value, so we would be stuck!

This example is intentionally an *open term* (it has a free variable `z`): in lambda-calculus we often reason about open terms up to $\beta$-equivalence, while programming-language evaluation is usually defined for *closed* programs.

### 4.3 Booleans

Alonzo Church originally introduced lambda-calculus as a foundation for logic, seeking to encode logical reasoning in a purely computational form. There are multiple ways to encode various sorts of data in lambda-calculus, though not all of them work well in a typed setting---the straightforward encode/decode functions may not type-check for some encodings.

The key insight behind the **Church encoding** of booleans is to represent truth values as *selector functions*. Think about what a boolean fundamentally does: it chooses between two alternatives. So we define:

- **True** selects the first argument: `c_true` $= \lambda xy.x$
- **False** selects the second argument: `c_false` $= \lambda xy.y$

In OCaml syntax:

```ocaml env=ch4
let c_true = fun x y -> x   (* "True" is projection on the first argument *)
let c_false = fun x y -> y  (* And "false" on the second argument *)
```

Once we have booleans as selectors, logical operations become elegant. Logical conjunction can be defined as:

$$\texttt{c\_and} = \lambda xy. x \; y \; \texttt{c\_false}$$

The logic behind this definition is beautifully simple: we apply `x` (which is a selector) to two arguments. If `x` is true, it selects its first argument, which is `y`---so the result is true only if both `x` and `y` are true. If `x` is false, it selects its second argument, `c_false`, and returns false immediately without even looking at `y`.

```ocaml env=ch4
let c_and = fun x y -> x y c_false  (* If one is false, then return false *)
```

Let us verify this works. For `c_and c_true c_true`:

$$(\lambda xy. x \; y \; \texttt{c\_false}) \; (\lambda xy.x) \; (\lambda xy.x)$$

reduces to:

$$(\lambda xy.x) \; (\lambda xy.x) \; \texttt{c\_false}$$

which gives us $\lambda xy.x$ = `c_true`. You can verify that for any other combination involving `c_false`, the result is `c_false`.

To verify our encodings in OCaml, we need encode and decode functions. The decoder works by applying our Church boolean to the actual OCaml values `true` and `false`:

```ocaml env=ch4
let encode_bool b = if b then c_true else c_false
let decode_bool c = (Obj.magic c) true false  (* Don't enforce type on c *)
```

**Exercise:** Define `c_or` and `c_not` yourself! Hint: think about what `c_or` should return when the first argument is true, and when it is false. For `c_not`, consider that a boolean is a function that selects between two arguments.

### 4.4 If-then-else and Pairs

From now on, we will use OCaml syntax for our lambda-calculus programs. This makes it easier to experiment with our encodings in the toplevel.

An important observation is that our encoded booleans already implement conditional selection:

```ocaml env=ch4
let if_then_else b t e = b t e  (* Booleans select the branch! *)
```

Wait---is `if_then_else` “just” the identity function? Up to $\eta$-equivalence, yes: `fun b -> b` and `fun b t e -> b t e` are the same function. Since `c_true` returns its first argument and `c_false` returns its second, `if_then_else b t e` simply applies `b` to the two branches. The boolean *is* the conditional.

Remember to play with these functions in the toplevel to build intuition. Try expressions like `if_then_else c_true "yes" "no"` and see what happens.

#### Pairs

Pairs (ordered tuples of two elements) can be encoded using a similar idea. The key insight is that a pair needs to "remember" two values and provide them when asked. We can achieve this by creating a function that holds onto both values and waits for a selector to choose between them:

```ocaml env=ch4
let c_pair m n = fun x -> x m n  (* We couple things *)
let c_first = fun p -> p c_true  (* by passing them together *)
let c_second = fun p -> p c_false  (* Check that it works! *)
```

A pair is a function that, when given a selector, applies that selector to both components. To extract the first component, we pass `c_true` (which selects the first argument); to extract the second, we pass `c_false`. Verify for yourself that `c_first (c_pair a b)` reduces to `a`!

For verification:

```ocaml env=ch4
let encode_pair enc_fst enc_snd (a, b) =
  c_pair (enc_fst a) (enc_snd b)
let decode_pair de_fst de_snd c = c (fun x y -> de_fst x, de_snd y)
let decode_bool_pair c = decode_pair decode_bool decode_bool c
```

We can define larger tuples in the same manner: `let c_triple l m n = fun x -> x l m n`

### 4.5 Pair-Encoded Natural Numbers

Now we come to encoding numbers---a crucial test of whether functions alone can represent all data. Our first encoding of natural numbers uses nested pairs. The representation is based on the depth of nested pairs whose rightmost leaf is the identity function $\lambda x.x$ and whose left elements are `c_false`.

```ocaml env=ch4
let pn0 = fun x -> x           (* Start with the identity function *)
let pn_succ n = c_pair c_false n  (* Stack another pair *)

let pn_pred = fun x -> x c_false  (* Extract the nested number *)
let pn_is_zero = fun x -> x c_true  (* Check if it's the base case *)
```

The number 0 is represented as the identity function. The number 1 is `c_pair c_false pn0`, the number 2 is `c_pair c_false (c_pair c_false pn0)`, and so on. Think of it as a stack of pairs, where the height of the stack represents the number.

How do `pn_pred` and `pn_is_zero` work? Let us think through this carefully:
- The identity function `pn0`, when applied to any argument, returns that argument.
- A successor `c_pair c_false n` is a function waiting for a selector; applying it to `c_false` selects the second component (the predecessor), while applying it to `c_true` selects the first component (`c_false`).

So `pn_is_zero` applies the number to `c_true`:
- For `pn0`, we get `c_true` back (since `pn0` is the identity)---the number is zero!
- For any successor, we get `c_false` back (the first component of the pair)---the number is not zero!

We program in untyped lambda-calculus as an exercise, and we need encoding/decoding to verify our work. Since these encodings do not type-check cleanly in OCaml, using `Obj.magic` to bypass the type system for encoding/decoding is "fair game":

```ocaml env=ch4
let rec encode_pnat n =                (* We use Obj.magic to forget types *)
  if n <= 0 then Obj.magic pn0
  else pn_succ (Obj.magic (encode_pnat (n-1)))  (* Disregarding types, *)
let rec decode_pnat pn =               (* these functions are straightforward! *)
  if decode_bool (pn_is_zero pn) then 0
  else 1 + decode_pnat (pn_pred (Obj.magic pn))
```

Needless to say, `Obj.magic` is unsafe and should not be used in real code; here it is only a convenient bridge from untyped lambda-terms to OCaml so we can test our encodings.

### 4.6 Church Numerals

Do you remember our function `power f n` from Chapter 3 that composed a function with itself `n` times? We will use a similar idea for a different, and historically important, representation of numbers.

**Church numerals** represent a natural number $n$ as a function that applies its first argument $n$ times to its second argument:

```ocaml env=ch4
let cn0 = fun f x -> x        (* The same as c_false *)
let cn1 = fun f x -> f x      (* Behaves like identity when f = id *)
let cn2 = fun f x -> f (f x)
let cn3 = fun f x -> f (f (f x))
```

This is the original Alonzo Church encoding, and it is remarkably elegant. The number $n$ is represented as $\lambda fx. f^n(x)$, where $f^n$ denotes $n$-fold composition. A number literally *is* the act of doing something $n$ times!

Notice that `cn0` is the same as `c_false`---zero applications of `f` just returns `x`.

The successor function adds one more application of `f`:

```ocaml env=ch4
let cn_succ = fun n f x -> f (n f x)
```

**Exercise:** Define addition, multiplication, and comparing to zero for Church numerals. Also try to define the predecessor function "-1".

It turns out even Alonzo Church could not define predecessor right away! The story goes that his student Stephen Kleene figured it out while at the dentist. Try to make some progress on addition and multiplication first (they are not too hard), and then attempt predecessor before looking at the solution below.

```ocaml env=ch4
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
  fun f x ->
    (* A Church numeral is an n-step iterator. Predecessor is tricky because
       we cannot “subtract an iteration”; instead we build a small state
       transformer that delays the use of [f] and then skips the first step. *)
    n
      (fun g h -> h (g f))
      (fun _z -> x)
      (fun z -> z)
```

Addition is intuitive: to add $n$ and $m$, we first apply `f` $m$ times (giving us `m f x`), then apply `f` $n$ more times. Multiplication is even more clever: we apply the operation "apply `f` $m$ times" $n$ times, which computes $m \times n$ applications of `f`.

The predecessor function is ingenious and worth studying carefully. The challenge is that Church numerals only know how to apply `f` more times, not fewer. Kleene's insight was to build up a chain of functions that, when "started" with the identity, yields $n-1$ applications of `f`. The key is to delay the actual application of `f` and skip the first one.

`cn_is_zero` is left as an exercise. Hint: what happens when you apply zero to a function that always returns `c_false` and start with `c_true`?

#### Tracing `cn_prev cn3`

The predecessor function is tricky enough that it is worth tracing through a complete example. Let us trace through `decode_cnat (cn_prev cn3)` to see how it computes 2 from 3:

$$\rightsquigarrow^*$$

```
(cn_prev cn3) ((+) 1) 0
```

$$\rightsquigarrow^*$$

```
(fun f x ->
    cn3
      (fun g h -> h (g f))
      (fun _z -> x)
      (fun z -> z)) ((+) 1) 0
```

$$\rightsquigarrow^*$$

```
((fun f x -> f (f (f x)))
      (fun g h -> h (g ((+) 1)))
      (fun z -> 0)
      (fun z -> z))
```

$$\rightsquigarrow^*$$

```
((fun g h -> h (g ((+) 1)))
  ((fun g h -> h (g ((+) 1)))
    ((fun g h -> h (g ((+) 1)))
      (fun z -> 0))))
  (fun z -> z))
```

$$\rightsquigarrow^*$$

```
((fun z -> z)
  (((fun g h -> h (g ((+) 1)))
    ((fun g h -> h (g ((+) 1)))
      (fun z -> 0)))) ((+) 1)))
```

$$\rightsquigarrow^*$$

```
(fun g h -> h (g ((+) 1)))
  ((fun g h -> h (g ((+) 1)))
    (fun z -> 0)) ((+) 1)
```

$$\rightsquigarrow^*$$

```
((+) 1) ((fun g h -> h (g ((+) 1)))
          (fun z -> 0) ((+) 1))
```

$$\rightsquigarrow^*$$

```
((+) 1) (((+) 1) ((fun z -> 0) ((+) 1)))
```

$$\rightsquigarrow^*$$

```
((+) 1) (((+) 1) (0))
```

$$\rightsquigarrow^*$$

```
((+) 1) 1
```

$\rightsquigarrow^*$ `2`

### 4.7 Recursion: Fixpoint Combinators

We have seen how to encode data in lambda-calculus, but how do we encode *computation*, especially recursive computation? In lambda-calculus, there is no `let rec` or any built-in notion of a function referring to itself. Instead, recursion is achieved through **fixpoint combinators**---remarkable lambda terms that compute fixed points of functions.

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

The lambda-terms we have seen above are **fixpoint combinators**---the means within lambda-calculus to perform recursion without any special recursive binding constructs.

#### The Problem with the First Two Combinators

What is the problem with Turing's and Curry's combinators in a practical programming language? Consider what happens when we try to evaluate $\Theta F$:

$$
\begin{aligned}
\Theta F &\rightsquigarrow\rightsquigarrow F \; ((\lambda xy. y \; (x \; x \; y)) \; (\lambda xy. y \; (x \; x \; y)) \; F) \\
&\rightsquigarrow\rightsquigarrow F \; (F \; ((\lambda xy. y \; (x \; x \; y)) \; (\lambda xy. y \; (x \; x \; y)) \; F)) \\
&\rightsquigarrow\rightsquigarrow F \; (F \; (F \; ((\lambda xy. y \; (x \; x \; y)) \; (\lambda xy. y \; (x \; x \; y)) \; F))) \\
&\rightsquigarrow\rightsquigarrow \ldots
\end{aligned}
$$

Recall the distinction between *expressions* and *values* from Chapter 3 on Computation. The reduction rule for lambda-calculus is meant to determine which expressions are considered "equal"---it is highly *non-deterministic*, while on a computer, computation needs to go one way or another.

Using the general reduction rule of lambda-calculus, for a recursive definition, it is always possible to find an infinite reduction sequence. Why? Because we can always choose to reduce the recursive call first, which generates another recursive call, and so on forever. This means a naive lambda-calculus compiler could legitimately generate infinite loops for all recursive definitions---which would not be very useful!

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

If you examine our derivations, you will see they establish $x = f(x)$. Such values $x$ are called **fixpoints** of $f$. An arithmetic function can have several fixpoints---for example, $f(x) = x^2$ has fixpoints 0 and 1 (since $0^2 = 0$ and $1^2 = 1$)---or no fixpoints, such as $f(x) = x + 1$ (since $x + 1 \neq x$ for all $x$).

When you define a function (or another object) by recursion, it has a similar meaning: the name appears on both sides of the equality. For example, `fact n = if n = 0 then 1 else n * fact (n-1)` has `fact` on both sides. In lambda-calculus, functions like $\Theta$ and $\mathbf{Y}$ take *any* function as an argument and return its fixpoint.

We turn a specification of a recursive object into a definition by solving it with respect to the recurring name: deriving $x = f(x)$ where $x$ is the recurring name. We then have $x = \texttt{fix}(f)$.

#### Deriving Factorial

Let us walk through this process step by step for the factorial function. This will show how to transform a recursive specification into a proper definition using `fix`. We omit the prefix `cn_` (could be `pn_` if using pair-encoded numbers) and shorten `if_then_else` to `if_t_e`:

$$
\begin{aligned}
\texttt{fact} \; n &= \texttt{if\_t\_e} \; (\texttt{is\_zero} \; n) \; \texttt{cn1} \; (\texttt{mult} \; n \; (\texttt{fact} \; (\texttt{pred} \; n))) \\
\texttt{fact} &= \lambda n. \texttt{if\_t\_e} \; (\texttt{is\_zero} \; n) \; \texttt{cn1} \; (\texttt{mult} \; n \; (\texttt{fact} \; (\texttt{pred} \; n))) \\
\texttt{fact} &= (\lambda fn. \texttt{if\_t\_e} \; (\texttt{is\_zero} \; n) \; \texttt{cn1} \; (\texttt{mult} \; n \; (f \; (\texttt{pred} \; n)))) \; \texttt{fact} \\
\texttt{fact} &= \texttt{fix} \; (\lambda fn. \texttt{if\_t\_e} \; (\texttt{is\_zero} \; n) \; \texttt{cn1} \; (\texttt{mult} \; n \; (f \; (\texttt{pred} \; n))))
\end{aligned}
$$

The last line is a valid definition: we simply give a name to a *ground* (also called *closed*) expression---one with no free variables. We have already seen how `fix` works in the reduction semantics.

**Exercise:** Compute `fact cn2` by hand, tracing through the reduction steps.

**Exercise:** What does `fix (fun x -> cn_succ x)` mean? What happens if you try to evaluate it? Think about whether there is any value `x` such that `x = cn_succ x`.

### 4.8 Encoding Lists and Trees

Now that we have numbers and recursion, we can encode more complex data structures. The pattern we have seen with booleans and pairs extends naturally to algebraic data types like lists and trees.

A **list** is either empty (often called `Empty` or `Nil`) or consists of an element followed by another list (the "tail"), called `Cons`. Since lists have two variants, we encode them with two-argument selector functions:

- `nil` $= \lambda xy.y$ (select the second argument, like `c_false`)
- `cons` $H \; T = \lambda xy. x \; H \; T$ (apply the first argument to head and tail)

With these definitions, we can write a function to add all numbers stored inside a list:

$$\texttt{addlist} \; l = l \; (\lambda h t. \texttt{cn\_add} \; h \; (\texttt{addlist} \; t)) \; \texttt{cn0}$$

To make a proper definition, we apply $\texttt{fix}$ to the solution of the above equation:

$$\texttt{addlist} = \texttt{fix} \; (\lambda f l. l \; (\lambda h t. \texttt{cn\_add} \; h \; (f \; t)) \; \texttt{cn0})$$

For **trees**, let us use a different form of binary trees than we have seen before: instead of keeping elements in inner nodes, we will keep elements in leaves. This is sometimes called an "external" tree structure.

Again, we have two variants, so we use two-argument selector functions:

- `leaf` $n = \lambda xy. x \; n$ (apply first argument to the element)
- `node` $L \; R = \lambda xy. y \; L \; R$ (apply second argument to left and right subtrees)

To add numbers stored inside a tree:

$$\texttt{addtree} \; t = t \; (\lambda n.n) \; (\lambda l r. \texttt{cn\_add} \; (\texttt{addtree} \; l) \; (\texttt{addtree} \; r))$$

And in solved form:

$$\texttt{addtree} = \texttt{fix} \; (\lambda f t. t \; (\lambda n.n) \; (\lambda l r. \texttt{cn\_add} \; (f \; l) \; (f \; r)))$$

```ocaml env=ch4
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

If you look back at our encodings, you will observe a consistent pattern: when we encode a variant type with $n$ variants, for each variant we define a function that takes $n$ arguments.

If the $k$th variant $C_k$ has $m_k$ parameters, then the function $c_k$ that encodes it has the form:

$$C_k(v_1, \ldots, v_{m_k}) \sim c_k \; v_1 \; \ldots \; v_{m_k} = \lambda x_1 \ldots x_n. x_k \; v_1 \; \ldots \; v_{m_k}$$

The encoded variants serve as shallow pattern matching with guaranteed exhaustiveness: the $k$th argument corresponds to the $k$th branch of pattern matching. This is exactly how `match` works in OCaml, but encoded purely with functions!

### 4.9 Looping Recursion

We have been coding in untyped lambda-calculus and verifying our code works in OCaml. But there is a subtle trap we must be aware of when combining lambda-calculus encodings with OCaml's eager evaluation.

Let us return to pair-encoded numbers and define addition:

```ocaml skip
let pn_add m n =
  fix (fun f m n ->
    if_then_else (pn_is_zero m)
      n (pn_succ (f (pn_pred m) n))
  ) m n;;
decode_pnat (pn_add pn3 pn3);;
```

Oops... OCaml says: `Stack overflow during evaluation (looping recursion?).`

What went wrong? Nothing as far as lambda-calculus is concerned---the definition is mathematically correct. But OCaml (and F#) always compute arguments before calling a function. This is the *eager* evaluation strategy we discussed earlier. By definition of `fix`, `f` corresponds to recursively calling `pn_add`. Therefore, `(pn_succ (f (pn_pred m) n))` will be evaluated regardless of what `(pn_is_zero m)` returns!

In other words, even when `m` is zero and we should return `n`, OCaml first tries to compute the "else" branch, which makes a recursive call, which computes its "else" branch, and so on forever.

Why do `addlist` and `addtree` work? Look at them carefully: their recursive calls are "guarded" by corresponding `fun`. The expression `(fun h t -> cn_add h (f t))` does not immediately call `f`---it creates a function that will call `f` only when that function is applied to arguments. What is inside of `fun` is not computed immediately---only when the function is applied to argument(s).

To avoid looping recursion, you need to guard all recursive calls. Besides putting them inside `fun`, in OCaml or F# you can also put them in branches of a `match` clause, as long as one of the branches does not have unguarded recursive calls.

The trick for functions like `if_then_else` is to guard their arguments with `fun x ->`, where `x` is not used, and apply the *result* of `if_then_else` to some dummy value. This delays the evaluation of both branches until the boolean has selected one of them:

```ocaml env=ch4
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

Now the recursive call is wrapped in `fun x ->`, so it is not evaluated until `if_then_else` selects the second branch and applies it to `id`. When `m` is zero, the first branch `(fun x -> n)` is selected and applied to `id`, giving us `n` without ever touching the recursive call.

In OCaml or F# we would typically guard by `fun () ->` and then apply to `()`, but we do not have datatypes like `unit` in pure lambda-calculus, so we use `id` as our dummy value.

### 4.10 Exercises

The following exercises will help solidify your understanding of lambda-calculus encodings. For each exercise involving lambda-calculus, test your implementation by encoding some inputs, applying your function, and decoding the result.

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

Do not use the imperative features of OCaml and F#! This exercise demonstrates that imperative control flow can be encoded purely functionally by threading state through function calls.

Although we will not cover imperative features in this course, it is instructive to see the implementation using them, to better understand what is actually required of a solution to Exercise 3:

```ocaml env=ch4
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
