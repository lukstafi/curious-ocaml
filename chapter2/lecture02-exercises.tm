<TeXmacs|1.0.7.15>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming>

  <\title>
    Algebraic Data Types
  </title>

  <\exercise>
    Due to Yaron Minsky.

    Consider a datatype to store internet connection information. The time
    <verbatim|when_initiated> marks the start of connecting and is not needed
    after the connection is established (it is only used to decide whether to
    give up trying to connect). The ping information is available for
    established connection but not straight away.

    <next-line><hlstd|><hlkwa|type ><hlstd|connection<textunderscore>state
    ><hlopt|=><hlendline|><next-line><hlstd|><hlstd| \ ><hlopt|\|
    ><hlkwd|Connecting><hlendline|><next-line><hlstd|><hlstd| \ ><hlopt|\|
    ><hlkwd|Connected><hlendline|><next-line><hlstd|><hlstd| \ ><hlopt|\|
    ><hlkwd|Disconnected><hlendline|><next-line><hlstd|><hlendline|><next-line><hlkwa|type
    ><hlstd|connection<textunderscore>info ><hlopt|=
    {><hlendline|><next-line><hlstd|><hlstd| \ ><hlstd|state ><hlopt|:
    ><hlstd|connection<textunderscore>state><hlopt|;><hlendline|><next-line><hlstd|><hlstd|
    \ ><hlstd|server ><hlopt|: ><hlstd|><hlkwc|Inet<textunderscore>addr><hlstd|><hlopt|.><hlstd|t><hlopt|;><hlendline|><next-line><hlstd|><hlstd|
    \ ><hlstd|last<textunderscore>ping<textunderscore>time ><hlopt|:
    ><hlstd|><hlkwc|Time><hlstd|><hlopt|.><hlstd|t
    ><hlkwb|option><hlstd|><hlopt|;><hlendline|><next-line><hlstd|><hlstd|
    \ ><hlstd|last<textunderscore>ping<textunderscore>id ><hlopt|:
    ><hlstd|><hlkwb|int option><hlstd|><hlopt|;><hlendline|><next-line><hlstd|><hlstd|
    \ ><hlstd|session<textunderscore>id ><hlopt|: ><hlstd|><hlkwb|string
    option><hlstd|><hlopt|;><hlendline|><next-line><hlstd|><hlstd|
    \ ><hlstd|when<textunderscore>initiated ><hlopt|:
    ><hlstd|><hlkwc|Time><hlstd|><hlopt|.><hlstd|t
    ><hlkwb|option><hlstd|><hlopt|;><hlendline|><next-line><hlstd|><hlstd|
    \ ><hlstd|when<textunderscore>disconnected ><hlopt|:
    ><hlstd|><hlkwc|Time><hlstd|><hlopt|.><hlstd|t
    ><hlkwb|option><hlstd|><hlopt|;><hlendline|><next-line><hlstd|><hlopt|}><hlstd|><hlendline|>

    (The types <hlkwc|Time><hlstd|><hlopt|.><hlstd|t >and
    <hlkwc|Inet<textunderscore>addr><hlstd|><hlopt|.><hlstd|t> come from the
    library <em|Core> used where Yaron Minsky works. You can replace them
    with <verbatim|float> and <hlkwc|Unix><hlstd|><hlopt|.><hlstd|inet_addr>.
    Load the Unix library in the interactive toplevel by <verbatim|#load
    "unix.cma";;>.) Rewrite the type definitions so that the datatype will
    contain only reasonable combinations of information.
  </exercise>

  <\exercise>
    In OCaml, functions can have named arguments, and also default arguments
    (parameters, possibly with default values, which can be omitted when
    providing arguments). The names of arguments are called labels. The
    labels can be different from the names of the argument values:

    <next-line><hlkwa|let ><hlstd|f <math|\<sim\>>meaningful<textunderscore>name><hlopt|:><hlstd|n
    ><hlopt|= ><hlstd|n><hlopt|+><hlnum|1><hlendline|><next-line><hlkwa|let
    ><hlstd|<textunderscore> ><hlopt|= ><hlstd|f
    <math|\<sim\>>meaningful<textunderscore>name><hlopt|:><hlnum|5><hlendline|We
    do not need the result so we ignore it.>

    \;

    When the label and value names are the same, the syntax is shorter:

    <next-line><hlkwa|let ><hlstd|g <math|\<sim\>>pos <math|\<sim\>>len
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwc|StringLabels><hlopt|.><hlstd|sub
    ><hlstr|"0123456789abcdefghijklmnopqrstuvwxyz"><hlstd| <math|\<sim\>>pos
    <math|\<sim\>>len><hlendline|><next-line><hlkwa|let ><hlopt|()
    =><hlendline|A nicer way to mark computations that do not produce a
    result (return <verbatim|unit>).><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|pos ><hlopt|= ><hlkwc|Random><hlopt|.><hlkwb|int ><hlnum|26
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|len
    ><hlopt|= ><hlkwc|Random><hlopt|.><hlkwb|int ><hlnum|10
    ><hlkwa|in><hlendline|><next-line><hlstd| \ print<textunderscore>string
    ><hlopt|(><hlstd|g <math|\<sim\>>pos <math|\<sim\>>len><hlopt|)><hlendline|><next-line>

    When some function arguments are optional, the function has to take
    non-optional arguments after the last optional argument. When the
    optional parameters have default values:

    <next-line><hlkwa|let ><hlstd|h ?><hlopt|(><hlstd|len><hlopt|=><hlnum|1><hlopt|)
    ><hlstd|pos ><hlopt|= ><hlstd|g <math|\<sim\>>pos
    <math|\<sim\>>len><hlendline|><next-line><hlkwa|let ><hlopt|() =
    ><hlstd|print<textunderscore>string ><hlopt|(><hlstd|h
    ><hlnum|10><hlopt|)><hlendline|><next-line>

    Optional arguments are implemented as parameters of an option type. This
    allows us to check whether the argument was actually provided:

    <next-line><hlkwa|let ><hlstd|foo ?bar n
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match ><hlstd|bar
    ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|None
    ><hlopt|-\<gtr\> ><hlstr|"Argument = "><hlstd| <textasciicircum>
    string<textunderscore>of<textunderscore>int n<hlendline|><next-line>
    \ \ \ ><hlopt|\| ><hlkwd|Some ><hlstd|m ><hlopt|-\<gtr\> ><hlstr|"Sum =
    "><hlstd| <textasciicircum> string<textunderscore>of<textunderscore>int
    ><hlopt|(><hlstd|m ><hlopt|+ ><hlstd|n><hlopt|)><hlendline|><next-line><hlopt|;;><hlendline|><next-line><hlstd|foo
    ><hlnum|5><hlopt|;;><hlendline|><next-line><hlstd|foo
    <math|\<sim\>>bar><hlopt|:><hlnum|5 7><hlopt|;;><hlendline|><next-line>

    We can also provide the option value directly:

    <next-line><hlkwa|let ><hlstd|bar ><hlopt|= ><hlkwa|if
    ><hlkwc|Random><hlopt|.><hlkwb|int ><hlnum|10 ><hlopt|\<less\> ><hlnum|5
    ><hlkwa|then ><hlkwd|None ><hlkwa|else ><hlkwd|Some ><hlnum|7
    ><hlkwa|in><hlendline|><next-line><hlstd|foo ?bar
    ><hlnum|7><hlopt|;;><hlendline|><next-line>

    <\enumerate>
      <item>Observe the types that functions with labelled and optional
      arguments have. Come up with coding style guidelines, e.g. when to use
      labeled arguments.

      <item>Write a rectangle-drawing procedure that takes three optional
      arguments: left-upper corner, right-lower corner, and a width-height
      pair. It should draw a correct rectangle whenever two arguments are
      given, and raise exception otherwise. Load the graphics library in the
      interactive toplevel by <verbatim|#load "graphics.cma";;>. Use
      ``functions'' <verbatim|invalid_arg>,
      <hlkwc|Graphics><hlopt|.><verbatim|open_graph> and
      <hlkwc|Graphics><hlopt|.><verbatim|draw_rect>.

      <item>Write a function that takes an optional argument of arbitrary
      type and a function argument, and passes the optional argument to the
      function without inspecting it.
    </enumerate>
  </exercise>

  <\exercise>
    From last year's exam.

    <\enumerate>
      <item>Give the (most general) types of the following expressions,
      either by guessing or inferring by hand:

      <\enumerate>
        <item><hlstd|><hlkwa|let ><hlstd|double f y ><hlopt|= ><hlstd|f
        ><hlopt|(><hlstd|f y><hlopt|) ><hlstd|><hlkwa|in fun ><hlstd|g x
        ><hlopt|-\<gtr\> ><hlstd|double ><hlopt|(><hlstd|g
        x><hlopt|)><hlstd|>

        <item><hlkwa|let rec ><hlstd|tails l ><hlopt|= ><hlkwa|match
        ><hlstd|l ><hlkwa|with ><hlopt|[] -\<gtr\> [] ><hlstd|<hlopt|\|>
        x><hlopt|::><hlstd|xs ><hlopt|-\<gtr\>
        ><hlstd|xs><hlopt|::><hlstd|tails xs
        ><hlkwa|in><hlendline|><next-line><hlkwa|fun ><hlstd|l
        ><hlopt|-\<gtr\> ><hlkwc|List><hlopt|.><hlstd|combine l
        ><hlopt|(><hlstd|tails l><hlopt|)>
      </enumerate>

      <item>Give example expressions that have the following types (without
      using type constraints):

      <\enumerate>
        <item><verbatim|(int -\<gtr\> int) -\<gtr\> bool>

        <item><verbatim|'a option -\<gtr\> 'a list>
      </enumerate>
    </enumerate>
  </exercise>

  <\exercise>
    We have seen in the class, that algebraic data types can be related to
    analytic functions (the subset that can be defined out of polynomials via
    recursion) -- by literally interpreting sum types (i.e. variant types) as
    sums and product types (i.e. tuple and record types) as products. We can
    extend this interpretation to all OCaml types that we introduced, by
    interpreting a function type <math|a\<rightarrow\>b> as <math|b<rsup|a>>,
    <math|b> to the power of <math|a>. Note that the <math|b<rsup|a>>
    notation is actually used to denote functions in set theory.

    <\enumerate>
      <item>Translate <math|a<rsup|b+c*d>> and
      <math|a<rsup|b>*<around*|(|a<rsup|c>|)><rsup|d>> into OCaml types,
      using any distinct types for <math|a,b,c,d>, and using the
      <verbatim|('a,'b) choice = Left of 'a \| Right of 'b> datatype for
      <math|+>. Write the bijection function in both directions.

      <item>Come up with a type <verbatim|'t exp>, that shares with the
      exponential function the following property:
      <math|<frac|\<partial\>exp<around*|(|t|)>|\<partial\>t>=exp<around*|(|t|)>>,
      where we translate a derivative of a type as a context, i.e. the type
      with a ``hole'', as in the lecture. Explain why your answer is correct.
      Hint: in computer science, our logarithms are mostly base 2.
    </enumerate>

    Further reading:<next-line><hlink|http://bababadalgharaghtakamminarronnkonnbro.blogspot.com/2012/10/algebraic-type-systems-combinatorial.html|http://bababadalgharaghtakamminarronnkonnbro.blogspot.com/2012/10/algebraic-type-systems-combinatorial.html>
  </exercise>
</body>

<\initial>
  <\collection>
    <associate|language|american>
    <associate|page-type|letter>
  </collection>
</initial>