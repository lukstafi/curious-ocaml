<TeXmacs|1.99.2>

<style|<tuple|exam|american|highlight>>

<\body>
  <class|Functional Programming><name|Šukasz Stafiniak>

  <\title>
    The Expression Problem
  </title>

  <\exercise>
    <label|ExStringOf>Implement the <verbatim|string_of_> functions or
    methods, covering all data cases, corresponding to the <verbatim|eval_>
    functions in at least two examples from the lecture, including both an
    object-based example and a variant-based example (either standard, or
    polymorphic, or extensible variants).
  </exercise>

  <\exercise>
    <label|ExSplitFiles>Split at least one of the examples from the previous
    exercise into multiple files and demonstrate separate compilation.
  </exercise>

  <\exercise>
    Can we drop the tags <verbatim|Lambda_t>, <verbatim|Expr_t> and
    <verbatim|LExpr_t> used in the examples based on standard variants (file
    <verbatim|FP_ADT.ml>)? When using polymorphic variants, such tags are not
    needed.
  </exercise>

  <\exercise>
    Factor-out the sub-language consisting only of variables, thus
    eliminating the duplication of tags <verbatim|VarL>, <verbatim|VarE> in
    the examples based on standard variants (file <verbatim|FP_ADT.ml>).
  </exercise>

  <\exercise>
    Come up with a scenario where the extensible variant types-based solution
    leads to a non-obvious or hard to locate bug.
  </exercise>

  <\exercise>
    * Re-implement the direct object-based solution to the expression problem
    (file <verbatim|Objects.ml>) to make it more satisfying. For example,
    eliminate the need for some of the <verbatim|rename>, <verbatim|apply>,
    <verbatim|compute> methods.
  </exercise>

  <\exercise>
    Re-implement the visitor pattern-based solution to the expression problem
    (file <verbatim|Visitor.ml>) in a functional way, i.e. replace the
    mutable fields <verbatim|subst> and <verbatim|beta_redex> in the
    <verbatim|eval_lambda> class with a different solution to the problem of
    treating <verbatim|abs> and non-<verbatim|abs> expressions differently.

    * See if you can replace the reference cells <verbatim|result> in
    <verbatim|eval<math|N>> and <verbatim|freevars<math|N>> functions (for
    <verbatim|<math|N=>1,2,3>) with a different solution to the problem of
    polymorphism wrt. the type of the computed values.\ 
  </exercise>

  <\exercise>
    Extend the sub-language <verbatim|expr_visit> with variables, and add to
    arguments of the evaluation constructor <verbatim|eval_expr> the
    substitution. Handle the problem of potentially duplicate fields
    <verbatim|subst>. (One approach might be to use ideas from exercise 6.)
  </exercise>

  <\exercise>
    Impement the following modifications to the example from the file
    <verbatim|PolyV.ml>:

    <\enumerate>
      <item>Factor-out the sub-language of variables, around the already
      present <verbatim|var> type.

      <item>Open the types of functions <verbatim|eval3>,
      <verbatim|freevars3> and other functions as required, so that explicit
      subtyping, e.g. in <hlstd|eval3<space|0.5em>><hlopt|[]<space|0.5em>(><hlstd|test2<space|0.5em>><hlopt|:\<gtr\><space|0.5em>><hlstd|lexpr<textunderscore>t><hlopt|)>,
      is not necessary.

      <item>Remove the double-dispatch currently in <verbatim|eval_lexpr> and
      <verbatim|freevars_lexpr>, by implementing a cascading design rather
      than a ``divide-and-conquer'' design.
    </enumerate>
  </exercise>

  <\exercise>
    Streamline the solution <verbatim|PolyRecM.ml> by extending the language
    of <math|\<lambda\>>-expressions with arithmetic expressions, rather than
    defining the sub-languages separately and then merging them. See slide on
    page 15 of Jacques Garrigue <em|Structural Types, Recursive Modules, and
    the Expression Problem>.
  </exercise>

  <\exercise>
    Transform a parser monad, or rewrite the parser monad transformer, by
    adding state for the line and column numbers.

    * How to implement a monad transformer transformer in OCaml?
  </exercise>

  <\exercise>
    Implement <verbatim|_of_string> functions as parser combinators on top of
    the example <verbatim|PolyRecM.ml>. Sections 4.3 and 6.2 of <em|Monadic
    Parser Combinators> by Graham Hutton and Erik Meijer might be helpful.
    Split the result into multiple files as in Exercise
    <reference|ExSplitFiles> and demonstrate dynamic loading of code.
  </exercise>

  <\exercise>
    What are the benefits and drawbacks of our lazy-monad-plus (built on top
    of <em|odd lazy lists>) approach, as compared to regular monad-plus built
    on top of <em|even lazy lists>? To additionally illustrate your answer:

    <\enumerate>
      <item>Rewrite the parser combinators example to use regular monad-plus
      and even lazy lists.

      <item>Select one example from Lecture 8 and rewrite it using
      lazy-monad-plus and odd lazy lists.
    </enumerate>
  </exercise>

  \;
</body>

<\initial>
  <\collection>
    <associate|page-type|letter>
    <associate|sfactor|5>
  </collection>
</initial>

<\references>
  <\collection>
    <associate|Ex1|<tuple|1|?>>
    <associate|ExSplitFiles|<tuple|2|1>>
    <associate|ExStringOf|<tuple|1|1>>
    <associate|TravTreeEx|<tuple|3|?>>
    <associate|TreeM|<tuple|3|?>>
    <associate|auto-1|<tuple|1|?>>
  </collection>
</references>