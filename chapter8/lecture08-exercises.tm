<TeXmacs|1.0.7.16>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming>

  <\title>
    Monads
  </title>

  <\exercise>
    Puzzle via Oleg Kiselyov.

    <\quote-env>
      "U2" has a concert that starts in 17 minutes and they must all cross a
      bridge to get there. All four men begin on the same side of the bridge.
      It is night. There is one flashlight. A maximum of two people can cross
      at one time. Any party who crosses, either 1 or 2 people, must have the
      flashlight with them. The flashlight must be walked back and forth, it
      cannot be thrown, etc.. Each band member walks at a different speed. A
      pair must walk together at the rate of the slower man's pace:

      <\itemize>
        <item>Bono: 1 minute to cross

        <item>Edge: 2 minutes to cross

        <item>Adam: 5 minutes to cross

        <item>Larry: 10 minutes to cross
      </itemize>

      For example: if Bono and Larry walk across first, 10 minutes have
      elapsed when they get to the other side of the bridge. If Larry then
      returns with the flashlight, a total of 20 minutes have passed and you
      have failed the mission.
    </quote-env>

    Find all answers to the puzzle using a list comprehension. The
    comprehension will be a bit long but recursion is not needed.
  </exercise>

  <\exercise>
    Assume <verbatim|concat_map> as defined in lecture 6. What will the
    following expresions return? Why?

    <\enumerate>
      <item><hlkwa|perform with ><hlopt|(><hlstd|<hlopt|\|>><hlopt|-\<gtr\>)
      ><hlkwa|in><hlendline|><next-line><hlstd| \ return
      ><hlnum|5><hlopt|;><hlendline|><next-line><hlstd| \ return
      ><hlnum|7><hlendline|>

      <item><hlkwa|let ><hlstd|guard p ><hlopt|= ><hlkwa|if ><hlstd|p
      ><hlkwa|then ><hlopt|[()] ><hlkwa|else
      ><hlopt|[];;><hlendline|><next-line><hlkwa|perform with
      ><hlopt|(><hlstd|<hlopt|\|>><hlopt|-\<gtr\>)
      ><hlkwa|in><hlendline|><next-line><hlstd| \ guard
      ><hlkwa|false><hlopt|;><hlendline|><next-line><hlstd| \ return
      ><hlnum|7><hlopt|;;><hlendline|>

      <item><hlkwa|perform with ><hlopt|(><hlstd|<hlopt|\|>><hlopt|-\<gtr\>)
      ><hlkwa|in><hlendline|><next-line><hlstd| \ return
      ><hlnum|5><hlopt|;><hlendline|><next-line><hlstd| \ guard
      ><hlkwa|false><hlopt|;><hlendline|><next-line><hlstd| \ return
      ><hlnum|7><hlopt|;;><hlendline|>
    </enumerate>
  </exercise>

  <\exercise>
    Define <verbatim|bind> in terms of <verbatim|lift> and <verbatim|join>.
  </exercise>

  <\exercise>
    <label|TreeM>Define a monad-plus implementation based on binary trees,
    with constant-time <verbatim|mzero> and <verbatim|mplus>. Starter
    code:<next-line><hlkwa|type ><hlstd|'a tree ><hlopt|= ><hlkwd|Empty
    ><hlopt|\| ><hlkwd|Leaf ><hlkwa|of ><hlstd|'a <hlopt|\|> ><hlkwd|T
    ><hlkwa|of ><hlstd|'a t ><hlopt|* ><hlstd|'a
    t><hlendline|><next-line><hlkwa|module ><hlkwd|TreeM ><hlopt|=
    ><hlkwd|MonadPlus ><hlopt|(><hlkwa|struct><hlendline|><next-line><hlstd|
    \ ><hlkwa|type ><hlstd|'a><hlstd| t ><hlopt|= ><hlstd|'a
    tree<hlendline|><next-line> \ ><hlkwa|let ><hlstd|bind a b ><hlopt|=
    >TODO<hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|return a
    ><hlopt|= >TODO<hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|mzero
    ><hlopt|= >TODO<hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|mplus
    a b ><hlopt|= >TODO<hlendline|><next-line><hlkwa|end><hlopt|)><hlendline|>
  </exercise>

  <\exercise>
    Show the monad-plus laws for one of:

    <\enumerate>
      <item><verbatim|TreeM> from your solution of exercise
      <reference|TreeM>;

      <item><verbatim|ListM> from lecture.
    </enumerate>
  </exercise>

  <\exercise>
    Why the following monad-plus is not lazy enough?

    <\itemize>
      <item><hlkwa|let rec ><hlstd|badappend l1 l2
      ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match ><hlstd|l1
      ><hlkwa|with lazy ><hlkwd|LazNil ><hlopt|-\<gtr\>
      ><hlstd|l2<hlendline|><next-line> \ ><hlopt|\| ><hlkwa|lazy
      ><hlopt|(><hlkwd|LazCons ><hlopt|(><hlstd|hd><hlopt|,
      ><hlstd|tl><hlopt|)) -\<gtr\>><hlendline|><next-line><hlstd|
      \ \ \ ><hlkwa|lazy ><hlopt|(><hlkwd|LazCons
      ><hlopt|(><hlstd|hd><hlopt|, ><hlstd|badappend tl
      l2><hlopt|))><hlendline|><next-line><hlkwa|let rec
      ><hlstd|badconcat<textunderscore>map f ><hlopt|=
      ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
      ><hlkwa|lazy ><hlkwd|LazNil ><hlopt|-\<gtr\> ><hlkwa|lazy
      ><hlkwd|LazNil><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwa|lazy
      ><hlopt|(><hlkwd|LazCons ><hlopt|(><hlstd|a><hlopt|,
      ><hlstd|l><hlopt|)) -\<gtr\>><hlendline|><next-line><hlstd|
      \ \ \ badappend ><hlopt|(><hlstd|f a><hlopt|)
      (><hlstd|badconcat<textunderscore>map f l><hlopt|)><hlendline|>

      <item><hlkwa|module ><hlkwd|BadyListM ><hlopt|= ><hlkwd|MonadPlus
      ><hlopt|(><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|type
      ><hlstd|'a><hlstd| t ><hlopt|= ><hlstd|'a
      lazy<textunderscore>list<hlendline|><next-line> \ ><hlkwa|let
      ><hlstd|bind a b ><hlopt|= ><hlstd|badconcat<textunderscore>map b
      a<hlendline|><next-line> \ ><hlkwa|let ><hlstd|return a ><hlopt|=
      ><hlkwa|lazy ><hlopt|(><hlkwd|LazCons ><hlopt|(><hlstd|a><hlopt|,
      ><hlkwa|lazy ><hlkwd|LazNil><hlopt|))><hlendline|><next-line><hlstd|
      \ ><hlkwa|let ><hlstd|mzero ><hlopt|= ><hlkwa|lazy
      ><hlkwd|LazNil><hlendline|><next-line><hlstd| \ ><hlkwa|let
      ><hlstd|mplus ><hlopt|= ><hlstd|badappend><hlendline|><next-line><hlkwa|end><hlopt|)><hlendline|>

      <item><hlkwa|module ><hlkwd|BadyCountdown ><hlopt|= ><hlkwd|Countdown
      ><hlopt|(><hlkwd|BadyListM><hlopt|)><hlendline|><next-line><hlkwa|let
      ><hlstd|test5 ><hlopt|() = ><hlkwc|BadyListM><hlopt|.><hlstd|run
      ><hlopt|(><hlkwc|BadyCountdown><hlopt|.><hlstd|solutions
      ><hlopt|[><hlnum|1><hlopt|;><hlnum|3><hlopt|;><hlnum|7><hlopt|;><hlnum|10><hlopt|;><hlnum|25><hlopt|;><hlnum|50><hlopt|]
      ><hlnum|765><hlopt|)><hlendline|>

      <item><hlstd|# ><hlkwa|let ><hlstd|t5a><hlopt|, ><hlstd|sol5 ><hlopt|=
      ><hlstd|time test5><hlopt|;;><hlendline|><next-line><hlkwa|val
      ><hlstd|t5a ><hlopt|: ><hlkwb|float ><hlopt|=
      ><hlnum|3.3954310417175293><hlendline|><next-line><hlkwa|val
      ><hlstd|sol5 ><hlopt|: ><hlkwb|string ><hlstd|lazy<textunderscore>list
      ><hlopt|= \<less\>><hlkwa|lazy><hlopt|\<gtr\>><hlendline|><next-line><hlstd|#
      ><hlkwa|let ><hlstd|t5b><hlopt|, ><hlstd|sol5<textunderscore>1
      ><hlopt|= ><hlstd|time ><hlopt|(><hlkwa|fun ><hlopt|() -\<gtr\>
      ><hlstd|laztake ><hlnum|1 ><hlstd|sol5><hlopt|);;><hlendline|><next-line><hlkwa|val
      ><hlstd|t5b ><hlopt|: ><hlkwb|float ><hlopt|=
      ><hlnum|3.0994415283203125e-06><hlendline|><next-line><hlkwa|val
      ><hlstd|sol5<textunderscore>1 ><hlopt|: ><hlkwb|string ><hlstd|list
      ><hlopt|= [><hlstr|"((25-(3+7))*(1+50))"><hlopt|]><hlendline|><next-line><hlstd|#
      ><hlkwa|let ><hlstd|t5c><hlopt|, ><hlstd|sol5<textunderscore>9
      ><hlopt|= ><hlstd|time ><hlopt|(><hlkwa|fun ><hlopt|() -\<gtr\>
      ><hlstd|laztake ><hlnum|10 ><hlstd|sol5><hlopt|);;><hlendline|><next-line><hlkwa|val
      ><hlstd|t5c ><hlopt|: ><hlkwb|float ><hlopt|=
      ><hlnum|7.8678131103515625e-06><hlendline|><next-line><hlkwa|val
      ><hlstd|sol5<textunderscore>9 ><hlopt|: ><hlkwb|string ><hlstd|list
      ><hlopt|=><hlendline|><next-line><hlstd|
      \ ><hlopt|[><hlstr|"((25-(3+7))*(1+50))"><hlopt|;
      ><hlstr|"(((25-3)-7)*(1+50))"><hlopt|;
      ...><hlendline|><next-line><hlstd|# ><hlkwa|let ><hlstd|t5d><hlopt|,
      ><hlstd|sol5<textunderscore>39 ><hlopt|= ><hlstd|time
      ><hlopt|(><hlkwa|fun ><hlopt|() -\<gtr\> ><hlstd|laztake ><hlnum|49
      ><hlstd|sol5><hlopt|);;><hlendline|><next-line><hlkwa|val ><hlstd|t5d
      ><hlopt|: ><hlkwb|float ><hlopt|= ><hlnum|2.59876251220703125e-05><hlendline|><next-line><hlkwa|val
      ><hlstd|sol5<textunderscore>39 ><hlopt|: ><hlkwb|string ><hlstd|list
      ><hlopt|=><hlendline|><next-line><hlstd|
      \ ><hlopt|[><hlstr|"((25-(3+7))*(1+50))"><hlopt|;
      ><hlstr|"(((25-3)-7)*(1+50))"><hlopt|; ...><hlendline|>
    </itemize>
  </exercise>

  <\exercise>
    Convert a ``rectangular'' list of lists of strings, representing a matrix
    with inner lists being rows, into a string, where elements are
    column-aligned. (Exercise not related to recent material.)
  </exercise>

  <\exercise>
    Recall the overly rich way to introduce monads -- providing the freedom
    of additional parameter<next-line><hlkwa|module type ><hlkwd|MONAD
    ><hlopt|= ><hlkwa|sig><hlendline|><next-line><hlstd| \ ><hlkwa|type
    ><hlopt|(><hlstd|'s><hlopt|, ><hlstd|'a><hlopt|)
    ><hlstd|t<hlendline|><next-line> \ ><hlkwa|val ><hlstd|return ><hlopt|:
    ><hlstd|'a ><hlopt|-\<gtr\> (><hlstd|'s><hlopt|, ><hlstd|'a><hlopt|)
    ><hlstd|t<hlendline|><next-line> \ ><hlkwa|val ><hlstd|bind
    ><hlopt|:><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|(><hlstd|'s><hlopt|, ><hlstd|'a><hlopt|) ><hlstd|t
    ><hlopt|-\<gtr\> (><hlstd|'a ><hlopt|-\<gtr\> (><hlstd|'s><hlopt|,
    ><hlstd|'b><hlopt|) ><hlstd|t><hlopt|) -\<gtr\> (><hlstd|'s><hlopt|,
    ><hlstd|'b><hlopt|) ><hlstd|t><hlendline|><next-line><hlkwa|end>

    Recall the operations for the exception monad:<next-line><hlkwa|val
    ><hlstd|throw ><hlopt|: ><hlstd|excn ><hlopt|-\<gtr\> ><hlstd|'a
    monad<hlendline|><next-line>><hlkwa|val ><hlstd|catch ><hlopt|:
    ><hlstd|'a monad ><hlopt|-\<gtr\> (><hlstd|excn ><hlopt|-\<gtr\>
    ><hlstd|'a monad><hlopt|) -\<gtr\> ><hlstd|'a monad><hlendline|>

    <\enumerate>
      <item>Design the signatures for the exception monad operations to use
      the enriched monads with <hlopt|(><hlstd|'s><hlopt|,
      ><hlstd|'a><hlopt|) ><hlstd|monad> type, so that they provide more
      flexibility than our exception monad.

      <item>Does the implementation of the exception monad need to change?
      The same implementation can work with both sets of signatures, but the
      implementation given in lecture needs a very slight change. Can you
      find it without implementing? If not, the lecture script provides
      <hlkwd|RMONAD>, <hlkwd|RMONAD_OPS>, <hlkwd|RMonadOps> and
      <hlkwd|RMonad>, so you can implement and see for yourself -- copy
      <hlkwd|ExceptionM> and modify:<next-line><hlkwa|module
      ><hlkwd|ExceptionRM ><hlopt|: ><hlkwa|sig><hlendline|><next-line><hlstd|
      \ ><hlkwa|type ><hlopt|(><hlstd|'e><hlopt|, ><hlstd|'a><hlopt|)
      ><hlstd|t ><hlopt|= >KEEP/TODO<hlstd|<hlendline|><next-line>
      \ ><hlkwa|include ><hlkwd|RMONAD<textunderscore>OPS><hlendline|><next-line><hlstd|
      \ ><hlkwa|val ><hlstd|run ><hlopt|: (><hlstd|'e><hlopt|,
      ><hlstd|'a><hlopt|) ><hlstd|monad ><hlopt|-\<gtr\> (><hlstd|'e><hlopt|,
      ><hlstd|'a><hlopt|) ><hlstd|t<hlendline|><next-line> \ ><hlkwa|val
      ><hlstd|throw ><hlopt|: >TODO<hlstd|<hlendline|><next-line>
      \ ><hlkwa|val ><hlstd|catch ><hlopt|:
      >TODO<hlendline|><next-line><hlkwa|end ><hlopt|=
      ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|module
      ><hlkwd|M ><hlopt|= ><hlkwa|struct><hlendline|><next-line><hlstd|
      \ \ \ ><hlkwa|type ><hlopt|(><hlstd|'e><hlopt|, ><hlstd|'a><hlopt|)
      ><hlstd|t ><hlopt|= >KEEP/TODO<hlstd|<hlendline|><next-line>
      \ \ \ ><hlkwa|let ><hlstd|return a ><hlopt|= ><hlkwd|OK
      ><hlstd|a<hlendline|><next-line> \ \ \ ><hlkwa|let ><hlstd|bind m b
      ><hlopt|= >KEEP/TODO<hlstd|<hlendline|><next-line>
      \ ><hlkwa|end><hlendline|><next-line><hlstd| \ ><hlkwa|include
      ><hlkwd|M><hlendline|><next-line><hlstd| \ ><hlkwa|include
      ><hlkwd|RMonadOps><hlopt|(><hlkwd|M><hlopt|)><hlendline|><next-line><hlstd|
      \ ><hlkwa|let ><hlstd|throw e ><hlopt|=
      >KEEP/TODO<hlstd|<hlendline|><next-line> \ ><hlkwa|let ><hlstd|catch m
      handler ><hlopt|= >KEEP/TODO<hlendline|><next-line><hlkwa|end><hlstd|
      \ \ \ ><hlendline|>
    </enumerate>
  </exercise>

  <\exercise>
    \ Implement the following constructs for <em|all> monads:

    <\enumerate>
      <item><hlkwa|for>...<hlkwa|to>...

      <item><hlkwa|for>...<hlkwa|downto>...

      <item><hlkwa|while>...<hlkwa|do>...

      <item><hlkwa|do>...<hlkwa|while>...

      <item><hlkwa|repeat>...<hlkwa|until>...
    </enumerate>

    Explain how, when your implementation is instantiated with the
    <hlkwd|StateM> monad, we get the solution to exercise 2 from lecture 4.
  </exercise>

  <\exercise>
    A canonical example of a probabilistic model is that of a lawn whose
    grass may be wet because it rained, because the sprinkler was on, or for
    some other reason. Oleg Kiselyov builds on this example with variables
    <verbatim|rain>, <verbatim|sprinkler>, and <verbatim|wet_grass>, by
    adding variables <verbatim|cloudy> and <verbatim|wet_roof>. The
    probability tables are:

    <\eqnarray*>
      <tformat|<table|<row|<cell|P<around*|(|cloudy|)>>|<cell|=>|<cell|0.5>>|<row|<cell|P<around*|(|rain\|cloudy|)>>|<cell|=>|<cell|0.8>>|<row|<cell|P<around*|(|rain\|not
      cloudy|)>>|<cell|=>|<cell|0.2>>|<row|<cell|P<around*|(|sprinkler\|cloudy|)>>|<cell|=>|<cell|0.1>>|<row|<cell|P<around*|(|sprinkler\|not
      cloudy|)>>|<cell|=>|<cell|0.5>>|<row|<cell|P<around*|(|wet roof\|not
      rain|)>>|<cell|=>|<cell|0>>|<row|<cell|P<around*|(|wet
      roof\|rain|)>>|<cell|=>|<cell|0.7>>|<row|<cell|P<around*|(|wet
      grass\|rain\<wedge\>not sprinkler|)>>|<cell|=>|<cell|0.9>>|<row|<cell|P<around*|(|wet
      grass\|sprinkler\<wedge\>not rain|)>>|<cell|=>|<cell|0.9>>>>
    </eqnarray*>

    We observe whether the grass is wet and whether the roof is wet. What is
    the probability that it rained?
  </exercise>

  <\exercise>
    Implement the coarse-grained concurrency model.

    <\itemize>
      <item>Modify <verbatim|bind> to compute the resulting monad straight
      away if the input monad has returned.

      <item>Introduce <verbatim|suspend> to do what in the fine-grained model
      was the effect of <verbatim|bind (return a) b>, i.e. suspend the work
      although it could already be started.

      <item>One possibility is to introduce <verbatim|suspend> of type
      <hlkwb|unit ><hlstd|monad>, introduce a ``dummy'' monadic value
      <verbatim|Suspend> (besides <verbatim|Return> and <verbatim|Sleep>),
      and define <verbatim|bind suspend b> to do what <verbatim|bind (return
      ()) b> would formerly do.
    </itemize>
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
    <associate|TreeM|<tuple|4|?>>
    <associate|auto-1|<tuple|1|?>>
  </collection>
</references>