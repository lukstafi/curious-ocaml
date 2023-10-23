<TeXmacs|1.0.7.15>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming>

  <\title>
    Computation
  </title>

  <\exercise>
    <label|TravTreeEx>By ``traverse a tree'' below we mean: write a function
    that takes a tree and returns a list of values in the nodes of the tree.

    <\enumerate>
      <item>Write a function (of type <verbatim|btree -\<gtr\> int list>)
      that traverses a binary tree: in prefix order -- first the value stored
      in a node, then values in all nodes to the left, then values in all
      nodes to the right;

      <item>in infix order -- first values in all nodes to the left, then
      value stored in a node, then values in all nodes to the right (so it is
      ``left-to-right'' order);

      <item>in breadth-first order -- first values in more shallow nodes.
    </enumerate>
  </exercise>

  <\exercise>
    Turn the function from ex. <reference|TravTreeEx> point 1 or 2 into
    continuation passing style.
  </exercise>

  <\exercise>
    Do the homework from the end of last week slides: write
    <verbatim|btree_deriv_at>.
  </exercise>

  <\exercise>
    Write a function <verbatim|simplify: expression -\<gtr\> expression> that
    simplifies the expression a bit, so that for example the result of
    <verbatim|simplify (deriv exp dv)> looks more like what a human would get
    computing the derivative of <verbatim|exp> with respect to <verbatim|dv>:

    Write a <verbatim|simplify_once> function that performs a single step of
    the simplification, and wrap it using a general <verbatim|fixpoint>
    function that performs an operation until a <em|fixed point> is reached:
    given <math|f> and <math|x>, it computes <math|f<rsup|n><around*|(|x|)>>
    such that <math|f<rsup|n><around*|(|x|)>=f<rsup|n+1><around*|(|x|)>>.
  </exercise>

  <\exercise>
    Write two sorting algorithms, working on lists: merge sort and quicksort.

    <\enumerate>
      <item>Merge sort splits the list roughly in half, sorts the parts, and
      merges the sorted parts into the sorted result.

      <item>Quicksort splits the list into elements smaller/greater than the
      first element, sorts the parts, and puts them together.
    </enumerate>
  </exercise>

  \;
</body>

<\initial>
  <\collection>
    <associate|language|american>
    <associate|page-type|letter>
  </collection>
</initial>

<\references>
  <\collection>
    <associate|TravTreeEx|<tuple|1|?>>
  </collection>
</references>