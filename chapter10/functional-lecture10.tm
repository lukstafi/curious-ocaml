<TeXmacs|1.0.7.16>

<style|<tuple|beamer|highlight|beamer-metal-lighter|smileys>>

<\body>
  <doc-data|<doc-title|Functional Programming>|<\doc-author-data|<author-name|Šukasz
  Stafiniak>>
    \;
  </doc-author-data|<author-email|lukstafi@gmail.com,
  lukstafi@ii.uni.wroc.pl>|<\author-homepage>
    www.ii.uni.wroc.pl/~lukstafi
  </author-homepage>>>

  <doc-data|<doc-title|Lecture 10: FRP>|<\doc-subtitle>
    Zippers. Functional Reactive Programming. GUIs.

    <\small>
      \ <em|``Zipper''> in <em|Haskell Wikibook> and <em|``The Zipper''> by
      Gerard Huet<next-line> <em|``How <verbatim|froc> works''> by Jacob
      Donham<next-line> <em|``The Haskell School of Expression''> by Paul
      Hudak<next-line> ``<em|Deprecating the Observer Pattern with
      <verbatim|Scala.React>>'' by Ingo Maier, Martin Odersky
    </small>
  </doc-subtitle>|>

  <center|If you see any error on the slides, let me know!>

  <section|<new-page*>Zippers>

  <\itemize>
    <item>We would like to keep track of a position in a data structure:
    easily access and modify it at that location, easily move the location
    around.

    <item>Recall how we have defined <em|context types> for datatypes: types
    that represent a data structure with one of elements stored in it
    missing.
  </itemize>

  <\code>
    type btree = Tip \| Node of int * btree * btree
  </code>

  <\eqnarray*>
    <tformat|<table|<row|<cell|T>|<cell|=>|<cell|1+x*T<rsup|2>>>|<row|<cell|<frac|\<partial\>T|\<partial\>x>>|<cell|=>|<cell|0+T<rsup|2>+2*x*T*<frac|\<partial\>T|\<partial\>x>=T*T+2*x*T*<frac|\<partial\>T|\<partial\>x>>>>>
  </eqnarray*>

  <\code>
    type btree_dir = LeftBranch \| RightBranch

    type btree_deriv =

    \ \ \| Here of btree * btree

    \ \ \| Below of btree_dir * int * btree * btree_deriv
  </code>

  <\itemize>
    <item><strong|Location = context + subtree>! But there's a problem above.

    <new-page*><item>But we cannot easily move the location if <hlkwd|Here>
    is at the bottom.

    The part closest to the location should be on top.

    <item>Revisiting equations for trees and lists:

    <\eqnarray*>
      <tformat|<table|<row|<cell|T>|<cell|=>|<cell|1+x*T<rsup|2>>>|<row|<cell|<frac|\<partial\>T|\<partial\>x>>|<cell|=>|<cell|0+T<rsup|2>+2*x*T*<frac|\<partial\>T|\<partial\>x>>>|<row|<cell|<frac|\<partial\>T|\<partial\>x>>|<cell|=>|<cell|<frac|T<rsup|2>|1-2*x*T>>>|<row|<cell|L<around*|(|y|)>>|<cell|=>|<cell|1+y*L<around*|(|y|)>>>|<row|<cell|L<around*|(|y|)>>|<cell|=>|<cell|<frac|1|1-y>>>|<row|<cell|<frac|\<partial\>T|\<partial\>x>>|<cell|=>|<cell|T<rsup|2>*L<around*|(|2*x*T|)>>>>>
    </eqnarray*>

    I.e. the context can be stored as a list with the root as the last node.

    <\itemize>
      <item>Of course it doesn't matter whether we use built-in lists, or a
      type with <hlkwd|Above> and <hlkwd|Root> variants.
    </itemize>

    <new-page*><item>Contexts of subtrees are more useful than of single
    elements.

    <hlkwa|type ><hlstd|'a tree ><hlopt|= ><hlkwd|Tip ><hlopt|\| ><hlkwd|Node
    ><hlkwa|of ><hlstd|'a tree ><hlopt|* ><hlstd|'a ><hlopt|* ><hlstd|'a
    tree><hlendline|><next-line><hlkwa|type ><hlstd|tree<textunderscore>dir
    ><hlopt|= ><hlkwd|Left<textunderscore>br ><hlopt|\|
    ><hlkwd|Right<textunderscore>br><hlendline|><next-line><hlkwa|type
    ><hlstd|'a context ><hlopt|= (><hlstd|tree<textunderscore>dir ><hlopt|*
    ><hlstd|'a ><hlopt|* ><hlstd|'a tree><hlopt|)
    ><hlstd|list><hlendline|><next-line><hlkwa|type ><hlstd|'a location
    ><hlopt|= {><hlstd|sub><hlopt|: ><hlstd|'a tree><hlopt|;
    ><hlstd|ctx><hlopt|: ><hlstd|'a context><hlopt|}><hlendline|><next-line><hlkwa|let
    ><hlstd|access ><hlopt|{><hlstd|sub><hlopt|} =
    ><hlstd|sub><hlendline|><next-line><hlkwa|let ><hlstd|change
    ><hlopt|{><hlstd|ctx><hlopt|} ><hlstd|sub ><hlopt|= {><hlstd|sub><hlopt|;
    ><hlstd|ctx><hlopt|}><hlendline|><next-line><hlkwa|let ><hlstd|modify f
    ><hlopt|{><hlstd|sub><hlopt|; ><hlstd|ctx><hlopt|} =
    {><hlstd|sub><hlopt|=><hlstd|f sub><hlopt|;
    ><hlstd|ctx><hlopt|}><hlendline|>

    <item>We can imagine a location as a rooted tree, which is hanging pinned
    at one of its nodes. Let's look at pictures
    in<next-line><hlink|http://en.wikibooks.org/wiki/Haskell/Zippers|http://en.wikibooks.org/wiki/Haskell/Zippers>

    <new-page*><item>Moving around:

    <hlkwa|let ><hlstd|ascend loc ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|match ><hlstd|loc><hlopt|.><hlstd|ctx
    ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
    ><verbatim|loc><hlendline|Or raise exception.><verbatim|<next-line>
    \ ><hlopt|\| (><hlkwd|Left<textunderscore>br><hlopt|, ><hlstd|n><hlopt|,
    ><hlstd|l><hlopt|) :: ><hlstd|up<textunderscore>ctx
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|{><hlstd|sub><hlopt|=><hlkwd|Node
    ><hlopt|(><hlstd|l><hlopt|, ><hlstd|n><hlopt|,
    ><hlstd|loc><hlopt|.><hlstd|sub><hlopt|);
    ><hlstd|ctx><hlopt|=><hlstd|up<textunderscore>ctx><hlopt|}><hlendline|><next-line><hlstd|
    \ ><hlopt|\| (><hlkwd|Right<textunderscore>br><hlopt|, ><hlstd|n><hlopt|,
    ><hlstd|r><hlopt|) :: ><hlstd|up<textunderscore>ctx
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|{><hlstd|sub><hlopt|=><hlkwd|Node
    ><hlopt|(><hlstd|loc><hlopt|.><hlstd|sub><hlopt|, ><hlstd|n><hlopt|,
    ><hlstd|r><hlopt|); ><hlstd|ctx><hlopt|=><hlstd|up<textunderscore>ctx><hlopt|}><hlendline|><next-line><hlkwa|let
    ><hlstd|desc<textunderscore>left loc ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|match ><hlstd|loc><hlopt|.><hlstd|sub
    ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Tip
    ><hlopt|-\<gtr\> ><verbatim|loc><hlendline|Or raise
    exception.><verbatim|<next-line> \ ><hlopt|\| ><hlkwd|Node
    ><hlopt|(><hlstd|l><hlopt|, ><hlstd|n><hlopt|, ><hlstd|r><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|{><hlstd|sub><hlopt|=><hlstd|l><hlopt|;
    ><hlstd|ctx><hlopt|=(><hlkwd|Right<textunderscore>br><hlopt|,
    ><hlstd|n><hlopt|, ><hlstd|r><hlopt|)::><hlstd|loc><hlopt|.><hlstd|ctx><hlopt|}><hlendline|><next-line><hlkwa|let
    ><hlstd|desc<textunderscore>right loc
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match
    ><hlstd|loc><hlopt|.><hlstd|sub ><hlkwa|with><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|Tip ><hlopt|-\<gtr\> ><verbatim|loc><hlendline|Or
    raise exception.><verbatim|<next-line> \ ><hlopt|\| ><hlkwd|Node
    ><hlopt|(><hlstd|l><hlopt|, ><hlstd|n><hlopt|, ><hlstd|r><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|{><hlstd|sub><hlopt|=><hlstd|r><hlopt|;
    ><hlstd|ctx><hlopt|=(><hlkwd|Left<textunderscore>br><hlopt|,
    ><hlstd|n><hlopt|, ><hlstd|l><hlopt|)::><hlstd|loc><hlopt|.><hlstd|ctx><hlopt|}><hlendline|>

    <new-page*><item>Following <em|The Zipper>, let's look at a tree with
    arbitrary number of branches.
  </itemize>

  <hlkwa|type ><hlstd|doc ><hlopt|= ><hlkwd|Text ><hlkwa|of ><hlkwb|string
  ><hlopt|\| ><hlkwd|Line ><hlopt|\| ><hlkwd|Group ><hlkwa|of ><hlstd|doc
  list><hlendline|><next-line><hlkwa|type ><hlstd|context ><hlopt|=
  (><hlstd|doc list ><hlopt|* ><hlstd|doc list><hlopt|)
  ><hlstd|list><hlendline|><next-line><hlkwa|type ><hlstd|location ><hlopt|=
  {><hlstd|sub><hlopt|: ><hlstd|doc><hlopt|; ><hlstd|ctx><hlopt|:
  ><hlstd|context><hlopt|}><hlendline|>

  <hlkwa|let ><hlstd|go<textunderscore>up loc
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match
  ><hlstd|loc><hlopt|.><hlstd|ctx ><hlkwa|with><hlendline|><next-line><hlstd|
  \ ><hlopt|\| [] -\<gtr\> ><hlstd|invalid<textunderscore>arg
  ><hlstr|"go<textunderscore>up: at top"><hlstd|<hlendline|><next-line>
  \ ><hlopt|\| (><hlstd|left><hlopt|, ><hlstd|right><hlopt|) ::
  ><hlstd|up<textunderscore>ctx ><hlopt|-\<gtr\>><hlendline|Previous
  subdocument and its siblings.><next-line><hlstd|
  \ \ \ ><hlopt|{><hlstd|sub><hlopt|=><hlkwd|Group
  ><hlopt|(><hlkwc|List><hlopt|.><hlstd|rev left @
  loc><hlopt|.><hlstd|sub><hlopt|::><hlstd|right><hlopt|);
  ><hlstd|ctx><hlopt|=><hlstd|up<textunderscore>ctx><hlopt|}><next-line><hlkwa|let
  ><hlstd|go<textunderscore>left loc ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|match ><hlstd|loc><hlopt|.><hlstd|ctx
  ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
  ><hlstd|invalid<textunderscore>arg ><hlstr|"go<textunderscore>left: at
  top"><hlstd|<hlendline|><next-line> \ ><hlopt|\|
  (><hlstd|l><hlopt|::><hlstd|left><hlopt|, ><hlstd|right><hlopt|) ::
  ><hlstd|up<textunderscore>ctx ><hlopt|-\<gtr\>><hlendline|Left sibling of
  previous subdocument.><next-line><hlstd|
  \ \ \ ><hlopt|{><hlstd|sub><hlopt|=><hlstd|l><hlopt|;
  ><hlstd|ctx><hlopt|=(><hlstd|left><hlopt|,
  ><hlstd|loc><hlopt|.><hlstd|sub><hlopt|::><hlstd|right><hlopt|) ::
  ><hlstd|up<textunderscore>ctx><hlopt|}><hlendline|><next-line><hlstd|
  \ ><hlopt|\| ([], ><hlstd|<textunderscore>><hlopt|) ::
  ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
  ><hlstd|invalid<textunderscore>arg ><hlstr|"go<textunderscore>left: at
  first"><hlendline|>

  <new-page*><hlkwa|let ><hlstd|go<textunderscore>right loc
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match
  ><hlstd|loc><hlopt|.><hlstd|ctx ><hlkwa|with><hlendline|><next-line><hlstd|
  \ ><hlopt|\| [] -\<gtr\> ><hlstd|invalid<textunderscore>arg
  ><hlstr|"go<textunderscore>right: at top"><hlstd|<hlendline|><next-line>
  \ ><hlopt|\| (><hlstd|left><hlopt|, ><hlstd|r><hlopt|::><hlstd|right><hlopt|)
  :: ><hlstd|up<textunderscore>ctx ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|{><hlstd|sub><hlopt|=><hlstd|r><hlopt|;
  ><hlstd|ctx><hlopt|=(><hlstd|loc><hlopt|.><hlstd|sub><hlopt|::><hlstd|left><hlopt|,
  ><hlstd|right><hlopt|) :: ><hlstd|up<textunderscore>ctx><hlopt|}><hlendline|><next-line><hlstd|
  \ ><hlopt|\| (><hlstd|<textunderscore>><hlopt|, []) ::
  ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
  ><hlstd|invalid<textunderscore>arg ><hlstr|"go<textunderscore>right: at
  last"><hlendline|><next-line><hlkwa|let ><hlstd|go<textunderscore>down loc
  ><hlopt|=><hlendline|Go to the first (i.e. leftmost)
  subdocument.><next-line><hlstd| \ ><hlkwa|match
  ><hlstd|loc><hlopt|.><hlstd|sub ><hlkwa|with><hlendline|><next-line><hlstd|
  \ ><hlopt|\| ><hlkwd|Text ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
  ><hlstd|invalid<textunderscore>arg ><hlstr|"go<textunderscore>down: at
  text"><hlstd|<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Line
  ><hlopt|-\<gtr\> ><hlstd|invalid<textunderscore>arg
  ><hlstr|"go<textunderscore>down: at line"><hlstd|<hlendline|><next-line>
  \ ><hlopt|\| ><hlkwd|Group ><hlopt|[] -\<gtr\>
  ><hlstd|invalid<textunderscore>arg ><hlstr|"go<textunderscore>down: at
  empty"><hlstd|<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Group
  ><hlopt|(><hlstd|doc><hlopt|::><hlstd|docs><hlopt|) -\<gtr\>
  {><hlstd|sub><hlopt|=><hlstd|doc><hlopt|; ><hlstd|ctx><hlopt|=([],
  ><hlstd|docs><hlopt|)::><hlstd|loc><hlopt|.><hlstd|ctx><hlopt|}><hlendline|>

  <subsection|<new-page*>Example: Context rewriting>

  <\itemize>
    <item>Our friend working on the string theory asked us for help with
    simplifying his equations.

    <item>The task is to pull out particular subexpressions as far to the
    left as we can, but changing the whole expression as little as possible.

    <item>We can illustrate our algorithm using mathematical notation. Let:

    <\itemize>
      <item> <math|x> be the thing we pull out

      <item><math|C<around*|[|e|]>> and <math|D<around*|[|e|]>> be big
      expressions with subexpression <math|e>

      <item>operator <math|\<circ\>> stand for one of: <math|\<ast\>,+>
    </itemize>

    <\eqnarray*>
      <tformat|<table|<row|<cell|D<around*|[|<around*|(|C<around*|[|x|]>\<circ\>e<rsub|1>|)>\<circ\>e<rsub|2>|]>>|<cell|\<Rightarrow\>>|<cell|D<around*|[|C<around*|[|x|]>\<circ\><around*|(|e<rsub|1>\<circ\>e<rsub|2>|)>|]>>>|<row|<cell|D<around*|[|e<rsub|2>\<circ\><around*|(|C<around*|[|x|]>\<circ\>e<rsub|1>|)>|]>>|<cell|\<Rightarrow\>>|<cell|D<around*|[|C<around*|[|x|]>\<circ\><around*|(|e<rsub|1>\<circ\>e<rsub|2>|)>|]>>>|<row|<cell|D<around*|[|<around*|(|C<around*|[|x|]>+e<rsub|1>|)>*e<rsub|2>|]>>|<cell|\<Rightarrow\>>|<cell|D<around*|[|C<around*|[|x|]>*e<rsub|2>+e<rsub|1>*e<rsub|2>|]>>>|<row|<cell|D<around*|[|e<rsub|2>*<around*|(|C<around*|[|x|]>+e<rsub|1>|)>|]>>|<cell|\<Rightarrow\>>|<cell|D<around*|[|C<around*|[|x|]>*e<rsub|2>+e<rsub|1>*e<rsub|2>|]>>>|<row|<cell|D<around*|[|e\<circ\>C<around*|[|x|]>|]>>|<cell|\<Rightarrow\>>|<cell|D<around*|[|C<around*|[|x|]>\<circ\>e|]>>>>>
    </eqnarray*>

    <new-page*><item>First the groundwork:
  </itemize>

  <hlkwa|type ><hlstd|op ><hlopt|= ><hlkwd|Add ><hlopt|\|
  ><hlkwd|Mul><hlendline|><next-line><hlkwa|type ><hlstd|expr ><hlopt|=
  ><hlkwd|Val ><hlkwa|of ><hlkwb|int ><hlopt|\| ><hlkwd|Var ><hlkwa|of
  ><hlkwb|string ><hlopt|\| ><hlkwd|App ><hlkwa|of
  ><hlstd|expr><hlopt|*><hlstd|op><hlopt|*><hlstd|expr><next-line><hlkwa|type
  ><hlstd|expr<textunderscore>dir ><hlopt|= ><hlkwd|Left<textunderscore>arg
  ><hlopt|\| ><hlkwd|Right<textunderscore>arg><hlendline|><next-line><hlkwa|type
  ><hlstd|context ><hlopt|= (><hlstd|expr<textunderscore>dir ><hlopt|*
  ><hlstd|op ><hlopt|* ><hlstd|expr><hlopt|)
  ><hlstd|list><hlendline|><next-line><hlkwa|type ><hlstd|location ><hlopt|=
  {><hlstd|sub><hlopt|: ><hlstd|expr><hlopt|; ><hlstd|ctx><hlopt|:
  ><hlstd|context><hlopt|}><hlendline|>

  <\itemize>
    <new-page*><item>Locate the subexpression described by <verbatim|p>.
  </itemize>

  <hlkwa|let rec ><hlstd|find<textunderscore>aux p e
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|if ><hlstd|p e
  ><hlkwa|then ><hlkwd|Some ><hlopt|(><hlstd|e><hlopt|,
  [])><hlendline|><next-line><hlstd| \ ><hlkwa|else match ><hlstd|e
  ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Val
  ><hlstd|<textunderscore> <hlopt|\|> ><hlkwd|Var ><hlstd|<textunderscore>
  ><hlopt|-\<gtr\> ><hlkwd|None><hlendline|><next-line><hlstd| \ ><hlopt|\|
  ><hlkwd|App ><hlopt|(><hlstd|l><hlopt|, ><hlstd|op><hlopt|,
  ><hlstd|r><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|match ><hlstd|find<textunderscore>aux p l
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Some
  ><hlopt|(><hlstd|sub><hlopt|, ><hlstd|up<textunderscore>ctx><hlopt|)
  -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwd|Some
  ><hlopt|(><hlstd|sub><hlopt|, (><hlkwd|Right<textunderscore>arg><hlopt|,
  ><hlstd|op><hlopt|, ><hlstd|r><hlopt|)::><hlstd|up<textunderscore>ctx><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|None ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|match ><hlstd|find<textunderscore>aux p r
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Some ><hlopt|(><hlstd|sub><hlopt|,
  ><hlstd|up<textunderscore>ctx><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlkwd|Some ><hlopt|(><hlstd|sub><hlopt|,
  (><hlkwd|Left<textunderscore>arg><hlopt|, ><hlstd|op><hlopt|,
  ><hlstd|l><hlopt|)::><hlstd|up<textunderscore>ctx><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|None ><hlopt|-\<gtr\>
  ><hlkwd|None><hlendline|>

  <hlkwa|let ><hlstd|find p e ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|match ><hlstd|find<textunderscore>aux p e
  ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|None
  ><hlopt|-\<gtr\> ><hlkwd|None><hlendline|><next-line><hlstd| \ ><hlopt|\|
  ><hlkwd|Some ><hlopt|(><hlstd|sub><hlopt|, ><hlstd|ctx><hlopt|) -\<gtr\>
  ><hlkwd|Some ><hlopt|{><hlstd|sub><hlopt|;
  ><hlstd|ctx><hlopt|=><hlkwc|List><hlopt|.><hlstd|rev
  ctx><hlopt|}><hlendline|>

  <\itemize>
    <new-page*><item>Pull-out the located subexpression.
  </itemize>

  <small|<hlkwa|let rec ><hlstd|pull<textunderscore>out loc
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match
  ><hlstd|loc><hlopt|.><hlstd|ctx ><hlkwa|with><hlendline|><next-line><hlstd|
  \ ><hlopt|\| [] -\<gtr\> ><verbatim|loc><hlendline|Done.><verbatim|<next-line>
  \ ><hlopt|\| (><hlkwd|Left<textunderscore>arg><hlopt|, ><hlstd|op><hlopt|,
  ><hlstd|l><hlopt|) :: ><hlstd|up<textunderscore>ctx
  ><hlopt|-\<gtr\>><hlendline|<math|D<around*|[|e\<circ\>C<around*|[|x|]>|]>\<Rightarrow\>D<around*|[|C<around*|[|x|]>\<circ\>e|]>>><next-line><hlstd|
  \ \ \ pull<textunderscore>out ><hlopt|{><hlstd|loc ><hlkwa|with
  ><hlstd|ctx><hlopt|=(><hlkwd|Right<textunderscore>arg><hlopt|,
  ><hlstd|op><hlopt|, ><hlstd|l><hlopt|) ::
  ><hlstd|up<textunderscore>ctx><hlopt|}><hlendline|><next-line><hlstd|
  \ ><hlopt|\| (><hlkwd|Right<textunderscore>arg><hlopt|,
  ><hlstd|op1><hlopt|, ><hlstd|e1><hlopt|) ::
  (><hlkwd|<textunderscore>><hlopt|, ><hlstd|op2><hlopt|, ><hlstd|e2><hlopt|)
  :: ><hlstd|up<textunderscore>ctx<hlendline|><next-line>
  \ \ \ \ \ ><hlkwa|when ><hlstd|op1 ><hlopt|= ><hlstd|op2
  ><hlopt|-\<gtr\>><hlendline|<math|D<around*|[|<around*|(|C<around*|[|x|]>\<circ\>e<rsub|1>|)>\<circ\>e<rsub|2>|]>/D<around*|[|e<rsub|2>\<circ\><around*|(|C<around*|[|x|]>\<circ\>e<rsub|1>|)>|]>\<Rightarrow\>D<around*|[|C<around*|[|x|]>\<circ\><around*|(|e<rsub|1>\<circ\>e<rsub|2>|)>|]>>><next-line><hlstd|
  \ \ \ pull<textunderscore>out ><hlopt|{><hlstd|loc ><hlkwa|with
  ><hlstd|ctx><hlopt|=(><hlkwd|Right<textunderscore>arg><hlopt|,
  ><hlstd|op1><hlopt|, ><hlkwd|App><hlopt|(><hlstd|e1><hlopt|,><hlstd|op1><hlopt|,><hlstd|e2><hlopt|))
  :: ><hlstd|up<textunderscore>ctx><hlopt|}><hlendline|><next-line><hlstd|
  \ ><hlopt|\| (><hlkwd|Right<textunderscore>arg><hlopt|,
  ><hlkwd|Add><hlopt|, ><hlstd|e1><hlopt|) ::
  (><hlkwd|<textunderscore>><hlopt|, ><hlkwd|Mul><hlopt|, ><hlstd|e2><hlopt|)
  :: ><hlstd|up<textunderscore>ctx ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ pull<textunderscore>out ><hlopt|{><hlstd|loc ><hlkwa|with
  ><hlstd|ctx><hlopt|=><hlendline|<math|D<around*|[|<around*|(|C<around*|[|x|]>+e<rsub|1>|)>e<rsub|2>|]>/D<around*|[|e<rsub|2>*<around*|(|C<around*|[|x|]>+e<rsub|1>|)>|]>\<Rightarrow\>D<around*|[|C<around*|[|x|]>*e<rsub|2>+e<rsub|1>*e<rsub|2>|]>>><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlopt|(><hlkwd|Right<textunderscore>arg><hlopt|,
  ><hlkwd|Mul><hlopt|, ><hlstd|e2><hlopt|) ::><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlopt|(><hlkwd|Right<textunderscore>arg><hlopt|,
  ><hlkwd|Add><hlopt|, ><hlkwd|App><hlopt|(><hlstd|e1><hlopt|,><hlkwd|Mul><hlopt|,><hlstd|e2><hlopt|))
  :: ><hlstd|up<textunderscore>ctx><hlopt|}><hlendline|><next-line><hlstd|
  \ ><hlopt|\| (><hlkwd|Right<textunderscore>arg><hlopt|, ><hlstd|op><hlopt|,
  ><hlstd|r><hlopt|)::><hlstd|up<textunderscore>ctx
  ><hlopt|-\<gtr\>><hlendline|Move up the context.><next-line><hlstd|
  \ \ \ pull<textunderscore>out ><hlopt|{><hlstd|sub><hlopt|=><hlkwd|App><hlopt|(><hlstd|loc><hlopt|.><hlstd|sub><hlopt|,
  ><hlstd|op><hlopt|, ><hlstd|r><hlopt|);
  ><hlstd|ctx><hlopt|=><hlstd|up<textunderscore>ctx><hlopt|}><hlendline|>>

  <\itemize>
    <item>Since operators are commutative, we ignore the direction for the
    second piece of context above.

    <new-page*><item>Test:

    <hlkwa|let ><hlopt|(+) ><hlstd|a b ><hlopt|= ><hlkwd|App
    ><hlopt|(><hlstd|a><hlopt|, ><hlkwd|Add><hlopt|,
    ><hlstd|b><hlopt|)><hlendline|><next-line><hlkwa|let ><hlopt|( * )
    ><hlstd|a b ><hlopt|= ><hlkwd|App ><hlopt|(><hlstd|a><hlopt|,
    ><hlkwd|Mul><hlopt|, ><hlstd|b><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlopt|(!) ><hlstd|a ><hlopt|= ><hlkwd|Val
    ><hlstd|a><hlendline|><next-line><hlkwa|let ><hlstd|x ><hlopt|=
    ><hlkwd|Var ><hlstr|"x"><hlendline|><next-line><hlkwa|let ><hlstd|y
    ><hlopt|= ><hlkwd|Var ><hlstr|"y"><hlendline|><next-line><hlkwa|let
    ><hlstd|ex ><hlopt|= !><hlnum|5 ><hlopt|+ ><hlstd|y ><hlopt|* (!><hlnum|7
    ><hlopt|+ ><hlstd|x><hlopt|) * (!><hlnum|3 ><hlopt|+
    ><hlstd|y><hlopt|)><hlendline|><next-line><hlkwa|let ><hlstd|loc
    ><hlopt|= ><hlstd|find ><hlopt|(><hlkwa|fun
    ><hlstd|e><hlopt|-\<gtr\>><hlstd|e><hlopt|=><hlstd|x><hlopt|)
    ><hlstd|ex><hlendline|><next-line><hlkwa|let ><hlstd|sol
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match ><hlstd|loc
    ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|None
    ><hlopt|-\<gtr\> ><hlstd|raise ><hlkwd|Not<textunderscore>found><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|Some ><hlstd|loc ><hlopt|-\<gtr\>
    ><hlstd|pull<textunderscore>out loc><hlendline|><next-line><hlstd|#
    ><hlkwa|let ><hlstd|<textunderscore> ><hlopt|= ><hlstd|expr2str
    sol><hlopt|;;><hlendline|><next-line><hlopt|- : ><hlkwb|string ><hlopt|=
    ><hlstr|"(((x*y)*(3+y))+(((7*y)*(3+y))+5))"><hlendline|>

    <item>For best results we can iterate the <verbatim|pull_out> function
    until fixpoint.
  </itemize>

  <section|<new-page*>Adaptive Programming<large| aka.Incremental Computing>>

  <\itemize>
    <item>Zippers are somewhat unnatural.

    <item>Once we change the data-structure, it is difficult to propagate the
    changes -- need to rewrite all algorithms to work on context changes.

    <item>In <em|Adaptive Programming>, aka. <em|incremental computation>,
    aka. <em|self-adjusting computation>, we write programs in
    straightforward functional manner, but can later modify any data causing
    only minimal amount of work required to update results.

    <item>The functional description of computation is within a monad.

    <item>We can change monadic values -- e.g. parts of input -- from outside
    and propagate the changes.

    <\itemize>
      <item>In the <em|Froc> library, the monadic <em|changeables> are
      <verbatim|'a Froc_sa.t>, and the ability to modify them is exposed by
      type <verbatim|'a Froc_sa.u> -- the <em|writeables>.
    </itemize>
  </itemize>

  <new-page*><subsubsection|Dependency Graphs (explained by Jake Dunham)>

  <\itemize>
    <item>The monadic value <verbatim|'a changeable> will be the
    <em|dependency graph> of the computation of the represented value
    <verbatim|'a>.

    <item>Let's look at the example in <em|``How froc works''>, representing
    computation

    <hlkwa|let ><hlstd|u ><hlopt|= ><hlstd|v ><hlopt|/ ><hlstd|w ><hlopt|+
    ><hlstd|x ><hlopt|* ><hlstd|y ><hlopt|+ ><hlstd|z
    ><image|how-froc-works-a.png|338px|184px||>

    <item>and its state with partial results memoized

    <image|how-froc-works-b.png|450px|185px||>

    where <verbatim|n0, n1, n2> are interior nodes of computation.

    <new-page*><item>Modify inputs <verbatim|v> and <verbatim|z>
    simultaneously

    <image|how-froc-works-c.png|450px|185px||>

    <item>We need to update <verbatim|n2> before <verbatim|u>.

    <item>We use the gray numbers -- the order of computation -- for the
    order of update of <verbatim|n0>, <verbatim|n2> and <verbatim|u>.

    <item>Similarly to <verbatim|parallel> in the concurrency monad, we
    provide <verbatim|bind2>, <verbatim|bind3>, ... -- and corresponding
    <verbatim|lift2>, <verbatim|lift3>, ... -- to introduce nodes with
    several children.

    <hlkwa|let ><hlstd|n0 ><hlopt|= ><hlstd|bind2 v w ><hlopt|(><hlkwa|fun
    ><hlstd|v w ><hlopt|-\<gtr\> ><hlstd|return ><hlopt|(><hlstd|v ><hlopt|/
    ><hlstd|w><hlopt|)) ><hlendline|><next-line><hlkwa|let ><hlstd|n1
    ><hlopt|= ><hlstd|bind2 x y ><hlopt|(><hlkwa|fun ><hlstd|x y
    ><hlopt|-\<gtr\> ><hlstd|return ><hlopt|(><hlstd|x ><hlopt|*
    ><hlstd|y><hlopt|)) ><hlendline|><next-line><hlkwa|let ><hlstd|n2
    ><hlopt|= ><hlstd|bind2 n0 n1 ><hlopt|(><hlkwa|fun ><hlstd|n0 n1
    ><hlopt|-\<gtr\> ><hlstd|return ><hlopt|(><hlstd|n0 ><hlopt|+
    ><hlstd|n1><hlopt|)) ><hlendline|><next-line><hlkwa|let ><hlstd|u
    ><hlopt|= ><hlstd|bind2 n2 z ><hlopt|(><hlkwa|fun ><hlstd|n2 z
    ><hlopt|-\<gtr\> ><hlstd|return ><hlopt|(><hlstd|n2 ><hlopt|+
    ><hlstd|z><hlopt|))><hlendline|>

    <new-page*><item>Do-notation is not necessary to have readable
    expressions.

    <hlkwa|let ><hlopt|(/) = ><hlstd|lift2 ><hlopt|(/)
    ><hlendline|><next-line><hlkwa|let ><hlopt|( * ) = ><hlstd|lift2
    ><hlopt|( * ) ><hlendline|><next-line><hlkwa|let ><hlopt|(+) =
    ><hlstd|lift2 ><hlopt|(+) ><hlendline|><next-line><hlkwa|let ><hlstd|u
    ><hlopt|= ><hlstd|v ><hlopt|/ ><hlstd|w ><hlopt|+ ><hlstd|x ><hlopt|*
    ><hlstd|y ><hlopt|+ ><hlstd|z><hlendline|>

    <item>As in other monads, we can decrease overhead by using bigger
    chunks.

    <hlkwa|let ><hlstd|n0 ><hlopt|= ><hlstd|blift2 v w ><hlopt|(><hlkwa|fun
    ><hlstd|v w ><hlopt|-\<gtr\> ><hlstd|v ><hlopt|/ ><hlstd|w><hlopt|)
    ><hlendline|><next-line><hlkwa|let ><hlstd|n2 ><hlopt|= ><hlstd|blift3 n0
    x y ><hlopt|(><hlkwa|fun ><hlstd|n0 x y ><hlopt|-\<gtr\> ><hlstd|n0
    ><hlopt|+ ><hlstd|x ><hlopt|* ><hlstd|y><hlopt|)
    ><hlendline|><next-line><hlkwa|let ><hlstd|u ><hlopt|= ><hlstd|blift2 n2
    z ><hlopt|(><hlkwa|fun ><hlstd|n2 z ><hlopt|-\<gtr\> ><hlstd|n2 ><hlopt|+
    ><hlstd|z><hlopt|)><hlendline|>

    <item>We have a problem if we recompute all nodes by order of
    computation.

    <hlkwa|let ><hlstd|b ><hlopt|= ><hlstd|x ><hlopt|\<gtr\>\<gtr\>=
    ><hlkwa|fun ><hlstd|x ><hlopt|-\<gtr\> ><hlstd|return ><hlopt|(><hlstd|x
    ><hlopt|= ><hlnum|0><hlopt|) ><hlendline|><next-line><hlkwa|let
    ><hlstd|n0 ><hlopt|= ><hlstd|x ><hlopt|\<gtr\>\<gtr\>= ><hlkwa|fun
    ><hlstd|x ><hlopt|-\<gtr\> ><hlstd|return ><hlopt|(><hlnum|100 ><hlopt|/
    ><hlstd|x><hlopt|) ><hlendline|><next-line><hlkwa|let ><hlstd|y ><hlopt|=
    ><hlstd|bind2 b n0 ><hlopt|(><hlkwa|fun ><hlstd|b
    n0><hlopt|-\<gtr\>><hlkwa|if ><hlstd|b ><hlkwa|then ><hlstd|return
    ><hlnum|0 ><hlkwa|else ><hlstd|n0><hlopt|)>

    <image|how-froc-works-d.png|337px|133px||>

    <new-page*><item>Rather than a signle ``time'' stamp, we store intervals:
    begin and end of computation

    <image|how-froc-works-e.png|465px|201px||>

    <item>When updating the <verbatim|y> node, we first detach nodes in range
    4-9 from the graph.

    <\itemize>
      <item>Computing the expression will re-attach the nodes as needed.
    </itemize>

    <item>When value of <verbatim|b> does not change, then we skip updating
    <verbatim|y> and proceed with updating <verbatim|n0>.

    <\itemize>
      <item>I.e. no children of <verbatim|y> with time stamp smaller than
      <verbatim|y> change.

      <item>The value of <verbatim|y> is a link to the value of <verbatim|n0>
      so it will change anyway.
    </itemize>

    <item>We need memoization to re-attach the same nodes in case they don't
    need updating.

    <\itemize>
      <item>Are they up-to-date? Run updating past the node's timestamp
      range.
    </itemize>
  </itemize>

  <subsection|<new-page*>Example using <em|Froc>>

  <\itemize>
    <item>Download <em|Froc> from <hlink|https://github.com/jaked/froc/downloads|https://github.com/jaked/froc/downloads>

    <item>Install for example with

    <verbatim|cd froc-0.2a; ./configure; make all; sudo make install>

    <item><hlkwd|Froc<textunderscore>sa> (for <em|self-adjusting>) exports
    the monadic type <verbatim|t> for changeable computation, and a handle
    type <verbatim|u> for updating the computation.

    <item><hlkwa|open ><hlkwd|Froc<textunderscore>sa><hlendline|><next-line><hlkwa|type
    ><hlstd|tree ><hlopt|=><hlendline|Binary tree with nodes storing their
    screen location.><next-line><hlopt|\| ><hlkwd|Leaf ><hlkwa|of ><hlkwb|int
    ><hlopt|* ><hlkwb|int><hlendline|We will grow the
    tree><next-line><hlopt|\| ><hlkwd|Node ><hlkwa|of ><hlkwb|int ><hlopt|*
    ><hlkwb|int ><hlopt|* ><hlstd|tree t ><hlopt|* ><hlstd|tree
    t><hlendline|by modifying subtrees.>

    <new-page*><item><hlkwa|let rec ><hlstd|display px py t
    ><hlopt|=><hlendline|Displaying the tree is changeable
    effect:><next-line><hlstd| \ ><hlkwa|match ><hlstd|t
    ><hlkwa|with><hlendline|whenever the tree changes, displaying will be
    updated.><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Leaf
    ><hlopt|(><hlstd|x><hlopt|, ><hlstd|y><hlopt|) -\<gtr\>><hlendline|Only
    new nodes will be drawn after update.><next-line><hlstd|
    \ \ \ return<hlendline|><next-line> \ \ \ \ \ ><hlopt|(><hlkwc|Graphics><hlopt|.><hlstd|draw<textunderscore>poly<textunderscore>line
    ><hlopt|[><hlstd|<hlopt|\|>px><hlopt|,><hlstd|py><hlopt|;><hlstd|x><hlopt|,><hlstd|y<hlopt|\|>><hlopt|];><hlendline|We
    return><next-line><hlstd| \ \ \ \ \ \ ><hlkwc|Graphics><hlopt|.><hlstd|draw<textunderscore>circle
    x y ><hlnum|3><hlopt|)><hlendline|a throwaway value.><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|Node ><hlopt|(><hlstd|x><hlopt|, ><hlstd|y><hlopt|,
    ><hlstd|l><hlopt|, ><hlstd|r><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ return
    ><hlopt|(><hlkwc|Graphics><hlopt|.><hlstd|draw<textunderscore>poly<textunderscore>line
    ><hlopt|[><hlstd|<hlopt|\|>px><hlopt|,><hlstd|py><hlopt|;><hlstd|x><hlopt|,><hlstd|y<hlopt|\|>><hlopt|])><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|\<gtr\>\<gtr\>= ><hlkwa|fun ><hlstd|<textunderscore>
    ><hlopt|-\<gtr\> ><hlstd|l ><hlopt|\<gtr\>\<gtr\>= ><hlstd|display x
    y<hlendline|><next-line> \ \ \ ><hlopt|\<gtr\>\<gtr\>= ><hlkwa|fun
    ><hlstd|<textunderscore> ><hlopt|-\<gtr\> ><hlstd|r
    ><hlopt|\<gtr\>\<gtr\>= ><hlstd|display x y><hlendline|>

    <item><hlkwa|let ><hlstd|grow<textunderscore>at
    ><hlopt|(><hlstd|x><hlopt|, ><hlstd|depth><hlopt|, ><hlstd|upd><hlopt|)
    =><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|x<textunderscore>l
    ><hlopt|= ><hlstd|x><hlopt|-><hlstd|f2i
    ><hlopt|(><hlstd|width><hlopt|*.(><hlnum|2.0><hlopt|**(><hlstd|<math|\<sim\>>><hlopt|-.(><hlstd|i2f
    ><hlopt|(><hlstd|depth><hlopt|+><hlnum|1><hlopt|)))))
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|l><hlopt|, ><hlstd|upd<textunderscore>l ><hlopt|=
    ><hlstd|changeable ><hlopt|(><hlkwd|Leaf
    ><hlopt|(><hlstd|x<textunderscore>l><hlopt|,
    (><hlstd|depth><hlopt|+><hlnum|1><hlopt|)*><hlnum|20><hlopt|))
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|x<textunderscore>r ><hlopt|= ><hlstd|x><hlopt|+><hlstd|f2i
    ><hlopt|(><hlstd|width><hlopt|*.(><hlnum|2.0><hlopt|**(><hlstd|<math|\<sim\>>><hlopt|-.(><hlstd|i2f
    ><hlopt|(><hlstd|depth><hlopt|+><hlnum|1><hlopt|)))))
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|r><hlopt|, ><hlstd|upd<textunderscore>r ><hlopt|=
    ><hlstd|changeable ><hlopt|(><hlkwd|Leaf
    ><hlopt|(><hlstd|x<textunderscore>r><hlopt|,
    (><hlstd|depth><hlopt|+><hlnum|1><hlopt|)*><hlnum|20><hlopt|))
    ><hlkwa|in><hlendline|><next-line><hlstd| \ write upd
    ><hlopt|(><hlkwd|Node ><hlopt|(><hlstd|x><hlopt|,
    ><hlstd|depth><hlopt|*><hlnum|20><hlopt|, ><hlstd|l><hlopt|,
    ><hlstd|r><hlopt|));><hlendline|Update the old leaf><next-line><hlstd|
    \ propagate ><hlopt|();><hlendline|and keep handles to make future
    updates.><next-line><hlstd| \ ><hlopt|[><hlstd|x<textunderscore>l><hlopt|,
    ><hlstd|depth><hlopt|+><hlnum|1><hlopt|,
    ><hlstd|upd<textunderscore>l><hlopt|; ><hlstd|x<textunderscore>r><hlopt|,
    ><hlstd|depth><hlopt|+><hlnum|1><hlopt|,
    ><hlstd|upd<textunderscore>r><hlopt|]><hlendline|>

    <new-page*><item><hlkwa|let rec ><hlstd|loop t subts steps
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|if ><hlstd|steps
    ><hlopt|\<less\>= ><hlnum|0 ><hlkwa|then
    ><hlopt|()><hlendline|><next-line><hlstd| \ ><hlkwa|else ><hlstd|loop t
    ><hlopt|(><hlstd|concat<textunderscore>map grow<textunderscore>at
    subts><hlopt|) (><hlstd|steps><hlopt|-><hlnum|1><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|incremental steps ><hlopt|() =><hlendline|><next-line><hlstd|
    \ ><hlkwc|Graphics><hlopt|.><hlstd|open<textunderscore>graph ><hlstr|"
    1024x600"><hlopt|;><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|t><hlopt|, ><hlstd|u ><hlopt|= ><hlstd|changeable
    ><hlopt|(><hlkwd|Leaf ><hlopt|(><hlnum|512><hlopt|, ><hlnum|20><hlopt|))
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|d
    ><hlopt|= ><hlstd|t ><hlopt|\<gtr\>\<gtr\>= ><hlstd|display
    ><hlopt|(><hlstd|f2i ><hlopt|(><hlstd|width ><hlopt|/.
    ><hlnum|2><hlopt|.)) ><hlnum|0 ><hlkwa|in><hlendline|Display
    once><next-line><hlstd| \ loop t ><hlopt|[><hlnum|512><hlopt|,
    ><hlnum|1><hlopt|, ><hlstd|u><hlopt|]
    ><hlstd|steps><hlopt|;><hlendline|-- new nodes will be drawn
    automatically.><next-line><hlstd| \ ><hlkwc|Graphics><hlopt|.><hlstd|close<textunderscore>graph
    ><hlopt|();;><hlendline|>

    <item>Compare with rebuilding and redrawing the whole tree. Unfortunately
    the overhead of incremental computation is quite large. Byte code run:

    \ <block|<tformat|<cwith|3|3|1|1|cell-halign|l>|<cwith|1|1|2|2|cell-halign|l>|<table|<row|<cell|depth>|<cell|12>|<cell|13>|<cell|14>|<cell|15>|<cell|16>|<cell|17>|<cell|18>|<cell|19>|<cell|20>>|<row|<cell|incremental>|<cell|0.66s>|<cell|1s>|<cell|2.2s>|<cell|4.4s>|<cell|9.3s>|<cell|21s>|<cell|50s>|<cell|140s>|<cell|255s>>|<row|<cell|rebuilding>|<cell|0.5s>|<cell|0.63s>|<cell|1.3s>|<cell|3s>|<cell|5.3s>|<cell|13s>|<cell|39s>|<cell|190s>|<cell|<math|\<infty\>>>>>>>
  </itemize>

  <section|<new-page*>Functional Reactive Programming>

  <\itemize>
    <item>FRP is an attempt to declaratively deal with time.

    <item><em|Behaviors> are functions of time.

    <\itemize>
      <item>A behavior has a specific value in each instant.
    </itemize>

    <item><em|Events> are sets of (time, value) pairs.

    <\itemize>
      <item>I.e. they are organised into streams of actions.
    </itemize>

    <item>Two problems

    <\itemize>
      <item>Behaviors / events are well defined when they don't depend on
      future

      <item>Efficiency: minimize overhead
    </itemize>

    <item>FRP is <em|synchronous>: it is possible to set up for events to
    happen at the same time, and it is <em|continuous>: behaviors can have
    details at arbitrary time resolution.

    <\itemize>
      <item>Although the results are <em|sampled>, there's no fixed (minimal)
      time step for specifying behavior.

      <item><small|Asynchrony refers to various ideas so ask what people
      mean.>
    </itemize>

    <new-page*><item>Ideally we would define:

    <hlkwa|type ><hlstd|time ><hlopt|= ><hlkwb|float><hlendline|><next-line><hlkwa|type
    ><hlstd|'a behavior ><hlopt|= ><hlstd|time ><hlopt|-\<gtr\>
    ><hlstd|'a><hlendline|Arbitrary function.><next-line><hlkwa|type
    ><hlstd|'a event ><hlopt|= (><hlstd|'a><hlopt|, ><hlstd|time><hlopt|)
    ><hlstd|stream><hlendline|Increasing time instants.>

    <item>Forcing a lazy list (stream) of events would wait till an event
    arrives.

    <item>But behaviors need to react to external events:

    <small|<hlkwa|type ><hlstd|user<textunderscore>action
    ><hlopt|=><hlendline|><next-line><hlopt|\| ><hlkwd|Key ><hlkwa|of
    ><hlstd|char ><hlopt|* ><hlkwb|bool><hlendline|><next-line><hlopt|\|
    ><hlkwd|Button ><hlkwa|of ><hlkwb|int ><hlopt|* ><hlkwb|int ><hlopt|*
    ><hlkwb|bool ><hlopt|* ><hlkwb|bool><hlendline|><next-line><hlopt|\|
    ><hlkwd|MouseMove ><hlkwa|of ><hlkwb|int ><hlopt|*
    ><hlkwb|int><hlendline|><next-line><hlopt|\| ><hlkwd|Resize ><hlkwa|of
    ><hlkwb|int ><hlopt|* ><hlkwb|int><hlendline|><next-line><hlkwa|type
    ><hlstd|'a behavior ><hlopt|= ><hlstd|user<textunderscore>action event
    ><hlopt|-\<gtr\> ><hlstd|time ><hlopt|-\<gtr\> ><hlstd|'a><hlendline|>>

    <item>Scanning through an event list since the beginnig of time till
    current time, each time we evaluate a behavior -- very wasteful wrt.
    time&space.

    Producing a stream of behaviors for the stream of time allows to forget
    about events already in the past.

    <hlkwa|type ><hlstd|'a behavior ><hlopt|=><hlendline|><next-line><hlstd|
    \ user<textunderscore>action event ><hlopt|-\<gtr\> ><hlstd|time stream
    ><hlopt|-\<gtr\> ><hlstd|'a stream><hlendline|>

    <item>Next optimization is to pair user actions with sampling times.

    <hlkwa|type ><hlstd|'a behavior ><hlopt|=><hlendline|><next-line><hlstd|
    \ <hlopt|(>user<textunderscore>action ><hlkwb|option ><hlopt|*
    ><hlstd|time<hlopt|)> stream ><hlopt|-\<gtr\> ><hlstd|'a
    stream><hlendline|>

    <hlkwd|None> action corresponds to sampling time when nothing happens.

    <item>Turning behaviors and events from functions of time into
    input-output streams is similar to optimizing interesction of ordered
    lists from <math|O<around*|(|m*n|)>> to <math|O<around*|(|m+n|)>> time.

    <item>Now we can in turn define events in terms of behaviors:

    <hlkwa|type ><hlstd|'a event ><hlopt|= ><hlstd|'a ><hlkwb|option
    ><hlstd|behavior><hlendline|>

    although it betrays the discrete character of events (happening at points
    in time rather than varying over intervals of time).

    <item>We've gotten very close to <em|stream processing> as discussed in
    lecture 7.

    <\itemize>
      <item>Recall the incremental pretty-printing example that can ``react''
      to more input.

      <item>Stream combinators, <em|fork> from exercise 9 for lecture 7, and
      a corresponding <em|merge>, turn stream processing into <em|synchronous
      discrete reactive programming>.
    </itemize>

    <new-page*><item>Behaviors are monadic (but see next point) -- in
    original specification:

    <hlkwa|type ><hlstd|'a behavior ><hlopt|= ><hlstd|time ><hlopt|-\<gtr\>
    ><hlstd|'a><hlendline|><next-line><hlkwa|val ><hlstd|return ><hlopt|:
    ><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'a
    behavior><hlendline|><next-line><hlkwa|let ><hlstd|return a ><hlopt|=
    ><hlkwa|fun ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
    ><hlstd|a><hlendline|><next-line><hlkwa|val ><hlstd|bind
    ><hlopt|:><hlendline|><next-line><hlstd| \ 'a behavior ><hlopt|-\<gtr\>
    (><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b behavior><hlopt|) -\<gtr\>
    ><hlstd|'b behavior><hlendline|><next-line><hlkwa|let ><hlstd|bind a f
    ><hlopt|= ><hlkwa|fun ><hlstd|t ><hlopt|-\<gtr\> ><hlstd|f
    ><hlopt|(><hlstd|a t><hlopt|) ><hlstd|t><hlendline|>

    <item>As we've seen with changeables, we mostly use lifting. In Haskell
    world we'd call behaviors <em|applicative>. To build our own lifters in
    any monad:

    <hlkwa|val ><hlstd|ap ><hlopt|: (><hlstd|'a ><hlopt|-\<gtr\>
    ><hlstd|'b><hlopt|) ><hlstd|monad ><hlopt|-\<gtr\> ><hlstd|'a monad
    ><hlopt|-\<gtr\> ><hlstd|'b monad><hlendline|><next-line><hlkwa|let
    ><hlstd|ap fm am ><hlopt|= ><hlkwa|perform><hlendline|><next-line><hlstd|
    \ f ><hlopt|\<less\>-- ><hlstd|fm><hlopt|;><hlendline|><next-line><hlstd|
    \ a ><hlopt|\<less\>-- ><hlstd|am><hlopt|;><hlendline|><next-line><hlstd|
    \ return ><hlopt|(><hlstd|f a><hlopt|)><hlendline|>

    <\itemize>
      <item>Note that for changeables, the naive implementation above will
      introduce unnecessary dependencies. Monadic libraries for
      <em|incremental computing> or FRP should provide optimized variants if
      needed.

      <\itemize>
        <item>Compare with <verbatim|parallel> for concurrent computing.
      </itemize>
    </itemize>

    <new-page*><item>Going from events to behaviors. <verbatim|until> and
    <verbatim|switch> have type

    <hlstd|'a behavior ><hlopt|-\<gtr\> ><hlstd|'a behavior event
    ><hlopt|-\<gtr\> ><hlstd|'a behavior><hlendline|>

    <verbatim|step> has type

    <hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'a event ><hlopt|-\<gtr\> ><hlstd|'a
    behavior><hlendline|>

    <\itemize>
      <item><verbatim|until b es> behaves as <verbatim|b> until the first
      event in <verbatim|es>, then behaves as the behavior in that event

      <item><verbatim|switch b es> behaves as the behavior from the last
      event in <verbatim|es> prior to current time, if any, otherwise as
      <verbatim|b>

      <item><verbatim|step a b> starts with behavior returning <verbatim|a>
      and then switches to returning the value of the last event in
      <verbatim|b> (prior to current time) -- a <em|step function>.
    </itemize>

    <item>We will use ``<em|signal>'' to refer to a behavior or an event. But
    often ``signal'' is used as our behavior (check terminology when looking
    at a new FRP library).
  </itemize>

  <section|<new-page*>Reactivity by Stream Processing>

  <\itemize>
    <item>The stream processing infrastructure should be familiar.

    <hlkwa|type ><hlstd|'a stream ><hlopt|= ><hlstd|'a stream<textunderscore>
    ><hlkwc|Lazy><hlopt|.><hlstd|t><hlendline|><next-line><hlkwa|and
    ><hlstd|'a stream<textunderscore> ><hlopt|= ><hlkwd|Cons ><hlkwa|of
    ><hlstd|'a ><hlopt|* ><hlstd|'a stream><hlendline|><next-line><hlkwa|let
    rec ><hlstd|lmap f l ><hlopt|= ><hlkwa|lazy
    ><hlopt|(><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlkwd|Cons
    ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) =
    ><hlkwc|Lazy><hlopt|.><hlstd|force l ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwd|Cons ><hlopt|(><hlstd|f x><hlopt|, ><hlstd|lmap f
    xs><hlopt|))><hlendline|><next-line><hlkwa|let rec ><hlstd|liter
    ><hlopt|(><hlstd|f ><hlopt|: ><hlstd|'a ><hlopt|-\<gtr\>
    ><hlkwb|unit><hlopt|) (><hlstd|l ><hlopt|: ><hlstd|'a stream><hlopt|) :
    ><hlkwb|unit ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) =
    ><hlkwc|Lazy><hlopt|.><hlstd|force l ><hlkwa|in><hlendline|><next-line><hlstd|
    \ f x><hlopt|; ><hlstd|liter f xs><hlendline|><next-line><hlkwa|let rec
    ><hlstd|lmap2 f xs ys ><hlopt|= ><hlkwa|lazy
    ><hlopt|(><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlkwd|Cons
    ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) =
    ><hlkwc|Lazy><hlopt|.><hlstd|force xs
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlkwd|Cons
    ><hlopt|(><hlstd|y><hlopt|, ><hlstd|ys><hlopt|) =
    ><hlkwc|Lazy><hlopt|.><hlstd|force ys
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwd|Cons
    ><hlopt|(><hlstd|f x y><hlopt|, ><hlstd|lmap2 f xs
    ys><hlopt|))><hlendline|><next-line><hlkwa|let rec ><hlstd|lmap3 f xs ys
    zs ><hlopt|= ><hlkwa|lazy ><hlopt|(><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
    ><hlstd|xs><hlopt|) = ><hlkwc|Lazy><hlopt|.><hlstd|force xs
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlkwd|Cons
    ><hlopt|(><hlstd|y><hlopt|, ><hlstd|ys><hlopt|) =
    ><hlkwc|Lazy><hlopt|.><hlstd|force ys
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlkwd|Cons
    ><hlopt|(><hlstd|z><hlopt|, ><hlstd|zs><hlopt|) =
    ><hlkwc|Lazy><hlopt|.><hlstd|force zs
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwd|Cons
    ><hlopt|(><hlstd|f x y z><hlopt|, ><hlstd|lmap3 f xs ys
    zs><hlopt|))><hlendline|><next-line><hlkwa|let rec ><hlstd|lfold acc f
    ><hlopt|(><hlstd|l ><hlopt|: ><hlstd|'a stream><hlopt|) = ><hlkwa|lazy
    ><hlopt|(><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlkwd|Cons
    ><hlopt|(><hlstd|x><hlopt|, ><hlstd|xs><hlopt|) =
    ><hlkwc|Lazy><hlopt|.><hlstd|force l ><hlkwa|in><hlendline|Fold a
    function over the stream><next-line><hlstd| \ ><hlkwa|let ><hlstd|acc
    ><hlopt|= ><hlstd|f acc x ><hlkwa|in><hlendline|producing a stream of
    partial results.><next-line><hlstd| \ ><hlkwd|Cons
    ><hlopt|(><hlstd|acc><hlopt|, ><hlstd|lfold acc f
    xs><hlopt|))><hlendline|>

    <new-page*><item>Since a behavior is a function of user actions and
    sample times, we need to ensure that only one stream is created for the
    actual input stream.

    <hlkwa|type ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|)
    ><hlstd|memo1 ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|{><hlstd|memo<textunderscore>f ><hlopt|: ><hlstd|'a
    ><hlopt|-\<gtr\> ><hlstd|'b><hlopt|; ><hlkwa|mutable
    ><hlstd|memo<textunderscore>r ><hlopt|: (><hlstd|'a ><hlopt|*
    ><hlstd|'b><hlopt|) ><hlkwb|option><hlopt|}><hlendline|><next-line><hlkwa|let
    ><hlstd|memo1 f ><hlopt|= {><hlstd|memo<textunderscore>f ><hlopt|=
    ><hlstd|f><hlopt|; ><hlstd|memo<textunderscore>r ><hlopt|=
    ><hlkwd|None><hlopt|}><hlendline|><next-line><hlkwa|let
    ><hlstd|memo1<textunderscore>app f x ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|match ><hlstd|f><hlopt|.><hlstd|memo<textunderscore>r
    ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Some
    ><hlopt|(><hlstd|y><hlopt|, ><hlstd|res><hlopt|) ><hlkwa|when ><hlstd|x
    ><hlopt|== ><hlstd|y ><hlopt|-\<gtr\> ><verbatim|res><hlendline|Physical
    equality is OK --><next-line><verbatim| \ ><hlopt|\|> <textunderscore>
    <hlopt|-\<gtr\>><hlendline|external input is ``physically''
    unique.><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|res ><hlopt|=
    ><hlstd|f><hlopt|.><hlstd|memo<textunderscore>f x
    ><hlkwa|in><hlendline|While debugging, we can monitor><next-line><hlstd|
    \ \ \ f><hlopt|.><hlstd|memo<textunderscore>r ><hlopt|\<less\>-
    ><hlkwd|Some ><hlopt|(><hlstd|x><hlopt|,
    ><hlstd|res><hlopt|);><hlendline|whether
    <hlstd|f><hlopt|.><hlstd|memo<textunderscore>r ><hlopt|= ><hlkwd|None>
    before.><next-line><hlstd| \ \ \ res><hlendline|><next-line><hlkwa|let
    ><hlopt|(><hlstd|$><hlopt|) = ><hlstd|memo1<textunderscore>app><hlendline|><next-line><hlkwa|type
    ><hlstd|'a behavior ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlopt|((><hlstd|user<textunderscore>action ><hlkwb|option ><hlopt|*
    ><hlstd|time><hlopt|) ><hlstd|stream><hlopt|, ><hlstd|'a stream><hlopt|)
    ><hlstd|memo1><hlendline|>

    <new-page*><item>The monadic/applicative functions to build complex
    behaviors.

    <\itemize>
      <item>If you do not provide type annotations in <verbatim|.ml> files,
      work together with an <verbatim|.mli> file to catch problems early. You
      can later add more type annotations as needed to find out what's wrong.
    </itemize>

    <hlkwa|let ><hlstd|returnB x ><hlopt|: ><hlstd|'a behavior
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|xs
    ><hlopt|= ><hlkwa|lazy ><hlopt|(><hlkwd|Cons ><hlopt|(><hlstd|x><hlopt|,
    ><hlstd|xs><hlopt|)) ><hlkwa|in><hlendline|><next-line><hlstd| \ memo1
    ><hlopt|(><hlkwa|fun ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
    ><hlstd|xs><hlopt|)><hlendline|><next-line><hlkwa|let ><hlopt|( !* ) =
    ><hlstd|returnB><hlendline|><next-line><hlkwa|let ><hlstd|liftB f fb
    ><hlopt|= ><hlstd|memo1 ><hlopt|(><hlkwa|fun ><hlstd|uts ><hlopt|-\<gtr\>
    ><hlstd|lmap f ><hlopt|(><hlstd|fb $ uts><hlopt|))><hlendline|><next-line><hlkwa|let
    ><hlstd|liftB2 f fb1 fb2 ><hlopt|= ><hlstd|memo1<hlendline|><next-line>
    \ ><hlopt|(><hlkwa|fun ><hlstd|uts ><hlopt|-\<gtr\> ><hlstd|lmap2 f
    ><hlopt|(><hlstd|fb1 $ uts><hlopt|) (><hlstd|fb2 $
    uts><hlopt|))><hlendline|><next-line><hlkwa|let ><hlstd|liftB3 f fb1 fb2
    fb3 ><hlopt|= ><hlstd|memo1<hlendline|><next-line> \ ><hlopt|(><hlkwa|fun
    ><hlstd|uts ><hlopt|-\<gtr\> ><hlstd|lmap3 f ><hlopt|(><hlstd|fb1 $
    uts><hlopt|) (><hlstd|fb2 $ uts><hlopt|) (><hlstd|fb3 $
    uts><hlopt|))><next-line><hlkwa|let ><hlstd|liftE f ><hlopt|(><hlstd|fe
    ><hlopt|: ><hlstd|'a event><hlopt|) : ><hlstd|'b event ><hlopt|=
    ><hlstd|memo1<hlendline|><next-line> \ ><hlopt|(><hlkwa|fun ><hlstd|uts
    ><hlopt|-\<gtr\> ><hlstd|lmap<hlendline|><next-line>
    \ \ \ ><hlopt|(><hlkwa|function ><hlkwd|Some ><hlstd|e ><hlopt|-\<gtr\>
    ><hlkwd|Some ><hlopt|(><hlstd|f e><hlopt|) \| ><hlkwd|None
    ><hlopt|-\<gtr\> ><hlkwd|None><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|(><hlstd|fe $ uts><hlopt|))><hlendline|><next-line><hlkwa|let
    ><hlopt|(=\<gtr\>\<gtr\>) ><hlstd|fe f ><hlopt|= ><hlstd|liftE f
    fe><hlendline|><next-line><hlkwa|let ><hlopt|(-\<gtr\>\<gtr\>) ><hlstd|e
    v ><hlopt|= ><hlstd|e ><hlopt|=\<gtr\>\<gtr\> ><hlkwa|fun
    ><hlstd|<textunderscore> ><hlopt|-\<gtr\> ><hlstd|v><hlendline|>

    <new-page*><item>Creating events out of behaviors.

    <hlkwa|let ><hlstd|whileB ><hlopt|(><hlstd|fb ><hlopt|: ><hlkwb|bool
    ><hlstd|behavior><hlopt|) : ><hlkwb|unit ><hlstd|event
    ><hlopt|=><hlendline|><next-line><hlstd| \ memo1 ><hlopt|(><hlkwa|fun
    ><hlstd|uts ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ lmap
    ><hlopt|(><hlkwa|function true ><hlopt|-\<gtr\> ><hlkwd|Some ><hlopt|()
    \| ><hlkwa|false ><hlopt|-\<gtr\> ><hlkwd|None><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|(><hlstd|fb $ uts><hlopt|))><hlendline|><next-line><hlkwa|let
    ><hlstd|unique fe ><hlopt|: ><hlstd|'a event
    ><hlopt|=><hlendline|><next-line><hlstd| \ memo1 ><hlopt|(><hlkwa|fun
    ><hlstd|uts ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|xs ><hlopt|= ><hlstd|fe $ uts
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ lmap2
    ><hlopt|(><hlkwa|fun ><hlstd|x y ><hlopt|-\<gtr\> ><hlkwa|if ><hlstd|x
    ><hlopt|= ><hlstd|y ><hlkwa|then ><hlkwd|None ><hlkwa|else
    ><hlstd|y><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|(><hlkwa|lazy ><hlopt|(><hlkwd|Cons
    ><hlopt|(><hlkwd|None><hlopt|, ><hlstd|xs><hlopt|)))
    ><hlstd|xs><hlopt|)><hlendline|><next-line><hlkwa|let ><hlstd|whenB fb
    ><hlopt|=><hlendline|><next-line><hlstd| \ memo1 ><hlopt|(><hlkwa|fun
    ><hlstd|uts ><hlopt|-\<gtr\> ><hlstd|unique ><hlopt|(><hlstd|whileB
    fb><hlopt|) ><hlstd|$ uts><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|snapshot fe fb ><hlopt|: (><hlstd|'a ><hlopt|*
    ><hlstd|'b><hlopt|) ><hlstd|event ><hlopt|=><hlendline|><next-line><hlstd|
    \ memo1 ><hlopt|(><hlkwa|fun ><hlstd|uts ><hlopt|-\<gtr\>
    ><hlstd|lmap2<hlendline|><next-line> \ \ \ ><hlopt|(><hlkwa|fun
    ><hlstd|x><hlopt|-\<gtr\>><hlkwa|function ><hlkwd|Some ><hlstd|y
    ><hlopt|-\<gtr\> ><hlkwd|Some ><hlopt|(><hlstd|y><hlopt|,><hlstd|x><hlopt|)
    \| ><hlkwd|None ><hlopt|-\<gtr\> ><hlkwd|None><hlopt|)><next-line><hlstd|
    \ \ \ \ \ ><hlopt|(><hlstd|fb $ uts><hlopt|) (><hlstd|fe $
    uts><hlopt|))><hlendline|>

    <new-page*><item>Creating behaviors out of events.

    <hlkwa|let ><hlstd|step acc fe ><hlopt|=><hlendline|The step function:
    value of last event.><next-line><hlstd| memo1 ><hlopt|(><hlkwa|fun
    ><hlstd|uts ><hlopt|-\<gtr\> ><hlstd|lfold acc<hlendline|><next-line>
    \ \ ><hlopt|(><hlkwa|fun ><hlstd|acc ><hlopt|-\<gtr\> ><hlkwa|function
    ><hlkwd|None ><hlopt|-\<gtr\> ><hlstd|acc <hlopt|\|> ><hlkwd|Some
    ><hlstd|v ><hlopt|-\<gtr\> ><hlstd|v><hlopt|)><hlendline|><next-line><hlstd|
    \ \ ><hlopt|(><hlstd|fe $ uts><hlopt|))><hlendline|><next-line><hlkwa|let
    ><hlstd|step<textunderscore>accum acc ff ><hlopt|=><hlendline|Transform a
    value by a series of functions.><next-line><hlstd| memo1
    ><hlopt|(><hlkwa|fun ><hlstd|uts ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ lfold acc ><hlopt|(><hlkwa|fun ><hlstd|acc ><hlopt|-\<gtr\>
    ><hlkwa|function><hlendline|><next-line><hlstd| \ \ ><hlopt|\|
    ><hlkwd|None ><hlopt|-\<gtr\> ><hlstd|acc <hlopt|\|> ><hlkwd|Some
    ><hlstd|f ><hlopt|-\<gtr\> ><hlstd|f acc><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ \ ><hlopt|(><hlstd|ff $ uts><hlopt|))><hlendline|>

    <new-page*><item>To numerically integrate a behavior, we need to access
    the sampling times.

    <hlkwa|let ><hlstd|integral fb ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let rec ><hlstd|loop t0 acc uts bs
    ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlkwd|Cons
    ><hlopt|((><hlstd|<textunderscore>><hlopt|,><hlstd|t1><hlopt|),
    ><hlstd|uts><hlopt|) = ><hlkwc|Lazy><hlopt|.><hlstd|force uts
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlkwd|Cons
    ><hlopt|(><hlstd|b><hlopt|, ><hlstd|bs><hlopt|) =
    ><hlkwc|Lazy><hlopt|.><hlstd|force bs
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|acc
    ><hlopt|= ><hlstd|acc ><hlopt|+. (><hlstd|t1 ><hlopt|-.
    ><hlstd|t0><hlopt|) *. ><hlstd|b ><hlkwa|in><hlendline|<math|b=fb<around*|(|t<rsub|1>|)>,acc\<approx\><big|int><rsub|t\<leqslant\>t<rsub|0>>f>.><next-line><hlstd|
    \ \ \ ><hlkwd|Cons ><hlopt|(><hlstd|acc><hlopt|, ><hlkwa|lazy
    ><hlopt|(><hlstd|loop t1 acc uts bs><hlopt|))
    ><hlkwa|in><hlendline|><next-line><hlstd| \ memo1 ><hlopt|(><hlkwa|fun
    ><hlstd|uts ><hlopt|-\<gtr\> ><hlkwa|lazy
    ><hlopt|(><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlkwd|Cons
    ><hlopt|((><hlstd|<textunderscore>><hlopt|,><hlstd|t><hlopt|),
    ><hlstd|uts'><hlopt|) = ><hlkwc|Lazy><hlopt|.><hlstd|force uts
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwd|Cons
    ><hlopt|(><hlnum|0><hlopt|., ><hlkwa|lazy ><hlopt|(><hlstd|loop t
    ><hlnum|0><hlopt|. ><hlstd|uts' ><hlopt|(><hlstd|fb $
    uts><hlopt|)))))><hlendline|>

    <\itemize>
      <item>In our <em|paddle game> example, we paradoxically express
      position and velocity in mutually recursive manner. The trick is the
      same as in chapter 7 -- integration introduces one step of delay.
    </itemize>

    <new-page*><item>User actions:

    <hlkwa|let ><hlstd|lbp ><hlopt|: ><hlkwb|unit ><hlstd|event
    ><hlopt|=><hlendline|><next-line><hlstd| \ memo1 ><hlopt|(><hlkwa|fun
    ><hlstd|uts ><hlopt|-\<gtr\> ><hlstd|lmap<hlendline|><next-line>
    \ \ \ ><hlopt|(><hlkwa|function ><hlkwd|Some><hlopt|(><hlkwd|Button><hlopt|(><hlstd|<textunderscore>><hlopt|,><hlstd|<textunderscore>><hlopt|)),
    ><hlstd|<textunderscore> ><hlopt|-\<gtr\> ><hlkwd|Some><hlopt|()
    ><hlstd|<hlopt|\|> <textunderscore> ><hlopt|-\<gtr\>><hlkwd|
    None><hlopt|)><next-line><hlstd| \ \ \ uts><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|mm ><hlopt|: (><hlkwb|int ><hlopt|* ><hlkwb|int><hlopt|)
    ><hlstd|event ><hlopt|=><hlendline|><next-line><hlstd| \ memo1
    ><hlopt|(><hlkwa|fun ><hlstd|uts ><hlopt|-\<gtr\>
    ><hlstd|lmap<hlendline|><next-line> \ ><hlopt|(><hlkwa|function
    ><hlkwd|Some><hlopt|(><hlkwd|MouseMove><hlopt|(><hlstd|x><hlopt|,><hlstd|y><hlopt|)),><hlstd|<textunderscore>
    ><hlopt|-\<gtr\>><hlkwd|Some><hlopt|(><hlstd|x><hlopt|,><hlstd|y><hlopt|)
    ><hlstd|<hlopt|\|> <textunderscore> ><hlopt|-\<gtr\>><hlkwd|None><hlopt|)><next-line><hlstd|
    \ \ \ uts><hlopt|)><hlendline|><next-line><hlkwa|let ><hlstd|screen
    ><hlopt|: (><hlkwb|int ><hlopt|* ><hlkwb|int><hlopt|) ><hlstd|event
    ><hlopt|=><hlendline|><next-line><hlstd| \ memo1 ><hlopt|(><hlkwa|fun
    ><hlstd|uts ><hlopt|-\<gtr\> ><hlstd|lmap<hlendline|><next-line>
    \ \ \ ><hlopt|(><hlkwa|function ><hlkwd|Some><hlopt|(><hlkwd|Resize><hlopt|(><hlstd|x><hlopt|,><hlstd|y><hlopt|)),><hlstd|<textunderscore>
    ><hlopt|-\<gtr\>><hlkwd|Some><hlopt|(><hlstd|x><hlopt|,><hlstd|y><hlopt|)
    ><hlstd|<hlopt|\|> <textunderscore> ><hlopt|-\<gtr\>><hlkwd|None><hlopt|)><next-line><hlstd|
    \ \ \ uts><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|mouse<textunderscore>x ><hlopt|: ><hlkwb|int ><hlstd|behavior
    ><hlopt|= ><hlstd|step ><hlnum|0 ><hlopt|(><hlstd|liftE fst
    mm><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|mouse<textunderscore>y ><hlopt|: ><hlkwb|int ><hlstd|behavior
    ><hlopt|= ><hlstd|step ><hlnum|0 ><hlopt|(><hlstd|liftE snd
    mm><hlopt|)><hlendline|><next-line><hlkwa|let ><hlstd|width ><hlopt|:
    ><hlkwb|int ><hlstd|behavior ><hlopt|= ><hlstd|step ><hlnum|640
    ><hlopt|(><hlstd|liftE fst screen><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|height ><hlopt|: ><hlkwb|int ><hlstd|behavior ><hlopt|=
    ><hlstd|step ><hlnum|512 ><hlopt|(><hlstd|liftE snd
    screen><hlopt|)><hlendline|>
  </itemize>

  <subsubsection|<new-page*>The Paddle Game example>

  <\itemize>
    <item>A <em|scene graph> is a data structure that represents a ``world''
    which can be drawn on screen.

    <hlkwa|type ><hlstd|scene ><hlopt|=><hlendline|><next-line><hlopt|\|
    ><hlkwd|Rect ><hlkwa|of ><hlkwb|int ><hlopt|* ><hlkwb|int ><hlopt|*
    ><hlkwb|int ><hlopt|* ><hlkwb|int><hlendline|position, width,
    height><next-line><hlopt|\| ><hlkwd|Circle ><hlkwa|of ><hlkwb|int
    ><hlopt|* ><hlkwb|int ><hlopt|* ><hlkwb|int><hlendline|position,
    radius><next-line><hlopt|\| ><hlkwd|Group ><hlkwa|of ><hlstd|scene
    list<hlendline|><next-line><hlopt|\|> ><hlkwd|Color ><hlkwa|of
    ><hlkwc|Graphics><hlopt|.><hlstd|color ><hlopt|*
    ><verbatim|scene><hlendline|color of subscene
    objects><next-line><hlopt|\|><verbatim| ><hlkwd|Translate ><hlkwa|of
    ><hlkwb|float ><hlopt|* ><hlkwb|float ><hlopt|*
    ><hlstd|scene><hlendline|additional offset of origin>

    <new-page*><item>Drawing a scene explains what we mean above.

    <hlkwa|let ><hlstd|draw sc ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|f2i ><hlopt|= ><hlstd|int<textunderscore>of<textunderscore>float
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let open
    ><hlkwd|Graphics ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
    rec ><hlstd|aux t<textunderscore>x t<textunderscore>y ><hlopt|=
    ><hlkwa|function><hlendline|Accumulate translations.><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|Rect ><hlopt|(><hlstd|x><hlopt|, ><hlstd|y><hlopt|,
    ><hlstd|w><hlopt|, ><hlstd|h><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ fill<textunderscore>rect
    ><hlopt|(><hlstd|f2i t<textunderscore>x><hlopt|+><hlstd|x><hlopt|)
    (><hlstd|f2i t<textunderscore>y><hlopt|+><hlstd|y><hlopt|) ><hlstd|w
    h<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Circle
    ><hlopt|(><hlstd|x><hlopt|, ><hlstd|y><hlopt|, ><hlstd|r><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ fill<textunderscore>circle
    ><hlopt|(><hlstd|f2i t<textunderscore>x><hlopt|+><hlstd|x><hlopt|)
    (><hlstd|f2i t<textunderscore>y><hlopt|+><hlstd|y><hlopt|)
    ><hlstd|r<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Group ><hlstd|scs
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwc|List><hlopt|.><hlstd|iter ><hlopt|(><hlstd|aux
    t<textunderscore>x t<textunderscore>y><hlopt|)
    ><verbatim|scs><hlendline|<math|\<swarrow\>> \ Set color for
    <verbatim|sc> objects.><next-line><verbatim| \ ><hlopt|\| ><hlkwd|Color
    ><hlopt|(><hlstd|c><hlopt|, ><hlstd|sc><hlopt|) -\<gtr\>
    ><hlstd|set<textunderscore>color c><hlopt|; ><hlstd|aux
    t<textunderscore>x t<textunderscore>y sc<hlendline|><next-line>
    \ ><hlopt|\| ><hlkwd|Translate ><hlopt|(><hlstd|x><hlopt|,
    ><hlstd|y><hlopt|, ><hlstd|sc><hlopt|) -\<gtr\> ><hlstd|aux
    ><hlopt|(><hlstd|t<textunderscore>x><hlopt|+.><hlstd|x><hlopt|)
    (><hlstd|t<textunderscore>y><hlopt|+.><hlstd|y><hlopt|) ><hlstd|sc
    ><hlkwa|in><hlendline|><next-line><hlstd| \ clear<textunderscore>graph
    ><hlopt|();><hlendline|``Fast and clean'' removing of previous
    picture.><next-line><hlstd| \ aux ><hlnum|0><hlopt|. ><hlnum|0><hlopt|.
    ><hlstd|sc><hlopt|;><hlendline|><next-line><hlstd| \ synchronize
    ><hlopt|()><hlendline|Synchronize the <em|double buffer> -- avoiding
    flickering.>

    <verbatim|><new-page*><item>An animation is a scene behavior. To animate
    it we need to create the input stream: the user actions and sampling
    times stream.

    <\itemize>
      <item>We could abstract away drawing from time sampling in
      <verbatim|reactimate>, asking for (i.e. passing as argument) a producer
      of user actions and a consumer of scene graphs (like <verbatim|draw>).
    </itemize>

    <\small>
      <hlkwa|let ><hlstd|reactimate ><hlopt|(><hlstd|anim ><hlopt|:
      ><hlstd|scene behavior><hlopt|) =><hlendline|><next-line><hlstd|
      \ ><hlkwa|let open ><hlkwd|Graphics
      ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
      ><hlstd|not<textunderscore>b ><hlopt|= ><hlkwa|function ><hlkwd|Some
      ><hlopt|(><hlkwd|Button ><hlopt|(><hlstd|<textunderscore>><hlopt|,><hlstd|<textunderscore>><hlopt|))
      -\<gtr\> ><hlkwa|false ><hlstd|<hlopt|\|> <textunderscore>
      ><hlopt|-\<gtr\> ><hlkwa|true in><hlendline|><next-line><hlstd|
      \ ><hlkwa|let ><hlstd|current old<textunderscore>m
      old<textunderscore>scr ><hlopt|(><hlstd|old<textunderscore>u><hlopt|,
      ><hlstd|t0><hlopt|) =><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
      rec ><hlstd|delay ><hlopt|() =><hlendline|><next-line><hlstd|
      \ \ \ \ \ ><hlkwa|let ><hlstd|t1 ><hlopt|=
      ><hlkwc|Unix><hlopt|.><hlstd|gettimeofday ><hlopt|()
      ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|let
      ><hlstd|d ><hlopt|= ><hlnum|0.01 ><hlopt|-. (><hlstd|t1 ><hlopt|-.
      ><hlstd|t0><hlopt|) ><hlkwa|in><hlendline|><next-line><hlstd|
      \ \ \ \ \ ><hlkwa|try if ><hlstd|d ><hlopt|\<gtr\> ><hlnum|0><hlopt|.
      ><hlkwa|then ><hlkwc|Thread><hlopt|.><hlstd|delay
      d><hlopt|;><hlendline|><next-line><hlstd|
      \ \ \ \ \ \ \ \ \ ><hlkwc|Unix><hlopt|.><hlstd|gettimeofday
      ><hlopt|()><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|with
      ><hlkwc|Unix><hlopt|.><hlkwd|Unix<textunderscore>error
      ><hlopt|(><hlcom|(* Unix.EAGAIN *)><hlstd|<textunderscore>><hlopt|,
      ><hlstd|<textunderscore>><hlopt|, ><hlstd|<textunderscore>><hlopt|)
      -\<gtr\> ><hlstd|delay ><hlopt|() ><hlkwa|in><hlendline|><next-line><hlstd|
      \ \ \ ><hlkwa|let ><hlstd|t1 ><hlopt|= ><hlstd|delay ><hlopt|()
      ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|s
      ><hlopt|= ><hlkwc|Graphics><hlopt|.><hlstd|wait<textunderscore>next<textunderscore>event
      ><hlopt|[><hlkwd|Poll><hlopt|] ><hlkwa|in><hlendline|><next-line><hlstd|
      \ \ \ ><hlkwa|let ><hlstd|x ><hlopt|=
      ><hlstd|s><hlopt|.><hlstd|mouse<textunderscore>x ><hlkwa|and ><hlstd|y
      ><hlopt|= ><hlstd|s><hlopt|.><hlstd|mouse<textunderscore>y<hlendline|><next-line>
      \ \ \ ><hlkwa|and ><hlstd|scr<textunderscore>x ><hlopt|=
      ><hlkwc|Graphics><hlopt|.><hlstd|size<textunderscore>x ><hlopt|()
      ><hlkwa|and ><hlstd|scr<textunderscore>y ><hlopt|=
      ><hlkwc|Graphics><hlopt|.><hlstd|size<textunderscore>y ><hlopt|()
      ><hlkwa|in><hlendline|>

      <new-page*><hlstd| \ \ \ ><hlkwa|let ><hlstd|ue
      ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|if
      ><hlstd|s><hlopt|.><hlstd|keypressed ><hlkwa|then ><hlkwd|Some
      ><hlopt|(><hlkwd|Key ><hlstd|s><hlopt|.><hlstd|key><hlopt|)><hlendline|><next-line><hlstd|
      \ \ \ \ \ ><hlkwa|else if ><hlopt|(><hlstd|scr<textunderscore>x><hlopt|,
      ><hlstd|scr<textunderscore>y><hlopt|) \<less\>\<gtr\>
      ><hlstd|old<textunderscore>scr ><hlkwa|then ><hlkwd|Some
      ><hlopt|(><hlkwd|Resize><hlopt| (><hlstd|scr<textunderscore>x><hlopt|,><hlstd|scr<textunderscore>y><hlopt|))><next-line><hlstd|
      \ \ \ \ \ ><hlkwa|else if ><hlstd|s><hlopt|.><hlstd|button ><hlopt|&&
      ><hlstd|not<textunderscore>b old<textunderscore>u ><hlkwa|then
      ><hlkwd|Some ><hlopt|(><hlkwd|Button ><hlopt|(><hlstd|x><hlopt|,
      ><hlstd|y><hlopt|))><hlendline|><next-line><hlstd|
      \ \ \ \ \ ><hlkwa|else if ><hlopt|(><hlstd|x><hlopt|,
      ><hlstd|y><hlopt|) \<less\>\<gtr\> ><hlstd|old<textunderscore>m
      ><hlkwa|then ><hlkwd|Some ><hlopt|(><hlkwd|MouseMove
      ><hlopt|(><hlstd|x><hlopt|, ><hlstd|y><hlopt|))><hlendline|><next-line><hlstd|
      \ \ \ \ \ ><hlkwa|else ><hlkwd|None
      ><hlkwa|in><hlendline|><next-line><hlstd|
      \ \ \ ><hlopt|(><hlstd|x><hlopt|, ><hlstd|y><hlopt|),
      (><hlstd|scr<textunderscore>x><hlopt|,
      ><hlstd|scr<textunderscore>y><hlopt|), (><hlstd|ue><hlopt|,
      ><hlstd|t1><hlopt|) ><hlkwa|in><hlendline|><next-line><hlstd|
      \ open<textunderscore>graph ><hlstr|""><hlopt|;><hlendline|Open
      window.><next-line><hlstd| \ display<textunderscore>mode
      ><hlkwa|false><hlopt|;><hlendline|Draw using <em|double
      buffering>.><next-line><hlstd| \ ><hlkwa|let ><hlstd|t0 ><hlopt|=
      ><hlkwc|Unix><hlopt|.><hlstd|gettimeofday ><hlopt|()
      ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let rec
      ><hlstd|utstep mpos scr ut ><hlopt|= ><hlkwa|lazy
      ><hlopt|(><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
      ><hlstd|mpos><hlopt|, ><hlstd|scr><hlopt|, ><hlstd|ut ><hlopt|=
      ><hlstd|current mpos scr ut ><hlkwa|in><hlendline|><next-line><hlstd|
      \ \ \ ><hlkwd|Cons ><hlopt|(><hlstd|ut><hlopt|, ><hlstd|utstep mpos scr
      ut><hlopt|)) ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
      ><hlstd|scr ><hlopt|= ><hlkwc|Graphics><hlopt|.><hlstd|size<textunderscore>x
      ><hlopt|(), ><hlkwc|Graphics><hlopt|.><hlstd|size<textunderscore>y
      ><hlopt|() ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
      ><hlstd|ut0 ><hlopt|= ><hlkwd|Some ><hlopt|(><hlkwd|Resize
      ><hlopt|(><hlstd|fst scr><hlopt|, ><hlstd|snd scr><hlopt|)), ><hlstd|t0
      ><hlkwa|in><hlendline|><next-line><hlstd| \ liter draw
      ><hlopt|(><hlstd|anim $ ><hlkwa|lazy ><hlopt|(><hlkwd|Cons
      ><hlopt|(><hlstd|ut0><hlopt|, ><hlstd|utstep
      ><hlopt|(><hlnum|0><hlopt|,><hlnum|0><hlopt|) ><hlstd|scr
      ut0><hlopt|)));><hlendline|><next-line><hlstd|
      \ close<textunderscore>graph ><hlopt|()><hlendline|Close window --
      unfortunately never happens.>
    </small>

    <new-page*><item>General-purpose behavior operators.

    <hlkwa|let ><hlopt|(+><hlstd|*) ><hlopt|= ><hlstd|liftB2
    ><hlopt|(+)><hlendline|><next-line><hlkwa|let ><hlopt|(-><hlstd|*)
    ><hlopt|= ><hlstd|liftB2 ><hlopt|(-)><hlendline|><next-line><hlkwa|let
    ><hlopt|( *** ) = ><hlstd|liftB2 ><hlopt|( *
    )><hlendline|><next-line><hlkwa|let ><hlopt|(/><hlstd|*) ><hlopt|=
    ><hlstd|liftB2 ><hlopt|(/)><hlendline|><next-line><hlkwa|let
    ><hlopt|(&&><hlstd|*) ><hlopt|= ><hlstd|liftB2
    ><hlopt|(&&)><hlendline|><next-line><hlkwa|let
    ><hlopt|(><hlstd|<hlopt|\|><hlopt|\||*>) ><hlopt|= ><hlstd|liftB2
    ><hlopt|(><hlstd|<hlopt|\|\|>><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlopt|(\<less\>><hlstd|*) ><hlopt|= ><hlstd|liftB2
    ><hlopt|(\<less\>)><hlendline|><next-line><hlkwa|let
    ><hlopt|(\<gtr\>><hlstd|*) ><hlopt|= ><hlstd|liftB2
    ><hlopt|(\<gtr\>)><hlendline|>

    <item>The walls are drawn on left, top and right borders of the window.

    <hlkwa|let ><hlstd|walls ><hlopt|=><hlendline|><next-line><hlstd|
    \ liftB2 ><hlopt|(><hlkwa|fun ><hlstd|w h ><hlopt|-\<gtr\> ><hlkwd|Color
    ><hlopt|(><hlkwc|Graphics><hlopt|.><hlstd|blue><hlopt|,
    ><hlkwd|Group><hlendline|><next-line><hlstd| \ \ \ ><hlopt|[><hlkwd|Rect
    ><hlopt|(><hlnum|0><hlopt|, ><hlnum|0><hlopt|, ><hlnum|20><hlopt|,
    ><hlstd|h><hlopt|-><hlnum|1><hlopt|); ><hlkwd|Rect
    ><hlopt|(><hlnum|0><hlopt|, ><hlstd|h><hlopt|-><hlnum|21><hlopt|,
    ><hlstd|w><hlopt|-><hlnum|1><hlopt|, ><hlnum|20><hlopt|);><hlendline|><next-line><hlstd|
    \ \ \ \ ><hlkwd|Rect ><hlopt|(><hlstd|w><hlopt|-><hlnum|21><hlopt|,
    ><hlnum|0><hlopt|, ><hlnum|20><hlopt|,
    ><hlstd|h><hlopt|-><hlnum|1><hlopt|)]))><hlendline|><next-line><hlstd|
    \ \ \ width height><hlendline|>

    <item>The paddle is tied to the mouse at the bottom border of the window.

    <hlkwa|let ><hlstd|paddle ><hlopt|= ><hlstd|liftB ><hlopt|(><hlkwa|fun
    ><hlstd|mx ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ ><hlkwd|Color ><hlopt|(><hlkwc|Graphics><hlopt|.><hlstd|black><hlopt|,
    ><hlkwd|Rect ><hlopt|(><hlstd|mx><hlopt|, ><hlnum|0><hlopt|,
    ><hlnum|50><hlopt|, ><hlnum|10><hlopt|)))
    ><hlstd|mouse<textunderscore>x><hlendline|>

    <new-page*><item>The ball has a velocity in pixels per second. It bounces
    from the walls, which is hard-coded in terms of distance from window
    borders.

    <\itemize>
      <item>Unfortunately OCaml, being an eager language, does not let us
      encode recursive behaviors in elegant way. \ We need to unpack
      behaviors and events as functions of the input stream.

      <item><hlstd|xbounce ><hlopt|-\<gtr\>\<gtr\>
      (><hlstd|<math|\<sim\>>><hlopt|-.)> event is just the negation function
      happening at each horizontal bounce.

      <item><hlstd|step<textunderscore>accum vel ><hlopt|(><hlstd|xbounce
      ><hlopt|-\<gtr\>\<gtr\> (><hlstd|<math|\<sim\>>><hlopt|-.))> behavior
      is <verbatim|vel> value changing sign at each horizontal bounce.

      <item><hlstd|liftB int<textunderscore>of<textunderscore>float
      ><hlopt|(><hlstd|integral xvel><hlopt|) +* ><hlstd|width ><hlopt|/*
      !*><hlnum|2> -- first integrate velocity, then truncate it to integers
      and offset to the middle of the window.

      <item><hlstd|whenB ><hlopt|((><hlstd|xpos ><hlopt|\<gtr\>*
      ><hlstd|width ><hlopt|-* !*><hlnum|27><hlopt|)
      ><hlstd|<hlopt|\|\|>><hlopt|* (><hlstd|xpos ><hlopt|\<less\>*
      !*><hlnum|27><hlopt|))> -- issue an event the first time the position
      exceeds the bounds. This ensures there are no further bouncings until
      the ball moves out of the walls.
    </itemize>
  </itemize>

  <small|<new-page*><hlkwa|let ><hlstd|pbal vel
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let rec
  ><hlstd|xvel<textunderscore> uts ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ step<textunderscore>accum vel ><hlopt|(><hlstd|xbounce
  ><hlopt|-\<gtr\>\<gtr\> (><hlstd|<math|\<sim\>>><hlopt|-.)) ><hlstd|$
  uts<hlendline|><next-line> \ ><hlkwa|and ><hlstd|xvel ><hlopt|=
  {><hlstd|memo<textunderscore>f ><hlopt|=
  ><hlstd|xvel<textunderscore>><hlopt|; ><hlstd|memo<textunderscore>r
  ><hlopt|= ><hlkwd|None><hlopt|}><hlendline|><next-line><hlstd|
  \ ><hlkwa|and ><hlstd|xpos<textunderscore> uts
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlopt|(><hlstd|liftB
  int<textunderscore>of<textunderscore>float ><hlopt|(><hlstd|integral
  xvel><hlopt|) +* ><hlstd|width ><hlopt|/* !*><hlnum|2><hlopt|) ><hlstd|$
  uts<hlendline|><next-line> \ ><hlkwa|and ><hlstd|xpos ><hlopt|=
  {><hlstd|memo<textunderscore>f ><hlopt|=
  ><hlstd|xpos<textunderscore>><hlopt|; ><hlstd|memo<textunderscore>r
  ><hlopt|= ><hlkwd|None><hlopt|}><hlendline|><next-line><hlstd|
  \ ><hlkwa|and ><hlstd|xbounce<textunderscore> uts ><hlopt|=
  ><hlstd|whenB<hlendline|><next-line> \ \ \ ><hlopt|((><hlstd|xpos
  ><hlopt|\<gtr\>* ><hlstd|width ><hlopt|-* !*><hlnum|27><hlopt|)
  ><hlstd|<hlopt|\|\|>><hlopt|* (><hlstd|xpos ><hlopt|\<less\>*
  !*><hlnum|27><hlopt|)) ><hlstd|$ uts<hlendline|><next-line> \ ><hlkwa|and
  ><hlstd|xbounce ><hlopt|= {><hlstd|memo<textunderscore>f ><hlopt|=
  ><hlstd|xbounce<textunderscore>><hlopt|; ><hlstd|memo<textunderscore>r
  ><hlopt|= ><hlkwd|None><hlopt|} ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwa|let rec ><hlstd|yvel<textunderscore> uts
  ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|(><hlstd|step<textunderscore>accum vel
  ><hlopt|(><hlstd|ybounce ><hlopt|-\<gtr\>\<gtr\>
  (><hlstd|<math|\<sim\>>><hlopt|-.))) ><hlstd|$ uts<hlendline|><next-line>
  \ ><hlkwa|and ><hlstd|yvel ><hlopt|= {><hlstd|memo<textunderscore>f
  ><hlopt|= ><hlstd|yvel<textunderscore>><hlopt|;
  ><hlstd|memo<textunderscore>r ><hlopt|=
  ><hlkwd|None><hlopt|}><hlendline|><next-line><hlstd| \ ><hlkwa|and
  ><hlstd|ypos<textunderscore> uts ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|(><hlstd|liftB int<textunderscore>of<textunderscore>float
  ><hlopt|(><hlstd|integral yvel><hlopt|) +* ><hlstd|height ><hlopt|/*
  !*><hlnum|2><hlopt|) ><hlstd|$ uts<hlendline|><next-line> \ ><hlkwa|and
  ><hlstd|ypos ><hlopt|= {><hlstd|memo<textunderscore>f ><hlopt|=
  ><hlstd|ypos<textunderscore>><hlopt|; ><hlstd|memo<textunderscore>r
  ><hlopt|= ><hlkwd|None><hlopt|}><hlendline|><next-line><hlstd|
  \ ><hlkwa|and ><hlstd|ybounce<textunderscore> uts ><hlopt|= ><hlstd|whenB
  ><hlopt|(><hlendline|><next-line><hlstd| \ \ \ ><hlopt|(><hlstd|ypos
  ><hlopt|\<gtr\>* ><hlstd|height ><hlopt|-* !*><hlnum|27><hlopt|)
  ><hlstd|<hlopt|\|\|>><hlopt|*><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|((><hlstd|ypos ><hlopt|\<less\>* !*><hlnum|17><hlopt|)
  &&* (><hlstd|ypos ><hlopt|\<gtr\>* !*><hlnum|7><hlopt|)
  &&*><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|xpos
  ><hlopt|\<gtr\>* ><hlstd|mouse<textunderscore>x><hlopt|) &&* (><hlstd|xpos
  ><hlopt|\<less\>* ><hlstd|mouse<textunderscore>x ><hlopt|+*
  !*><hlnum|50><hlopt|))) ><hlstd|$ uts<hlendline|><next-line> \ ><hlkwa|and
  ><hlstd|ybounce ><hlopt|= {><hlstd|memo<textunderscore>f ><hlopt|=
  ><hlstd|ybounce<textunderscore>><hlopt|; ><hlstd|memo<textunderscore>r
  ><hlopt|= ><hlkwd|None><hlopt|} ><hlkwa|in><hlendline|><next-line><hlstd|
  \ liftB2 ><hlopt|(><hlkwa|fun ><hlstd|x y ><hlopt|-\<gtr\> ><hlkwd|Color
  ><hlopt|(><hlkwc|Graphics><hlopt|.><hlstd|red><hlopt|, ><hlkwd|Circle
  ><hlopt|(><hlstd|x><hlopt|, ><hlstd|y><hlopt|,
  ><hlnum|6><hlopt|)))><hlendline|><next-line><hlstd| \ \ \ xpos
  ypos><hlendline|>>

  <\itemize>
    <new-page*><item>Invocation:

    <verbatim|ocamlbuild Lec10b.native -cflags -I,+threads<next-line> \ -libs
    graphics,unix,threads/threads -->

    <item><image|Lec10b.png|602px|479px||><verbatim|>
  </itemize>

  <section|<new-page*>Reactivity by Incremental Computing>

  <\itemize>
    <item>In <em|Froc> behaviors and events are both implemented as
    changeables but only behaviors persist, events are ``instantaneous''.

    <\itemize>
      <item>Behaviors are composed out of constants and prior events, capture
      the ``changeable'' aspect.

      <item>Events capture the ``writeable'' aspect -- after their values are
      propagated, the values are removed.
    </itemize>

    Events and behaviors are called <em|signals>.

    <item><em|Froc> does not represent time, and provides the function
    <hlstd|changes ><hlopt|: ><hlstd|'a behavior ><hlopt|-\<gtr\> ><hlstd|'a
    event>, which violates the continuous semantics we introduced before.

    <\itemize>
      <item>It breaks the illusion that behaviors vary continuously rather
      than at discrete points in time.

      <item>But it avoids the need to synchronize global time samples with
      events in the system. <small|It is ``less continuous but more dense''.>
    </itemize>

    <item>Sending an event -- <verbatim|send> -- starts an <em|update cycle>.
    Signals cannot call <verbatim|send>, but can <verbatim|send_deferred>
    which will send an event in next cycle.

    <\itemize>
      <item>Things that happen in the same update cycle are
      <em|simultaneous>.

      <item>Events are removed (detached from dependency graph) after an
      update cycle.
    </itemize>

    <item><em|Froc> provides the <verbatim|fix_b>, <verbatim|fix_e> functions
    to define signals recursively. Current value refers to value from
    previous update cycle, and defers next recursive step to next cycle,
    until convergence.

    <item>Update cycles can happen ``back-to-back'' via
    <verbatim|send_deferred> and <verbatim|fix_b>, <verbatim|fix_e>, or can
    be invoked from outside <em|Froc> by sending events at arbitrary times.

    <\itemize>
      <item>With a <verbatim|time> behavior that holds a <verbatim|clock>
      event value, events from ``back-to-back'' update cycles can be at the
      same clock time although not simultaneous in this sense.

      <item>Update cycles prevent <em|glitches>, where outdated signal is
      used e.g. to issue an event.
    </itemize>

    <new-page*><item>Let's familiarize ourselves with <em|Froc>
    API:<next-line><hlink|http://jaked.github.com/froc/doc/Froc.html|http://jaked.github.com/froc/doc/Froc.html>

    <item>A behavior is written in <em|pure style>, when its definition does
    not use <verbatim|send>, <verbatim|send_deferred>, <verbatim|notify_e>,
    <verbatim|notify_b> and <verbatim|sample>:

    <\itemize>
      <item><verbatim|sample>, <verbatim|notify_e>, <verbatim|notify_b> are
      used from outside the behavior (from its ``environment'') analogously
      to observing result of a function,

      <item><verbatim|send>, <verbatim|send_deferred> are used from outside
      analogously to providing input to a function.
    </itemize>

    <item>We will develop an example in a pragmatic, <em|impure> style, but
    since purity is an important aspect of functional programming, I propose
    to rewrite it in pure style as an exercise (ex. 5).

    <item>When writing in impure style we need to remember to refer from
    somewhere to all the pieces of our behavior, otherwise the unreferred
    parts will be <strong|garbage collected> breaking the behavior.

    <\itemize>
      <item>A value is referred to, when it has a name in the global
      environment or is part of a bigger value that is referred to (for
      example it's stored somewhere). Signals can be referred to by being
      part of the dependency graph, but also by any of the more general ways.
    </itemize>
  </itemize>

  <subsubsection|<new-page*>Reimplementing the Paddle Game example>

  <\itemize>
    <item>Rather than following our incremental computing example (a scene
    with changeable parts), we follow our FRP example: a scene behavior.

    <item>First we introduce time:

    <hlkwa|open ><hlkwd|Froc><hlendline|><next-line><hlkwa|let
    ><hlstd|clock><hlopt|, ><hlstd|tick ><hlopt|=
    ><hlstd|make<textunderscore>event ><hlopt|()><hlendline|><next-line><hlkwa|let
    ><hlstd|time ><hlopt|= ><hlstd|hold ><hlopt|(><hlkwc|Unix><hlopt|.><hlstd|gettimeofday
    ><hlopt|()) ><hlstd|clock><hlendline|>

    <item>Next we define integration:

    <hlkwa|let ><hlstd|integral fb ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|aux ><hlopt|(><hlstd|sum><hlopt|,
    ><hlstd|t0><hlopt|) ><hlstd|t1 ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ sum ><hlopt|+. (><hlstd|t1 ><hlopt|-. ><hlstd|t0><hlopt|) *.
    ><hlstd|sample fb><hlopt|, ><hlstd|t1
    ><hlkwa|in><hlendline|><next-line><hlstd| \ collect<textunderscore>b aux
    ><hlopt|(><hlnum|0><hlopt|., ><hlstd|sample time><hlopt|)
    ><hlstd|clock><hlendline|>

    For convenience, the integral remembers the current upper limit of
    integration. It will be useful to get the integer part:

    <hlkwa|let ><hlstd|integ<textunderscore>res fb
    ><hlopt|=><hlendline|><next-line><hlstd| \ lift ><hlopt|(><hlkwa|fun
    ><hlopt|(><hlstd|v><hlopt|,><hlstd|<textunderscore>><hlopt|) -\<gtr\>
    ><hlstd|int<textunderscore>of<textunderscore>float v><hlopt|)
    (><hlstd|integral fb><hlopt|)><hlendline|>

    \;

    <item>We can also define integration in pure style:

    <hlkwa|let ><hlstd|pair fa fb ><hlopt|= ><hlstd|lift2
    ><hlopt|(><hlkwa|fun ><hlstd|x y ><hlopt|-\<gtr\> ><hlstd|x><hlopt|,
    ><hlstd|y><hlopt|) ><hlstd|fa fb><hlendline|><next-line><hlkwa|let
    ><hlstd|integral<textunderscore>nice fb
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|samples
    ><hlopt|= ><hlstd|changes ><hlopt|(><hlstd|pair fb time><hlopt|)
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|aux
    ><hlopt|(><hlstd|sum><hlopt|, ><hlstd|t0><hlopt|) (><hlstd|fv><hlopt|,
    ><hlstd|t1><hlopt|) =><hlendline|><next-line><hlstd| \ \ \ sum ><hlopt|+.
    (><hlstd|t1 ><hlopt|-. ><hlstd|t0><hlopt|) *. ><hlstd|fv><hlopt|,
    ><hlstd|t1 ><hlkwa|in><hlendline|><next-line><hlstd|
    \ collect<textunderscore>b aux ><hlopt|(><hlnum|0><hlopt|.,
    ><hlstd|sample time><hlopt|) ><hlstd|samples><hlendline|>

    The initial value <hlopt|(><hlnum|0><hlopt|., ><hlstd|sample
    time><hlopt|)> is not ``inside'' the behavior so <verbatim|sample> here
    does not spoil the pure style.

    <item>The <verbatim|scene> datatype and how we <verbatim|draw> a scene
    does not change.

    <new-page*><item>Signals which will be sent to behaviors:

    <\small>
      <hlkwa|let ><hlstd|mouse<textunderscore>move<textunderscore>x><hlopt|,
      ><hlstd|move<textunderscore>mouse<textunderscore>x ><hlopt|=
      ><hlstd|make<textunderscore>event ><hlopt|()><hlendline|><next-line><hlkwa|let
      ><hlstd|mouse<textunderscore>move<textunderscore>y><hlopt|,
      ><hlstd|move<textunderscore>mouse<textunderscore>y ><hlopt|=
      ><hlstd|make<textunderscore>event ><hlopt|()><hlendline|><next-line><hlkwa|let
      ><hlstd|mouse<textunderscore>x ><hlopt|= ><hlstd|hold ><hlnum|0
      ><hlstd|mouse<textunderscore>move<textunderscore>x><hlendline|><next-line><hlkwa|let
      ><hlstd|mouse<textunderscore>y ><hlopt|= ><hlstd|hold ><hlnum|0
      ><hlstd|mouse<textunderscore>move<textunderscore>x><hlendline|><next-line><hlkwa|let
      ><hlstd|width<textunderscore>resized><hlopt|,
      ><hlstd|resize<textunderscore>width ><hlopt|=
      ><hlstd|make<textunderscore>event ><hlopt|()><hlendline|><next-line><hlkwa|let
      ><hlstd|height<textunderscore>resized><hlopt|,
      ><hlstd|resize<textunderscore>height ><hlopt|=
      ><hlstd|make<textunderscore>event ><hlopt|()><hlendline|><next-line><hlkwa|let
      ><hlstd|width ><hlopt|= ><hlstd|hold ><hlnum|640
      ><hlstd|width<textunderscore>resized><hlendline|><next-line><hlkwa|let
      ><hlstd|height ><hlopt|= ><hlstd|hold ><hlnum|512
      ><hlstd|height<textunderscore>resized><hlendline|><next-line><hlkwa|let
      ><hlstd|mbutton<textunderscore>pressed><hlopt|,
      ><hlstd|press<textunderscore>mbutton ><hlopt|=
      ><hlstd|make<textunderscore>event ><hlopt|()><hlendline|><next-line><hlkwa|let
      ><hlstd|key<textunderscore>pressed><hlopt|,
      ><hlstd|press<textunderscore>key ><hlopt|=
      ><hlstd|make<textunderscore>event ><hlopt|()><hlendline|>
    </small>

    <item>The user interface main loop, emiting signals and observing
    behaviors:

    <small|<hlkwa|let ><hlstd|reactimate ><hlopt|(><hlstd|anim ><hlopt|:
    ><hlstd|scene behavior><hlopt|) =><hlendline|><next-line><hlstd|
    \ ><hlkwa|let open ><hlkwd|Graphics ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwa|let rec ><hlstd|loop omx omy osx osy omb t0
    ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let rec
    ><hlstd|delay ><hlopt|() =><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|let ><hlstd|t1 ><hlopt|=
    ><hlkwc|Unix><hlopt|.><hlstd|gettimeofday ><hlopt|()
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|let ><hlstd|d
    ><hlopt|= ><hlnum|0.01 ><hlopt|-. (><hlstd|t1 ><hlopt|-.
    ><hlstd|t0><hlopt|) ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|try if ><hlstd|d ><hlopt|\<gtr\> ><hlnum|0><hlopt|.
    ><hlkwa|then ><hlkwc|Thread><hlopt|.><hlstd|delay
    d><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ ><hlkwc|Unix><hlopt|.><hlstd|gettimeofday
    ><hlopt|()><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|with
    ><hlkwc|Unix><hlopt|.><hlkwd|Unix<textunderscore>error
    ><hlopt|(><hlcom|(* Unix.EAGAIN *)><hlstd|<textunderscore>><hlopt|,
    ><hlstd|<textunderscore>><hlopt|, ><hlstd|<textunderscore>><hlopt|)
    -\<gtr\> ><hlstd|delay ><hlopt|() ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|t1 ><hlopt|= ><hlstd|delay ><hlopt|()
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|s
    ><hlopt|= ><hlkwc|Graphics><hlopt|.><hlstd|wait<textunderscore>next<textunderscore>event
    ><hlopt|[><hlkwd|Poll><hlopt|] ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|x ><hlopt|=
    ><hlstd|s><hlopt|.><hlstd|mouse<textunderscore>x ><hlkwa|and ><hlstd|y
    ><hlopt|= ><hlstd|s><hlopt|.><hlstd|mouse<textunderscore>y<hlendline|><next-line>
    \ \ \ ><hlkwa|and ><hlstd|scr<textunderscore>x ><hlopt|=
    ><hlkwc|Graphics><hlopt|.><hlstd|size<textunderscore>x ><hlopt|()
    ><hlkwa|and ><hlstd|scr<textunderscore>y ><hlopt|=
    ><hlkwc|Graphics><hlopt|.><hlstd|size<textunderscore>y ><hlopt|()
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|if
    ><hlstd|s><hlopt|.><hlstd|keypressed ><hlkwa|then ><hlstd|send
    press<textunderscore>key s><hlopt|.><hlstd|key><hlopt|;><hlendline|We can
    send signals><next-line><hlstd| \ \ \ ><hlkwa|if
    ><hlstd|scr<textunderscore>x ><hlopt|\<less\>\<gtr\> ><hlstd|osx
    ><hlkwa|then ><hlstd|send resize<textunderscore>width
    scr<textunderscore>x><hlopt|;><hlendline|one by one.><next-line><hlstd|
    \ \ \ ><hlkwa|if ><hlstd|scr<textunderscore>y ><hlopt|\<less\>\<gtr\>
    ><hlstd|osy ><hlkwa|then ><hlstd|send resize<textunderscore>height
    scr<textunderscore>y><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|if ><hlstd|s><hlopt|.><hlstd|button ><hlopt|&& ><hlstd|not
    omb ><hlkwa|then ><hlstd|send press<textunderscore>mbutton
    ><hlopt|();><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|if ><hlstd|x
    ><hlopt|\<less\>\<gtr\> ><hlstd|omx ><hlkwa|then ><hlstd|send
    move<textunderscore>mouse<textunderscore>x
    x><hlopt|;><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|if ><hlstd|y
    ><hlopt|\<less\>\<gtr\> ><hlstd|omy ><hlkwa|then ><hlstd|send
    move<textunderscore>mouse<textunderscore>y
    y><hlopt|;><hlendline|><next-line><hlstd| \ \ \ send tick
    t1><hlopt|;><hlendline|><next-line><hlstd| \ \ \ draw
    ><hlopt|(><hlstd|sample anim><hlopt|);><hlendline|After all signals are
    updated, observe behavior.><next-line><hlstd| \ \ \ loop x y
    scr<textunderscore>x scr<textunderscore>y s><hlopt|.><hlstd|button t1
    ><hlkwa|in><hlendline|><next-line><hlstd| \ open<textunderscore>graph
    ><hlstr|""><hlopt|;><hlendline|><next-line><hlstd|
    \ display<textunderscore>mode ><hlkwa|false><hlopt|;><hlendline|><next-line><hlstd|
    \ loop ><hlnum|0 0 640 512 ><hlkwa|false
    ><hlopt|(><hlkwc|Unix><hlopt|.><hlstd|gettimeofday
    ><hlopt|());><hlendline|><next-line><hlstd| \ close<textunderscore>graph
    ><hlopt|()><hlendline|>>

    <new-page*><item>The simple behaviors as in <verbatim|Lec10b.ml>.
    Pragmatic (impure) bouncing:

    <\small>
      <hlkwa|let ><hlstd|pbal vel ><hlopt|=><hlendline|><next-line><hlstd|
      \ ><hlkwa|let ><hlstd|xbounce><hlopt|, ><hlstd|bounce<textunderscore>x
      ><hlopt|= ><hlstd|make<textunderscore>event ><hlopt|()
      ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
      ><hlstd|ybounce><hlopt|, ><hlstd|bounce<textunderscore>y ><hlopt|=
      ><hlstd|make<textunderscore>event ><hlopt|()
      ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|xvel
      ><hlopt|= ><hlstd|collect<textunderscore>b ><hlopt|(><hlkwa|fun
      ><hlstd|v <textunderscore> ><hlopt|-\<gtr\>
      ><hlstd|<math|\<sim\>>><hlopt|-.><hlstd|v><hlopt|) ><hlstd|vel xbounce
      ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|yvel
      ><hlopt|= ><hlstd|collect<textunderscore>b ><hlopt|(><hlkwa|fun
      ><hlstd|v <textunderscore> ><hlopt|-\<gtr\>
      ><hlstd|<math|\<sim\>>><hlopt|-.><hlstd|v><hlopt|) ><hlstd|vel ybounce
      ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|xpos
      ><hlopt|= ><hlstd|integ<textunderscore>res xvel ><hlopt|+*
      ><hlstd|width ><hlopt|/* !*><hlnum|2
      ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|ypos
      ><hlopt|= ><hlstd|integ<textunderscore>res yvel ><hlopt|+*
      ><hlstd|height ><hlopt|/* !*><hlnum|2
      ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
      ><hlstd|xbounce<textunderscore> ><hlopt|=
      ><hlstd|when<textunderscore>true<hlendline|><next-line>
      \ \ \ ><hlopt|((><hlstd|xpos ><hlopt|\<gtr\>* ><hlstd|width ><hlopt|-*
      !*><hlnum|27><hlopt|) ><hlstd|<hlopt|\|\|>><hlopt|* (><hlstd|xpos
      ><hlopt|\<less\>* !*><hlnum|27><hlopt|))
      ><hlkwa|in><hlendline|><next-line><hlstd| \ notify<textunderscore>e
      xbounce<textunderscore> ><hlopt|(><hlstd|send
      bounce<textunderscore>x><hlopt|);><hlendline|><next-line><hlstd|
      \ ><hlkwa|let ><hlstd|ybounce<textunderscore> ><hlopt|=
      ><hlstd|when<textunderscore>true ><hlopt|(><hlendline|><next-line><hlstd|
      \ \ \ ><hlopt|(><hlstd|ypos ><hlopt|\<gtr\>* ><hlstd|height ><hlopt|-*
      !*><hlnum|27><hlopt|) ><hlstd|<hlopt|\|\|>><hlopt|*><hlendline|><next-line><hlstd|
      \ \ \ \ \ ><hlopt|((><hlstd|ypos ><hlopt|\<less\>*
      !*><hlnum|17><hlopt|) &&* (><hlstd|ypos ><hlopt|\<gtr\>*
      !*><hlnum|7><hlopt|) &&*><hlendline|><next-line><hlstd|
      \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|xpos ><hlopt|\<gtr\>*
      ><hlstd|mouse<textunderscore>x><hlopt|) &&* (><hlstd|xpos
      ><hlopt|\<less\>* ><hlstd|mouse<textunderscore>x ><hlopt|+*
      !*><hlnum|50><hlopt|))) ><hlkwa|in><hlendline|><next-line><hlstd|
      \ notify<textunderscore>e ybounce<textunderscore> ><hlopt|(><hlstd|send
      bounce<textunderscore>y><hlopt|);><hlendline|><next-line><hlstd|
      \ lift4 ><hlopt|(><hlkwa|fun ><hlstd|x y <textunderscore>
      <textunderscore> ><hlopt|-\<gtr\> ><hlkwd|Color
      ><hlopt|(><hlkwc|Graphics><hlopt|.><hlstd|red><hlopt|, ><hlkwd|Circle
      ><hlopt|(><hlstd|x><hlopt|, ><hlstd|y><hlopt|,
      ><hlnum|6><hlopt|)))><hlendline|><next-line><hlstd| \ \ \ xpos ypos
      ><hlopt|(><hlstd|hold ><hlopt|() ><hlstd|xbounce<textunderscore>><hlopt|)
      (><hlstd|hold ><hlopt|() ><hlstd|ybounce<textunderscore>><hlopt|)><hlendline|>
    </small>

    <new-page*><item>We hold on to <hlstd|xbounce<textunderscore>> and
    <hlstd|ybounce<textunderscore>> above to prevent garbage collecting them.
    We could instead remember them in the ``toplevel'':

    <small|<hlkwa|let ><hlstd|pbal vel ><hlopt|=><hlendline|><next-line><hlstd|
    \ >...<hlendline|><next-line><hlstd| \ xbounce<textunderscore>><hlopt|,
    ><hlstd|ybounce<textunderscore>><hlopt|,><hlendline|><next-line><hlstd|
    \ lift2 ><hlopt|(><hlkwa|fun ><hlstd|x y ><hlopt|-\<gtr\> ><hlkwd|Color
    ><hlopt|(><hlkwc|Graphics><hlopt|.><hlstd|red><hlopt|, ><hlkwd|Circle
    ><hlopt|(><hlstd|x><hlopt|, ><hlstd|y><hlopt|,
    ><hlnum|6><hlopt|)))><hlendline|><next-line><hlstd| \ \ \ xpos
    ypos><hlendline|><next-line><hlkwa|let
    ><hlstd|xb<textunderscore>><hlopt|, ><hlstd|yb<textunderscore>><hlopt|,
    ><hlstd|ball ><hlopt|= ><hlstd|pbal ><hlnum|100><hlopt|.><hlendline|><next-line><hlkwa|let
    ><hlstd|game ><hlopt|= ><hlstd|lift3 ><hlopt|(><hlkwa|fun ><hlstd|walls
    paddle ball ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ ><hlkwd|Group ><hlopt|[><hlstd|walls><hlopt|; ><hlstd|paddle><hlopt|;
    ><hlstd|ball><hlopt|]) ><hlstd|walls paddle ball><hlendline|>>

    <item>We can easily monitor signals while debugging, e.g.:

    <small|<hlstd| \ notify<textunderscore>e xbounce ><hlopt|(><hlkwa|fun
    ><hlopt|() -\<gtr\> ><hlkwc|Printf><hlopt|.><hlstd|printf
    ><hlstr|"xbounce><hlesc|<math|>\\n><hlstr|%!"><hlopt|);><hlendline|><next-line><hlstd|
    \ notify<textunderscore>e ybounce ><hlopt|(><hlkwa|fun ><hlopt|()
    -\<gtr\> ><hlkwc|Printf><hlopt|.><hlstd|printf
    ><hlstr|"ybounce><hlesc|<math|>\\n><hlstr|%!"><hlopt|);><hlendline|>>

    <item>Invocation:<next-line><verbatim|ocamlbuild Lec10c.native -cflags
    -I,+froc,-I,+threads -libs froc/froc,unix,graphics,threads/threads -->
  </itemize>

  <section|<new-page*>Direct Control>

  <\itemize>
    <item>Real-world behaviors often are <em|state machines>, going through
    several stages. We don't have declarative means for it yet.

    <\itemize>
      <item>Example: baking recipes. <em|1. Preheat the oven. 2. Put flour,
      sugar, eggs into a bowl. 3. Spoon the mixture.> etc.
    </itemize>

    <item>We want a <em|flow> to be able to proceed through events: when the
    first event arrives we remember its result and wait for the next event,
    disregarding any further arrivals of the first event!

    <\itemize>
      <item>Therefore <em|Froc> constructs like mapping an event:
      <verbatim|map>, or attaching a notification to a behavior change:
      <verbatim|bind b1 (fun v1 -\<gtr\> notify_b ~now:false b2 (fun v2
      -\<gtr\> >...<verbatim|))>, will not work.
    </itemize>

    <item>We also want to be able to repeat or loop a flow, but starting from
    the notification of the first event that happens after the notification
    of the last event.

    <new-page*><item><verbatim|next e> is an event propagating only the first
    occurrence of <verbatim|e>. This will be the basis of our
    <verbatim|await> function.

    <item>The whole flow should be cancellable from outside at any time.

    <item>A flow is a kind of a <em|lightweight thread> as in end of lecture
    8, we'll make it a monad. It only ``stores'' a non-unit value when it
    <verbatim|await>s an event. But it has a primitive to <verbatim|emit>
    values.

    <\itemize>
      <item>We actually implement <em|coarse-grained> threads (lecture 8
      exercise 11), with <verbatim|await> in the role of <verbatim|suspend>.
    </itemize>

    <new-page*><item>We build a module <hlkwc|Flow> with monadic type
    <hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|flow> ``storing''
    <verbatim|'b> and emitting <verbatim|'a>.

    <hlkwa|type ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|)
    ><hlstd|flow><hlendline|><next-line><hlkwa|type
    ><hlstd|cancellable><hlendline|A handle to cancel a flow (stop further
    computation).><next-line><hlkwa|val ><hlstd|noop<textunderscore>flow
    ><hlopt|: (><hlstd|'a><hlopt|, ><hlkwb|unit><hlopt|)
    ><hlstd|flow><hlendline|Same as <verbatim|return
    ><hlopt|()>.><next-line><hlkwa|val ><hlstd|return ><hlopt|: ><hlstd|'b
    ><hlopt|-\<gtr\> (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|)
    ><hlstd|flow><hlendline|Completed flow.><next-line><hlkwa|val
    ><hlstd|await ><hlopt|: ><hlstd|'b ><hlkwc|Froc><hlopt|.><hlstd|event
    ><hlopt|-\<gtr\> (><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|)
    ><hlstd|flow><hlendline|Wait and store event:><next-line><hlkwa|val
    ><hlstd|bind ><hlopt|:><hlendline|the principled way to
    input.><next-line><hlstd| \ ><hlopt|(><hlstd|'a><hlopt|,
    ><hlstd|'b><hlopt|) ><hlstd|flow ><hlopt|-\<gtr\> (><hlstd|'b
    ><hlopt|-\<gtr\> (><hlstd|'a><hlopt|, ><hlstd|'c><hlopt|)
    ><hlstd|flow><hlopt|) -\<gtr\> (><hlstd|'a><hlopt|, ><hlstd|'c><hlopt|)
    ><hlstd|flow><hlendline|><next-line><hlkwa|val ><hlstd|emit ><hlopt|:
    ><hlstd|'a ><hlopt|-\<gtr\> (><hlstd|'a><hlopt|, ><hlkwb|unit><hlopt|)
    ><hlstd|flow><hlendline|The principled way to
    output.><next-line><hlkwa|val ><hlstd|cancel ><hlopt|:
    ><hlstd|cancellable ><hlopt|-\<gtr\> ><hlkwb|unit><hlendline|><next-line><hlkwa|val
    ><hlstd|repeat ><hlopt|:><hlendline|Loop the given flow and store the
    stop event.><next-line><hlstd| \ ?until><hlopt|:><hlstd|'a
    ><hlkwc|Froc><hlopt|.><hlstd|event ><hlopt|-\<gtr\> (><hlstd|'b><hlopt|,
    ><hlkwb|unit><hlopt|)><hlstd| flow ><hlopt|-\<gtr\> (><hlstd|'b><hlopt|,
    ><hlstd|'a><hlopt|) ><hlstd|flow><next-line><hlkwa|val
    ><hlstd|event<textunderscore>flow ><hlopt|:><hlendline|><next-line><hlstd|
    \ ><hlopt|(><hlstd|'a><hlopt|, ><hlkwb|unit><hlopt|) ><hlstd|flow
    ><hlopt|-\<gtr\> ><hlstd|'a ><hlkwc|Froc><hlopt|.><hlstd|event ><hlopt|*
    ><hlstd|cancellable><hlendline|><next-line><hlkwa|val
    ><hlstd|behavior<textunderscore>flow ><hlopt|:><hlendline|The initial
    value of a behavior and a flow to update it.><next-line><hlstd| \ 'a
    ><hlopt|-\<gtr\> (><hlstd|'a><hlopt|, ><hlkwb|unit><hlopt|) ><hlstd|flow
    ><hlopt|-\<gtr\> ><hlstd|'a ><hlkwc|Froc><hlopt|.><hlstd|behavior
    ><hlopt|* ><hlstd|cancellable><hlendline|><next-line><hlkwa|val
    ><hlstd|is<textunderscore>cancelled ><hlopt|: ><hlstd|cancellable
    ><hlopt|-\<gtr\> ><hlkwb|bool><hlendline|>

    <new-page*><item>We follow our (or <em|Lwt>) implementation of
    lightweight threads, adapting it to the need of cancelling flows.

    <hlkwa|module ><hlkwd|F ><hlopt|= ><hlkwd|Froc><hlendline|><next-line><hlkwa|type
    ><hlstd|'a result ><hlopt|=><hlendline|><next-line><hlopt|\|
    ><hlkwd|Return ><hlkwa|of ><verbatim|'a><hlendline|<math|\<downarrow\>>Notifications
    to cancel when cancelled.><next-line><hlopt|\|><hlkwd| Sleep ><hlkwa|of
    ><hlopt|(><hlstd|'a ><hlopt|-\<gtr\> ><hlkwb|unit><hlopt|) ><hlstd|list
    ><hlopt|* ><hlkwc|F><hlopt|.><hlstd|cancel ><hlkwb|ref
    ><hlstd|list<hlendline|><next-line><hlopt|\|>
    ><hlkwd|Cancelled><hlendline|><next-line><hlopt|\| ><hlkwd|Link
    ><hlkwa|of ><hlstd|'a state><hlendline|><next-line><hlkwa|and ><hlstd|'a
    state ><hlopt|= {><hlkwa|mutable ><hlstd|state ><hlopt|: ><hlstd|'a
    result><hlopt|}><hlendline|><next-line><hlkwa|type ><hlstd|cancellable
    ><hlopt|= ><hlkwb|unit ><hlstd|state><hlendline|>

    <item>Functions <verbatim|find>, <verbatim|wakeup>, <verbatim|connect>
    are as in lecture 8 (but connecting to cancelled thread cancels the other
    thread).

    <item>Our monad is actually a reader monad over the result state. The
    reader supplies the <verbatim|emit> function. (See exercise 10.)

    <hlkwa|type ><hlopt|(><hlstd|'a><hlopt|, ><hlstd|'b><hlopt|) ><hlstd|flow
    ><hlopt|= (><hlstd|'a ><hlopt|-\<gtr\> ><hlkwb|unit><hlopt|) -\<gtr\>
    ><hlstd|'b state><hlendline|>

    <new-page*><item>The <verbatim|return> and <verbatim|bind> functions are
    as in our lightweight threads, but we need to handle cancelled flows: for
    <verbatim|m = bind a b>, if <verbatim|a> is cancelled then <verbatim|m>
    is cancelled, and if <verbatim|m> is cancelled then don't wake up
    <verbatim|b>:

    <hlstd| \ \ \ \ \ ><hlkwa|let ><hlstd|waiter x
    ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|if
    ><hlstd|not ><hlopt|(><hlstd|is<textunderscore>cancelled
    m><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|then
    ><hlstd|connect m ><hlopt|(><hlstd|b x emit><hlopt|)
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ >...

    <item><verbatim|await> is implemented like <verbatim|next>, but it wakes
    up a flow:

    <hlkwa|let ><hlstd|await t ><hlopt|= ><hlkwa|fun ><hlstd|emit
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|c
    ><hlopt|= ><hlkwb|ref ><hlkwc|F><hlopt|.><hlstd|no<textunderscore>cancel
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|m
    ><hlopt|= {><hlstd|state><hlopt|=><hlkwd|Sleep ><hlopt|([],
    [><hlstd|c><hlopt|])} ><hlkwa|in><hlendline|><next-line><hlstd| \ c
    ><hlopt|:=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwc|F><hlopt|.><hlstd|notify<textunderscore>e<textunderscore>cancel
    t ><hlkwa|begin fun ><hlstd|r ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwc|F><hlopt|.><hlstd|cancel
    ><hlopt|!><hlstd|c><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ c
    ><hlopt|:= ><hlkwc|F><hlopt|.><hlstd|no<textunderscore>cancel><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ \ \ wakeup m r<hlendline|><next-line>
    \ \ \ ><hlkwa|end><hlopt|;><hlendline|><next-line><hlstd|
    \ m><hlendline|>

    <item><verbatim|repeat> attaches the whole loop as a waiter for the loop
    body.

    <small|<hlkwa|let ><hlstd|repeat ?><hlopt|(><hlstd|until><hlopt|=><hlkwc|F><hlopt|.><hlstd|never><hlopt|)
    ><hlstd|fa ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|fun
    ><hlstd|emit ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|c ><hlopt|= ><hlkwb|ref
    ><hlkwc|F><hlopt|.><hlstd|no<textunderscore>cancel
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|out
    ><hlopt|= {><hlstd|state><hlopt|=><hlkwd|Sleep ><hlopt|([],
    [><hlstd|c><hlopt|])} ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|cancel<textunderscore>body ><hlopt|=
    ><hlkwb|ref ><hlopt|{><hlstd|state><hlopt|=><hlkwd|Cancelled><hlopt|}
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ c ><hlopt|:=><hlkwc|
    F><hlopt|.><hlstd|notify<textunderscore>e<textunderscore>cancel until
    ><hlkwa|begin fun ><hlstd|tv ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwc|F><hlopt|.><hlstd|cancel
    ><hlopt|!><hlstd|c><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ c ><hlopt|:= ><hlkwc|F><hlopt|.><hlstd|no<textunderscore>cancel><hlopt|;><hlendline|
    Exiting the loop consists of cancelling the loop body><next-line><hlstd|
    \ \ \ \ \ \ \ cancel ><hlopt|!><hlstd|cancel<textunderscore>body><hlopt|;
    ><verbatim|wakeup out tv><hlendline|and waking up loop
    waiters.><verbatim|<next-line> \ \ \ \ \ ><hlkwa|end><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let rec ><hlstd|loop ><hlopt|()
    =><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|let ><hlstd|a
    ><hlopt|= ><hlstd|find ><hlopt|(><hlstd|fa emit><hlopt|)
    ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ cancel<textunderscore>body ><hlopt|:=
    ><hlstd|a><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|(><hlkwa|match ><hlstd|a><hlopt|.><hlstd|state
    ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
    ><hlkwd|Cancelled ><hlopt|-\<gtr\> ><hlstd|cancel out><hlopt|;
    ><hlkwc|F><hlopt|.><hlstd|cancel ><hlopt|!><hlstd|c<hlendline|><next-line>
    \ \ \ \ \ ><hlopt|\| ><hlkwd|Return ><hlstd|x
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ failwith
    ><hlstr|"loop<textunderscore>until: not implemented for unsuspended
    flows"><hlstd|<hlendline|><next-line> \ \ \ \ \ ><hlopt|\| ><hlkwd|Sleep
    ><hlopt|(><hlstd|xwaiters><hlopt|, ><hlstd|xcancels><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ a><hlopt|.><hlstd|state ><hlopt|\<less\>- ><hlkwd|Sleep
    ><hlopt|(><hlstd|loop><hlopt|::><hlstd|xwaiters><hlopt|,
    ><hlstd|xcancels><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|\| ><hlkwd|Link ><hlstd|<textunderscore>
    ><hlopt|-\<gtr\> ><hlkwa|assert false><hlopt|)
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ loop ><hlopt|();
    ><hlstd|out><hlendline|>>

    <new-page*><item>Example: drawing shapes.
    Invocation:<next-line><verbatim|ocamlbuild Lec10d.native -pp "camlp4o
    monad/pa_monad.cmo" -libs froc/froc,graphics -cflags -I,+froc -->

    <item>The event handlers and drawing/event dispatch loop
    <verbatim|reactimate> is similar to the paddle game example (we removed
    unnecessary events).

    <item>The scene is a list of shapes, the first shape is open.

    <hlkwa|type ><hlstd|scene ><hlopt|= (><hlkwb|int ><hlopt|*
    ><hlkwb|int><hlopt|) ><hlstd|list list><hlendline|><next-line><hlkwa|let
    ><hlstd|draw sc ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let
    open ><hlkwd|Graphics ><hlkwa|in><hlendline|><next-line><hlstd|
    \ clear<textunderscore>graph ><hlopt|();><hlendline|><next-line><hlstd|
    \ ><hlopt|(><hlkwa|match ><hlstd|sc ><hlkwa|with><hlendline|><next-line><hlstd|
    \ ><hlopt|\| [] -\<gtr\> ()><hlendline|><next-line><hlstd| \ <hlopt|\|>
    opn><hlopt|::><hlstd|cld ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ draw<textunderscore>poly<textunderscore>line
    ><hlopt|(><hlkwc|Array><hlopt|.><hlstd|of<textunderscore>list
    opn><hlopt|);><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwc|List><hlopt|.><hlstd|iter
    ><hlopt|(><hlstd|fill<textunderscore>poly ><hlopt|-\|
    ><hlkwc|Array><hlopt|.><hlstd|of<textunderscore>list><hlopt|)
    ><hlstd|cld><hlopt|);><hlendline|><next-line><hlstd| \ synchronize
    ><hlopt|()><hlendline|>

    <new-page*><item>We build a flow and turn it into a behavior to animate.

    <hlkwa|let ><hlstd|painter ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|cld ><hlopt|= ><hlkwb|ref ><hlopt|[]
    ><hlkwa|in><hlendline|Global state of painter.><next-line><hlstd|
    \ repeat ><hlopt|(><hlkwa|perform><hlendline|><next-line><hlstd|
    \ \ \ \ \ await mbutton<textunderscore>pressed><hlopt|;><hlendline|Start
    when button down.><next-line><hlstd| \ \ \ \ \ ><hlkwa|let ><hlstd|opn
    ><hlopt|= ><hlkwb|ref ><hlopt|[] ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ repeat ><hlopt|(><hlkwa|perform><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ mpos ><hlopt|\<less\>-- ><hlstd|await
    mouse<textunderscore>move><hlopt|;><hlendline|<math|\<swarrow\>>Add next
    position to line.><next-line><hlstd| \ \ \ \ \ \ \ \ \ emit
    ><hlopt|(><hlstd|opn ><hlopt|:= ><hlstd|mpos ><hlopt|::
    !><hlstd|opn><hlopt|; !><hlstd|opn ><hlopt|::
    !><hlstd|cld><hlopt|))><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ <math|\<sim\>>until><hlopt|:><hlstd|mbutton<textunderscore>released><hlopt|;><hlendline|<math|\<swarrow\>>Start
    new shape.><next-line><hlstd| \ \ \ \ \ emit ><hlopt|(><hlstd|cld
    ><hlopt|:= !><hlstd|opn ><hlopt|:: !><hlstd|cld><hlopt|; ><hlstd|opn
    ><hlopt|:= []; [] :: !><hlstd|cld><hlopt|))><hlendline|><next-line><hlkwa|let
    ><hlstd|painter><hlopt|, ><hlstd|cancel<textunderscore>painter ><hlopt|=
    ><hlstd|behavior<textunderscore>flow ><hlopt|[]
    ><hlstd|painter><hlendline|><next-line><hlkwa|let ><hlopt|() =
    ><hlstd|reactimate painter><hlendline|>

    <item><image|Lec10d.png|602px|479px||>
  </itemize>

  <subsubsection|<new-page*>Flows and state>

  Global state and thread-local state can be used with lightweight threads,
  but pay attention to semantics -- which computations are inside the monad
  and which while building the initial monadic value.

  <\itemize>
    <item>Side effects hidden in <verbatim|return> and <verbatim|emit>
    arguments are not inside the monad. E.g. if in the ``first line'' of a
    loop effects are executed only at the start of the loop -- but if after
    bind (``below first line'' of a loop), at each step of the loop.
  </itemize>

  <small|<hlkwa|let ><hlstd|f ><hlopt|=><hlendline|><next-line><hlstd|
  \ repeat ><hlopt|(><hlkwa|perform><hlendline|><next-line><hlstd|
  \ \ \ \ \ emit ><hlopt|(><hlkwc|Printf><hlopt|.><hlstd|printf
  ><hlstr|"[0]><hlesc|<math|>\\n><hlstr|%!"><hlopt|;
  ><hlstd|'><hlnum|0><hlstd|'><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|() \<less\>-- ><hlstd|await
  aas><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ emit
  ><hlopt|(><hlkwc|Printf><hlopt|.><hlstd|printf
  ><hlstr|"[1]><hlesc|<math|>\\n><hlstr|%!"><hlopt|;
  ><hlstd|'><hlnum|1><hlstd|'><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|() \<less\>-- ><hlstd|await
  bs><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ emit
  ><hlopt|(><hlkwc|Printf><hlopt|.><hlstd|printf
  ><hlstr|"[2]><hlesc|<math|>\\n><hlstr|%!"><hlopt|;
  ><hlstd|'><hlnum|2><hlstd|'><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|() \<less\>-- ><hlstd|await
  cs><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ emit
  ><hlopt|(><hlkwc|Printf><hlopt|.><hlstd|printf
  ><hlstr|"[3]><hlesc|<math|>\\n><hlstr|%!"><hlopt|;
  ><hlstd|'><hlnum|3><hlstd|'><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|() \<less\>-- ><hlstd|await
  ds><hlopt|;><hlendline|><next-line><hlstd| \ \ \ \ \ emit
  ><hlopt|(><hlkwc|Printf><hlopt|.><hlstd|printf
  ><hlstr|"[4]><hlesc|<math|>\\n><hlstr|%!"><hlopt|;
  ><hlstd|'><hlnum|4><hlstd|'><hlopt|))><hlendline|><next-line><hlkwa|let
  ><hlstd|e><hlopt|, ><hlstd|cancel<textunderscore>e ><hlopt|=
  ><hlstd|event<textunderscore>flow f><hlendline|><next-line><hlkwa|let
  ><hlopt|() =><hlendline|><next-line><hlstd|
  \ ><hlkwc|F><hlopt|.><hlstd|notify<textunderscore>e e ><hlopt|(><hlkwa|fun
  ><hlstd|c ><hlopt|-\<gtr\> ><hlkwc|Printf><hlopt|.><hlstd|printf
  ><hlstr|"flow: %c><hlesc|<math|>\\n><hlstr|%!"><hlstd|
  c><hlopt|);><hlendline|><next-line><hlstd|
  \ ><hlkwc|Printf><hlopt|.><hlstd|printf ><hlstr|"notification
  installed><hlesc|<math|>\\n><hlstr|%!"><hlendline|><next-line><hlkwa|let
  ><hlopt|() =><hlendline|><next-line><hlstd|
  \ ><hlkwc|F><hlopt|.><hlstd|send a ><hlopt|();
  ><hlkwc|F><hlopt|.><hlstd|send b ><hlopt|(); ><hlkwc|F><hlopt|.><hlstd|send
  c ><hlopt|(); ><hlkwc|F><hlopt|.><hlstd|send d
  ><hlopt|();><hlendline|><next-line><hlstd| \ ><hlkwc|F><hlopt|.><hlstd|send
  a ><hlopt|(); ><hlkwc|F><hlopt|.><hlstd|send b ><hlopt|();
  ><hlkwc|F><hlopt|.><hlstd|send c ><hlopt|(); ><hlkwc|F><hlopt|.><hlstd|send
  d ><hlopt|()><hlendline|>>

  <hlopt|[><hlnum|0><hlopt|]><hlendline|Only printed once -- when building
  the loop.><next-line><verbatim|notification installed><hlendline|Only
  installed <strong|after> the first flow event
  sent.><next-line>event<hlopt|: ><hlstd|a><hlendline|Event notification (see
  source <verbatim|Lec10e.ml>).><next-line><hlopt|[><hlnum|1><hlopt|]><hlendline|Second
  <verbatim|emit> computed after first <verbatim|await>
  returns.><next-line><hlstd|flow><hlopt|: ><hlnum|1><hlendline|Emitted
  signal.><next-line><hlstd|event><hlopt|: ><hlstd|b><hlendline|Next
  event...><next-line><hlopt|[><hlnum|2><hlopt|]><hlendline|><next-line><hlstd|flow><hlopt|:
  ><hlnum|2><hlendline|><next-line><hlstd|event><hlopt|:
  ><hlstd|c><hlendline|><next-line><hlopt|[><hlnum|3><hlopt|]><hlendline|><next-line><hlstd|flow><hlopt|:
  ><hlnum|3><hlendline|><next-line><hlstd|event><hlopt|:
  ><hlstd|d><hlendline|><next-line><hlopt|[><hlnum|4><hlopt|]><hlendline|><next-line><hlstd|flow><hlopt|:
  ><hlnum|4><hlendline|Last signal emitted from first turn of the loop
  --><next-line><hlstd|flow><hlopt|: ><hlnum|0><hlendline|and first signal of
  the second turn (but <verbatim|[0]> not
  printed).><next-line><hlstd|event><hlopt|:
  ><hlstd|a><hlendline|><next-line><hlopt|[><hlnum|1><hlopt|]><hlendline|><next-line><hlstd|flow><hlopt|:
  ><hlnum|1><hlendline|><next-line><hlstd|event><hlopt|:
  ><hlstd|b><hlendline|><next-line><hlopt|[><hlnum|2><hlopt|]><hlendline|><next-line><hlstd|flow><hlopt|:
  ><hlnum|2><hlendline|><next-line><hlstd|event><hlopt|:
  ><hlstd|c><hlendline|><next-line><hlopt|[><hlnum|3><hlopt|]><hlendline|><next-line><hlstd|flow><hlopt|:
  ><hlnum|3><hlendline|><next-line><hlstd|event><hlopt|:
  ><hlstd|d><hlendline|><next-line><hlopt|[><hlnum|4><hlopt|]><hlendline|><next-line><hlstd|flow><hlopt|:
  ><hlnum|4><hlendline|><next-line><hlstd|flow><hlopt|:
  ><hlnum|0><hlendline|Program ends while flow in third turn of the loop.>

  \;

  <section|<new-page*>Graphical User Interfaces>

  <\itemize>
    <item>In-depth discussion of GUIs is beyond the scope of this course. We
    only cover what's needed for an example reactive program with direct
    control.

    <item>Demo of libraries <em|LablTk> based on optional labelled arguments
    discussed in lecture 2 exercise 2, and polymorphic variants, and
    <em|LablGtk> additionally based on objects. We will learn more about
    objects and polymorphic variants in next lecture.
  </itemize>

  <subsection|<new-page*>Calculator Flow>

  <hlkwa|let ><hlstd|digits><hlopt|, ><hlstd|digit ><hlopt|=
  ><hlkwc|F><hlopt|.><hlstd|make<textunderscore>event
  ><hlopt|()><hlendline|We represent the mechanics><next-line><hlkwa|let
  ><hlstd|ops><hlopt|, ><hlstd|op ><hlopt|=
  ><hlkwc|F><hlopt|.><hlstd|make<textunderscore>event
  ><hlopt|()><hlendline|of the calculator directly as a
  flow.><next-line><hlkwa|let ><hlstd|dots><hlopt|, ><hlstd|dot ><hlopt|=
  ><hlkwc|F><hlopt|.><hlstd|make<textunderscore>event
  ><hlopt|()><hlendline|><next-line><hlkwa|let ><hlstd|calc
  ><hlopt|=><hlendline|We need two state variables for two arguments of
  calculation><next-line><hlstd| \ ><hlkwa|let ><hlstd|f ><hlopt|=
  ><hlkwb|ref ><hlopt|(><hlkwa|fun ><hlstd|x ><hlopt|-\<gtr\>
  ><hlstd|x><hlopt|) ><hlkwa|and ><hlstd|now ><hlopt|= ><hlkwb|ref
  ><hlnum|0.0 ><hlkwa|in><hlendline|but we><next-line><hlstd| \ repeat
  ><hlopt|(><hlkwa|perform><hlendline|remember the older argument in partial
  application.><next-line><hlstd| \ \ \ \ \ op ><hlopt|\<less\>--
  ><hlstd|repeat<hlendline|><next-line> \ \ \ \ \ \ \ ><hlopt|(><hlkwa|perform><hlendline|Enter
  the digits of a number (on later turns><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ d ><hlopt|\<less\>-- ><hlstd|await
  digits><hlopt|;><hlendline|starting from the second
  digit)><next-line><hlstd| \ \ \ \ \ \ \ \ \ \ \ emit ><hlopt|(><hlstd|now
  ><hlopt|:= ><hlnum|10><hlopt|. *. !><hlstd|now ><hlopt|+.
  ><hlstd|d><hlopt|; !><hlstd|now><hlopt|))><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ <math|\<sim\>>until><hlopt|:><hlstd|ops><hlopt|;><hlendline|until
  operator button is pressed.><next-line><hlstd| \ \ \ \ \ emit
  ><hlopt|(><hlstd|now ><hlopt|:= !><hlstd|f ><hlopt|!><hlstd|now><hlopt|;
  ><hlstd|f ><hlopt|:= ><hlstd|op ><hlopt|!><hlstd|now><hlopt|;
  !><hlstd|now><hlopt|);><hlendline|><next-line><hlstd| \ \ \ \ \ d
  ><hlopt|\<less\>-- ><verbatim|repeat><hlendline|<math|\<nwarrow\>>Compute
  the result and ``store away'' the operator.><verbatim|<next-line>
  \ \ \ \ \ \ \ ><hlopt|(><hlkwa|perform ><hlstd|op ><hlopt|\<less\>--
  ><hlstd|await ops><hlopt|; ><hlstd|return ><hlopt|(><hlstd|f ><hlopt|:=
  ><hlstd|op ><hlopt|!><hlstd|now><hlopt|))><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ <math|\<sim\>>until><hlopt|:><hlstd|digits><hlopt|;><hlendline|The
  user can pick a different operator.><next-line><hlstd| \ \ \ \ \ emit
  ><hlopt|(><hlstd|now ><hlopt|:= ><hlstd|d><hlopt|;
  !><hlstd|now><hlopt|))><hlendline|Reset the state to a new
  number.><next-line><hlkwa|let ><hlstd|calc<textunderscore>e><hlopt|,
  ><hlstd|cancel<textunderscore>calc ><hlopt|=
  ><hlstd|event<textunderscore>flow calc><hlendline|Notifies display update.>

  <subsection|<em|<new-page*>Tk>: <em|LablTk>>

  <\itemize>
    <item>Widget toolkit <strong|<em|Tk>> known from the <em|Tcl> language.

    <item>Invocation:<next-line><verbatim|ocamlbuild Lec10tk.byte -cflags
    -I,+froc -libs froc/froc<next-line> \ -pkg labltk -pp "camlp4o
    monad/pa_monad.cmo" -->

    <\itemize>
      <item>For unknown reason I had build problems with <verbatim|ocamlopt>
      (native).
    </itemize>

    <item>Layout of the calculator -- common across GUIs.

    <hlkwa|let ><hlstd|layout ><hlopt|=><hlendline|><next-line><hlstd|
    ><hlopt|[><hlstd|<hlopt|\|>><hlopt|[><hlstd|<hlopt|\|>><hlstr|"7"><hlopt|,><hlstd|`><hlkwd|Di
    ><hlnum|7><hlopt|.; ><hlstr|"8"><hlopt|,><hlstd|`><hlkwd|Di
    ><hlnum|8><hlopt|.; ><hlstr|"9"><hlopt|,><hlstd|`><hlkwd|Di
    ><hlnum|9><hlopt|.; ><hlstr|"+"><hlopt|,><hlstd|`><hlkwd|O
    ><hlopt|(+.)><hlstd|<hlopt|\|>><hlopt|];><next-line><hlstd|
    \ \ ><hlopt|[><hlstd|<hlopt|\|>><hlstr|"4"><hlopt|,><hlstd|`><hlkwd|Di
    ><hlnum|4><hlopt|.; ><hlstr|"5"><hlopt|,><hlstd|`><hlkwd|Di
    ><hlnum|5><hlopt|.; ><hlstr|"6"><hlopt|,><hlstd|`><hlkwd|Di
    ><hlnum|6><hlopt|.; ><hlstr|"-"><hlopt|,><hlstd|`><hlkwd|O
    ><hlopt|(-.)><hlstd|<hlopt|\|>><hlopt|];><next-line><hlstd|
    \ \ ><hlopt|[><hlstd|<hlopt|\|>><hlstr|"1"><hlopt|,><hlstd|`><hlkwd|Di
    ><hlnum|1><hlopt|.; ><hlstr|"2"><hlopt|,><hlstd|`><hlkwd|Di
    ><hlnum|2><hlopt|.; ><hlstr|"3"><hlopt|,><hlstd|`><hlkwd|Di
    ><hlnum|3><hlopt|.; ><hlstr|"*"><hlopt|,><hlstd|`><hlkwd|O ><hlopt|(
    *.)><hlstd|<hlopt|\|>><hlopt|];><next-line><hlstd|
    \ \ ><hlopt|[><hlstd|<hlopt|\|>><hlstr|"0"><hlopt|,><hlstd|`><hlkwd|Di
    ><hlnum|0><hlopt|.; ><hlstr|"."><hlopt|,><hlstd|`><hlkwd|Dot><hlopt|;><hlstd|
    \ \ ><hlstr|"="><hlopt|,><hlstd| `><hlkwd|O ><hlstd|sk><hlopt|;
    ><hlstr|"/"><hlopt|,><hlstd|`><hlkwd|O
    ><hlopt|(/.)><hlstd|<hlopt|\|>><hlopt|]><hlstd|<hlopt|\|>><hlopt|]><next-line>

    <item>Every <em|widget> (window gadget) has a parent in which it is
    located.

    <item><em|Buttons> have action associated with pressing them, <em|labels>
    just provide information, <em|entries> (aka. <em|edit> fields) are for
    entering info from keyboard.

    <\itemize>
      <item>Actions are <em|callback> functions passed as the
      <math|\<sim\>><verbatim|command> argument.
    </itemize>

    <item><em|Frames> in <em|Tk> group widgets.

    <item>The parent is sent as last argument, after optional labelled
    arguments.

    <hlkwa|let ><hlstd|top ><hlopt|= ><hlkwc|Tk><hlopt|.><hlstd|openTk
    ><hlopt|()><hlendline|><next-line><hlkwa|let
    ><hlstd|btn<textunderscore>frame ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwc|Frame><hlopt|.><hlstd|create
    <math|\<sim\>>relief><hlopt|:><hlstd|`><hlkwd|Groove
    ><hlstd|<math|\<sim\>>borderwidth><hlopt|:><hlnum|2
    ><hlstd|top><hlendline|><next-line><hlkwa|let ><hlstd|buttons
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwc|Array><hlopt|.><hlstd|map ><hlopt|(><hlkwc|Array><hlopt|.><hlstd|map
    ><hlopt|(><hlkwa|function><hlendline|><next-line><hlstd| \ <hlopt|\|>
    text><hlopt|, ><hlstd|`><hlkwd|Dot ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwc|Button><hlopt|.><hlstd|create
    <math|\<sim\>>text<hlendline|><next-line>
    \ \ \ \ \ <math|\<sim\>>command><hlopt|:(><hlkwa|fun ><hlopt|() -\<gtr\>
    ><hlkwc|F><hlopt|.><hlstd|send dot ><hlopt|())
    ><hlstd|btn<textunderscore>frame<hlendline|><next-line> \ <hlopt|\|>
    text><hlopt|, ><hlstd|`><hlkwd|Di ><hlstd|d
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwc|Button><hlopt|.><hlstd|create
    <math|\<sim\>>text<hlendline|><next-line>
    \ \ \ \ \ <math|\<sim\>>command><hlopt|:(><hlkwa|fun ><hlopt|() -\<gtr\>
    ><hlkwc|F><hlopt|.><hlstd|send digit d><hlopt|)
    ><hlstd|btn<textunderscore>frame<hlendline|><next-line> \ <hlopt|\|>
    text><hlopt|, ><hlstd|`><hlkwd|O ><hlstd|f
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwc|Button><hlopt|.><hlstd|create
    <math|\<sim\>>text<hlendline|><next-line>
    \ \ \ \ \ <math|\<sim\>>command><hlopt|:(><hlkwa|fun ><hlopt|() -\<gtr\>
    ><hlkwc|F><hlopt|.><hlstd|send op f><hlopt|)
    ><hlstd|btn<textunderscore>frame><hlopt|))
    ><hlstd|layout><hlendline|><next-line><hlkwa|let ><hlstd|result ><hlopt|=
    ><hlkwc|Label><hlopt|.><hlstd|create <math|\<sim\>>text><hlopt|:><hlstr|"0"><hlstd|
    <math|\<sim\>>relief><hlopt|:><hlstd|`><hlkwd|Sunken
    ><hlstd|top><hlendline|>

    <new-page*><item>GUI toolkits have layout algorithms, so we only need to
    tell which widgets hang together and whether they should fill all
    available space etc. -- via <verbatim|pack>, or <verbatim|grid> for
    ``rectangular'' organization.

    <item><hlstd|<math|\<sim\>>fill><hlopt|:> the allocated space in
    <verbatim|`X>, <verbatim|`Y>, <verbatim|`Both> or <verbatim|`None>
    axes;<next-line><hlstd|<math|\<sim\>>expand><hlopt|:> maximally how much
    space is allocated or only as needed.

    <item><hlstd|<math|\<sim\>>anchor><hlopt|:> allows to glue a widget in
    particular direction (<verbatim|`Center>, <verbatim|`E>, <verbatim|`Ne>
    etc.)

    <item>The <verbatim|grid> packing flexibility:
    <hlstd|<math|\<sim\>>columnspan> and <hlstd|<math|\<sim\>>rowspan>.

    <item><verbatim|configure> functions accept the same arguments as
    <verbatim|create> but change existing widgets.

    <new-page*><item><hlkwa|let ><hlopt|() =><hlendline|><next-line><hlstd|
    \ ><hlkwc|Wm><hlopt|.><hlstd|title<textunderscore>set top
    ><hlstr|"Calculator"><hlopt|;><hlendline|><next-line><hlstd|
    \ ><hlkwc|Tk><hlopt|.><hlstd|pack ><hlopt|[><hlstd|result><hlopt|]
    ><hlstd|<math|\<sim\>>side><hlopt|:><hlstd|`><hlkwd|Top
    ><hlstd|<math|\<sim\>>fill><hlopt|:><hlstd|`><hlkwd|X><hlopt|;><hlendline|><next-line><hlstd|
    \ ><hlkwc|Tk><hlopt|.><hlstd|pack ><hlopt|[><hlstd|btn<textunderscore>frame><hlopt|]
    ><hlstd|<math|\<sim\>>side><hlopt|:><hlstd|`><hlkwd|Bottom
    ><hlstd|<math|\<sim\>>expand><hlopt|:><hlkwa|true><hlopt|;><hlendline|><next-line><hlstd|
    \ ><hlkwc|Array><hlopt|.><hlstd|iteri ><hlopt|(><hlkwa|fun ><hlstd|column
    ><hlopt|-\<gtr\>><hlkwc|Array><hlopt|.><hlstd|iteri><hlopt| (><hlkwa|fun
    ><hlstd|row button ><hlopt|-\<gtr\>><next-line><hlstd|
    \ \ \ ><hlkwc|Tk><hlopt|.><hlstd|grid <math|\<sim\>>column
    <math|\<sim\>>row ><hlopt|[><hlstd|button><hlopt|]))
    ><hlstd|buttons><hlopt|;><hlendline|><next-line><hlstd|
    \ ><hlkwc|Wm><hlopt|.><hlstd|geometry<textunderscore>set top
    ><hlstr|"200x200"><hlopt|;><hlendline|><next-line><hlkwc|
    \ F><hlopt|.><hlstd|notify<textunderscore>e
    calc<textunderscore>e<hlendline|><next-line> \ ><hlopt| \ (><hlkwa|fun
    ><hlstd|now ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwc|Label><hlopt|.><hlstd|configure
    <math|\<sim\>>text><hlopt|:(><hlstd|string<textunderscore>of<textunderscore>float
    now><hlopt|) ><hlstd|result><hlopt|);><next-line><hlstd|
    \ ><hlkwc|Tk><hlopt|.><hlstd|mainLoop ><hlopt|()><hlendline|>

    <item><image|Lec10-Calc_Tk.png|202px|229px||>
  </itemize>

  <subsection|<new-page*><em|GTk+>: <em|LablGTk>>

  <\itemize>
    <item><strong|<em|LablGTk>> is build as an object-oriented layer over a
    low-level layer of functions interfacing with the <em|GTk+> library,
    which is written in <em|C>.

    <item>In OCaml, object fields are only visible to object methods, and
    methods are called with <hlopt|#> syntax, e.g. <hlstd|window#show
    ><hlopt|()>

    <item>The interaction with the application is reactive:

    <\itemize>
      <item>Our events are called signals in <em|GTk+>.

      <item>Registering a notification is called connecting a signal handler,
      e.g.<next-line><hlstd|button#connect#clicked
      <math|\<sim\>>callback><hlopt|:><hlstd|hello> which takes
      <hlstd|<math|\<sim\><no-break>>callback><hlopt|:(><hlkwb|unit
      ><hlopt|-\<gtr\> ><hlkwb|unit><hlopt|)> and returns
      <hlkwc|GtkSignal><hlopt|.><hlstd|id>.

      <\itemize>
        <item>As with <em|Froc> notifications, multiple handlers can be
        attached.
      </itemize>

      <item><em|GTk+> events are a subclass of signals related to more
      specific window events, e.g.<next-line><hlstd|window#event#connect#delete
      <math|\<sim\>>callback><hlopt|:><hlstd|delete<textunderscore>event>

      <item><em|GTk+> event callbacks take more info:
      <hlstd|<math|\<sim\>>callback><hlopt|:(><hlstd|event ><hlopt|-\<gtr\>
      ><hlkwb|unit><hlopt|)> for some type <verbatim|event>.
    </itemize>

    <new-page*><item>Automatic layout (aka. packing) seems less sophisticated
    than in <em|Tk>:

    <\itemize>
      <item>only horizontal and vertical boxes,

      <item>therefore <hlstd|<math|\<sim\>>fill> is binary and
      <hlstd|<math|\<sim\>>anchor> is replaced by <hlstd|<math|\<sim\>>from>
      <verbatim|`START> or <verbatim|`END>.
    </itemize>

    <item>Automatic grid layout is called <verbatim|table>.

    <\itemize>
      <item><hlstd|<math|\<sim\>>fill> and <hlstd|<math|\<sim\>>expand> take
      <verbatim|`X>, <verbatim|`Y>, <verbatim|`BOTH>, <verbatim|`NONE>.
    </itemize>

    <item>The <verbatim|coerce> method casts the type of the object (in
    <em|Tk> there is <verbatim|coe> function).

    <item>Labels don't have a dedicated module -- see definition of
    <verbatim|result> widget.

    <item>Widgets have setter methods <verbatim|widget#set_X> (instead of a
    single <verbatim|configure> function in <em|Tk>).

    <item>Invocation:<next-line><verbatim|ocamlbuild Lec10gtk.native -cflags
    -I,+froc -libs froc/froc<next-line> \ -pkg lablgtk2 -pp "camlp4o
    monad/pa_monad.cmo" -- >

    <item>The model part of application doesn't change.

    <new-page*><item>Setup:

    <hlkwa|let ><hlstd|<textunderscore> ><hlopt|=
    ><hlkwc|GtkMain><hlopt|.><hlkwc|Main><hlopt|.><hlstd|init
    ><hlopt|()><hlendline|><next-line><hlkwa|let ><hlstd|window
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwc|GWindow><hlopt|.><hlstd|window
    <math|\<sim\>>width><hlopt|:><hlnum|200
    ><hlstd|<math|\<sim\>>height><hlopt|:><hlnum|200
    ><hlstd|<math|\<sim\>>title><hlopt|:><hlstr|"Calculator"><hlstd|
    ><hlopt|()><hlendline|><next-line><hlkwa|let ><hlstd|top ><hlopt|=
    ><hlkwc|GPack><hlopt|.><hlstd|vbox <math|\<sim\>>packing><hlopt|:><hlstd|window#add
    ><hlopt|()><hlendline|><next-line><hlkwa|let ><hlstd|result ><hlopt|=
    ><hlkwc|GMisc><hlopt|.><hlstd|label <math|\<sim\>>text><hlopt|:><hlstr|"0"><hlstd|
    <math|\<sim\>>packing><hlopt|:><hlstd|top#add
    ><hlopt|()><hlendline|><next-line><hlkwa|let
    ><hlstd|btn<textunderscore>frame ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwc|GPack><hlopt|.><hlstd|table
    <math|\<sim\>>rows><hlopt|:(><hlkwc|Array><hlopt|.><hlstd|length
    layout><hlopt|)><hlendline|><next-line><hlstd|
    \ \ <math|\<sim\>>columns><hlopt|:(><hlkwc|Array><hlopt|.><hlstd|length
    layout><hlopt|.(><hlnum|0><hlopt|)) ><hlstd|<math|\<sim\>>packing><hlopt|:><hlstd|top#add
    ><hlopt|()>

    <new-page*><item>Button actions:

    <hlkwa|let ><hlstd|buttons ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwc|Array><hlopt|.><hlstd|map ><hlopt|(><hlkwc|Array><hlopt|.><hlstd|map
    ><hlopt|(><hlkwa|function><hlendline|><next-line><hlstd| \ <hlopt|\|>
    label><hlopt|, ><hlstd|`><hlkwd|Dot ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|b ><hlopt|=
    ><hlkwc|GButton><hlopt|.><hlstd|button <math|\<sim\>>label ><hlopt|()
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|<textunderscore> ><hlopt|= ><hlstd|b#connect#clicked<hlendline|><next-line>
    \ \ \ \ \ <math|\<sim\>>callback><hlopt|:(><hlkwa|fun ><hlopt|() -\<gtr\>
    ><hlkwc|F><hlopt|.><hlstd|send dot ><hlopt|()) ><hlkwa|in
    ><hlstd|b<hlendline|><next-line> \ <hlopt|\|> label><hlopt|,
    ><hlstd|`><hlkwd|Di ><hlstd|d ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|b ><hlopt|=
    ><hlkwc|GButton><hlopt|.><hlstd|button <math|\<sim\>>label ><hlopt|()
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|<textunderscore> ><hlopt|= ><hlstd|b#connect#clicked<hlendline|><next-line>
    \ \ \ \ \ <math|\<sim\>>callback><hlopt|:(><hlkwa|fun ><hlopt|() -\<gtr\>
    ><hlkwc|F><hlopt|.><hlstd|send digit d><hlopt|) ><hlkwa|in
    ><hlstd|b<hlendline|><next-line> \ <hlopt|\|> label><hlopt|,
    ><hlstd|`><hlkwd|O ><hlstd|f ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|b ><hlopt|=
    ><hlkwc|GButton><hlopt|.><hlstd|button <math|\<sim\>>label ><hlopt|()
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|<textunderscore> ><hlopt|= ><hlstd|b#connect#clicked<hlendline|><next-line>
    \ \ \ \ \ <math|\<sim\>>callback><hlopt|:(><hlkwa|fun ><hlopt|() -\<gtr\>
    ><hlkwc|F><hlopt|.><hlstd|send op f><hlopt|) ><hlkwa|in
    ><hlstd|b><hlopt|)) ><hlstd|layout><hlendline|>

    <new-page*><item>Button layout, result notification, start application:

    <hlkwa|let ><hlstd|delete<textunderscore>event <textunderscore> ><hlopt|=
    ><hlkwc|GMain><hlopt|.><hlkwc|Main><hlopt|.><hlstd|quit ><hlopt|();
    ><hlkwa|false><hlendline|><next-line><hlkwa|let ><hlopt|()
    =><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|<textunderscore>
    ><hlopt|= ><hlstd|window#event#connect#delete
    <math|\<sim\>>callback><hlopt|:><hlstd|delete<textunderscore>event
    ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwc|Array><hlopt|.><hlstd|iteri ><hlopt|(><hlkwa|fun
    ><hlstd|column><hlopt|-\<gtr\>><hlkwc|Array><hlopt|.><hlstd|iteri
    ><hlopt|(><hlkwa|fun ><hlstd|row button
    ><hlopt|-\<gtr\>><next-line><hlstd| \ \ \ btn<textunderscore>frame#attach
    <math|\<sim\>>left><hlopt|:><hlstd|column
    <math|\<sim\>>top><hlopt|:><hlstd|row<hlendline|><next-line>
    \ \ \ \ \ <math|\<sim\>>fill><hlopt|:><hlstd|`><hlkwd|BOTH
    ><hlstd|<math|\<sim\>>expand><hlopt|:><hlstd|`><hlkwd|BOTH
    ><hlopt|(><hlstd|button#coerce><hlopt|))><hlendline|><next-line><hlstd|
    \ ><hlopt|) ><hlstd|buttons><hlopt|;><hlendline|><next-line><hlstd|
    \ ><hlkwc|F><hlopt|.><hlstd|notify<textunderscore>e
    calc<textunderscore>e<hlendline|><next-line> \ \ \ ><hlopt|(><hlkwa|fun
    ><hlstd|now ><hlopt|-\<gtr\> ><hlstd|result#set<textunderscore>label
    ><hlopt|(><hlstd|string<textunderscore>of<textunderscore>float
    now><hlopt|));><hlendline|><next-line><hlstd| \ window#show
    ><hlopt|();><hlendline|><next-line><hlstd|
    \ ><hlkwc|GMain><hlopt|.><hlkwc|Main><hlopt|.><hlstd|main
    ><hlopt|()><hlendline|>

    <item><image|Lec10calc_gtk.png|202px|229px||>
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
  </collection>
</initial>

<\references>
  <\collection>
    <associate|auto-1|<tuple|1|2>>
    <associate|auto-10|<tuple|5.0.2|44>>
    <associate|auto-11|<tuple|6|50>>
    <associate|auto-12|<tuple|6.0.3|58>>
    <associate|auto-13|<tuple|7|61>>
    <associate|auto-14|<tuple|7.1|61>>
    <associate|auto-15|<tuple|7.2|67>>
    <associate|auto-16|<tuple|7.3|35>>
    <associate|auto-17|<tuple|2.1.5|37>>
    <associate|auto-18|<tuple|3.1.5|40>>
    <associate|auto-19|<tuple|3.1.5|42>>
    <associate|auto-2|<tuple|1.1|8>>
    <associate|auto-20|<tuple|3.1.5|43>>
    <associate|auto-21|<tuple|3.1.5|48>>
    <associate|auto-22|<tuple|3.1.5|53>>
    <associate|auto-23|<tuple|4.1.5|62>>
    <associate|auto-24|<tuple|4.1.5|69>>
    <associate|auto-25|<tuple|4.1.5|79>>
    <associate|auto-26|<tuple|5.1.5|86>>
    <associate|auto-27|<tuple|5.1.5|89>>
    <associate|auto-28|<tuple|5.1.5|90>>
    <associate|auto-29|<tuple|5.1.5|91>>
    <associate|auto-3|<tuple|2|13>>
    <associate|auto-30|<tuple|6.1.4|92>>
    <associate|auto-31|<tuple|6.1.5|93>>
    <associate|auto-32|<tuple|6.1.5|95>>
    <associate|auto-33|<tuple|7.1.5|96>>
    <associate|auto-34|<tuple|7.1.5|97>>
    <associate|auto-35|<tuple|7.1.5|99>>
    <associate|auto-36|<tuple|7.1.6|?>>
    <associate|auto-4|<tuple|2.0.1|14>>
    <associate|auto-5|<tuple|2.1|18>>
    <associate|auto-6|<tuple|3|21>>
    <associate|auto-7|<tuple|4|26>>
    <associate|auto-8|<tuple|4.0.1|34>>
    <associate|auto-9|<tuple|5|41>>
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
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Zippers>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Example: Context rewriting
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Adaptive
      Programming<with|font-size|<quote|1.189>| aka.Incremental Computing>>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3><vspace|0.5fn>

      <with|par-left|<quote|3fn>|Dependency Graphs (explained by Jake Dunham)
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4>>

      <with|par-left|<quote|1.5fn>|<new-page*>Example using
      <with|font-shape|<quote|italic>|Froc>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Functional
      Reactive Programming> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Reactivity
      by Stream Processing> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-7><vspace|0.5fn>

      <with|par-left|<quote|3fn>|<new-page*>The Paddle Game example
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-8>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Reactivity
      by Incremental Computing> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-9><vspace|0.5fn>

      <with|par-left|<quote|3fn>|<new-page*>Reimplementing the Paddle Game
      example <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-10>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Direct
      Control> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-11><vspace|0.5fn>

      <with|par-left|<quote|3fn>|<new-page*>Flows and state
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-12>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Graphical
      User Interfaces> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-13><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<with|font-shape|<quote|italic>|Tk>:
      <with|font-shape|<quote|italic>|LablTk>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-14>>

      <with|par-left|<quote|1.5fn>|<new-page*><with|font-shape|<quote|italic>|GTk+>:
      <with|font-shape|<quote|italic>|LablGTk>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-15>>
    </associate>
  </collection>
</auxiliary>