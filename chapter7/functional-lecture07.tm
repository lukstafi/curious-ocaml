<TeXmacs|1.0.7.16>

<style|<tuple|beamer|highlight|beamer-metal-lighter>>

<\body>
  <doc-data|<doc-title|Functional Programming>|<\doc-author-data|<author-name|Šukasz
  Stafiniak>>
    \;
  </doc-author-data|<author-email|lukstafi@gmail.com,
  lukstafi@ii.uni.wroc.pl>|<\author-homepage>
    www.ii.uni.wroc.pl/~lukstafi
  </author-homepage>>>

  <doc-data|<doc-title|Lecture 7: Laziness>|<\doc-subtitle>
    Lazy evaluation. Stream processing.

    <\small>
      M. Douglas McIlroy <em|``Power Series, Power Serious''>

      Oleg Kiselyov, Simon Peyton-Jones, Amr Sabry<next-line> <em|``Lazy v.
      Yield: Incremental, Linear Pretty-Printing''>
    </small>
  </doc-subtitle>|>

  <center|If you see any error on the slides, let me know!>

  <new-page>

  <section|<new-page*>Laziness>

  <\itemize>
    <item>Today's lecture is about lazy evaluation.

    <item>Thank you for coming, goodbye!

    <item>But perhaps, do you have any questions?
  </itemize>

  <section|<new-page*>Evaluation strategies and parameter passing>

  <\itemize>
    <item><strong|Evaluation strategy> is the order in which expressions are
    computed.

    <\itemize>
      <item>For the most part: when are arguments computed.
    </itemize>

    <item>Recall our problems with using <em|flow control> expressions like
    <verbatim|if_then_else> in examples from <math|\<lambda\>>-calculus
    lecture.

    <item>There are many technical terms describing various strategies.
    Wikipedia:

    <\description>
      <item*|Strict evaluation>Arguments are always evaluated completely
      before function is applied.

      <item*|Non-strict evaluation>Arguments are not evaluated unless they
      are actually used in the evaluation of the function body.

      <item*|Eager evaluation>An expression is evaluated as soon as it gets
      bound to a variable.

      <item*|Lazy evaluation>Non-strict evaluation which avoids repeating
      computation.

      <item*|Call-by-value>The argument expression is evaluated, and the
      resulting value is bound to the corresponding variable in the function
      (frequently by copying the value into a new memory region).

      <item*|Call-by-reference>A function receives an implicit reference to a
      variable used as argument, rather than a copy of its value.

      <\itemize>
        <item>In purely functional languages there is no difference between
        the two strategies, so they are typically described as call-by-value
        even though implementations use call-by-reference internally for
        efficiency.

        <item>Call-by-value languages like C and OCaml support explicit
        references (objects that refer to other objects), and these can be
        used to simulate call-by-reference.
      </itemize>

      <item*|Normal order> Start computing function bodies before evaluating
      their arguments. Do not even wait for arguments if they are not needed.

      <new-page*><item*|Call-by-name>Arguments are substituted directly into
      the function body and then left to be evaluated whenever they appear in
      the function.

      <item*|Call-by-need>If the function argument is evaluated, that value
      is stored for subsequent uses.
    </description>

    <item>Almost all languages do not compute inside the body of un-applied
    func<no-break>tion, but with curried functions you can pre-compute data
    before all arguments are provided.

    <\itemize>
      <item>Recall the <verbatim|search_bible> example.
    </itemize>

    <item>In eager / call-by-value languages we can simulate call-by-name by
    taking a function to compute the value as an argument <small|instead of
    the value directly>.

    <\itemize>
      <item>''Our'' languages have a <verbatim|unit> type with a single value
      <verbatim|()> specifically for use as throw-away arguments.

      <item>Scala has a built-in support for call-by-name (i.e. direct,
      without the need to build argument functions).
    </itemize>

    <item>ML languages have built-in support for lazy evaluation.

    <item>Haskell has built-in support for eager evaluation.
  </itemize>

  <section|<new-page*>Call-by-name: streams>

  <\itemize>
    <item>Call-by-name is useful not only for implementing flow control

    <\itemize>
      <item><hlkwa|let ><hlstd|if<textunderscore>then<textunderscore>else
      cond e1 e2 ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match
      ><hlstd|cond ><hlkwa|with true ><hlopt|-\<gtr\> ><hlstd|e1 ><hlopt|()
      \| ><hlkwa|false ><hlopt|-\<gtr\> ><hlstd|e2 ><hlopt|()><hlendline|>
    </itemize>

    but also for arguments of value constructors, i.e. for data structures.

    <item><strong|Streams> are lists with call-by-name tails.

    <hlkwa|type ><hlstd|'a stream ><hlopt|= ><hlkwd|SNil ><hlopt|\|
    ><hlkwd|SCons ><hlkwa|of ><hlstd|'a ><hlopt|* (><hlkwb|unit
    ><hlopt|-\<gtr\> ><hlstd|'a stream><hlopt|)>

    <item>Reading from a stream into a list.

    <hlkwa|let rec ><hlstd|stake n ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| <hlopt|\|> ><hlkwd|SCons
    ><hlopt|(><hlstd|a><hlopt|, ><hlstd|s><hlopt|) ><hlkwa|when ><hlstd|n
    ><hlopt|\<gtr\> ><hlnum|0 ><hlopt|-\<gtr\>
    ><hlstd|a><hlopt|::(><hlstd|stake ><hlopt|(><hlstd|n><hlopt|-><hlnum|1><hlopt|)
    (><hlstd|s ><hlopt|()))><hlendline|><next-line><hlstd| <hlopt|\|>
    <textunderscore> ><hlopt|-\<gtr\> []><hlendline|>

    <item>Streams can easily be infinite.

    <hlkwa|let rec ><hlstd|s<textunderscore>ones ><hlopt|= ><hlkwd|SCons
    ><hlopt|(><hlnum|1><hlopt|, ><hlkwa|fun ><hlopt|() -\<gtr\>
    ><hlstd|s<textunderscore>ones><hlopt|)><hlendline|><next-line><hlkwa|let
    rec ><hlstd|s<textunderscore>from n ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwd|SCons ><hlopt|(><hlstd|n><hlopt|, ><hlkwa|fun ><hlopt|()
    -\<gtr\>><hlstd|s<textunderscore>from><hlopt|
    (><hlstd|n><hlopt|+><hlnum|1><hlopt|))><hlendline|>

    <new-page*><item>Streams admit list-like operations.

    <hlkwa|let rec ><hlstd|smap f ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| <hlopt|\|> ><hlkwd|SNil
    ><hlopt|-\<gtr\> ><hlkwd|SNil><hlendline|><next-line><hlstd| <hlopt|\|>
    ><hlkwd|SCons ><hlopt|(><hlstd|a><hlopt|, ><hlstd|s><hlopt|) -\<gtr\>
    ><hlkwd|SCons ><hlopt|(><hlstd|f a><hlopt|, ><hlkwa|fun ><hlopt|()
    -\<gtr\> ><hlstd|smap f ><hlopt|(><hlstd|s
    ><hlopt|()))><hlendline|><next-line><hlkwa|let rec ><hlstd|szip ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| <hlopt|\|>
    ><hlkwd|SNil><hlopt|, ><hlkwd|SNil ><hlopt|-\<gtr\>
    ><hlkwd|SNil><hlendline|><next-line><hlstd| <hlopt|\|> ><hlkwd|SCons
    ><hlopt|(><hlstd|a1><hlopt|, ><hlstd|s1><hlopt|), ><hlkwd|SCons
    ><hlopt|(><hlstd|a2><hlopt|, ><hlstd|s2><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ ><hlkwd|SCons
    ><hlopt|((><hlstd|a1><hlopt|, ><hlstd|a2><hlopt|), ><hlkwa|fun ><hlopt|()
    -\<gtr\> ><hlstd|szip ><hlopt|(><hlstd|s1 ><hlopt|(), ><hlstd|s2
    ><hlopt|()))><hlendline|><next-line><hlstd| <hlopt|\|> <textunderscore>
    ><hlopt|-\<gtr\> ><hlstd|raise ><hlopt|(><hlkwd|Invalid<textunderscore>argument
    ><hlstr|"szip"><hlopt|)><hlendline|>

    <item>Streams can provide scaffolding for recursive algorithms:

    <hlkwa|let rec ><hlstd|sfib ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwd|SCons ><hlopt|(><hlnum|1><hlopt|, ><hlkwa|fun ><hlopt|()
    -\<gtr\> ><hlstd|smap ><hlopt|(><hlkwa|fun
    ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|)-\<gtr\>
    ><hlstd|a><hlopt|+><hlstd|b><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|(><hlstd|szip ><hlopt|(><hlstd|sfib><hlopt|, ><hlkwd|SCons
    ><hlopt|(><hlnum|1><hlopt|, ><hlkwa|fun ><hlopt|() -\<gtr\>
    ><hlstd|sfib><hlopt|))))><hlendline|>

    <draw-over|<tabular|<tformat|<table|<row|<cell|<block|<tformat|<cwith|1|1|1|1|cell-halign|c>|<cwith|1|1|2|2|cell-halign|c>|<twith|table-rborder|0>|<cwith|1|1|7|7|cell-rborder|0ln>|<table|<row|<cell|1>|<cell|2>|<cell|3>|<cell|5>|<cell|8>|<cell|13>|<cell|...>>>>>>>|<row|<cell|
    \ \ \ <block|<tformat|<cwith|1|1|1|1|cell-halign|c>|<cwith|1|1|2|2|cell-halign|c>|<twith|table-rborder|0>|<cwith|1|1|7|7|cell-rborder|0ln>|<table|<row|<cell|1>|<cell|2>|<cell|3>|<cell|5>|<cell|8>|<cell|13>|<cell|...>>>>>>>|<row|<cell|
    \ \ <block|<tformat|<table|<row|<cell|1>>>>>
    <block|<tformat|<cwith|1|1|1|1|cell-halign|c>|<cwith|1|1|2|2|cell-halign|c>|<twith|table-rborder|0>|<cwith|1|1|7|7|cell-rborder|0ln>|<table|<row|<cell|1>|<cell|2>|<cell|3>|<cell|5>|<cell|
    8>|<cell|13>|<cell|...>>>>>>>>>>|<with|gr-mode|<tuple|edit|line>|gr-arrow-end|\<gtr\>\<gtr\>|gr-color|dark
    blue|<graphics|<with|color|red|<spline|<point|-3.45314|-0.974534>|<point|-3.85530493451515|-0.297195396216431>|<point|-3.26263394628919|0.020306918904617>>>|<with|color|red|arrow-end|\<gtr\>|<spline|<point|-3.89764|-0.254862>|<point|-3.87647175552322|0.464810160074084>|<point|-3.24146712528112|0.930480222251621>>>|<with|color|red|<spline|<point|-2.33129|-1.0592>|<point|-2.60646249503903|-0.276028575208361>|<point|-2.26779335890991|0.0414737399126869>>>|<with|color|red|<spline|<point|-1.46345|-0.9957>|<point|-1.73862283370816|-0.276028575208361>|<point|-1.44228733959518|0.0626405609207567>>>|<with|color|red|arrow-end|\<gtr\>|<spline|<point|-1.73862|-0.254862>|<point|-2.01379150681307|0.676478370154782>|<point|-1.54812144463553|1.03631432729197>>>|<with|color|red|arrow-end|\<gtr\>|<spline|<point|-2.62763|-0.276029>|<point|-2.79696388411165|0.507143802090224>|<point|-2.37362746395026|1.0151475062839>>>|<with|color|dark
    blue|<text-at|<verbatim|+>|<point|-3.7833|-0.582834>>>|<with|color|dark
    blue|<text-at|<verbatim|+>|<point|-2.55958|-0.567776>>>|<with|color|dark
    blue|<text-at|<verbatim|+>|<point|-1.69025|-0.539064>>>>>>

    <new-page*><item>Streams are less functional than could be expected in
    context of input-output effects.

    <hlkwa|let ><hlstd|file<textunderscore>stream name
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|ch
    ><hlopt|= ><hlstd|open<textunderscore>in name
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let rec
    ><hlstd|ch<textunderscore>read<textunderscore>line ><hlopt|()
    =><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|try ><hlkwd|SCons
    ><hlopt|(><hlstd|input<textunderscore>line ch><hlopt|,
    ><hlstd|ch<textunderscore>read<textunderscore>line><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|with ><hlkwd|End<textunderscore>of<textunderscore>file
    ><hlopt|-\<gtr\> ><hlkwd|SNil ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ch<textunderscore>read<textunderscore>line ><hlopt|()><hlendline|>

    <item><em|OCaml Batteries> use a stream type <verbatim|enum> for
    interfacing between various sequence-like data types.

    <\itemize>
      <item>The safest way to use streams in a <em|linear> / <em|ephemeral>
      manner: every value used only once.

      <item>Streams minimize space consumption at the expense of time for
      recomputation.
    </itemize>
  </itemize>

  <section|<new-page*>Lazy values>

  <\itemize>
    <item>Lazy evaluation is more general than call-by-need as any value can
    be lazy, not only a function parameter.

    <item>A <em|lazy value> is a value that ``holds'' an expression until its
    result is needed, and from then on it ``holds'' the result.

    <\itemize>
      <item>Also called: a <em|suspension>. If it holds the expression,
      called a <em|thunk>.
    </itemize>

    <item>In OCaml, we build lazy values explicitly. In Haskell, all values
    are lazy but functions can have call-by-value parameters which ``need''
    the argument.

    <item>To create a lazy value: <hlkwa|lazy ><hlstd|expr> -- where
    <verbatim|expr> is the suspended computation.

    <item>Two ways to use a lazy value, be careful when the result is
    computed!

    <\itemize>
      <item>In expressions: <hlkwc|Lazy><hlopt|.><hlstd|force l_expr>

      <item>In patterns: <hlkwa|match ><hlstd|l<textunderscore>expr
      ><hlkwa|with lazy ><hlstd|v ><hlopt|-\<gtr\>> ...

      <\itemize>
        <item>Syntactically <hlkwa|lazy >behaves like a data constructor.
      </itemize>
    </itemize>

    <item>Lazy lists:

    <hlkwa|type ><hlstd|'a llist ><hlopt|= ><hlkwd|LNil ><hlopt|\|
    ><hlkwd|LCons ><hlkwa|of ><hlstd|'a ><hlopt|* ><hlstd|'a llist
    ><hlkwc|Lazy><hlopt|.><hlstd|t><hlendline|>

    <item>Reading from a lazy list into a list:

    <hlkwa|let rec ><hlstd|ltake n ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| <hlopt|\|> ><hlkwd|LCons
    ><hlopt|(><hlstd|a><hlopt|, ><hlkwa|lazy ><hlstd|l><hlopt|) ><hlkwa|when
    ><hlstd|n ><hlopt|\<gtr\> ><hlnum|0 ><hlopt|-\<gtr\>
    ><hlstd|a><hlopt|::(><hlstd|ltake ><hlopt|(><hlstd|n><hlopt|-><hlnum|1><hlopt|)
    ><hlstd|l><hlopt|)><hlendline|><next-line><hlstd| <hlopt|\|>
    <textunderscore> ><hlopt|-\<gtr\> []><hlendline|>

    <item>Lazy lists can easily be infinite:

    <hlkwa|let rec ><hlstd|l<textunderscore>ones ><hlopt|= ><hlkwd|LCons
    ><hlopt|(><hlnum|1><hlopt|, ><hlkwa|lazy
    ><hlstd|l<textunderscore>ones><hlopt|)><hlendline|><next-line><hlkwa|let
    rec ><hlstd|l<textunderscore>from n ><hlopt|= ><hlkwd|LCons
    ><hlopt|(><hlstd|n><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlstd|l<textunderscore>from
    ><hlopt|(><hlstd|n><hlopt|+><hlnum|1><hlopt|)))><hlendline|>

    <item>Read once, access multiple times:

    <hlkwa|let ><hlstd|file<textunderscore>llist name
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|ch
    ><hlopt|= ><hlstd|open<textunderscore>in name
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let rec
    ><hlstd|ch<textunderscore>read<textunderscore>line ><hlopt|()
    =><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|try ><hlkwd|LCons
    ><hlopt|(><hlstd|input<textunderscore>line ch><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlstd|ch<textunderscore>read<textunderscore>line
    ><hlopt|()))><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|with
    ><hlkwd|End<textunderscore>of<textunderscore>file ><hlopt|-\<gtr\>
    ><hlkwd|LNil ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ch<textunderscore>read<textunderscore>line ><hlopt|()><hlendline|>

    <new-page*><item><hlkwa|let rec ><hlstd|lzip ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| <hlopt|\|>
    ><hlkwd|LNil><hlopt|, ><hlkwd|LNil ><hlopt|-\<gtr\>
    ><hlkwd|LNil><hlendline|><next-line><hlstd| <hlopt|\|> ><hlkwd|LCons
    ><hlopt|(><hlstd|a1><hlopt|, ><hlstd|ll1><hlopt|), ><hlkwd|LCons
    ><hlopt|(><hlstd|a2><hlopt|, ><hlstd|ll2><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ ><hlkwd|LCons
    ><hlopt|((><hlstd|a1><hlopt|, ><hlstd|a2><hlopt|), ><hlkwa|lazy
    ><hlopt|(><hlendline|><next-line><hlstd| \ \ \ \ \ \ lzip
    ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force ll1><hlopt|,
    ><hlkwc|Lazy><hlopt|.><hlstd|force ll2><hlopt|)))><hlendline|><next-line><hlstd|
    <hlopt|\|> <textunderscore> ><hlopt|-\<gtr\> ><hlstd|raise
    ><hlopt|(><hlkwd|Invalid<textunderscore>argument
    ><hlstr|"lzip"><hlopt|)><hlendline|>

    <hlkwa|let rec ><hlstd|lmap f ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| <hlopt|\|> ><hlkwd|LNil
    ><hlopt|-\<gtr\> ><hlkwd|LNil><hlendline|><next-line><hlstd| <hlopt|\|>
    ><hlkwd|LCons ><hlopt|(><hlstd|a><hlopt|, ><hlstd|ll><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ ><hlkwd|LCons
    ><hlopt|(><hlstd|f a><hlopt|, ><hlkwa|lazy ><hlopt|(><hlstd|lmap f
    ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force ll><hlopt|)))><hlendline|>

    <item><hlkwa|let ><hlstd|posnums ><hlopt|= ><hlstd|lfrom
    ><hlnum|1><hlendline|><next-line><hlkwa|let rec ><hlstd|lfact
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwd|LCons
    ><hlopt|(><hlnum|1><hlopt|, ><hlkwa|lazy ><hlopt|(><hlstd|lmap
    ><hlopt|(><hlkwa|fun ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|)-\<gtr\>
    ><hlstd|a><hlopt|*><hlstd|b><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|lzip
    ><hlopt|(><hlstd|lfact><hlopt|, ><hlstd|posnums><hlopt|))))><hlendline|>

    <draw-over|<tabular|<tformat|<table|<row|<cell|<block|<tformat|<cwith|1|1|7|7|cell-rborder|0ln>|<table|<row|<cell|<verbatim|1>>|<cell|<verbatim|1>>|<cell|<verbatim|2>>|<cell|<verbatim|6>>|<cell|<verbatim|24>>|<cell|<verbatim|120>>|<cell|...>>>>>>>|<row|<cell|
    \ \ \ <block|<tformat|<cwith|1|1|7|7|cell-rborder|0ln>|<table|<row|<cell|<verbatim|1>>|<cell|<verbatim|1>>|<cell|<verbatim|2>>|<cell|<verbatim|
    6>>|<cell|<verbatim|24>>|<cell|<verbatim|120>>|<cell|...>>>>>>>|<row|<cell|
    \ \ \ <block|<tformat|<cwith|1|1|7|7|cell-rborder|0ln>|<table|<row|<cell|<verbatim|1>>|<cell|<verbatim|2>>|<cell|<verbatim|3>>|<cell|<verbatim|
    4>>|<cell|<verbatim| 5>>|<cell|<verbatim|
    \ 6>>|<cell|...>>>>>>>>>>|<with|gr-color|dark
    blue|gr-mode|<tuple|edit|text-at>|gr-arrow-end|\<gtr\>|gr-frame|<tuple|scale|1cm|<tuple|0.5gw|0.5gh>>|<graphics|<with|color|red|<spline|<point|-3.24858|-1.02259>|<point|-3.5449133483265|-0.239416589495965>|<point|-3.29091149622966|0.0569189046170128>>>|<with|color|red|<spline|<point|-2.40191|-1.00142>|<point|-2.65590686598756|-0.281750231512105>|<point|-2.38073819288266|0.0145852626008731>>>|<with|color|red|<spline|<point|-1.5129|-0.980255>|<point|-1.70339992062442|-0.218249768487895>|<point|-1.51289853155179|0.0145852626008731>>>|<with|color|red|<spline|<point|-0.327557|-1.02259>|<point|-0.772059796269348|-0.0489152004233364>|<point|-0.306389734091811|0.183919830665432>>>|<with|color|red|<spline|<point|0.878952|-1.02259>|<point|0.392115359174494|-0.239416589495965>|<point|0.603783569255192|0.0780857256250827>>>|<with|color|red|arrow-end|\<gtr\>|<spline|<point|-3.56608|-0.260583>|<point|-3.62958063235878|0.691923534859108>|<point|-3.3332451382458|1.03059267098823>>>|<with|color|red|arrow-end|\<gtr\>|<spline|<point|-2.67707|-0.260583>|<point|-2.6982405080037|0.734257176875248>|<point|-2.4230718348988|1.0517594919963>>>|<with|color|red|arrow-end|\<gtr\>|<spline|<point|-1.7034|-0.21825>|<point|-1.87273448868898|0.670756713851039>|<point|-1.55523217356793|1.0517594919963>>>|<with|color|red|arrow-end|\<gtr\>|<spline|<point|-0.77206|-0.0489152>|<point|-0.941394364333907|0.903591744939807>|<point|-0.623892049212859|1.09409313401244>>>|<with|color|red|arrow-end|\<gtr\>|<spline|<point|0.392115|-0.239417>|<point|0.286281254134145|0.628423071834899>|<point|0.624950390263262|1.0517594919963>>>|<with|color|dark
    blue|<text-at|<verbatim|*>|<point|-2.60922|-0.546619>>>|<with|color|dark
    blue|<text-at|<verbatim|*>|<point|-1.66302|-0.503353>>>|<with|color|dark
    blue|<text-at|<verbatim|*>|<point|-0.632667|-0.5082>>>|<with|color|dark
    blue|<text-at|<verbatim|*>|<point|0.504955|-0.500198>>>|<with|color|dark
    blue|<text-at|<verbatim|*>|<point|-3.48713460768869|-0.510082575483059>>>>>>
  </itemize>

  <section|<new-page*>Power series and differential equations>

  <\itemize>
    <item>Differential equations idea due to Henning Thielemann.
    <small|<strong|Just an example.>>

    <item>Expression <math|P<around*|(|x|)>=<big|sum><rsub|i=0><rsup|n>a<rsub|i>x<rsup|i>>
    defines a polynomial for <math|n\<less\>\<infty\>> and a power series for
    <math|n=\<infty\>>.

    <item>If we define

    <hlkwa|let rec ><hlstd|lfold<textunderscore>right f l base
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match ><hlstd|l
    ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|LNil
    ><hlopt|-\<gtr\> ><hlstd|base<hlendline|><next-line> \ \ \ ><hlopt|\|
    ><hlkwd|LCons ><hlopt|(><hlstd|a><hlopt|, ><hlkwa|lazy ><hlstd|l><hlopt|)
    -\<gtr\> ><hlstd|f a ><hlopt|(><hlstd|lfold<textunderscore>right f l
    base><hlopt|)><hlendline|>

    then we can compute polynomials

    <hlkwa|let ><hlstd|horner x l ><hlopt|=><hlendline|><next-line><hlstd|
    \ lfold<textunderscore>right ><hlopt|(><hlkwa|fun ><hlstd|c sum
    ><hlopt|-\<gtr\> ><hlstd|c ><hlopt|+. ><hlstd|x ><hlopt|*.
    ><hlstd|sum><hlopt|) ><hlstd|l ><hlnum|0><hlopt|.><hlendline|>

    <item>But it will not work for infinite power series!

    <\itemize>
      <item>Does it make sense to compute the value at <math|x> of a power
      series?

      <item>Does it make sense to fold an infinite list?
    </itemize>

    <new-page*><item>If the power series converges for <math|x\<gtr\>1>, then
    when the elements <math|a<rsub|n>> get small, the remaining sum
    <math|<big|sum><rsub|i=n><rsup|\<infty\>>a<rsub|i>x<rsup|i>> is also
    small.

    <item><verbatim|lfold_right> falls into an infinite loop on infinite
    lists. We need call-by-name / call-by-need semantics for the argument
    function <verbatim|f>.

    <hlkwa|let rec ><hlstd|lazy<textunderscore>foldr f l base
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match ><hlstd|l
    ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|LNil
    ><hlopt|-\<gtr\> ><hlstd|base<hlendline|><next-line> \ \ \ ><hlopt|\|
    ><hlkwd|LCons ><hlopt|(><hlstd|a><hlopt|, ><hlstd|ll><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ f a
    ><hlopt|(><hlkwa|lazy ><hlopt|(><hlstd|lazy<textunderscore>foldr f
    ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force ll><hlopt|)
    ><hlstd|base><hlopt|))><hlendline|>

    <item>We need a stopping condition in the Horner algorithm step:

    <hlkwa|let ><hlstd|lhorner x l ><hlopt|=><hlendline|This is a bit of a
    hack,><next-line><hlstd| \ ><hlkwa|let ><hlstd|upd c sum
    ><hlopt|=><hlendline|we hope to ``hit'' the interval
    <math|<around*|(|0,\<varepsilon\>|]>>.><next-line><hlstd|
    \ \ \ ><hlkwa|if ><hlstd|c ><hlopt|= ><hlnum|0><hlopt|.
    ><hlstd|<hlopt|\|\|> ><hlstd|abs<textunderscore>float c ><hlopt|\<gtr\>
    ><hlstd|epsilon<textunderscore>float<hlendline|><next-line>
    \ \ \ ><hlkwa|then ><hlstd|c ><hlopt|+. ><hlstd|x ><hlopt|*.
    ><hlkwc|Lazy><hlopt|.><hlstd|force sum<hlendline|><next-line>
    \ \ \ ><hlkwa|else ><hlnum|0><hlopt|.
    ><hlkwa|in><hlendline|><next-line><hlstd| \ lazy<textunderscore>foldr upd
    l ><hlnum|0><hlopt|.><hlendline|>

    <hlkwa|let ><hlstd|inv<textunderscore>fact ><hlopt|= ><hlstd|lmap
    ><hlopt|(><hlkwa|fun ><hlstd|n ><hlopt|-\<gtr\> ><hlnum|1><hlopt|. /.
    ><hlstd|float<textunderscore>of<textunderscore>int n><hlopt|)
    ><hlstd|lfact><hlendline|><next-line><hlkwa|let ><hlstd|e ><hlopt|=
    ><hlstd|lhorner ><hlnum|1><hlopt|. ><hlstd|inv<textunderscore>fact><hlendline|>
  </itemize>

  <subsection|<new-page*>Power series / polynomial operations>

  <\small>
    <\itemize>
      <item><hlkwa|let rec ><hlstd|add xs ys
      ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match
      ><hlstd|xs><hlopt|, ><hlstd|ys ><hlkwa|with><hlendline|><next-line><hlstd|
      \ \ \ ><hlopt|\| ><hlkwd|LNil><hlopt|, ><hlstd|<textunderscore>
      ><hlopt|-\<gtr\> ><hlstd|ys<hlendline|><next-line> \ \ \ <hlopt|\|>
      <textunderscore>><hlopt|, ><hlkwd|LNil ><hlopt|-\<gtr\>
      ><hlstd|xs<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|LCons
      ><hlopt|(><hlstd|x><hlopt|,><hlstd|xs><hlopt|), ><hlkwd|LCons
      ><hlopt|(><hlstd|y><hlopt|,><hlstd|ys><hlopt|)
      -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwd|LCons
      ><hlopt|(><hlstd|x ><hlopt|+. ><hlstd|y><hlopt|, ><hlkwa|lazy
      ><hlopt|(><hlstd|add ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force
      xs><hlopt|) (><hlkwc|Lazy><hlopt|.><hlstd|force
      ys><hlopt|)))><hlendline|>

      <item><hlkwa|let rec ><hlstd|sub xs ys
      ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match
      ><hlstd|xs><hlopt|, ><hlstd|ys ><hlkwa|with><hlendline|><next-line><hlstd|
      \ \ \ ><hlopt|\| ><hlkwd|LNil><hlopt|, ><hlstd|<textunderscore>
      ><hlopt|-\<gtr\> ><hlstd|lmap ><hlopt|(><hlkwa|fun
      ><hlstd|x><hlopt|-\<gtr\> ><hlstd|<math|\<sim\>>><hlopt|-.><hlstd|x><hlopt|)
      ><hlstd|ys<hlendline|><next-line> \ \ \ <hlopt|\|>
      <textunderscore>><hlopt|, ><hlkwd|LNil ><hlopt|-\<gtr\>
      ><hlstd|xs<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|LCons
      ><hlopt|(><hlstd|x><hlopt|,><hlstd|xs><hlopt|), ><hlkwd|LCons
      ><hlopt|(><hlstd|y><hlopt|,><hlstd|ys><hlopt|)
      -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwd|LCons
      ><hlopt|(><hlstd|x><hlopt|-.><hlstd|y><hlopt|, ><hlkwa|lazy
      ><hlopt|(><hlstd|add ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force
      xs><hlopt|) (><hlkwc|Lazy><hlopt|.><hlstd|force
      ys><hlopt|)))><hlendline|>

      <item><hlkwa|let ><hlstd|scale s ><hlopt|= ><hlstd|lmap
      ><hlopt|(><hlkwa|fun ><hlstd|x><hlopt|-\<gtr\>><hlstd|s><hlopt|*.><hlstd|x><hlopt|)><hlendline|>

      <item><hlkwa|let rec ><hlstd|shift n xs
      ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|if ><hlstd|n
      ><hlopt|= ><hlnum|0 ><hlkwa|then ><hlstd|xs<hlendline|><next-line>
      \ ><hlkwa|else if ><hlstd|n ><hlopt|\<gtr\> ><hlnum|0 ><hlkwa|then
      ><hlkwd|LCons ><hlopt|(><hlnum|0><hlopt|. , ><hlkwa|lazy
      ><hlopt|(><hlstd|shift ><hlopt|(><hlstd|n><hlopt|-><hlnum|1><hlopt|)
      ><hlstd|xs><hlopt|))><hlendline|><next-line><hlstd| \ ><hlkwa|else
      match ><hlstd|xs ><hlkwa|with><hlendline|><next-line><hlstd|
      \ \ \ ><hlopt|\| ><hlkwd|LNil ><hlopt|-\<gtr\>
      ><hlkwd|LNil><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
      ><hlkwd|LCons ><hlopt|(><hlnum|0><hlopt|., ><hlkwa|lazy
      ><hlstd|xs><hlopt|) -\<gtr\> ><hlstd|shift
      ><hlopt|(><hlstd|n><hlopt|+><hlnum|1><hlopt|)
      ><hlstd|xs<hlendline|><next-line> \ \ \ <hlopt|\|> <textunderscore>
      ><hlopt|-\<gtr\> ><hlstd|failwith ><hlstr|"shift: fractional
      division"><hlendline|>

      <item><hlkwa|let rec ><hlstd|mul xs ><hlopt|=
      ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
      ><hlkwd|LNil ><hlopt|-\<gtr\> ><hlkwd|LNil><hlendline|><next-line><hlstd|
      \ ><hlopt|\| ><hlkwd|LCons ><hlopt|(><hlstd|y><hlopt|,
      ><hlstd|ys><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ add
      ><hlopt|(><hlstd|scale y xs><hlopt|) (><hlkwd|LCons
      ><hlopt|(><hlnum|0><hlopt|., ><hlkwa|lazy ><hlopt|(><hlstd|mul xs
      ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force ys><hlopt|))))><hlendline|>

      <item><hlkwa|let rec ><hlstd|div xs ys
      ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match
      ><hlstd|xs><hlopt|, ><hlstd|ys ><hlkwa|with><hlendline|><next-line><hlstd|
      \ ><hlopt|\| ><hlkwd|LNil><hlopt|, ><hlstd|<textunderscore>
      ><hlopt|-\<gtr\> ><hlkwd|LNil><hlendline|><next-line><hlstd|
      \ ><hlopt|\| ><hlkwd|LCons ><hlopt|(><hlnum|0><hlopt|.,
      ><hlstd|xs'><hlopt|), ><hlkwd|LCons ><hlopt|(><hlnum|0><hlopt|.,
      ><hlstd|ys'><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ div
      ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force xs'><hlopt|)
      (><hlkwc|Lazy><hlopt|.><hlstd|force
      ys'><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|LCons
      ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs'><hlopt|), ><hlkwd|LCons
      ><hlopt|(><hlstd|y><hlopt|, ><hlstd|ys'><hlopt|)
      -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|q
      ><hlopt|= ><hlstd|x ><hlopt|/. ><hlstd|y
      ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|LCons
      ><hlopt|(><hlstd|q><hlopt|, ><hlkwa|lazy ><hlopt|(><hlstd|divSeries
      ><hlopt|(><hlstd|sub ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force
      xs'><hlopt|)><hlendline|><next-line><hlstd|
      \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|scale
      q ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force ys'><hlopt|)))
      ><hlstd|ys><hlopt|))><hlendline|><next-line><hlstd| \ ><hlopt|\|
      ><hlkwd|LCons ><hlstd|<textunderscore>><hlopt|, ><hlkwd|LNil
      ><hlopt|-\<gtr\> ><hlstd|failwith ><hlstr|"divSeries: division by
      zero"><hlendline|>

      <item><hlkwa|let ><hlstd|integrate c xs
      ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwd|LCons
      ><hlopt|(><hlstd|c><hlopt|, ><hlkwa|lazy ><hlopt|(><hlstd|lmap
      ><hlopt|(><hlstd|uncurry ><hlopt|(/.)) (><hlstd|lzip
      ><hlopt|(><hlstd|xs><hlopt|, ><hlstd|posnums><hlopt|))))><hlendline|>

      <item><hlkwa|let ><hlstd|ltail ><hlopt|=
      ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
      ><hlkwd|LNil ><hlopt|-\<gtr\> ><hlstd|invalid<textunderscore>arg
      ><hlstr|"ltail"><hlstd|<hlendline|><next-line> \ ><hlopt|\|
      ><hlkwd|LCons ><hlopt|(><hlstd|<textunderscore>><hlopt|, ><hlkwa|lazy
      ><hlstd|tl><hlopt|) -\<gtr\> ><hlstd|tl><hlendline|>

      <item><hlkwa|let ><hlstd|differentiate xs
      ><hlopt|=><hlendline|><next-line><hlstd| \ lmap
      ><hlopt|(><hlstd|uncurry ><hlopt|( *.)) (><hlstd|lzip
      ><hlopt|(><hlstd|ltail xs><hlopt|, ><hlstd|posnums><hlopt|))><hlendline|>
    </itemize>
  </small>

  <subsection|<new-page*>Differential equations>

  <\itemize>
    <item><math|<frac|\<mathd\>sin x|\<mathd\>x>=cos x,<frac|\<mathd\>cos
    x|\<mathd\>x>=-sin x,sin 0=0,cos 0=1>.

    <item>We will solve the corresponding integral equations. <em|Why?>

    <item>We cannot define the integral by direct recursion like this:

    <hlkwa|let rec ><hlstd|sin ><hlopt|= ><hlstd|integrate
    ><hlopt|(><hlstd|of<textunderscore>int ><hlnum|0><hlopt|)
    ><hlstd|cos><hlendline|Unary op. <tiny|<hlkwa|let
    ><hlopt|(><hlstd|<math|\<sim\>>><hlopt|-:) =>>><next-line><hlkwa|and
    ><hlstd|cos ><hlopt|= ><hlstd|integrate
    ><hlopt|(><hlstd|of<textunderscore>int ><hlnum|1><hlopt|)
    ><hlstd|<math|\<sim\>>><hlopt|-:><hlstd|sin><hlendline| <tiny|<hlstd|lmap
    ><hlopt|(><hlkwa|fun ><hlstd|x><hlopt|-\<gtr\>
    ><hlstd|<math|\<sim\>>><hlopt|-.><hlstd|x><hlopt|)>>>

    unfortunately fails:

    <verbatim|Error: This kind of expression is not allowed as right-hand
    side of `let rec'>

    <\itemize>
      <item>Even changing the second argument of <verbatim|integrate> to
      call-by-need does not help, because OCaml cannot represent the values
      that <verbatim|x> and <verbatim|y> refer to.
    </itemize>

    <new-page*><item>We need to inline a bit of <verbatim|integrate> so that
    OCaml knows how to start building the recursive structure.

    <hlkwa|let ><hlstd|integ xs ><hlopt|= ><hlstd|lmap
    ><hlopt|(><hlstd|uncurry ><hlopt|(/.)) (><hlstd|lzip
    ><hlopt|(><hlstd|xs><hlopt|, ><hlstd|posnums><hlopt|))><hlendline|><next-line><hlkwa|let
    rec ><hlstd|sin ><hlopt|= ><hlkwd|LCons
    ><hlopt|(><hlstd|of<textunderscore>int ><hlnum|0><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlstd|integ cos><hlopt|))><hlendline|><next-line><hlkwa|and
    ><hlstd|cos ><hlopt|= ><hlkwd|LCons ><hlopt|(><hlstd|of<textunderscore>int
    ><hlnum|1><hlopt|, ><hlkwa|lazy ><hlopt|(><hlstd|integ
    <math|\<sim\>>><hlopt|-:><hlstd|sin><hlopt|))><hlendline|>

    <item>The complete example would look much more elegant in Haskell.

    <item>Although this approach is not limited to linear equations,
    equations like Lotka-Volterra or Lorentz are not ``solvable'' -- computed
    coefficients quickly grow instead of quickly falling...

    <new-page*><item>Drawing functions are like in previous lecture, but with
    open curves.

    <item><hlkwa|let ><hlstd|plot<textunderscore>1D f <math|\<sim\>>w
    <math|\<sim\>>scale <math|\<sim\>>t<textunderscore>beg
    <math|\<sim\>>t<textunderscore>end ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|dt ><hlopt|= (><hlstd|t<textunderscore>end
    ><hlopt|-. ><hlstd|t<textunderscore>beg><hlopt|) /.
    ><hlstd|of<textunderscore>int w ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwc|Array><hlopt|.><hlstd|init w ><hlopt|(><hlkwa|fun ><hlstd|i
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|y ><hlopt|= ><hlstd|lhorner ><hlopt|(><hlstd|dt ><hlopt|*.
    ><hlstd|of<textunderscore>int i><hlopt|) ><hlstd|f
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ i><hlopt|, ><hlstd|to_int
    ><hlopt|(><hlstd|scale ><hlopt|*. ><hlstd|y><hlopt|))><hlendline|>
  </itemize>

  <section|<new-page*>Arbitrary precision computation>

  <\itemize>
    <item>Putting it all together reveals drastic numerical errors for large
    <math|x>.

    <hlkwa|let ><hlstd|graph ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|scale ><hlopt|= ><hlstd|of<textunderscore>int h
    ><hlopt|/. ><hlstd|of<textunderscore>int ><hlnum|8
    ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlopt|[><hlstd|plot<textunderscore>1D sin <math|\<sim\>>w
    <math|\<sim\>>h0><hlopt|:(><hlstd|h><hlopt|/><hlnum|2><hlopt|)
    ><hlstd|<math|\<sim\>>scale<hlendline|><next-line>
    \ \ \ \ \ <math|\<sim\>>t<textunderscore>beg><hlopt|:(><hlstd|of<textunderscore>int
    ><hlnum|0><hlopt|) ><hlstd|<math|\<sim\>>t<textunderscore>end><hlopt|:(><hlstd|of<textunderscore>int
    ><hlnum|15><hlopt|),><hlendline|><next-line><hlstd|
    \ \ ><hlopt|(><hlnum|250><hlopt|,><hlnum|250><hlopt|,><hlnum|0><hlopt|);><hlendline|><next-line><hlstd|
    \ \ plot<textunderscore>1D cos <math|\<sim\>>w
    <math|\<sim\>>h0><hlopt|:(><hlstd|h><hlopt|/><hlnum|2><hlopt|)
    ><hlstd|<math|\<sim\>>scale<hlendline|><next-line>
    \ \ \ \ <math|\<sim\>>t<textunderscore>beg><hlopt|:(><hlstd|of<textunderscore>int
    ><hlnum|0><hlopt|) ><hlstd|<math|\<sim\>>t<textunderscore>end><hlopt|:(><hlstd|of<textunderscore>int
    ><hlnum|15><hlopt|),><hlendline|><next-line><hlstd|
    \ \ ><hlopt|(><hlnum|250><hlopt|,><hlnum|0><hlopt|,><hlnum|250><hlopt|)]><hlendline|><next-line><hlkwa|let
    ><hlopt|() = ><hlstd|draw<textunderscore>to<textunderscore>screen
    <math|\<sim\>>w <math|\<sim\>>h graph><hlendline|>

    <\itemize>
      <item>Floating-point numbers have limited precision.

      <item>We break out of Horner method computations too quickly.
    </itemize>

    <image|sin_cos_1.eps|0.6w|||>

    <new-page*><item>For infinite precision on rational numbers we use the
    <verbatim|nums> library.

    <\itemize>
      <item>It does not help -- yet.
    </itemize>

    <item>Generate a sequence of approximations to the power series limit at
    <math|x>.

    <hlkwa|let ><hlstd|infhorner x l ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|upd c sum ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwd|LCons ><hlopt|(><hlstd|c><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlstd|lmap ><hlopt|(><hlkwa|fun ><hlstd|apx ><hlopt|-\<gtr\>
    ><hlstd|c><hlopt|+.><hlstd|x><hlopt|*.><hlstd|apx><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force
    sum><hlopt|))) ><hlkwa|in><hlendline|><next-line><hlstd|
    \ lazy<textunderscore>foldr upd l ><hlopt|(><hlkwd|LCons
    ><hlopt|(><hlstd|of<textunderscore>int ><hlnum|0><hlopt|, ><hlkwa|lazy
    ><hlkwd|LNil><hlopt|))><hlendline|>

    <item>Find where the series converges -- as far as a given test is
    concerned.

    <hlkwa|let rec ><hlstd|exact f ><hlopt|= ><hlkwa|function><hlendline|We
    arbitrarily decide that convergence is><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|LNil ><hlopt|-\<gtr\> ><hlkwa|assert false><hlendline|when three
    consecutive results are the same.><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|LCons ><hlopt|(><hlstd|x0><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlkwd|LCons ><hlopt|(><hlstd|x1><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlkwd|LCons ><hlopt|(><hlstd|x2><hlopt|,
    ><hlstd|<textunderscore>><hlopt|)))))><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|when ><hlstd|f x0 ><hlopt|= ><hlstd|f x1 ><hlopt|&&
    ><hlstd|f x0 ><hlopt|= ><hlstd|f x2 ><hlopt|-\<gtr\> ><hlstd|f
    x0<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|LCons
    ><hlopt|(><hlstd|<textunderscore>><hlopt|, ><hlkwa|lazy
    ><hlstd|tl><hlopt|) -\<gtr\> ><hlstd|exact f tl><hlendline|>

    <new-page*><item>Draw the pixels of the graph at exact coordinates.

    <hlkwa|let ><hlstd|plot<textunderscore>1D f <math|\<sim\>>w
    <math|\<sim\>>h0 <math|\<sim\>>scale <math|\<sim\>>t<textunderscore>beg
    <math|\<sim\>>t<textunderscore>end ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|dt ><hlopt|= (><hlstd|t<textunderscore>end
    ><hlopt|-. ><hlstd|t<textunderscore>beg><hlopt|) /.
    ><hlstd|of<textunderscore>int w ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|eval ><hlopt|= ><hlstd|exact ><hlopt|(><hlkwa|fun
    ><hlstd|y><hlopt|-\<gtr\> ><hlstd|to<textunderscore>int
    ><hlopt|(><hlstd|scale ><hlopt|*. ><hlstd|y><hlopt|))
    ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwc|Array><hlopt|.><hlstd|init w ><hlopt|(><hlkwa|fun ><hlstd|i
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|y ><hlopt|= ><hlstd|infhorner
    ><hlopt|(><hlstd|t<textunderscore>beg ><hlopt|+. ><hlstd|dt ><hlopt|*.
    ><hlstd|of<textunderscore>int i><hlopt|) ><hlstd|f
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ i><hlopt|, ><hlstd|h0
    ><hlopt|+ ><hlstd|eval y><hlopt|)><hlendline|>

    <item>Success! If a power series had every third term contributing we
    would have to check three terms in the function <verbatim|exact>...

    <\itemize>
      <item>We could like in <verbatim|lhorner> test for <verbatim|f x0 = f
      x1 && not x0 =. x1>
    </itemize>

    <item>Example <verbatim|n_chain>: nuclear chain reaction--<em|A decays
    into B decays into C>

    <\itemize>
      <item><small|<hlink|http://en.wikipedia.org/wiki/Radioactive_decay#Chain-decay_processes|http://en.wikipedia.org/wiki/Radioactive_decay#Chain-decay_processes>>
    </itemize>

    <small|<hlkwa|let ><hlstd|n<textunderscore>chain <math|\<sim\>>nA0
    <math|\<sim\>>nB0 <math|\<sim\>>lA <math|\<sim\>>lB
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|nA
    ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|LCons
    ><hlopt|(><hlstd|nA0><hlopt|, ><hlkwa|lazy ><hlopt|(><hlstd|integ
    ><hlopt|(><hlstd|<math|\<sim\>>><hlopt|-.><hlstd|lA ><hlopt|*:.
    ><hlstd|nA><hlopt|)))><hlendline|><next-line><hlstd| \ ><hlkwa|and
    ><hlstd|nB ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|LCons
    ><hlopt|(><hlstd|nB0><hlopt|, ><hlkwa|lazy ><hlopt|(><hlstd|integ
    ><hlopt|(><hlstd|<math|\<sim\>>><hlopt|-.><hlstd|lB ><hlopt|*:.
    ><hlstd|nB ><hlopt|+: ><hlstd|lA ><hlopt|*:. ><hlstd|nA><hlopt|)))
    ><hlkwa|in><hlendline|><next-line><hlstd| \ nA><hlopt|,
    ><hlstd|nB><hlendline|>>
  </itemize>

  <image|chain_reaction.eps|0.6w|||>

  <section|<new-page*>Circular data structures: double-linked list>

  <\itemize>
    <item>Without delayed computation, the ability to define data structures
    with referential cycles is very limited.

    <item>Double-linked lists contain such cycles between any two nodes even
    if they are not cyclic when following only <em|forward> or <em|backward>
    links.

    <draw-over|<tabular|<tformat|<table|<row|<cell|<block|<tformat|<table|<row|<cell|<verbatim|DLNil>>|<cell|<verbatim|a1>>|<cell|
    >>>>>>|<cell|<block|<tformat|<table|<row|<cell|
    >|<cell|<verbatim|a2>>|<cell| >>>>>>|<cell|<block|<tformat|<table|<row|<cell|
    >|<cell|<verbatim|a3>>|<cell| >>>>>>|<cell|<block|<tformat|<table|<row|<cell|
    >|<cell|<verbatim|a4>>|<cell| >>>>>>|<cell|<block|<tformat|<table|<row|<cell|
    >|<cell|<verbatim|a5>>|<cell|<verbatim|DLNil>>>>>>>>>>>|<with|gr-color|red|gr-arrow-end|\|\<gtr\>|gr-mode|<tuple|edit|arc>|<graphics|<with|color|red|arrow-end|\|\<gtr\>|<arc|<point|-5.51728|0.0390925>|<point|-4.67060788464083|0.102592935573489>|<point|-4.56477377960048|0.0602592935573488>>>|<with|color|red|arrow-end|\|\<gtr\>|<arc|<point|-4.1626|-0.00324117>|<point|-4.88227609472152|-0.214909379547559>|<point|-5.05161066278608|-0.10907527450721>>>|<with|color|red|arrow-end|\|\<gtr\>|<arc|<point|-2.21526|0.0179257>|<point|-1.51675155443842|0.229593861621908>|<point|-1.41091744939807|0.123759756581558>>>|<with|color|red|arrow-end|\|\<gtr\>|<arc|<point|-0.987581|-0.00324117>|<point|-1.68608612250298|-0.15140891652335>|<point|-1.8130870485514|-0.0667416324910702>>>|<with|color|red|arrow-end|\|\<gtr\>|<arc|<point|0.980933|0.0179257>|<point|1.61593795475592|0.166093398597698>|<point|1.82760616483662|0.0179256515412092>>>|<with|color|red|arrow-end|\|\<gtr\>|<arc|<point|2.20861|-0.0667416>|<point|1.57360431273978|-0.278409842571769>|<point|1.40426974467522|-0.15140891652335>>>|<with|color|red|arrow-end|\|\<gtr\>|<arc|<point|4.19829|0.0390925>|<point|4.81212792697447|0.187260219605768>|<point|4.98146249503903|0.123759756581558>>>|<with|color|red|arrow-end|\|\<gtr\>|<arc|<point|5.44713|-0.024408>|<point|4.74862746395026|-0.17257573753142>|<point|4.5792928958857|-0.15140891652335>>>>>>

    <item>We need to ``break'' the cycles by making some links lazy.

    <item><hlkwa|type ><hlstd|'a dllist ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwd|DLNil ><hlopt|\| ><hlkwd|DLCons ><hlkwa|of ><hlstd|'a dllist
    ><hlkwc|Lazy><hlopt|.><hlstd|t ><hlopt|* ><hlstd|'a ><hlopt|* ><hlstd|'a
    dllist><hlendline|>

    <item><hlkwa|let rec ><hlstd|dldrop n l
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match ><hlstd|l
    ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|DLCons ><hlopt|(><hlstd|<textunderscore>><hlopt|,
    ><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) ><hlkwa|when
    ><hlstd|n><hlopt|\<gtr\>><hlnum|0 ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ dldrop ><hlopt|(><hlstd|n><hlopt|-><hlnum|1><hlopt|)
    ><hlstd|xs<hlendline|><next-line> \ \ \ <hlopt|\|> <textunderscore>
    ><hlopt|-\<gtr\> ><hlstd|l><hlendline|>

    <new-page*><item><hlkwa|let ><hlstd|dllist<textunderscore>of<textunderscore>list
    l ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let rec
    ><hlstd|dllist prev l ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|match ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|\| [] -\<gtr\> ><hlkwd|DLNil><hlendline|><next-line><hlstd|
    \ \ \ \ \ <hlopt|\|> x><hlopt|::><hlstd|xs
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|let
    rec ><hlstd|cell ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ ><hlkwa|lazy ><hlopt|(><hlkwd|DLCons
    ><hlopt|(><hlstd|prev><hlopt|, ><hlstd|x><hlopt|, ><hlstd|dllist cell
    xs><hlopt|)) ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwc|Lazy><hlopt|.><hlstd|force cell
    ><hlkwa|in><hlendline|><next-line><hlstd| \ dllist ><hlopt|(><hlkwa|lazy
    ><hlkwd|DLNil><hlopt|) ><hlstd|l><hlendline|>

    <item><hlkwa|let rec ><hlstd|dltake n l
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match ><hlstd|l
    ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|DLCons ><hlopt|(><hlstd|<textunderscore>><hlopt|,
    ><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) ><hlkwa|when
    ><hlstd|n><hlopt|\<gtr\>><hlnum|0 ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ x><hlopt|::><hlstd|dltake ><hlopt|(><hlstd|n><hlopt|-><hlnum|1><hlopt|)
    ><hlstd|xs<hlendline|><next-line> \ \ \ <hlopt|\|> <textunderscore>
    ><hlopt|-\<gtr\> []><hlendline|>

    <item><hlkwa|let rec ><hlstd|dlbackwards n l
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match ><hlstd|l
    ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|DLCons ><hlopt|(><hlkwa|lazy ><hlstd|xs><hlopt|,
    ><hlstd|x><hlopt|, ><hlstd|<textunderscore>><hlopt|) ><hlkwa|when
    ><hlstd|n><hlopt|\<gtr\>><hlnum|0 ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ x><hlopt|::><hlstd|dlbackwards
    ><hlopt|(><hlstd|n><hlopt|-><hlnum|1><hlopt|)
    ><hlstd|xs<hlendline|><next-line> \ \ \ <hlopt|\|> <textunderscore>
    ><hlopt|-\<gtr\> []><hlendline|>
  </itemize>

  <section|<new-page*>Input-Output streams>

  <\itemize>
    <item>The stream type used a throwaway argument to make a suspension

    <hlkwa|type ><hlstd|'a stream ><hlopt|= ><hlkwd|SNil ><hlopt|\|
    ><hlkwd|SCons ><hlkwa|of ><hlstd|'a ><hlopt|* (><hlkwb|unit
    ><hlopt|-\<gtr\> ><hlstd|'a stream><hlopt|)><hlendline|>

    What if we take a real argument?

    <hlkwa|type ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|)
    ><hlstd|iostream ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwd|EOS
    ><hlopt|\| ><hlkwd|More ><hlkwa|of ><hlstd|'b ><hlopt|* (><hlstd|'a
    ><hlopt|-\<gtr\> (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|)
    ><hlstd|iostream><hlopt|)><hlendline|>

    A stream that for a single input value produces an output value.

    <item><hlkwa|type ><hlstd|'a istream ><hlopt|= (><hlkwb|unit><hlopt|,
    ><hlstd|'a><hlopt|) ><hlstd|iostream><hlendline|><next-line>Input stream
    produces output when ``asked''.

    <hlkwa|type ><hlstd|'a ostream ><hlopt|= (><hlstd|'a><hlopt|,
    ><hlkwb|unit><hlopt|) ><hlstd|iostream><hlendline|><next-line>Output
    stream consumes provided input.

    <\itemize>
      <item>Sorry, the confusion arises from adapting the <em|input file /
      output file> terminology, also used for streams.
    </itemize>

    <new-page*><item>We can compose streams: directing output of one to input
    of another.

    <hlkwa|let rec ><hlstd|compose sf sg ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|match ><hlstd|sg ><hlkwa|with><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|EOS ><hlopt|-\<gtr\> ><hlkwd|EOS><hlendline|No more
    output.><verbatim|<next-line> \ ><hlopt|\| ><hlkwd|More
    ><hlopt|(><hlstd|z><hlopt|, ><hlstd|g><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match ><hlstd|sf
    ><hlkwa|with><hlendline|No more><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|EOS ><hlopt|-\<gtr\> ><hlkwd|More ><hlopt|(><hlstd|z><hlopt|,
    ><hlkwa|fun ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
    ><hlkwd|EOS><hlopt|)><hlendline|input ``processing power''.><next-line>
    \ \ \ <hlopt|\| ><hlkwd|More ><hlopt|(><hlstd|y><hlopt|,
    ><hlstd|f><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|let ><hlstd|update x ><hlopt|= ><hlstd|compose
    ><hlopt|(><hlstd|f x><hlopt|) (><hlstd|g y><hlopt|)
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwd|More
    ><hlopt|(><hlstd|z><hlopt|, ><hlstd|update><hlopt|)><hlendline|>

    <\itemize>
      <item>Every box has one incoming and one outgoing
      wire:<draw-over|<tabular|<tformat|<cwith|2|2|1|1|cell-valign|c>|<table|<row|<cell|>>|<row|<cell|<block|<tformat|<table|<row|<cell|<verbatim|f>>>>>>>>|<row|<cell|>>|<row|<cell|<block|<tformat|<table|<row|<cell|<verbatim|g>>>>>>>>|<row|<cell|>>>>>|<with|gr-color|red|gr-arrow-end|\|\<gtr\>|<graphics|<with|color|red|arrow-end|\|\<gtr\>|<line|<point|0.0290382|2.28018>|<point|0.0290382325704458|1.41233959518455>>>|<with|color|red|arrow-end|\|\<gtr\>|<line|<point|-0.0344622|0.459833>|<point|-0.0344622304537637|-0.492674295541738>>>|<with|color|red|arrow-end|\|\<gtr\>|<line|<point|-0.0132954|-1.40285>|<point|-0.0132954094456939|-2.22835361820347>>>>>>

      <item>Notice how the output stream is ahead of the input stream.
    </itemize>
  </itemize>

  <subsection|<new-page*>Pipes>

  <\itemize>
    <item>We need a more flexible input-output stream definition.

    <\itemize>
      <item>Consume several inputs to produce a single output.

      <item>Produce several outputs after a single input (or even without
      input).

      <item>No need for a dummy when producing output requires input.
    </itemize>

    <item>After Haskell, we call the data structure <verbatim|pipe>.

    <hlkwa|type ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|pipe
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwd|EOP><hlendline|><next-line><hlopt|\| ><hlkwd|Yield ><hlkwa|of
    ><hlstd|'b ><hlopt|* (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|)
    ><verbatim|pipe><hlendline|For incremental streams change to
    lazy.><verbatim|<next-line><hlopt|\|> ><hlkwd|Await ><hlkwa|of ><hlstd|'a
    ><hlopt|-\<gtr\> (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|)
    ><hlstd|pipe><hlendline|>

    <item>Again, we can have producing output only <em|input pipes> and
    consuming input only <em|output pipes>.

    <hlkwa|type ><hlstd|'a ipipe ><hlopt|= (><hlkwb|unit><hlopt|,
    ><hlstd|'a><hlopt|) ><hlstd|pipe><hlendline|><next-line><hlkwa|type
    ><hlstd|void><hlendline|><next-line><hlkwa|type ><hlstd|'a opipe
    ><hlopt|= (><hlstd|'a><hlopt|, ><hlstd|void><hlopt|)
    ><hlstd|pipe><hlendline|>

    <\itemize>
      <item>Why <verbatim|void> rather than <verbatim|unit>, and why only for
      <verbatim|opipe>?
    </itemize>

    <new-page*><item>Composition of pipes is like ``concatenating them in
    space'' or connecting boxes:

    <hlkwa|let rec ><hlstd|compose pf pg ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|match ><hlstd|pg ><hlkwa|with><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|EOP ><hlopt|-\<gtr\> ><hlkwd|EOP><hlendline|Done
    producing results.><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Yield
    ><hlopt|(><hlstd|z><hlopt|, ><hlstd|pg'><hlopt|) -\<gtr\> ><hlkwd|Yield
    ><hlopt|(><hlstd|z><hlopt|, ><hlstd|compose pf
    pg'><hlopt|)><hlendline|Ready result.><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|Await ><hlstd|g ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|match ><hlstd|pf ><hlkwa|with><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|\| ><hlkwd|EOP ><hlopt|-\<gtr\> ><hlkwd|EOP><hlendline|End
    of input.><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Yield
    ><hlopt|(><hlstd|y><hlopt|, ><hlstd|pf'><hlopt|) -\<gtr\> ><hlstd|compose
    pf' ><hlopt|(><hlstd|g y><hlopt|)><hlendline|Compute next
    result.><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Await ><hlstd|f
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|let
    ><hlstd|update x ><hlopt|= ><hlstd|compose ><hlopt|(><hlstd|f x><hlopt|)
    ><hlstd|pg ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwd|Await ><hlstd|update><hlendline|Wait for more input.>

    <hlkwa|let ><hlopt|(\<gtr\>-\<gtr\>) ><hlstd|pf pg ><hlopt|=
    ><hlstd|compose pf pg><hlendline|>

    <new-page*><item>Appending pipes means ``concatenating them in time'' or
    adding more fuel to a box:

    <hlkwa|let rec ><hlstd|append pf pg ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|match ><hlstd|pf ><hlkwa|with><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|EOP ><hlopt|-\<gtr\> ><verbatim|pg><hlendline|When
    <verbatim|pf> runs out, use <verbatim|pg>.><verbatim|<next-line>
    \ <hlopt|\| >><hlkwd|Yield ><hlopt|(><hlstd|z><hlopt|,
    ><hlstd|pf'><hlopt|) -\<gtr\> ><hlkwd|Yield ><hlopt|(><hlstd|z><hlopt|,
    ><hlstd|append pf' pg><hlopt|)><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|Await ><hlstd|f ><hlopt|-\<gtr\>><hlendline|If
    <verbatim|pf> awaits input, continue when it comes.><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|update x ><hlopt|= ><hlstd|append
    ><hlopt|(><hlstd|f x><hlopt|) ><hlstd|pg
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|Await
    ><hlstd|update><hlendline|>

    <item>Append a list of ready results in front of a pipe.

    <hlkwa|let rec ><hlstd|yield<textunderscore>all l tail
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match ><hlstd|l
    ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
    ><hlstd|tail<hlendline|><next-line> \ <hlopt|\|> x><hlopt|::><hlstd|xs
    ><hlopt|-\<gtr\> ><hlkwd|Yield ><hlopt|(><hlstd|x><hlopt|,
    ><hlstd|yield<textunderscore>all xs tail><hlopt|)><hlendline|>

    <item>Iterate a pipe (<strong|not functional>).

    <hlkwa|let rec ><hlstd|iterate f ><hlopt|: ><hlstd|'a opipe
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwd|Await
    ><hlopt|(><hlkwa|fun ><hlstd|x ><hlopt|-\<gtr\> ><hlkwa|let ><hlopt|() =
    ><hlstd|f x ><hlkwa|in ><hlstd|iterate f><hlopt|)><hlendline|>
  </itemize>

  <subsection|<new-page*>Example: pretty-printing>

  <\itemize>
    <item>Print hierarchically organized document with a limited line width.

    <hlkwa|type ><hlstd|doc ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwd|Text ><hlkwa|of ><hlkwb|string ><hlopt|\| ><hlkwd|Line
    ><hlopt|\| ><hlkwd|Cat ><hlkwa|of ><hlstd|doc ><hlopt|* ><hlstd|doc
    <hlopt|\|> ><hlkwd|Group ><hlkwa|of ><hlstd|doc><hlendline|>

    <item><hlkwa|let ><hlopt|(++) ><hlstd|d1 d2 ><hlopt|= ><hlkwd|Cat
    ><hlopt|(><hlstd|d1><hlopt|, ><hlkwd|Cat ><hlopt|(><hlkwd|Line><hlopt|,
    ><hlstd|d2><hlopt|))><hlendline|><next-line><hlkwa|let ><hlopt|(!)
    ><hlstd|s ><hlopt|= ><hlkwd|Text ><hlstd|s><hlendline|><next-line><hlkwa|let
    ><hlstd|test<textunderscore>doc ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwd|Group ><hlopt|(!><hlstr|"Document"><hlstd|
    ><hlopt|++><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ \ \ ><hlkwd|Group ><hlopt|(!><hlstr|"First
    part"><hlstd| ><hlopt|++ !><hlstr|"Second part"><hlopt|))><hlendline|>
  </itemize>

  <small|<hlstd|# ><hlkwa|let ><hlopt|() =
  ><hlstd|print<textunderscore>endline ><hlopt|(><hlstd|pretty ><hlnum|30
  ><hlstd|test<textunderscore>doc><hlopt|);;><hlendline|><next-line><hlkwd|Document><hlendline|><next-line><hlkwd|First
  ><hlstd|part ><hlkwd|Second ><hlstd|part<hlendline|><next-line>#
  ><hlkwa|let ><hlopt|() = ><hlstd|print<textunderscore>endline
  ><hlopt|(><hlstd|pretty ><hlnum|20 ><hlstd|test<textunderscore>doc><hlopt|);;><hlendline|><next-line><hlkwd|Document><hlendline|><next-line><hlkwd|First
  ><hlstd|part><hlendline|><next-line><hlkwd|Second
  ><hlstd|part<hlendline|><next-line># ><hlkwa|let ><hlopt|() =
  ><hlstd|print<textunderscore>endline ><hlopt|(><hlstd|pretty ><hlnum|60
  ><hlstd|test<textunderscore>doc><hlopt|);;><hlendline|><next-line><hlkwd|Document
  First ><hlstd|part ><hlkwd|Second ><hlstd|part><hlendline|>>

  <\itemize>
    <new-page*><item>Straightforward solution:

    <hlkwa|let ><hlstd|pretty w d ><hlopt|=><hlendline|Allowed width of line
    <verbatim|w>.><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|width
    ><hlopt|= ><hlkwa|function><hlendline|Total length of
    subdocument.><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Text ><hlstd|z
    ><hlopt|-\<gtr\> ><hlkwc|String><hlopt|.><hlstd|length
    z<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|Line ><hlopt|-\<gtr\>
    ><hlnum|1><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Cat
    ><hlopt|(><hlstd|d1><hlopt|, ><hlstd|d2><hlopt|) -\<gtr\> ><hlstd|width
    d1 ><hlopt|+ ><hlstd|width d2<hlendline|><next-line> \ \ \ ><hlopt|\|
    ><hlkwd|Group ><hlstd|d ><hlopt|-\<gtr\> ><hlstd|width d
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let rec
    ><hlstd|format f r ><hlopt|= ><hlkwa|function><hlendline|Remaining space
    <verbatim|r>.><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Text ><hlstd|z
    ><hlopt|-\<gtr\> ><hlstd|z><hlopt|, ><hlstd|r ><hlopt|-
    ><hlkwc|String><hlopt|.><hlstd|length z<hlendline|><next-line>
    \ \ \ ><hlopt|\| ><hlkwd|Line ><hlkwa|when ><hlstd|f ><hlopt|-\<gtr\>
    ><hlstr|" "><hlopt|, ><hlstd|r><hlopt|-><hlnum|1><hlendline|If
    <verbatim|not f> then line breaks.><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|Line ><hlopt|-\<gtr\> ><hlstr|"><hlesc|\\n><hlstr|"><hlopt|,
    ><hlstd|w<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|Cat
    ><hlopt|(><hlstd|d1><hlopt|, ><hlstd|d2><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|let
    ><hlstd|s1><hlopt|, ><hlstd|r ><hlopt|= ><hlstd|format f r d1
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|let
    ><hlstd|s2><hlopt|, ><hlstd|r ><hlopt|= ><hlstd|format f r d2
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ s1 <textasciicircum>
    s2><hlopt|, ><verbatim|r><hlendline|If following group fits, then without
    line breaks.><verbatim|<next-line> \ \ \ ><hlopt|\| ><hlkwd|Group
    ><hlstd|d ><hlopt|-\<gtr\> ><hlstd|format ><hlopt|(><hlstd|f <hlopt|\|\|>
    width d ><hlopt|\<less\>= ><hlstd|r><hlopt|) ><hlstd|r d
    ><hlkwa|in><hlendline|><next-line><hlstd| \ fst ><hlopt|(><hlstd|format
    ><hlkwa|false ><hlstd|w d><hlopt|)><hlendline|>

    <new-page*><item>Working with a stream of nodes.

    <hlkwa|type ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|)
    ><hlstd|doc<textunderscore>e ><hlopt|=><hlendline|Annotated nodes,
    special for group beginning.><next-line><hlstd| \ ><hlkwd|TE ><hlkwa|of
    ><hlstd|'a ><hlopt|* ><hlkwb|string ><hlopt|\| ><hlkwd|LE ><hlkwa|of
    ><hlstd|'a <hlopt|\|> ><hlkwd|GBeg ><hlkwa|of ><hlstd|'b <hlopt|\|>
    ><hlkwd|GEnd ><hlkwa|of ><hlstd|'a><hlendline|>

    <item>Normalize a subdocument -- remove empty groups.

    <hlkwa|let rec ><hlstd|norm ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|Group ><hlstd|d ><hlopt|-\<gtr\> ><hlstd|norm
    d<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Text ><hlstr|""><hlstd|
    ><hlopt|-\<gtr\> ><hlkwd|None><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|Cat ><hlopt|(><hlkwd|Text ><hlstr|""><hlopt|, ><hlstd|d><hlopt|)
    -\<gtr\> ><hlstd|norm d<hlendline|><next-line> \ <hlopt|\|> d
    ><hlopt|-\<gtr\> ><hlkwd|Some ><hlstd|d><hlendline|>

    <new-page*><item>Generate the stream by infix traversal.

    <hlkwa|let rec ><hlstd|gen ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|Text ><hlstd|z ><hlopt|-\<gtr\> ><hlkwd|Yield
    ><hlopt|(><hlkwd|TE ><hlopt|((),><hlstd|z><hlopt|),
    ><hlkwd|EOP><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|Line ><hlopt|-\<gtr\> ><hlkwd|Yield ><hlopt|(><hlkwd|LE
    ><hlopt|(), ><hlkwd|EOP><hlopt|)><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|Cat ><hlopt|(><hlstd|d1><hlopt|, ><hlstd|d2><hlopt|)
    -\<gtr\> ><hlstd|append ><hlopt|(><hlstd|gen d1><hlopt|) (><hlstd|gen
    d2><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Group
    ><hlstd|d ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|match ><hlstd|norm d ><hlkwa|with><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|\| ><hlkwd|None ><hlopt|-\<gtr\>
    ><hlkwd|EOP><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Some
    ><hlstd|d ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwd|Yield ><hlopt|(><hlkwd|GBeg
    ><hlopt|(),><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ \ \ \ \ append
    ><hlopt|(><hlstd|gen d><hlopt|) (><hlkwd|Yield ><hlopt|(><hlkwd|GEnd
    ><hlopt|(), ><hlkwd|EOP><hlopt|)))><hlendline|>

    <new-page*><item>Compute lengths of document prefixes, i.e. the position
    of each node counting by characters from the beginning of document.

    <hlkwa|let rec ><hlstd|docpos curpos ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwd|Await ><hlopt|(><hlkwa|function><hlendline|We input from a
    <verbatim|doc_e> pipe><next-line><hlstd| \ ><hlopt|\| ><hlkwd|TE
    ><hlopt|(><hlstd|<textunderscore>><hlopt|, ><hlstd|z><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|Yield
    ><hlopt|(><hlkwd|TE ><hlopt|(><hlstd|curpos><hlopt|,
    ><hlstd|z><hlopt|),><hlendline|and output <verbatim|doc_e> annotated with
    position.><next-line><hlstd| \ \ \ \ \ \ \ \ \ \ docpos
    ><hlopt|(><hlstd|curpos ><hlopt|+ ><hlkwc|String><hlopt|.><hlstd|length
    z><hlopt|))><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|LE
    ><hlstd|<textunderscore> ><hlopt|-\<gtr\>><hlendline|Spice and line
    breaks increase position by 1.><next-line><hlstd| \ \ \ ><hlkwd|Yield
    ><hlopt|(><hlkwd|LE ><hlstd|curpos><hlopt|, ><hlstd|docpos
    ><hlopt|(><hlstd|curpos ><hlopt|+ ><hlnum|1><hlopt|))><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|GBeg ><hlstd|<textunderscore>
    ><hlopt|-\<gtr\>><hlendline|Groups do not increase
    position.><next-line><hlstd| \ \ \ ><hlkwd|Yield ><hlopt|(><hlkwd|GBeg
    ><hlstd|curpos><hlopt|, ><hlstd|docpos
    curpos><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|GEnd
    ><hlstd|<textunderscore> ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwd|Yield ><hlopt|(><hlkwd|GEnd ><hlstd|curpos><hlopt|,
    ><hlstd|docpos curpos><hlopt|))><hlendline|><hlstd| \ >

    <hlkwa|let ><hlstd|docpos ><hlopt|= ><hlstd|docpos
    ><hlnum|0><hlendline|The whole document starts at 0.>

    <new-page*><item>Put the end position of the group into the group
    beginning marker, so that we can know whether to break it into multiple
    lines.

    <hlkwa|let rec ><hlstd|grends grstack
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwd|Await
    ><hlopt|(><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|TE ><hlstd|<textunderscore> <hlopt|\|> ><hlkwd|LE
    ><hlstd|<textunderscore> ><hlkwa|as ><hlstd|e
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|(><hlkwa|match ><hlstd|grstack
    ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| [] -\<gtr\>
    ><hlkwd|Yield ><hlopt|(><hlstd|e><hlopt|, ><hlstd|grends
    ><hlopt|[])><hlendline|We can yield only when><next-line><hlstd|
    \ \ \ <hlopt|\|> gr><hlopt|::><hlstd|grs ><hlopt|-\<gtr\> ><hlstd|grends
    ><hlopt|((><hlstd|e><hlopt|::><hlstd|gr><hlopt|)::><hlstd|grs><hlopt|))><hlendline|no
    group is waiting.><next-line><hlstd| \ ><hlopt|\| ><hlkwd|GBeg
    ><hlstd|<textunderscore> ><hlopt|-\<gtr\> ><hlstd|grends
    ><hlopt|([]::><hlstd|grstack><hlopt|)><hlendline|Wait for end of
    group.><next-line><hlstd| \ ><hlopt|\| ><hlkwd|GEnd ><hlstd|endp
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match
    ><hlstd|grstack ><hlkwa|with><hlendline|End the group on top of
    stack.><next-line><hlstd| \ \ \ ><hlopt|\| [] -\<gtr\> ><hlstd|failwith
    ><hlstr|"grends: unmatched group end marker"><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|\| [><hlstd|gr><hlopt|] -\<gtr\>><hlendline|Top group -- we
    can yield now.><next-line><hlstd| \ \ \ \ \ yield<textunderscore>all<hlendline|><next-line>
    \ \ \ \ \ \ \ ><hlopt|(><hlkwd|GBeg ><hlstd|endp><hlopt|::><hlkwc|List><hlopt|.><hlstd|rev
    ><hlopt|(><hlkwd|GEnd ><hlstd|endp><hlopt|::><hlstd|gr><hlopt|))><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlopt|(><hlstd|grends
    ><hlopt|[])><hlendline|><next-line><hlstd| \ \ \ <hlopt|\|>
    gr><hlopt|::><hlstd|par><hlopt|::><hlstd|grs
    ><hlopt|-\<gtr\>><hlendline|Remember in parent group
    instead.><next-line><hlstd| \ \ \ \ \ ><hlkwa|let ><hlstd|par ><hlopt|=
    ><hlkwd|GEnd ><hlstd|endp><hlopt|::><hlstd|gr @ ><hlopt|[><hlkwd|GBeg
    ><hlstd|endp><hlopt|] ><hlstd|@ par ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ grends ><hlopt|(><hlstd|par><hlopt|::><hlstd|grs><hlopt|))><hlendline|Could
    use <em|catenable lists> above.>

    <new-page*><item>That's waiting too long! We can stop waiting when the
    width of a group exceeds line limit. <hlkwd|GBeg> will not store end of
    group when it is irrelevant.

    <hlkwa|let rec ><hlstd|grends w grstack
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|flush tail
    ><hlopt|=><hlendline|When the stack exceeds width
    <verbatim|w>,><verbatim|<next-line> \ \ \ yield<textunderscore>all><hlendline|flush
    it -- yield everything in it.><verbatim|<next-line>
    \ \ \ \ \ ><hlopt|(><hlstd|rev<textunderscore>concat<textunderscore>map
    <math|\<sim\>>prep><hlopt|:(><hlkwd|GBeg Too<textunderscore>far><hlopt|)
    ><hlstd|snd grstack><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ \ \ tail ><hlkwa|in><hlendline|Above: concatenate in rev. with
    <verbatim|prep> before each part.><next-line><hlstd| \ ><hlkwd|Await
    ><hlopt|(><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|TE ><hlopt|(><hlstd|curp><hlopt|,
    ><hlstd|<textunderscore>><hlopt|) \| ><hlkwd|LE ><hlstd|curp ><hlkwa|as
    ><hlstd|e ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|(><hlkwa|match ><hlstd|grstack
    ><hlkwa|with><hlendline|Remember beginning of groups in the
    stack.><next-line><hlstd| \ \ \ ><hlopt|\| [] -\<gtr\> ><hlkwd|Yield
    ><hlopt|(><hlstd|e><hlopt|, ><hlstd|grends w
    ><hlopt|[])><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    (><hlstd|begp><hlopt|, ><hlstd|<textunderscore>><hlopt|)::><hlstd|<textunderscore>
    ><hlkwa|when ><hlstd|curp><hlopt|-><hlstd|begp ><hlopt|\<gtr\> ><hlstd|w
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ flush
    ><hlopt|(><hlkwd|Yield ><hlopt|(><hlstd|e><hlopt|, ><hlstd|grends w
    ><hlopt|[]))><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    (><hlstd|begp><hlopt|, ><hlstd|gr><hlopt|)::><hlstd|grs ><hlopt|-\<gtr\>
    ><hlstd|grends w ><hlopt|((><hlstd|begp><hlopt|,
    ><hlstd|e><hlopt|::><hlstd|gr><hlopt|)::><hlstd|grs><hlopt|))><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|GBeg ><hlstd|begp ><hlopt|-\<gtr\> ><hlstd|grends w
    ><hlopt|((><hlstd|begp><hlopt|, [])::><hlstd|grstack><hlopt|)><hlendline|><next-line><new-page*><hlstd|
    \ ><hlopt|\| ><hlkwd|GEnd ><hlstd|endp ><hlkwa|as ><hlstd|e
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match
    ><hlstd|grstack ><hlkwa|with><hlendline|No longer fail when the stack is
    empty --><next-line><hlstd| \ \ \ ><hlopt|\| [] -\<gtr\> ><hlkwd|Yield
    ><hlopt|(><hlstd|e><hlopt|, ><hlstd|grends w ><hlopt|[])><hlendline|could
    have been flushed.><next-line><hlstd| \ \ \ ><hlopt|\|
    (><hlstd|begp><hlopt|, ><hlstd|<textunderscore>><hlopt|)::><hlstd|<textunderscore>
    ><hlkwa|when ><hlstd|endp><hlopt|-><hlstd|begp ><hlopt|\<gtr\> ><hlstd|w
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ flush
    ><hlopt|(><hlkwd|Yield ><hlopt|(><hlstd|e><hlopt|, ><hlstd|grends w
    ><hlopt|[]))><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    [><hlstd|<textunderscore>><hlopt|, ><hlstd|gr><hlopt|]
    -\<gtr\>><hlendline|If width not exceeded,><verbatim|<next-line>
    \ \ \ \ \ yield<textunderscore>all><hlendline|work as before
    optimization.><verbatim|<next-line> \ \ \ \ \ \ \ ><hlopt|(><hlkwd|GBeg
    ><hlopt|(><hlkwd|Pos ><hlstd|endp><hlopt|)::><hlkwc|List><hlopt|.><hlstd|rev
    ><hlopt|(><hlkwd|GEnd ><hlstd|endp><hlopt|::><hlstd|gr><hlopt|))><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlopt|(><hlstd|grends w
    ><hlopt|[])><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    (><hlstd|<textunderscore>><hlopt|, ><hlstd|gr><hlopt|)::(><hlstd|par<textunderscore>begp><hlopt|,
    ><hlstd|par><hlopt|)::><hlstd|grs ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|let ><hlstd|par ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwd|GEnd ><hlstd|endp><hlopt|::><hlstd|gr @
    ><hlopt|[><hlkwd|GBeg ><hlopt|(><hlkwd|Pos ><hlstd|endp><hlopt|)]
    ><hlstd|@ par ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ grends
    w ><hlopt|((><hlstd|par<textunderscore>begp><hlopt|,
    ><hlstd|par><hlopt|)::><hlstd|grs><hlopt|))><hlendline|>

    <item>Initial stack is empty:

    <hlkwa|let ><hlstd|grends w ><hlopt|= ><hlstd|grends w
    ><hlopt|[]><hlendline|>

    <new-page*><item>Finally we produce the resulting stream of strings.

    <hlkwa|let rec ><hlstd|format w ><hlopt|(><hlstd|inline><hlopt|,
    ><hlstd|endlpos ><hlkwa|as ><hlstd|st><hlopt|) =><hlendline|State: the
    stack of><next-line><hlstd| \ ><hlkwd|Await
    ><hlopt|(><hlkwa|function><hlendline|``group fits in line''; position
    where end of line would be.><next-line><hlstd| \ ><hlopt|\| ><hlkwd|TE
    ><hlopt|(><hlstd|<textunderscore>><hlopt|, ><hlstd|z><hlopt|) -\<gtr\>
    ><hlkwd|Yield ><hlopt|(><hlstd|z><hlopt|, ><hlstd|format w
    st><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|LE
    ><hlstd|p ><hlkwa|when ><hlkwc|List><hlopt|.><hlstd|hd inline
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|Yield
    ><hlopt|(><hlstr|" ><hlstr|"><hlopt|, ><hlstd|format w
    st><hlopt|)><hlendline|After return, line has <verbatim|w> free
    space.><next-line><hlstd| \ ><hlopt|\| ><hlkwd|LE ><hlstd|p
    ><hlopt|-\<gtr\> ><hlkwd|Yield ><hlopt|(><hlstr|"<hlesc|\\n>"><hlopt|,
    ><hlstd|format w ><hlopt|(><hlstd|inline><hlopt|,
    ><hlstd|p><hlopt|+><hlstd|w><hlopt|))><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|GBeg Too<textunderscore>far
    ><hlopt|-\<gtr\>><hlendline|Group with end too far is not
    inline.><next-line><hlstd| \ \ \ format w
    ><hlopt|(><hlkwa|false><hlopt|::><hlstd|inline><hlopt|,
    ><hlstd|endlpos><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|GBeg ><hlopt|(><hlkwd|Pos ><hlstd|p><hlopt|)
    -\<gtr\>><hlendline|Group is inline if it ends soon
    enough.><next-line><hlstd| \ \ \ format w
    ><hlopt|((><hlstd|p><hlopt|\<less\>=><hlstd|endlpos><hlopt|)::><hlstd|inline><hlopt|,
    ><hlstd|endlpos><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|GEnd ><hlstd|<textunderscore> ><hlopt|-\<gtr\> ><hlstd|format w
    ><hlopt|(><hlkwc|List><hlopt|.><hlstd|tl inline><hlopt|,
    ><hlstd|endlpos><hlopt|))><hlendline|>

    <hlkwa|let ><hlstd|format w ><hlopt|= ><hlstd|format w
    ><hlopt|([><hlkwa|false><hlopt|], ><hlstd|w><hlopt|)><hlendline|Break
    lines outside of groups.>

    <item>Put the pipes together:

    <hlkwa|let ><hlstd|pretty<textunderscore>print w doc
    ><hlopt|=><hlendline|><next-line><draw-over|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|c>|<cwith|1|1|5|5|cell-halign|c>|<table|<row|<cell|<block|<tformat|<table|<row|<cell|<verbatim|gen
    doc>>>>>>>|<cell|<block|<tformat|<table|<row|<cell|<verbatim|docpos>>>>>>>|<cell|<block|<tformat|<table|<row|<cell|<verbatim|grends
    w>>>>>>>|<cell|<block|<tformat|<table|<row|<cell|<verbatim|format
    w>>>>>>>|<cell|<block|<tformat|<table|<row|<cell|<verbatim|iterate
    <tiny|print_string>>>>>>>>>>>>|<with|gr-color|red|gr-arrow-end|\|\<gtr\>|gr-grid|<tuple|empty>|gr-grid-old|<tuple|cartesian|<point|0|0>|1>|gr-edit-grid-aspect|<tuple|<tuple|axes|none>|<tuple|1|none>|<tuple|10|none>>|gr-edit-grid|<tuple|empty>|gr-edit-grid-old|<tuple|cartesian|<point|0|0>|1>|<graphics|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-7.32332|-0.0176611>|<point|-6.8788199497288|-0.0176610662786083>>>|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-4.10597|-0.0176611>|<point|-3.64029633549411|-0.0176610662786083>>>|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-0.147771|0.00350575>|<point|0.275565550998809|0.00350575472946157>>>|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|3.76809|-0.0176611>|<point|4.23376107950787|0.00350575472946157>>>>>>

    <new-page*><item>Factorize <verbatim|format> so that various line
    breaking styles can be plugged in.

    <hlkwa|let rec ><hlstd|breaks w ><hlopt|(><hlstd|inline><hlopt|,
    ><hlstd|endlpos ><hlkwa|as ><hlstd|st><hlopt|)
    =><hlendline|><next-line><hlstd| \ ><hlkwd|Await
    ><hlopt|(><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|TE ><hlstd|<textunderscore> ><hlkwa|as ><hlstd|e ><hlopt|-\<gtr\>
    ><hlkwd|Yield ><hlopt|(><hlstd|e><hlopt|, ><hlstd|breaks w
    st><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|LE
    ><hlstd|p ><hlkwa|when ><hlkwc|List><hlopt|.><hlstd|hd inline
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|Yield
    ><hlopt|(><hlkwd|TE ><hlopt|(><hlstd|p><hlopt|, ><hlstr|" "><hlopt|),
    ><hlstd|breaks w st><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|LE ><hlstd|p ><hlkwa|as ><hlstd|e ><hlopt|-\<gtr\> ><hlkwd|Yield
    ><hlopt|(><hlstd|e><hlopt|, ><hlstd|breaks w
    ><hlopt|(><hlstd|inline><hlopt|, ><hlstd|p><hlopt|+><hlstd|w><hlopt|))><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|GBeg Too<textunderscore>far ><hlkwa|as ><hlstd|e
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|Yield
    ><hlopt|(><hlstd|e><hlopt|, ><hlstd|breaks w
    ><hlopt|(><hlkwa|false><hlopt|::><hlstd|inline><hlopt|,
    ><hlstd|endlpos><hlopt|))><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|GBeg ><hlopt|(><hlkwd|Pos ><hlstd|p><hlopt|) ><hlkwa|as ><hlstd|e
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|Yield
    ><hlopt|(><hlstd|e><hlopt|, ><hlstd|breaks w
    ><hlopt|((><hlstd|p><hlopt|\<less\>=><hlstd|endlpos><hlopt|)::><hlstd|inline><hlopt|,
    ><hlstd|endlpos><hlopt|))><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|GEnd ><hlstd|<textunderscore> ><hlkwa|as ><hlstd|e
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|Yield
    ><hlopt|(><hlstd|e><hlopt|, ><hlstd|breaks w
    ><hlopt|(><hlkwc|List><hlopt|.><hlstd|tl inline><hlopt|,
    ><hlstd|endlpos><hlopt|)))><hlendline|><next-line><hlendline|><next-line><hlkwa|let
    ><hlstd|breaks w ><hlopt|= ><hlstd|breaks w
    ><hlopt|([><hlkwa|false><hlopt|], ><hlstd|w><hlopt|)><hlstd|
    \ ><hlendline|><next-line><hlkwa|let rec ><hlstd|emit
    ><hlopt|=><hlendline|><new-page*><next-line><hlstd| \ ><hlkwd|Await
    ><hlopt|(><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|TE ><hlopt|(><hlstd|<textunderscore>><hlopt|, ><hlstd|z><hlopt|)
    -\<gtr\> ><hlkwd|Yield ><hlopt|(><hlstd|z><hlopt|,
    ><hlstd|emit><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|LE ><hlstd|<textunderscore> ><hlopt|-\<gtr\> ><hlkwd|Yield
    ><hlopt|(><hlstr|"><hlesc|<math|>n><hlstr|"><hlopt|,
    ><hlstd|emit><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|GBeg ><hlstd|<textunderscore> <hlopt|\|> ><hlkwd|GEnd
    ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
    ><hlstd|emit><hlopt|)><hlendline|><next-line><hlendline|><next-line><hlkwa|let
    ><hlstd|pretty<textunderscore>print w doc
    ><hlopt|=><hlendline|><next-line><hlstd| \ gen doc
    ><hlopt|\<gtr\>-\<gtr\> ><hlstd|docpos ><hlopt|\<gtr\>-\<gtr\>
    ><hlstd|grends w ><hlopt|\<gtr\>-\<gtr\> ><hlstd|breaks w
    ><hlopt|\<gtr\>-\<gtr\>><hlendline|><next-line><hlstd| \ emit
    ><hlopt|\<gtr\>-\<gtr\> ><hlstd|iterate
    print<textunderscore>string><hlendline|>

    <new-page*><item>Tests.

    <tiny|<hlkwa|let ><hlopt|(++) ><hlstd|d1 d2 ><hlopt|= ><hlkwd|Cat
    ><hlopt|(><hlstd|d1><hlopt|, ><hlkwd|Cat ><hlopt|(><hlkwd|Line><hlopt|,
    ><hlstd|d2><hlopt|))><hlendline|><next-line><hlkwa|let ><hlopt|(!)
    ><hlstd|s ><hlopt|= ><hlkwd|Text ><hlstd|s><hlendline|><next-line><hlkwa|let
    ><hlstd|test<textunderscore>doc ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwd|Group ><hlopt|(!><hlstr|"Document"><hlstd|
    ><hlopt|++><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ \ \ ><hlkwd|Group ><hlopt|(!><hlstr|"First
    part"><hlstd| ><hlopt|++ !><hlstr|"Second
    part"><hlopt|))><hlendline|><next-line><hlendline|><next-line><hlkwa|let
    ><hlstd|print<textunderscore>e<textunderscore>doc pr<textunderscore>p
    pr<textunderscore>ep ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|TE ><hlopt|(><hlstd|p><hlopt|,><hlstd|z><hlopt|)
    -\<gtr\> ><hlstd|pr<textunderscore>p p><hlopt|;
    ><hlstd|print<textunderscore>endline ><hlopt|(><hlstr|":
    "><hlstd|<textasciicircum>z><hlopt|)><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|LE ><hlstd|p ><hlopt|-\<gtr\>
    ><hlstd|pr<textunderscore>p p><hlopt|;
    ><hlstd|print<textunderscore>endline ><hlstr|":
    endline"><hlstd|<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|GBeg
    ><hlstd|ep ><hlopt|-\<gtr\> ><hlstd|pr<textunderscore>ep ep><hlopt|;
    ><hlstd|print<textunderscore>endline ><hlstr|":
    GBeg"><hlstd|<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|GEnd ><hlstd|p
    ><hlopt|-\<gtr\> ><hlstd|pr<textunderscore>p p><hlopt|;
    ><hlstd|print<textunderscore>endline ><hlstr|":
    GEnd"><hlendline|><next-line><hlkwa|let ><hlstd|noop ><hlopt|() =
    ()><hlendline|><next-line><hlkwa|let ><hlstd|print<textunderscore>pos
    ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|Pos ><hlstd|p ><hlopt|-\<gtr\> ><hlstd|print<textunderscore>int
    p<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Too<textunderscore>far
    ><hlopt|-\<gtr\> ><hlstd|print<textunderscore>string ><hlstr|"Too
    far"><hlendline|><next-line><hlendline|><next-line><hlkwa|let
    ><hlstd|<textunderscore> ><hlopt|= ><hlstd|gen test<textunderscore>doc
    ><hlopt|\<gtr\>-\<gtr\>><hlendline|><next-line><hlstd| \ iterate
    ><hlopt|(><hlstd|print<textunderscore>e<textunderscore>doc noop
    noop><hlopt|)><hlendline|><next-line><hlkwa|let ><hlstd|<textunderscore>
    ><hlopt|= ><hlstd|gen test<textunderscore>doc ><hlopt|\<gtr\>-\<gtr\>
    ><hlstd|docpos ><hlopt|\<gtr\>-\<gtr\>><hlendline|><next-line><hlstd|
    \ iterate ><hlopt|(><hlstd|print<textunderscore>e<textunderscore>doc
    print<textunderscore>int print<textunderscore>int><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|<textunderscore> ><hlopt|= ><hlstd|gen test<textunderscore>doc
    ><hlopt|\<gtr\>-\<gtr\> ><hlstd|docpos ><hlopt|\<gtr\>-\<gtr\>
    ><hlstd|grends ><hlnum|20 ><hlopt|\<gtr\>-\<gtr\>><hlendline|><next-line><hlstd|
    \ iterate ><hlopt|(><hlstd|print<textunderscore>e<textunderscore>doc
    print<textunderscore>int print<textunderscore>pos><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|<textunderscore> ><hlopt|= ><hlstd|gen test<textunderscore>doc
    ><hlopt|\<gtr\>-\<gtr\> ><hlstd|docpos ><hlopt|\<gtr\>-\<gtr\>
    ><hlstd|grends ><hlnum|30 ><hlopt|\<gtr\>-\<gtr\>><hlendline|><next-line><hlstd|
    \ iterate ><hlopt|(><hlstd|print<textunderscore>e<textunderscore>doc
    print<textunderscore>int print<textunderscore>pos><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|<textunderscore> ><hlopt|= ><hlstd|gen test<textunderscore>doc
    ><hlopt|\<gtr\>-\<gtr\> ><hlstd|docpos ><hlopt|\<gtr\>-\<gtr\>
    ><hlstd|grends ><hlnum|60 ><hlopt|\<gtr\>-\<gtr\>><hlendline|><next-line><hlstd|
    \ iterate ><hlopt|(><hlstd|print<textunderscore>e<textunderscore>doc
    print<textunderscore>int print<textunderscore>pos><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|<textunderscore> ><hlopt|= ><hlstd|pretty<textunderscore>print
    ><hlnum|20 ><hlstd|test<textunderscore>doc><hlendline|><next-line><hlkwa|let
    ><hlstd|<textunderscore> ><hlopt|= ><hlstd|pretty<textunderscore>print
    ><hlnum|30 ><hlstd|test<textunderscore>doc><hlendline|><next-line><hlkwa|let
    ><hlstd|<textunderscore> ><hlopt|= ><hlstd|pretty<textunderscore>print
    ><hlnum|60 ><hlstd|test<textunderscore>doc><hlendline|>>
  </itemize>
</body>

<\initial>
  <\collection>
    <associate|language|american>
    <associate|magnification|2>
    <associate|page-medium|paper>
    <associate|page-orientation|landscape>
    <associate|page-type|letter>
    <associate|par-hyphen|normal>
    <associate|preamble|false>
    <associate|sfactor|7>
  </collection>
</initial>

<\references>
  <\collection>
    <associate|auto-1|<tuple|1|2>>
    <associate|auto-10|<tuple|8|26>>
    <associate|auto-11|<tuple|8.1|28>>
    <associate|auto-12|<tuple|8.2|31>>
    <associate|auto-13|<tuple|5|32>>
    <associate|auto-14|<tuple|5|33>>
    <associate|auto-15|<tuple|6|34>>
    <associate|auto-16|<tuple|7|36>>
    <associate|auto-17|<tuple|8|38>>
    <associate|auto-18|<tuple|9|39>>
    <associate|auto-19|<tuple|10.0.1|40>>
    <associate|auto-2|<tuple|2|3>>
    <associate|auto-20|<tuple|11|42>>
    <associate|auto-21|<tuple|12|45>>
    <associate|auto-22|<tuple|12|48>>
    <associate|auto-23|<tuple|12|51>>
    <associate|auto-24|<tuple|12|53>>
    <associate|auto-25|<tuple|13|55>>
    <associate|auto-3|<tuple|3|6>>
    <associate|auto-4|<tuple|4|9>>
    <associate|auto-5|<tuple|5|12>>
    <associate|auto-6|<tuple|5.1|14>>
    <associate|auto-7|<tuple|5.2|16>>
    <associate|auto-8|<tuple|6|19>>
    <associate|auto-9|<tuple|7|24>>
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
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Laziness>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Evaluation
      strategies and parameter passing> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Call-by-name:
      streams> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Lazy
      values> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Power
      series and differential equations> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Power series / polynomial
      operations <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6>>

      <with|par-left|<quote|1.5fn>|<new-page*>Differential equations
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-7>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Arbitrary
      precision computation> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-8><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Circular
      data structures: double-linked list>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-9><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Input-Output
      streams> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-10><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Pipes
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-11>>

      <with|par-left|<quote|1.5fn>|<new-page*>Example: pretty-printing
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-12>>
    </associate>
  </collection>
</auxiliary>