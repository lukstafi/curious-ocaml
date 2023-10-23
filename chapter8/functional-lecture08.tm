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

  <doc-data|<doc-title|Lecture 8: Monads>|<\doc-subtitle>
    List comprehensions. Basic monads; transformers. Probabilistic
    Programming.<next-line>Lightweight cooperative threads.

    <\small>
      <very-small|Some examples from Tomasz Wierzbicki.> Jeff Newbern
      <em|``All About Monads''>.<next-line>M. Erwig, S. Kollmansberger
      <em|``Probabilistic Functional Programming in
      Haskell''>.<next-line>Jerome Vouillon <em|``Lwt: a Cooperative Thread
      Library''>.
    </small>
  </doc-subtitle>|>

  <center|If you see any error on the slides, let me know!>

  <section|<new-page*>List comprehensions>

  <\itemize>
    <item>Recall the awkward syntax we used in the Countdown Problem example:

    <\itemize>
      <item>Brute-force generation:

      <small|<hlkwa|let ><hlstd|combine l r
      ><hlopt|=><hlendline|><next-line><hlstd|
      \ ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
      ><hlstd|o><hlopt|-\<gtr\>><hlkwd|App
      ><hlopt|(><hlstd|o><hlopt|,><hlstd|l><hlopt|,><hlstd|r><hlopt|))
      [><hlkwd|Add><hlopt|; ><hlkwd|Sub><hlopt|; ><hlkwd|Mul><hlopt|;
      ><hlkwd|Div><hlopt|]><hlendline|><next-line><hlkwa|let rec
      ><hlstd|exprs ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd|
      \ ><hlopt|\| [] -\<gtr\> []><hlendline|><next-line><hlstd| \ ><hlopt|\|
      [><hlstd|n><hlopt|] -\<gtr\> [><hlkwd|Val
      ><hlstd|n><hlopt|]><hlendline|><next-line><hlstd| \ <hlopt|\|> ns
      ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ split ns
      <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun
      ><hlopt|(><hlstd|ls><hlopt|,><hlstd|rs><hlopt|)
      -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ exprs ls
      <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|l
      ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ exprs rs
      <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|r
      ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
      \ \ \ \ \ \ \ \ \ combine l r><hlopt|)))><hlendline|>>

      <item>Genarate-and-test scheme:

      <small|<hlkwa|let ><hlstd|guard p e ><hlopt|=><hlkwa| if ><hlstd|p e
      ><hlkwa|then ><hlopt|[><hlstd|e><hlopt|] ><hlkwa|else
      ><hlopt|[]><hlendline|><next-line><hlkwa|let ><hlstd|solutions ns n
      ><hlopt|=><hlendline|><next-line><hlstd| \ choices ns
      <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|ns'
      ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ exprs ns'
      <hlopt|\|>><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
      \ \ \ \ \ guard ><hlopt|(><hlkwa|fun ><hlstd|e ><hlopt|-\<gtr\>
      ><hlstd|eval e ><hlopt|= ><hlkwd|Some ><hlstd|n><hlopt|))>><hlendline|>
    </itemize>

    <item>Recall that we introduced the operator

    <hlkwa|let ><hlopt|( ><hlstd|<hlopt|\|>><hlopt|-\<gtr\> ) ><hlstd|x f
    ><hlopt|= ><hlstd|concat<textunderscore>map f x><hlendline|>

    <item>We can do better with <em|list comprehensions> syntax extension.

    <hlstd|#load ><hlstr|"dynlink.cma"><hlopt|;;><hlendline|><next-line><hlstd|#load
    ><hlstr|"camlp4o.cma"><hlopt|;;><hlendline|><next-line><hlstd|#load
    ><hlstr|"Camlp4Parsers/Camlp4ListComprehension.cmo"><hlopt|;;><hlendline|>

    <hlkwa|let ><hlstd|test ><hlopt|= [><hlstd|i ><hlopt|* ><hlnum|2
    ><hlstd|<hlopt|\|> i ><hlopt|\<less\>- ><hlstd|from<textunderscore>to
    ><hlnum|2 22><hlopt|; ><hlstd|i ><hlkwa|mod ><hlnum|3 ><hlopt|=
    ><hlnum|0><hlopt|]><hlendline|>

    <item>What it means:

    <\itemize>
      <item><hlopt|[><hlstd|expr><hlstd| <hlopt|\| ]>> can be translated as
      <hlopt|[><hlstd|expr><hlstd|<hlopt|]>>

      <item><hlstd|<hlopt|[><hlstd|expr><hlopt| \|> v ><hlopt|\<less\>-
      ><hlstd|generator><hlopt|; ><em|more><hlopt|]> can be translated as

      <verbatim|generator><hlopt| \|-\<gtr\> (><hlkwa|fun ><hlstd|v
      ><hlopt|-\<gtr\> >translation of <hlstd|<hlopt|[><hlstd|expr><hlopt|
      \|> ><em|more><hlopt|]><hlopt|)>

      <item><hlstd|<hlopt|[><hlstd|expr><hlopt| \|>
      ><verbatim|condition><hlopt|; ><em|more><hlopt|]> can be translated as

      <hlkwa|if ><hlstd|condition ><hlkwa|then >translation of
      <hlopt|[><verbatim|expr ><hlopt|\| ><em|more><hlopt|] ><hlkwa|else
      ><hlopt|[]>
    </itemize>

    <new-page*><item>Revisiting the Countdown Problem code snippets:

    <\itemize>
      <item>Brute-force generation:

      <hlkwa|let rec ><hlstd|exprs ><hlopt|=
      ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| []
      -\<gtr\> []><hlendline|><next-line><hlstd| \ ><hlopt|\|
      [><hlstd|n><hlopt|] -\<gtr\> [><hlkwd|Val
      ><hlstd|n><hlopt|]><hlendline|><next-line><hlstd| \ <hlopt|\|> ns
      ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
      \ \ \ ><hlopt|[><hlkwd|App ><hlopt|(><hlstd|o><hlopt|,><hlstd|l><hlopt|,><hlstd|r><hlopt|)
      \| (><hlstd|ls><hlopt|,><hlstd|rs><hlopt|) \<less\>- ><hlstd|split
      ns><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ l ><hlopt|\<less\>-
      ><hlstd|exprs ls><hlopt|; ><hlstd|r ><hlopt|\<less\>- ><hlstd|exprs
      rs><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ o ><hlopt|\<less\>-
      [><hlkwd|Add><hlopt|; ><hlkwd|Sub><hlopt|; ><hlkwd|Mul><hlopt|;
      ><hlkwd|Div><hlopt|]]><hlendline|>

      <item>Genarate-and-test scheme:

      <hlkwa|let ><hlstd|solutions ns n ><hlopt|=><hlendline|><next-line><hlstd|
      \ ><hlopt|[><hlstd|e <hlopt|\|> ns' ><hlopt|\<less\>- ><hlstd|choices
      ns><hlopt|;><hlendline|><next-line><hlstd| \ \ e ><hlopt|\<less\>-
      ><hlstd|exprs ns'><hlopt|; ><hlstd|eval e ><hlopt|= ><hlkwd|Some
      ><hlstd|n><hlopt|]><hlendline|>
    </itemize>

    <item>Subsequences using list comprehensions (with garbage):

    <hlkwa|let rec ><hlstd|subseqs l ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|match ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|\| [] -\<gtr\> [[]]><hlendline|><next-line><hlstd|
    \ \ \ <hlopt|\|> x><hlopt|::><hlstd|xs ><hlopt|-\<gtr\> [><hlstd|ys
    <hlopt|\|> px ><hlopt|\<less\>- ><hlstd|subseqs xs><hlopt|; ><hlstd|ys
    ><hlopt|\<less\>- [><hlstd|px><hlopt|;
    ><hlstd|x><hlopt|::><hlstd|px><hlopt|]]><hlendline|>

    <new-page*><item>Computing permutations using list comprehensions:

    <\itemize>
      <item>via insertion

      <hlkwa|let rec ><hlstd|insert x ><hlopt|=
      ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| []
      -\<gtr\> [[><hlstd|x><hlopt|]]><hlendline|><next-line><hlstd|
      \ <hlopt|\|> y><hlopt|::><hlstd|ys' ><hlkwa|as ><hlstd|ys
      ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
      \ \ \ ><hlopt|(><hlstd|x><hlopt|::><hlstd|ys><hlopt|) ::
      [><hlstd|y><hlopt|::><hlstd|zs <hlopt|\|> zs ><hlopt|\<less\>-
      ><hlstd|insert x ys'><hlopt|]><hlendline|><next-line><hlkwa|let rec
      ><hlstd|ins<textunderscore>perms ><hlopt|=
      ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| []
      -\<gtr\> [[]]><hlendline|><next-line><hlstd| \ <hlopt|\|>
      x><hlopt|::><hlstd|xs ><hlopt|-\<gtr\> [><hlstd|zs <hlopt|\|> ys
      ><hlopt|\<less\>- ><hlstd|ins<textunderscore>perms xs><hlopt|;
      ><hlstd|zs ><hlopt|\<less\>- ><hlstd|insert ys><hlopt|]>

      <item>via selection

      <hlkwa|let rec ><hlstd|select ><hlopt|=
      ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
      [><hlstd|x><hlopt|] -\<gtr\> [><hlstd|x><hlopt|,[]]><hlendline|><next-line><hlstd|
      \ <hlopt|\|> x><hlopt|::><hlstd|xs ><hlopt|-\<gtr\>
      (><hlstd|x><hlopt|,><hlstd|xs><hlopt|) :: [ ><hlstd|y><hlopt|,
      ><hlstd|x><hlopt|::><hlstd|ys <hlopt|\|> y><hlopt|,><hlstd|ys
      ><hlopt|\<less\>- ><hlstd|select xs><hlopt|]><hlendline|><next-line><hlkwa|let
      rec ><hlstd|sel<textunderscore>perms ><hlopt|=
      ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| []
      -\<gtr\> [[]]><hlendline|><next-line><hlstd| \ <hlopt|\|> xs
      ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
      \ \ \ ><hlopt|[><hlstd|x><hlopt|::><hlstd|ys <hlopt|\|>
      x><hlopt|,><hlstd|xs' ><hlopt|\<less\>- ><hlstd|select xs><hlopt|;
      ><hlstd|ys ><hlopt|\<less\>- ><hlstd|sel<textunderscore>perms
      xs'><hlopt|]><hlendline|>
    </itemize>
  </itemize>

  <section|<new-page*>Generalized comprehensions aka. <em|do-notation>>

  <\itemize>
    <item>We need to install the syntax extension <verbatim|pa_monad>

    <\itemize>
      <item>by copying the <verbatim|pa_monad.cmo or pa_monad400.cmo> (for
      OCaml 4.0) file from the course page,

      <item>or if it does not work, by compiling from sources at<next-line>
      <hlink|http://www.cas.mcmaster.ca/~carette/pa_monad/|http://www.cas.mcmaster.ca/~carette/pa_monad/><next-line>and
      installing under a Unix-like shell (Windows: the Cygwin shell).

      <\itemize>
        <item>Under Debian/Ubuntu, you may need to install
        <verbatim|camlp4-extras>
      </itemize>
    </itemize>

    <item><hlkwa|let rec ><hlstd|exprs ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
    []><hlstd|<hlendline|><next-line> \ ><hlopt|\| [><hlstd|n><hlopt|]
    -\<gtr\> ><hlopt|[><hlkwd|Val ><hlstd|n><hlopt|]><hlendline|><next-line><hlstd|
    \ <hlopt|\|> ns ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|perform with ><hlopt|(><hlstd|<hlopt|\|>><hlopt|-\<gtr\>)
    ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|(><hlstd|ls><hlopt|,><hlstd|rs><hlopt|) \<less\>--
    ><hlstd|split ns><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ l
    ><hlopt|\<less\>-- ><hlstd|exprs ls><hlopt|; ><hlstd|r ><hlopt|\<less\>--
    ><hlstd|exprs rs><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ o
    ><hlopt|\<less\>-- [><hlkwd|Add><hlopt|; ><hlkwd|Sub><hlopt|;
    ><hlkwd|Mul><hlopt|; ><hlkwd|Div><hlopt|];><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|[><hlkwd|App ><hlopt|(><hlstd|o><hlopt|,><hlstd|l><hlopt|,><hlstd|r><hlopt|)]><hlendline|>

    <new-page*><item>The <hlkwa|perform> syntax does not seem to support
    guards...

    <hlkwa|let ><hlstd|solutions ns n ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|perform with ><hlopt|(><hlstd|<hlopt|\|>><hlopt|-\<gtr\>)
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ns' ><hlopt|\<less\>--
    ><hlstd|choices ns><hlopt|;><hlendline|><next-line><hlstd| \ \ \ e
    ><hlopt|\<less\>-- ><hlstd|exprs ns'><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ eval e ><hlopt|= ><hlkwd|Some ><hlstd|n><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ e><hlendline|>

    <hlstd| \ \ \ \ \ eval e ><hlopt|= ><hlkwd|Some
    ><hlstd|n><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ \ \ <textasciicircum><textasciicircum><textasciicircum><textasciicircum><textasciicircum><textasciicircum><textasciicircum><textasciicircum><textasciicircum><textasciicircum><textasciicircum><textasciicircum><textasciicircum><textasciicircum><textasciicircum>><hlendline|><next-line><hlkwd|Error><hlopt|:
    ><hlkwd|This ><hlstd|expression has ><hlkwa|type ><hlkwb|bool ><hlstd|but
    an expression was expected ><hlkwa|of type><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ 'a list><hlendline|>

    <item>So it wants a list... What can we do?

    <new-page*><item>We can decide whether to return anything

    <hlkwa|let ><hlstd|solutions ns n ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|perform with ><hlopt|(><hlstd|<hlopt|\|>><hlopt|-\<gtr\>)
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ns' ><hlopt|\<less\>--
    ><hlstd|choices ns><hlopt|;><hlendline|><next-line><hlstd| \ \ \ e
    ><hlopt|\<less\>-- ><hlstd|exprs ns'><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|if ><hlstd|eval e ><hlopt|= ><hlkwd|Some ><hlstd|n
    ><hlkwa|then ><hlopt|[><hlstd|e><hlopt|] ><hlkwa|else
    ><hlopt|[]><hlendline|>

    <item>But what if we want to check earlier...

    General ``guard check'' function

    <hlkwa|let ><hlstd|guard p ><hlopt|= ><hlkwa|if ><hlstd|p ><hlkwa|then
    ><hlopt|[()] ><hlkwa|else ><hlopt|[]><hlendline|>

    <item><hlkwa|let ><hlstd|solutions ns n
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|perform with
    ><hlopt|(><hlstd|<hlopt|\|>><hlopt|-\<gtr\>)
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ns' ><hlopt|\<less\>--
    ><hlstd|choices ns><hlopt|;><hlendline|><next-line><hlstd| \ \ \ e
    ><hlopt|\<less\>-- ><hlstd|exprs ns'><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ guard ><hlopt|(><hlstd|eval e ><hlopt|= ><hlkwd|Some
    ><hlstd|n><hlopt|);><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|[><hlstd|e><hlopt|]><hlendline|>
  </itemize>

  <section|<new-page*>Monads>

  <\itemize>
    <item>A polymorphic type <verbatim|'a monad> (or <verbatim|'a Monad.t>,
    etc.) that supports at least two operations:

    <\itemize>
      <item><verbatim|bind : 'a monad -\<gtr\> ('a -\<gtr\> 'b monad)
      -\<gtr\> 'b monad>

      <item><verbatim|return : 'a -\<gtr\> 'a monad>

      <item><hlopt|\<gtr\>\<gtr\>=> is infix syntax for <verbatim|bind>:
      <hlkwa|let ><hlopt|(\<gtr\>\<gtr\>=) ><hlstd|a b ><hlopt|= ><hlstd|bind
      a b>
    </itemize>

    <item>With <verbatim|bind> in scope, we do not need the <hlkwa|with>
    clause in <hlkwa|perform>

    <hlkwa|let ><hlstd|bind a b ><hlopt|= ><hlstd|concat<textunderscore>map b
    a><hlendline|><next-line><hlkwa|let ><hlstd|return x ><hlopt|=
    [><hlstd|x><hlopt|]><hlstd| \ ><hlendline|><next-line><hlkwa|let
    ><hlstd|solutions ns n ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ ns'
    ><hlopt|\<less\>-- ><hlstd|choices ns><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ e ><hlopt|\<less\>-- ><hlstd|exprs
    ns'><hlopt|;><hlendline|><next-line><hlstd| \ \ \ guard
    ><hlopt|(><hlstd|eval e ><hlopt|= ><hlkwd|Some
    ><hlstd|n><hlopt|);><hlendline|><next-line><hlstd| \ \ \ return
    e><hlendline|>

    <item>Why <verbatim|guard> looks this way?

    <hlkwa|let ><hlstd|fail ><hlopt|= []><hlendline|><next-line><hlkwa|let
    ><hlstd|guard p ><hlopt|= ><hlkwa|if ><hlstd|p ><hlkwa|then
    ><hlstd|return ><hlopt|() ><hlkwa|else ><hlstd|fail><hlendline|>

    <\itemize>
      <item>Steps in monadic computation are composed with
      <hlopt|\<gtr\>\<gtr\>=>, e.g. <hlopt|\|-\<gtr\>>

      <\itemize>
        <item>as if <hlopt|;> was replaced by <hlopt|\<gtr\>\<gtr\>=>
      </itemize>

      <item><hlopt|[] \|-\<gtr\> >... does not produce anything -- as needed
      by guarding

      <item><hlopt|[()] \|-\<gtr\> >... <math|\<rightsquigarrow\>>
      <hlopt|(><hlkwa|fun ><hlopt|_ -\<gtr\> >...<hlopt|) ()>
      <math|\<rightsquigarrow\>> ... i.e. keep without change
    </itemize>

    <item>Throwing away the binding argument is a common practice, with infix
    syntax <hlopt|\<gtr\>\<gtr\>> in Haskell, and supported in
    <em|do-notation> and <hlkwa|perform>.

    <item>Everything is a monad?

    <item>Different flavors of monads?

    <item>Can <verbatim|guard> be defined for any monad?

    <new-page*><item><hlkwa|perform> syntax in depth:

    <tabular|<tformat|<table|<row|<cell|<hlkwa|perform
    ><hlstd|exp>>|<cell|<math|\<Longrightarrow\>>>|<cell|<verbatim|exp>>>|<row|<cell|<hlkwa|perform
    ><hlstd|pat ><hlopt|\<less\>-- ><hlstd|exp><hlopt|;>>|<cell|<math|\<Longrightarrow\>>>|<cell|<hlstd|bind
    exp >>>|<row|<cell|<hlstd| \ \ \ \ \ \ \ rest>>|<cell|>|<cell|<hlopt|(><hlkwa|fun
    ><hlstd|pat ><hlopt|-\<gtr\> ><hlkwa|perform
    ><hlstd|rest><hlopt|)>>>|<row|<cell|<hlkwa|perform ><hlstd|exp><hlopt|;
    ><hlstd|rest>>|<cell|<math|\<Longrightarrow\>>>|<cell|<hlstd|bind
    exp>>>|<row|<cell|>|<cell|>|<cell|<hlopt|(><hlkwa|fun
    ><hlstd|<textunderscore> ><hlopt|-\<gtr\> ><hlkwa|perform
    ><hlstd|rest><hlopt|)>>>|<row|<cell|<hlkwa|perform let ><hlopt|...
    ><hlkwa|in ><hlstd|rest>>|<cell|<math|\<Longrightarrow\>>>|<cell|<hlkwa|let
    ><hlopt|... ><hlkwa|in perform ><hlstd|rest>>>|<row|<cell|<hlkwa|perform
    ><hlstd|rpt ><hlopt|\<less\>-- ><hlstd|exp><hlopt|;>>|<cell|<math|\<Longrightarrow\>>>|<cell|<hlstd|bind
    exp>>>|<row|<cell|<hlstd| \ \ \ \ \ \ \ rest>>|<cell|>|<cell|<hlopt|(><hlkwa|function
    >>>|<row|<cell|>|<cell|>|<cell|<hlstd|<hlopt|\|> rpt ><hlopt|-\<gtr\>
    ><hlkwa|perform ><hlstd|rest>>>|<row|<cell|>|<cell|>|<cell|<hlstd|<hlopt|\|>
    <textunderscore> ><hlopt|-\<gtr\>><hlstd|
    failwith>>>|<row|<cell|>|<cell|>|<cell|<hlstr| \ \ \ \ \ \ "pattern
    match"><hlopt|)>>>|<row|<cell|>|<cell|>|<cell|>>|<row|<cell|<hlkwa|perform
    with ><hlstd|b >[<hlkwa|and ><hlstd|f>] <hlkwa|in
    >>|<cell|<math|\<Longrightarrow\>>>|<cell|<hlkwa|perform
    ><hlstd|body>>>|<row|<cell|<hlstd| \ \ \ \ \ \ \ body>>|<cell|>|<cell|but
    uses <verbatim|b> instead of <verbatim|bind>>>|<row|<cell|>|<cell|>|<cell|and
    <verbatim|f> instead of <verbatim|failwith>>>|<row|<cell|>|<cell|>|<cell|during
    translation>>>>>

    <item>It can be useful to redefine: <hlkwa|let ><hlstd|failwith
    <textunderscore> ><hlopt|= ><hlstd|fail> (<em|why?>)
  </itemize>

  <subsection|<new-page*>Monad laws>

  <\itemize>
    <item>A parametric data type is a monad only if its <verbatim|bind> and
    <verbatim|return> operations meet axioms:

    <\eqnarray*>
      <tformat|<table|<row|<cell|bind <around*|(|return a|)>
      f>|<cell|\<approx\>>|<cell|f a>>|<row|<cell|bind a
      <around*|(|\<lambda\>x.return x|)>>|<cell|\<approx\>>|<cell|a>>|<row|<cell|bind
      <around*|(|bind a <around*|(|\<lambda\>x.b|)>|)>
      <around*|(|\<lambda\>y.c|)>>|<cell|\<approx\>>|<cell|bind a
      <around*|(|\<lambda\>x.bind b <around*|(|\<lambda\>y.c|)>|)>>>>>
    </eqnarray*>

    \;

    <item>Check that the laws hold for our example monad

    <hlkwa|let ><hlstd|bind a b ><hlopt|= ><hlstd|concat<textunderscore>map b
    a><hlendline|><next-line><hlkwa|let ><hlstd|return x ><hlopt|=
    [><hlstd|x><hlopt|]><hlstd| \ ><hlendline|>
  </itemize>

  <subsection|<new-page*>Monoid laws and <em|monad-plus>>

  <\itemize>
    <item>A monoid is a type with, at least, two operations

    <\itemize>
      <item><verbatim|mzero : 'a monoid>

      <item><verbatim|mplus : 'a monoid -\<gtr\> 'a monoid -\<gtr\> 'a
      monoid>
    </itemize>

    that meet the laws:

    <\eqnarray*>
      <tformat|<table|<row|<cell|mplus mzero
      a>|<cell|\<approx\>>|<cell|a>>|<row|<cell|mplus a
      mzero>|<cell|\<approx\>>|<cell|a>>|<row|<cell|mplus a <around*|(|mplus
      b c|)>>|<cell|\<approx\>>|<cell|mplus <around*|(|mplus a b|)> c>>>>
    </eqnarray*>

    <item>We will define <verbatim|fail> as synonym for <verbatim|mzero> and
    infix <hlopt|++> for <verbatim|mplus>.

    <item>Fusing monads and monoids gives the most popular general flavor of
    monads which we call <em|monad-plus> after Haskell.

    <new-page*><item>Monad-plus requires additional axioms that relate its
    ``addition'' and its ``multiplication''.

    <\eqnarray*>
      <tformat|<table|<row|<cell|bind mzero
      f>|<cell|\<approx\>>|<cell|mzero>>|<row|<cell|bind m
      <around*|(|\<lambda\>x.mzero|)>>|<cell|\<approx\>>|<cell|mzero>>>>
    </eqnarray*>

    <item>Using infix notation with <math|\<oplus\>> as <verbatim|mplus>,
    <math|\<b-0\>> as <verbatim|mzero>, <math|\<vartriangleright\>> as
    <verbatim|bind> and \ <math|\<b-1\>> as <verbatim|return>, we get
    monad-plus axioms

    <\eqnarray*>
      <tformat|<table|<row|<cell|\<b-0\>\<oplus\>a>|<cell|\<approx\>>|<cell|a>>|<row|<cell|a\<oplus\>\<b-0\>>|<cell|\<approx\>>|<cell|a>>|<row|<cell|a\<oplus\><around*|(|b\<oplus\>c|)>>|<cell|\<approx\>>|<cell|<around*|(|a\<oplus\>b|)>\<oplus\>c>>|<row|<cell|\<b-1\>
      x\<vartriangleright\>f>|<cell|\<approx\>>|<cell|f
      x>>|<row|<cell|a\<vartriangleright\>\<lambda\>x.\<b-1\>
      x>|<cell|\<approx\>>|<cell|a>>|<row|<cell|<around*|(|a\<vartriangleright\>\<lambda\>x.b|)>\<vartriangleright\>\<lambda\>y.c>|<cell|\<approx\>>|<cell|a\<vartriangleright\><around*|(|\<lambda\>x.b\<vartriangleright\>\<lambda\>y.c|)>>>|<row|<cell|\<b-0\>\<vartriangleright\>f>|<cell|\<approx\>>|<cell|\<b-0\>>>|<row|<cell|a\<vartriangleright\><around*|(|\<lambda\>x.\<b-0\>|)>>|<cell|\<approx\>>|<cell|\<b-0\>>>>>
    </eqnarray*>

    <new-page*><item>The list type has a natural monad and monoid structure

    <hlkwa| \ let ><hlstd|mzero ><hlopt|= []><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|mplus ><hlopt|=
    (><hlstd|@><hlopt|)><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|bind a b ><hlopt|= ><hlstd|concat<textunderscore>map b
    a<hlendline|><next-line> \ ><hlkwa|let ><hlstd|return a ><hlopt|=
    [><hlstd|a><hlopt|]><hlendline|>

    <item>We can define in any monad-plus

    <hlstd| \ ><hlkwa|let ><hlstd|fail ><hlopt|=
    ><hlstd|mzero<hlendline|><next-line> \ ><hlkwa|let ><hlstd|failwith
    <textunderscore> ><hlopt|= ><hlstd|fail<hlendline|><next-line>
    \ ><hlkwa|let ><hlopt|(++) = ><hlstd|mplus<hlendline|><next-line>
    \ ><hlkwa|let ><hlopt|(\<gtr\>\<gtr\>=) ><hlstd|a b ><hlopt|=
    ><hlstd|bind a b<hlendline|><next-line> \ ><hlkwa|let ><hlstd|guard p
    ><hlopt|= ><hlkwa|if ><hlstd|p ><hlkwa|then ><hlstd|return ><hlopt|()
    ><hlkwa|else ><hlstd|fail><hlendline|>
  </itemize>

  <subsection|<new-page*>Backtracking: computation with choice>

  We have seen <verbatim|mzero>, i.e. <verbatim|fail> in the countdown
  problem. What about <verbatim|mplus>?

  <hlkwa|let ><hlstd|find<textunderscore>to<textunderscore>eat n
  island<textunderscore>size num<textunderscore>islands
  empty<textunderscore>cells ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|honey ><hlopt|= ><hlstd|honey<textunderscore>cells n
  empty<textunderscore>cells ><hlkwa|in><hlendline|><next-line><hlstd|<hlendline|><next-line>
  \ ><hlkwa|let rec ><hlstd|find<textunderscore>board s
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlcom|(* Printf.printf
  "find<textunderscore>board: %s<math|>n" (state<textunderscore>str s);
  *)><hlstd|<hlendline|><next-line> \ \ \ ><hlkwa|match
  ><hlstd|visit<textunderscore>cell s ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|None ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|perform><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ guard ><hlopt|(><hlstd|s><hlopt|.><hlstd|been<textunderscore>islands
  ><hlopt|= ><hlstd|num<textunderscore>islands><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ return s><hlopt|.><hlstd|eaten<hlendline|><next-line>
  \ \ \ ><hlopt|\| ><hlkwd|Some ><hlopt|(><hlstd|cell><hlopt|,
  ><hlstd|s><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ s
  ><hlopt|\<less\>-- ><hlstd|find<textunderscore>island cell
  ><hlopt|(><hlstd|fresh<textunderscore>island
  s><hlopt|);><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ guard
  ><hlopt|(><hlstd|s><hlopt|.><hlstd|been<textunderscore>size ><hlopt|=
  ><hlstd|island<textunderscore>size><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ find<textunderscore>board s<hlendline|><next-line><new-page*>
  \ ><hlkwa|and ><hlstd|find<textunderscore>island current s
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|s
  ><hlopt|= ><hlstd|keep<textunderscore>cell current s
  ><hlkwa|in><hlstd|<hlendline|><next-line> \ \ \ neighbors n
  empty<textunderscore>cells current<hlendline|><next-line>
  \ \ \ <hlopt|\|>><hlopt|\<gtr\> ><hlstd|foldM<hlendline|><next-line>
  \ \ \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|neighbor s
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlkwa|if ><hlkwc|CellSet><hlopt|.><hlstd|mem neighbor
  s><hlopt|.><hlstd|visited ><hlkwa|then ><hlstd|return
  s<hlendline|><next-line> \ \ \ \ \ \ \ \ \ ><hlkwa|else><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|let ><hlstd|choose<textunderscore>eat
  ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|if ><hlstd|s><hlopt|.><hlstd|more<textunderscore>to<textunderscore>eat
  ><hlopt|\<less\>= ><hlnum|0 ><hlkwa|then
  ><hlstd|fail<hlendline|><next-line> \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|else
  ><hlstd|return ><hlopt|(><hlstd|eat<textunderscore>cell neighbor
  s><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|and
  ><hlstd|choose<textunderscore>keep ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|if ><hlstd|s><hlopt|.><hlstd|been<textunderscore>size
  ><hlopt|\<gtr\>= ><hlstd|island<textunderscore>size ><hlkwa|then
  ><hlstd|fail<hlendline|><next-line> \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|else
  ><hlstd|find<textunderscore>island neighbor s
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ <with|font-base-size|14|mplus>
  choose<textunderscore>eat choose<textunderscore>keep><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ s ><hlkwa|in><hlendline|><next-line><hlstd|
  \ <hlendline|><next-line> \ ><hlkwa|let
  ><hlstd|cells<textunderscore>to<textunderscore>eat
  ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|List><hlopt|.><hlstd|length honey ><hlopt|-
  ><hlstd|island<textunderscore>size ><hlopt|*
  ><hlstd|num<textunderscore>islands ><hlkwa|in><hlendline|><next-line><hlstd|
  \ find<textunderscore>board ><hlopt|(><hlstd|init<textunderscore>state
  honey cells<textunderscore>to<textunderscore>eat><hlopt|)>

  <section|<new-page*>Monad ``flavors''>

  <\itemize>
    <item>Monads ``wrap around'' a type, but some monads need an additional
    type parameter.

    <\itemize>
      <item>Usually the additional type does not change while within a monad
      -- we will therefore stick to <verbatim|'a monad> rather than
      parameterize with an additional type <verbatim|('s, 'a) monad>.
    </itemize>

    <item>As monad-plus shows, things get interesting when we add more
    operations to a basic monad (with <verbatim|bind> and <verbatim|return>).

    <\itemize>
      <item>Monads with access:

      <hlstd|access ><hlopt|: ><hlstd|'a><hlstd| monad ><hlopt|-\<gtr\>
      ><hlstd|'a><hlendline|>

      Example: the lazy monad.

      <item>Monad-plus, non-deterministic computation:

      <verbatim|mzero <hlopt|: ><hlstd|'a><hlopt|
      >monad><next-line><verbatim|mplus <hlopt|: ><hlstd|'a> monad -\<gtr\>
      <hlstd|'a> monad -\<gtr\> <hlstd|'a><hlopt| >monad>

      <new-page*><item>Monads with environment or state -- parameterized by
      type <verbatim|store>:

      <hlstd|get ><hlopt|: ><hlstd|store monad<hlendline|><next-line>put
      ><hlopt|: ><hlstd|store ><hlopt|-\<gtr\> ><hlkwb|unit><hlstd|
      monad><hlendline|>

      There is a ``canonical'' state monad. Similar monads: the writer monad
      (with <verbatim|get> called <verbatim|listen> and <verbatim|put> called
      <verbatim|tell>); the reader monad, without <verbatim|put>, but with
      <verbatim|get> (called <verbatim|ask>) and <verbatim|local>:

      <hlstd|local ><hlopt|: (><hlstd|store ><hlopt|-\<gtr\>
      ><hlstd|store><hlopt|) -\<gtr\> ><hlstd|'a ><hlstd|monad
      ><hlopt|-\<gtr\> ><hlstd|'a><hlstd| monad><hlendline|>

      <item>The exception / error monads -- parameterized by type
      <verbatim|excn>:

      <hlstd|throw ><hlopt|: ><hlstd|excn ><hlopt|-\<gtr\> ><hlstd|'a
      ><hlstd|monad<hlendline|><next-line><hlkwa|><hlstd|catch ><hlopt|:
      ><hlstd|'a monad ><hlopt|-\<gtr\> (><hlstd|excn ><hlopt|-\<gtr\>
      ><hlstd|'a monad><hlopt|) -\<gtr\> ><hlstd|'a monad><hlendline|>>

      <item>The continuation monad:

      <hlstd|callCC ><hlopt|: ((><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b
      monad><hlopt|) -\<gtr\> ><hlstd|'a monad><hlopt|) -\<gtr\> ><hlstd|'a
      monad><hlendline|>

      We will not cover it.

      <new-page*><item>Probabilistic computation:

      <hlstd|choose ><hlopt|: ><hlkwb|float ><hlopt|-\<gtr\> ><hlstd|'a monad
      ><hlopt|-\<gtr\> ><hlstd|'a monad ><hlopt|-\<gtr\> ><hlstd|'a monad>

      satisfying the laws with <math|a\<oplus\><rsub|p>b> for
      <verbatim|choose p a b> and <math|p*q> for <verbatim|p*.q>,
      <math|0\<leqslant\>p,q\<leqslant\>1>:

      <\eqnarray*>
        <tformat|<table|<row|<cell|a\<oplus\><rsub|0>b>|<cell|\<approx\>>|<cell|b>>|<row|<cell|a\<oplus\><rsub|p>b>|<cell|\<approx\>>|<cell|b\<oplus\><rsub|1-p>a>>|<row|<cell|a\<oplus\><rsub|p><around*|(|b\<oplus\><rsub|q>c|)>>|<cell|\<approx\>>|<cell|<around*|(|a\<oplus\><rsub|<frac|p|p+q-p*q>>b|)>\<oplus\><rsub|p+q-p*q>c>>|<row|<cell|a\<oplus\><rsub|p>a>|<cell|\<approx\>>|<cell|a>>>>
      </eqnarray*>

      <item>Parallel computation as monad with access and parallel bind:

      <hlstd|parallel ><hlopt|:><hlendline|><next-line><hlstd|'a
      monad><hlopt|-\<gtr\> ><hlstd|'b monad><hlopt|-\<gtr\> (><hlstd|'a
      ><hlopt|-\<gtr\> ><hlstd|'b ><hlopt|-\<gtr\> ><hlstd|'c monad><hlopt|)
      -\<gtr\> ><hlstd|'c monad>

      Example: lightweight threads.
    </itemize>
  </itemize>

  <section|<new-page*>Interlude: the module system>

  <\itemize>
    <item>I provide below much more information about the module system than
    we need, just for completeness. You can use it as reference.

    <\itemize>
      <item>Module system details will <strong|not> be on the exam -- only
      the structure / signature definitions as discussed in lecture 5.
    </itemize>

    <item>Modules collect related type definitions and operations together.

    <item>Module ``values'' are introduced with <hlkwa|struct >...<hlkwa|
    end> -- structures.

    <item>Module types are introduced with <hlkwa|sig >...<hlkwa| end> --
    signatures.

    <\itemize>
      <item>A structure is a package of definitions, a signature is an
      interface for packages.
    </itemize>

    <item>A source file <verbatim|source.ml> or <verbatim|Source.ml> defines
    a module <hlkwd|Source>.

    A source file <verbatim|source.mli> or <verbatim|Source.mli> defines its
    type.

    <item>We can create the initial interface by entering the module in the
    interactive toplevel or by command <verbatim|ocamlc -i source.ml>

    <new-page*><item>In the ``toplevel'' -- accurately, module level --
    modules are defined with <hlkwa|module ><hlkwd|ModuleName ><hlopt|=> ...
    or <hlkwa|module ><hlkwd|ModuleName ><hlopt|: ><hlkwd|MODULE_TYPE><hlopt|
    => ... syntax, and module types with <hlkwa|module type
    ><hlkwd|MODULE<textunderscore>TYPE ><hlopt|=> ... syntax.

    <\itemize>
      <item>Corresponds to <hlkwa|let><verbatim| v_name ><hlopt|=> ... resp.
      <hlkwa|let><verbatim| v_name ><hlopt|:><hlstd| v_type ><hlopt|=> ...
      syntax for values and <hlkwa|type ><hlstd|v<textunderscore>type
      ><hlopt|=> ... syntax for types.
    </itemize>

    <item>Locally in expressions, modules are defined with <hlkwa|let module
    ><hlkwd|M ><hlopt|= >...<hlkwa| in> ... syntax.

    <\itemize>
      <item>Corresponds to <hlkwa|let><verbatim| v_name ><hlopt|= >...<hlkwa|
      in >... syntax for values.
    </itemize>

    <item>The content of a module is made visible in the remainder of another
    module by <hlkwa|open ><hlkwd|Module>

    <\itemize>
      <item>Module <hlkwd|Pervasives> is initially visible, as if each file
      started with <hlkwa|open><hlkwd| Pervasives>.
    </itemize>

    <item>The content of a module is made visible locally in an expression
    with <hlkwa|let <no-break>open ><hlkwd|Module ><hlkwa|in >... syntax.

    <item>Content of a module is included into another module -- i.e. made
    part of it -- by <hlkwa|include ><hlkwd|Module>.

    <\itemize>
      <item>Just having <hlkwa|open ><hlkwd|Module> inside <hlkwd|Parent>
      does not affect how <hlkwd|Parent> looks from outside.
    </itemize>

    <item>Module functions -- functions from modules to modules -- are called
    <em|func<no-break>tors> <small|(not the Haskell ones!)>. The type of the
    parameter has to be given.

    <hlkwa|module ><hlkwd|Funct ><hlopt|= ><hlkwa|functor
    ><hlopt|(><hlkwd|Arg ><hlopt|: ><hlkwa|sig >...<hlkwa| end><hlopt|)
    -\<gtr\> ><hlkwa|struct >...<hlkwa| end>

    <hlkwa|module ><hlkwd|Funct ><hlopt|(><hlkwd|Arg ><hlopt|: ><hlkwa|sig
    >...<hlkwa| end><hlopt|) = ><hlkwa|struct >...<hlkwa| end>

    <\itemize>
      <item>Functors can return functors, i.e. modules can be parameterized
      by multiple modules.

      <item>Modules are either structures or functors.

      <item>Different kind of thing than Haskell functors.
    </itemize>

    <item>Functor application always uses parentheses: <hlkwd|Funct
    ><hlopt|(><hlkwa|struct ><hlopt|... ><hlkwa|end><hlopt|)>

    <item>We can use named module type instead of signature and named module
    instead of structure above.

    <item>Argument structures can contain more definitions than required.

    <new-page*><item>A signature <hlkwd|MODULE<textunderscore>TYPE
    ><hlkwa|with type ><hlstd|t_name><hlopt| => ... is like
    <hlkwd|MODULE<textunderscore>TYPE >but with <verbatim|t_name> made more
    specific.

    <item>We can also include signatures into other signatures, by
    <hlkwa|include ><hlkwd|MODULE<textunderscore>TYPE>.

    <\itemize>
      <item><hlkwa|include ><hlkwd|MODULE<textunderscore>TYPE ><hlkwa|with
      type ><hlstd|t<textunderscore>name ><hlopt|:= >... will substitute type
      <verbatim|t_name> with provided type.
    </itemize>

    <item>Modules, just as expressions, are <strong|not> recursive or
    mutually recursive by default. Syntax for recursive
    modules:<next-line><hlkwa|module rec ><hlkwd|ModuleName ><hlopt|:
    ><hlkwd|MODULE<textunderscore>TYPE ><hlopt|= >...<hlkwa| and >...

    <item>We can recover the type -- i.e. signature -- of a module
    by<next-line><hlkwa|module type of ><hlkwd|Module>

    <new-page*><item>Finally, we can pass around modules in normal functions.

    <\itemize>
      <item><hlopt|(><hlkwa|module ><hlkwd|Module><hlopt|)> is an expression

      <item><hlopt|(><hlkwa|val ><hlstd|module<textunderscore>v><hlopt|)> is
      a module

      <item># <hlkwa|module type ><hlkwd|T ><hlopt|= ><hlkwa|sig val
      ><hlstd|g ><hlopt|: ><hlkwb|int ><hlopt|-\<gtr\> ><hlkwb|int
      ><hlkwa|end><hlendline|><next-line><hlkwa|let ><hlstd|f
      mod<textunderscore>v x ><hlopt|=><hlendline|><next-line><hlstd|
      \ ><hlkwa|let module ><hlkwd|M ><hlopt|= (><hlkwa|val
      ><hlstd|mod<textunderscore>v ><hlopt|: ><hlkwd|T><hlopt|)
      ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwc|M><hlopt|.><hlstd|g
      x><hlopt|;;><hlendline|>

      <hlkwa|val ><hlstd|f ><hlopt|: (><hlkwa|module ><hlkwd|T><hlopt|)
      -\<gtr\> ><hlkwb|int ><hlopt|-\<gtr\> ><hlkwb|int ><hlopt|=
      \<less\>><hlkwa|fun><hlopt|\<gtr\>><hlendline|>

      # <hlkwa|let ><hlstd|test ><hlopt|= ><hlstd|f ><hlopt|(><hlkwa|module
      struct let ><hlstd|g i ><hlopt|= ><hlstd|i><hlopt|*><hlstd|i
      ><hlkwa|end ><hlopt|: ><hlkwd|T><hlopt|);;><hlendline|>

      <hlkwa|val ><hlstd|test ><hlopt|: ><hlkwb|int ><hlopt|-\<gtr\>
      ><hlkwb|int ><hlopt|= \<less\>><hlkwa|fun><hlopt|\<gtr\>><hlendline|>
    </itemize>
  </itemize>

  <section|<new-page*>The two metaphors>

  <\itemize>
    <item>Monads can be seen as <strong|containers>: <verbatim|'a monad>
    contains stuff of type <verbatim|'a>

    <item>and as <strong|computation>: <verbatim|'a monad> is a special way
    to compute <verbatim|'a>.

    <\itemize>
      <item>A monad fixes the sequence of computing steps -- unless it is a
      fancy monad like parallel computation monad.
    </itemize>
  </itemize>

  <subsection|<new-page*>Monads as containers>

  <\itemize>
    <item>A monad is a <em|quarantine container>:

    <\itemize>
      <item>we can put something into the container with <verbatim|return>

      <item>we can operate on it, but the result needs to stay in the
      container

      <hlstd| \ ><hlkwa|let ><hlstd|lift f m ><hlopt|= ><hlkwa|perform
      ><hlstd|x ><hlopt|\<less\>-- ><hlstd|m><hlopt|; ><hlstd|return
      ><hlopt|(><hlstd|f x><hlopt|)><hlendline|><next-line><hlkwa| \ val
      ><hlstd|lift ><hlopt|: (><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b><hlopt|)
      -\<gtr\> ><hlstd|'a><hlopt| ><hlstd|monad ><hlopt|-\<gtr\>
      ><hlstd|'b><hlstd| monad>

      <item>We can deactivate-unwrap the quarantine container but only when
      it is in another container so the quarantine is not broken

      <hlstd| \ ><hlkwa|let ><hlstd|join m ><hlopt|= ><hlkwa|perform
      ><hlstd|x ><hlopt|\<less\>-- ><hlstd|m><hlopt|;
      ><hlstd|x><hlendline|><next-line><hlstd| ><hlkwa| val ><hlstd|join
      ><hlopt|: (><hlstd|'a><hlopt| ><hlstd|monad><hlopt|) ><hlstd|monad
      ><hlopt|-\<gtr\> ><hlstd|'a><hlstd| monad>
    </itemize>

    <item>The quarantine container for a <strong|monad-plus> is more like
    other containers: it can be empty, or contain multiple elements.

    <item>Monads with access allow us to extract the resulting element from
    the container, other monads provide a <verbatim|run> operation that
    exposes ``what really happened behind the quarantine''.
  </itemize>

  <subsection|<new-page*>Monads as computation>

  <\itemize>
    <item>To compute the result, <hlkwa|perform> instructions, naming partial
    results.

    <item>Physical metaphor: <strong|assembly line>

    <draw-over|<tabular|<tformat|<cwith|4|4|3|3|cell-halign|c>|<cwith|4|4|1|1|cell-halign|r>|<table|<row|<cell|>|<cell|<block|<tformat|<table|<row|<cell|Combiner>>|<row|<cell|<verbatim|bind>>>>>>>|<cell|>|<cell|>>|<row|<cell|<block|<tformat|<table|<row|<cell|Worker>>|<row|<cell|<verbatim|makeChopsticks>>>>>>>|<cell|>|<cell|<block|<tformat|<table|<row|<cell|Worker>>|<row|<cell|<verbatim|polishChopsticks>>>>>>>|<cell|>>|<row|<cell|>|<cell|<block|<tformat|<table|<row|<cell|Combiner>>|<row|<cell|<verbatim|bind>>>>>>>|<cell|>|<cell|<block|<tformat|<table|<row|<cell|Combiner>>|<row|<cell|<verbatim|bind>>>>>>>>|<row|<cell|<block|<tformat|<table|<row|<cell|Loader>>|<row|<cell|<verbatim|return>>>>>>>|<cell|>|<cell|<block|<tformat|<table|<row|<cell|Worker>>|<row|<cell|<verbatim|wrapChopsticks>>>>>>>|<cell|>>>>>|<with|gr-mode|<tuple|edit|line>|gr-arrow-end|\<gtr\>|gr-color|dark
    green|<graphics|<with|line-width|2ln|<line|<point|-5.76293|3.7055>|<point|6.06932133880143|3.72666688715439>>>|<with|line-width|2ln|<line|<point|-5.7206|1.99099>|<point|6.21748908585792|1.99098756449266>>>|<with|line-width|2ln|<arc|<point|6.06932|3.72667>|<point|8.92684217489086|2.77415994179124>|<point|10.0486836883186|-0.104527715306257>>>|<with|line-width|2ln|<arc|<point|6.21749|1.99099>|<point|6.38682365392248|1.73698571239582>|<point|6.76782643206773|-0.0833608942981876>>>|<with|line-width|2ln|<line|<point|6.76783|-0.0833609>|<point|-5.29726154253208|-0.104527715306257>>>|<with|line-width|2ln|<line|<point|6.72549|-1.84021>|<point|-5.19142743749173|-1.81904021695992>>>|<with|color|dark
    green|arrow-end|\<gtr\>\<gtr\>|line-width|2ln|<line|<point|0.671782|2.87999>|<point|2.301627199365|2.87999404683159>>>|<with|color|dark
    green|arrow-end|\<gtr\>\<gtr\>|line-width|2ln|<line|<point|7.72033|1.86399>|<point|8.1225029765842|0.720978304008467>>>|<with|color|dark
    green|arrow-end|\<gtr\>\<gtr\>|line-width|2ln|<line|<point|6.00582|-0.972367>|<point|4.69347797327689|-0.972367376637121>>>|<with|color|dark
    green|arrow-end|\<gtr\>\<gtr\>|line-width|2ln|<line|<point|2.06879|-0.908867>|<point|0.735282444767826|-0.908866913612912>>>|<with|color|dark
    green|arrow-end|\<gtr\>\<gtr\>|line-width|2ln|<line|<point|-5.76293|2.87999>|<point|-4.61992327027385|2.87999404683159>>>|<with|color|dark
    green|arrow-end|\<gtr\>\<gtr\>|line-width|2ln|<line|<point|-4.42942|-0.930034>|<point|-5.53009657362085|-0.930033734620982>>>|<with|color|dark
    green|arrow-end|\<gtr\>|<arc|<point|-9.76346|2.68949>|<point|-8.32411694668607|2.26615623759757>|<point|-7.30810953829872|0.974980156105305>>>|<with|color|dark
    green|arrow-end|\<gtr\>|<arc|<point|2.28046|2.37199>|<point|3.17510086006645|1.99098818517481>|<point|3.65630374388147|0.974980156105305>>>|<with|color|dark
    green|arrow-end|\<gtr\>|<arc|<point|3.88914|-1.28987>|<point|3.31763460775235|-2.26354345812938>|<point|3.29646778674428|-2.83504762534727>>>|<with|color|dark
    green|arrow-end|\<gtr\>|<arc|<point|-4.26009|-1.18404>|<point|-4.64394551581309|-1.82001279007382>|<point|-4.72575737531419|-2.72921352030692>>>|<text-at|<verbatim|w>|<point|-7.4274|1.25543>>|<text-at|<verbatim|c>|<point|3.59673|1.32033>>|<text-at|<verbatim|c'>|<point|3.5293|-2.47521>>|<text-at|<verbatim|c''>|<point|-4.93743|-1.58621>>|<with|color|dark
    green|arrow-end|\<gtr\>|<line|<point|6.28099|0.91148>|<point|6.76783|-0.0833609>>>|<with|color|dark
    green|arrow-end|\<gtr\>|<line|<point|-4.40826|0.91148>|<point|-3.91697154319691|1.99098963203907>>>|<with|color|dark
    green|arrow-end|\<gtr\>|<line|<point|0.206112|-2.89855>|<point|-0.600035853371303|-1.82719658492988>>>>>>

    <hlkwa|let ><hlstd|assemblyLine w ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ \ c
    ><hlopt|\<less\>-- ><hlstd|makeChopsticks w<hlendline|><next-line>
    \ \ \ \ c' ><hlopt|\<less\>-- ><hlstd|polishChopsticks
    c<hlendline|><next-line> \ \ \ \ c'' ><hlopt|\<less\>--
    ><hlstd|wrapChopsticks c'<hlendline|><next-line> \ \ \ \ return
    c''><hlendline|>

    <item>Any expression can be spread over a monad, e.g. for
    <math|\<lambda\>>-terms:

    <\eqnarray*>
      <tformat|<cwith|1|1|3|3|cell-halign|l>|<cwith|2|2|2|2|cell-halign|l>|<cwith|1|1|2|2|cell-halign|l>|<cwith|4|4|2|2|cell-halign|l>|<cwith|5|5|2|2|cell-halign|l>|<cwith|3|3|2|2|cell-halign|l>|<table|<row|<cell|<around*|\<llbracket\>|N|\<rrbracket\>>=>|<cell|return
      N>|<cell|<with|mode|text|(constant)>>>|<row|<cell|<around*|\<llbracket\>|x|\<rrbracket\>>=>|<cell|return
      x>|<cell|<with|mode|text|(variable)>>>|<row|<cell|<around*|\<llbracket\>|\<lambda\>x.a|\<rrbracket\>>=>|<cell|return<around*|(|\<lambda\>x.<around*|\<llbracket\>|a|\<rrbracket\>>|)>>|<cell|<with|mode|text|(function)>>>|<row|<cell|<around*|\<llbracket\>|let
      x=a in b|\<rrbracket\>>=>|<cell|bind
      <around*|\<llbracket\>|a|\<rrbracket\>>
      <around*|(|\<lambda\>x.<around*|\<llbracket\>|b|\<rrbracket\>>|)>>|<cell|<with|mode|text|(local
      definition)>>>|<row|<cell|<around*|\<llbracket\>|a
      b|\<rrbracket\>>=>|<cell|bind <around*|\<llbracket\>|a|\<rrbracket\>>
      <around*|(|\<lambda\>v<rsub|a>.bind
      <around*|\<llbracket\>|b|\<rrbracket\>>
      <around*|(|\<lambda\>v<rsub|b>.v<rsub|a>
      v<rsub|b>|)>|)>>|<cell|<with|mode|text|(application)>>>>>
    </eqnarray*>

    <item>When an expression is spread over a monad, its computation can be
    monitored or affected without modifying the expression.
  </itemize>

  \;

  <section|<new-page*>Monad classes>

  <\itemize>
    <item>To implement a monad we need to provide the implementation type,
    <verbatim|return> and <verbatim|bind> operations.

    <hlkwa|module type ><hlkwd|MONAD ><hlopt|=
    ><hlkwa|sig><hlendline|><next-line><hlstd| \ ><hlkwa|type ><hlstd|'a
    t<hlendline|><next-line> \ ><hlkwa|val ><hlstd|return ><hlopt|:
    ><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'a t<hlendline|><next-line>
    \ ><hlkwa|val ><hlstd|bind ><hlopt|: ><hlstd|'a t ><hlopt|-\<gtr\>
    (><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b t><hlopt|) -\<gtr\> ><hlstd|'b
    t><hlendline|><next-line><hlkwa|end><hlendline|>

    <\itemize>
      <item>Alternatively we could start from <verbatim|return>,
      <verbatim|lift> and <verbatim|join> operations.

      <\small>
        <item>For monads that change their additional type parameter we could
        define:

        <hlkwa|module type ><hlkwd|MONAD ><hlopt|=
        ><hlkwa|sig><hlendline|><next-line><hlstd| \ ><hlkwa|type
        ><hlopt|(><hlstd|'s><hlopt|, ><hlstd|'a><hlopt|)
        ><hlstd|t<hlendline|><next-line> \ ><hlkwa|val ><hlstd|return
        ><hlopt|: ><hlstd|'a ><hlopt|-\<gtr\> (><hlstd|'s><hlopt|,
        ><hlstd|'a><hlopt|) ><hlstd|t<hlendline|><next-line> \ ><hlkwa|val
        ><hlstd|bind ><hlopt|:><hlendline|><next-line><hlstd|
        \ \ \ ><hlopt|(><hlstd|'s><hlopt|, ><hlstd|'a><hlopt|) ><hlstd|t
        ><hlopt|-\<gtr\> (><hlstd|'a ><hlopt|-\<gtr\> (><hlstd|'s><hlopt|,
        ><hlstd|'b><hlopt|) ><hlstd|t><hlopt|) -\<gtr\> (><hlstd|'s><hlopt|,
        ><hlstd|'b><hlopt|) ><hlstd|t><hlendline|><next-line><hlkwa|end><hlendline|>
      </small>

      \;
    </itemize>

    <new-page*><item>Based on just these two operations, we can define a
    whole suite of general-purpose functions. We look at just a tiny
    selection.

    <hlkwa|module type ><hlkwd|MONAD<textunderscore>OPS ><hlopt|=
    ><hlkwa|sig><hlendline|><next-line><hlstd| \ ><hlkwa|type ><hlstd|'a
    monad<hlendline|><next-line> \ ><hlkwa|include ><hlkwd|MONAD ><hlkwa|with
    type ><hlstd|'a t ><hlopt|:= ><hlstd|'a monad<hlendline|><next-line>
    \ ><hlkwa|val ><hlopt|( \<gtr\>\<gtr\>= ) :><hlstd|'a monad
    ><hlopt|-\<gtr\> (><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b monad><hlopt|)
    -\<gtr\> ><hlstd|'b monad<hlendline|><next-line> \ ><hlkwa|val
    ><hlstd|foldM ><hlopt|:><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|(><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b ><hlopt|-\<gtr\>
    ><hlstd|'a monad><hlopt|) -\<gtr\> ><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b
    list ><hlopt|-\<gtr\> ><hlstd|'a monad<hlendline|><next-line>
    \ ><hlkwa|val ><hlstd|whenM ><hlopt|: ><hlkwb|bool ><hlopt|-\<gtr\>
    ><hlkwb|unit ><hlstd|monad ><hlopt|-\<gtr\> ><hlkwb|unit
    ><hlstd|monad<hlendline|><next-line> \ ><hlkwa|val ><hlstd|lift ><hlopt|:
    (><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b><hlopt|) -\<gtr\> ><hlstd|'a
    monad ><hlopt|-\<gtr\> ><verbatim|'b monad><hlendline|><next-line><hlstd|
    \ ><hlkwa|val ><hlopt|(\<gtr\>\<gtr\>><hlstd|<hlopt|\|>><hlopt|) :
    ><hlstd|'a monad ><hlopt|-\<gtr\> (><hlstd|'a ><hlopt|-\<gtr\>
    ><hlstd|'b><hlopt|) -\<gtr\> ><hlstd|'b
    monad><hlendline|><next-line><verbatim| \ ><hlkwa|val ><hlstd|join
    ><hlopt|: ><hlstd|'a monad monad ><hlopt|-\<gtr\> ><hlstd|'a
    monad<hlendline|><next-line> \ ><hlkwa|val ><hlopt|( \<gtr\>=\<gtr\> )
    :><hlendline|><next-line><hlstd| \ \ \ ><hlopt|(><hlstd|'a
    ><hlopt|-\<gtr\>><hlstd|'b monad><hlopt|) -\<gtr\> (><hlstd|'b
    ><hlopt|-\<gtr\>><hlstd|'c monad><hlopt|) -\<gtr\> ><hlstd|'a
    ><hlopt|-\<gtr\> ><hlstd|'c monad><hlendline|><next-line><hlkwa|end><hlendline|><next-line>

    <new-page*><item>Given a particular implementation, we define these
    functions.

    <hlkwa|module ><hlkwd|MonadOps ><hlopt|(><hlkwd|M ><hlopt|:
    ><hlkwd|MONAD><hlopt|) = ><hlkwa|struct><hlendline|><next-line><hlstd|
    \ ><hlkwa|open ><hlkwd|M><hlendline|><next-line><hlstd| \ ><hlkwa|type
    ><hlstd|'a><hlstd| monad ><hlopt|= ><hlstd|'a><hlstd|
    t<hlendline|><next-line> \ ><hlkwa|let ><hlstd|run x ><hlopt|=
    ><hlstd|x<hlendline|><next-line> \ ><hlkwa|let ><hlopt|(\<gtr\>\<gtr\>=)
    ><hlstd|a b ><hlopt|= ><hlstd|bind a b<hlendline|><next-line>
    \ ><hlkwa|let rec ><hlstd|foldM f a ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| []
    -\<gtr\> ><hlstd|return a<hlendline|><next-line> \ \ \ <hlopt|\|>
    x><hlopt|::><hlstd|xs ><hlopt|-\<gtr\> ><hlstd|f a x
    ><hlopt|\<gtr\>\<gtr\>= ><hlkwa|fun ><hlstd|a' ><hlopt|-\<gtr\>
    ><hlstd|foldM f a' xs<hlendline|><next-line> \ ><hlkwa|let ><hlstd|whenM
    p s ><hlopt|= ><hlkwa|if ><hlstd|p ><hlkwa|then ><hlstd|s ><hlkwa|else
    ><hlstd|return ><hlopt|()><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|lift f m ><hlopt|= ><hlkwa|perform ><hlstd|x ><hlopt|\<less\>--
    ><hlstd|m><hlopt|; ><hlstd|return ><hlopt|(><hlstd|f
    x><hlopt|)><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlopt|(\<gtr\>\<gtr\>><hlstd|<hlopt|\|>><hlopt|) ><hlstd|a b ><hlopt|=
    ><hlstd|lift b a><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|join m ><hlopt|= ><hlkwa|perform ><hlstd|x ><hlopt|\<less\>--
    ><hlstd|m><hlopt|; ><hlstd|x<hlendline|><next-line> \ ><hlkwa|let
    ><hlopt|(\<gtr\>=\<gtr\>) ><hlstd|f g ><hlopt|= ><hlkwa|fun ><hlstd|x
    ><hlopt|-\<gtr\> ><hlstd|f x ><hlopt|\<gtr\>\<gtr\>=
    ><hlstd|g><hlendline|><next-line><hlkwa|end><hlendline|>

    <new-page*><item>We make the monad ``safe'' by keeping its type abstract.
    But <verbatim|run> exposes ``what really happened''.

    <hlkwa|module ><hlkwd|Monad ><hlopt|(><hlkwd|M ><hlopt|:
    ><hlkwd|MONAD><hlopt|) :><hlendline|><next-line><hlkwa|sig><hlendline|><next-line><hlstd|
    \ ><hlkwa|include ><hlkwd|MONAD<textunderscore>OPS><hlendline|><next-line><hlstd|
    \ ><hlkwa|val ><hlstd|run ><hlopt|: ><hlstd|'a><hlstd| monad
    ><hlopt|-\<gtr\> ><hlstd|'a><hlkwc| M><hlopt|.><hlstd|t><hlendline|><next-line><hlkwa|end
    ><hlopt|= ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|M><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|MonadOps><hlopt|(><hlkwd|M><hlopt|)><hlendline|><next-line><hlkwa|end><hlendline|>

    <\itemize>
      <item>Our <verbatim|run> function does not do anything at all. Often
      more useful functions are called <verbatim|run> but then they need to
      be defined for each implementation separately. Our <verbatim|access>
      operation (see section on monad flavors) is often called
      <verbatim|run>.
    </itemize>

    <new-page*><item>The monad-plus class of monads has a lot of
    implementations. They need to provide <verbatim|mzero> and
    <verbatim|mplus>.

    <hlkwa|module type ><hlkwd|MONAD<textunderscore>PLUS ><hlopt|=
    ><hlkwa|sig><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|MONAD><hlendline|><next-line><hlstd| \ ><hlkwa|val ><hlstd|mzero
    ><hlopt|: ><hlstd|'a t<hlendline|><next-line> \ ><hlkwa|val ><hlstd|mplus
    ><hlopt|: ><hlstd|'a t ><hlopt|-\<gtr\> ><hlstd|'a t ><hlopt|-\<gtr\>
    ><hlstd|'a t><hlendline|><next-line><hlkwa|end><hlendline|><hlendline|>

    <item>Monad-plus class also has its general-purpose functions:

    <hlkwa|module type ><hlkwd|MONAD<textunderscore>PLUS<textunderscore>OPS
    ><hlopt|= ><hlkwa|sig><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|MONAD<textunderscore>OPS><hlendline|><next-line><hlstd|
    \ ><hlkwa|val ><hlstd|mzero ><hlopt|: ><hlstd|'a
    monad<hlendline|><next-line> \ ><hlkwa|val ><hlstd|mplus ><hlopt|:
    ><hlstd|'a monad ><hlopt|-\<gtr\> ><hlstd|'a monad ><hlopt|-\<gtr\>
    ><hlstd|'a monad<hlendline|><next-line> \ ><hlkwa|val ><hlstd|fail
    ><hlopt|: ><hlstd|'a monad<hlendline|><next-line> \ ><hlkwa|val
    ><hlopt|(++) : ><hlstd|'a monad ><hlopt|-\<gtr\> ><hlstd|'a monad
    ><hlopt|-\<gtr\> ><hlstd|'a monad<hlendline|><next-line> \ ><hlkwa|val
    ><hlstd|guard ><hlopt|: ><hlkwb|bool ><hlopt|-\<gtr\> ><hlkwb|unit
    ><hlstd|monad<hlendline|><next-line> \ ><hlkwa|val
    ><hlstd|msum<textunderscore>map ><hlopt|: (><hlstd|'a ><hlopt|-\<gtr\>
    ><hlstd|'b monad><hlopt|) -\<gtr\> ><hlstd|'a list ><hlopt|-\<gtr\>
    ><hlstd|'b monad><hlendline|><next-line><hlkwa|end><hlendline|>

    <new-page*><item>We again separate the ``implementation'' and the
    ``interface''.

    <hlkwa|module ><hlkwd|MonadPlusOps ><hlopt|(><hlkwd|M ><hlopt|:
    ><hlkwd|MONAD<textunderscore>PLUS><hlopt|) =
    ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|open
    ><hlkwd|M><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|MonadOps><hlopt|(><hlkwd|M><hlopt|)><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|fail ><hlopt|= ><hlstd|mzero<hlendline|><next-line>
    \ ><hlkwa|let ><hlopt|(++) ><hlstd|a b ><hlopt|= ><hlstd|mplus a
    b<hlendline|><next-line> \ ><hlkwa|let ><hlstd|guard p ><hlopt|=
    ><hlkwa|if ><hlstd|p ><hlkwa|then ><hlstd|return ><hlopt|() ><hlkwa|else
    ><hlstd|fail<hlendline|><next-line> \ ><hlkwa|let
    ><hlstd|msum<textunderscore>map f l ><hlopt|=
    ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>right<hlendline|><next-line>
    \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|a acc ><hlopt|-\<gtr\> ><hlstd|mplus
    ><hlopt|(><hlstd|f a><hlopt|) ><hlstd|acc><hlopt|) ><hlstd|l
    mzero><hlendline|><next-line><hlkwa|end><hlendline|>

    <hlkwa|module ><hlkwd|MonadPlus ><hlopt|(><hlkwd|M ><hlopt|:
    ><hlkwd|MONAD<textunderscore>PLUS><hlopt|)
    :><hlendline|><next-line><hlkwa|sig><hlendline|><next-line><hlstd|
    \ ><hlkwa|include ><hlkwd|MONAD<textunderscore>PLUS<textunderscore>OPS><hlendline|><next-line><hlstd|
    \ ><hlkwa|val ><hlstd|run ><hlopt|: ><hlstd|'a monad ><hlopt|-\<gtr\>
    ><hlstd|'a ><hlkwc|M><hlopt|.><hlstd|t><hlendline|><next-line><hlkwa|end
    ><hlopt|= ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|M><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|MonadPlusOps><hlopt|(><hlkwd|M><hlopt|)><hlendline|><next-line><hlkwa|end><hlendline|><next-line>

    <new-page*><item>We also need a class for computations with state.

    <hlkwa|module type ><hlkwd|STATE ><hlopt|=
    ><hlkwa|sig><hlendline|><next-line><hlstd| \ ><hlkwa|type
    ><hlstd|store<hlendline|><next-line> \ ><hlkwa|type ><hlstd|'a
    t<hlendline|><next-line> \ ><hlkwa|val ><hlstd|get ><hlopt|:
    ><hlstd|store t<hlendline|><next-line> \ ><hlkwa|val ><hlstd|put
    ><hlopt|: ><hlstd|store ><hlopt|-\<gtr\> ><hlkwb|unit
    ><hlstd|t><hlendline|><next-line><hlkwa|end><hlendline|>

    The purpose of this signature is inclusion in other signatures.
  </itemize>

  <section|<new-page*>Monad instances>

  <\itemize>
    <item>We do not define a class for monads with access since accessing
    means running the monad, not useful while in the monad.

    <item>Notation for laziness heavy? Try a monad! (Monads with access.)

    <hlkwa|module ><hlkwd|LazyM ><hlopt|= ><hlkwd|Monad
    ><hlopt|(><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|type
    ><hlstd|'a><hlstd| t ><hlopt|= ><hlstd|'a
    ><hlkwc|Lazy><hlopt|.><hlstd|t<hlendline|><next-line> \ ><hlkwa|let
    ><hlstd|bind a b ><hlopt|= ><hlkwa|lazy
    ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force ><hlopt|(><hlstd|b
    ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force
    a><hlopt|)))><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|return
    a ><hlopt|= ><hlkwa|lazy ><hlstd|a><hlendline|><next-line><hlkwa|end><hlopt|)><hlendline|>

    <hlkwa|let ><hlstd|laccess m ><hlopt|= ><hlkwc|Lazy><hlopt|.><hlstd|force
    ><hlopt|(><hlkwc|LazyM><hlopt|.><hlstd|run
    m><hlopt|)><hlendline|><next-line>

    <new-page*><item>Our resident list monad. (Monad-plus.)

    <hlkwa|module ><hlkwd|ListM ><hlopt|= ><hlkwd|MonadPlus
    ><hlopt|(><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|type
    ><hlstd|'a><hlstd| t ><hlopt|= ><hlstd|'a list<hlendline|><next-line>
    \ ><hlkwa|let ><hlstd|bind a b ><hlopt|=
    ><hlstd|concat<textunderscore>map b a<hlendline|><next-line>
    \ ><hlkwa|let ><hlstd|return a ><hlopt|=
    [><hlstd|a><hlopt|]><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|mzero ><hlopt|= []><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|mplus ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|append><hlendline|><next-line><hlkwa|end><hlopt|)><hlendline|>
  </itemize>

  <subsection|<new-page*>Backtracking parameterized by monad-plus >

  <hlkwa|module ><hlkwd|Countdown ><hlopt|(><hlkwd|M ><hlopt|:
  ><hlkwd|MONAD<textunderscore>PLUS<textunderscore>OPS><hlopt|) =
  ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|open
  ><hlkwd|M><hlendline|Open the module to make monad operations visible.>

  <hlkwa| \ let rec ><hlstd|insert x ><hlopt|=
  ><hlkwa|function><hlendline|All choice-introducing
  operations><next-line><hlstd| \ \ \ ><hlopt|\| [] -\<gtr\> ><hlstd|return
  ><hlopt|[><hlstd|x><hlopt|]><hlendline|need to happen in the
  monad.><next-line><hlstd| \ \ \ <hlopt|\|> y><hlopt|::><hlstd|ys ><hlkwa|as
  ><hlstd|xs ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ return
  ><hlopt|(><hlstd|x><hlopt|::><hlstd|xs><hlopt|)
  ++><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|perform ><hlstd|xys
  ><hlopt|\<less\>-- ><hlstd|insert x ys><hlopt|; ><hlstd|return
  ><hlopt|(><hlstd|y><hlopt|::><hlstd|xys><hlopt|)><hlendline|>

  <hlstd| \ ><hlkwa|let rec ><hlstd|choices ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| []
  -\<gtr\> ><hlstd|return ><hlopt|[]><hlendline|><next-line><hlstd|
  \ \ \ <hlopt|\|> x><hlopt|::><hlstd|xs ><hlopt|-\<gtr\>
  ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ cxs
  ><hlopt|\<less\>-- ><hlstd|choices xs><hlopt|;><hlendline|Choosing which
  numbers in what order><next-line><hlstd| \ \ \ \ \ \ \ return cxs
  ><hlopt|++ ><verbatim|insert x cxs><hlendline|and now whether with or
  without <verbatim|x>.>

  <new-page*><verbatim| \ ><hlkwa|type ><hlstd|op ><hlopt|= ><hlkwd|Add
  ><hlopt|\| ><hlkwd|Sub ><hlopt|\| ><hlkwd|Mul ><hlopt|\|
  ><hlkwd|Div><hlendline|>

  <hlkwa| \ let ><hlstd|apply op x y ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|match ><hlstd|op ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|Add ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|+
  ><hlstd|y<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|Sub
  ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|- ><hlstd|y<hlendline|><next-line>
  \ \ \ ><hlopt|\| ><hlkwd|Mul ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|*
  ><hlstd|y<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|Div
  ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|/ ><hlstd|y<hlendline|> \ >

  <hlkwa| \ let ><hlstd|valid op x y ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|match ><hlstd|op ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|Add ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|\<less\>=
  ><hlstd|y<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|Sub
  ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|\<gtr\> ><hlstd|y<hlendline|><next-line>
  \ \ \ ><hlopt|\| ><hlkwd|Mul ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|\<less\>=
  ><hlstd|y ><hlopt|&& ><hlstd|x ><hlopt|\<less\>\<gtr\> ><hlnum|1 ><hlopt|&&
  ><hlstd|y ><hlopt|\<less\>\<gtr\> ><hlnum|1><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|Div ><hlopt|-\<gtr\> ><hlstd|x ><hlkwa|mod
  ><hlstd|y ><hlopt|= ><hlnum|0 ><hlopt|&& ><hlstd|y ><hlopt|\<less\>\<gtr\>
  ><hlnum|1><hlendline|>

  <new-page*><hlkwa| \ type ><hlstd|expr ><hlopt|= ><hlkwd|Val ><hlkwa|of
  ><hlkwb|int ><hlopt|\| ><hlkwd|App ><hlkwa|of ><hlstd|op ><hlopt|*
  ><hlstd|expr ><hlopt|* ><hlstd|expr<hlendline|> \ >

  <hlkwa| \ let ><hlstd|op2str ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|Add ><hlopt|-\<gtr\> ><hlstr|"+"><hlstd|
  <hlopt|\|> ><hlkwd|Sub ><hlopt|-\<gtr\> ><hlstr|"-"><hlstd| <hlopt|\|>
  ><hlkwd|Mul ><hlopt|-\<gtr\> ><hlstr|"*"><hlstd| <hlopt|\|> ><hlkwd|Div
  ><hlopt|-\<gtr\> ><hlstr|"/"><hlstd|<hlendline|><next-line> \ ><hlkwa|let
  rec ><hlstd|expr2str ><hlopt|= ><hlkwa|function><hlendline|We will provide
  solutions as strings.><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Val
  ><hlstd|n ><hlopt|-\<gtr\> ><hlstd|string<textunderscore>of<textunderscore>int
  n<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|App
  ><hlopt|(><hlstd|op><hlopt|,><hlstd|l><hlopt|,><hlstd|r><hlopt|)
  -\<gtr\>><hlstr|"("><hlstd|<textasciicircum>expr2str
  l<textasciicircum>op2str op<textasciicircum>expr2str
  r<textasciicircum>><hlstr|")">

  <hlkwa| \ let ><hlstd|combine ><hlopt|(><hlstd|l><hlopt|,><hlstd|x><hlopt|)
  (><hlstd|r><hlopt|,><hlstd|y><hlopt|) ><hlstd|o ><hlopt|=
  ><hlkwa|perform><hlendline|Try out an operator.><next-line><hlstd|
  \ \ \ \ \ guard ><hlopt|(><hlstd|valid o x
  y><hlopt|);><hlendline|><next-line><hlstd| \ \ \ \ \ return
  ><hlopt|(><hlkwd|App ><hlopt|(><hlstd|o><hlopt|,><hlstd|l><hlopt|,><hlstd|r><hlopt|),
  ><hlstd|apply o x y><hlopt|)><hlendline|>

  <hlkwa| \ let ><hlstd|split l ><hlopt|=><hlendline|Another choice: which
  numbers go into which argument.><next-line><hlstd| \ \ \ ><hlkwa|let rec
  ><hlstd|aux lhs ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| [] \| [><hlstd|<textunderscore>><hlopt|] -\<gtr\>
  ><verbatim|fail><hlendline|Both arguments need
  numbers.><next-line><verbatim| \ \ \ \ \ ><hlopt|\| [><hlstd|y><hlopt|;
  ><hlstd|z><hlopt|] -\<gtr\> ><hlstd|return
  ><hlopt|(><hlkwc|List><hlopt|.><hlstd|rev
  ><hlopt|(><hlstd|y><hlopt|::><hlstd|lhs><hlopt|),
  [><hlstd|z><hlopt|])><hlendline|><next-line><hlstd| \ \ \ \ \ <hlopt|\|>
  hd><hlopt|::><hlstd|rhs ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlkwa|let ><hlstd|lhs ><hlopt|=
  ><hlstd|hd><hlopt|::><hlstd|lhs ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ return ><hlopt|(><hlkwc|List><hlopt|.><hlstd|rev lhs><hlopt|,
  ><hlstd|rhs><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlopt|++ ><hlstd|aux lhs rhs
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ aux ><hlopt|[]
  ><hlstd|l<hlendline|> \ >

  <hlkwa| \ let rec ><hlstd|results ><hlopt|=
  ><hlkwa|function><hlendline|Build possible expressions once
  numbers><next-line><hlstd| \ \ \ ><hlopt|\| [] -\<gtr\>
  ><verbatim|fail><hlendline|have been picked.><next-line><verbatim|
  \ \ \ ><hlopt|\| [><hlstd|n><hlopt|] -\<gtr\>
  ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ guard
  ><hlopt|(><hlstd|n ><hlopt|\<gtr\> ><hlnum|0><hlopt|); ><hlstd|return
  ><hlopt|(><hlkwd|Val ><hlstd|n><hlopt|,
  ><hlstd|n><hlopt|)><hlendline|><next-line><hlstd| \ \ \ <hlopt|\|> ns
  ><hlopt|-\<gtr\> ><hlkwa|perform><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlopt|(><hlstd|ls><hlopt|, ><hlstd|rs><hlopt|) \<less\>--
  ><hlstd|split ns><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ lx
  ><hlopt|\<less\>-- ><hlstd|results ls><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ly ><hlopt|\<less\>-- ><hlstd|results
  rs><hlopt|;><hlendline|Collect solutions using each
  operator.><next-line><hlstd| \ \ \ \ \ \ \ msum<textunderscore>map
  ><hlopt|(><hlstd|combine lx ly><hlopt|) [><hlkwd|Add><hlopt|;
  ><hlkwd|Sub><hlopt|; ><hlkwd|Mul><hlopt|; ><hlkwd|Div><hlopt|]><hlendline|>

  <hlkwa| \ let ><hlstd|solutions ns n ><hlopt|=
  ><hlkwa|perform><hlendline|Solve the problem:><next-line><hlstd|
  \ \ \ \ \ ns' ><hlopt|\<less\>-- ><hlstd|choices
  ns><hlopt|;><hlendline|pick numbers and their order,><next-line><hlstd|
  \ \ \ \ \ ><hlopt|(><hlstd|e><hlopt|,><hlstd|m><hlopt|) \<less\>--
  ><hlstd|results ns'><hlopt|;><hlendline|build possible
  expressions,><next-line><hlstd| \ \ \ \ \ guard
  ><hlopt|(><hlstd|m><hlopt|=><hlstd|n><hlopt|);><hlendline|check if the
  expression gives target value,><next-line><hlstd| \ \ \ \ \ return
  ><hlopt|(><hlstd|expr2str e><hlopt|)><hlendline|``print'' the
  solution.><next-line><hlkwa|end><hlendline|>

  <subsection|<new-page*>Understanding laziness>

  <\itemize>
    <item>We will measure execution times:

    <hlstd|#load ><hlstr|"unix.cma"><hlopt|;;><hlendline|><next-line><hlkwa|let
    ><hlstd|time f ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|tbeg ><hlopt|= ><hlkwc|Unix><hlopt|.><hlstd|gettimeofday
    ><hlopt|() ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|res ><hlopt|= ><hlstd|f ><hlopt|()
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|tend
    ><hlopt|= ><hlkwc|Unix><hlopt|.><hlstd|gettimeofday ><hlopt|()
    ><hlkwa|in><hlendline|><next-line><hlstd| \ tend ><hlopt|-.
    ><hlstd|tbeg><hlopt|, ><hlstd|res><hlendline|>

    <item>Let's check our generalized <hlkwd|Countdown> solver using original
    operations.

    <hlkwa|module ><hlkwd|ListCountdown ><hlopt|= ><hlkwd|Countdown
    ><hlopt|(><hlkwd|ListM><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|test1 ><hlopt|() = ><hlkwc|ListM><hlopt|.><hlstd|run
    ><hlopt|(><hlkwc|ListCountdown><hlopt|.><hlstd|solutions
    ><hlopt|[><hlnum|1><hlopt|;><hlnum|3><hlopt|;><hlnum|7><hlopt|;><hlnum|10><hlopt|;><hlnum|25><hlopt|;><hlnum|50><hlopt|]
    ><hlnum|765><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|t1><hlopt|, ><hlstd|sol1 ><hlopt|= ><hlstd|time
    test1><hlendline|>

    <item><hlkwa|val ><hlstd|t1 ><hlopt|: ><hlkwb|float ><hlopt|=
    ><hlnum|2.2856600284576416><hlendline|><next-line><hlkwa|val ><hlstd|sol1
    ><hlopt|: ><hlkwb|string ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[><hlstr|"((25-(3+7))*(1+50))"><hlopt|;
    ><hlstr|"(((25-3)-7)*(1+50))"><hlopt|; ...><hlendline|>

    <new-page*><item>What if we want only one solution? Laziness to the
    rescue!

    <hlkwa|type ><hlstd|'a llist ><hlopt|= ><hlkwd|LNil ><hlopt|\|
    ><hlkwd|LCons ><hlkwa|of ><hlstd|'a ><hlopt|* ><hlstd|'a llist
    ><hlkwc|Lazy><hlopt|.><hlstd|t><hlendline|><next-line><hlkwa|let rec
    ><hlstd|ltake n ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd|
    <hlopt|\|> ><hlkwd|LCons ><hlopt|(><hlstd|a><hlopt|, ><hlkwa|lazy
    ><hlstd|l><hlopt|) ><hlkwa|when ><hlstd|n ><hlopt|\<gtr\> ><hlnum|0
    ><hlopt|-\<gtr\> ><hlstd|a><hlopt|::(><hlstd|ltake
    ><hlopt|(><hlstd|n><hlopt|-><hlnum|1><hlopt|)
    ><hlstd|l><hlopt|)><hlendline|><next-line><hlstd| <hlopt|\|>
    <textunderscore> ><hlopt|-\<gtr\> []><hlendline|><next-line><hlkwa|let
    rec ><hlstd|lappend l1 l2 ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|match ><hlstd|l1 ><hlkwa|with ><hlkwd|LNil ><hlopt|-\<gtr\>
    ><hlstd|l2<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|LCons
    ><hlopt|(><hlstd|hd><hlopt|, ><hlstd|tl><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|LCons
    ><hlopt|(><hlstd|hd><hlopt|, ><hlkwa|lazy ><hlopt|(><hlstd|lappend
    ><hlopt|(><hlkwc|Lazy><hlopt|.><hlstd|force tl><hlopt|)
    ><hlstd|l2><hlopt|))><hlendline|><next-line><hlkwa|let rec
    ><hlstd|lconcat<textunderscore>map f ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|LNil
    ><hlopt|-\<gtr\> ><hlkwd|LNil><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|LCons ><hlopt|(><hlstd|a><hlopt|, ><hlkwa|lazy ><hlstd|l><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ lappend ><hlopt|(><hlstd|f
    a><hlopt|) (><hlstd|lconcat<textunderscore>map f l><hlopt|)><hlendline|>

    <new-page*><item>That is, another monad-plus.

    <hlkwa|module ><hlkwd|LListM ><hlopt|= ><hlkwd|MonadPlus
    ><hlopt|(><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|type
    ><hlstd|'a><hlstd| t ><hlopt|= ><hlstd|'a llist<hlendline|><next-line>
    \ ><hlkwa|let ><hlstd|bind a b ><hlopt|=
    ><hlstd|lconcat<textunderscore>map b a<hlendline|><next-line>
    \ ><hlkwa|let ><hlstd|return a ><hlopt|= ><hlkwd|LCons
    ><hlopt|(><hlstd|a><hlopt|, ><hlkwa|lazy
    ><hlkwd|LNil><hlopt|)><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|mzero ><hlopt|= ><hlkwd|LNil><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|mplus ><hlopt|=
    ><hlstd|lappend><hlendline|><next-line><hlkwa|end><hlopt|)><hlendline|>

    <item><hlkwa|module ><hlkwd|LListCountdown ><hlopt|= ><hlkwd|Countdown
    ><hlopt|(><hlkwd|LListM><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|test2 ><hlopt|() = ><hlkwc|LListM><hlopt|.><hlstd|run
    ><hlopt|(><hlkwc|LListCountdown><hlopt|.><hlstd|solutions
    ><hlopt|[><hlnum|1><hlopt|;><hlnum|3><hlopt|;><hlnum|7><hlopt|;><hlnum|10><hlopt|;><hlnum|25><hlopt|;><hlnum|50><hlopt|]
    ><hlnum|765><hlopt|)><hlendline|>

    <item><hlstd|# ><hlkwa|let ><hlstd|t2a><hlopt|, ><hlstd|sol2 ><hlopt|=
    ><hlstd|time test2><hlopt|;;><hlendline|><next-line><hlkwa|val
    ><hlstd|t2a ><hlopt|: ><hlkwb|float ><hlopt|=
    ><hlnum|2.51197600364685059><hlendline|><next-line><hlkwa|val
    ><hlstd|sol2 ><hlopt|: ><hlkwb|string ><hlstd|llist ><hlopt|=
    ><hlkwd|LCons ><hlopt|(><hlstr|"((25-(3+7))*(1+50))"><hlopt|,
    \<less\>><hlkwa|lazy><hlopt|\<gtr\>)><hlendline|>

    Not good, almost the same time to even get the lazy list!

    <new-page*><item><hlstd|# ><hlkwa|let ><hlstd|t2b><hlopt|,
    ><hlstd|sol2<textunderscore>1 ><hlopt|= ><hlstd|time ><hlopt|(><hlkwa|fun
    ><hlopt|() -\<gtr\> ><hlstd|ltake ><hlnum|1
    ><hlstd|sol2><hlopt|);;><hlendline|><next-line><hlkwa|val ><hlstd|t2b
    ><hlopt|: ><hlkwb|float ><hlopt|= ><hlnum|2.86102294921875e-06><hlendline|><next-line><hlkwa|val
    ><hlstd|sol2<textunderscore>1 ><hlopt|: ><hlkwb|string ><hlstd|list
    ><hlopt|= [><hlstr|"((25-(3+7))*(1+50))"><hlopt|]><hlendline|><next-line><hlstd|#
    ><hlkwa|let ><hlstd|t2c><hlopt|, ><hlstd|sol2<textunderscore>9 ><hlopt|=
    ><hlstd|time ><hlopt|(><hlkwa|fun ><hlopt|() -\<gtr\> ><hlstd|ltake
    ><hlnum|10 ><hlstd|sol2><hlopt|);;><hlendline|><next-line><hlkwa|val
    ><hlstd|t2c ><hlopt|: ><hlkwb|float ><hlopt|=
    ><hlnum|9.059906005859375e-06><hlendline|><next-line><hlkwa|val
    ><hlstd|sol2<textunderscore>9 ><hlopt|: ><hlkwb|string ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[><hlstr|"((25-(3+7))*(1+50))"><hlopt|;
    ><hlstr|"(((25-3)-7)*(1+50))"><hlopt|;
    ...><hlendline|><next-line><hlstd|# ><hlkwa|let ><hlstd|t2d><hlopt|,
    ><hlstd|sol2<textunderscore>39 ><hlopt|= ><hlstd|time
    ><hlopt|(><hlkwa|fun ><hlopt|() -\<gtr\> ><hlstd|ltake ><hlnum|49
    ><hlstd|sol2><hlopt|);;><hlendline|><next-line><hlkwa|val ><hlstd|t2d
    ><hlopt|: ><hlkwb|float ><hlopt|= ><hlnum|4.00543212890625e-05><hlendline|><next-line><hlkwa|val
    ><hlstd|sol2<textunderscore>39 ><hlopt|: ><hlkwb|string ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[><hlstr|"((25-(3+7))*(1+50))"><hlopt|;
    ><hlstr|"(((25-3)-7)*(1+50))"><hlopt|; ...><hlendline|>

    Getting elements from the list shows they are almost already computed.

    <new-page*><item>Wait! Perhaps we should not store all candidates when we
    are only interested in one.

    <hlkwa|module ><hlkwd|OptionM ><hlopt|= ><hlkwd|MonadPlus
    ><hlopt|(><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|type
    ><hlstd|'a><hlstd| t ><hlopt|= ><hlstd|'a
    ><hlkwb|option><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|bind
    a b ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match
    ><hlstd|a ><hlkwa|with ><hlkwd|None ><hlopt|-\<gtr\> ><hlkwd|None
    ><hlopt|\| ><hlkwd|Some ><hlstd|x ><hlopt|-\<gtr\> ><hlstd|b
    x<hlendline|><next-line> \ ><hlkwa|let ><hlstd|return a ><hlopt|=
    ><hlkwd|Some ><hlstd|a<hlendline|><next-line> \ ><hlkwa|let ><hlstd|mzero
    ><hlopt|= ><hlkwd|None><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|mplus a b ><hlopt|= ><hlkwa|match ><hlstd|a ><hlkwa|with
    ><hlkwd|None ><hlopt|-\<gtr\> ><hlstd|b <hlopt|\|> ><hlkwd|Some
    ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
    ><hlstd|a><hlendline|><next-line><hlkwa|end><hlopt|)><hlendline|>

    <item><hlkwa|module ><hlkwd|OptCountdown ><hlopt|= ><hlkwd|Countdown
    ><hlopt|(><hlkwd|OptionM><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|test3 ><hlopt|() = ><hlkwc|OptionM><hlopt|.><hlstd|run
    ><hlopt|(><hlkwc|OptCountdown><hlopt|.><hlstd|solutions
    ><hlopt|[><hlnum|1><hlopt|;><hlnum|3><hlopt|;><hlnum|7><hlopt|;><hlnum|10><hlopt|;><hlnum|25><hlopt|;><hlnum|50><hlopt|]
    ><hlnum|765><hlopt|)><hlendline|>

    <item><hlstd|# ><hlkwa|let ><hlstd|t3><hlopt|, ><hlstd|sol3 ><hlopt|=
    ><hlstd|time test3><hlopt|;;><hlendline|><next-line><hlkwa|val ><hlstd|t3
    ><hlopt|: ><hlkwb|float ><hlopt|= ><hlnum|5.0067901611328125e-06><hlendline|><next-line><hlkwa|val
    ><hlstd|sol3 ><hlopt|: ><hlkwb|string option ><hlopt|=
    ><hlkwd|None><hlendline|>

    It very quickly computes... nothing. Why?

    <\itemize>
      <item>What is the <hlkwd|OptionM> monad (<verbatim|Maybe> monad in
      Haskell) good for?
    </itemize>

    <item>Our lazy list type is not lazy enough.

    <\itemize>
      <item>Whenever we ``make'' a choice: <verbatim|a ><hlopt|++><verbatim|
      b> or <verbatim|msum_map> ..., it computes the first candidate for each
      choice path.

      <item>When we bind consecutive steps, it computes the second candidate
      of the first step even when the first candidate would suffice.
    </itemize>

    <new-page*><item>We want the whole monad to be lazy: it's called <em|even
    lazy lists>.

    <\itemize>
      <item>Our <verbatim|llist> are called <em|odd lazy lists>.
    </itemize>

    <hlkwa|type ><hlstd|'a lazy<textunderscore>list ><hlopt|= ><hlstd|'a
    lazy<textunderscore>list<textunderscore>
    ><hlkwc|Lazy><hlopt|.><hlstd|t><hlendline|><next-line><hlkwa|and
    ><hlstd|'a lazy<textunderscore>list<textunderscore> ><hlopt|=
    ><hlkwd|LazNil ><hlopt|\| ><hlkwd|LazCons ><hlkwa|of ><hlstd|'a ><hlopt|*
    ><hlstd|'a lazy<textunderscore>list><hlendline|><next-line><hlkwa|let rec
    ><hlstd|laztake n ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd|
    <hlopt|\|> ><hlkwa|lazy ><hlopt|(><hlkwd|LazCons
    ><hlopt|(><hlstd|a><hlopt|, ><hlstd|l><hlopt|)) ><hlkwa|when ><hlstd|n
    ><hlopt|\<gtr\> ><hlnum|0 ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ a><hlopt|::(><hlstd|laztake ><hlopt|(><hlstd|n><hlopt|-><hlnum|1><hlopt|)
    ><hlstd|l><hlopt|)><hlendline|><next-line><hlstd| <hlopt|\|>
    <textunderscore> ><hlopt|-\<gtr\> []><hlendline|><next-line><hlkwa|let
    rec ><hlstd|append<textunderscore>aux l1 l2
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match ><hlstd|l1
    ><hlkwa|with lazy ><hlkwd|LazNil ><hlopt|-\<gtr\>
    ><hlkwc|Lazy><hlopt|.><hlstd|force l2<hlendline|><next-line> \ ><hlopt|\|
    ><hlkwa|lazy ><hlopt|(><hlkwd|LazCons ><hlopt|(><hlstd|hd><hlopt|,
    ><hlstd|tl><hlopt|)) -\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwd|LazCons ><hlopt|(><hlstd|hd><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlstd|append<textunderscore>aux tl
    l2><hlopt|))><hlendline|><next-line><hlkwa|let ><hlstd|lazappend l1 l2
    ><hlopt|= ><hlkwa|lazy ><hlopt|(><hlstd|append<textunderscore>aux l1
    l2><hlopt|)><hlendline|><next-line><hlkwa|let rec
    ><hlstd|concat<textunderscore>map<textunderscore>aux f ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwa|lazy
    ><hlkwd|LazNil ><hlopt|-\<gtr\> ><hlkwd|LazNil><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwa|lazy ><hlopt|(><hlkwd|LazCons
    ><hlopt|(><hlstd|a><hlopt|, ><hlstd|l><hlopt|))
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ append<textunderscore>aux
    ><hlopt|(><hlstd|f a><hlopt|) (><hlkwa|lazy
    ><hlopt|(><hlstd|concat<textunderscore>map<textunderscore>aux f
    l><hlopt|))><hlendline|><next-line><hlkwa|let
    ><hlstd|lazconcat<textunderscore>map f l ><hlopt|= ><hlkwa|lazy
    ><hlopt|(><hlstd|concat<textunderscore>map<textunderscore>aux f
    l><hlopt|)><hlendline|>

    <new-page*><item><hlkwa|module ><hlkwd|LazyListM ><hlopt|=
    ><hlkwd|MonadPlus ><hlopt|(><hlkwa|struct><hlendline|><next-line><hlstd|
    \ ><hlkwa|type ><hlstd|'a><hlstd| t ><hlopt|= ><hlstd|'a
    lazy<textunderscore>list<hlendline|><next-line> \ ><hlkwa|let
    ><hlstd|bind a b ><hlopt|= ><hlstd|lazconcat<textunderscore>map b
    a<hlendline|><next-line> \ ><hlkwa|let ><hlstd|return a ><hlopt|=
    ><hlkwa|lazy ><hlopt|(><hlkwd|LazCons ><hlopt|(><hlstd|a><hlopt|,
    ><hlkwa|lazy ><hlkwd|LazNil><hlopt|))><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|mzero ><hlopt|= ><hlkwa|lazy
    ><hlkwd|LazNil><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|mplus
    ><hlopt|= ><hlstd|lazappend><hlendline|><next-line><hlkwa|end><hlopt|)><hlendline|>

    <item><hlkwa|module ><hlkwd|LazyCountdown ><hlopt|= ><hlkwd|Countdown
    ><hlopt|(><hlkwd|LazyListM><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|test4 ><hlopt|() = ><hlkwc|LazyListM><hlopt|.><hlstd|run
    ><hlopt|(><hlkwc|LazyCountdown><hlopt|.><hlstd|solutions
    ><hlopt|[><hlnum|1><hlopt|;><hlnum|3><hlopt|;><hlnum|7><hlopt|;><hlnum|10><hlopt|;><hlnum|25><hlopt|;><hlnum|50><hlopt|]
    ><hlnum|765><hlopt|)><hlendline|>

    <new-page*><item><hlstd|# ><hlkwa|let ><hlstd|t4a><hlopt|, ><hlstd|sol4
    ><hlopt|= ><hlstd|time test4><hlopt|;;><hlendline|><next-line><hlkwa|val
    ><hlstd|t4a ><hlopt|: ><hlkwb|float ><hlopt|=
    ><hlnum|2.86102294921875e-06><hlendline|><next-line><hlkwa|val
    ><hlstd|sol4 ><hlopt|: ><hlkwb|string ><hlstd|lazy<textunderscore>list
    ><hlopt|= \<less\>><hlkwa|lazy><hlopt|\<gtr\>><hlendline|><next-line><hlstd|#
    ><hlkwa|let ><hlstd|t4b><hlopt|, ><hlstd|sol4<textunderscore>1 ><hlopt|=
    ><hlstd|time ><hlopt|(><hlkwa|fun ><hlopt|() -\<gtr\> ><hlstd|laztake
    ><hlnum|1 ><hlstd|sol4><hlopt|);;><hlendline|><next-line><hlkwa|val
    ><hlstd|t4b ><hlopt|: ><hlkwb|float ><hlopt|=
    ><hlnum|0.367874860763549805><hlendline|><next-line><hlkwa|val
    ><hlstd|sol4<textunderscore>1 ><hlopt|: ><hlkwb|string ><hlstd|list
    ><hlopt|= [><hlstr|"((25-(3+7))*(1+50))"><hlopt|]><hlendline|><next-line><hlstd|#
    ><hlkwa|let ><hlstd|t4c><hlopt|, ><hlstd|sol4<textunderscore>9 ><hlopt|=
    ><hlstd|time ><hlopt|(><hlkwa|fun ><hlopt|() -\<gtr\> ><hlstd|laztake
    ><hlnum|10 ><hlstd|sol4><hlopt|);;><hlendline|><next-line><hlkwa|val
    ><hlstd|t4c ><hlopt|: ><hlkwb|float ><hlopt|=
    ><hlnum|0.234670877456665039><hlendline|><next-line><hlkwa|val
    ><hlstd|sol4<textunderscore>9 ><hlopt|: ><hlkwb|string ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[><hlstr|"((25-(3+7))*(1+50))"><hlopt|;
    ><hlstr|"(((25-3)-7)*(1+50))"><hlopt|;
    ...><hlendline|><next-line><hlstd|# ><hlkwa|let ><hlstd|t4d><hlopt|,
    ><hlstd|sol4<textunderscore>39 ><hlopt|= ><hlstd|time
    ><hlopt|(><hlkwa|fun ><hlopt|() -\<gtr\> ><hlstd|laztake ><hlnum|49
    ><hlstd|sol4><hlopt|);;><hlendline|><next-line><hlkwa|val ><hlstd|t4d
    ><hlopt|: ><hlkwb|float ><hlopt|= ><hlnum|4.0594940185546875><hlendline|><next-line><hlkwa|val
    ><hlstd|sol4<textunderscore>39 ><hlopt|: ><hlkwb|string ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[><hlstr|"((25-(3+7))*(1+50))"><hlopt|;
    ><hlstr|"(((25-3)-7)*(1+50))"><hlopt|; ...><hlendline|>

    <\itemize>
      <item>Finally, the first solution in considerably less time than all
      solutions.

      <item>The next 9 solutions are almost computed once the first one is.

      <item>But computing all solutions takes nearly twice as long as without
      the overhead of lazy computation.
    </itemize>
  </itemize>

  <subsection|<new-page*>The exception monad>

  <\itemize>
    <item>Built-in non-functional exceptions in OCaml are more efficient (and
    more flexible).

    <item>Instead of specifying a type of exceptional values, we could use
    OCaml open type <verbatim|exn>, restoring some flexibility.

    <item>Monadic exceptions are safer than standard exceptions in situations
    like multi-threading. Monadic lightweight-thread library <hlkwc|Lwt> has
    <verbatim|throw> (called <verbatim|fail> there) and <verbatim|catch>
    operations in its monad.
  </itemize>

  <hlkwa|module ><hlkwd|ExceptionM><hlopt|(><hlkwd|Excn ><hlopt|: ><hlkwa|sig
  type ><hlstd|t ><hlkwa|end><hlopt|) : ><hlkwa|sig><hlendline|><next-line><hlstd|
  \ ><hlkwa|type ><hlstd|excn ><hlopt|= ><hlkwc|Excn><hlopt|.><hlstd|t<hlendline|><next-line>
  \ ><hlkwa|type ><hlstd|'a t ><hlopt|= ><hlkwd|OK ><hlkwa|of ><hlstd|'a
  <hlopt|\|> ><hlkwd|Bad ><hlkwa|of ><hlstd|excn<hlendline|><next-line>
  \ ><hlkwa|include ><hlkwd|MONAD<textunderscore>OPS><hlendline|><next-line><hlstd|
  \ ><hlkwa|val ><hlstd|run ><hlopt|: ><hlstd|'a monad ><hlopt|-\<gtr\>
  ><hlstd|'a t<hlendline|><next-line> \ ><hlkwa|val ><hlstd|throw ><hlopt|:
  ><hlstd|excn ><hlopt|-\<gtr\> ><hlstd|'a monad<hlendline|><next-line>
  \ ><hlkwa|val ><hlstd|catch ><hlopt|: ><hlstd|'a monad ><hlopt|-\<gtr\>
  (><hlstd|excn ><hlopt|-\<gtr\> ><hlstd|'a monad><hlopt|) -\<gtr\>
  ><hlstd|'a monad><hlendline|><next-line><hlkwa|end ><hlopt|=
  ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|type ><hlstd|excn
  ><hlopt|= ><hlkwc|Excn><hlopt|.><verbatim|t><hlendline|>

  <new-page*><verbatim| \ ><hlkwa|module ><hlkwd|M ><hlopt|=
  ><hlkwa|struct><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|type ><hlstd|'a
  t ><hlopt|= ><hlkwd|OK ><hlkwa|of ><hlstd|'a <hlopt|\|> ><hlkwd|Bad
  ><hlkwa|of ><hlstd|excn<hlendline|><next-line> \ \ \ ><hlkwa|let
  ><hlstd|return a ><hlopt|= ><hlkwd|OK ><hlstd|a<hlendline|><next-line>
  \ \ \ ><hlkwa|let ><hlstd|bind m b ><hlopt|= ><hlkwa|match ><hlstd|m
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\| ><hlkwd|OK
  ><hlstd|a ><hlopt|-\<gtr\> ><hlstd|b a<hlendline|><next-line>
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Bad ><hlstd|e ><hlopt|-\<gtr\> ><hlkwd|Bad
  ><hlstd|e<hlendline|><next-line> \ ><hlkwa|end><hlendline|><next-line><hlstd|
  \ ><hlkwa|include ><hlkwd|M><hlendline|><next-line><hlstd|
  \ ><hlkwa|include ><hlkwd|MonadOps><hlopt|(><hlkwd|M><hlopt|)><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|throw e ><hlopt|= ><hlkwd|Bad
  ><hlstd|e<hlendline|><next-line> \ ><hlkwa|let ><hlstd|catch m handler
  ><hlopt|= ><hlkwa|match ><hlstd|m ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|OK ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
  ><hlstd|m<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|Bad ><hlstd|e
  ><hlopt|-\<gtr\> ><hlstd|handler e><hlendline|><next-line><hlkwa|end><hlstd|
  \ \ \ ><hlendline|>

  <subsection|<new-page*>The state monad>

  <hlkwa|module ><hlkwd|StateM><hlopt|(><hlkwd|Store ><hlopt|: ><hlkwa|sig
  type ><hlstd|t ><hlkwa|end><hlopt|) : ><hlkwa|sig><hlendline|><next-line><hlstd|
  \ ><hlkwa|type ><hlstd|store ><hlopt|= ><hlkwc|Store><hlopt|.><verbatim|t><hlendline|Pass
  the current <verbatim|store> value to get the next
  value.><next-line><verbatim| \ ><hlkwa|type ><hlstd|'a t ><hlopt|=
  ><hlstd|store ><hlopt|-\<gtr\> ><hlstd|'a ><hlopt|*
  ><hlstd|store<hlendline|><next-line> \ ><hlkwa|include
  ><hlkwd|MONAD<textunderscore>OPS><hlendline|><next-line><hlstd|
  \ ><hlkwa|include ><hlkwd|STATE ><hlkwa|with type ><hlstd|'a t ><hlopt|:=
  ><hlstd|'a monad<hlendline|><next-line>
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|and type ><hlstd|store ><hlopt|:=
  ><hlstd|store<hlendline|><next-line> \ ><hlkwa|val ><hlstd|run ><hlopt|:
  ><hlstd|'a monad ><hlopt|-\<gtr\> ><hlstd|'a
  t><hlendline|><next-line><hlkwa|end ><hlopt|=
  ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|type ><hlstd|store
  ><hlopt|= ><hlkwc|Store><hlopt|.><hlstd|t<hlendline|><next-line>
  \ ><hlkwa|module ><hlkwd|M ><hlopt|= ><hlkwa|struct><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|type ><hlstd|'a t ><hlopt|= ><hlstd|store ><hlopt|-\<gtr\>
  ><hlstd|'a ><hlopt|* ><hlstd|store<hlendline|><next-line> \ \ \ ><hlkwa|let
  ><hlstd|return a ><hlopt|= ><hlkwa|fun ><hlstd|s ><hlopt|-\<gtr\>
  ><hlstd|a><hlopt|, ><verbatim|s><hlendline|Keep the current value
  unchanged.><next-line><verbatim| \ \ \ ><hlkwa|let ><hlstd|bind m b
  ><hlopt|= ><hlkwa|fun ><hlstd|s ><hlopt|-\<gtr\> ><hlkwa|let
  ><hlstd|a><hlopt|, ><hlstd|s' ><hlopt|= ><hlstd|m s ><hlkwa|in ><hlstd|b a
  s'<hlendline|><next-line> \ ><hlkwa|end><hlendline|To bind two steps, pass
  the value after first step to the second step.><next-line><hlstd|
  \ ><hlkwa|include ><hlkwd|M><hlkwa| include
  ><hlkwd|MonadOps><hlopt|(><hlkwd|M><hlopt|)><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|get ><hlopt|= ><hlkwa|fun ><hlstd|s ><hlopt|-\<gtr\>
  ><hlstd|s><hlopt|, ><verbatim|s><hlendline|Keep the value unchanged but put
  it in monad.><verbatim|<next-line> \ ><hlkwa|let ><hlstd|put s' ><hlopt|=
  ><hlkwa|fun ><hlstd|<textunderscore> ><hlopt|-\<gtr\> (),
  ><hlstd|s'><hlendline|Change the value; a throwaway in
  monad.><next-line><hlkwa|end>

  <\itemize>
    <new-page*><item>The state monad is useful to hide passing-around of a
    ``current'' value.

    <item>We will rename variables in <math|\<lambda\>>-terms to get rid of
    possible name clashes.

    <\itemize>
      <item>This does not make a <math|\<lambda\>>-term safe for multiple
      steps of <math|\<beta\>>-reduction. Find a counter-example.
    </itemize>

    <item><hlkwa|type ><hlstd|term ><hlopt|=><hlendline|><next-line><hlopt|\|
    ><hlkwd|Var ><hlkwa|of ><hlkwb|string><hlendline|><next-line><hlopt|\|
    ><hlkwd|Lam ><hlkwa|of ><hlkwb|string ><hlopt|*
    ><hlstd|term<hlendline|><next-line><hlopt|\|> ><hlkwd|App ><hlkwa|of
    ><hlstd|term ><hlopt|* ><hlstd|term><hlendline|>

    <item><hlkwa|let ><hlopt|(!) ><hlstd|x ><hlopt|= ><hlkwd|Var
    ><hlstd|x><hlendline|><next-line><hlkwa|let
    ><hlopt|(><hlstd|<hlopt|\|>><hlopt|-\<gtr\>) ><hlstd|x t ><hlopt|=
    ><hlkwd|Lam ><hlopt|(><hlstd|x><hlopt|,
    ><hlstd|t><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlopt|(><hlstd|@><hlopt|) ><hlstd|t1 t2 ><hlopt|= ><hlkwd|App
    ><hlopt|(><hlstd|t1><hlopt|, ><hlstd|t2><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|test ><hlopt|= ><hlstr|"x"><hlstd| <hlopt|\|>><hlopt|-\<gtr\>
    (><hlstr|"x"><hlstd| <hlopt|\|>><hlopt|-\<gtr\> !><hlstr|"y"><hlstd| @
    ><hlopt|!><hlstr|"x"><hlopt|) ><hlstd|@ ><hlopt|!><hlstr|"x"><hlendline|>

    <item><hlkwa|module ><hlkwd|S ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwd|StateM><hlopt|(><hlkwa|struct type ><hlstd|t ><hlopt|=
    ><hlkwb|int ><hlopt|* (><hlkwb|string ><hlopt|* ><hlkwb|string><hlopt|)
    ><hlstd|list ><hlkwa|end><hlopt|)><next-line><hlkwa|open ><hlkwd|S>

    Without opening the module, we would write <hlkwd|S><verbatim|.get>,
    <hlkwd|S><verbatim|.put> and <hlkwa|perform with ><hlkwd|S><hlkwa|
    in>...<hlendline|>

    <new-page*><item><hlkwa|let rec ><hlstd|alpha<textunderscore>conv
    ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|Var ><hlstd|x ><hlkwa|as ><hlstd|v ><hlopt|-\<gtr\>
    ><hlkwa|perform><hlendline|Function from terms to <hlkwd|StateM>
    monad.><next-line><hlstd| \ \ \ ><hlopt|(><hlstd|_><hlopt|,
    ><hlstd|env><hlopt|) \<less\>-- ><hlstd|get><hlopt|;><hlendline|Seeing a
    variable does not change state><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|v ><hlopt|= ><hlkwa|try ><hlkwd|Var
    ><hlopt|(><hlkwc|List><hlopt|.><hlstd|assoc x env><hlopt|)><hlendline|but
    we need its new name.><next-line><hlstd| \ \ \ \ \ ><hlkwa|with
    ><hlkwd|Not<textunderscore>found ><hlopt|-\<gtr\> ><hlstd|v
    ><hlkwa|in><hlendline|Free variables don't change
    name.><next-line><hlstd| \ \ \ return v<hlendline|><next-line>
    \ ><hlopt|\| ><hlkwd|Lam ><hlopt|(><hlstd|x><hlopt|, ><hlstd|t><hlopt|)
    -\<gtr\> ><hlkwa|perform><hlendline|We rename each bound
    variable.><next-line><hlstd| \ \ \ ><hlopt|(><hlstd|fresh><hlopt|,
    ><hlstd|env><hlopt|) \<less\>-- ><hlstd|get><hlopt|;><hlendline|We need a
    fresh number.><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|x' ><hlopt|=
    ><hlstd|x <textasciicircum> string<textunderscore>of<textunderscore>int
    fresh ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ put
    ><hlopt|(><hlstd|fresh><hlopt|+><hlnum|1><hlopt|, (><hlstd|x><hlopt|,
    ><hlstd|x'><hlopt|)::><hlstd|env><hlopt|);><hlendline|Remember new name,
    update number.><next-line><hlstd| \ \ \ t' ><hlopt|\<less\>--
    ><hlstd|alpha<textunderscore>conv t><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|(><hlstd|fresh'><hlopt|, ><hlstd|<textunderscore>><hlopt|)
    \<less\>-- ><hlstd|get><hlopt|;><hlendline|We need to restore
    names,><next-line><hlstd| \ \ \ put ><hlopt|(><hlstd|fresh'><hlopt|,
    ><hlstd|env><hlopt|);><hlendline|but keep the number
    fresh.><next-line><hlstd| \ \ \ return ><hlopt|(><hlkwd|Lam
    ><hlopt|(><hlstd|x'><hlopt|, ><hlstd|t'><hlopt|))><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|App ><hlopt|(><hlstd|t1><hlopt|, ><hlstd|t2><hlopt|)
    -\<gtr\> ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ t1
    ><hlopt|\<less\>-- ><hlstd|alpha<textunderscore>conv
    t1><hlopt|;><hlendline|Passing around of names><next-line><hlstd|
    \ \ \ t2 ><hlopt|\<less\>-- ><hlstd|alpha<textunderscore>conv
    t2><hlopt|;><hlendline|and the currently fresh number><next-line><hlstd|
    \ \ \ return ><hlopt|(><hlkwd|App ><hlopt|(><hlstd|t1><hlopt|,
    ><hlstd|t2><hlopt|))><hlendline|is done by the monad.>

    <new-page*><item><hlkwa|val ><hlstd|test ><hlopt|: ><hlstd|term ><hlopt|=
    ><hlkwd|Lam ><hlopt|(><hlstr|"x"><hlopt|, ><hlkwd|App
    ><hlopt|(><hlkwd|Lam ><hlopt|(><hlstr|"x"><hlopt|, ><hlkwd|App
    ><hlopt|(><hlkwd|Var ><hlstr|"y"><hlopt|, ><hlkwd|Var
    ><hlstr|"x"><hlopt|)), ><hlkwd|Var ><hlstr|"x"><hlopt|))><hlendline|><next-line><hlstd|#
    ><hlkwa|let ><hlstd|<textunderscore> ><hlopt|=
    ><hlkwc|StateM><hlopt|.><hlstd|run ><hlopt|(><hlstd|alpha<textunderscore>conv
    test><hlopt|) (><hlnum|5><hlopt|, []);;><hlendline|><next-line><hlopt|- :
    ><hlstd|term ><hlopt|* (><hlkwb|int ><hlopt|* (><hlkwb|string ><hlopt|*
    ><hlkwb|string><hlopt|) ><hlstd|list><hlopt|)
    =><hlendline|><next-line><hlopt|(><hlkwd|Lam
    ><hlopt|(><hlstr|"x5"><hlopt|, ><hlkwd|App ><hlopt|(><hlkwd|Lam
    ><hlopt|(><hlstr|"x6"><hlopt|, ><hlkwd|App ><hlopt|(><hlkwd|Var
    ><hlstr|"y"><hlopt|, ><hlkwd|Var ><hlstr|"x6"><hlopt|)), ><hlkwd|Var
    ><hlstr|"x5"><hlopt|)), (><hlnum|7><hlopt|, []))><hlendline|>

    <item>If we separated the reader monad and the state monad, we would
    avoid the lines:<next-line><hlstd| \ \ \ ><hlopt|(><hlstd|fresh'><hlopt|,
    ><hlstd|<textunderscore>><hlopt|) \<less\>--
    ><hlstd|get><hlopt|;><hlendline|Restoring the ``reader'' part
    <verbatim|env>><next-line><hlstd| \ \ \ put
    ><hlopt|(><hlstd|fresh'><hlopt|, ><hlstd|env><hlopt|);><hlendline|but
    preserving the ``state'' part <verbatim|fresh>.>

    <item>The elegant way is to define the monad locally:

    <hlkwa|let ><hlstd|alpha<textunderscore>conv t
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let module ><hlkwd|S
    ><hlopt|= ><hlkwd|StateM><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|(><hlkwa|struct type ><hlstd|t ><hlopt|= ><hlkwb|int
    ><hlopt|* (><hlkwb|string ><hlopt|* ><hlkwb|string><hlopt|) ><hlstd|list
    ><hlkwa|end><hlopt|) ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwa|let open ><hlkwd|S ><hlkwa|in><hlendline|><next-line><new-page*><hlstd|
    \ ><hlkwa|let rec ><hlstd|aux ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|Var ><hlstd|x ><hlkwa|as ><hlstd|v ><hlopt|-\<gtr\>
    ><hlkwa|perform><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|(><hlstd|fresh><hlopt|, ><hlstd|env><hlopt|) \<less\>--
    ><hlstd|get><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|let
    ><hlstd|v ><hlopt|= ><hlkwa|try ><hlkwd|Var
    ><hlopt|(><hlkwc|List><hlopt|.><hlstd|assoc x
    env><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|with
    ><hlkwd|Not<textunderscore>found ><hlopt|-\<gtr\> ><hlstd|v
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ return
    v<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|Lam
    ><hlopt|(><hlstd|x><hlopt|, ><hlstd|t><hlopt|) -\<gtr\>
    ><hlkwa|perform><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|(><hlstd|fresh><hlopt|, ><hlstd|env><hlopt|) \<less\>--
    ><hlstd|get><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|let
    ><hlstd|x' ><hlopt|= ><hlstd|x <textasciicircum>
    string<textunderscore>of<textunderscore>int fresh
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ put
    ><hlopt|(><hlstd|fresh><hlopt|+><hlnum|1><hlopt|, (><hlstd|x><hlopt|,
    ><hlstd|x'><hlopt|)::><hlstd|env><hlopt|);><hlendline|><next-line><hlstd|
    \ \ \ \ \ t' ><hlopt|\<less\>-- ><hlstd|aux
    t><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|(><hlstd|fresh'><hlopt|,
    ><hlstd|<textunderscore>><hlopt|) \<less\>--
    ><hlstd|get><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ put
    ><hlopt|(><hlstd|fresh'><hlopt|, ><hlstd|env><hlopt|);><hlendline|><next-line><hlstd|
    \ \ \ \ \ return ><hlopt|(><hlkwd|Lam ><hlopt|(><hlstd|x'><hlopt|,
    ><hlstd|t'><hlopt|))><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|App ><hlopt|(><hlstd|t1><hlopt|, ><hlstd|t2><hlopt|) -\<gtr\>
    ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ \ \ t1
    ><hlopt|\<less\>-- ><hlstd|aux t1><hlopt|; ><hlstd|t2 ><hlopt|\<less\>--
    ><hlstd|aux t2><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ return
    ><hlopt|(><hlkwd|App ><hlopt|(><hlstd|t1><hlopt|, ><hlstd|t2><hlopt|))
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlstd|run
    ><hlopt|(><hlstd|aux t><hlopt|) (><hlnum|0><hlopt|, [])><hlendline|>
  </itemize>

  <section|<new-page*>Monad transformers>

  <\itemize>
    <item>Based on: <hlink|http://lambda.jimpryor.net/monad_transformers/|http://lambda.jimpryor.net/monad_transformers/>

    <item>Sometimes we need merits of multiple monads at the same time, e.g.
    monads <hlkwc|AM> and <hlkwc|BM>.

    <item>Straightforwad idea is to nest one monad within another:

    <\itemize>
      <item>either <hlstd|'a ><hlkwc|AM><hlopt|.><hlstd|monad
      ><hlkwc|BM><hlopt|.><hlstd|monad>

      <item>or <hlstd|'a ><hlkwc|BM><hlopt|.><hlstd|monad
      ><hlkwc|AM><hlopt|.><hlstd|monad>.
    </itemize>

    <item>But we want a monad that has operations of both <hlkwc|AM> and
    <hlkwc|BM>.

    <item>It turns out that the straightforward approach does not lead to
    operations with the meaning we want.

    <item>A <em|monad transformer> <hlkwc|AT> takes a monad <hlkwc|BM> and
    turns it into a monad <hlkwc|AT<hlopt|(>BM<hlopt|)>> which actually wraps
    around <hlkwc|BM> on both sides. <hlkwc|AT<hlopt|(>BM<hlopt|)>> has
    operations of both monads.

    <new-page*><item>We will develop a monad transformer <hlkwc|StateT> which
    adds state to a monad-plus. The resulting monad has all:
    <verbatim|return>, <verbatim|bind>, <verbatim|mzero>, <verbatim|mplus>,
    <verbatim|put>, <verbatim|get> and their supporting general-purpose
    functions.

    <\itemize>
      <item>There is no reason for <hlkwc|StateT> not to provide state to any
      flavor of monads. Our restriction to monad-plus is because the
      type/module system makes more general solutions harder.
    </itemize>

    <item>We need monad transformers in OCaml because ``monads are
    conta<no-break>gious'': although we have built-in state and exceptions,
    we need to use monadic state and exceptions when we are inside a monad.

    <\itemize>
      <item>The reason <em|Lwt> is both a concurrency and an exception monad.
    </itemize>

    <item>Things get <em|interesting> when we have several monad
    transformers, e.g. <hlkwc|AT>, <hlkwc|BT>, ... We can compose them in
    various orders: <hlkwc|AT<hlopt|(>BT<hlopt|(>CM<hlopt|))>>,
    <hlkwc|BT<hlopt|(>AT<hlopt|(>CM<hlopt|))>>, ... achieving different
    results.

    <\itemize>
      <item>With a single trasformer, we will not get into issues with
      multiple-layer monads...

      <item>They are worth exploring -- especially if you plan a career
      around programming in Haskell.
    </itemize>

    <new-page*><item>The state monad, using <hlopt|(><hlkwa|fun ><hlstd|x
    ><hlopt|-\<gtr\> >...<hlopt|) ><hlstd|a> instead of <hlkwa|let ><hlstd|x
    ><hlopt|= ><hlstd|a ><hlkwa|in >...

    <hlkwa|type ><hlstd|'a state ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ store ><hlopt|-\<gtr\> (><hlstd|'a ><hlopt|*
    ><hlstd|store><hlopt|)><hlendline|>

    <hlkwa|let ><verbatim|return> <hlopt|(><hlstd|a ><hlopt|:
    ><hlstd|'a><hlopt|) : ><hlstd|'a state
    ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|fun ><hlstd|s
    ><hlopt|-\<gtr\> (><hlstd|a><hlopt|, ><hlstd|s><hlopt|)><hlendline|>

    <hlkwa|let ><hlstd|bind ><hlopt|(><hlstd|u ><hlopt|: ><hlstd|'a
    state><hlopt|) (><hlstd|f ><hlopt|: ><hlstd|'a ><hlopt|-\<gtr\>
    ><hlstd|'b state><hlopt|) : ><hlstd|'b state
    ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|fun ><hlstd|s
    ><hlopt|-\<gtr\> (><hlkwa|fun ><hlopt|(><hlstd|a><hlopt|,
    ><hlstd|s'><hlopt|) -\<gtr\> ><hlstd|f a s'><hlopt|) (><hlstd|u
    s><hlopt|)><hlendline|>

    <item>Monad <hlkwc|M> transformed to add state, in pseudo-code:

    <hlkwa|type ><hlstd|'a stateT><hlopt|(><hlkwd|M><hlopt|)
    =><hlendline|><next-line><hlstd| \ \ \ store ><hlopt|-\<gtr\> (><hlstd|'a
    ><hlopt|* ><hlstd|store><hlopt|) ><hlkwd|M><hlendline|><next-line><hlcom|(*
    notice this is not an ('a M) state *)><hlendline|>

    <hlkwa|let ><verbatim|return ><hlopt|(><hlstd|a ><hlopt|:
    ><hlstd|'a><hlopt|) : ><hlstd|'a stateT><hlopt|(><hlkwd|M><hlopt|)
    =><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|fun ><hlstd|s
    ><hlopt|-\<gtr\> ><hlkwc|M><hlopt|.><verbatim|return
    ><hlopt|(><hlstd|a><hlopt|, ><hlstd|s><hlopt|)><hlendline|>Rather than
    returning, M.return

    <hlkwa|let ><hlstd|bind><hlopt|(><hlstd|u><hlopt|:><hlstd|'a
    stateT><hlopt|(><hlkwd|M><hlopt|))(><hlstd|f><hlopt|:><hlstd|'a><hlopt|-\<gtr\>><hlstd|'b
    stateT><hlopt|(><hlkwd|M><hlopt|)):><hlstd|'b
    stateT><hlopt|(><hlkwd|M><hlopt|)=><next-line><hlstd| \ \ \ ><hlkwa|fun
    ><hlstd|s ><hlopt|-\<gtr\> ><hlkwc|M><hlopt|.><hlstd|bind
    ><hlopt|(><hlstd|u s><hlopt|) (><hlkwa|fun ><hlopt|(><hlstd|a><hlopt|,
    ><hlstd|s'><hlopt|) -\<gtr\> ><hlstd|f a
    s'><hlopt|)><hlendline|><next-line><hlendline|>Rather than let-binding,
    M.bind
  </itemize>

  <subsection|<new-page*>State transformer>

  <hlkwa|module ><hlkwd|StateT ><hlopt|(><hlkwd|MP ><hlopt|:
  ><hlkwd|MONAD<textunderscore>PLUS<textunderscore>OPS><hlopt|)
  (><hlkwd|Store ><hlopt|: ><hlkwa|sig type ><hlstd|t ><hlkwa|end><hlopt|) :
  ><hlkwa|sig><hlendline|Functor takes two modules -- the second
  one><next-line><hlstd| \ ><hlkwa|type ><hlstd|store ><hlopt|=
  ><hlkwc|Store><hlopt|.><verbatim|t><hlendline|provides only the storage
  type.><next-line><verbatim| \ ><hlkwa|type ><hlstd|'a t ><hlopt|=
  ><hlstd|store ><hlopt|-\<gtr\> (><hlstd|'a ><hlopt|* ><hlstd|store><hlopt|)
  ><hlkwc|MP><hlopt|.><hlstd|monad<hlendline|><next-line> \ ><hlkwa|include
  ><hlkwd|MONAD<textunderscore>PLUS<textunderscore>OPS><hlendline|Exporting
  all the monad-plus operations><next-line><hlstd| \ ><hlkwa|include
  ><hlkwd|STATE ><hlkwa|with type ><hlstd|'a t ><hlopt|:= ><verbatim|'a
  monad><hlendline|and state operations.><next-line><verbatim|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|and type ><hlstd|store ><hlopt|:=
  ><hlstd|store<hlendline|><next-line> \ ><hlkwa|val ><hlstd|run ><hlopt|:
  ><hlstd|'a monad ><hlopt|-\<gtr\> ><verbatim|'a t><hlendline|Expose ``what
  happened'' -- resulting states.><next-line><verbatim| \ ><hlkwa|val
  ><hlstd|runT ><hlopt|: ><hlstd|'a monad ><hlopt|-\<gtr\> ><hlstd|store
  ><hlopt|-\<gtr\> ><hlstd|'a ><hlkwc|MP><hlopt|.><hlstd|monad><hlendline|><next-line><hlkwa|end
  ><hlopt|= ><hlkwa|struct><hlendline|Run the state transformer -- get the
  resulting values.><next-line><hlstd| \ ><hlkwa|type ><hlstd|store ><hlopt|=
  ><hlkwc|Store><hlopt|.><verbatim|t><hlendline|>

  <new-page*><verbatim| \ ><hlkwa|module ><hlkwd|M ><hlopt|=
  ><hlkwa|struct><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|type ><hlstd|'a
  t ><hlopt|= ><hlstd|store ><hlopt|-\<gtr\> (><hlstd|'a ><hlopt|*
  ><hlstd|store><hlopt|) ><hlkwc|MP><hlopt|.><hlstd|monad<hlendline|><next-line>
  \ \ \ ><hlkwa|let ><hlstd|return a ><hlopt|= ><hlkwa|fun ><hlstd|s
  ><hlopt|-\<gtr\> ><hlkwc|MP><hlopt|.><hlstd|return
  ><hlopt|(><hlstd|a><hlopt|, ><hlstd|s><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|let ><hlstd|bind m b ><hlopt|= ><hlkwa|fun ><hlstd|s
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwc|MP><hlopt|.><hlstd|bind ><hlopt|(><hlstd|m s><hlopt|)
  (><hlkwa|fun ><hlopt|(><hlstd|a><hlopt|, ><hlstd|s'><hlopt|) -\<gtr\>
  ><hlstd|b a s'><hlopt|)><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
  ><hlstd|mzero ><hlopt|= ><hlkwa|fun ><hlstd|<textunderscore>
  ><hlopt|-\<gtr\> ><hlkwc|MP><hlopt|.><verbatim|mzero><hlendline|<em|Lift>
  the monad-plus operations.><next-line><verbatim| \ \ \ ><hlkwa|let
  ><hlstd|mplus ma mb ><hlopt|= ><hlkwa|fun ><hlstd|s ><hlopt|-\<gtr\>
  ><hlkwc|MP><hlopt|.><hlstd|mplus ><hlopt|(><hlstd|ma s><hlopt|) (><hlstd|mb
  s><hlopt|)><hlendline|><next-line><hlstd|
  \ ><hlkwa|end><hlendline|><next-line><hlstd| \ ><hlkwa|include
  ><hlkwd|M><hlendline|><next-line><hlstd| \ ><hlkwa|include
  ><hlkwd|MonadPlusOps><hlopt|(><hlkwd|M><hlopt|)><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|get ><hlopt|= ><hlkwa|fun ><hlstd|s ><hlopt|-\<gtr\>
  ><hlkwc|MP><hlopt|.><hlstd|return ><hlopt|(><hlstd|s><hlopt|,
  ><hlstd|s><hlopt|)><hlendline|Instead of just returning,><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|put s' ><hlopt|= ><hlkwa|fun ><hlstd|<textunderscore>
  ><hlopt|-\<gtr\> ><hlkwc|MP><hlopt|.><hlstd|return ><hlopt|((),
  ><hlstd|s'><hlopt|)><hlendline|MP.return.><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|runT m s ><hlopt|= ><hlkwc|MP><hlopt|.><hlstd|lift fst
  ><hlopt|(><hlstd|m s><hlopt|)><hlendline|><next-line><hlkwa|end><hlstd|
  \ \ \ ><hlendline|>

  <subsection|<new-page*>Backtracking with state>

  <hlkwa|module ><hlkwd|HoneyIslands ><hlopt|(><hlkwd|M ><hlopt|:
  ><hlkwd|MONAD<textunderscore>PLUS<textunderscore>OPS><hlopt|) =
  ><hlkwa|struct><hlendline|><next-line><hlkwa| \ type ><hlstd|state
  ><hlopt|= {><hlendline|For use with list monad or lazy list
  monad.><next-line><hlstd| \ \ \ been<textunderscore>size><hlopt|:
  ><hlkwb|int><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ been<textunderscore>islands><hlopt|:
  ><hlkwb|int><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ unvisited><hlopt|: ><hlstd|cell list><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ visited><hlopt|: ><hlkwc|CellSet><hlopt|.><hlstd|t><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ eaten><hlopt|: ><hlstd|cell list><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ more<textunderscore>to<textunderscore>eat><hlopt|:
  ><hlkwb|int><hlopt|;><hlendline|><next-line><hlstd|
  \ ><hlopt|}><hlendline|><next-line><hlstd|<hlendline|><next-line>
  \ ><hlkwa|let ><hlstd|init<textunderscore>state unvisited
  more<textunderscore>to<textunderscore>eat ><hlopt|=
  {><hlendline|><next-line><hlstd| \ \ \ been<textunderscore>size ><hlopt|=
  ><hlnum|0><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ been<textunderscore>islands ><hlopt|=
  ><hlnum|0><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ unvisited><hlopt|;><hlendline|><next-line><hlstd| \ \ \ visited
  ><hlopt|= ><hlkwc|CellSet><hlopt|.><hlstd|empty><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ eaten ><hlopt|= [];><hlendline|><next-line><hlstd|
  \ \ \ more<textunderscore>to<textunderscore>eat><hlopt|;><hlendline|><next-line><hlstd|
  \ ><hlopt|}><hlendline|>

  <new-page*><hlkwa| \ module ><hlkwd|BacktrackingM
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|StateT
  ><hlopt|(><hlkwd|M><hlopt|) (><hlkwa|struct type ><hlstd|t ><hlopt|=
  ><hlstd|state ><hlkwa|end><hlopt|)><hlendline|><next-line><hlstd|
  \ ><hlkwa|open ><hlkwd|BacktrackingM><hlendline|><next-line><hlstd|<hlendline|><next-line>
  \ ><hlkwa|let rec ><hlstd|visit<textunderscore>cell ><hlopt|() =
  ><hlkwa|perform><hlendline|State update actions.><next-line><hlstd|
  \ \ \ \ \ s ><hlopt|\<less\>-- ><hlstd|get><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|match ><hlstd|s><hlopt|.><hlstd|unvisited
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\| []
  -\<gtr\> ><hlstd|return ><hlkwd|None><hlendline|><next-line><hlstd|
  \ \ \ \ \ <hlopt|\|> c><hlopt|::><hlstd|remaining ><hlkwa|when
  ><hlkwc|CellSet><hlopt|.><hlstd|mem c s><hlopt|.><hlstd|visited
  ><hlopt|-\<gtr\> ><hlkwa|perform><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ put ><hlopt|{><hlstd|s ><hlkwa|with
  ><hlstd|unvisited><hlopt|=><hlstd|remaining><hlopt|};><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ visit<textunderscore>cell ><hlopt|()><hlendline|Throwaway
  argument because of recursion. See (*)><next-line><hlstd| \ \ \ <hlopt|\|>
  c><hlopt|::><hlstd|remaining ><hlcom|(* when c not visited *)><hlstd|
  ><hlopt|-\<gtr\> ><hlkwa|perform><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ put ><hlopt|{><hlstd|s ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ unvisited><hlopt|=><hlstd|remaining><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ visited ><hlopt|= ><hlkwc|CellSet><hlopt|.><hlstd|add c
  s><hlopt|.><hlstd|visited><hlopt|};><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ return ><hlopt|(><hlkwd|Some
  ><hlstd|c><hlopt|)><hlendline|This action returns a value.>

  <new-page*><hlkwa| \ let ><hlstd|eat<textunderscore>cell c ><hlopt|=
  ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ \ \ s
  ><hlopt|\<less\>-- ><hlstd|get><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ put ><hlopt|{><hlstd|s ><hlkwa|with ><hlstd|eaten ><hlopt|=
  ><hlstd|c><hlopt|::><hlstd|s><hlopt|.><hlstd|eaten><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ visited ><hlopt|= ><hlkwc|CellSet><hlopt|.><hlstd|add c
  s><hlopt|.><hlstd|visited><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ more<textunderscore>to<textunderscore>eat ><hlopt|=
  ><hlstd|s><hlopt|.><hlstd|more<textunderscore>to<textunderscore>eat
  ><hlopt|- ><hlnum|1><hlopt|};><hlendline|><next-line><hlstd|
  \ \ \ \ \ return ><hlopt|()><hlendline|Remaining state update actions just
  affect the state.><next-line><hlstd|<hlendline|><next-line> \ ><hlkwa|let
  ><hlstd|keep<textunderscore>cell c ><hlopt|=
  ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ \ \ s
  ><hlopt|\<less\>-- ><hlstd|get><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ put ><hlopt|{><hlstd|s ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ visited ><hlopt|= ><hlkwc|CellSet><hlopt|.><hlstd|add c
  s><hlopt|.><hlstd|visited><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ been<textunderscore>size ><hlopt|=
  ><hlstd|s><hlopt|.><hlstd|been<textunderscore>size ><hlopt|+
  ><hlnum|1><hlopt|};><hlendline|><next-line><hlstd| \ \ \ \ \ return
  ><hlopt|()><hlendline|><next-line><hlstd|<hlendline|><next-line>
  \ ><hlkwa|let ><hlstd|fresh<textunderscore>island ><hlopt|=
  ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ \ \ s
  ><hlopt|\<less\>-- ><hlstd|get><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ put ><hlopt|{><hlstd|s ><hlkwa|with
  ><hlstd|been<textunderscore>size ><hlopt|=
  ><hlnum|0><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ been<textunderscore>islands ><hlopt|=
  ><hlstd|s><hlopt|.><hlstd|been<textunderscore>islands ><hlopt|+
  ><hlnum|1><hlopt|};><hlendline|><next-line><hlstd| \ \ \ \ \ return
  ><hlopt|()><hlendline|>

  <new-page*><hlkwa| \ let ><hlstd|find<textunderscore>to<textunderscore>eat
  n island<textunderscore>size num<textunderscore>islands
  empty<textunderscore>cells ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|let ><hlstd|honey ><hlopt|=
  ><hlstd|honey<textunderscore>cells n empty<textunderscore>cells
  ><hlkwa|in><hlendline|><next-line><hlendline|OCaml does not realize that
  <verbatim|'a monad> with state is actually a function --><next-line>
  \ \ \ <hlkwa|let rec ><hlstd|find<textunderscore>board ><hlopt|() =
  ><hlkwa|perform><hlendline|it's an abstract type.(*)><next-line><hlstd|
  \ \ \ \ \ \ \ cell ><hlopt|\<less\>-- ><hlstd|visit<textunderscore>cell
  ><hlopt|();><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|match
  ><hlstd|cell ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|None ><hlopt|-\<gtr\>
  ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ \ \ \ s
  ><hlopt|\<less\>-- ><hlstd|get><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ guard ><hlopt|(><hlstd|s><hlopt|.><hlstd|been<textunderscore>islands
  ><hlopt|= ><hlstd|num<textunderscore>islands><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ return s><hlopt|.><hlstd|eaten<hlendline|><next-line>
  \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Some ><hlstd|cell ><hlopt|-\<gtr\>
  ><hlkwa|perform><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ fresh<textunderscore>island><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ find<textunderscore>island
  cell><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ \ \ \ s
  ><hlopt|\<less\>-- ><hlstd|get><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ guard ><hlopt|(><hlstd|s><hlopt|.><hlstd|been<textunderscore>size
  ><hlopt|= ><hlstd|island<textunderscore>size><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ find<textunderscore>board ><hlopt|()><hlendline|>

  <new-page*><hlkwa| \ \ \ and ><hlstd|find<textunderscore>island current
  ><hlopt|= ><hlkwa|perform><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ keep<textunderscore>cell current><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ neighbors n empty<textunderscore>cells
  current<hlendline|><next-line> \ \ \ \ \ \ \ <hlopt|\|>><hlopt|\<gtr\>
  ><verbatim|foldM><hlendline|The partial answer sits in the state --
  throwaway result.><next-line><verbatim|
  \ \ \ \ \ \ \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlopt|() ><hlstd|neighbor
  ><hlopt|-\<gtr\> ><hlkwa|perform><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ s ><hlopt|\<less\>--
  ><hlstd|get><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ whenM ><hlopt|(><hlstd|not
  ><hlopt|(><hlkwc|CellSet><hlopt|.><hlstd|mem neighbor
  s><hlopt|.><hlstd|visited><hlopt|))><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt|(><hlkwa|let
  ><hlstd|choose<textunderscore>eat ><hlopt|=
  ><hlkwa|perform><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ guard
  ><hlopt|(><hlstd|s><hlopt|.><hlstd|more<textunderscore>to<textunderscore>eat
  ><hlopt|\<gtr\> ><hlnum|0><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ eat<textunderscore>cell
  neighbor<hlendline|><next-line> \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|and
  ><hlstd|choose<textunderscore>keep ><hlopt|=
  ><hlkwa|perform><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ guard
  ><hlopt|(><hlstd|s><hlopt|.><hlstd|been<textunderscore>size
  ><hlopt|\<less\> ><hlstd|island<textunderscore>size><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ find<textunderscore>island
  neighbor ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ choose<textunderscore>eat ><hlopt|++
  ><hlstd|choose<textunderscore>keep><hlopt|)) () ><hlkwa|in><hlendline|>

  <new-page*><hlkwa| \ \ \ let ><hlstd|cells<textunderscore>to<textunderscore>eat
  ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwc|List><hlopt|.><hlstd|length honey ><hlopt|-
  ><hlstd|island<textunderscore>size ><hlopt|*
  ><hlstd|num<textunderscore>islands ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ init<textunderscore>state honey cells<textunderscore>to<textunderscore>eat<hlendline|><next-line>
  \ \ \ <hlopt|\|>><hlopt|\<gtr\> ><hlstd|runT
  ><hlopt|(><hlstd|find<textunderscore>board
  ><hlopt|())><hlendline|><next-line><hlendline|><next-line><hlkwa|end><hlendline|><next-line><hlendline|><next-line><hlkwa|module
  ><hlkwd|HoneyL ><hlopt|= ><hlkwd|HoneyIslands
  ><hlopt|(><hlkwd|ListM><hlopt|)><hlendline|><next-line><hlkwa|let
  ><hlstd|find<textunderscore>to<textunderscore>eat a b c d
  ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwc|ListM><hlopt|.><hlstd|run ><hlopt|(><hlkwc|HoneyL><hlopt|.><hlstd|find<textunderscore>to<textunderscore>eat
  a b c d><hlopt|)><hlendline|><next-line>

  <section|<new-page*>Probabilistic Programming>

  <\itemize>
    <item>Using a random number generator, we can define procedures that
    produce various output. This is <strong|not functional> -- mathematical
    functions have a deterministic result for fixed arguments.

    <item>Similarly to how we can ``simulate'' (mutable) variables with state
    monad and non-determinism (i.e. making choices) with list monad, we can
    ``simulate'' random computation with probability monad.

    <item>The probability monad class means much more than having randomized
    computation. We can ask questions about probabilities of results. Monad
    instances can make tradeoffs of efficiency vs. accuracy (exact vs.
    approximate probabilities).

    <item>Probability monad imposes limitations on what approximation
    algorithms can be implemented.

    <\itemize>
      <item>Efficient <em|probabilistic programming> library for OCaml, based
      on continuations, memoisation and reified search
      trees:<next-line><hlink|http://okmij.org/ftp/kakuritu/index.html|http://okmij.org/ftp/kakuritu/index.html>
    </itemize>
  </itemize>

  <subsection|<new-page*>The probability monad>

  <\itemize>
    <item>The essential functions for the probability monad class are
    <verbatim|choose> and <verbatim|distrib> -- remaining functions could be
    defined in terms of these but are provided by each instance for
    efficiency.

    <item>Inside-monad operations:

    <\itemize>
      <item><hlstd|choose ><hlopt|: ><hlkwb|float ><hlopt|-\<gtr\> ><hlstd|'a
      monad ><hlopt|-\<gtr\> ><hlstd|'a monad ><hlopt|-\<gtr\> ><hlstd|'a
      monad>

      <verbatim|choose p a b> represents an event or distribution which is
      <math|a> with probability <math|p> and is <math|b> with probability
      <math|1-p>.

      <item><hlkwa|val ><hlstd|pick ><hlopt|: (><hlstd|'a ><hlopt|*
      ><hlkwb|float><hlopt|) ><hlstd|list ><hlopt|-\<gtr\> ><hlstd|'a
      t><hlendline|>

      A result from the provided distribution over values. The argument must
      be a probability distribution: positive values summing to 1.

      <item><hlkwa|val ><hlstd|uniform ><hlopt|: ><hlstd|'a list
      ><hlopt|-\<gtr\> ><hlstd|'a monad><hlendline|>

      Uniform distribution over given values.

      <item><hlkwa|val ><hlstd|flip ><hlopt|: ><verbatim|><hlkwb|float
      <hlopt|-\<gtr\> >bool ><hlstd|monad><hlendline|>

      Equal to <verbatim|choose 0.5 (return true) (return false)>.

      <item><hlkwa|val ><hlstd|coin ><hlopt|: ><hlkwb|bool
      ><hlstd|monad><hlendline|Equal to <verbatim|flip 0.5>.>
    </itemize>

    <new-page*><item>And some operations for getting out of the monad:

    <\itemize>
      <item><hlkwa|val ><hlstd|prob ><hlopt|: (><hlstd|'a ><hlopt|-\<gtr\>
      ><hlkwb|bool><hlopt|) -\<gtr\> ><hlstd|'a monad ><hlopt|-\<gtr\>
      ><hlkwb|float><hlendline|>

      Returns the probability that the predicate holds.

      <item><hlkwa|val ><hlstd|distrib ><hlopt|: ><hlstd|'a monad
      ><hlopt|-\<gtr\> (><hlstd|'a ><hlopt|* ><hlkwb|float><hlopt|)
      ><hlstd|list><hlendline|>

      Returns the distribution of probabilities over the resulting values.

      <item><hlkwa|val ><hlstd|access <hlopt|:> 'a monad ><hlopt|-\<gtr\>
      ><hlstd|'a><hlendline|>

      Samples a <em|random> result from the distribution --
      <strong|non-functional> behavior.
    </itemize>

    <item>We give two instances of the probability monad: exact distribution
    monad, and sampling monad, which can approximate distributions.

    <\itemize>
      <item>The sampling monad is entirely non-functional: in Haskell, it
      lives in the IO monad.
    </itemize>

    <item>The monad instances indeed represent probability distributions:
    collections of positive numbers that add up to 1 -- although often
    <verbatim|merge> rather than <verbatim|normalize> is used. <small|If
    <verbatim|pick> and <verbatim|choose> are used correctly.>

    <new-page*><item><hlkwa|module type ><hlkwd|PROBABILITY ><hlopt|=
    ><hlkwa|sig><hlendline|Probability monad class.><next-line><hlstd|
    \ ><hlkwa|include ><hlkwd|MONAD<textunderscore>OPS><hlendline|><next-line><hlstd|
    \ ><hlkwa|val ><hlstd|choose ><hlopt|: ><hlkwb|float ><hlopt|-\<gtr\>
    ><hlstd|'a monad ><hlopt|-\<gtr\> ><hlstd|'a monad ><hlopt|-\<gtr\>
    ><hlstd|'a monad<hlendline|><next-line> \ ><hlkwa|val ><hlstd|pick
    ><hlopt|: (><hlstd|'a ><hlopt|* ><hlkwb|float><hlopt|) ><hlstd|list
    ><hlopt|-\<gtr\> ><verbatim|'a monad><hlendline|><next-line><hlstd|
    \ ><hlkwa|val ><hlstd|uniform ><hlopt|: ><hlstd|'a list ><hlopt|-\<gtr\>
    ><hlstd|'a monad><hlendline|><next-line><verbatim| \ ><hlkwa|val
    ><hlstd|coin ><hlopt|: ><hlkwb|bool ><hlstd|monad<hlendline|><next-line><hlstd|
    \ ><hlkwa|val ><hlstd|flip ><hlopt|: ><hlkwb|float ><hlopt|-\<gtr\>
    ><hlkwb|bool ><hlstd|monad><hlendline|><next-line> \ ><hlkwa|val
    ><hlstd|prob ><hlopt|: (><hlstd|'a ><hlopt|-\<gtr\> ><hlkwb|bool><hlopt|)
    -\<gtr\> ><hlstd|'a monad ><hlopt|-\<gtr\>
    ><hlkwb|float><hlendline|><next-line><hlstd| \ ><hlkwa|val
    ><hlstd|distrib ><hlopt|: ><hlstd|'a monad ><hlopt|-\<gtr\> (><hlstd|'a
    ><hlopt|* ><hlkwb|float><hlopt|) ><hlstd|list<hlendline|><next-line>
    \ ><hlkwa|val ><hlstd|access ><hlopt|: ><hlstd|'a monad ><hlopt|-\<gtr\>
    ><hlstd|'a><hlendline|><next-line><hlkwa|end><hlendline|>

    <new-page*><item><hlkwa|let ><hlstd|total dist
    ><hlopt|=><hlendline|Helper functions.><next-line><hlstd|
    \ ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left
    ><hlopt|(><hlkwa|fun ><hlstd|a ><hlopt|(><hlstd|<textunderscore>><hlopt|,><hlstd|b><hlopt|)-\<gtr\>><hlstd|a><hlopt|+.><hlstd|b><hlopt|)
    ><hlnum|0><hlopt|. ><hlstd|dist><hlendline|><next-line><hlkwa|let
    ><hlstd|merge dist ><hlopt|=><hlendline|Merge repeating
    elements.><next-line><hlstd| \ map<textunderscore>reduce
    ><hlopt|(><hlkwa|fun ><hlstd|x><hlopt|-\<gtr\>><hlstd|x><hlopt|) (+.)
    ><hlnum|0><hlopt|. ><hlstd|dist><hlendline|><next-line><hlkwa|let
    ><hlstd|normalize dist ><hlopt|= ><hlendline|Normalize a measure into a
    distribution.><next-line><hlstd| \ ><hlkwa|let ><hlstd|tot ><hlopt|=
    ><hlstd|total dist ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|if
    ><hlstd|tot ><hlopt|= ><hlnum|0><hlopt|. ><hlkwa|then
    ><hlstd|dist><hlendline|><next-line><hlstd| \ ><hlkwa|else
    ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
    ><hlopt|(><hlstd|e><hlopt|,><hlstd|w><hlopt|)-\<gtr\>><hlstd|e><hlopt|,><hlstd|w><hlopt|/.><hlstd|tot><hlopt|)
    ><hlstd|dist><hlendline|><next-line><hlkwa|let ><hlstd|roulette dist
    ><hlopt|=><hlendline|Roulette wheel from a
    distribution/measure.><next-line><hlstd| \ ><hlkwa|let ><hlstd|tot
    ><hlopt|= ><hlstd|total dist ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwa|let rec ><hlstd|aux r ><hlopt|= ><hlkwa|function ><hlopt|[]
    -\<gtr\> ><hlkwa|assert false><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|\| (><hlstd|e><hlopt|,><hlstd|w><hlopt|)::><hlstd|<textunderscore>
    ><hlkwa|when ><hlstd|w ><hlopt|\<less\>= ><hlstd|r ><hlopt|-\<gtr\>
    ><hlstd|e<hlendline|><next-line> \ \ \ ><hlopt|\|
    (><hlstd|<textunderscore>><hlopt|,><hlstd|w><hlopt|)::><hlstd|tl
    ><hlopt|-\<gtr\> ><hlstd|aux ><hlopt|(><hlstd|r><hlopt|-.><hlstd|w><hlopt|)
    ><hlstd|tl ><hlkwa|in><hlendline|><next-line><hlstd| \ aux
    ><hlopt|(><hlkwc|Random><hlopt|.><hlkwb|float ><hlstd|tot><hlopt|)
    ><hlstd|dist><hlendline|>

    <new-page*><item><hlkwa|module ><hlkwd|DistribM ><hlopt|:
    ><hlkwd|PROBABILITY ><hlopt|= ><hlkwa|struct><hlendline|><next-line><hlstd|
    \ ><hlkwa|module ><hlkwd|M ><hlopt|= ><hlkwa|struct><hlendline|Exact
    probability distribution -- naive implementation.><next-line><hlstd|
    \ \ \ ><hlkwa|type ><hlstd|'a t ><hlopt|= (><hlstd|'a ><hlopt|*
    ><hlkwb|float><hlopt|) ><hlstd|list<hlendline|><next-line>
    \ \ \ ><hlkwa|let ><hlstd|bind a b ><hlopt|=
    ><verbatim|merge><hlendline|<verbatim|x> w.p. <math|p> and then
    <verbatim|y> w.p. <math|q> happens =><verbatim|<next-line>
    \ \ \ \ \ ><hlopt|[><hlstd|y><hlopt|, ><hlstd|q><hlopt|*.><hlstd|p
    <hlopt|\|> ><hlopt|(><hlstd|x><hlopt|,><hlstd|p><hlopt|) \<less\>-
    ><hlstd|a><hlopt|; (><hlstd|y><hlopt|,><hlstd|q><hlopt|) \<less\>-
    ><hlstd|b x><hlopt|]><hlendline|<verbatim|y> results w.p. <math|p
    q>.><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|return a ><hlopt|=
    [><hlstd|a><hlopt|, ><hlnum|1><hlopt|.]><hlendline|Certainly
    <verbatim|a>.><next-line><hlstd| \ ><hlkwa|end><hlendline|><next-line><hlstd|
    \ ><hlkwa|include ><hlkwd|M ><hlkwa|include ><hlkwd|MonadOps
    ><hlopt|(><hlkwd|M><hlopt|)><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|choose p a b ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
    ><hlopt|(><hlstd|e><hlopt|,><hlstd|w><hlopt|) -\<gtr\> ><hlstd|e><hlopt|,
    ><hlstd|p><hlopt|*.><hlstd|w><hlopt|) ><hlstd|a @<hlendline|><next-line>
    \ \ \ \ \ ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
    ><hlopt|(><hlstd|e><hlopt|,><hlstd|w><hlopt|) -\<gtr\> ><hlstd|e><hlopt|,
    (><hlnum|1><hlopt|. -.><hlstd|p><hlopt|)*.><hlstd|w><hlopt|)
    ><hlstd|b<hlendline|><next-line> \ ><hlkwa|let ><hlstd|pick dist
    ><hlopt|= ><verbatim|dist><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|uniform elems ><hlopt|= ><hlstd|normalize<hlendline|><next-line>
    \ \ \ ><hlopt|(><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
    ><hlstd|e><hlopt|-\<gtr\>><hlstd|e><hlopt|,><hlnum|1><hlopt|.)
    ><hlstd|elems><hlopt|)><hlendline|><next-line><verbatim| \ ><hlkwa|let
    ><hlstd|coin ><hlopt|= [><hlkwa|true><hlopt|, ><hlnum|0.5><hlopt|;
    ><hlkwa|false><hlopt|, ><hlnum|0.5><hlopt|]><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|flip p ><hlopt|= [><hlkwa|true><hlopt|,
    ><hlstd|p><hlopt|; ><hlkwa|false><hlopt|, ><hlnum|1><hlopt|. -.
    ><hlstd|p><hlopt|]><hlendline|>

    <new-page*><hlstd| \ ><hlkwa|let ><hlstd|prob p m ><hlopt|=
    ><hlstd|m<hlendline|><next-line> \ \ \ <hlopt|\|>><hlopt|\<gtr\>
    ><hlkwc|List><hlopt|.><hlstd|filter ><hlopt|(><hlkwa|fun
    ><hlopt|(><hlstd|e><hlopt|,><hlstd|<textunderscore>><hlopt|) -\<gtr\>
    ><hlstd|p e><hlopt|)><hlendline|All cases where <verbatim|p>
    holds,><next-line><hlstd| \ \ \ <hlopt|\|>><hlopt|\<gtr\>
    ><hlkwc|List><hlopt|.><hlstd|map snd <hlopt|\|>><hlopt|\<gtr\>
    ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left ><hlopt|(+.)
    ><hlnum|0><hlopt|.><hlendline|add up.><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|distrib m ><hlopt|= ><hlstd|m<hlendline|><next-line>
    \ ><hlkwa|let ><hlstd|access m ><hlopt|= ><hlstd|roulette
    m><hlendline|><next-line><hlkwa|end><hlendline|>

    <new-page*><item><hlkwa|module ><hlkwd|SamplingM ><hlopt|(><hlkwd|S
    ><hlopt|: ><hlkwa|sig val ><hlstd|samples ><hlopt|: ><hlkwb|int
    ><hlkwa|end><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|:
    ><hlkwd|PROBABILITY ><hlopt|= ><hlkwa|struct><hlendline|Parameterized by
    how many samples><next-line><hlstd| \ ><hlkwa|module ><hlkwd|M ><hlopt|=
    ><hlkwa|struct><hlendline|used to approximate <verbatim|prob> or
    <verbatim|distrib>.><next-line><hlstd| \ \ \ ><hlkwa|type ><hlstd|'a t
    ><hlopt|= ><hlkwb|unit ><hlopt|-\<gtr\>
    ><verbatim|'a><hlendline|Randomized computation -- each call
    <hlstd|a><hlopt|()>><verbatim|<next-line> \ \ \ ><hlkwa|let ><hlstd|bind
    a b ><hlopt|() = ><hlstd|b ><hlopt|(><hlstd|a ><hlopt|()) ()><hlendline|
    is an independent sample.><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|return a ><hlopt|= ><hlkwa|fun ><hlopt|() -\<gtr\>
    ><verbatim|a><hlendline|Always <verbatim|a>.><verbatim|<next-line>
    \ ><hlkwa|end><hlendline|><next-line><hlstd| \ ><hlkwa|include ><hlkwd|M
    ><hlkwa|include ><hlkwd|MonadOps ><hlopt|(><hlkwd|M><hlopt|)><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|choose p a b ><hlopt|()
    =><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|if
    ><hlkwc|Random><hlopt|.><hlkwb|float ><hlnum|1><hlopt|. \<less\>=
    ><hlstd|p ><hlkwa|then ><hlstd|a ><hlopt|() ><hlkwa|else ><hlstd|b
    ><hlopt|()><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|pick dist
    ><hlopt|= ><hlkwa|fun ><hlopt|() -\<gtr\> ><verbatim|roulette
    dist><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|uniform elems
    ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|n
    ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|length elems
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|fun ><hlopt|()
    -\<gtr\> ><hlkwc|List><hlopt|.><hlstd|nth
    ><hlopt|(><hlkwc|Random><hlopt|.><hlkwb|int ><hlstd|n><hlopt|)
    ><hlstd|elems><hlendline|><next-line><verbatim| \ ><hlkwa|let
    ><hlstd|coin ><hlopt|= ><hlkwc|Random><hlopt|.><hlkwb|bool><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|flip p ><hlopt|= ><hlstd|choose p
    ><hlopt|(><hlstd|return ><hlkwa|true><hlopt|) (><hlstd|return
    ><hlkwa|false><hlopt|)><hlendline|>

    <new-page*><hlstd| \ ><hlkwa|let ><hlstd|prob p m
    ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|count
    ><hlopt|= ><hlkwb|ref ><hlnum|0 ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|for ><hlstd|i ><hlopt|= ><hlnum|1 ><hlkwa|to
    ><hlkwc|S><hlopt|.><hlstd|samples ><hlkwa|do><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|if ><hlstd|p ><hlopt|(><hlstd|m ><hlopt|())
    ><hlkwa|then ><hlstd|incr count<hlendline|><next-line>
    \ \ \ ><hlkwa|done><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ float<textunderscore>of<textunderscore>int ><hlopt|!><hlstd|count
    ><hlopt|/. ><hlstd|float<textunderscore>of<textunderscore>int
    ><hlkwc|S><hlopt|.><verbatim|samples><hlendline|><next-line><verbatim|
    \ ><hlkwa|let ><hlstd|distrib m ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|dist ><hlopt|= ><hlkwb|ref ><hlopt|[]
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|for ><hlstd|i
    ><hlopt|= ><hlnum|1 ><hlkwa|to ><hlkwc|S><hlopt|.><hlstd|samples
    ><hlkwa|do><hlendline|><next-line><hlstd| \ \ \ \ \ dist ><hlopt|:=
    (><hlstd|m ><hlopt|(), ><hlnum|1><hlopt|.) :: !><hlstd|dist
    ><hlkwa|done><hlopt|;><hlendline|><next-line><hlstd| \ \ \ normalize
    ><hlopt|(><verbatim|merge ><hlopt|!><hlstd|dist<hlopt|)><hlendline|><next-line>
    \ ><hlkwa|let ><hlstd|access m ><hlopt|= ><hlstd|m
    ><hlopt|()><hlendline|><next-line><hlkwa|end><hlendline|>
  </itemize>

  <subsection|<new-page*>Example: The Monty Hall problem>

  <\itemize>
    <item><hlink|http://en.wikipedia.org/wiki/Monty_Hall_problem|http://en.wikipedia.org/wiki/Monty_Hall_problem>:

    <\quotation>
      In search of a new car, the player picks a door, say 1. The game host
      then opens one of the other doors, say 3, to reveal a goat and offers
      to let the player pick door 2 instead of door 1.

      <image|Monty_open_door.eps|1.45w|||>
    </quotation>

    <new-page*><item><hlkwa|module ><hlkwd|MontyHall ><hlopt|(><hlkwd|P
    ><hlopt|: ><hlkwd|PROBABILITY><hlopt|) =
    ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|open
    ><hlkwd|P><hlendline|><next-line><hlstd| \ ><hlkwa|type ><hlstd|door
    ><hlopt|= ><hlkwd|A ><hlopt|\| ><hlkwd|B ><hlopt|\|
    ><hlkwd|C><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|doors
    ><hlopt|= [><hlkwd|A><hlopt|; ><hlkwd|B><hlopt|;
    ><hlkwd|C><hlopt|]><hlendline|>

    <hlkwa| \ let ><hlstd|monty<textunderscore>win switch ><hlopt|=
    ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ \ \ prize
    ><hlopt|\<less\>-- ><hlstd|uniform doors><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ \ \ chosen ><hlopt|\<less\>-- ><hlstd|uniform
    doors><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ opened
    ><hlopt|\<less\>-- ><hlstd|uniform<hlendline|><next-line>
    \ \ \ \ \ \ \ ><hlopt|(><hlstd|list<textunderscore>diff doors
    ><hlopt|[><hlstd|prize><hlopt|; ><hlstd|chosen><hlopt|]);><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|let ><hlstd|final ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwa|if ><hlstd|switch ><hlkwa|then
    ><hlkwc|List><hlopt|.><hlstd|hd<hlendline|><next-line>
    \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|list<textunderscore>diff doors
    ><hlopt|[><hlstd|opened><hlopt|; ><hlstd|chosen><hlopt|])><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwa|else ><hlstd|chosen
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ return
    ><hlopt|(><hlstd|final ><hlopt|= ><hlstd|prize><hlopt|)><hlendline|><next-line><hlkwa|end><hlendline|>

    <item><hlkwa|module ><hlkwd|MontyExact ><hlopt|= ><hlkwd|MontyHall
    ><hlopt|(><hlkwd|DistribM><hlopt|)><hlendline|><next-line><hlkwa|module
    ><hlkwd|Sampling1000 ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwd|SamplingM ><hlopt|(><hlkwa|struct let ><hlstd|samples ><hlopt|=
    ><hlnum|1000 ><hlkwa|end><hlopt|)><hlendline|><next-line><hlkwa|module
    ><hlkwd|MontySimul ><hlopt|= ><hlkwd|MontyHall
    ><hlopt|(><hlkwd|Sampling1000><hlopt|)><hlendline|>

    <new-page*><item><small|<hlstd|# ><hlkwa|let ><hlstd|t1 ><hlopt|=
    ><hlkwc|DistribM><hlopt|.><hlstd|distrib
    ><hlopt|(><hlkwc|MontyExact><hlopt|.><hlstd|monty<textunderscore>win
    ><hlkwa|false><hlopt|);;><hlendline|><next-line><hlkwa|val ><hlstd|t1
    ><hlopt|: (><hlkwb|bool ><hlopt|* ><hlkwb|float><hlopt|) ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[(><hlkwa|true><hlopt|, ><hlnum|0.333333333333333315><hlopt|);
    (><hlkwa|false><hlopt|, ><hlnum|0.66666666666666663><hlopt|)]><hlendline|><next-line><hlstd|#
    ><hlkwa|let ><hlstd|t2 ><hlopt|= ><hlkwc|DistribM><hlopt|.><hlstd|distrib
    ><hlopt|(><hlkwc|MontyExact><hlopt|.><hlstd|monty<textunderscore>win
    ><hlkwa|true><hlopt|);;><hlendline|><next-line><hlkwa|val ><hlstd|t2
    ><hlopt|: (><hlkwb|bool ><hlopt|* ><hlkwb|float><hlopt|) ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[(><hlkwa|true><hlopt|, ><hlnum|0.66666666666666663><hlopt|);
    (><hlkwa|false><hlopt|, ><hlnum|0.333333333333333315><hlopt|)]><hlendline|><next-line><hlstd|#
    ><hlkwa|let ><hlstd|t3 ><hlopt|= ><hlkwc|Sampling1000><hlopt|.><hlstd|distrib
    ><hlopt|(><hlkwc|MontySimul><hlopt|.><hlstd|monty<textunderscore>win
    ><hlkwa|false><hlopt|);;><hlendline|><next-line><hlkwa|val ><hlstd|t3
    ><hlopt|: (><hlkwb|bool ><hlopt|* ><hlkwb|float><hlopt|) ><hlstd|list
    ><hlopt|= [(><hlkwa|true><hlopt|, ><hlnum|0.313><hlopt|);
    (><hlkwa|false><hlopt|, ><hlnum|0.687><hlopt|)]><hlendline|><next-line><hlstd|#
    ><hlkwa|let ><hlstd|t4 ><hlopt|= ><hlkwc|Sampling1000><hlopt|.><hlstd|distrib
    ><hlopt|(><hlkwc|MontySimul><hlopt|.><hlstd|monty<textunderscore>win
    ><hlkwa|true><hlopt|);;><hlendline|><next-line><hlkwa|val ><hlstd|t4
    ><hlopt|: (><hlkwb|bool ><hlopt|* ><hlkwb|float><hlopt|) ><hlstd|list
    ><hlopt|= [(><hlkwa|true><hlopt|, ><hlnum|0.655><hlopt|);
    (><hlkwa|false><hlopt|, ><hlnum|0.345><hlopt|)]><hlendline|>>
  </itemize>

  <subsection|<new-page*>Conditional probabilities>

  <\itemize>
    <item>Wouldn't it be nice to have a monad-plus rather than a monad?

    <item>We could use <verbatim|guard> -- conditional probabilities!

    <\itemize>
      <item><math|P<around*|(|A\|B|)>>

      <\itemize>
        <item>Compute what is needed for both <math|A> and <math|B>.

        <item>Guard <math|B>.

        <item>Return <math|A>.
      </itemize>
    </itemize>

    <item>For the exact distribution monad it turns out very easy -- we just
    need to allow intermediate distributions to be unnormalized (sum to less
    than 1).

    <item>For the sampling monad we use rejection sampling.

    <\itemize>
      <item><verbatim|mplus> has no straightforward correct implementation.
    </itemize>

    <item>We implemented <hlkwd|PROBABILITY> separately for educational
    purposes only, as <hlkwd|COND_PROBAB> introduced below supersedes it.

    <new-page*><item><hlkwa|module type ><hlkwd|COND<textunderscore>PROBAB
    ><hlopt|= ><hlkwa|sig><hlendline|Class for conditional probability
    monad,><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|PROBABILITY><hlendline|where <verbatim|guard cond> conditions on
    <verbatim|cond>.><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|MONAD<textunderscore>PLUS<textunderscore>OPS ><hlkwa|with type
    ><hlstd|'a monad ><hlopt|:= ><hlstd|'a
    monad><hlendline|><next-line><hlkwa|end><hlendline|>

    <item><hlkwa|module ><hlkwd|DistribMP ><hlopt|:
    ><hlkwd|COND<textunderscore>PROBAB ><hlopt|=
    ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|module ><hlkwd|MP
    ><hlopt|= ><hlkwa|struct><hlendline|The measures no longer restricted
    to><next-line><hlstd| \ \ \ ><hlkwa|type ><hlstd|'a t ><hlopt|=
    (><hlstd|'a ><hlopt|* ><hlkwb|float><hlopt|)
    ><verbatim|list><hlendline|probability distributions:><next-line>
    \ \ \ <hlkwa|let ><hlstd|bind a b ><hlopt|=
    ><hlstd|merge<hlendline|><next-line> \ \ \ \ \ ><hlopt|[><hlstd|y><hlopt|,
    ><hlstd|q><hlopt|*.><hlstd|p <hlopt|\|>
    ><hlopt|(><hlstd|x><hlopt|,><hlstd|p><hlopt|) \<less\>-
    ><hlstd|a><hlopt|; (><hlstd|y><hlopt|,><hlstd|q><hlopt|) \<less\>-
    ><hlstd|b x><hlopt|]><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|return a ><hlopt|= [><hlstd|a><hlopt|,
    ><hlnum|1><hlopt|.]><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|mzero ><hlopt|= []><hlendline|Measure equal 0 everywhere is
    OK.><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|mplus ><hlopt|=
    ><hlkwc|List><hlopt|.><hlstd|append<hlendline|><next-line>
    \ ><hlkwa|end><hlendline|><next-line><hlstd| \ ><hlkwa|include ><hlkwd|MP
    ><hlkwa|include ><hlkwd|MonadPlusOps ><hlopt|(><hlkwd|MP><hlopt|)><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|choose p a b ><hlopt|=><hlendline|It isn't
    <verbatim|a> w.p. <math|p> & <verbatim|b> w.p. <math|<around*|(|1-p|)>>
    since <verbatim|a> and <verbatim|b>><next-line><hlstd|
    \ \ \ ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
    ><hlopt|(><hlstd|e><hlopt|,><hlstd|w><hlopt|) -\<gtr\> ><hlstd|e><hlopt|,
    ><hlstd|p><hlopt|*.><hlstd|w><hlopt|) ><hlstd|a ><hlopt|@><hlendline|are
    not normalized!><next-line><verbatim|
    \ \ \ \ \ ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
    ><hlopt|(><hlstd|e><hlopt|,><hlstd|w><hlopt|) -\<gtr\> ><hlstd|e><hlopt|,
    (><hlnum|1><hlopt|. -.><hlstd|p><hlopt|)*.><hlstd|w><hlopt|)
    ><hlstd|b><next-line><hlstd| \ ><hlkwa|let ><hlstd|pick dist ><hlopt|=
    ><verbatim|dist><hlendline|>

    <new-page*><verbatim| \ ><hlkwa|let ><hlstd|uniform elems ><hlopt|=
    ><hlstd|normalize<hlendline|><next-line>
    \ \ \ ><hlopt|(><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
    ><hlstd|e><hlopt|-\<gtr\>><hlstd|e><hlopt|,><hlnum|1><hlopt|.)
    ><hlstd|elems><hlopt|)><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|coin ><hlopt|= [><hlkwa|true><hlopt|, ><hlnum|0.5><hlopt|;
    ><hlkwa|false><hlopt|, ><hlnum|0.5><hlopt|]><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|flip p ><hlopt|= [><hlkwa|true><hlopt|,
    ><hlstd|p><hlopt|; ><hlkwa|false><hlopt|, ><hlnum|1><hlopt|. -.
    ><hlstd|p><hlopt|]><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|prob p m ><hlopt|= ><verbatim|normalize m><hlendline|Final
    normalization step.><next-line><verbatim| \ \ \ ><hlopt|\|><hlopt|\<gtr\>
    ><hlkwc|List><hlopt|.><hlstd|filter ><hlopt|(><hlkwa|fun
    ><hlopt|(><hlstd|e><hlopt|,><hlstd|<textunderscore>><hlopt|) -\<gtr\>
    ><hlstd|p e><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ <hlopt|\|>><hlopt|\<gtr\> ><hlkwc|List><hlopt|.><hlstd|map snd
    <hlopt|\|>><hlopt|\<gtr\> ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left
    ><hlopt|(+.) ><hlnum|0><hlopt|.><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|distrib m ><hlopt|= ><hlstd|normalize
    m<hlendline|><next-line> \ ><hlkwa|let ><hlstd|access m ><hlopt|=
    ><hlstd|roulette m><hlendline|><next-line><hlkwa|end><hlendline|>

    <new-page*><item>We write the rejection sampler in mostly imperative
    style:

    <hlkwa|module ><hlkwd|SamplingMP ><hlopt|(><hlkwd|S ><hlopt|: ><hlkwa|sig
    val ><hlstd|samples ><hlopt|: ><hlkwb|int
    ><hlkwa|end><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|:
    ><hlkwd|COND<textunderscore>PROBAB ><hlopt|=
    ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|exception
    ><hlkwd|Rejected><hlendline|For rejecting current
    sample.><next-line><hlstd| \ ><hlkwa|module ><hlkwd|MP ><hlopt|=
    ><hlkwa|struct><hlendline|Monad operations are exactly as for
    <hlkwd|SamplingM>><next-line><hlstd| \ \ \ ><hlkwa|type ><hlstd|'a t
    ><hlopt|= ><hlkwb|unit ><hlopt|-\<gtr\> ><hlstd|'a<hlendline|><next-line>
    \ \ \ ><hlkwa|let ><hlstd|bind a b ><hlopt|() = ><hlstd|b
    ><hlopt|(><hlstd|a ><hlopt|()) ()><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|return a ><hlopt|= ><hlkwa|fun ><hlopt|()
    -\<gtr\> ><verbatim|a><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|mzero ><hlopt|= ><hlkwa|fun ><hlopt|() -\<gtr\> ><hlstd|raise
    ><hlkwd|Rejected><hlendline|but now we can
    <verbatim|fail>.><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|mplus a b
    ><hlopt|= ><hlkwa|fun ><hlopt|() -\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ failwith ><hlstr|"SamplingMP.mplus not
    implemented"><hlstd|<hlendline|><next-line>
    \ ><hlkwa|end><hlendline|><next-line><hlstd| \ ><hlkwa|include ><hlkwd|MP
    ><hlkwa|include ><hlkwd|MonadPlusOps ><hlopt|(><hlkwd|MP><hlopt|)><hlendline|>

    <new-page*><hlstd| \ ><hlkwa|let ><hlstd|choose p a b ><hlopt|()
    =><hlendline|Inside-monad operations don't change.><next-line><hlstd|
    \ \ \ ><hlkwa|if ><hlkwc|Random><hlopt|.><hlkwb|float ><hlnum|1><hlopt|.
    \<less\>= ><hlstd|p ><hlkwa|then ><hlstd|a ><hlopt|() ><hlkwa|else
    ><hlstd|b ><hlopt|()><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|pick dist ><hlopt|= ><hlkwa|fun ><hlopt|() -\<gtr\>
    ><verbatim|roulette dist><hlendline|><next-line><verbatim| \ ><hlkwa|let
    ><hlstd|uniform elems ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|n ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|length
    elems ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|fun
    ><hlopt|() -\<gtr\> ><hlkwc|List><hlopt|.><hlstd|nth elems
    ><hlopt|(><hlkwc|Random><hlopt|.><hlkwb|int
    ><hlstd|n><hlopt|)><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|coin ><hlopt|= ><hlkwc|Random><hlopt|.><hlkwb|bool><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|flip p ><hlopt|= ><hlstd|choose p
    ><hlopt|(><hlstd|return ><hlkwa|true><hlopt|) (><hlstd|return
    ><hlkwa|false><hlopt|)><hlendline|>

    <hlstd| \ ><hlkwa|let ><hlstd|prob p m ><hlopt|=><hlendline|Getting out
    of monad: handle rejected samples.><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|count ><hlopt|= ><hlkwb|ref ><hlnum|0 ><hlkwa|and ><hlstd|tot
    ><hlopt|= ><hlkwb|ref ><hlnum|0 ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|while ><hlopt|!><hlstd|tot ><hlopt|\<less\>
    ><hlkwc|S><hlopt|.><hlstd|samples ><hlkwa|do><hlendline|Count up to the
    required><next-line><hlstd| \ \ \ \ \ ><hlkwa|try><hlendline|number of
    samples.><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|if ><hlstd|p
    ><hlopt|(><hlstd|m ><hlopt|()) ><hlkwa|then ><hlstd|incr
    count><hlopt|;><hlendline|<hlstd|m><hlopt|()> can
    fail.><next-line><verbatim| \ \ \ \ \ \ \ incr tot><hlendline|But if we
    got here it hasn't.><next-line><verbatim| \ \ \ \ \ ><hlkwa|with
    ><hlkwd|Rejected ><hlopt|-\<gtr\> ()><hlendline|Rejected, keep
    sampling.><next-line><hlstd| \ \ \ ><hlkwa|done><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ float<textunderscore>of<textunderscore>int ><hlopt|!><hlstd|count
    ><hlopt|/. ><hlstd|float<textunderscore>of<textunderscore>int
    ><hlkwc|S><hlopt|.><verbatim|samples><hlendline|>

    <new-page*><verbatim| \ ><hlkwa|let ><hlstd|distrib m
    ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|dist
    ><hlopt|= ><hlkwb|ref ><hlopt|[] ><hlkwa|and ><hlstd|tot ><hlopt|=
    ><hlkwb|ref ><hlnum|0 ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|while ><hlopt|!><hlstd|tot ><hlopt|\<less\>
    ><hlkwc|S><hlopt|.><hlstd|samples ><hlkwa|do><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|try><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ dist
    ><hlopt|:= (><hlstd|m ><hlopt|(), ><hlnum|1><hlopt|.) ::
    !><hlstd|dist><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ incr
    tot<hlendline|><next-line> \ \ \ \ \ ><hlkwa|with ><hlkwd|Rejected
    ><hlopt|-\<gtr\> ()><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|done><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ normalize ><hlopt|(><hlstd|merge
    ><hlopt|!><hlstd|dist><hlopt|)><hlendline|><next-line><hlstd|
    \ ><hlkwa|let rec ><hlstd|access m ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|try ><hlstd|m ><hlopt|() ><hlkwa|with ><hlkwd|Rejected
    ><hlopt|-\<gtr\> ><hlstd|access m><hlendline|><next-line><hlkwa|end><hlendline|>
  </itemize>

  <subsection|<new-page*>Burglary example: encoding a Bayes net>

  <\itemize>
    <item>We're faced with a problem with the following dependency structure:

    <draw-over|<tabular|<tformat|<cwith|7|7|6|6|cell-halign|l>|<cwith|3|3|2|2|cell-halign|r>|<cwith|1|1|2|2|cell-halign|r>|<cwith|7|7|2|2|cell-halign|r>|<table|<row|<cell|>|<cell|<block|<tformat|<table|<row|<cell|<math|P<around*|(|B|)>>>>|<row|<cell|<math|0.001>>>>>>>|<cell|>|<cell|>|<cell|>|<cell|<block|<tformat|<table|<row|<cell|<math|P<around*|(|E|)>>>>|<row|<cell|<math|0.002>>>>>>>|<cell|>>|<row|<cell|>|<cell|>|<cell|>|<cell|>|<cell|>|<cell|>|<cell|>>|<row|<cell|>|<cell|Burglary>|<cell|>|<cell|>|<cell|>|<cell|Earthquake>|<cell|>>|<row|<cell|>|<cell|>|<cell|>|<cell|>|<cell|>|<cell|>|<cell|>>|<row|<cell|>|<cell|>|<cell|>|<cell|Alarm>|<cell|>|<cell|>|<cell|<block|<tformat|<table|<row|<cell|<math|B>>|<cell|<math|E>>|<cell|<math|P<around*|(|A\|B,E|)>>>>|<row|<cell|F>|<cell|F>|<cell|<math|0.001>>>|<row|<cell|F>|<cell|T>|<cell|<math|0.29>>>|<row|<cell|T>|<cell|F>|<cell|<math|0.94>>>|<row|<cell|T>|<cell|T>|<cell|<math|0.95>>>>>>>>|<row|<cell|>|<cell|>|<cell|>|<cell|>|<cell|>|<cell|>|<cell|>>|<row|<cell|<block|<tformat|<table|<row|<cell|<math|A>>|<cell|<math|P<around*|(|J\|A|)>>>>|<row|<cell|F>|<cell|<math|0.05>>>|<row|<cell|T>|<cell|<math|0.9>>>>>>>|<cell|John
    calls>|<cell|>|<cell|>|<cell|>|<cell|Mary
    calls>|<cell|<block|<tformat|<table|<row|<cell|<math|A>>|<cell|<math|P<around*|(|M\|A|)>>>>|<row|<cell|F>|<cell|<math|0.01>>>|<row|<cell|T>|<cell|<math|0.7>>>>>>>>>>>|<with|gr-color|dark
    orange|gr-mode|<tuple|edit|line>|gr-arrow-end|\|\<gtr\>|gr-line-width|2ln|<graphics|<with|color|red|<carc|<point|-5.52538|3.15826>|<point|-3.0488655906866|3.17942188120122>|<point|-3.13353287471888|2.73491864003175>>>|<with|color|red|<carc|<point|-2.11753|-0.376604>|<point|-0.297178859637518|-0.418937690170658>|<point|-0.318345680645588|-0.228436301098029>>>|<with|color|red|<carc|<point|-5.82172|-4.9063>|<point|-2.98536512766239|-4.90630374388147>|<point|-3.64153657891255|-6.02814525730917>>>|<with|color|red|<carc|<point|0.570661|-4.86397>|<point|3.63984984786347|-4.90630374388147>|<point|2.85667747056489|-6.09164572033338>>>|<with|color|red|<carc|<point|0.739995|3.15826>|<point|3.68218348987961|3.09475459716894>|<point|3.51284892181505|2.50208360894298>>>|<with|color|dark
    orange|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-3.34695|2.3791>|<point|-1.79045436394757|0.276461491447145>>>|<with|color|dark
    orange|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|0.976479|2.39298>|<point|-0.681982790138585|0.319857839429467>>>|<with|color|dark
    orange|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-1.87545|-1.04339>|<point|-3.6026998120943|-3.65669671517365>>>|<with|color|dark
    orange|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-0.55984|-1.06362>|<point|1.16004444583979|-3.52932916190852>>>>>>

    <\itemize>
      <new-page*><item>Alarm can be due to either a burglary or an
      earthquake.

      <item>I've left on vacations.

      <item>I've asked neighbors John and Mary to call me if the alarm rings.

      <item>Mary only calls when she is really sure about the alarm, but John
      has better hearing.

      <item>Earthquakes are twice as probable as burglaries.

      <item>The alarm has about 30% chance of going off during earthquake.

      <item>I can check on the radio if there was an earthquake, but I might
      miss the news.
    </itemize>

    <new-page*><item><hlkwa|module ><hlkwd|Burglary ><hlopt|(><hlkwd|P
    ><hlopt|: ><hlkwd|COND<textunderscore>PROBAB><hlopt|) =
    ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|open
    ><hlkwd|P><hlendline|><next-line><hlstd| \ ><hlkwa|type
    ><hlstd|what<textunderscore>happened ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwd|Safe ><hlopt|\| ><hlkwd|Burgl ><hlopt|\| ><hlkwd|Earthq
    ><hlopt|\| ><hlkwd|Burgl<textunderscore>n<textunderscore>earthq><hlendline|>

    <verbatim| \ ><hlkwa|let ><hlstd|check
    <math|\<sim\>>john<textunderscore>called
    <math|\<sim\>>mary<textunderscore>called <math|\<sim\>>radio ><hlopt|=
    ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ earthquake
    ><hlopt|\<less\>-- ><hlstd|flip ><hlnum|0.002><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ guard ><hlopt|(><hlstd|radio ><hlopt|= ><hlkwd|None
    ><hlstd|<hlopt|\|\|> radio ><hlopt|= ><hlkwd|Some
    ><hlstd|earthquake><hlopt|);><hlendline|><next-line><hlstd|
    \ \ \ burglary ><hlopt|\<less\>-- ><hlstd|flip
    ><hlnum|0.001><hlopt|;><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|alarm<textunderscore>p ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|match ><hlstd|burglary><hlopt|, ><hlstd|earthquake
    ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
    ><hlkwa|false><hlopt|, ><hlkwa|false ><hlopt|-\<gtr\>
    ><hlnum|0.001><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
    ><hlkwa|false><hlopt|, ><hlkwa|true ><hlopt|-\<gtr\>
    ><hlnum|0.29><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
    ><hlkwa|true><hlopt|, ><hlkwa|false ><hlopt|-\<gtr\>
    ><hlnum|0.94><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
    ><hlkwa|true><hlopt|, ><hlkwa|true ><hlopt|-\<gtr\> ><hlnum|0.95
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ alarm ><hlopt|\<less\>--
    ><hlstd|flip alarm<textunderscore>p><hlopt|;><hlendline|>

    <new-page*><hlstd| \ \ \ ><hlkwa|let ><hlstd|john<textunderscore>p
    ><hlopt|= ><hlkwa|if ><hlstd|alarm ><hlkwa|then ><hlnum|0.9 ><hlkwa|else
    ><hlnum|0.05 ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ john<textunderscore>calls ><hlopt|\<less\>-- ><hlstd|flip
    john<textunderscore>p><hlopt|;><hlendline|><next-line><hlstd| \ \ \ guard
    ><hlopt|(><hlstd|john<textunderscore>calls ><hlopt|=
    ><hlstd|john<textunderscore>called><hlopt|);><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|mary<textunderscore>p ><hlopt|= ><hlkwa|if
    ><hlstd|alarm ><hlkwa|then ><hlnum|0.7 ><hlkwa|else ><hlnum|0.01
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ mary<textunderscore>calls
    ><hlopt|\<less\>-- ><hlstd|flip mary<textunderscore>p><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ guard ><hlopt|(><hlstd|mary<textunderscore>calls ><hlopt|=
    ><hlstd|mary<textunderscore>called><hlopt|);><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|match ><hlstd|burglary><hlopt|, ><hlstd|earthquake
    ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwa|false><hlopt|, ><hlkwa|false ><hlopt|-\<gtr\> ><hlstd|return
    ><hlkwd|Safe><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwa|true><hlopt|, ><hlkwa|false ><hlopt|-\<gtr\> ><hlstd|return
    ><hlkwd|Burgl><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwa|false><hlopt|, ><hlkwa|true ><hlopt|-\<gtr\> ><hlstd|return
    ><hlkwd|Earthq><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwa|true><hlopt|, ><hlkwa|true ><hlopt|-\<gtr\> ><hlstd|return
    ><hlkwd|Burgl<textunderscore>n<textunderscore>earthq><hlendline|><next-line><hlkwa|end><hlendline|>

    <item><hlkwa|module ><hlkwd|BurglaryExact ><hlopt|= ><hlkwd|Burglary
    ><hlopt|(><hlkwd|DistribMP><hlopt|)><hlendline|><next-line><hlkwa|module
    ><hlkwd|Sampling2000 ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwd|SamplingMP ><hlopt|(><hlkwa|struct let ><hlstd|samples
    ><hlopt|= ><hlnum|2000 ><hlkwa|end><hlopt|)><hlendline|><next-line><hlkwa|module
    ><hlkwd|BurglarySimul ><hlopt|= ><hlkwd|Burglary
    ><hlopt|(><hlkwd|Sampling2000><hlopt|)><hlendline|>
  </itemize>

  <new-page>

  <\very-small>
    <hlstd|# ><hlkwa|let ><hlstd|t1 ><hlopt|=
    ><hlkwc|DistribMP><hlopt|.><hlstd|distrib<hlendline|><next-line>
    \ ><hlopt|(><hlkwc|BurglaryExact><hlopt|.><hlstd|check
    <math|\<sim\>>john<textunderscore>called><hlopt|:><hlkwa|true
    ><hlstd|<math|\<sim\>>mary<textunderscore>called><hlopt|:><hlkwa|false><hlendline|><next-line><hlstd|
    \ \ \ \ <math|\<sim\>>radio><hlopt|:><hlkwd|None><hlopt|);;><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|val ><hlstd|t1 ><hlopt|:
    (><hlkwc|BurglaryExact><hlopt|.><hlstd|what<textunderscore>happened
    ><hlopt|* ><hlkwb|float><hlopt|) ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[(><hlkwc|BurglaryExact><hlopt|.><hlkwd|Burgl<textunderscore>n<textunderscore>earthq><hlopt|,
    ><hlnum|1.03476433660005444e-05><hlopt|);><hlendline|><next-line><hlstd|
    \ \ ><hlopt|(><hlkwc|BurglaryExact><hlopt|.><hlkwd|Earthq><hlopt|,
    ><hlnum|0.00452829235738691407><hlopt|);><hlendline|><next-line><hlstd|
    \ \ ><hlopt|(><hlkwc|BurglaryExact><hlopt|.><hlkwd|Burgl><hlopt|,
    ><hlnum|0.00511951049003530299><hlopt|);><hlendline|><next-line><hlstd|
    \ \ ><hlopt|(><hlkwc|BurglaryExact><hlopt|.><hlkwd|Safe><hlopt|,
    ><hlnum|0.99034184950921178><hlopt|)]><hlendline|><next-line><hlstd|#
    ><hlkwa|let ><hlstd|t2 ><hlopt|= ><hlkwc|DistribMP><hlopt|.><hlstd|distrib<hlendline|><next-line>
    \ ><hlopt|(><hlkwc|BurglaryExact><hlopt|.><hlstd|check
    <math|\<sim\>>john<textunderscore>called><hlopt|:><hlkwa|true
    ><hlstd|<math|\<sim\>>mary<textunderscore>called><hlopt|:><hlkwa|true><hlendline|><next-line><hlstd|
    \ \ \ \ <math|\<sim\>>radio><hlopt|:><hlkwd|None><hlopt|);;><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|val ><hlstd|t2 ><hlopt|:
    (><hlkwc|BurglaryExact><hlopt|.><hlstd|what<textunderscore>happened
    ><hlopt|* ><hlkwb|float><hlopt|) ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[(><hlkwc|BurglaryExact><hlopt|.><hlkwd|Burgl<textunderscore>n<textunderscore>earthq><hlopt|,
    ><hlnum|0.00057437256500405794><hlopt|);><hlendline|><next-line><hlstd|
    \ \ ><hlopt|(><hlkwc|BurglaryExact><hlopt|.><hlkwd|Earthq><hlopt|,
    ><hlnum|0.175492465840075218><hlopt|);><hlendline|><next-line><hlstd|
    \ \ ><hlopt|(><hlkwc|BurglaryExact><hlopt|.><hlkwd|Burgl><hlopt|,
    ><hlnum|0.283597462799388911><hlopt|);><hlendline|><next-line><hlstd|
    \ \ ><hlopt|(><hlkwc|BurglaryExact><hlopt|.><hlkwd|Safe><hlopt|,
    ><hlnum|0.540335698795532><hlopt|)]><hlendline|><next-line><hlstd|#
    ><hlkwa|let ><hlstd|t3 ><hlopt|= ><hlkwc|DistribMP><hlopt|.><hlstd|distrib<hlendline|><next-line>
    \ ><hlopt|(><hlkwc|BurglaryExact><hlopt|.><hlstd|check
    <math|\<sim\>>john<textunderscore>called><hlopt|:><hlkwa|true
    ><hlstd|<math|\<sim\>>mary<textunderscore>called><hlopt|:><hlkwa|true><hlendline|><next-line><hlstd|
    \ \ \ \ <math|\<sim\>>radio><hlopt|:(><hlkwd|Some
    ><hlkwa|true><hlopt|));;><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|val
    ><hlstd|t3 ><hlopt|: (><hlkwc|BurglaryExact><hlopt|.><hlstd|what<textunderscore>happened
    ><hlopt|* ><hlkwb|float><hlopt|) ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[(><hlkwc|BurglaryExact><hlopt|.><hlkwd|Burgl<textunderscore>n<textunderscore>earthq><hlopt|,
    ><hlnum|0.0032622416021499262><hlopt|);><hlendline|><next-line><hlstd|
    \ \ ><hlopt|(><hlkwc|BurglaryExact><hlopt|.><hlkwd|Earthq><hlopt|,
    ><hlnum|0.99673775839785006><hlopt|)]><hlendline|>

    <new-page*><hlstd|# ><hlkwa|let ><hlstd|t4 ><hlopt|=
    ><hlkwc|Sampling2000><hlopt|.><hlstd|distrib<hlendline|><next-line>
    \ ><hlopt|(><hlkwc|BurglarySimul><hlopt|.><hlstd|check
    <math|\<sim\>>john<textunderscore>called><hlopt|:><hlkwa|true
    ><hlstd|<math|\<sim\>>mary<textunderscore>called><hlopt|:><hlkwa|false><hlendline|><next-line><hlstd|
    \ \ \ \ <math|\<sim\>>radio><hlopt|:><hlkwd|None><hlopt|);;><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|val ><hlstd|t4 ><hlopt|:
    (><hlkwc|BurglarySimul><hlopt|.><hlstd|what<textunderscore>happened
    ><hlopt|* ><hlkwb|float><hlopt|) ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[(><hlkwc|BurglarySimul><hlopt|.><hlkwd|Earthq><hlopt|,
    ><hlnum|0.0035><hlopt|); (><hlkwc|BurglarySimul><hlopt|.><hlkwd|Burgl><hlopt|,
    ><hlnum|0.0035><hlopt|);><hlendline|><next-line><hlstd|
    \ \ ><hlopt|(><hlkwc|BurglarySimul><hlopt|.><hlkwd|Safe><hlopt|,
    ><hlnum|0.993><hlopt|)]><hlendline|><next-line><hlstd|# ><hlkwa|let
    ><hlstd|t5 ><hlopt|= ><hlkwc|Sampling2000><hlopt|.><hlstd|distrib<hlendline|><next-line>
    \ ><hlopt|(><hlkwc|BurglarySimul><hlopt|.><hlstd|check
    <math|\<sim\>>john<textunderscore>called><hlopt|:><hlkwa|true
    ><hlstd|<math|\<sim\>>mary<textunderscore>called><hlopt|:><hlkwa|true><hlendline|><next-line><hlstd|
    \ \ \ \ <math|\<sim\>>radio><hlopt|:><hlkwd|None><hlopt|);;><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|val ><hlstd|t5 ><hlopt|:
    (><hlkwc|BurglarySimul><hlopt|.><hlstd|what<textunderscore>happened
    ><hlopt|* ><hlkwb|float><hlopt|) ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[(><hlkwc|BurglarySimul><hlopt|.><hlkwd|Burgl<textunderscore>n<textunderscore>earthq><hlopt|,
    ><hlnum|0.0005><hlopt|); (><hlkwc|BurglarySimul><hlopt|.><hlkwd|Earthq><hlopt|,
    ><hlnum|0.1715><hlopt|);><hlendline|><next-line><hlstd|
    \ \ ><hlopt|(><hlkwc|BurglarySimul><hlopt|.><hlkwd|Burgl><hlopt|,
    ><hlnum|0.2875><hlopt|); (><hlkwc|BurglarySimul><hlopt|.><hlkwd|Safe><hlopt|,
    ><hlnum|0.5405><hlopt|)]><hlendline|><next-line><hlstd|# ><hlkwa|let
    ><hlstd|t6 ><hlopt|= ><hlkwc|Sampling2000><hlopt|.><hlstd|distrib<hlendline|><next-line>
    \ ><hlopt|(><hlkwc|BurglarySimul><hlopt|.><hlstd|check
    <math|\<sim\>>john<textunderscore>called><hlopt|:><hlkwa|true
    ><hlstd|<math|\<sim\>>mary<textunderscore>called><hlopt|:><hlkwa|true><hlendline|><next-line><hlstd|
    \ \ \ \ <math|\<sim\>>radio><hlopt|:(><hlkwd|Some
    ><hlkwa|true><hlopt|));;><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|val
    ><hlstd|t6 ><hlopt|: (><hlkwc|BurglarySimul><hlopt|.><hlstd|what<textunderscore>happened
    ><hlopt|* ><hlkwb|float><hlopt|) ><hlstd|list
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|[(><hlkwc|BurglarySimul><hlopt|.><hlkwd|Burgl<textunderscore>n<textunderscore>earthq><hlopt|,
    ><hlnum|0.0015><hlopt|); (><hlkwc|BurglarySimul><hlopt|.><hlkwd|Earthq><hlopt|,
    ><hlnum|0.9985><hlopt|)]><hlendline|>
  </very-small>

  <section|<new-page*>Lightweight cooperative threads>

  <\itemize>
    <item><verbatim|bind> is inherently sequential: <hlstd|bind a
    ><hlopt|(><hlkwa|fun ><hlstd|x ><hlopt|-\<gtr\> ><hlstd|b><hlopt|)>
    computes <verbatim|a>, and resumes computing <verbatim|b> only once the
    result <verbatim|x> is known.

    <item>For concurrency we need to ``suppress'' this sequentiality. We
    introduce

    <hlstd|parallel ><hlopt|:><hlendline|><next-line><hlstd|'a
    monad><hlopt|-\<gtr\> ><hlstd|'b monad><hlopt|-\<gtr\> (><hlstd|'a
    ><hlopt|-\<gtr\> ><hlstd|'b ><hlopt|-\<gtr\> ><hlstd|'c monad><hlopt|)
    -\<gtr\> ><hlstd|'c monad>

    where <hlstd|parallel a b ><hlopt|(><hlkwa|fun ><hlstd|x y
    ><hlopt|-\<gtr\> ><hlstd|c><hlopt|)> does not wait for <verbatim|a> to be
    computed before it can start computing <verbatim|b>.

    <item>It can be that only accessing the value in the monad triggers the
    computation of the value, as we've seen in some monads.

    <\itemize>
      <item>The state monad does not start computing until you ``get out of
      the monad'' and pass the initial value.

      <item>The list monad computes right away -- the <verbatim|'a monad>
      value is the computed results.
    </itemize>

    In former case, a ``built-in'' <verbatim|parallel> is necessary for
    concurrency.

    <item>If the monad starts computing right away, as in the <em|Lwt>
    library, <verbatim|parallel <math|e<rsub|a>> <math|e<rsub|b>> c> is
    equivalent to

    <hlkwa|perform><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|a
    ><hlopt|= ><math|e<rsub|a>><hlkwa| in><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|b ><hlopt|= ><math|e<rsub|b>><hlkwa|
    in><hlendline|><next-line><hlstd| \ x ><hlopt|\<less\>--
    ><hlstd|a><hlopt|;><hlendline|><next-line><hlstd| \ y ><hlopt|\<less\>--
    ><hlstd|b><hlopt|;><hlendline|><next-line><hlstd| \ c x y><hlendline|>

    <\itemize>
      <item>We will follow this model, with an imperative implementation.

      <item>In any case, do not call <verbatim|run> or <verbatim|access> from
      within a monad.
    </itemize>

    <new-page*><item>We still need to decide on when concurrency happens.

    <\itemize>
      <item>Under <strong|fine-grained> concurrency, every <verbatim|bind> is
      suspended and computation moves to other threads.

      <\itemize>
        <item>It comes back to complete the <verbatim|bind> before running
        threads created since the <verbatim|bind> was suspended.

        <item>We implement this model in our example.
      </itemize>

      <item>Under <strong|coarse-grained> concurrency, computation is only
      suspended when requested.

      <\itemize>
        <item>Operation <verbatim|suspend> is often called <verbatim|yield>
        but the meaning is \ more similar to <verbatim|Await> than
        <verbatim|Yield> from lecture 7.

        <item>Library operations that need to wait for an event or completion
        of IO (file operations, etc.) should call <verbatim|suspend> or its
        equivalent internally.

        <item>We leave coarse-grained concurrency as exercise 11.
      </itemize>
    </itemize>

    <new-page*><item>The basic operations of a multithreading monad class.

    <hlkwa|module type ><hlkwd|THREADS ><hlopt|=
    ><hlkwa|sig><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|MONAD><hlendline|><next-line><hlstd| \ ><hlkwa|val
    ><hlstd|parallel ><hlopt|:><hlendline|><next-line><hlstd| \ \ \ 'a t
    ><hlopt|-\<gtr\> ><hlstd|'b t ><hlopt|-\<gtr\> (><hlstd|'a
    ><hlopt|-\<gtr\> ><hlstd|'b ><hlopt|-\<gtr\> ><hlstd|'c t><hlopt|)
    -\<gtr\> ><hlstd|'c t><hlendline|><next-line><hlkwa|end><hlendline|>

    <item>Although in our implementation <verbatim|parallel> will be
    redundant, it is a principled way to make sure subthreads of a thread are
    run concurrently.

    <new-page*><item>All within-monad operations.

    <hlkwa|module type ><hlkwd|THREAD<textunderscore>OPS ><hlopt|=
    ><hlkwa|sig><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|MONAD<textunderscore>OPS ><hlendline|><next-line><hlstd|
    \ ><hlkwa|include ><hlkwd|THREADS ><hlkwa|with type ><hlstd|'a t
    ><hlopt|:= ><hlstd|'a monad<hlendline|><next-line> \ ><hlkwa|val
    ><hlstd|parallel<textunderscore>map ><hlopt|:><hlendline|><next-line><hlstd|
    \ \ \ 'a list ><hlopt|-\<gtr\> (><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b
    monad><hlopt|) -\<gtr\> ><hlstd|'b list monad<hlendline|><next-line>
    \ ><hlkwa|val ><hlopt|(\<gtr\>><hlstd|<hlopt|\|\|>><hlopt|=)
    :><hlendline|><next-line><hlstd| \ \ \ 'a monad ><hlopt|-\<gtr\>
    ><hlstd|'b monad ><hlopt|-\<gtr\> (><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b
    ><hlopt|-\<gtr\> ><hlstd|'c monad><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ 'c
    monad<hlendline|><next-line> \ ><hlkwa|val
    ><hlopt|(\<gtr\>><hlstd|<hlopt|\|\|>><hlopt|)
    :><hlendline|><next-line><hlstd| \ \ \ 'a monad ><hlopt|-\<gtr\>
    ><hlstd|'b monad ><hlopt|-\<gtr\> (><hlkwb|unit ><hlopt|-\<gtr\>
    ><hlstd|'c monad><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ 'c monad><hlendline|><next-line><hlkwa|end><hlendline|>

    <new-page*><item>Outside-monad operations.

    <hlkwa|module type ><hlkwd|THREADSYS ><hlopt|=
    ><hlkwa|sig><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|THREADS><hlendline|><next-line><hlstd| \ ><hlkwa|val
    ><hlstd|access ><hlopt|: ><hlstd|'a t ><hlopt|-\<gtr\>
    ><hlstd|'a<hlendline|><next-line> \ ><hlkwa|val
    ><hlstd|kill<textunderscore>threads ><hlopt|: ><hlkwb|unit
    ><hlopt|-\<gtr\> ><hlkwb|unit><hlendline|><next-line><hlkwa|end><hlendline|>

    <item>Helper functions.

    <hlkwa|module ><hlkwd|ThreadOps ><hlopt|(><hlkwd|M ><hlopt|:
    ><hlkwd|THREADS><hlopt|) = ><hlkwa|struct><hlendline|><next-line><hlstd|
    \ ><hlkwa|open ><hlkwd|M><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|MonadOps ><hlopt|(><hlkwd|M><hlopt|)><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|parallel<textunderscore>map l f
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>right
    ><hlopt|(><hlkwa|fun ><hlstd|a bs ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ parallel ><hlopt|(><hlstd|f a><hlopt|)
    ><hlstd|bs<hlendline|><next-line> \ \ \ \ \ \ \ ><hlopt|(><hlkwa|fun
    ><hlstd|a bs ><hlopt|-\<gtr\> ><hlstd|return
    ><hlopt|(><hlstd|a><hlopt|::><hlstd|bs><hlopt|))) ><hlstd|l
    ><hlopt|(><hlstd|return ><hlopt|[])><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlopt|(\<gtr\>><hlstd|<hlopt|\|\|>><hlopt|=) =
    ><hlstd|parallel<hlendline|><next-line> \ ><hlkwa|let
    ><hlopt|(\<gtr\>><hlstd|<hlopt|\|\|>><hlopt|) ><hlstd|a b c ><hlopt|=
    ><hlstd|parallel a b ><hlopt|(><hlkwa|fun ><hlstd|<textunderscore>
    <textunderscore> ><hlopt|-\<gtr\> ><hlstd|c
    ><hlopt|())><hlendline|><next-line><hlkwa|end><hlendline|>

    <new-page*><item>Put an interface around an implementation.

    <hlkwa|module ><hlkwd|Threads ><hlopt|(><hlkwd|M ><hlopt|:
    ><hlkwd|THREADSYS><hlopt|) :><hlendline|><next-line><hlkwa|sig><hlendline|><next-line><hlstd|
    \ ><hlkwa|include ><hlkwd|THREAD<textunderscore>OPS><hlendline|><next-line><hlstd|
    \ ><hlkwa|val ><hlstd|access ><hlopt|: ><hlstd|'a monad ><hlopt|-\<gtr\>
    ><hlstd|'a<hlendline|><next-line> \ ><hlkwa|val
    ><hlstd|kill<textunderscore>threads ><hlopt|: ><hlkwb|unit
    ><hlopt|-\<gtr\> ><hlkwb|unit><hlendline|><next-line><hlkwa|end ><hlopt|=
    ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|M><hlendline|><next-line><hlstd| \ ><hlkwa|include
    ><hlkwd|ThreadOps><hlopt|(><hlkwd|M><hlopt|)><hlendline|><next-line><hlkwa|end><hlendline|>

    <new-page*><item>Our implementation, following the <em|Lwt> paper.
  </itemize>

  <hlkwa|module ><hlkwd|Cooperative ><hlopt|=
  ><hlkwd|Threads><hlopt|(><hlkwa|struct><hlendline|><next-line><hlstd|
  \ ><hlkwa|type ><hlstd|'a state ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlopt|\| ><hlkwd|Return ><hlkwa|of ><verbatim|'a><hlendline|The thread
  has returned.><next-line><verbatim| \ ><hlopt|\| ><hlkwd|Sleep ><hlkwa|of
  ><hlopt|(><hlstd|'a ><hlopt|-\<gtr\> ><hlkwb|unit><hlopt|)
  ><verbatim|list><hlendline|When thread returns, wake up
  waiters.><next-line><verbatim| \ ><hlopt|\| ><hlkwd|Link ><hlkwa|of
  ><verbatim|'a t><hlendline|A link to the actual
  thread.><next-line><verbatim| \ ><hlkwa|and ><hlstd|'a t ><hlopt|=
  {><hlkwa|mutable ><hlstd|state ><hlopt|: ><hlstd|'a
  state><hlopt|}><hlendline|State of the thread can
  change><next-line><hlendline|-- it can return, or more waiters can be
  added.><verbatim|<next-line> \ ><hlkwa|let rec ><hlstd|find t
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match
  ><hlstd|t><hlopt|.><hlstd|state ><hlkwa|with><hlendline|Union-find style
  link chasing.><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Link ><hlstd|t
  ><hlopt|-\<gtr\> ><hlstd|find t<hlendline|><next-line> \ \ \ <hlopt|\|>
  <textunderscore> ><hlopt|-\<gtr\> ><hlstd|t<hlendline|><next-line><hlendline|><next-line>
  \ ><hlkwa|let ><hlstd|jobs ><hlopt|= ><hlkwc|Queue><hlopt|.><hlstd|create
  ><hlopt|()><hlendline|Work queue -- will
  store><next-line><hlendline|<hlkwb|unit ><hlopt|-\<gtr\> ><hlkwb|unit>
  procedures.><next-line><new-page*><hlkwa| \ let ><hlstd|wakeup m a
  ><hlopt|=><hlendline|Thread <verbatim|m> has actually finished
  --><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|m ><hlopt|= ><hlstd|find m
  ><hlkwa|in><hlendline|updating its state.><next-line><hlstd|
  \ \ \ ><hlkwa|match ><hlstd|m><hlopt|.><hlstd|state
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Return
  ><hlstd|<textunderscore> ><hlopt|-\<gtr\> ><hlkwa|assert
  false><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Sleep
  ><hlstd|waiters ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ m><hlopt|.><hlstd|state ><hlopt|\<less\>- ><hlkwd|Return
  ><hlstd|a><hlopt|;><hlendline|Set the state, and only
  then><next-line><hlstd| \ \ \ \ \ ><hlkwc|List><hlopt|.><hlstd|iter
  ><hlopt|((><hlstd|<hlopt|\|>><hlopt|\<gtr\>) ><hlstd|a><hlopt|)
  ><verbatim|waiters><hlendline|wake up the waiters.><next-line> <verbatim|
  \ \ ><hlopt|\| ><hlkwd|Link ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
  ><hlkwa|assert false><hlendline|><next-line><hlstd|<hlendline|><next-line>
  \ ><hlkwa|let ><hlstd|return a ><hlopt|= {><hlstd|state ><hlopt|=
  ><hlkwd|Return ><hlstd|a><hlopt|}><hlendline|><next-line><hlendline|><next-line><new-page*><verbatim|
  \ ><hlkwa|let ><hlstd|connect t t' ><hlopt|=><hlendline|<verbatim|t> was a
  placeholder for <verbatim|t'>.><next-line><hlstd| \ \ \ ><hlkwa|let
  ><hlstd|t' ><hlopt|= ><hlstd|find t' ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|match ><hlstd|t'><hlopt|.><hlstd|state
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Sleep
  ><hlstd|waiters' ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|let ><hlstd|t ><hlopt|= ><hlstd|find t
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|(><hlkwa|match
  ><hlstd|t><hlopt|.><hlstd|state ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|Sleep ><hlstd|waiters
  ><hlopt|-\<gtr\>><hlendline|If both sleep, collect their
  waiters><next-line><hlstd| \ \ \ \ \ \ \ t><hlopt|.><hlstd|state
  ><hlopt|\<less\>- ><hlkwd|Sleep ><hlopt|(><hlstd|waiters' @
  waiters><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ t'><hlopt|.><hlstd|state ><hlopt|\<less\>- ><hlkwd|Link
  ><verbatim|t><hlendline|and link one to the other.><next-line><verbatim|
  \ \ \ \ \ ><hlopt|\|> <textunderscore> <hlopt|-\<gtr\> ><hlkwa|assert
  false><hlopt|)><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  ><hlkwd|Return ><hlstd|x ><hlopt|-\<gtr\> ><verbatim|wakeup t
  x><hlendline|If <verbatim|t'> returned, wake up the
  placeholder.><verbatim|<next-line> \ \ \ ><hlopt|\| ><hlkwd|Link
  ><hlstd|<textunderscore> ><hlopt|-\<gtr\> ><hlkwa|assert
  false><hlendline|><next-line><hlendline|><next-line><new-page*><verbatim|
  \ ><hlkwa|let rec ><hlstd|bind a b ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|let ><hlstd|a ><hlopt|= ><hlstd|find a
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|m
  ><hlopt|= {><hlstd|state ><hlopt|= ><hlkwd|Sleep ><hlopt|[]}
  ><hlkwa|in><hlendline|The resulting monad.><next-line><hlstd|
  \ \ \ ><hlopt|(><hlkwa|match ><hlstd|a><hlopt|.><hlstd|state
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Return
  ><hlstd|x ><hlopt|-\<gtr\>><hlendline|If <verbatim|a> returned, we suspend
  further work.><next-line><hlstd| \ \ \ \ \ ><hlkwa|let ><hlstd|job
  ><hlopt|() = ><hlstd|connect m ><hlopt|(><hlstd|b x><hlopt|)
  ><hlkwa|in><hlendline|(In exercise 11, this should><next-line><hlstd|
  \ \ \ \ \ ><hlkwc|Queue><hlopt|.><verbatim|push job jobs><hlendline|only
  happen after <verbatim|suspend>.)><next-line><verbatim| \ \ \ ><hlopt|\|
  ><hlkwd|Sleep ><hlstd|waiters ><hlopt|-\<gtr\>><hlendline|If <verbatim|a>
  sleeps, we wait for it to return.><next-line><hlstd| \ \ \ \ \ ><hlkwa|let
  ><hlstd|job x ><hlopt|= ><hlstd|connect m ><hlopt|(><hlstd|b x><hlopt|)
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ a><hlopt|.><hlstd|state
  ><hlopt|\<less\>- ><hlkwd|Sleep ><hlopt|(><hlstd|job><hlopt|::><hlstd|waiters><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|Link ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
  ><hlkwa|assert false><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ m<hlendline|><next-line><hlendline|><next-line> \ ><hlkwa|let
  ><hlstd|parallel a b c ><hlopt|= ><hlkwa|perform><hlendline|Since in our
  implementation><next-line><hlstd| \ \ \ x ><hlopt|\<less\>--
  ><hlstd|a><hlopt|;><hlendline|the threads run as soon as they are
  created,><next-line><hlstd| \ \ \ y ><hlopt|\<less\>--
  ><hlstd|b><hlopt|;><hlendline|<verbatim|parallel> is
  redundant.><next-line><verbatim| \ \ \ c x
  y><hlendline|><next-line><hlendline|><next-line><new-page*><verbatim|
  \ ><hlkwa|let rec ><hlstd|access m ><hlopt|=><hlendline|Accessing not only
  gets the result of <verbatim|m>,><next-line><hlstd| \ \ \ ><hlkwa|let
  ><hlstd|m ><hlopt|= ><hlstd|find m ><hlkwa|in><hlendline|but spins the
  thread loop till <verbatim|m> terminates.><next-line><hlstd|
  \ \ \ ><hlkwa|match ><hlstd|m><hlopt|.><hlstd|state
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Return
  ><hlstd|x ><hlopt|-\<gtr\> ><verbatim|x><hlendline|No further
  work.><next-line><verbatim| \ \ \ ><hlopt|\| ><hlkwd|Sleep
  ><hlstd|<textunderscore> ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|(><hlkwa|try ><hlkwc|Queue><hlopt|.><hlstd|pop jobs
  ><hlopt|()><hlendline|Perform suspended work.><next-line><hlstd|
  \ \ \ \ \ \ ><hlkwa|with ><hlkwc|Queue><hlopt|.><hlkwd|Empty
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ failwith
  ><hlstr|"access: result not available"><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ \ \ access m<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|Link
  ><hlstd|<textunderscore> ><hlopt|-\<gtr\> ><hlkwa|assert
  false><hlendline|><next-line><hlstd|<hlendline|><next-line> \ ><hlkwa|let
  ><hlstd|kill<textunderscore>threads ><hlopt|() =
  ><hlkwc|Queue><hlopt|.><hlstd|clear jobs><hlendline|Remove pending
  work.><next-line><hlkwa|end><hlopt|)><hlendline|>

  <\itemize>
    <new-page*><item><hlkwa|module ><hlkwd|TTest ><hlopt|(><hlkwd|T ><hlopt|:
    ><hlkwd|THREAD<textunderscore>OPS><hlopt|) =
    ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|open
    ><hlkwd|T><hlendline|><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|loop s
    n ><hlopt|= ><hlkwa|perform><hlendline|><next-line><hlstd| \ \ \ return
    ><hlopt|(><hlkwc|Printf><hlopt|.><hlstd|printf ><hlstr|"--
    %s(%d)\\><hlesc|<math|>n><hlstr|%!"><hlstd| s
    n><hlopt|);><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|if ><hlstd|n
    ><hlopt|\<gtr\> ><hlnum|0 ><hlkwa|then ><hlstd|loop s
    ><hlopt|(><hlstd|n><hlopt|-><hlnum|1><hlopt|)><hlendline|We cannot use
    <verbatim|whenM> because><next-line><hlstd| \ \ \ ><hlkwa|else
    ><hlstd|return ><hlopt|()><hlendline|the thread would be created
    regardless of condition.><next-line><hlkwa|end><hlendline|><next-line><hlkwa|module
    ><hlkwd|TT ><hlopt|= ><hlkwd|TTest ><hlopt|(><hlkwd|Cooperative><hlopt|)><hlendline|>

    <item><hlkwa|let ><hlstd|test ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwc|Cooperative><hlopt|.><hlstd|kill<textunderscore>threads
    ><hlopt|();><hlendline|Clean-up after previous tests.><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|thread1 ><hlopt|= ><hlkwc|TT><hlopt|.><hlstd|loop
    ><hlstr|"A"><hlstd| ><hlnum|5 ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|thread2 ><hlopt|= ><hlkwc|TT><hlopt|.><hlstd|loop
    ><hlstr|"B"><hlstd| ><hlnum|4 ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwc|Cooperative><hlopt|.><hlstd|access
    thread1><hlopt|;><hlendline|We ensure threads finish
    computing><next-line><hlstd| \ ><hlkwc|Cooperative><hlopt|.><hlstd|access
    thread2><hlendline|before we proceed.>
  </itemize>

  <new-page>

  <small|<hlstd|# ><hlkwa|let ><hlstd|test
  ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|Cooperative><hlopt|.><hlstd|kill<textunderscore>threads
  ><hlopt|();><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
  ><hlstd|thread1 ><hlopt|= ><hlkwc|TT><hlopt|.><hlstd|loop
  ><hlstr|"A"><hlstd| ><hlnum|5 ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|let ><hlstd|thread2 ><hlopt|= ><hlkwc|TT><hlopt|.><hlstd|loop
  ><hlstr|"B"><hlstd| ><hlnum|4 ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|Cooperative><hlopt|.><hlstd|access
  thread1><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|Cooperative><hlopt|.><hlstd|access
  thread2><hlopt|;;><hlendline|><next-line><hlopt|--
  ><hlkwd|A><hlopt|(><hlnum|5><hlopt|)><hlendline|><next-line><hlopt|--
  ><hlkwd|B><hlopt|(><hlnum|4><hlopt|)><hlendline|><next-line><hlopt|--
  ><hlkwd|A><hlopt|(><hlnum|4><hlopt|)><hlendline|><next-line><hlopt|--
  ><hlkwd|B><hlopt|(><hlnum|3><hlopt|)><hlendline|><next-line><hlopt|--
  ><hlkwd|A><hlopt|(><hlnum|3><hlopt|)><hlendline|><next-line><hlopt|--
  ><hlkwd|B><hlopt|(><hlnum|2><hlopt|)><hlendline|><next-line><hlopt|--
  ><hlkwd|A><hlopt|(><hlnum|2><hlopt|)><hlendline|><next-line><hlopt|--
  ><hlkwd|B><hlopt|(><hlnum|1><hlopt|)><hlendline|><next-line><hlopt|--
  ><hlkwd|A><hlopt|(><hlnum|1><hlopt|)><hlendline|><next-line><hlopt|--
  ><hlkwd|B><hlopt|(><hlnum|0><hlopt|)><hlendline|><next-line><hlopt|--
  ><hlkwd|A><hlopt|(><hlnum|0><hlopt|)><hlendline|><next-line><hlkwa|val
  ><hlstd|test ><hlopt|: ><hlkwb|unit ><hlopt|= ()><hlendline|><next-line>>
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
  </collection>
</initial>

<\references>
  <\collection>
    <associate|auto-1|<tuple|1|2>>
    <associate|auto-10|<tuple|6.1|27>>
    <associate|auto-11|<tuple|6.2|28>>
    <associate|auto-12|<tuple|7|30>>
    <associate|auto-13|<tuple|8|37>>
    <associate|auto-14|<tuple|8.1|39>>
    <associate|auto-15|<tuple|8.2|43>>
    <associate|auto-16|<tuple|8.3|52>>
    <associate|auto-17|<tuple|8.4|54>>
    <associate|auto-18|<tuple|9|59>>
    <associate|auto-19|<tuple|9.1|62>>
    <associate|auto-2|<tuple|2|6>>
    <associate|auto-20|<tuple|9.2|64>>
    <associate|auto-21|<tuple|10|70>>
    <associate|auto-22|<tuple|10.1|71>>
    <associate|auto-23|<tuple|10.2|79>>
    <associate|auto-24|<tuple|10.3|82>>
    <associate|auto-25|<tuple|10.4|88>>
    <associate|auto-26|<tuple|11|94>>
    <associate|auto-3|<tuple|3|9>>
    <associate|auto-4|<tuple|3.1|12>>
    <associate|auto-5|<tuple|3.2|13>>
    <associate|auto-6|<tuple|3.3|16>>
    <associate|auto-7|<tuple|4|18>>
    <associate|auto-8|<tuple|5|21>>
    <associate|auto-9|<tuple|6|26>>
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
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>List
      comprehensions> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Generalized
      comprehensions aka. <with|font-shape|<quote|italic>|do-notation>>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Monads>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Monad laws
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4>>

      <with|par-left|<quote|1.5fn>|<new-page*>Monoid laws and
      <with|font-shape|<quote|italic>|monad-plus>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5>>

      <with|par-left|<quote|1.5fn>|<new-page*>Backtracking: computation with
      choice <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Monad
      ``flavors''> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-7><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Interlude:
      the module system> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-8><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>The
      two metaphors> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-9><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Monads as containers
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-10>>

      <with|par-left|<quote|1.5fn>|<new-page*>Monads as computation
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-11>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Monad
      classes> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-12><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Monad
      instances> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-13><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Backtracking parameterized by
      monad-plus \ <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-14>>

      <with|par-left|<quote|1.5fn>|<new-page*>Understanding laziness
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-15>>

      <with|par-left|<quote|1.5fn>|<new-page*>The exception monad
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-16>>

      <with|par-left|<quote|1.5fn>|<new-page*>The state monad
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-17>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Monad
      transformers> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-18><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>State transformer
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-19>>

      <with|par-left|<quote|1.5fn>|<new-page*>Backtracking with state
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-20>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Probabilistic
      Programming> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-21><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>The probability monad
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-22>>

      <with|par-left|<quote|1.5fn>|<new-page*>Example: The Monty Hall problem
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-23>>

      <with|par-left|<quote|1.5fn>|<new-page*>Conditional probabilities
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-24>>

      <with|par-left|<quote|1.5fn>|<new-page*>Burglary example: encoding a
      Bayes net <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-25>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Lightweight
      cooperative threads> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-26><vspace|0.5fn>
    </associate>
  </collection>
</auxiliary>