<TeXmacs|1.0.7.16>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming><title-date|February 5th 2013>

  <\title>
    Exam set 1
  </title>

  <\exercise>
    (Blue.) What is the type of the subexpression <verbatim|y> as part of the
    expression below assuming that the whole expression has the type given?

    <hlopt|(><hlkwa|fun ><hlstd|double g x ><hlopt|-\<gtr\> ><hlstd|double
    ><hlopt|(><hlstd|g x><hlopt|))><hlstd|> <hlopt|(><hlkwa|fun><hlstd| f y
    ><hlopt|-\<gtr\> ><hlstd|f ><hlopt|(><hlstd|f
    <block|<tformat|<table|<row|<cell|y>>>>>><hlopt|))>

    <hlopt| : (><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b ><hlopt|-\<gtr\>
    ><hlstd|'b><hlopt|) -\<gtr\> ><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b
    ><hlopt|-\<gtr\> ><hlstd|'b>
  </exercise>

  <\exercise>
    (Blue.) Write an example function with type:

    <verbatim|((int -\<gtr\> int) -\<gtr\> bool) -\<gtr\> int>

    Tell ``in your words'' what it does.
  </exercise>

  <\exercise>
    (Green.) Write a function <verbatim|last : 'a list -\<gtr\> 'a option>
    that returns the last element of a list.
  </exercise>

  <\exercise>
    (Green.) Duplicate the elements of a list.
  </exercise>

  <\exercise>
    (Yellow.) Drop every N'th element from a list.
  </exercise>

  <\exercise>
    (Yellow.) Construct completely balanced binary trees of given depth.

    In a completely balanced binary tree, the following property holds for
    every node: The number of nodes in its left subtree and the number of
    nodes in its right subtree are almost equal, which means their difference
    is not greater than one.

    Write a function <verbatim|cbal_tree> to construct completely balanced
    binary trees for a given number of nodes. The function should generate
    the list of all solutions (e.g. via backtracking). Put the letter
    <verbatim|'x'> as information into all nodes of the tree.
  </exercise>

  <\exercise>
    (White.) Due to Yaron Minsky.

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
    (White.) Design an algebraic specification and write a signature for
    first-in-first-out queues. Provide two implementations: one
    straightforward using a list, and another one using two lists: one for
    freshly added elements providing efficient queueing of new elements, and
    ``reversed'' one for efficient popping of old elements.
  </exercise>

  <\exercise>
    (Orange.) Implement <verbatim|while_do> in terms of
    <verbatim|repeat_until>.
  </exercise>

  <\exercise>
    (Orange.) Implement a map from keys to values (a dictionary) using only
    functions (without data structures like lists or trees).
  </exercise>

  <\exercise>
    (Purple.) One way to express constraints on a polymorphic function is to
    write its type in the form: <math|\<forall\>\<alpha\><rsub|1>\<ldots\>\<alpha\><rsub|n><around*|[|C|]>.\<tau\>>,
    where <math|\<tau\>> is the type of the function,
    <math|\<alpha\><rsub|1>\<ldots\>\<alpha\><rsub|n>> are the polymorphic
    type variables, and <math|C> are additional constraints that the
    variables <math|\<alpha\><rsub|1>\<ldots\>\<alpha\><rsub|n>> have to
    meet. Let's say we allow ``local variables'' in <math|C>: for example
    <math|C=\<exists\>\<beta\>.\<alpha\><rsub|1><wide|=|\<dot\>>list<around*|(|\<beta\>|)>>.
    Why the general form <math|\<forall\>\<beta\><around*|[|C|]>.\<beta\>> is
    enough to express all types of the general form
    <math|\<forall\>\<alpha\><rsub|1>\<ldots\>\<alpha\><rsub|n><around*|[|C|]>.\<tau\>>?
  </exercise>

  <\exercise>
    (Purple.) Define a type that corresponds to a set with a googleplex of
    elements (i.e. <math|10<rsup|10<rsup|100>>> elements).
  </exercise>

  <\exercise>
    (Red.) In a height-balanced binary tree, the following property holds for
    every node: The height of its left subtree and the height of its right
    subtree are almost equal, which means their difference is not greater
    than one. Consider a height-balanced binary tree of height <math|h>. What
    is the maximum number of nodes it can contain? Clearly, <math|maxN = 2h -
    1>. However, finding the minimum number <math|minN> is more difficult.

    Construct all the height-balanced binary trees with a given nuber of
    nodes. <verbatim|hbal_tree_nodes n> returns a list of all height-balanced
    binary tree with <verbatim|n> nodes.

    Find out how many height-balanced trees exist for <verbatim|n> = 15.
  </exercise>

  <\exercise>
    (Crimson.) To construct a Huffman code for symbols with
    probability/frequency, we can start by building a binary tree as follows.
    The algorithm uses a priority queue where the node with lowest
    probability is given highest priority:

    <\enumerate>
      <item>Create a leaf node for each symbol and add it to the priority
      queue.

      <item>While there is more than one node in the queue:

      <\enumerate>
        <item>Remove the two nodes of highest priority (lowest probability)
        from the queue.

        <item>Create a new internal node with these two nodes as children and
        with probability equal to the sum of the two nodes' probabilities.

        <item>Add the new node to the queue.
      </enumerate>

      <item>The remaining node is the root node and the tree is complete.
    </enumerate>

    Label each left edge by <verbatim|0> and right edge by <verbatim|1>. The
    final binary code assigns the string of bits on the path from root to the
    symbol as its code.

    We suppose a set of symbols with their frequencies, given as a list of
    Fr(S,F) terms. Example: <verbatim|fs = [Fr(a,45); Fr(b,13); Fr(c,12);
    Fr(d,16); Fr(e,9); Fr(f,5)]>. Our objective is to construct a list
    <verbatim|Hc(S,C)> terms, where <verbatim|C> is the Huffman code word for
    the symbol <verbatim|S>. In our example, the result could be <verbatim|hs
    = [Hc(a,'0'); Hc(b,'101'); Hc(c,'100'); Hc(d,'111'); Hc(e,'1101');
    Hc(f,'1100')]> [<verbatim|Hc(a,'01')>,...etc.]. The task shall be
    performed by the function huffman defined as follows:
    <verbatim|huffman(fs)> returns the Huffman code table for the frequency
    table <verbatim|fs>.
  </exercise>

  <\exercise>
    (Black.) Implement the Gaussian Elimination algorithm for solving linear
    equations and inverting square invertible matrices.
  </exercise>
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
    <associate|TravTreeEx|<tuple|3|?>>
    <associate|TreeM|<tuple|3|?>>
    <associate|auto-1|<tuple|1|?>>
  </collection>
</references>