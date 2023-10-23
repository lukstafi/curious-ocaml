The Expression Problem

The Expression Problem

Code organization, extensibility and reuse

* Ralf Lämmel lectures on MSDN's Channel 9:[The Expression 
  Problem](http://channel9.msdn.com/Shows/Going+Deep/C9-Lectures-Dr-Ralf-Laemmel-Advanced-Functional-Programming-The-Expression-Problem), 
  [Haskell's Type 
  Classes](http://channel9.msdn.com/Shows/Going+Deep/C9-Lectures-Dr-Ralf-Lmmel-Advanced-Functional-Programming-Type-Classes)
* The old book *Developing Applications with Objective Caml*:[Comparison of 
  Modules and 
  Objects](http://caml.inria.fr/pub/docs/oreilly-book/html/book-ora153.html), 
  [Extending 
  Components](http://caml.inria.fr/pub/docs/oreilly-book/html/book-ora154.html)
* The new book *Real World OCaml*: [Chapter 11: 
  Objects](https://realworldocaml.org/v1/en/html/objects.html), [Chapter 12: 
  Classes](https://realworldocaml.org/v1/en/html/classes.html)
* Jacques Garrigue's [Code reuse through polymorphic 
  variants](http://www.math.nagoya-u.ac.jp/~garrigue/papers/variant-reuse.ps.gz),and 
  [Recursive Modules for 
  Programming](http://www.math.nagoya-u.ac.jp/~garrigue/papers/nakata-icfp2006.pdf) 
  with Keiko Nakata
* [Extensible variant 
  types](http://caml.inria.fr/pub/docs/manual-ocaml/extn.html#sec246)
* Graham Hutton's and Erik Meijer's [Monadic Parser 
  Combinators](https://www.cs.nott.ac.uk/~gmh/monparsing.pdf)The Expression Problem: Definition

* The *Expression Problem*: design an implementation for expressions, where:
  * new variants of expressions can be added (*datatype extensibility*),
  * new operations on the expressions can be added (*functional 
    extensibility*).
* By *extensibility* we mean three conditions:
  * code-level modularization: the new datatype variants, and new operations, 
    are in separate files,
  * separate compilation: the files can be compiled and distributed 
    separately,
  * static type safety: we do not lose the type checking help and guarantees.
* The name comes from an example: extend a language of expressions with new 
  constructs:
  * lambda calculus: variables `Var`, $\lambda$-abstractions `Abs`, function 
    applications `App`;
  * arithmetics: variables `Var`, constants `Num`, addition `Add`, 
    multiplication `Mult`; …

  and new oparations:
  * evaluation `eval`;
  * pretty-printing to strings `string_of`;
  * free variables `free_vars`; …Functional Programming Non-solution: ordinary Algebraic Datatypes

* Pattern matching makes functional extensibility easy in functional 
  programming.
* Ensuring datatype extensibility is complicated when using standard variant 
  types.
* For brevity, we will place examples in a single file, but the component type 
  and function definitions are not mutually recursive so can be put in 
  separate modules.
* Non-solution penalty points:
  * Functions implemented for a broader language (e.g. `lexpr_t`) cannot be 
    used with a value from a narrower langugage (e.g. `expr_t`).
  * Significant memory (and some time) overhead due to so called *tagging*: 
    work of the `wrap` and `unwrap` functions, adding tags e.g. `Lambda` and 
    `Expr`.
  * Some code bloat due to tagging. For example, deep pattern matching needs 
    to be manually unrolled and interspersed with calls to `unwrap`.

  Verdict: non-solution, but better than extensible variant types-based 
  approach (next) and direct OOP approach (later).

type0.5emvar0.5em=0.5emstringVariables constitute a sub-language of its own.We 
treat this sub-language slightly differently -- no need for a dedicated 
variant.let0.5emevalvar0.5emwrap0.5emsub0.5em(s0.5em:0.5emvar)0.5em=0.5em0.5emtry0.5emList.assoc0.5ems0.5emsub0.5emwith0.5emNotfound0.5em->0.5emwrap0.5emstype0.5em'a0.5emlambda0.5em=Here 
we define the sub-language of 
$\lambda$-expressions.0.5em0.5emVarL0.5emof0.5emvar0.5em|0.5emAbs0.5emof0.5emstring0.5em\*0.5em'a0.5em|0.5emApp0.5emof0.5em'a0.5em\*0.5em'aDuring 
evaluation, we need to freshen variables to avoid 
capturelet0.5emgensym0.5em=0.5emlet0.5emn0.5em=0.5emref0.5em00.5emin0.5emfun0.5em()0.5em->0.5emincr0.5emn;0.5em""0.5emˆ0.5emstringofint0.5em!n(mistaking 
distinct variables with the same 
name).let0.5emevallambda0.5emevalrec0.5emwrap0.5emunwrap0.5emsubst0.5eme0.5em=0.5em0.5emmatch0.5emunwrap0.5eme0.5emwithAlternatively, 
unwrapping could use an 
exception,0.5em0.5em|0.5emSome0.5em(VarL0.5emv)0.5em->0.5emevalvar0.5em(fun0.5emv0.5em->0.5emwrap0.5em(VarL0.5emv))0.5emsubst0.5emv0.5em0.5em|0.5emSome0.5em(App0.5em(l1,0.5eml2))0.5em->but 
we use the option type as it is 
safer0.5em0.5em0.5em0.5emlet0.5eml1'0.5em=0.5em`evalrec0.5emsubst0.5eml1`and 
more flexible in this 
context.0.5em0.5em0.5em0.5emand0.5eml2'0.5em=0.5emevalrec0.5emsubst0.5eml20.5eminRecursive 
processing function returns 
expression0.5em0.5em0.5em0.5em(match0.5emunwrap0.5eml1'0.5emwithof the 
completed language, we 
need0.5em0.5em0.5em0.5em|0.5emSome0.5em(Abs0.5em(s,0.5embody))0.5em->to 
unwrap it into the current 
sub-language.0.5em0.5em0.5em0.5em0.5em0.5emevalrec0.5em[s,0.5eml2']0.5em`body`The 
recursive call is already wrapped.`0.5em0.5em0.5em0.5em`|0.5em0.5em 
\_ ->0.5emwrap0.5em(App0.5em(l1',0.5eml2')))Wrap into the completed 
language.0.5em0.5em0.5emSome0.5em(Abs0.5em(s,0.5eml1))0.5em->0.5em0.5em0.5em0.5emlet0.5ems'0.5em=0.5emgensym0.5em()0.5eminRename 
variable to avoid capture 
($\alpha$-equivalence).0.5em0.5em0.5em0.5emwrap0.5em(Abs0.5em(s',0.5emevalrec0.5em((s,0.5emwrap0.5em(VarL0.5ems'))::subst)0.5eml1))0.5em0.5em0.5emNone0.5em->0.5emeFalling-through 
when not in the current 
sub-language.type0.5emlambdat0.5em=0.5emLambdat0.5emof0.5emlambdat0.5emlambdaDefining 
$\lambda$-expressionsas the completed 
language,let0.5emrec0.5emeval10.5emsubst0.5em=and the corresponding `eval` 
function.0.5em0.5emevallambda0.5emeval10.5em0.5em0.5em0.5em(fun0.5eme0.5em->0.5emLambdat0.5eme)0.5em(fun0.5em(Lambdat0.5eme)0.5em->0.5emSome0.5eme)0.5emsubsttype0.5em'a0.5emexpr0.5em=The 
sub-language of arithmetic 
expressions.0.5em0.5emVarE0.5emof0.5emvar0.5em0.5emNum0.5emof0.5emint0.5em0.5emAdd0.5emof0.5em'a0.5em\*0.5em'a0.5em0.5emMult0.5emof0.5em'a0.5em\*0.5em'alet0.5emevalexpr0.5emevalrec0.5emwrap0.5emunwrap0.5emsubst0.5eme0.5em=0.5em0.5emmatch0.5emunwrap0.5eme0.5emwith0.5em0.5em0.5emSome0.5em(Num0.5em)0.5em->0.5eme0.5em0.5em0.5emSome0.5em(VarE0.5emv)0.5em->0.5em0.5em0.5em0.5emevalvar0.5em(fun0.5emx0.5em->0.5emwrap0.5em(VarE0.5emx))0.5emsubst0.5emv0.5em0.5em0.5emSome0.5em(Add0.5em(m,0.5emn))0.5em->0.5em0.5em0.5em0.5emlet0.5emm'0.5em=0.5emevalrec0.5emsubst0.5emm0.5em0.5em0.5em0.5emand0.5emn'0.5em=0.5emevalrec0.5emsubst0.5emn0.5emin0.5em0.5em0.5em0.5em(match0.5emunwrap0.5emm',0.5emunwrap0.5emn'0.5emwithUnwrapping 
to check if the 
subexpressions0.5em0.5em0.5em0.5em0.5emSome0.5em(Num0.5emm'),0.5emSome0.5em(Num0.5emn')0.5em->got 
computed to 
values.0.5em0.5em0.5em0.5em0.5em0.5emwrap0.5em(Num0.5em(m'0.5em+0.5emn'))0.5em0.5em0.5em0.5em->0.5emwrap0.5em(Add0.5em(m',0.5emn')))Here 
`m'` and `n'` are 
wrapped.0.5em0.5em0.5emSome0.5em(Mult0.5em(m,0.5emn))0.5em->0.5em0.5em0.5em0.5emlet0.5emm'0.5em=0.5emevalrec0.5emsubst0.5emm0.5em0.5em0.5em0.5emand0.5emn'0.5em=0.5emevalrec0.5emsubst0.5emn0.5emin0.5em0.5em0.5em0.5em(match0.5emunwrap0.5emm',0.5emunwrap0.5emn'0.5emwith0.5em0.5em0.5em0.5em0.5emSome0.5em(Num0.5emm'),0.5emSome0.5em(Num0.5emn')0.5em->0.5em0.5em0.5em0.5em0.5em0.5emwrap0.5em(Num0.5em(m'0.5em\*0.5emn'))0.5em0.5em0.5em0.5em->0.5emwrap0.5em(Mult0.5em(m',0.5emn')))0.5em0.5em0.5emNone0.5em->0.5emetype0.5emexprt0.5em=0.5emExprt0.5emof0.5emexprt0.5emexprDefining 
arithmetic expressionsas the completed 
language,let0.5emrec0.5emeval20.5emsubst0.5em=aka. ‘‘tying the recursive 
knot''.0.5em0.5emevalexpr0.5emeval20.5em0.5em0.5em0.5em(fun0.5eme0.5em->0.5emExprt0.5eme)0.5em(fun0.5em(Exprt0.5eme)0.5em->0.5emSome0.5eme)0.5emsubsttype0.5em'a0.5emlexpr0.5em=The 
language merging $\lambda$-expressions and arithmetic 
expressions,0.5em0.5emLambda0.5emof0.5em'a0.5emlambda0.5em0.5emExpr0.5emof0.5em'a0.5emexprcan 
also be used asa sub-language for further 
extensions.let0.5emevallexpr0.5emevalrec0.5emwrap0.5emunwrap0.5emsubst0.5eme0.5em=0.5em0.5emevallambda0.5emevalrec0.5em0.5em0.5em0.5em(fun0.5eme0.5em->0.5emwrap0.5em(Lambda0.5eme))0.5em0.5em0.5em0.5em(fun0.5eme0.5em->0.5em0.5em0.5em0.5em0.5em0.5emmatch0.5emunwrap0.5eme0.5emwith0.5em0.5em0.5em0.5em0.5em0.5em0.5emSome0.5em(Lambda0.5eme)0.5em->0.5emSome0.5eme0.5em0.5em0.5em0.5em0.5em0.5em->0.5emNone)0.5em0.5em0.5em0.5emsubst0.5em0.5em0.5em0.5em(`evalexpr0.5emevalrec`We 
use the ‘‘fall-through'' property of 
`eval_expr``0.5em0.5em0.5em0.5em0.5em0.5em0.5em`(fun0.5eme0.5em->0.5emwrap0.5em(Expr0.5eme))to 
combine the 
evaluators.0.5em0.5em0.5em0.5em0.5em0.5em0.5em(fun0.5eme0.5em->0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5emmatch0.5emunwrap0.5eme0.5emwith0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5emSome0.5em(Expr0.5eme)0.5em->0.5emSome0.5eme0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em->0.5emNone)0.5em0.5em0.5em0.5em0.5em0.5em0.5emsubst0.5eme)type0.5emlexprt0.5em=0.5emLExprt0.5emof0.5emlexprt0.5emlexprTying 
the recursive knot one last 
time.let0.5emrec0.5emeval30.5emsubst0.5em=0.5em0.5emevallexpr0.5emeval30.5em0.5em0.5em0.5em(fun0.5eme0.5em->0.5emLExprt0.5eme)0.5em0.5em0.5em0.5em(fun0.5em(LExprt0.5eme)0.5em->0.5emSome0.5eme)0.5emsubstLightweight FP non-solution: Extensible Variant Types

* Exceptions have always formed an extensible variant type in OCaml, whose 
  pattern matching is done using the try$\ldots$with syntax. Since recently, 
  new extensible variant types can be defined. This augments the normal 
  function extensibility of FP with straightforward data extensibility.
* Non-solution penalty points:
  * Giving up exhaustivity checking, which is an important aspect of static 
    type safety.
  * More natural with “single inheritance” extension chains, although merging 
    is possible, and demonstrated in our example.
  * Requires “tying the recursive knot” for functions.

  Verdict: pleasant-looking, but the worst approach because of possible 
  bugginess. Unless bug-proneness is not a concern, then the best approach.

type0.5emexpr0.5em=0.5em..This is how extensible variant types are 
defined.type0.5emvarname0.5em=0.5emstringtype0.5emexpr0.5em+=0.5emVar0.5emof0.5emstringWe 
add a variant 
case.let0.5emevalvar0.5emsub0.5em=0.5emfunction0.5em0.5em0.5emVar0.5ems0.5emas0.5emv0.5em->0.5em(try0.5emList.assoc0.5ems0.5emsub0.5emwith0.5emNotfound0.5em->0.5emv)0.5em0.5em0.5eme0.5em->0.5emelet0.5emgensym0.5em=0.5emlet0.5emn0.5em=0.5emref0.5em00.5emin0.5emfun0.5em()0.5em->0.5emincr0.5emn;0.5em""0.5em0.5emstringofint0.5em!ntype0.5emexpr0.5em+=0.5emAbs0.5emof0.5emstring0.5em\*0.5emexpr0.5em0.5emApp0.5emof0.5emexpr0.5em\*0.5emexprThe 
sub-languagesare not differentiated by types, a shortcoming of this 
non-solution.let0.5emevallambda0.5emevalrec0.5emsubst0.5em=0.5emfunction0.5em0.5em0.5emVar0.5em0.5emas0.5emv0.5em->0.5emevalvar0.5emsubst0.5emv0.5em0.5em0.5emApp0.5em(l1,0.5eml2)0.5em->0.5em0.5em0.5em0.5emlet0.5eml2'0.5em=0.5emevalrec0.5emsubst0.5eml20.5emin0.5em0.5em0.5em0.5em(match0.5emevalrec0.5emsubst0.5eml10.5emwith0.5em0.5em0.5em0.5em0.5emAbs0.5em(s,0.5embody)0.5em->0.5em0.5em0.5em0.5em0.5em0.5emevalrec0.5em[s,0.5eml2']0.5embody0.5em0.5em0.5em0.5em0.5eml1'0.5em->0.5emApp0.5em(l1',0.5eml2'))0.5em0.5em0.5emAbs0.5em(s,0.5eml1)0.5em->0.5em0.5em0.5em0.5emlet0.5ems'0.5em=0.5emgensym0.5em()0.5emin0.5em0.5em0.5em0.5emAbs0.5em(s',0.5emevalrec0.5em((s,0.5emVar0.5ems')::subst)0.5eml1)0.5em0.5em0.5eme0.5em->0.5emelet0.5emfreevarslambda0.5emfreevarsrec0.5em=0.5emfunction0.5em0.5em0.5emVar0.5emv0.5em->0.5em[v]0.5em0.5em0.5emApp0.5em(l1,0.5eml2)0.5em->0.5emfreevarsrec0.5eml10.5em@0.5emfreevarsrec0.5eml20.5em0.5em0.5emAbs0.5em(s,0.5eml1)0.5em->0.5em0.5em0.5em0.5emList.filter0.5em(fun0.5emv0.5em->0.5emv0.5em<>0.5ems)0.5em(freevarsrec0.5eml1)0.5em0.5em->0.5em[]let0.5emrec0.5emeval10.5emsubst0.5eme0.5em=0.5emevallambda0.5emeval10.5emsubst0.5emelet0.5emrec0.5emfreevars10.5eme0.5em=0.5emfreevarslambda0.5emfreevars10.5emelet0.5emtest10.5em=0.5emApp0.5em(Abs0.5em("x",0.5emVar0.5em"x"),0.5emVar0.5em"y")let0.5emetest0.5em=0.5emeval10.5em[]0.5emtest1let0.5emfvtest0.5em=0.5emfreevars10.5emtest1type0.5emexpr0.5em+=0.5emNum0.5emof0.5emint0.5em0.5emAdd0.5emof0.5emexpr0.5em\*0.5emexpr0.5em0.5emMult0.5emof0.5emexpr0.5em\*0.5emexprlet0.5emmapexpr0.5emf0.5em=0.5emfunction0.5em0.5em0.5emAdd0.5em(e1,0.5eme2)0.5em->0.5emAdd0.5em(f0.5eme1,0.5emf0.5eme2)0.5em0.5em0.5emMult0.5em(e1,0.5eme2)0.5em->0.5emMult0.5em(f0.5eme1,0.5emf0.5eme2)0.5em0.5em0.5eme0.5em->0.5emelet0.5emevalexpr0.5emevalrec0.5emsubst0.5eme0.5em=0.5em0.5emmatch0.5emmapexpr0.5em(evalrec0.5emsubst)0.5eme0.5emwith0.5em0.5em0.5emAdd0.5em(Num0.5emm,0.5emNum0.5emn)0.5em->0.5emNum0.5em(m0.5em+0.5emn)0.5em0.5em0.5emMult0.5em(Num0.5emm,0.5emNum0.5emn)0.5em->0.5emNum0.5em(m0.5em\*0.5emn)0.5em0.5em0.5em(Num0.5em0.5em0.5emAdd0.5em0.5em0.5emMult0.5em)0.5emas0.5eme0.5em->0.5eme0.5em0.5em0.5eme0.5em->0.5emelet0.5emfreevarsexpr0.5emfreevarsrec0.5em=0.5emfunction0.5em0.5em0.5emNum0.5em0.5em->0.5em[]0.5em0.5em0.5emAdd0.5em(e1,0.5eme2)0.5em0.5emMult0.5em(e1,0.5eme2)0.5em->0.5emfreevarsrec0.5eme10.5em@0.5emfreevarsrec0.5eme20.5em0.5em->0.5em[]let0.5emrec0.5emeval20.5emsubst0.5eme0.5em=0.5emevalexpr0.5emeval20.5emsubst0.5emelet0.5emrec0.5emfreevars20.5eme0.5em=0.5emfreevarsexpr0.5emfreevars20.5emelet0.5emtest20.5em=0.5emAdd0.5em(Mult0.5em(Num0.5em3,0.5emVar0.5em"x"),0.5emNum0.5em1)let0.5emetest20.5em=0.5emeval20.5em[]0.5emtest2let0.5emfvtest20.5em=0.5emfreevars20.5emtest2let0.5emevallexpr0.5emevalrec0.5emsubst0.5eme0.5em=0.5em0.5emevalexpr0.5emevalrec0.5emsubst0.5em(evallambda0.5emevalrec0.5emsubst0.5eme)let0.5emfreevarslexpr0.5emfreevarsrec0.5eme0.5em=0.5em0.5emfreevarslambda0.5emfreevarsrec0.5eme0.5em@0.5emfreevarsexpr0.5emfreevarsrec0.5emelet0.5emrec0.5emeval30.5emsubst0.5eme0.5em=0.5emevallexpr0.5emeval30.5emsubst0.5emelet0.5emrec0.5emfreevars30.5eme0.5em=0.5emfreevarslexpr0.5emfreevars30.5emelet0.5emtest30.5em=0.5em0.5emApp0.5em(Abs0.5em("x",0.5emAdd0.5em(Mult0.5em(Num0.5em3,0.5emVar0.5em"x"),0.5emNum0.5em1)),0.5em0.5em0.5em0.5em0.5em0.5em0.5emNum0.5em2)let0.5emetest30.5em=0.5emeval30.5em[]0.5emtest3let0.5emfvtest30.5em=0.5emfreevars30.5emtest3Object Oriented Programming: Subtyping

* OCaml's *objects* are values, somewhat similar to records.
* Viewed from the outside, an OCaml object has only *methods*, identifying the 
  code with which to respond to messages, i.e. method invocations.
* All methods are *late-bound*, the object determines what code is run 
  (i.e. *virtual* in C++ parlance).
* *Subtyping* determines if an object can be used in some context. OCaml 
  has *structural subtyping*: the content of the types concerned decides if an 
  object can be used.
* Parametric polymorphism can be used to infer if an object has the required 
  methods.

let0.5emf0.5emx0.5em=0.5emx#mMethod invocation: 
object#method.val0.5emf0.5em:0.5em<0.5emm0.5em:0.5em'a;0.5em..0.5em>0.5em->0.5em'aType 
poymorphic in two ways: `'a` is the method type,.. means that objects with 
more methods will be accepted.

* Methods are computed when they are invoked, even if they do not take 
  arguments.
* We define objects inside object…end (compare: records {…}) using 
  keywords method for methods, val for constant fields and val mutable for 
  mutable fields. Constructor arguments can often be used instead of constant 
  fields:

  
  let0.5emsquare0.5emw0.5em=0.5emobject0.5em0.5emmethod0.5emarea0.5em=0.5emfloatofint0.5em(w0.5em\*0.5emw)0.5emmethod0.5emwidth0.5em=0.5emw0.5emend
* Subtyping often needs to be explicit: we write (object :> supertype) or 
  in more complex cases (object : type :> supertype).
  * Technically speaking, subtyping in OCaml always is explicit, and *open 
    types*, containing .., use *row polymorphism* rather than subtyping.


let0.5ema0.5em=0.5emobject0.5emmethod0.5emm0.5em=0.5em70.5em0.5emmethod0.5emx0.5em=0.5em"a"0.5emendToy 
example: object 
typeslet0.5emb0.5em=0.5emobject0.5emmethod0.5emm0.5em=0.5em420.5emmethod0.5emy0.5em=0.5em"b"0.5emendshare 
some but not all methods.let0.5eml0.5em=0.5em[a;0.5emb]The exact types of the 
objects do not 
agree.Error:0.5emThis0.5emexpression0.5emhas0.5emtype0.5em<0.5emm0.5em:0.5emint;0.5emy0.5em:0.5emstring0.5em>0.5em0.5em0.5em0.5em0.5em0.5em0.5embut0.5eman0.5emexpression0.5emwas0.5emexpected0.5emof0.5emtype0.5em<0.5emm0.5em:0.5emint;0.5emx0.5em:0.5emstring0.5em>0.5em0.5em0.5em0.5em0.5em0.5em0.5emThe0.5emsecond0.5emobject0.5emtype0.5emhas0.5emno0.5emmethod0.5emylet0.5eml0.5em=0.5em[(a0.5em:>0.5em<m0.5em:0.5em'a>);0.5em(b0.5em:>0.5em<m0.5em:0.5em'a>)]But 
the types share a 
supertype.val0.5eml0.5em:0.5em<0.5emm0.5em:0.5emint0.5em>0.5emlist

* *Variance* determines how type parameters behave wrt. subtyping:
  * *Invariant parameters* cannot be subtyped:

    
    let0.5emf0.5emx0.5em=0.5em(x0.5em:0.5em<m0.5em:0.5emint;0.5emn0.5em:0.5emfloat>0.5emarray0.5em:>0.5em<m0.5em:0.5emint>0.5emarray)Error:0.5emType0.5em<0.5emm0.5em:0.5emint;0.5emn0.5em:0.5emfloat0.5em>0.5emarray0.5emis0.5emnot0.5ema0.5emsubtype0.5emof0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em<0.5emm0.5em:0.5emint0.5em>0.5emarray0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5emThe0.5emsecond0.5emobject0.5emtype0.5emhas0.5emno0.5emmethod0.5emn
  * *Covariant parameters* are subtyped in the same direction as the type:

    
    let0.5emf0.5emx0.5em=0.5em(x0.5em:0.5em<m0.5em:0.5emint;0.5emn0.5em:0.5emfloat>0.5emlist0.5em:>0.5em<m0.5em:0.5emint>0.5emlist)val0.5emf0.5em:0.5em<0.5emm0.5em:0.5emint;0.5emn0.5em:0.5emfloat0.5em>0.5emlist0.5em->0.5em<0.5emm0.5em:0.5emint0.5em>0.5emlist
  * *Contravariant parameters* are subtyped in the opposite direction:

    
    let0.5emf0.5emx0.5em=0.5em(x0.5em:0.5em<m0.5em:0.5emint;0.5emn0.5em:0.5emfloat>0.5em->0.5emfloat0.5em:>0.5em<m0.5em:0.5emint>0.5em->0.5emfloat)Error:0.5emType0.5em<0.5emm0.5em:0.5emint;0.5emn0.5em:0.5emfloat0.5em>0.5em->0.5emfloat0.5emis0.5emnot0.5ema0.5emsubtype0.5emof0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em<0.5emm0.5em:0.5emint0.5em>0.5em->0.5emfloat0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5emType0.5em<0.5emm0.5em:0.5emint0.5em>0.5emis0.5emnot0.5ema0.5emsubtype0.5emof0.5em<0.5emm0.5em:0.5emint;0.5emn0.5em:0.5emfloat0.5em>0.5emlet0.5emf0.5emx0.5em=0.5em(x0.5em:0.5em<m0.5em:0.5emint>0.5em->0.5emfloat0.5em:>0.5em<m0.5em:0.5emint;0.5emn0.5em:0.5emfloat>0.5em->0.5emfloat)val0.5emf0.5em:0.5em(<0.5emm0.5em:0.5emint0.5em>0.5em->0.5emfloat)0.5em->0.5em<0.5emm0.5em:0.5emint;0.5emn0.5em:0.5emfloat0.5em>0.5em->0.5emfloatObject Oriented Programming: Inheritance

* The system of object classes in OCaml is similar to the module system.
  * Object classes are not types. Classes are a way to build 
    object *constructors* – functions that return objects.
  * Classes have their types (compare: modules and signatures).
* In OCaml parlance:
  * late binding is not called anything – all methods are late-bound (in C++ 
    called virtual)
  * a method or field declared to be defined in sub-classes is *virtual* (in 
    C++ called abstract); classes that use virtual methods or fields are also 
    called virtual
  * a method that is only visible in sub-classes is *private* (in C++ called 
    protected)
  * a method not visible outside the class is not called anything (in C++ 
    called private) – provide the type for the class, and omit the method in 
    the class type (compare: module signatures and `.mli` files)
* OCaml allows multiple inheritance, which can be used to implement *mixins* 
  as virtual / abstract classes.
* Inheritance works somewhat similarly to textual inclusion.
* See the excellent examples in 
  [https://realworldocaml.org/v1/en/html/classes.html](https://realworldocaml.org/v1/en/html/classes.html)
* You can perform `ocamlc -i Objects.ml` etc. to see inferred object and class 
  types.

OOP Non-solution: direct approach

* It turns out that although object oriented programming was designed with 
  data extensibility in mind, it is a bad fit for recursive types, like in the 
  expression problem. Below is my attempt at solving our problem using classes 
  – can you do better?
* Non-solution penalty points:
  * Functions implemented for a broader language (e.g. corresponding to 
    `lexpr_t` on other slides) cannot handle values from a narrower one (e.g. 
    corresponding to `expr_t`).
  * Writing a new function requires extending the language.
  * No deep pattern matching.

  Verdict: non-solution, better only than the extensible variant types-based 
  approach.

type0.5emvarname0.5em=0.5emstringlet0.5emgensym0.5em=0.5emlet0.5emn0.5em=0.5emref0.5em00.5emin0.5emfun0.5em()0.5em->0.5emincr0.5emn;0.5em""0.5em0.5emstringofint0.5em!nclass0.5emvirtual0.5em['lang]0.5emevaluable0.5em=The abstract class for objects supporting the `eval` method.object0.5emFor $\lambda$-calculus, we need helper functions:0.5em0.5emmethod0.5emvirtual0.5emeval0.5em:0.5em(varname0.5em\*0.5em'lang)0.5emlist0.5em->0.5em'lang0.5em0.5emmethod0.5emvirtual0.5emrename0.5em:0.5emvarname0.5em->0.5emvarname0.5em->0.5em`'lang`renaming of free variables,0.5em0.5emmethod0.5emapply0.5em(arg0.5em:0.5em'lang)$\beta$-reduction if possible (fallback otherwise).0.5em0.5em0.5em0.5em(fallback0.5em:0.5emunit0.5em->0.5em'lang)0.5em(subst0.5em:0.5em(varname0.5em\*0.5em'lang)0.5emlist)0.5em=0.5em0.5em0.5em0.5emfallback0.5em()endclass0.5em['lang]0.5emvar0.5em(v0.5em:0.5emvarname)0.5em=object0.5em(self)We name the current object `self`.0.5em0.5eminherit0.5em['lang]0.5emevaluable0.5em0.5emval0.5emv0.5em=0.5emv0.5em0.5emmethod0.5emeval0.5emsubst0.5em=0.5em0.5em0.5em0.5emtry0.5emList.assoc0.5emv0.5emsubst0.5emwith0.5emNotfound0.5em->0.5emself0.5em0.5emmethod0.5emrename0.5emv10.5emv20.5em=Renaming a variable:0.5em0.5em0.5em0.5emif0.5emv0.5em=0.5emv10.5emthen0.5em{<0.5emv0.5em=0.5emv20.5em>}0.5emelse0.5emselfwe clone the current object putting the new name.endclass0.5em['lang]0.5emabs0.5em(v0.5em:0.5emvarname)0.5em(body0.5em:0.5em'lang)0.5em=object0.5em(self)0.5em0.5eminherit0.5em['lang]0.5emevaluable0.5em0.5emval0.5emv0.5em=0.5emv0.5em0.5emval0.5embody0.5em=0.5embody0.5em0.5emmethod0.5emeval0.5emsubst0.5em=We do $\alpha$-conversion prior to evaluation.0.5em0.5em0.5em0.5emlet0.5emv'0.5em=0.5emgensym0.5em()0.5eminAlternatively, we could evaluate with0.5em0.5em0.5em0.5em{<0.5emv0.5em=0.5emv';0.5embody0.5em=0.5em(body#rename0.5emv0.5emv')#eval0.5emsubst0.5em>}substitution of `v`0.5em0.5emmethod0.5emrename0.5emv10.5emv20.5em=by `v_inst v' : 'lang` similar to `num_inst` below.0.5em0.5em0.5em0.5emif0.5emv0.5em=0.5emv10.5emthen0.5em`self`Renaming the free variable `v1`, so no work if `v=v1`.0.5em0.5em0.5em0.5emelse0.5em{<0.5embody0.5em=0.5embody#rename0.5emv10.5emv20.5em>}0.5em0.5emmethod0.5emapply0.5emargsubst0.5em=0.5em0.5em0.5em0.5embody#eval0.5em((v,0.5emarg)::subst)endclass0.5em['lang]0.5emapp0.5em(f0.5em:0.5em'lang)0.5em(arg0.5em:0.5em'lang)0.5em=object0.5em(self)0.5em0.5eminherit0.5em['lang]0.5emevaluable0.5em0.5emval0.5emf0.5em=0.5emf0.5em0.5emval0.5emarg0.5em=0.5emarg0.5em0.5emmethod0.5emeval0.5emsubst0.5em=We use `apply` to differentiate between `f = abs`0.5em0.5em0.5em0.5emlet0.5emarg'0.5em=0.5emarg#eval0.5emsubst0.5emin ($\beta$-redexes) and `f ≠ abs`.0.5em0.5em0.5em0.5emf#apply0.5emarg'0.5em(fun0.5em()0.5em->0.5em{<0.5emf0.5em=0.5emf#eval0.5emsubst;0.5emarg0.5em=0.5emarg'0.5em>})0.5emsubst0.5em0.5emmethod0.5emrename0.5emv10.5emv20.5em=Cloning the object ensures that it will be a subtype of `'lang`0.5em0.5em0.5em0.5em{<0.5emf0.5em=0.5emf#rename0.5emv10.5emv2;0.5emarg0.5em=0.5emarg#rename0.5emv10.5emv20.5em>}rather than just `'lang app`.endtype0.5emevaluablet0.5em=0.5emevaluablet0.5emevaluableThese definitions only add nice-looking types.let0.5emnewvar10.5emv0.5em:0.5emevaluablet0.5em=0.5emnew0.5emvar0.5emvlet0.5emnewabs10.5emv0.5em(body0.5em:0.5emevaluablet)0.5em:0.5emevaluablet0.5em=0.5emnew0.5emabs0.5emv0.5embodyclass0.5emvirtual0.5emcomputemixin0.5em=0.5emobjectFor evaluating arithmetic expressions we need0.5em0.5emmethod0.5emcompute0.5em:0.5emint0.5emoption0.5em=0.5emNone0.5em0.5ema heper method `compute`.endclass0.5em['lang]0.5emvarc0.5emv0.5em=0.5emobjectTo use $\lambda$-expressions together with arithmetic expressions0.5em0.5eminherit0.5em['lang]0.5em`var0.5emv`we need to upgrade them with the helper method.0.5em0.5eminherit0.5emcomputemixinendclass0.5em['lang]0.5emabsc0.5emv0.5embody0.5em=0.5emobject0.5em0.5eminherit0.5em['lang]0.5emabs0.5emv0.5embody0.5em0.5eminherit0.5emcomputemixinendclass0.5em['lang]0.5emappc0.5emf0.5emarg0.5em=0.5emobject0.5em0.5eminherit0.5em['lang]0.5emapp0.5emf0.5emarg0.5em0.5eminherit0.5emcomputemixinendclass0.5em['lang]0.5emnum0.5em(i0.5em:0.5emint)0.5em=A numerical constant.object0.5em(self)0.5em0.5eminherit0.5em['lang]0.5emevaluable0.5em0.5emval0.5emi0.5em=0.5emi0.5em0.5emmethod0.5emeval0.5emsubst0.5em=0.5emself0.5em0.5emmethod0.5emrename0.5em=0.5emself0.5em0.5emmethod0.5emcompute0.5em=0.5emSome0.5emiendclass0.5emvirtual0.5em['lang]0.5em`operation`Abstract class for evaluating arithmetic operations.0.5em0.5em0.5em0.5em(numinst0.5em:0.5emint0.5em->0.5em'lang)0.5em(n10.5em:0.5em'lang)0.5em(n20.5em:0.5em'lang)0.5em=object0.5em(self)0.5em0.5eminherit0.5em['lang]0.5emevaluable0.5em0.5emval0.5emn10.5em=0.5emn10.5em0.5emval0.5emn20.5em=0.5emn20.5em0.5emmethod0.5emeval0.5emsubst0.5em=0.5em0.5em0.5em0.5emlet0.5emself'0.5em=0.5em{<0.5emn10.5em=0.5emn1#eval0.5emsubst;0.5emn20.5em=0.5emn2#eval0.5emsubst0.5em>}0.5emin0.5em0.5em0.5em0.5emmatch0.5emself'#compute0.5emwith0.5em0.5em0.5em0.5em0.5emSome0.5emi0.5em->0.5em`numinst0.5emi`We need to inject the integer as a constant that is0.5em0.5em0.5em0.5em->0.5em`self'`a subtype of `'lang`.0.5em0.5emmethod0.5emrename0.5emv10.5emv20.5em=0.5em{<0.5emn10.5em=0.5emn1#rename0.5emv10.5emv2;0.5emn20.5em=0.5emn2#rename0.5emv10.5emv20.5em>}endclass0.5em['lang]0.5emadd0.5emnuminst0.5emn10.5emn20.5em=object0.5em(self)0.5em0.5eminherit0.5em['lang]0.5emoperation0.5emnuminst0.5emn10.5emn20.5em0.5emmethod0.5emcompute0.5em=If `compute` is called by `eval`, as intended,0.5em0.5em0.5em0.5emmatch0.5emn1#compute,0.5emn2#compute0.5emwiththen `n1` and `n2` are already computed.0.5em0.5em0.5em0.5em0.5emSome0.5emi1,0.5emSome0.5emi20.5em->0.5emSome0.5em(i10.5em+0.5emi2)0.5em0.5em0.5em0.5em->0.5emNoneendclass0.5em['lang]0.5emmult0.5emnuminst0.5emn10.5emn20.5em=object0.5em(self)0.5em0.5eminherit0.5em['lang]0.5emoperation0.5emnuminst0.5emn10.5emn20.5em0.5emmethod0.5emcompute0.5em=0.5em0.5em0.5em0.5emmatch0.5emn1#compute,0.5emn2#compute0.5emwith0.5em0.5em0.5em0.5em0.5emSome0.5emi1,0.5emSome0.5emi20.5em->0.5emSome0.5em(i10.5em\*0.5emi2)0.5em0.5em0.5em0.5em->0.5emNoneendclass0.5emvirtual0.5em['lang]0.5emcomputable0.5em=This class is defined merely to provide an object type,objectwe could also define this object type ‘‘by hand''.0.5em0.5eminherit0.5em['lang]0.5emevaluable0.5em0.5eminherit0.5emcomputemixinendtype0.5emcomputablet0.5em=0.5emcomputablet0.5emcomputableNice types for all the constructors.let0.5emnewvar20.5emv0.5em:0.5emcomputablet0.5em=0.5emnew0.5emvarc0.5emvlet0.5emnewabs20.5emv0.5em(body0.5em:0.5emcomputablet)0.5em:0.5emcomputablet0.5em=0.5emnew0.5emabsc0.5emv0.5embodylet0.5emnewapp20.5emv0.5em(body0.5em:0.5emcomputablet)0.5em:0.5emcomputablet0.5em=0.5emnew0.5emappc0.5emv0.5embodylet0.5emnewnum20.5emi0.5em:0.5emcomputablet0.5em=0.5emnew0.5emnum0.5emilet0.5emnewadd20.5em(n10.5em:0.5emcomputablet)0.5em(n20.5em:0.5emcomputablet)0.5em:0.5emcomputablet0.5em=0.5em0.5emnew0.5emadd0.5emnewnum20.5emn10.5emn2let0.5emnewmult20.5em(n10.5em:0.5emcomputablet)0.5em(n20.5em:0.5emcomputablet)0.5em:0.5emcomputablet0.5em=0.5em0.5emnew0.5emmult0.5emnewnum20.5emn10.5emn2OOP: The Visitor Pattern

* The *Visitor Pattern* is an object-oriented programming pattern for turning 
  objects into variants with shallow pattern-matching (i.e. dispatch based on 
  which variant a value is). It replaces data extensibility by operation 
  extensibility.
* I needed to use imperative features (mutable fields), can you do better?
* Penalty points:
  * Heavy code bloat.
  * Side-effects appear to be required.
  * No deep pattern matching.

  Verdict: poor solution, better than approaches we considered so far, and 
  worse than approaches we consider next.

type0.5em'visitor0.5emvisitable0.5em=0.5em<0.5emaccept0.5em:0.5em'visitor0.5em->0.5emunit0.5em>The variants need be visitable.We store the computation as side effect because of the difficultytype0.5emvarname0.5em=0.5emstringto keep the visitor polymorphic but have the result typedepend on the visitor.class0.5em['visitor]0.5emvar0.5em(v0.5em:0.5emvarname)0.5em=The `'visitor` will determine the (sub)languageobject0.5em(self)to which a given `var` variant belongs.0.5em0.5emmethod0.5emv0.5em=0.5emv0.5em0.5emmethod0.5emaccept0.5em:0.5em'visitor0.5em->0.5emunit0.5em=The visitor pattern inverts the way0.5em0.5em0.5em0.5emfun0.5emvisitor0.5em->0.5emvisitor#visitVar0.5emselfpattern matching proceeds: the variantendselects the pattern matching branch.let0.5emnewvar0.5emv0.5em=0.5em(new0.5emvar0.5emv0.5em:>0.5em'a0.5emvisitable)Visitors need to see the stored data,but distinct constructors need to belong to the same type.class0.5em['visitor]0.5emabs0.5em(v0.5em:0.5emvarname)0.5em(body0.5em:0.5em'visitor0.5emvisitable)0.5em=object0.5em(self)0.5em0.5emmethod0.5emv0.5em=0.5emv0.5em0.5emmethod0.5embody0.5em=0.5embody0.5em0.5emmethod0.5emaccept0.5em:0.5em'visitor0.5em->0.5emunit0.5em=0.5em0.5em0.5em0.5emfun0.5emvisitor0.5em->0.5emvisitor#visitAbs0.5emselfendlet0.5emnewabs0.5emv0.5embody0.5em=0.5em(new0.5emabs0.5emv0.5embody0.5em:>0.5em'a0.5emvisitable)class0.5em['visitor]0.5emapp0.5em(f0.5em:0.5em'visitor0.5emvisitable)0.5em(arg0.5em:0.5em'visitor0.5emvisitable)0.5em=object0.5em(self)0.5em0.5emmethod0.5emf0.5em=0.5emf0.5em0.5emmethod0.5emarg0.5em=0.5emarg0.5em0.5emmethod0.5emaccept0.5em:0.5em'visitor0.5em->0.5emunit0.5em=0.5em0.5em0.5em0.5emfun0.5emvisitor0.5em->0.5emvisitor#visitApp0.5emselfendlet0.5emnewapp0.5emf0.5emarg0.5em=0.5em(new0.5emapp0.5emf0.5emarg0.5em:>0.5em'a0.5emvisitable)class0.5emvirtual0.5em['visitor]0.5emlambdavisit0.5em=This abstract class has two uses:objectit defines the visitors for the sub-langauge of $\lambda$-expressions,0.5em0.5emmethod0.5emvirtual0.5emvisitVar0.5em:0.5em'visitor0.5emvar0.5em->0.5emunitand it will provide an early check0.5em0.5emmethod0.5emvirtual0.5emvisitAbs0.5em:0.5em'visitor0.5emabs0.5em->0.5emunitthat the visitor classes0.5em0.5emmethod0.5emvirtual0.5emvisitApp0.5em:0.5em'visitor0.5emapp0.5em->0.5emunitimplement all the methods.endlet0.5emgensym0.5em=0.5emlet0.5emn0.5em=0.5emref0.5em00.5emin0.5emfun0.5em()0.5em->0.5emincr0.5emn;0.5em""0.5em0.5emstringofint0.5em!nclass0.5em['visitor]0.5em`evallambda`0.5em0.5em(subst0.5em:0.5em(varname0.5em\*0.5em'visitor0.5emvisitable)0.5emlist)0.5em0.5em(result0.5em:0.5em'visitor0.5emvisitable0.5emref)0.5em=An output argument, but also used internallyobject0.5em(self)to store intermediate results.0.5em0.5eminherit0.5em['visitor]0.5emlambdavisit0.5em0.5emval0.5emmutable0.5emsubst0.5em=0.5em`subst`We avoid threading the argument through the visit methods.0.5em0.5emval0.5emmutable0.5embetaredex0.5em:0.5em(varname0.5em\*0.5em'visitor0.5emvisitable)0.5emoption0.5em=0.5emNoneWe work around0.5em0.5emmethod0.5emvisitVar0.5emvar0.5em=the need to differentiate between `abs` and non-`abs` values0.5em0.5em0.5em0.5embetaredex0.5em<-0.5emNone;of app#f inside `visitApp`.0.5em0.5em0.5em0.5emtry0.5emresult0.5em:=0.5emList.assoc0.5emvar#v0.5emsubst0.5em0.5em0.5em0.5emwith0.5emNotfound0.5em->0.5emresult0.5em:=0.5em(var0.5em:>0.5em'visitor0.5emvisitable)0.5em0.5emmethod0.5emvisitAbs0.5emabs0.5em=0.5em0.5em0.5em0.5emlet0.5emv'0.5em=0.5emgensym0.5em()0.5emin0.5em0.5em0.5em0.5emlet0.5emorigsubst0.5em=0.5emsubst0.5emin0.5em0.5em0.5em0.5emsubst0.5em<-0.5em(abs#v,0.5emnew\_var0.5emv')::subst;‘‘Pass'' the updated substitution0.5em0.5em0.5em0.5em(abs#body)#accept0.5emself;to the recursive call0.5em0.5em0.5em0.5emlet0.5embody'0.5em=0.5em!result0.5eminand collect the result of the recursive call.0.5em0.5em0.5em0.5emsubst0.5em<-0.5emorigsubst;0.5em0.5em0.5em0.5embetaredex0.5em<-0.5emSome0.5em(v',0.5embody');Indicate that an `abs` has just been visited.0.5em0.5em0.5em0.5emresult0.5em:=0.5emnewabs0.5emv'0.5embody'0.5em0.5emmethod0.5emvisitApp0.5emapp0.5em=0.5em0.5em0.5em0.5emapp#arg#accept0.5emself;0.5em0.5em0.5em0.5emlet0.5emarg'0.5em=0.5em!result0.5emin0.5em0.5em0.5em0.5emapp#f#accept0.5emself;0.5em0.5em0.5em0.5emlet0.5emf'0.5em=0.5em!result0.5emin0.5em0.5em0.5em0.5emmatch0.5embetaredex0.5emwithPattern-match on app#f.0.5em0.5em0.5em0.5em0.5emSome0.5em(v',0.5embody')0.5em->0.5em0.5em0.5em0.5em0.5em0.5embetaredex0.5em<-0.5emNone;0.5em0.5em0.5em0.5em0.5em0.5emlet0.5emorigsubst0.5em=0.5emsubst0.5emin0.5em0.5em0.5em0.5em0.5em0.5emsubst0.5em<-0.5em(v',0.5emarg')::subst;0.5em0.5em0.5em0.5em0.5em0.5embody'#accept0.5emself;0.5em0.5em0.5em0.5em0.5em0.5emsubst0.5em<-0.5emorigsubst0.5em0.5em0.5em0.5em0.5emNone0.5em->0.5emresult0.5em:=0.5emnewapp0.5emf'0.5emarg'endclass0.5em['visitor]0.5emfreevarslambda0.5em(result0.5em:0.5emvarname0.5emlist0.5emref)0.5em=object0.5em(self)We use `result` as an accumulator.0.5em0.5eminherit0.5em['visitor]0.5emlambdavisit0.5em0.5emmethod0.5emvisitVar0.5emvar0.5em=0.5em0.5em0.5em0.5emresult0.5em:=0.5emvar#v0.5em::0.5em!result0.5em0.5emmethod0.5emvisitAbs0.5emabs0.5em=0.5em0.5em0.5em0.5em(abs#body)#accept0.5emself;0.5em0.5em0.5em0.5emresult0.5em:=0.5emList.filter0.5em(fun0.5emv'0.5em->0.5emv'0.5em<>0.5emabs#v)0.5em!result0.5em0.5emmethod0.5emvisitApp0.5emapp0.5em=0.5em0.5em0.5em0.5emapp#arg#accept0.5emself;0.5emapp#f#accept0.5emselfendtype0.5emlambdavisitt0.5em=0.5emlambdavisitt0.5emlambdavisitVisitor for the language of $\lambda$-expressions.type0.5emlambdat0.5em=0.5emlambdavisitt0.5emvisitablelet0.5emeval10.5em(e0.5em:0.5emlambdat)0.5emsubst0.5em:0.5emlambdat0.5em=0.5em0.5emlet0.5emresult0.5em=0.5emref0.5em(newvar0.5em"")0.5eminThis initial value will be ignored.0.5em0.5eme#accept0.5em(new0.5emevallambda0.5emsubst0.5emresult0.5em:>0.5emlambdavisitt);0.5em0.5em!resultlet0.5emfreevars10.5em(e0.5em:0.5emlambdat)0.5em=0.5em0.5emlet0.5emresult0.5em=0.5emref0.5em[]0.5eminInitial value of the accumulator.0.5em0.5eme#accept0.5em(new0.5emfreevarslambda0.5emresult);0.5em0.5em!resultlet0.5emtest10.5em=0.5em0.5em(newapp0.5em(newabs0.5em"x"0.5em(newvar0.5em"x"))0.5em(newvar0.5em"y")0.5em:>0.5emlambdat)let0.5emetest0.5em=0.5emeval10.5emtest10.5em[]let0.5emfvtest0.5em=0.5emfreevars10.5emtest1class0.5em['visitor]0.5emnum0.5em(i0.5em:0.5emint)0.5em=object0.5em(self)0.5em0.5emmethod0.5emi0.5em=0.5emi0.5em0.5emmethod0.5emaccept0.5em:0.5em'visitor0.5em->0.5emunit0.5em=0.5em0.5em0.5em0.5emfun0.5emvisitor0.5em->0.5emvisitor#visitNum0.5emselfendlet0.5emnewnum0.5emi0.5em=0.5em(new0.5emnum0.5emi0.5em:>0.5em'a0.5emvisitable)class0.5emvirtual0.5em['visitor]0.5emoperation0.5em0.5em(arg10.5em:0.5em'visitor0.5emvisitable)0.5em(arg20.5em:0.5em'visitor0.5emvisitable)0.5em=object0.5em(self)Shared accessor methods.0.5em0.5emmethod0.5emarg10.5em=0.5emarg10.5em0.5emmethod0.5emarg20.5em=0.5emarg2endclass0.5em['visitor]0.5emadd0.5emarg10.5emarg20.5em=object0.5em(self)0.5em0.5eminherit0.5em['visitor]0.5emoperation0.5emarg10.5emarg20.5em0.5emmethod0.5emaccept0.5em:0.5em'visitor0.5em->0.5emunit0.5em=0.5em0.5em0.5em0.5emfun0.5emvisitor0.5em->0.5emvisitor#visitAdd0.5emselfendlet0.5emnewadd0.5emarg10.5emarg20.5em=0.5em(new0.5emadd0.5emarg10.5emarg20.5em:>0.5em'a0.5emvisitable)class0.5em['visitor]0.5emmult0.5emarg10.5emarg20.5em=object0.5em(self)0.5em0.5eminherit0.5em['visitor]0.5emoperation0.5emarg10.5emarg20.5em0.5emmethod0.5emaccept0.5em:0.5em'visitor0.5em->0.5emunit0.5em=0.5em0.5em0.5em0.5emfun0.5emvisitor0.5em->0.5emvisitor#visitMult0.5emselfendlet0.5emnewmult0.5emarg10.5emarg20.5em=0.5em(new0.5emmult0.5emarg10.5emarg20.5em:>0.5em'a0.5emvisitable)class0.5emvirtual0.5em['visitor]0.5emexprvisit0.5em=The sub-language of arithmetic expressions.object0.5em0.5emmethod0.5emvirtual0.5emvisitNum0.5em:0.5em'visitor0.5emnum0.5em->0.5emunit0.5em0.5emmethod0.5emvirtual0.5emvisitAdd0.5em:0.5em'visitor0.5emadd0.5em->0.5emunit0.5em0.5emmethod0.5emvirtual0.5emvisitMult0.5em:0.5em'visitor0.5emmult0.5em->0.5emunitendclass0.5em['visitor]0.5emevalexpr0.5em0.5em(result0.5em:0.5em'visitor0.5emvisitable0.5emref)0.5em=object0.5em(self)0.5em0.5eminherit0.5em['visitor]0.5emexprvisit0.5em0.5emval0.5emmutable0.5emnumredex0.5em:0.5emint0.5emoption0.5em=0.5emNoneThe numeric result, if any.0.5em0.5emmethod0.5emvisitNum0.5emnum0.5em=0.5em0.5em0.5em0.5emnumredex0.5em<-0.5emSome0.5emnum#i;0.5em0.5em0.5em0.5emresult0.5em:=0.5em(num0.5em:>0.5em'visitor0.5emvisitable)0.5em0.5emmethod0.5emprivate0.5emvisitOperation0.5emnewe0.5emop0.5eme0.5em=0.5em0.5em0.5em0.5em(e#arg1)#accept0.5emself;0.5em0.5em0.5em0.5emlet0.5emarg1'0.5em=0.5em!result0.5emand0.5emi10.5em=0.5emnumredex0.5emin0.5em0.5em0.5em0.5em(e#arg2)#accept0.5emself;0.5em0.5em0.5em0.5emlet0.5emarg2'0.5em=0.5em!result0.5emand0.5emi20.5em=0.5emnumredex0.5emin0.5em0.5em0.5em0.5emmatch0.5emi1,0.5emi20.5emwith0.5em0.5em0.5em0.5em0.5emSome0.5emi1,0.5emSome0.5emi20.5em->0.5em0.5em0.5em0.5em0.5em0.5emlet0.5emres0.5em=0.5emop0.5emi10.5emi20.5emin0.5em0.5em0.5em0.5em0.5em0.5emnumredex0.5em<-0.5emSome0.5emres;0.5emresult0.5em:=0.5emnewnum0.5emres0.5em0.5em0.5em0.5em->0.5em0.5em0.5em0.5em0.5em0.5emnumredex0.5em<-0.5emNone;0.5em0.5em0.5em0.5em0.5em0.5emresult0.5em:=0.5emnewe0.5emarg1'0.5emarg2'0.5em0.5emmethod0.5emvisitAdd0.5emadd0.5em=0.5emself#visitOperation0.5emnewadd0.5em(0.5em+0.5em)0.5emadd0.5em0.5emmethod0.5emvisitMult0.5emmult0.5em=0.5emself#visitOperation0.5emnewmult0.5em(0.5em\*0.5em)0.5emmultendclass0.5em['visitor]0.5emfreevarsexpr0.5em(result0.5em:0.5emvarname0.5emlist0.5emref)0.5em=Flow-through classobject0.5em(self)for computing free variables.0.5em0.5eminherit0.5em['visitor]0.5emexprvisit0.5em0.5emmethod0.5emvisitNum=0.5em()0.5em0.5emmethod0.5emvisitAdd0.5emadd0.5em=0.5em0.5em0.5em0.5emadd#arg1#accept0.5emself;0.5emadd#arg2#accept0.5emself0.5em0.5emmethod0.5emvisitMult0.5emmult0.5em=0.5em0.5em0.5em0.5emmult#arg1#accept0.5emself;0.5emmult#arg2#accept0.5emselfendtype0.5emexprvisitt0.5em=0.5emexprvisitt0.5emexprvisitThe language of arithmetic expressionstype0.5emexprt0.5em=0.5emexprvisitt0.5emvisitable-- in this example without variables.let0.5emeval20.5em(e0.5em:0.5emexprt)0.5em:0.5emexprt0.5em=0.5em0.5emlet0.5emresult0.5em=0.5emref0.5em(newnum0.5em0)0.5eminThis initial value will be ignored.0.5em0.5eme#accept0.5em(new0.5emevalexpr0.5emresult);0.5em0.5em!resultlet0.5emtest20.5em=0.5em0.5em(newadd0.5em(newmult0.5em(newnum0.5em3)0.5em(newnum0.5em3))0.5em(newnum0.5em1)0.5em:>0.5emexprt)let0.5emetest0.5em=0.5emeval20.5emtest2class0.5emvirtual0.5em['visitor]0.5emlexprvisit0.5em=Combining the variants / constructors.object0.5em0.5eminherit0.5em['visitor]0.5emlambdavisit0.5em0.5eminherit0.5em['visitor]0.5emexprvisitendclass0.5em['visitor]0.5emevallexpr0.5emsubst0.5emresult0.5em=Combining the ‘‘pattern-matching branches''.object0.5em0.5eminherit0.5em['visitor]0.5emevalexpr0.5emresult0.5em0.5eminherit0.5em['visitor]0.5emevallambda0.5emsubst0.5emresultendclass0.5em['visitor]0.5emfreevarslexpr0.5emresult0.5em=object0.5em0.5eminherit0.5em['visitor]0.5emfreevarsexpr0.5emresult0.5em0.5eminherit0.5em['visitor]0.5emfreevarslambda0.5emresultendtype0.5emlexprvisitt0.5em=0.5emlexprvisitt0.5emlexprvisitThe language combiningtype0.5emlexprt0.5em=0.5emlexprvisitt0.5emvisitable$\lambda$-expressions and arithmetic expressions.let0.5emeval30.5em(e0.5em:0.5emlexprt)0.5emsubst0.5em:0.5emlexprt0.5em=0.5em0.5emlet0.5emresult0.5em=0.5emref0.5em(newnum0.5em0)0.5emin0.5em0.5eme#accept0.5em(new0.5emevallexpr0.5emsubst0.5emresult);0.5em0.5em!resultlet0.5emfreevars30.5em(e0.5em:0.5emlexprt)0.5em=0.5em0.5emlet0.5emresult0.5em=0.5emref0.5em[]0.5emin0.5em0.5eme#accept0.5em(new0.5emfreevarslexpr0.5emresult);0.5em0.5em!resultlet0.5emtest30.5em=0.5em0.5em(newadd0.5em(newmult0.5em(newnum0.5em3)0.5em(newvar0.5em"x"))0.5em(newnum0.5em1)0.5em:>0.5emlexprt)let0.5emetest0.5em=0.5emeval30.5emtest30.5em[]let0.5emfvtest0.5em=0.5emfreevars30.5emtest3let0.5emoldetest0.5em=0.5emeval30.5em(test20.5em:>0.5emlexprt)0.5em[]let0.5emoldfvtest0.5em=0.5emeval30.5em(test20.5em:>0.5emlexprt)0.5em[]Polymorphic Variant Types: Subtyping

* Polymorphic variants are to ordinary variants as objects are to records: 
  both enable *open types* and subtyping, both allow different types to share 
  the same components.
  * They are *dual* concepts in that if we replace “product” of records / 
    objects by “sum” (see lecture 2), we get variants / polymorphic 
    variants.Duality implies many behaviors are opposite.
* While object subtypes have more methods, polymorphic variant subtypes have 
  less tags.
* The > sign means “these tags or more”:

  
  let0.5eml0.5em=0.5em[‘Int0.5em3;0.5em‘Float0.5em4.];;val0.5eml0.5em:0.5em[>0.5em‘Float0.5emof0.5emfloat0.5em0.5em‘Int0.5emof0.5emint0.5em]0.5emlist0.5em=0.5em[‘Int0.5em3;0.5em‘Float0.5em4.]
* The < sign means “these tags or less”:

  
  let0.5emispositive0.5em=0.5emfunction0.5em0.5em0.5em0.5em0.5em0.5em‘Int0.5em0.5em0.5emx0.5em->0.5emSome0.5em(x0.5em>0.5em0)0.5em0.5em0.5em0.5em0.5em0.5em‘Float0.5emx0.5em->0.5emSome0.5em(x0.5em>0.5em0.)0.5em0.5em0.5em0.5em0.5em0.5em‘Notanumber0.5em->0.5emNone;;val0.5emispositive0.5em:0.5em0.5em[<0.5em‘Float0.5emof0.5emfloat0.5em0.5em‘Int0.5emof0.5emint0.5em0.5em‘Notanumber0.5em]0.5em->0.5em 
     bool0.5emoption0.5em=0.5em<fun>
* No sign means a closed type (similar to an object type without the ..)
* Both an upper and a lower bound are sometimes inferred,see 
  [https://realworldocaml.org/v1/en/html/variants.html](https://realworldocaml.org/v1/en/html/variants.html)

  
  List.filter0.5em0.5em(fun0.5emx0.5em->0.5emmatch0.5emispositive0.5emx0.5emwith0.5emNone0.5em->0.5emfalse0.5em0.5emSome0.5emb0.5em->0.5emb)0.5eml;;-0.5em:0.5em[<0.5em‘Float0.5emof0.5emfloat0.5em0.5em‘Int0.5emof0.5emint0.5em0.5em‘Notanumber0.5em>0.5em‘Float0.5em‘Int0.5em]0.5em 
       list0.5em=[‘Int0.5em3;0.5em‘Float0.5em4.]Polymorphic Variant Types: The Expression Problem

* Because distinct polymorphic variant types can share the same tags, the 
  solution to the Expression Problem is straightforward.
* Penalty points:
  * The need to “tie the recursive knot” separately both at the type level and 
    the function level. At the function level, an $\eta$-expansion is required 
    due to *value recursion* problem. At the type level, the type variable can 
    be confusing.
  * There can be a slight time cost compared to the visitor pattern-based 
    approach: additional dispatch at each level of type aggregation (i.e. 
    merging sub-languages).

  Verdict: a flexible and concise solution, second-best place.


type0.5emvar0.5em=0.5em[‘Var0.5emof0.5emstring]let0.5emevalvar0.5emsub0.5em(‘Var0.5ems0.5emas0.5emv0.5em:0.5emvar)0.5em=0.5em0.5emtry0.5emList.assoc0.5ems0.5emsub0.5emwith0.5emNotfound0.5em->0.5emvtype0.5em'a0.5emlambda0.5em=0.5em0.5em[‘Var0.5emof0.5emstring0.5em0.5em‘Abs0.5emof0.5emstring0.5em\*0.5em'a0.5em0.5em‘App0.5emof0.5em'a0.5em\*0.5em'a]let0.5emgensym0.5em=0.5emlet0.5emn0.5em=0.5emref0.5em00.5emin0.5emfun0.5em()0.5em->0.5emincr0.5emn;0.5em""0.5em0.5emstringofint0.5em!nlet0.5emevallambda0.5emevalrec0.5emsubst0.5em:0.5em'a0.5emlambda0.5em->0.5em'a0.5em=0.5emfunction0.5em0.5em0.5em#var0.5emas0.5emv0.5em->0.5em`evalvar0.5emsubst0.5emv`We 
could also leave the type 
open0.5em0.5em0.5em‘App0.5em(l1,0.5eml2)0.5em->rather than closing it to 
`lambda`.0.5em0.5em0.5em0.5emlet0.5eml2'0.5em=0.5emevalrec0.5emsubst0.5eml20.5emin0.5em0.5em0.5em0.5em(match0.5emevalrec0.5emsubst0.5eml10.5emwith0.5em0.5em0.5em0.5em0.5em‘Abs0.5em(s,0.5embody)0.5em->0.5em0.5em0.5em0.5em0.5em0.5emevalrec0.5em[s,0.5eml2']0.5embody0.5em0.5em0.5em0.5em0.5eml1'0.5em->0.5em‘App0.5em(l1',0.5eml2'))0.5em0.5em0.5em‘Abs0.5em(s,0.5eml1)0.5em->0.5em0.5em0.5em0.5emlet0.5ems'0.5em=0.5emgensym0.5em()0.5emin0.5em0.5em0.5em0.5em‘Abs0.5em(s',0.5emevalrec0.5em((s,0.5em‘Var0.5ems')::subst)0.5eml1)let0.5emfreevarslambda0.5emfreevarsrec0.5em:0.5em'a0.5emlambda0.5em->0.5em'b0.5em=0.5emfunction0.5em0.5em0.5em‘Var0.5emv0.5em->0.5em[v]0.5em0.5em0.5em‘App0.5em(l1,0.5eml2)0.5em->0.5emfreevarsrec0.5eml10.5em@0.5emfreevarsrec0.5eml20.5em0.5em0.5em‘Abs0.5em(s,0.5eml1)0.5em->0.5em0.5em0.5em0.5emList.filter0.5em(fun0.5emv0.5em->0.5emv0.5em<>0.5ems)0.5em(freevarsrec0.5eml1)type0.5emlambdat0.5em=0.5emlambdat0.5emlambdalet0.5emrec0.5emeval10.5emsubst0.5eme0.5em:0.5emlambdat0.5em=0.5emevallambda0.5emeval10.5emsubst0.5emelet0.5emrec0.5emfreevars10.5em(e0.5em:0.5emlambdat)0.5em=0.5emfreevarslambda0.5emfreevars10.5emelet0.5emtest10.5em=0.5em(‘App0.5em(‘Abs0.5em("x",0.5em‘Var0.5em"x"),0.5em‘Var0.5em"y")0.5em:>0.5emlambdat)let0.5emetest0.5em=0.5emeval10.5em[]0.5emtest1let0.5emfvtest0.5em=0.5emfreevars10.5emtest1type0.5em'a0.5emexpr0.5em=0.5em0.5em[‘Var0.5emof0.5emstring0.5em0.5em‘Num0.5emof0.5emint0.5em0.5em‘Add0.5emof0.5em'a0.5em\*0.5em'a0.5em0.5em‘Mult0.5emof0.5em'a0.5em\*0.5em'a]let0.5emmapexpr0.5em(f0.5em:0.5em0.5em->0.5em'a)0.5em:0.5em'a0.5emexpr0.5em->0.5em'a0.5em=0.5emfunction0.5em0.5em0.5em#var0.5emas0.5emv0.5em->0.5emv0.5em0.5em0.5em‘Num0.5em0.5emas0.5emn0.5em->0.5emn0.5em0.5em0.5em‘Add0.5em(e1,0.5eme2)0.5em->0.5em‘Add0.5em(f0.5eme1,0.5emf0.5eme2)0.5em0.5em0.5em‘Mult0.5em(e1,0.5eme2)0.5em->0.5em‘Mult0.5em(f0.5eme1,0.5emf0.5eme2)let0.5emevalexpr0.5emevalrec0.5emsubst0.5em(e0.5em:0.5em'a0.5emexpr)0.5em:0.5em'a0.5em=0.5em0.5emmatch0.5emmapexpr0.5em(evalrec0.5emsubst)0.5eme0.5emwith0.5em0.5em0.5em#var0.5emas0.5emv0.5em->0.5em`evalvar0.5emsubst0.5emv`Here 
and elsewhere, we could also 
factor-out0.5em0.5em`0.5em‘`Add0.5em(‘Num0.5emm,0.5em‘Num0.5emn)0.5em->0.5em‘Num0.5em(m0.5em+0.5emn)the 
sub-language of 
variables.0.5em0.5em0.5em‘Mult0.5em(‘Num0.5emm,0.5em‘Num0.5emn)0.5em->0.5em‘Num0.5em(m0.5em\*0.5emn)0.5em0.5em0.5eme0.5em->0.5emelet0.5emfreevarsexpr0.5emfreevarsrec0.5em:0.5em'a0.5emexpr0.5em->0.5em'b0.5em=0.5emfunction0.5em0.5em0.5em‘Var0.5emv0.5em->0.5em[v]0.5em0.5em0.5em‘Num0.5em0.5em->0.5em[]0.5em0.5em0.5em‘Add0.5em(e1,0.5eme2)0.5em0.5em‘Mult0.5em(e1,0.5eme2)0.5em->0.5emfreevarsrec0.5eme10.5em@0.5emfreevarsrec0.5eme2type0.5emexprt0.5em=0.5emexprt0.5emexprlet0.5emrec0.5emeval20.5emsubst0.5eme0.5em:0.5emexprt0.5em=0.5emevalexpr0.5emeval20.5emsubst0.5emelet0.5emrec0.5emfreevars20.5em(e0.5em:0.5emexprt)0.5em=0.5emfreevarsexpr0.5emfreevars20.5emelet0.5emtest20.5em=0.5em(‘Add0.5em(‘Mult0.5em(‘Num0.5em3,0.5em‘Var0.5em"x"),0.5em‘Num0.5em1)0.5em:0.5emexprt)let0.5emetest20.5em=0.5emeval20.5em["x",0.5em‘Num0.5em2]0.5emtest2let0.5emfvtest20.5em=0.5emfreevars20.5emtest2type0.5em'a0.5emlexpr0.5em=0.5em['a0.5emlambda0.5em0.5em'a0.5emexpr]let0.5emevallexpr0.5emevalrec0.5emsubst0.5em:0.5em'a0.5emlexpr0.5em->0.5em'a0.5em=0.5emfunction0.5em0.5em0.5em#lambda0.5emas0.5emx0.5em->0.5emevallambda0.5emevalrec0.5emsubst0.5emx0.5em0.5em0.5em#expr0.5emas0.5emx0.5em->0.5emevalexpr0.5emevalrec0.5emsubst0.5emxlet0.5emfreevarslexpr0.5emfreevarsrec0.5em:0.5em'a0.5emlexpr0.5em->0.5em'b0.5em=0.5emfunction0.5em0.5em0.5em#lambda0.5emas0.5emx0.5em->0.5emfreevarslambda0.5emfreevarsrec0.5emx0.5em0.5em0.5em#expr0.5emas0.5emx0.5em->0.5emfreevarsexpr0.5emfreevarsrec0.5emxtype0.5emlexprt0.5em=0.5emlexprt0.5emlexprlet0.5emrec0.5emeval30.5emsubst0.5eme0.5em:0.5emlexprt0.5em=0.5emevallexpr0.5emeval30.5emsubst0.5emelet0.5emrec0.5emfreevars30.5em(e0.5em:0.5emlexprt)0.5em=0.5emfreevarslexpr0.5emfreevars30.5emelet0.5emtest30.5em=0.5em0.5em(‘App0.5em(‘Abs0.5em("x",0.5em‘Add0.5em(‘Mult0.5em(‘Num0.5em3,0.5em‘Var0.5em"x"),0.5em‘Num0.5em1)),0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em‘Num0.5em2)0.5em:0.5emlexprt)let0.5emetest30.5em=0.5emeval30.5em[]0.5emtest3let0.5emfvtest30.5em=0.5emfreevars30.5emtest3let0.5emeoldtest0.5em=0.5emeval30.5em[]0.5em(test20.5em:>0.5emlexprt)let0.5emfvoldtest0.5em=0.5emfreevars30.5em(test20.5em:>0.5emlexprt)Polymorphic Variants and Recursive Modules

* Using recursive modules, we can clean-up the confusing or cluttering aspects 
  of tying the recursive knots: type variables, recursive call arguments.
* We need *private types*, which for objects and polymorphic variants 
  means *private rows*.
  * We can conceive of open row types, e.g. [> 
    ‘Int0.5emof0.5emint0.5em0.5em‘String0.5emof0.5emstring] as using a *row 
    variable*, e.g. `'a`:

    [‘Int0.5emof0.5emint0.5em0.5em‘String0.5emof0.5emstring0.5em0.5em'a]

    and then of private row types as abstracting the row variable:

    
    type0.5emtrowtype0.5emt0.5em=0.5em[‘Int0.5emof0.5emint0.5em0.5em‘String0.5emof0.5emstring0.5em0.5emtrow]

    But the actual formalization of private row types is more complex.
* Penalty points:
  * We still need to tie the recursive knots for types, for example 
    private0.5em[>0.5em'a0.5emlambda]0.5emas0.5em'a.
  * There can be slight time costs due to the use of functors and dispatch on 
    merging of sub-languages.
* Verdict: a clean solution, best place.


type0.5emvar0.5em=0.5em[‘Var0.5emof0.5emstring]let0.5emevalvar0.5emsubst0.5em(‘Var0.5ems0.5emas0.5emv0.5em:0.5emvar)0.5em=0.5em0.5emtry0.5emList.assoc0.5ems0.5emsubst0.5emwith0.5emNotfound0.5em->0.5emvtype0.5em'a0.5emlambda0.5em=0.5em0.5em[‘Var0.5emof0.5emstring0.5em0.5em‘Abs0.5emof0.5emstring0.5em\*0.5em'a0.5em0.5em‘App0.5emof0.5em'a0.5em\*0.5em'a]module0.5emtype0.5emEval0.5em=sig0.5emtype0.5emexp0.5emval0.5emeval0.5em:0.5em(string0.5em\*0.5emexp)0.5emlist0.5em->0.5emexp0.5em->0.5emexp0.5emendmodule0.5emLF(X0.5em:0.5emEval0.5emwith0.5emtype0.5emexp0.5em=0.5emprivate0.5em[>0.5em'a0.5emlambda]0.5emas0.5em'a)0.5em=struct0.5em0.5emtype0.5emexp0.5em=0.5emX.exp0.5emlambda0.5em0.5emlet0.5emgensym0.5em=0.5em 
   
let0.5emn0.5em=0.5emref0.5em00.5emin0.5emfun0.5em()0.5em->0.5emincr0.5emn;0.5em""0.5em0.5emstringofint0.5em!n0.5em0.5emlet0.5emeval0.5emsubst0.5em:0.5emexp0.5em->0.5emX.exp0.5em=0.5emfunction0.5em0.5em0.5em0.5em0.5em#var0.5emas0.5emv0.5em->0.5emevalvar0.5emsubst0.5emv0.5em0.5em0.5em0.5em0.5em‘App0.5em(l1,0.5eml2)0.5em->0.5em0.5em0.5em0.5em0.5em0.5emlet0.5eml2'0.5em=0.5emX.eval0.5emsubst0.5eml20.5emin0.5em0.5em0.5em0.5em0.5em0.5em(match0.5emX.eval0.5emsubst0.5eml10.5emwith0.5em0.5em0.5em0.5em0.5em0.5em0.5em‘Abs0.5em(s,0.5embody)0.5em->0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5emX.eval0.5em[s,0.5eml2']0.5embody0.5em0.5em0.5em0.5em0.5em0.5em0.5eml1'0.5em->0.5em‘App0.5em(l1',0.5eml2'))0.5em0.5em0.5em0.5em0.5em‘Abs0.5em(s,0.5eml1)0.5em->0.5em0.5em0.5em0.5em0.5em0.5emlet0.5ems'0.5em=0.5emgensym0.5em()0.5emin0.5em0.5em0.5em0.5em0.5em0.5em‘Abs0.5em(s',0.5emX.eval0.5em((s,0.5em‘Var0.5ems')::subst)0.5eml1)endmodule0.5emrec0.5emLambda0.5em:0.5em(Eval0.5emwith0.5emtype0.5emexp0.5em=0.5emLambda.exp0.5emlambda)0.5em=0.5em0.5emLF(Lambda)module0.5emtype0.5emFreeVars0.5em=sig0.5emtype0.5emexp0.5emval0.5emfreevars0.5em:0.5emexp0.5em->0.5emstring0.5emlist0.5emendmodule0.5emLFVF(X0.5em:0.5emFreeVars0.5emwith0.5emtype0.5emexp0.5em=0.5emprivate0.5em[>0.5em'a0.5emlambda]0.5emas0.5em'a)0.5em=struct0.5em0.5emtype0.5emexp0.5em=0.5emX.exp0.5emlambda0.5em0.5emlet0.5emfreevars0.5em:0.5emexp0.5em->0.5em'b0.5em=0.5emfunction0.5em0.5em0.5em0.5em0.5em‘Var0.5emv0.5em->0.5em[v]0.5em0.5em0.5em0.5em0.5em‘App0.5em(l1,0.5eml2)0.5em->0.5emX.freevars0.5eml10.5em@0.5emX.freevars0.5eml20.5em0.5em0.5em0.5em0.5em‘Abs0.5em(s,0.5eml1)0.5em->0.5em0.5em0.5em0.5em0.5em0.5emList.filter0.5em(fun0.5emv0.5em->0.5emv0.5em<>0.5ems)0.5em(X.freevars0.5eml1)endmodule0.5emrec0.5emLambdaFV0.5em:0.5em(FreeVars0.5emwith0.5emtype0.5emexp0.5em=0.5emLambdaFV.exp0.5emlambda)0.5em=0.5em0.5emLFVF(LambdaFV)let0.5emtest10.5em=0.5em(‘App0.5em(‘Abs0.5em("x",0.5em‘Var0.5em"x"),0.5em‘Var0.5em"y")0.5em:0.5emLambda.exp)let0.5emetest0.5em=0.5emLambda.eval0.5em[]0.5emtest1let0.5emfvtest0.5em=0.5emLambdaFV.freevars0.5emtest1type0.5em'a0.5emexpr0.5em=0.5em0.5em[‘Var0.5emof0.5emstring0.5em0.5em‘Num0.5emof0.5emint0.5em0.5em‘Add0.5emof0.5em'a0.5em\*0.5em'a0.5em0.5em‘Mult0.5emof0.5em'a0.5em\*0.5em'a]module0.5emtype0.5emOperations0.5em=sig0.5eminclude0.5emEval0.5eminclude0.5emFreeVars0.5emwith0.5emtype0.5emexp0.5em:=0.5emexp0.5emendmodule0.5emEF(X0.5em:0.5emOperations0.5emwith0.5emtype0.5emexp0.5em=0.5emprivate0.5em[>0.5em'a0.5emexpr]0.5emas0.5em'a)0.5em=struct0.5em0.5emtype0.5emexp0.5em=0.5emX.exp0.5emexpr0.5em0.5emlet0.5emmapexpr0.5emf0.5em=0.5emfunction0.5em0.5em0.5em0.5em0.5em#var0.5emas0.5emv0.5em->0.5emv0.5em0.5em0.5em0.5em0.5em‘Num0.5em0.5emas0.5emn0.5em->0.5emn0.5em0.5em0.5em0.5em0.5em‘Add0.5em(e1,0.5eme2)0.5em->0.5em‘Add0.5em(f0.5eme1,0.5emf0.5eme2)0.5em0.5em0.5em0.5em0.5em‘Mult0.5em(e1,0.5eme2)0.5em->0.5em‘Mult0.5em(f0.5eme1,0.5emf0.5eme2)0.5em0.5emlet0.5emeval0.5emsubst0.5em(e0.5em:0.5emexp)0.5em:0.5emX.exp0.5em=0.5em0.5em0.5em0.5emmatch0.5emmapexpr0.5em(X.eval0.5emsubst)0.5eme0.5emwith0.5em0.5em0.5em0.5em0.5em#var0.5emas0.5emv0.5em->0.5emevalvar0.5emsubst0.5emv0.5em0.5em0.5em0.5em0.5em‘Add0.5em(‘Num0.5emm,0.5em‘Num0.5emn)0.5em->0.5em‘Num0.5em(m0.5em+0.5emn)0.5em0.5em0.5em0.5em0.5em‘Mult0.5em(‘Num0.5emm,0.5em‘Num0.5emn)0.5em->0.5em‘Num0.5em(m0.5em\*0.5emn)0.5em0.5em0.5em0.5em0.5eme0.5em->0.5eme0.5em0.5emlet0.5emfreevars0.5em:0.5emexp0.5em->0.5em'b0.5em=0.5emfunction0.5em0.5em0.5em0.5em0.5em‘Var0.5emv0.5em->0.5em[v]0.5em0.5em0.5em0.5em0.5em‘Num0.5em0.5em->0.5em[]0.5em0.5em0.5em0.5em0.5em‘Add0.5em(e1,0.5eme2)0.5em0.5em‘Mult0.5em(e1,0.5eme2)0.5em->0.5emX.freevars0.5eme10.5em@0.5emX.freevars0.5eme2endmodule0.5emrec0.5emExpr0.5em:0.5em(Operations0.5emwith0.5emtype0.5emexp0.5em=0.5emExpr.exp0.5emexpr)0.5em=0.5em0.5emEF(Expr)let0.5emtest20.5em=0.5em(‘Add0.5em(‘Mult0.5em(‘Num0.5em3,0.5em‘Var0.5em"x"),0.5em‘Num0.5em1)0.5em:0.5emExpr.exp)let0.5emetest20.5em=0.5emExpr.eval0.5em["x",0.5em‘Num0.5em2]0.5emtest2let0.5emfvstest20.5em=0.5emExpr.freevars0.5emtest2type0.5em'a0.5emlexpr0.5em=0.5em['a0.5emlambda0.5em0.5em'a0.5emexpr]module0.5emLEF(X0.5em:0.5emOperations0.5emwith0.5emtype0.5emexp0.5em=0.5emprivate0.5em[>0.5em'a0.5emlexpr]0.5emas0.5em'a)0.5em=struct0.5em0.5emtype0.5emexp0.5em=0.5emX.exp0.5emlexpr0.5em0.5emmodule0.5emLambdaX0.5em=0.5emLF(X)0.5em0.5emmodule0.5emLambdaFVX0.5em=0.5emLFVF(X)0.5em0.5emmodule0.5emExprX0.5em=0.5emEF(X)0.5em0.5emlet0.5emeval0.5emsubst0.5em:0.5emexp0.5em->0.5emX.exp0.5em=0.5emfunction0.5em0.5em0.5em0.5em0.5em#LambdaX.exp0.5emas0.5emx0.5em->0.5emLambdaX.eval0.5emsubst0.5emx0.5em0.5em0.5em0.5em0.5em#ExprX.exp0.5emas0.5emx0.5em->0.5emExprX.eval0.5emsubst0.5emx0.5em0.5emlet0.5emfreevars0.5em:0.5emexp0.5em->0.5em'b0.5em=0.5emfunction0.5em0.5em0.5em0.5em0.5em#lambda0.5emas0.5emx0.5em->0.5emLambdaFVX.freevars0.5emxEither 
of #lambda or #LambdaX.exp is 
fine.`0.5em0.5em0.5em0.5em`0.5em#expr0.5emas0.5emx0.5em->0.5emExprX.freevars0.5emxEither 
of #expr or #ExprX.exp is 
fine.endmodule0.5emrec0.5emLExpr0.5em:0.5em(Operations0.5emwith0.5emtype0.5emexp0.5em=0.5emLExpr.exp0.5emlexpr)0.5em=0.5em0.5emLEF(LExpr)let0.5emtest30.5em=0.5em0.5em(‘App0.5em(‘Abs0.5em("x",0.5em‘Add0.5em(‘Mult0.5em(‘Num0.5em3,0.5em‘Var0.5em"x"),0.5em‘Num0.5em1)),0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em‘Num0.5em2)0.5em:0.5emLExpr.exp)let0.5emetest30.5em=0.5emLExpr.eval0.5em[]0.5emtest3let0.5emfvtest30.5em=0.5emLExpr.freevars0.5emtest3let0.5emeoldtest0.5em=0.5emLExpr.eval0.5em[]0.5em(test20.5em:>0.5emLExpr.exp)let0.5emfvoldtest0.5em=0.5emLExpr.freevars0.5em(test20.5em:>0.5emLExpr.exp)Digression: Parser Combinators

* We have done parsing using external languages OCamlLex and Menhir, now we 
  will look at parsers written directly in OCaml.
* Language *combinators* are ways defining languages by composing definitions 
  of smaller languages. For example, the combinators of the *Extended 
  Backus-Naur Form* notation are:
  * concatenation: $S = A, B$ stands for $S = \lbrace a b|a \in A, b \in b 
    \rbrace$,
  * alternation: $S = A|B$ stands for $S = \lbrace a|a \in A \vee a \in B 
    \rbrace$,
  * option: $S = [A]$ stands for $S = \lbrace \epsilon \rbrace \cup A$, where 
    $\epsilon$ is an empty string,
  * repetition: $S = \lbrace A \rbrace$ stands for $S = \lbrace \epsilon 
    \rbrace \cup \lbrace a s|a \in A, s \in S \rbrace$,
  * terminal string: $S ='' a''$ stands for $S = \lbrace a \rbrace$.
* Parsers implemented directly in a functional programming paradigm are 
  functions from character streams to the parsed values. Algorithmically they 
  are *recursive descent parsers*.
* *Parser combinators* approach builds parsers as *monad plus* values:
  * Bind: `val (>>=) : 'a parser -> ('a -> 'b parser) -> 
    'b parser`
    * `p >>= f` is a parser that first parses `p`, and makes the 
      result available for parsing `f`.
  * Return: `val return : 'a -> 'a parser`
    * `return x` parses an empty string, symbolically $S = \lbrace \epsilon 
      \rbrace$, and returns `x`.
  * MZero: `val fail : 'a parser`
    * `fail` fails to parse anything, symbolically $S = \varnothing = \lbrace 
      \rbrace$.
  * MPlus: either `val <|> : 'a parser -> 'a parser -> 'a 
    parser`,

    or `val <|> : 'a parser -> 'b parser -> ('a, 'b) choice 
    parser`
    * `p <|> q` tries `p`, and if `p` succeeds, its result is 
      returned, otherwise the parser `q` is used.

  The only non-monad-plus operation that has to be built into the monad is 
  some way to consume a single character from the input stream, for example:
  * `val satisfy : (char -> bool) -> char parser`
    * `satisfy (fun c -> c = 'a')` consumes the character “a” from the 
      input stream and returns it; if the input stream starts with a different 
      character, this parser fails.
* Ordinary monadic recursive descent parsers **do not 
  allow** *left-recursion*: if a cycle of calls not consuming any character 
  can be entered when a parse failure should occur, the cycle will keep 
  repeating.
  * For example, if we define numbers $N := D | N D$, where $D$ stands for 
    digits, then a stack of uses of the rule $N \rightarrow N D$ will build up 
    when the next character is not a digit.
  * On the other hand, rules can share common prefixes.Parser Combinators: Implementation

* The parser monad is actually a composition of two monads:
  * the state monad for storing the stream of characters that remain to be 
    parsed,
  * the backtracking monad for handling parse failures and ambiguities.

  Alternatively, one can split the state monad into a reader monad with the 
  parsed string, and a state monad with the parsing position.
* Recall Lecture 8, especially slides 54-63.
* On my new OPAM installation of OCaml, I run the parsing example with:

  `ocamlbuild Plugin1.cmxs -pp "camlp4o 
  /home/lukstafi/.opam/4.02.1/lib/monad-custom/pa_monad.cmo"`

  `ocamlbuild Plugin2.cmxs -pp "camlp4o 
  /home/lukstafi/.opam/4.02.1/lib/monad-custom/pa_monad.cmo"`

  `ocamlbuild PluginRun.native -lib dynlink -pp "camlp4o 
  ~/.opam/4.02.1/lib/monad-custom/pa_monad.cmo" -- "(3*(6+1))" 
  _build/Plugin1.cmxs _build/Plugin2.cmxs`
* We experiment with a different approach to *monad-plus*. The merits of this 
  approach (or lack thereof) is left as an exercise. *lazy-monad-plus*:

  
  val0.5emmplus0.5em:0.5em'a0.5emmonad ->0.5em'a0.5emmonad0.5emLazy.t0.5em->0.5em'a0.5emmonad

Parser Combinators: Implementation of lazy-monad-plus

* Excerpts from `Monad.ml`. First an operation from MonadPlusOps.


0.5em0.5emlet0.5emmsummap0.5emf0.5eml0.5em=0.5em0.5em0.5em0.5emList.`foldleft`Folding 
left reversers the apparent order of 
composition,`0.5em0.5em0.5em0.5em0.5em0.5em`(fun0.5emacc0.5ema0.5em->0.5emmplus0.5emacc0.5em(lazy0.5em(f0.5ema)))0.5emmzero0.5emlorder 
from `l` is preserved.

* The implementation of the lazy-monad-plus.

type0.5em'a0.5emllist0.5em=0.5emLNil0.5em0.5emLCons0.5emof0.5em'a0.5em\*0.5em'a0.5emllist0.5emLazy.tlet0.5emrec0.5emltake0.5emn0.5em=0.5emfunction0.5em0.5emLCons0.5em(a,0.5eml)0.5emwhen0.5emn0.5em>0.5em10.5em->0.5ema::(ltake0.5em(n-1)0.5em(Lazy.force0.5eml))0.5em0.5emLCons0.5em(a,0.5eml)0.5emwhen0.5emn0.5em=0.5em10.5em->0.5em[a]Avoid forcing the tail if not needed.0.5em->0.5em[]let0.5emrec0.5emlappend0.5eml10.5eml20.5em=0.5em0.5emmatch0.5eml10.5emwith0.5emLNil0.5em->0.5emLazy.`force0.5eml2`0.5em0.5em0.5emLCons0.5em(hd,0.5emtl)0.5em-> LCons0.5em(hd,0.5emlazy0.5em(lappend0.5em(Lazy.force0.5emtl)0.5eml2))let0.5emrec0.5emlconcatmap0.5emf0.5em=0.5emfunction0.5em0.5em0.5emLNil0.5em->0.5emLNil0.5em0.5em0.5emLCons0.5em(a,0.5eml)0.5em->0.5emlappend0.5em(f0.5ema)0.5em(lazy0.5em(lconcatmap0.5emf0.5em(Lazy.force0.5eml)))module0.5emLListM0.5em=0.5emMonadPlus0.5em(struct0.5em0.5emtype0.5em'a0.5emt0.5em=0.5em'a0.5emllist0.5em0.5emlet0.5embind0.5ema0.5emb0.5em=0.5emlconcatmap0.5emb0.5ema0.5em0.5emlet0.5emreturn0.5ema0.5em=0.5emLCons0.5em(a,0.5emlazy0.5emLNil)0.5em0.5emlet0.5emmzero0.5em=0.5emLNil0.5em0.5emlet0.5emmplus0.5em=0.5emlappendend)Parser Combinators: the *Parsec* Monad

* File `Parsec.ml`:

open0.5emMonadmodule0.5emtype0.5emPARSE0.5em=0.5emsig0.5em0.5emtype0.5em`'a0.5embacktrackingmonad`Name for the underlying monad-plus.0.5em0.5emtype0.5em'a0.5emparsingstate0.5em=0.5emint0.5em->0.5em('a0.5em\*0.5emint)0.5em`backtrackingmonad`Processing state -- position.0.5em0.5emtype0.5em'a0.5emt0.5em=0.5emstring0.5em->0.5em`'a0.5emparsingstate`Reader for the parsed text.0.5em0.5eminclude0.5emMONADPLUSOPS0.5em0.5emval0.5em(<>)0.5em:0.5em'a0.5emmonad0.5em->0.5em'a0.5emmonad0.5emLazy.t0.5em->0.5em`'a0.5emmonad`A synonym for `mplus`.0.5em0.5emval0.5emrun0.5em:0.5em'a0.5emmonad0.5em->0.5em'a0.5emt0.5em0.5emval0.5emrunT0.5em:0.5em'a0.5emmonad0.5em->0.5emstring0.5em->0.5emint0.5em->0.5em'a0.5embacktrackingmonad0.5em0.5emval0.5emsatisfy0.5em:0.5em(char0.5em->0.5embool)0.5em->0.5em`char0.5emmonad`Consume a character of the specified class.0.5em0.5emval0.5emendoftext0.5em:0.5emunit0.5emmonadCheck for end of the processed text.endmodule0.5emParseT0.5em(MP0.5em:0.5emMONADPLUSOPS)0.5em:0.5em0.5emPARSE0.5emwith0.5emtype0.5em'a0.5embacktrackingmonad0.5em:=0.5em'a0.5emMP.monad0.5em=struct0.5em0.5emtype0.5em'a0.5embacktrackingmonad0.5em=0.5em'a0.5emMP.monad0.5em0.5emtype0.5em'a0.5emparsingstate0.5em=0.5emint0.5em->0.5em('a0.5em\*0.5emint)0.5emMP.monad0.5em0.5emmodule0.5emM0.5em=0.5emstruct0.5em0.5em0.5em0.5emtype0.5em'a0.5emt0.5em=0.5emstring0.5em->0.5em'a0.5emparsingstate0.5em0.5em0.5em0.5em0.5emlet0.5emreturn0.5ema0.5em=0.5emfun0.5ems0.5emp0.5em->0.5emMP.return0.5em(a,0.5emp)0.5em0.5em0.5em0.5emlet0.5embind0.5emm0.5emb0.5em=0.5emfun0.5ems0.5emp0.5em->0.5em0.5em0.5em0.5em0.5em0.5emMP.bind0.5em(m0.5ems0.5emp)0.5em(fun0.5em(a,0.5emp')0.5em->0.5emb0.5ema0.5ems0.5emp')0.5em0.5em0.5em0.5emlet0.5emmzero0.5em=0.5emfun0.5em0.5em\_0.5em->0.5emMP.mzero0.5em0.5em0.5em0.5emlet0.5emmplus0.5emma0.5emmb0.5em=0.5emfun0.5ems0.5emp0.5em->0.5em0.5em0.5em0.5em0.5em0.5emMP.mplus0.5em(ma0.5ems0.5emp)0.5em(lazy0.5em(Lazy.force0.5emmb0.5ems0.5emp))0.5em0.5emend0.5em0.5eminclude0.5emM0.5em0.5eminclude0.5emMonadPlusOps(M)0.5em0.5emlet0.5em(<>)0.5emma0.5emmb0.5em=0.5emmplus0.5emma0.5emmb0.5em0.5emlet0.5emrunT0.5emm0.5ems0.5emp0.5em=0.5emMP.lift0.5emfst0.5em(m0.5ems0.5emp)0.5em0.5emlet0.5emsatisfy0.5emf0.5ems0.5emp0.5em=0.5em0.5em0.5em0.5emif0.5emp0.5em<0.5emString.length0.5ems0.5em&&0.5emf0.5ems.[p]Consuming a character means accessing it0.5em0.5em0.5em0.5emthen0.5emMP.return0.5em(s.[p],0.5emp0.5em+0.5em1)0.5emelse0.5emMP.`mzero`and advancing the parsing position.0.5em0.5emlet0.5emendoftext0.5ems0.5emp0.5em=0.5em0.5em0.5em0.5emif0.5emp0.5em>=0.5emString.length0.5ems0.5emthen0.5emMP.return0.5em((),0.5emp)0.5emelse0.5emMP.mzeroendmodule0.5emtype0.5emPARSEOPS0.5em=0.5emsig0.5em0.5eminclude0.5emPARSE0.5em0.5emval0.5emmany0.5em:0.5em'a0.5emmonad0.5em->0.5em'a0.5emlist0.5emmonad0.5em0.5emval0.5emopt0.5em:0.5em'a0.5emmonad0.5em->0.5em'a0.5emoption0.5emmonad0.5em0.5emval0.5em(?)0.5em:0.5em'a0.5emmonad0.5em->0.5em'a0.5emoption0.5emmonad0.5em0.5emval0.5emseq0.5em:0.5em'a0.5emmonad0.5em->0.5em'b0.5emmonad0.5emLazy.t0.5em->0.5em('a0.5em\*0.5em'b)0.5em`monad`Exercise: why laziness here?0.5em0.5emval0.5em(<\*>)0.5em:0.5em'a0.5emmonad0.5em->0.5em'b0.5emmonad0.5emLazy.t0.5em->0.5em('a0.5em\*0.5em'b)0.5em`monad`Synonym for `seq`.0.5em0.5emval0.5emlowercase0.5em:0.5emchar0.5emmonad0.5em0.5emval0.5emuppercase0.5em:0.5emchar0.5emmonad0.5em0.5emval0.5emdigit0.5em:0.5emchar0.5emmonad0.5em0.5emval0.5emalpha0.5em:0.5emchar0.5emmonad0.5em0.5emval0.5emalphanum0.5em:0.5emchar0.5emmonad0.5em0.5emval0.5emliteral0.5em:0.5emstring0.5em->0.5emunit0.5em`monad`Consume characters of the given string.0.5em0.5emval0.5em(<<>)0.5em:0.5emstring0.5em->0.5em'a0.5emmonad0.5em->0.5em`'a0.5emmonad`Prefix and postfix keywords.0.5em0.5emval0.5em(<>>)0.5em:0.5em'a0.5emmonad0.5em->0.5emstring0.5em->0.5em'a0.5emmonadendmodule0.5emParseOps0.5em(R0.5em:0.5emMONADPLUSOPS)0.5em0.5em(P0.5em:0.5emPARSE0.5emwith0.5emtype0.5em'a0.5embacktrackingmonad0.5em:=0.5em'a0.5emR.monad)0.5em:0.5em0.5emPARSEOPS0.5emwith0.5emtype0.5em'a0.5embacktrackingmonad0.5em:=0.5em'a0.5emR.monad0.5em=struct0.5em0.5eminclude0.5emP0.5em0.5emlet0.5emrec0.5emmany0.5emp0.5em=0.5em0.5em0.5em0.5em(perform0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5emr0.5em<--0.5emp;0.5emrs0.5em<--0.5emmany0.5emp;0.5emreturn0.5em(r::rs))0.5em0.5em0.5em0.5em++0.5emlazy0.5em(return0.5em[])0.5em0.5emlet0.5emopt0.5emp0.5em=0.5em(p0.5em>>=0.5em(fun0.5emx0.5em->0.5emreturn0.5em(Some0.5emx)))0.5em++0.5emlazy0.5em(return0.5emNone)0.5em0.5emlet0.5em(?)0.5emp0.5em=0.5emopt0.5emp0.5em0.5emlet0.5emseq0.5emp0.5emq0.5em=0.5emperform0.5em0.5em0.5em0.5em0.5em0.5emx0.5em<--0.5emp;0.5emy0.5em<--0.5emLazy.force0.5emq;0.5emreturn0.5em(x,0.5emy)0.5em0.5emlet0.5em(<\*>)0.5emp0.5emq0.5em=0.5emseq0.5emp0.5emq0.5em0.5emlet0.5emlowercase0.5em=0.5emsatisfy0.5em(fun0.5emc0.5em->0.5emc0.5em>=0.5em'a'0.5em&&0.5emc0.5em<=0.5em'z')0.5em0.5emlet0.5emuppercase0.5em=0.5emsatisfy0.5em(fun0.5emc0.5em->0.5emc0.5em>=0.5em'A'0.5em&&0.5emc0.5em<=0.5em'Z')0.5em0.5emlet0.5emdigit0.5em=0.5emsatisfy0.5em(fun0.5emc0.5em->0.5emc0.5em>=0.5em'0'0.5em&&0.5emc0.5em<=0.5em'9')0.5em0.5emlet0.5emalpha0.5em=0.5emlowercase0.5em++0.5emlazy0.5emuppercase0.5em0.5emlet0.5emalphanum0.5em=0.5emalpha0.5em++0.5emlazy0.5emdigit0.5em0.5emlet0.5emliteral0.5eml0.5em=0.5em0.5em0.5em0.5emlet0.5emrec0.5emloop0.5empos0.5em=0.5em0.5em0.5em0.5em0.5em0.5emif0.5empos0.5em=0.5emString.length0.5eml0.5emthen0.5emreturn0.5em()0.5em0.5em0.5em0.5em0.5em0.5emelse0.5emsatisfy0.5em(fun0.5emc0.5em->0.5emc0.5em=0.5eml.[pos])0.5em>>-0.5emloop0.5em(pos0.5em+0.5em1)0.5emin0.5em0.5em0.5em0.5emloop0.5em00.5em0.5emlet0.5em(<<>)0.5embra0.5emp0.5em=0.5emliteral0.5embra0.5em>>-0.5emp0.5em0.5emlet0.5em(<>>)0.5emp0.5emket0.5em=0.5emp0.5em>>=0.5em(fun0.5emx0.5em->0.5emliteral0.5emket0.5em>>-0.5emreturn0.5emx)endParser Combinators: Tying the Recursive Knot

* File `PluginBase.ml`:


module0.5emParseM0.5em=0.5em0.5emParsec.ParseOps0.5em(Monad.LListM)0.5em(Parsec.ParseT0.5em(Monad.LListM))open0.5emParseMlet0.5emgrammarrules0.5em:0.5em(int0.5emmonad0.5em->0.5emint0.5emmonad)0.5emlist0.5emref0.5em=0.5emref0.5em[]let0.5emgetlanguage0.5em()0.5em:0.5emint0.5emmonad0.5em=0.5em0.5emlet0.5emrec0.5emresult0.5em=0.5em0.5em0.5em0.5emlazy0.5em0.5em0.5em0.5em0.5em0.5em(List.foldleft0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em(fun0.5emacc0.5emlang0.5em->0.5emacc0.5em<>0.5emlazy0.5em(lang0.5em(Lazy.force0.5emresult)))0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5emmzero0.5em!grammarrules)0.5eminEnsure 
we parse the whole 
text.0.5em0.5emperform0.5emr0.5em<--0.5emLazy.force0.5emresult;0.5emendoftext;0.5emreturn0.5emrParser Combinators: Dynamic Code Loading

* File `PluginRun.ml`:

let0.5emloadplug0.5emfname0.5em:0.5emunit0.5em=0.5em0.5emlet0.5emfname0.5em=0.5emDynlink.adaptfilename0.5emfname0.5emin0.5em0.5emif0.5emSys.fileexists0.5emfname0.5emthen0.5em0.5em0.5em0.5emtry0.5emDynlink.loadfile0.5emfname0.5em0.5em0.5em0.5emwith0.5em0.5em0.5em0.5em0.5em0.5em(Dynlink.Error0.5emerr)0.5emas0.5eme0.5em->0.5em0.5em0.5em0.5em0.5em0.5emPrintf.printf0.5em"\nERROR0.5emloading0.5emplugin:0.5em%s\n%!"0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em(Dynlink.errormessage0.5emerr);0.5em0.5em0.5em0.5em0.5em0.5emraise0.5eme0.5em0.5em0.5em0.5em0.5eme0.5em->0.5emPrintf.printf0.5em"\nUnknow0.5emerror0.5emwhile0.5emloading0.5emplugin\n%!"0.5em0.5emelse0.5em(0.5em0.5em0.5em0.5emPrintf.printf0.5em"\nPlugin0.5emfile0.5em%s0.5emdoes0.5emnot0.5emexist\n%!"0.5emfname;0.5em0.5em0.5em0.5emexit0.5em(-1))let0.5em()0.5em=0.5em0.5emfor0.5emi0.5em=0.5em20.5emto0.5emArray.length0.5emSys.argv0.5em-0.5em10.5emdo0.5em0.5em0.5em0.5emloadplug0.5emSys.argv.(i)0.5emdone;0.5em0.5emlet0.5emlang0.5em=0.5emPluginBase.getlanguage0.5em()0.5emin0.5em0.5emlet0.5emresult0.5em=0.5em0.5em0.5em0.5emMonad.LListM.run0.5em0.5em0.5em0.5em0.5em0.5em(PluginBase.ParseM.runT0.5emlang0.5emSys.argv.(1)0.5em0)0.5emin0.5em0.5emmatch0.5emMonad.ltake0.5em10.5emresult0.5emwith0.5em0.5em0.5em[]0.5em->0.5emPrintf.printf0.5em"\nParse0.5emerror\n%!"0.5em0.5em0.5emr::0.5em->0.5emPrintf.printf0.5em"\nResult:0.5em%d\n%!"0.5emrParser Combinators: Toy Example

* File `Plugin1.ml`:

open0.5emPluginBase.ParseMlet0.5emdigitofchar0.5emd0.5em=0.5emintofchar0.5emd0.5em-0.5emintofchar0.5em'0'let0.5emnumber=0.5em0.5emlet0.5emrec0.5emnum0.5em=Numbers: $N := D N | D$ where $D$ is digits.0.5em0.5em0.5em0.5emlazy0.5em(0.5em0.5em(perform0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5emd0.5em<--0.5emdigit;0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em(n,0.5emb)0.5em<--0.5emLazy.force0.5emnum;0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5em0.5emreturn0.5em(digitofchar0.5emd0.5em\*0.5emb0.5em+0.5emn,0.5emb0.5em\*0.5em10))0.5em0.5em0.5em0.5em0.5em0.5em<>0.5emlazy0.5em(digit0.5em>>=0.5em(fun0.5emd0.5em->0.5emreturn0.5em(digitofchar0.5emd,0.5em10))))0.5emin0.5em0.5emLazy.force0.5emnum0.5em>>0.5emfstlet0.5emaddition0.5emlang0.5em=Addition rule: $S \rightarrow (S + S)$.0.5em0.5emperformRequiring a parenthesis ( turns the rule into non-left-recursive.0.5em0.5em0.5em0.5emliteral0.5em"(";0.5emn10.5em<--0.5emlang;0.5emliteral0.5em"+";0.5emn20.5em<--0.5emlang;0.5emliteral0.5em")";0.5em0.5em0.5em0.5emreturn0.5em(n10.5em+0.5emn2)let0.5em()0.5em= PluginBase.(grammarrules0.5em:=0.5emnumber0.5em::0.5emaddition0.5em::0.5em!grammarrules)

* File `Plugin2.ml`:

open0.5emPluginBase.ParseMlet0.5emmultiplication0.5emlang0.5em=0.5em0.5emperformMultiplication rule: $S \rightarrow (S \ast S)$.0.5em0.5em0.5em0.5emliteral0.5em"(";0.5emn10.5em<--0.5emlang;0.5emliteral0.5em"\*";0.5emn20.5em<--0.5emlang;0.5emliteral0.5em")";0.5em0.5em0.5em0.5emreturn0.5em(n10.5em\*0.5emn2)let0.5em()0.5em= PluginBase.(grammarrules0.5em:=0.5emmultiplication0.5em::0.5em!grammarrules)
