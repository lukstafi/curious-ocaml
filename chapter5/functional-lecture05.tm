<TeXmacs|1.0.7.16>

<style|<tuple|beamer|highlight|smileys|beamer-metal-lighter>>

<\body>
  <doc-data|<doc-title|Functional Programming>|<\doc-author-data|<author-name|Šukasz
  Stafiniak>>
    \;
  </doc-author-data|<author-email|lukstafi@gmail.com,
  lukstafi@ii.uni.wroc.pl>|<\author-homepage>
    www.ii.uni.wroc.pl/~lukstafi
  </author-homepage>>>

  <doc-data|<doc-title|Lecture 5: Polymorphism & ADTs>|<\doc-subtitle>
    Parametric types. Abstract Data Types.

    Example: maps using red-black trees.
  </doc-subtitle>|>

  <center|If you see any error on the slides, let me know!>

  <new-page>

  <section|Type Inference>

  We have seen the rules that govern the assignment of types to expressions,
  but how does OCaml guess what types to use, and when no correct types
  exist? It solves equations.

  <\itemize>
    <item>Variables play two roles: of <em|unknowns> and of <em|parameters>.

    <\itemize>
      <item>Inside:

      <hlstd|# ><hlkwa|let ><hlstd|f ><hlopt|=
      ><hlkwc|List><hlopt|.><hlstd|hd><hlopt|;;><hlendline|><next-line><hlkwa|val
      ><hlstd|f ><hlopt|: ><hlstd|'a list ><hlopt|-\<gtr\> ><hlstd|'a>

      <verbatim|'a> is a parameter: it can become any type. Mathematically we
      write: <math|f:\<forall\>\<alpha\>.\<alpha\>
      list\<rightarrow\>\<alpha\>> -- the quantified type is called a
      <em|type scheme>.

      <item>Inside:

      <hlstd|# ><hlkwa|let ><hlstd|x ><hlopt|= ><hlkwb|ref
      ><hlopt|[];;><hlendline|><next-line><hlkwa|val ><hlstd|x ><hlopt|:
      ><hlstd|'<textunderscore>a list ><hlkwb|ref>

      <verbatim|'_a> is an unknown. It stands for a particular type like
      <hlkwb|float> \ or <hlopt|(><hlkwb|int ><hlopt|-\<gtr\>
      ><hlkwb|int><hlopt|)>, OCaml just doesn't yet know the type.

      <item>OCaml only reports unknowns like <verbatim|'_a> in inferred types
      for reasons not relevant to functional programming. When unknowns
      appear in inferred type against our expectations,
      <em|<math|\<eta\>>-expansion> may help: writing <hlkwa|let ><hlstd|f x
      ><hlopt|= ><hlstd|expr x> instead of <hlkwa|let ><hlstd|f ><hlopt|=
      ><hlstd|expr> -- for example:

      <hlstd|# ><hlkwa|let ><hlstd|f ><hlopt|=
      ><hlkwc|List><hlopt|.><hlstd|append
      ><hlopt|[];;><hlendline|><next-line><hlkwa|val ><hlstd|f ><hlopt|:
      ><hlstd|'<textunderscore>a list ><hlopt|-\<gtr\>
      ><hlstd|'<textunderscore>a list ><hlopt|=
      \<less\>><hlkwa|fun><hlopt|\<gtr\>><hlendline|><next-line><hlstd|#
      ><hlkwa|let ><hlstd|f l ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|append
      ><hlopt|[] ><hlstd|l><hlopt|;;><hlendline|><next-line><hlkwa|val
      ><hlstd|f ><hlopt|: ><hlstd|'a list ><hlopt|-\<gtr\> ><hlstd|'a list
      ><hlopt|= \<less\>><hlkwa|fun><hlopt|\<gtr\>>
    </itemize>

    <item>A <em|type environment> specifies what names (corresponding to
    parameters and definitions) are available for an expression, because they
    were introduced above it, and it specifies their types.

    <item>Type inference solves equations over unknowns. ``What has to hold
    so that <math|e:\<tau\>> in type environment <math|\<Gamma\>>?''

    <\itemize>
      <item>If, for example, <math|f:\<forall\>\<alpha\>.\<alpha\>
      list\<rightarrow\>\<alpha\>\<in\>\<Gamma\>>, then for <math|f:\<tau\>>
      we introduce <math|\<gamma\> list\<rightarrow\>\<gamma\>=\<tau\>> for
      some fresh unknown <math|\<gamma\>>.

      <item>For <math|e<rsub|1> e<rsub|2>:\<tau\>> we introduce
      <math|\<beta\>=\<tau\>> and ask for
      <math|e<rsub|1>:\<gamma\>\<rightarrow\>\<beta\>> and
      <math|e<rsub|2>:\<gamma\>>, for some fresh unknowns
      <math|\<beta\>,\<gamma\>>.

      <item>For <math|fun x\<rightarrow\>e:\<tau\>> we introduce
      <math|\<beta\>\<rightarrow\>\<gamma\>=\<tau\>> and ask for
      <math|e:\<gamma\>> in environment <math|<around*|{|x:\<beta\>|}>\<cup\>\<Gamma\>>,
      for some fresh unknowns <math|\<beta\>,\<gamma\>>.

      <item>Case <math|let x=e<rsub|1> in e<rsub|2>:\<tau\>> is different.
      One approach is to <em|first> solve the equations that we get by asking
      for <math|e<rsub|1>:\<beta\>>, for some fresh unknown <math|\<beta\>>.
      Let's say a solution <math|\<beta\>=\<tau\><rsub|\<beta\>>> has been
      found, <math|\<alpha\><rsub|1>\<ldots\>\<alpha\><rsub|n>\<beta\><rsub|1>\<ldots\>\<beta\><rsub|m>>
      are the remaining unknowns in <math|\<tau\><rsub|\<beta\>>>, \ and
      <math|\<alpha\><rsub|1>\<ldots\>\<alpha\><rsub|n>> are all that do not
      appear in <math|\<Gamma\>>. Then we ask for <math|e<rsub|2>:\<tau\>> in
      environment <math|<around*|{|x:\<forall\>\<alpha\><rsub|1>\<ldots\>\<alpha\><rsub|n>.\<tau\><rsub|\<beta\>>|}>\<cup\>\<Gamma\>>.

      <item>Remember that whenever we establish a solution
      <math|\<beta\>=\<tau\><rsub|\<beta\>>> to an unknown <math|\<beta\>>,
      it takes effect everywhere!

      <item>To find a type for <math|e> (in environment <math|\<Gamma\>>), we
      pick a fresh unknown <math|\<beta\>> and ask for <math|e:\<beta\>> (in
      <math|\<Gamma\>>).
    </itemize>

    <item>The ``top-level'' definitions for which the system infers types
    with variables are called <em|polymorphic>, which informally means
    ``working with different shapes of data''.

    <\itemize>
      <item>This kind of polymorphism is called <em|parametric polymorphism>,
      since the types have parameters. A different kind of polymorphism is
      provided by object-oriented programming languages.
    </itemize>
  </itemize>

  <section|<new-page*>Parametric Types>

  <\itemize>
    <item>Polymorphic functions shine when used with polymorphic data types.
    In:

    <hlkwa|type ><hlstd|'a my<textunderscore>list ><hlopt|= ><hlkwd|Empty
    ><hlopt|\| ><hlkwd|Cons ><hlkwa|of ><hlstd|'a ><hlopt|* ><hlstd|'a
    my<textunderscore>list>

    we define lists that can store elements of any type <verbatim|'a>. Now:

    <hlstd|# ><hlkwa|let ><hlstd|tail l ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|match ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|\| ><hlkwd|Empty ><hlopt|-\<gtr\>
    ><hlstd|invalid<textunderscore>arg ><hlstr|"tail"><hlstd|<hlendline|><next-line>
    \ \ \ ><hlopt|\| ><hlkwd|Cons ><hlopt|(><hlstd|<textunderscore>><hlopt|,
    ><hlstd|tl><hlopt|) -\<gtr\> ><hlstd|tl><hlopt|;;><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|val ><hlstd|tail ><hlopt|: ><hlstd|'a
    my<textunderscore>list ><hlopt|-\<gtr\> ><hlstd|'a
    my<textunderscore>list>

    is a polymorphic function: works for lists with elements of any type.

    <item>A <em|parametric type> like <hlstd|'a my<textunderscore>list>
    <em|is not> itself a data type but a family of data types:
    <hlkwb|bool><hlstd| my<textunderscore>list>, <hlkwb|int><hlstd|
    my<textunderscore>list> etc. <em|are> different types.

    <\itemize>
      <item>We say that the type <hlkwb|int><hlstd| my<textunderscore>list>
      <em|instantiates> the parametric type <hlstd|'a
      my<textunderscore>list>.\ 
    </itemize>

    <new-page*><item>In OCaml, the syntax is a bit confusing: type parameters
    precede type name. For example:

    <hlkwa|type ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|)
    ><hlstd|choice ><hlopt|= ><hlkwd|Left ><hlkwa|of ><hlstd|'a <hlopt|\|>
    ><hlkwd|Right ><hlkwa|of ><hlstd|'b>

    has two parameters. Mathematically we would write
    <math|choice<around*|(|\<alpha\>,\<beta\>|)>>.

    <\itemize>
      <item>Functions do not have to be polymorphic:

      <hlstd|# ><hlkwa|let ><hlstd|get<textunderscore>int c
      ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match ><hlstd|c
      ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
      ><hlkwd|Left ><hlstd|i ><hlopt|-\<gtr\>
      ><hlstd|i<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|Right
      ><hlstd|b ><hlopt|-\<gtr\> ><hlkwa|if ><hlstd|b ><hlkwa|then ><hlnum|1
      ><hlkwa|else ><hlnum|0><hlopt|;;><hlendline|><next-line><hlstd|
      \ \ \ \ \ ><hlkwa|val ><hlstd|get<textunderscore>int ><hlopt|:
      (><hlkwb|int><hlopt|, ><hlkwb|bool><hlopt|) ><hlstd|choice
      ><hlopt|-\<gtr\> ><hlkwb|int>
    </itemize>

    <item>In F#, we provide parameters (when more than one) after type name:

    <hlkwa|type ><hlstd|choice><hlopt|\<less\>><verbatim|'a,'><hlstd|b><hlopt|\<gtr\>
    = ><hlkwd|Left ><hlkwa|of ><verbatim|'a ><hlopt|\|><verbatim| Right of
    ><hlstd|'b>

    <item>In Haskell, we provide type parameters similarly to function
    arguments:

    <hlkwd|data ><hlstd|Choice a b ><hlopt|= ><hlstd|Left a <hlopt|\|> Right
    b>
  </itemize>

  <section|<new-page*>Type Inference, Formally>

  <\itemize>
    <item>A statement that an expression has a type in an environment is
    called a <em|type judgement>. For environment
    <math|\<Gamma\>=<around*|{|x:\<forall\>\<alpha\><rsub|1>\<ldots\>\<alpha\><rsub|n>.\<tau\><rsub|x>;\<ldots\>|}>>,
    expression <math|e> and type <math|\<tau\>> we write

    <\equation*>
      \<Gamma\>\<vdash\>e:\<tau\>
    </equation*>

    <item>We will derive the equations in one go using
    <math|<around*|\<llbracket\>|\<cdot\>|\<rrbracket\>>>, to be solved
    later. Besides equations we will need to manage introduced variables,
    using existential quantification.

    <item>For local definitions we require to remember what constraints
    should hold when the definition is used. Therefore we extend <em|type
    schemes> in the environment to: <math|\<Gamma\>=<around*|{|x:\<forall\>\<beta\><rsub|1>\<ldots\>\<beta\><rsub|m><around*|[|\<exists\>\<alpha\><rsub|1>\<ldots\>\<alpha\><rsub|n>.D|]>.\<tau\><rsub|x>;\<ldots\>|}>>
    where <math|D> are equations -- keeping the variables
    <math|\<alpha\><rsub|1>\<ldots\>\<alpha\><rsub|n>> introduced while
    deriving <math|D> in front.

    <\itemize>
      <item>A simpler form would be enough:
      <math|\<Gamma\>=<around*|{|x:\<forall\>\<beta\><around*|[|\<exists\>\<alpha\><rsub|1>\<ldots\>\<alpha\><rsub|n>.D|]>.\<beta\>;\<ldots\>|}>>
    </itemize>
  </itemize>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|\<llbracket\>|\<Gamma\>\<vdash\>x:\<tau\>|\<rrbracket\>>>|<cell|=>|<cell|\<exists\><wide|\<beta\><rprime|'>|\<bar\>><wide|\<alpha\>|\<bar\>><rprime|'>.<around|(|D<around|[|<wide|\<beta\>|\<bar\>><wide|\<alpha\>|\<bar\>>\<assign\><wide|\<beta\><rprime|'>|\<bar\>><wide|\<alpha\>|\<bar\>><rprime|'>|]>\<wedge\>\<tau\><rsub|x><around|[|<wide|\<beta\>|\<bar\>><wide|\<alpha\>|\<bar\>>\<assign\><wide|\<beta\><rprime|'>|\<bar\>><wide|\<alpha\>|\<bar\>><rprime|'>|]><wide|=|\<dot\>>\<tau\>|)>>>|<row|<cell|>|<cell|>|<cell|<text|where
    >\<Gamma\><around|(|x|)>=\<forall\><wide|\<beta\>|\<bar\>><around|[|\<exists\><wide|\<alpha\>|\<bar\>>.D|]>.\<tau\><rsub|x>,<wide|\<beta\><rprime|'>|\<bar\>><wide|\<alpha\>|\<bar\>><rprime|'>#FV<around|(|\<Gamma\>,\<tau\>|)>>>|<row|<cell|>|<cell|>|<cell|>>|<row|<cell|<around*|\<llbracket\>|\<Gamma\>\<vdash\><with|math-font-series|bold|fun
    >x<with|mode|text|<verbatim|-\<gtr\>>>e:\<tau\>|\<rrbracket\>>>|<cell|=>|<cell|\<exists\>\<alpha\><rsub|1>\<alpha\><rsub|2>.<around|(|<around*|\<llbracket\>|\<Gamma\><around*|{|x:\<alpha\><rsub|1>|}>\<vdash\>e:\<alpha\><rsub|2>|\<rrbracket\>>\<wedge\>\<alpha\><rsub|1>\<rightarrow\>\<alpha\><rsub|2><wide|=|\<dot\>>\<tau\>|)>,>>|<row|<cell|>|<cell|>|<cell|<text|where
    >\<alpha\><rsub|1>\<alpha\><rsub|2>#FV<around|(|\<Gamma\>,\<tau\>|)>>>|<row|<cell|>|<cell|>|<cell|>>|<row|<cell|<around*|\<llbracket\>|\<Gamma\>\<vdash\>e<rsub|1>
    e<rsub|2>:\<tau\>|\<rrbracket\>>>|<cell|=>|<cell|\<exists\>\<alpha\>.<around|(|<around*|\<llbracket\>|\<Gamma\>\<vdash\>e<rsub|1>:\<alpha\>\<rightarrow\>\<tau\>|\<rrbracket\>>\<wedge\><around*|\<llbracket\>|\<Gamma\>\<vdash\>e<rsub|2>:\<alpha\>|\<rrbracket\>>|)>,\<alpha\>#FV<around|(|\<Gamma\>,\<tau\>|)>>>|<row|<cell|>|<cell|>|<cell|>>|<row|<cell|<around*|\<llbracket\>|\<Gamma\>\<vdash\>K
    e<rsub|1>\<ldots\>e<rsub|n>:\<tau\>|\<rrbracket\>>>|<cell|=>|<cell|\<exists\><wide|\<alpha\>|\<bar\>><rprime|'>.(\<wedge\><rsub|i><around*|\<llbracket\>|\<Gamma\>\<vdash\>e<rsub|i>:\<tau\><rsub|i><around|[|<wide|\<alpha\>|\<bar\>>\<assign\><wide|\<alpha\>|\<bar\>><rprime|'>|]>|\<rrbracket\>>\<wedge\>\<varepsilon\><around|(|<wide|\<alpha\>|\<bar\>><rprime|'>|)><wide|=|\<dot\>>\<tau\>),>>|<row|<cell|>|<cell|>|<cell|<text|w.
    >K\<colons\>\<forall\><wide|\<alpha\>|\<bar\>>.\<tau\><rsub|1>\<times\>\<ldots\>\<times\>\<tau\><rsub|n>\<rightarrow\>\<varepsilon\><around|(|<wide|\<alpha\>|\<bar\>>|)>,<wide|\<alpha\>|\<bar\>><rprime|'>#FV<around|(|\<Gamma\>,\<tau\>|)>>>|<row|<cell|>|<cell|>|<cell|>>|<row|<cell|<around*|\<llbracket\>|\<Gamma\>\<vdash\>e:\<tau\>|\<rrbracket\>>>|<cell|=>|<cell|<around*|(|\<exists\>\<beta\>.C|)>\<wedge\><around*|\<llbracket\>|\<Gamma\><around|{|x:\<forall\>\<beta\><around|[|C|]>.\<beta\>|}>\<vdash\>e<rsub|2>:\<tau\>|\<rrbracket\>>>>|<row|<cell|e=<with|math-font-series|bold|let
    >x=e<rsub|1><with|math-font-series|bold| in
    >e<rsub|2>>|<cell|>|<cell|<with|mode|text|where
    >C=<around*|\<llbracket\>|\<Gamma\>\<vdash\>e<rsub|1>:\<beta\>|\<rrbracket\>>>>|<row|<cell|>|<cell|>|<cell|>>|<row|<cell|<around*|\<llbracket\>|\<Gamma\>\<vdash\>e:\<tau\>|\<rrbracket\>>>|<cell|=>|<cell|<around*|(|\<exists\>\<beta\>.C|)>\<wedge\><around*|\<llbracket\>|\<Gamma\><around|{|x:\<forall\>\<beta\><around|[|C|]>.\<beta\>|}>\<vdash\>e<rsub|2>:\<tau\>|\<rrbracket\>>>>|<row|<cell|e=<with|math-font-series|bold|letrec
    >x=e<rsub|1><with|math-font-series|bold| in
    >e<rsub|2>>|<cell|>|<cell|<with|mode|text|where
    >C=<around*|\<llbracket\>|\<Gamma\><around|{|x:\<beta\>|}>\<vdash\>e<rsub|1>:\<beta\>|\<rrbracket\>>>>|<row|<cell|>|<cell|>|<cell|>>|<row|<cell|<around*|\<llbracket\>|\<Gamma\>\<vdash\>e:\<tau\>|\<rrbracket\>>>|<cell|=>|<cell|\<exists\>\<alpha\><rsub|v>.<around*|\<llbracket\>|\<Gamma\>\<vdash\>e<rsub|v>:\<alpha\><rsub|v>|\<rrbracket\>>\<wedge\><rsub|i><around*|\<llbracket\>|\<Gamma\>\<vdash\>p<rsub|i>.e<rsub|i>:\<alpha\><rsub|v>\<rightarrow\>\<tau\>|\<rrbracket\>>,>>|<row|<cell|e=<with|math-font-series|bold|match
    >e<rsub|v><with|math-font-series|bold| with
    ><wide|c|\<bar\>>>|<cell|>|<cell|\<alpha\><rsub|v>#FV<around|(|\<Gamma\>,\<tau\>|)>>>|<row|<cell|<wide|c|\<bar\>>=p<rsub|1>.e<rsub|1>\|\<ldots\>\|p<rsub|n>.e<rsub|n>>|<cell|>|<cell|>>|<row|<cell|>|<cell|>|<cell|>>|<row|<cell|<around*|\<llbracket\>|\<Gamma\>,\<Sigma\>\<vdash\>p.e:\<tau\><rsub|1>\<rightarrow\>\<tau\><rsub|2>|\<rrbracket\>>>|<cell|=>|<cell|<around*|\<llbracket\>|\<Sigma\>\<vdash\>p\<downarrow\>\<tau\><rsub|1>|\<rrbracket\>>\<wedge\>\<exists\><wide|\<beta\>|\<bar\>>.<around*|\<llbracket\>|\<Gamma\>\<Gamma\><rprime|'>\<vdash\>e:\<tau\><rsub|2>|\<rrbracket\>>>>|<row|<cell|>|<cell|>|<cell|<text|where
    >\<exists\><wide|\<beta\>|\<bar\>>\<Gamma\><rprime|'><text| is
    ><around*|\<llbracket\>|\<Sigma\>\<vdash\>p\<uparrow\>\<tau\><rsub|1>|\<rrbracket\>>,<wide|\<beta\>|\<bar\>>#FV<around|(|\<Gamma\>,\<tau\><rsub|2>|)>>>|<row|<cell|>|<cell|>|<cell|>>|<row|<cell|<around*|\<llbracket\>|\<Sigma\>\<vdash\>p\<downarrow\>\<tau\><rsub|1>|\<rrbracket\>>>|<cell|>|<cell|<with|mode|text|derives
    constraints on type of matched value>>>|<row|<cell|>|<cell|>|<cell|>>|<row|<cell|<around*|\<llbracket\>|\<Sigma\>\<vdash\>p\<uparrow\>\<tau\><rsub|1>|\<rrbracket\>>>|<cell|>|<cell|<with|mode|text|derives
    environment for pattern variables>>>>>
  </eqnarray*>

  <\itemize>
    <item>By <math|<wide|\<alpha\>|\<bar\>>> or
    <math|<wide|\<alpha\><rsub|i>|\<bar\>>> we denote a sequence of some
    length: <math|\<alpha\><rsub|1>\<ldots\>\<alpha\><rsub|n>>

    <item>By <math|\<wedge\><rsub|i>\<varphi\><rsub|i>> we denote a
    conjunction of <math|<wide|\<varphi\><rsub|i>|\<bar\>>>:
    <math|\<varphi\><rsub|1>\<ldots\>\<varphi\><rsub|n>>.
  </itemize>

  <subsection|<new-page*>Polymorphic Recursion>

  <\itemize>
    <item>Note the limited polymorphism of <hlkwa|let rec ><hlstd|f
    ><hlopt|=> ... -- we cannot use <verbatim|f> polymorphically in its
    definition.

    <\itemize>
      <item>In modern OCaml we can bypass the problem if we provide type of
      <verbatim|f> upfront: <hlkwa|let rec ><hlstd|f ><hlopt|:
      ><hlstd|'a><hlopt|. ><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'a list><hlopt|
      => ...

      <item>where <hlstd|'a><hlopt|. ><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'a
      list> stands for <math|\<forall\>\<alpha\>.\<alpha\>\<rightarrow\>\<alpha\>
      list>.
    </itemize>

    <item>Using the recursively defined function with different types in its
    definition is called polymorphic recursion.

    <item>It is most useful together with irregular recursive datatypes where
    the recursive use has different type arguments than the actual
    parameters.
  </itemize>

  <subsubsection|<new-page*>Polymorphic Rec: A list alternating between two
  types of elements>

  <hlkwa|type ><hlopt|(><hlstd|'x><hlopt|, '><hlstd|o><hlopt|)
  ><hlstd|alterning ><hlopt|=><hlendline|><next-line><hlopt|\|
  ><hlkwd|Stop><hlendline|><next-line><hlopt|\| ><hlkwd|One ><hlkwa|of
  ><hlstd|'x ><hlopt|* (><hlstd|'o><hlopt|, ><hlstd|'x><hlopt|)
  ><hlstd|alterning><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  rec ><hlstd|to<textunderscore>list ><hlopt|:><hlendline|><next-line><hlstd|
  \ \ \ 'x 'o 'a><hlopt|. (><hlstd|'x><hlopt|-\<gtr\>><hlstd|'a><hlopt|)
  -\<gtr\> (><hlstd|'o><hlopt|-\<gtr\>><hlstd|'a><hlopt|)
  -\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|'x><hlopt|, ><hlstd|'o><hlopt|)
  ><hlstd|alterning ><hlopt|-\<gtr\> ><hlstd|'a list
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|fun ><hlstd|x2a o2a
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  ><hlkwd|Stop ><hlopt|-\<gtr\> []><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|One ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|rest><hlopt|) -\<gtr\> ><hlstd|x2a
  x><hlopt|::><hlstd|to<textunderscore>list o2a x2a
  rest><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  ><hlstd|to<textunderscore>choice<textunderscore>list alt
  ><hlopt|=><hlendline|><next-line><hlstd| \ to<textunderscore>list
  ><hlopt|(><hlkwa|fun ><hlstd|x><hlopt|-\<gtr\>><hlkwd|Left
  ><hlstd|x><hlopt|) (><hlkwa|fun ><hlstd|o><hlopt|-\<gtr\>><hlkwd|Right
  ><hlstd|o><hlopt|) ><hlstd|alt><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  ><hlstd|it ><hlopt|= ><hlstd|to<textunderscore>choice<textunderscore>list<hlendline|><next-line>
  \ ><hlopt|(><hlkwd|One ><hlopt|(><hlnum|1><hlopt|, ><hlkwd|One
  ><hlopt|(><hlstr|"o"><hlopt|, ><hlkwd|One ><hlopt|(><hlnum|2><hlopt|,
  ><hlkwd|One ><hlopt|(><hlstr|"oo"><hlopt|,
  ><hlkwd|Stop><hlopt|)))))><hlendline|><next-line>

  <subsubsection|Polymorphic Rec: Data-Structural Bootstrapping>

  <small|<hlkwa|type ><hlstd|'a seq ><hlopt|= ><hlkwd|Nil ><hlopt|\|
  ><hlkwd|Zero ><hlkwa|of ><hlopt|(><hlstd|'a ><hlopt|* ><hlstd|'a><hlopt|)
  ><hlstd|seq <hlopt|\|> ><hlkwd|One ><hlkwa|of ><hlstd|'a ><hlopt|*
  (><hlstd|'a ><hlopt|* ><hlstd|'a><hlopt|)
  ><hlstd|seq><hlendline|><next-line><hlendline|We store a list of elements
  in exponentially increasing chunks.><next-line><hlkwa|let ><hlstd|example
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwd|One
  ><hlopt|(><hlnum|0><hlopt|, ><hlkwd|One
  ><hlopt|((><hlnum|1><hlopt|,><hlnum|2><hlopt|), ><hlkwd|Zero
  ><hlopt|(><hlkwd|One ><hlopt|((((><hlnum|3><hlopt|,><hlnum|4><hlopt|),(><hlnum|5><hlopt|,><hlnum|6><hlopt|)),
  ((><hlnum|7><hlopt|,><hlnum|8><hlopt|),(><hlnum|9><hlopt|,><hlnum|10><hlopt|))),
  ><hlkwd|Nil><hlopt|))))><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  rec ><hlstd|cons ><hlopt|: ><hlstd|'a><hlopt|. ><hlstd|'a ><hlopt|-\<gtr\>
  ><hlstd|'a seq ><hlopt|-\<gtr\> ><hlstd|'a seq
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|fun ><hlstd|x
  ><hlopt|-\<gtr\> ><hlkwa|function><hlendline|Appending an element to the
  datastructure is like><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Nil
  ><hlopt|-\<gtr\> ><hlkwd|One ><hlopt|(><hlstd|x><hlopt|,
  ><hlkwd|Nil><hlopt|)><hlendline|adding one to a binary number:
  1+0=1><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Zero ><hlstd|ps
  ><hlopt|-\<gtr\> ><hlkwd|One ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|ps><hlopt|)><hlendline|1+...0=...1><next-line><hlstd| \ ><hlopt|\|
  ><hlkwd|One ><hlopt|(><hlstd|y><hlopt|, ><hlstd|ps><hlopt|) -\<gtr\>
  ><hlkwd|Zero ><hlopt|(><hlstd|cons ><hlopt|(><hlstd|x><hlopt|,><hlstd|y><hlopt|)
  ><hlstd|ps><hlopt|)><hlendline|1+...1=[...+1]0><next-line><hlendline|><next-line><hlkwa|let
  rec ><hlstd|lookup ><hlopt|: ><hlstd|'a><hlopt|. ><hlkwb|int
  ><hlopt|-\<gtr\> ><hlstd|'a seq ><hlopt|-\<gtr\> ><hlstd|'a
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|fun ><hlstd|i s
  ><hlopt|-\<gtr\> ><hlkwa|match ><hlstd|i><hlopt|, ><hlstd|s
  ><hlkwa|with><hlendline|Rather than returning <verbatim|None : 'a
  option>><next-line><hlstd| \ <hlopt|\|> <textunderscore>><hlopt|,
  ><hlkwd|Nil ><hlopt|-\<gtr\> ><hlstd|raise
  ><hlkwd|Not<textunderscore>found><hlendline|we raise exception, for
  convenience.><next-line><hlstd| \ ><hlopt|\| ><hlnum|0><hlopt|, ><hlkwd|One
  ><hlopt|(><hlstd|x><hlopt|, ><hlstd|<textunderscore>><hlopt|) -\<gtr\>
  ><hlstd|x<hlendline|><next-line> \ <hlopt|\|> i><hlopt|, ><hlkwd|One
  ><hlopt|(><hlstd|<textunderscore>><hlopt|, ><hlstd|ps><hlopt|) -\<gtr\>
  ><hlstd|lookup ><hlopt|(><hlstd|i><hlopt|-><hlnum|1><hlopt|) (><hlkwd|Zero
  ><hlstd|ps><hlopt|)><hlendline|><next-line><hlstd| \ <hlopt|\|> i><hlopt|,
  ><hlkwd|Zero ><hlstd|ps ><hlopt|-\<gtr\>><hlendline|Random-Access lookup
  works><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|x><hlopt|, ><hlstd|y
  ><hlopt|= ><hlstd|lookup ><hlopt|(><hlstd|i ><hlopt|/ ><hlnum|2><hlopt|)
  ><hlstd|ps ><hlkwa|in><hlendline|in logarithmic time -- much faster
  than><next-line><hlstd| \ \ \ ><hlkwa|if ><hlstd|i ><hlkwa|mod ><hlnum|2
  ><hlopt|= ><hlnum|0 ><hlkwa|then ><hlstd|x ><hlkwa|else
  ><hlstd|y><hlendline|in standard lists.><next-line>>

  <section|<new-page*>Algebraic Specification>

  <\itemize>
    <item>The way we introduce a data structure, like complex numbers or
    strings, in mathematics, is by specifying an <em|algebraic structure>.

    <item>Algebraic structures consist of a set (or several sets, for
    so-called <em|multisorted> algebras) and a bunch of functions (aka.
    operations) over this set (or sets).

    <item>A <em|signature> is a rough description of an algebraic structure:
    it provides sorts -- names for the sets (in multisorted case) and names
    of the functions-operations together with their arity (and what sorts of
    arguments they take).

    <item>We select a class of algebraic structures by providing axioms that
    have to hold. We will call such classes <em|algebraic specifications>.

    <\itemize>
      <item>In mathematics, a rusty name for some algebraic specifications is
      a <em|variety>, a more modern and name is <em|algebraic category>.
    </itemize>

    <item>Algebraic structures correspond to ``implementations'' and
    signatures to ``interfaces'' in programming languages.

    <item>We will say that an algebraic structure implements an algebraic
    specification when all axioms of the specification hold in the structure.

    <item>All algebraic specifications are implemented by multiple
    structures!

    <item>We say that an algebraic structure does not have junk, when all its
    elements (i.e. elements in the sets corresponding to sorts) can be built
    using operations in its signature.

    <item>We allow parametric types as sorts. <small|In that case, strictly
    speaking, we define a family of algebraic specifications (a different
    specification for each instantiation of the parametric type).>
  </itemize>

  <subsection|<new-page*>Algebraic specifications: examples>

  <\itemize>
    <item>An algebraic specification can also use an earlier specification.

    <item>In ``impure'' languages like OCaml and F# we allow that the result
    of any operation be an <math|error>. In Haskell we could use
    <verbatim|Maybe>.
  </itemize>

  <block|<tformat|<table|<row|<cell|<math|nat<rsub|p>>>>|<row|<cell|<tabular|<tformat|<table|<row|<cell|<math|0:nat<rsub|p>>>>|<row|<cell|<math|succ:nat<rsub|p>\<rightarrow\>nat<rsub|p>>>>|<row|<cell|<math|+:nat<rsub|p>\<rightarrow\>nat<rsub|p>\<rightarrow\>nat<rsub|p>>>>|<row|<cell|<math|\<ast\>:nat<rsub|p>\<rightarrow\>nat<rsub|p>\<rightarrow\>nat<rsub|p>>>>>>>>>|<row|<cell|<math|n,m:nat<rsub|p>>>>|<row|<cell|<tabular|<tformat|<table|<row|<cell|<math|0+n=n>,
  <math|n+0=n>>>|<row|<cell|<math|m+succ<around*|(|n|)>=succ<around*|(|m+n|)>>>>|<row|<cell|<math|0\<ast\>n=0>,
  <math|n\<ast\>0=0>>>|<row|<cell|<math|m\<ast\>succ<around*|(|n|)>=m+<around*|(|m\<ast\>n|)>>>>|<row|<cell|<math|<below|succ<around*|(|\<ldots\>succ<around*|(|0|)>|)>|<with|mode|text|less
  than >p<with|mode|text| times>>\<neq\>0>>>|<row|<cell|<math|<below|succ<around*|(|\<ldots\>succ<around*|(|0|)>|)>|p<with|mode|text|
  times>>=0>>>>>>>>>>> \ <block|<tformat|<table|<row|<cell|<math|string<rsub|p>>>>|<row|<cell|uses
  <math|char>, <math|nat<rsub|p>>>>|<row|<cell|<tabular|<tformat|<table|<row|<cell|<verbatim|""><math|:string<rsub|p>>>>|<row|<cell|<verbatim|"<math|\<cdot\>>"><math|:char\<rightarrow\>string<rsub|p>>>>|<row|<cell|<math|^:string<rsub|p>\<rightarrow\>string<rsub|p>\<rightarrow\>string<rsub|p>>>>|<row|<cell|<math|\<cdot\><around*|[|\<cdot\>|]>:string<rsub|p>\<rightarrow\>nat<rsub|p>\<rightarrow\>char>>>>>>>>|<row|<cell|<math|s:string<rsub|p>,c,c<rsub|1>,\<ldots\>,c<rsub|p>:char,n:nat<rsub|p>>>>|<row|<cell|<tabular|<tformat|<table|<row|<cell|<verbatim|""><math|^s=s>,
  <math|s^<with|mode|text|<verbatim|"">>=s>>>|<row|<cell|<math|<below|<with|mode|text|<verbatim|"<math|c<rsub|1>>">>^<around*|(|\<ldots\>^<with|mode|text|<verbatim|"<math|c<rsub|p>>">>|)>|p<with|mode|text|
  times>>=error>>>|<row|<cell|<math|r^<around*|(|s^t|)>=<around*|(|r^s|)>^t>>>|<row|<cell|<math|<around*|(|<with|mode|text|<verbatim|"<math|c>">>^s|)><around*|[|0|]>=c>>>|<row|<cell|<math|<around*|(|<with|mode|text|<verbatim|"<math|c>">>^s|)><around*|[|succ<around*|(|n|)>|]>=s<around*|[|n|]>>>>|<row|<cell|<math|<with|mode|text|<verbatim|"">><around*|[|n|]>=error>>>>>>>>>>>

  <section|<new-page*>Homomorphisms>

  <\itemize>
    <item>Mappings between algebraic structures with the same signature
    preserving operations.

    <item>A <em|homomorphism> from algebraic structure
    <math|<around*|(|A,<around*|{|f<rsup|A>,g<rsup|A>,\<ldots\>|}>|)>> to
    <math|<around*|(|B,<around*|{|f<rsup|B>,g<rsup|B>,\<ldots\>|}>|)>> is a
    function <math|h:A\<rightarrow\>B> such that
    <math|h<around*|(|f<rsup|A><around*|(|a<rsub|1>,\<ldots\>,a<rsub|n<rsub|f>>|)>|)>=f<rsup|B><around*|(|h<around*|(|a<rsub|1>|)>,\<ldots\>,h<around*|(|a<rsub|n<rsub|f>>|)>|)>>
    for all <math|<around*|(|a<rsub|1>,\<ldots\>,a<rsub|n<rsub|f>>|)>>,
    <math|h<around*|(|g<rsup|A><around*|(|a<rsub|1>,\<ldots\>,a<rsub|n<rsub|g>>|)>|)>=g<rsup|B><around*|(|h<around*|(|a<rsub|1>|)>,\<ldots\>,h<around*|(|a<rsub|n<rsub|g>>|)>|)>>
    for all <math|<around*|(|a<rsub|1>,\<ldots\>,a<rsub|n<rsub|g>>|)>>, ...

    <item>Two algebraic structures are <em|isomorphic> if there are
    homomorphisms <math|h<rsub|1>:A\<rightarrow\>B,h<rsub|2>:B\<rightarrow\>A>
    from one to the other and back, that when composed in any order form
    identity: <math|\<forall\><around*|(|b\<in\>B|)>
    h<rsub|1><around*|(|h<rsub|2><around*|(|b|)>|)>=b>,
    <math|\<forall\><around*|(|a\<in\>A|)>
    h<rsub|2><around*|(|h<rsub|1><around*|(|a|)>|)>=a>.

    <item>An algebraic specification whose all implementations without junk
    are isomorphic is called ``<em|monomorphic>''.

    <\itemize>
      <item>We usually only add axioms that really matter to us to the
      specification, so that the implementations have room for optimization.
      For this reason, the resulting specifications will often not be
      monomorphic in the above sense.
    </itemize>
  </itemize>

  <section|<new-page*>Example: Maps>

  <block|<tformat|<table|<row|<cell|<math|<around*|(|\<alpha\>,\<beta\>|)>
  map>, or <math|map<around*|\<langle\>|\<alpha\>,\<beta\>|\<rangle\>>>>>|<row|<cell|uses
  <math|bool>, type parameters <math|\<alpha\>,\<beta\>>>>|<row|<cell|<tabular|<tformat|<table|<row|<cell|<math|empty:<around*|(|\<alpha\>,\<beta\>|)>
  map>>>|<row|<cell|<math|member:\<alpha\>\<rightarrow\><around*|(|\<alpha\>,\<beta\>|)>
  map\<rightarrow\>bool>>>|<row|<cell|<math|add:\<alpha\>\<rightarrow\>\<beta\>\<rightarrow\><around*|(|\<alpha\>,\<beta\>|)>
  map\<rightarrow\><around*|(|\<alpha\>,\<beta\>|)>
  map>>>|<row|<cell|<math|remove:\<alpha\>\<rightarrow\><around*|(|\<alpha\>,\<beta\>|)>
  map\<rightarrow\><around*|(|\<alpha\>,\<beta\>|)>
  map>>>|<row|<cell|<math|find:\<alpha\>\<rightarrow\><around*|(|\<alpha\>,\<beta\>|)>
  map\<rightarrow\>\<beta\>>>>>>>>>|<row|<cell|<math|k,k<rsub|2>:\<alpha\>>,
  <math|v,v<rsub|2>:\<beta\>>, <math|m:<around*|(|\<alpha\>,\<beta\>|)>
  map>>>|<row|<cell|<tabular|<tformat|<table|<row|<cell|<math|member<around*|(|k,add<around*|(|k,v,m|)>|)>=true>>>|<row|<cell|<math|member<around*|(|k,remove<around*|(|k,m|)>|)>=false>>>|<row|<cell|<math|member<around*|(|k,add<around*|(|k<rsub|2>,v,m|)>|)>=true\<wedge\>k\<neq\>k<rsub|2>\<Leftrightarrow\>member<around*|(|k,m|)>=true\<wedge\>k\<neq\>k<rsub|2>>>>|<row|<cell|<small|<math|member<around*|(|k,remove<around*|(|k<rsub|2>,v,m|)>|)>=true\<wedge\>k\<neq\>k<rsub|2>\<Leftrightarrow\>member<around*|(|k,m|)>=true\<wedge\>k\<neq\>k<rsub|2>>>>>|<row|<cell|<math|find<around*|(|k,add<around*|(|k,v,m|)>|)>=v>>>|<row|<cell|<math|find<around*|(|k,remove<around*|(|k,m|)>|)>=error>,
  <math|find<around*|(|k,empty|)>=error>>>|<row|<cell|<math|find<around*|(|k,add<around*|(|k<rsub|2>,v<rsub|2>,m|)>|)>=v\<wedge\>k\<neq\>k<rsub|2>\<Leftrightarrow\>find<around*|(|k,m|)>=v\<wedge\>k\<neq\>k<rsub|2>>>>|<row|<cell|<math|find<around*|(|k,remove<around*|(|k<rsub|2>,v<rsub|2>,m|)>|)>=v\<wedge\>k\<neq\>k<rsub|2>\<Leftrightarrow\>find<around*|(|k,m|)>=v\<wedge\>k\<neq\>k<rsub|2>>>>|<row|<cell|<math|remove<around*|(|k,empty|)>=empty>>>>>>>>>>>

  <section|<new-page*>Modules and interfaces (signatures): syntax>

  <\itemize>
    <item>In the ML family of languages, structures are given names by
    <strong|module> bindings, and signatures are types of modules.

    <item>From outside of a structure or signature, we refer to the values or
    types it provides with a dot notation: <verbatim|Module.value>.

    <item>Module (and module type) names have to start with a capital letter
    (in ML languages).

    <item>Since modules and module types have names, there is a tradition to
    name the central type of a signature (the one that is ``specified'' by
    the signature), for brevity, <verbatim|t>.

    <item>Module types are often named with ``all-caps'' (all letters upper
    case).
  </itemize>

  <new-page>

  <hlkwa|module type ><hlkwd|MAP ><hlopt|=
  ><hlkwa|sig><hlendline|><next-line><hlstd| \ ><hlkwa|type
  ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|)
  ><hlstd|t<hlendline|><next-line> \ ><hlkwa|val ><hlstd|empty ><hlopt|:
  (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|t<hlendline|><next-line>
  \ ><hlkwa|val ><hlstd|member ><hlopt|: ><hlstd|'a ><hlopt|-\<gtr\>
  (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|t ><hlopt|-\<gtr\>
  ><hlkwb|bool><hlendline|><next-line><hlstd| \ ><hlkwa|val ><hlstd|add
  ><hlopt|: ><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b ><hlopt|-\<gtr\>
  (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|t ><hlopt|-\<gtr\>
  (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|t<hlendline|><next-line>
  \ ><hlkwa|val ><hlstd|remove ><hlopt|: ><hlstd|'a ><hlopt|-\<gtr\>
  (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|t ><hlopt|-\<gtr\>
  (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|t<hlendline|><next-line>
  \ ><hlkwa|val ><hlstd|find ><hlopt|: ><hlstd|'a ><hlopt|-\<gtr\>
  (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|t ><hlopt|-\<gtr\>
  ><hlstd|'b><hlendline|><next-line><hlkwa|end><hlendline|><next-line><hlendline|><next-line><hlkwa|module
  ><hlkwd|ListMap ><hlopt|: ><hlkwd|MAP ><hlopt|=
  ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|type
  ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|t ><hlopt|=
  (><hlstd|'a ><hlopt|* ><hlstd|'b><hlopt|)
  ><hlstd|list<hlendline|><next-line> \ ><hlkwa|let ><hlstd|empty ><hlopt|=
  []><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|member ><hlopt|=
  ><hlkwc|List><hlopt|.><hlstd|mem<textunderscore>assoc<hlendline|><next-line>
  \ ><hlkwa|let ><hlstd|add k v m ><hlopt|= (><hlstd|k><hlopt|,
  ><hlstd|v><hlopt|)::><hlstd|m<hlendline|><next-line> \ ><hlkwa|let
  ><hlstd|remove ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|remove<textunderscore>assoc<hlendline|><next-line>
  \ ><hlkwa|let ><hlstd|find ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|assoc><hlendline|><next-line><hlkwa|end><hlendline|>

  <section|<new-page*>Implementing maps: Association lists>

  Let's now build an implementation of maps from the ground up. The most
  straightforward implementation... might not be what you expected:

  <hlkwa|module ><hlkwd|TrivialMap ><hlopt|: ><hlkwd|MAP ><hlopt|=
  ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|type
  ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|t
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  ><hlkwd|Empty><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Add
  ><hlkwa|of ><hlstd|'a ><hlopt|* ><hlstd|'b ><hlopt|* (><hlstd|'a><hlopt|,
  ><hlstd|'b><hlopt|) ><hlstd|t<hlendline|><next-line> \ \ \ ><hlopt|\|
  ><hlkwd|Remove ><hlkwa|of ><hlstd|'a ><hlopt|* (><hlstd|'a><hlopt|,
  ><hlstd|'b><hlopt|) ><hlstd|t \ \ \ \ \ \ \ <hlendline|><next-line>
  \ ><hlkwa|let ><hlstd|empty ><hlopt|= ><hlkwd|Empty><hlendline|><next-line><hlstd|
  \ ><hlkwa|let rec ><hlstd|member k m ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|match ><hlstd|m ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Empty ><hlopt|-\<gtr\>
  ><hlkwa|false><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Add ><hlopt|(><hlstd|k2><hlopt|, ><hlstd|<textunderscore>><hlopt|,
  ><hlstd|<textunderscore>><hlopt|) ><hlkwa|when ><hlstd|k ><hlopt|=
  ><hlstd|k2 ><hlopt|-\<gtr\> ><hlkwa|true><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Remove ><hlopt|(><hlstd|k2><hlopt|,
  ><hlstd|<textunderscore>><hlopt|) ><hlkwa|when ><hlstd|k ><hlopt|=
  ><hlstd|k2 ><hlopt|-\<gtr\> ><hlkwa|false><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Add ><hlopt|(><hlstd|<textunderscore>><hlopt|,
  ><hlstd|<textunderscore>><hlopt|, ><hlstd|m2><hlopt|) -\<gtr\>
  ><hlstd|member k m2<hlendline|><next-line> \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Remove ><hlopt|(><hlstd|<textunderscore>><hlopt|,
  ><hlstd|m2><hlopt|) -\<gtr\> ><hlstd|member k m2<hlendline|><next-line>
  \ ><hlkwa|let ><hlstd|add k v m ><hlopt|= ><hlkwd|Add
  ><hlopt|(><hlstd|k><hlopt|, ><hlstd|v><hlopt|,
  ><hlstd|m><hlopt|)><hlendline|><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|remove k m ><hlopt|= ><hlkwd|Remove ><hlopt|(><hlstd|k><hlopt|,
  ><hlstd|m><hlopt|)><hlendline|><next-line><hlstd| \ ><hlkwa|let rec
  ><hlstd|find k m ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|match ><hlstd|m ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Empty ><hlopt|-\<gtr\> ><hlstd|raise
  ><hlkwd|Not<textunderscore>found><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Add ><hlopt|(><hlstd|k2><hlopt|,
  ><hlstd|v><hlopt|, ><hlstd|<textunderscore>><hlopt|) ><hlkwa|when ><hlstd|k
  ><hlopt|= ><hlstd|k2 ><hlopt|-\<gtr\> ><hlstd|v<hlendline|><next-line>
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Remove ><hlopt|(><hlstd|k2><hlopt|,
  ><hlstd|<textunderscore>><hlopt|) ><hlkwa|when ><hlstd|k ><hlopt|=
  ><hlstd|k2 ><hlopt|-\<gtr\> ><hlstd|raise
  ><hlkwd|Not<textunderscore>found><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Add ><hlopt|(><hlstd|<textunderscore>><hlopt|,
  ><hlstd|<textunderscore>><hlopt|, ><hlstd|m2><hlopt|) -\<gtr\> ><hlstd|find
  k m2<hlendline|><next-line> \ \ \ \ \ ><hlopt|\| ><hlkwd|Remove
  ><hlopt|(><hlstd|<textunderscore>><hlopt|, ><hlstd|m2><hlopt|) -\<gtr\>
  ><hlstd|find k m2><hlendline|><next-line><hlkwa|end><hlendline|><new-page>

  Here is an implementation based on association lists, i.e. on lists of
  key-value pairs.

  <hlkwa|module ><hlkwd|MyListMap ><hlopt|: ><hlkwd|MAP ><hlopt|=
  ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|type
  ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|t ><hlopt|=
  ><hlkwd|Empty ><hlopt|\| ><hlkwd|Add ><hlkwa|of ><hlstd|'a ><hlopt|*
  ><hlstd|'b ><hlopt|* (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|)
  ><hlstd|t<hlendline|><next-line> \ ><hlkwa|let ><hlstd|empty ><hlopt|=
  ><hlkwd|Empty><hlendline|><next-line><hlstd| \ ><hlkwa|let rec
  ><hlstd|member k m ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|match ><hlstd|m ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Empty ><hlopt|-\<gtr\>
  ><hlkwa|false><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Add ><hlopt|(><hlstd|k2><hlopt|, ><hlstd|<textunderscore>><hlopt|,
  ><hlstd|<textunderscore>><hlopt|) ><hlkwa|when ><hlstd|k ><hlopt|=
  ><hlstd|k2 ><hlopt|-\<gtr\> ><hlkwa|true><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Add ><hlopt|(><hlstd|<textunderscore>><hlopt|,
  ><hlstd|<textunderscore>><hlopt|, ><hlstd|m2><hlopt|) -\<gtr\>
  ><hlstd|member k m2<hlendline|><next-line> \ ><hlkwa|let rec ><hlstd|add k
  v m ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match ><hlstd|m
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Empty ><hlopt|-\<gtr\> ><hlkwd|Add ><hlopt|(><hlstd|k><hlopt|,
  ><hlstd|v><hlopt|, ><hlkwd|Empty><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Add ><hlopt|(><hlstd|k2><hlopt|,
  ><hlstd|<textunderscore>><hlopt|, ><hlstd|m><hlopt|) ><hlkwa|when ><hlstd|k
  ><hlopt|= ><hlstd|k2 ><hlopt|-\<gtr\> ><hlkwd|Add
  ><hlopt|(><hlstd|k><hlopt|, ><hlstd|v><hlopt|,
  ><hlstd|m><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Add ><hlopt|(><hlstd|k2><hlopt|, ><hlstd|v2><hlopt|,
  ><hlstd|m><hlopt|) -\<gtr\> ><hlkwd|Add ><hlopt|(><hlstd|k2><hlopt|,
  ><hlstd|v2><hlopt|, ><hlstd|add k v m><hlopt|)><hlendline|><new-page>

  <hlstd| \ ><hlkwa|let rec ><hlstd|remove k m
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match ><hlstd|m
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Empty ><hlopt|-\<gtr\> ><hlkwd|Empty><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Add ><hlopt|(><hlstd|k2><hlopt|,
  ><hlstd|<textunderscore>><hlopt|, ><hlstd|m><hlopt|) ><hlkwa|when ><hlstd|k
  ><hlopt|= ><hlstd|k2 ><hlopt|-\<gtr\> ><hlstd|m<hlendline|><next-line>
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Add ><hlopt|(><hlstd|k2><hlopt|,
  ><hlstd|v><hlopt|, ><hlstd|m><hlopt|) -\<gtr\> ><hlkwd|Add
  ><hlopt|(><hlstd|k2><hlopt|, ><hlstd|v><hlopt|, ><hlstd|remove k
  m><hlopt|)><hlendline|><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|find k
  m ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match ><hlstd|m
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Empty ><hlopt|-\<gtr\> ><hlstd|raise
  ><hlkwd|Error><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Add ><hlopt|(><hlstd|k2><hlopt|, ><hlstd|v><hlopt|,
  ><hlstd|<textunderscore>><hlopt|) ><hlkwa|when ><hlstd|k ><hlopt|=
  ><hlstd|k2 ><hlopt|-\<gtr\> ><hlstd|v<hlendline|><next-line>
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Add ><hlopt|(><hlstd|<textunderscore>><hlopt|,
  ><hlstd|<textunderscore>><hlopt|, ><hlstd|m2><hlopt|) -\<gtr\> ><hlstd|find
  k m2><hlendline|><next-line><hlkwa|end><hlendline|><next-line>

  <section|<new-page*>Implementing maps: Binary search trees>

  <\itemize>
    <item>Binary search trees are binary trees with elements stored at the
    interior nodes, such that elements to the left of a node are smaller
    than, and elements to the right bigger than, elements within a node.

    <item>For maps, we store key-value pairs as elements in binary search
    trees, and compare the elements by keys alone.

    <item>On average, binary search trees are fast because they use
    ``divide-and-conquer'' to search for the value associated with a key.
    (<math|O<around*|(|log n|)>> compl.)

    <\itemize>
      <item>In worst case they reduce to association lists.
    </itemize>

    <item>The simple polymorphic signature for maps is only possible with
    implementations based on some total order of keys because OCaml has
    polymorphic comparison (and equality) operators.

    <\itemize>
      <item>These operators work on elements of most types, but not on
      functions. They may not work in a way you would want though!

      <item>Our signature for polymorphic maps is not the standard approach
      because of the problem of needing the order of keys; it is just to keep
      things simple.
    </itemize>
  </itemize>

  <\small>
    <hlkwa|module ><hlkwd|BTreeMap ><hlopt|: ><hlkwd|MAP ><hlopt|=
    ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|type
    ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|t ><hlopt|=
    ><hlkwd|Empty ><hlopt|\| ><hlkwd|T ><hlkwa|of
    ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|t ><hlopt|*
    ><hlstd|'a ><hlopt|* ><hlstd|'b ><hlopt|* (><hlstd|'a><hlopt|,
    ><hlstd|'b><hlopt|) ><hlstd|t<hlendline|><next-line> \ ><hlkwa|let
    ><hlstd|empty ><hlopt|= ><hlkwd|Empty><hlendline|><next-line><hlstd|
    \ ><hlkwa|let rec ><hlstd|member k m ><hlopt|=><hlendline|``Divide and
    conquer'' search through the tree.><next-line><hlstd| \ \ \ ><hlkwa|match
    ><hlstd|m ><hlkwa|with><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|\| ><hlkwd|Empty ><hlopt|-\<gtr\>
    ><hlkwa|false><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
    ><hlkwd|T ><hlopt|(><hlstd|<textunderscore>><hlopt|, ><hlstd|k2><hlopt|,
    ><hlstd|<textunderscore>><hlopt|, ><hlstd|<textunderscore>><hlopt|)
    ><hlkwa|when ><hlstd|k ><hlopt|= ><hlstd|k2 ><hlopt|-\<gtr\>
    ><hlkwa|true><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
    ><hlkwd|T ><hlopt|(><hlstd|m1><hlopt|, ><hlstd|k2><hlopt|,
    ><hlstd|<textunderscore>><hlopt|, ><hlstd|<textunderscore>><hlopt|)
    ><hlkwa|when ><hlstd|k ><hlopt|\<less\> ><hlstd|k2 ><hlopt|-\<gtr\>
    ><hlstd|member k m1<hlendline|><next-line> \ \ \ \ \ ><hlopt|\| ><hlkwd|T
    ><hlopt|(><hlstd|<textunderscore>><hlopt|,
    ><hlstd|<textunderscore>><hlopt|, ><hlstd|<textunderscore>><hlopt|,
    ><hlstd|m2><hlopt|) -\<gtr\> ><hlstd|member k m2<hlendline|><next-line>
    \ ><hlkwa|let rec ><hlstd|add k v m ><hlopt|=><hlendline|Searches the
    tree in the same way as <verbatim|member>><next-line><hlstd|
    \ \ \ ><hlkwa|match ><hlstd|m ><hlkwa|with><hlendline|but copies every
    node along the way.><next-line><hlstd| \ \ \ \ \ ><hlopt|\| ><hlkwd|Empty
    ><hlopt|-\<gtr\> ><hlkwd|T ><hlopt|(><hlkwd|Empty><hlopt|,
    ><hlstd|k><hlopt|, ><hlstd|v><hlopt|,
    ><hlkwd|Empty><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|\| ><hlkwd|T ><hlopt|(><hlstd|m1><hlopt|,
    ><hlstd|k2><hlopt|, ><hlstd|<textunderscore>><hlopt|, ><hlstd|m2><hlopt|)
    ><hlkwa|when ><hlstd|k ><hlopt|= ><hlstd|k2 ><hlopt|-\<gtr\> ><hlkwd|T
    ><hlopt|(><hlstd|m1><hlopt|, ><hlstd|k><hlopt|, ><hlstd|v><hlopt|,
    ><hlstd|m2><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
    ><hlkwd|T ><hlopt|(><hlstd|m1><hlopt|, ><hlstd|k2><hlopt|,
    ><hlstd|v2><hlopt|, ><hlstd|m2><hlopt|) ><hlkwa|when ><hlstd|k
    ><hlopt|\<less\> ><hlstd|k2 ><hlopt|-\<gtr\> ><hlkwd|T
    ><hlopt|(><hlstd|add k v m1><hlopt|, ><hlstd|k2><hlopt|,
    ><hlstd|v2><hlopt|, ><hlstd|m2><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|\| ><hlkwd|T ><hlopt|(><hlstd|m1><hlopt|,
    ><hlstd|k2><hlopt|, ><hlstd|v2><hlopt|, ><hlstd|m2><hlopt|) -\<gtr\>
    ><hlkwd|T ><hlopt|(><hlstd|m1><hlopt|, ><hlstd|k2><hlopt|,
    ><hlstd|v2><hlopt|, ><hlstd|add k v m2><hlopt|)><hlendline|><next-line><hlstd|
    \ ><hlkwa|let rec ><hlstd|split<textunderscore>rightmost m
    ><hlopt|=><hlendline|A helper function, it does not
    belong><next-line><hlstd| \ \ \ ><hlkwa|match ><hlstd|m
    ><hlkwa|with><hlendline|to the ``exported'' signature.><next-line><hlstd|
    \ \ \ \ \ ><hlopt|\| ><hlkwd|Empty ><hlopt|-\<gtr\> ><hlstd|raise
    ><hlkwd|Not<textunderscore>found><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|\| ><hlkwd|T ><hlopt|(><hlkwd|Empty><hlopt|,
    ><hlstd|k><hlopt|, ><hlstd|v><hlopt|, ><hlkwd|Empty><hlopt|) -\<gtr\>
    ><hlstd|k><hlopt|, ><hlstd|v><hlopt|, ><hlkwd|Empty><hlendline|We remove
    one element,><next-line><hlstd| \ \ \ \ \ ><hlopt|\| ><hlkwd|T
    ><hlopt|(><hlstd|m1><hlopt|, ><hlstd|k><hlopt|, ><hlstd|v><hlopt|,
    ><hlstd|m2><hlopt|) -\<gtr\>><hlendline|the one that is on the bottom
    right.><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|let ><hlstd|rk><hlopt|,
    ><hlstd|rv><hlopt|, ><hlstd|rm ><hlopt|=
    ><hlstd|split<textunderscore>rightmost m2
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ rk><hlopt|,
    ><hlstd|rv><hlopt|, ><hlkwd|T ><hlopt|(><hlstd|m1><hlopt|,
    ><hlstd|k><hlopt|, ><hlstd|v><hlopt|,
    ><hlstd|rm><hlopt|)><hlendline|><new-page>

    <hlstd| \ ><hlkwa|let rec ><hlstd|remove k m
    ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match ><hlstd|m
    ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
    ><hlkwd|Empty ><hlopt|-\<gtr\> ><hlkwd|Empty><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|\| ><hlkwd|T ><hlopt|(><hlstd|m1><hlopt|,
    ><hlstd|k2><hlopt|, ><hlstd|<textunderscore>><hlopt|,
    ><hlkwd|Empty><hlopt|) ><hlkwa|when ><hlstd|k ><hlopt|= ><hlstd|k2
    ><hlopt|-\<gtr\> ><hlstd|m1<hlendline|><next-line> \ \ \ \ \ ><hlopt|\|
    ><hlkwd|T ><hlopt|(><hlkwd|Empty><hlopt|, ><hlstd|k2><hlopt|,
    ><hlstd|<textunderscore>><hlopt|, ><hlstd|m2><hlopt|) ><hlkwa|when
    ><hlstd|k ><hlopt|= ><hlstd|k2 ><hlopt|-\<gtr\>
    ><hlstd|m2<hlendline|><next-line> \ \ \ \ \ ><hlopt|\| ><hlkwd|T
    ><hlopt|(><hlstd|m1><hlopt|, ><hlstd|k2><hlopt|,
    ><hlstd|<textunderscore>><hlopt|, ><hlstd|m2><hlopt|) ><hlkwa|when
    ><hlstd|k ><hlopt|= ><hlstd|k2 ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwa|let ><hlstd|rk><hlopt|, ><hlstd|rv><hlopt|,
    ><hlstd|rm ><hlopt|= ><hlstd|split<textunderscore>rightmost m1
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwd|T
    ><hlopt|(><hlstd|rm><hlopt|, ><hlstd|rk><hlopt|, ><hlstd|rv><hlopt|,
    ><hlstd|m2><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
    ><hlkwd|T ><hlopt|(><hlstd|m1><hlopt|, ><hlstd|k2><hlopt|,
    ><hlstd|v><hlopt|, ><hlstd|m2><hlopt|) ><hlkwa|when ><hlstd|k
    ><hlopt|\<less\> ><hlstd|k2 ><hlopt|-\<gtr\> ><hlkwd|T
    ><hlopt|(><hlstd|remove k m1><hlopt|, ><hlstd|k2><hlopt|,
    ><hlstd|v><hlopt|, ><hlstd|m2><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|\| ><hlkwd|T ><hlopt|(><hlstd|m1><hlopt|,
    ><hlstd|k2><hlopt|, ><hlstd|v><hlopt|, ><hlstd|m2><hlopt|) -\<gtr\>
    ><hlkwd|T ><hlopt|(><hlstd|m1><hlopt|, ><hlstd|k2><hlopt|,
    ><hlstd|v><hlopt|, ><hlstd|remove k m2><hlopt|)><hlendline|><next-line><hlstd|
    \ ><hlkwa|let rec ><hlstd|find k m ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|match ><hlstd|m ><hlkwa|with><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|\| ><hlkwd|Empty ><hlopt|-\<gtr\> ><hlstd|raise
    ><hlkwd|Not<textunderscore>found><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|\| ><hlkwd|T ><hlopt|(><hlstd|<textunderscore>><hlopt|,
    ><hlstd|k2><hlopt|, ><hlstd|v><hlopt|, ><hlstd|<textunderscore>><hlopt|)
    ><hlkwa|when ><hlstd|k ><hlopt|= ><hlstd|k2 ><hlopt|-\<gtr\>
    ><hlstd|v<hlendline|><next-line> \ \ \ \ \ ><hlopt|\| ><hlkwd|T
    ><hlopt|(><hlstd|m1><hlopt|, ><hlstd|k2><hlopt|,
    ><hlstd|<textunderscore>><hlopt|, ><hlstd|<textunderscore>><hlopt|)
    ><hlkwa|when ><hlstd|k ><hlopt|\<less\> ><hlstd|k2 ><hlopt|-\<gtr\>
    ><hlstd|find k m1<hlendline|><next-line> \ \ \ \ \ ><hlopt|\| ><hlkwd|T
    ><hlopt|(><hlstd|<textunderscore>><hlopt|,
    ><hlstd|<textunderscore>><hlopt|, ><hlstd|<textunderscore>><hlopt|,
    ><hlstd|m2><hlopt|) -\<gtr\> ><hlstd|find k
    m2><hlendline|><next-line><hlkwa|end><hlendline|><next-line>
  </small>

  <section|<new-page*>Implementing maps: red-black trees>

  Based on Wikipedia <hlink|http://en.wikipedia.org/wiki/Red-black_tree|http://en.wikipedia.org/wiki/Red-black_tree>,
  Chris Okasaki's ``Functional Data Structures'' and Matt Might's excellent
  blog post <hlink|http://matt.might.net/articles/red-black-delete/|http://matt.might.net/articles/red-black-delete/>.

  <\itemize>
    <item>Binary search trees are good when we encounter keys in random
    order, because the cost of operations is limited by the depth of the tree
    which is small relatively to the number of nodes...

    <item>...unless the tree grows unbalanced achieving large depth (which
    means there are sibling subtrees of vastly different sizes on some path).

    <item>To remedy it, we rebalance the tree while building it -- i.e. while
    adding elements.

    <item>In <em|red-black trees> we achieve balance by remembering one of
    two colors with each node, keeping the same length of each root-leaf path
    if only black nodes are counted, and not allowing a red node to have a
    red child.

    <\itemize>
      <item>This way the depth is at most twice the depth of a perfectly
      balanced tree with the same number of nodes.
    </itemize>
  </itemize>

  <subsection|B-trees of order 4 (2-3-4 trees)>

  How can we have perfectly balanced trees without worrying about having
  <math|2<rsup|k>-1> elements? <strong|2-3-4 trees> can store from 1 to 3
  elements in each node and have 2 to 4 subtrees correspondingly. Lots of
  freedom!

  <huge|<tabular|<tformat|<table|<row|<cell|<math|<tree|a|p|q>>>|<cell|>|<cell|<math|<tree|a<with|mode|text|
  >b|p|q|r>>>|<cell|>|<cell|<math|<tree|a<with|mode|text| >b<with|mode|text|
  >c|p<with|mode|text| \ >|q<with|mode|text| >|<with|mode|text|
  >r|<with|mode|text| \ >s>>>>|<row|<cell|2-node>|<cell|>|<cell|3-node>|<cell|>|<cell|4-node>>>>>>

  <new-page*>To insert ``25'' into (``.'' stand for leaves, ignored later)

  <\equation*>
    <tree|10<with|mode|text| >20|<tree|5|.|.>|<tree|17|.|.>|<tree|22<with|mode|text|
    >24<with|mode|text| >29|<with|mode|text| . \ \ >|<with|mode|text| \ .
    \ >|<with|mode|text| \ \ . >|<with|mode|text| \ \ . >>>
  </equation*>

  we descend right, but it is a full node, so we move the middle up and split
  the remaining elements:

  <\equation*>
    <tree|10<with|mode|text| >20<with|mode|text| >24|5<with|mode|text|
    \ >|17<with|mode|text| >|<with|mode|text| >22|<with|mode|text| \ >29>
  </equation*>

  Now there is a place between 24 and 29: next to 29

  <\equation*>
    <tree|10<with|mode|text| >20<with|mode|text| >24|5<with|mode|text|
    \ >|17<with|mode|text| >|<with|mode|text| >22|<with|mode|text|
    \ >25<with|mode|text| >29>
  </equation*>

  <new-page>

  To represent 2-3-4 tree as a binary tree with one element per node, we
  color the middle element of a 4-node, or the first element of 2-/3-node,
  black and make it the parent of its neighbor elements, and make them
  parents of the original subtrees. Turning this:

  <image|Red-black_tree_B-tree.png|1078px|404px||>

  <new-page*>into this Red-Black tree:

  <image|Red-black_tree_example.png|1078px|650px||>

  <subsection|<new-page*>Red-Black trees, without deletion>

  <\itemize>
    <item><strong|Invariant 1.> No red node has a red child.

    <item><strong|Invariant 2>. Every path from the root to an empty node
    contains the same number of black nodes.

    <item>First we implement Red-Black tree based sets without deletion.

    <item>The implementation proceeds almost exactly like for unbalanced
    binary search trees, we only need to restore invariants.

    <item>By keeping balance at each step of constructing a node, it is
    enough to check locally (around the root of the subtree).

    <item>For understandable implementation of deletion, we need to introduce
    more colors. See Matt Might's post edited in a separate file.
  </itemize>

  <new-page>

  <\small>
    <hlkwa|type ><hlstd|color ><hlopt|= ><hlkwd|R ><hlopt|\|
    ><hlkwd|B><hlendline|><next-line><hlkwa|type ><hlstd|'a t ><hlopt|=
    ><hlkwd|E ><hlopt|\| ><hlkwd|T ><hlkwa|of ><hlstd|color ><hlopt|*
    ><hlstd|'a t ><hlopt|* ><hlstd|'a ><hlopt|* ><hlstd|'a
    t><hlendline|><next-line><hlkwa|let ><hlstd|empty ><hlopt|=
    ><hlkwd|E><hlendline|><next-line><hlkwa|let rec ><hlstd|member x m
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match ><hlstd|m
    ><hlkwa|with><hlendline|Like in unbalanced binary search
    tree.><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Empty ><hlopt|-\<gtr\>
    ><hlkwa|false><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|T
    ><hlopt|(><hlstd|<textunderscore>><hlopt|,
    ><hlstd|<textunderscore>><hlopt|, ><hlstd|y><hlopt|,
    ><hlstd|<textunderscore>><hlopt|) ><hlkwa|when ><hlstd|x ><hlopt|=
    ><hlstd|y ><hlopt|-\<gtr\> ><hlkwa|true><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|T ><hlopt|(><hlstd|<textunderscore>><hlopt|,
    ><hlstd|a><hlopt|, ><hlstd|y><hlopt|, ><hlstd|<textunderscore>><hlopt|)
    ><hlkwa|when ><hlstd|x ><hlopt|\<less\> ><hlstd|y ><hlopt|-\<gtr\>
    ><hlstd|member x a<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|T
    ><hlopt|(><hlstd|<textunderscore>><hlopt|,
    ><hlstd|<textunderscore>><hlopt|, ><hlstd|<textunderscore>><hlopt|,
    ><hlstd|b><hlopt|) -\<gtr\> ><hlstd|member x
    b><hlendline|><next-line><hlkwa|let ><hlstd|balance ><hlopt|=
    ><hlkwa|function><hlendline|Restoring the invariants.><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|B><hlopt|,><hlkwd|T
    ><hlopt|(><hlkwd|R><hlopt|,><hlkwd|T ><hlopt|(><hlkwd|R><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|),><hlstd|y><hlopt|,><hlstd|c><hlopt|),><hlstd|z><hlopt|,><hlstd|d><hlendline|On
    next figure: left,><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|B><hlopt|,><hlkwd|T ><hlopt|(><hlkwd|R><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlkwd|T
    ><hlopt|(><hlkwd|R><hlopt|,><hlstd|b><hlopt|,><hlstd|y><hlopt|,><hlstd|c><hlopt|)),><hlstd|z><hlopt|,><hlstd|d<hlendline|top,><next-line>
    \ ><hlopt|\| ><hlkwd|B><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlkwd|T
    ><hlopt|(><hlkwd|R><hlopt|,><hlkwd|T ><hlopt|(><hlkwd|R><hlopt|,><hlstd|b><hlopt|,><hlstd|y><hlopt|,><hlstd|c><hlopt|),><hlstd|z><hlopt|,><hlstd|d><hlopt|)><hlendline|bottom,><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|B><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlkwd|T
    ><hlopt|(><hlkwd|R><hlopt|,><hlstd|b><hlopt|,><hlstd|y><hlopt|,><hlkwd|T
    ><hlopt|(><hlkwd|R><hlopt|,><hlstd|c><hlopt|,><hlstd|z><hlopt|,><hlstd|d><hlopt|))><hlendline|right,><next-line><hlstd|
    \ \ \ ><hlopt|-\<gtr\> ><hlkwd|T ><hlopt|(><hlkwd|R><hlopt|,><hlkwd|T
    ><hlopt|(><hlkwd|B><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|),><hlstd|y><hlopt|,><hlkwd|T
    ><hlopt|(><hlkwd|B><hlopt|,><hlstd|c><hlopt|,><hlstd|z><hlopt|,><hlstd|d><hlopt|))><hlendline|center
    tree.><next-line><hlstd| \ <hlopt|\|>
    color><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b
    ><hlopt|-\<gtr\> ><hlkwd|T ><hlopt|(><hlstd|color><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|)><hlendline|We
    allow red-red violation for now.><new-page>

    <hlkwa|let ><hlstd|insert x s ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let rec ><hlstd|ins ><hlopt|= ><hlkwa|function><hlendline|Like
    in unbalanced binary search tree,><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|E ><hlopt|-\<gtr\> ><hlkwd|T ><hlopt|(><hlkwd|R><hlopt|,><hlkwd|E><hlopt|,><hlstd|x><hlopt|,><hlkwd|E><hlopt|)><hlendline|but
    fix violation above created node.><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|T ><hlopt|(><hlstd|color><hlopt|,><hlstd|a><hlopt|,><hlstd|y><hlopt|,><hlstd|b><hlopt|)
    ><hlkwa|as ><hlstd|s ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|if ><hlstd|x><hlopt|\<less\>><hlstd|y ><hlkwa|then
    ><hlstd|balance ><hlopt|(><hlstd|color><hlopt|,><hlstd|ins
    a><hlopt|,><hlstd|y><hlopt|,><hlstd|b><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|else if ><hlstd|x><hlopt|\<gtr\>><hlstd|y ><hlkwa|then
    ><hlstd|balance ><hlopt|(><hlstd|color><hlopt|,><hlstd|a><hlopt|,><hlstd|y><hlopt|,><hlstd|ins
    b><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|else
    ><hlstd|s ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|match
    ><hlstd|ins s ><hlkwa|with><hlendline|We could still have red-red
    violation at root,><next-line><hlstd| \ ><hlopt|\| ><hlkwd|T
    ><hlopt|(><hlstd|<textunderscore>><hlopt|,><hlstd|a><hlopt|,><hlstd|y><hlopt|,><hlstd|b><hlopt|)
    -\<gtr\> ><hlkwd|T ><hlopt|(><hlkwd|B><hlopt|,><hlstd|a><hlopt|,><hlstd|y><hlopt|,><hlstd|b><hlopt|)><hlendline|fixed
    by coloring it black.><next-line><hlstd| \ ><hlopt|\| ><hlkwd|E
    ><hlopt|-\<gtr\> ><hlstd|failwith ><hlstr|"insert:
    impossible"><hlendline|>
  </small>

  <new-page>

  <small|<tabular|<tformat|<cwith|1|1|1|1|cell-valign|b>|<cwith|3|3|1|1|cell-valign|b>|<cwith|2|2|1|1|cell-halign|r>|<table|<row|<cell|<hlkwd|B><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlkwd|T ><hlopt|(><hlkwd|R><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|),><hlstd|y><hlopt|,><hlstd|c><hlopt|),><hlstd|z><hlopt|,><hlstd|d>>|<cell|<math|<below|<tree|<with|math-font-series|bold|z>|<tree|<with|color|red|x>|a|<tree|<with|color|red|y>|b|c>>|d>|\<Downarrow\>>>>|<cell|<hlkwd|B><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlstd|b><hlopt|,><hlstd|y><hlopt|,><hlstd|c><hlopt|)),><hlstd|z><hlopt|,><hlstd|d>>>|<row|<cell|<math|<tree|<with|math-font-series|bold|z>|<tree|<with|color|red|y>|<tree|<with|color|red|x>|a|b>|c>|d>\<Rightarrow\>>>|<cell|<math|<tree|<with|color|red|y>|<tree|<with|math-font-series|bold|x>|a|b>|<tree|<with|math-font-series|bold|z>|c|d>>>>|<cell|<math|\<Leftarrow\><tree|<with|math-font-series|bold|x>|a|<tree|<with|color|red|y>|b|<tree|<with|color|red|z>|c|d>>>>>>|<row|<cell|<hlkwd|B><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlkwd|T ><hlopt|(><hlkwd|R><hlopt|,><hlstd|b><hlopt|,><hlstd|y><hlopt|,><hlstd|c><hlopt|),><hlstd|z><hlopt|,><hlstd|d><hlopt|)>>|<cell|<math|<above|<tree|<with|math-font-series|bold|x>|a|<tree|<with|color|red|z>|<tree|<with|color|red|y>|b|c>|d>>|\<Uparrow\>>>>|<cell|<hlkwd|B><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlstd|b><hlopt|,><hlstd|y><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlstd|c><hlopt|,><hlstd|z><hlopt|,><hlstd|d><hlopt|))>>>>>>>

  \;

  <section|<new-page*>Homework>

  <\enumerate>
    <item>Derive the equations and solve them to find the type for:

    <hlkwa|let ><hlstd|cadr l ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|hd
    ><hlopt|(><hlkwc|List><hlopt|.><hlstd|tl l><hlopt|) ><hlkwa|in
    ><next-line><hlstd|cadr ><hlopt|(><hlnum|1><hlopt|::><hlnum|2><hlopt|::[]),
    ><hlstd|cadr ><hlopt|(><hlkwa|true><hlopt|::><hlkwa|false><hlopt|::[])>

    in environ. <math|\<Gamma\>=<around*|{|<with|mode|text|<hlkwc|List><hlopt|.><hlstd|hd>>:\<forall\>\<alpha\>.\<alpha\>
    list\<rightarrow\>\<alpha\>;<with|mode|text|<hlkwc|List><hlopt|.><hlstd|tl>>:\<forall\>\<alpha\>.\<alpha\>
    list\<rightarrow\>\<alpha\> list|}>>. You can take ``shortcuts'' if it is
    too many equations to write down.

    <item>What does it mean that an implementation has junk (as an algebraic
    structure for a given signature)? Is it bad?

    <item>Define a monomorphic algebraic specification (other than, but
    similar to, <math|nat<rsub|p>> or <math|string<rsub|p>>, some useful data
    type).

    <item>Discuss an example of a (monomorphic) algebraic specification where
    it would be useful to drop some axioms (giving up monomorphicity) to
    allow more efficient implementations.

    <new-page*><item>Does the example <hlkwc|ListMap> meet the requirements
    of the algebraic specification for maps? Hint: here is the definition of
    <hlkwc|List><hlopt|.><hlstd|remove<textunderscore>assoc>;
    <verbatim|compare a x> equals <hlnum|0> if and only if
    <verbatim|a><hlopt| = ><verbatim|x>.

    <small|<hlkwa|let rec ><hlstd|remove<textunderscore>assoc x ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
    []><hlendline|><next-line><hlstd| \ ><hlopt|\| (><hlstd|a><hlopt|,
    ><hlstd|b ><hlkwa|as ><hlstd|pair><hlopt|) :: ><hlstd|l
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|if
    ><hlstd|compare a x ><hlopt|= ><hlnum|0 ><hlkwa|then ><hlstd|l
    ><hlkwa|else ><hlstd|pair ><hlopt|:: ><hlstd|remove<textunderscore>assoc
    x l><hlendline|>>

    <item>Trick question: what is the computational complexity of
    <hlkwc|ListMap> or <hlkwc|TrivialMap>?

    <item>* The implementation <hlkwc|MyListMap> is inefficient: it performs
    a lot of copying and is not tail-recursive. Optimize it (without changing
    the type definition).

    <item>Add (and specify) <math|isEmpty:<around*|(|\<alpha\>,\<beta\>|)>
    map\<rightarrow\>bool> to the example algebraic specification of maps
    without increasing the burden on its implementations (i.e. without
    affecting implementations of other operations). Hint: equational
    reasoning might be not enough; consider an equivalence relation
    <math|\<approx\>> meaning ``have the same keys'', defined and used just
    in the axioms of the specification.

    <new-page*><item>Design an algebraic specification and write a signature
    for first-in-first-out queues. Provide two implementations: one
    straightforward using a list, and another one using two lists: one for
    freshly added elements providing efficient queueing of new elements, and
    ``reversed'' one for efficient popping of old elements.

    <item>Design an algebraic specification and write a signature for sets.
    Provide two implementations: one straightforward using a list, and
    another one using a map into the unit type.

    <new-page*><item>(Ex. 2.2 in Chris Okasaki ``Purely Functional Data
    Structures'') In the worst case, <verbatim|member> performs approximately
    <math|2d> comparisons, where <math|d> is the depth of the tree. Rewrite
    <verbatim|member> to take no mare than <math|d+1> comparisons by keeping
    track of a candidate element that <em|might> be equal to the query
    element (say, the last element for which <math|\<less\>> returned false)
    and checking for equality only when you hit the bottom of the tree.

    <item>(Ex. 3.10 in Chris Okasaki ``Purely Functional Data Structures'')
    The <verbatim|balance> function currently performs several unnecessary
    tests: when e.g. <verbatim|ins> recurses on the left child, there are no
    violations on the right child.

    <\enumerate>
      <item>Split <verbatim|balance> into <verbatim|lbalance> and
      <verbatim|rbalance> that test for violations of left resp. right child
      only. Replace calls to <verbatim|balance> appropriately.

      <item>One of the remaining tests on grandchildren is also unnecessary.
      Rewrite <verbatim|ins> so that it never tests the color of nodes not on
      the search path.
    </enumerate>

    <item>* Implement maps (i.e. write a module for the map signature) based
    on AVL trees. See <verbatim|http://en.wikipedia.org/wiki/AVL_tree>.
  </enumerate>
</body>

<\initial>
  <\collection>
    <associate|language|american>
    <associate|magnification|2>
    <associate|page-medium|paper>
    <associate|page-orientation|landscape>
    <associate|page-type|letter>
    <associate|par-hyphen|normal>
  </collection>
</initial>

<\references>
  <\collection>
    <associate|auto-1|<tuple|1|2>>
    <associate|auto-10|<tuple|6|17>>
    <associate|auto-11|<tuple|7|18>>
    <associate|auto-12|<tuple|8|20>>
    <associate|auto-13|<tuple|9|24>>
    <associate|auto-14|<tuple|10|27>>
    <associate|auto-15|<tuple|10.1|28>>
    <associate|auto-16|<tuple|10.2|32>>
    <associate|auto-17|<tuple|11|36>>
    <associate|auto-18|<tuple|9|39>>
    <associate|auto-19|<tuple|10.0.1|40>>
    <associate|auto-2|<tuple|2|5>>
    <associate|auto-20|<tuple|11|42>>
    <associate|auto-21|<tuple|12|45>>
    <associate|auto-22|<tuple|12|48>>
    <associate|auto-23|<tuple|12|51>>
    <associate|auto-24|<tuple|12|53>>
    <associate|auto-25|<tuple|13|55>>
    <associate|auto-3|<tuple|3|7>>
    <associate|auto-4|<tuple|3.1|10>>
    <associate|auto-5|<tuple|3.1.1|11>>
    <associate|auto-6|<tuple|3.1.2|12>>
    <associate|auto-7|<tuple|4|13>>
    <associate|auto-8|<tuple|4.1|15>>
    <associate|auto-9|<tuple|5|16>>
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
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Type
      Inference> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Parametric
      Types> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Type
      Inference, Formally> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Polymorphic Recursion
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4>>

      <with|par-left|<quote|3fn>|<new-page*>Polymorphic Rec: A list
      alternating between two types of elements
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5>>

      <with|par-left|<quote|3fn>|Polymorphic Rec: Data-Structural
      Bootstrapping <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Algebraic
      Specification> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-7><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Algebraic specifications:
      examples <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-8>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Homomorphisms>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-9><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Example:
      Maps> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-10><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Modules
      and interfaces (signatures): syntax>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-11><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Implementing
      maps: Association lists> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-12><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Implementing
      maps: Binary search trees> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-13><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Implementing
      maps: red-black trees> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-14><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|B-trees of order 4 (2-3-4 trees)
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-15>>

      <with|par-left|<quote|1.5fn>|<new-page*>Red-Black trees, without
      deletion <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-16>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Homework>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-17><vspace|0.5fn>
    </associate>
  </collection>
</auxiliary>