Functional Programming



Lecture 7: Laziness

Lazy evaluation. Stream processing.

M. Douglas McIlroy *‘‘Power Series, Power Serious''*

Oleg Kiselyov, Simon Peyton-Jones, Amr Sabry *‘‘Lazy v. Yield: Incremental,
Linear Pretty-Printing''*

If you see any error on the slides, let me know!

# 1 Laziness

* Today's lecture is about lazy evaluation.
* Thank you for coming, goodbye!
* But perhaps, do you have any questions?

# 2 Evaluation strategies and parameter passing

* **Evaluation strategy** is the order in which expressions are computed.
  * For the most part: when are arguments computed.
* Recall our problems with using *flow control* expressions like 
  `if_then_else` in examples from $\lambda$-calculus lecture.
* There are many technical terms describing various strategies. Wikipedia:

  Strict evaluationArguments are always evaluated completely before function 
  is
  applied.
Non-strict evaluationArguments are not evaluated unless they are actually used
  in the evaluation of the function body.
Eager evaluationAn expression is evaluated as soon as it gets bound to a
  variable.
Lazy evaluationNon-strict evaluation which avoids repeating computation.
Call-by-valueThe argument expression is evaluated, and the resulting value is
  bound to the corresponding variable in the function (frequently by copying
  the value into a new memory region).
Call-by-referenceA function receives an implicit reference to a variable used
  as argument, rather than a copy of its value.
  * In purely functional languages there is no difference between the two
    strategies, so they are typically described as call-by-value even though
    implementations use call-by-reference internally for efficiency.
  * Call-by-value languages like C and OCaml support explicit references
    (objects that refer to other objects), and these can be used to simulate
    call-by-reference.
Normal order Start computing function bodies before evaluating their
  arguments. Do not even wait for arguments if they are not needed.
Call-by-nameArguments are substituted directly into the function body and then
  left to be evaluated whenever they appear in the function.
Call-by-needIf the function argument is evaluated, that value is stored for
  subsequent uses.
* Almost all languages do not compute inside the body of un-applied function, 
  but with curried functions you can pre-compute data before all arguments are 
  provided.
  * Recall the `search_bible` example.
* In eager / call-by-value languages we can simulate call-by-name by taking a 
  function to compute the value as an argument instead of the value directly.
  * ”Our” languages have a `unit` type with a single value () specifically for 
    use as throw-away arguments.
  * Scala has a built-in support for call-by-name (i.e. direct, without the 
    need to build argument functions).
* ML languages have built-in support for lazy evaluation.
* Haskell has built-in support for eager evaluation.

# 3 Call-by-name: streams

* Call-by-name is useful not only for implementing flow control
  * let ifthenelse cond e1 e2 =  match cond with true -> e1 () | 
    false -> e2 ()

  but also for arguments of value constructors, i.e. for data structures.
* **Streams** are lists with call-by-name tails.

  type 'a stream = SNil | SCons of 'a \* (unit -> 'a stream)
* Reading from a stream into a list.

  let rec stake n = function | SCons (a, s) when n > 0 -> a::(stake 
  (n-1) (s ())) |  -> []
* Streams can easily be infinite.

  let rec sones = SCons (1, fun () -> sones)let rec sfrom n =  SCons (n, 
  fun () ->sfrom (n+1))
* Streams admit list-like operations.

  let rec smap f = function | SNil -> SNil | SCons (a, s) -> SCons (f 
  a, fun () -> smap f (s ()))let rec szip = function | SNil, SNil -> 
  SNil | SCons (a1, s1), SCons (a2, s2) ->     SCons ((a1, a2), fun 
  () -> szip (s1 (), s2 ())) |  -> raise (Invalidargument "szip")
* Streams can provide scaffolding for recursive algorithms:

  let rec sfib =  SCons (1, fun () -> smap (fun (a,b)-> a+b)    (szip 
  (sfib, SCons (1, fun () -> sfib))))

  <table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td></td>
  </tr><tr>
    <td>    </td>
  </tr><tr>
    <td>    </td>
  </tr></tbody>

  </table>-3.45314-0.974534-3.85530493451515-0.297195396216431-3.262633946289190.020306918904617-3.89764-0.254862-3.876471755523220.464810160074084-3.241467125281120.930480222251621-2.33129-1.0592-2.60646249503903-0.276028575208361-2.267793358909910.0414737399126869-1.46345-0.9957-1.73862283370816-0.276028575208361-1.442287339595180.0626405609207567-1.73862-0.254862-2.013791506813070.676478370154782-1.548121444635531.03631432729197-2.62763-0.276029-2.796963884111650.507143802090224-2.373627463950261.0151475062839+-3.7833-0.582834+-2.55958-0.567776+-1.69025-0.5390640cm
* Streams are less functional than could be expected in context of 
  input-output effects.

  let filestream name =  let ch = openin name in  let rec chreadline () =    
  try SCons (inputline ch, chreadline)    with Endoffile -> SNil in  
  chreadline ()
* *OCaml Batteries* use a stream type `enum` for interfacing between various 
  sequence-like data types.
  * The safest way to use streams in a *linear* / *ephemeral* manner: every 
    value used only once.
  * Streams minimize space consumption at the expense of time for 
    recomputation.

# 4 Lazy values

* Lazy evaluation is more general than call-by-need as any value can be lazy, 
  not only a function parameter.
* A *lazy value* is a value that “holds” an expression until its result is 
  needed, and from then on it “holds” the result.
  * Also called: a *suspension*. If it holds the expression, called a *thunk*.
* In OCaml, we build lazy values explicitly. In Haskell, all values are lazy 
  but functions can have call-by-value parameters which “need” the argument.
* To create a lazy value: lazy expr – where `expr` is the suspended 
  computation.
* Two ways to use a lazy value, be careful when the result is computed!
  * In expressions: Lazy.force l\_expr
  * In patterns: match lexpr with lazy v -> …
    * Syntactically lazy behaves like a data constructor.
* Lazy lists:

  type 'a llist = LNil | LCons of 'a \* 'a llist Lazy.t
* Reading from a lazy list into a list:

  let rec ltake n = function | LCons (a, lazy l) when n > 0 -> 
  a::(ltake (n-1) l) |  -> []
* Lazy lists can easily be infinite:

  let rec lones = LCons (1, lazy lones)let rec lfrom n = LCons (n, lazy (lfrom 
  (n+1)))
* Read once, access multiple times:

  let filellist name =  let ch = openin name in  let rec chreadline () =    
  try LCons (inputline ch, lazy (chreadline ()))    with Endoffile -> LNil 
  in  chreadline ()
* let rec lzip = function | LNil, LNil -> LNil | LCons (a1, ll1), LCons 
  (a2, ll2) ->     LCons ((a1, a2), lazy (       lzip (Lazy.force ll1, 
  Lazy.force ll2))) |  -> raise (Invalidargument "lzip")

  let rec lmap f = function | LNil -> LNil | LCons (a, ll) ->   LCons 
  (f a, lazy (lmap f (Lazy.force ll)))
* let posnums = lfrom 1let rec lfact =  LCons (1, lazy (lmap (fun (a,b)-> 
  a\*b)                    (lzip (lfact, posnums))))

  <table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td></td>
  </tr><tr>
    <td>    </td>
  </tr><tr>
    <td>    </td>
  </tr></tbody>

  </table>-3.24858-1.02259-3.5449133483265-0.239416589495965-3.290911496229660.0569189046170128-2.40191-1.00142-2.65590686598756-0.281750231512105-2.380738192882660.0145852626008731-1.5129-0.980255-1.70339992062442-0.218249768487895-1.512898531551790.0145852626008731-0.327557-1.02259-0.772059796269348-0.0489152004233364-0.3063897340918110.1839198306654320.878952-1.022590.392115359174494-0.2394165894959650.6037835692551920.0780857256250827-3.56608-0.260583-3.629580632358780.691923534859108-3.33324513824581.03059267098823-2.67707-0.260583-2.69824050800370.734257176875248-2.42307183489881.0517594919963-1.7034-0.21825-1.872734488688980.670756713851039-1.555232173567931.0517594919963-0.77206-0.0489152-0.9413943643339070.903591744939807-0.6238920492128591.094093134012440.392115-0.2394170.2862812541341450.6284230718348990.6249503902632621.0517594919963*-2.60922-0.546619*-1.66302-0.503353*-0.632667-0.5082*0.504955-0.500198*-3.48713460768869-0.5100825754830590cm

# 5 Power series and differential equations

* Differential equations idea due to Henning Thielemann. **Just an example.**
* Expression $P (x) = \sum\_{i = 0}^n a\_{i} x^i$ defines a polynomial for $n 
  < \infty$ and a power series for $n = \infty$.
* If we define

  let rec lfoldright f l base =  match l with    | LNil -> base    | LCons 
  (a, lazy l) -> f a (lfoldright f l base)

  then we can compute polynomials

  let horner x l =  lfoldright (fun c sum -> c +. x \*. sum) l 0.
* But it will not work for infinite power series!
  * Does it make sense to compute the value at $x$ of a power series?
  * Does it make sense to fold an infinite list?
* If the power series converges for $x > 1$, then when the elements 
  $a\_{n}$ get small, the remaining sum $\sum\_{i = n}^{\infty} a\_{i} x^i$ is 
  also small.
* `lfold_right` falls into an infinite loop on infinite lists. We need 
  call-by-name / call-by-need semantics for the argument function `f`.

  let rec lazyfoldr f l base =  match l with    | LNil -> base    | LCons 
  (a, ll) ->      f a (lazy (lazyfoldr f (Lazy.force ll) base))
* We need a stopping condition in the Horner algorithm step:

  let lhorner x l =This is a bit of a hack,  let upd c sum =we hope to ‘‘hit'' 
  the interval $(0, \varepsilon]$.    if c = 0. || absfloat c > 
  epsilonfloat    then c +. x \*. Lazy.force sum    else 0. in  lazyfoldr upd 
  l 0.

  let invfact = lmap (fun n -> 1. /. floatofint n) lfactlet e = lhorner 1. 
  invfact

## 5.1 Power series / polynomial operations

* let rec add xs ys =  match xs, ys with    | LNil,  -> ys    | , 
  LNil -> xs    | LCons (x,xs), LCons (y,ys) ->      LCons (x +. y, 
  lazy (add (Lazy.force xs) (Lazy.force ys)))
* let rec sub xs ys =  match xs, ys with    | LNil,  -> lmap (fun x-> 
  $\sim$-.x) ys    | , LNil -> xs    | LCons (x,xs), LCons (y,ys) ->   
     LCons (x-.y, lazy (add (Lazy.force xs) (Lazy.force ys)))
* let scale s = lmap (fun x->s\*.x)
* let rec shift n xs =  if n = 0 then xs  else if n > 0 then LCons (0. , 
  lazy (shift (n-1) xs))  else match xs with    | LNil -> LNil    | LCons 
  (0., lazy xs) -> shift (n+1) xs    |  -> failwith "shift: fractional 
  division"
* let rec mul xs = function  | LNil -> LNil  | LCons (y, ys) ->    add 
  (scale y xs) (LCons (0., lazy (mul xs (Lazy.force ys))))
* let rec div xs ys =  match xs, ys with  | LNil,  -> LNil  | LCons (0., 
  xs'), LCons (0., ys') ->    div (Lazy.force xs') (Lazy.force ys')  | 
  LCons (x, xs'), LCons (y, ys') ->    let q = x /. y in    LCons (q, lazy 
  (divSeries (sub (Lazy.force xs')                                 (scale q 
  (Lazy.force ys'))) ys))  | LCons , LNil -> failwith "divSeries: division 
  by zero"
* let integrate c xs =  LCons (c, lazy (lmap (uncurry (/.)) (lzip (xs, 
  posnums))))
* let ltail = function  | LNil -> invalidarg "ltail"  | LCons (, lazy 
  tl) -> tl
* let differentiate xs =  lmap (uncurry ( \*.)) (lzip (ltail xs, posnums))

## 5.2 Differential equations

* $\frac{\mathrm{d} \sin x}{\mathrm{d} x} = \cos x, \frac{\mathrm{d} \cos 
  x}{\mathrm{d} x} = - \sin x, \sin 0 = 0, \cos 0 = 1$.
* We will solve the corresponding integral equations. *Why?*
* We cannot define the integral by direct recursion like this:

  let rec sin = integrate (ofint 0) cosUnary op. let ($\sim$-:) =and cos = 
  integrate (ofint 1) $\sim$-:sin lmap (fun x-> $\sim$-.x)

  unfortunately fails:

  `Error: This kind of expression is not allowed as right-hand side of ‘let 
  rec'`
  * Even changing the second argument of `integrate` to call-by-need does not 
    help, because OCaml cannot represent the values that `x` and `y` refer to.
* We need to inline a bit of `integrate` so that OCaml knows how to start 
  building the recursive structure.

  let integ xs = lmap (uncurry (/.)) (lzip (xs, posnums))let rec sin = LCons 
  (ofint 0, lazy (integ cos))and cos = LCons (ofint 1, lazy (integ 
  $\sim$-:sin))
* The complete example would look much more elegant in Haskell.
* Although this approach is not limited to linear equations, equations like 
  Lotka-Volterra or Lorentz are not “solvable” – computed coefficients quickly 
  grow instead of quickly falling…
* Drawing functions are like in previous lecture, but with open curves.
* let plot1D f $\sim$w $\sim$scale $\sim$tbeg $\sim$tend =  let dt = (tend -. 
  tbeg) /. ofint w in  Array.init w (fun i ->    let y = lhorner (dt \*. 
  ofint i) f in    i, to\_int (scale \*. y))

# 6 Arbitrary precision computation

* Putting it all together reveals drastic numerical errors for large $x$.

  let graph =  let scale = ofint h /. ofint 8 in  [plot1D sin $\sim$w 
  $\sim$h0:(h/2) $\sim$scale      $\sim$tbeg:(ofint 0) $\sim$tend:(ofint 15),  
   (250,250,0);   plot1D cos $\sim$w $\sim$h0:(h/2) $\sim$scale     
  $\sim$tbeg:(ofint 0) $\sim$tend:(ofint 15),   (250,0,250)]let () = 
  drawtoscreen $\sim$w $\sim$h graph
  * Floating-point numbers have limited precision.
  * We break out of Horner method computations too quickly.

  ![](sin_cos_1.eps)
* For infinite precision on rational numbers we use the `nums` library.
  * It does not help – yet.
* Generate a sequence of approximations to the power series limit at $x$.

  let infhorner x l =  let upd c sum =    LCons (c, lazy (lmap (fun apx -> 
  c+.x\*.apx)                      (Lazy.force sum))) in  lazyfoldr upd l 
  (LCons (ofint 0, lazy LNil))
* Find where the series converges – as far as a given test is concerned.

  let rec exact f = functionWe arbitrarily decide that convergence is  | 
  LNil -> assert falsewhen three consecutive results are the same.  | 
  LCons (x0, lazy (LCons (x1, lazy (LCons (x2, )))))      when f x0 = f x1 && 
  f x0 = f x2 -> f x0  | LCons (, lazy tl) -> exact f tl
* Draw the pixels of the graph at exact coordinates.

  let plot1D f $\sim$w $\sim$h0 $\sim$scale $\sim$tbeg $\sim$tend =  let dt = 
  (tend -. tbeg) /. ofint w in  let eval = exact (fun y-> toint (scale \*. 
  y)) in  Array.init w (fun i ->    let y = infhorner (tbeg +. dt \*. 
  ofint i) f in    i, h0 + eval y)
* Success! If a power series had every third term contributing we would have 
  to check three terms in the function `exact`…
  * We could like in `lhorner` test for `f x0 = f x1 && not x0 =. x1`
* Example `n_chain`: nuclear chain reaction–*A decays into B decays into C*
  * 
    [http://en.wikipedia.org/wiki/Radioactive\_decay#Chain-decay\_processes](http://en.wikipedia.org/wiki/Radioactive_decay#Chain-decay_processes)

  let nchain $\sim$nA0 $\sim$nB0 $\sim$lA $\sim$lB =  let rec nA =    LCons 
  (nA0, lazy (integ ($\sim$-.lA \*:. nA)))  and nB =    LCons (nB0, lazy 
  (integ ($\sim$-.lB \*:. nB +: lA \*:. nA))) in  nA, nB

![](chain_reaction.eps)

# 7 Circular data structures: double-linked list

* Without delayed computation, the ability to define data structures with 
  referential cycles is very limited.
* Double-linked lists contain such cycles between any two nodes even if they 
  are not cyclic when following only *forward* or *backward* links.

  <table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr></tbody>

  </table>-5.517280.0390925-4.670607884640830.102592935573489-4.564773779600480.0602592935573488-4.1626-0.00324117-4.88227609472152-0.214909379547559-5.05161066278608-0.10907527450721-2.215260.0179257-1.516751554438420.229593861621908-1.410917449398070.123759756581558-0.987581-0.00324117-1.68608612250298-0.15140891652335-1.8130870485514-0.06674163249107020.9809330.01792571.615937954755920.1660933985976981.827606164836620.01792565154120922.20861-0.06674161.57360431273978-0.2784098425717691.40426974467522-0.151408916523354.198290.03909254.812127926974470.1872602196057684.981462495039030.1237597565815585.44713-0.0244084.74862746395026-0.172575737531424.5792928958857-0.151408916523350cm
* We need to “break” the cycles by making some links lazy.
* type 'a dllist =  DLNil | DLCons of 'a dllist Lazy.t \* 'a \* 'a dllist
* let rec dldrop n l =  match l with    | DLCons (, x, xs) when n>0 -> 
       dldrop (n-1) xs    |  -> l
* let dllistoflist l =  let rec dllist prev l =    match l with      | 
  [] -> DLNil      | x::xs ->        let rec cell =          lazy 
  (DLCons (prev, x, dllist cell xs)) in        Lazy.force cell in  dllist 
  (lazy DLNil) l
* let rec dltake n l =  match l with    | DLCons (, x, xs) when n>0 -> 
       x::dltake (n-1) xs    |  -> []
* let rec dlbackwards n l =  match l with    | DLCons (lazy xs, x, ) when 
  n>0 ->      x::dlbackwards (n-1) xs    |  -> []

# 8 Input-Output streams

* The stream type used a throwaway argument to make a suspension

  type 'a stream = SNil | SCons of 'a \* (unit -> 'a stream)

  What if we take a real argument?

  type ('a, 'b) iostream =  EOS | More of 'b \* ('a -> ('a, 'b) iostream)

  A stream that for a single input value produces an output value.
* type 'a istream = (unit, 'a) iostreamInput stream produces output when 
  “asked”.

  type 'a ostream = ('a, unit) iostreamOutput stream consumes provided input.
  * Sorry, the confusion arises from adapting the *input file / output file* 
    terminology, also used for streams.
* We can compose streams: directing output of one to input of another.

  let rec compose sf sg =  match sg with  | EOS -> EOSNo more output.| 
  More (z, g) ->    match sf withNo more    | EOS -> More (z, fun 
   -> EOS)input ‘‘processing power''.    | More (y, f) ->      let 
  update x = compose (f x) (g y) in      More (z, update)
  * Every box has one incoming and one outgoing wire:<table 
    style="display: inline-table; vertical-align: middle">
    <tbody><tr>
      <td></td>
    </tr><tr>
      <td style="vertical-align: middle"></td>
    </tr><tr>
      <td></td>
    </tr><tr>
      <td></td>
    </tr><tr>
      <td></td>
    </tr></tbody>
  
    </table>0.02903822.280180.02903823257044581.41233959518455-0.03446220.459833-0.0344622304537637-0.492674295541738-0.0132954-1.40285-0.0132954094456939-2.228353618203470cm
  * Notice how the output stream is ahead of the input stream.

## 8.1 Pipes

* We need a more flexible input-output stream definition.
  * Consume several inputs to produce a single output.
  * Produce several outputs after a single input (or even without input).
  * No need for a dummy when producing output requires input.
* After Haskell, we call the data structure `pipe`.

  type ('a, 'b) pipe =  EOP| Yield of 'b \* ('a, 'b) `pipe`For incremental 
  streams change to lazy.|Await of 'a -> ('a, 'b) pipe
* Again, we can have producing output only *input pipes* and consuming input 
  only *output pipes*.

  type 'a ipipe = (unit, 'a) pipetype voidtype 'a opipe = ('a, void) pipe
  * Why `void` rather than `unit`, and why only for `opipe`?
* Composition of pipes is like “concatenating them in space” or connecting 
  boxes:

  let rec compose pf pg =  match pg with  | EOP -> EOPDone producing 
  results.  | Yield (z, pg') -> Yield (z, compose pf pg')Ready result.  | 
  Await g ->    match pf with    | EOP -> EOPEnd of input.    | Yield 
  (y, pf') -> compose pf' (g y)Compute next result.    | Await f ->    
    let update x = compose (f x) pg in      Await updateWait for more input.

  let (>->) pf pg = compose pf pg
* Appending pipes means “concatenating them in time” or adding more fuel to a 
  box:

  let rec append pf pg =  match pf with  | EOP -> `pg`When `pf` runs out, 
  use `pg`.|Yield (z, pf') -> Yield (z, append pf' pg)  | Await f ->If 
  `pf` awaits input, continue when it comes.    let update x = append (f x) pg 
  in    Await update
* Append a list of ready results in front of a pipe.

  let rec yieldall l tail =  match l with  | [] -> tail  | x::xs -> 
  Yield (x, yieldall xs tail)
* Iterate a pipe (**not functional**).

  let rec iterate f : 'a opipe =  Await (fun x -> let () = f x in iterate 
  f)

## 8.2 Example: pretty-printing

* Print hierarchically organized document with a limited line width.

  type doc =  Text of string | Line | Cat of doc \* doc | Group of doc
* let (++) d1 d2 = Cat (d1, Cat (Line, d2))let (!) s = Text slet testdoc =  
  Group (!"Document" ++            Group (!"First part" ++ !"Second part"))

# let () = printendline (pretty 30 testdoc);;DocumentFirst part Second part# let () = printendline (pretty 20 testdoc);;DocumentFirst partSecond part# let () = printendline (pretty 60 testdoc);;Document First part Second part

* Straightforward solution:

  let pretty w d =Allowed width of line `w`.  let rec width = functionTotal 
  length of subdocument.    | Text z -> String.length z    | Line -> 1 
     | Cat (d1, d2) -> width d1 + width d2    | Group d -> width d in  
  let rec format f r = functionRemaining space `r`.    | Text z -> z, r - 
  String.length z    | Line when f -> " ", r-1If `not f` then line breaks. 
     | Line -> "\n", w    | Cat (d1, d2) ->      let s1, r = format f 
  r d1 in      let s2, r = format f r d2 in      s1  s2, `r`If following group 
  fits, then without line breaks.| Group d -> format (f || width d <= 
  r) r d in  fst (format false w d)
* Working with a stream of nodes.

  type ('a, 'b) doce =Annotated nodes, special for group beginning.  TE of 'a 
  \* string | LE of 'a | GBeg of 'b | GEnd of 'a
* Normalize a subdocument – remove empty groups.

  let rec norm = function  | Group d -> norm d  | Text "" -> None  | 
  Cat (Text "", d) -> norm d  | d -> Some d
* Generate the stream by infix traversal.

  let rec gen = function  | Text z -> Yield (TE ((),z), EOP)  | 
  Line -> Yield (LE (), EOP)  | Cat (d1, d2) -> append (gen d1) (gen 
  d2)  | Group d ->    match norm d with    | None -> EOP    | Some 
  d ->      Yield (GBeg (),             append (gen d) (Yield (GEnd (), 
  EOP)))
* Compute lengths of document prefixes, i.e. the position of each node 
  counting by characters from the beginning of document.

  let rec docpos curpos =  Await (functionWe input from a `doc_e` pipe  | TE 
  (, z) ->    Yield (TE (curpos, z),and output `doc_e` annotated with 
  position.           docpos (curpos + String.length z))  | LE  ->Spice 
  and line breaks increase position by 1.    Yield (LE curpos, docpos 
  (curpos + 1))  | GBeg  ->Groups do not increase position.    Yield (GBeg 
  curpos, docpos curpos)  | GEnd  ->    Yield (GEnd curpos, docpos 
  curpos))

  let docpos = docpos 0The whole document starts at 0.
* Put the end position of the group into the group beginning marker, so that 
  we can know whether to break it into multiple lines.

  let rec grends grstack =  Await (function  | TE  | LE  as e ->    (match 
  grstack with    | [] -> Yield (e, grends [])We can yield only when    | 
  gr::grs -> grends ((e::gr)::grs))no group is waiting.  | GBeg  -> 
  grends ([]::grstack)Wait for end of group.  | GEnd endp ->    match 
  grstack withEnd the group on top of stack.    | [] -> failwith "grends: 
  unmatched group end marker"    | [gr] ->Top group -- we can yield now.   
     yieldall        (GBeg endp::List.rev (GEnd endp::gr))        (grends [])  
    | gr::par::grs ->Remember in parent group instead.      let par = GEnd 
  endp::gr @ [GBeg endp] @ par in      grends (par::grs))Could use *catenable 
  lists* above.
* That's waiting too long! We can stop waiting when the width of a group 
  exceeds line limit. GBeg will not store end of group when it is irrelevant.

  let rec grends w grstack =  let flush tail =When the stack exceeds width 
  `w`, `yieldall`flush it -- yield everything in it.(revconcatmap 
  $\sim$prep:(GBeg Toofar) snd grstack)      tail inAbove: concatenate in rev. 
  with `prep` before each part.  Await (function  | TE (curp, ) | LE curp as 
  e ->    (match grstack withRemember beginning of groups in the stack.    
  | [] -> Yield (e, grends w [])    | (begp, ):: when curp-begp > 
  w ->      flush (Yield (e, grends w []))    | (begp, gr)::grs -> 
  grends w ((begp, e::gr)::grs))  | GBeg begp -> grends w ((begp, 
  [])::grstack)  | GEnd endp as e ->    match grstack withNo longer fail 
  when the stack is empty --    | [] -> Yield (e, grends w [])could have 
  been flushed.    | (begp, ):: when endp-begp > w ->      flush 
  (Yield (e, grends w []))    | [, gr] ->If width not exceeded, 
  `yieldall`work as before optimization.(GBeg (Pos endp)::List.rev (GEnd 
  endp::gr))        (grends w [])    | (, gr)::(parbegp, par)::grs ->      
  let par =        GEnd endp::gr @ [GBeg (Pos endp)] @ par in      grends w 
  ((parbegp, par)::grs))
* Initial stack is empty:

  let grends w = grends w []
* Finally we produce the resulting stream of strings.

  let rec format w (inline, endlpos as st) =State: the stack of  Await 
  (function‘‘group fits in line''; position where end of line would be.  | TE 
  (, z) -> Yield (z, format w st)  | LE p when List.hd inline ->    
  Yield (" ", format w st)After return, line has `w` free space.  | LE 
  p -> Yield ("\n", format w (inline, p+w))  | GBeg Toofar ->Group 
  with end too far is not inline.    format w (false::inline, endlpos)  | GBeg 
  (Pos p) ->Group is inline if it ends soon enough.    format w 
  ((p<=endlpos)::inline, endlpos)  | GEnd  -> format w (List.tl 
  inline, endlpos))

  let format w = format w ([false], w)Break lines outside of groups.
* Put the pipes together:

  let prettyprint w doc =<table style="display: inline-table; 
  vertical-align: middle">
  <tbody><tr>
    <td style="text-align: center"></td>
    <td></td>
    <td></td>
    <td></td>
    <td style="text-align: center"></td>
  </tr></tbody>

  </table>-7.32332-0.0176611-6.8788199497288-0.0176610662786083-4.10597-0.0176611-3.64029633549411-0.0176610662786083-0.1477710.003505750.2755655509988090.003505754729461573.76809-0.01766114.233761079507870.003505754729461570cm
* Factorize `format` so that various line breaking styles can be plugged in.

  let rec breaks w (inline, endlpos as st) =  Await (function  | TE  as 
  e -> Yield (e, breaks w st)  | LE p when List.hd inline ->    Yield 
  (TE (p, " "), breaks w st)  | LE p as e -> Yield (e, breaks w (inline, 
  p+w))  | GBeg Toofar as e ->    Yield (e, breaks w (false::inline, 
  endlpos))  | GBeg (Pos p) as e ->    Yield (e, breaks w 
  ((p<=endlpos)::inline, endlpos))  | GEnd  as e ->    Yield (e, 
  breaks w (List.tl inline, endlpos)))let breaks w = breaks w ([false], w)  
  let rec emit =  Await (function  | TE (, z) -> Yield (z, emit)  | LE 
   -> Yield ("n", emit)  | GBeg  | GEnd  -> emit)let prettyprint w doc 
  =  gen doc >-> docpos >-> grends w >-> breaks 
  w >->  emit >-> iterate printstring
* Tests.

  let (++) d1 d2 = Cat (d1, Cat (Line, d2))let (!) s = Text slet testdoc =  
  Group (!"Document" ++            Group (!"First part" ++ !"Second part"))let 
  printedoc prp prep = function  | TE (p,z) -> prp p; printendline (": "z) 
   | LE p -> prp p; printendline ": endline"  | GBeg ep -> prep ep; 
  printendline ": GBeg"  | GEnd p -> prp p; printendline ": GEnd"let noop 
  () = ()let printpos = function  | Pos p -> printint p  | Toofar -> 
  printstring "Too far"let  = gen testdoc >->  iterate (printedoc noop 
  noop)let  = gen testdoc >-> docpos >->  iterate (printedoc 
  printint printint)let  = gen testdoc >-> docpos >-> grends 
  20 >->  iterate (printedoc printint printpos)let  = gen 
  testdoc >-> docpos >-> grends 30 >->  iterate 
  (printedoc printint printpos)let  = gen testdoc >-> 
  docpos >-> grends 60 >->  iterate (printedoc printint 
  printpos)let  = prettyprint 20 testdoclet  = prettyprint 30 testdoclet  = 
  prettyprint 60 testdoc
