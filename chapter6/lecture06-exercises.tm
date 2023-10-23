<TeXmacs|1.0.7.16>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming>

  <\title>
    Mapping and folding

    List-based backtracking
  </title>

  <\exercise>
    Recall how we generated all subsequences of a list. Find (i.e. generate)
    all:

    <\enumerate>
      <item>permutations of a list;

      <item>ways of choosing without repetition from a list;

      <item>combinations of K distinct objects chosen from the N elements of
      a list.
    </enumerate>
  </exercise>

  <\exercise>
    Using folding for the <verbatim|expression> data type, compute the degree
    of the corresponding polynomial. See <hlink|http://en.wikipedia.org/wiki/Degree_of_a_polynomial|http://en.wikipedia.org/wiki/Degree_of_a_polynomial>.
  </exercise>

  <\exercise>
    Implement simplification of expressions using mapping for the
    <verbatim|expression> data type.
  </exercise>

  <\exercise>
    Express in terms of <verbatim|fold_left> or <verbatim|fold_right>:

    <\enumerate>
      <item><hlstd|indexed ><hlopt|: ><hlstr|'><hlstd|a list ><hlopt|-\<gtr\>
      (><hlkwb|int ><hlopt|* ><hlstr|'><hlstd|a><hlopt|) ><hlstd|list>, which
      pairs elements with their indices in the list;

      <item>* <verbatim|concat_fold>, as used in the solution of <em|Honey
      Islands> puzzle:

      <\itemize>
        <item><hlkwa|let rec ><hlstd|concat<textunderscore>fold f a ><hlopt|=
        ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| []
        -\<gtr\> [><hlstd|a><hlopt|]><hlendline|><next-line><hlstd|
        \ <hlopt|\|> x><hlopt|::><hlstd|xs ><hlopt|-\<gtr\>
        ><hlendline|><next-line><hlstd| \ \ \ f x a
        <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|a' ><hlopt|-\<gtr\>
        ><hlstd|concat<textunderscore>fold f a' xs><hlopt|)><hlendline|>

        <item>Hint -- consider the function:<next-line><hlkwa|let rec
        ><hlstd|concat<textunderscore>foldl f a ><hlopt|=
        ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| []
        -\<gtr\> ><hlstd|a<hlendline|><next-line> \ <hlopt|\|>
        x><hlopt|::><hlstd|xs ><hlopt|-\<gtr\>
        ><hlstd|concat<textunderscore>foldl f
        ><hlopt|(><hlstd|concat<textunderscore>map ><hlopt|(><hlstd|f
        x><hlopt|) ><hlstd|a><hlopt|) ><hlstd|xs><hlendline|>
      </itemize>

      <item>run-length encoding of a list (exercise 10 from <em|99
      Problems>).

      <\itemize>
        <item><verbatim|encode [`a;`a;`a;`a;`b;`c;`c;`a;`a;`d] = [4,`a; 1,`b;
        2,`c; 2,`a; 1,`d]>
      </itemize>
    </enumerate>
  </exercise>

  <\exercise>
    \;

    <\enumerate>
      <item>Write a more efficient variant of <verbatim|list_diff> that
      computes the difference of sets represented as sorted lists.

      <item><verbatim|is_unique> in the provided code takes quadratic time --
      optimize it.
    </enumerate>
  </exercise>

  <\exercise>
    Write functions <verbatim|compose> and <verbatim|perform> that take a
    list of functions and return their composition, i.e. a function
    <verbatim|compose [f1; <math|\<ldots\>>; fn] = x <math|\<mapsto\>> f1
    (<math|\<ldots\>> (fn x)<math|\<ldots\>>)> and <verbatim|perform [f1;
    <math|\<ldots\>>; fn] = x <math|\<mapsto\>> fn (<math|\<ldots\>> (f1
    x)<math|\<ldots\>>)>.
  </exercise>

  <\exercise>
    Write a solver for the <em|Tents Puzzle>
    <hlink|http://www.mathsisfun.com/games/tents-puzzle.html|http://www.mathsisfun.com/games/tents-puzzle.html>.
  </exercise>

  <\exercise>
    * <strong|Robot Squad>. We are given a map of terrain with empty spaces
    and walls, and lidar readings for multiple robots, 8 readings of the
    distance to wall or another robot, for each robot. Robots are equipped
    with compasses, the lidar readings are in directions E, NE, N, NW, W,
    \ SW, S, SE. Determine the possible positions of robots.
  </exercise>

  <\exercise>
    * Write a solver for the <em|Plinx Puzzle>
    <hlink|http://www.mathsisfun.com/games/plinx-puzzle.html|http://www.mathsisfun.com/games/plinx-puzzle.html>.
    It does not need to always return correct solutions but it should
    correctly solve the initial levels from the game.
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
    <associate|auto-1|<tuple|1|?>>
  </collection>
</references>