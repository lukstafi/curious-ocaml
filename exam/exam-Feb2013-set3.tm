<TeXmacs|1.0.7.16>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming><title-date|February 5th 2013>

  <\title>
    Exam set 3
  </title>

  <\exercise>
    (Blue.) What is the type of the subexpression <verbatim|f y> as part of
    the expression below assuming that the whole expression has the type
    given?

    <hlopt|(><hlkwa|fun ><hlstd|double g x ><hlopt|-\<gtr\> ><hlstd|double
    ><hlopt|(><hlstd|g x><hlopt|)) (><hlstd|><hlkwa|fun><hlstd| f y
    ><hlopt|-\<gtr\> ><hlstd|f ><hlopt|(><block|<tformat|<table|<row|<cell|<hlstd|f
    y>>>>>><hlopt|))>

    <hlopt| : (><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b ><hlopt|-\<gtr\>
    ><hlstd|'b><hlopt|) -\<gtr\> ><hlstd|'a ><hlopt|-\<gtr\> ><hlstd|'b
    ><hlopt|-\<gtr\> ><hlstd|'b>
  </exercise>

  <\exercise>
    (Blue.) Write an example function with type:

    <verbatim|(int -\<gtr\> int -\<gtr\> bool option) -\<gtr\> bool list>

    Tell ``in your words'' what it does.\ 
  </exercise>

  <\exercise>
    (Green.) Find the k'th element of a list.
  </exercise>

  <\exercise>
    (Green.) Insert an element at a given position into a list.
  </exercise>

  <\exercise>
    (Yellow.) Group the elements of a set into disjoint subsets. Represent
    sets as lists, preserve the order of elements. The required sizes of
    subsets are given as a list of numbers.
  </exercise>

  <\exercise>
    (Yellow.) A complete binary tree with height <math|H> is defined as
    follows: The levels <math|1,2,3,\<ldots\>,H-1> contain the maximum number
    of nodes (i.e <math|2<rsup|i-1>> at the level <math|i>, note that we
    start counting the levels from <math|1> at the root). In level <math|H>,
    which may contain less than the maximum possible number of nodes, all the
    nodes are "left-adjusted". This means that in a levelorder tree traversal
    all internal nodes come first, the leaves come second, and empty
    successors (the nil's which are not really nodes!) come last.

    We can assign an address number to each node in a complete binary tree by
    enumerating the nodes in levelorder, starting at the root with number 1.
    In doing so, we realize that for every node X with address A the
    following property holds: The address of X's left and right successors
    are 2*A and 2*A+1, respectively, supposed the successors do exist. This
    fact can be used to elegantly construct a complete binary tree structure.
    Write a function <verbatim|is_complete_binary_tree> with the following
    specification: <verbatim|is_complete_binary_tree n t> returns true iff
    <verbatim|t> is a complete binary tree with <verbatim|n> nodes.
  </exercise>

  <\exercise>
    (White.) Write two sorting algorithms, working on lists: merge sort and
    quicksort.

    <\enumerate>
      <item>Merge sort splits the list roughly in half, sorts the parts, and
      merges the sorted parts into the sorted result.

      <item>Quicksort splits the list into elements smaller/greater than the
      first element, sorts the parts, and puts them together.
    </enumerate>
  </exercise>

  <\exercise>
    (White.) Express in terms of <verbatim|fold_left> or
    <verbatim|fold_right>, i.e. with all recursion contained in the call to
    one of these functions, run-length encoding of a list (exercise 10 from
    <em|99 Problems>).

    <\itemize>
      <item><verbatim|encode [`a;`a;`a;`a;`b;`c;`c;`a;`a;`d] = [4,`a; 1,`b;
      2,`c; 2,`a; 1,`d]>
    </itemize>
  </exercise>

  <\exercise>
    (Orange.) Implement Priority Queue module that is an abstract data type
    for polymorphic queues parameterized by comparison function: the empty
    queue creation has signature

    \ \ <verbatim|val make_empty : leq:('a -\<gtr\> 'a -\<gtr\> bool)
    -\<gtr\> 'a prio_queue>

    Provide only functions: <verbatim|make_empty>, <verbatim|add>,
    <verbatim|min>, <verbatim|delete_min>. Is this data structure "safe"?

    Implement the heap as a <em|heap-ordered tree>, i.e. in which the element
    at each node is no larger than the elements at its children. Unbalanced
    binary trees are OK.
  </exercise>

  <\exercise>
    (Orange.) Write a function that transposes a rectangular matrix
    represented as a list of lists.
  </exercise>

  <\exercise>
    (Purple.) Find the bijective functions between the types corresponding to
    <math|a*(a<rsup|b>+c)> and <math|a<rsup|b+1>+a*c> (in OCaml).
  </exercise>

  <\exercise>
    (Purple.) Show the monad-plus laws for <verbatim|OptionM> monad.
  </exercise>

  <\exercise>
    (Red.) As a preparation for drawing the tree, a layout algorithm is
    required to determine the position of each node in a rectangular grid.
    Several layout methods are conceivable, one of them is shown in the
    illustration below.

    <image|Layout_bin_tree-p64.png|322px|174px||>

    In this layout strategy, the position of a node v is obtained by the
    following two rules:

    <\itemize>
      <item>x(v) is equal to the position of the node v in the inorder
      sequence;

      <item>y(v) is equal to the depth of the node v in the tree.
    </itemize>

    In order to store the position of the nodes, we redefine the OCaml type
    representing a node (and its successors) as follows:

    <\code>
      type 'a pos_binary_tree =

      \ \ \ \ \| E (* represents the empty tree *)

      \ \ \ \ \| N of 'a * int * int * 'a pos_binary_tree * 'a
      pos_binary_tree
    </code>

    <verbatim|N(w,x,y,l,r)> represents a (non-empty) binary tree with root w
    "positioned" at <verbatim|(x,y)>, and subtrees <verbatim|l> and
    <verbatim|r>. Write a function <verbatim|layout_binary_tree> with the
    following specification: <verbatim|layout_binary_tree t> returns the
    "positioned" binary tree obtained from the binary tree <verbatim|t>.

    An alternative layout method is depicted in the illustration:

    <image|Layout_bin_tree-p65.png|371px|144px||>

    Find out the rules and write the corresponding function.

    Hint: On a given level, the horizontal distance between neighboring nodes
    is constant.
  </exercise>

  <\exercise>
    (Crimson.) Nonograms. Each row and column of a rectangular bitmap is
    annotated with the respective lengths of its distinct strings of occupied
    cells. The person who solves the puzzle must complete the bitmap given
    only these lengths.

    <\code>
      \ \ \ \ \ \ \ \ \ \ Problem statement: \ \ \ \ \ \ \ \ \ Solution:

      \;

      \ \ \ \ \ \ \ \ \ \ \|_\|_\|_\|_\|_\|_\|_\|_\| 3
      \ \ \ \ \ \ \ \ \|_\|X\|X\|X\|_\|_\|_\|_\| 3

      \ \ \ \ \ \ \ \ \ \ \|_\|_\|_\|_\|_\|_\|_\|_\| 2 1
      \ \ \ \ \ \ \|X\|X\|_\|X\|_\|_\|_\|_\| 2 1

      \ \ \ \ \ \ \ \ \ \ \|_\|_\|_\|_\|_\|_\|_\|_\| 3 2
      \ \ \ \ \ \ \|_\|X\|X\|X\|_\|_\|X\|X\| 3 2

      \ \ \ \ \ \ \ \ \ \ \|_\|_\|_\|_\|_\|_\|_\|_\| 2 2
      \ \ \ \ \ \ \|_\|_\|X\|X\|_\|_\|X\|X\| 2 2

      \ \ \ \ \ \ \ \ \ \ \|_\|_\|_\|_\|_\|_\|_\|_\| 6
      \ \ \ \ \ \ \ \ \|_\|_\|X\|X\|X\|X\|X\|X\| 6

      \ \ \ \ \ \ \ \ \ \ \|_\|_\|_\|_\|_\|_\|_\|_\| 1 5
      \ \ \ \ \ \ \|X\|_\|X\|X\|X\|X\|X\|_\| 1 5

      \ \ \ \ \ \ \ \ \ \ \|_\|_\|_\|_\|_\|_\|_\|_\| 6
      \ \ \ \ \ \ \ \ \|X\|X\|X\|X\|X\|X\|_\|_\| 6

      \ \ \ \ \ \ \ \ \ \ \|_\|_\|_\|_\|_\|_\|_\|_\| 1
      \ \ \ \ \ \ \ \ \|_\|_\|_\|_\|X\|_\|_\|_\| 1

      \ \ \ \ \ \ \ \ \ \ \|_\|_\|_\|_\|_\|_\|_\|_\| 2
      \ \ \ \ \ \ \ \ \|_\|_\|_\|X\|X\|_\|_\|_\| 2

      \ \ \ \ \ \ \ \ \ \ \ 1 3 1 7 5 3 4 3 \ \ \ \ \ \ \ \ \ \ \ \ 1 3 1 7 5
      3 4 3

      \ \ \ \ \ \ \ \ \ \ \ 2 1 5 1 \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ 2
      1 5 1<verbatim|>
    </code>

    For the example above, the problem can be stated as the two lists
    <verbatim|[[3];[2;1];[3;2];[2;2];[6];[1;5];[6];[1];[2]]> and
    <verbatim|[[1;2];[3;1];[1;5];[7;1];[5];[3];[4];[3]]> which give the
    "solid" lengths of the rows and columns, top-to-bottom and left-to-right,
    respectively. Published puzzles are larger than this example, e.g. 25*20,
    and apparently always have unique solutions.
  </exercise>

  <\exercise>
    (Black.) Leftist heaps are heap-ordered binary trees that satisfy the
    <em|leftist property>: the rank of any left child is at least as large as
    the rank of its right sibling. The rank of a node is defined to be the
    length of its <em|right spine>, i.e. the rightmost path from the node in
    question to an empty node. Implement <math|O<around*|(|log n|)>> worst
    case time complexity Priority Queues based on leftist heaps. Each node of
    the tree should contain its rank.

    Note that the elements along any path through a heap-ordered tree are
    stored in sorted order. The key insight behind leftist heaps is that two
    heaps can be merged by merging their right spines as you would merge two
    sorted lists, and then swapping the children of nodes along this path as
    necessary to restore the leftist property.
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
    <associate|TravTreeEx|<tuple|3|?>>
    <associate|TreeM|<tuple|3|?>>
    <associate|auto-1|<tuple|1|?>>
  </collection>
</references>