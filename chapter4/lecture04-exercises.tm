<TeXmacs|1.0.7.15>

<style|<tuple|exam|highlight>>

<\body>
  <class|Functional Programming>

  <\title>
    Functions
  </title>

  <\exercise>
    Define (implement) and test on a couple of examples functions
    corresponding to / computing:

    <\enumerate>
      <item><verbatim|c_or> and <verbatim|c_not>;

      <item>exponentiation for Church numerals;

      <item>is-zero predicate for Church numerals;

      <item>even-number predicate for Church numerals;

      <item>multiplication for pair-encoded natural numbers;

      <item>factorial <math|n!> for pair-encoded natural numbers.

      <item>the length of a list (in Church numerals);

      <item><verbatim|cn_max> -- maximum of two Church numerals;

      <item>the depth of a tree (in Church numerals).
    </enumerate>
  </exercise>

  <\exercise>
    Representing side-effects as an explicitly ``passed around'' state value,
    write (higher-order) functions that represent the imperative constructs:

    <\enumerate>
      <item><hlkwa|for>...<hlkwa|to>...

      <item><hlkwa|for>...<hlkwa|downto>...

      <item><hlkwa|while>...<hlkwa|do>...

      <item><hlkwa|do>...<hlkwa|while>...

      <item><hlkwa|repeat>...<hlkwa|until>...
    </enumerate>

    Rather than writing a <math|\<lambda\>>-term using the encodings that
    we've learnt, just implement the functions in OCaml / F#, using built-in
    <hlkwb|int> and <hlkwb|bool> types. You can use <hlkwa|let rec> instead
    of <hlkwa|fix>.

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
  </exercise>

  Despite we will not cover them, it is instructive to see the implementation
  using the imperative features, to better understand what is actually
  required of a solution to this exercise.

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

    <item><hlkwa|let ><hlstd|while<textunderscore>do p f s
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
    <associate|page-type|letter>
  </collection>
</initial>

<\references>
  <\collection>
    <associate|TravTreeEx|<tuple|3|?>>
  </collection>
</references>