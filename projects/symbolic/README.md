# Project: symbolic differentiation

**Prerequisites:** Chapters 3 and 6; ordinary differentiation of real functions.

This optional project preserves the second edition's larger arithmetic example.
Its calculus rules concern differentiable real functions where denominators are
nonzero. The executable evaluator uses IEEE floating-point arithmetic: overflow,
NaN, signed zero, rounding and unbound variables can invalidate algebraic rewrites.
The trace is an illustrative transcript, not a language-specified argument order.
Run `dune runtest projects/symbolic` from the repository root.


Let us see the reduction rules in action with a more substantial example. We will build a small computer algebra system that can represent mathematical expressions symbolically, evaluate them, and even compute their derivatives symbolically.

Consider the symbolic expression type from `Lec3.ml`:

```ocaml env=ch3
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

```ocaml env=ch3
let rec deriv exp dv =
  match exp with
  | Const _ -> Const 0.0
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

```ocaml env=ch3
let x = Var "x"
let y = Var "y"
let z = Var "z"
let (+:) f g = Sum (f, g)
let (-:) f g = Diff (f, g)
let ( *: ) f g = Prod (f, g)
let (/:) f g = Quot (f, g)
let (!:) i = Const i
```

These custom operators (ending in `:`) let us write symbolic expressions that look almost like regular mathematical notation.

Now let us evaluate the expression $3x + 2y + x^2 y$ at $x = 1, y = 2$:

```ocaml env=ch3
let example = !:3.0 *: x +: !:2.0 *: y +: x *: x *: y
let env = ["x", 1.0; "y", 2.0]
```

For nicer output, it is helpful to define a pretty-printer that displays expressions in infix notation (this is adapted from `Lec3.ml`):

```ocaml env=ch3
let print_expr ppf exp =
  let open_paren prec op_prec =
    if prec > op_prec then Format.fprintf ppf "(@["
    else Format.fprintf ppf "@[" in
  let close_paren prec op_prec =
    if prec > op_prec then Format.fprintf ppf "@])"
    else Format.fprintf ppf "@]" in
  let rec print prec exp =
    match exp with
    | Const c -> Format.fprintf ppf "%.2f" c
    | Var v -> Format.fprintf ppf "%s" v
    | Sum(f, g) ->
      open_paren prec 0;
      print 0 f; Format.fprintf ppf "@ +@ "; print 0 g;
      close_paren prec 0
    | Diff(f, g) ->
      open_paren prec 0;
      print 0 f; Format.fprintf ppf "@ -@ "; print 1 g;
      close_paren prec 0
    | Prod(f, g) ->
      open_paren prec 2;
      print 2 f; Format.fprintf ppf "@ *@ "; print 2 g;
      close_paren prec 2
    | Quot(f, g) ->
      open_paren prec 2;
      print 2 f; Format.fprintf ppf "@ /@ "; print 3 g;
      close_paren prec 2
  in
  print 0 exp
```

And for tracing, we define a specialized evaluator `eval_1_2` with the environment baked in (so the trace focuses on the expression structure):

```ocaml env=ch3
let rec eval_1_2 exp =
  match exp with
  | Const c -> c
  | Var v ->
    (try List.assoc v env with Not_found -> raise (Unbound_variable v))
  | Sum(f, g) -> eval_1_2 f +. eval_1_2 g
  | Diff(f, g) -> eval_1_2 f -. eval_1_2 g
  | Prod(f, g) -> eval_1_2 f *. eval_1_2 g
  | Quot(f, g) -> eval_1_2 f /. eval_1_2 g
```

In the toplevel, you can now install the printer and trace the evaluation:

<!-- book-skip: interactive printer and tracing directives; transcript is illustrative -->
```ocaml skip
# #install_printer print_expr;;
# #trace eval_1_2;;
# eval_1_2 example;;
```

The trace output makes the recursive structure of the computation very concrete:

```text
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


## Project acceptance criteria

Implement a bottom-up simplifier and test its intended contract. Compare symbolic
derivatives with analytic derivatives of three polynomials on a stated finite
grid. A small numerical discrepancy is evidence, not a proof. Include a division
by zero and an unbound variable as counterexamples to unconditional simplification.
