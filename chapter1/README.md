## Chapter 1: Logic

*From logic rules to programming constructs*

### 1.1 In the Beginning there was Logos

Let's start by reviewing the logical connectives you may have encountered. What logical connectives do you know?

| $\top$ | $\bot$ | $\wedge$ | $\vee$ | $\rightarrow$ |
|---|---|---|---|---|
|   |   | $a \wedge b$ | $a \vee b$ | $a \rightarrow b$ |
| truth | falsehood | conjunction | disjunction | implication |
| "trivial" | "impossible" | $a$ and $b$ | $a$ or $b$ | $a$ gives $b$ |
|   | shouldn't get | got both | got at least one | given $a$, we get $b$ |

How can we define them? Think in terms of *derivation trees*:

$$
\frac{
\frac{\frac{\,}{\text{a premise}} \; \frac{\,}{\text{another premise}}}{\text{some fact}} \;
\frac{\frac{\,}{\text{this we have by default}}}{\text{another fact}}}
{\text{final conclusion}}
$$

We define connectives by providing rules for using them. For example, a rule $\frac{a \; b}{c}$ matches parts of the tree that have two premises, represented by variables $a$ and $b$, and have any conclusion, represented by variable $c$.

**Design principle:** Try to use only the connective you define in its definition.

### 1.2 Rules for Logical Connectives

**Introduction rules** say how to *produce* a connective.

**Elimination rules** say how to *use* it.

Text in parentheses is comments. Letters are variables that can stand for anything.

| Connective | Introduction Rules | Elimination Rules |
|------------|-------------------|-------------------|
| $\top$ | $\frac{}{\top}$ | doesn't have |
| $\bot$ | doesn't have | $\frac{\bot}{a}$ (i.e., anything) |
| $\wedge$ | $\frac{a \quad b}{a \wedge b}$ | $\frac{a \wedge b}{a}$ (take first) &nbsp; $\frac{a \wedge b}{b}$ (take second) |
| $\vee$ | $\frac{a}{a \vee b}$ (put first) &nbsp; $\frac{b}{a \vee b}$ (put second) | $\frac{a \vee b \quad \genfrac{}{}{0pt}{}{[a]^x}{\vdots \; c} \quad \genfrac{}{}{0pt}{}{[b]^y}{\vdots \; c}}{c}$ using $x, y$ |
| $\rightarrow$ | $\frac{\genfrac{}{}{0pt}{}{[a]^x}{\vdots \; b}}{a \rightarrow b}$ using $x$ | $\frac{a \rightarrow b \quad a}{b}$ |

#### Notation for Hypothetical Derivations

The notation $\genfrac{}{}{0pt}{}{[a]^x}{\vdots \; b}$ (sometimes written as a tree) matches any subtree that derives $b$ and can use $a$ as an assumption (marked with label $x$), even though $a$ might not otherwise be warranted.

For example, we can derive "sunny $\rightarrow$ happy" by showing that *assuming* it's sunny, we can derive happiness:

$$
\frac{\frac{\frac{\frac{\frac{\,}{\text{sunny}}^x}{\text{go outdoor}}}{\text{playing}}}{\text{happy}}}{\text{sunny} \rightarrow \text{happy}} \text{ using } x
$$

Such assumptions can only be used in the matched subtree! But they can be used several times. For example, if someone's mood is more difficult to influence:

$$
\frac{\frac{
  \frac{\frac{\frac{\,}{\text{sunny}}^x}{\text{go outdoor}}}{\text{playing}} \quad
  \frac{\frac{\,}{\text{sunny}}^x \quad \frac{\frac{\,}{\text{sunny}}^x}{\text{go outdoor}}}{\text{nice view}}
}{\text{happy}}}{\text{sunny} \rightarrow \text{happy}} \text{ using } x
$$

#### Reasoning by Cases

The elimination rule for disjunction represents **reasoning by cases**.

How can we use the fact that it is sunny $\vee$ cloudy (but not rainy)?

$$
\frac{
  \frac{\,}{\text{sunny} \vee \text{cloudy}}^{\text{forecast}} \quad
  \frac{\frac{\,}{\text{sunny}}^x}{\text{no-umbrella}} \quad
  \frac{\frac{\,}{\text{cloudy}}^y}{\text{no-umbrella}}
}{\text{no-umbrella}} \text{ using } x, y
$$

We know that it will be sunny or cloudy (by watching the weather forecast). If it will be sunny, we won't need an umbrella. If it will be cloudy, we won't need an umbrella. Therefore, we won't need an umbrella.

#### Reasoning by Induction

We need one more kind of rule to do serious math: **reasoning by induction** (somewhat similar to reasoning by cases). Example rule for induction on natural numbers:

$$
\frac{p(0) \quad \genfrac{}{}{0pt}{}{[p(x)]^x}{\vdots \; p(x+1)}}{p(n)} \text{ by induction, using } x
$$

We get property $p$ for any natural number $n$, provided we can:
1. Establish $p(0)$ (the base case)
2. Show that assuming $p(x)$ holds, we can derive $p(x+1)$ (the inductive step)

Here $x$ is a unique variable—we cannot substitute a particular number for it because we write "using $x$" on the side.

### 1.3 Logos was Programmed in OCaml

We now arrive at a remarkable connection between logic and programming—the **Curry-Howard correspondence** (also known as "propositions as types"). This deep correspondence shows that proofs in logic directly correspond to programs in typed programming languages!

The following table shows how logical connectives correspond to programming constructs:

| Logic | Type | Expression |
|-------|------|------------|
| $\top$ | `unit` | `()` |
| $\bot$ | `'a` | `raise` |
| $\wedge$ | `*` | `(,)` |
| $\vee$ | `|` | `match` |
| $\rightarrow$ | `->` | `fun` |
| induction | — | `rec` |

**Typing rules for OCaml constructs:**

- **Unit (truth):** $\frac{}{\texttt{()} : \texttt{unit}}$

- **Exception (falsehood):** $\frac{\text{oops!}}{\texttt{raise exn} : c}$ — can produce any type

- **Pair (conjunction):**
  - Introduction: $\frac{s : a \quad t : b}{(s, t) : a * b}$
  - Elimination: $\frac{p : a * b}{\texttt{fst}~p : a}$ and $\frac{p : a * b}{\texttt{snd}~p : b}$

- **Variant (disjunction):**
  - Introduction: $\frac{s : a}{\texttt{A}(s) : \texttt{A of}~a~|~\texttt{B of}~b}$
  - Elimination (match): given $t$ of variant type and branches for each case, produce result $c$

- **Function (implication):**
  - Introduction: $\frac{\genfrac{}{}{0pt}{}{[x : a]}{e : b}}{\texttt{fun}~x \to e : a \to b}$
  - Elimination (application): $\frac{f : a \to b \quad t : a}{f~t : b}$

- **Recursion (induction):** $\frac{\genfrac{}{}{0pt}{}{[x : a]}{e : a}}{\texttt{rec}~x = e : a}$

#### 1.3.1 Definitions

Writing out expressions and types repetitively is tedious: we need definitions.

**Type definitions** are written: `type ty =` some type.

- Writing `A(s) : A of a | B of b` in the table was cheating. Usually we have to define the type and then use it. For example, using `int` for $a$ and `string` for $b$:
  ```ocaml
  type int_string_choice = A of int | B of string
  ```
  This allows us to write `A(s) : int_string_choice`.

- Without the type definition, it is difficult to know what other variants there are when one *infers* (i.e., "guesses", computes) the type!

- In OCaml we can write `` `A(s) : [`A of a | `B of b] ``. With "`` ` ``" variants (polymorphic variants), OCaml does guess what other variants there are. These types are interesting, but we will not focus on them in this book.

- Tuple elements don't need labels because we always know at which position a tuple element stands. But having labels makes code more clear, so we can define a *record type*:
  ```ocaml
  type int_string_record = {a: int; b: string}
  ```
  and create its values: `{a = 7; b = "Mary"}`.

- We access the *fields* of records using the dot notation: `{a=7; b="Mary"}.b = "Mary"`.

#### 1.3.2 Expression Definitions

The recursive expression `rec x = e` in the table was cheating: `rec` (usually called `fix` in theory) cannot appear alone in OCaml! It must be part of a definition.

**Definitions for expressions** are introduced by rules a bit more complex:

$$
\frac{e_1 : a \quad \frac{[x : a]}{e_2 : b}}{\texttt{let } x = e_1 \texttt{ in } e_2 : b}
$$

(Note that this rule is the same as introducing and eliminating $\rightarrow$.)

For recursive definitions:

$$
\frac{\frac{[x : a]}{e_1 : a} \quad \frac{[x : a]}{e_2 : b}}{\texttt{let rec } x = e_1 \texttt{ in } e_2 : b}
$$

We will cover what is missing in the above rules when we discuss **polymorphism**.

#### 1.3.3 Scoping Rules

- **Type definitions** we have seen above are *global*: they need to be at the top-level (not nested in expressions), and they extend from the point they occur till the end of the source file or interactive session.

- **`let`-`in` definitions** for expressions: `let x = e1 in e2` are *local*—$x$ is only visible in $e_2$. But **`let` definitions** without `in` are global: placing `let x = e1` at the top-level makes $x$ visible from after $e_1$ till the end of the source file or interactive session.

- In the interactive session (toplevel/REPL), we mark the end of a top-level "sentence" with `;;`—this is unnecessary in source files.

#### 1.3.4 Operators

Operators like `+`, `*`, `<`, `=` are names of functions. Just like other names, you can use operator names for your own functions:

```ocaml
let (+:) a b = String.concat "" [a; b];;  (* Special way of defining *)
"Alpha" +: "Beta";;  (* but normal way of using operators *)
```

Notice the asymmetry: we use a *special* syntax for defining operators (with parentheses) but the *normal* infix syntax for using them.

Operators in OCaml are **not overloaded**. This means that every type needs its own set of operators:
- `+`, `*`, `/` work for integers
- `+.`, `*.`, `/.` work for floating point numbers

**Exception:** Comparisons `<`, `=`, etc. work for all values other than functions.

### 1.4 Exercises

Exercises from *Think OCaml: How to Think Like a Computer Scientist* by Nicholas Monje and Allen Downey.

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
