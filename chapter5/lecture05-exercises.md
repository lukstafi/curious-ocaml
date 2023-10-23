Functional Programming

Type Inference

Abstract Data Types

**Exercise 1:** Derive the equations and solve them to find the type for:

*let cadr l = List.hd (List.tl l) in cadr (1::2::[]), cadr (true::false::[])*

*in environment $\Gamma = \left\lbrace
\text{{\hlkwc{List}}{\hlopt{.}}{\hlstd{hd}}} : \forall \alpha . \alpha
\operatorname{list} \rightarrow \alpha ;
\text{{\hlkwc{List}}{\hlopt{.}}{\hlstd{tl}}} : \forall \alpha . \alpha
\operatorname{list} \rightarrow \alpha \operatorname{list} \right\rbrace$. You
can take “shortcuts” if it is too many equations to write down.*

**Exercise 2:** *Terms* $t\_{1}, t\_{2}, \ldots \in T (\Sigma, X)$ are built 
out of variables $x, y, \ldots \in X$ and function symbols $f, g, \ldots \in 
\Sigma$ the way you build values out of functions:

* $X \subset T (\Sigma, X)$ *– variables are terms; usually an infinite set,*
* *for terms* $t\_{1}, \ldots, t\_{n} \in T (\Sigma, X)$ *and a function
  symbol* $f \in \Sigma \_{n}$ *of arity* $n$,$f (t\_{1}, \ldots, t\_{n}) \in
  T (\Sigma, X)$ *– bigger terms arise from applying function symbols to
  smaller terms;* $\Sigma = \dot{\cup}\_{n} \Sigma \_{n}$ *is called a
  signature.*

*In OCaml, we can define terms as: type term = V of string | T of string \*
term list5mm, where for example V("x") is a variable $x$ and T("f", [V("x");
V("y")]) is the term $f (x, y)$.*

*By *substitutions* $\sigma, \rho, \ldots$ we mean finite sets of variable,
term pairs which we can write as $\lbrace x\_{1} \mapsto t\_{1}, \ldots,
x\_{k} \mapsto t\_{k} \rbrace$ or $[x\_{1} := t\_{1} ; \ldots ; x\_{k} :=
t\_{k}]$, but also functions from terms to terms $\sigma : T (\Sigma, X)
\rightarrow T (\Sigma, X)$ related to the pairs as follows: if $\sigma =
\lbrace x\_{1} \mapsto t\_{1}, \ldots, x\_{k} \mapsto t\_{k} \rbrace$, then*

* $\sigma (x\_{i}) = t\_{i}$ *for* $x\_{i} \in \lbrace x\_{1}, \ldots, x\_{k}
  \rbrace$,
* $\sigma (x) = x$ *for* $x \in X\backslash \lbrace x\_{1}, \ldots, x\_{k}
  \rbrace$,
* $\sigma (f (t\_{1}, \ldots, t\_{n})) = f (\sigma (t\_{1}), \ldots, \sigma
  (t\_{n}))$.

*In OCaml, we can define substitutions $\sigma$ as: type subst = (string \*
term) list, together with a function apply : subst -> term -> term
which computes $\sigma (\cdot)$.*

*We say that a substitution $\sigma$ is *more general* than all substitutions
$\rho \circ \sigma$, where $(\rho \circ \sigma) (x) = \rho (\sigma (x))$. In
type inference, we are interested in most general solutions: the less general
type judgement $\text{{\hlkwc{List}}{\hlopt{.}}{\hlstd{hd}}} :
\operatorname{int}\operatorname{list} \rightarrow \operatorname{int}$,
although valid, is less useful than
$\text{{\hlkwc{List}}{\hlopt{.}}{\hlstd{hd}}} : \forall \alpha . \alpha
\operatorname{list} \rightarrow \alpha$ because it limits the usage of
List.hd.*

*A *unification problem* is a finite set of equations $S = \lbrace s\_{1} =^?
t\_{1}, \ldots, s\_{n} =^? t\_{n} \rbrace$ which we can also write as $s\_{1}
\dot{=} t\_{1} \wedge \ldots \wedge s\_{n} \dot{=} t\_{n}$. A solution,
or *unifier* of $S$, is a substitution $\sigma$ such that $\sigma (s\_{i}) =
\sigma (t\_{i})$ for $i = 1, \ldots, n$. A *most general unifier*, for
short *MGU*, is a most general such substitution.*

*A substitution is *idempotent* when $\sigma = \sigma \circ \sigma$. If
$\sigma = \lbrace x\_{1} \mapsto t\_{1}, \ldots, x\_{k} \mapsto t\_{k}
\rbrace$, then $\sigma$ is idempotent exactly when no $t\_{i}$ contains any of
the variables $\lbrace x\_{1}, \ldots, x\_{n} \rbrace$; i.e. $\lbrace x\_{1},
\ldots, x\_{n} \rbrace \cap \operatorname{Vars} (t\_{1}, \ldots, t\_{n}) =
\varnothing$.*

1. *Implement an algorithm that, given a set of equations represented as a
   list of pairs of terms, computes an idempotent most general unifier of the
   equations.*
1. *\* (Ex. 4.22 in* *Franz Baader and Tobias Nipkov “Term Rewriting and All
   That”**, p. 82.) Modify the implementation of unification to achieve linear
   space complexity by working with what could be called iterated
   substitutions. For example, the solution to* $\lbrace x =^? f (y), y =^? g
   (z), z =^? a \rbrace$ *should be represented as variable, term pairs* $(x,
   f (y)), (y, g (z)), (z, a)$*. (Hint: iterated substitutions should be
   unfolded lazily, i.e. only so far that either a non-variable term or the
   end of the instantiation chain is found.)*

**Exercise 3:**

1. *What does it mean that an implementation has junk (as an algebraic
   structure for a given signature)? Is it bad?*
1. *Define a monomorphic algebraic specification (other than, but similar to,*
   $\operatorname{nat}\_{p}$ *or* $\operatorname{string}\_{p}$*, some useful
   data type).*
1. *Discuss an example of a (monomorphic) algebraic specification where it
   would be useful to drop some axioms (giving up monomorphicity) to allow
   more efficient implementations.*

**Exercise 4:**

1. *Does the example* *ListMap* *meet the requirements of the algebraic
   specification for maps? Hint: here is the definition
   of* *List*.*removeassoc*;`*compare a x*` *equals* *0* *if and only if*
   `*a*`=`*x*`.

   *let rec removeassoc x = function  | [] -> []  | (a, b as pair) ::
   l ->      if compare a x = 0 then l else pair :: removeassoc x l*
1. *Trick question: what is the computational complexity
   of* *ListMap* *or* *TrivialMap*?
1. *\* The implementation* *MyListMap* *is inefficient: it performs a lot of
   copying and is not tail-recursive. Optimize it (without changing the type
   definition).*
1. *Add (and specify)* $\operatorname{isEmpty}: (\alpha, \beta)
   \operatorname{map} \rightarrow \operatorname{bool}$ *to the example
   algebraic specification of maps without increasing the burden on its
   implementations (i.e. without affecting implementations of other
   operations). Hint: equational reasoning might be not enough; consider an
   equivalence relation* $\approx$ *meaning “have the same keys”, defined and
   used just in the axioms of the specification.*

**Exercise 5:** Design an algebraic specification and write a signature for 
first-in-first-out queues. Provide two implementations: one straightforward 
using a list, and another one using two lists: one for freshly added elements 
providing efficient queueing of new elements, and “reversed” one for efficient 
popping of old elements.

**Exercise 6:** Design an algebraic specification and write a signature for 
sets. Provide two implementations: one straightforward using a list, and 
another one using a map into the unit type.

* *To allow for a more complete specification of sets here, augment the maps
  ADT with generally useful operations that you find necessary or convenient
  for map-based implementation of sets.*

**Exercise 7:**

1. *(Ex. 2.2 in* *Chris Okasaki “Purely Functional Data Structures”**) In the
   worst case,* `*member*` *performs approximately* $2 d$ *comparisons, where*
   $d$ *is the depth of the tree. Rewrite* `*member*` *to take no mare than*
   $d + 1$ *comparisons by keeping track of a candidate element
   that* *might* *be equal to the query element (say, the last element for
   which* $<$ *returned false) and checking for equality only when you
   hit the bottom of the tree.*
1. *(Ex. 3.10 in* *Chris Okasaki “Purely Functional Data Structures”**) The*
   `*balance*` *function currently performs several unnecessary tests: when
   e.g.* `*ins*` *recurses on the left child, there are no violations on the
   right child.*
   1. *Split* `*balance*` *into* `*lbalance*` *and* `*rbalance*` *that test
      for violations of left resp. right child only. Replace calls to*
      `*balance*` *appropriately.*
   1. *One of the remaining tests on grandchildren is also unnecessary.
      Rewrite* `*ins*` *so that it never tests the color of nodes not on the
      search path.*
