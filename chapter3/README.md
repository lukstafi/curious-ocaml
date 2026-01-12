## Chapter 3: Computation

*Reduction semantics and operational reasoning*

**References:**

- "Using, Understanding and Unraveling the OCaml Language" by Didier Remy, Chapter 1
- "The OCaml system" manual, the tutorial part, Chapter 1

### 3.1 Function Composition

The usual way function composition is defined in mathematics is "backward"---the notation follows the convention of mathematical function application:

$$
(f \circ g)(x) = f(g(x))
$$

This means that when we write $f \circ g$, we first apply $g$ and then apply $f$ to the result. Here is how this is expressed in different functional programming languages:

| Language | Definition |
|----------|-----------|
| Math | $(f \circ g)(x) = f(g(x))$ |
| OCaml | `let (-|) f g x = f (g x)` |
| F# | `let (<<) f g x = f (g x)` |
| Haskell | `(.) f g = \x -> f (g x)` |

This backward composition looks like function application but needs fewer parentheses. Recall the functions `iso1` and `iso2` from the previous chapter on type isomorphisms. Using backward composition, we could write:

```
let iso2 = step1l -| step2l -| step3l
```

A more natural definition of function composition is "forward" composition, which follows the order in which computation actually proceeds:

| Language | Definition |
|----------|-----------|
| OCaml | `let (\|-) f g x = g (f x)` |
| F# | `let (>>) f g x = g (f x)` |

With forward composition, data flows from left to right, matching how we typically read code:

```
let iso1 = step1r |- step2r |- step3r
```

#### Partial Application

Both composition examples above use **partial application**. Recall from the previous chapter that `((+) 1)` is a function that adds 1 to its argument. Partial application occurs when we do not pass all the arguments a function needs; the result is a function that requires the remaining arguments.

In the composition `step1r |- step2r |- step3r`, each `stepNr` function is partially applied. The composition operator `(|-)` takes two functions `f` and `g` and returns a new function that first applies `f`, then applies `g` to the result.

#### Power Function

Now we define iterated function composition:

$$
f^n(x) := \underbrace{(f \circ \cdots \circ f)}_{n \text{ times}}(x)
$$

In OCaml, we first define the backward composition operator, then use it in `power`:

```ocaml
let (-|) f g x = f (g x)

let rec power f n =
  if n <= 0 then (fun x -> x) else f -| power f (n-1)
```

When `n <= 0`, we return the identity function. Otherwise, we compose `f` with `power f (n-1)`, which gives us one more application of `f`.

#### Numerical Derivative

Using `power`, we can define a numerical approximation of the derivative:

```ocaml
let derivative dx f = fun x -> (f(x +. dx) -. f(x)) /. dx
```

This definition emphasizes that `derivative dx f` is itself a function of `x`. We can write it more concisely as:

```ocaml
let derivative dx f x = (f(x +. dx) -. f(x)) /. dx
```

Note that OCaml uses different operators for floating-point arithmetic. We have `(+): int -> int -> int` for integers, so we cannot use `+` with floating-point numbers. Instead, operators followed by a dot work on `float` values: `+.`, `-.`, `*.`, `/.`.

#### Computing Higher-Order Derivatives

With `power` and `derivative`, we can easily compute higher-order derivatives:

```ocaml
let pi = 4.0 *. atan 1.0
let sin''' = (power (derivative 1e-5) 3) sin;;
sin''' pi
```

Here `sin'''` is the third derivative of sine. The result should be approximately $-\cos(\pi) = 1$ (with some numerical error due to the finite difference approximation).

### 3.2 Evaluation Rules (Reduction Semantics)

To understand how OCaml programs compute their results, we need to formalize the evaluation process. This section presents **reduction semantics**, which describes computation as a series of rewriting steps.

#### Expressions

Programs consist of **expressions**. Here is the grammar of expressions for a simplified version of OCaml:

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

**Arity** means how many arguments something requires (and for tuples, the length of the tuple).

#### The `fix` Primitive

To simplify our presentation of recursion, we use a primitive `fix` to define a limited form of `let rec`:

$$
\texttt{let rec } f \; x = e_1 \texttt{ in } e_2 \equiv \texttt{let } f = \texttt{fix (fun } f \; x \texttt{ -> } e_1 \texttt{) in } e_2
$$

The `fix` primitive captures the essence of recursion: it takes a function that expects to receive itself as an argument and produces a fixed point---a function that, when called, behaves as if it had access to itself.

#### Values

Expressions evaluate (i.e., compute) to **values**. Values are expressions that cannot be reduced further:

$$
\begin{array}{lcll}
v & := & \texttt{fun } x \texttt{ -> } a & \text{(defined) functions} \\
  & |  & C^n(v_1, \ldots, v_n) & \text{constructed values} \\
  & |  & f^n \; v_1 \; \cdots \; v_k & k < n \text{ (partially applied primitives)}
\end{array}
$$

Note that functions are values: `fun x -> x + 1` is already fully evaluated. Partially applied primitives like `(+) 3` are also values---they are waiting for more arguments.

#### Substitution

To **substitute** a value $v$ for a variable $x$ in expression $a$, we write $a[x := v]$. This notation means that every occurrence of $x$ in $a$ is replaced by $v$.

In the actual implementation, the value $v$ is not duplicated in memory. Instead, OCaml uses references or closures to share the value efficiently.

#### Reduction Rules (Redexes)

Reduction (i.e., computation) proceeds by finding reducible expressions called **redexes** and applying reduction rules. Here are the fundamental redexes:

**Function application (beta reduction):**
$$
(\texttt{fun } x \texttt{ -> } a) \; v \rightsquigarrow a[x := v]
$$

When we apply a function to a value, we substitute the value for the parameter in the function body.

**Let binding:**
$$
\texttt{let } x = v \texttt{ in } a \rightsquigarrow a[x := v]
$$

A let binding with a value substitutes that value into the body.

**Primitive application:**
$$
f^n \; v_1 \; \cdots \; v_n \rightsquigarrow f(v_1, \ldots, v_n)
$$

When a primitive receives all its arguments, it computes the result. Here $f(v_1, \ldots, v_n)$ denotes the actual result of the primitive operation.

**Pattern matching with a variable pattern:**
$$
\texttt{match } v \texttt{ with } x \texttt{ -> } a \texttt{ | } \cdots \rightsquigarrow a[x := v]
$$

**Pattern matching with a non-matching constructor:**
$$
\frac{C_1 \neq C_2}{\texttt{match } C_1^n(v_1, \ldots, v_n) \texttt{ with } C_2^k(p_1, \ldots, p_k) \texttt{ -> } a \texttt{ | } pm \rightsquigarrow \texttt{match } C_1^n(v_1, \ldots, v_n) \texttt{ with } pm}
$$

If the constructor does not match, we try the next pattern.

**Pattern matching with a matching constructor:**
$$
\texttt{match } C_1^n(v_1, \ldots, v_n) \texttt{ with } C_1^n(x_1, \ldots, x_n) \texttt{ -> } a \texttt{ | } \cdots \rightsquigarrow a[x_1 := v_1; \ldots; x_n := v_n]
$$

If the constructor matches, we substitute all the bound values.

If $n = 0$, then $C_1^n(v_1, \ldots, v_n)$ stands for simply $C_1^0$, a constructor with no arguments. We omit the more complex cases of nested pattern matching.

#### Rule Variables

In these rules, the metavariables have specific meanings:
- $x$ matches any expression or pattern variable
- $a, a_1, \ldots, a_n$ match any expression
- $v, v_1, \ldots, v_n$ match any value

To apply a rule, find substitutions for these metavariables that make the left-hand side match your expression. The right-hand side (with the same substitutions) is the reduced expression.

#### Evaluation Context Rules

The rules above only apply when the arguments are already values. We also need rules that allow evaluation of subexpressions. If $a_i \rightsquigarrow a_i'$, then:

$$
\begin{array}{lcl}
a_1 \; a_2 & \rightsquigarrow & a_1' \; a_2 \\
a_1 \; a_2 & \rightsquigarrow & a_1 \; a_2' \\
C^n(a_1, \ldots, a_i, \ldots, a_n) & \rightsquigarrow & C^n(a_1, \ldots, a_i', \ldots, a_n) \\
\texttt{let } x = a_1 \texttt{ in } a_2 & \rightsquigarrow & \texttt{let } x = a_1' \texttt{ in } a_2 \\
\texttt{match } a_1 \texttt{ with } pm & \rightsquigarrow & \texttt{match } a_1' \texttt{ with } pm
\end{array}
$$

These rules say that:
- In an application, either the function or the argument can be evaluated (in arbitrary order)
- In a constructor, any argument can be evaluated
- In a let binding, the bound expression is evaluated before the body
- In a match, the scrutinee is evaluated before matching

#### The `fix` Rule

Finally, the rule for the `fix` primitive, which enables recursion:

$$
\texttt{fix}^2 \; v_1 \; v_2 \rightsquigarrow v_1 \; (\texttt{fix}^2 \; v_1) \; v_2
$$

Because `fix` is a binary primitive (arity 2), the expression $(\texttt{fix}^2 \; v_1)$ is already a value (a partially applied primitive). This means it will not be further evaluated until it is applied inside $v_1$. This delayed evaluation is what makes recursion work without infinite loops.

#### Practice

**Exercise:** Compute some simple programs by hand using these rules. For example, trace the evaluation of:

```ocaml
let double x = x + x in double 3
```

### 3.3 Symbolic Derivation Example

Let us see the reduction rules in action with a more complex example. Consider the symbolic expression evaluator from `Lec3.ml`:

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

We can also define symbolic differentiation:

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

For convenience, let us define some operators and variables:

```ocaml
let x = Var "x"
let y = Var "y"
let (+:) f g = Sum (f, g)
let (-:) f g = Diff (f, g)
let ( *: ) f g = Prod (f, g)
let (/:) f g = Quot (f, g)
let (!:) i = Const i
```

Now consider evaluating the expression `3x + 2y + x^2 y` at $x = 1, y = 2$:

```ocaml
let example = !:3.0 *: x +: !:2.0 *: y +: x *: x *: y
let env = ["x", 1.0; "y", 2.0]
```

When we trace the evaluation, we can see the recursive structure of the computation:

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

The indentation levels in this trace correspond to **stack frames**---the runtime structures that store the state of each function call. This brings us to an important optimization technique.

### 3.4 Tail Calls and Tail Recursion

Computers normally evaluate programs by creating **stack frames** on the call stack for each function call. The trace above illustrates this: each level of indentation represents a new stack frame.

#### What is a Tail Call?

A **tail call** is a function call that is performed last when computing a function---there is nothing more to do after the call returns. For example, in:

```
let f x = g (x + 1)
```

The call to `g` is a tail call because after `g` returns, `f` immediately returns that value.

In contrast, in:

```
let f x = 1 + g x
```

The call to `g` is *not* a tail call because after `g` returns, we still need to add 1 to the result.

#### Tail Call Optimization

Functional language compilers (including OCaml's) recognize tail calls and optimize them. Instead of creating a new stack frame, they reuse the current frame by performing a "jump" to the called function. This means tail calls use constant stack space.

#### Tail Recursive Functions

A function is **tail recursive** if it calls itself (and any mutually recursive functions it depends on) only using tail calls.

Tail recursive functions often use special **accumulator** arguments that store intermediate computation results. In a non-tail-recursive function, these intermediate results would be values of subexpressions stored on the stack.

The key insight is that the accumulated result is computed in "reverse order"---while climbing up the recursion (making calls) rather than while descending (returning from calls).

#### Example: Counting

Compare these two counting functions:

```ocaml
let rec count n =
  if n <= 0 then 0 else 1 + (count (n-1))
```

This is *not* tail recursive because after the recursive call returns, we still need to add 1.

```ocaml
let rec count_tcall acc n =
  if n <= 0 then acc else count_tcall (acc+1) (n-1)
```

This *is* tail recursive: the recursive call is the last thing the function does.

#### Example: Building Lists

Let us see a more dramatic example:

```ocaml
let rec unfold n = if n <= 0 then [] else n :: unfold (n-1)
```

This function builds a list counting down from `n`. It is not tail recursive because after the recursive call, we must cons `n` onto the result.

```
# unfold 100000;;
- : int list = [100000; 99999; 99998; 99997; ...]

# unfold 1000000;;
Stack overflow during evaluation (looping recursion?).
```

With a million elements, we run out of stack space! Now consider the tail-recursive version:

```ocaml
let rec unfold_tcall acc n =
  if n <= 0 then acc else unfold_tcall (n::acc) (n-1)
```

The accumulator `acc` collects the list as we go. Note that the list is built in reverse order:

```
# unfold_tcall [] 100000;;
- : int list = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; ...]

# unfold_tcall [] 1000000;;
- : int list = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; ...]
```

The tail-recursive version handles a million elements with no problem.

#### A Challenge: Tree Depth

Is it possible to find the depth of a tree using a tail-recursive function?

```ocaml
type btree = Tip | Node of int * btree * btree
```

The naive approach:

```ocaml
let rec depth tree = match tree with
  | Tip -> 0
  | Node(_, left, right) -> 1 + max (depth left) (depth right)
```

This is not tail recursive: after both recursive calls, we still need to compute `1 + max ...`. The challenge is that we have *two* recursive calls, and we cannot simply use an accumulator.

#### Note on Lazy Languages

The issue of tail recursion is more complex for **lazy** programming languages like Haskell. In a lazy language, the cons operation `(:)` does not immediately evaluate its arguments, so building a list with `n :: unfold (n-1)` does not consume stack space in the same way.

### 3.5 First Encounter of Continuation Passing Style

We can solve the tree depth problem using **Continuation Passing Style (CPS)**. The key idea is to postpone doing actual work until the very last moment by passing around a "continuation"---a function that represents "what to do next."

```ocaml
let rec depth_cps tree k = match tree with
  | Tip -> k 0
  | Node(_, left, right) ->
    depth_cps left (fun dleft ->
      depth_cps right (fun dright ->
        k (1 + (max dleft dright))))

let depth tree = depth_cps tree (fun d -> d)
```

Let us understand how this works:

1. The function takes an extra parameter `k`, called the **continuation**. It represents what to do with the final result.

2. In the `Tip` case, we call the continuation with the depth 0.

3. In the `Node` case, we recursively compute the depth of the left subtree, passing a continuation that:
   - Receives the left depth `dleft`
   - Then recursively computes the depth of the right subtree, passing a continuation that:
     - Receives the right depth `dright`
     - Finally calls the original continuation with `1 + max dleft dright`

4. The wrapper function passes the identity function `fun d -> d` as the initial continuation.

The magic is that each recursive call is now a tail call! The "work" of computing `1 + max dleft dright` is captured in the continuation closures, which are allocated on the heap rather than the stack.

However, this does not completely solve the stack overflow problem---we are trading stack space for heap space (storing the continuation closures). For very deep trees, we might still run out of memory. True solutions involve trampolining or iterative approaches with explicit stacks.

CPS is a powerful technique that appears throughout functional programming. We will encounter it again when studying monads and advanced control flow.

### 3.6 Exercises

**Exercise 1:** By "traverse a tree" below we mean: write a function that takes a tree and returns a list of values in the nodes of the tree.

1. Write a function (of type `btree -> int list`) that traverses a binary tree in **prefix order**---first the value stored in a node, then values in all nodes to the left, then values in all nodes to the right.

2. Write a traversal in **infix order**---first values in all nodes to the left, then the value stored in the node, then values in all nodes to the right (so it is "left-to-right" order).

3. Write a traversal in **breadth-first order**---first values in shallower nodes before deeper nodes.

**Exercise 2:** Turn the function from Exercise 1 (prefix or infix traversal) into continuation passing style.

**Exercise 3:** Do the homework from the end of Chapter 2: write `btree_deriv_at` that takes a predicate over integers and a `btree`, and builds a `btree_deriv` whose "hole" is in the first position for which the predicate returns true.

**Exercise 4:** Write a function `simplify: expression -> expression` that simplifies symbolic expressions, so that for example the result of `simplify (deriv exp dv)` looks more like what a human would get computing the derivative of `exp` with respect to `dv`.

- Write a `simplify_once` function that performs a single step of simplification.
- Wrap it using a general `fixpoint` function that performs an operation until a **fixed point** is reached: given $f$ and $x$, it computes $f^n(x)$ such that $f^n(x) = f^{n+1}(x)$.

**Exercise 5:** Write two sorting algorithms working on lists: merge sort and quicksort.

1. **Merge sort** splits the list roughly in half, sorts the parts recursively, and merges the sorted parts into the sorted result.

2. **Quicksort** splits the list into elements smaller than and greater than (or equal to) the first element, sorts the parts recursively, and concatenates them.
