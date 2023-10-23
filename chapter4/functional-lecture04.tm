<TeXmacs|1.0.7.14>

<style|<tuple|beamer|highlight>>

<\body>
  <doc-data|<doc-title|Functional Programming>|<\doc-author-data|<author-name|Šukasz
  Stafiniak>>
    \;
  </doc-author-data|<author-email|lukstafi@gmail.com,
  lukstafi@ii.uni.wroc.pl>|<author-homepage|www.ii.uni.wroc.pl/~lukstafi>>>

  <doc-data|<doc-title|Lecture 4: Functions.>|<\doc-subtitle>
    Programming in untyped <math|\<lambda\>>-calculus.

    <\small>
      <em|Introduction to Lambda Calculus> Henk Barendregt, Erik Barendsen

      <em|Lecture Notes on the Lambda Calculus> Peter Selinger
    </small>
  </doc-subtitle>|>

  <new-page>

  <section|Review: a ``computation by hand'' example>

  Let's compute some larger, recursive program.<next-line>Recall that we use
  <hlkwa|fix> instead of <hlkwa|let rec> to simplify rules for recursion.
  Also remember our syntactic conventions:<next-line> <verbatim|fun x y
  -\<gtr\> e> stands for <verbatim|fun x -\<gtr\> (fun y -\<gtr\> e)>, etc.

  <hlkwa|let rec fix ><hlstd|f x ><hlopt|= ><hlstd|f ><hlopt|(><hlkwa|fix
  ><hlstd|f><hlopt|) ><hlstd|x><hlendline|Preparations.><next-line><hlkwa|type
  ><hlstd|int<textunderscore>list ><hlopt|= ><hlkwd|Nil ><hlopt|\|
  ><hlkwd|Cons ><hlkwa|of ><hlkwb|int ><hlopt|*
  ><hlstd|int<textunderscore>list><hlendline|><next-line><hlendline|We will
  evaluate (reduce) the following expression.><next-line><hlkwa|let
  ><hlstd|length ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|fix
  ><hlopt|(><hlkwa|fun ><hlstd|f l ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|match ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\| ><hlkwd|Cons
  ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1
  ><hlopt|+ ><hlstd|f xs><hlopt|) ><hlkwa|in><hlendline|><next-line><hlstd|length
  ><hlopt|(><hlkwd|Cons ><hlopt|(><hlnum|1><hlopt|, (><hlkwd|Cons
  ><hlopt|(><hlnum|2><hlopt|, ><hlkwd|Nil><hlopt|))))><hlendline|><new-page>

  <hlkwa|let ><hlstd|length ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|fix ><hlopt|(><hlkwa|fun ><hlstd|f l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match
  ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Nil ><hlopt|-\<gtr\> ><hlnum|0><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlstd|f xs><hlopt|)
  ><hlkwa|in><hlendline|><next-line><hlstd|length ><hlopt|(><hlkwd|Cons
  ><hlopt|(><hlnum|1><hlopt|, (><hlkwd|Cons ><hlopt|(><hlnum|2><hlopt|,
  ><hlkwd|Nil><hlopt|))))><hlendline|>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|let
    >>x=v<with|mode|text|<verbatim| in >>a>|<cell|\<downsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>>>
  </eqnarray*>

  <hlstd| \ ><hlkwa|fix ><hlopt|(><hlkwa|fun ><hlstd|f l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match
  ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Nil ><hlopt|-\<gtr\> ><hlnum|0><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlstd|f xs><hlopt|)
  ><hlopt|(><hlkwd|Cons ><hlopt|(><hlnum|1><hlopt|, (><hlkwd|Cons
  ><hlopt|(><hlnum|2><hlopt|, ><hlkwd|Nil><hlopt|))))>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|fix>><rsup|2>
    v<rsub|1> v<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|v<rsub|1>
    <around*|(|<with|mode|text|<verbatim|fix>><rsup|2> v<rsub|1>|)>
    v<rsub|2>>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|fix>><rsup|2>
    v<rsub|1> v<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|v<rsub|1>
    <around*|(|<with|mode|text|<verbatim|fix>><rsup|2> v<rsub|1>|)>
    v<rsub|2>>>>>
  </eqnarray*>

  <hlstd| \ ><hlopt|(><hlkwa|fun ><hlstd|f l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match
  ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Nil ><hlopt|-\<gtr\> ><hlnum|0><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlstd|f xs><hlopt|)
  ><next-line><hlopt| \ \ \ (><hlkwa|fix ><hlopt|(><hlkwa|fun ><hlstd|f l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|match
  ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt| \ \|
  ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\>
  ><hlnum|1 ><hlopt|+ ><hlstd|f xs><hlopt|))><next-line><hlopt|
  \ \ \ (><hlkwd|Cons ><hlopt|(><hlnum|1><hlopt|, (><hlkwd|Cons
  ><hlopt|(><hlnum|2><hlopt|, ><hlkwd|Nil><hlopt|))))>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1><rprime|'>
    a<rsub|2>>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1><rprime|'>
    a<rsub|2>>>>>
  </eqnarray*>

  <hlstd| \ ><hlopt|(><hlkwa|fun ><hlstd|l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match
  ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt| \ \|
  ><hlkwd|Nil ><hlopt|-\<gtr\> ><hlnum|0><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt| \ \| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlopt|(><hlkwa|fix
  ><hlopt|(><hlkwa|fun ><hlstd|f l ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlkwa|match ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt| \ \ \ \|
  ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\>
  ><hlnum|1 ><hlopt|+ ><hlstd|f xs><hlopt|))><hlstd| xs><hlopt|)
  ><next-line><hlopt| \ \ \ (><hlkwd|Cons ><hlopt|(><hlnum|1><hlopt|,
  (><hlkwd|Cons ><hlopt|(><hlnum|2><hlopt|, ><hlkwd|Nil><hlopt|))))>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v>|<cell|\<downsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v>|<cell|\<downsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>>>
  </eqnarray*>

  <hlstd| \ ><hlopt|(><hlkwa|match ><hlkwd|Cons ><hlopt|(><hlnum|1><hlopt|,
  (><hlkwd|Cons ><hlopt|(><hlnum|2><hlopt|, ><hlkwd|Nil><hlopt|)))
  ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt| \ \| ><hlkwd|Nil
  ><hlopt|-\<gtr\> ><hlnum|0><hlendline|><next-line><hlstd| \ ><hlopt| \ \|
  ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\>
  ><hlnum|1 ><hlopt|+ ><hlopt|(><hlkwa|fix ><hlopt|(><hlkwa|fun ><hlstd|f l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|match
  ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt| \ \ \ \|
  ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\>
  ><hlnum|1 ><hlopt|+ ><hlstd|f xs><hlopt|))><hlstd| xs><hlopt|) >

  <\eqnarray*>
    <tformat|<cwith|3|3|3|3|cell-halign|c>|<table|<row|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)><with|mode|text|<verbatim|
    with>>>|<cell|>|<cell|>>|<row|<cell|C<rsub|2><rsup|n><around*|(|p<rsub|1>,\<ldots\>,p<rsub|k>|)><with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
    \| >>pm>|<cell|\<downsquigarrow\>>|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)>>>|<row|<cell|>|<cell|>|<cell|<with|mode|text|<verbatim|with>
    >pm>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<cwith|3|3|3|3|cell-halign|c>|<table|<row|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)><with|mode|text|<verbatim|
    with>>>|<cell|>|<cell|>>|<row|<cell|C<rsub|2><rsup|n><around*|(|p<rsub|1>,\<ldots\>,p<rsub|k>|)><with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
    \| >>pm>|<cell|\<downsquigarrow\>>|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)>>>|<row|<cell|>|<cell|>|<cell|<with|mode|text|<verbatim|with>
    >pm>>>>
  </eqnarray*>

  <hlstd| \ ><hlopt|(><hlkwa|match ><hlkwd|Cons ><hlopt|(><hlnum|1><hlopt|,
  (><hlkwd|Cons ><hlopt|(><hlnum|2><hlopt|, ><hlkwd|Nil><hlopt|)))
  ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt| \ \| ><hlkwd|Cons
  ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1
  ><hlopt|+ ><hlopt|(><hlkwa|fix ><hlopt|(><hlkwa|fun ><hlstd|f l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|match
  ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt| \ \ \ \|
  ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\>
  ><hlnum|1 ><hlopt|+ ><hlstd|f xs><hlopt|))><hlstd| xs><hlopt|) >

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)><with|mode|text|<verbatim|
    with>>>|<cell|>|<cell|>>|<row|<cell|C<rsub|1><rsup|n><around*|(|x<rsub|1>,\<ldots\>,x<rsub|n>|)><with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
    \| >>\<ldots\>>|<cell|\<downsquigarrow\>>|<cell|a<around*|[|x<rsub|1>\<assign\>v<rsub|1>;\<ldots\>;x<rsub|n>\<assign\>v<rsub|n>|]>>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)><with|mode|text|<verbatim|
    with>>>|<cell|>|<cell|>>|<row|<cell|C<rsub|1><rsup|n><around*|(|x<rsub|1>,\<ldots\>,x<rsub|n>|)><with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
    \| >>\<ldots\>>|<cell|\<downsquigarrow\>>|<cell|a<around*|[|x<rsub|1>\<assign\>v<rsub|1>;\<ldots\>;x<rsub|n>\<assign\>v<rsub|n>|]>>>>>
  </eqnarray*>

  <hlstd| \ ><hlnum|1 ><hlopt|+ ><hlopt|(><hlkwa|fix ><hlopt|(><hlkwa|fun
  ><hlstd|f l ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|match ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt| \ \ \ \|
  ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\>
  ><hlnum|1 ><hlopt|+ ><hlstd|f xs><hlopt|))><hlopt| (><hlkwd|Cons
  ><hlopt|(><hlnum|2><hlopt|, ><hlkwd|Nil><hlopt|))>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|fix>><rsup|2>
    v<rsub|1> v<rsub|2>>|<cell|\<rightsquigarrow\>>|<cell|v<rsub|1>
    <around*|(|<with|mode|text|<verbatim|fix>><rsup|2> v<rsub|1>|)>
    v<rsub|2>>>|<row|<cell|a<rsub|1> a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|fix>><rsup|2>
    v<rsub|1> v<rsub|2>>|<cell|\<rightsquigarrow\>>|<cell|v<rsub|1>
    <around*|(|<with|mode|text|<verbatim|fix>><rsup|2> v<rsub|1>|)>
    v<rsub|2>>>|<row|<cell|a<rsub|1> a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <hlstd| \ ><hlnum|1 ><hlopt|+ ><hlopt|(><hlkwa|fun ><hlstd|f l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ >
  \ \ <hlkwa|match ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt| \ \ \ \ \ \|
  ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\>
  ><hlnum|1 ><hlopt|+ ><hlstd|f xs><hlopt|))><next-line><hlopt|
  \ \ \ \ \ \ \ (><hlkwa|fix ><hlopt|(><hlkwa|fun ><hlstd|f l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|
  \ \ \ \ match ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlopt| \ \ \ \ \| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt| \ \ \ \ \ \ \ \ \|
  ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\>
  ><hlnum|1 ><hlopt|+ ><hlstd|f xs><hlopt|))><hlopt| (><hlkwd|Cons
  ><hlopt|(><hlnum|2><hlopt|, ><hlkwd|Nil><hlopt|))>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <hlstd| \ ><hlnum|1 ><hlopt|+ ><hlopt|(><hlkwa|fun ><hlstd|l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ >
  \ \ <hlkwa|match ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt| \ \ \ \ \ \|
  ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\>
  ><hlnum|1 ><hlopt|+ ><hlopt|(><hlkwa|fix ><hlopt|(><hlkwa|fun ><hlstd|f l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|
  \ \ \ \ \ match ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlopt| \ \ \ \ \ \| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt|
  \ \ \ \ \ \ \ \ \ \| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlstd|f
  xs><hlopt|))><hlstd| xs><hlopt|))><next-line><hlopt|
  \ \ \ \ \ \ \ (><hlkwd|Cons ><hlopt|(><hlnum|2><hlopt|,
  ><hlkwd|Nil><hlopt|))>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <hlstd| \ ><hlnum|1 ><hlopt|+ ><hlopt|(><hlkwa|match ><hlkwd|Cons
  ><hlopt|(><hlnum|2><hlopt|, ><hlkwd|Nil><hlopt|)
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Nil ><hlopt|-\<gtr\> ><hlnum|0><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt| \ \ \ \ \| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlopt|(><hlkwa|fix
  ><hlopt|(><hlkwa|fun ><hlstd|f l ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa| \ \ \ \ match ><hlstd|l
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlopt|
  \ \ \ \ \| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt| \ \ \ \ \ \ \ \ \|
  ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\>
  ><hlnum|1 ><hlopt|+ ><hlstd|f xs><hlopt|))><hlstd| xs><hlopt|))>

  <\eqnarray*>
    <tformat|<cwith|3|3|3|3|cell-halign|c>|<table|<row|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)><with|mode|text|<verbatim|
    with>>>|<cell|>|<cell|>>|<row|<cell|C<rsub|2><rsup|n><around*|(|p<rsub|1>,\<ldots\>,p<rsub|k>|)><with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
    \| >>pm>|<cell|\<rightsquigarrow\>>|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)>>>|<row|<cell|>|<cell|>|<cell|<with|mode|text|<verbatim|with>
    >pm>>|<row|<cell|a<rsub|1> a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<cwith|3|3|3|3|cell-halign|c>|<table|<row|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)><with|mode|text|<verbatim|
    with>>>|<cell|>|<cell|>>|<row|<cell|C<rsub|2><rsup|n><around*|(|p<rsub|1>,\<ldots\>,p<rsub|k>|)><with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
    \| >>pm>|<cell|\<rightsquigarrow\>>|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)>>>|<row|<cell|>|<cell|>|<cell|<with|mode|text|<verbatim|with>
    >pm>>|<row|<cell|a<rsub|1> a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <hlstd| \ ><hlnum|1 ><hlopt|+ ><hlopt|(><hlkwa|match ><hlkwd|Cons
  ><hlopt|(><hlnum|2><hlopt|, ><hlkwd|Nil><hlopt|)
  ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt| \ \ \ \ \ \ \|
  ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\>
  ><hlnum|1 ><hlopt|+ ><hlopt|(><hlkwa|fix ><hlopt|(><hlkwa|fun ><hlstd|f l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ ><hlkwa|match ><hlstd|l
  ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt| \ \ \ \ \ \ \ \ \|
  ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) -\<gtr\>
  ><hlnum|1 ><hlopt|+ ><hlstd|f xs><hlopt|))><hlstd| xs><hlopt|) >

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)><with|mode|text|<verbatim|
    with>>>|<cell|>|<cell|>>|<row|<cell|C<rsub|1><rsup|n><around*|(|x<rsub|1>,\<ldots\>,x<rsub|n>|)><with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
    \| >>\<ldots\>>|<cell|\<downsquigarrow\>>|<cell|a<around*|[|x<rsub|1>\<assign\>v<rsub|1>;\<ldots\>;x<rsub|n>\<assign\>v<rsub|n>|]>>>|<row|<cell|>|<cell|>|<cell|>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)><with|mode|text|<verbatim|
    with>>>|<cell|>|<cell|>>|<row|<cell|C<rsub|1><rsup|n><around*|(|x<rsub|1>,\<ldots\>,x<rsub|n>|)><with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
    \| >>\<ldots\>>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x<rsub|1>\<assign\>v<rsub|1>;\<ldots\>;x<rsub|n>\<assign\>v<rsub|n>|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <hlstd| \ ><hlnum|1 ><hlopt|+ ><hlopt|(><hlnum|1 ><hlopt|+
  ><hlopt|(><hlkwa|fix ><hlopt|(><hlkwa|fun ><hlstd|f l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|match ><hlstd|l
  ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt|
  \ \ \ \ \ \ \ \ \ \ \| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlstd|f
  xs><hlopt|))><hlstd| Nil><hlopt|)>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|fix>><rsup|2>
    v<rsub|1> v<rsub|2>>|<cell|\<rightsquigarrow\>>|<cell|v<rsub|1>
    <around*|(|<with|mode|text|<verbatim|fix>><rsup|2> v<rsub|1>|)>
    v<rsub|2>>>|<row|<cell|a<rsub|1> a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|fix>><rsup|2>
    v<rsub|1> v<rsub|2>>|<cell|\<rightsquigarrow\>>|<cell|v<rsub|1>
    <around*|(|<with|mode|text|<verbatim|fix>><rsup|2> v<rsub|1>|)>
    v<rsub|2>>>|<row|<cell|a<rsub|1> a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <hlstd| \ ><hlnum|1 ><hlopt|+ ><hlopt|(><hlnum|1 ><hlopt|+
  ><hlopt|(><hlkwa|fun ><hlstd|f l ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|match ><hlstd|l
  ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt|
  \ \ \ \ \ \ \ \ \ \ \| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlstd|f
  xs><hlopt|)><hlopt| ><hlopt|(><hlkwa|fix ><hlopt|(><hlkwa|fun ><hlstd|f l
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|match ><hlstd|l
  ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt| \ \ \ \| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlstd|f
  xs><hlopt|))><hlstd| Nil><hlopt|)>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <hlstd| \ ><hlnum|1 ><hlopt|+ ><hlopt|(><hlnum|1 ><hlopt|+
  ><hlopt|(><hlkwa|fun ><hlstd|l ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|match ><hlstd|l
  ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt|
  \ \ \ \ \ \ \ \ \ \ \| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlopt|(><hlkwa|fix
  ><hlopt|(><hlkwa|fun ><hlstd|f l ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|match ><hlstd|l
  ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt| \ \ \ \| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlstd|f
  xs><hlopt|))><hlstd| xs><hlopt|)><hlstd| Nil><hlopt|)>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <hlstd| \ ><hlnum|1 ><hlopt|+ ><hlopt|(><hlnum|1 ><hlopt|+
  ><hlopt|(><hlkwa|match ><hlstd|Nil ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt|
  \ \ \ \ \ \ \ \ \ \ \| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlopt|(><hlkwa|fix
  ><hlopt|(><hlkwa|fun ><hlstd|f l ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|match ><hlstd|l
  ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt| \ \ \ \| ><hlkwd|Nil ><hlopt|-\<gtr\>
  ><hlnum|0><hlendline|><next-line><hlstd| \ \ \ ><hlopt|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \| ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
  ><hlstd|xs><hlopt|) -\<gtr\> ><hlnum|1 ><hlopt|+ ><hlstd|f
  xs><hlopt|))><hlstd| xs><hlopt|)><hlopt|)>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)><with|mode|text|<verbatim|
    with>>>|<cell|>|<cell|>>|<row|<cell|C<rsub|1><rsup|n><around*|(|x<rsub|1>,\<ldots\>,x<rsub|n>|)><with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
    \| >>\<ldots\>>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x<rsub|1>\<assign\>v<rsub|1>;\<ldots\>;x<rsub|n>\<assign\>v<rsub|n>|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <new-page>

  <\eqnarray*>
    <tformat|<table|<row|<cell|<with|mode|text|<verbatim|match
    >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)><with|mode|text|<verbatim|
    with>>>|<cell|>|<cell|>>|<row|<cell|C<rsub|1><rsup|n><around*|(|x<rsub|1>,\<ldots\>,x<rsub|n>|)><with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
    \| >>\<ldots\>>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x<rsub|1>\<assign\>v<rsub|1>;\<ldots\>;x<rsub|n>\<assign\>v<rsub|n>|]>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <hlstd| \ ><hlnum|1 ><hlopt|+ ><hlopt|(><hlnum|1 ><hlopt|+
  ><hlnum|0><hlopt|)>

  <\eqnarray*>
    <tformat|<table|<row|<cell|f<rsup|n> v<rsub|1> \<ldots\>
    v<rsub|n>>|<cell|\<rightsquigarrow\>>|<cell|f<around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)>>>|<row|<cell|a<rsub|1>
    a<rsub|2>>|<cell|\<downsquigarrow\>>|<cell|a<rsub|1>
    a<rsub|2><rprime|'>>>>>
  </eqnarray*>

  <hlstd| \ ><hlnum|1 ><hlopt|+ ><hlnum|1>

  <\eqnarray*>
    <tformat|<table|<row|<cell|f<rsup|n> v<rsub|1> \<ldots\>
    v<rsub|n>>|<cell|\<downsquigarrow\>>|<cell|f<around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)>>>>>
  </eqnarray*>

  <hlstd| \ ><hlnum|2><new-page>

  <section|<new-page*>Language and rules of the untyped
  <math|\<lambda\>>-calculus>

  <\itemize>
    <item>First, let's forget about types.

    <item>Next, let's introduce a shortcut:

    <\itemize>
      <item>We write <math|\<lambda\>x.a> for <verbatim|fun
      <math|x>-\<gtr\><math|a>>, <math|\<lambda\>x y.a> for <verbatim|fun
      <math|x> <math|y>-\<gtr\><math|a>>, etc.
    </itemize>

    <item>Let's forget about all other constructions, only <hlkwa|fun> and
    variables.

    <item>The real <math|\<lambda\>>-calculus has a more general reduction:

    <\eqnarray*>
      <tformat|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
      >>x<with|mode|text|<verbatim|-\<gtr\>>>a<rsub|1>|)>
      a<rsub|2>>|<cell|\<rightsquigarrow\>>|<cell|a<rsub|1><around*|[|x\<assign\>a<rsub|2>|]>>>>>
    </eqnarray*>

    (called <em|<math|\<beta\>>-reduction>) and uses <em|bound variable
    renaming> (called <em|<math|\<alpha\>>-conversion>), or some other trick,
    to avoid <em|variable capture>. But let's not over-complicate things.

    <\itemize>
      <item>We will look into the <math|\<beta\>>-reduction rule in the
      <strong|laziness> lecture.

      <item>Why is <math|\<beta\>>-reduction more general than the rule we
      use?
    </itemize>
  </itemize>

  \;

  <section|<new-page*>Booleans>

  <\itemize>
    <item>Alonzo Church introduced <math|\<lambda\>>-calculus to encode
    logic.

    <item>There are multiple ways to encode various sorts of data in
    <math|\<lambda\>>-calculus. Not all of them make sense in a typed
    setting, i.e. the straightforward encode/decode functions do not
    type-check for them.

    <item>Define <verbatim|c_true>=<math|\<lambda\>x y.x> and
    <verbatim|c_false>=<math|\<lambda\>x y.y>.

    <item>Define <verbatim|c_and>=<math|\<lambda\>x y.x y
    <with|mode|text|<verbatim|c_false>>>. Check that it works!

    <\itemize>
      <item>I.e. that <verbatim|c_and c_true c_true> =
      <verbatim|c_true>,<next-line>otherwise <verbatim|c_and a b> =
      <verbatim|c_false>.
    </itemize>
  </itemize>

  <hlkwa|let ><hlstd|c<textunderscore>true ><hlopt|= ><hlkwa|fun ><hlstd|x y
  ><hlopt|-\<gtr\> ><hlstd|x><hlendline|``True'' is projection on the first
  argument.><next-line><hlkwa|let ><hlstd|c<textunderscore>false ><hlopt|=
  ><hlkwa|fun ><hlstd|x y ><hlopt|-\<gtr\> ><hlstd|y><hlendline|And ``false''
  on the second argument.><next-line><hlkwa|let ><hlstd|c<textunderscore>and
  ><hlopt|= ><hlkwa|fun ><hlstd|x y ><hlopt|-\<gtr\> ><hlstd|x y
  c<textunderscore>false><hlendline|If one is false, then return
  false.><next-line><hlkwa|let ><hlstd|encode<textunderscore>bool b ><hlopt|=
  ><hlkwa|if ><hlstd|b ><hlkwa|then ><hlstd|c<textunderscore>true
  ><hlkwa|else ><hlstd|c<textunderscore>false><hlendline|><next-line><hlkwa|let
  ><hlstd|decode<textunderscore>bool c ><hlopt|= ><hlstd|c ><hlkwa|true
  false><hlendline|Test the functions in the toplevel.>

  <\itemize>
    <item>Define <verbatim|c_or> and <verbatim|c_not> yourself!
  </itemize>

  <section|<new-page*>If-then-else and pairs>

  <\itemize>
    <item>We will just use the OCaml syntax from now.
  </itemize>

  <hlkwa|let ><hlstd|if<textunderscore>then<textunderscore>else ><hlopt|=
  ><hlkwa|fun ><hlstd|b ><hlopt|-\<gtr\> ><hlstd|b><hlendline|Booleans select
  the argument!><small|>

  Remember to play with the functions in the toplevel.

  <hlkwa|let ><hlstd|c<textunderscore>pair m n ><hlopt|= ><hlkwa|fun
  ><hlstd|x ><hlopt|-\<gtr\> ><hlstd|x m n><hlendline|We couple
  things><next-line><hlkwa|let ><hlstd|c<textunderscore>first ><hlopt|=
  ><hlkwa|fun ><hlstd|p ><hlopt|-\<gtr\> ><hlstd|p
  c<textunderscore>true><hlendline|by passing them
  together.><next-line><hlkwa|let ><hlstd|c<textunderscore>second ><hlopt|=
  ><hlkwa|fun ><hlstd|p ><hlopt|-\<gtr\> ><hlstd|p
  c<textunderscore>false><hlendline|Check that it works!>

  <small|<hlkwa|let ><hlstd|encode<textunderscore>pair enc<textunderscore>fst
  enc<textunderscore>snd ><hlopt|(><hlstd|a><hlopt|, ><hlstd|b><hlopt|)
  =><hlendline|><next-line><hlstd| \ c<textunderscore>pair
  ><hlopt|(><hlstd|enc<textunderscore>fst a><hlopt|)
  (><hlstd|enc<textunderscore>snd b><hlopt|)><hlendline|><next-line><hlkwa|let
  ><hlstd|decode<textunderscore>pair de<textunderscore>fst
  de<textunderscore>snd c ><hlopt|= ><hlstd|c ><hlopt|(><hlkwa|fun ><hlstd|x
  y ><hlopt|-\<gtr\> ><hlstd|de<textunderscore>fst x><hlopt|,
  ><hlstd|de<textunderscore>snd y><hlopt|)><hlendline|><next-line><hlkwa|let
  ><hlstd|decode<textunderscore>bool<textunderscore>pair c ><hlopt|=
  ><hlstd|decode<textunderscore>pair decode<textunderscore>bool
  decode<textunderscore>bool c><hlendline|>>

  <\itemize>
    <item>We can define larger tuples in the same manner:

    <hlkwa|let ><hlstd|c<textunderscore>triple l m n ><hlopt|= ><hlkwa|fun
    ><hlstd|x ><hlopt|-\<gtr\> ><hlstd|x l m n><hlendline|>
  </itemize>

  \;

  <section|<new-page*>Pair-encoded natural numbers>

  <\itemize>
    <item>Our first encoding of natural numbers is as the depth of nested
    pairs whose rightmost leaf is <math|\<lambda\>x.x> and whose left
    elements are <verbatim|c_false>.
  </itemize>

  <hlkwa|let ><hlstd|pn0 ><hlopt|= ><hlkwa|fun ><hlstd|x ><hlopt|-\<gtr\>
  ><hlstd|x><hlendline|Start with the identity
  function.><next-line><hlkwa|let ><hlstd|pn<textunderscore>succ n ><hlopt|=
  ><hlstd|c<textunderscore>pair c<textunderscore>false n><hlendline|Stack
  another pair.><next-line><hlendline|><next-line><hlkwa|let
  ><hlstd|pn<textunderscore>pred ><hlopt|= ><hlkwa|fun ><hlstd|x
  ><hlopt|-\<gtr\> ><hlstd|x c<textunderscore>false><hlendline|[Explain these
  functions.]><next-line><hlkwa|let ><hlstd|pn<textunderscore>is<textunderscore>zero
  ><hlopt|= ><hlkwa|fun ><hlstd|x ><hlopt|-\<gtr\> ><hlstd|x
  c<textunderscore>true><hlendline|>

  We program in untyped lambda calculus as an exercise, and we need encoding
  / decoding to verify our exercises, so using ``magic'' for encoding /
  decoding is ``fair game''.

  <hlkwa|let rec ><hlstd|encode<textunderscore>pnat n ><hlopt|=><hlendline|We
  use <hlkwc|Obj><hlopt|.><verbatim|magic> to forget
  types.><next-line><hlstd| \ ><hlkwa|if ><hlstd|n ><hlopt|<math|\<less\>>=
  ><hlnum|0 ><hlkwa|then ><hlkwc|Obj><hlopt|.><hlstd|magic
  pn0<hlendline|><next-line> \ ><hlkwa|else ><hlstd|pn<textunderscore>succ
  ><hlopt|(><hlkwc|Obj><hlopt|.><hlstd|magic
  ><hlopt|(><hlstd|encode<textunderscore>pnat
  ><hlopt|(><hlstd|n><hlopt|-><hlnum|1><hlopt|)))><hlendline|Disregarding
  types,><next-line><hlkwa|let rec ><hlstd|decode<textunderscore>pnat pn
  ><hlopt|=><hlendline|these functions are
  straightforward!><next-line><hlstd| \ ><hlkwa|if
  ><hlstd|decode<textunderscore>bool ><hlopt|(><hlstd|pn<textunderscore>is<textunderscore>zero
  pn><hlopt|) ><hlkwa|then ><hlnum|0><hlendline|><next-line><hlstd|
  \ ><hlkwa|else ><hlnum|1 ><hlopt|+ ><hlstd|decode<textunderscore>pnat
  ><hlopt|(><hlstd|pn<textunderscore>pred
  ><hlopt|(><hlkwc|Obj><hlopt|.><hlstd|magic pn><hlopt|))><hlendline|>

  <\section>
    <new-page*>Church numerals (natural numbers in Ch. enc.)
  </section>

  <\itemize>
    <item>Do you remember our function <verbatim|power f n>? We will use its
    variant for a different representation of numbers:
  </itemize>

  <hlkwa|let ><hlstd|cn0 ><hlopt|= ><hlkwa|fun ><hlstd|f x ><hlopt|-\<gtr\>
  ><hlstd|x><hlendline|The same as <verbatim|c_false>.><next-line><hlkwa|let
  ><hlstd|cn1 ><hlopt|= ><hlkwa|fun ><hlstd|f x ><hlopt|-\<gtr\> ><hlstd|f
  x><hlendline|Behaves like identity.><next-line><hlkwa|let ><hlstd|cn2
  ><hlopt|= ><hlkwa|fun ><hlstd|f x ><hlopt|-\<gtr\> ><hlstd|f
  ><hlopt|(><hlstd|f x><hlopt|)><hlendline|><next-line><hlkwa|let ><hlstd|cn3
  ><hlopt|= ><hlkwa|fun ><hlstd|f x ><hlopt|-\<gtr\> ><hlstd|f
  ><hlopt|(><hlstd|f ><hlopt|(><hlstd|f x><hlopt|))><hlendline|>

  <\itemize>
    <item>This is the original Alonzo Church encoding.
  </itemize>

  <hlkwa|let ><hlstd|cn<textunderscore>succ ><hlopt|= ><hlkwa|fun ><hlstd|n f
  x ><hlopt|-\<gtr\> ><hlstd|f ><hlopt|(><hlstd|n f x><hlopt|)><hlendline|>

  <\itemize>
    <item>Define addition, multiplication, comparing to zero, and the
    predecesor function ``-1'' for Church numerals.

    <item>Turns out even Alozno Church couldn't define predecesor right away!
    But try to make some progress before you turn to the next slide.

    <\itemize>
      <item>His student Stephen Kleene found it.
    </itemize>
  </itemize>

  <new-page>

  <hlkwa|let rec ><hlstd|encode<textunderscore>cnat n f
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|if ><hlstd|n
  ><hlopt|<math|\<less\>>= ><hlnum|0 ><hlkwa|then ><hlopt|(><hlkwa|fun
  ><hlstd|x ><hlopt|-\<gtr\> ><hlstd|x><hlopt|) ><hlkwa|else ><hlstd|f
  ><hlopt|-><hlstd|<hlopt|\|> encode<textunderscore>cnat
  ><hlopt|(><hlstd|n><hlopt|-><hlnum|1><hlopt|)
  ><hlstd|f><hlendline|><next-line><hlkwa|let
  ><hlstd|decode<textunderscore>cnat n ><hlopt|= ><hlstd|n ><hlopt|((+)
  ><hlnum|1><hlopt|) ><hlnum|0><hlendline|><next-line><hlkwa|let ><hlstd|cn7
  f x ><hlopt|= ><hlstd|encode<textunderscore>cnat ><hlnum|7 ><hlstd|f
  x><hlendline|We need to <em|<math|\<eta\>>-expand> these
  definitions><next-line><hlkwa|let ><hlstd|cn13 f x ><hlopt|=
  ><hlstd|encode<textunderscore>cnat ><hlnum|13 ><hlstd|f x><hlendline|for
  type-system reasons.><next-line><hlendline|(Because OCaml allows
  <em|side-effects>.)><next-line><hlkwa|let ><hlstd|cn<textunderscore>add
  ><hlopt|= ><hlkwa|fun ><hlstd|n m f x ><hlopt|-\<gtr\> ><hlstd|n f
  ><hlopt|(><hlstd|m f x><hlopt|)><hlendline|Put <verbatim|n> of <verbatim|f>
  in front.><next-line><hlkwa|let ><hlstd|cn<textunderscore>mult ><hlopt|=
  ><hlkwa|fun ><hlstd|n m f ><hlopt|-\<gtr\> ><hlstd|n ><hlopt|(><hlstd|m
  f><hlopt|)><hlendline|Repeat <verbatim|n>
  times><next-line><hlendline|putting <verbatim|m> of <verbatim|f> in
  front.><next-line><hlkwa|let ><hlstd|cn<textunderscore>prev n
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|fun ><hlstd|f x
  ><hlopt|-\<gtr\>><hlendline|This is the ``Church numeral
  signature''.><next-line><hlstd| \ \ \ n><hlendline|The only thing we have
  is an <verbatim|n>-step loop.><next-line><hlstd|
  \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|g v ><hlopt|-\<gtr\> ><hlstd|v
  ><hlopt|(><hlstd|g f><hlopt|))><hlendline|We need sth that operates on
  <verbatim|f>.><next-line><hlstd| \ \ \ \ \ ><hlopt|(><hlkwa|fun
  ><hlstd|z><hlopt|-\<gtr\>><hlstd|x><hlopt|)><hlendline|We need to ignore
  the innermost step.><next-line><hlstd| \ \ \ \ \ ><hlopt|(><hlkwa|fun
  ><hlstd|z><hlopt|-\<gtr\>><hlstd|z><hlopt|)><hlendline|We've build a
  ``machine'' not results -- start the machine.>

  <verbatim|cn_is_zero> left as an exercise.

  <new-page>

  <hlstd|decode<textunderscore>cnat ><hlopt|(><hlstd|cn_prev cn3><hlopt|)>

  <\equation*>
    \<downsquigarrow\>
  </equation*>

  <hlopt|(><hlstd|cn_prev cn3><hlopt|)><hlstd| ><hlopt|((+)
  ><hlnum|1><hlopt|) ><hlnum|0>

  <\equation*>
    \<downsquigarrow\>
  </equation*>

  <hlopt|(><hlkwa|fun ><hlstd|f x ><hlopt|-\<gtr\>><next-line><hlstd|
  \ \ \ ><hlstd|cn3><next-line><hlstd| \ \ \ \ \ ><hlopt|(><hlkwa|fun
  ><hlstd|g v ><hlopt|-\<gtr\> ><hlstd|v ><hlopt|(><hlstd|g
  f><hlopt|))><next-line><hlstd| \ \ \ \ \ ><hlopt|(><hlkwa|fun
  ><hlstd|z><hlopt|-\<gtr\>><hlstd|x><hlopt|)><next-line><hlstd|
  \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|z><hlopt|-\<gtr\>><hlstd|z><hlopt|)><hlopt|)><hlstd|
  ><hlopt|((+) ><hlnum|1><hlopt|) ><hlnum|0>

  <\equation*>
    \<downsquigarrow\>
  </equation*>

  <hlopt|((><hlkwa|fun ><hlstd|f x ><hlopt|-\<gtr\> ><hlstd|f
  ><hlopt|(><hlstd|f ><hlopt|(><hlstd|f x><hlopt|)))><next-line><hlstd|
  \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|g v ><hlopt|-\<gtr\> ><hlstd|v
  ><hlopt|(><hlstd|g ><hlopt|((+) ><hlnum|1><hlopt|)><hlopt|))><next-line><hlstd|
  \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|z><hlopt|-\<gtr\>><hlnum|0><hlopt|)><next-line><hlstd|
  \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|z><hlopt|-\<gtr\>><hlstd|z><hlopt|)><hlopt|)>

  <\equation*>
    \<downsquigarrow\>
  </equation*>

  <hlopt|(><hlopt|(><hlkwa|fun ><hlstd|g v ><hlopt|-\<gtr\> ><hlstd|v
  ><hlopt|(><hlstd|g ><hlopt|((+) ><hlnum|1><hlopt|)><hlopt|))><next-line><hlstd|
  \ ><hlopt|(><hlopt|(><hlkwa|fun ><hlstd|g v ><hlopt|-\<gtr\> ><hlstd|v
  ><hlopt|(><hlstd|g ><hlopt|((+) ><hlnum|1><hlopt|)><hlopt|))><next-line><hlstd|
  \ \ \ ><hlopt|(><hlopt|(><hlkwa|fun ><hlstd|g v ><hlopt|-\<gtr\> ><hlstd|v
  ><hlopt|(><hlstd|g ><hlopt|((+) ><hlnum|1><hlopt|)><hlopt|))><next-line><hlstd|
  \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|z><hlopt|-\<gtr\>><hlnum|0><hlopt|)><hlopt|)))><next-line><hlstd|
  \ ><hlopt|(><hlkwa|fun ><hlstd|z><hlopt|-\<gtr\>><hlstd|z><hlopt|)><hlopt|)>

  <\equation*>
    \<downsquigarrow\>
  </equation*>

  <hlopt|(><hlopt|(><hlkwa|fun ><hlstd|z><hlopt|-\<gtr\>><hlstd|z><hlopt|)><next-line><hlstd|
  \ ><hlopt|(><hlopt|(><hlopt|(><hlkwa|fun ><hlstd|g v ><hlopt|-\<gtr\>
  ><hlstd|v ><hlopt|(><hlstd|g ><hlopt|((+)
  ><hlnum|1><hlopt|)><hlopt|))><next-line><hlstd|
  \ \ \ ><hlopt|(><hlopt|(><hlkwa|fun ><hlstd|g v ><hlopt|-\<gtr\> ><hlstd|v
  ><hlopt|(><hlstd|g ><hlopt|((+) ><hlnum|1><hlopt|)><hlopt|))><next-line><hlstd|
  \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|z><hlopt|-\<gtr\>><hlnum|0><hlopt|)><hlopt|)))><hlstd|
  ><hlopt|((+) ><hlnum|1><hlopt|)><hlopt|))>

  <\equation*>
    \<downsquigarrow\>
  </equation*>

  <hlopt|><hlopt|(><hlkwa|fun ><hlstd|g v ><hlopt|-\<gtr\> ><hlstd|v
  ><hlopt|(><hlstd|g ><hlopt|((+) ><hlnum|1><hlopt|)><hlopt|))><next-line><hlstd|
  \ ><hlopt|(><hlopt|(><hlkwa|fun ><hlstd|g v ><hlopt|-\<gtr\> ><hlstd|v
  ><hlopt|(><hlstd|g ><hlopt|((+) ><hlnum|1><hlopt|)><hlopt|))><next-line><hlstd|
  \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|z><hlopt|-\<gtr\>><hlnum|0><hlopt|)><hlopt|)><hlstd|
  ><hlopt|((+) ><hlnum|1><hlopt|)>

  <\equation*>
    \<downsquigarrow\>
  </equation*>

  <hlopt|><hlopt|((+) ><hlnum|1><hlopt|)><hlstd|
  ><hlopt|(><hlopt|(><hlkwa|fun ><hlstd|g v ><hlopt|-\<gtr\> ><hlstd|v
  ><hlopt|(><hlstd|g ><hlopt|((+) ><hlnum|1><hlopt|)><hlopt|))><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|z><hlopt|-\<gtr\>><hlnum|0><hlopt|)><hlstd|
  ><hlopt|((+) ><hlnum|1><hlopt|)><hlopt|)>

  <\equation*>
    \<downsquigarrow\>
  </equation*>

  <hlopt|><hlopt|((+) ><hlnum|1><hlopt|)><hlstd| ><hlopt|(><hlopt|((+)
  ><hlnum|1><hlopt|)><hlstd| ><hlopt|(><hlopt|(><hlkwa|fun
  ><hlstd|z><hlopt|-\<gtr\>><hlnum|0><hlopt|)><hlstd| ><hlopt|((+)
  ><hlnum|1><hlopt|)><hlopt|))>

  <\equation*>
    \<downsquigarrow\>
  </equation*>

  <hlopt|><hlopt|((+) ><hlnum|1><hlopt|)><hlstd| ><hlopt|(><hlopt|((+)
  ><hlnum|1><hlopt|)><hlstd| ><hlopt|(><hlnum|0><hlopt|))>

  <\equation*>
    \<downsquigarrow\>
  </equation*>

  <hlopt|><hlopt|((+) ><hlnum|1><hlopt|)><hlstd| ><hlnum|1>

  <\equation*>
    \<downsquigarrow\>
  </equation*>

  <hlopt|><hlnum|2>

  <section|<new-page*>Recursion: Fixpoint Combinator>

  <\itemize>
    <item>Turing's fixpoint combinator: <math|\<Theta\>=<around*|(|\<lambda\>x
    y.y <around*|(|x x y|)>|)> <around*|(|\<lambda\>x y.y <around*|(|x x
    y|)>|)>>

    <\eqnarray*>
      <tformat|<table|<row|<cell|N>|<cell|=>|<cell|\<Theta\>
      F>>|<row|<cell|>|<cell|=>|<cell|<around*|(|\<lambda\>x y.y <around*|(|x
      x y|)>|)> <around*|(|\<lambda\>x y.y <around*|(|x x y|)>|)>
      F>>|<row|<cell|>|<cell|=<rsub|\<rightarrow\>\<rightarrow\>>>|<cell|F
      <around*|(|<around*|(|\<lambda\>x y.y <around*|(|x x y|)>|)>
      <around*|(|\<lambda\>x y.y <around*|(|x x y|)>|)>
      F|)>>>|<row|<cell|>|<cell|=>|<cell|F <around*|(|\<Theta\> F|)>=F N>>>>
    </eqnarray*>

    <item>Curry's fixpoint combinator: <math|\<b-Y\>=\<lambda\>f.<around*|(|\<lambda\>x.f
    <around*|(|x x|)>|)> <around*|(|\<lambda\>x.f <around*|(|x x|)>|)>>

    <\eqnarray*>
      <tformat|<table|<row|<cell|N>|<cell|=>|<cell|\<b-Y\>
      F>>|<row|<cell|>|<cell|=>|<cell|<around*|(|\<lambda\>f.<around*|(|\<lambda\>x.f
      <around*|(|x x|)>|)> <around*|(|\<lambda\>x.f <around*|(|x x|)>|)>|)>
      F>>|<row|<cell|>|<cell|=<rsub|\<rightarrow\>>>|<cell|<around*|(|\<lambda\>x.F
      <around*|(|x x|)>|)> <around*|(|\<lambda\>x.F <around*|(|x
      x|)>|)>>>|<row|<cell|>|<cell|=<rsub|\<rightarrow\>>>|<cell|F
      <around*|(|<around*|(|\<lambda\>x.F <around*|(|x x|)>|)>
      <around*|(|\<lambda\>x.F <around*|(|x
      x|)>|)>|)>>>|<row|<cell|>|<cell|=<rsub|\<leftarrow\>>>|<cell|F
      <around*|(|<around*|(|\<lambda\>f.<around*|(|\<lambda\>x.f <around*|(|x
      x|)>|)> <around*|(|\<lambda\>x.f <around*|(|x x|)>|)>|)>
      F|)>>>|<row|<cell|>|<cell|=>|<cell|F <around*|(|\<b-Y\> F|)>=F N>>>>
    </eqnarray*>

    <item>Call-by-value <em|fix>point combinator:
    <math|\<lambda\>f<rprime|'>.<around*|(|\<lambda\>f x.f<rprime|'>
    <around*|(|f f|)> x|)> <around*|(|\<lambda\>f x.f<rprime|'> <around*|(|f
    f|)> x|)>>

    <\eqnarray*>
      <tformat|<table|<row|<cell|N>|<cell|=>|<cell|fix
      F>>|<row|<cell|>|<cell|=>|<cell|<around*|(|\<lambda\>f<rprime|'>.<around*|(|\<lambda\>f
      x.f<rprime|'> <around*|(|f f|)> x|)> <around*|(|\<lambda\>f
      x.f<rprime|'> <around*|(|f f|)> x|)>|)>
      F>>|<row|<cell|>|<cell|=<rsub|\<rightarrow\>>>|<cell|<around*|(|\<lambda\>f
      x.F <around*|(|f f|)> x|)> <around*|(|\<lambda\>f x.F <around*|(|f f|)>
      x|)>>>|<row|<cell|>|<cell|=<rsub|\<rightarrow\>>>|<cell|\<lambda\>x.F
      <around*|(|<around*|(|\<lambda\>f x.F <around*|(|f f|)> x|)>
      <around*|(|\<lambda\>f x.F <around*|(|f f|)> x|)>|)>
      x>>|<row|<cell|>|<cell|=<rsub|\<leftarrow\>>>|<cell|\<lambda\>x.F
      <around*|(|<around*|(|\<lambda\>f<rprime|'>.<around*|(|\<lambda\>f
      x.f<rprime|'> <around*|(|f f|)> x|)> <around*|(|\<lambda\>f
      x.f<rprime|'> <around*|(|f f|)> x|)>|)> F|)>
      x>>|<row|<cell|>|<cell|=>|<cell|\<lambda\>x.F <around*|(|fix F|)>
      x=\<lambda\>x.F N x>>|<row|<cell|>|<cell|=<rsub|\<eta\>>>|<cell|F N>>>>
    </eqnarray*>

    <item>The <math|\<lambda\>>-terms we have seen above are <strong|fixpoint
    combinators> -- means inside <math|\<lambda\>>-calculus to perform
    recursion.

    <item>What is the problem with the first two combinators?

    <\eqnarray*>
      <tformat|<table|<row|<cell|\<Theta\>
      F>|<cell|\<rightsquigarrow\>\<rightsquigarrow\>>|<cell|F
      <around*|(|<around*|(|\<lambda\>x y.y <around*|(|x x y|)>|)>
      <around*|(|\<lambda\>x y.y <around*|(|x x y|)>|)>
      F|)>>>|<row|<cell|>|<cell|\<rightsquigarrow\>\<rightsquigarrow\>>|<cell|F
      <around*|(|F <around*|(|<around*|(|\<lambda\>x y.y <around*|(|x x
      y|)>|)> <around*|(|\<lambda\>x y.y <around*|(|x x y|)>|)>
      F|)>|)>>>|<row|<cell|>|<cell|\<rightsquigarrow\>\<rightsquigarrow\>>|<cell|F
      <around*|(|F <around*|(|F <around*|(|<around*|(|\<lambda\>x y.y
      <around*|(|x x y|)>|)> <around*|(|\<lambda\>x y.y <around*|(|x x
      y|)>|)> F|)>|)>|)>>>|<row|<cell|>|<cell|\<rightsquigarrow\>\<rightsquigarrow\>>|<cell|\<ldots\>>>>>
    </eqnarray*>

    <new-page*><item>Recall the distinction between <em|expressions> and
    <em|values> from the previous lecture <em|Computation>.

    <item>The reduction rule for <math|\<lambda\>>-calculus is just meant to
    determine which expressions are considered ``equal'' -- it is highly
    <em|non-deterministic>, while on a computer, computation needs to go one
    way or another.

    <item>Using the general reduction rule of <math|\<lambda\>>-calculus, for
    a recursive definition, it is always possible to find an infinite
    reduction sequence <small|(which means that you couldn't complain when a
    nasty <math|\<lambda\>>-calculus compiler generates infinite loops for
    all recursive definitions)>.

    <\itemize>
      <item>Why?
    </itemize>

    <item>Therefore, we need more specific rules. For example, most languages
    use <math|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v\<rightsquigarrow\>a<around*|[|x\<assign\>v|]>>, which is called
    <em|call-by-value>, or <strong|eager> computation (because the program
    <em|eagerly> computes the arguments before starting to compute the
    function). (It's exactly the rule we introduced in <em|Computation>
    lecture.)

    <new-page*><item>What happens with call-by-value fixpoint combinator?

    <\eqnarray*>
      <tformat|<table|<row|<cell|fix F>|<cell|\<rightsquigarrow\>>|<cell|<around*|(|\<lambda\>f
      x.F <around*|(|f f|)> x|)> <around*|(|\<lambda\>f x.F <around*|(|f f|)>
      x|)>>>|<row|<cell|>|<cell|\<rightsquigarrow\>>|<cell|\<lambda\>x.F
      <around*|(|<around*|(|\<lambda\>f x.F <around*|(|f f|)> x|)>
      <around*|(|\<lambda\>f x.F <around*|(|f f|)> x|)>|)> x>>>>
    </eqnarray*>

    Voila -- if we use <math|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
    v\<rightsquigarrow\>a<around*|[|x\<assign\>v|]>> as the
    rule<next-line>rather than <math|<around*|(|<with|mode|text|<verbatim|fun
    >>x<with|mode|text|<verbatim|-\<gtr\>>>a<rsub|1>|)>
    a<rsub|2>\<rightsquigarrow\>a<rsub|1><around*|[|x\<assign\>a<rsub|2>|]>>,
    the computation stops. Let's compute the function on some input:

    <\eqnarray*>
      <tformat|<table|<row|<cell|fix F v>|<cell|\<rightsquigarrow\>>|<cell|<around*|(|\<lambda\>f
      x.F <around*|(|f f|)> x|)> <around*|(|\<lambda\>f x.F <around*|(|f f|)>
      x|)> v>>|<row|<cell|>|<cell|\<rightsquigarrow\>>|<cell|<around*|(|\<lambda\>x.F
      <around*|(|<around*|(|\<lambda\>f x.F <around*|(|f f|)> x|)>
      <around*|(|\<lambda\>f x.F <around*|(|f f|)> x|)>|)> x|)>
      v>>|<row|<cell|>|<cell|\<rightsquigarrow\>>|<cell|F
      <around*|(|<around*|(|\<lambda\>f x.F <around*|(|f f|)> x|)>
      <around*|(|\<lambda\>f x.F <around*|(|f f|)> x|)>|)>
      v>>|<row|<cell|>|<cell|\<rightsquigarrow\>>|<cell|F
      <around*|(|\<lambda\>x.F <around*|(|<around*|(|\<lambda\>f x.F
      <around*|(|f f|)> x|)> <around*|(|\<lambda\>f x.F <around*|(|f f|)>
      x|)>|)> x|)> v>>|<row|<cell|>|<cell|\<rightsquigarrow\>>|<cell|<with|mode|text|depends
      on >F>>>>
    </eqnarray*>

    <new-page*><item>Why the name <em|fixpoint>? If you look at our
    derivations, you'll see that they show what in math can be written as
    <math|x=f<around*|(|x|)>>. Such values <math|x> are called fixpoints of
    <math|f>. An arithmetic function can have several fixpoints, for example
    <math|f<around*|(|x|)>=x<rsup|2>> (which <math|x>es are fixpoints?) or no
    fixpoints, for example <math|f<around*|(|x|)>=x+1>.

    <item>When you define a function (or another object) by recursion, it has
    very similar meaning: there is a name that is on both sides of <math|=>.

    <item>In <math|\<lambda\>>-calculus, there are functions like
    <math|\<Theta\>> and <math|\<b-Y\>>, that take <em|any> function as an
    argument, and return its fixpoint.

    <item>We turn a specification of a recursive object into a definition, by
    solving it with respect to the recurring name: deriving
    <math|x=f<around*|(|x|)>> where <math|x> is the recurring name. We then
    have <math|x=fix<around*|(|f|)>>.

    <new-page*><item>Let's walk through it for the factorial function (we
    omit the prefix <verbatim|cn_> -- could be <verbatim|pn_> if
    <verbatim|pn1> was used instead of <verbatim|cn1> -- for numeric
    functions, and we shorten <with|mode|text|<verbatim|if_then_else>> into
    <verbatim|if_t_e>):

    <\eqnarray*>
      <tformat|<table|<row|<cell|<with|mode|text|<verbatim|fact>>
      n>|<cell|=>|<cell|<with|mode|text|<verbatim|if_t_e>>
      <around*|(|<with|mode|text|<verbatim|is_zero>> n|)>
      <with|mode|text|<verbatim|cn1>> <around*|(|<with|mode|text|<verbatim|mult>>
      n <around*|(|<with|mode|text|<verbatim|fact>>
      <around*|(|<with|mode|text|<verbatim|pred>>
      n|)>|)>|)>>>|<row|<cell|<with|mode|text|<verbatim|fact>>>|<cell|=>|<cell|\<lambda\>n.<with|mode|text|<verbatim|if_t_e>>
      <around*|(|<with|mode|text|<verbatim|is_zero>> n|)>
      <with|mode|text|<verbatim|cn1>> <around*|(|<with|mode|text|<verbatim|mult>>
      n <around*|(|<with|mode|text|<verbatim|fact>>
      <around*|(|<with|mode|text|<verbatim|pred>>
      n|)>|)>|)>>>|<row|<cell|<with|mode|text|<verbatim|fact>>>|<cell|=>|<cell|<around*|(|\<lambda\>f
      n.<with|mode|text|<verbatim|if_t_e>>
      <around*|(|<with|mode|text|<verbatim|is_zero>> n|)>
      <with|mode|text|<verbatim|cn1>> <around*|(|<with|mode|text|<verbatim|mult>>
      n <around*|(|f <around*|(|<with|mode|text|<verbatim|pred>>
      n|)>|)>|)>|)> <with|mode|text|<verbatim|fact>>>>|<row|<cell|<with|mode|text|<verbatim|fact>>>|<cell|=>|<cell|fix
      <around*|(|\<lambda\>f n.<with|mode|text|<verbatim|if_t_e>>
      <around*|(|<with|mode|text|<verbatim|is_zero>> n|)>
      <with|mode|text|<verbatim|cn1>> <around*|(|<with|mode|text|<verbatim|mult>>
      n <around*|(|f <around*|(|<with|mode|text|<verbatim|pred>>
      n|)>|)>|)>|)>>>>>
    </eqnarray*>

    The last specification is a valid definition: we just give a name to a
    <small|(<em|ground>, a.k.a. <em|closed>)> expression.

    <item>We have seen how <hlkwa|fix> works already!

    <\itemize>
      <item>Compute <verbatim|fact cn2>.
    </itemize>

    <item>What does <verbatim|fix (<hlkwa|fun> x <hlopt|-\<gtr\>> cn_succ x)>
    mean?
  </itemize>

  <section|<new-page*>Encoding of Lists and Trees>

  <\itemize>
    <item>A list is either empty, which we often call <verbatim|Empty> or
    <verbatim|Nil>, or it consists of an element followed by another list
    (called ``tail''), the other case often called <verbatim|Cons>.

    <item>Define <verbatim|nil><math|=\<lambda\>x y.y> and
    <verbatim|cons><math| H T=\<lambda\>x y.x H T>.

    <item>Add numbers stored inside a list:

    <\eqnarray*>
      <tformat|<table|<row|<cell|<with|mode|text|<verbatim|addlist>>
      l>|<cell|=>|<cell|l <around*|(|\<lambda\>h
      t.<with|mode|text|<verbatim|cn_add>> h
      <around*|(|<with|mode|text|<verbatim|addlist>> t|)>|)>
      <with|mode|text|<verbatim|cn0>>>>>>
    </eqnarray*>

    To make a proper definition, we need to apply <math|fix> to the solution
    of above equation.

    <\eqnarray*>
      <tformat|<table|<row|<cell|<with|mode|text|<verbatim|addlist>>>|<cell|=>|<cell|fix
      <around*|(|\<lambda\>f l.l <around*|(|\<lambda\>h
      t.<with|mode|text|<verbatim|cn_add>> h <around*|(|f t|)>|)>
      <with|mode|text|<verbatim|cn0>>|)>>>>>
    </eqnarray*>

    <new-page*><item>For trees, let's use a different form of binary trees
    than so far: instead of keeping elements in inner nodes, we will keep
    elements in leaves.

    <item>Define <verbatim|leaf><math| n=\<lambda\>x y.x n> and
    <verbatim|node><math| L R=\<lambda\>x y.y L R>.

    <item>Add numbers stored inside a tree:

    <\eqnarray*>
      <tformat|<table|<row|<cell|<with|mode|text|<verbatim|addtree>>
      t>|<cell|=>|<cell|t <around*|(|\<lambda\>n.n|)> <around*|(|\<lambda\>l
      r.<with|mode|text|<verbatim|cn_add>>
      <around*|(|<with|mode|text|<verbatim|addtree>> l|)>
      <around*|(|<with|mode|text|<verbatim|addtree>> r|)>|)>>>>>
    </eqnarray*>

    and, in solved form:

    <\eqnarray*>
      <tformat|<table|<row|<cell|<with|mode|text|<verbatim|addtree>>>|<cell|=>|<cell|fix
      <around*|(|\<lambda\>f t.t <around*|(|\<lambda\>n.n|)>
      <around*|(|\<lambda\>l r.<with|mode|text|<verbatim|cn_add>>
      <around*|(|f l|)> <around*|(|f r|)>|)>|)>>>>>
    </eqnarray*>
  </itemize>

  <new-page>

  <hlkwa|let ><hlstd|nil ><hlopt|= ><hlkwa|fun ><hlstd|x y ><hlopt|-\<gtr\>
  ><hlstd|y><hlendline|><next-line><hlkwa|let ><hlstd|cons h t ><hlopt|=
  ><hlkwa|fun ><hlstd|x y ><hlopt|-\<gtr\> ><hlstd|x h
  t><hlendline|><next-line><hlkwa|let ><hlstd|addlist l
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|fix ><hlopt|(><hlkwa|fun
  ><hlstd|f l ><hlopt|-\<gtr\> ><hlstd|l ><hlopt|(><hlkwa|fun ><hlstd|h t
  ><hlopt|-\<gtr\> ><hlstd|cn<textunderscore>add h ><hlopt|(><hlstd|f
  t><hlopt|)) ><hlstd|cn0><hlopt|) ><hlstd|l><hlendline|><next-line><hlopt|;;><hlendline|><next-line><hlstd|decode<textunderscore>cnat<hlendline|><next-line>
  \ ><hlopt|(><hlstd|addlist ><hlopt|(><hlstd|cons cn1 ><hlopt|(><hlstd|cons
  cn2 ><hlopt|(><hlstd|cons cn7 nil><hlopt|))));;><hlendline|><next-line><hlkwa|let
  ><hlstd|leaf n ><hlopt|= ><hlkwa|fun ><hlstd|x y ><hlopt|-\<gtr\> ><hlstd|x
  n><hlendline|><next-line><hlkwa|let ><hlstd|node l r ><hlopt|= ><hlkwa|fun
  ><hlstd|x y ><hlopt|-\<gtr\> ><hlstd|y l
  r><hlendline|><next-line><hlkwa|let ><hlstd|addtree t
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|fix ><hlopt|(><hlkwa|fun
  ><hlstd|f t ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ t
  ><hlopt|(><hlkwa|fun ><hlstd|n ><hlopt|-\<gtr\> ><hlstd|n><hlopt|)
  (><hlkwa|fun ><hlstd|l r ><hlopt|-\<gtr\> ><hlstd|cn<textunderscore>add
  ><hlopt|(><hlstd|f l><hlopt|) (><hlstd|f
  r><hlopt|))><hlendline|><next-line><hlstd| \ ><hlopt|)
  ><hlstd|t><hlendline|><next-line><hlopt|;;><hlendline|><next-line><hlstd|decode<textunderscore>cnat<hlendline|><next-line>
  \ ><hlopt|(><hlstd|addtree ><hlopt|(><hlstd|node ><hlopt|(><hlstd|node
  ><hlopt|(><hlstd|leaf cn3><hlopt|) (><hlstd|leaf
  cn7><hlopt|))><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|leaf
  cn1><hlopt|)));;><hlendline|><new-page>

  <\itemize>
    <item>Observe a regularity: when we encode a variant type with <math|n>
    variants, for each variant we define a function that takes <math|n>
    arguments.

    <item>If the <math|k>th variant <math|C<rsub|k>> has <math|m<rsub|k>>
    parameters, then the function <math|c<rsub|k>> that encodes it will have
    the form:

    <\equation*>
      C<rsub|k><around*|(|v<rsub|1>,\<ldots\>,v<rsub|m<rsub|k>>|)>\<sim\>c<rsub|k>
      v<rsub|1> \<ldots\> v<rsub|m<rsub|k>>=\<lambda\>x<rsub|1>\<ldots\>x<rsub|n>.x<rsub|k>
      v<rsub|1> \<ldots\> v<rsub|m<rsub|k>>
    </equation*>

    <item>The encoded variants serve as a shallow pattern matching with
    guaranteed exhaustiveness: <math|k>th argument corresponds to <math|k>th
    branch of pattern matching.
  </itemize>

  <section|<new-page*>Looping Recursion>

  <\itemize>
    <item>Let's come back to numbers defined as lengths lists and define
    addition:
  </itemize>

  <hlkwa|let ><hlstd|pn<textunderscore>add m n
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|fix ><hlopt|(><hlkwa|fun
  ><hlstd|f m n ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ if<textunderscore>then<textunderscore>else
  ><hlopt|(><hlstd|pn<textunderscore>is<textunderscore>zero
  m><hlopt|)><next-line><hlstd| \ \ \ \ \ n
  ><hlopt|(><hlstd|pn<textunderscore>succ ><hlopt|(><hlstd|f
  ><hlopt|(><hlstd|pn<textunderscore>pred m><hlopt|)
  ><hlstd|n><hlopt|))><hlendline|><next-line><hlstd| \ ><hlopt|) ><hlstd|m
  n><hlopt|;;><hlendline|><next-line><hlstd|decode<textunderscore>pnat
  ><hlopt|(><hlstd|pn<textunderscore>add pn3 pn3><hlopt|);;>

  <\itemize>
    <item>Oops... OCaml says:<next-line><verbatim|Stack overflow during
    evaluation (looping recursion?).>

    <item>What is wrong? Nothing as far as <math|\<lambda\>>-calculus is
    concerned. But OCaml and F# always compute arguments before calling a
    function. By definition of <hlkwa|fix>, <verbatim|f> corresponds to
    recursively calling <verbatim|pn_add>.
    Therefore,<next-line><hlopt|(><hlstd|pn<textunderscore>succ
    ><hlopt|(><hlstd|f ><hlopt|(><hlstd|pn<textunderscore>pred m><hlopt|)
    ><hlstd|n><hlopt|))> will be called regardless of
    what<next-line><hlopt|(><hlstd|pn<textunderscore>is<textunderscore>zero
    m><hlopt|)> returns!

    <item>Why <verbatim|addlist> and <verbatim|addtree> work?

    <new-page*><item><verbatim|addlist> and <verbatim|addtree> work because
    their recursive calls are ``guarded'' by corresponding <hlkwa|fun>. What
    is inside of <hlkwa|fun> is not computed immediately, only when the
    function is applied to argument(s).

    <item>To avoid looping recursion, you need to guard all recursive calls.
    Besides putting them inside <hlkwa|fun>, in OCaml or F# you can also put
    them in branches of a <hlkwa|match> clause, as long as one of the
    branches does not have unguarded recursive calls!

    <new-page*><item>The trick to use with functions like
    <verbatim|if_then_else>, is to guard their arguments with
    <hlkwa|fun><verbatim| x><hlopt| -\<gtr\>>, where <verbatim|x> is not
    used, and apply the <em|result> of <verbatim|if_then_else> to some dummy
    value.

    <\itemize>
      <item>In OCaml or F# we would guard by <hlkwa|fun ><hlopt|() -\<gtr\>>,
      and then apply to <hlopt|()>, but we do not have datatypes like
      <verbatim|unit> in <math|\<lambda\>>-calculus.
    </itemize>
  </itemize>

  <hlkwa|let ><hlstd|pn<textunderscore>add m n
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|fix ><hlopt|(><hlkwa|fun
  ><hlstd|f m n ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|(><hlstd|if<textunderscore>then<textunderscore>else
  ><hlopt|(><hlstd|pn<textunderscore>is<textunderscore>zero
  m><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ \ ><hlopt|(><hlkwa|fun
  ><hlstd|x ><hlopt|-\<gtr\> ><hlstd|n><hlopt|) (><hlkwa|fun ><hlstd|x
  ><hlopt|-\<gtr\> ><hlstd|pn<textunderscore>succ ><hlopt|(><hlstd|f
  ><hlopt|(><hlstd|pn<textunderscore>pred m><hlopt|)
  ><hlstd|n><hlopt|)))><hlendline|><next-line><hlstd|
  \ \ \ \ \ id<hlendline|><next-line> \ ><hlopt|) ><hlstd|m
  n><hlopt|;;><hlendline|><next-line><hlstd|decode<textunderscore>pnat
  ><hlopt|(><hlstd|pn<textunderscore>add pn3
  pn3><hlopt|);;><hlendline|><next-line><hlstd|decode<textunderscore>pnat
  ><hlopt|(><hlstd|pn<textunderscore>add pn3
  pn7><hlopt|);;><hlendline|><next-line>

  <section|<new-page*>In-class Work and Homework>

  <\enumerate>
    Define (implement) and verify:\ 

    <item><verbatim|c_or> and <verbatim|c_not>;

    <item>exponentiation for Church numerals;

    <item>is-zero predicate for Church numerals;

    <item>even-number predicate for Church numerals;

    <item>multiplication for pair-encoded natural numbers;

    <item>factorial <math|n!> for pair-encoded natural numbers.

    <item>Construct <math|\<lambda\>>-terms
    <math|m<rsub|0>,m<rsub|1>,\<ldots\>> such that for all <math|n> one has:

    <\eqnarray*>
      <tformat|<table|<row|<cell|m<rsub|0>>|<cell|=>|<cell|x>>|<row|<cell|m<rsub|n+1>>|<cell|=>|<cell|m<rsub|n+2>
      m<rsub|n>>>>>
    </eqnarray*>

    (where equality is after performing <math|\<beta\>>-reductions).

    <new-page*><item>Define (implement) and verify a function computing: the
    length of a list (in Church numerals);

    <item><verbatim|cn_max> -- maximum of two Church numerals;

    <item>the depth of a tree (in Church numerals).

    <item>Representing side-effects as an explicitly ``passed around'' state
    value, write combinators that represent the imperative constructs:

    <\enumerate>
      <item><hlkwa|for>...<hlkwa|to>...

      <item><hlkwa|for>...<hlkwa|downto>...

      <item><hlkwa|while>...<hlkwa|do>...

      <item><hlkwa|do>...<hlkwa|while>...

      <item><hlkwa|repeat>...<hlkwa|until>...
    </enumerate>

    <new-page*>Rather than writing a <math|\<lambda\>>-term using the
    encodings that we've learnt, just implement the functions in OCaml / F#,
    using built-in <hlkwb|int> and <hlkwb|bool> types. You can use <hlkwa|let
    rec> instead of <hlkwa|fix>.

    <\itemize>
      <item>For example, in exercise (a), write a function <hlkwa|let rec
      ><verbatim|for_to f beg_i end_i s ><hlopt|=>... where <verbatim|f>
      takes arguments <verbatim|i> ranging from <verbatim|beg_i> to
      <verbatim|end_i>, state <verbatim|s> at given step, and returns state
      <verbatim|s> at next step; the <verbatim|for_to> function returns the
      state after the last step.

      <item>And in exercise (c), write a function <hlkwa|let rec
      ><verbatim|while_do p f s ><hlopt|=>... where both <verbatim|p> and
      <verbatim|f> take state <verbatim|s> at given step, and if <verbatim|p
      s> returns true, then <verbatim|f s> is computed to obtain state at
      next step; the <verbatim|while_do> function returns the state after the
      last step.
    </itemize>

    Do not use the imperative features of OCaml and F#, we will not even
    cover them in this course!
  </enumerate>

  <new-page*>Despite we will not cover them, it is instructive to see the
  implementation using the imperative features, to better understand what is
  actually required of a solution to the last exercise.

  <\enumerate-alpha>
    <item><hlkwa|let ><hlstd|for<textunderscore>to f beg<textunderscore>i
    end<textunderscore>i s ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|s ><hlopt|= ><hlkwb|ref ><hlstd|s
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|for ><hlstd|i
    ><hlopt|= ><hlstd|beg<textunderscore>i ><hlkwa|to
    ><hlstd|end<textunderscore>i ><hlkwa|do><hlendline|><next-line><hlstd|
    \ \ \ s ><hlopt|:= ><hlstd|f i ><hlopt|!><hlstd|s<hlendline|><next-line>
    \ ><hlkwa|done><hlopt|;><hlendline|><next-line><hlstd|
    \ ><hlopt|!><hlstd|s>

    <item><hlkwa|let ><hlstd|for<textunderscore>downto f beg<textunderscore>i
    end<textunderscore>i s ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|s ><hlopt|= ><hlkwb|ref ><hlstd|s
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|for ><hlstd|i
    ><hlopt|= ><hlstd|beg<textunderscore>i ><hlkwa|downto
    ><hlstd|end<textunderscore>i ><hlkwa|do><hlendline|><next-line><hlstd|
    \ \ \ s ><hlopt|:= ><hlstd|f i ><hlopt|!><hlstd|s<hlendline|><next-line>
    \ ><hlkwa|done><hlopt|;><hlendline|><next-line><hlstd|
    \ ><hlopt|!><hlstd|s>

    <new-page*><item><hlkwa|let ><hlstd|while<textunderscore>do p f s
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|s
    ><hlopt|= ><hlkwb|ref ><hlstd|s ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwa|while ><hlstd|p ><hlopt|!><hlstd|s
    ><hlkwa|do><hlendline|><next-line><hlstd| \ \ \ s ><hlopt|:= ><hlstd|f
    ><hlopt|!><hlstd|s<hlendline|><next-line>
    \ ><hlkwa|done><hlopt|;><hlendline|><next-line><hlstd|
    \ ><hlopt|!><hlstd|s>

    <item><hlkwa|let ><hlstd|do<textunderscore>while p f s
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|s
    ><hlopt|= ><hlkwb|ref ><hlopt|(><hlstd|f s><hlopt|)
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|while ><hlstd|p
    ><hlopt|!><hlstd|s ><hlkwa|do><hlendline|><next-line><hlstd| \ \ \ s
    ><hlopt|:= ><hlstd|f ><hlopt|!><hlstd|s<hlendline|><next-line>
    \ ><hlkwa|done><hlopt|;><hlendline|><next-line><hlstd|
    \ ><hlopt|!><hlstd|s>

    <item><hlkwa|let ><hlstd|repeat<textunderscore>until p f s
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|s
    ><hlopt|= ><hlkwb|ref ><hlopt|(><hlstd|f s><hlopt|)
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|while ><hlstd|not
    ><hlopt|(><hlstd|p ><hlopt|!><hlstd|s><hlopt|)
    ><hlkwa|do><hlendline|><next-line><hlstd| \ \ \ s ><hlopt|:= ><hlstd|f
    ><hlopt|!><hlstd|s<hlendline|><next-line>
    \ ><hlkwa|done><hlopt|;><hlendline|><next-line><hlstd|
    \ ><hlopt|!><hlstd|s>
  </enumerate-alpha>
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
    <associate|auto-10|<tuple|10|22>>
    <associate|auto-11|<tuple|4|27>>
    <associate|auto-12|<tuple|4|28>>
    <associate|auto-13|<tuple|5|32>>
    <associate|auto-14|<tuple|5|33>>
    <associate|auto-15|<tuple|6|34>>
    <associate|auto-16|<tuple|7|36>>
    <associate|auto-17|<tuple|8|38>>
    <associate|auto-18|<tuple|9|39>>
    <associate|auto-19|<tuple|10.0.1|40>>
    <associate|auto-2|<tuple|2|18>>
    <associate|auto-20|<tuple|11|42>>
    <associate|auto-21|<tuple|12|45>>
    <associate|auto-22|<tuple|12|48>>
    <associate|auto-23|<tuple|12|51>>
    <associate|auto-24|<tuple|12|53>>
    <associate|auto-25|<tuple|13|55>>
    <associate|auto-3|<tuple|3|19>>
    <associate|auto-4|<tuple|4|20>>
    <associate|auto-5|<tuple|5|21>>
    <associate|auto-6|<tuple|6|22>>
    <associate|auto-7|<tuple|7|27>>
    <associate|auto-8|<tuple|8|33>>
    <associate|auto-9|<tuple|9|37>>
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
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Review:
      a ``computation by hand'' example> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Language
      and rules of the untyped <with|color|<quote|dark
      red>|<with|mode|<quote|math>|\<lambda\>>>-calculus>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Booleans>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>If-then-else
      and pairs> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Pair-encoded
      natural numbers> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5><vspace|0.5fn>

      <vspace*|1fn><\with|font-series|<quote|bold>|math-font-series|<quote|bold>>
        <new-page*>Church numerals (natural numbers in Ch. enc.)
      </with> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Recursion:
      Fixpoint Combinator> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-7><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Encoding
      of Lists and Trees> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-8><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>In-class
      Work and Homework> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-9><vspace|0.5fn>
    </associate>
  </collection>
</auxiliary>