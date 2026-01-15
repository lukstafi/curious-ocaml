## Chapter 1: Logic

*From logic rules to programming constructs*

### 1.1 In the Beginning there was Logos

What logical connectives do you know? Before we write any code, let us take a step back and think about logic itself. The connectives listed below form the foundation of reasoning, and as we will discover, they also form the foundation of programming.

| $\top$ | $\bot$ | $\wedge$ | $\vee$ | $\rightarrow$ |
|---|---|---|---|---|
|   |   | $a \wedge b$ | $a \vee b$ | $a \rightarrow b$ |
| truth | falsehood | conjunction | disjunction | implication |
| "trivial" | "impossible" | $a$ and $b$ | $a$ or $b$ | $a$ gives $b$ |
|   | shouldn't get | got both | got at least one | given $a$, we get $b$ |

How can we define these connectives precisely? The key insight is to think in terms of *derivation trees*. A derivation tree shows how we arrive at conclusions from premises, building up knowledge step by step:

$$
\frac{
\frac{\frac{\,}{\text{a premise}} \; \frac{\,}{\text{another premise}}}{\text{some fact}} \;
\frac{\frac{\,}{\text{this we have by default}}}{\text{another fact}}}
{\text{final conclusion}}
$$

We define connectives by providing rules for using them. For example, a rule $\frac{a \; b}{c}$ matches parts of the tree that have two premises, represented by variables $a$ and $b$, and have any conclusion, represented by variable $c$. These variables act as placeholders that can match any proposition.

**Design principle:** When defining a connective, we try to use only that connective in its definition. This keeps definitions self-contained and avoids circular dependencies between connectives.

### 1.2 Rules for Logical Connectives

Each logical connective comes with two kinds of rules:

**Introduction rules** tell us how to *produce* or *construct* a connective. If you want to prove "A and B", the introduction rule tells you what you need: proofs of both A and B.

**Elimination rules** tell us how to *use* or *consume* a connective. If you already have "A and B", the elimination rules tell you what you can get from it: either A or B (your choice).

In the table below, text in parentheses provides informal commentary. Letters like $a$, $b$, and $c$ are variables that can stand for any proposition.

| Connective | Introduction Rules | Elimination Rules |
|------------|-------------------|-------------------|
| $\top$ | $\frac{}{\top}$ | doesn't have |
| $\bot$ | doesn't have | $\frac{\bot}{a}$ (i.e., anything) |
| $\wedge$ | $\frac{a \quad b}{a \wedge b}$ | $\frac{a \wedge b}{a}$ (take first) &nbsp; $\frac{a \wedge b}{b}$ (take second) |
| $\vee$ | $\frac{a}{a \vee b}$ (put first) &nbsp; $\frac{b}{a \vee b}$ (put second) | $\frac{a \vee b \quad \genfrac{}{}{0pt}{}{[a]^x}{\vdots \; c} \quad \genfrac{}{}{0pt}{}{[b]^y}{\vdots \; c}}{c}$ using $x, y$ |
| $\rightarrow$ | $\frac{\genfrac{}{}{0pt}{}{[a]^x}{\vdots \; b}}{a \rightarrow b}$ using $x$ | $\frac{a \rightarrow b \quad a}{b}$ |

#### Notation for Hypothetical Derivations

The notation $\genfrac{}{}{0pt}{}{[a]^x}{\vdots \; b}$ (sometimes written as a tree) matches any subtree that derives $b$ and can use $a$ as an assumption (marked with label $x$), even though $a$ might not otherwise be warranted. The square brackets around $a$ indicate that this is a *hypothetical* assumption, not something we have actually established. The superscript $x$ is a label that helps us track which assumption gets "discharged" when we complete the derivation.

This is the key to proving implications: to prove "if A then B", we temporarily assume A and show we can derive B. For example, we can derive "sunny $\rightarrow$ happy" by showing that *assuming* it is sunny, we can derive happiness:

$$
\frac{\frac{\frac{\frac{\frac{\,}{\text{sunny}}^x}{\text{go outdoor}}}{\text{playing}}}{\text{happy}}}{\text{sunny} \rightarrow \text{happy}} \text{ using } x
$$

Notice how the assumption "sunny" (marked with $x$) appears at the top of the derivation tree. We use this assumption to derive "go outdoor", then "playing", and finally "happy". Once we complete the derivation, the assumption is *discharged*: we no longer need to assume it is sunny because we have established the conditional "sunny $\rightarrow$ happy".

A crucial point: such assumptions can only be used within the matched subtree! However, they can be used *multiple times* within that subtree. For example, if someone's mood is more difficult to influence and requires multiple sunny conditions:

$$
\frac{\frac{
  \frac{\frac{\frac{\,}{\text{sunny}}^x}{\text{go outdoor}}}{\text{playing}} \quad
  \frac{\frac{\,}{\text{sunny}}^x \quad \frac{\frac{\,}{\text{sunny}}^x}{\text{go outdoor}}}{\text{nice view}}
}{\text{happy}}}{\text{sunny} \rightarrow \text{happy}} \text{ using } x
$$

In this more complex derivation, the assumption "sunny" (labeled $x$) is used three times: once to derive "go outdoor", and twice more in deriving "nice view". All three uses are valid because they occur within the same hypothetical subtree.

#### Reasoning by Cases

The elimination rule for disjunction deserves special attention because it represents **reasoning by cases**, one of the most fundamental proof techniques.

Suppose we know "A or B" is true, but we do not know which one. How can we still derive a conclusion C? We must show that C follows *regardless* of which alternative holds. In other words, we need to prove: (1) assuming A, we can derive C, and (2) assuming B, we can derive C. Since one of A or B must be true, and both lead to C, we can conclude C.

Here is a concrete example: How can we use the fact that it is sunny $\vee$ cloudy (but not rainy)?

$$
\frac{
  \frac{\,}{\text{sunny} \vee \text{cloudy}}^{\text{forecast}} \quad
  \frac{\frac{\,}{\text{sunny}}^x}{\text{no-umbrella}} \quad
  \frac{\frac{\,}{\text{cloudy}}^y}{\text{no-umbrella}}
}{\text{no-umbrella}} \text{ using } x, y
$$

We know that it will be sunny or cloudy (by watching the weather forecast). Now we reason by cases: *If* it will be sunny, we will not need an umbrella. *If* it will be cloudy, we will not need an umbrella. Since one of these must be the case, and both lead to the same conclusion, we can confidently say: we will not need an umbrella.

#### Reasoning by Induction

We need one more kind of rule to do serious math: **reasoning by induction**. This rule is somewhat similar to reasoning by cases, but instead of considering a finite number of alternatives, it allows us to prove properties that hold for infinitely many cases, such as all natural numbers.

Here is the example rule for induction on natural numbers:

$$
\frac{p(0) \quad \genfrac{}{}{0pt}{}{[p(x)]^x}{\vdots \; p(x+1)}}{p(n)} \text{ by induction, using } x
$$

This rule says: we get property $p$ for *any* natural number $n$, provided we can do two things:

1. **Base case:** Establish $p(0)$, that is, prove the property holds for zero.
2. **Inductive step:** Show that *assuming* $p(x)$ holds for some arbitrary $x$, we can derive $p(x+1)$. This assumption $p(x)$ is called the *induction hypothesis*.

Here $x$ is a unique variable representing an arbitrary natural number. We cannot substitute a particular number for it because we write "using $x$" on the side, indicating that the derivation works for any choice of $x$.

The power of induction lies in this: once we have the base case and the inductive step, we have implicitly covered *all* natural numbers. Starting from $p(0)$, we can derive $p(1)$, then $p(2)$, then $p(3)$, and so on, reaching any natural number $n$ we wish.

### 1.3 Logos was Programmed in OCaml

We now arrive at one of the most remarkable discoveries in the foundations of computer science: the **Curry-Howard correspondence**, also known as "propositions as types" or the "proofs-as-programs" interpretation. This deep correspondence reveals that logical proofs and computer programs are, in a precise sense, the same thing!

Under this correspondence:

- **Propositions** (logical statements) correspond to **types**
- **Proofs** (derivations showing a proposition is true) correspond to **programs** (expressions of a given type)
- **Introduction rules** correspond to **constructors** (ways to build values)
- **Elimination rules** correspond to **destructors** (ways to use values)

This is not merely an analogy. The formal rules for logic and the formal rules for type checking are *identical*. When you write a well-typed program, you are simultaneously constructing a proof!

The following table shows how each logical connective corresponds to a programming construct in OCaml:

| Logic | Type | Expression | Intuition |
|-------|------|------------|-----------|
| $\top$ | `unit` | `()` | The trivially true proposition; the type with exactly one value |
| $\bot$ | `'a` | `raise` | Falsehood; a type with no values (exceptions escape normal typing) |
| $\wedge$ | `*` | `(,)` | Conjunction corresponds to pairs: having both A and B |
| $\vee$ | `\|` | `match` | Disjunction corresponds to variants: having either A or B |
| $\rightarrow$ | `->` | `fun` | Implication corresponds to functions: given A, produce B |
| induction | - | `rec` | Inductive proofs correspond to recursive functions |

Let us now see the precise typing rules for each OCaml construct, presented in the same style as our logical rules:

**Typing rules for OCaml constructs:**

- **Unit (truth):** $\frac{}{\texttt{()} : \texttt{unit}}$

  The unit value `()` always has type `unit`. This is like $\top$ in logic: we can always produce it without any premises.

- **Exception (falsehood):** $\frac{\text{oops!}}{\texttt{raise exn} : c}$ can produce any type

  The `raise` expression can have *any* type $c$. This corresponds to the principle of "explosion" in logic: from falsehood, anything follows. In practice, `raise` never actually produces a value; it transfers control to an exception handler. The type system allows it to have any type because the expression will never complete normally.

- **Pair (conjunction):**
  - Introduction: $\frac{s : a \quad t : b}{(s, t) : a * b}$
  - Elimination: $\frac{p : a * b}{\texttt{fst}~p : a}$ and $\frac{p : a * b}{\texttt{snd}~p : b}$

  To construct a pair, you need both components. To use a pair, you can extract either component. This mirrors conjunction perfectly: to prove "A and B", you need proofs of both; given "A and B", you can conclude either A or B.

- **Variant (disjunction):**
  - Introduction: $\frac{s : a}{\texttt{A}(s) : \texttt{A of}~a~|~\texttt{B of}~b}$
  - Elimination (match): given $t$ of variant type and branches for each case, produce result $c$

  To construct a variant, you only need one of the alternatives. To use a variant, you must handle *all* possible cases (pattern matching). This mirrors disjunction: to prove "A or B", you only need one; to use "A or B", you must consider both possibilities.

- **Function (implication):**
  - Introduction: $\frac{\genfrac{}{}{0pt}{}{[x : a]}{e : b}}{\texttt{fun}~x \to e : a \to b}$
  - Elimination (application): $\frac{f : a \to b \quad t : a}{f~t : b}$

  To construct a function, you assume you have an input of type $a$ (the parameter $x$) and show how to produce a result of type $b$. To use a function, you apply it to an argument. This mirrors implication: to prove "A implies B", assume A and derive B; given "A implies B" and A, conclude B.

- **Recursion (induction):** $\frac{\genfrac{}{}{0pt}{}{[x : a]}{e : a}}{\texttt{rec}~x = e : a}$

  In recursion, the function being defined can refer to itself. This corresponds to induction: we can use the property we are trying to prove (the induction hypothesis) in the inductive step.

#### Definitions

Writing out expressions and types repetitively quickly becomes tedious. More importantly, without definitions we cannot give names to our concepts, making code harder to understand and maintain. This is why we need definitions.

**Type definitions** are written: `type ty =` some type.

- Writing `A(s) : A of a | B of b` in the table above was a simplification. In practice, we usually have to define the type first and then use it. For example, using `int` for $a$ and `string` for $b$:
  ```ocaml
  type int_string_choice = A of int | B of string
  ```
  This allows us to write `A(s) : int_string_choice`.

- Why do we need to define variant types? The reasons are: exhaustiveness checks, performnance of generated code, and ease of type inference. When OCaml sees `A(5)`, it needs to figure out (or "infer") the type. Without a type definition, how would OCaml know whether this is `A of int | B of string` or `A of int | B of float | C of bool`? The definition tells OCaml exactly what variants exist. When you match `| A i -> ...`, the compiler will warn you if you forgot to also cover `C b` in your match patterns.

- OCaml does provide an alternative: *polymorphic variants*, written with a backtick. We can write `` `A(s) : [`A of a | `B of b] ``. With `` ` `` variants, OCaml does infer what other variants might exist based on usage. These types are powerful and flexible, we will discuss them in chapter 11.

- Tuple elements do not need labels because we always know at which position a tuple element stands: the first element is first, the second is second, and so on. However, having labels makes code much clearer, especially when tuples have many components or components of the same type. For this reason, we can define a *record type*:

  ```ocaml skip
  type int_string_record = {a: int; b: string}
  ```

  and create its values: `{a = 7; b = "Mary"}`. OCaml 5.4 and newer also support labeled tuples, we will not discuss these.

- We access the *fields* of records using the dot notation: `{a=7; b="Mary"}.b = "Mary"`. Unlike tuples where you must remember "the second element is the name", with records you can write `.b` to get the field named `b`.

#### Expression Definitions

The recursive expression `rec x = e` that appeared in our table was a simplification: `rec` (usually called `fix` in programming language theory) cannot appear alone in OCaml! It must always be part of a `let` definition.

This brings us to **expression definitions**, which let us give names to values. The typing rules for definitions are a bit more complex than what we have seen so far:

$$
\frac{e_1 : a \quad \frac{[x : a]}{e_2 : b}}{\texttt{let } x = e_1 \texttt{ in } e_2 : b}
$$

This rule says: if $e_1$ has type $a$, and assuming $x$ has type $a$ we can show that $e_2$ has type $b$, then the whole `let` expression has type $b$. Interestingly, this rule is equivalent to introducing a function and immediately applying it: `let x = e1 in e2` behaves the same as `(fun x -> e2) e1`. This equivalence reflects a deep connection in the Curry-Howard correspondence.

For recursive definitions, we need an additional rule:

$$
\frac{\frac{[x : a]}{e_1 : a} \quad \frac{[x : a]}{e_2 : b}}{\texttt{let rec } x = e_1 \texttt{ in } e_2 : b}
$$

Notice the crucial difference: in the recursive case, $x$ can appear in $e_1$ itself! This is what allows functions to call themselves. The name $x$ is visible both in its own definition ($e_1$) and in the body that uses the definition ($e_2$).

These rules are slightly simplified. The full rules involve a concept called **polymorphism**, which we will cover in a later chapter. Polymorphism explains how the same function can work with different types.

#### Scoping Rules

Understanding *scope*—where names are visible—is essential for reading and writing OCaml programs.

- **Type definitions** we have seen above are *global*: they need to be at the top-level (not nested in expressions), and they extend from the point they occur till the end of the source file or interactive session. You cannot define a type inside a function.

- **`let`-`in` definitions** for expressions: `let x = e1 in e2` are *local*—the name $x$ is only visible within $e_2$. Once you exit the `in` part, $x$ no longer exists. This is useful for temporary values that should not pollute the global namespace.

- **`let` definitions** without `in` are global: placing `let x = e1` at the top-level makes $x$ visible from after $e_1$ till the end of the source file or interactive session. This is how you define functions and values that the rest of your program can use.

- In the interactive session (toplevel/REPL), we mark the end of a top-level "sentence" with `;;`. This tells OCaml "I am done typing, please evaluate this." In source files compiled by the build system, `;;` is unnecessary because the end of each definition is clear from context.

#### Operators

Operators like `+`, `*`, `<`, `=` are simply names of functions. In OCaml, there is nothing magical about operators; they are ordinary functions that happen to have special characters in their names and can be used in infix position (between their arguments).

Just like other names, you can define your own operators:

```ocaml
let (+:) a b = String.concat "" [a; b];;  (* Special way of defining *)
"Alpha" +: "Beta";;  (* but normal way of using operators *)
```

Notice the asymmetry here: when *defining* an operator, we wrap it in parentheses to tell OCaml "this is the name I am defining". When *using* the operator, we write it in the normal infix position between its arguments. This asymmetry exists because the definition syntax needs to distinguish between "the name `+:`" and "the expression `a +: b`".

An important feature of OCaml is that operators are **not overloaded**. This means that a single operator cannot work for multiple types. Each type needs its own set of operators:
- `+`, `*`, `/` work for integers
- `+.`, `*.`, `/.` work for floating point numbers

This design choice makes type inference simpler and more predictable. When you see `x + y`, OCaml knows immediately that `x` and `y` must be integers.

**Exception:** The comparison operators `<`, `=`, `<=`, `>=`, `<>` do work for all values other than functions. These are called *polymorphic comparisons*.

### 1.4 Exercises

The following exercises are adapted from *Think OCaml: How to Think Like a Computer Scientist* by Nicholas Monje and Allen Downey. They will help you get comfortable with OCaml's syntax and type system.

1. Assume that we execute the following assignment statements:
   ```ocaml
   let width = 17
   let height = 12.0
   let delimiter = '.'
   ```
   For each of the following expressions, write the value of the expression and the type (of the value of the expression), or the resulting type error.
   1. `width/2`
   2. `width/.2.0`
   3. `height/3`
   4. `1 + 2 * 5`
   5. `delimiter * 5`

2. Practice using the OCaml interpreter as a calculator:
   1. The volume of a sphere with radius $r$ is $\frac{4}{3} \pi r^3$. What is the volume of a sphere with radius 5? (*Hint:* 392.6 is wrong!)
   2. Suppose the cover price of a book is \$24.95, but bookstores get a 40% discount. Shipping costs \$3 for the first copy and 75 cents for each additional copy. What is the total wholesale cost for 60 copies?
   3. If I leave my house at 6:52 am and run 1 mile at an easy pace (8:15 per mile), then 3 miles at tempo (7:12 per mile) and 1 mile at easy pace again, what time do I get home for breakfast?

3. You've probably heard of the Fibonacci numbers before, but in case you haven't, they're defined by the following recursive relationship:
   $$
   \begin{cases}
   f(0) = 0 \\
   f(1) = 1 \\
   f(n+1) = f(n) + f(n-1) & \text{for } n = 2, 3, \ldots
   \end{cases}
   $$
   Write a recursive function to calculate these numbers.

4. A palindrome is a word that is spelled the same backward and forward, like "noon" and "redivider". Recursively, a word is a palindrome if the first and last letters are the same and the middle is a palindrome.

   The following are functions that take a string argument and return the first, last, and middle letters:
   ```ocaml
   let first_char word = word.[0]
   let last_char word =
     let len = String.length word - 1 in
     word.[len]
   let middle word =
     let len = String.length word - 2 in
     String.sub word 1 len
   ```
   1. Enter these functions into the toplevel and test them out. What happens if you call `middle` with a string with two letters? One letter? What about the empty string `""`?
   2. Write a function called `is_palindrome` that takes a string argument and returns `true` if it is a palindrome and `false` otherwise.

5. The greatest common divisor (GCD) of $a$ and $b$ is the largest number that divides both of them with no remainder.

   One way to find the GCD of two numbers is Euclid's algorithm, which is based on the observation that if $r$ is the remainder when $a$ is divided by $b$, then $\gcd(a, b) = \gcd(b, r)$. As a base case, we can consider $\gcd(a, 0) = a$.

   Write a function called `gcd` that takes parameters `a` and `b` and returns their greatest common divisor.

   If you need help, see [http://en.wikipedia.org/wiki/Euclidean_algorithm](http://en.wikipedia.org/wiki/Euclidean_algorithm).
