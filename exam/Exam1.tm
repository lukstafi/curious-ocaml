<TeXmacs|1.0.7.14>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming>

  <\title>
    Exam<title-date|June 8th 2012>
  </title>

  <\exercise>
    Give types of the following expressions, either by guessing or inferring
    them by hand:

    <\enumerate>
      <item><hlstd|><hlkwa|let ><hlstd|double f y ><hlopt|= ><hlstd|f
      ><hlopt|(><hlstd|f y><hlopt|) ><hlstd|><hlkwa|in fun ><hlstd|g x
      ><hlopt|-\<gtr\> ><hlstd|double ><hlopt|(><hlstd|g x><hlopt|)><hlstd|>

      <item><hlkwa|let rec ><hlstd|tails l ><hlopt|= ><hlkwa|match ><hlstd|l
      ><hlkwa|with ><hlopt|[] -\<gtr\> [] ><hlstd|<hlopt|\|>
      x><hlopt|::><hlstd|xs ><hlopt|-\<gtr\>
      ><hlstd|xs><hlopt|::><hlstd|tails xs
      ><hlkwa|in><hlendline|><next-line><hlkwa|fun ><hlstd|l ><hlopt|-\<gtr\>
      ><hlkwc|List><hlopt|.><hlstd|combine l ><hlopt|(><hlstd|tails
      l><hlopt|)>
    </enumerate>
  </exercise>

  <\exercise>
    Assume that the corresponding expression from previous exercise is bound
    to name <verbatim|foo>. What are the values computed for the expressions
    (compute in your head or derive on paper):

    <\enumerate>
      <item><hlstd|foo ><hlopt|(+) ><hlnum|2 3><hlopt|, ><hlstd|foo ><hlopt|(
      * ) ><hlnum|2 3><hlopt|, ><hlstd|foo ><hlopt|( * ) ><hlnum|3 2>

      <item><hlstd|foo ><hlopt|[><hlnum|1><hlopt|; ><hlnum|2><hlopt|;
      ><hlnum|3><hlopt|]>
    </enumerate>
  </exercise>

  <\exercise>
    Give example expressions that have the following types (without using
    type constraints):

    <\enumerate>
      <item><verbatim|(int -\<gtr\> int) -\<gtr\> bool>

      <item><verbatim|'a option -\<gtr\> 'a list>
    </enumerate>
  </exercise>

  <\exercise>
    Write function that returns the list of all lists containing elements
    from the input list, preserving order from the input list, but without
    two elements.
  </exercise>

  <\exercise>
    Write a breadth-first-search function that returns an element from a
    binary tree for which a predicate holds, or <verbatim|None> if no such
    element exists. The function should have signature:

    <verbatim|val bfs : ('a -\<gtr\> bool) -\<gtr\> 'a btree -\<gtr\> 'a
    option>
  </exercise>

  <\exercise>
    Solve the n-queens problem using backtracking based on lists.

    Available functions: <verbatim|from_to>, <verbatim|concat_map>,
    <verbatim|concat_foldl>, <verbatim|unique>.

    Hint functions (asking for hint each loses one point):
    <verbatim|valid_queens>, <verbatim|add_queen>, <verbatim|find_queen>,
    <verbatim|find_queens>. Final function <verbatim|solve> takes <math|n> as
    an argument. Each function, other than <verbatim|valid_queens> that takes
    3 lines, fits on one line.
  </exercise>

  <\exercise>
    Provide an algebraic specification and an implementation for
    first-in-first-out queues (lecture 5 exercise 9).
  </exercise>
</body>