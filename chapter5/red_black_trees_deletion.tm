<TeXmacs|1.0.7.16>

<style|<tuple|browser|highlight>>

<\body>
  <chapter|The missing method: Deleting from Okasaki's red-black
  trees><label|body><label|abstract-container><label|abstract-content>

  [<hlink|article index|../>] [] [<hlink|@mattmight|http://twitter.com/mattmight>]
  [<hlink|+mattmight|http://gplus.to/mattmight>] [<hlink|rss|../feed.rss>]

  Balanced-tree-based maps are a workhorse in functional programming.

  Because of their disarming simplicity, <hlink|Chris
  Okasaki|http://www.eecs.usma.edu/webs/people/okasaki/>'s <hlink|purely
  functional red-black trees|http://www.eecs.usma.edu/webs/people/okasaki/jfp99.ps>
  are a popular means for implementing such maps.

  In <hlink|his book|http://www.amazon.com/gp/product/0521663504?ie=UTF8&tag=ucmbread-20&linkCode=as2&camp=1789&creative=390957&creativeASIN=0521663504><image|http://www.assoc-amazon.com/e/ir?t=ucmbread-20&l=as2&o=1&a=0521663504|1px|1px||>,
  self-balancing binary search trees are less than a page of code.

  Except that delete is left as an exercise to the reader.

  Unfortunately, deletion is tricky.

  <\with|par-mode|center>
    <image|red-black-tree-deletion.png|400px|||>
  </with>

  <hlink|Stefan Kahrs|http://www.cs.kent.ac.uk/people/staff/smk/> devised a
  widely-copied functional red-black delete.

  But, the Kahrs algorithm is complex, because Stefan's primary goal was to
  enhance correctness by enforcing the red-black invariants with types.

  Transliterating this algorithm outside Haskell leads to <hlink|Byzantine
  code|https://lampsvn.epfl.ch/trac/scala/browser/scala/tags/R_2_8_1_final/src//library/scala/collection/immutable/RedBlack.scala#L1>.

  I wondered whether a simple, efficient, purely functional, "obviously
  correct" red-black delete algorithm is possible.

  Of course, it is.

  By temporarily allowing two new colors during the deletion
  process--double-black and negative black--it's easy to factor delete into
  three conceptually simple phases: remove, bubble and balance.

  Read on for the details of my implementation in Racket.

  <with|font-series|bold|Update:> <hlink|Wei
  Hu|http://www.cs.virginia.edu/~wh5a/> emailed me to point out that two of
  my cases for <code*|remove> are unnecessary, and can be deleted. The
  algorithm is even simpler now!

  <\with|par-mode|center>
    \ 
  </with>

  <section|Red-black trees><label|content-container><label|article-content>

  Red-black trees are self-balancing binary search trees in which every node
  has one of two colors: red or black.

  Red-black trees obey two additional invariants:

  <\enumerate>
    <item>Any path from the root to a leaf has the same number of black
    nodes.

    <item>All red nodes have two black children.
  </enumerate>

  Leaf nodes, which do not carry values, are considered black for the
  purposes of both height and coloring.

  Any tree that obeys these conditions ensures that the longest root-to-leaf
  path is no more than double the shortest root-to-leaf path. These
  constraints on path length guarantee fast, logarithmic reads, insertions
  and deletes.

  <subsection|Examples>

  The following is a valid red-black tree:

  <image|red-black-slides.002.png|400px|||>

  Both of the following are invalid red-black representations of the set
  {1,2,3}:

  <image|red-black-slides.003.png|400px|||>

  The following are valid representations of the set {1,2,3}:

  <image|red-black-slides.004.png|400px|||>

  <section|Delete: A high-level summary>

  There are many easy cases in red-black deletion--cases where the change is
  local and doesn't require rebalancing or (much) recoloring.

  The only hard case ends up being the removal of a black node with no
  children, since it alters the height of the tree.

  Fortunately, it's easy to break apart this case into three phases, each of
  which is conceptually simple and straightforward to implement.

  The trick is to add two temporary colors: double black and negative black.

  The three phases are then removing, bubbling and balancing:

  <\enumerate>
    <item>By adding the color double-black, the hard case reduces to changing
    the target node into a double-black leaf. A double-black node counts
    twice for black height, which allows the black-height invariant to be
    preserved.

    <item>Bubbling tries to eliminate the double black just created by a
    removal. Sometimes, it's possible to eliminate a double-black by
    recoloring its parent and its sibling. If that's not possible, then the
    double-black gets "bubbled up" to its parent. To do so, it might be
    necessary to recolor the double black's (red) sibling to negative black.

    <item>Balancing eliminates double blacks and negative blacks at the same
    time. Okasaki's red-black algorithms use a rebalancing procedure. It's
    possible to generalize this rebalancing procedure with two new cases so
    that it can reliably eliminate double blacks and negative blacks.
  </enumerate>

  <section|Red-black trees in Racket>

  My implementation of red-black trees is actually an implementation of
  red-black maps:

  <\code>
    ; Struct definition for sorted-map:

    (define-struct sorted-map (compare))

    \;

    ; \ Internal nodes:

    (define-struct (T sorted-map)

    \ \ (color left key value right))

    \;

    ; \ Leaf nodes:

    (define-struct (L sorted-map) ())

    \;

    ; \ Double-black leaf nodes:

    (define-struct (BBL sorted-map) ())
  </code>

  [In OCaml:]

  <hlstd|><hlstd| \ ><hlstd|><hlkwa|type ><hlstd|color ><hlopt|=
  ><hlstd|><hlkwd|R ><hlopt|\| ><hlkwd|B ><hlopt|\| ><hlkwd|BB ><hlopt|\|
  ><hlkwd|NB><hlendline|><next-line><hlstd|><hlstd| \ ><hlstd|><hlkwa|type
  ><hlstd|><hlopt|(><hlstd|><hlstr|'a, '><hlstd|b><hlopt|) ><hlstd|t
  ><hlopt|=><hlendline|><next-line><hlstd|><hlstd| \ \ \ ><hlopt|\| ><hlkwd|L
  ><hlopt|\| ><hlkwd|BBL><hlendline|Leaf nodes.><next-line><hlstd|><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|T ><hlstd|><hlkwa|of ><hlstd|color ><hlopt|*
  (><hlstd|><hlstr|'a, '><hlstd|b><hlopt|) ><hlstd|t ><hlopt|*
  (><hlstd|><hlstr|'a * '><hlstd|b><hlopt|) * (><hlstd|><hlstr|'a,
  '><hlstd|b><hlopt|) ><hlstd|t><hlendline|Internal nodes.><next-line>

  Every <code*|sorted-map> has a comparison function on keys [we ignore this,
  using <hlopt|\<less\>> and <hlopt|=>]. Each internal node (<code*|T>) has a
  color, a left sub-tree, a key, a value and a right sub-tree. There are also
  black leaf nodes (<code*|L>) and double-black leaf nodes (<code*|LBB>).

  The implementation contains four colors total--double black (<code*|'BB>),
  black (<code*|'B>), red (<code*|'R>) and negative black (<code*|'-B>,
  <verbatim|NB>):

  <image|red-black-slides.005.png|400px|||>

  To make the expression of routines and sub-routines compact and readable, I
  used Racket's fully extensible pattern-matching systems:

  <\code>
    ; Matches internal nodes:

    (define-match-expander T!

    \ \ (syntax-rules ()

    \ \ \ \ [(_) \ \ \ \ \ \ \ \ \ \ \ (T _ _ _ _ _ _)]

    \ \ \ \ [(_ l r) \ \ \ \ \ \ \ (T _ _ l _ _ r)]

    \ \ \ \ [(_ c l r) \ \ \ \ \ (T _ c l _ _ r)]

    \ \ \ \ [(_ l k v r) \ \ \ (T _ _ l k v r)]

    \ \ \ \ [(_ c l k v r) \ (T _ c l k v r)]))

    \;

    ; Matches leaf nodes:\ 

    (define-match-expander L!

    \ \ (syntax-rules ()

    \ \ \ \ [(_) \ \ \ \ (L _)]))

    \;

    ; Matches black nodes (leaf or internal):

    (define-match-expander B

    \ \ (syntax-rules ()

    \ \ \ \ [(_) \ \ \ \ \ \ \ \ \ \ \ \ \ (or (T _ 'B _ _ _ _)

    \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ (L _))]

    \ \ \ \ [(_ cmp) \ \ \ \ \ \ \ \ \ (or (T cmp 'B _ _ _ _)

    \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ (L cmp))]

    \ \ \ \ [(_ l r) \ \ \ \ \ \ \ \ \ (T _ 'B l _ _ r)]

    \ \ \ \ [(_ l k v r) \ \ \ \ \ (T _ 'B l k v r)]

    \ \ \ \ [(_ cmp l k v r) \ (T cmp 'B l k v r)]))

    \;

    ; Matches red nodes:

    (define-match-expander R

    \ \ (syntax-rules ()

    \ \ \ \ [(_) \ \ \ \ \ \ \ \ \ \ \ \ \ (T _ 'R _ _ _ _)]

    \ \ \ \ [(_ cmp) \ \ \ \ \ \ \ \ \ (T cmp 'R _ _ _ _)]

    \ \ \ \ [(_ l r) \ \ \ \ \ \ \ \ \ (T _ 'R l _ _ r)]

    \ \ \ \ [(_ l k v r) \ \ \ \ \ (T _ 'R l k v r)]

    \ \ \ \ [(_ cmp l k v r) \ (T cmp 'R l k v r)]))

    \;

    ; Matches negative black nodes:

    (define-match-expander -B

    \ \ (syntax-rules ()

    \ \ \ \ [(_) \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ (T _ '-B _ _ _ _)]

    \ \ \ \ [(_ cmp) \ \ \ \ \ \ \ \ \ \ \ (T cmp '-B _ _ _ _)]

    \ \ \ \ [(_ l k v r) \ \ \ \ \ \ \ (T _ '-B l k v r)]

    \ \ \ \ [(_ cmp l k v r) \ \ \ (T cmp '-B l k v r)]))

    \;

    ; Matches double-black nodes (leaf or internal):

    (define-match-expander BB

    \ \ (syntax-rules ()

    \ \ \ \ [(_) \ \ \ \ \ \ \ \ \ \ \ \ \ (or (T _ 'BB _ _ _ _)

    \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ (BBL _))]

    \ \ \ \ [(_ cmp) \ \ \ \ \ \ \ \ \ (or (T cmp 'BB _ _ _ _)

    \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ (BBL _))]

    \ \ \ \ [(_ l k v r) \ \ \ \ \ (T _ 'BB l k v r)]

    \ \ \ \ [(_ cmp l k v r) \ (T cmp 'BB l k v r)]))
  </code>

  [We don't have active patterns in vanilla OCaml, although they're available
  in F# and there is an OCaml syntax extension...]

  To further condense cases, the implementation also uses color arithmetic.
  For instance, adding a black to a black yields a double-black. Subtracting
  a black from a black yields a red. Subtracting a black from a red yields a
  negative black. In Racket:

  <\code>
    (define/match (black+1 color-or-node)

    \ \ [(T cmp c l k v r) \ (T cmp (black+1 c) l k v r)]

    \ \ [(L cmp) \ \ \ \ \ \ \ \ \ \ \ (BBL cmp)]

    \ \ ['-B 'R]

    \ \ ['R \ 'B]

    \ \ ['B \ 'BB])

    \;

    (define/match (black-1 color-or-node)

    \ \ [(T cmp c l k v r) \ (T cmp (black-1 c) l k v r)]

    \ \ [(BBL cmp) \ \ \ \ \ \ \ \ \ (L cmp)]

    \ \ ['R \ \ '-B]

    \ \ ['B \ \ \ 'R]

    \ \ ['BB \ \ 'B])
  </code>

  [In OCaml:]

  <hlstd| \ ><hlkwa|let ><hlstd|blacken ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|R
  ><hlopt|-\<gtr\> ><hlkwd|B><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  ><hlkwd|B ><hlopt|-\<gtr\> ><hlkwd|BB><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|BB ><hlopt|-\<gtr\> ><hlstd|failwith
  ><hlstr|"blacken: impossible"><hlstd|<hlendline|><next-line>
  \ \ \ ><hlopt|\| ><hlkwd|NB ><hlopt|-\<gtr\>
  ><hlkwd|R><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|whiten
  ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  ><hlkwd|R ><hlopt|-\<gtr\> ><hlkwd|NB><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|B ><hlopt|-\<gtr\>
  ><hlkwd|R><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|BB
  ><hlopt|-\<gtr\> ><hlkwd|B><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  ><hlkwd|NB ><hlopt|-\<gtr\> ><hlstd|failwith ><hlstr|"whiten:
  impossible"><hlendline|><next-line>

  Diagrammatically:

  <image|red-black-slides.006.png|400px|||>

  <section|Red-black deletion in detail>

  In Racket, the skeleton for red-black deletion is:

  <\code>
    (define (sorted-map-delete node key)

    \ \ 

    \ \ ; The comparison function on keys:

    \ \ (define cmp (sorted-map-compare node))

    \ \ 

    \ \ ; Finds and deletes the node with the right key:

    \ \ (define (del node) ...)

    \;

    \ \ ; Removes this node; it might

    \ \ ; leave behind a double-black node:

    \ \ (define (remove node) ...)

    \ 

    \ \ ; Kills a double-black, or moves it upward;

    \ \ ; it might leave behind a negative black:

    \ \ (define (bubble c l k v r) ...)

    \ \ 

    \ \ ; Removes the max (rightmost) node in a tree;

    \ \ ; may leave behind a double-black at the root:

    \ \ (define (remove-max node) ...)

    \ \ \ 

    \ \ ; Delete the key, and color the new root black:

    \ \ (blacken (del node)))
  </code>

  [In OCaml, we also have these, and more for the whole red-black
  implementation of maps.]

  \;

  <subsection|Finding the target key>

  The procedure <code*|del> searches through the tree until it finds the node
  to delete, and then it calls <code*|remove>:

  <\code>
    \ \ (define/match (del node)

    \ \ \ \ [(T! c l k v r)

    \ \ \ \ \ ; =\<gtr\>

    \ \ \ \ \ (switch-compare (cmp key k)

    \ \ \ \ \ \ \ [\<less\> \ \ (bubble c (del l) k v r)]

    \ \ \ \ \ \ \ [= \ \ (remove node)]

    \ \ \ \ \ \ \ [\<gtr\> \ \ (bubble c l k v (del r))])]

    \ \ \ \ 

    \ \ \ \ [else \ \ \ \ node])
  </code>

  (<code*|define/match> and <code*|switch-compare> are macros to make the
  code more compact and readable.)

  [In OCaml, I call it <verbatim|remove> and it is mutually recursive with
  <verbatim|delete>:]

  <hlstd| \ ><hlkwa|and ><hlstd|remove k ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  ><hlkwd|BBL ><hlopt|-\<gtr\> ><hlstd|failwith ><hlstr|"remove:
  impossible"><hlstd|<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|L
  ><hlopt|-\<gtr\> ><hlkwd|L><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  ><hlkwd|T ><hlopt|(><hlstd|<textunderscore>><hlopt|,><hlstd|<textunderscore>><hlopt|,(><hlstd|k2><hlopt|,><hlstd|<textunderscore>><hlopt|),><hlstd|<textunderscore>><hlopt|)
  ><hlkwa|as ><hlstd|m ><hlkwa|when ><hlstd|k ><hlopt|= ><hlstd|k2
  ><hlopt|-\<gtr\> ><hlstd|delete m<hlendline|><next-line> \ \ \ ><hlopt|\|
  ><hlkwd|T ><hlopt|(><hlstd|c><hlopt|,><hlstd|a><hlopt|,(><hlstd|k2><hlopt|,><hlstd|<textunderscore>
  ><hlkwa|as ><hlstd|x><hlopt|),><hlstd|b><hlopt|) ><hlkwa|when ><hlstd|k
  ><hlopt|\<less\> ><hlstd|k2 ><hlopt|-\<gtr\> ><hlstd|bubble
  ><hlopt|(><hlstd|c><hlopt|,><hlstd|remove k
  a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|T ><hlopt|(><hlstd|c><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|)
  -\<gtr\> ><hlstd|bubble ><hlopt|(><hlstd|c><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|remove
  k b><hlopt|)><hlendline|><next-line>

  Because deletion could produce a double-black node, the procedure
  <code*|bubble> gets invoked to move it upward.

  <subsection|Removal>

  The <code*|remove> procedure breaks removal into several cases:

  The cases group according to how many children the target node has. If the
  target node has two sub-trees, <code*|remove> reduces it to the case where
  there is at most one sub-tree.

  It's easy to turn removal of a node with two children into removal of a
  node with at most one child: find the maximum (rightmost) element in its
  left (less-than) sub-tree; remove that node instead, and place its value
  into the node to be removed.

  For example, removing the blue node (with two children) reduces to removing
  the green node (with one) and then overwriting the blue with the green:

  <image|red-black-slides.007.png|400px|||>

  If the target node has leaves for children, removal is straightforward:

  <image|red-black-slides.008.png|400px|||>

  A red node becomes a leaf node; a black node becomes a double-black leaf.

  If the target node has one child, there is only one possible case. (I
  originally thought there were three, but <hlink|Wei
  Hu|http://www.cs.virginia.edu/~wh5a/> pointed out that the other two
  violate red-black constraints, and cannot happen.)

  That single case is where the target node is black and its child is red.

  The child becomes the parent, and it is made black:

  <image|red-black-slides.009.png|400px|||>

  The corresponding Racket code for these cases is:

  <\code>
    \ \ (define/match (remove node)

    \ \ \ \ ; Leaves are easy to kill:

    \ \ \ \ [(R (L!) (L!)) \ \ \ \ (L cmp)]

    \ \ \ \ [(B (L!) (L!)) \ \ \ \ (BBL cmp)]

    \ \ \ \ 

    \ \ \ \ ; Killing a node with one child:

    \ \ \ \ [(or (B (R l k v r) (L!))

    \ \ \ \ \ \ \ \ \ (B (L!) (R l k v r)))

    \ \ \ \ \ ; =\<gtr\>

    \ \ \ \ \ (T cmp 'B l k v r)]

    \ \ \ \ 

    \ \ \ \ ; Killing a node with two sub-trees:

    \ \ \ \ [(T! c (and l (T!)) (and r (T!)))

    \ \ \ \ \ ; =\<gtr\>

    \ \ \ \ \ (match-let (((cons k v) (sorted-map-max l))

    \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ (l* \ \ \ \ \ \ \ \ (remove-max l)))

    \ \ \ \ \ \ \ (bubble c l* k v r))])
  </code>

  [In OCaml, I call it <verbatim|delete> because I've called deletion
  <verbatim|remove>:]

  <hlstd| \ ><hlkwa|let rec ><hlstd|delete ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlkwd|L><hlopt|,><hlstd|<textunderscore>><hlopt|,><hlkwd|L><hlopt|)
  -\<gtr\> ><hlkwd|L><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  ><hlkwd|T ><hlopt|(><hlkwd|B><hlopt|,><hlkwd|L><hlopt|,><hlstd|<textunderscore>><hlopt|,><hlkwd|L><hlopt|)
  -\<gtr\> ><hlkwd|BBL><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  ><hlkwd|T ><hlopt|(><hlkwd|B><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlstd|a><hlopt|,><hlstd|p><hlopt|,><hlstd|b><hlopt|),><hlstd|<textunderscore>><hlopt|,><hlkwd|L><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|T ><hlopt|(><hlkwd|B><hlopt|,><hlkwd|L><hlopt|,><hlstd|<textunderscore>><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlstd|a><hlopt|,><hlstd|p><hlopt|,><hlstd|b><hlopt|))
  -\<gtr\> ><hlkwd|T ><hlopt|(><hlkwd|B><hlopt|,><hlstd|a><hlopt|,><hlstd|p><hlopt|,><hlstd|b><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|T ><hlopt|(><hlstd|c><hlopt|,(><hlkwd|T
  ><hlstd|<textunderscore> ><hlkwa|as ><hlstd|a><hlopt|),><hlstd|x><hlopt|,(><hlkwd|T
  ><hlstd|<textunderscore> ><hlkwa|as ><hlstd|b><hlopt|))
  -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ bubble
  ><hlopt|(><hlstd|c><hlopt|,><hlstd|remove<textunderscore>max
  a><hlopt|,><hlstd|find<textunderscore>max
  a><hlopt|,><hlstd|b><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ <hlopt|\|> <textunderscore> ><hlopt|-\<gtr\> ><hlstd|failwith
  ><hlstr|"delete: impossible"><hlendline|><next-line>

  <subsection|Bubbling>

  The <code*|bubble> procedure moves double-blacks from children to parents,
  or eliminates them entirely if possible.

  There are six possible cases in which a double-black child appears:

  <image|red-black-slides.011.png|400px|||>

  In every case, the action necessary to move the double black upward is the
  same; a black is substracted from the children, and added to the parent:

  <image|red-black-slides.012.png|400px|||>

  This operation leads to the corresponding trees:

  <image|red-black-slides.013.png|400px|||>

  A dotted line indicates the need for a rebalancing operation, because of
  the possible introduction of a red/red or negative black/red parent/child
  relationship.

  Because the action is the same in every case, the code for bubble is short:

  <\code>
    \ \ (define (bubble c l k v r)

    \ \ \ \ (cond

    \ \ \ \ \ \ [(or (double-black? l) (double-black? r))

    \ \ \ \ \ \ \ ; =\<gtr\>

    \ \ \ \ \ \ \ (balance cmp (black+1 c) (black-1 l) k v (black-1 r))]

    \ \ \ \ \ \ 

    \ \ \ \ \ \ [else (T cmp c l k v r)]))
  </code>

  [In OCaml:]

  <hlstd| \ ><hlkwa|let ><hlstd|bubble ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  (><hlstd|c1><hlopt|,><hlkwd|T ><hlopt|(><hlstd|c2><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|),><hlstd|y><hlopt|,><hlkwd|T
  ><hlopt|(><hlstd|c3><hlopt|,><hlstd|c><hlopt|,><hlstd|z><hlopt|,><hlstd|d><hlopt|))
  ><hlkwa|when ><hlstd|c1><hlopt|=><hlkwd|BB ><hlkwa|or
  ><hlstd|c2><hlopt|=><hlkwd|BB ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ balance ><hlopt|(><hlstd|blacken c1><hlopt|,><hlkwd|T
  ><hlopt|(><hlstd|whiten c2><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|),><hlstd|y><hlopt|,><hlkwd|T
  ><hlopt|(><hlstd|whiten c3><hlopt|,><hlstd|c><hlopt|,><hlstd|z><hlopt|,><hlstd|d><hlopt|))><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| (><hlstd|c><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|)
  -\<gtr\> ><hlkwd|T ><hlopt|(><hlstd|c><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|)><hlendline|><next-line>

  <subsection|Generalizing rebalancing>

  Okasaki's balancing operation takes a tree with balanced black-height but
  improper coloring and performs a tree rotation and a recoloring.

  The original procedure focused on fixing red/red violations. The new
  procedure has to fix negative-black/red violations, and it also has to
  opportunistically eliminate double-blacks.

  The original procedure eliminated all of the red/red violations in these
  trees:

  <image|red-black-slides.014.png|400px|||>

  by turning them into this tree:

  <image|red-black-slides.015.png|400px|||>

  The extended procedure can handle a root that is double-black:

  <image|red-black-slides.016.png|400px|||>

  by turning them all into this tree:

  <image|red-black-slides.017.png|400px|||>

  If a negative black appears as the result of a bubbling, as in:

  <image|red-black-slides.018.png|400px|||>

  then a slightly deeper transformation is necessary:

  <image|red-black-slides.019.png|400px|||>

  Once again, the dotted lines indicate the possible introduction of a
  red/red violation that could need rebalancing.

  So, the balance procedure is recursive, but it won't call itself more than
  once.

  There is also the symmetric case for this last operation, and these two new
  cases take care of all possible negative blacks.

  In Racket, only two new cases are added to the balancing procedure:

  <\code>
    ; Turns a black-balanced tree with invalid colors

    ; into a black-balanced tree with valid colors:

    (define (balance-node node)

    \ \ (define cmp (sorted-map-compare node))

    \ \ (match node

    \;

    \ \ \ \ ; Classic balance, but also catches double blacks:

    \ \ \ \ [(or (T! (or 'B 'BB) (R (R a xk xv b) yk yv c) zk zv d)

    \ \ \ \ \ \ \ \ \ (T! (or 'B 'BB) (R a xk xv (R b yk yv c)) zk zv d)

    \ \ \ \ \ \ \ \ \ (T! (or 'B 'BB) a xk xv (R (R b yk yv c) zk zv d))

    \ \ \ \ \ \ \ \ \ (T! (or 'B 'BB) a xk xv (R b yk yv (R c zk zv d))))

    \ \ \ \ \ ; =\<gtr\>

    \ \ \ \ \ (T cmp (black-1 (T-color node))\ 

    \ \ \ \ \ \ \ \ \ \ \ \ (T cmp 'B a xk xv b)

    \ \ \ \ \ \ \ \ \ \ \ \ yk yv\ 

    \ \ \ \ \ \ \ \ \ \ \ \ (T cmp 'B c zk zv d))]

    \;

    \ \ \ \ ; Two new cases to eliminate negative blacks:

    \ \ \ \ [(BB a xk xv (-B (B b yk yv c) zk zv (and d (B))))

    \ \ \ \ \ ; =\<gtr\>

    \ \ \ \ \ (T cmp 'B (T cmp 'B a xk xv b)

    \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ yk yv

    \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ (balance cmp 'B c zk zv (redden d)))]

    \ \ \ \ 

    \ \ \ \ [(BB (-B (and a (B)) xk xv (B b yk yv c)) zk zv d)

    \ \ \ \ \ ; =\<gtr\>

    \ \ \ \ \ (T cmp 'B (balance cmp 'B (redden a) xk xv b)

    \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ yk yv

    \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ (T cmp 'B c zk zv d))]

    \ \ \ \ 

    \ \ \ \ [else \ \ \ \ node]))

    \ \ 

    (define (balance cmp c l k v r)

    \ \ (balance-node (T cmp c l k v r)))
  </code>

  [In OCaml:]

  <hlstd| \ ><hlkwa|let rec ><hlstd|balance ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  ((><hlkwd|B ><hlopt|\| ><hlkwd|BB><hlopt|) ><hlkwa|as
  ><hlstd|col><hlopt|,><hlkwd|T ><hlopt|(><hlkwd|R><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|),
  ><hlstd|y><hlopt|, ><hlstd|c><hlopt|),><hlstd|z><hlopt|,><hlstd|d><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ((><hlkwd|B ><hlopt|\| ><hlkwd|BB><hlopt|) ><hlkwa|as
  ><hlstd|col><hlopt|,><hlkwd|T ><hlopt|(><hlkwd|R><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlstd|b><hlopt|,><hlstd|y><hlopt|,><hlstd|c><hlopt|)),><hlstd|z><hlopt|,><hlstd|d><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ((><hlkwd|B ><hlopt|\| ><hlkwd|BB><hlopt|) ><hlkwa|as
  ><hlstd|col><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlkwd|T ><hlopt|(><hlkwd|R><hlopt|,><hlstd|b><hlopt|,><hlstd|y><hlopt|,><hlstd|c><hlopt|),><hlstd|z><hlopt|,><hlstd|d><hlopt|))><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ((><hlkwd|B ><hlopt|\| ><hlkwd|BB><hlopt|) ><hlkwa|as
  ><hlstd|col><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlstd|b><hlopt|,><hlstd|y><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlstd|c><hlopt|,><hlstd|z><hlopt|,><hlstd|d><hlopt|)))
  -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwd|T
  ><hlopt|(><hlstd|whiten col><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|B><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|),><hlstd|y><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|B><hlopt|,><hlstd|c><hlopt|,><hlstd|z><hlopt|,><hlstd|d><hlopt|))><hlendline|><next-line><hlstd|<hlendline|><next-line>
  \ \ \ ><hlopt|\| (><hlkwd|BB><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|NB><hlopt|,><hlkwd|T ><hlopt|(><hlkwd|B><hlopt|,><hlstd|a><hlopt|,><hlstd|w><hlopt|,><hlstd|b><hlopt|),><hlstd|x><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|B><hlopt|,><hlstd|c><hlopt|,><hlstd|y><hlopt|,><hlstd|d><hlopt|)),><hlstd|z><hlopt|,><hlstd|e><hlopt|)
  -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwd|T
  ><hlopt|(><hlkwd|B><hlopt|,><hlstd|balance
  ><hlopt|(><hlkwd|B><hlopt|,><hlkwd|T ><hlopt|(><hlkwd|R><hlopt|,><hlstd|a><hlopt|,><hlstd|w><hlopt|,><hlstd|b><hlopt|),><hlstd|x><hlopt|,><hlstd|c><hlopt|),><hlstd|y><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|B><hlopt|,><hlstd|d><hlopt|,><hlstd|z><hlopt|,><hlstd|e><hlopt|))><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| (><hlkwd|BB><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|NB><hlopt|,><hlkwd|T ><hlopt|(><hlkwd|B><hlopt|,><hlstd|b><hlopt|,><hlstd|y><hlopt|,><hlstd|c><hlopt|),><hlstd|z><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|B><hlopt|,><hlstd|d><hlopt|,><hlstd|w><hlopt|,><hlstd|e><hlopt|)))
  -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwd|T
  ><hlopt|(><hlkwd|B><hlopt|,><hlkwd|T ><hlopt|(><hlkwd|B><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|),><hlstd|y><hlopt|,><hlstd|balance
  ><hlopt|(><hlkwd|B><hlopt|,><hlstd|c><hlopt|,><hlstd|z><hlopt|,><hlkwd|T
  ><hlopt|(><hlkwd|R><hlopt|,><hlstd|d><hlopt|,><hlstd|w><hlopt|,><hlstd|e><hlopt|)))><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| (><hlstd|color><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|)
  -\<gtr\> ><hlkwd|T ><hlopt|(><hlstd|color><hlopt|,><hlstd|a><hlopt|,><hlstd|x><hlopt|,><hlstd|b><hlopt|)><hlendline|><next-line>

  And, that's it.

  <section|Code>

  The code is available as a Racket module. My testing script is also
  available:

  <\itemize>
    <item><hlink|sorted-map.rkt|./code/sorted-map.rkt> - a functional sorted
    map module.

    <item><hlink|sorted-map-test.rkt|./code/sorted-map-test.rkt> - a testing
    script.
  </itemize>

  The testing system uses a mixture of exhaustive testing (on all trees with
  up to eight elements) and randomized testing (on much larger trees).

  I'm confident it flushed the bugs out of my implementation. Please let me
  know if you find a test case that breaks it.

  <subsection|More resources>

  <\itemize>
    <item>Every functional programmer should have a copy of Chris Okasaki's
    <hlink|Purely Functional Data Structures|http://www.amazon.com/gp/product/0521663504?ie=UTF8&tag=ucmbread-20&linkCode=as2&camp=1789&creative=390957&creativeASIN=0521663504><image|http://www.assoc-amazon.com/e/ir?t=ucmbread-20&l=as2&o=1&a=0521663504|1px|1px||>.

    <item>Richard Bird's brand new <hlink|Pearls of Functional Algorithm
    Design|http://www.amazon.com/gp/product/0521513383?ie=UTF8&tag=ucmbread-20&linkCode=as2&camp=1789&creative=390957&creativeASIN=0521513383><image|http://www.assoc-amazon.com/e/ir?t=ucmbread-20&l=as2&o=1&a=0521513383|1px|1px||>
    is a fantastic case-study book on the design of elegant functional
    algorithms.
  </itemize>

  <hrule>

  [<hlink|article index|../>] [] [<hlink|@mattmight|http://twitter.com/mattmight>]
  [<hlink|+mattmight|http://gplus.to/mattmight>] [<hlink|rss|../feed.rss>]

  <\with|par-mode|center>
    <label|footer-ad>\ 
  </with>

  <\with|par-mode|center>
    <label|footer-linode>matt.might.net is powered by
    <with|font-series|bold|<hlink|linode|http://www.linode.com/?r=bf5d4e7c8a1af61855b5227279a6744c3bde8a8a>>.
  </with>
</body>

<\initial>
  <\collection>
    <associate|page-screen-height|1114880tmpt>
    <associate|page-screen-width|1136640tmpt>
  </collection>
</initial>

<\references>
  <\collection>
    <associate|abstract-container|<tuple|1|?>>
    <associate|abstract-content|<tuple|1|?>>
    <associate|article-content|<tuple|1|?>>
    <associate|auto-1|<tuple|1|?>>
    <associate|auto-10|<tuple|4.4|?>>
    <associate|auto-11|<tuple|5|?>>
    <associate|auto-12|<tuple|5.1|?>>
    <associate|auto-2|<tuple|1|?>>
    <associate|auto-3|<tuple|1.1|?>>
    <associate|auto-4|<tuple|2|?>>
    <associate|auto-5|<tuple|3|?>>
    <associate|auto-6|<tuple|4|?>>
    <associate|auto-7|<tuple|4.1|?>>
    <associate|auto-8|<tuple|4.2|?>>
    <associate|auto-9|<tuple|4.3|?>>
    <associate|body|<tuple|1|?>>
    <associate|content-container|<tuple|1|?>>
    <associate|footer-ad|<tuple|<with|mode|<quote|math>|\<bullet\>>|?>>
    <associate|footer-linode|<tuple|<with|mode|<quote|math>|\<bullet\>>|?>>
  </collection>
</references>

<\auxiliary>
  <\collection>
    <\associate|toc>
      <vspace*|2fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|font-size|<quote|1.19>|The
      missing method: Deleting from Okasaki's red-black trees>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|1fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Red-black
      trees> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|Examples
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Delete:
      A high-level summary> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Red-black
      trees in Racket> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Red-black
      deletion in detail> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|Finding the target key
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-7>>

      <with|par-left|<quote|1.5fn>|Removal
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-8>>

      <with|par-left|<quote|1.5fn>|Bubbling
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-9>>

      <with|par-left|<quote|1.5fn>|Generalizing rebalancing
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-10>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Code>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-11><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|More resources
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-12>>
    </associate>
  </collection>
</auxiliary>