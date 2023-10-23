<TeXmacs|1.0.7.16>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming>

  <\title>
    Streams and lazy evaluation
  </title>

  <\exercise>
    My first impulse was to define lazy list functions as here:

    <next-line><hlkwa|let rec ><hlstd|wrong_lzip ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| <hlopt|\|>
    ><hlkwd|LNil><hlopt|, ><hlkwd|LNil ><hlopt|-\<gtr\>
    ><hlkwd|LNil><hlendline|><next-line><hlstd| <hlopt|\|> ><hlkwd|LCons
    ><hlopt|(><hlstd|a1><hlopt|, ><hlkwa|lazy ><hlstd|l1><hlopt|),
    ><hlkwd|LCons ><hlopt|(><hlstd|a2><hlopt|, ><hlkwa|lazy
    ><hlstd|l2><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ ><hlkwd|LCons ><hlopt|((><hlstd|a1><hlopt|, ><hlstd|a2><hlopt|),
    ><hlkwa|lazy ><hlopt|(><hlstd|wrong_lzip ><hlopt|(><hlstd|l1><hlopt|,
    ><hlstd|l2><hlopt|)))><hlendline|><next-line><hlstd| <hlopt|\|>
    <textunderscore> ><hlopt|-\<gtr\> ><hlstd|raise
    ><hlopt|(><hlkwd|Invalid<textunderscore>argument
    ><hlstr|"lzip"><hlopt|)><hlendline|><next-line><hlendline|><next-line><hlkwa|let
    rec ><hlstd|wrong_lmap f ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd|
    <hlopt|\|> ><hlkwd|LNil ><hlopt|-\<gtr\>
    ><hlkwd|LNil><hlendline|><next-line><hlstd| <hlopt|\|> ><hlkwd|LCons
    ><hlopt|(><hlstd|a><hlopt|, ><hlkwa|lazy ><hlstd|l><hlopt|) -\<gtr\>
    ><hlkwd|LCons ><hlopt|(><hlstd|f a><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlstd|wrong_lmap f l><hlopt|))><hlendline|><next-line>

    What is wrong with these definitions -- for which edge cases they do not
    work as intended?
  </exercise>

  <\exercise>
    Cyclic lazy lists:

    <\enumerate>
      <item>Implement a function <verbatim|cycle : 'a list -\<gtr\> 'a llist>
      that creates a lazy list with elements from standard list, and the
      whole list as the tail after the last element from the input list.

      <verbatim|[a1; a2; ...; aN]><math|\<mapsto\>><draw-over|<tabular|<tformat|<cwith|1|1|2|2|cell-halign|c>|<table|<row|<cell|<block|<tformat|<table|<row|<cell|<verbatim|a1>>|<cell|
      >>>>>>|<cell|<block|<tformat|<table|<row|<cell|<verbatim|a2>>|<cell|
      >>>>>>|<cell|<verbatim|...>>|<cell|<block|<tformat|<table|<row|<cell|<verbatim|aN>>|<cell|>>>>>>|<cell|>>|<row|<cell|>|<cell|>|<cell|>|<cell|>|<cell|>>>>>|<with|gr-color|red|gr-arrow-end|\|\<gtr\>|gr-grid|<tuple|empty>|gr-grid-old|<tuple|cartesian|<point|0|0>|1>|gr-edit-grid-aspect|<tuple|<tuple|axes|none>|<tuple|1|none>|<tuple|5|none>>|gr-edit-grid|<tuple|empty>|gr-edit-grid-old|<tuple|cartesian|<point|0|0>|1>|gr-grid-aspect|<tuple|<tuple|axes|dark
      blue>|<tuple|1|blue>|<tuple|5|blue>>|gr-grid-aspect-props|<tuple|<tuple|axes|dark
      blue>|<tuple|1|blue>|<tuple|5|blue>>|<graphics|<with|color|red|arrow-end|\|\<gtr\>|<line|<point|-1.40773|0.189096>|<point|-0.963222648498479|0.210262600873131>>>|<with|color|red|arrow-end|\|\<gtr\>|<line|<point|-0.201217|0.189096>|<point|0.264452969969573|0.210262600873131>>>|<with|color|red|arrow-end|\|\<gtr\>|<line|<point|0.75129|0.189096>|<point|1.06879216827623|0.189095779865062>>>|<with|color|red|arrow-end|\|\<gtr\>|<line|<point|1.78846|0.189096>|<point|2.19063368170393|0.210262600873131>|<point|2.19063368170393|-0.191906998280196>|<point|-2.0|-0.2>|<point|-2.0003968778939|-0.00140560920756714>>>>>>

      Your<strong|> function <verbatim|cycle> can either return
      <verbatim|LNil> or fail for an empty list as argument.\ 

      <item>Note that <verbatim|inv_fact> from the lecture defines the power
      series for the <math|exp<around*|(|\<cdot\>|)>> function
      (<math|exp<around*|(|x|)>=e<rsup|x>>). Using <verbatim|cycle> and
      <verbatim|inv_fact>, define the power series for
      <math|sin<around*|(|\<cdot\>|)>> and <math|cos<around*|(|\<cdot\>|)>>,
      and draw their graphs using helper functions from the lecture script
      <verbatim|Lec7.ml>.
    </enumerate>
  </exercise>

  <\exercise>
    * Modify one of the puzzle solving programs (either from the previous
    lecture or from your previous homework) to work with lazy lists.
    Implement the necessary higher-order lazy list functions. Check that
    indeed displaying only the first solution when there are multiple
    solutions in the result takes shorter than computing solutions by the
    original program.
  </exercise>

  <\exercise>
    <em|Hamming's problem>. Generate in increasing order the numbers of the
    form <math|2<rsup|a<rsub|1>>*3<rsup|a<rsub|2>>5<rsup|a<rsub|3>>\<ldots\>p<rsub|k><rsup|a<rsub|k>>>,
    that is numbers not divisible by prime numbers greater than the
    <math|k>th prime number.

    <\itemize>
      <item>In the original Hamming's problem posed by Dijkstra, <math|k=3>,
      which is related to <hlink|http://en.wikipedia.org/wiki/Regular_number|http://en.wikipedia.org/wiki/Regular_number>.
    </itemize>

    Starter code is available in the middle of the lecture script
    <verbatim|Lec7.ml>:<next-line><hlkwa|let rec ><hlstd|lfilter f ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| <hlopt|\|> ><hlkwd|LNil
    ><hlopt|-\<gtr\> ><hlkwd|LNil><hlendline|><next-line><hlstd| <hlopt|\|>
    ><hlkwd|LCons ><hlopt|(><hlstd|n><hlopt|, ><hlstd|ll><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ ><hlkwa|if ><hlstd|f n
    ><hlkwa|then ><hlkwd|LCons ><hlopt|(><hlstd|n><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlstd|lfilter f ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force
    ll><hlopt|)))><hlendline|><next-line><hlstd| \ \ \ \ ><hlkwa|else
    ><hlstd|lfilter f ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force
    ll><hlopt|)><hlendline|><next-line><hlendline|><next-line><hlkwa|let
    ><hlstd|primes ><hlopt|=><hlendline|><next-line><hlstd| ><hlkwa|let rec
    ><hlstd|sieve ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd|
    \ \ \ \ ><hlkwd|LCons><hlopt|(><hlstd|p><hlopt|,><hlstd|nf><hlopt|)
    -\<gtr\> ><hlkwd|LCons><hlopt|(><hlstd|p><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlstd|sieve ><hlopt|(><hlstd|sift p
    ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force
    nf><hlopt|))))><hlendline|><next-line><hlstd| \ \ ><hlopt|\| ><hlkwd|LNil
    ><hlopt|-\<gtr\> ><hlstd|failwith ><hlstr|"Impossible! Internal
    error."><hlstd|<hlendline|><next-line> ><hlkwa|and ><hlstd|sift p
    ><hlopt|= ><hlstd|lfilter ><hlopt|(><hlkwa|function ><hlstd|n
    ><hlopt|-\<gtr\> ><hlstd|n ><hlkwa|mod ><hlstd|p ><hlopt|\<less\>\<gtr\>
    ><hlnum|0><hlopt|)><hlendline|><next-line><hlkwa|in ><hlstd|sieve
    ><hlopt|(><hlstd|lfrom ><hlnum|2><hlopt|)><hlendline|><next-line><hlendline|><next-line><hlkwa|let
    ><hlstd|times ll n ><hlopt|= ><hlstd|lmap ><hlopt|(><hlkwa|fun ><hlstd|i
    ><hlopt|-\<gtr\> ><hlstd|i ><hlopt|* ><hlstd|n><hlopt|)
    ><hlstd|ll><hlopt|;;><hlendline|><next-line><hlendline|><next-line><hlkwa|let
    rec ><hlstd|merge xs ys ><hlopt|= ><hlkwa|match ><hlstd|xs><hlopt|,
    ><hlstd|ys ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|LCons ><hlopt|(><hlstd|x><hlopt|, ><hlkwa|lazy
    ><hlstd|xr><hlopt|), ><hlkwd|LCons ><hlopt|(><hlstd|y><hlopt|,
    ><hlkwa|lazy ><hlstd|yr><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ ><hlkwa|if ><hlstd|x ><hlopt|\<less\> ><hlstd|y ><hlkwa|then
    ><hlkwd|LCons ><hlopt|(><hlstd|x><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlstd|merge xr ys><hlopt|))><hlendline|><next-line><hlstd|
    \ \ \ \ ><hlkwa|else if ><hlstd|x ><hlopt|\<gtr\> ><hlstd|y ><hlkwa|then
    ><hlkwd|LCons ><hlopt|(><hlstd|y><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlstd|merge xs yr><hlopt|))><hlendline|><next-line><hlstd|
    \ \ \ \ ><hlkwa|else ><hlkwd|LCons ><hlopt|(><hlstd|x><hlopt|,
    ><hlkwa|lazy ><hlopt|(><hlstd|merge xr
    yr><hlopt|))><hlendline|><next-line><hlstd| <hlopt|\|> r><hlopt|,
    ><hlkwd|LNil ><hlopt|\| ><hlkwd|LNil><hlopt|, ><hlstd|r ><hlopt|-\<gtr\>
    ><hlstd|r><hlendline|><next-line><hlendline|><next-line><hlkwa|let
    ><hlstd|hamming k ><hlopt|=><hlendline|><next-line><hlstd| ><hlkwa|let
    ><hlstd|pr ><hlopt|= ><hlstd|ltake k primes
    ><hlkwa|in><hlendline|><next-line><hlstd| ><hlkwa|let rec ><hlstd|h
    ><hlopt|= ><hlkwd|LCons ><hlopt|(><hlnum|1><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlendline|><next-line><hlstd|
    \ \ ><hlopt|\<less\>><hlkwd|TODO><hlopt|\<gtr\> ))
    ><hlkwa|in><hlendline|><next-line><hlstd| h><hlendline|>
  </exercise>

  <\exercise>
    Modify <verbatim|format> and/or <verbatim|breaks> to use just a single
    number instead of a stack of booleans to keep track of what groups should
    be inlined.
  </exercise>

  <\exercise>
    Add <strong|indentation> to the pretty-printer for groups: if a group
    does not fit in a single line, its consecutive lines are indented by a
    given amount <verbatim|tab> of spaces deeper than its parent group lines
    would be. For comparison, let's do several implementations.

    <\enumerate>
      <item>Modify the straightforward implementation of <verbatim|pretty>.

      <item>Modify the first pipe-based implementation of <verbatim|pretty>
      by modifying the <verbatim|format> function.

      <item>Modify the second pipe-based implementation of <verbatim|pretty>
      by modifying the <verbatim|breaks> function. Recover the positions of
      elements -- the number of characters from the beginning of the document
      -- by keeping track of the growing offset.

      <item>* Modify a pipe-based implementation to provide a different style
      of indentation: indent the first line of a group, when the group starts
      on a new line, at the same level as the consecutive lines (rather than
      at the parent level of indentation).\ 
    </enumerate>
  </exercise>

  <\exercise>
    Write a pipe that takes document elements annotated with linear position,
    and produces document elements annotated with (line, column) coordinates.

    Write another pipe that takes so annotated elements and adds a line
    number indicator in front of each line. Do not update the column
    coordinate. Test the pipes by plugging them before the <verbatim|emit>
    pipe.

    <\code>
      1: first line

      2: second line, etc.
    </code>
  </exercise>

  <\exercise>
    Write a pipe that consumes document elements <verbatim|doc_e> and yields
    the toplevel subdocuments <verbatim|doc> which would generate the
    corresponding elements.

    You can modify the definition of documents to allow annotations, so that
    the element annotations are preserved (<verbatim|gen> should ignore
    annotations to keep things simple):<next-line><hlkwa|type ><hlstd|'a doc
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwd|Text ><hlkwa|of
    ><hlstd|'a ><hlopt|* ><hlkwb|string ><hlopt|\| ><hlkwd|Line ><hlkwa|of
    ><hlstd|'a <hlopt|\|> ><hlkwd|Cat ><hlkwa|of ><hlstd|doc ><hlopt|*
    ><hlstd|doc <hlopt|\|> ><hlkwd|Group ><hlkwa|of ><hlstd|'a ><hlopt|*
    ><hlstd|doc><hlendline|>
  </exercise>

  <\exercise>
    * Design and implement a way to duplicate arrows outgoing from a
    pipe-box, that would memoize the stream, i.e. not recompute everything
    ``upstream'' for the composition of pipes. Such duplicated arrows would
    behave nicely with pipes reading from files.

    <draw-over|<tabular|<tformat|<cwith|4|4|1|1|cell-col-span|3>|<cwith|4|4|5|5|cell-col-span|2>|<table|<row|<cell|>|<cell|>|<cell|<block|<tformat|<table|<row|<cell|<verbatim|h1>>>>>>>|<cell|>|<cell|>|<cell|<block|<tformat|<table|<row|<cell|<verbatim|f>>>>>>>>|<row|<cell|<block|<tformat|<table|<row|<cell|<verbatim|f>>>>>>>|<cell|<block|<tformat|<table|<row|<cell|<verbatim|g>>>>>>
    \ \ \ \ \ \ \ \ \ >|<cell|>|<cell|>|<cell|<block|<tformat|<table|<row|<cell|<verbatim|read_file>>>>>>>|<cell|>>|<row|<cell|>|<cell|>|<cell|<block|<tformat|<table|<row|<cell|<verbatim|h2>>>>>>>|<cell|>|<cell|>|<cell|<block|<tformat|<table|<row|<cell|<verbatim|g>>>>>>
    \ \ \ \ \ \ \ \ \ \ \ \ \ \ >>|<row|<cell|Does not recompute <verbatim|g>
    nor <verbatim|f>.>|<cell|>|<cell|>|<cell| \ \ \ >|<cell|Reads once and
    passes all content to <verbatim|f> and
    <verbatim|g>.>|<cell|>>>>>|<with|gr-color|red|gr-line-width|2ln|gr-arrow-end|\|\<gtr\>|gr-grid|<tuple|empty>|gr-grid-old|<tuple|cartesian|<point|0|0>|1>|gr-edit-grid-aspect|<tuple|<tuple|axes|none>|<tuple|1|none>|<tuple|4|none>>|gr-edit-grid|<tuple|empty>|gr-edit-grid-old|<tuple|cartesian|<point|0|0>|1>|gr-grid-aspect-props|<tuple|<tuple|axes|#808080>|<tuple|1|#c0c0c0>|<tuple|4|#e0e0ff>>|gr-grid-aspect|<tuple|<tuple|axes|#808080>|<tuple|1|#c0c0c0>|<tuple|4|#e0e0ff>>|<graphics|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-5.76918|0.217059>|<point|-4.24517131895753|0.217059134806191>>>|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-3.80067|0.238226>|<point|-2.4459915332716|0.746229660007938>>>|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-3.82183|0.259393>|<point|-2.4459915332716|-0.290944569387485>>>|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|1.08887|0.217059>|<point|3.98872205318164|0.725062838999868>>>|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|1.04653|0.195892>|<point|3.96755523217357|-0.333278211403625>>>>>>
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