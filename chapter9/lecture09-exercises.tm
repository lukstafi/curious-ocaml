<TeXmacs|1.0.7.16>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming>

  <\title>
    Compiling and Parsing
  </title>

  <\exercise>
    (Exercise 6.1 from <em|``Modern Compiler Implementation in ML''> by
    Andrew W. Appel.) Using the <verbatim|ocamlopt> compiler with parameter
    <verbatim|-S> and other parameters turning on all possible compiler
    optimizations, evaluate the compiled programs by these criteria:

    <\enumerate>
      <item>Are local variables kept in registers? Show on an example.

      <item>If local variable <verbatim|b> is live across more than one
      procedure call, is it kept in a callee-save register? Explain how it
      would speed up the program:<next-line><hlkwa|let ><hlstd|f a ><hlopt|=
      ><hlkwa|let ><hlstd|b ><hlopt|= ><hlstd|a><hlopt|+><hlnum|1 ><hlkwa|in
      let ><hlstd|c ><hlopt|= ><hlstd|g ><hlopt|() ><hlkwa|in let ><hlstd|d
      ><hlopt|= ><hlstd|h c ><hlkwa|in ><hlstd|b><hlopt|+><hlstd|c><hlendline|>

      <item>If local variable <verbatim|x> is never live across a procedure
      call, is it properly kept in a caller-save register? Explain how doing
      thes would speed up the program:<next-line><hlkwa|let ><hlstd|h y
      ><hlopt|= ><hlkwa|let ><hlstd|x ><hlopt|= ><hlstd|y><hlopt|+><hlnum|1
      ><hlkwa|in let ><hlstd|z ><hlopt|= ><hlstd|f y ><hlkwa|in ><hlstd|f
      z><hlendline|>
    </enumerate>
  </exercise>

  <\exercise>
    As above, verify whether escaping variables of a function are kept in a
    closure corresponding to the function, or in closures corresponding to
    the local, i.e. nested, functions that are returned from the function (or
    assigned to a mutable field).
  </exercise>

  <\exercise>
    As above, verify that OCaml compiler performs <em|inline expansion> of
    small functions. Check whether the compiler can inline, or specialize
    (produce a local function to help inlining), recursive functions.
  </exercise>

  <\exercise>
    Write a ``<verbatim|.mll> program'' that anonymizes, or masks, text. That
    is, it replaces identified probable full names (of persons, companies
    etc.) with fresh shorthands <em|Mr. A>, <em|Ms. B>, or <em|Mr./Ms. C>
    when the gender cannot be easily determined. The same (full) name should
    be replaced with the same letter.

    <\itemize>
      <item>Do only a very rough job of course, starting with recognizing two
      or more capitalized words in a row.
    </itemize>
  </exercise>

  <\exercise>
    In the lexer <hlkwc|EngLexer> we call function <verbatim|abridged> from
    the module <hlkwc|EngMorph>. Inline the operation of <verbatim|abridged>
    into the lexer by adding a new regular expression pattern for each
    <hlkwa|if> clause. Assess the speedup on the <em|Shakespeare> corpus and
    the readability and either keep the change or revert it.
  </exercise>

  <\exercise>
    Make the lexer re-entrant for the second Menhir example (toy English
    grammar parser).
  </exercise>

  <\exercise>
    Make the determiner optional in the toy English grammar.

    <\enumerate>
      <item>* Can you come up with a factorization that would avoid having
      two more productions in total?
    </enumerate>
  </exercise>

  <\exercise>
    Integrate into the <em|Phrase search> example, the <em|Porter Stemmer>
    whose source is in the <verbatim|stemmer.ml> file.
  </exercise>

  <\exercise>
    Revisit the search engine example from lecture 6.

    <\enumerate>
      <item>Perform optimization of data structure, i.e. replace association
      lists with hash tables.

      <item>Optimize the algorithm: perform <em|query optimization>. Measure
      time gains for selected queries.

      <item>For bonus points, as time and interest permits, extend the query
      language with <em|OR> and <em|NOT> connectives, in addition to
      <em|AND>.

      <item>* Extend query optimization to the query language with <em|AND>,
      <em|OR> and <em|NOT> connectives.
    </enumerate>
  </exercise>

  <\exercise>
    Write an XML parser tailored to the <verbatim|shakespeare.xml> corpus
    provided with the phrase search example. Modify the phrase search engine
    to provide detailed information for each found location, e.g. which play
    and who speaks the phrase.
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
    <associate|TreeM|<tuple|3|?>>
    <associate|auto-1|<tuple|1|?>>
  </collection>
</references>