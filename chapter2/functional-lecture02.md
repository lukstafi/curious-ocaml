# Lecture 2: Algebra

Algebraic Data Types and some curious analogies

## 1 A Glimpse at Type Inference

For a refresher, let's try to use the rules we introduced last time on some 
simple examples. Starting with `fun x -> x`. $[?]$ will mean “dunno yet”.

$$ \begin{matrix}
  & \frac{[?]}{\text{{\texttt{fun x -> x}}} : [?]} & \text{use }
  \rightarrow \text{ introduction:}\\\\\\
  & \frac{\frac{\,}{\text{{\texttt{x}}} : a}
  \tiny{x}}{\text{{\texttt{fun x -> x}}} : [?] \rightarrow [?]}
  & \frac{\,}{\text{{\texttt{x}}} : a} \tiny{x} \text{ matches with }
{{{\frac{\,}{x : a} \tiny{x}} \atop {\text{\textbar}}} \atop {e : b}}
 \text{ since } e = \text{{\texttt{x}}}\\\\\\
  & \frac{\frac{\,}{\text{{\texttt{x}}} : a}
  \tiny{x}}{\text{{\texttt{fun x -> x}}} : a \rightarrow a} &
  \text{since } b = a \text{ because } x : a \text{ matched with } e : b
\end{matrix} $$

Because $a$ is arbitrary, OCaml puts a *type variable* `'a` for it:

```ocaml
# fun x -> x;;
- : 'a -> 'a = <fun>
```

Let's try `fun x -> x+1`, which is the same as `fun x -> ((+) x) 
1`(try it with OCaml/F#!). $[? \alpha]$ will mean “dunno yet, but the same as 
in other places with $[? \alpha]$”.

$$ \begin{matrix}
  & \frac{[?]}{\text{{\texttt{fun x -> ((+) x) 1}}} : [?]} &
  \text{use } \rightarrow \text{ introduction:}\\\\\\
  & \frac{\frac{[?]}{\text{{\texttt{((+) x) 1}}} : [?
  \alpha]}}{\text{{\texttt{fun x -> ((+) x) 1}}} : [?] 
\rightarrow [?
  \alpha]} & \text{use } \rightarrow \text{ elimination:}\\\\\\
  & \frac{\frac{\begin{array}{ll}
    \frac{[?]}{\text{{\texttt{(+) x}}} : [? \beta] \rightarrow [?
    \alpha]} & \frac{[?]}{\text{{\texttt{1}}} : [? \beta]}
  \end{array}}{\text{{\texttt{((+) x) 1}}} : [?
  \alpha]}}{\text{{\texttt{fun x -> ((+) x) 1}}} : [?] 
\rightarrow [?
  \alpha]} & \text{we know that \text{{\texttt{1}}}} :
  \text{{\texttt{int}}}\\\\\\
  & \frac{\frac{\begin{array}{ll}
    \frac{[?]}{\text{{\texttt{(+) x}}} :
    \text{{\texttt{int}}} \rightarrow [? \alpha]} &
    \frac{\,}{\text{{\texttt{1}}} : \text{{\texttt{int}}}}
    \tiny{\text{(constant)}}
  \end{array}}{\text{{\texttt{((+) x) 1}}} : [?
  \alpha]}}{\text{{\texttt{fun x -> ((+) x) 1}}} : [?] 
\rightarrow [?
  \alpha]} & \text{application again:}\\\\\\
  & \frac{\frac{\begin{array}{ll}
    \frac{\begin{array}{ll}
      \frac{[?]}{\text{{\texttt{(+)}}} : [? \gamma] \rightarrow
      \text{{\texttt{int}}} \rightarrow [? \alpha]} &
      \frac{[?]}{\text{{\texttt{x}}} : [? \gamma]}
    \end{array}}{\text{{\texttt{(+) x}}} :
    \text{{\texttt{int}}} \rightarrow [? \alpha]} &
    \frac{\,}{\text{{\texttt{1}}} : \text{{\texttt{int}}}}
    \tiny{\text{(constant)}}
  \end{array}}{\text{{\texttt{((+) x) 1}}} : [?
  \alpha]}}{\text{{\texttt{fun x -> ((+) x) 1}}} : [?] 
\rightarrow [?
  \alpha]} & \text{it's our \text{{\texttt{x}}}!}\\\\\\
  & \frac{\frac{\begin{array}{ll}
    \frac{\begin{array}{ll}
      \frac{[?]}{\text{{\texttt{(+)}}} : [? \gamma] \rightarrow
      \text{{\texttt{int}}} \rightarrow [? \alpha]} &
      \frac{\,}{\text{{\texttt{x}}} : [? \gamma]}
      \tiny{\text{{\texttt{x}}}}
    \end{array}}{\text{{\texttt{(+) x}}} :
    \text{{\texttt{int}}} \rightarrow [? \alpha]} &
    \frac{\,}{\text{{\texttt{1}}} : \text{{\texttt{int}}}}
    \tiny{\text{(constant)}}
  \end{array}}{\text{{\texttt{((+) x) 1}}} : [?
  \alpha]}}{\text{{\texttt{fun x -> ((+) x) 1}}} : [? \gamma]
  \rightarrow [? \alpha]} & \text{but \text{{\texttt{(+)}}}} :
  \text{{\texttt{int}}} \rightarrow \text{{\texttt{int}}}
  \rightarrow \text{{\texttt{int}}}\\\\\\
  & \frac{\frac{\begin{array}{ll}
    \frac{\begin{array}{ll}
      \frac{\,}{\text{{\texttt{(+)}}} : \text{{\texttt{int}}}
      \rightarrow \text{{\texttt{int}}} \rightarrow
      \text{{\texttt{int}}}} \tiny{\text{(constant)}} &
      \frac{\,}{\text{{\texttt{x}}} : \text{{\texttt{int}}}}
      \tiny{\text{{\texttt{x}}}}
    \end{array}}{\text{{\texttt{(+) x}}} :
    \text{{\texttt{int}}} \rightarrow \text{{\texttt{int}}}}
    & \frac{\,}{\text{{\texttt{1}}} : \text{{\texttt{int}}}}
    \tiny{\text{(constant)}}
  \end{array}}{\text{{\texttt{((+) x) 1}}} :
  \text{{\texttt{int}}}}}{\text{\text{{\texttt{fun x -> ((+) x)
  1}}}} : \text{{\texttt{int}}} \rightarrow
  \text{{\texttt{int}}}} &
\end{matrix} $$

### 1.1 Curried form

When there are several arrows “on the same depth” in a function type, it means 
that the function returns a function: e.g. $\text{{\texttt{(+)}}} : 
\text{{\texttt{int}}} \rightarrow \text{{\texttt{int}}} 
\rightarrow \text{{\texttt{int}}}$ is just a shorthand for 
$\text{{\texttt{(+)}}} : \text{{\texttt{int}}} \rightarrow 
\left( \text{{\texttt{int}}} \rightarrow 
\text{{\texttt{int}}} \right)$. It is very different from

$$ \text{{\texttt{fun f -> (f 1) + 1}}} : \left(
   \text{{\texttt{int}}} \rightarrow \text{{\texttt{int}}}
   \right) \rightarrow \text{{\texttt{int}}} $$

For addition, instead of `(fun x -> x+1)` we can write `((+) 1)`. What 
expanded form does `((+) 1)` correspond to exactly (computationally)?

We will get used to functions returning functions when learning about 
the *lambda calculus*.

## 2 Algebraic Data Types

* Last time we learned about the `unit` type, variant types like:

```ocaml
type int_string_choice = A of int | B of string
```

  and also tuple types, record types, and type definitions.
* Variants don't have to have arguments: instead of `A of unit` just use `A`.
  * In OCaml, variants take multiple arguments rather than taking tuples as 
    arguments: `A of int * string` is different than`A of (int * string)`. But 
    it's not important unless you get bitten by it.
* Type definitions can be recursive!

```ocaml
type int_list = Empty | Cons of int * int_list
```

  Let's see what we have in `int_list`:`Empty`, `Cons (5, Cons (7, Cons (13, 
  Empty)))`, etc.
* Type `bool` can be seen as `type bool = true | false`, type `int` can be 
  seen as a very large `type int = 0 | -1 | 1 | -2 | 2 | …`
* Type definitions can be *parametric* with respect to types of their 
  components (more on this in lecture about polymorphism), for example a list 
  elements of arbitrary type:

```ocaml
type 'elem list = Empty | Cons of 'elem * 'elem list
```
  * Type variables must start with ', but since OCaml will not remember the 
    names we give, it's customary to use the names OCaml uses: `'a`, `'b`, 
    `'c`, `'d`…
  * The syntax in OCaml is a bit strange: in F# we write 
    `list<'elem>`. OCaml syntax mimics English, silly example:

  ```
    type 'white_color dog = Dog of 'white_color
```
  * With multiple parameters:
    * OCaml:`type ('a, 'b) choice = Left of 'a | Right of 'b`
    * F#:`type choice<'a,'b> = Left of 'a | Right of 'b`
    * Haskell:`data Choice a b = Left a | Right b`

## 3 Syntactic Bread and Sugar

* Names of variants, called *constructors*, must start with capital letter – 
  so if we wanted to define our own booleans, it would be

```ocaml
type my_bool = True | False
```

  Only constructors and module names can start with capital letter.
  * *Modules* are “shelves” with values. For example, `List` has operations on 
    lists, like `List.map` and `List.filter`.
* Did I mention that we can use `record.field` to access a field?
* `fun x y -> e` stands for `fun x -> fun y -> e`, etc. – and of 
  course,`fun x -> fun y -> e` parses as `fun x -> (fun y -> 
  e)`
* `function A x -> e1 | B y -> e2` stands for `fun p -> match p 
  with A x -> e1 | B y -> e2`, etc.
  * the general form is: `function *PATTERN-MATCHING*` stands for`fun v -> 
    match v with *PATTERN-MATCHING*`
* `let f ARGS = e` is a shorthand for `let f = fun ARGS -> e`



## 4 Pattern Matching

* Recall that we introduced `fst` and `snd` as means to access elements of a 
  pair. But what about bigger tuples? The “basic” way of accessing any tuple 
  reuses the `match` construct. Functions `fst` and `snd` can easily be 
  defined!

```ocaml
let fst = fun p -> match p with (a, b) -> a
let snd = fun p -> match p with (a, b) -> b
```
* It also works with records:

```ocaml
type person = {name: string; surname: string; age: int}
match {name="Walker"; surname="Johnnie"; age=207}
with {name=n; surname=sn; age=a} -> "Hi "^sn^"!"
```
* The left-hand-sides of -> in `match` expressions are 
  called **patterns**.
* Patterns can be nested:

```ocaml
match Some (5, 7) with None -> "sum: nothing"
  | Some (x, y) -> "sum: " ^ string_of_int (x+y)
```
* A pattern can just match the whole value, without performing destructuring: 
  `match f x with v ->`… is the same as `let v = f x in` …
* When we do not need a value in a pattern, it is good practice to use the 
  underscore: `_` (which is not a variable!)

```ocaml
let fst (a,_) = a
let snd (_,b) = b
```
* A variable can only appear once in a pattern (it is called *linearity*).
* But we can add conditions to the patterns after `when`, so linearity is not 
  really a problem!

```ocaml
match p with (x, y) when x = y -> "diag" | _ -> "off-diag"
```

```ocaml
let compare a b = match a, b with
  | (x, y) when x < y -> -1
  | (x, y) when x = y -> 0
  | _ -> 1
```
* We can skip over unused fields of a record in a pattern.
* We can compress our patterns by using | inside a single pattern:

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
  | {weekday = Sat | Sun} -> "Weekend!"
  | _ -> "Work day"
```
* We use `(pattern **as** v)` to name a nested pattern:

```ocaml
match day with
  | {weekday = (Mon | Tue | Wed | Thu | Fri **as** wday)}
      when not (day.month = Dec && day.day = 24) ->
    Some (work (get_plan wday))
  | _ -> None
```

## 5 Interpreting Algebraic DTs as Polynomials

Let's do a peculiar translation: take a data type and replace | with $+$, * 
with $\times$, treating record types as tuple types (i.e. erasing field names 
and translationg ; as $\times$).

There is a special type for which we cannot build a value:

```ocaml
type void
```

(yes, it is its definition, no `= something` part). Translate it as $0$.

Translate the `unit` type as $1$. Since variants without arguments behave as 
variants `of unit`, translate them as $1$ as well. Translate `bool` as $2$.

Translate `int`, `string`, `float`, type parameters and other types of 
interest as variables. Translate defined types by their translations 
(substituting variables if necessary).

Give name to the type being defined (denoting a function of the variables 
introduced). Now interpret the result as ordinary numeric polynomial! (Or 
“rational function” if it is recursively defined.)

Let's have fun with it.

```ocaml
type date = {year: int; month: int; day: int}
```

$$ D = xxx = x^3 $$

```ocaml
type 'a option = None | Some of 'a   (* built-in type *)
```

$$ O = 1 + x $$

```ocaml
type 'a my_list = Empty | Cons of 'a * 'a my_list
```

$$ L = 1 + xL $$

```ocaml
type btree = Tip | Node of int * btree * btree
```

$$ T = 1 + xTT = 1 + xT^2 $$

When translations of two types are equal according to laws of high-school 
algebra, the types are *isomorphic*, that is, there exist 1-to-1 functions 
from one type to the other.

Let's play with the type of binary trees:

$$ \begin{matrix}
  T & = & 1 + xT^2 = 1 + xT + x^2 T^3 = 1 + x + x^2 T^2 + x^2 T^3 =\\\\\\
  & = & 1 + x + x^2 T^2  (1 + T) = 1 + x (1 + xT^2  (1 + T))
\end{matrix} $$

Now let's translate the resulting type:

```ocaml
type repr =
  (int * (int * btree * btree * btree option) option) option
```

Try to find the isomorphism functions `iso1` and `iso2`

```ocaml
val iso1 : btree -> repr
val iso2 : repr -> btree
```

i.e. functions such that for all trees `t`, `iso2 (iso1 t) = t`, and for all 
representations `r`, `iso1 (iso2 r) = r`.

My first failed attempt:

```ocaml
# let iso1 (t : btree) : repr =
  match t with
    | Tip -> None
    | Node (x, Tip, Tip) -> Some (x, None)
    | Node (x, Node (y, t1, t2), Tip) ->
      Some (x, Some (y, t1, t2, None))
    | Node (x, Node (y, t1, t2), t3) ->
      Some (x, Some (y, t1, t2, Some t3));;
            Characters 32-261: […]
Warning 8: this pattern-matching is not exhaustive.
Here is an example of a value that is not matched:
Node (_, Tip, Node (_, _, _))
```

I forgot about one case. It seems difficult to guess the solution, have you 
found it on your try?

Let's divide the task into smaller steps corresponding to selected 
intermediate points in the transformation of the polynomial:

```ocaml
type ('a, 'b) choice = Left of 'a | Right of 'b
type interm1 =
  ((int * btree, int * int * btree * btree * btree) choice)
  option
type interm2 =
  ((int, int * int * btree * btree * btree option) choice)
  option

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

Define `step1l`, `step2l`, `step3l`, and `iso2`. Hint: now it's trivial!

Take-home lessons:

* Try to define data structures so that only information that makes sense can 
  be represented – as long as it does not overcomplicate the data structures. 
  Avoid catch-all clauses when defining functions. The compiler will then tell 
  you if you have forgotten about a case.
* Divide solutions into small steps so that each step can be easily understood 
  and checked.

### 5.1 Differentiating Algebraic Data Types

Of course, you would say, the pompous title is wrong, we will differentiate 
the translated polynomials. But what sense does it make?

It turns out, that taking the partial derivative of a polynomial resulting 
from translating a data type, gives us, when translated back, a type 
representing how to change one occurrence of a value of type corresponding to 
the variable with respect to which we computed the partial derivative.

Take the “date” example:

```ocaml
type date = {year: int; month: int; day: int}
```

$$ \begin{matrix}
  D & = & xxx = x^3\\\\\\
  \frac{\partial D}{\partial x} & = & 3 x^2 = xx + xx + xx
\end{matrix} $$

(we could have left it at $3 xx$ as well). Now we construct the type:

```ocaml
type date_deriv =
  Year of int * int | Month of int * int | Day of int * int
```

Now we need to introduce and use (“eliminate”) the type `date_deriv`.

```ocaml
let date_deriv {year=y; month=m; day=d} =
  [Year (m, d); Month (y, d); Day (y, m)]

let date_integr n = function
  | Year (m, d) -> {year=n; month=m; day=d}
  | Month (y, d) -> {year=y; month=n; day=d}
  | Day (y, m) -> {year=y; month=m, day=n}
;;
List.map (date_integr 7)
  (date_deriv {year=2012; month=2; day=14})
```

Let's do now the more difficult case of binary trees:

```ocaml
type btree = Tip | Node of int * btree * btree
```

$$ \begin{matrix}
  T & = & 1 + xT^2\\\\\\
  \frac{\partial T}{\partial x} & = & 0 + T^2 + 2 xT \frac{\partial
  T}{\partial x} = TT + 2 xT \frac{\partial T}{\partial x}
\end{matrix} $$

(again, we could expand further into $\frac{\partial T}{\partial x} = TT + xT 
\frac{\partial T}{\partial x} + xT \frac{\partial T}{\partial x}$).

Instead of translating $2$ as `bool`, we will introduce new type for clarity:

```ocaml
type btree_dir = LeftBranch | RightBranch
type btree_deriv =
  | Here of btree * btree
  | Below of btree_dir * int * btree * btree_deriv
```

(You might someday hear about *zippers* – they are “inverted” w.r.t. our type, 
in zippers the hole comes first.)

Write a function that takes a number and a `btree_deriv`, and builds a `btree` 
by putting the number into the “hole” in `btree_deriv`.

Solution:

```ocaml
let rec btree_integr n =
  | Here (ltree, rtree) -> Node (n, ltree, rtree)
  | Below (LeftBranch, m, rtree) ->
    Node (m, btree_integr n ltree, rtree)
  | Below (RightBranch, m, ltree) ->
    Node (m, ltree, btree_integr n rtree)
```

## 6 Homework

Write a function `btree_deriv_at` that takes a predicate over integers (i.e. a 
function `f: int -> bool`), and a `btree`, and builds a `btree_deriv` 
whose “hole” is in the first position for which the predicate returns true. It 
should actually return a `btree_deriv option`, with `None` in case the 
predicate does not hold for any node.

*This homework is due for the class **after** the Computation class, i.e. for 
(before) the Functions class.*
