# Lecture 6: Folding and Backtracking

Mapping and folding.Backtracking using lists. Constraint solving.

Martin Odersky ‘‘Functional Programming Fundamentals'' Lectures 2, 5 and 6

Bits of Ralf Laemmel ‘‘Going Bananas''

Graham Hutton ‘‘Programming in Haskell'' Chapter 11 ‘‘Countdown Problem''

Tomasz Wierzbicki ‘‘*Honey Islands* Puzzle Solver''

If you see any error on the slides, let me know!

## 1 Plan

* `map` and `fold_right`: recursive function examples, abstracting over gets 
  the higher-order functions.
* Reversing list example, tail-recursive variant, `fold_left`.
* Trimming a list: `filter`.
  * Another definition via `fold_right`.
* `map` and `fold` for trees and other data structures.
* The point-free programming style. A bit of history: the FP language.
* Sum over an interval example: $\sum_{n = a}^b f (n)$.
* Combining multiple results: `concat_map`.
* Interlude: generating all subsets of a set (as list), and as exercise: all 
  permutations of a list.
* The Google problem: the `map_reduce` higher-order function.
  * Homework reference: modified `map_reduce` to
    1. build a histogram of a list of documents
    1. build an inverted index for a list of documents

    Later: use `fold` (?) to search for a set of words (conjunctive query).
* Puzzles: checking correctness of a solution.
* Combining bags of intermediate results: the `concat_fold` functions.
* From checking to generating solutions.
* Improving “generate-and-test” by filtering (propagating constraints) along 
  the way.
* Constraint variables, splitting and constraint propagation.
* Another example with “heavier” constraint propagation.

## 2 Basic generic list operations

How to print a comma-separated list of integers? In module `String`:

val concat : string -> string list -> string

First convert numbers into strings:

let rec stringsofints = function  | [] -> []  | hd::tl -> stringofint 
hd :: stringsofints tllet commasepints = String.concat ", " -| stringsofints

How to get strings sorted from shortest to longest? First find the length:

let rec stringslengths = function  | [] -> []  | hd::tl -> 
(String.length hd, hd) :: stringslengths tllet bysize = List.sort compare -| 
stringslengths

### 2.1 Always extract common patterns

<table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr></tbody>
</table>1.589482.889124.91267032676283.016123164439747.15635335361822.783288133350976.098012303214712.127116682100812.139816774705652.127116682100811.483645323455482.296451250165373.70616-0.561076.6695164704326-0.4552354808837159.37886955946554-0.6034032279402048.15119394099749-1.323075142214584.36233298055298-1.19607421616616-8.062594.51897-5.437905146183364.62480156105305-2.538050668077794.56130109802884-3.5117244344493.79929554173833-7.575754067998413.92629646778674-7.914421.15344-4.506565021828281.30161066278608-2.453383384045510.984108347665035-3.659892181505490.391437359439079-7.575754067998410.4549378224632891.483652.27528-0.506035851303082-3.630258632094194.34117-1.217240.255969704987432-3.63025863209419-7.639253.88396-7.66042135203069-2.1485811615293-3.659890.370271-6.55974665961106-2.12741434052123-8.16843-2.31792-5.94590885037703-2.21208162455351-4.16789588569917-2.27558208757772-4.76056687392512-2.88941989681175-7.78742227807911-2.86825307580368-2.72855-3.79959-0.506035851303082-3.630258632094190.742806588173039-4.053595052255590.213636062971293-4.60393239846541-2.79205252017463-4.41343100939278-5.840072.78329-2.919053446223053.01612316443974-1.05637319751292.78328813335097-1.691377827754992.14828350310888-5.395571504167222.23295078714116-5.33207-0.476402-0.992872734488689-0.2647340918110861.75881399656039-0.5399027649159940.785140230189178-1.21724103717423-4.52773184283635-1.19607421616616-5.459072.19062-5.62840653525599-3.71492591612647-4.52773-1.23841-5.45907196719143-3.778426379150680cm

Now use the generic function:

let commasepints =  String.concat ", " -| listmap stringofintlet bysize =  
List.sort compare -| listmap (fun s->String.length s, s)

<table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td style="text-align: right">How to sum elements of a 
list?</td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td style="text-align: right">How to multiply elements in a 
list?</td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td style="text-align: right">Generic solution:</td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td>Caution: <tt class="verbatim">list_fold f base 
l</tt> = <tt class="verbatim">List.fold_right
    f l base</tt>.</td>
  </tr></tbody>

</table>-6.968285.20805-5.592439476121185.48321537240376-4.237762931604715.22921352030692-4.576432067733834.72120981611324-6.354445032411694.70004299510517-6.693111.18635-4.682266172774181.24985117078979-2.756085461039821.1016834237333-3.306422807249640.509012435507342-6.354445032411690.466678793491203-2.269253.7687-0.8722383913216043.7687028707501-0.1102328350310893.45120055562905-0.5759028972086263.04903095647572-2.692584998015613.11253141949993-2.37508-0.549329-0.512402434184416-0.3799940468315911.73128059267099-0.591662256912291.05394232041275-1.16316642413018-2.03641354676544-1.12083278211404-6.92595-2.36968-4.02609472152401-2.11567336949332-0.999239317370023-2.34850840058209-1.48607620055563-2.87767892578383-6.07927635930679-2.87767892578383-2.26925-3.914851.49844556158222-3.809019050138913.40345945230851-4.063020902235752.93778939013097-4.52869096441328-1.27440799047493-4.61335824844556-6.354454.70004-6.10044318031486-2.2003406535256-3.306420.509012-5.10853954194466-2.14605530848409-2.734923.11253-1.38460084405009-3.806950349498371.05394-1.184330.19997872622222-3.78626681481166-3.560423.4512-3.200588702209293.133698240508-3.073587776160873.64170194470168-3.58159-0.760997-2.90425320809631-0.54932861489615-2.75608546103982-0.866830930017198-4.70343-4.21119-4.08959518454822-4.10535454425189-4.1742624685805-4.48635732239714-3.242923.11253-4.3859306786612-3.87251951316312-3.26132-1.28056-4.23776293160471-3.95718679719540cm

<table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td><tt class="verbatim">map</tt> alters the contents of data</td>
    <td></td>
    <td></td>
    <td><tt class="verbatim">fold</tt> computes a value using</td>
    <td></td>
    <td></td>
  </tr><tr>
    <td>without changing the structure:</td>
    <td></td>
    <td></td>
    <td>the structure as a scaffolding:</td>
    <td></td>
    <td></td>
  </tr><tr>
    <td style="text-align: center; vertical-align: bottom"></td>
    <td style="vertical-align: middle"></td>
    <td></td>
    <td></td>
    <td style="text-align: center; vertical-align: middle"></td>
    <td></td>
  </tr></tbody>
</table>

### 2.2 Can we make `fold` tail-recursive?

Let's investigate some tail-recursive functions. (Not hidden as helpers.)

<table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td></td>
  </tr><tr>
    <td><tt class="verbatim">acc</tt></td>
  </tr><tr>
    <td><tt class="verbatim">   
hd</tt></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td><br /></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td>tot</td>
  </tr><tr>
    <td><tt class="verbatim">  </tt> hd<tt 
class="verbatim"> tl</tt></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td><br /></td>
  </tr><tr>
    <td><br /></td>
  </tr><tr>
    <td><br /></td>
  </tr></tbody>

</table>-5.909944.94728-3.729759227411035.01078184945099-1.486076200555634.88378092340257-2.099914009789654.33344357719275-5.338437624024344.26994311416854-5.867611.47592-2.756085461039821.666424130175950.7152731842836351.49708956211139-0.4489019711602060.925585394893504-4.936268024871010.925585394893504-6.01578-2.79978-2.69258499801561-2.56694007143802-0.152566477047228-2.79977510252679-0.427735150152137-3.30777880672047-4.57643206773383-3.35011244873661-3.750933.06343-2.121080830797723.29626934779733-0.5970697182166953.04226749570049-2.226914935838072.55543061251488-4.02609-1.1911-2.45974996692684-0.852427569784363-1.21090752745072-1.25459716893769-2.43858314591877-1.63559994708295-4.5341-4.40845-2.37508268289456-4.28145257309168-0.343067866119857-4.4084534991401-1.02040613837809-4.93762402434184-3.83559333245138-4.93762402434184-0.1102333.296271.498445561582223.423270273845752.874288927106763.232768884773122.175783833840452.555430612514880.1437690170657492.57659743352295-0.491236-0.9582623.61512766238921-0.8100939277682237.04415266569652-1.064095779865065.71064294218812-1.720267231115230.524771795211007-1.677933589099090.376604-4.302622.21811747585659-4.239118931075543.61512766238921-4.429620320148173.17062442121974-4.916457203333770.799940468315915-4.95879084534991-5.338444.29111-6.07927635930679-2.16477047228469-5.69827358116153-2.69394099748644-4.957430.967919-5.48660537108083-1.97426908321207-5.44427172906469-2.6516073554703-2.226912.55543-2.03641354676544-3.62528112184151-2.37508268289456-4.28145257309168-2.41742-1.61443-2.69258499801561-3.79461568990607-2.80072853017803-4.283284085867292.895463.253945.64714247916391-2.397605503373463.72096176742955-4.429620320148174.73754-1.786764.14429818759095-3.413612911760813.50929355734886-4.323786215107820.5036052.70363.00128985315518-4.49312078317238-0.0678992-1.50862.89545574811483-4.598954888212731.752452.70361.62544648763064-4.450787141156242.47212-1.57213.04362349517132-2.461105966397676.17631-1.50863.04362349517132-2.461105966397673.04362-2.461112.02761608678397-4.366119857123960cm

* With `fold_left`, it is easier to hide the accumulator. The `average` 
  example is a bit more tricky than `list_rev`.

  let listrev l =  foldleft (fun t h->h::t) [] llet average =  foldleft 
  (fun (sum,tot) e->sum +. e, 1. +. tot) (0.,0.)
* The function names and order of arguments for `List.fold_right` / 
  `List.fold_left` are due to:
  * `fold_right f` makes `f` *right associative*, like list constructor ::

    List.foldright f [a1; …; an] b is f a1 (f a2 (… (f an b) 
    …)).
  * `fold_left f` makes `f` *left associative*, like function application

    List.foldleft f a [b1; …; bn] is f (… (f (f a b1) b2) …) 
    bn.
* The “backward” structure of `fold_left` computation:

  <table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td></td>
    <td style="text-align: center; vertical-align: 
  middle"></td>
    <td></td>
  </tr></tbody>
</table>
* List filtering, already rather generic (a polymorphic higher-order function)

  let listfilter p l =  List.foldright (fun h t->if p h then h::t else t) 
  l []
* Tail-recursive map returning elements in reverse order:

  let listrevmap f l =  List.foldleft (fun t h->f h::t) [] l

## 3 `map` and `fold` for trees and other structures

* Mapping binary trees is straightforward:

  type 'a btree = Empty | Node of 'a * 'a btree * 'a btree    let rec btmap 
  f = function  | Empty -> Empty  | Node (e, l, r) -> Node (f e, btmap 
  f l, btmap f r)  let test = Node  (3, Node (5, Empty, Empty), Node (7, 
  Empty, Empty))let  = btmap ((+) 1) test
* `map` and `fold` we consider in this section preserve / respect the 
  structure of the data, they **do not** correspond to `map` and `fold` 
  of *abstract data type* containers, which are like `List.rev_map` and 
  `List.fold_left` over container elements listed in arbitrary order.
  * I.e. here we generalize `List.map` and `List.fold_right` to other 
    structures.
* `fold` in most general form needs to process the element together with 
  partial results for the subtrees.

  let rec btfold f base = function  | Empty -> base  | Node (e, l, 
  r) ->    f e (btfold f base l) (btfold f base r)
* Examples:

  let sumels = btfold (fun i l r -> i + l + r) 0let depth t = btfold (fun  
  l r -> 1 + max l r) 1 t

### 3.1 `map` and `fold` for more complex structures

To have a data structure to work with, we recall expressions from lecture 3.

type expression =     Const of float   | Var of string   | Sum of expression 
* expression    (* e1 + e2 *)   | Diff of expression * expression   (* 
e1 - e2 *)   | Prod of expression * expression   (* e1 * e2 *)   | Quot 
of expression * expression   (* e1 / e2 *)

Multitude of cases make the datatype harder to work with. 
Fortunately, *or-patterns* help a bit:

let rec vars = function  | Const  -> []  | Var x -> [x]  | Sum (a,b) | 
Diff (a,b) | Prod (a,b) | Quot (a,b) ->    vars a @ vars b

Mapping and folding needs to be specialized for each case. We pack the 
behaviors into a record.

type expressionmap = {  mapconst : float -> expression;  mapvar : 
string -> expression;  mapsum : expression -> expression -> 
expression;  mapdiff : expression -> expression -> expression;  
mapprod : expression -> expression -> expression;  mapquot : 
expression -> expression -> expression;}Note how `expression` from 
above is substituted by `'a` below, explain why?type 'a expressionfold = {  
foldconst : float -> 'a;  foldvar : string -> 'a;  foldsum : 'a -> 
'a -> 'a;  folddiff : 'a -> 'a -> 'a;  foldprod : 'a -> 
'a -> 'a;  foldquot : 'a -> 'a -> 'a;}

Next we define standard behaviors for `map` and `fold`, which can be tailored 
to needs for particular case.

let identitymap = {  mapconst = (fun c -> Const c);  mapvar = (fun 
x -> Var x);  mapsum = (fun a b -> Sum (a, b));  mapdiff = (fun a 
b -> Diff (a, b));  mapprod = (fun a b -> Prod (a, b));  mapquot = 
(fun a b -> Quot (a, b));}let makefold op base = {  foldconst = (fun 
 -> base);  foldvar = (fun  -> base);  foldsum = op; folddiff = op;  
foldprod = op; foldquot = op;}

The actual `map` and `fold` functions are straightforward:

let rec exprmap emap = function  | Const c -> emap.mapconst c  | Var x -> emap.mapvar x  | Sum (a,b) -> emap.mapsum (exprmap emap a) (exprmap emap b)  | Diff (a,b) -> emap.mapdiff (exprmap emap a) (exprmap emap b)  | Prod (a,b) -> emap.mapprod (exprmap emap a) (exprmap emap b)  | Quot (a,b) -> emap.mapquot (exprmap emap a) (exprmap emap b)let rec exprfold efold = function  | Const c -> efold.foldconst c  | Var x -> efold.foldvar x  | Sum (a,b) -> efold.foldsum (exprfold efold a) (exprfold efold b)  | Diff (a,b) -> efold.folddiff (exprfold efold a) (exprfold efold b)  | Prod (a,b) -> efold.foldprod (exprfold efold a) (exprfold efold b)  | Quot (a,b) -> efold.foldquot (exprfold efold a) (exprfold efold b)

Now examples. We use {record with field=`value`} syntax which copies `record` 
but puts `value` instead of `record.field` in the result.

let primevars = exprmap  {identitymap with mapvar = fun x -> Var 
(x"'")}let subst s =  let apply x = try List.assoc x s with Notfound -> 
Var x in  exprmap {identitymap with mapvar = apply}let vars =  exprfold 
{(makefold (@) []) with foldvar = fun x-> [x]}let size = exprfold 
(makefold (fun a b->1+a+b) 1)let eval env = exprfold {  foldconst = id;  
foldvar = (fun x -> List.assoc x env);  foldsum = (+.); folddiff = (-.);  
foldprod = ( *.); foldquot = (/.);}

## 4 Point-free Programming

* In 1977/78, John Backus designed **FP**, the first *function-level 
  programming* language. Over the next decade it evolved into the **FL** 
  language.
  * ”Clarity is achieved when programs are written at the function level –that 
    is, by putting together existing programs to form new ones, rather than by 
    manipulating objects and then abstracting from those objects to produce 
    programs.” *The FL Project: The Design of a Functional Language*
* For functionl-level programming style, we need functionals/combinators, like 
  these from *OCaml Batteries*:  let const x  = xlet ( |- ) f g x = g (f x)let 
  ( -| ) f g x = f (g x)let flip f x y = f y xlet ( *** ) f g = fun 
  (x,y) -> (f x, g y)let ( &&& ) f g = fun x -> (f x, g x)let first f 
  x = fst (f x)let second f x = snd (f x)let curry f x y = f (x,y)let uncurry 
  f (x,y) = f x y
* The flow of computation can be seen as a circuit where the results of 
  nodes-functions are connected to further nodes as inputs.

  We can represent the cross-sections of the circuit as tuples of intermediate 
  values.
* let print2 c i =  let a = Char.escaped c in  let b = stringofint i in  a  b

<table style="display: inline-table; vertical-align: middle">
  <tbody><tr>
    <td></td>
  </tr><tr>
    <td></td>
  </tr><tr>
    <td><br /></td>
  </tr><tr>
    <td>            <br /></td>
  </tr></tbody>
</table>-9.51-4.01.0-9.4935-0.00601931-4.00.0`Char.escaped`-41`string_of_int`-4.05-5.47857e-050.513.50.50.5395720333377430.0151475062839`uncurry (^)`3.50.57.50.510.50.50cm

* Since we usually work by passing arguments one at a time rather than in 
  tuples, we need `uncurry` to access multi-argument functions, and we pack 
  the result with `curry`.
  * Turning C/Pascal-like function into one that takes arguments one at a time 
    is called *currification*, after the logician Haskell Brooks Curry.
* Another option to remove explicit use of function parameters, rather than to 
  pack intermediate values as tuples, is to use function composition, `flip`, 
  and the so called **S** combinator:

  let s x y z = x z (y z)

  to bring a particular argument of a function to “front”, and pass it a 
  result of another function. Example: a filter-map function

  let func2 f g l = List.filter f (List.map g (l))Definition of function 
  composition.let func2 f g = (-|) (List.filter f) (List.map g)let func2 f = 
  (-|) (List.filter f) -| List.mapCompositionagain, below without the infix 
  notation.let func2 f = (-|) ((-|) (List.filter f)) List.maplet func2 f = 
  flip (-|) List.map ((-|) (List.filter f))let func2 f = (((|-) List.map) -| 
  ((-|) -| List.filter)) flet func2 = (|-) List.map -| ((-|) -| List.filter)

## 5 Reductions. More higher-order/list functions

Mathematics has notation for sum over an interval: $\sum_{n = a}^b f (n)$.

In OCaml, we do not have a universal addition operator:

let rec isumfromto f a b =  if a > b then 0  else f a + isumfromto f (a+1) 
blet rec fsumfromto f a b =  if a > b then 0.  else f a +. fsumfromto f 
(a+1) blet pi2over6 =  fsumfromto (fun i->1. /. floatofint (i*i)) 1 5000

It is natural to generalize:

let rec opfromto op base f a b =  if a > b then base  else op (f a) 
(opfromto op base f (a+1) b)

Let's collect the results of a multifunction (i.e. a set-valued function) for 
a set of arguments, in math notation:

$$ f (A) = \bigcup_{p \in A} f (p) $$

It is a useful operation over lists with `union` translated as `append`:

let rec concatmap f = function  | [] -> []  | a::l -> f a @ concatmap 
f l

and more efficiently:

let concatmap f l =  let rec cmapf accu = function    | [] -> accu    | 
a::l -> cmapf (List.revappend (f a) accu) l in  List.rev (cmapf [] l)

### 5.1 List manipulation: All subsequences of a list

let rec subseqs l =  match l with    | [] -> [[]]    | x::xs ->      
let pxs = subseqs xs in      List.map (fun px -> x::px) pxs @ pxs

Tail-recursively:

let rec rmapappend f accu = function  | [] -> accu  | a::l -> 
rmapappend f (f a :: accu) l

let rec subseqs l =  match l with    | [] -> [[]]    | x::xs ->      
let pxs = subseqs xs in      rmapappend (fun px -> x::px) pxs pxs

**In-class work:** Return a list of all possible ways of splitting a list into 
two non-empty parts.

**Homework:**

 Find all permutations of a list.

 Find all ways of choosing without repetition from a list.

### 5.2 By key: `group_by` and `map_reduce`

It is often useful to organize values by some property.

First we collect an elements from an association list by key.

let collect l =  match List.sort (fun x y -> compare (fst x) (fst y)) l 
with  | [] -> []Start with associations sorted by key.  | (k0, 
v0)::tl ->    let k0, vs, l = List.foldleft      (fun (k0, vs, l) (kn, 
vn) ->Collect values for the current key        if k0 = kn then k0, 
vn::vs, `l`and when the key changes else kn, [vn], (k0,List.rev vs)::l)stack 
the collected values.      (k0, [v0], []) tl inWhat do we gain by reversing?   
 List.rev ((k0,List.rev vs)::l)

Now we can group by an arbitrary property:

let groupby p l = collect (List.map (fun e->p e, e) l)

But we want to process the results, like with an *aggregate operation* in SQL. 
The aggregation operation is called **reduction**.

let aggregateby p red base l =  let ags = groupby p l in  List.map (fun 
(k,vs)->k, List.foldright red vs base) ags

We can use the **feed-forward** operator: let ( |> ) x f = f x

let aggregateby p redf base l =  groupby p l  |> List.map (fun 
(k,vs)->k, List.foldright redf vs base)

Often it is easier to extract the property over which we aggregate upfront. 
Since we first map the elements into the extracted key-value pairs, we call 
the operation `map_reduce`:

let mapreduce mapf redf base l =  List.map mapf l  |> collect  |> 
List.map (fun (k,vs)->k, List.foldright redf vs base)

#### 5.2.1 `map_reduce`/`concat_reduce` examples

Sometimes we have multiple sources of information rather than records.

let concatreduce mapf redf base l =  concatmap mapf l  |> collect  |> 
List.map (fun (k,vs)->k, List.foldright redf vs base)

Compute the merged histogram of several documents:

let histogram documents =  let mapf doc =    Str.split (Str.regexp "[ t.,;]+") 
doc  |> List.map (fun `word`->`word`,1) in  concatreduce mapf (+) 0 
documents

Now compute the *inverted index* of several documents (which come with 
identifiers or addresses).

let cons hd tl = hd::tllet invertedindex documents =  let mapf (addr, doc) =   
 Str.split (Str.regexp "[ t.,;]+") doc  |> List.map (fun 
word->word,addr) in  concatreduce mapf cons [] documents

And now… a “search engine”:

let search index words =  match List.map (flip List.assoc index) words with  | 
[] -> []  | idx::idcs -> List.foldleft intersect idx idcs

where `intersect` computes intersection of sets represented as lists.

#### 5.2.2 Tail-recursive variants

let revcollect l =  match List.sort (fun x y -> compare (fst x) (fst y)) l 
with  | [] -> []  | (k0, v0)::tl ->    let k0, vs, l = List.foldleft   
   (fun (k0, vs, l) (kn, vn) ->        if k0 = kn then k0, vn::vs, l       
 else kn, [vn], (k0, vs)::l)      (k0, [v0], []) tl in    List.rev ((k0, 
vs)::l)

let trconcatreduce mapf redf base l =  concatmap mapf l  |> revcollect  
|> List.revmap (fun (k,vs)->k, List.foldleft redf base vs)

let rcons tl hd = hd::tllet invertedindex documents =  let mapf (addr, doc) = 
… in  trconcatreduce mapf rcons [] documents

#### 5.2.3 Helper functions for inverted index demonstration

let intersect xs ys =Sets as **sorted** lists.  let rec aux acc = function    
| [],  | , [] -> acc    | (x::xs' as xs), (y::ys' as ys) ->      let c 
= compare x y in      if c = 0 then aux (x::acc) (xs', ys')      else if c 
< 0 then aux acc (xs', ys)      else aux acc (xs, ys') in  List.rev (aux 
[] (xs, ys))

```
let readlines file =
  let input = open_in file in
  let rec read lines =
    (* The Scanf library uses continuation passing. *)
    try Scanf.fscanf input "%[\r\n]\n"
      (fun x -> read (x :: lines))
    with End_of_file -> lines
  in
  List.rev (read [])
```

let indexed l =Index elements by their positions.  Array.oflist l |> 
Array.mapi (fun i e->i,e)  |> Array.tolist

let searchengine lines =  let lines = indexed lines in  let index = 
invertedindex lines in  fun words ->    let ans = search index words in    
List.map (flip List.assoc lines) ans

let searchbible =  searchengine (readlines "./bible-kjv.txt")let testresult =  
searchbible ["Abraham"; "sons"; "wife"]

### 5.3 Higher-order functions for the `option` type

Operate on an optional value:

let mapoption f = function  | None -> None  | Some e -> f e

Map an operation over a list and filter-out cases when it does not succeed:

let rec mapsome f = function  | [] -> []  | e::l -> match f e with    
| None -> mapsome f l    | Some r -> r :: mapsome f lTail-recurively:

let mapsome f l =  let rec mapsf accu = function    | [] -> accu    | 
a::l -> mapsf (match f a with None -> accu      | Some r -> 
r::accu) l in  List.rev (mapsf [] l)

## 6 The Countdown Problem Puzzle

* Using a given set of numbers and arithmetic operators +, -, *, /, construct 
  an expression with a given value.
* All numbers, including intermediate results, must be positive integers.
* Each of the source numbers can be used at most once when constructing the 
  expression.
* Example:
  * numbers 1, 3, 7, 10, 25, 50
  * target 765
  * possible solution (25-10) * (50+1)
* There are 780 solutions for this example.
* Changing the target to 831 gives an example that has no solutions.
* Operators:

  type op = Add | Sub | Mul | Div
* Apply an operator:

  let apply op x y =  match op with  | Add -> x + y  | Sub -> x - y  | 
  Mul -> x * y  | Div -> x / y
* Decide if the result of applying an operator to two positive integers is 
  another positive integer:

  let valid op x y =  match op with  | Add -> true  | Sub -> x > y 
   | Mul -> true  | Div -> x mod y = 0
* Expressions:

  type expr = Val of int | App of op * expr * expr
* Return the overall value of an expression, provided that it is a positive 
  integer:

  let rec eval = function  | Val n -> if n > 0 then Some n else None  
  | App (o,l,r) ->    eval l |> mapoption (fun x ->      eval r 
  |> mapoption (fun y ->      if valid o x y then Some (apply o x y)   
     else None))
* **Homework:** Return a list of all possible ways of choosing zero or more 
  elements from a list – `choices`.
* Return a list of all the values in an expression:

  let rec values = function  | Val n -> [n]  | App (,l,r) -> values l 
  @ values r
* Decide if an expression is a solution for a given list of source numbers and 
  a target number:

  let solution e ns n =  listdiff (values e) ns = [] && isunique (values e) && 
   eval e = Some n

### 6.1 Brute force solution

* Return a list of all possible ways of splitting a list into two non-empty 
  parts:

  let split l =  let rec aux lhs acc = function    | [] | [] -> []    | 
  [y; z] -> (List.rev (y::lhs), [z])::acc    | hd::rhs ->      let lhs 
  = hd::lhs in      aux lhs ((List.rev lhs, rhs)::acc) rhs in  aux [] [] l
* We introduce an operator to work on multiple sources of data, producing even 
  more data for the next stage of computation:

  let ( |-> ) x f = concatmap f x
* Return a list of all possible expressions whose values are precisely a given 
  list of numbers:

  let combine l r =Combine two expressions using each operator.  List.map (fun 
  o->App (o,l,r)) [Add; Sub; Mul; Div]let rec exprs = function  | 
  [] -> []  | [n] -> [Val n]  | ns ->    split ns |-> (fun 
  (ls,rs) ->For each split ls,rs of numbers,      exprs ls |-> (fun 
  l ->for each expression `l` over `ls`        exprs rs |-> (fun 
  r ->and expression `r` over `rs`          combine l r)))produce all `l ? 
  r` expressions.
* Return a list of all possible expressions that solve an instance of the 
  countdown problem:

  let guard n =  List.filter (fun e -> eval e = Some n)

  let solutions ns n =  choices ns |-> (fun ns' ->    exprs ns' |> 
  guard n)
* Another way to express this:

  let guard p e =  if p e then [e] else []

  let solutions ns n =  choices ns |-> (fun ns' ->    exprs ns' 
  |->      guard (fun e -> eval e = Some n))

### 6.2 Fuse the generate phase with the test phase

* We seek to define a function that fuses together the generation and 
  evaluation of expressions:
  * We memorize the value together with the expression – in pairs `(e, eval 
    e)` – so only valid subexpressions are ever generated.

  let combine' (l,x) (r,y) =  [Add; Sub; Mul; Div]  |> List.filter (fun 
  o->valid o x y)  |> List.map (fun o->App (o,l,r), apply o x 
  y)let rec results = function  | [] -> []  | [n] -> if n > 0 then 
  [Val n, n] else []  | ns ->    split ns |-> (fun (ls,rs) ->      
  results ls |-> (fun lx ->        results rs |-> (fun ry ->   
         combine' lx ry)))
* Once the result is generated its value is already computed, we only check if 
  it equals the target.

  let solutions' ns n =  choices ns |-> (fun ns' ->    results ns' 
  |>        List.filter (fun (e,m)-> m=n) |>            List.map 
  fst)We discard the memorized values.

### 6.3 Eliminate symmetric cases

* Strengthening the valid predicate to take account of commutativity and 
  identity properties:

  let valid op x y =  match op with  | Add -> x <= y  | Sub -> 
  x > y  | Mul -> x <= y && x <> 1 && y <> 1  | 
  Div -> x mod y = 0 && y <> 1
  * We eliminate repeating symmetrical solutions on the semantic level, i.e. 
    on values, rather than on the syntactic level of expressions – it is both 
    easier and gives better results.
* Now recompile combine', results and solutions'.



## 7 The Honey Islands Puzzle

* Be a bee! Find the cells to eat honey out of, so that the least amount of 
  honey becomes sour, assuming that sourness spreads through contact.
  * Honey sourness is totally made up, sorry.
* Each honeycomb cell is connected with 6 other cells, unless it is a border 
  cell. Given a honeycomb with some cells initially marked as black, mark some 
  more cells so that unmarked cells form `num_islands` disconnected 
  components, each with `island_size` cells.

Task: 3 islands x 3![](honey0.eps)Solution:![](honey1.eps)

### 7.1 Representing the honeycomb

type cell = int * intWe address cells using ‘‘cartesian'' coordinatesmodule 
CellSet =and store them in either lists or sets.  Set.Make (struct type t = 
cell let compare = compare end)type task = {For board ‘‘size'' $N$, the 
honeycomb coordinates  boardsize : int;range from $(- 2 N, - N)$ to $2 N, N$.  
numislands : int;Required number of islands  islandsize : int;and required 
number of cells in an island.  emptycells : CellSet.t;The cells that are 
initially without honey.}

let cellsetoflist l =List into set, inverse of CellSet.elements  
List.foldright CellSet.add l CellSet.empty

#### 7.1.1 Neighborhood

![](honey_min2.eps)`x,y`-0.902203-0.291672`x+2,y`2.23049-0.376339`x+1,y+1`0.410142.35418`x-1,y+1`-2.637882.33301`x-2,y`-4.20423-0.418673`x-1,y-1`-2.65905-3.08569`x+1,y-1`0.431307-3.191530cm

let neighbors n eaten (x,y) =  List.filter    (insideboard n eaten)    [x-1,y-1; x+1,y-1; x+2,y;     x+1,y+1; x-1,y+1; x-2,y]

#### 7.1.2 Building the honeycomb

![](honey_demo.eps)0,0-0.373032-0.1543520,2-0.3730323.041840,-2-0.394199-3.541041,10.5159741.496664,03.33116-0.239023,12.505661.496662,21.510813.063-2,0-2.23571-0.1543520cm

let even x = x mod 2 = 0

let insideboard n eaten (x, y) =  even x = even y && abs y <= n &&  abs 
x + abs y <= 2*n &&  not (CellSet.mem (x,y) eaten)

let honeycells n eaten =  fromto (-2*n) (2*n)|->(fun x ->    fromto 
(-n) n |-> (fun y ->     guard (insideboard n eaten)        (x, y)))

#### 7.1.3 Drawing honeycombs

We separately generate colored polygons:

let drawhoneycomb $\sim$w $\sim$h task eaten =  let i2f = floatofint in  let nx = i2f (4 * task.boardsize + 2) in  let ny = i2f (2 * task.boardsize + 2) in  let radius = min (i2f w /. nx) (i2f h /. ny) in  let x0 = w / 2 in  let y0 = h / 2 in  let dx = (sqrt 3. /. 2.) *. radius +. 1. inThe distance between  let dy = (3. /. 2.) *. radius +. 2. in$(x, y)$ and $(x + 1, y + 1)$.  let drawcell (x,y) =    Array.init 7We draw a closed polygon by placing 6 points      (fun i ->evenly spaced on a circumcircle.        let phi = floatofint i *. pi /. 3. in        x0 + intoffloat (radius *. sin phi +. floatofint x *. dx),        y0 + intoffloat (radius *. cos phi +. floatofint y *. dy)) in  let honey =    honeycells task.boardsize (CellSet.union task.emptycells                     (cellsetoflist eaten))    |> List.map (fun p->drawcell p, (255, 255, 0)) in  let eaten = List.map     (fun p->drawcell p, (50, 0, 50)) eaten in  let oldempty = List.map     (fun p->drawcell p, (0, 0, 0))     (CellSet.elements task.emptycells) in  honey @ eaten @ oldempty

We can draw the polygons to an *SVG* image:

let drawtosvg file $\sim$w $\sim$h ?title ?desc curves =  let f = openout file in  Printf.fprintf f "<?xml version="1.0" standalone="no"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"   "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"><svg width="%d" height="%d" viewBox="0 0 %d %d"     xmlns="http://www.w3.org/2000/svg" version="1.1">" w h w h;  (match title with None -> ()  | Some title -> Printf.fprintf f "  <title>%s</title>n" title);  (match desc with None -> ()  | Some desc -> Printf.fprintf f "  <desc>%s</desc>n" desc);  let drawshape (points, (r,g,b)) =    uncurry (Printf.fprintf f "  <path d="M %d %d") points.(0);    Array.iteri (fun i (x, y) ->      if i > 0 then Printf.fprintf f " L %d %d" x y) points;    Printf.fprintf f      ""n        fill="rgb(%d, %d, %d)" stroke-width="3" />n"      r g b in  List.iter drawshape curves;  Printf.fprintf f "</svg>%!"

But we also want to draw on a screen window – we need to link the `Graphics` 
library. In the interactive toplevel:

##load "graphics.cma";;

When compiling we just provide `graphics.cma` to the command.

let drawtoscreen $\sim$w $\sim$h curves =  Graphics.opengraph (" "stringofint w"x"stringofint h);  Graphics.setcolor (Graphics.rgb 50 50 0);We draw a brown background.  Graphics.fillrect 0 0 (Graphics.sizex ()) (Graphics.sizey ());  List.iter (fun (points, (r,g,b)) ->    Graphics.setcolor (Graphics.rgb r g b);    Graphics.fillpoly points) curves;  if Graphics.readkey () = `'q'`We wait so that solutions can be seen  then failwith "User interrupted finding solutions.";as they're computed.  Graphics.closegraph ()

### 7.2 Testing correctness of a solution

We walk through each island counting its cells, depth-first: having visited 
everything possible in one direction, we check whether something remains in 
another direction.

Correctness means there are `numislands` components each with `islandsize` 
cells. We start by computing the cells to walk on: `honey`.

let checkcorrect n islandsize numislands emptycells =  let honey = honeycells 
n emptycells in

We keep track of already visited cells and islands. When an unvisited cell is 
there after walking around an island, it must belong to a different island.

  let rec checkboard beenislands unvisited visited =    match unvisited with   
 | [] -> beenislands = numislands    | cell::remaining when CellSet.mem 
cell visited -> `checkboard been_islands remaining visited`Keep looking.   
   | cell::remaining (* when not visited *) ->        let (beensize, 
unvisited, visited) = `checkisland cell`Visit another island.(1, remaining, 
CellSet.add cell visited) in        beensize = islandsize        && checkboard 
(beenislands+1) unvisited visited

When walking over an island, besides the `unvisited` and `visited` cells, we 
need to remember `been_size` – number of cells in the island visited so far.

  and checkisland current state =    neighbors n emptycells current     |> 
List`.foldleft` Walk into each direction and accumulate visits.(fun (beensize, 
unvisited, visited as state)        neighbor ->        if CellSet.mem 
neighbor visited then state        else          let unvisited = remove 
neighbor unvisited in          let visited = CellSet.add neighbor visited in   
       let beensize = beensize + 1 in          checkisland neighbor            
(beensize, unvisited, visited)) `state` inStart from the current overall state 
(initial `been_size` is 1).

Initially there are no islands already visited.

  checkboard 0 honey emptycells

### 7.3 Interlude: multiple results per step

When there is only one possible result per step, we work through a list using 
List.foldright and List.foldleft functions.

What if there are multiple results? Recall that when we have multiple sources 
of data and want to collect multiple results, we use `concat_map`:

-4.568261.32331-3.509921.34447-2.218751.32331-0.9699031.323310.3424391.30214-4.568261.32331-5.541936764122240.264965603915862-4.568261.32331-4.695263923799440.328466066940071-4.568261.32331-4.039092472549280.286132424923932-3.509921.34447-3.573422410371740.391966529964281-3.509921.34447-2.896084138113510.370799708956211-2.218751.32331-2.451580896944040.434300171980421-0.9699031.32331-1.604908056621250.413133350972351-0.9699031.32331-0.8640693213388010.3919665299642811.316111.386811.316111.386810.405939939145390.4554669929884911.316111.386811.083278211403620.476633813996561.316111.386811.8029501256780.4131333509723511.316111.386812.586122502976580.54013427702077-5.541940.264966-5.541940.264966-4.695260.328466-4.039090.286132-3.573420.391967-2.896080.3708-2.451580.4343-1.604910.413133-0.8640690.3919670.405940.4554671.083280.4766341.802950.4131332.586120.540134-5.774770.624802-6.007606826299780.56130109802884-6.02877364730784-0.0525367112051859-5.73243815319487-0.116037174229395-4.017930.794136-3.890924725492790.56130109802884-3.933258367508930.0109637518190237-4.22959386162191-0.116037174229395-3.763920.878803-3.679256515412090.0532973938351634-3.44642148432332-0.031369890197116-2.874920.89997-2.769083212065090.688302024077259-2.76908321206509-0.0102030691890462-2.98075142214579-0.031369890197116-2.557420.89997-2.557415001984390.0956310358513031-2.45158089694404-0.0737035322132557-2.091740.815303-2.007077655774570.688302024077259-2.070578118798780.0744642148432332-2.23991268686334-0.031369890197116-1.668410.878803-1.816576266701940.794136129117608-1.837743087710010.0532973938351634-1.62607487762932-0.137203995237465-0.6312340.878803-0.4830665431935440.794136129117608-0.5254001852096840.0956310358513031-0.821735679322662-0.0948703532213256-0.01739650.857637-0.1443974070644270.794136129117608-0.2078978700886360.264965603915862-0.1443974070644270.1379646778674430.1731050.7518020.0672708030162720.1591314988755130.469440.8788030.300105834105040.9634706971821670.278939013096970.05329739383516340.4271067601534590.05329739383516342.649620.9423042.882457997089560.8999702341579572.84012435507342-0.0313698901971162.48028839793623-0.0525367112051859-5.541940.264966-5.54193676412224-0.539373594390792-4.695260.328466-4.71643074480751-0.560540415398862-3.573420.391967-3.55225558936367-0.539373594390792-2.896080.3708-2.89608413811351-0.539373594390792-1.604910.413133-1.62607487762932-0.560540415398862-0.8640690.391967-0.864069321338801-0.5817072364069320.405940.4554670.38477311813732-0.5605404153988621.083280.4766341.06211139039556-0.4970399523746531.802950.4131331.78178330466993-0.4758731313665832.586120.5401342.5014552189443-0.497039952374653-5.54194-0.539374-4.71643-0.56054-3.55226-0.539374-2.89608-0.539374-1.62607-0.56054-0.864069-0.5817070.384773-0.560541.06211-0.497041.78178-0.4758732.50146-0.49704-5.541941.55614-5.859439079243291.47147440137584-5.859439079243291.11163844423866-5.626604048154520.9846375181902372.120451.534972.416787934912031.492641222383912.416787934912031.196305728270942.205119724831331.13280526524673-5.98644-0.306539-6.28277549940468-0.348872205318164-6.24044185738854-0.687541341447281-5.9229395422675-0.856875909511842.96713-0.2218713.30579441725096-0.3700390263262343.30579441725096-0.6452076994311422.88245799708956-0.85687590951184`concat_map`-11.06650.984638`f xs =`-10.34680.264966`List.map f xs`3.707961.04814`|> List.concat`3.87730.0744642

We shortened `concat_map` calls using “work |-> (fun a\_result -> 
…)” scheme. Here we need to collect results once per step.

let rec concatfold f a = function  | [] -> [a]  | x::xs ->     f x a 
|-> (fun a' -> concatfold f a' xs)

### 7.4 Generating a solution

We turn the code for testing a solution into one that generates a correct 
solution.

* We pass around the current solution `eaten`.
* The results will be in a list.
* Empty list means that in a particular case there are no (further) results.
* When walking an island, we pick a new neighbor and try eating from it in one 
  set of possible solutions – which ends walking in its direction, and walking 
  through it in another set of possible solutions.
  * When testing a solution, we never decided to eat from a cell.

The generating function has the same signature as the testing function:

let findtoeat n islandsize numislands emptycells =  let honey = honeycells n 
emptycells in

Since we return lists of solutions, if we are done with current solution 
`eaten` we return `[eaten]`, and if we are in a “dead corner” we return [].

  let rec findboard beenislands unvisited visited eaten =    match unvisited 
with    | [] ->      if beenislands = numislands then [eaten] else []    | 
cell::remaining when CellSet.mem cell visited ->      findboard 
beenislands        remaining visited eaten    | cell::remaining (* when not 
visited *) ->      findisland cell        (1, remaining, CellSet.add cell 
visited, eaten)      |->Concatenate solutions for each way of eating cells 
around and island.      (fun (beensize, unvisited, visited, eaten) ->      
  if beensize = islandsize        then findboard (beenislands+1)               
unvisited visited eaten        else [])

We step into each neighbor of a current cell of the island, and either eat it 
or walk further.

  and findisland current state =    neighbors n emptycells current    |> 
`concatfold`Instead of `fold_left` since multiple results.(fun neighbor        
  (beensize, unvisited, visited, eaten as state) ->          if 
CellSet.mem neighbor visited then [state]          else            let 
unvisited = remove neighbor unvisited in            let visited = CellSet.add 
neighbor visited in            (beensize, unvisited, visited,             
neighbor::eaten)::              (* solutions where neighbor is honey *)      
      findisland neighbor              (beensize+1, unvisited, visited, 
eaten))        state in

The initial partial solution is – nothing eaten yet.

  checkboard 0 honey emptycells []

We can test it now:

let w = 800 and h = 800let ans0 = findtoeat testtask0.boardsize testtask0.islandsize  testtask0.numislands testtask0.emptycellslet  = drawtoscreen $\sim$w $\sim$h  (drawhoneycomb $\sim$w $\sim$h testtask0 (List.hd ans0))

But in a more complex case, finding all solutions takes too long:

let ans1 = findtoeat testtask1.boardsize testtask1.islandsize  testtask1.numislands testtask1.emptycellslet  = drawtoscreen $\sim$w $\sim$h  (drawhoneycomb $\sim$w $\sim$h testtask1 (List.hd ans1))

(See `Lec6.ml` for definitions of test cases.)

### 7.5 Optimizations for *Honey Islands*

* Main rule: **fail** (drop solution candidates) **as early as possible**.
  * Is the number of solutions generated by the more brute-force approach 
    above $2^n$ for $n$ honey cells, or smaller?
* We will guard both choices (eating a cell and keeping it in island).
* We know exactly how much honey needs to be eaten.
* Since the state has many fields, we define a record for it.

type state = {  beensize: int;Number of honey cells in current island.  
beenislands: int;Number of islands visited so far.  unvisited: cell list;Cells 
that need to be visited.  visited: CellSet.t;Already visited.  eaten: cell 
list;Current solution candidate.  moretoeat: int;Remaining cells to eat for a 
complete solution.}

We define the basic operations on the state up-front. If you could keep them 
inlined, the code would remain more similar to the previous version.

let rec visitcell s =  match s.unvisited with  | [] -> None  | 
c::remaining when CellSet.mem c s.visited ->    visitcell {s with 
unvisited=remaining}  | c::remaining (* when c not visited *) ->    Some 
(c, {s with      unvisited=remaining;      visited = CellSet.add c s.visited})

let eatcell c s =  {s with eaten = c::s.eaten;    visited = CellSet.add c 
s.visited;    moretoeat = s.moretoeat - 1}

let keepcell c s =Actually `c` is not used…  {s with beensize = 
s.beensize + 1;    visited = CellSet.add c s.visited}

let freshisland s =We increase `been_size` at the start of `find_island`  {s 
with beensize = 0;rather than before calling it.    beenislands = 
s.beenislands + 1}

let initstate unvisited moretoeat = {  beensize =5mm 0;  beenislands = 0;  
unvisited; visited = CellSet.empty;  eaten = []; moretoeat;}

We need a state to begin with:

let initstate unvisited moretoeat = {  beensize = 0; beenislands = 0;  
unvisited; visited = CellSet.empty;  eaten = []; moretoeat;}

The “main loop” only changes because of the different handling of state.

  let rec findboard s =    match visitcell s with    | None ->      if 
s.beenislands = numislands then [eaten] else []    | Some (cell, s) ->     
 findisland cell (freshisland s)      |-> (fun s ->        if 
s.beensize = s.islandsize        then findboard s        else [])

In the “island loop” we only try actions that make sense:

  and findisland current s =    let s = keepcell current s in    neighbors n 
emptycells current    |> concatfold        (fun neighbor s ->          
if CellSet.mem neighbor s.visited then [s]          else            let 
chooseeat =Guard against actions that would fail.              if s.moretoeat 
= 0 then []              else [eatcell neighbor s]            and choosekeep = 
             if s.beensize >= islandsize then []              else 
findisland neighbor s in            chooseeat @ choosekeep)        s in

Finally, we compute the required length of `eaten` and start searching.

  let cellstoeat =    List.length honey - islandsize * numislands in  
findboard (initstate honey cellstoeat)

## 8 Constraint-based puzzles

* Puzzles can be presented by providing the general form of solutions, and 
  additional requirements that the solutions must meet.
* For many puzzles, the general form of solutions for a given problem can be 
  decomposed into a fixed number of variables.
  * A domain of a variable is a set of possible values the variable can have 
    in any solution.
  * In the *Honey Islands* puzzle, the variables correspond to cells and the 
    domains are $\lbrace \operatorname{Honey}, \operatorname{Empty} \rbrace$ 
    (either a cell has honey, or is empty – without distinguishing “initially 
    empty” and “eaten”).
  * In the *Honey Islands* puzzle, the constraints are: a selection of cells 
    that have to be empty, the number and size of connected components of 
    cells that are not empty. The neighborhood graph – which cell-variable is 
    connected with which – is part of the constraints.
* There is a general and often efficient scheme of solving constraint-based 
  problems. **Finite Domain Constraint Programming** algorithm:
  1. With each variable, associate a set of values, initially equal to the 
     domain of the variable. The singleton containing the association is the 
     initial set of partial solutions.
  1. While there is a solution with more than one value associated to some 
     variable in the set of partial solutions, select it and:
     1. If there is a possible value for some variable, such that for all 
        possible assignments of values to other variables, the requirements 
        fail, remove this value from the set associated with this variable.
     1. If there is a variable with empty set of possible values associated to 
        it, remove the solution from the set of partial solutions.
     1. Select the variable with the smallest non-singleton set associated 
        with it (i.e. the smallest greater than 2 size). Split that set into 
        similarly-sized parts. Replace the solution with two solutions where 
        the variable is associated with either of the two parts.
  1. The final solutions are built from partial solutions by assigning to a 
     variable the single possible value associated with it.
* This general algorithm can be simplified. For example, in step (2.c), 
  instead of splitting into two equal-sized parts, we can partition into a 
  singleton and remainder, or partition “all the way” into several singletons.
* The above definition of *finite domain constraint solving* algorithm is 
  sketchy. Questions?
* We will not discuss a complete implementation example, but you can exploit 
  ideas from the algorithm in your homework.
