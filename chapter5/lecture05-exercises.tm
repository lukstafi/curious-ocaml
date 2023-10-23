<TeXmacs|1.0.7.16>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming>

  <\title>
    Type Inference

    Abstract Data Types
  </title>

  <\exercise>
    Derive the equations and solve them to find the type for:

    <hlkwa|let ><hlstd|cadr l ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|hd
    ><hlopt|(><hlkwc|List><hlopt|.><hlstd|tl l><hlopt|) ><hlkwa|in
    ><hlstd|cadr ><hlopt|(><hlnum|1><hlopt|::><hlnum|2><hlopt|::[]),
    ><hlstd|cadr ><hlopt|(><hlkwa|true><hlopt|::><hlkwa|false><hlopt|::[])>

    in environment <math|\<Gamma\>=<around*|{|<with|mode|text|<hlkwc|List><hlopt|.><hlstd|hd>>:\<forall\>\<alpha\>.\<alpha\>
    list\<rightarrow\>\<alpha\>;<with|mode|text|<hlkwc|List><hlopt|.><hlstd|tl>>:\<forall\>\<alpha\>.\<alpha\>
    list\<rightarrow\>\<alpha\> list|}>>. You can take ``shortcuts'' if it is
    too many equations to write down.
  </exercise>

  <\exercise>
    <em|Terms> <math|t<rsub|1>,t<rsub|2>,\<ldots\>\<in\>T<around*|(|\<Sigma\>,X|)>>
    are built out of variables <math|x,y,\<ldots\>\<in\>X> and function
    symbols <math|f,g,\<ldots\>\<in\>\<Sigma\>> the way you build values out
    of functions:

    <\itemize>
      <item><math|X\<subset\>T<around*|(|\<Sigma\>,X|)>> -- variables are
      terms; usually an infinite set,

      <item>for terms <math|t<rsub|1>,\<ldots\>,t<rsub|n>\<in\>T<around*|(|\<Sigma\>,X|)>>
      and a function symbol <math|f\<in\>\<Sigma\><rsub|n>> of arity
      <math|n>, <math|f<around*|(|t<rsub|1>,\<ldots\>,t<rsub|n>|)>\<in\>T<around*|(|\<Sigma\>,X|)>>
      -- bigger terms arise from applying function symbols to smaller terms;
      <math|\<Sigma\>=<wide|\<cup\>|\<dot\>><rsub|n>\<Sigma\><rsub|n>> is
      called a signature.
    </itemize>

    In OCaml, we can define terms as: <hlkwa|type ><hlstd|term ><hlopt|=
    ><hlkwd|V ><hlkwa|of ><hlkwb|string ><hlopt|\| ><hlkwd|T ><hlkwa|of
    ><hlkwb|string ><hlopt|* ><hlstd|term list><htab|5mm>, where for example
    <hlkwd|V><hlopt|(><hlstr|"x"><hlopt|)> is a variable <math|x> and
    <hlkwd|T><hlopt|(><hlstr|"f"><hlopt|,
    [><hlkwd|V><hlopt|(><hlstr|"x"><hlopt|);
    ><hlkwd|V><hlopt|(><hlstr|"y"><hlopt|)])> is the term
    <math|f<around*|(|x,y|)>>.

    By <em|substitutions> <math|\<sigma\>,\<rho\>,\<ldots\>> we mean finite
    sets of variable, term pairs which we can write as
    <math|<around*|{|x<rsub|1>\<mapsto\>t<rsub|1>,\<ldots\>,x<rsub|k>\<mapsto\>t<rsub|k>|}>>
    or <math|<around*|[|x<rsub|1>\<assign\>t<rsub|1>;\<ldots\>;x<rsub|k>\<assign\>t<rsub|k>|]>>,
    but also functions from terms to terms
    <math|\<sigma\>:T<around*|(|\<Sigma\>,X|)>\<rightarrow\>T<around*|(|\<Sigma\>,X|)>>
    related to the pairs as follows: if <math|\<sigma\>=<around*|{|x<rsub|1>\<mapsto\>t<rsub|1>,\<ldots\>,x<rsub|k>\<mapsto\>t<rsub|k>|}>>,
    then

    <\itemize>
      <item><math|\<sigma\><around*|(|x<rsub|i>|)>=t<rsub|i>> for
      <math|x<rsub|i>\<in\><around*|{|x<rsub|1>,\<ldots\>,x<rsub|k>|}>>,

      <item><math|\<sigma\><around*|(|x|)>=x> for
      <math|x\<in\>X\\<around*|{|x<rsub|1>,\<ldots\>,x<rsub|k>|}>>,

      <item><math|\<sigma\><around*|(|f<around*|(|t<rsub|1>,\<ldots\>,t<rsub|n>|)>|)>=f<around*|(|\<sigma\><around*|(|t<rsub|1>|)>,\<ldots\>,\<sigma\><around*|(|t<rsub|n>|)>|)>>.
    </itemize>

    In OCaml, we can define substitutions <math|\<sigma\>> as: <hlkwa|type
    ><hlstd|subst ><hlopt|= (><hlkwb|string ><hlopt|* ><hlstd|term><hlopt|)
    ><hlstd|list>, together with a function <hlstd|apply ><hlopt|:
    ><hlstd|subst ><hlopt|-\<gtr\> ><hlstd|term ><hlopt|-\<gtr\>
    ><hlstd|term> which computes <math|\<sigma\><around*|(|\<cdot\>|)>>.

    We say that a substitution <math|\<sigma\>> is <em|more general> than all
    substitutions <math|\<rho\>\<circ\>\<sigma\>>, where
    <math|<around*|(|\<rho\>\<circ\>\<sigma\>|)><around*|(|x|)>=\<rho\><around*|(|\<sigma\><around*|(|x|)>|)>>.
    In type inference, we are interested in most general solutions: the less
    general type judgement <math|<with|mode|text|<hlkwc|List><hlopt|.><hlstd|hd>>:int
    list\<rightarrow\>int>, although valid, is less useful than
    <math|<with|mode|text|<hlkwc|List><hlopt|.><hlstd|hd>>:\<forall\>\<alpha\>.\<alpha\>
    list\<rightarrow\>\<alpha\>> because it limits the usage of
    <hlkwc|List><hlopt|.><hlstd|hd>.

    A <em|unification problem> is a finite set of equations
    <math|S=<around*|{|s<rsub|1>=<rsup|?>t<rsub|1>,\<ldots\>,s<rsub|n>=<rsup|?>t<rsub|n>|}>>
    which we can also write as <math|s<rsub|1><wide|=|\<dot\>>t<rsub|1>\<wedge\>\<ldots\>\<wedge\>s<rsub|n><wide|=|\<dot\>>t<rsub|n>>.
    A solution, or <em|unifier> of <math|S>, is a substitution
    <math|\<sigma\>> such that <math|\<sigma\><around*|(|s<rsub|i>|)>=\<sigma\><around*|(|t<rsub|i>|)>>
    for <math|i=1,\<ldots\>,n>. A <em|most general unifier>, for short
    <em|MGU>, is a most general such substitution.

    A substitution is <em|idempotent> when
    <math|\<sigma\>=\<sigma\>\<circ\>\<sigma\>>. If
    <math|\<sigma\>=<around*|{|x<rsub|1>\<mapsto\>t<rsub|1>,\<ldots\>,x<rsub|k>\<mapsto\>t<rsub|k>|}>>,
    then <math|\<sigma\>> is idempotent exactly when no <math|t<rsub|i>>
    contains any of the variables <math|<around*|{|x<rsub|1>,\<ldots\>,x<rsub|n>|}>>;
    i.e. <math|<around*|{|x<rsub|1>,\<ldots\>,x<rsub|n>|}>\<cap\>Vars<around*|(|t<rsub|1>,\<ldots\>,t<rsub|n>|)>=\<varnothing\>>.

    <\enumerate>
      <item>Implement an algorithm that, given a set of equations represented
      as a list of pairs of terms, computes an idempotent most general
      unifier of the equations.

      <item>* (Ex. 4.22 in <em|Franz Baader and Tobias Nipkov ``Term
      Rewriting and All That''>, p. 82.) Modify the implementation of
      unification to achieve linear space complexity by working with what
      could be called iterated substitutions. For example, the solution to
      <math|<around*|{|x=<rsup|?>f<around*|(|y|)>,y=<rsup|?>g<around*|(|z|)>,z=<rsup|?>a|}>>
      should be represented as variable, term pairs
      <math|<around*|(|x,f<around*|(|y|)>|)>,<around*|(|y,g<around*|(|z|)>|)>,<around*|(|z,a|)>>.
      (Hint: iterated substitutions should be unfolded lazily, i.e. only so
      far that either a non-variable term or the end of the instantiation
      chain is found.)
    </enumerate>
  </exercise>

  <\exercise>
    \;

    <\enumerate>
      <item>What does it mean that an implementation has junk (as an
      algebraic structure for a given signature)? Is it bad?

      <item>Define a monomorphic algebraic specification (other than, but
      similar to, <math|nat<rsub|p>> or <math|string<rsub|p>>, some useful
      data type).

      <item>Discuss an example of a (monomorphic) algebraic specification
      where it would be useful to drop some axioms (giving up monomorphicity)
      to allow more efficient implementations.
    </enumerate>
  </exercise>

  <\exercise>
    \;

    <\enumerate>
      <item>Does the example <hlkwc|ListMap> meet the requirements of the
      algebraic specification for maps? Hint: here is the definition of
      <hlkwc|List><hlopt|.><hlstd|remove<textunderscore>assoc>;
      <verbatim|compare a x> equals <hlnum|0> if and only if
      <verbatim|a><hlopt| = ><verbatim|x>.

      <small|<hlkwa|let rec ><hlstd|remove<textunderscore>assoc x ><hlopt|=
      ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| []
      -\<gtr\> []><hlendline|><next-line><hlstd| \ ><hlopt|\|
      (><hlstd|a><hlopt|, ><hlstd|b ><hlkwa|as ><hlstd|pair><hlopt|) ::
      ><hlstd|l ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
      \ \ \ \ \ ><hlkwa|if ><hlstd|compare a x ><hlopt|= ><hlnum|0
      ><hlkwa|then ><hlstd|l ><hlkwa|else ><hlstd|pair ><hlopt|::
      ><hlstd|remove<textunderscore>assoc x l><hlendline|>>

      <item>Trick question: what is the computational complexity of
      <hlkwc|ListMap> or <hlkwc|TrivialMap>?

      <item>* The implementation <hlkwc|MyListMap> is inefficient: it
      performs a lot of copying and is not tail-recursive. Optimize it
      (without changing the type definition).

      <item>Add (and specify) <math|isEmpty:<around*|(|\<alpha\>,\<beta\>|)>
      map\<rightarrow\>bool> to the example algebraic specification of maps
      without increasing the burden on its implementations (i.e. without
      affecting implementations of other operations). Hint: equational
      reasoning might be not enough; consider an equivalence relation
      <math|\<approx\>> meaning ``have the same keys'', defined and used just
      in the axioms of the specification.
    </enumerate>
  </exercise>

  <\exercise>
    Design an algebraic specification and write a signature for
    first-in-first-out queues. Provide two implementations: one
    straightforward using a list, and another one using two lists: one for
    freshly added elements providing efficient queueing of new elements, and
    ``reversed'' one for efficient popping of old elements.
  </exercise>

  <\exercise>
    Design an algebraic specification and write a signature for sets. Provide
    two implementations: one straightforward using a list, and another one
    using a map into the unit type.

    <\itemize>
      <item>To allow for a more complete specification of sets here, augment
      the maps ADT with generally useful operations that you find necessary
      or convenient for map-based implementation of sets.
    </itemize>
  </exercise>

  <\exercise>
    \;

    <\enumerate>
      <item>(Ex. 2.2 in <em|Chris Okasaki ``Purely Functional Data
      Structures''>) In the worst case, <verbatim|member> performs
      approximately <math|2d> comparisons, where <math|d> is the depth of the
      tree. Rewrite <verbatim|member> to take no mare than <math|d+1>
      comparisons by keeping track of a candidate element that <em|might> be
      equal to the query element (say, the last element for which
      <math|\<less\>> returned false) and checking for equality only when you
      hit the bottom of the tree.

      <item>(Ex. 3.10 in <em|Chris Okasaki ``Purely Functional Data
      Structures''>) The <verbatim|balance> function currently performs
      several unnecessary tests: when e.g. <verbatim|ins> recurses on the
      left child, there are no violations on the right child.

      <\enumerate>
        <item>Split <verbatim|balance> into <verbatim|lbalance> and
        <verbatim|rbalance> that test for violations of left resp. right
        child only. Replace calls to <verbatim|balance> appropriately.

        <item>One of the remaining tests on grandchildren is also
        unnecessary. Rewrite <verbatim|ins> so that it never tests the color
        of nodes not on the search path.
      </enumerate>
    </enumerate>
  </exercise>
</body>

<\initial>
  <\collection>
    <associate|language|american>
    <associate|page-type|letter>
    <associate|sfactor|5>
  </collection>
</initial>

<\references>
  <\collection>
    <associate|TravTreeEx|<tuple|3|?>>
    <associate|auto-1|<tuple|1|?>>
  </collection>
</references>