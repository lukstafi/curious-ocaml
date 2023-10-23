<TeXmacs|1.0.7.15>

<style|<tuple|beamer|beamer-ridged-paper-lighter>>

<\body>
  <doc-data|<doc-title|Functional Programming>|<\doc-author-data|<author-name|Šukasz
  Stafiniak>>
    \;
  </doc-author-data|<author-email|lukstafi@gmail.com,
  lukstafi@ii.uni.wroc.pl>|<author-homepage|www.ii.uni.wroc.pl/~lukstafi>>>

  <doc-data|<doc-title|Lecture 3: Computation>|<\doc-subtitle>
    <\very-small>
      ``Using, Understanding and Unraveling the OCaml Language'' Didier Rémy,
      chapter 1

      ``The OCaml system'' manual, the tutorial part, chapter 1
    </very-small>
  </doc-subtitle>|>

  <new-page>

  <section|Function Composition>

  <\itemize>
    <item>The usual way function composition is defined in math is
    ``backward'':

    <\itemize>
      <item>math: <math|<around*|(|f\<circ\>g|)><around*|(|x|)>=f<around*|(|g<around*|(|x|)>|)>>

      <item>OCaml: <verbatim|let (-\|) f g x = f (g x)>

      <item>F#: <verbatim|let (\<less\>\<less\>) f g x = f (g x)>

      <item>Haskell: <verbatim|(.) f g = \\x -\<gtr\> f (g x)>
    </itemize>

    <item>It looks like function application, but needs less parentheses. Do
    you recall the functions <verbatim|iso1> and <verbatim|iso2> from
    previous lecture?

    <\code>
      let iso2 = step1l -\| step2l -\| step3l
    </code>

    <new-page*><item>A more natural definition of function composition is
    ``forward'':

    <\itemize>
      <item>OCaml: <verbatim|let (\|-) f g x = g (f x)>

      <item>F#: <verbatim|let (\<gtr\>\<gtr\>) f g x = g (f x)>
    </itemize>

    <item>It follows the order in which computation proceeds.

    <\code>
      let iso1 = step1r \|- step2r \|- step3r
    </code>

    <item><em|Partial application> is e.g. <verbatim|((+) 1)> from last week:
    we don't pass all arguments a function needs, in result we get a function
    that requires the remaining arguments. How is it used above?

    <new-page*><item>Now we define <math|f<rsup|n><around*|(|x|)>\<assign\><around*|(|f\<circ\>\<ldots\>\<circ\>f|)><around*|(|x|)>>
    (<math|f> appears <math|n> times).

    <\code>
      let rec power f n =

      \ \ if n \<less\>= 0 then (fun x -\<gtr\> x) else f -\| power f (n-1)
    </code>

    <item>Now we define a numerical derivative:

    <\code>
      let derivative dx f = fun x -\<gtr\> (f(x +. dx) -. f(x)) /. dx
    </code>

    where the intent to use with two arguments is stressed, or for short:

    <\code>
      let derivative dx f x = (f(x +. dx) -. f(x)) /. dx
    </code>

    <item>We have <verbatim|(+): int -\<gtr\> int -\<gtr\> int>, so cannot
    use with <verbatim|float>ing point numbers -- operators followed by dot
    work on <verbatim|float> numbers.

    <\code>
      let pi = 4.0 *. atan 1.0

      let sin''' = (power (derivative 1e-5) 3) sin;;

      sin''' pi;;
    </code>
  </itemize>

  <section|<new-page*>Evaluation Rules (reduction semantics)>

  <\itemize>
    <item>Programs consist of <strong|expressions>:

    <\eqnarray*>
      <tformat|<cwith|1|1|3|3|cell-halign|l>|<cwith|1|1|2|2|cell-halign|l>|<cwith|3|3|2|2|cell-halign|l>|<cwith|5|5|2|2|cell-halign|l>|<cwith|6|6|2|2|cell-halign|l>|<cwith|7|7|2|2|cell-halign|l>|<cwith|2|2|2|2|cell-halign|l>|<cwith|8|8|2|2|cell-halign|l>|<cwith|10|10|2|2|cell-halign|l>|<cwith|11|11|2|2|cell-halign|l>|<cwith|13|13|2|2|cell-halign|l>|<cwith|9|9|2|2|cell-halign|r>|<cwith|4|4|2|2|cell-halign|l>|<cwith|12|12|2|2|cell-halign|l>|<table|<row|<cell|a\<assign\>>|<cell|x>|<cell|<with|mode|text|variables>>>|<row|<cell|\|>|<cell|<with|mode|text|<verbatim|fun
      >>x<with|mode|text|<verbatim|-\<gtr\>>>a>|<cell|<with|mode|text|(defined)
      functions>>>|<row|<cell|\|>|<cell|a
      a>|<cell|<with|mode|text|applications>>>|<row|<cell|\|>|<cell|C<rsup|0>>|<cell|<with|mode|text|value
      constructors of arity >0>>|<row|<cell|\|>|<cell|C<rsup|n><around*|(|a,\<ldots\>,a|)>>|<cell|<with|mode|text|value
      constructors of arity >n>>|<row|<cell|\|>|<cell|f<rsup|n>>|<cell|<with|mode|text|built-in
      values (primitives) of a. >n>>|<row|<cell|\|>|<cell|<with|mode|text|<verbatim|let
      >>x=a<with|mode|text|<verbatim| in >>a>|<cell|<with|mode|text|name
      bindings (local definitions)>>>|<row|<cell|\|>|<cell|<with|mode|text|<verbatim|match
      >>a<with|mode|text|<verbatim| with>
      \ \ \ \ \ \ \ >>|<cell|>>|<row|<cell|>|<cell|p<with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
      \| >>\<ldots\><with|mode|text|<verbatim| \|
      >>p<with|mode|text|<verbatim|-\<gtr\>>>a>|<cell|<with|mode|text|pattern
      matching>>>|<row|<cell|p\<assign\>>|<cell|x>|<cell|<with|mode|text|pattern
      variables>>>|<row|<cell|\|>|<cell|<around*|(|p,\<ldots\>,p|)>>|<cell|<with|mode|text|tuple
      patterns>>>|<row|<cell|\|>|<cell|C<rsup|0>>|<cell|<with|mode|text|variant
      patterns of arity >0>>|<row|<cell|\|>|<cell|C<rsup|n><around*|(|p,\<ldots\>,p|)>>|<cell|<with|mode|text|variant
      patterns of arity >n>>>>
    </eqnarray*>

    <new-page*><item><em|Arity> means how many arguments something requires;
    (and for tuples, the length of a tuple).

    <item>To simplify presentation, we will use a primitive <verbatim|fix> to
    define a limited form of <verbatim|let rec>:

    <\equation*>
      <with|mode|text|<verbatim|let rec >>f<with|mode|text|<verbatim|
      >>x=e<rsub|1><with|mode|text|<verbatim| in
      >>e<rsub|2>\<equiv\><with|mode|text|<verbatim|let
      >>f=<with|mode|text|<verbatim|fix (fun >>f<with|mode|text|<verbatim|
      >>x<with|mode|text|<verbatim|-\<gtr\>>>e<rsub|1><with|mode|text|<verbatim|)
      in >>e<rsub|2>
    </equation*>

    <item>Expressions evaluate (i.e. compute) to <strong|values>:

    <\eqnarray*>
      <tformat|<cwith|2|2|3|3|cell-halign|c>|<cwith|3|3|3|3|cell-halign|c>|<cwith|1|1|3|3|cell-halign|c>|<cwith|1|1|2|2|cell-halign|l>|<cwith|2|2|2|2|cell-halign|l>|<cwith|3|3|2|2|cell-halign|l>|<table|<row|<cell|v\<assign\>>|<cell|<with|mode|text|<verbatim|fun
      >>x<with|mode|text|<verbatim|-\<gtr\>>>a>|<cell|<with|mode|text|(defined)
      functions>>>|<row|<cell|\|>|<cell|C<rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)>>|<cell|<with|mode|text|constructed
      values>>>|<row|<cell|\|>|<cell|f<rsup|n> v<rsub|1> \<ldots\>
      v<rsub|k>>|<cell|k\<less\>n<with|mode|text| partially applied
      primitives>>>>>
    </eqnarray*>

    <item>To <em|substitute> a value <math|v> for a variable <math|x> in
    expression <math|a> we write <math|a<around*|[|x\<assign\>v|]>> -- it
    behaves as if every occurrence of <math|x> in <math|a> was <em|rewritten>
    by <math|v>.

    <\itemize>
      <item>(But actually the value <math|v> is not duplicated.)
    </itemize>

    <new-page*><item>Reduction (i.e. computation) proceeds as follows: first
    we give <em|redexes>

    <\eqnarray*>
      <tformat|<cwith|7|7|3|3|cell-halign|c>|<table|<row|<cell|<around*|(|<with|mode|text|<verbatim|fun
      >>x<with|mode|text|<verbatim|-\<gtr\>>>a|)>
      v>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|<with|mode|text|<verbatim|let
      >>x=v<with|mode|text|<verbatim| in >>a>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|f<rsup|n>
      v<rsub|1> \<ldots\> v<rsub|n>>|<cell|\<rightsquigarrow\>>|<cell|f<around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)>>>|<row|<cell|<with|mode|text|<verbatim|match
      >>v<with|mode|text|<verbatim| with>
      >x<with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim| \|
      >>\<ldots\>>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x\<assign\>v|]>>>|<row|<cell|<with|mode|text|<verbatim|match
      >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)><with|mode|text|<verbatim|
      with>>>|<cell|>|<cell|>>|<row|<cell|C<rsub|2><rsup|n><around*|(|p<rsub|1>,\<ldots\>,p<rsub|k>|)><with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
      \| >>pm>|<cell|\<rightsquigarrow\>>|<cell|<with|mode|text|<verbatim|match
      >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)>>>|<row|<cell|>|<cell|>|<cell|<with|mode|text|<verbatim|with>
      >pm>>|<row|<cell|<with|mode|text|<verbatim|match
      >>C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)><with|mode|text|<verbatim|
      with>>>|<cell|>|<cell|>>|<row|<cell|C<rsub|1><rsup|n><around*|(|x<rsub|1>,\<ldots\>,x<rsub|n>|)><with|mode|text|<verbatim|-\<gtr\>>>a<with|mode|text|<verbatim|
      \| >>\<ldots\>>|<cell|\<rightsquigarrow\>>|<cell|a<around*|[|x<rsub|1>\<assign\>v<rsub|1>;\<ldots\>;x<rsub|n>\<assign\>v<rsub|n>|]>>>>>
    </eqnarray*>

    If <math|n=0>, <math|C<rsub|1><rsup|n><around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)>>
    stands for <math|C<rsup|0><rsub|1>>, etc. By
    <math|f<around*|(|v<rsub|1>,\<ldots\>,v<rsub|n>|)>> we denote the actual
    value resulting from computing the primitive. We omit the more complex
    cases of pattern matching.

    <item><very-small|Rule variables: <math|x> matches any expression/pattern
    variable; <math|a,a<rsub|1>,\<ldots\>,a<rsub|n>> match any expression;
    <math|v,v<rsub|1>,\<ldots\>,v<rsub|n>> match any value. Substitute them
    so that the left-hand-side of a rule is your expression, then the
    right-hand-side is the reduced expression.>

    <new-page*><item>The remaining rules evaluate the arguments in arbitrary
    order, but keep the order in which <verbatim|let>...<verbatim|in> and
    <verbatim|match>...<verbatim|with> is evaluated.

    If <math|a<rsub|i>\<rightsquigarrow\>a<rsub|i><rprime|'>>, then:

    <\eqnarray*>
      <tformat|<table|<row|<cell|a<rsub|1>
      a<rsub|2>>|<cell|\<rightsquigarrow\>>|<cell|a<rsub|1><rprime|'>
      a<rsub|2>>>|<row|<cell|a<rsub|1> a<rsub|2>>|<cell|\<rightsquigarrow\>>|<cell|a<rsub|1>
      a<rsub|2><rprime|'>>>|<row|<cell|C<rsup|n><around*|(|a<rsub|1>,\<ldots\>,a<rsub|i>,\<ldots\>,a<rsub|n>|)>>|<cell|\<rightsquigarrow\>>|<cell|C<rsup|n><around*|(|a<rsub|1>,\<ldots\>,a<rsub|i><rprime|'>,\<ldots\>,a<rsub|n>|)>>>|<row|<cell|<with|mode|text|<verbatim|let
      >>x=a<rsub|1><with|mode|text|<verbatim| in
      >>a<rsub|2>>|<cell|\<rightsquigarrow\>>|<cell|<with|mode|text|<verbatim|let
      >>x=a<rsub|1><rprime|'><with|mode|text|<verbatim| in
      >>a<rsub|2>>>|<row|<cell|<with|mode|text|<verbatim|match
      >>a<rsub|1><with|mode|text|<verbatim| with>
      >pm>|<cell|\<rightsquigarrow\>>|<cell|<with|mode|text|<verbatim|match
      >>a<rsub|1><rprime|'><with|mode|text|<verbatim| with> >pm>>>>
    </eqnarray*>

    <item>Finally, we give the rule for the primitive <verbatim|fix> -- it is
    a binary primitive:

    <\eqnarray*>
      <tformat|<table|<row|<cell|<with|mode|text|<verbatim|fix>><rsup|2>
      v<rsub|1> v<rsub|2>>|<cell|\<rightsquigarrow\>>|<cell|v<rsub|1>
      <around*|(|<with|mode|text|<verbatim|fix>><rsup|2> v<rsub|1>|)>
      v<rsub|2>>>>>
    </eqnarray*>

    Because <verbatim|fix> is binary, <math|<around*|(|<with|mode|text|<verbatim|fix>><rsup|2>
    v<rsub|1>|)>> is already a value so it will not be further computed until
    it is applied inside of <math|v<rsub|1>>.

    <item>Compute some programs using the rules by hand.
  </itemize>

  <section|<new-page*>Symbolic Derivation Example>

  Go through the examples from the <verbatim|Lec3.ml> file in the
  toplevel.<new-page>

  <\very-small>
    <\code>
      eval_1_2 \<less\>-- 3.00 * x + 2.00 * y + x * x * y

      \ \ eval_1_2 \<less\>-- x * x * y

      \ \ \ \ eval_1_2 \<less\>-- y

      \ \ \ \ eval_1_2 --\<gtr\> 2.

      \ \ \ \ eval_1_2 \<less\>-- x * x

      \ \ \ \ \ \ eval_1_2 \<less\>-- x

      \ \ \ \ \ \ eval_1_2 --\<gtr\> 1.

      \ \ \ \ \ \ eval_1_2 \<less\>-- x

      \ \ \ \ \ \ eval_1_2 --\<gtr\> 1.

      \ \ \ \ eval_1_2 --\<gtr\> 1.

      \ \ eval_1_2 --\<gtr\> 2.

      \ \ eval_1_2 \<less\>-- 3.00 * x + 2.00 * y

      \ \ \ \ eval_1_2 \<less\>-- 2.00 * y

      \ \ \ \ \ \ eval_1_2 \<less\>-- y

      \ \ \ \ \ \ eval_1_2 --\<gtr\> 2.

      \ \ \ \ \ \ eval_1_2 \<less\>-- 2.00

      \ \ \ \ \ \ eval_1_2 --\<gtr\> 2.

      \ \ \ \ eval_1_2 --\<gtr\> 4.

      \ \ \ \ eval_1_2 \<less\>-- 3.00 * x

      \ \ \ \ \ \ eval_1_2 \<less\>-- x

      \ \ \ \ \ \ eval_1_2 --\<gtr\> 1.

      \ \ \ \ \ \ eval_1_2 \<less\>-- 3.00

      \ \ \ \ \ \ eval_1_2 --\<gtr\> 3.

      \ \ \ \ eval_1_2 --\<gtr\> 3.

      \ \ eval_1_2 --\<gtr\> 7.

      eval_1_2 --\<gtr\> 9.

      - : float = 9.
    </code>
  </very-small>

  <section|<new-page*>Tail Calls (and tail recursion)>

  <\itemize>
    <item>Excuse me for not defining what a <em|function call> is...

    <item>Computers normally evaluate programs by creating <em|stack frames>
    on the stack for function calls (roughly like indentation levels in the
    above example).

    <item>A <strong|tail call> is a function call that is performed last when
    computing a function.

    <item>Functional language compilers will often insert a ``jump'' for a
    tail call instead of creating a stack frame.

    <item>A function is <strong|tail recursive> if it calls itself, and
    functions it mutually-recursively depends on, only using a tail call.

    <item>Tail recursive functions often have special <em|accumulator>
    arguments that store intermediate computation results which in a
    non-tail-recursive function would just be values of subexpressions.

    <item>The accumulated result is computed in ``reverse order'' -- while
    climbing up the recursion rather than while descending (i.e. returning)
    from it.

    <new-page*><item>The issue is more complex for <em|lazy> programming
    languages like Haskell.

    <item>Compare:

    <\small>
      <\code>
        # let rec unfold n = if n \<less\>= 0 then [] else n :: unfold
        (n-1);;

        val unfold : int -\<gtr\> int list = \<less\>fun\<gtr\>

        # unfold 100000;;

        - : int list =

        [100000; 99999; 99998; 99997; 99996; 99995; 99994; 99993; ...]

        # unfold 1000000;;

        Stack overflow during evaluation (looping recursion?).

        # let rec unfold_tcall acc n =

        \ \ if n \<less\>= 0 then acc else unfold_tcall (n::acc) (n-1);;

        \ \ val unfold_tcall : int list -\<gtr\> int -\<gtr\> int list =
        \<less\>fun\<gtr\>

        # unfold_tcall [] 100000;;

        - : int list =

        [1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; ...]

        # unfold_tcall [] 1000000;;

        - : int list =

        [1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; ...]
      </code>
    </small>

    <item>Is it possible to find the depth of a tree using a tail-recursive
    function?
  </itemize>

  <section|<new-page*>First Encounter of Continuation Passing Style>

  We can postpone doing the actual work till the last moment:

  <\code>
    let rec depth tree k = match tree with

    \ \ \ \ \| Tip -\<gtr\> k 0

    \ \ \ \ \| Node(_,left,right) -\<gtr\>

    \ \ \ \ \ \ depth left (fun dleft -\<gtr\>

    \ \ \ \ \ \ \ \ depth right (fun dright -\<gtr\>

    \ \ \ \ \ \ \ \ \ \ k (1 + (max dleft dright))))

    \;

    let depth tree = depth tree (fun d -\<gtr\> d)
  </code>

  <section|<new-page*>Homework>

  By ``traverse a tree'' below we mean: write a function that takes a tree
  and returns a list of values in the nodes of the tree.

  <\enumerate>
    <item>Write a function (of type <verbatim|btree -\<gtr\> int list>) that
    traverses a binary tree: in prefix order -- first the value stored in a
    node, then values in all nodes to the left, then values in all nodes to
    the right;

    <item>in infix order -- first values in all nodes to the left, then value
    stored in a node, then values in all nodes to the right (so it is
    ``left-to-right'' order);

    <item>in breadth-first order -- first values in more shallow nodes.

    <item>Turn the function from ex. 1 or 2 into continuation passing style.

    <new-page*><item>Do the homework from the end of last week slides: write
    <verbatim|btree_deriv_at>.

    <item>Write a function <verbatim|simplify: expression -\<gtr\>
    expression> that simplifies the expression a bit, so that for example the
    result of <verbatim|simplify (deriv exp dv)> looks more like what a human
    would get computing the derivative of <verbatim|exp> with respect to
    <verbatim|dv>.

    <\itemize>
      <item>Write a <verbatim|simplify_once> function that performs a single
      step of the simplification, and wrap it using a general
      <verbatim|fixpoint> function that performs an operation until a
      <em|fixed point> is reached: given <math|f> and <math|x>, it computes
      <math|f<rsup|n><around*|(|x|)>> such that
      <math|f<rsup|n><around*|(|x|)>=f<rsup|n+1><around*|(|x|)>>.
    </itemize>
  </enumerate>
</body>

<\initial>
  <\collection>
    <associate|language|american>
    <associate|magnification|2>
    <associate|page-medium|paper>
    <associate|page-orientation|landscape>
    <associate|page-type|letter>
    <associate|par-hyphen|normal>
  </collection>
</initial>

<\references>
  <\collection>
    <associate|auto-1|<tuple|1|2>>
    <associate|auto-10|<tuple|5.0.4|22>>
    <associate|auto-11|<tuple|4|27>>
    <associate|auto-12|<tuple|4|28>>
    <associate|auto-13|<tuple|5|32>>
    <associate|auto-14|<tuple|5|33>>
    <associate|auto-15|<tuple|6|34>>
    <associate|auto-16|<tuple|7|36>>
    <associate|auto-17|<tuple|8|38>>
    <associate|auto-18|<tuple|9|39>>
    <associate|auto-19|<tuple|10.0.1|40>>
    <associate|auto-2|<tuple|2|5>>
    <associate|auto-20|<tuple|11|42>>
    <associate|auto-21|<tuple|12|45>>
    <associate|auto-22|<tuple|12|48>>
    <associate|auto-23|<tuple|12|51>>
    <associate|auto-24|<tuple|12|53>>
    <associate|auto-25|<tuple|13|55>>
    <associate|auto-3|<tuple|3|9>>
    <associate|auto-4|<tuple|4|11>>
    <associate|auto-5|<tuple|5|13>>
    <associate|auto-6|<tuple|6|14>>
    <associate|auto-7|<tuple|6|20>>
    <associate|auto-8|<tuple|6|23>>
    <associate|auto-9|<tuple|4.0.4|17>>
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
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Function
      Composition> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Evaluation
      Rules (reduction semantics)> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Symbolic
      Derivation Example> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Tail
      Calls (and tail recursion)> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>First
      Encounter of Continuation Passing Style>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Homework>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6><vspace|0.5fn>
    </associate>
  </collection>
</auxiliary>