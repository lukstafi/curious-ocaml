## Chapter 4: Functions as a language (optional)

![Chapter 4 illustration](Curious_OCaml-chapter_4.jpg){.chapter-image}

**Prerequisites:** Chapter 3's distinction between syntax and evaluation; functions
and recursive datatypes. **Route:** this is an optional Part I detour. Continue
to Chapter 5 without it if you want modules and useful data structures first.

Can functions alone represent booleans, numbers and recursion? The untyped lambda
calculus asks this question with three syntax forms: variables, functions and
application. We will calculate with that syntax in a small OCaml interpreter.
The interpreter is typed OCaml; its object language is untyped. No unsafe cast or
recursive OCaml type is needed to represent a self-application.

### 4.1 Equations and evaluation are different

The notation $\lambda x.e$ binds `x` in `e`. Application associates to the left:
`f x y` means `(f x) y`. A function body extends as far to the right as possible,
so $\lambda x.f\,x$ means $\lambda x.(f\,x)$.

Three familiar equations have different jobs:

- **Alpha:** rename a bound variable consistently, avoiding capture.
- **Beta:** $(\lambda x.e)\,v = e[x:=v]$, with capture-avoiding substitution.
- **Eta:** $\lambda x.f\,x = f$ when `x` is not free in `f`, as an extensional
  equation of the pure calculus. This is not unrestricted contextual equivalence
  for effectful or diverging strict programs.

Full beta reduction permits work inside a function body and in an argument before
it is needed. **Normal order** chooses the leftmost outermost redex and continues
under lambdas. **Weak call by value** first evaluates a function and its argument
to values, and does not reduce inside an unapplied lambda. OCaml is a strict
language, but our interpreter specifies a left-to-right operand order explicitly;
we do not infer OCaml's argument order from this object-language rule.

For example, let $I=\lambda x.x$ and
$\Omega=(\lambda x.x\,x)(\lambda x.x\,x)$. Normal order reduces
$(\lambda ignored.I)\,\Omega$ to $I$ without touching $\Omega$. Weak call by value
tries to evaluate $\Omega$ and never reaches the body.

### 4.2 Names without accidental capture

Naively replacing `x` by `y` in $\lambda y.x$ produces $\lambda y.y$, which
captures the free `y`. The correct result is $\lambda z.y$ for a fresh `z`.
We can avoid bound-name choices entirely: **de Bruijn indices** count binders
outward from each occurrence. `Bound 0` refers to the nearest enclosing lambda;
`Bound 1` refers to the next one. Free variables keep their names.

Thus $\lambda x.x$ is `Lam (Bound 0)` and $\lambda x.\lambda y.x$ is
`Lam (Lam (Bound 1))`. Alpha-equivalent terms have the same representation.
An index must be nonnegative and smaller than the number of enclosing binders;
`well_scoped` in the source checks that precondition.

<!-- $MDX file=../projects/expressions/lambda.ml,part=terms -->
```ocaml
type t = Bound of int | Free of string | Lam of t | App of t * t

let rec shift amount cutoff = function
  | Bound k -> Bound (if k >= cutoff then k + amount else k)
  | Free _ as x -> x
  | Lam body -> Lam (shift amount (cutoff + 1) body)
  | App (f, x) -> App (shift amount cutoff f, shift amount cutoff x)

let rec substitute index value = function
  | Bound k as x -> if k = index then value else x
  | Free _ as x -> x
  | Lam body -> Lam (substitute (index + 1) (shift 1 0 value) body)
  | App (f, x) -> App (substitute index value f, substitute index value x)

let beta body argument =
  shift (-1) 0 (substitute 0 (shift 1 0 argument) body)
```

`shift amount cutoff` adjusts indices that refer outside the binders we have
already crossed. Entering a lambda increments the cutoff. Substitution under a
lambda shifts its replacement up by one, because the replacement now occurs
under one more binder. Beta reduction shifts the argument up before substitution,
then shifts the result down when removing the applied lambda.

These three shifts can seem bureaucratic. Trace `beta (Lam (Bound 1)) (Free "y")`:
`Bound 1` under the inner lambda refers to the parameter being replaced; the
answer is `Lam (Free "y")`, not `Lam (Bound 0)`. A free variable never becomes a
bound index. The named substitution in Chapter 11 implements the same obligation
by choosing fresh names instead.

### 4.3 Two executable reduction strategies

<!-- $MDX file=../projects/expressions/lambda.ml,part=strategies -->
```ocaml
let rec normal_step = function
  | App (Lam body, argument) -> Some (beta body argument)
  | App (f, x) ->
    (match normal_step f with
     | Some f' -> Some (App (f', x))
     | None -> Option.map (fun x' -> App (f, x')) (normal_step x))
  | Lam body -> Option.map (fun body -> Lam body) (normal_step body)
  | Bound _ | Free _ -> None

let rec value_step = function
  | App (Lam body, (Lam _ as argument)) -> Some (beta body argument)
  | App ((Lam _ as f), x) ->
    Option.map (fun x -> App (f, x)) (value_step x)
  | App (f, x) -> Option.map (fun f -> App (f, x)) (value_step f)
  | Bound _ | Free _ | Lam _ -> None

type result = Done of t | Limit of t
let reduce ~fuel step term =
  if fuel < 0 then invalid_arg "negative reduction fuel";
  let rec loop fuel term =
    match step term with
    | None -> Done term
    | Some _ when fuel = 0 -> Limit term
    | Some term -> loop (fuel - 1) term in
  loop fuel term
```

The interpreter lives in `projects/expressions/lambda.ml`. Its tests include
capture, shadowing, reduction under lambdas, Church addition, and Scott
predecessor. The `Done` result means no step is available under the selected
strategy. For weak call by value on an *open* term that can mean stuck, rather
than a value. Use closed, well-scoped terms when claiming a value result.
`Limit` means only that we spent the chosen beta-step budget; it does not decide
whether the term diverges. Searching for a redex still traverses syntax, so fuel
is not a bound on allocation or total interpreter work.

```ocaml env=lambda
open Expressions.Lambda
let identity = Lam (Bound 0)
let self = Lam (App (Bound 0, Bound 0))
let omega = App (self, self)
let discarded = App (Lam identity, omega)
let () =
  assert (reduce ~fuel:20 normal_step discarded = Done identity);
  assert (match reduce ~fuel:20 value_step discarded with
    | Limit _ -> true | Done _ -> false);
  assert (beta (Lam (Bound 1)) (Free "y") = Lam (Free "y"))
```

We deliberately store `omega` as finite syntax. Evaluating an equivalent
self-applying OCaml function would instead run in the host language and could
prevent the experiment from finishing.

### 4.4 Booleans and products choose their consumers

A Church boolean selects a branch:

$$\mathit{true}=\lambda t.\lambda f.t,\qquad
  \mathit{false}=\lambda t.\lambda f.f.$$

An if-expression is `b t f`; conjunction can be `a b false`.
A pair packages two values for a consumer:

$$\mathit{pair}=\lambda a.\lambda b.\lambda k.k\,a\,b.$$

Apply the pair to `true` to select its first component and to `false` to select
its second. The representation exposes the elimination operation rather than
constructors and pattern matching.

```ocaml env=lambda
let yes = Lam (Lam (Bound 1))
let no = Lam (Lam (Bound 0))
let select b t f = App (App (b, t), f)
let () =
  assert (reduce ~fuel:20 normal_step (select yes identity omega) = Done identity)
```

A strict evaluator would evaluate both supplied branches. To implement an
if-like operation under call by value, wrap each branch in a lambda (a thunk),
select a thunk, and apply it to a dummy value. The distinction is operational:
writing a boolean encoding alone does not make its arguments lazy.

### 4.5 Church iteration and Scott case analysis

A **Church numeral** is an iterator:

$$0=\lambda f.\lambda x.x,\quad
  1=\lambda f.\lambda x.f\,x,\quad
  2=\lambda f.\lambda x.f(f\,x).$$

Addition composes iterations:
$\mathit{add}=\lambda m.\lambda n.\lambda f.\lambda x.m\,f\,(n\,f\,x)$.
The implementation below constructs the syntax, not a host-language numeral:

```ocaml env=lambda
let church n =
  if n < 0 then invalid_arg "negative numeral";
  let rec times n =
    if n = 0 then Bound 0 else App (Bound 1, times (n - 1)) in
  Lam (Lam (times n))
let add = Lam (Lam (Lam (Lam
  (App (App (Bound 3, Bound 1), App (App (Bound 2, Bound 1), Bound 0))))))
let () =
  assert (reduce ~fuel:100 normal_step (App (App (add, church 2), church 3))
          = Done (church 5))
```

A **Scott numeral** selects between a zero case and a successor case, giving its
predecessor directly to the latter:

$$\mathit{zero}=\lambda z.\lambda s.z,\qquad
  \mathit{succ}=\lambda n.\lambda z.\lambda s.s\,n.$$

```ocaml env=lambda
let scott_zero = Lam (Lam (Bound 1))
let scott_succ = Lam (Lam (Lam (App (Bound 0, Bound 2))))
let predecessor n = App (App (n, scott_zero), identity)
let () =
  assert (reduce ~fuel:30 normal_step
    (predecessor (App (scott_succ, scott_zero))) = Done scott_zero)
```

Scott predecessor chooses a constructor case. Church predecessor instead needs
to carry additional state through an iteration, for instance a pair of successive
counts. Church lists similarly encode a fold, while Scott lists expose the head
and tail to the nonempty case. Calling both encodings “Church” hides the distinction
between iteration and one-step case analysis.

### 4.6 Recursion and cost

In the untyped calculus, the fixed-point combinator

$$Y=\lambda f.(\lambda x.f(x\,x))(\lambda x.f(x\,x))$$

satisfies $Yf\rightsquigarrow^* f(Yf)$. This equation provides a recursive call;
it does not prove that any invocation terminates. Under weak call by value,
this `Y` attempts self-application too early. A delayed variant can expose a
lambda before recurring, but its operational argument must be checked separately.
OCaml's `let rec` is the practical construct for recursive functions; encoding
`Y` is an experiment about evaluation strategy, not a replacement for it.

Counting beta reductions also omits the work of copying syntax during substitution.
The arithmetic machine from Chapter 3 stores an environment instead of replacing
every variable occurrence. An environment-and-closure lambda machine is a useful
next project precisely because it changes this cost model.

### 4.7 Exercises

1. **Practice.** Encode $\lambda x.\lambda y.y\,x$ with indices. Selected answer:
   `Lam (Lam (App (Bound 0, Bound 1)))`.
2. **Proof.** Explain why shifting the replacement when entering a lambda is
   necessary. Give a well-scoped term whose reduction would capture a variable
   if that shift were omitted.
3. **Experiment.** Evaluate the same term with `normal_step` and `value_step`.
   Use one example that differs only under a lambda and one discarded divergent
   argument. Report fuel exhaustion as inconclusive, not as a divergence proof.
4. **Practice.** Implement Church multiplication and check `2 * 3 = 6` by comparing
   normal forms with `church 6`. Write Scott numerals zero through three and check
   predecessor at zero and three.
5. **Project.** Build an environment-and-closure interpreter for closed terms.
   Specify the strategy, compare terminating cases against `value_step`, and
   measure syntax copying versus environment retention. Include a shadowing test.
