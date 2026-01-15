## Chapter 2: Algebra

*Algebraic Data Types and some curious analogies*

In this chapter, we will deepen our understanding of OCaml's type system by working through type inference examples by hand. Then we will explore algebraic data types---a cornerstone of functional programming that allows us to define rich, structured data. Along the way, we will discover a surprising and beautiful connection between these types and ordinary polynomials from high-school algebra.

### 2.1 A Glimpse at Type Inference

For a refresher, let us apply the type inference rules introduced in Chapter 1 to some simple examples. We will start with the identity function `fun x -> x`---perhaps the simplest possible function, yet one that reveals important aspects of polymorphism. In the derivations below, $[?]$ means "dunno yet" (type unknown).

We begin with an incomplete derivation:

$$
\frac{[?]}{\texttt{fun x -> x} : [?]}
$$

Using the $\rightarrow$ introduction rule, we need to derive the body `x` assuming `x` has some type $a$:

$$
\frac{\frac{\,}{\texttt{x} : a}^x}{\texttt{fun x -> x} : [?] \rightarrow [?]}
$$

The premise $\frac{\,}{\texttt{x} : a}^x$ matches the pattern for hypothetical derivations since $e = \texttt{x}$. Since the body `x` has type $a$ (from our assumption), and the parameter `x` also has type $a$, we conclude:

$$
\frac{\frac{\,}{\texttt{x} : a}^x}{\texttt{fun x -> x} : a \rightarrow a}
$$

Because $a$ is arbitrary (we made no assumptions constraining it), OCaml introduces a *type variable* `'a` to represent it. This is how polymorphism emerges naturally from the inference process---the identity function can work with values of any type:

```ocaml
# fun x -> x;;
- : 'a -> 'a = <fun>
```

#### A More Complex Example

Now let us try something that will constrain the types more: `fun x -> x+1`. This is the same as `fun x -> ((+) x) 1` (try it in OCaml to verify!). The addition operator forces specific types upon us.

We will use the notation $[?\alpha]$ to mean "type unknown yet, but the same as in other places marked $[?\alpha]$." This notation helps us track how constraints propagate through the derivation.

Starting the derivation and applying $\rightarrow$ introduction:

$$
\frac{\frac{[?]}{\texttt{((+) x) 1} : [?\alpha]}}{\texttt{fun x -> ((+) x) 1} : [?] \rightarrow [?\alpha]}
$$

Applying $\rightarrow$ elimination (function application) to `((+) x) 1`:

$$
\frac{\frac{\frac{[?]}{\texttt{(+) x} : [?\beta] \rightarrow [?\alpha]} \quad \frac{[?]}{\texttt{1} : [?\beta]}}{\texttt{((+) x) 1} : [?\alpha]}}{\texttt{fun x -> ((+) x) 1} : [?] \rightarrow [?\alpha]}
$$

We know that `1 : int`, so $[?\beta] = \texttt{int}$:

$$
\frac{\frac{\frac{[?]}{\texttt{(+) x} : \texttt{int} \rightarrow [?\alpha]} \quad \frac{\,}{\texttt{1} : \texttt{int}}^{\text{(constant)}}}{\texttt{((+) x) 1} : [?\alpha]}}{\texttt{fun x -> ((+) x) 1} : [?] \rightarrow [?\alpha]}
$$

Applying function application again to `(+) x`:

$$
\frac{\frac{\frac{\frac{[?]}{\texttt{(+)} : [?\gamma] \rightarrow \texttt{int} \rightarrow [?\alpha]} \quad \frac{[?]}{\texttt{x} : [?\gamma]}}{\texttt{(+) x} : \texttt{int} \rightarrow [?\alpha]} \quad \frac{\,}{\texttt{1} : \texttt{int}}^{\text{(constant)}}}{\texttt{((+) x) 1} : [?\alpha]}}{\texttt{fun x -> ((+) x) 1} : [?\gamma] \rightarrow [?\alpha]}
$$

Since `(+) : int -> int -> int`, we have $[?\gamma] = \texttt{int}$ and $[?\alpha] = \texttt{int}$:

$$
\frac{\frac{\frac{\frac{\,}{\texttt{(+)} : \texttt{int} \rightarrow \texttt{int} \rightarrow \texttt{int}}^{\text{(constant)}} \quad \frac{\,}{\texttt{x} : \texttt{int}}^x}{\texttt{(+) x} : \texttt{int} \rightarrow \texttt{int}} \quad \frac{\,}{\texttt{1} : \texttt{int}}^{\text{(constant)}}}{\texttt{((+) x) 1} : \texttt{int}}}{\texttt{fun x -> ((+) x) 1} : \texttt{int} \rightarrow \texttt{int}}
$$

#### Curried Form

When there are several arrows "on the same depth" in a function type, it means that the function returns a function. For example, `(+) : int -> int -> int` is just a shorthand for `(+) : int -> (int -> int)`. The arrow associates to the right, so we can omit the parentheses.

This is very different from:

$$
\texttt{fun f -> (f 1) + 1} : (\texttt{int} \rightarrow \texttt{int}) \rightarrow \texttt{int}
$$

In the first case, `(+)` is a function that takes an integer and returns a function from integers to integers. In the second case, we have a function that takes a function as an argument---a *higher-order function*. The parentheses around `int -> int` are essential here; without them, the meaning would be completely different.

This style of defining multi-argument functions, where each function takes one argument and returns another function expecting the remaining arguments, is called *curried form* (named after logician Haskell Curry). It enables a powerful technique called *partial application*.

For example, instead of writing `(fun x -> x+1)`, we can simply write `((+) 1)`. Here we apply `(+)` to just one argument, getting back a function that adds 1 to its input. What expanded form does `((+) 1)` correspond to exactly (computationally)?

*Think about it before reading on...*

It corresponds to `fun y -> 1 + y`. We have "baked in" the first argument, and the resulting function waits for the second.

We will become more familiar with functions returning functions when we study the *lambda calculus* in a later chapter.

### 2.2 Algebraic Data Types

In Chapter 1, we learned about the `unit` type and variant types like:

```ocaml
type int_string_choice = A of int | B of string
```

We also covered tuple types, record types, and type definitions. Now let us explore these concepts more deeply, building up to the powerful notion of *algebraic data types*.

#### Variants Without Arguments

Variants do not have to carry arguments. Instead of writing `A of unit`, we can simply use `A`. This is more convenient and idiomatic:

```ocaml
type color = Red | Green | Blue
```

This defines a type with exactly three possible values---no more, no less. The compiler knows this, which enables exhaustive pattern matching checks.

**A subtle point about OCaml:** In OCaml, variants take multiple arguments rather than taking tuples as arguments. This means `A of int * string` is different from `A of (int * string)`. The first takes two separate arguments, while the second takes a single tuple argument. This distinction is usually not important---until you get bitten by it in some corner case! For most purposes, you can ignore it.

#### Recursive Type Definitions

Here is where things get really interesting: type definitions can be recursive! This allows us to define data structures of arbitrary size using a finite definition:

```ocaml
type int_list = Empty | Cons of int * int_list
```

Let us see what values inhabit `int_list`. The definition tells us there are two ways to build an `int_list`:
- `Empty` represents the empty list---a list with no elements
- `Cons (5, Empty)` is a list containing just 5
- `Cons (5, Cons (7, Cons (13, Empty)))` is a list containing 5, 7, and 13

Notice how `Cons` takes an integer and another `int_list`, allowing us to chain together as many elements as we like. This recursive structure is the essence of how functional languages represent unbounded data.

The built-in type `bool` can be viewed as if it were defined as `type bool = true | false`---just a variant with two constructors. Similarly, `int` can be thought of as a very large variant: `type int = 0 | -1 | 1 | -2 | 2 | ...` (though of course the compiler implements it more efficiently!)

#### Parametric Type Definitions

Our `int_list` type only works with integers. But what if we want a list of strings? Or a list of booleans? We would have to define separate types for each, duplicating the same structure.

Type definitions can be *parametric* with respect to the types of their components. This allows us to define generic data structures that work with any element type. For example, a list of elements of arbitrary type:

```ocaml
type 'elem list = Empty | Cons of 'elem * 'elem list
```

The `'elem` is a *type parameter*---a placeholder that gets filled in when we use the type. We can have a `string list`, an `int list`, or even an `int list list` (a list of lists of integers).

Several conventions and syntax rules apply to parametric types:

- Type variables must start with `'`, but since OCaml will not remember the names we give, it is customary to use the names OCaml uses: `'a`, `'b`, `'c`, `'d`, etc.

- The OCaml syntax places the type parameter before the type name, mimicking English word order. A silly example that reads almost like English:
  ```ocaml
  type 'white_color dog = Dog of 'white_color
  ```

  This defines a "white-color dog" type---the syntax reads naturally!

- With multiple parameters, OCaml uses parentheses:
  ```ocaml
  type ('a, 'b) choice = Left of 'a | Right of 'b
  ```

  Compare this to F# syntax: `type choice<'a,'b> = Left of 'a | Right of 'b`

  And Haskell syntax: `data Choice a b = Left a | Right b`

  Different languages have different conventions, but the underlying concept is the same.

### 2.3 Syntactic Bread and Sugar

OCaml provides various syntactic conveniences---sometimes called *syntactic sugar*---that make code more pleasant to write and read. Let us survey the most important ones.

#### Constructor Naming

Names of variants, called *constructors*, must start with a capital letter. If we wanted to define our own booleans, we would write:

```ocaml
type my_bool = True | False
```

Only constructors and module names can start with capital letters in OCaml. Everything else (values, functions, type names) must start with a lowercase letter. This convention makes it easy to distinguish constructors at a glance.

*Modules* are organizational units (like "shelves") containing related values. For example, the `List` module provides operations on lists, including `List.map` and `List.filter`. We will learn more about modules in later chapters.

#### Accessing Record Fields

Did we mention that we can use dot notation to access record fields? The syntax `record.field` extracts a field value. For example, if we have `let person = {name="Alice"; age=30}`, we can write `person.name` to get `"Alice"`.

#### Function Definition Shortcuts

Several syntactic shortcuts make function definitions more concise. These are worth memorizing, as you will see them constantly in OCaml code:

- `fun x y -> e` stands for `fun x -> fun y -> e`. Note that `fun x -> fun y -> e` parses as `fun x -> (fun y -> e)`. This shorthand aligns with curried form---we can write multi-argument functions without nesting `fun` expressions.

- `function A x -> e1 | B y -> e2` stands for `fun p -> match p with A x -> e1 | B y -> e2`. The general form is: `function PATTERN-MATCHING` stands for `fun v -> match v with PATTERN-MATCHING`. This is handy when you want to immediately pattern-match on a function's argument.

- `let f ARGS = e` is a shorthand for `let f = fun ARGS -> e`. This is probably the most common way to define functions in practice.

### 2.4 Pattern Matching

Pattern matching is one of the most powerful features of OCaml and similar languages. It lets us examine the structure of data and extract components in a single, elegant construct.

Recall that we introduced `fst` and `snd` as means to access elements of a pair. But what about larger tuples? There is no built-in `thd` for the third element. The fundamental way to access any tuple---or any algebraic data type---uses the `match` construct. In fact, `fst` and `snd` can easily be defined using pattern matching:

```ocaml
let fst = fun p -> match p with (a, b) -> a
let snd = fun p -> match p with (a, b) -> b
```

The pattern `(a, b)` *destructures* the pair, binding its first component to `a` and its second to `b`. We then return whichever component we want.

#### Matching on Records

Pattern matching also works with records, letting us extract multiple fields at once:

```ocaml
type person = {name: string; surname: string; age: int}

let greet_person () =
  match {name="Walker"; surname="Johnnie"; age=207}
  with {name=n; surname=sn; age=a} -> "Hi " ^ sn ^ "!"
```

Here we match against a record pattern, binding each field to a variable. Note that we bind `name` to `n`, `surname` to `sn`, and `age` to `a`---then use `sn` in the greeting.

#### Understanding Patterns

The left-hand sides of `->` in `match` expressions are called **patterns**. Patterns describe the structure of values we want to match against. They can include:
- Constants (like `1`, `"hello"`, or `true`)
- Variables (which bind to the matched value)
- Constructors (like `None`, `Some x`, or `Cons (h, t)`)
- Tuples and records
- Nested combinations of all the above

Patterns can be nested to arbitrary depth, allowing us to match complex structures in one go:

```ocaml
match Some (5, 7) with
| None -> "sum: nothing"
| Some (x, y) -> "sum: " ^ string_of_int (x+y)
```

Here `Some (x, y)` is a nested pattern: we match `Some` of *something*, and that something must be a pair, whose components we bind to `x` and `y`.

#### Simple Patterns and Wildcards

A pattern can simply bind the entire value without destructuring. Writing `match f x with v -> ...` is the same as `let v = f x in ...`. This is occasionally useful when you want the syntax of `match` but do not need to take the value apart.

When we do not need a value in a pattern, it is good practice to use the underscore `_`, which is a *wildcard*. The wildcard matches anything but does not bind it to a name. This signals to the reader (and the compiler) that we are intentionally ignoring that part:

```ocaml
let fst (a, _) = a
let snd (_, b) = b
```

Using `_` instead of an unused variable name avoids compiler warnings about unused bindings.

#### Pattern Linearity

A variable can only appear once in a pattern. This property is called *linearity*. You might think this is a limitation---what if we want to check that two parts of a structure are equal? We cannot write `(x, x)` to match pairs with equal components.

However, we can add conditions to patterns using `when`, so linearity is not really a limitation in practice:

```ocaml
let describe_point p =
  match p with
  | (x, y) when x = y -> "diag"
  | _ -> "off-diag"
```

The `when` clause acts as a guard: the pattern matches only if both the structure matches *and* the condition is true.

Here is a more elaborate example showing how to implement a comparison function:

```ocaml
let compare a b = match a, b with
  | (x, y) when x < y -> -1
  | (x, y) when x = y -> 0
  | _ -> 1
```

Notice how we match against the tuple `(a, b)` in different ways, using guards to distinguish the cases.

#### Partial Record Patterns

We can skip unused fields of a record in a pattern. Only the fields we care about need to be mentioned. This keeps patterns concise and means we do not have to update every pattern when we add a new field to a record type.

#### Or-Patterns

We can compress patterns by using `|` inside a single pattern to match multiple alternatives. This is different from having multiple pattern clauses---it lets us share a single right-hand side for several patterns:

```ocaml
type month =
  | Jan | Feb | Mar | Apr | May | Jun
  | Jul | Aug | Sep | Oct | Nov | Dec

type weekday = Mon | Tue | Wed | Thu | Fri | Sat | Sun

type date =
  {year: int; month: month; day: int; weekday: weekday}

let day =
  {year = 2012; month = Feb; day = 14; weekday = Wed};;

match day with
  | {weekday = Sat | Sun; _} -> "Weekend!"
  | _ -> "Work day"
```

The pattern `Sat | Sun` matches either `Sat` or `Sun`. This is much cleaner than writing two separate clauses with the same right-hand side.

#### Named Patterns with `as`

Sometimes we want to both destructure a value *and* keep a reference to the whole thing (or some intermediate part). We use `(pattern as v)` to name a nested pattern, binding the matched value to `v`:

```
match day with
  | {weekday = (Mon | Tue | Wed | Thu | Fri as wday); _}
      when not (day.month = Dec && day.day = 24) ->
    Some (work (get_plan wday))
  | _ -> None
```

This example demonstrates several features working together:

- An or-pattern matches any weekday from Monday to Friday
- The `as wday` clause binds the matched weekday to the variable `wday`
- A `when` guard checks that it is not Christmas Eve
- The bound variable `wday` is then used in the expression `get_plan wday`

This combination of features makes OCaml's pattern matching remarkably expressive.

### 2.5 Interpreting Algebraic Data Types as Polynomials

Now we come to one of the most delightful aspects of algebraic data types: they really are *algebraic* in a precise mathematical sense. Let us explore a curious analogy between types and polynomials that turns out to be surprisingly deep.

The translation from types to mathematical expressions works as follows:

- Replace `|` (variant choice) with $+$ (addition)
- Replace `*` (tuple product) with $\times$ (multiplication)
- Treat record types as tuple types (erasing field names and translating `;` as $\times$)

We also need translations for some special types:

- The **void type** (a type with no constructors, hence no values):
  ```ocaml
  type void
  ```
  (Yes, this is its complete definition, with no `= something` part.) Since no values can be constructed, it represents emptiness---translate it as $0$.

- The **unit type** has exactly one value, so translate it as $1$. Since variants without arguments behave like variants `of unit`, translate them as $1$ as well.

- The **bool type** has exactly two values (`true` and `false`), so translate it as $2$.

- Types like `int`, `string`, `float`, and type parameters are treated as variables. We do not care about their exact number of values; we just give them symbolic names like $x$, $y$, etc.

- Defined types translate according to their definitions (substituting variables as necessary).

Give a name to the type being defined (representing a function of the introduced variables). Now interpret the result as an ordinary numeric polynomial! (Or a "rational function" if recursively defined.)

This might seem like a mere curiosity, but it leads to real insights. Let us have some fun with it!

#### Example: Date Type

```ocaml
type date = {year: int; month: int; day: int}
```

A date is a record with three `int` fields. Translating to a polynomial (using $x$ for `int`):

$$D = x \times x \times x = x^3$$

The cube makes sense: a date is essentially a triple of integers.

#### Example: Option Type

The built-in option type is defined as:

```
type 'a option = None | Some of 'a
```

Translating (using $x$ for the type parameter `'a`):

$$O = 1 + x$$

This reads as: an option is either nothing (1) or something of type $x$. The polynomial $1 + x$ is beautifully simple!

#### Example: List Type

```ocaml
type 'a my_list = Empty | Cons of 'a * 'a my_list
```

Translating (where $L$ represents the list type itself, and $x$ represents the element type):

$$L = 1 + x \cdot L$$

This is a recursive equation! A list is either empty ($1$) or an element times another list ($x \cdot L$). If you solve this equation algebraically, you get $L = \frac{1}{1-x} = 1 + x + x^2 + x^3 + \ldots$, which corresponds to: a list is either empty, or has one element, or has two elements, etc.

#### Example: Binary Tree Type

```ocaml
type btree = Tip | Node of int * btree * btree
```

Translating:

$$T = 1 + x \cdot T \cdot T = 1 + x \cdot T^2$$

A binary tree is either a tip ($1$) or a node containing a value and two subtrees ($x \cdot T^2$).

#### Type Isomorphisms

Here is the remarkable payoff: when translations of two types are equal according to the laws of high-school algebra, the types are *isomorphic*. This means there exist bijective (one-to-one and onto) functions between them---you can convert from one type to the other and back without losing any information.

Let us play with the binary tree polynomial and see where algebra takes us:

$$
\begin{aligned}
T &= 1 + x \cdot T^2 \\
  &= 1 + x \cdot T + x^2 \cdot T^3 \\
  &= 1 + x + x^2 \cdot T^2 + x^2 \cdot T^3 \\
  &= 1 + x + x^2 \cdot T^2 \cdot (1 + T) \\
  &= 1 + x \cdot (1 + x \cdot T^2 \cdot (1 + T))
\end{aligned}
$$

Each step uses standard algebraic manipulations: substituting $T = 1 + xT^2$, expanding, factoring, and rearranging. The result is a different but algebraically equivalent expression.

Now let us translate this resulting expression back to a type:

```ocaml
type repr =
  (int * (int * btree * btree * btree option) option) option
```

Reading the polynomial $1 + x \cdot (1 + x \cdot T^2 \cdot (1 + T))$ from outside in: we have an option (the outermost $1 + \ldots$), whose `Some` case contains an `int` times another option, and so on.

The challenge is to find isomorphism functions with signatures:

```
val iso1 : btree -> repr
val iso2 : repr -> btree
```

These functions should satisfy: for all trees `t`, `iso2 (iso1 t) = t`, and for all representations `r`, `iso1 (iso2 r) = r`. Can you write them?

#### My First (Failed) Attempt

Here is my first attempt, trying to guess the pattern directly:

```
# let iso1 (t : btree) : repr =
  match t with
    | Tip -> None
    | Node (x, Tip, Tip) -> Some (x, None)
    | Node (x, Node (y, t1, t2), Tip) ->
      Some (x, Some (y, t1, t2, None))
    | Node (x, Node (y, t1, t2), t3) ->
      Some (x, Some (y, t1, t2, Some t3));;

Warning 8: this pattern-matching is not exhaustive.
Here is an example of a value that is not matched:
Node (_, Tip, Node (_, _, _))
```

I forgot about one case! The case `Node (_, Tip, Node (_, _, _))`---a node with an empty left subtree and non-empty right subtree---was not covered. It seems difficult to guess the solution directly when trying to map the complex final form all at once.

Have you found it on your first try? If so, congratulations! Most people do not. This illustrates an important principle: complex transformations are easier to get right when broken into smaller steps.

#### Breaking Down the Problem

Let us divide the task into smaller steps corresponding to intermediate points in the polynomial transformation. Instead of jumping from $T = 1 + xT^2$ directly to the final form, we will introduce intermediate types for each algebraic step:

```ocaml
type ('a, 'b) choice = Left of 'a | Right of 'b

type interm1 =
  ((int * btree, int * int * btree * btree * btree) choice)
  option

type interm2 =
  ((int, int * int * btree * btree * btree option) choice)
  option
```

Now we can define each step:

```ocaml
let step1r (t : btree) : interm1 =
  match t with
    | Tip -> None
    | Node (x, t1, Tip) -> Some (Left (x, t1))
    | Node (x, t1, Node (y, t2, t3)) ->
      Some (Right (x, y, t1, t2, t3))

let step2r (r : interm1) : interm2 =
  match r with
    | None -> None
    | Some (Left (x, Tip)) -> Some (Left x)
    | Some (Left (x, Node (y, t1, t2))) ->
      Some (Right (x, y, t1, t2, None))
    | Some (Right (x, y, t1, t2, t3)) ->
      Some (Right (x, y, t1, t2, Some t3))

let step3r (r : interm2) : repr =
  match r with
    | None -> None
    | Some (Left x) -> Some (x, None)
    | Some (Right (x, y, t1, t2, t3opt)) ->
      Some (x, Some (y, t1, t2, t3opt))

let iso1 (t : btree) : repr =
  step3r (step2r (step1r t))
```

Each step function handles one small transformation, and the compiler verifies that our pattern matching is exhaustive. No more missed cases!

**Exercise:** Define `step1l`, `step2l`, `step3l`, and `iso2`.

*Hint:* Now it is straightforward---each step is simply the inverse of its corresponding forward step. The left-going functions undo what the right-going functions do.

#### Take-Home Lessons

This exploration of type isomorphisms teaches us two valuable principles:

1. **Design for validity:** Try to define data structures so that only meaningful information can be represented---as long as it does not overcomplicate the data structures. Avoid catch-all clauses when defining functions. The compiler will then tell you if you have forgotten about a case. The exhaustiveness checker is your friend.

2. **Divide and conquer:** Break solutions into small steps so that each step can be easily understood and verified. When I tried to write `iso1` directly, I made a mistake. When I broke it into three simple steps, each step was obviously correct, and composing them gave the right answer.

### 2.6 Differentiating Algebraic Data Types

Of course, you might object that the pompous title is wrong---we will differentiate the translated polynomials, not the types themselves. Fair enough! But what sense does differentiating a type's polynomial make?

It turns out that taking the partial derivative of a polynomial (translated from a data type), when translated back, gives a type representing a "one-hole context"---a data structure with one piece missing. This missing piece corresponds to the variable with respect to which we differentiated. The derivative tells us: "Here are all the ways to point at one element of this type."

#### Example: Differentiating the Date Type

Let us start with our familiar date type:

```ocaml
type date = {year: int; month: int; day: int}
```

The translation and its derivative:

$$
\begin{aligned}
D &= x \cdot x \cdot x = x^3 \\
\frac{\partial D}{\partial x} &= 3x^2 = x \cdot x + x \cdot x + x \cdot x
\end{aligned}
$$

We could have left it as $3 \cdot x \cdot x$, but expanding it as a sum shows the structure more clearly. The derivative $3x^2$ says: there are three ways to "point at" an `int` in a date, and each way leaves two other `int`s behind.

Translating the expanded form back to a type:

```ocaml
type date_deriv =
  Year of int * int | Month of int * int | Day of int * int
```

Each variant represents a "hole" at a different position:
- `Year (m, d)` means the year field is the hole (and we have the month `m` and day `d`)
- `Month (y, d)` means the month field is the hole (and we have year `y` and day `d`)
- `Day (y, m)` means the day field is the hole

Now we can define functions to introduce and eliminate this derivative type:

```ocaml
let date_deriv {year=y; month=m; day=d} =
  [Year (m, d); Month (y, d); Day (y, m)]

let date_integr n = function
  | Year (m, d) -> {year=n; month=m; day=d}
  | Month (y, d) -> {year=y; month=n; day=d}
  | Day (y, m) -> {year=y; month=m; day=n}
;;

List.map (date_integr 7)
  (date_deriv {year=2012; month=2; day=14})
```

The `date_deriv` function produces all contexts (one for each field)---it "differentiates" a date into a list of one-hole contexts. The `date_integr` function fills in a hole with a new value---it "integrates" by putting a value back into the context. Notice how the naming follows the calculus analogy!

The example above takes the date February 14, 2012, produces three contexts (one for each field), and then fills each hole with the number 7, producing three modified dates.

#### Example: Differentiating Binary Trees

Now let us tackle the more challenging case of binary trees:

```ocaml
type btree = Tip | Node of int * btree * btree
```

The translation and differentiation:

$$
\begin{aligned}
T &= 1 + x \cdot T^2 \\
\frac{\partial T}{\partial x} &= 0 + T^2 + 2 \cdot x \cdot T \cdot \frac{\partial T}{\partial x} = T \cdot T + 2 \cdot x \cdot T \cdot \frac{\partial T}{\partial x}
\end{aligned}
$$

Something interesting happened: the derivative is recursive! It refers to itself via $\frac{\partial T}{\partial x}$. This makes perfect sense when you think about it:

- $T \cdot T$ represents pointing at the root: the hole is at the current node, and we have the two subtrees.
- $2 \cdot x \cdot T \cdot \frac{\partial T}{\partial x}$ represents pointing deeper in the tree: we choose left or right (the factor of 2), remember the current node's value ($x$), keep the other subtree ($T$), and then have a context in the chosen subtree ($\frac{\partial T}{\partial x}$).

Instead of translating $2$ as `bool`, we introduce a more descriptive type to make the code clearer:

```ocaml
type btree_dir = LeftBranch | RightBranch

type btree_deriv =
  | Here of btree * btree
  | Below of btree_dir * int * btree * btree_deriv
```

The `Here` constructor means the hole is at the current position, and we have the left and right subtrees. The `Below` constructor means we go down one level, remembering which direction we went, the value at the node we passed, and the subtree we did not enter.

(You might someday hear about *zippers*---they are "inverted" relative to our type. In a zipper, the hole comes first, and the context trails behind. Both representations are useful in different situations.)

**Exercise:** Write a function that takes a number and a `btree_deriv`, and builds a `btree` by putting the number into the "hole" in `btree_deriv`.

<details>
<summary>Solution</summary>

The integration function fills the hole with a value. It must be recursive because the derivative type is recursive---we may need to descend through multiple `Below` constructors before reaching the `Here` where the hole actually is:

```ocaml
let rec btree_integr n = function
  | Here (ltree, rtree) -> Node (n, ltree, rtree)
  | Below (LeftBranch, m, rtree, deriv) ->
    Node (m, btree_integr n deriv, rtree)
  | Below (RightBranch, m, ltree, deriv) ->
    Node (m, ltree, btree_integr n deriv)
```

When we reach `Here`, we create a node with the new value `n` and the two subtrees. When we see `Below`, we reconstruct the node we passed through and recursively integrate into the appropriate subtree.

</details>

### 2.7 Exercises

#### Exercise 1: Designing Valid Data Structures

*Due to Yaron Minsky.*

This exercise practices the principle of "making invalid states unrepresentable." Consider a datatype to store internet connection information. The time `when_initiated` marks the start of connecting and is not needed after the connection is established (it is only used to decide whether to give up trying to connect). The ping information is available for established connections but not straight away.

```
type connectionstate = Connecting | Connected | Disconnected

type connectioninfo = {
  state : connectionstate;
  server : Inetaddr.t;
  lastpingtime : Time.t option;
  lastpingid : int option;
  sessionid : string option;
  wheninitiated : Time.t option;
  whendisconnected : Time.t option;
}
```

(The types `Time.t` and `Inetaddr.t` come from the *Core* library. You can replace them with `float` and `Unix.inet_addr`. Load the Unix library in the interactive toplevel with `#load "unix.cma";;`.)

The problem with this design is that it allows many nonsensical combinations: a `Connecting` state with ping information, a `Disconnected` state with a session ID, etc. The optional fields (all those `option` types) make it unclear which fields are valid in which states.

Rewrite the type definitions so that the datatype will contain only reasonable combinations of information. Use separate record types for each connection state, with only the fields that make sense for that state.

#### Exercise 2: Labeled and Optional Arguments

In OCaml, functions can have labeled arguments and optional arguments (parameters with default values that can be omitted). This exercise explores these features.

Labels can differ from the names of argument values:

```ocaml
let f ~meaningfulname:n = n + 1
let _ = f ~meaningfulname:5  (* We do not need the result so we ignore it. *)
```

When the label and value names are the same, the syntax is shorter:

```ocaml
let g ~pos ~len =
  StringLabels.sub "0123456789abcdefghijklmnopqrstuvwxyz" ~pos ~len

let () =  (* A nicer way to mark computations that return unit. *)
  let pos = Random.int 26 in
  let len = Random.int 10 in
  print_string (g ~pos ~len)
```

When some function arguments are optional, the function must take non-optional arguments after the last optional argument. Optional parameters with default values:

```ocaml
let h ?(len=1) pos = g ~pos ~len
let () = print_string (h 10)
```

Optional arguments are implemented as parameters of an option type. This allows checking whether the argument was provided:

```ocaml
let foo ?bar n =
  match bar with
    | None -> "Argument = " ^ string_of_int n
    | Some m -> "Sum = " ^ string_of_int (m + n)
```

We can use it in various ways:

```ocaml
let _ = foo 5
let _ = foo ~bar:5 7
```

We can also provide the option value directly:

```ocaml
let test_foo () =
  let bar = if Random.int 10 < 5 then None else Some 7 in
  foo ?bar 7
```

1. Observe the types that functions with labeled and optional arguments have. Come up with coding style guidelines for when to use labeled arguments. When might they improve readability? When might they be overkill?

2. Write a rectangle-drawing procedure that takes three optional arguments: left-upper corner, right-lower corner, and a width-height pair. It should draw a correct rectangle whenever two of the three arguments are given (since any two determine the third), and raise an exception otherwise. Load the graphics library with `#load "graphics.cma";;`. Use `invalid_arg`, `Graphics.open_graph`, and `Graphics.draw_rect`.

3. Write a function that takes an optional argument of arbitrary type and a function argument, and passes the optional argument to the function without inspecting it. This tests your understanding of how optional arguments work at the type level.

#### Exercise 3: Type Inference Practice

*From a past exam.*

These exercises help you internalize how type inference works. Try to work them out by hand before checking with the OCaml toplevel.

1. Give the (most general) types of the following expressions, either by guessing or by inferring by hand:
   1. `let double f y = f (f y) in fun g x -> double (g x)`
   2. `let rec tails l = match l with [] -> [] | x::xs -> xs::tails xs in fun l -> List.combine l (tails l)`

2. Give example expressions that have the following types (without using type constraints). There are many possible answers for each:
   1. `(int -> int) -> bool`
   2. `'a option -> 'a list`

#### Exercise 4: Types as Exponents

We have seen that algebraic data types can be related to analytic functions (the subset definable from polynomials via recursion)---by literally interpreting sum types (variant types) as sums and product types (tuple and record types) as products. We can extend this interpretation to function types by interpreting $a \rightarrow b$ as $b^a$ (i.e., $b$ to the power of $a$). Note that the $b^a$ notation is actually used to denote functions in set theory.

This interpretation makes sense: a function from a set with $a$ elements to a set with $b$ elements is choosing, for each of the $a$ inputs, one of $b$ outputs---giving $b^a$ possible functions.

1. Translate $a^{b + cd}$ and $a^b \cdot (a^c)^d$ into OCaml types, using any distinct types for $a, b, c, d$, and using `type ('a,'b) choice = Left of 'a | Right of 'b` for $+$. Write the bijection functions in both directions. Verify algebraically that $a^{b + cd} = a^b \cdot (a^c)^d$ using the laws of exponents.

2. Come up with a type `'t exp` that shares with the exponential function the following property: $\frac{\partial \exp(t)}{\partial t} = \exp(t)$, where we translate a derivative of a type as a context (i.e., the type with a "hole"), as in this chapter. In other words, the derivative of the type should be isomorphic to the type itself! Explain why your answer is correct. *Hint:* in computer science, our logarithms are mostly base 2.

*Further reading:* [Algebraic Type Systems - Combinatorial Species](http://bababadalgharaghtakamminarronnkonnbro.blogspot.com/2012/10/algebraic-type-systems-combinatorial.html)

#### Exercise 5 (Homework): Finding Contexts

Write a function `btree_deriv_at` that takes a predicate over integers (i.e., a function `f: int -> bool`) and a `btree`, and builds a `btree_deriv` whose "hole" is in the first position for which the predicate returns true. It should return a `btree_deriv option`, with `None` if the predicate does not hold for any node.

This function lets you "search" a tree and get back a context pointing to the found element. Think about what order you want to search in (pre-order, in-order, or post-order) and what "first" means in that context.
