## Chapter 7: Laziness

This chapter explores lazy evaluation and stream processing in OCaml. We examine different evaluation strategies, implement streams and lazy lists, apply them to power series computation and differential equations, build circular data structures, and develop a sophisticated pipe-based pretty-printer.

### 7.1 Evaluation Strategies and Parameter Passing

**Evaluation strategy** is the order in which expressions are computed -- primarily, when arguments are computed. Recall our problems with using *flow control* expressions like `if_then_else` in examples from the lambda-calculus lecture. There are many technical terms describing various evaluation strategies:

**Strict evaluation**: Arguments are always evaluated completely before the function is applied.

**Non-strict evaluation**: Arguments are not evaluated unless they are actually used in the evaluation of the function body.

**Eager evaluation**: An expression is evaluated as soon as it gets bound to a variable.

**Lazy evaluation**: Non-strict evaluation which avoids repeating computation.

**Call-by-value**: The argument expression is evaluated, and the resulting value is bound to the corresponding variable in the function (frequently by copying the value into a new memory region).

**Call-by-reference**: A function receives an implicit reference to a variable used as argument, rather than a copy of its value. In purely functional languages there is no difference between the two strategies, so they are typically described as call-by-value even though implementations use call-by-reference internally for efficiency. Call-by-value languages like C and OCaml support explicit references (objects that refer to other objects), and these can be used to simulate call-by-reference.

**Normal order**: Start computing function bodies before evaluating their arguments. Do not even wait for arguments if they are not needed.

**Call-by-name**: Arguments are substituted directly into the function body and then left to be evaluated whenever they appear in the function.

**Call-by-need**: If the function argument is evaluated, that value is stored for subsequent uses.

Almost all languages do not compute inside the body of an un-applied function, but with curried functions you can pre-compute data before all arguments are provided (recall the `search_bible` example from earlier lectures).

In eager / call-by-value languages we can simulate call-by-name by taking a function to compute the value as an argument instead of the value directly. "Our" languages have a `unit` type with a single value `()` specifically for use as throw-away arguments. Scala has built-in support for call-by-name (i.e. direct, without the need to build argument functions).

ML languages have built-in support for lazy evaluation, while Haskell has built-in support for eager evaluation (to override the default laziness).

### 7.2 Call-by-name: Streams

Call-by-name is useful not only for implementing flow control:

```ocaml env=ch7
let if_then_else cond e1 e2 =
  match cond with
  | true -> e1 ()
  | false -> e2 ()
```

but also for arguments of value constructors, i.e. for data structures.

**Streams** are lists with call-by-name tails:

```ocaml env=ch7
type 'a stream = SNil | SCons of 'a * (unit -> 'a stream)
```

Reading from a stream into a list:

```ocaml env=ch7
let rec stake n = function
  | SCons (a, s) when n > 0 -> a :: (stake (n-1) (s ()))
  | _ -> []
```

Streams can easily be infinite:

```ocaml env=ch7
let rec s_ones = SCons (1, fun () -> s_ones)

let rec s_from n =
  SCons (n, fun () -> s_from (n+1))
```

#### 7.2.1 Stream Operations

Streams admit list-like operations:

```ocaml env=ch7
let rec smap f = function
  | SNil -> SNil
  | SCons (a, s) -> SCons (f a, fun () -> smap f (s ()))

let rec szip = function
  | SNil, SNil -> SNil
  | SCons (a1, s1), SCons (a2, s2) ->
      SCons ((a1, a2), fun () -> szip (s1 (), s2 ()))
  | _ -> raise (Invalid_argument "szip")
```

Streams can provide scaffolding for recursive algorithms. Consider the Fibonacci sequence:

```ocaml env=ch7
let rec sfib =
  SCons (1, fun () -> smap (fun (a,b) -> a+b)
    (szip (sfib, SCons (1, fun () -> sfib))))
```

This definition creates a stream where each element is computed by adding pairs from the current stream and itself shifted by one position:

| sfib     | 1 | 2 | 3 | 5 | 8 | 13 | ... |
|----------|---|---|---|---|---|----|-----|
| sfib     | 1 | 2 | 3 | 5 | 8 | 13 | ... |
| shifted  | 1 | 1 | 2 | 3 | 5 | 8  | ... |

The `+` operation between corresponding elements produces the next values.

#### 7.2.2 Streams and Input-Output

Streams are less functional than could be expected in the context of input-output effects:

```ocaml env=ch7
let file_stream name =
  let ch = open_in name in
  let rec ch_read_line () =
    try SCons (input_line ch, ch_read_line)
    with End_of_file -> SNil in
  ch_read_line ()
```

*OCaml Batteries* uses a stream type `enum` for interfacing between various sequence-like data types. The safest way to use streams is in a *linear* / *ephemeral* manner: every value used only once. Streams minimize space consumption at the expense of time for recomputation.

### 7.3 Lazy Values

Lazy evaluation is more general than call-by-need as any value can be lazy, not only a function parameter.

A *lazy value* is a value that "holds" an expression until its result is needed, and from then on it "holds" the result. It is also called a *suspension*. If it holds the expression (not yet evaluated), it is called a *thunk*.

In OCaml, we build lazy values explicitly. In Haskell, all values are lazy but functions can have call-by-value parameters which "need" the argument.

To create a lazy value: `lazy expr` -- where `expr` is the suspended computation.

Two ways to use a lazy value (be careful when the result is computed!):
- In expressions: `Lazy.force l_expr`
- In patterns: `match l_expr with lazy v -> ...`
  - Syntactically `lazy` behaves like a data constructor.

#### 7.3.1 Lazy Lists

Lazy lists are defined as:

```ocaml env=ch7
type 'a llist = LNil | LCons of 'a * 'a llist Lazy.t
```

Reading from a lazy list into a list:

```ocaml env=ch7
let rec ltake n = function
  | LCons (a, lazy l) when n > 0 -> a :: (ltake (n-1) l)
  | _ -> []
```

Lazy lists can easily be infinite:

```ocaml env=ch7
let rec l_ones = LCons (1, lazy l_ones)

let rec l_from n = LCons (n, lazy (l_from (n+1)))
```

Read once, access multiple times (unlike streams):

```ocaml env=ch7
let file_llist name =
  let ch = open_in name in
  let rec ch_read_line () =
    try LCons (input_line ch, lazy (ch_read_line ()))
    with End_of_file -> LNil in
  ch_read_line ()
```

#### 7.3.2 Lazy List Operations

```ocaml env=ch7
let rec lzip = function
  | LNil, LNil -> LNil
  | LCons (a1, ll1), LCons (a2, ll2) ->
      LCons ((a1, a2), lazy (
        lzip (Lazy.force ll1, Lazy.force ll2)))
  | _ -> raise (Invalid_argument "lzip")

let rec lmap f = function
  | LNil -> LNil
  | LCons (a, ll) ->
    LCons (f a, lazy (lmap f (Lazy.force ll)))
```

Using these operations, we can define the factorial sequence elegantly:

```ocaml env=ch7
let posnums = l_from 1

let rec lfact =
  LCons (1, lazy (lmap (fun (a,b) -> a*b)
                    (lzip (lfact, posnums))))
```

This produces: 1, 1, 2, 6, 24, 120, ... where each element is the product of the previous factorial and the corresponding positive integer:

| lfact   | 1 | 1 | 2 |  6 |  24 | 120 | ... |
|---------|---|---|---|----|-----|-----|-----|
| lfact   | 1 | 1 | 2 |  6 |  24 | 120 | ... |
| posnums | 1 | 2 | 3 |  4 |   5 |   6 | ... |

The `*` operation between corresponding elements produces the next values.

### 7.4 Power Series and Differential Equations

This section presents an application of lazy lists to power series computation and solving differential equations through power series. The differential equations idea is due to Henning Thielemann.

The expression $P(x) = \sum_{i=0}^{n} a_i x^i$ defines a polynomial for $n < \infty$ and a power series for $n = \infty$.

If we define:

```ocaml env=ch7
let rec lfold_right f l base =
  match l with
    | LNil -> base
    | LCons (a, lazy l) -> f a (lfold_right f l base)
```

then we can compute polynomials using Horner's method:

```ocaml env=ch7
let horner x l =
  lfold_right (fun c sum -> c +. x *. sum) l 0.
```

But this will not work for infinite power series! Does it make sense to compute the value at $x$ of a power series? Does it make sense to fold an infinite list?

If the power series converges for $x > 1$, then when the elements $a_n$ get small, the remaining sum $\sum_{i=n}^{\infty} a_i x^i$ is also small.

`lfold_right` falls into an infinite loop on infinite lists. We need call-by-name / call-by-need semantics for the argument function `f`:

```ocaml env=ch7
let rec lazy_foldr f l base =
  match l with
    | LNil -> base
    | LCons (a, ll) ->
      f a (lazy (lazy_foldr f (Lazy.force ll) base))
```

We need a stopping condition in the Horner algorithm step:

```ocaml env=ch7
let lhorner x l =                         (* This is a bit of a hack, *)
  let upd c sum =                         (* we hope to "hit" the interval (0, epsilon]. *)
    if c = 0. || abs_float c > epsilon_float
    then c +. x *. Lazy.force sum
    else 0. in
  lazy_foldr upd l 0.

let inv_fact = lmap (fun n -> 1. /. float_of_int n) lfact
let e = lhorner 1. inv_fact
```

#### 7.4.1 Power Series / Polynomial Operations

For power series operations with floating-point coefficients, we need a float-based version of positive numbers:

```ocaml env=ch7
let rec l_from_f n = LCons (n, lazy (l_from_f (n +. 1.)))
let posnums_f = l_from_f 1.

(* Unary negation for series *)
let (~-:) = lmap (fun x -> -.x)
```

```ocaml env=ch7
let rec add xs ys =
  match xs, ys with
    | LNil, _ -> ys
    | _, LNil -> xs
    | LCons (x,xs), LCons (y,ys) ->
      LCons (x +. y, lazy (add (Lazy.force xs) (Lazy.force ys)))

let rec sub xs ys =
  match xs, ys with
    | LNil, _ -> lmap (fun x -> -.x) ys
    | _, LNil -> xs
    | LCons (x,xs), LCons (y,ys) ->
      LCons (x -. y, lazy (add (Lazy.force xs) (Lazy.force ys)))

let scale s = lmap (fun x -> s *. x)

let rec shift n xs =
  if n = 0 then xs
  else if n > 0 then LCons (0., lazy (shift (n-1) xs))
  else match xs with
    | LNil -> LNil
    | LCons (0., lazy xs) -> shift (n+1) xs
    | _ -> failwith "shift: fractional division"

let rec mul xs = function
  | LNil -> LNil
  | LCons (y, ys) ->
    add (scale y xs) (LCons (0., lazy (mul xs (Lazy.force ys))))

let rec div xs ys =
  match xs, ys with
  | LNil, _ -> LNil
  | LCons (0., xs'), LCons (0., ys') ->
    div (Lazy.force xs') (Lazy.force ys')
  | LCons (x, xs'), LCons (y, ys') ->
    let q = x /. y in
    LCons (q, lazy (div (sub (Lazy.force xs')
                                 (scale q (Lazy.force ys'))) ys))
  | LCons _, LNil -> failwith "div: division by zero"

let integrate c xs =
  LCons (c, lazy (lmap (uncurry (/.)) (lzip (xs, posnums_f))))

let ltail = function
  | LNil -> invalid_arg "ltail"
  | LCons (_, lazy tl) -> tl

let differentiate xs =
  lmap (uncurry ( *.)) (lzip (ltail xs, posnums_f))
```

#### 7.4.2 Differential Equations

Consider the differential equations for sine and cosine:

$$\frac{d \sin x}{dx} = \cos x, \quad \frac{d \cos x}{dx} = -\sin x, \quad \sin 0 = 0, \quad \cos 0 = 1$$

We will solve the corresponding integral equations. We cannot define the integral by direct recursion like this:

```
let (~-:) = lmap (fun x -> -.x)  (* Unary negation for series *)

let rec sin = integrate (of_int 0) cos
and cos = integrate (of_int 1) (~-:sin)
```

Unfortunately this fails with: `Error: This kind of expression is not allowed as right-hand side of 'let rec'`

Even changing the second argument of `integrate` to call-by-need does not help, because OCaml cannot represent the values that `sin` and `cos` refer to at the point of their definition.

We need to inline a bit of `integrate` so that OCaml knows how to start building the recursive structure:

```ocaml env=ch7
let integ xs = lmap (uncurry (/.)) (lzip (xs, posnums_f))

let rec sin = LCons (of_int 0, lazy (integ cos))
and cos = LCons (of_int 1, lazy (integ (~-:sin)))
```

The complete example would look much more elegant in Haskell, where all values are lazy by default.

Although this approach is not limited to linear equations, equations like Lotka-Volterra or Lorentz are not "solvable" this way -- computed coefficients quickly grow instead of quickly falling.

Drawing functions work like in the previous lecture, but with open curves:

```ocaml env=ch7
let plot_1D f ~w ~scale ~t_beg ~t_end =
  let dt = (t_end -. t_beg) /. of_int w in
  Array.init w (fun i ->
    let y = lhorner (dt *. of_int i) f in
    i, to_int (scale *. y))
```

### 7.5 Arbitrary Precision Computation

Putting together the power series computation with floating-point numbers reveals drastic numerical errors for large $x$. Floating-point numbers have limited precision, and we break out of Horner method computations too quickly.

For infinite precision on rational numbers we use the `nums` library -- but it does not help by itself.

We need to generate a sequence of approximations to the power series limit at $x$:

```ocaml env=ch7
let infhorner x l =
  let upd c sum =
    LCons (c, lazy (lmap (fun apx -> c +. x *. apx)
                      (Lazy.force sum))) in
  lazy_foldr upd l (LCons (of_int 0, lazy LNil))
```

Find where the series converges -- as far as a given test is concerned:

```ocaml env=ch7
let rec exact f = function           (* We arbitrarily decide that convergence is *)
  | LNil -> assert false             (* when three consecutive results are the same. *)
  | LCons (x0, lazy (LCons (x1, lazy (LCons (x2, _)))))
      when f x0 = f x1 && f x0 = f x2 -> f x0
  | LCons (_, lazy tl) -> exact f tl
```

Draw the pixels of the graph at exact coordinates:

```ocaml env=ch7
let plot_1D f ~w ~h0 ~scale ~t_beg ~t_end =
  let dt = (t_end -. t_beg) /. of_int w in
  let eval = exact (fun y -> to_int (scale *. y)) in
  Array.init w (fun i ->
    let y = infhorner (t_beg +. dt *. of_int i) f in
    i, h0 + eval y)
```

If a power series had every third term contributing we would have to check three terms in the function `exact`. We could also test for `f x0 = f x1 && not (x0 =. x1)` like in `lhorner`.

#### 7.5.1 Example: Nuclear Chain Reaction

Consider a nuclear chain reaction where substance A decays into B, which decays into C. The differential equations are:

$$\frac{dN_A}{dt} = -\lambda_A N_A, \quad \frac{dN_B}{dt} = \lambda_A N_A - \lambda_B N_B$$

```
let n_chain ~nA0 ~nB0 ~lA ~lB =
  let rec nA =
    LCons (nA0, lazy (integ (~-.lA *:. nA)))
  and nB =
    LCons (nB0, lazy (integ (~-.lB *:. nB +: lA *:. nA))) in
  nA, nB
```

(See [Radioactive decay chain processes](http://en.wikipedia.org/wiki/Radioactive_decay#Chain-decay_processes) for more information.)

### 7.6 Circular Data Structures: Double-Linked Lists

Without delayed computation, the ability to define data structures with referential cycles is very limited.

Double-linked lists contain such cycles between any two nodes even if they are not cyclic when following only *forward* or *backward* links:

```
+--------+     +--------+     +--------+     +--------+     +--------+
| DLNil  | <-> |   a1   | <-> |   a2   | <-> |   a3   | <-> | DLNil  |
+--------+     +--------+     +--------+     +--------+     +--------+
```

We need to "break" the cycles by making some links lazy:

```ocaml env=ch7
type 'a dllist =
  DLNil | DLCons of 'a dllist Lazy.t * 'a * 'a dllist
```

```ocaml env=ch7
let rec dldrop n l =
  match l with
    | DLCons (_, x, xs) when n > 0 ->
       dldrop (n-1) xs
    | _ -> l
```

Creating a double-linked list from a regular list:

```ocaml env=ch7
let dllist_of_list l =
  let rec dllist prev l =
    match l with
      | [] -> DLNil
      | x::xs ->
        let rec cell =
          lazy (DLCons (prev, x, dllist cell xs)) in
        Lazy.force cell in
  dllist (lazy DLNil) l
```

Taking elements going forward:

```ocaml env=ch7
let rec dltake n l =
  match l with
    | DLCons (_, x, xs) when n > 0 ->
       x :: dltake (n-1) xs
    | _ -> []
```

Taking elements going backward:

```ocaml env=ch7
let rec dlbackwards n l =
  match l with
    | DLCons (lazy xs, x, _) when n > 0 ->
      x :: dlbackwards (n-1) xs
    | _ -> []
```

### 7.7 Input-Output Streams

The stream type used a throwaway argument to make a suspension:

```ocaml env=ch7
type 'a stream = SNil | SCons of 'a * (unit -> 'a stream)
```

What if we take a real argument?

```ocaml env=ch7
type ('a, 'b) iostream =
  EOS | More of 'b * ('a -> ('a, 'b) iostream)
```

This is a stream that for a single input value produces an output value.

```ocaml env=ch7
type 'a istream = (unit, 'a) iostream  (* Input stream produces output when "asked". *)
type 'a ostream = ('a, unit) iostream  (* Output stream consumes provided input. *)
```

(The confusion arises from adapting the *input file / output file* terminology, also used for streams.)

We can compose streams: directing output of one to input of another.

```ocaml env=ch7
let rec compose sf sg =
  match sg with
  | EOS -> EOS                              (* No more output. *)
  | More (z, g) ->
    match sf with
    | EOS -> More (z, fun _ -> EOS)         (* No more input "processing power". *)
    | More (y, f) ->
      let update x = compose (f x) (g y) in
      More (z, update)
```

Every box has one incoming and one outgoing wire. Notice how the output stream is ahead of the input stream.

### 7.8 Pipes

We need a more flexible input-output stream definition:
- Consume several inputs to produce a single output.
- Produce several outputs after a single input (or even without input).
- No need for a dummy when producing output requires input.

After Haskell, we call the data structure `pipe`:

```ocaml env=ch7
type ('a, 'b) pipe =
  EOP                                       (* End of pipe *)
| Yield of 'b * ('a, 'b) pipe               (* For incremental streams change to lazy. *)
| Await of ('a -> ('a, 'b) pipe)
```

Again, we can have producing output only *input pipes* and consuming input only *output pipes*:

```ocaml env=ch7
type 'a ipipe = (unit, 'a) pipe
type void
type 'a opipe = ('a, void) pipe
```

Why `void` rather than `unit`, and why only for `opipe`? Because an output pipe never yields values -- if it used `unit` as the output type, it could still yield `()` values, but with the abstract `void` type, it cannot yield anything.

#### 7.8.1 Pipe Composition

Composition of pipes is like "concatenating them in space" or connecting boxes:

```ocaml env=ch7
let rec compose pf pg =
  match pg with
  | EOP -> EOP                              (* Done producing results. *)
  | Yield (z, pg') -> Yield (z, compose pf pg')   (* Ready result. *)
  | Await g ->
    match pf with
    | EOP -> EOP                            (* End of input. *)
    | Yield (y, pf') -> compose pf' (g y)   (* Compute next result. *)
    | Await f ->
      let update x = compose (f x) pg in
      Await update                          (* Wait for more input. *)

let (>->) pf pg = compose pf pg
```

Appending pipes means "concatenating them in time" or adding more fuel to a box:

```ocaml env=ch7
let rec append pf pg =
  match pf with
  | EOP -> pg                               (* When pf runs out, use pg. *)
  | Yield (z, pf') -> Yield (z, append pf' pg)
  | Await f ->                              (* If pf awaits input, continue when it comes. *)
    let update x = append (f x) pg in
    Await update
```

Append a list of ready results in front of a pipe:

```ocaml env=ch7
let rec yield_all l tail =
  match l with
  | [] -> tail
  | x::xs -> Yield (x, yield_all xs tail)
```

Iterate a pipe (**not functional** -- performs side effects):

```ocaml env=ch7
let rec iterate f : 'a opipe =
  Await (fun x -> let () = f x in iterate f)
```

### 7.9 Example: Pretty-Printing

Print a hierarchically organized document with a limited line width.

```ocaml env=ch7
type doc =
  Text of string | Line | Cat of doc * doc | Group of doc
```

```ocaml env=ch7
let (++) d1 d2 = Cat (d1, Cat (Line, d2))
let (!) s = Text s

let test_doc =
  Group (!"Document" ++
            Group (!"First part" ++ !"Second part"))
```

Example output with different widths:

```
# let () = print_endline (pretty 30 test_doc);;
Document
First part Second part

# let () = print_endline (pretty 20 test_doc);;
Document
First part
Second part

# let () = print_endline (pretty 60 test_doc);;
Document First part Second part
```

#### 7.9.1 Straightforward Solution

```ocaml env=ch7
let pretty w d =                     (* Allowed width of line w. *)
  let rec width = function           (* Total length of subdocument. *)
    | Text z -> String.length z
    | Line -> 1
    | Cat (d1, d2) -> width d1 + width d2
    | Group d -> width d in
  let rec format f r = function      (* Remaining space r. *)
    | Text z -> z, r - String.length z
    | Line when f -> " ", r-1        (* If not f then line breaks. *)
    | Line -> "\n", w
    | Cat (d1, d2) ->
      let s1, r = format f r d1 in
      let s2, r = format f r d2 in
      s1 ^ s2, r                     (* If following group fits, then without line breaks. *)
    | Group d -> format (f || width d <= r) r d in
  fst (format false w d)
```

#### 7.9.2 Stream-Based Solution

Working with a stream of nodes:

```ocaml env=ch7
type ('a, 'b) doc_e =                (* Annotated nodes, special for group beginning. *)
  TE of 'a * string | LE of 'a | GBeg of 'b | GEnd of 'a
```

Normalize a subdocument -- remove empty groups:

```ocaml env=ch7
let rec norm = function
  | Group d -> norm d
  | Text "" -> None
  | Cat (Text "", d) -> norm d
  | d -> Some d
```

Generate the stream by infix traversal:

```ocaml env=ch7
let rec gen = function
  | Text z -> Yield (TE ((),z), EOP)
  | Line -> Yield (LE (), EOP)
  | Cat (d1, d2) -> append (gen d1) (gen d2)
  | Group d ->
    match norm d with
    | None -> EOP
    | Some d ->
      Yield (GBeg (),
             append (gen d) (Yield (GEnd (), EOP)))
```

Compute lengths of document prefixes, i.e. the position of each node counting by characters from the beginning of document:

```ocaml env=ch7
let rec docpos curpos =
  Await (function                         (* We input from a doc_e pipe *)
  | TE (_, z) ->
    Yield (TE (curpos, z),                (* and output doc_e annotated with position. *)
           docpos (curpos + String.length z))
  | LE _ ->                               (* Space and line breaks increase position by 1. *)
    Yield (LE curpos, docpos (curpos + 1))
  | GBeg _ ->                             (* Groups do not increase position. *)
    Yield (GBeg curpos, docpos curpos)
  | GEnd _ ->
    Yield (GEnd curpos, docpos curpos))

let docpos = docpos 0                     (* The whole document starts at 0. *)
```

Put the end position of the group into the group beginning marker, so that we can know whether to break it into multiple lines:

```ocaml env=ch7
let rec grends grstack =
  Await (function
  | TE _ | LE _ as e ->
    (match grstack with
    | [] -> Yield (e, grends [])          (* We can yield only when *)
    | gr::grs -> grends ((e::gr)::grs))   (* no group is waiting. *)
  | GBeg _ -> grends ([]::grstack)        (* Wait for end of group. *)
  | GEnd endp ->
    match grstack with                    (* End the group on top of stack. *)
    | [] -> failwith "grends: unmatched group end marker"
    | [gr] ->                             (* Top group -- we can yield now. *)
      yield_all
        (GBeg endp::List.rev (GEnd endp::gr))
        (grends [])
    | gr::par::grs ->                     (* Remember in parent group instead. *)
      let par = GEnd endp::gr @ [GBeg endp] @ par in
      grends (par::grs))                  (* Could use catenable lists above. *)
```

That's waiting too long! We can stop waiting when the width of a group exceeds the line limit. `GBeg` will not store end of group when it is irrelevant:

```ocaml skip
type grp_pos = Pos of int | Too_far

let rec grends w grstack =
  let flush tail =                   (* When the stack exceeds width w, *)
    yield_all                        (* flush it -- yield everything in it. *)
      (rev_concat_map ~prep:(GBeg Too_far) snd grstack)
      tail in
  Await (function
  | TE (curp, _) | LE curp as e ->
    (match grstack with              (* Remember beginning of groups in the stack. *)
    | [] -> Yield (e, grends w [])
    | (begp, _)::_ when curp-begp > w ->
      flush (Yield (e, grends w []))
    | (begp, gr)::grs -> grends w ((begp, e::gr)::grs))
  | GBeg begp -> grends w ((begp, [])::grstack)
  | GEnd endp as e ->
    match grstack with               (* No longer fail when the stack is empty -- *)
    | [] -> Yield (e, grends w [])   (* could have been flushed. *)
    | (begp, _)::_ when endp-begp > w ->
      flush (Yield (e, grends w []))
    | [_, gr] ->                     (* If width not exceeded, *)
      yield_all                      (* work as before optimization. *)
        (GBeg (Pos endp)::List.rev (GEnd endp::gr))
        (grends w [])
    | (_, gr)::(par_begp, par)::grs ->
      let par =
        GEnd endp::gr @ [GBeg (Pos endp)] @ par in
      grends w ((par_begp, par)::grs))

let grends w = grends w []           (* Initial stack is empty. *)
```

Finally we produce the resulting stream of strings:

```ocaml skip
let rec format w (inline, endlpos as st) =  (* State: the stack of *)
  Await (function                           (* "group fits in line"; position where *)
  | TE (_, z) -> Yield (z, format w st)     (* end of line would be. *)
  | LE p when List.hd inline ->
    Yield (" ", format w st)                (* After return, line has w free space. *)
  | LE p -> Yield ("\n", format w (inline, p+w))
  | GBeg Too_far ->                         (* Group with end too far is not inline. *)
    format w (false::inline, endlpos)
  | GBeg (Pos p) ->                         (* Group is inline if it ends soon enough. *)
    format w ((p<=endlpos)::inline, endlpos)
  | GEnd _ -> format w (List.tl inline, endlpos))

let format w = format w ([false], w)        (* Break lines outside of groups. *)
```

Put the pipes together:

```
+--------+     +-------+     +---------+     +--------+     +----------------+
| gen doc| --> |docpos | --> |grends w | --> |format w| --> |iterate print_s |
+--------+     +-------+     +---------+     +--------+     +----------------+
```

#### 7.9.3 Factored Solution

Factorize `format` so that various line breaking styles can be plugged in:

```ocaml skip
let rec breaks w (inline, endlpos as st) =
  Await (function
  | TE _ as e -> Yield (e, breaks w st)
  | LE p when List.hd inline ->
    Yield (TE (p, " "), breaks w st)
  | LE p as e -> Yield (e, breaks w (inline, p+w))
  | GBeg Too_far as e ->
    Yield (e, breaks w (false::inline, endlpos))
  | GBeg (Pos p) as e ->
    Yield (e, breaks w ((p<=endlpos)::inline, endlpos))
  | GEnd _ as e ->
    Yield (e, breaks w (List.tl inline, endlpos)))

let breaks w = breaks w ([false], w)

let rec emit =
  Await (function
  | TE (_, z) -> Yield (z, emit)
  | LE _ -> Yield ("\n", emit)
  | GBeg _ | GEnd _ -> emit)

let pretty_print w doc =
  gen doc >-> docpos >-> grends w >-> breaks w >->
  emit >-> iterate print_string
```

### 7.10 Exercises

**Exercise 1:** My first impulse was to define lazy list functions as follows:

```ocaml env=ch7
let rec wrong_lzip = function
  | LNil, LNil -> LNil
  | LCons (a1, lazy l1), LCons (a2, lazy l2) ->
      LCons ((a1, a2), lazy (wrong_lzip (l1, l2)))
  | _ -> raise (Invalid_argument "lzip")

let rec wrong_lmap f = function
  | LNil -> LNil
  | LCons (a, lazy l) -> LCons (f a, lazy (wrong_lmap f l))
```

What is wrong with these definitions -- for which edge cases do they not work as intended?

**Exercise 2:** Cyclic lazy lists.

1. Implement a function `cycle : 'a list -> 'a llist` that creates a lazy list with elements from a standard list, and the whole list as the tail after the last element from the input list:
   `[a1; a2; ...; aN]` maps to a cyclic structure where `aN` points back to `a1`.
   Your function `cycle` can either return `LNil` or fail for an empty list as argument.

2. Note that `inv_fact` from the lecture defines the power series for the $\exp(\cdot)$ function ($\exp(x) = e^x$). Using `cycle` and `inv_fact`, define the power series for $\sin(\cdot)$ and $\cos(\cdot)$, and draw their graphs using helper functions from the lecture script `Lec7.ml`.

**Exercise 3:** Modify one of the puzzle solving programs (either from the previous lecture or from your previous homework) to work with lazy lists. Implement the necessary higher-order lazy list functions. Check that indeed displaying only the first solution when there are multiple solutions in the result takes shorter than computing solutions by the original program.

**Exercise 4:** *Hamming's problem*. Generate in increasing order the numbers of the form $2^{a_1} 3^{a_2} 5^{a_3} \ldots p_k^{a_k}$, that is numbers not divisible by prime numbers greater than the $k$th prime number.

In the original Hamming's problem posed by Dijkstra, $k = 3$, which is related to [regular numbers](http://en.wikipedia.org/wiki/Regular_number).

Starter code is available in the lecture script `Lec7.ml`:

```ocaml env=ch7
let rec lfilter f = function
  | LNil -> LNil
  | LCons (n, ll) ->
      if f n then LCons (n, lazy (lfilter f (Lazy.force ll)))
      else lfilter f (Lazy.force ll)

let primes =
  let rec sieve = function
    | LCons(p, nf) ->
        LCons(p, lazy (sieve (sift p (Lazy.force nf))))
    | LNil -> failwith "Impossible! Internal error."
  and sift p = lfilter (fun n -> n mod p <> 0)
  in sieve (l_from 2)

let times ll n = lmap (fun i -> i * n) ll

let rec merge xs ys =
  match xs, ys with
  | LCons (x, lazy xr), LCons (y, lazy yr) ->
      if x < y then LCons (x, lazy (merge xr ys))
      else if x > y then LCons (y, lazy (merge xs yr))
      else LCons (x, lazy (merge xr yr))
  | r, LNil | LNil, r -> r

let hamming k =
  let _pr = ltake k primes in  (* TODO: use primes to generate smooth numbers *)
  let rec h = LCons (1, lazy (
     (* TODO *)h
  )) in h
```

**Exercise 5:** Modify `format` and/or `breaks` to use just a single number instead of a stack of booleans to keep track of what groups should be inlined.

**Exercise 6:** Add **indentation** to the pretty-printer for groups: if a group does not fit in a single line, its consecutive lines are indented by a given amount `tab` of spaces deeper than its parent group lines would be. For comparison, let's do several implementations.

1. Modify the straightforward implementation of `pretty`.
2. Modify the first pipe-based implementation of `pretty` by modifying the `format` function.
3. Modify the second pipe-based implementation of `pretty` by modifying the `breaks` function. Recover the positions of elements -- the number of characters from the beginning of the document -- by keeping track of the growing offset.
4. (Harder) Modify a pipe-based implementation to provide a different style of indentation: indent the first line of a group, when the group starts on a new line, at the same level as the consecutive lines (rather than at the parent level of indentation).

**Exercise 7:** Write a pipe that takes document elements annotated with linear position, and produces document elements annotated with (line, column) coordinates.

Write another pipe that takes so annotated elements and adds a line number indicator in front of each line. Do not update the column coordinate. Test the pipes by plugging them before the `emit` pipe.

```
1: first line
2: second line, etc.
```

**Exercise 8:** Write a pipe that consumes document elements `doc_e` and yields the toplevel subdocuments `doc` which would generate the corresponding elements.

You can modify the definition of documents to allow annotations, so that the element annotations are preserved (`gen` should ignore annotations to keep things simple):

```ocaml skip
type 'a doc =
  Text of 'a * string | Line of 'a | Cat of 'a doc * 'a doc | Group of 'a * 'a doc
```

**Exercise 9:** (Harder) Design and implement a way to duplicate arrows outgoing from a pipe-box, that would memoize the stream, i.e. not recompute everything "upstream" for the composition of pipes. Such duplicated arrows would behave nicely with pipes reading from files.
