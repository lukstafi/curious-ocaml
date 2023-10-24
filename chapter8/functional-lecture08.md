Functional Programming



Lecture 8: Monads

List comprehensions. Basic monads; transformers. Probabilistic
Programming.Lightweight cooperative threads.

Some examples from Tomasz Wierzbicki. Jeff Newbern *‘‘All About Monads''*.M.
Erwig, S. Kollmansberger *‘‘Probabilistic Functional Programming in
Haskell''*.Jerome Vouillon *‘‘Lwt: a Cooperative Thread Library''*.

If you see any error on the slides, let me know!

# 1 List comprehensions

* Recall the awkward syntax we used in the Countdown Problem example:
  * Brute-force generation:

    let combine l r =  List.map (fun o->App (o,l,r)) [Add; Sub; Mul; 
    Div]let rec exprs = function  | [] -> []  | [n] -> [Val n]  | 
    ns ->    split ns |-> (fun (ls,rs) ->      exprs ls |-> 
    (fun l ->        exprs rs |-> (fun r ->          combine l 
    r)))
  * Genarate-and-test scheme:

    let guard p e = if p e then [e] else []let solutions ns n =  choices ns 
    |-> (fun ns' ->    exprs ns' |->      guard (fun e -> eval 
    e = Some n))
* Recall that we introduced the operator

  let ( |-> ) x f = concatmap f x
* We can do better with *list comprehensions* syntax extension.

  #load "dynlink.cma";;#load "camlp4o.cma";;#load 
  "Camlp4Parsers/Camlp4ListComprehension.cmo";;

  let test = [i * 2 | i <- fromto 2 22; i mod 3 = 0]
* What it means:
  * [expr | ] can be translated as [expr]
  * [expr | v <- generator; *more*] can be translated as

    `generator` |-> (fun v -> translation of [expr | *more*])
  * [expr | `condition`; *more*] can be translated as

    if condition then translation of [`expr` | *more*] else []
* Revisiting the Countdown Problem code snippets:
  * Brute-force generation:

    let rec exprs = function  | [] -> []  | [n] -> [Val n]  | 
    ns ->    [App (o,l,r) | (ls,rs) <- split ns;     l <- exprs 
    ls; r <- exprs rs;     o <- [Add; Sub; Mul; Div]]
  * Genarate-and-test scheme:

    let solutions ns n =  [e | ns' <- choices ns;   e <- exprs ns'; 
    eval e = Some n]
* Subsequences using list comprehensions (with garbage):

  let rec subseqs l =  match l with    | [] -> [[]]    | x::xs -> [ys 
  | px <- subseqs xs; ys <- [px; x::px]]
* Computing permutations using list comprehensions:
  * via insertion

    let rec insert x = function  | [] -> [[x]]  | y::ys' as ys ->    
    (x::ys) :: [y::zs | zs <- insert x ys']let rec insperms = function  | 
    [] -> [[]]  | x::xs -> [zs | ys <- insperms xs; zs <- 
    insert ys]
  * via selection

    let rec select = function  | [x] -> [x,[]]  | x::xs -> (x,xs) :: [ 
    y, x::ys | y,ys <- select xs]let rec selperms = function  | [] -> 
    [[]]  | xs ->    [x::ys | x,xs' <- select xs; ys <- selperms 
    xs']

# 2 Generalized comprehensions aka. *do-notation*

* We need to install the syntax extension `pa_monad`
  * by copying the `pa_monad.cmo or pa_monad400.cmo` (for OCaml 4.0) file from 
    the course page,
  * or if it does not work, by compiling from sources at 
    [http://www.cas.mcmaster.ca/~carette/pa\_monad/](http://www.cas.mcmaster.ca/~carette/pa_monad/)and 
    installing under a Unix-like shell (Windows: the Cygwin shell).
    * Under Debian/Ubuntu, you may need to install `camlp4-extras`
* let rec exprs = function  | [] -> []  | [n] -> [Val n]  | ns ->  
    perform with (|->) in      (ls,rs) <-- split ns;      l <-- 
  exprs ls; r <-- exprs rs;      o <-- [Add; Sub; Mul; Div];      
  [App (o,l,r)]
* The perform syntax does not seem to support guards…

  let solutions ns n =  perform with (|->) in    ns' <-- choices ns;  
    e <-- exprs ns';    eval e = Some n;    e

        eval e = Some n;      Error: This expression has type bool but an 
  expression was expected of type         'a list
* So it wants a list… What can we do?
* We can decide whether to return anything

  let solutions ns n =  perform with (|->) in    ns' <-- choices ns;  
    e <-- exprs ns';    if eval e = Some n then [e] else []
* But what if we want to check earlier…

  General “guard check” function

  let guard p = if p then [()] else []
* let solutions ns n =  perform with (|->) in    ns' <-- choices ns;  
    e <-- exprs ns';    guard (eval e = Some n);    [e]

# 3 Monads

* A polymorphic type `'a monad` (or `'a Monad.t`, etc.) that supports at least 
  two operations:
  * `bind : 'a monad -> ('a -> 'b monad) -> 'b monad`
  * `return : 'a -> 'a monad`
  * >>= is infix syntax for `bind`: let (>>=) a b = bind a b
* With `bind` in scope, we do not need the with clause in perform

  let bind a b = concatmap b alet return x = [x]  let solutions ns n =  
  perform    ns' <-- choices ns;    e <-- exprs ns';    guard (eval 
  e = Some n);    return e
* Why `guard` looks this way?

  let fail = []let guard p = if p then return () else fail
  * Steps in monadic computation are composed with >>=, e.g. |->
    * as if ; was replaced by >>=
  * [] |-> … does not produce anything – as needed by guarding
  * [()] |-> … $\rightsquigarrow$ (fun \_ -> …) () 
    $\rightsquigarrow$ … i.e. keep without change
* Throwing away the binding argument is a common practice, with infix 
  syntax >> in Haskell, and supported in *do-notation* and perform.
* Everything is a monad?
* Different flavors of monads?
* Can `guard` be defined for any monad?
* perform syntax in depth:

  <table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td></td>
    <td></td>
    <td><tt class="verbatim">exp</tt></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td>[] </td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td>but uses <tt class="verbatim">b</tt> 
  instead of <tt class="verbatim">bind</tt></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td>and <tt class="verbatim">f</tt> instead of 
  <tt class="verbatim">failwith</tt></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td>during translation</td>
  </tr></tbody>
</table>
* It can be useful to redefine: let failwith  = fail (*why?*)

## 3.1 Monad laws

* A parametric data type is a monad only if its `bind` and `return` operations 
  meet axioms:

  $$ \begin{matrix}
  \operatorname{bind} (\operatorname{return}a) f & \approx & f a\\\\\\
  \operatorname{bind}a (\lambda x.\operatorname{return}x) & \approx & a \\\\\\
  \operatorname{bind} (\operatorname{bind}a (\lambda x.b))  (\lambda y.c) &
  \approx & \operatorname{bind}a (\lambda x.\operatorname{bind}b (\lambda
  y.c)) \end{matrix} $$


* Check that the laws hold for our example monad

  let bind a b = concatmap b alet return x = [x]

## 3.2 Monoid laws and *monad-plus*

* A monoid is a type with, at least, two operations
  * `mzero : 'a monoid`
  * `mplus : 'a monoid -> 'a monoid -> 'a monoid`

  that meet the laws:

  $$ \begin{matrix}
  \operatorname{mplus}\operatorname{mzero}a & \approx & a \\\\\\
  \operatorname{mplus}a\operatorname{mzero} & \approx & a \\\\\\
  \operatorname{mplus}a (\operatorname{mplus}b c) & \approx &
  \operatorname{mplus} (\operatorname{mplus}a b) c \end{matrix} $$
* We will define `fail` as synonym for `mzero` and infix ++ for `mplus`.
* Fusing monads and monoids gives the most popular general flavor of monads 
  which we call *monad-plus* after Haskell.
* Monad-plus requires additional axioms that relate its “addition” and its 
  “multiplication”.

  $$ \begin{matrix}
  \operatorname{bind}\operatorname{mzero}f & \approx &
  \operatorname{mzero}\\\\\\
  \operatorname{bind}m (\lambda x.\operatorname{mzero}) & \approx &
  \operatorname{mzero} \end{matrix} $$
* Using infix notation with $\oplus$ as `mplus`, $\boldsymbol{0}$ as `mzero`, 
  $\vartriangleright$ as `bind` and  $\boldsymbol{1}$ as `return`, we get 
  monad-plus axioms

  $$ \begin{matrix}
  \boldsymbol{0} \oplus a & \approx & a \\\\\\
  a \oplus \boldsymbol{0} & \approx & a \\\\\\
  a \oplus (b \oplus c) & \approx & (a \oplus b) \oplus c\\\\\\
  \boldsymbol{1}x \vartriangleright f & \approx & f x\\\\\\
  a \vartriangleright \lambda x.\boldsymbol{1}x & \approx & a \\\\\\
  (a \vartriangleright \lambda x.b) \vartriangleright \lambda y.c & \approx &
  a \vartriangleright (\lambda x.b \vartriangleright \lambda y.c)\\\\\\
  \boldsymbol{0} \vartriangleright f & \approx & \boldsymbol{0}\\\\\\
  a \vartriangleright (\lambda x.\boldsymbol{0}) & \approx & \boldsymbol{0} \end{matrix} $$
* The list type has a natural monad and monoid structure

    let mzero = []  let mplus = (@)  let bind a b = concatmap b a  let return 
  a = [a]
* We can define in any monad-plus

    let fail = mzero  let failwith  = fail  let (++) = mplus  let 
  (>>=) a b = bind a b  let guard p = if p then return () else fail

## 3.3 Backtracking: computation with choice

We have seen `mzero`, i.e. `fail` in the countdown problem. What about 
`mplus`?

let findtoeat n islandsize numislands emptycells =  let honey = honeycells n 
emptycells in  let rec findboard s =    (* Printf.printf "findboard: %sn" 
(statestr s); *)    match visitcell s with    | None ->      perform      
  guard (s.beenislands = numislands);        return s.eaten    | Some (cell, 
s) ->      perform        s <-- findisland cell (freshisland s);      
  guard (s.beensize = islandsize);        findboard s  and findisland current 
s =    let s = keepcell current s in    neighbors n emptycells current    
|> foldM        (fun neighbor s ->          if CellSet.mem neighbor 
s.visited then return s          else            let chooseeat =              
if s.moretoeat <= 0 then fail              else return (eatcell neighbor 
s)            and choosekeep =              if s.beensize >= islandsize 
then fail              else findisland neighbor s in            mplus 
chooseeat choosekeep)        s in    let cellstoeat =    List.length honey - 
islandsize * numislands in  findboard (initstate honey cellstoeat)

# 4 Monad “flavors”

* Monads “wrap around” a type, but some monads need an additional type 
  parameter.
  * Usually the additional type does not change while within a monad – we will 
    therefore stick to `'a monad` rather than parameterize with an additional 
    type `('s, 'a) monad`.
* As monad-plus shows, things get interesting when we add more operations to a 
  basic monad (with `bind` and `return`).
  * Monads with access:

    access : 'a monad -> 'a

    Example: the lazy monad.
  * Monad-plus, non-deterministic computation:

    `mzero : 'a monad``mplus : 'a monad -> 'a monad -> 'a monad`
  * Monads with environment or state – parameterized by type `store`:

    get : store monadput : store -> unit monad

    There is a “canonical” state monad. Similar monads: the writer monad (with 
    `get` called `listen` and `put` called `tell`); the reader monad, without 
    `put`, but with `get` (called `ask`) and `local`:

    local : (store -> store) -> 'a monad -> 'a monad
  * The exception / error monads – parameterized by type `excn`:

    throw : excn -> 'a monadcatch : 'a monad -> (excn -> 'a 
    monad) -> 'a monad
  * The continuation monad:

    callCC : (('a -> 'b monad) -> 'a monad) -> 'a monad

    We will not cover it.
  * Probabilistic computation:

    choose : float -> 'a monad -> 'a monad -> 'a monad

    satisfying the laws with $a \oplus _{p} b$ for `choose p a b` and $pq$ 
    for `p*.q`, $0 \leqslant p, q \leqslant 1$:

      $$ \begin{matrix}
       a \oplus _{0} b & \approx & b \\\\\\
       a \oplus _{p} b & \approx & b \oplus _{1 - p} a\\\\\\
       a \oplus _{p} (b \oplus _{q} c) & \approx & \left( a \oplus
       _{\frac{p}{p + q - pq}} b \right) \oplus _{p + q - pq} c\\\\\\
       a \oplus _{p} a & \approx & a \end{matrix} $$
  * Parallel computation as monad with access and parallel bind:

    parallel :'a monad-> 'b monad-> ('a -> 'b -> 'c 
    monad) -> 'c monad

    Example: lightweight threads.

# 5 Interlude: the module system

* I provide below much more information about the module system than we need, 
  just for completeness. You can use it as reference.
  * Module system details will **not** be on the exam – only the structure / 
    signature definitions as discussed in lecture 5.
* Modules collect related type definitions and operations together.
* Module “values” are introduced with struct … end – structures.
* Module types are introduced with sig … end – signatures.
  * A structure is a package of definitions, a signature is an interface for 
    packages.
* A source file `source.ml` or `Source.ml` defines a module Source.

  A source file `source.mli` or `Source.mli` defines its type.
* We can create the initial interface by entering the module in the 
  interactive toplevel or by command `ocamlc -i source.ml`
* In the “toplevel” – accurately, module level – modules are defined with 
  module ModuleName = … or module ModuleName : MODULE\_TYPE = … 
  syntax, and module types with module type MODULETYPE = … syntax.
  * Corresponds to let `v_name` = … resp. let `v_name` : v\_type = 
    … syntax for values and type vtype = … syntax for types.
* Locally in expressions, modules are defined with let module M = … in 
  … syntax.
  * Corresponds to let `v_name` = … in … syntax for values.
* The content of a module is made visible in the remainder of another module 
  by open Module
  * Module Pervasives is initially visible, as if each file started with open 
    Pervasives.
* The content of a module is made visible locally in an expression with let 
  open Module in … syntax.
* Content of a module is included into another module – i.e. made part of it – 
  by include Module.
  * Just having open Module inside Parent does not affect how Parent looks 
    from outside.
* Module functions – functions from modules to modules – are called *functors* 
  (not the Haskell ones!). The type of the parameter has to be given.

  module Funct = functor (Arg : sig … end) -> struct … end

  module Funct (Arg : sig … end) = struct … end
  * Functors can return functors, i.e. modules can be parameterized by 
    multiple modules.
  * Modules are either structures or functors.
  * Different kind of thing than Haskell functors.
* Functor application always uses parentheses: Funct (struct … end)
* We can use named module type instead of signature and named module instead 
  of structure above.
* Argument structures can contain more definitions than required.
* A signature MODULETYPE with type t\_name = … is like MODULETYPE but 
  with `t_name` made more specific.
* We can also include signatures into other signatures, by include MODULETYPE.
  * include MODULETYPE with type tname := … will substitute type 
    `t_name` with provided type.
* Modules, just as expressions, are **not** recursive or mutually recursive by 
  default. Syntax for recursive modules:module rec ModuleName : MODULETYPE = 
  … and …
* We can recover the type – i.e. signature – of a module bymodule type of 
  Module
* Finally, we can pass around modules in normal functions.
  * (module Module) is an expression
  * (val modulev) is a module
  * 
    ```ocaml
    # module type T = sig val g : int -> int endlet f modv x =  let module 
    M = (val modv : T) in  M.g x;;

    val f : (module T) -> int -> int = <fun>

    # let test = f (module struct let g i = i*i end : T);;

    val test : int -> int = <fun>
    ```

# 6 The two metaphors

* Monads can be seen as **containers**: `'a monad` contains stuff of type `'a`
* and as **computation**: `'a monad` is a special way to compute `'a`.
  * A monad fixes the sequence of computing steps – unless it is a fancy monad 
    like parallel computation monad.

## 6.1 Monads as containers

* A monad is a *quarantine container*:
  * we can put something into the container with `return`
  * we can operate on it, but the result needs to stay in the container

      let lift f m = perform x <-- m; return (f x)  val lift : ('a -> 
    'b) -> 'a monad -> 'b monad
  * We can deactivate-unwrap the quarantine container but only when it is in 
    another container so the quarantine is not broken

      let join m = perform x <-- m; x  val join : ('a monad) monad -> 
    'a monad
* The quarantine container for a **monad-plus** is more like other containers: 
  it can be empty, or contain multiple elements.
* Monads with access allow us to extract the resulting element from the 
  container, other monads provide a `run` operation that exposes “what really 
  happened behind the quarantine”.

## 6.2 Monads as computation

* To compute the result, perform instructions, naming partial results.
* Physical metaphor: **assembly line**

  <table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td style="text-align: right"></td>
    <td></td>
    <td style="text-align: center"></td>
    <td></td>
  </tr></tbody>

  </table>-5.762933.70556.069321338801433.72666688715439-5.72061.990996.217489085857921.990987564492666.069323.726678.926842174890862.7741599417912410.0486836883186-0.1045277153062576.217491.990996.386823653922481.736985712395826.76782643206773-0.08336089429818766.76783-0.0833609-5.29726154253208-0.1045277153062576.72549-1.84021-5.19142743749173-1.819040216959920.6717822.879992.3016271993652.879994046831597.720331.863998.12250297658420.7209783040084676.00582-0.9723674.69347797327689-0.9723673766371212.06879-0.9088670.735282444767826-0.908866913612912-5.762932.87999-4.619923270273852.87999404683159-4.42942-0.930034-5.53009657362085-0.930033734620982-9.763462.68949-8.324116946686072.26615623759757-7.308109538298720.9749801561053052.280462.371993.175100860066451.990988185174813.656303743881470.9749801561053053.88914-1.289873.31763460775235-2.263543458129383.29646778674428-2.83504762534727-4.26009-1.18404-4.64394551581309-1.82001279007382-4.72575737531419-2.72921352030692`w`-7.42741.25543`c`3.596731.32033`c'`3.5293-2.47521`c''`-4.93743-1.586216.280990.911486.76783-0.0833609-4.408260.91148-3.916971543196911.990989632039070.206112-2.89855-0.600035853371303-1.827196584929880cm

  let assemblyLine w =   perform     c <-- makeChopsticks w     c' 
  <-- polishChopsticks c     c'' <-- wrapChopsticks c'     return 
  c''
* Any expression can be spread over a monad, e.g. for $\lambda$-terms:

  $$ \begin{matrix}
  \llbracket N \rrbracket = & \operatorname{return}N & \text{(constant)}\\\\\\
  \llbracket x \rrbracket = & \operatorname{return}x & \text{(variable)}\\\\\\
  \llbracket \lambda x.a \rrbracket = & \operatorname{return} (\lambda x.
  \llbracket a \rrbracket) & \text{(function)}\\\\\\
  \llbracket \operatorname{let}x = a\operatorname{in}b \rrbracket = &
  \operatorname{bind} \llbracket a \rrbracket  (\lambda x. \llbracket b
  \rrbracket) & \text{(local definition)}\\\\\\
  \llbracket a b \rrbracket = & \operatorname{bind} \llbracket a \rrbracket
  (\lambda v_{a} .\operatorname{bind} \llbracket b \rrbracket  (\lambda
  v_{b} .v_{a} v_{b})) & \text{(application)} \end{matrix} $$
* When an expression is spread over a monad, its computation can be monitored 
  or affected without modifying the expression.



# 7 Monad classes

* To implement a monad we need to provide the implementation type, `return` 
  and `bind` operations.

  module type MONAD = sig  type 'a t  val return : 'a -> 'a t  val bind : 
  'a t -> ('a -> 'b t) -> 'b tend
  * Alternatively we could start from `return`, `lift` and `join` operations.

      * For monads that change their additional type parameter we could 
    define:
    module type MONAD = sig  type ('s, 'a) t  val return : 'a -> ('s, 'a) 
    t
      val bind :    ('s, 'a) t -> ('a -> ('s, 'b) t) -> ('s, 'b)
      tend


* Based on just these two operations, we can define a whole suite of 
  general-purpose functions. We look at just a tiny selection.

  module type MONADOPS = sig  type 'a monad  include MONAD with type 'a t := 
  'a monad  val ( >>= ) :'a monad -> ('a -> 'b monad) -> 
  'b monad  val foldM :    ('a -> 'b -> 'a monad) -> 'a -> 'b 
  list -> 'a monad  val whenM : bool -> unit monad -> unit monad  
  val lift : ('a -> 'b) -> 'a monad -> `'b monad`  val 
  (>>|) : 'a monad -> ('a -> 'b) -> 'b monadval join : 'a 
  monad monad -> 'a monad  val ( >=> ) :    ('a ->'b 
  monad) -> ('b ->'c monad) -> 'a -> 'c monadend
* Given a particular implementation, we define these functions.

  module MonadOps (M : MONAD) = struct  open M  type 'a monad = 'a t  let run 
  x = x  let (>>=) a b = bind a b  let rec foldM f a = function    | 
  [] -> return a    | x::xs -> f a x >>= fun a' -> foldM f 
  a' xs  let whenM p s = if p then s else return ()  let lift f m = perform x 
  <-- m; return (f x)  let (>>|) a b = lift b a  let join m = 
  perform x <-- m; x  let (>=>) f g = fun x -> f 
  x >>= gend
* We make the monad “safe” by keeping its type abstract. But `run` exposes 
  “what really happened”.

  module Monad (M : MONAD) :sig  include MONADOPS  val run : 'a monad -> 
  'a M.tend = struct  include M  include MonadOps(M)end
  * Our `run` function does not do anything at all. Often more useful 
    functions are called `run` but then they need to be defined for each 
    implementation separately. Our `access` operation (see section on monad 
    flavors) is often called `run`.
* The monad-plus class of monads has a lot of implementations. They need to 
  provide `mzero` and `mplus`.

  module type MONADPLUS = sig  include MONAD  val mzero : 'a t  val mplus : 'a 
  t -> 'a t -> 'a tend
* Monad-plus class also has its general-purpose functions:

  module type MONADPLUSOPS = sig  include MONADOPS  val mzero : 'a monad  val 
  mplus : 'a monad -> 'a monad -> 'a monad  val fail : 'a monad  val 
  (++) : 'a monad -> 'a monad -> 'a monad  val guard : bool -> 
  unit monad  val msummap : ('a -> 'b monad) -> 'a list -> 'b 
  monadend
* We again separate the “implementation” and the “interface”.

  module MonadPlusOps (M : MONADPLUS) = struct  open M  include MonadOps(M)  
  let fail = mzero  let (++) a b = mplus a b  let guard p = if p then return 
  () else fail  let msummap f l = List.foldright    (fun a acc -> mplus (f 
  a) acc) l mzeroend

  module MonadPlus (M : MONADPLUS) :sig  include MONADPLUSOPS  val run : 'a 
  monad -> 'a M.tend = struct  include M  include MonadPlusOps(M)end
* We also need a class for computations with state.

  module type STATE = sig  type store  type 'a t  val get : store t  val put : 
  store -> unit tend

  The purpose of this signature is inclusion in other signatures.

# 8 Monad instances

* We do not define a class for monads with access since accessing means 
  running the monad, not useful while in the monad.
* Notation for laziness heavy? Try a monad! (Monads with access.)

  module LazyM = Monad (struct  type 'a t = 'a Lazy.t  let bind a b = lazy 
  (Lazy.force (b (Lazy.force a)))  let return a = lazy aend)

  let laccess m = Lazy.force (LazyM.run m)
* Our resident list monad. (Monad-plus.)

  module ListM = MonadPlus (struct  type 'a t = 'a list  let bind a b = 
  concatmap b a  let return a = [a]  let mzero = []  let mplus = 
  List.appendend)

## 8.1 Backtracking parameterized by monad-plus 

module Countdown (M : MONADPLUSOPS) = struct  open MOpen the module to make 
monad operations visible.

  let rec insert x = functionAll choice-introducing operations    | [] -> 
return [x]need to happen in the monad.    | y::ys as xs ->      return 
(x::xs) ++        perform xys <-- insert x ys; return (y::xys)

  let rec choices = function    | [] -> return []    | x::xs -> 
perform        cxs <-- choices xs;Choosing which numbers in what order    
    return cxs ++ `insert x cxs`and now whether with or without `x`.

type op = Add | Sub | Mul | Div

  let apply op x y =    match op with    | Add -> x + y    | Sub -> 
x - y    | Mul -> x * y    | Div -> x / y

  let valid op x y =    match op with    | Add -> x <= y    | 
Sub -> x > y    | Mul -> x <= y && x <> 1 && y 
<> 1    | Div -> x mod y = 0 && y <> 1

  type expr = Val of int | App of op * expr * expr

  let op2str = function    | Add -> "+" | Sub -> "-" | Mul -> "*" 
| Div -> "/"  let rec expr2str = functionWe will provide solutions as 
strings.    | Val n -> stringofint n    | App (op,l,r) ->"("expr2str 
lop2str opexpr2str r")"

  let combine (l,x) (r,y) o = performTry out an operator.      guard (valid o 
x y);      return (App (o,l,r), apply o x y)

  let split l =Another choice: which numbers go into which argument.    let 
rec aux lhs = function      | [] | [] -> `fail`Both arguments need 
numbers.| [y; z] -> return (List.rev (y::lhs), [z])      | hd::rhs ->  
      let lhs = hd::lhs in        return (List.rev lhs, rhs)          ++ aux 
lhs rhs in    aux [] l

  let rec results = functionBuild possible expressions once numbers    | 
[] -> `fail`have been picked.| [n] -> perform        guard (n > 
0); return (Val n, n)    | ns -> perform        (ls, rs) <-- split 
ns;        lx <-- results ls;        ly <-- results rs;Collect 
solutions using each operator.        msummap (combine lx ly) [Add; Sub; Mul; 
Div]

  let solutions ns n = performSolve the problem:      ns' <-- choices 
ns;pick numbers and their order,      (e,m) <-- results ns';build 
possible expressions,      guard (m=n);check if the expression gives target 
value,      return (expr2str e)‘‘print'' the solution.end

## 8.2 Understanding laziness

* We will measure execution times:

  #load "unix.cma";;let time f =  let tbeg = Unix.gettimeofday () in  let res 
  = f () in  let tend = Unix.gettimeofday () in  tend -. tbeg, res
* Let's check our generalized Countdown solver using original operations.

  module ListCountdown = Countdown (ListM)let test1 () = ListM.run 
  (ListCountdown.solutions [1;3;7;10;25;50] 765)let t1, sol1 = time test1
* val t1 : float = 2.2856600284576416val sol1 : string list =  
  ["((25-(3+7))*(1+50))"; "(((25-3)-7)*(1+50))"; …
* What if we want only one solution? Laziness to the rescue!

  type 'a llist = LNil | LCons of 'a * 'a llist Lazy.tlet rec ltake n = 
  function | LCons (a, lazy l) when n > 0 -> a::(ltake (n-1) l) | 
   -> []let rec lappend l1 l2 =  match l1 with LNil -> l2  | LCons 
  (hd, tl) ->    LCons (hd, lazy (lappend (Lazy.force tl) l2))let rec 
  lconcatmap f = function  | LNil -> LNil  | LCons (a, lazy l) ->    
  lappend (f a) (lconcatmap f l)
* That is, another monad-plus.

  module LListM = MonadPlus (struct  type 'a t = 'a llist  let bind a b = 
  lconcatmap b a  let return a = LCons (a, lazy LNil)  let mzero = LNil  let 
  mplus = lappendend)
* module LListCountdown = Countdown (LListM)let test2 () = LListM.run 
  (LListCountdown.solutions [1;3;7;10;25;50] 765)
* 
  ```ocaml
  # let t2a, sol2 = time test2;;val t2a : float = 2.51197600364685059val 
  sol2 : string llist = LCons ("((25-(3+7))*(1+50))", <lazy>)
  ```
  Not good, almost the same time to even get the lazy list!
* 
  ```ocaml
  # let t2b, sol21 = time (fun () -> ltake 1 sol2);;val t2b : float 
  = 2.86102294921875e-06val sol21 : string list = ["((25-(3+7))*(1+50))"]# 
  let t2c, sol29 = time (fun () -> ltake 10 sol2);;val t2c : float 
  = 9.059906005859375e-06val sol29 : string list =  ["((25-(3+7))*(1+50))"; 
  "(((25-3)-7)*(1+50))"; …# let t2d, sol239 = time (fun () -> ltake 
  49 sol2);;val t2d : float = 4.00543212890625e-05val sol239 : string list =  
  ["((25-(3+7))*(1+50))"; "(((25-3)-7)*(1+50))"; …
  ```
  Getting elements from the list shows they are almost already computed.
* Wait! Perhaps we should not store all candidates when we are only interested 
  in one.

  module OptionM = MonadPlus (struct  type 'a t = 'a option  let bind a b =    
  match a with None -> None | Some x -> b x  let return a = Some a  
  let mzero = None  let mplus a b = match a with None -> b | Some  -> 
  aend)
* module OptCountdown = Countdown (OptionM)let test3 () = OptionM.run 
  (OptCountdown.solutions [1;3;7;10;25;50] 765)
* ```ocaml
  # let t3, sol3 = time test3;;val t3 : float = 5.0067901611328125e-06val 
  sol3 : string option = None
  ```
  It very quickly computes… nothing. Why?
  * What is the OptionM monad (`Maybe` monad in Haskell) good for?
* Our lazy list type is not lazy enough.
  * Whenever we “make” a choice: `a` ++ `b` or `msum_map` …, it computes 
    the first candidate for each choice path.
  * When we bind consecutive steps, it computes the second candidate of the 
    first step even when the first candidate would suffice.
* We want the whole monad to be lazy: it's called *even lazy lists*.
  * Our `llist` are called *odd lazy lists*.

  type 'a lazylist = 'a lazylist Lazy.tand 'a lazylist = LazNil | LazCons of 
  'a * 'a lazylistlet rec laztake n = function | lazy (LazCons (a, l)) when 
  n > 0 ->   a::(laztake (n-1) l) |  -> []let rec appendaux l1 l2 
  =  match l1 with lazy LazNil -> Lazy.force l2  | lazy (LazCons (hd, 
  tl)) ->    LazCons (hd, lazy (appendaux tl l2))let lazappend l1 l2 = 
  lazy (appendaux l1 l2)let rec concatmapaux f = function  | lazy 
  LazNil -> LazNil  | lazy (LazCons (a, l)) ->    appendaux (f a) 
  (lazy (concatmapaux f l))let lazconcatmap f l = lazy (concatmapaux f l)
* module LazyListM = MonadPlus (struct  type 'a t = 'a lazylist  let bind a b 
  = lazconcatmap b a  let return a = lazy (LazCons (a, lazy LazNil))  let 
  mzero = lazy LazNil  let mplus = lazappendend)
* module LazyCountdown = Countdown (LazyListM)let test4 () = LazyListM.run 
  (LazyCountdown.solutions [1;3;7;10;25;50] 765)
* ```ocaml
  # let t4a, sol4 = time test4;;val t4a : float = 2.86102294921875e-06val 
  sol4 : string lazylist = <lazy># let t4b, sol41 = time (fun 
  () -> laztake 1 sol4);;val t4b : float = 0.367874860763549805val sol41 : 
  string list = ["((25-(3+7))*(1+50))"]# let t4c, sol49 = time (fun () -> 
  laztake 10 sol4);;val t4c : float = 0.234670877456665039val sol49 : string 
  list =  ["((25-(3+7))*(1+50))"; "(((25-3)-7)*(1+50))"; …# let t4d, 
  sol439 = time (fun () -> laztake 49 sol4);;val t4d : float 
  = 4.0594940185546875val sol439 : string list =  ["((25-(3+7))*(1+50))"; 
  "(((25-3)-7)*(1+50))"; …
  ```
  * Finally, the first solution in considerably less time than all solutions.
  * The next 9 solutions are almost computed once the first one is.
  * But computing all solutions takes nearly twice as long as without the 
    overhead of lazy computation.

## 8.3 The exception monad

* Built-in non-functional exceptions in OCaml are more efficient (and more 
  flexible).
* Instead of specifying a type of exceptional values, we could use OCaml open 
  type `exn`, restoring some flexibility.
* Monadic exceptions are safer than standard exceptions in situations like 
  multi-threading. Monadic lightweight-thread library Lwt has `throw` (called 
  `fail` there) and `catch` operations in its monad.

module ExceptionM(Excn : sig type t end) : sig  type excn = Excn.t  type 'a t 
= OK of 'a | Bad of excn  include MONADOPS  val run : 'a monad -> 'a t  
val throw : excn -> 'a monad  val catch : 'a monad -> (excn -> 'a 
monad) -> 'a monadend = struct  type excn = Excn.`t`

module M = struct    type 'a t = OK of 'a | Bad of excn    let return a = OK a 
   let bind m b = match m with      | OK a -> b a      | Bad e -> Bad 
e  end  include M  include MonadOps(M)  let throw e = Bad e  let catch m 
handler = match m with    | OK  -> m    | Bad e -> handler eend

## 8.4 The state monad

module StateM(Store : sig type t end) : sig  type store = Store.`t`Pass the 
current `store` value to get the next value.type 'a t = store -> 'a * 
store  include MONADOPS  include STATE with type 'a t := 'a monad              
  and type store := store  val run : 'a monad -> 'a tend = struct  type 
store = Store.t  module M = struct    type 'a t = store -> 'a * store    
let return a = fun s -> a, `s`Keep the current value unchanged.let bind m 
b = fun s -> let a, s' = m s in b a s'  endTo bind two steps, pass the 
value after first step to the second step.  include M include MonadOps(M)  let 
get = fun s -> s, `s`Keep the value unchanged but put it in monad.let put 
s' = fun  -> (), s'Change the value; a throwaway in monad.end

* The state monad is useful to hide passing-around of a “current” value.
* We will rename variables in $\lambda$-terms to get rid of possible name 
  clashes.
  * This does not make a $\lambda$-term safe for multiple steps of 
    $\beta$-reduction. Find a counter-example.
* type term =| Var of string| Lam of string * term| App of term * term
* let (!) x = Var xlet (|->) x t = Lam (x, t)let (@) t1 t2 = App (t1, 
  t2)let test = "x" |-> ("x" |-> !"y" @ !"x") @ !"x"
* module S =  StateM(struct type t = int * (string * string) list end)open S

  Without opening the module, we would write S`.get`, S`.put` and perform with 
  S in…
* let rec alphaconv = function  | Var x as v -> performFunction from terms 
  to StateM monad.    (\_, env) <-- get;Seeing a variable does not change 
  state    let v = try Var (List.assoc x env)but we need its new name.      
  with Notfound -> v inFree variables don't change name.    return v  | 
  Lam (x, t) -> performWe rename each bound variable.    (fresh, env) 
  <-- get;We need a fresh number.    let x' = x  stringofint fresh in    
  put (fresh+1, (x, x')::env);Remember new name, update number.    t' <-- 
  alphaconv t;    (fresh', ) <-- get;We need to restore names,    put 
  (fresh', env);but keep the number fresh.    return (Lam (x', t'))  | App 
  (t1, t2) -> perform    t1 <-- alphaconv t1;Passing around of names  
    t2 <-- alphaconv t2;and the currently fresh number    return (App 
  (t1, t2))is done by the monad.
* val test : term = Lam ("x", App (Lam ("x", App (Var "y", Var "x")), Var 
  "x"))# let  = StateM.run (alphaconv test) (5, []);;- : term * (int * 
  (string * string) list) =(Lam ("x5", App (Lam ("x6", App (Var "y", Var 
  "x6")), Var "x5")), (7, []))
* If we separated the reader monad and the state monad, we would avoid the 
  lines:    (fresh', ) <-- get;Restoring the ‘‘reader'' part `env`    put 
  (fresh', env);but preserving the ‘‘state'' part `fresh`.
* The elegant way is to define the monad locally:

  let alphaconv t =  let module S = StateM    (struct type t = int * (string 
  * string) list end) in  let open S in  let rec aux = function    | Var x as 
  v -> perform      (fresh, env) <-- get;      let v = try Var 
  (List.assoc x env)        with Notfound -> v in      return v    | Lam 
  (x, t) -> perform      (fresh, env) <-- get;      let x' = x  
  stringofint fresh in      put (fresh+1, (x, x')::env);      t' <-- aux 
  t;      (fresh', ) <-- get;      put (fresh', env);      return (Lam 
  (x', t'))    | App (t1, t2) -> perform      t1 <-- aux t1; t2 
  <-- aux t2;      return (App (t1, t2)) in  run (aux t) (0, [])

# 9 Monad transformers

* Based on: 
  [http://lambda.jimpryor.net/monad\_transformers/](http://lambda.jimpryor.net/monad_transformers/)
* Sometimes we need merits of multiple monads at the same time, e.g. monads AM 
  and BM.
* Straightforwad idea is to nest one monad within another:
  * either 'a AM.monad BM.monad
  * or 'a BM.monad AM.monad.
* But we want a monad that has operations of both AM and BM.
* It turns out that the straightforward approach does not lead to operations 
  with the meaning we want.
* A *monad transformer* AT takes a monad BM and turns it into a monad AT(BM) 
  which actually wraps around BM on both sides. AT(BM) has operations of both 
  monads.
* We will develop a monad transformer StateT which adds state to a monad-plus. 
  The resulting monad has all: `return`, `bind`, `mzero`, `mplus`, `put`, 
  `get` and their supporting general-purpose functions.
  * There is no reason for StateT not to provide state to any flavor of 
    monads. Our restriction to monad-plus is because the type/module system 
    makes more general solutions harder.
* We need monad transformers in OCaml because “monads are contagious”: 
  although we have built-in state and exceptions, we need to use monadic state 
  and exceptions when we are inside a monad.
  * The reason *Lwt* is both a concurrency and an exception monad.
* Things get *interesting* when we have several monad transformers, e.g. AT, 
  BT, … We can compose them in various orders: AT(BT(CM)), BT(AT(CM)), 
  … achieving different results.
  * With a single trasformer, we will not get into issues with multiple-layer 
    monads…
  * They are worth exploring – especially if you plan a career around 
    programming in Haskell.
* The state monad, using (fun x -> …) a instead of let x = a in 
  …

  type 'a state =    store -> ('a * store)

  let `return` (a : 'a) : 'a state =    fun s -> (a, s)

  let bind (u : 'a state) (f : 'a -> 'b state) : 'b state =    fun 
  s -> (fun (a, s') -> f a s') (u s)
* Monad M transformed to add state, in pseudo-code:

  type 'a stateT(M) =    store -> ('a * store) M(* notice this is not an 
  ('a M) state *)

  let `return` (a : 'a) : 'a stateT(M) =    fun s -> M.`return` (a, 
  s)Rather than returning, M.return

  let bind(u:'a stateT(M))(f:'a->'b stateT(M)):'b stateT(M)=    fun 
  s -> M.bind (u s) (fun (a, s') -> f a s')Rather than let-binding, 
  M.bind

## 9.1 State transformer

module StateT (MP : MONADPLUSOPS) (Store : sig type t end) : sigFunctor takes 
two modules -- the second one  type store = Store.`t`provides only the storage 
type.type 'a t = store -> ('a * store) MP.monad  include 
MONADPLUSOPSExporting all the monad-plus operations  include STATE with type 
'a t := `'a monad`and state operations.and type store := store  val run : 'a 
monad -> `'a t`Expose ‘‘what happened'' -- resulting states.val runT : 'a 
monad -> store -> 'a MP.monadend = structRun the state transformer -- 
get the resulting values.  type store = Store.`t`

module M = struct    type 'a t = store -> ('a * store) MP.monad    let 
return a = fun s -> MP.return (a, s)    let bind m b = fun s ->      
MP.bind (m s) (fun (a, s') -> b a s')    let mzero = fun  -> 
MP.`mzero`*Lift* the monad-plus operations.let mplus ma mb = fun s -> 
MP.mplus (ma s) (mb s)  end  include M  include MonadPlusOps(M)  let get = fun 
s -> MP.return (s, s)Instead of just returning,  let put s' = fun  -> 
MP.return ((), s')MP.return.  let runT m s = MP.lift fst (m s)end

## 9.2 Backtracking with state

module HoneyIslands (M : MONADPLUSOPS) = struct  type state = {For use with 
list monad or lazy list monad.    beensize: int;    beenislands: int;    
unvisited: cell list;    visited: CellSet.t;    eaten: cell list;    
moretoeat: int;  }  let initstate unvisited moretoeat = {    beensize = 0;    
beenislands = 0;    unvisited;    visited = CellSet.empty;    eaten = [];    
moretoeat;  }

  module BacktrackingM =    StateT (M) (struct type t = state end)  open 
BacktrackingM  let rec visitcell () = performState update actions.      s 
<-- get;      match s.unvisited with      | [] -> return None      | 
c::remaining when CellSet.mem c s.visited -> perform        put {s with 
unvisited=remaining};        visitcell ()Throwaway argument because of 
recursion. See (*)    | c::remaining (* when c not visited *) -> 
perform        put {s with          unvisited=remaining;          visited = 
CellSet.add c s.visited};        return (Some c)This action returns a value.

  let eatcell c = perform      s <-- get;      put {s with eaten = 
c::s.eaten;        visited = CellSet.add c s.visited;        moretoeat = 
s.moretoeat - 1};      return ()Remaining state update actions just affect the 
state.  let keepcell c = perform      s <-- get;      put {s with        
visited = CellSet.add c s.visited;        beensize = s.beensize + 1};      
return ()  let freshisland = perform      s <-- get;      put {s with 
beensize = 0;        beenislands = s.beenislands + 1};      return ()

  let findtoeat n islandsize numislands emptycells =    let honey = honeycells 
n emptycells inOCaml does not realize that `'a monad` with state is actually a 
function --    let rec findboard () = performit's an abstract type.(*)        
cell <-- visitcell ();        match cell with        | None -> 
perform            s <-- get;            guard (s.beenislands = 
numislands);            return s.eaten        | Some cell -> perform       
     freshisland;            findisland cell;            s <-- get;       
     guard (s.beensize = islandsize);            findboard ()

    and findisland current = perform        keepcell current;        neighbors 
n emptycells current        |> `foldM`The partial answer sits in the 
state -- throwaway result.(fun () neighbor -> perform                s 
<-- get;                whenM (not (CellSet.mem neighbor s.visited))      
            (let chooseeat = perform                      guard 
(s.moretoeat > 0);                      eatcell neighbor                  
and choosekeep = perform                      guard (s.beensize < 
islandsize);                      findisland neighbor in                  
chooseeat ++ choosekeep)) () in

    let cellstoeat =      List.length honey - islandsize * numislands in    
initstate honey cellstoeat    |> runT (findboard ())endmodule HoneyL = 
HoneyIslands (ListM)let findtoeat a b c d =  ListM.run (HoneyL.findtoeat a b c 
d)

# 10 Probabilistic Programming

* Using a random number generator, we can define procedures that produce 
  various output. This is **not functional** – mathematical functions have a 
  deterministic result for fixed arguments.
* Similarly to how we can “simulate” (mutable) variables with state monad and 
  non-determinism (i.e. making choices) with list monad, we can “simulate” 
  random computation with probability monad.
* The probability monad class means much more than having randomized 
  computation. We can ask questions about probabilities of results. Monad 
  instances can make tradeoffs of efficiency vs. accuracy (exact vs. 
  approximate probabilities).
* Probability monad imposes limitations on what approximation algorithms can 
  be implemented.
  * Efficient *probabilistic programming* library for OCaml, based on 
    continuations, memoisation and reified search 
    trees:[http://okmij.org/ftp/kakuritu/index.html](http://okmij.org/ftp/kakuritu/index.html)

## 10.1 The probability monad

* The essential functions for the probability monad class are `choose` and 
  `distrib` – remaining functions could be defined in terms of these but are 
  provided by each instance for efficiency.
* Inside-monad operations:
  * choose : float -> 'a monad -> 'a monad -> 'a monad

    `choose p a b` represents an event or distribution which is $a$ with 
    probability $p$ and is $b$ with probability $1 - p$.
  * val pick : ('a * float) list -> 'a t

    A result from the provided distribution over values. The argument must be 
    a probability distribution: positive values summing to 1.
  * val uniform : 'a list -> 'a monad

    Uniform distribution over given values.
  * val flip : float -> bool monad

    Equal to `choose 0.5 (return true) (return false)`.
  * val coin : bool monadEqual to `flip 0.5`.
* And some operations for getting out of the monad:
  * val prob : ('a -> bool) -> 'a monad -> float

    Returns the probability that the predicate holds.
  * val distrib : 'a monad -> ('a * float) list

    Returns the distribution of probabilities over the resulting values.
  * val access : 'a monad -> 'a

    Samples a *random* result from the distribution – **non-functional** 
    behavior.
* We give two instances of the probability monad: exact distribution monad, 
  and sampling monad, which can approximate distributions.
  * The sampling monad is entirely non-functional: in Haskell, it lives in the 
    IO monad.
* The monad instances indeed represent probability distributions: collections 
  of positive numbers that add up to 1 – although often `merge` rather than 
  `normalize` is used. If `pick` and `choose` are used correctly.
* module type PROBABILITY = sigProbability monad class.  include MONADOPS  val 
  choose : float -> 'a monad -> 'a monad -> 'a monad  val pick : 
  ('a * float) list -> `'a monad`  val uniform : 'a list -> 'a 
  monadval coin : bool monad  val flip : float -> bool monad  val prob : 
  ('a -> bool) -> 'a monad -> float  val distrib : 'a monad -> 
  ('a * float) list  val access : 'a monad -> 'aend
* let total dist =Helper functions.  List.foldleft (fun a (,b)->a+.b) 0. 
  distlet merge dist =Merge repeating elements.  mapreduce (fun x->x) 
  (+.) 0. distlet normalize dist = Normalize a measure into a distribution.  
  let tot = total dist in  if tot = 0. then dist  else List.map (fun 
  (e,w)->e,w/.tot) distlet roulette dist =Roulette wheel from a 
  distribution/measure.  let tot = total dist in  let rec aux r = function 
  [] -> assert false    | (e,w):: when w <= r -> e    | 
  (,w)::tl -> aux (r-.w) tl in  aux (Random.float tot) dist
* module DistribM : PROBABILITY = struct  module M = structExact probability 
  distribution -- naive implementation.    type 'a t = ('a * float) list    
  let bind a b = `merge``x` w.p. $p$ and then `y` w.p. $q$ happens =[y, q*.p 
  | (x,p) <- a; (y,q) <- b x]`y` results w.p. $p q$.    let return a 
  = [a, 1.]Certainly `a`.  end  include M include MonadOps (M)  let choose p a 
  b =    List.map (fun (e,w) -> e, p*.w) a @      List.map (fun 
  (e,w) -> e, (1. -.p)*.w) b  let pick dist = `dist`  let uniform elems = 
  normalize    (List.map (fun e->e,1.) elems)let coin = [true, 0.5; 
  false, 0.5]  let flip p = [true, p; false, 1. -. p]

    let prob p m = m    |> List.filter (fun (e,) -> p e)All cases 
  where `p` holds,    |> List.map snd |> List.foldleft (+.) 0.add up.  
  let distrib m = m  let access m = roulette mend
* module SamplingM (S : sig val samples : int end)  : PROBABILITY = 
  structParameterized by how many samples  module M = structused to 
  approximate `prob` or `distrib`.    type 'a t = unit -> `'a`Randomized 
  computation -- each call a()let bind a b () = b (a ()) () is an independent 
  sample.    let return a = fun () -> `a`Always `a`.end  include M include 
  MonadOps (M)  let choose p a b () =    if Random.float 1. <= p then a 
  () else b ()  let pick dist = fun () -> `roulette dist`  let uniform 
  elems =    let n = List.length elems in    fun () -> List.nth 
  (Random.int n) elemslet coin = Random.bool  let flip p = choose p (return 
  true) (return false)

    let prob p m =    let count = ref 0 in    for i = 1 to S.samples do      
  if p (m ()) then incr count    done;    floatofint !count /. floatofint 
  S.`samples`let distrib m =    let dist = ref [] in    for i = 1 to S.samples 
  do      dist := (m (), 1.) :: !dist done;    normalize (`merge` !dist)  let 
  access m = m ()end

## 10.2 Example: The Monty Hall problem

* 
  [http://en.wikipedia.org/wiki/Monty\_Hall\_problem](http://en.wikipedia.org/wiki/Monty_Hall_problem):
  > In search of a new car, the player picks a door, say 1. The game host 
  > then opens one of the other doors, say 3, to reveal a goat and offers to 
  > let the player pick door 2 instead of door 1.
![](Monty_open_door.eps)
* module MontyHall (P : PROBABILITY) = struct  open P  type door = A | B | C  
  let doors = [A; B; C]

    let montywin switch = perform      prize <-- uniform doors;      
  chosen <-- uniform doors;      opened <-- uniform        (listdiff 
  doors [prize; chosen]);      let final =        if switch then List.hd       
     (listdiff doors [opened; chosen])        else chosen in      return 
  (final = prize)end
* module MontyExact = MontyHall (DistribM)module Sampling1000 =  SamplingM 
  (struct let samples = 1000 end)module MontySimul = MontyHall (Sampling1000)
* ```ocaml
  # let t1 = DistribM.distrib (MontyExact.montywin false);;val t1 : (bool * 
  float) list =  [(true, 0.333333333333333315); (false, 0.66666666666666663)]# 
  let t2 = DistribM.distrib (MontyExact.montywin true);;val t2 : (bool * 
  float) list =  [(true, 0.66666666666666663); (false, 0.333333333333333315)]# 
  let t3 = Sampling1000.distrib (MontySimul.montywin false);;val t3 : (bool * 
  float) list = [(true, 0.313); (false, 0.687)]# let t4 = Sampling1000.distrib 
  (MontySimul.montywin true);;val t4 : (bool * float) list = [(true, 0.655); 
  (false, 0.345)]
  ```
## 10.3 Conditional probabilities

* Wouldn't it be nice to have a monad-plus rather than a monad?
* We could use `guard` – conditional probabilities!
  * $P (A|B)$
    * Compute what is needed for both $A$ and $B$.
    * Guard $B$.
    * Return $A$.
* For the exact distribution monad it turns out very easy – we just need to 
  allow intermediate distributions to be unnormalized (sum to less than 1).
* For the sampling monad we use rejection sampling.
  * `mplus` has no straightforward correct implementation.
* We implemented PROBABILITY separately for educational purposes only, as 
  COND\_PROBAB introduced below supersedes it.
* module type CONDPROBAB = sigClass for conditional probability monad,  
  include PROBABILITYwhere `guard cond` conditions on `cond`.  include 
  MONADPLUSOPS with type 'a monad := 'a monadend
* module DistribMP : CONDPROBAB = struct  module MP = structThe measures no 
  longer restricted to    type 'a t = ('a * float) `list`probability 
  distributions:    let bind a b = merge      [y, q*.p | (x,p) <- a; 
  (y,q) <- b x]    let return a = [a, 1.]    let mzero = []Measure equal 
  0 everywhere is OK.    let mplus = List.append  end  include MP include 
  MonadPlusOps (MP)  let choose p a b =It isn't `a` w.p. $p$ & `b` w.p. $(1 - 
  p)$ since `a` and `b`    List.map (fun (e,w) -> e, p*.w) a @are not 
  normalized!List.map (fun (e,w) -> e, (1. -.p)*.w) b  let pick dist = 
  `dist`

  let uniform elems = normalize    (List.map (fun e->e,1.) elems)  let 
  coin = [true, 0.5; false, 0.5]  let flip p = [true, p; false, 1. -. p]  let 
  prob p m = `normalize m`Final normalization step.|> List.filter (fun 
  (e,) -> p e)    |> List.map snd |> List.foldleft (+.) 0.  let 
  distrib m = normalize m  let access m = roulette mend
* We write the rejection sampler in mostly imperative style:

  module SamplingMP (S : sig val samples : int end)  : CONDPROBAB = struct  
  exception RejectedFor rejecting current sample.  module MP = structMonad 
  operations are exactly as for SamplingM    type 'a t = unit -> 'a    let 
  bind a b () = b (a ()) ()    let return a = fun () -> `a`    let mzero = 
  fun () -> raise Rejectedbut now we can `fail`.    let mplus a b = fun 
  () ->      failwith "SamplingMP.mplus not implemented"  end  include MP 
  include MonadPlusOps (MP)

    let choose p a b () =Inside-monad operations don't change.    if 
  Random.float 1. <= p then a () else b ()  let pick dist = fun () -> 
  `roulette dist`let uniform elems =    let n = List.length elems in    fun 
  () -> List.nth elems (Random.int n)  let coin = Random.bool  let flip p 
  = choose p (return true) (return false)

    let prob p m =Getting out of monad: handle rejected samples.    let count 
  = ref 0 and tot = ref 0 in    while !tot < S.samples doCount up to the 
  required      trynumber of samples.        if p (m ()) then incr count;m() 
  can fail. `incr tot`But if we got here it hasn't.with Rejected -> 
  ()Rejected, keep sampling.    done;    floatofint !count /. floatofint 
  S.`samples`

  let distrib m =    let dist = ref [] and tot = ref 0 in    while !tot < 
  S.samples do      try        dist := (m (), 1.) :: !dist;        incr tot    
    with Rejected -> ()    done;    normalize (merge !dist)  let rec 
  access m =    try m () with Rejected -> access mend

## 10.4 Burglary example: encoding a Bayes net

* We're faced with a problem with the following dependency structure:

  <table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td></td>
    <td style="text-align: right"></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td style="text-align: right">Burglary</td>
    <td></td>
    <td></td>
    <td></td>
    <td>Earthquake</td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
    <td>Alarm</td>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr><tr>
    <td></td>
    <td style="text-align: right">John calls</td>
    <td></td>
    <td></td>
    <td></td>
    <td style="text-align: left">Mary calls</td>
    <td></td>
  </tr></tbody>

  </table>-5.525383.15826-3.04886559068663.17942188120122-3.133532874718882.73491864003175-2.11753-0.376604-0.297178859637518-0.418937690170658-0.318345680645588-0.228436301098029-5.82172-4.9063-2.98536512766239-4.90630374388147-3.64153657891255-6.028145257309170.570661-4.863973.63984984786347-4.906303743881472.85667747056489-6.091645720333380.7399953.158263.682183489879613.094754597168943.512848921815052.50208360894298-3.346952.3791-1.790454363947570.2764614914471450.9764792.39298-0.6819827901385850.319857839429467-1.87545-1.04339-3.6026998120943-3.65669671517365-0.55984-1.063621.16004444583979-3.529329161908520cm
  * Alarm can be due to either a burglary or an earthquake.
  * I've left on vacations.
  * I've asked neighbors John and Mary to call me if the alarm rings.
  * Mary only calls when she is really sure about the alarm, but John has 
    better hearing.
  * Earthquakes are twice as probable as burglaries.
  * The alarm has about 30% chance of going off during earthquake.
  * I can check on the radio if there was an earthquake, but I might miss the 
    news.
* module Burglary (P : CONDPROBAB) = struct  open P  type whathappened =    
  Safe | Burgl | Earthq | Burglnearthq

  let check $\sim$johncalled $\sim$marycalled $\sim$radio = perform    
  earthquake <-- flip 0.002;    guard (radio = None || radio = Some 
  earthquake);    burglary <-- flip 0.001;    let alarmp =      match 
  burglary, earthquake with      | false, false -> 0.001      | false, 
  true -> 0.29      | true, false -> 0.94      | true, 
  true -> 0.95 in    alarm <-- flip alarmp;

      let johnp = if alarm then 0.9 else 0.05 in    johncalls <-- flip 
  johnp;    guard (johncalls = johncalled);    let maryp = if alarm then 0.7 
  else 0.01 in    marycalls <-- flip maryp;    guard (marycalls = 
  marycalled);    match burglary, earthquake with    | false, false -> 
  return Safe    | true, false -> return Burgl    | false, true -> 
  return Earthq    | true, true -> return Burglnearthqend
* module BurglaryExact = Burglary (DistribMP)module Sampling2000 =  SamplingMP 
  (struct let samples = 2000 end)module BurglarySimul = Burglary 
  (Sampling2000)
```ocaml
# let t1 = DistribMP.distrib  (BurglaryExact.check $\sim$johncalled:true 
$\sim$marycalled:false     $\sim$radio:None);;    val t1 : 
(BurglaryExact.whathappened * float) list =  
[(BurglaryExact.Burglnearthq, 1.03476433660005444e-05);   
(BurglaryExact.Earthq, 0.00452829235738691407);   
(BurglaryExact.Burgl, 0.00511951049003530299);   
(BurglaryExact.Safe, 0.99034184950921178)]# let t2 = DistribMP.distrib  
(BurglaryExact.check $\sim$johncalled:true $\sim$marycalled:true     
$\sim$radio:None);;    val t2 : (BurglaryExact.whathappened * float) list =  
[(BurglaryExact.Burglnearthq, 0.00057437256500405794);   
(BurglaryExact.Earthq, 0.175492465840075218);   
(BurglaryExact.Burgl, 0.283597462799388911);   
(BurglaryExact.Safe, 0.540335698795532)]# let t3 = DistribMP.distrib  
(BurglaryExact.check $\sim$johncalled:true $\sim$marycalled:true     
$\sim$radio:(Some true));;    val t3 : (BurglaryExact.whathappened * float) 
list =  [(BurglaryExact.Burglnearthq, 0.0032622416021499262);   
(BurglaryExact.Earthq, 0.99673775839785006)]

# let t4 = Sampling2000.distrib  (BurglarySimul.check $\sim$johncalled:true 
$\sim$marycalled:false     $\sim$radio:None);;    val t4 : 
(BurglarySimul.whathappened * float) list =  [(BurglarySimul.Earthq, 0.0035); 
(BurglarySimul.Burgl, 0.0035);   (BurglarySimul.Safe, 0.993)]# let t5 = 
Sampling2000.distrib  (BurglarySimul.check $\sim$johncalled:true 
$\sim$marycalled:true     $\sim$radio:None);;    val t5 : 
(BurglarySimul.whathappened * float) list =  
[(BurglarySimul.Burglnearthq, 0.0005); (BurglarySimul.Earthq, 0.1715);   
(BurglarySimul.Burgl, 0.2875); (BurglarySimul.Safe, 0.5405)]# let t6 = 
Sampling2000.distrib  (BurglarySimul.check $\sim$johncalled:true 
$\sim$marycalled:true     $\sim$radio:(Some true));;    val t6 : 
(BurglarySimul.whathappened * float) list =  
[(BurglarySimul.Burglnearthq, 0.0015); (BurglarySimul.Earthq, 0.9985)]
```

# 11 Lightweight cooperative threads

* `bind` is inherently sequential: bind a (fun x -> b) computes `a`, and 
  resumes computing `b` only once the result `x` is known.
* For concurrency we need to “suppress” this sequentiality. We introduce

  parallel :'a monad-> 'b monad-> ('a -> 'b -> 'c 
  monad) -> 'c monad

  where parallel a b (fun x y -> c) does not wait for `a` to be computed 
  before it can start computing `b`.
* It can be that only accessing the value in the monad triggers the 
  computation of the value, as we've seen in some monads.
  * The state monad does not start computing until you “get out of the monad” 
    and pass the initial value.
  * The list monad computes right away – the `'a monad` value is the computed 
    results.

  In former case, a “built-in” `parallel` is necessary for concurrency.
* If the monad starts computing right away, as in the *Lwt* library, `parallel 
  \concat{e}{\rsub{a}} \concat{e}{\rsub{b}} c` is equivalent to

  perform  let a = $e_{a}$ in  let b = $e_{b}$ in  x <-- a;  y <-- 
  b;  c x y
  * We will follow this model, with an imperative implementation.
  * In any case, do not call `run` or `access` from within a monad.
* We still need to decide on when concurrency happens.
  * Under **fine-grained** concurrency, every `bind` is suspended and 
    computation moves to other threads.
    * It comes back to complete the `bind` before running threads created 
      since the `bind` was suspended.
    * We implement this model in our example.
  * Under **coarse-grained** concurrency, computation is only suspended when 
    requested.
    * Operation `suspend` is often called `yield` but the meaning is  more 
      similar to `Await` than `Yield` from lecture 7.
    * Library operations that need to wait for an event or completion of IO 
      (file operations, etc.) should call `suspend` or its equivalent 
      internally.
    * We leave coarse-grained concurrency as exercise 11.
* The basic operations of a multithreading monad class.

  module type THREADS = sig  include MONAD  val parallel :    'a t -> 'b 
  t -> ('a -> 'b -> 'c t) -> 'c tend
* Although in our implementation `parallel` will be redundant, it is a 
  principled way to make sure subthreads of a thread are run concurrently.
* All within-monad operations.

  module type THREADOPS = sig  include MONADOPS   include THREADS with type 'a 
  t := 'a monad  val parallelmap :    'a list -> ('a -> 'b 
  monad) -> 'b list monad  val (>||=) :    'a monad -> 'b 
  monad -> ('a -> 'b -> 'c monad) ->    'c monad  val 
  (>||) :    'a monad -> 'b monad -> (unit -> 'c monad) -> 
     'c monadend
* Outside-monad operations.

  module type THREADSYS = sig  include THREADS  val access : 'a t -> 'a  
  val killthreads : unit -> unitend
* Helper functions.

  module ThreadOps (M : THREADS) = struct  open M  include MonadOps (M)  let 
  parallelmap l f =    List.foldright (fun a bs ->      parallel (f a) bs  
        (fun a bs -> return (a::bs))) l (return [])  let (>||=) = 
  parallel  let (>||) a b c = parallel a b (fun   -> c ())end
* Put an interface around an implementation.

  module Threads (M : THREADSYS) :sig  include THREADOPS  val access : 'a 
  monad -> 'a  val killthreads : unit -> unitend = struct  include M  
  include ThreadOps(M)end
* Our implementation, following the *Lwt* paper.

module Cooperative = Threads(struct  type 'a state =  | Return of `'a`The 
thread has returned.| Sleep of ('a -> unit) `list`When thread returns, 
wake up waiters.| Link of `'a t`A link to the actual thread.and 'a t = 
{mutable state : 'a state}State of the thread can change-- it can return, or 
more waiters can be added.let rec find t =    match t.state withUnion-find 
style link chasing.    | Link t -> find t    |  -> t  let jobs = 
Queue.create ()Work queue -- will storeunit -> unit procedures.  let 
wakeup m a =Thread `m` has actually finished --    let m = find m inupdating 
its state.    match m.state with    | Return  -> assert false    | Sleep 
waiters ->      m.state <- Return a;Set the state, and only then      
List.iter ((|>) a) `waiters`wake up the waiters. | Link  -> assert 
false  let return a = {state = Return a}let connect t t' =`t` was a 
placeholder for `t'`.    let t' = find t' in    match t'.state with    | Sleep 
waiters' ->      let t = find t in      (match t.state with      | Sleep 
waiters ->If both sleep, collect their waiters        t.state <- 
Sleep (waiters' @ waiters);        t'.state <- Link `t`and link one to 
the other.|  -> assert false)    | Return x -> `wakeup t x`If `t'` 
returned, wake up the placeholder.| Link  -> assert falselet rec bind a b 
=    let a = find a in    let m = {state = Sleep []} inThe resulting monad.    
(match a.state with    | Return x ->If `a` returned, we suspend further 
work.      let job () = connect m (b x) in(In exercise 11, this should      
Queue.`push job jobs`only happen after `suspend`.)| Sleep waiters ->If `a` 
sleeps, we wait for it to return.      let job x = connect m (b x) in      
a.state <- Sleep (job::waiters)    | Link  -> assert false);    m  
let parallel a b c = performSince in our implementation    x <-- a;the 
threads run as soon as they are created,    y <-- b;`parallel` is 
redundant. `c x y`let rec access m =Accessing not only gets the result of `m`, 
   let m = find m inbut spins the thread loop till `m` terminates.    match 
m.state with    | Return x -> `x`No further work.| Sleep  ->      (try 
Queue.pop jobs ()Perform suspended work.       with Queue.Empty ->         
failwith "access: result not available");      access m    | Link  -> 
assert false  let killthreads () = Queue.clear jobsRemove pending work.end)

* module TTest (T : THREADOPS) = struct  open T  let rec loop s n = perform    
  return (Printf.printf "-- %s(%d)\n%!" s n);    if n > 0 then loop s 
  (n-1)We cannot use `whenM` because    else return ()the thread would be 
  created regardless of condition.endmodule TT = TTest (Cooperative)
* let test =  Cooperative.killthreads ();Clean-up after previous tests.  let 
  thread1 = TT.loop "A" 5 in  let thread2 = TT.loop "B" 4 in  
  Cooperative.access thread1;We ensure threads finish computing  
  Cooperative.access thread2before we proceed.
```ocaml
# let test =    Cooperative.killthreads ();    let thread1 = TT.loop "A" 5 in    let thread2 = TT.loop "B" 4 in    Cooperative.access thread1;    Cooperative.access thread2;;-- A(5)-- B(4)-- A(4)-- B(3)-- A(3)-- B(2)-- A(2)-- B(1)-- A(1)-- B(0)-- A(0)val test : unit = ()
```
