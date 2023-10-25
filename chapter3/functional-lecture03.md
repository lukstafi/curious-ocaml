Functional Programming



Lecture 3: Computation

‘‘Using, Understanding and Unraveling the OCaml Language'' Didier Rémy,
chapter 1

‘‘The OCaml system'' manual, the tutorial part, chapter 1

# 1 Function Composition

* The usual way function composition is defined in math is “backward”:
  * math: $(f \circ g) (x) = f (g (x))$
  * OCaml: `let (-|) f g x = f (g x)`
  * F#: `let (<<) f g x = f (g x)`
  * Haskell: `(.) f g = \x -> f (g x)`
* It looks like function application, but needs less parentheses. Do you 
  recall the functions `iso1` and `iso2` from previous lecture?

```ocaml
let iso2 = step1l -| step2l -| step3l
```
* A more natural definition of function composition is “forward”:
  * OCaml: `let (|-) f g x = g (f x)`
  * F#: `let (>>) f g x = g (f x)`
* It follows the order in which computation proceeds.

```ocaml
let iso1 = step1r |- step2r |- step3r
```
* *Partial application* is e.g. `((+) 1)` from last week: we don't pass all 
  arguments a function needs, in result we get a function that requires the 
  remaining arguments. How is it used above?
* Now we define $f^n (x) := (f \circ \ldots \circ f) (x)$ ($f$ appears $n$ 
  times).

```ocaml
let rec power f n =
  if n <= 0 then (fun x -> x) else f -| power f (n-1)
```
* Now we define a numerical derivative:

```ocaml
let derivative dx f = fun x -> (f(x +. dx) -. f(x)) /. dx
```

  where the intent to use with two arguments is stressed, or for short:

```ocaml
let derivative dx f x = (f(x +. dx) -. f(x)) /. dx
```
* We have `(+): int -> int -> int`, so cannot use with `float`ing 
  point numbers – operators followed by dot work on `float` numbers.

```ocaml
let pi = 4.0 *. atan 1.0
let sin''' = (power (derivative 1e-5) 3) sin;;
sin''' pi;;
```

# 2 Evaluation Rules (reduction semantics)

* Programs consist of **expressions**:

  $$ \begin{matrix}
  a := & x & \text{variables}\\\\\\
  | & \text{{\texttt{fun }}} x \text{{\texttt{->}}} a &
  \text{(defined) functions}\\\\\\
  | & a a & \text{applications}\\\\\\
  | & C^0 & \text{value constructors of arity } 0\\\\\\
  | & C^n (a, \ldots, a) & \text{value constructors of arity } n \\\\\\
  | & f^n & \text{built-in values (primitives) of a. } n\\\\\\
  | & \text{{\texttt{let }}} x = a \text{{\texttt{ in }}} a
  & \text{name bindings (local definitions)}\\\\\\
  | & \text{{\texttt{match }}} a \text{{\texttt{ with}} \ \
  \ \ \ \ \ } &  \\\\\\
  & p \text{{\texttt{->}}} a \text{\text{{\texttt{ \textbar
  }}}}
  \ldots \text{{\texttt{ \textbar }}} p
  \text{{\texttt{->}}}
  a & \text{pattern matching}\\\\\\
  p := & x & \text{pattern variables}\\\\\\
  | & (p, \ldots, p) & \text{tuple patterns}\\\\\\
  | & C^0 & \text{variant patterns of arity } 0\\\\\\
  | & C^n (p, \ldots, p) & \text{variant patterns of arity } n \end{matrix} $$
* *Arity* means how many arguments something requires; (and for tuples, the 
  length of a tuple).
* To simplify presentation, we will use a primitive `fix` to define a limited 
  form of `let rec`:

  $$ \text{{\texttt{let rec }}} f \text{{\texttt{ }}} x =
   e_{1} \text{{\texttt{ in }}} e_{2} \equiv
   \text{{\texttt{let }}} f = \text{{\texttt{fix (fun }}} f
   \text{{\texttt{ }}} x \text{{\texttt{->}}} e_{1}
   \text{{\texttt{) in }}} e_{2} $$
* Expressions evaluate (i.e. compute) to **values**:

  $$ \begin{matrix}
  v := & \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  &
  \text{(defined) functions}\\\\\\
  | & C^n (v_{1}, \ldots, v_{n}) & \text{constructed values}\\\\\\
  | & f^n v_{1} \ldots v_{k} & k < n \text{ partially applied
  primitives} \end{matrix} $$
* To *substitute* a value $v$ for a variable $x$ in expression $a$ we write $a 
  [x := v]$ – it behaves as if every occurrence of $x$ in $a$ was *rewritten* 
  by $v$.
  * (But actually the value $v$ is not duplicated.)
* Reduction (i.e. computation) proceeds as follows: first we give *redexes*

  $$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \rightsquigarrow & a [x := v]\\\\\\
  \text{{\texttt{let }}} x = v \text{{\texttt{ in }}} a &
  \rightsquigarrow & a [x := v]\\\\\\
  f^n v_{1} \ldots v_{n} & \rightsquigarrow & f (v_{1}, \ldots,
  v_{n})\\\\\\
  \text{{\texttt{match }}} v \text{{\texttt{ with}} } x
  \text{{\texttt{->}}} a \text{{\texttt{ \textbar }}}
  \ldots
  & \rightsquigarrow & a [x := v]\\\\\\
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})
  \text{{\texttt{ with}}} &  &  \\\\\\
  C_{2}^n (p_{1}, \ldots, p_{k}) \text{{\texttt{->}}} a
  \text{{\texttt{ \textbar }}} \operatorname{pm} & \rightsquigarrow &
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})\\\\\\
  &  & \text{{\texttt{with}} } \operatorname{pm}\\\\\\
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})
  \text{{\texttt{ with}}} &  &  \\\\\\
  C_{1}^n (x_{1}, \ldots, x_{n}) \text{{\texttt{->}}} a
  \text{{\texttt{ \textbar }}} \ldots & \rightsquigarrow & a [x_{1}
  \:= v_{1} ; \ldots ; x_{n} := v_{n}] \end{matrix} $$

  If $n = 0$, $C_{1}^n (v_{1}, \ldots, v_{n})$ stands for $C^0_{1}$, etc. 
  By $f (v_{1}, \ldots, v_{n})$ we denote the actual value resulting from 
  computing the primitive. We omit the more complex cases of pattern matching.
* Rule variables: $x$ matches any expression/pattern variable; $a, a_{1}, 
  \ldots, a_{n}$ match any expression; $v, v_{1}, \ldots, v_{n}$ match any 
  value. Substitute them so that the left-hand-side of a rule is your 
  expression, then the right-hand-side is the reduced expression.
* The remaining rules evaluate the arguments in arbitrary order, but keep the 
  order in which `let`…`in` and `match`…`with` is evaluated.

  If $a_{i} \rightsquigarrow a_{i}'$, then:

  $$ \begin{matrix}
  a_{1} a_{2} & \rightsquigarrow & a_{1}' a_{2}\\\\\\
  a_{1} a_{2} & \rightsquigarrow & a_{1} a_{2}'\\\\\\
  C^n (a_{1}, \ldots, a_{i}, \ldots, a_{n}) & \rightsquigarrow & C^n
  (a_{1}, \ldots, a_{i}', \ldots, a_{n})\\\\\\
  \text{{\texttt{let }}} x = a_{1} \text{{\texttt{ in }}}
  a_{2} & \rightsquigarrow & \text{{\texttt{let }}} x = a_{1}'
  \text{{\texttt{ in }}} a_{2}\\\\\\
  \text{{\texttt{match }}} a_{1} \text{{\texttt{ with}} }
  \operatorname{pm} & \rightsquigarrow & \text{{\texttt{match }}}
  a_{1}' \text{{\texttt{ with}} } \operatorname{pm} \end{matrix} $$
* Finally, we give the rule for the primitive `fix` – it is a binary 
  primitive:

  $$ \begin{matrix}
  \text{{\texttt{fix}}}^2 v_{1} v_{2} & \rightsquigarrow & v_{1}
  \left( \text{{\texttt{fix}}}^2 v_{1} \right) v_{2} \end{matrix} $$

  Because `fix` is binary, $\left( \text{{\texttt{fix}}}^2 v_{1} 
  \right)$ is already a value so it will not be further computed until it is 
  applied inside of $v_{1}$.
* Compute some programs using the rules by hand.

# 3 Symbolic Derivation Example

Go through the examples from the `Lec3.ml` file in the toplevel.

```ocaml
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

# 4 Tail Calls (and tail recursion)

* Excuse me for not defining what a *function call* is…
* Computers normally evaluate programs by creating *stack frames* on the stack 
  for function calls (roughly like indentation levels in the above example).
* A **tail call** is a function call that is performed last when computing a 
  function.
* Functional language compilers will often insert a “jump” for a tail call 
  instead of creating a stack frame.
* A function is **tail recursive** if it calls itself, and functions it 
  mutually-recursively depends on, only using a tail call.
* Tail recursive functions often have special *accumulator* arguments that 
  store intermediate computation results which in a non-tail-recursive 
  function would just be values of subexpressions.
* The accumulated result is computed in “reverse order” – while climbing up 
  the recursion rather than while descending (i.e. returning) from it.
* The issue is more complex for *lazy* programming languages like Haskell.
* Compare:

```ocaml
# let rec unfold n = if n <= 0 then [] else n :: unfold (n-1);;
val unfold : int -> int list = <fun>
# unfold 100000;;
- : int list =
[100000; 99999; 99998; 99997; 99996; 99995; 99994; 99993; …]
# unfold 1000000;;
Stack overflow during evaluation (looping recursion?).
# let rec unfold_tcall acc n =
  if n <= 0 then acc else unfold_tcall (n::acc) (n-1);;
  val unfold_tcall : int list -> int -> int list = <fun>
# unfold_tcall [] 100000;;
- : int list =
[1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; …]
# unfold_tcall [] 1000000;;
- : int list =
[1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; …]
```
* Is it possible to find the depth of a tree using a tail-recursive function?

# 5 First Encounter of Continuation Passing Style

We can postpone doing the actual work till the last moment:

```ocaml
let rec depth tree k = match tree with
    | Tip -> k 0
    | Node(_,left,right) ->
      depth left (fun dleft ->
        depth right (fun dright ->
          k (1 + (max dleft dright))))

let depth tree = depth tree (fun d -> d)
```

# 6 Homework

By “traverse a tree” below we mean: write a function that takes a tree and 
returns a list of values in the nodes of the tree.

1. Write a function (of type `btree -> int list`) that traverses a binary 
   tree: in prefix order – first the value stored in a node, then values in 
   all nodes to the left, then values in all nodes to the right;
1. in infix order – first values in all nodes to the left, then value stored 
   in a node, then values in all nodes to the right (so it is “left-to-right” 
   order);
1. in breadth-first order – first values in more shallow nodes.
1. Turn the function from ex. 1 or 2 into continuation passing style.
1. Do the homework from the end of last week slides: write `btree_deriv_at`.
1. Write a function `simplify: expression -> expression` that simplifies 
   the expression a bit, so that for example the result of `simplify (deriv 
   exp dv)` looks more like what a human would get computing the derivative of 
   `exp` with respect to `dv`.
   * Write a `simplify_once` function that performs a single step of the 
     simplification, and wrap it using a general `fixpoint` function that 
     performs an operation until a *fixed point* is reached: given $f$ and 
     $x$, it computes $f^n (x)$ such that $f^n (x) = f^{n + 1} (x)$.
