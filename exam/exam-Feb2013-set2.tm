<TeXmacs|1.0.7.16>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming><title-date|February 5th 2013>

  <\title>
    Exam set 2
  </title>

  <\exercise>
    (Blue.) What is the type of the subexpression <verbatim|f> as part of the
    expression below assuming that the whole expression has the type given?

    <hlopt|(><hlkwa|fun ><hlstd|double g x ><hlopt|-\<gtr\> ><hlstd|double
    ><hlopt|(><hlstd|g x><hlopt|)) (><hlkwa|fun><hlstd| f y ><hlopt|-\<gtr\>
    ><block|<tformat|<table|<row|<cell|<hlstd|f>>>>>><hlopt| (><hlstd|f
    y><hlopt|))>

    <hlopt| : (><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b ><hlopt|-\<gtr\>
    ><hlstd|'b><hlopt|) -\<gtr\> ><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b
    ><hlopt|-\<gtr\> ><hlstd|'b>
  </exercise>

  <\exercise>
    (Blue.) Write an example function with type:

    <verbatim|(int -\<gtr\> int list) -\<gtr\> bool>

    Tell ``in your words'' what it does.
  </exercise>

  <\exercise>
    (Green.) Find the number of elements of a list.
  </exercise>

  <\exercise>
    (Green.) Split a list into two parts; the length of the first part is
    given.
  </exercise>

  <\exercise>
    (Yellow.) Rotate a list N places to the left.
  </exercise>

  <\exercise>
    (Yellow.) Let us call a binary tree symmetric if you can draw a vertical
    line through the root node and then the right subtree is the mirror image
    of the left subtree. Write a function <verbatim|is_symmetric> to check
    whether a given binary tree is symmetric.
  </exercise>

  <\exercise>
    (White.) By ``traverse a tree'' we mean: write a function that takes a
    tree and returns a list of values in the nodes of the tree. Traverse a
    tree in breadth-first order -- first values in more shallow nodes.
  </exercise>

  <\exercise>
    (White.) Generate all combinations of K distinct elements chosen from the
    N elements of a list.
  </exercise>

  <\exercise>
    (Orange.) Implement a topological sort of a graph: write a function that
    either returns a list of graph nodes in topological order or informs (via
    exception or option type) that the graph has a cycle.
  </exercise>

  <\exercise>
    (Orange.) Express <verbatim|fold_left> in terms of <verbatim|fold_right>.
    Hint: continuation passing style.
  </exercise>

  <\exercise>
    (Purple.) Show why for a monomorphic specification, if datastructures
    <math|d<rsub|1>> and <math|d<rsub|2>> have the same behavior under all
    operations, then they have the same representation
    <math|d<rsub|1>=d<rsub|2>> in all implementations.
  </exercise>

  <\exercise>
    (Purple.) <verbatim|append> for lazy lists returns in constant time.
    Where has its linear-time complexity gone? Explain how you would account
    for this in a time complexity analysis.
  </exercise>

  <\exercise>
    (Red.) Write a function <verbatim|ms_tree graph> to construct the
    <em|minimal spanning tree> of a given weighted graph. A weighted graph
    will be represented as follows:

    <verbatim|type 'a weighted_graph = {nodes : 'a list; edges : ('a * 'a *
    int) list}>

    The labels identify the nodes <verbatim|'a> uniquely and there is at most
    one edge between a pair of nodes. A triple <verbatim|(a,b,w)> inside
    <verbatim|edges> corresponds to edge between <verbatim|a> and
    <verbatim|b> with weight <verbatim|w>. The minimal spanning tree is a
    subset of <verbatim|edges> that forms an undirected tree, covers all
    nodes of the graph, and has the minimal sum of weights.
  </exercise>

  <\exercise>
    (Crimson.) Von Koch's conjecture. Given a tree with N nodes (and hence
    N-1 edges). Find a way to enumerate the nodes from 1 to N and,
    accordingly, the edges from 1 to N-1 in such a way, that for each edge K
    the difference of its node numbers equals to K. The conjecture is that
    this is always possible.

    For small trees the problem is easy to solve by hand. However, for larger
    trees, and 14 is already very large, it is extremely difficult to find a
    solution. And remember, we don't know for sure whether there is always a
    solution!

    Write a function that calculates a numbering scheme for a given tree.
    What is the solution for the larger tree pictured above?
  </exercise>

  <\exercise>
    (Black.) Based on our search engine implementation, write a function that
    for a list of keywords returns three best "next keyword" suggestions (in
    some sense of "best", e.g. occurring in most of documents containing the
    given words).
  </exercise>

  \;
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
    <associate|TravTreeEx|<tuple|11|?>>
    <associate|TreeM|<tuple|3|?>>
    <associate|auto-1|<tuple|1|?>>
  </collection>
</references>