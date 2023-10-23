<TeXmacs|1.0.7.15>

<style|<tuple|beamer|smileys|highlight>>

<\body>
  <screens|<\hidden>
    <doc-data|<doc-title|Functional Programming>|<\doc-author-data|<author-name|Šukasz
    Stafiniak>>
      \;
    </doc-author-data|<author-email|lukstafi@gmail.com,
    lukstafi@ii.uni.wroc.pl>|<author-homepage|www.ii.uni.wroc.pl/~lukstafi>>>

    <doc-data|<doc-title|Lecture 1: Logic>|<\doc-subtitle>
      From logic rules to programming constructs
    </doc-subtitle>|>

    \;
  </hidden>|<\hidden>
    <section|In the Beginning there was Logos>

    What logical connectives do you know?

    <block|<tformat|<cwith|3|3|1|1|cell-halign|c>|<cwith|1|1|2|2|cell-halign|c>|<cwith|1|1|1|1|cell-halign|c>|<cwith|1|1|3|3|cell-halign|c>|<cwith|1|1|4|4|cell-halign|c>|<table|<row|<cell|<math|\<top\>>>|<cell|<math|\<bot\>>>|<cell|<math|\<wedge\>>>|<cell|<math|\<vee\>>>|<cell|<math|\<rightarrow\>>>>|<row|<cell|>|<cell|>|<cell|<math|a\<wedge\>b>>|<cell|<math|a\<vee\>b>>|<cell|<math|a\<rightarrow\>b>>>|<row|<cell|truth>|<cell|falsehood>|<cell|conjunction>|<cell|disjunction>|<cell|implication>>|<row|<cell|``trivial''>|<cell|``impossible''>|<cell|<math|a>
    and <math|b>>|<cell|<math|a> or <math|b>>|<cell|<math|a> gives
    <math|b>>>|<row|<cell|>|<cell|shouldn't get>|<cell|got both>|<cell|got
    <very-small|at least >one>|<cell|given <math|a>, we get <math|b>>>>>>

    How can we define them?
  </hidden>|<\hidden>
    Think in terms of <em|derivation trees>:

    <\equation*>
      <frac|<tabular|<tformat|<table|<row|<cell|<frac|<tabular|<tformat|<table|<row|<cell|<frac||<with|mode|text|a
      premise>>>|<cell|<frac||<with|mode|text|another
      premise>>>>>>>|<with|mode|text|some
      fact>>>|<cell|<frac|<frac||<with|mode|text|this we have by
      default>>|<with|mode|text|another fact>>>>>>>|<with|mode|text|final
      conclusion>>
    </equation*>

    Define by providing rules for using the connectives: for example, a rule
    <math|<frac|<tabular|<tformat|<table|<row|<cell|a>|<cell|b>>>>>|c>>
    matches parts of the tree that have two premises, represented by
    variables <math|a> and <math|b>, and have any conclusion, represented by
    variable <math|c>.

    Try to use only the connective you define in its definition.
  </hidden>|<\hidden>
    <section|Rules for Logical Connectives>

    Introduction rules say how to produce a connective.

    Elimination rules say how to use it.

    Text in parentheses is comments. Letters are variables: stand for
    anything.

    <block|<tformat|<cwith|1|1|2|2|cell-halign|l>|<cwith|2|2|2|2|cell-halign|c>|<cwith|3|3|3|3|cell-halign|c>|<cwith|4|4|2|2|cell-halign|c>|<cwith|5|5|3|3|cell-halign|c>|<cwith|6|6|2|2|cell-halign|c>|<cwith|6|6|3|3|cell-halign|c>|<table|<row|<cell|>|<cell|Introduction
    Rules>|<cell|Elimination Rules>>|<row|<cell|<math|\<top\>>>|<cell|<math|<frac||<tabular|<tformat|<cwith|1|1|2|2|cell-halign|c>|<table|<row|<cell|>|<cell|\<top\>>|<cell|>>>>>>>>|<cell|doesn't
    have>>|<row|<cell|<math|\<bot\>>>|<cell|doesn't
    have>|<cell|<math|<frac|<tabular|<tformat|<table|<row|<cell|>|<cell|\<bot\>>|<cell|>>>>>|a>>
    <very-small|(i.e., anything)>>>|<row|<cell|<math|\<wedge\>>>|<cell|<math|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|a>|<cell|b>>>>>|a\<wedge\>b>>>|<cell|<tabular|<tformat|<table|<row|<cell|<math|<frac|a\<wedge\>b|a>><very-small|
    (take first)>>|<cell|<math|<frac|a\<wedge\>b|b>><very-small| (take
    second)>>>>>>>>|<row|<cell|<math|\<vee\>>>|<cell|<tabular|<tformat|<table|<row|<cell|<math|<frac|a|a\<vee\>b>><very-small|
    (put first)>>|<cell|<math|<frac|b|a\<vee\>b>><very-small| (put
    second)>>>>>>>|<cell|<math|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|r>|<cwith|1|1|1|1|cell-valign|b>|<cwith|1|1|2|2|cell-halign|r>|<table|<row|<cell|a\<vee\>b>|<cell|<tree|<frac||a>|c><very-small|x><with|mode|text|
    (consider >a<with|mode|text|)>>|<cell|<tree|<frac||b>|c><very-small|y><with|mode|text|
    (consider >b<with|mode|text|)>>>>>>|c<with|mode|text| <small|(since in
    both cases we get it)>>>><very-small|using
    <math|x,y>>>>|<row|<cell|<math|\<rightarrow\>>>|<cell|<math|<frac|<tree|<frac||a>|b><very-small|x>|a\<rightarrow\>b>><very-small|
    using <math|x>>>|<cell|<math|<frac|<tabular|<tformat|<table|<row|<cell|a\<rightarrow\>b>|<cell|a>>>>>|b>>>>>>>
  </hidden>|<\shown>
    Notations

    <\equation*>
      <tree|<frac||a>|b><very-small|x><with|mode|text|, \ \ or
      \ \ ><tree|<frac||a>|c><very-small|x>
    </equation*>

    match any subtree that derives <math|b> (or <math|c>) and can use
    <math|a> (by assumption <math|<frac||a><very-small|x>>) although
    otherwise <math|a> might not be warranted. For example:

    <\equation*>
      <frac|<frac|<frac|<frac|<frac||<with|mode|text|sunny>><small|x>|<with|mode|text|go
      outdoor>>|<with|mode|text|playing>>|<with|mode|text|happy>>|<with|mode|text|sunny>\<rightarrow\><with|mode|text|happy>><small|<with|mode|text|
      using >x>
    </equation*>

    Such assumption can only be used in the matched subtree! But it can be
    used several times, e.g. if someone's mood is more difficult to
    influence:

    <\equation*>
      <frac|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|<frac|<frac|<frac||<with|mode|text|sunny>><small|x>|<with|mode|text|go
      outdoor>>|<with|mode|text|playing>>>|<cell|<frac|<tabular|<tformat|<table|<row|<cell|<frac||<with|mode|text|sunny>><small|x>>|<cell|<frac|<frac||<with|mode|text|sunny>><small|x>|<with|mode|text|go
      outdoor>>>>>>>|<with|mode|text|nice
      view>>>>>>>|<with|mode|text|happy>>|<with|mode|text|sunny>\<rightarrow\><with|mode|text|happy>><small|<with|mode|text|
      using >x>
    </equation*>
  </shown>|<\hidden>
    Elimination rule for disjunction represents <strong|reasoning by cases>.

    How can we use the fact that it is sunny<math|\<vee\>>cloudy (but not
    rainy)?

    <\equation*>
      <frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|r>|<cwith|1|1|1|1|cell-valign|b>|<cwith|1|1|2|2|cell-halign|r>|<table|<row|<cell|<frac||<with|mode|text|sunny>\<vee\><with|mode|text|cloudy>><very-small|<with|mode|text|
      forecast>>>|<cell|<frac|<frac||<with|mode|text|sunny>><very-small|x>|<with|mode|text|no-umbrella>>>|<cell|<frac|<frac||<with|mode|text|cloudy>><very-small|y>|<with|mode|text|no-umbrella>>>>>>>|<with|mode|text|no-umbrella>><small|<with|mode|text|
      using >x,y>
    </equation*>

    We know that it will be sunny or cloudy, by watching weather forecast. If
    it will be sunny, we won't need an umbrella. If it will be cloudy, we
    won't need an umbrella. Therefore, won't need an umbrella.
  </hidden>|<\hidden>
    We need one more kind of rules to do serious math: <strong|reasoning by
    induction> (it is somewhat similar to reasoning by cases). Example rule
    for induction on natural numbers:

    <\equation*>
      <frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|r>|<cwith|1|1|1|1|cell-valign|b>|<cwith|1|1|2|2|cell-halign|r>|<table|<row|<cell|p<around*|(|0|)>>|<cell|<tree|<frac||p<around*|(|x|)>><small|x>|p<around*|(|x+1|)>>>>>>>|p<around*|(|n|)>><with|mode|text|
      by induction, using >x
    </equation*>

    So we get any <math|p> for any natural number <math|n>, provided we can
    get it for <math|0>, and using it for <math|x> we can derive it for the
    successor <math|x+1>, where <math|x> is a unique variable (we cannot
    substitute for it some particular number, because we write ``using
    <math|x>'' on the side).
  </hidden>|<\hidden>
    <section|Logos was Programmed in OCaml>

    <block|<tformat|<cwith|1|1|4|4|cell-halign|l>|<cwith|2|2|4|4|cell-halign|c>|<cwith|3|3|5|5|cell-halign|c>|<cwith|4|4|4|4|cell-halign|c>|<cwith|5|5|5|5|cell-halign|c>|<cwith|6|6|4|4|cell-halign|c>|<cwith|6|6|5|5|cell-halign|c>|<cwith|7|7|5|5|cell-halign|c>|<cwith|5|5|2|2|cell-halign|l>|<cwith|7|7|5|5|cell-lborder|invisible>|<cwith|7|7|5|5|cell-col-span|2-3>|<cwith|7|7|4|4|cell-halign|c>|<cwith|7|7|4|4|cell-col-span|2>|<cwith|7|7|1|1|cell-col-span|2>|<table|<row|<cell|Logic>|<cell|Type>|<cell|Expr.>|<cell|Introduction
    Rules>|<cell|Elimination Rules>>|<row|<cell|<math|\<top\>>>|<cell|<verbatim|unit>>|<cell|<verbatim|()>>|<cell|<math|<frac||<tabular|<tformat|<cwith|1|1|2|2|cell-halign|c>|<table|<row|<cell|>|<cell|<with|mode|text|<verbatim|()>>:<with|mode|text|<verbatim|unit>>>|<cell|>>>>>>>>|<cell|>>|<row|<cell|<math|\<bot\>>>|<cell|<verbatim|'a>>|<cell|<verbatim|raise>>|<cell|>|<cell|<math|<frac|<with|mode|text|oops!>|<with|mode|text|<verbatim|raise
    Not_found>>:c>>>>|<row|<cell|<math|\<wedge\>>>|<cell|<verbatim|*>>|<cell|<verbatim|(,)>>|<cell|<math|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|s:a>|<cell|t:b>>>>>|s<with|mode|text|<verbatim|,>>t:a<with|mode|text|<verbatim|*>>b>>>|<cell|<tabular|<tformat|<table|<row|<cell|<math|<frac|p:a<with|mode|text|<verbatim|*>>b|<with|mode|text|<verbatim|fst>
    >p:a>>>|<cell|<math|<frac|p:a<with|mode|text|<verbatim|*>>b|<with|mode|text|<verbatim|snd>
    >p:b>>>>>>>>>|<row|<cell|<math|\<vee\>>>|<cell|<verbatim|\|>>|<cell|<verbatim|match>>|<cell|<tabular|<tformat|<cwith|1|1|1|1|cell-valign|c>|<table|<row|<cell|<math|<frac|s:a|A<around*|(|s|)>:A<with|mode|text|
    <verbatim|of> >a<with|mode|text|<verbatim|\|<math|B<with|mode|text|
    <verbatim|of> >>>>b>>>>|<row|<cell|<very-small|(need to name
    sides)>>>|<row|<cell|<math|<frac|t:b|B<around*|(|t|)>:A<with|mode|text|
    <verbatim|of> >a<with|mode|text|<verbatim|\|<math|B<with|mode|text|
    <verbatim|of> >>>>b>>>>>>>>|<cell|<tabular|<tformat|<cwith|2|2|1|1|cell-halign|r>|<table|<row|<cell|<math|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|r>|<cwith|1|1|1|1|cell-valign|b>|<cwith|1|1|2|2|cell-halign|r>|<table|<row|<cell|t:A<with|mode|text|
    <verbatim|of> >a<with|mode|text|<verbatim|\|<math|B<with|mode|text|
    <verbatim|of> >>>>b>|<cell|<tree|<frac||x:a>|e<rsub|1>:c><very-small|x>>|<cell|<tree|<frac||y:b>|e<rsub|2>:c><very-small|y>>>>>>|<with|mode|text|<verbatim|match>
    >t<with|mode|text| <verbatim|with> >A<around*|(|x|)><with|mode|text|<verbatim|-\<gtr\>>>e<rsub|1><with|mode|text|
    <verbatim|\|> >B<around*|(|y|)><with|mode|text|<verbatim|-\<gtr\>>>e<rsub|2>:c>>>>|<row|<cell|<very-small|variables
    <math|x,y>>>>>>>>>|<row|<cell|<math|\<rightarrow\>>>|<cell|<verbatim|-\<gtr\>>>|<cell|<verbatim|fun>>|<cell|<math|<frac|<tree|<frac||x:a>|e:b><very-small|x>|<with|mode|text|<verbatim|fun>
    >x<with|mode|text|<verbatim|-\<gtr\>>>e:a\<rightarrow\>b>><very-small|
    var <math|x>>>|<cell|<math|<frac|<tabular|<tformat|<table|<row|<cell|f:a\<rightarrow\>b>|<cell|t:a>>>>>|f
    t:b>> <small|(application)>>>|<row|<cell|induction>|<cell|>|<cell|<verbatim|rec>>|<cell|<math|<frac|<tree|<frac||x:a>|e:a><very-small|x>|<with|mode|text|<verbatim|rec>
    >x<with|mode|text|<verbatim|=>>e:a>><very-small| variable
    <math|x>>>|<cell|>>>>>
  </hidden>|<\hidden>
    <subsection|Definitions>

    Writing out expressions and types repetitively is tedious: we need
    defini<no-break>tions. <strong|Definitions for types> are written:
    <verbatim|type ty = >some type.

    <\itemize>
      <item>Writing <math|A<around*|(|s|)>:A<with|mode|text| <verbatim|of>
      >a<with|mode|text|<verbatim|\|<math|B<with|mode|text| <verbatim|of>
      >>>>b> in the table was cheating. Usually we have to define the type
      and then use it, e.g. using <verbatim|int> for <math|a> and
      <verbatim|string> for <math|b>:<next-line> <verbatim|type
      int_string_choice = A of int \| B of string><next-line>allows us to
      write <math|A<around*|(|s|)>:<with|mode|text|<verbatim|int_string_choice>>>.

      <item>Without the type definition, it is difficult to know what other
      variants there are when one <em|infers> (i.e. ``guesses'', computes)
      the type!

      <item>In OCaml we can write <math|<lprime|`>A<around*|(|s|)>:<around*|[|<lprime|`>A<with|mode|text|
      <verbatim|of> >a<with|mode|text|<verbatim|\|<math|<lprime|`>B<with|mode|text|
      <verbatim|of> >>>>b|]>>. With ``<math|<lprime|`>>'' variants, OCaml
      does guess what other variants are. These types are fun, but we will
      not use them in future lectures.<new-page>

      <item>Tuple elements don't need labels because we always know at which
      position a tuple element stands. But having labels makes code more
      clear, so we can define a <em|record type>:

      <\code>
        type int_string_record = {a: int; b: string}
      </code>

      and create its values: <verbatim|{a = 7; b = "Mary"}>.

      <item>We access the <em|fields> of records using the dot notation:

      <verbatim|{a=7; b="Mary"}.b = "Mary">.
    </itemize>
  </hidden>|<\hidden>
    Recursive expression <math|<with|mode|text|<verbatim|rec>
    >x<with|mode|text|<verbatim|=>>e> in the table was cheating:
    <verbatim|rec> (usually called <verbatim|fix>) cannot appear alone in
    OCaml! It must be part of a definition.

    <strong|Definitions for expressions> are introduced by rules a bit more
    complex than these:

    <\equation*>
      <frac|<tabular|<tformat|<cwith|1|1|1|1|cell-valign|b>|<table|<row|<cell|e<rsub|1>:a>|<cell|<tree|<frac||x:a>|e<rsub|2>:b><very-small|x>>>>>>|<with|mode|text|<verbatim|let>
      >x<with|mode|text|<verbatim|=>>e<rsub|1><with|mode|text| <verbatim|in>
      >e<rsub|2>:b>
    </equation*>

    (note that this rule is the same as introducing and eliminating
    <math|\<rightarrow\>>), and:

    <\equation*>
      <frac|<tabular|<tformat|<cwith|1|1|1|1|cell-valign|b>|<table|<row|<cell|<tree|<frac||x:a>|e<rsub|1>:a><very-small|x>>|<cell|<tree|<frac||x:a>|e<rsub|2>:b><very-small|x>>>>>>|<with|mode|text|<verbatim|let
      rec> >x<with|mode|text|<verbatim|=>>e<rsub|1><with|mode|text|
      <verbatim|in> >e<rsub|2>:b>
    </equation*>

    We will cover what is missing in above rules when we will talk about
    <strong|poly<no-break>morphism.>
  </hidden>|<\hidden>
    <\itemize>
      <item>Type definitions we have seen above are <em|global>: they need to
      be at the top-level, not nested in expressions, and they extend from
      the point they occur till the end of the source file or interactive
      session.

      <item><verbatim|let>-<verbatim|in> definitions for expressions:
      <math|<with|mode|text|<verbatim|let>
      >x<with|mode|text|<verbatim|=>>e<rsub|1><with|mode|text| <verbatim|in>
      >e<rsub|2>> are <em|local>, <math|x> is only visible in
      <math|e<rsub|2>>. But <verbatim|let> definitions are global: placing
      <math|<with|mode|text|<verbatim|let>
      >x<with|mode|text|<verbatim|=>>e<rsub|1>> at the top-level makes
      <math|x> visible from after <math|e<rsub|1>> till the end of the source
      file or interactive session.

      <item>In the interactive session, we mark an end of a top-level
      ``sentence'' by <verbatim|;;> -- it is unnecessary in source files.

      <item>Operators like <verbatim|+>, <verbatim|*>, <verbatim|\<less\>>,
      <verbatim|=>, are names of functions. Just like other names, you can
      use operator names for your own functions:

      <hlkwa|let ><hlopt|(+:) ><hlstd|a b ><hlopt|=
      ><hlkwc|String><hlopt|.><hlstd|concat ><hlstr|""><hlstd|
      ><hlopt|[><hlstd|a><hlopt|; ><hlstd|b><hlopt|];;><hlendline|Special way
      of defining><next-line><hlstr|"Alpha"><hlstd| ><hlopt|+:
      ><hlstr|"Beta"><hlopt|;;><hlendline|but normal way of using operators.>

      <item>Operators in OCaml are <strong|not overloaded>. It means, that
      every type needs its own set of operators. For example, <hlopt|+>,
      <hlopt|*>, <hlopt|/> work for intigers, while <hlopt|+.>, <hlopt|*.>,
      <hlopt|/.> work for floating point numbers. <strong|Exception:>
      comparisons <hlopt|\<less\>>, <hlopt|=>, etc. work for all values other
      than functions.
    </itemize>
  </hidden>|<\hidden>
    <section|Exercises>

    Exercises from <em|Think OCaml. How to Think Like a Computer Scientist>
    by Nicholas Monje and Allen Downey.

    <\enumerate>
      <item>Assume that we execute the following assignment statements:

      <hlstd|><hlkwa|let ><hlstd|width ><hlopt|=
      ><hlstd|><hlnum|17><hlstd|><hlopt|;;><hlendline|><next-line><hlstd|><hlkwa|let
      ><hlstd|height ><hlopt|= ><hlstd|><hlnum|12.0><hlstd|><hlopt|;;><hlendline|><next-line><hlstd|><hlkwa|let
      ><hlstd|delimiter ><hlopt|= ><hlstd|><hlstr|'.'><hlstd|><hlopt|;;><hlstd|><hlendline|>

      For each of the following expressions, write the value of the
      expression and the type (of the value of the expression), or the
      resulting type error.

      <\enumerate>
        <item><hlstd|width><hlopt|/><hlnum|2>

        <item><hlstd|width><hlopt|/><hlnum|.2.0>

        <item><hlstd|height><hlopt|/><hlnum|3>

        <item><hlnum|1 ><hlopt|+ ><hlnum|2 ><hlopt|* ><hlnum|5>

        <item><hlstd|delimiter ><hlopt|* ><hlnum|5>
      </enumerate>

      <item>Practice using the OCaml interpreter as a calculator:

      <\enumerate>
        <item>The volume of a sphere with radius <math|r> is
        <math|<frac|4|3>\<pi\>r<rsup|3>>. What is the volume of a sphere with
        radius 5?

        Hint: 392.6 is wrong!

        <item>Suppose the cover price of a book is $24.95, but bookstores get
        a 40% discount. Shipping costs $3 for the first copy and 75 cents for
        each additional copy. What is the total wholesale cost for 60 copies?

        <item>If I leave my house at 6:52 am and run 1 mile at an easy pace
        (8:15 per mile), then 3 miles at tempo (7:12 per mile) and 1 mile at
        easy pace again, what time do I get home for breakfast?
      </enumerate>

      <new-page*><item>You've probably heard of the fibonacci numbers before,
      but in case you haven't, they're defined by the following recursive
      relationship:

      <\equation*>
        <choice|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|f<around*|(|0|)>>|<cell|=>|<cell|0>|<cell|>>|<row|<cell|f<around*|(|1|)>>|<cell|=>|<cell|1>|<cell|>>|<row|<cell|f<around*|(|n+1|)>>|<cell|=>|<cell|f<around*|(|n|)>+f<around*|(|n-1|)>>|<cell|<with|mode|text|for
        >n=2,3,\<ldots\>>>>>>
      </equation*>

      Write a recursive function to calculate these numbers.

      <new-page*><item>A palindrome is a word that is spelled the same
      backward and forward, like \Pnoon\Q and \Predivider\Q. Recursively, a
      word is a palindrome if the first and last letters are the same and the
      middle is a palindrome.

      The following are functions that take a string argument and return the
      first, last, and middle letters:

      <hlkwa|let ><hlstd|first<textunderscore>char ><hlkwb|word ><hlopt|=
      ><hlkwb|word><hlopt|.[><hlnum|0><hlopt|];;><hlendline|><next-line><hlkwa|let
      ><hlstd|last<textunderscore>char ><hlkwb|word
      ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|len
      ><hlopt|= ><hlkwc|String><hlopt|.><hlstd|length ><hlkwb|word ><hlopt|-
      ><hlnum|1 ><hlkwa|in><hlendline|><next-line><hlstd|
      \ ><hlkwb|word><hlopt|.[><hlstd|len><hlopt|];;><hlendline|><next-line><hlkwa|let
      ><hlstd|middle ><hlkwb|word ><hlopt|=><hlendline|><next-line><hlstd|
      \ ><hlkwa|let ><hlstd|len ><hlopt|=
      ><hlkwc|String><hlopt|.><hlstd|length ><hlkwb|word ><hlopt|- ><hlnum|2
      ><hlkwa|in><hlendline|><next-line><hlstd|
      \ ><hlkwc|String><hlopt|.><hlstd|sub ><hlkwb|word ><hlnum|1
      ><hlstd|len><hlopt|;;><hlendline|>

      <\enumerate>
        <item>Enter these functions into the toplevel and test them out. What
        happens if you call middle with a string with two letters? One
        letter? What about the empty string, which is written <hlstr|"">?

        <item>Write a function called is_palindrome that takes a string
        argument and returns <hlkwa|true> if it is a palindrome and
        <hlkwa|false> otherwise.
      </enumerate>

      <item>The greatest common divisor (GCD) of <math|a> and <math|b> is the
      largest number that divides both of them with no remainder.

      One way to find the GCD of two numbers is Euclid's algorithm, which is
      based on the observation that if <math|r> is the remainder when
      <math|a> is divided by <math|b>, then <math|gcd(a, b) = gcd(b, r)>. As
      a base case, we can consider <math|gcd(a, 0) = a>.

      Write a function called gcd that takes parameters a and b and returns
      their greatest common divisor.

      If you need help, see <hlink|http://en.wikipedia.org/wiki/Euclidean_algorithm|http://en.wikipedia.org/wiki/Euclidean_algorithm>.
    </enumerate>
  </hidden>>
</body>

<\initial>
  <\collection>
    <associate|language|american>
    <associate|magnification|2>
    <associate|page-medium|papyrus>
    <associate|page-orientation|landscape>
    <associate|page-type|letter>
    <associate|par-hyphen|normal>
  </collection>
</initial>

<\references>
  <\collection>
    <associate|auto-1|<tuple|1|1>>
    <associate|auto-10|<tuple|5.0.4|22>>
    <associate|auto-11|<tuple|4|27>>
    <associate|auto-12|<tuple|4|28>>
    <associate|auto-13|<tuple|5|32>>
    <associate|auto-14|<tuple|5|33>>
    <associate|auto-15|<tuple|6|34>>
    <associate|auto-16|<tuple|7|36>>
    <associate|auto-17|<tuple|8|38>>
    <associate|auto-18|<tuple|9|39>>
    <associate|auto-19|<tuple|10.0.1|40>>
    <associate|auto-2|<tuple|2|2>>
    <associate|auto-20|<tuple|11|42>>
    <associate|auto-21|<tuple|12|45>>
    <associate|auto-22|<tuple|12|48>>
    <associate|auto-23|<tuple|12|51>>
    <associate|auto-24|<tuple|12|53>>
    <associate|auto-25|<tuple|13|55>>
    <associate|auto-3|<tuple|3|7>>
    <associate|auto-4|<tuple|3.1|9>>
    <associate|auto-5|<tuple|4|13>>
    <associate|auto-6|<tuple|3|14>>
    <associate|auto-7|<tuple|4|15>>
    <associate|auto-8|<tuple|4.0.3|16>>
    <associate|auto-9|<tuple|4.0.4|17>>
    <associate|ch02fn03|<tuple|3.0.8|?>>
    <associate|ch02index14|<tuple|2.1|6>>
    <associate|ch02index20|<tuple|2.1.1|7>>
    <associate|ch02index21|<tuple|2.1.1|8>>
    <associate|ch02index23|<tuple|2.1.2|9>>
    <associate|ch02index25|<tuple|2.1.3|11>>
    <associate|ch02index34|<tuple|<with|mode|<quote|math>|\<bullet\>>|13>>
    <associate|ch02index35|<tuple|<with|mode|<quote|math>|\<bullet\>>|14>>
    <associate|ch02index36|<tuple|3.0.6|15>>
    <associate|ch02index37|<tuple|3.0.6|16>>
    <associate|ch02index38|<tuple|3.0.6|16>>
    <associate|ch02index39|<tuple|3.0.6|17>>
    <associate|ch02index49|<tuple|3.0.7|18>>
    <associate|ch03index07|<tuple|1|3>>
    <associate|ch03index08|<tuple|?|3>>
    <associate|ch03index15|<tuple|<with|mode|<quote|math>|\<bullet\>>|?>>
    <associate|ch03index16|<tuple|<with|mode|<quote|math>|\<bullet\>>|?>>
    <associate|ch03index19|<tuple|?|10>>
    <associate|ch03index20|<tuple|?|11>>
    <associate|ch03index24|<tuple|1|14>>
    <associate|ch03index26|<tuple|<with|mode|<quote|math>|\<bullet\>>|16>>
    <associate|ch03index30|<tuple|<with|mode|<quote|math>|\<bullet\>>|17>>
    <associate|ch03index31|<tuple|?|18>>
    <associate|ch03index38|<tuple|?|22>>
    <associate|ch03index39|<tuple|<with|mode|<quote|math>|\<bullet\>>|?>>
    <associate|ch03index44|<tuple|?|26>>
    <associate|ch05index06|<tuple|<with|mode|<quote|math>|<rigid|\<circ\>>>|?>>
    <associate|ch05index07|<tuple|<with|mode|<quote|math>|\<bullet\>>|?>>
    <associate|ch05index09|<tuple|12.0.1|?>>
    <associate|ch19index03|<tuple|5|?>>
    <associate|ch19index04|<tuple|<with|mode|<quote|math>|\<bullet\>>|?>>
    <associate|page100|<tuple|6|?>>
    <associate|page79|<tuple|4|?>>
  </collection>
</references>

<\auxiliary>
  <\collection>
    <\associate|toc>
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|In
      the Beginning there was Logos> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Rules
      for Logical Connectives> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Logos
      was Programmed in OCaml> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|Definitions
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Exercises>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5><vspace|0.5fn>
    </associate>
  </collection>
</auxiliary>