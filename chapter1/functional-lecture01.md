# Lecture 1: Logic

From logic rules to programming constructs

## 1 In the Beginning there was Logos

What logical connectives do you know?

|$\top$ | $\bot$ | $\wedge$ | $\vee$ | $\rightarrow$
|---|---|---|---|---
|   |   | $a \wedge b$ | $a \vee b$ | $a \rightarrow b$
| truth | falsehood | conjunction | disjunction | implication
| "trivial" | "impossible" | $a$ and $b$ | $a$ or $b$ | $a$ gives $b$
|   | shouldn't get | got both | got at least one | given $a$, we get $b$

How can we define them? Think in terms of *derivation trees*:

$$ \frac{\begin{array}{ll}
     \frac{\begin{array}{ll}
       \frac{\,}{\text{a premise}} & \frac{\,}{\text{another premise}}
     \end{array}}{\text{some fact}} & \frac{\frac{\,}{\text{this we have by
     default}}}{\text{another fact}}
   \end{array}}{\text{final conclusion}} $$

Define by providing rules for using the connectives: for example, a rule 
$\frac{\begin{array}{ll}   a & b \end{array}}{c}$ matches parts of the tree 
that have two premises, represented by variables $a$ and $b$, and have any 
conclusion, represented by variable $c$.

Try to use only the connective you define in its definition.# 2 Rules for Logical Connectives

Introduction rules say how to produce a connective.

Elimination rules say how to use it.

Text in parentheses is comments. Letters are variables: stand for anything.

<table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td></td>
    <td style="text-align: left">Introduction Rules</td>
    <td>Elimination Rules</td>
  </tr><tr>
    <td></td>
    <td style="text-align: center"></td>
    <td>doesn't have</td>
  </tr><tr>
    <td></td>
    <td>doesn't have</td>
    <td style="text-align: center"> </td>
  </tr><tr>
    <td></td>
    <td style="text-align: center"></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td style="text-align: center"></td>
  </tr><tr>
    <td></td>
    <td style="text-align: center"></td>
    <td style="text-align: center"></td>
  </tr></tbody>
</table>

Notations

$$ {{{\frac{\,}{a} \tiny{x}} \atop {\text{\textbar}}} \atop {b}} \text{, \ \ or \ \ }
   {{{\frac{\,}{a} \tiny{x}} \atop {\text{\textbar}}} \atop {c}} $$

match any subtree that derives $b$ (or $c$) and can use $a$ (by assumption 
$\frac{\,}{a} \tiny{x}$) although otherwise $a$ might not be warranted. 
For example:

$$ \frac{\frac{\frac{\frac{\frac{\,}{\text{sunny}} \small{x}}{\text{go
   outdoor}}}{\text{playing}}}{\text{happy}}}{\text{sunny} \rightarrow
   \text{happy}} \small{\text{ using } x} $$

Such assumption can only be used in the matched subtree! But it can be used 
several times, e.g. if someone's mood is more difficult to influence:

$$ \frac{\frac{\begin{array}{ll}
     \frac{\frac{\frac{\,}{\text{sunny}} \small{x}}{\text{go
     outdoor}}}{\text{playing}} & \frac{\begin{array}{ll}
       \frac{\,}{\text{sunny}} \small{x} & \frac{\frac{\,}{\text{sunny}}
       \small{x}}{\text{go outdoor}}
     \end{array}}{\text{nice view}}
   \end{array}}{\text{happy}}}{\text{sunny} \rightarrow \text{happy}}
   \small{\text{ using } x} $$
   
Elimination rule for disjunction represents **reasoning by cases**.

How can we use the fact that it is sunny$\vee$cloudy (but not rainy)?

$$ \frac{\begin{array}{rrl}
     \frac{\,}{\text{sunny} \vee \text{cloudy}} \tiny{\text{ forecast}} &
     \frac{\frac{\,}{\text{sunny}} \tiny{x}}{\text{no-umbrella}} &
     \frac{\frac{\,}{\text{cloudy}} \tiny{y}}{\text{no-umbrella}}
   \end{array}}{\text{no-umbrella}} \small{\text{ using } x, y} $$

We know that it will be sunny or cloudy, by watching weather forecast. If it 
will be sunny, we won't need an umbrella. If it will be cloudy, we won't need 
an umbrella. Therefore, won't need an umbrella.We need one more kind of rules to do serious math: **reasoning by induction** 
(it is somewhat similar to reasoning by cases). Example rule for induction on 
natural numbers:

$$ \frac{\begin{array}{rr}
     p (0) &
{{{\frac{\,}{p(x)} \tiny{x}} \atop {\text{\textbar}}} \atop {p(x+1)}}
   \end{array}}{p (n)} \text{ by induction, using } x $$

So we get any $p$ for any natural number $n$, provided we can get it for $0$, 
and using it for $x$ we can derive it for the successor $x + 1$, where $x$ is 
a unique variable (we cannot substitute for it some particular number, because 
we write “using $x$” on the side).# 3 Logos was Programmed in OCaml

<table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td>Logic</td>
    <td>Type</td>
    <td>Expr.</td>
    <td style="text-align: left">Introduction Rules</td>
    <td>Elimination Rules</td>
  </tr><tr>
    <td></td>
    <td><tt class="verbatim">unit</tt></td>
    <td><tt class="verbatim">()</tt></td>
    <td style="text-align: center"></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td><tt class="verbatim">'a</tt></td>
    <td><tt class="verbatim">raise</tt></td>
    <td></td>
    <td style="text-align: center"></td>
  </tr><tr>
    <td></td>
    <td><tt class="verbatim">*</tt></td>
    <td><tt class="verbatim">(,)</tt></td>
    <td style="text-align: center"></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td style="text-align: left"><tt class="verbatim">|</tt></td>
    <td><tt class="verbatim">match</tt></td>
    <td></td>
    <td style="text-align: center"></td>
  </tr><tr>
    <td></td>
    <td><tt class="verbatim">-&gt;</tt></td>
    <td><tt class="verbatim">fun</tt></td>
    <td style="text-align: center"></td>
    <td style="text-align: center"> </td>
  </tr><tr>
    <td>induction</td>
    <td></td>
    <td><tt class="verbatim">rec</tt></td>
    <td style="text-align: center"></td>
    <td style="text-align: center"></td>
  </tr></tbody>
</table>## 3.1 Definitions

Writing out expressions and types repetitively is tedious: we need 
definitions. **Definitions for types** are written: `type ty =` some type.

* Writing `A (`$s$`) : A of `$a$`  | B of  `$b$` ` in 
  the table was cheating. Usually we have to define the type and then use it, 
  e.g. using `int` for $a$ and `string` for $b$:
  ```ocaml
  type int_string_choice = A of int | B of string
  ```
  allows us to write `A (`$s$`) : int_string_choice`.
* Without the type definition, it is difficult to know what other variants 
  there are when one *infers* (i.e. “guesses”, computes) the type!
* In OCaml we can write `` `A(s) : [`A of a | `B of b] ``. With “`` ` ``” variants, 
  OCaml does guess what other variants are. These types are fun, but we will 
  not use them in future lectures.
* Tuple elements don't need labels because we always know at which position a 
  tuple element stands. But having labels makes code more clear, so we can 
  define a *record type*:

```ocaml
type int_string_record = {a: int; b: string}
```

  and create its values: `{a = 7; b = "Mary"}`.
* We access the *fields* of records using the dot notation:

  `{a=7; b="Mary"}.b = "Mary"`.Recursive expression $\text{{\texttt{rec}} } x 
\text{{\texttt{=}}} e$ in the table was cheating: `rec` (usually 
called `fix`) cannot appear alone in OCaml! It must be part of a definition.

**Definitions for expressions** are introduced by rules a bit more complex 
than these:

$$ \frac{\begin{array}{ll}
     e_{1} : a &
{{{\frac{\,}{x : a} \tiny{x}} \atop {\text{\textbar}}} \atop {e_2 : b}}
   \end{array}}{\text{{\texttt{let}} } x \text{{\texttt{=}}}
   e_{1} \text{ \text{{\texttt{in}}} } e_{2} : b} $$

(note that this rule is the same as introducing and eliminating 
$\rightarrow$), and:

$$ \frac{\begin{array}{ll}
{{{\frac{\,}{x : a} \tiny{x}} \atop {\text{\textbar}}} \atop {e_1 : a}} &
{{{\frac{\,}{x : a} \tiny{x}} \atop {\text{\textbar}}} \atop {e_2 : b}}
   \end{array}}{\text{{\texttt{let rec}} } x
   \text{{\texttt{=}}} e_{1} \text{ \text{{\texttt{in}}} } e_{2}
   \: b} $$

We will cover what is missing in above rules when we will talk 
about **polymorphism.*** Type definitions we have seen above are *global*: they need to be at the 
  top-level, not nested in expressions, and they extend from the point they 
  occur till the end of the source file or interactive session.
* `let`-`in` definitions for expressions: $\text{{\texttt{let}} } x 
  \text{{\texttt{=}}} e_{1} \text{ \text{{\texttt{in}}} } e_{2}$ 
  are *local*, $x$ is only visible in $e_{2}$. But `let` definitions are 
  global: placing $\text{{\texttt{let}} } x 
  \text{{\texttt{=}}} e_{1}$ at the top-level makes $x$ visible from 
  after $e_{1}$ till the end of the source file or interactive session.
* In the interactive session, we mark an end of a top-level “sentence” by ;; – 
  it is unnecessary in source files.
* Operators like +, *, <, =, are names of functions. Just like other 
  names, you can use operator names for your own functions:

  let (+:) a b = String.concat "" [a; b];;Special way of defining"Alpha" +: 
  "Beta";;but normal way of using operators.
* Operators in OCaml are **not overloaded**. It means, that every type needs 
  its own set of operators. For example, +, *, / work for intigers, while +., 
  *., /. work for floating point numbers. **Exception:** comparisons <, 
  =, etc. work for all values other than functions.# 4 Exercises

Exercises from *Think OCaml. How to Think Like a Computer Scientist* by 
Nicholas Monje and Allen Downey.

1. Assume that we execute the following assignment statements:

   let width = 17;;let height = 12.0;;let delimiter = '.';;

   For each of the following expressions, write the value of the expression 
   and the type (of the value of the expression), or the resulting type error.
   1. width/2
   1. width/.2.0
   1. height/3
   1. 1 + 2 * 5
   1. delimiter * 5
1. Practice using the OCaml interpreter as a calculator:
   1. The volume of a sphere with radius $r$ is $\frac{4}{3} \pi r^3$. What is 
      the volume of a sphere with radius 5?

      Hint: 392.6 is wrong!
   1. Suppose the cover price of a book is $24.95, but bookstores get a 40% 
      discount. Shipping costs $3 for the first copy and 75 cents for each 
      additional copy. What is the total wholesale cost for 60 copies?
   1. If I leave my house at 6:52 am and run 1 mile at an easy pace (8:15 per 
      mile), then 3 miles at tempo (7:12 per mile) and 1 mile at easy pace 
      again, what time do I get home for breakfast?
1. You've probably heard of the fibonacci numbers before, but in case you 
   haven't, they're defined by the following recursive relationship:

   $$ \left\lbrace\begin{array}{llll}
     f (0) & = & 0 &  \\\\\\
     f (1) & = & 1 &  \\\\\\
     f (n + 1) & = & f (n) + f (n - 1) & \text{for } n = 2, 3, \ldots
   \end{array}\right. $$

   Write a recursive function to calculate these numbers.
1. A palindrome is a word that is spelled the same backward and forward, like 
   “noon” and “redivider”. Recursively, a word is a palindrome if the first 
   and last letters are the same and the middle is a palindrome.

   The following are functions that take a string argument and return the 
   first, last, and middle letters:

   let firstchar word = word.[0];;let lastchar word =  let len = String.length 
   word - 1 in  word.[len];;let middle word =  let len = String.length word - 
   2 in  String.sub word 1 len;;
   1. Enter these functions into the toplevel and test them out. What happens 
      if you call middle with a string with two letters? One letter? What 
      about the empty string, which is written ""?
   1. Write a function called is\_palindrome that takes a string argument and 
      returns true if it is a palindrome and false otherwise.
1. The greatest common divisor (GCD) of $a$ and $b$ is the largest number that 
   divides both of them with no remainder.

   One way to find the GCD of two numbers is Euclid's algorithm, which is 
   based on the observation that if $r$ is the remainder when $a$ is divided 
   by $b$, then $\gcd (a, b) = \gcd (b, r)$. As a base case, we can consider 
   $\gcd (a, 0) = a$.

   Write a function called gcd that takes parameters a and b and returns their 
   greatest common divisor.

   If you need help, see 
   [http://en.wikipedia.org/wiki/Euclidean\_algorithm](http://en.wikipedia.org/wiki/Euclidean_algorithm).
