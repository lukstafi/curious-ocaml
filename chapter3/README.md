## Chapter 3: Computation

*Reduction semantics and operational reasoning*

**References:**

- "Using, Understanding and Unraveling the OCaml Language" by Didier Remy, Chapter 1
- "The OCaml system" manual, the tutorial part, Chapter 1

In this chapter, we explore how functional programs actually execute. We will learn how to reason about computation step by step using *reduction semantics*, and discover important optimization techniques like *tail call optimization* that make functional programming practical. Along the way, we will encounter our first taste of *continuation passing style*, a powerful programming technique that will reappear throughout this book.

### 3.1 Function Composition

Function composition is one of the most fundamental operations in functional programming. It allows us to build complex transformations by combining simpler functions. The usual way function composition is defined in mathematics is "backward"---the notation follows the convention of mathematical function application:

$$
(f \circ g)(x) = f(g(x))
$$

This means that when we write $f \circ g$, we first apply $g$ and then apply $f$ to the result. The function written on the left is applied last---hence the term "backward" composition. Here is how this is expressed in different functional programming languages:

| Language | Definition |
|----------|-----------|
| Math | $(f \circ g)(x) = f(g(x))$ |
| OCaml | `let (-|) f g x = f (g x)` |
| F# | `let (<<) f g x = f (g x)` |
| Haskell | `(.) f g = \x -> f (g x)` |

This backward composition looks like function application but needs fewer parentheses. Do you recall the functions `iso1` and `iso2` from the previous chapter on type isomorphisms? Using backward composition, we could write:

```
let iso2 = step1l -| step2l -| step3l
```

While backward composition matches traditional mathematical notation, many programmers find a "forward" composition more intuitive. Forward composition follows the order in which computation actually proceeds---data flows from left to right, matching how we typically read code in most programming languages:

| Language | Definition |
|----------|-----------|
| OCaml | `let (\|-) f g x = g (f x)` |
| F# | `let (>>) f g x = g (f x)` |

With forward composition, you can read a pipeline of transformations in the natural order:

```
let iso1 = step1r |- step2r |- step3r
```

Here, the data first passes through `step1r`, then the result goes to `step2r`, and finally to `step3r`. This "pipeline" style of programming is particularly popular in languages like F# and has influenced the design of many modern programming languages.

#### Partial Application

Both composition examples above rely on **partial application**, a technique we introduced in the previous chapter. Recall that `((+) 1)` is a function that adds 1 to its argument---we have provided only one of the two arguments that `(+)` requires. Partial application occurs whenever we supply fewer arguments than a function expects; the result is a new function that waits for the remaining arguments.

Consider the composition `step1r |- step2r |- step3r`. How exactly does partial application come into play here? The composition operator `(|-)` is defined as `let (|-) f g x = g (f x)`, which means it takes *three* arguments: two functions `f` and `g`, and a value `x`. When we write `step1r |- step2r`, we are partially applying `(|-)` with just two arguments. The result is a function that still needs the final argument `x`.

*Exercise:* Think about the types involved. If `step1r` has type `'a -> 'b` and `step2r` has type `'b -> 'c`, what is the type of `step1r |- step2r`?

#### Power Function

Now we define iterated function composition---applying a function to itself repeatedly. This is written mathematically as:

$$
f^n(x) := \underbrace{(f \circ \cdots \circ f)}_{n \text{ times}}(x)
$$

In other words, $f^0$ is the identity function, $f^1 = f$, $f^2 = f \circ f$, and so on. In OCaml, we first define the backward composition operator, then use it to implement `power`:

```ocaml
let (-|) f g x = f (g x)

let rec power f n =
  if n <= 0 then (fun x -> x) else f -| power f (n-1)
```

When `n <= 0`, we return the identity function `fun x -> x`. Otherwise, we compose `f` with `power f (n-1)`, which gives us one more application of `f`. Notice how elegantly this definition expresses the mathematical concept---we are literally composing `f` with itself `n` times.

This `power` function is surprisingly versatile. For example, we can use it to define addition in terms of the successor function:

```
let add n = power ((+) 1) n
```

Here `add 5 7` would compute $7 + 1 + 1 + 1 + 1 + 1 = 12$. We could even define multiplication:

```
let mult k n = power ((+) k) n 0
```

This computes $0 + k + k + \ldots + k$ (adding $k$ a total of $n$ times), giving us $k \times n$. While not the most efficient implementation, these examples show how higher-order functions like `power` can express fundamental mathematical operations.

#### Numerical Derivative

A beautiful application of `power` is computing higher-order derivatives. First, let us define a numerical approximation of the derivative using the standard finite difference formula:

```ocaml
let derivative dx f = fun x -> (f(x +. dx) -. f(x)) /. dx
```

This definition computes $\frac{f(x + dx) - f(x)}{dx}$, which approximates $f'(x)$ when `dx` is small. Notice the explicit `fun x -> ...` syntax, which emphasizes that `derivative dx f` is itself a function---we are transforming a function `f` into its derivative function.

We can write the same definition more concisely using OCaml's curried function syntax:

```ocaml
let derivative dx f x = (f(x +. dx) -. f(x)) /. dx
```

Both definitions are equivalent, but the first makes the "function returning a function" structure more explicit, while the second is more compact.

**A note on OCaml's numeric operators:** OCaml uses different operators for floating-point arithmetic than for integers. The type of `(+)` is `int -> int -> int`, so we cannot use `+` with `float` values. Instead, operators followed by a dot work on `float` numbers: `+.`, `-.`, `*.`, and `/.`. This might seem inconvenient at first, but it catches type errors at compile time and avoids the implicit conversions that cause subtle bugs in other languages.

#### Computing Higher-Order Derivatives

Now comes the payoff. With `power` and `derivative`, we can elegantly compute higher-order derivatives:

```ocaml
let pi = 4.0 *. atan 1.0
let sin''' = (power (derivative 1e-5) 3) sin;;
sin''' pi
```

Here `sin'''` is the third derivative of sine. The expression `(power (derivative 1e-5) 3)` creates a function that applies the derivative operation three times---exactly what we need for the third derivative.

Mathematically, the third derivative of $\sin(x)$ is $-\cos(x)$, so `sin''' pi` should give us $-\cos(\pi) = 1$. The actual result will be close to 1, with some numerical error due to the finite difference approximation (the error compounds with each derivative we take).

This example demonstrates the power of treating functions as first-class values. We have built a general-purpose derivative operator and combined it with our `power` function to create an $n$th-derivative calculator---all in just a few lines of code.

### 3.2 Evaluation Rules (Reduction Semantics)

So far, we have written OCaml programs and observed their results, but we have not precisely described *how* those results are computed. To understand how OCaml programs execute, we need to formalize the evaluation process. This section presents **reduction semantics** (also called *operational semantics*), which describes computation as a series of rewriting steps that transform expressions until we reach a final value.

Understanding reduction semantics is valuable for several reasons. It helps us predict what our programs will do, reason about their efficiency, and understand subtle behaviors like infinite loops and non-termination. The ideas here also form the foundation for understanding more advanced topics like type systems and program verification.

#### Expressions

Programs consist of **expressions**. Here is the grammar of expressions for a simplified version of OCaml (we omit some features for clarity):

$$
\begin{array}{lcll}
a & := & x & \text{variables} \\
  & |  & \texttt{fun } x \texttt{ -> } a & \text{(defined) functions} \\
  & |  & a \; a & \text{applications} \\
  & |  & C^0 & \text{value constructors of arity } 0 \\
  & |  & C^n(a, \ldots, a) & \text{value constructors of arity } n \\
  & |  & f^n & \text{built-in values (primitives) of arity } n \\
  & |  & \texttt{let } x = a \texttt{ in } a & \text{name bindings (local definitions)} \\
  & |  & \texttt{match } a \texttt{ with} & \\
  &    & \quad p \texttt{ -> } a \texttt{ | } \cdots \texttt{ | } p \texttt{ -> } a & \text{pattern matching} \\[1em]
p & := & x & \text{pattern variables} \\
  & |  & (p, \ldots, p) & \text{tuple patterns} \\
  & |  & C^0 & \text{variant patterns of arity } 0 \\
  & |  & C^n(p, \ldots, p) & \text{variant patterns of arity } n
\end{array}
$$

**Arity** means how many arguments something requires. For constructors, arity tells us how many components the constructor holds; for functions (primitives), it tells us how many arguments they need before they can compute a result. For tuple patterns, arity is simply the length of the tuple.

#### The `fix` Primitive

Our grammar above includes functions defined with `fun`, but what about recursive functions defined with `let rec`? To keep our semantics simple, we introduce a primitive `fix` that captures the essence of recursion:

$$
\texttt{let rec } f \; x = e_1 \texttt{ in } e_2 \equiv \texttt{let } f = \texttt{fix (fun } f \; x \texttt{ -> } e_1 \texttt{) in } e_2
$$

The `fix` primitive is a *fixpoint combinator*. It takes a function that expects to receive "itself" as its first argument and produces a function that, when called, behaves as if it has access to itself for recursive calls. This might seem mysterious now, but we will see exactly how it works when we examine its reduction rule below.

#### Values

Expressions evaluate (i.e., compute) to **values**. Values are expressions that cannot be reduced further---they are the "final answers" of computation:

$$
\begin{array}{lcll}
v & := & \texttt{fun } x \texttt{ -> } a & \text{(defined) functions} \\
  & |  & C^n(v_1, \ldots, v_n) & \text{constructed values} \\
  & |  & f^n \; v_1 \; \cdots \; v_k & k < n \text{ (partially applied primitives)}
\end{array}
$$

Note that functions are values: `fun x -> x + 1` is already fully evaluated---there is nothing more to compute until the function is applied to an argument. Similarly, constructed values like `Some 42` or `(1, 2, 3)` are values when all their components are values.

Partially applied primitives like `(+) 3` are also values. The expression `(+) 3` has received one argument but needs another before it can compute a sum. Until that second argument arrives, there is nothing more to do, so `(+) 3` is a value.

#### Substitution

The heart of evaluation is **substitution**. To substitute a value $v$ for a variable $x$ in expression $a$, we write $a[x := v]$. This notation means that every occurrence of $x$ in $a$ is replaced by $v$.

For example, if $a$ is the expression `x + x * y` and we substitute 3 for `x`, we get `3 + 3 * y`. In our notation: `(x + x * y)[x := 3] = 3 + 3 * y`.

**Implementation note:** Although we describe substitution as "replacing" variables with values, the actual implementation in OCaml does not duplicate the value $v$ in memory each time it appears. Instead, OCaml uses closures and sharing to ensure that values are stored once and referenced wherever needed. This is both more efficient and essential for handling recursive data structures.

#### Reduction Rules (Redexes)

Now we can describe how computation actually proceeds. Reduction works by finding reducible expressions called **redexes** (short for "reducible expressions") and applying reduction rules that rewrite them into simpler forms. We write $e_1 \rightsquigarrow e_2$ to mean "expression $e_1$ reduces to expression $e_2$ in one step."

Here are the fundamental reduction rules:

**Function application (beta reduction):**
$$
(\texttt{fun } x \texttt{ -> } a) \; v \rightsquigarrow a[x := v]
$$

This is the most important rule. When we apply a function `fun x -> a` to a value $v$, we substitute $v$ for the parameter $x$ throughout the function body $a$. This rule is traditionally called "beta reduction" in the lambda calculus literature.

For example: `(fun x -> x + 1) 5` $\rightsquigarrow$ `5 + 1` $\rightsquigarrow$ `6`.

**Let binding:**
$$
\texttt{let } x = v \texttt{ in } a \rightsquigarrow a[x := v]
$$

A let binding works similarly: once the bound expression has been evaluated to a value $v$, we substitute it into the body. Notice that `let x = e in a` is essentially equivalent to `(fun x -> a) e`---both bind $x$ to the result of evaluating $e$ within the expression $a$.

**Primitive application:**
$$
f^n \; v_1 \; \cdots \; v_n \rightsquigarrow f(v_1, \ldots, v_n)
$$

When a primitive (like `+` or `*`) receives all the arguments it needs (determined by its arity $n$), it computes the result. Here $f(v_1, \ldots, v_n)$ denotes the actual result of the primitive operation---for example, `(+) 2 3` $\rightsquigarrow$ `5`.

**Pattern matching with a variable pattern:**
$$
\texttt{match } v \texttt{ with } x \texttt{ -> } a \texttt{ | } \cdots \rightsquigarrow a[x := v]
$$

A variable pattern always matches, binding the entire value to the variable.

**Pattern matching with a non-matching constructor:**
$$
\frac{C_1 \neq C_2}{\texttt{match } C_1^n(v_1, \ldots, v_n) \texttt{ with } C_2^k(p_1, \ldots, p_k) \texttt{ -> } a \texttt{ | } pm \rightsquigarrow \texttt{match } C_1^n(v_1, \ldots, v_n) \texttt{ with } pm}
$$

If the constructor in the value ($C_1$) does not match the constructor in the pattern ($C_2$), we skip this branch and try the remaining patterns ($pm$). This is how OCaml searches through pattern match cases from top to bottom.

**Pattern matching with a matching constructor:**
$$
\texttt{match } C_1^n(v_1, \ldots, v_n) \texttt{ with } C_1^n(x_1, \ldots, x_n) \texttt{ -> } a \texttt{ | } \cdots \rightsquigarrow a[x_1 := v_1; \ldots; x_n := v_n]
$$

If the constructor matches, we substitute all the values from inside the constructor for the corresponding pattern variables. For example, `match Some 42 with Some x -> x + 1 | None -> 0` reduces to `42 + 1` because `Some` matches `Some` and we substitute 42 for `x`.

If $n = 0$, then $C_1^n(v_1, \ldots, v_n)$ stands for simply $C_1^0$, a constructor with no arguments (like `None` or `[]`). We omit the more complex cases of nested pattern matching for brevity.

#### Rule Variables

In these rules, we use *metavariables*---placeholders that can be replaced with actual expressions. Understanding them is key to applying the rules:

- $x$ matches any variable name (like `foo`, `n`, or `result`)
- $a, a_1, \ldots, a_n$ match any expression (not necessarily a value)
- $v, v_1, \ldots, v_n$ match any *value* (expressions that are fully evaluated)

To apply a rule, find substitutions for these metavariables that make the left-hand side of the rule match your expression. Then the right-hand side (with the same substitutions applied) gives you the reduced expression.

For example, to apply the beta reduction rule to `(fun n -> n * 2) 5`:
1. Match `fun x -> a` with `fun n -> n * 2`, giving us $x = \texttt{n}$ and $a = \texttt{n * 2}$
2. Match $v$ with `5`
3. The right-hand side $a[x := v]$ becomes `(n * 2)[n := 5]` which equals `5 * 2`

#### Evaluation Context Rules

The reduction rules above only apply when the arguments are already values. But what if we have `(fun x -> x + 1) (2 + 3)`? The argument `2 + 3` is not a value, so we cannot directly apply beta reduction. We need rules that tell us evaluation can proceed inside subexpressions.

If $a_i \rightsquigarrow a_i'$ (meaning $a_i$ can take a reduction step), then:

$$
\begin{array}{lcl}
a_1 \; a_2 & \rightsquigarrow & a_1' \; a_2 \\
a_1 \; a_2 & \rightsquigarrow & a_1 \; a_2' \\
C^n(a_1, \ldots, a_i, \ldots, a_n) & \rightsquigarrow & C^n(a_1, \ldots, a_i', \ldots, a_n) \\
\texttt{let } x = a_1 \texttt{ in } a_2 & \rightsquigarrow & \texttt{let } x = a_1' \texttt{ in } a_2 \\
\texttt{match } a_1 \texttt{ with } pm & \rightsquigarrow & \texttt{match } a_1' \texttt{ with } pm
\end{array}
$$

These rules describe *where* reduction can happen:
- In a function application $a_1 \; a_2$, either the function ($a_1$) or the argument ($a_2$) can be evaluated. The two rules allow evaluation in arbitrary order---this gives the implementation flexibility in how it schedules computation.
- In a constructor application, any argument can be evaluated.
- In a let binding `let x = a1 in a2`, the bound expression $a_1$ must be evaluated to a value before we can proceed. Notice there is no rule for evaluating $a_2$ directly---the body is only evaluated after the substitution happens.
- In a match expression, the scrutinee (the expression being matched) must be evaluated before pattern matching can proceed.

#### The `fix` Rule

Finally, the rule for the `fix` primitive, which enables recursion:

$$
\texttt{fix}^2 \; v_1 \; v_2 \rightsquigarrow v_1 \; (\texttt{fix}^2 \; v_1) \; v_2
$$

This rule is subtle but powerful. Let us unpack it:

1. `fix` is a binary primitive (arity 2), meaning it needs two arguments before it computes.
2. When we apply `fix` to two values $v_1$ and $v_2$, it "unrolls" one level of recursion by calling $v_1$ with two arguments: `(fix v1)` (which represents "the recursive function itself") and $v_2$ (the actual argument to the recursive call).
3. Because `fix` has arity 2, the expression `(fix v1)` is a *partially applied primitive*---and partially applied primitives are values! This is crucial: it means `(fix v1)` will not be evaluated further until it is applied to another argument inside $v_1$.

This delayed evaluation is what prevents infinite loops. If `(fix v1)` were evaluated immediately, we would get an infinite chain of expansions. Instead, evaluation only continues when the recursive function actually makes a recursive call.

#### Practice

The best way to understand reduction semantics is to work through examples by hand. Trace the evaluation of these expressions step by step:

**Exercise 1:** Evaluate `let double x = x + x in double 3`

**Exercise 2:** Evaluate `(fun f -> fun x -> f (f x)) (fun y -> y + 1) 0`

**Exercise 3:** Define the factorial function using `fix` and trace the evaluation of `factorial 3`

### 3.3 Symbolic Derivation Example

Let us see the reduction rules in action with a more substantial example. We will build a small computer algebra system that can represent mathematical expressions symbolically, evaluate them, and even compute their derivatives symbolically.

Consider the symbolic expression type from `Lec3.ml`:

```ocaml
type expression =
  | Const of float
  | Var of string
  | Sum of expression * expression    (* e1 + e2 *)
  | Diff of expression * expression   (* e1 - e2 *)
  | Prod of expression * expression   (* e1 * e2 *)
  | Quot of expression * expression   (* e1 / e2 *)

exception Unbound_variable of string

let rec eval env exp =
  match exp with
  | Const c -> c
  | Var v ->
    (try List.assoc v env with Not_found -> raise (Unbound_variable v))
  | Sum(f, g) -> eval env f +. eval env g
  | Diff(f, g) -> eval env f -. eval env g
  | Prod(f, g) -> eval env f *. eval env g
  | Quot(f, g) -> eval env f /. eval env g
```

The `expression` type represents mathematical expressions as a tree structure. Each constructor corresponds to a different kind of expression: constants, variables, and the four basic arithmetic operations. The `eval` function takes an environment `env` (a list of variable-value pairs) and recursively evaluates an expression to a floating-point number.

We can also define *symbolic differentiation*---computing the derivative of an expression without evaluating it numerically:

```ocaml
let rec deriv exp dv =
  match exp with
  | Const c -> Const 0.0
  | Var v -> if v = dv then Const 1.0 else Const 0.0
  | Sum(f, g) -> Sum(deriv f dv, deriv g dv)
  | Diff(f, g) -> Diff(deriv f dv, deriv g dv)
  | Prod(f, g) -> Sum(Prod(f, deriv g dv), Prod(deriv f dv, g))
  | Quot(f, g) -> Quot(Diff(Prod(deriv f dv, g), Prod(f, deriv g dv)),
                       Prod(g, g))
```

The `deriv` function implements the standard rules of calculus:
- The derivative of a constant is 0.
- The derivative of the variable we are differentiating with respect to is 1; any other variable is treated as a constant (derivative 0).
- The sum and difference rules: $(f + g)' = f' + g'$ and $(f - g)' = f' - g'$.
- The product rule: $(f \cdot g)' = f \cdot g' + f' \cdot g$.
- The quotient rule: $(f / g)' = (f' \cdot g - f \cdot g') / g^2$.

For convenience, let us define some operators and variables so we can write expressions more naturally:

```ocaml
let x = Var "x"
let y = Var "y"
let (+:) f g = Sum (f, g)
let (-:) f g = Diff (f, g)
let ( *: ) f g = Prod (f, g)
let (/:) f g = Quot (f, g)
let (!:) i = Const i
```

These custom operators (ending in `:`) let us write symbolic expressions that look almost like regular mathematical notation.

Now let us evaluate the expression $3x + 2y + x^2 y$ at $x = 1, y = 2$:

```ocaml
let example = !:3.0 *: x +: !:2.0 *: y +: x *: x *: y
let env = ["x", 1.0; "y", 2.0]
```

When we trace the evaluation using OCaml's `#trace` directive, we can see the recursive structure of the computation unfold:

```
eval_1_2 <-- 3.00 * x + 2.00 * y + x * x * y
  eval_1_2 <-- x * x * y
    eval_1_2 <-- y
    eval_1_2 --> 2.
    eval_1_2 <-- x * x
      eval_1_2 <-- x
      eval_1_2 --> 1.
      eval_1_2 <-- x
      eval_1_2 --> 1.
    eval_1_2 --> 1.
  eval_1_2 --> 2.
  eval_1_2 <-- 3.00 * x + 2.00 * y
    eval_1_2 <-- 2.00 * y
      eval_1_2 <-- y
      eval_1_2 --> 2.
      eval_1_2 <-- 2.00
      eval_1_2 --> 2.
    eval_1_2 --> 4.
    eval_1_2 <-- 3.00 * x
      eval_1_2 <-- x
      eval_1_2 --> 1.
      eval_1_2 <-- 3.00
      eval_1_2 --> 3.
    eval_1_2 --> 3.
  eval_1_2 --> 7.
eval_1_2 --> 9.
- : float = 9.
```

The arrows `<--` and `-->` show function calls and returns, respectively. Each level of indentation represents a nested function call. These indentation levels correspond to **stack frames**---the runtime structures that store the state of each function call. Each time `eval_1_2` is called recursively, a new stack frame is created to remember where to return and what computation remains.

The final result is $3 \cdot 1 + 2 \cdot 2 + 1 \cdot 1 \cdot 2 = 3 + 4 + 2 = 9$, as expected.

This trace visualization brings us to an important question: what happens when we have very deep recursion? This leads us to our next topic.

### 3.4 Tail Calls and Tail Recursion

The call stack is finite, and each recursive call typically adds a new frame to it. This means that deeply recursive functions can exhaust the stack and crash---a notorious problem known as "stack overflow." Fortunately, functional language implementations have a trick to avoid this problem in many cases.

Excuse me for not formally defining what a *function call* is... Computers normally evaluate programs by creating **stack frames** on the call stack for each function call. A stack frame stores the local variables, the return address (where to continue after the function returns), and other bookkeeping information. The trace in the previous section illustrates this: each level of indentation represents a new stack frame.

#### What is a Tail Call?

The key insight is that not all function calls require a new stack frame. A **tail call** is a function call that is performed as the very last action when computing a function---there is nothing more to do after the call returns except to return that value. For example:

```
let f x = g (x + 1)
```

The call to `g` is a tail call. Once `g` returns some value, `f` simply returns that same value---no further computation is needed.

In contrast:

```
let f x = 1 + g x
```

The call to `g` is *not* a tail call. After `g` returns, we still need to add 1 to the result before `f` can return. This means we need to remember to do the addition, which requires keeping the stack frame around.

#### Tail Call Optimization

Functional language compilers (including OCaml's) recognize tail calls and optimize them by performing **tail call optimization** (TCO). Instead of creating a new stack frame, the compiler generates code that reuses the current frame by performing a "jump" to the called function. This means tail calls use constant stack space, no matter how deep the call chain goes.

This optimization is not just a nice-to-have; it is *essential* for functional programming. Without TCO, many natural recursive algorithms would be impractical because they would overflow the stack on moderately large inputs.

#### Tail Recursive Functions

A function is **tail recursive** if all of its recursive calls (including calls to mutually recursive functions it depends on) are tail calls.

Writing tail recursive functions requires a shift in thinking. Instead of building up the result as recursive calls return, we build it up as we *make* the calls. This typically requires an extra **accumulator** argument that carries the partial result through the recursion.

The key insight is that with an accumulator, results are computed in "reverse order"---we do the work while climbing *into* the recursion (making calls) rather than while climbing *out* (returning from calls).

#### Example: Counting

Let us see this in action with a simple counting function. Compare these two versions:

```ocaml
let rec count n =
  if n <= 0 then 0 else 1 + (count (n-1))
```

This version is *not* tail recursive. Look at the recursive case: after `count (n-1)` returns, we still need to add 1 to the result. Each recursive call must remember to do this addition, consuming a stack frame.

Now compare with the tail recursive version:

```ocaml
let rec count_tcall acc n =
  if n <= 0 then acc else count_tcall (acc+1) (n-1)
```

Here, the recursive call `count_tcall (acc+1) (n-1)` is the very last thing the function does---its result becomes our result directly. The accumulator `acc` carries the running count: we add 1 to it *before* the recursive call rather than *after* it returns. To count to 1000000, we call `count_tcall 0 1000000`.

#### Example: Building Lists

The counting example does not really show the practical impact because the numbers are so small. Let us see a more dramatic example with lists:

```ocaml
let rec unfold n = if n <= 0 then [] else n :: unfold (n-1)
```

This function builds a list counting down from `n` to 1. It is not tail recursive because after the recursive call `unfold (n-1)` returns, we must cons `n` onto the front of the result.

```
# unfold 100000;;
- : int list = [100000; 99999; 99998; 99997; ...]

# unfold 1000000;;
Stack overflow during evaluation (looping recursion?).
```

With 100,000 elements, it works. But with a million elements, we run out of stack space and the program crashes! This is a serious problem for practical programming.

Now consider the tail-recursive version:

```ocaml
let rec unfold_tcall acc n =
  if n <= 0 then acc else unfold_tcall (n::acc) (n-1)
```

The accumulator `acc` collects the list as we go. We cons each element onto the accumulator *before* the recursive call. However, there is a catch: because we are building the list as we descend into the recursion (rather than as we return), the list comes out in reverse order:

```
# unfold_tcall [] 100000;;
- : int list = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; ...]

# unfold_tcall [] 1000000;;
- : int list = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; ...]
```

The tail-recursive version handles a million elements effortlessly. The trade-off is that we get `[1; 2; 3; ...]` instead of `[1000000; 999999; ...]`. If we need the original order, we could reverse the result at the end (which is an O(n) operation but uses only constant stack space).

#### A Challenge: Tree Depth

Not all recursive functions can be easily converted to tail recursive form. Consider this problem: can we find the depth of a binary tree using a tail-recursive function?

```ocaml
type btree = Tip | Node of int * btree * btree
```

Here is the natural recursive approach:

```ocaml
let rec depth tree = match tree with
  | Tip -> 0
  | Node(_, left, right) -> 1 + max (depth left) (depth right)
```

This is not tail recursive: after both recursive calls return, we still need to compute `1 + max ...`. The fundamental challenge is that we have *two* recursive calls that we need to make. A simple accumulator will not work---we cannot proceed with one subtree until we know the result of the other.

This seems like an impossible situation. How can we make a function tail recursive when it inherently needs to explore two branches? The answer involves a technique called *continuation passing style*, which we explore in the next section.

#### Note on Lazy Languages

The issue of tail recursion is more nuanced for **lazy** programming languages like Haskell. In a lazy language, expressions are only evaluated when their values are actually needed. The cons operation `(:)` does not immediately evaluate its arguments---it just builds a "promise" to compute them later.

This means that building a list with `n : unfold (n-1)` does not consume stack space in the same way as in OCaml. The `unfold (n-1)` is not evaluated immediately; it is just stored as an unevaluated expression (called a "thunk"). Stack space is only consumed later, when you actually traverse the list. This gives lazy languages different performance characteristics and trade-offs.

### 3.5 First Encounter of Continuation Passing Style

We can solve the tree depth problem using **Continuation Passing Style (CPS)**. This is a powerful technique that transforms programs in a surprising way: instead of returning values, functions receive an extra argument---a *continuation*---that tells them what to do with their result.

The key idea is to postpone doing actual work until the very last moment by passing around a continuation---a function that represents "what to do next with this result."

```ocaml
let rec depth_cps tree k = match tree with
  | Tip -> k 0
  | Node(_, left, right) ->
    depth_cps left (fun dleft ->
      depth_cps right (fun dright ->
        k (1 + (max dleft dright))))

let depth tree = depth_cps tree (fun d -> d)
```

Let us understand how this works step by step:

1. **The continuation parameter:** The function takes an extra parameter `k`, called the **continuation**. Instead of returning a value directly, `depth_cps` will call `k` with its result. You can think of `k` as meaning "and then do this with the answer."

2. **The base case (`Tip`):** When we reach a leaf, the depth is 0. Instead of returning 0, we call `k 0`---"give 0 to whoever is waiting for our answer."

3. **The recursive case (`Node`):** This is where CPS shines. We need to compute depths of both subtrees and combine them. Here is how we do it:
   - First, recursively compute the depth of the left subtree. But instead of waiting for the result, we pass a continuation: `fun dleft -> ...`
   - This continuation says "when you have the left depth (call it `dleft`), then..."
   - ...compute the depth of the right subtree, passing another continuation: `fun dright -> ...`
   - This inner continuation says "when you have the right depth (call it `dright`), then..."
   - ...finally call the original continuation `k` with the combined result `1 + max dleft dright`

4. **The wrapper function:** To use `depth_cps`, we need to provide an initial continuation. We pass the identity function `fun d -> d`, which just returns whatever it receives. This is the "final consumer" of the result.

The magic is that *every recursive call is now a tail call*! Look carefully: `depth_cps left (...)` is the last thing the function does in that branch---everything else is inside the continuation, which will be called later.

Where does the "pending work" go? Instead of being stored on the call stack, it is captured in the continuation closures. These closures are allocated on the heap. We have traded stack space for heap space.

**Important caveat:** This does not completely solve the stack overflow problem---we are just moving the problem from the stack to the heap. For very deep trees, the continuation closures can grow very large, potentially exhausting memory. True solutions for extreme cases involve techniques like *trampolining* (returning control to a loop) or using explicit data structures to represent the pending work. Nevertheless, CPS is often more space-efficient than direct recursion, and it is a fundamental technique that appears throughout functional programming.

We will encounter CPS again when studying monads and advanced control flow, where it provides the foundation for powerful abstractions.

### 3.6 Exercises

These exercises will help you practice the concepts from this chapter: function composition, reduction semantics, tail recursion, and continuation passing style.

**Exercise 1: Tree Traversals**

By "traverse a tree" below we mean: write a function that takes a tree and returns a list of values in the nodes of the tree. Use the `btree` type defined earlier.

1. Write a function (of type `btree -> int list`) that traverses a binary tree in **prefix order** (also called *preorder*)---first the value stored in a node, then values in all nodes to the left, then values in all nodes to the right.

2. Write a traversal in **infix order** (also called *inorder*)---first values in all nodes to the left, then the value stored in the node, then values in all nodes to the right. For a binary search tree, this would give you the elements in sorted order.

3. Write a traversal in **breadth-first order** (also called *level order*)---visit all nodes at depth 0, then all nodes at depth 1, and so on. Hint: you will need an auxiliary data structure (a queue) to keep track of nodes to visit.

**Exercise 2: CPS Transformation**

Turn the function from Exercise 1 (prefix or infix traversal) into continuation passing style. Compare the structure of your CPS version to the original. What are the trade-offs?

**Exercise 3: Tree Derivatives Revisited**

Do the homework from the end of Chapter 2: write `btree_deriv_at` that takes a predicate over integers and a `btree`, and builds a `btree_deriv` whose "hole" is in the first position (using your chosen traversal order) for which the predicate returns true.

**Exercise 4: Expression Simplification**

Write a function `simplify: expression -> expression` that simplifies symbolic expressions, so that for example the result of `simplify (deriv exp dv)` looks more like what a human would get computing the derivative of `exp` with respect to `dv`.

Some simplifications to consider:
- $0 + x = x$ and $x + 0 = x$
- $0 \cdot x = 0$ and $x \cdot 0 = 0$
- $1 \cdot x = x$ and $x \cdot 1 = x$
- $x - 0 = x$
- $x / 1 = x$

Approach this in two steps:
1. Write a `simplify_once` function that performs a single "pass" of simplification over the expression tree.
2. Wrap it using a general `fixpoint` function that performs an operation until a **fixed point** is reached: given $f$ and $x$, it computes $f^n(x)$ such that $f^n(x) = f^{n+1}(x)$ (i.e., applying $f$ one more time does not change the result).

Why do we need iteration to a fixed point rather than a single pass?

**Exercise 5: Sorting Algorithms**

Write two sorting algorithms working on lists: merge sort and quicksort.

1. **Merge sort** splits the list roughly in half, sorts the parts recursively, and merges the sorted parts into the sorted result. You will need a helper function to merge two sorted lists.

2. **Quicksort** splits the list into elements smaller than and greater-than-or-equal-to the first element (the "pivot"), sorts the parts recursively, and concatenates them.

Which of these algorithms can be implemented in a tail-recursive manner? What about the helper functions (merge, partition)?
