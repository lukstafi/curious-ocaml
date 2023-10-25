Functional Programming



Lecture 4: Functions.

Programming in untyped $\lambda$-calculus.

*Introduction to Lambda Calculus* Henk Barendregt, Erik Barendsen

*Lecture Notes on the Lambda Calculus* Peter Selinger

# 1 Review: a “computation by hand” example

Let's compute some larger, recursive program.Recall that we use fix instead of 
let rec to simplify rules for recursion. Also remember our syntactic 
conventions: `fun x y -> e` stands for `fun x -> (fun y -> e)`, 
etc.

let rec fix f x = f (fix f) xPreparations.type intlist = Nil | Cons of int * 
intlistWe will evaluate (reduce) the following expression.let length =  fix 
(fun f l ->    match l with      | Nil -> 0      | Cons (x, xs) -> 
1 + f xs) inlength (Cons (1, (Cons (2, Nil))))

let length =  fix (fun f l ->    match l with      | Nil -> 0      | 
Cons (x, xs) -> 1 + f xs) inlength (Cons (1, (Cons (2, Nil))))

$$ \begin{matrix}
  \text{{\texttt{let }}} x = v \text{{\texttt{ in }}} a &
  \Downarrow & a [x := v]
\end{matrix} $$

  fix (fun f l ->    match l with      | Nil -> 0      | Cons (x, 
xs) -> 1 + f xs) (Cons (1, (Cons (2, Nil))))

$$ \begin{matrix}
  \text{{\texttt{fix}}}^2 v_{1} v_{2} &
  \Downarrow & v_{1}  \left(
  \text{{\texttt{fix}}}^2 v_{1} \right) v_{2}
\end{matrix} $$

$$ \begin{matrix}
  \text{{\texttt{fix}}}^2 v_{1} v_{2} &
  \Downarrow & v_{1}  \left(
  \text{{\texttt{fix}}}^2 v_{1} \right) v_{2}
\end{matrix} $$

  (fun f l ->    match l with      | Nil -> 0      | Cons (x, 
xs) -> 1 + f xs)     (fix (fun f l ->      match l with        | 
Nil -> 0        | Cons (x, xs) -> 1 + f xs))    (Cons (1, (Cons (2, 
Nil))))

$$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \rightsquigarrow & a [x := v]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1}' a_{2}
\end{matrix} $$

$$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \rightsquigarrow & a [x := v]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1}' a_{2}
\end{matrix} $$

  (fun l ->    match l with      | Nil -> 0      | Cons (x, xs) -> 
1 + (fix (fun f l ->        match l with          | Nil -> 0          
| Cons (x, xs) -> 1 + f xs)) xs)     (Cons (1, (Cons (2, Nil))))

$$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \Downarrow & a [x :=
  v]
\end{matrix} $$

$$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \Downarrow & a [x :=
  v]
\end{matrix} $$

  (match Cons (1, (Cons (2, Nil))) with    | Nil -> 0    | Cons (x, 
xs) -> 1 + (fix (fun f l ->      match l with        | Nil -> 0    
    | Cons (x, xs) -> 1 + f xs)) xs)

$$ \begin{matrix}
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})
  \text{{\texttt{ with}}} &  &  \\\\\\
  C_{2}^n (p_{1}, \ldots, p_{k}) \text{{\texttt{->}}} a
  \text{{\texttt{ \textbar }}} \operatorname{pm} &
  \Downarrow &
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})\\\\\\
  &  & \text{{\texttt{with}} } \operatorname{pm}
\end{matrix} $$

$$ \begin{matrix}
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})
  \text{{\texttt{ with}}} &  &  \\\\\\
  C_{2}^n (p_{1}, \ldots, p_{k}) \text{{\texttt{->}}} a
  \text{{\texttt{ \textbar }}} \operatorname{pm} &
  \Downarrow &
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})\\\\\\
  &  & \text{{\texttt{with}} } \operatorname{pm}
\end{matrix} $$

  (match Cons (1, (Cons (2, Nil))) with    | Cons (x, xs) -> 1 + (fix (fun 
f l ->      match l with        | Nil -> 0        | Cons (x, 
xs) -> 1 + f xs)) xs)

$$ \begin{matrix}
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})
  \text{{\texttt{ with}}} &  &  \\\\\\
  C_{1}^n (x_{1}, \ldots, x_{n}) \text{{\texttt{->}}} a
  \text{{\texttt{ \textbar }}} \ldots &
  \Downarrow & a [x_{1} := v_{1}
  ; \ldots ; x_{n} := v_{n}]
\end{matrix} $$

$$ \begin{matrix}
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})
  \text{{\texttt{ with}}} &  &  \\\\\\
  C_{1}^n (x_{1}, \ldots, x_{n}) \text{{\texttt{->}}} a
  \text{{\texttt{ \textbar }}} \ldots &
  \Downarrow & a [x_{1} := v_{1}
  ; \ldots ; x_{n} := v_{n}]
\end{matrix} $$

  1 + (fix (fun f l ->      match l with        | Nil -> 0        | 
Cons (x, xs) -> 1 + f xs)) (Cons (2, Nil))

$$ \begin{matrix}
  \text{{\texttt{fix}}}^2 v_{1} v_{2} & \rightsquigarrow & v_{1}
  \left( \text{{\texttt{fix}}}^2 v_{1} \right) v_{2}\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

$$ \begin{matrix}
  \text{{\texttt{fix}}}^2 v_{1} v_{2} & \rightsquigarrow & v_{1}
  \left( \text{{\texttt{fix}}}^2 v_{1} \right) v_{2}\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

  1 + (fun f l ->         match l with          | Nil -> 0          | 
Cons (x, xs) -> 1 + f xs))        (fix (fun f l ->           match l 
with             | Nil -> 0             | Cons (x, xs) -> 1 + f xs)) 
(Cons (2, Nil))

$$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \rightsquigarrow & a [x := v]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

$$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \rightsquigarrow & a [x := v]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

  1 + (fun l ->         match l with          | Nil -> 0          | 
Cons (x, xs) -> 1 + (fix (fun f l ->            match l with           
   | Nil -> 0              | Cons (x, xs) -> 1 + f xs)) xs))        
(Cons (2, Nil))

$$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \rightsquigarrow & a [x := v]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

$$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \rightsquigarrow & a [x := v]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

  1 + (match Cons (2, Nil) with         | Nil -> 0         | Cons (x, 
xs) -> 1 + (fix (fun f l ->           match l with             | 
Nil -> 0             | Cons (x, xs) -> 1 + f xs)) xs))

$$ \begin{matrix}
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})
  \text{{\texttt{ with}}} &  &  \\\\\\
  C_{2}^n (p_{1}, \ldots, p_{k}) \text{{\texttt{->}}} a
  \text{{\texttt{ \textbar }}} \operatorname{pm} & \rightsquigarrow &
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})\\\\\\
  &  & \text{{\texttt{with}} } \operatorname{pm}\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

$$ \begin{matrix}
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})
  \text{{\texttt{ with}}} &  &  \\\\\\
  C_{2}^n (p_{1}, \ldots, p_{k}) \text{{\texttt{->}}} a
  \text{{\texttt{ \textbar }}} \operatorname{pm} & \rightsquigarrow &
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})\\\\\\
  &  & \text{{\texttt{with}} } \operatorname{pm}\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

  1 + (match Cons (2, Nil) with         | Cons (x, xs) -> 1 + (fix (fun f 
l ->           match l with             | Nil -> 0             | Cons 
(x, xs) -> 1 + f xs)) xs)

$$ \begin{matrix}
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})
  \text{{\texttt{ with}}} &  &  \\\\\\
  C_{1}^n (x_{1}, \ldots, x_{n}) \text{{\texttt{->}}} a
  \text{{\texttt{ \textbar }}} \ldots &
  \Downarrow & a [x_{1} := v_{1}
  ; \ldots ; x_{n} := v_{n}]\\\\\\
  &  &
\end{matrix} $$

$$ \begin{matrix}
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})
  \text{{\texttt{ with}}} &  &  \\\\\\
  C_{1}^n (x_{1}, \ldots, x_{n}) \text{{\texttt{->}}} a
  \text{{\texttt{ \textbar }}} \ldots & \rightsquigarrow & a [x_{1}
  \:= v_{1} ; \ldots ; x_{n} := v_{n}]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

  1 + (1 + (fix (fun f l ->             match l with               | 
Nil -> 0               | Cons (x, xs) -> 1 + f xs)) Nil)

$$ \begin{matrix}
  \text{{\texttt{fix}}}^2 v_{1} v_{2} & \rightsquigarrow & v_{1}
  \left( \text{{\texttt{fix}}}^2 v_{1} \right) v_{2}\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

$$ \begin{matrix}
  \text{{\texttt{fix}}}^2 v_{1} v_{2} & \rightsquigarrow & v_{1}
  \left( \text{{\texttt{fix}}}^2 v_{1} \right) v_{2}\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

  1 + (1 + (fun f l ->             match l with               | Nil -> 
0               | Cons (x, xs) -> 1 + f xs) (fix (fun f l ->           
      match l with                   | Nil -> 0                   | Cons 
(x, xs) -> 1 + f xs)) Nil)

$$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \rightsquigarrow & a [x := v]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

$$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \rightsquigarrow & a [x := v]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

  1 + (1 + (fun l ->             match l with               | Nil -> 0 
              | Cons (x, xs) -> 1 + (fix (fun f l ->                 
match l with                   | Nil -> 0                   | Cons (x, 
xs) -> 1 + f xs)) xs) Nil)

$$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \rightsquigarrow & a [x := v]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

$$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} a
  \right) v & \rightsquigarrow & a [x := v]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

  1 + (1 + (match Nil with               | Nil -> 0               | Cons 
(x, xs) -> 1 + (fix (fun f l ->                 match l with           
        | Nil -> 0                   | Cons (x, xs) -> 1 + f xs)) xs))

$$ \begin{matrix}
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})
  \text{{\texttt{ with}}} &  &  \\\\\\
  C_{1}^n (x_{1}, \ldots, x_{n}) \text{{\texttt{->}}} a
  \text{{\texttt{ \textbar }}} \ldots & \rightsquigarrow & a [x_{1}
  \:= v_{1} ; \ldots ; x_{n} := v_{n}]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

$$ \begin{matrix}
  \text{{\texttt{match }}} C_{1}^n (v_{1}, \ldots, v_{n})
  \text{{\texttt{ with}}} &  &  \\\\\\
  C_{1}^n (x_{1}, \ldots, x_{n}) \text{{\texttt{->}}} a
  \text{{\texttt{ \textbar }}} \ldots & \rightsquigarrow & a [x_{1}
  \:= v_{1} ; \ldots ; x_{n} := v_{n}]\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

  1 + (1 + 0)

$$ \begin{matrix}
  f^n v_{1} \ldots v_{n} & \rightsquigarrow & f (v_{1}, \ldots,
  v_{n})\\\\\\
  a_{1} a_{2} & \Downarrow &
  a_{1} a_{2}'
\end{matrix} $$

  1 + 1

$$ \begin{matrix}
  f^n v_{1} \ldots v_{n} &
  \Downarrow & f (v_{1}, \ldots,
  v_{n})
\end{matrix} $$

  2

# 2 Language and rules of the untyped $\lambda$-calculus

* First, let's forget about types.
* Next, let's introduce a shortcut:
  * We write $\lambda x.a$ for `fun x->a`, $\lambda x y.a$ for `fun x 
    y->a`, etc.
* Let's forget about all other constructions, only fun and variables.
* The real $\lambda$-calculus has a more general reduction:

  $$ \begin{matrix}
  \left( \text{{\texttt{fun }}} x \text{{\texttt{->}}}
  a_{1} \right) a_{2} & \rightsquigarrow & a_{1} [x := a_{2}] \end{matrix} $$

  (called *$\beta$-reduction*) and uses *bound variable renaming* 
  (called *$\alpha$-conversion*), or some other trick, to avoid *variable 
  capture*. But let's not over-complicate things.
  * We will look into the $\beta$-reduction rule in the **laziness** lecture.
  * Why is $\beta$-reduction more general than the rule we use?



# 3 Booleans

* Alonzo Church introduced $\lambda$-calculus to encode logic.
* There are multiple ways to encode various sorts of data in 
  $\lambda$-calculus. Not all of them make sense in a typed setting, i.e. the 
  straightforward encode/decode functions do not type-check for them.
* Define `c_true`=$\lambda x y.x$ and `c_false`=$\lambda x y.y$.
* Define `c_and`=$\lambda x y.x y \text{{\texttt{c\_false}}}$. Check 
  that it works!
  * I.e. that `c_and c_true c_true` = `c_true`,otherwise `c_and a b` = 
    `c_false`.

let ctrue = fun x y -> x‘‘True'' is projection on the first argument.let 
cfalse = fun x y -> yAnd ‘‘false'' on the second argument.let cand = fun x 
y -> x y cfalseIf one is false, then return false.let encodebool b = if b 
then ctrue else cfalselet decodebool c = c true falseTest the functions in the 
toplevel.

* Define `c_or` and `c_not` yourself!

# 4 If-then-else and pairs

* We will just use the OCaml syntax from now.

let ifthenelse = fun b -> bBooleans select the argument!

Remember to play with the functions in the toplevel.

let cpair m n = fun x -> x m nWe couple thingslet cfirst = fun p -> p 
ctrueby passing them together.let csecond = fun p -> p cfalseCheck that it 
works!

let encodepair encfst encsnd (a, b) =  cpair (encfst a) (encsnd b)let decodepair defst desnd c = c (fun x y -> defst x, desnd y)let decodeboolpair c = decodepair decodebool decodebool c

* We can define larger tuples in the same manner:

  let ctriple l m n = fun x -> x l m n



# 5 Pair-encoded natural numbers

* Our first encoding of natural numbers is as the depth of nested pairs whose 
  rightmost leaf is $\lambda x.x$ and whose left elements are `c_false`.

let pn0 = fun x -> xStart with the identity function.let pnsucc n = cpair 
cfalse nStack another pair.let pnpred = fun x -> x cfalse[Explain these 
functions.]let pniszero = fun x -> x ctrue

We program in untyped lambda calculus as an exercise, and we need encoding / 
decoding to verify our exercises, so using “magic” for encoding / decoding is 
“fair game”.

let rec encodepnat n =We use Obj.`magic` to forget types.  if n $<$= 0 
then Obj.magic pn0  else pnsucc (Obj.magic (encodepnat (n-1)))Disregarding 
types,let rec decodepnat pn =these functions are straightforward!  if 
decodebool (pniszero pn) then 0  else 1 + decodepnat (pnpred (Obj.magic pn))

# 6 Church numerals (natural numbers in Ch. enc.)

* Do you remember our function `power f n`? We will use its variant for a 
  different representation of numbers:

let cn0 = fun f x -> xThe same as `c_false`.let cn1 = fun f x -> f 
xBehaves like identity.let cn2 = fun f x -> f (f x)let cn3 = fun f 
x -> f (f (f x))

* This is the original Alonzo Church encoding.

let cnsucc = fun n f x -> f (n f x)

* Define addition, multiplication, comparing to zero, and the predecesor 
  function “-1” for Church numerals.
* Turns out even Alozno Church couldn't define predecesor right away! But try 
  to make some progress before you turn to the next slide.
  * His student Stephen Kleene found it.

let rec encodecnat n f =  if n $<$= 0 then (fun x -> x) else f -| 
encodecnat (n-1) flet decodecnat n = n ((+) 1) 0let cn7 f x = encodecnat 7 f 
xWe need to *$\eta$-expand* these definitionslet cn13 f x = encodecnat 13 f 
xfor type-system reasons.(Because OCaml allows *side-effects*.)let cnadd = fun 
n m f x -> n f (m f x)Put `n` of `f` in front.let cnmult = fun n m 
f -> n (m f)Repeat `n` timesputting `m` of `f` in front.let cnprev n =  
fun f x ->This is the ‘‘Church numeral signature''.    nThe only thing we 
have is an `n`-step loop.      (fun g v -> v (g f))We need sth that 
operates on `f`.      (fun z->x)We need to ignore the innermost step.      
(fun z->z)We've build a ‘‘machine'' not results -- start the machine.

`cn_is_zero` left as an exercise.

decodecnat (cn\_prev cn3)

$$ \Downarrow $$

(cn\_prev cn3) ((+) 1) 0

$$ \Downarrow $$

(fun f x ->    cn3      (fun g v -> v (g f))      (fun z->x)      
(fun z->z)) ((+) 1) 0

$$ \Downarrow $$

((fun f x -> f (f (f x)))      (fun g v -> v (g ((+) 1)))      (fun 
z->0)      (fun z->z))

$$ \Downarrow $$

((fun g v -> v (g ((+) 1)))  ((fun g v -> v (g ((+) 1)))    ((fun g 
v -> v (g ((+) 1)))      (fun z->0))))  (fun z->z))

$$ \Downarrow $$

((fun z->z)  (((fun g v -> v (g ((+) 1)))    ((fun g v -> v (g 
((+) 1)))      (fun z->0)))) ((+) 1)))

$$ \Downarrow $$

(fun g v -> v (g ((+) 1)))  ((fun g v -> v (g ((+) 1)))    (fun 
z->0)) ((+) 1)

$$ \Downarrow $$

((+) 1) ((fun g v -> v (g ((+) 1)))          (fun z->0) ((+) 1))

$$ \Downarrow $$

((+) 1) (((+) 1) ((fun z->0) ((+) 1)))

$$ \Downarrow $$

((+) 1) (((+) 1) (0))

$$ \Downarrow $$

((+) 1) 1

$$ \Downarrow $$

2

# 7 Recursion: Fixpoint Combinator

* Turing's fixpoint combinator: $\Theta = (\lambda x y.y (x x y))  (\lambda x 
  y.y (x x y))$

  $$ \begin{matrix}
  N & = & \Theta F\\\\\\
  & = & (\lambda x y.y (x x y))  (\lambda x y.y (x x y)) F\\\\\\
  & =_{\rightarrow \rightarrow} & F ((\lambda x y.y (x x y))  (\lambda x y.y
  (x x y)) F)\\\\\\
  & = & F (\Theta F) = F N \end{matrix} $$
* Curry's fixpoint combinator: $\boldsymbol{Y}= \lambda f. (\lambda x.f (x x)) 
   (\lambda x.f (x x))$

  $$ \begin{matrix}
  N & = & \boldsymbol{Y}F\\\\\\
  & = & (\lambda f. (\lambda x.f (x x))  (\lambda x.f (x x))) F\\\\\\
  & =_{\rightarrow} & (\lambda x.F (x x))  (\lambda x.F (x x))\\\\\\
  & =_{\rightarrow} & F ((\lambda x.F (x x))  (\lambda x.F (x x)))\\\\\\
  & =_{\leftarrow} & F ((\lambda f. (\lambda x.f (x x))  (\lambda x.f (x
  x))) F)\\\\\\
  & = & F (\boldsymbol{Y}F) = F N \end{matrix} $$
* Call-by-value *fix*point combinator: $\lambda f' . (\lambda f x.f'  (f f) x) 
   (\lambda f x.f'  (f f) x)$

  $$ \begin{matrix}
  N & = & \operatorname{fix}F\\\\\\
  & = & (\lambda f' . (\lambda f x.f'  (f f) x)  (\lambda f x.f'  (f f) x))
  F\\\\\\
  & =_{\rightarrow} & (\lambda f x.F (f f) x)  (\lambda f x.F (f f) x)\\\\\\
  & =_{\rightarrow} & \lambda x.F ((\lambda f x.F (f f) x)  (\lambda f x.F
  (f f) x)) x\\\\\\
  & =_{\leftarrow} & \lambda x.F ((\lambda f' . (\lambda f x.f'  (f f) x)
  (\lambda f x.f'  (f f) x)) F) x\\\\\\
  & = & \lambda x.F (\operatorname{fix}F) x = \lambda x.F N x\\\\\\
  & =_{\eta} & F N \end{matrix} $$
* The $\lambda$-terms we have seen above are **fixpoint combinators** – means 
  inside $\lambda$-calculus to perform recursion.
* What is the problem with the first two combinators?

  $$ \begin{matrix}
  \Theta F & \rightsquigarrow \rightsquigarrow & F ((\lambda x y.y (x x y))
  (\lambda x y.y (x x y)) F)\\\\\\
  & \rightsquigarrow \rightsquigarrow & F (F ((\lambda x y.y (x x y))
  (\lambda x y.y (x x y)) F))\\\\\\
  & \rightsquigarrow \rightsquigarrow & F (F (F ((\lambda x y.y (x x y))
  (\lambda x y.y (x x y)) F)))\\\\\\
  & \rightsquigarrow \rightsquigarrow & \ldots \end{matrix} $$
* Recall the distinction between *expressions* and *values* from the previous 
  lecture *Computation*.
* The reduction rule for $\lambda$-calculus is just meant to determine which 
  expressions are considered “equal” – it is highly *non-deterministic*, while 
  on a computer, computation needs to go one way or another.
* Using the general reduction rule of $\lambda$-calculus, for a recursive 
  definition, it is always possible to find an infinite reduction sequence 
  (which means that you couldn't complain when a nasty $\lambda$-calculus 
  compiler generates infinite loops for all recursive definitions).
  * Why?
* Therefore, we need more specific rules. For example, most languages use 
  $\left( \text{{\texttt{fun }}} x \text{{\texttt{->}}} 
  a \right) v \rightsquigarrow a [x := v]$, which is called *call-by-value*, 
  or **eager** computation (because the program *eagerly* computes the 
  arguments before starting to compute the function). (It's exactly the rule 
  we introduced in *Computation* lecture.)
* What happens with call-by-value fixpoint combinator?

  $$ \begin{matrix}
  \operatorname{fix}F & \rightsquigarrow & (\lambda f x.F (f f) x)  (\lambda f
  x.F (f f) x)\\\\\\
  & \rightsquigarrow & \lambda x.F ((\lambda f x.F (f f) x)  (\lambda f x.F
  (f f) x)) x \end{matrix} $$

  Voila – if we use $\left( \text{{\texttt{fun }}} x 
  \text{{\texttt{->}}} a \right) v \rightsquigarrow a [x := v]$ 
  as the rulerather than $\left( \text{{\texttt{fun }}} x 
  \text{{\texttt{->}}} a_{1} \right) a_{2} \rightsquigarrow 
  a_{1} [x := a_{2}]$, the computation stops. Let's compute the function on 
  some input:

  $$ \begin{matrix}
  \operatorname{fix}F v & \rightsquigarrow & (\lambda f x.F (f f) x)  (\lambda
  f x.F (f f) x) v\\\\\\
  & \rightsquigarrow & (\lambda x.F ((\lambda f x.F (f f) x)  (\lambda f x.F
  (f f) x)) x) v\\\\\\
  & \rightsquigarrow & F ((\lambda f x.F (f f) x)  (\lambda f x.F (f f) x))
  v\\\\\\
  & \rightsquigarrow & F (\lambda x.F ((\lambda f x.F (f f) x)  (\lambda f
  x.F (f f) x)) x) v\\\\\\
  & \rightsquigarrow & \text{depends on } F \end{matrix} $$
* Why the name *fixpoint*? If you look at our derivations, you'll see that 
  they show what in math can be written as $x = f (x)$. Such values $x$ are 
  called fixpoints of $f$. An arithmetic function can have several fixpoints, 
  for example $f (x) = x^2$ (which $x$es are fixpoints?) or no fixpoints, for 
  example $f (x) = x + 1$.
* When you define a function (or another object) by recursion, it has very 
  similar meaning: there is a name that is on both sides of $=$.
* In $\lambda$-calculus, there are functions like $\Theta$ and 
  $\boldsymbol{Y}$, that take *any* function as an argument, and return its 
  fixpoint.
* We turn a specification of a recursive object into a definition, by solving 
  it with respect to the recurring name: deriving $x = f (x)$ where $x$ is the 
  recurring name. We then have $x =\operatorname{fix} (f)$.
* Let's walk through it for the factorial function (we omit the prefix `cn_` – 
  could be `pn_` if `pn1` was used instead of `cn1` – for numeric functions, 
  and we shorten `if_then_else` into `if_t_e`):

  $$ \begin{matrix}
  \text{{\texttt{fact}}} n & = & \text{{\texttt{if\_t\_e}}}
  \left( \text{{\texttt{is\_zero}}} n \right)
  \text{{\texttt{cn1}}}  \left( \text{{\texttt{mult}}} n
  \left( \text{{\texttt{fact}}}  \left(
  \text{{\texttt{pred}}} n \right) \right) \right)\\\\\\
  \text{{\texttt{fact}}} & = & \lambda n.
  \text{{\texttt{if\_t\_e}}}  \left(
  \text{{\texttt{is\_zero}}} n \right)
  \text{{\texttt{cn1}}}  \left( \text{{\texttt{mult}}} n
  \left( \text{{\texttt{fact}}}  \left(
  \text{{\texttt{pred}}} n \right) \right) \right)\\\\\\
  \text{{\texttt{fact}}} & = & \left( \lambda f n.
  \text{{\texttt{if\_t\_e}}}  \left(
  \text{{\texttt{is\_zero}}} n \right)
  \text{{\texttt{cn1}}}  \left( \text{{\texttt{mult}}} n
  \left( f \left( \text{{\texttt{pred}}} n \right) \right) \right)
  \right)  \text{{\texttt{fact}}}\\\\\\
  \text{{\texttt{fact}}} & = & \operatorname{fix} \left( \lambda f n.
  \text{{\texttt{if\_t\_e}}}  \left(
  \text{{\texttt{is\_zero}}} n \right)
  \text{{\texttt{cn1}}}  \left( \text{{\texttt{mult}}} n
  \left( f \left( \text{{\texttt{pred}}} n \right) \right) \right)
  \right) \end{matrix} $$

  The last specification is a valid definition: we just give a name to a 
  (*ground*, a.k.a. *closed*) expression.
* We have seen how fix works already!
  * Compute `fact cn2`.
* What does `fix (fun x -> cn_succ x)` mean?

# 8 Encoding of Lists and Trees

* A list is either empty, which we often call `Empty` or `Nil`, or it consists 
  of an element followed by another list (called “tail”), the other case often 
  called `Cons`.
* Define `nil`$= \lambda x y.y$ and `cons`$H T = \lambda x y.x H T$.
* Add numbers stored inside a list:

  $$ \begin{matrix}
  \text{{\texttt{addlist}}} l & = & l \left( \lambda h t.
  \text{{\texttt{cn\_add}}} h \left(
  \text{{\texttt{addlist}}} t \right) \right)
  \text{{\texttt{cn0}}} \end{matrix} $$

  To make a proper definition, we need to apply $\operatorname{fix}$ to the 
  solution of above equation.

  $$ \begin{matrix}
  \text{{\texttt{addlist}}} & = & \operatorname{fix} \left( \lambda f
  l.l \left( \lambda h t. \text{{\texttt{cn\_add}}} h (f t) \right)
  \text{{\texttt{cn0}}} \right) \end{matrix} $$
* For trees, let's use a different form of binary trees than so far: instead 
  of keeping elements in inner nodes, we will keep elements in leaves.
* Define `leaf`$n = \lambda x y.x n$ and `node`$L R = \lambda x y.y L R$.
* Add numbers stored inside a tree:

  $$ \begin{matrix}
  \text{{\texttt{addtree}}} t & = & t (\lambda n.n)  \left( \lambda l
  r. \text{{\texttt{cn\_add}}}  \left(
  \text{{\texttt{addtree}}} l \right)  \left(
  \text{{\texttt{addtree}}} r \right) \right) \end{matrix} $$

  and, in solved form:

  $$ \begin{matrix}
  \text{{\texttt{addtree}}} & = & \operatorname{fix} \left( \lambda f
  t.t (\lambda n.n)  \left( \lambda l r. \text{{\texttt{cn\_add}}}
  (f l)  (f r) \right) \right) \end{matrix} $$

let nil = fun x y -> ylet cons h t = fun x y -> x h tlet addlist l =  
fix (fun f l -> l (fun h t -> cnadd h (f t)) cn0) l;;decodecnat  
(addlist (cons cn1 (cons cn2 (cons cn7 nil))));;let leaf n = fun x y -> x 
nlet node l r = fun x y -> y l rlet addtree t =  fix (fun f t ->    t 
(fun n -> n) (fun l r -> cnadd (f l) (f r))  ) t;;decodecnat  (addtree 
(node (node (leaf cn3) (leaf cn7))              (leaf cn1)));;

* Observe a regularity: when we encode a variant type with $n$ variants, for 
  each variant we define a function that takes $n$ arguments.
* If the $k$th variant $C_{k}$ has $m_{k}$ parameters, then the function 
  $c_{k}$ that encodes it will have the form:

  $$ C_{k} (v_{1}, \ldots, v_{m_{k}}) \sim c_{k} v_{1} \ldots 
  v_{m_{k}}
   = \lambda x_{1} \ldots x_{n} .x_{k} v_{1} \ldots v_{m_{k}} $$
* The encoded variants serve as a shallow pattern matching with guaranteed 
  exhaustiveness: $k$th argument corresponds to $k$th branch of pattern 
  matching.

# 9 Looping Recursion

* Let's come back to numbers defined as lengths lists and define addition:

let pnadd m n =  fix (fun f m n ->    ifthenelse (pniszero m)      n 
(pnsucc (f (pnpred m) n))  ) m n;;decodepnat (pnadd pn3 pn3);;

* Oops… OCaml says:`Stack overflow during evaluation (looping 
  recursion?).`
* What is wrong? Nothing as far as $\lambda$-calculus is concerned. But OCaml 
  and F# always compute arguments before calling a function. By definition of 
  fix, `f` corresponds to recursively calling `pn_add`. Therefore,(pnsucc (f 
  (pnpred m) n)) will be called regardless of what(pniszero m) returns!
* Why `addlist` and `addtree` work?
* `addlist` and `addtree` work because their recursive calls are “guarded” by 
  corresponding fun. What is inside of fun is not computed immediately, only 
  when the function is applied to argument(s).
* To avoid looping recursion, you need to guard all recursive calls. Besides 
  putting them inside fun, in OCaml or F# you can also put them in branches of 
  a match clause, as long as one of the branches does not have unguarded 
  recursive calls!
* The trick to use with functions like `if_then_else`, is to guard their 
  arguments with fun `x` ->, where `x` is not used, and apply the *result* 
  of `if_then_else` to some dummy value.
  * In OCaml or F# we would guard by fun () ->, and then apply to (), but 
    we do not have datatypes like `unit` in $\lambda$-calculus.

let pnadd m n =  fix (fun f m n ->    (ifthenelse (pniszero m)       (fun 
x -> n) (fun x -> pnsucc (f (pnpred m) n)))      id  ) m n;;decodepnat 
(pnadd pn3 pn3);;decodepnat (pnadd pn3 pn7);;

# 10 In-class Work and Homework


   Define (implement) and verify:
1. `c_or` and `c_not`;
1. exponentiation for Church numerals;
1. is-zero predicate for Church numerals;
1. even-number predicate for Church numerals;
1. multiplication for pair-encoded natural numbers;
1. factorial $n!$ for pair-encoded natural numbers.
1. Construct $\lambda$-terms $m_{0}, m_{1}, \ldots$ such that for all $n$ 
   one has:

   $$ \begin{matrix}
   m_{0} & = & x \\\\\\
   m_{n + 1} & = & m_{n + 2} m_{n} \end{matrix} $$

   (where equality is after performing $\beta$-reductions).
1. Define (implement) and verify a function computing: the length of a list 
   (in Church numerals);
1. `cn_max` – maximum of two Church numerals;
1. the depth of a tree (in Church numerals).
1. Representing side-effects as an explicitly “passed around” state value, 
   write combinators that represent the imperative constructs:
   1. for…to…
   1. for…downto…
   1. while…do…
   1. do…while…
   1. repeat…until…

   Rather than writing a $\lambda$-term using the encodings that we've learnt, 
   just implement the functions in OCaml / F#, using built-in int and bool 
   types. You can use let rec instead of fix.
   * For example, in exercise (a), write a function let rec `for_to f beg_i 
     end_i s` =… where `f` takes arguments `i` ranging from `beg_i` to 
     `end_i`, state `s` at given step, and returns state `s` at next step; the 
     `for_to` function returns the state after the last step.
   * And in exercise (c), write a function let rec `while_do p f s` =… 
     where both `p` and `f` take state `s` at given step, and if `p s` returns 
     true, then `f s` is computed to obtain state at next step; the `while_do` 
     function returns the state after the last step.

   Do not use the imperative features of OCaml and F#, we will not even cover 
   them in this course!

Despite we will not cover them, it is instructive to see the implementation 
using the imperative features, to better understand what is actually required 
of a solution to the last exercise.

1. let forto f begi endi s =  let s = ref s in  for i = begi to endi do    
   s := f i !s  done;  !s
1. let fordownto f begi endi s =  let s = ref s in  for i = begi downto endi 
   do    s := f i !s  done;  !s
1. let whiledo p f s =  let s = ref s in  while p !s do    s := f !s  done;  
   !s
1. let dowhile p f s =  let s = ref (f s) in  while p !s do    s := f !s  
   done;  !s
1. let repeatuntil p f s =  let s = ref (f s) in  while not (p !s) do    s := 
   f !s  done;  !s
