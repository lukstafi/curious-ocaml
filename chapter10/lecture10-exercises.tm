<TeXmacs|1.0.7.16>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming>

  <\title>
    Zippers, Reactivity, GUIs
  </title>

  <\exercise>
    Introduce operators <math|-,/> into the context rewriting ``pull out
    subexpression'' example. Remember that they are not commutative.
  </exercise>

  <\exercise>
    Add to the <em|paddle game> example:

    <\enumerate>
      <item>game restart,

      <item>score keeping,

      <item>game quitting (in more-or-less elegant way).
    </enumerate>
  </exercise>

  <\exercise>
    Our numerical integration function roughly corresponds to the rectangle
    rule. Modify the rule and write a test for the accuracy of:

    <\enumerate>
      <item>the trapezoidal rule;

      <item>the Simpson's rule. <hlink|http://en.wikipedia.org/wiki/Simpson%27s_rule|http://en.wikipedia.org/wiki/Simpson%27s_rule>
    </enumerate>
  </exercise>

  <\exercise>
    Explain the recursive behavior of integration:

    <\enumerate>
      <item>In <em|paddle game> implemented by stream processing --
      <verbatim|Lec10b.ml>, do we look at past velocity to determine current
      position, at past position to determine current velocity, both, or
      neither?

      <item>What is the difference between <verbatim|integral> and
      <verbatim|integral_nice> in <verbatim|Lec10c.ml>, what happens when we
      replace the former with the latter in the <verbatim|pbal> function? How
      about after rewriting <verbatim|pbal> into pure style as in the
      following exercise?
    </enumerate>
  </exercise>

  <\exercise>
    Reimplement the <em|Froc> based paddle ball example in a pure style:
    rewrite the <verbatim|pbal> function to not use <verbatim|notify_e>.
  </exercise>

  <\exercise>
    * Our implementation of flows is a bit heavy. One alternative approach is
    to use continuations, as in <verbatim|Scala.React>. OCaml has a
    continuations library <em|Delimcc>; for how it can cooperate with
    <em|Froc>, see<next-line><hlink|http://ambassadortothecomputers.blogspot.com/2010/08/mixing-monadic-and-direct-style-code.html|http://ambassadortothecomputers.blogspot.com/2010/08/mixing-monadic-and-direct-style-code.html>
  </exercise>

  <\exercise>
    Implement <verbatim|parallel> for flows, retaining coarse-grained
    implementation and using the event queue from <em|Froc> somehow (instead
    of introducing a new job queue).
  </exercise>

  <\exercise>
    Add quitting, e.g. via a <verbatim|'q'> key press, to the <em|painter>
    example. Use the <verbatim|is_cancelled> function.
  </exercise>

  <\exercise>
    Our calculator example is not finished. Implement entering decimal
    fractions: add handling of the <verbatim|dots> event.
  </exercise>

  <\exercise>
    The <hlkwc|Flow> module has reader monad functions that have not been
    discussed on slides:<next-line><hlkwa|let ><hlstd|local f m ><hlopt|=
    ><hlkwa|fun ><hlstd|emit ><hlopt|-\<gtr\> ><hlstd|m ><hlopt|(><hlkwa|fun
    ><hlstd|x ><hlopt|-\<gtr\> ><hlstd|emit ><hlopt|(><hlstd|f
    x><hlopt|))><hlendline|><next-line><hlkwa|let
    ><hlstd|local<textunderscore>opt f m ><hlopt|= ><hlkwa|fun ><hlstd|emit
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ m ><hlopt|(><hlkwa|fun
    ><hlstd|x ><hlopt|-\<gtr\> ><hlkwa|match ><hlstd|f x ><hlkwa|with
    ><hlkwd|None ><hlopt|-\<gtr\> () \| ><hlkwd|Some ><hlstd|y
    ><hlopt|-\<gtr\> ><hlstd|emit y><hlopt|)><hlendline|><next-line><hlkwa|val
    ><hlstd|local ><hlopt|: (><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b><hlopt|)
    -\<gtr\> (><hlstd|'a><hlopt|, ><hlstd|'c><hlopt|) ><hlstd|flow
    ><hlopt|-\<gtr\> (><hlstd|'b><hlopt|, ><hlstd|'c><hlopt|)
    ><hlstd|flow><hlendline|><next-line><hlkwa|val
    ><hlstd|local<textunderscore>opt ><hlopt|: (><hlstd|'a ><hlopt|-\<gtr\>
    ><hlstd|'b ><hlkwb|option><hlopt|) -\<gtr\> (><hlstd|'a><hlopt|,
    ><hlstd|'c><hlopt|) ><hlstd|flow ><hlopt|-\<gtr\> (><hlstd|'b><hlopt|,
    ><hlstd|'c><hlopt|) ><hlstd|flow><hlendline|>

    Implement an example that uses this compositionality-increasing
    capability.
  </exercise>

  \;
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
    <associate|TreeM|<tuple|3|?>>
    <associate|auto-1|<tuple|1|?>>
  </collection>
</references>