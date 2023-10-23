<TeXmacs|1.0.7.14>

<style|beamer>

<\body>
  <doc-data|<doc-title|Functional Programming>|<\doc-author-data|<author-name|Šukasz
  Stafiniak>>
    \;
  </doc-author-data|<author-email|lukstafi@gmail.com,
  lukstafi@ii.uni.wroc.pl>|<author-homepage|www.ii.uni.wroc.pl/~lukstafi>>>

  <doc-data|<doc-title|Lecture 2: Algebra>|<\doc-subtitle>
    Algebraic Data Types and some curious analogies
  </doc-subtitle>|>

  <new-page>

  <section|A Glimpse at Type Inference>

  For a refresher, let's try to use the rules we introduced last time on some
  simple examples. Starting with <verbatim|fun x -\<gtr\> x>.
  <math|<around*|[|?|]>> will mean ``dunno yet''.

  <\eqnarray*>
    <tformat|<table|<row|<cell|>|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|fun
    x -\<gtr\> x>>:<around*|[|?|]>>>|<cell|<with|mode|text|use
    >\<rightarrow\><with|mode|text| introduction:>>>|<row|<cell|>|<cell|<frac|<frac||<with|mode|text|<verbatim|x>>:a><very-small|x>|<with|mode|text|<verbatim|fun
    x -\<gtr\> x>>:<around*|[|?|]>\<rightarrow\><around*|[|?|]>>>|<cell|<frac||<with|mode|text|<verbatim|x>>:a><very-small|x><with|mode|text|
    matches with ><tree|<frac||x:a>|e:b><very-small|x><with|mode|text| since
    >e=<with|mode|text|<verbatim|x>>>>|<row|<cell|>|<cell|<frac|<frac||<with|mode|text|<verbatim|x>>:a><very-small|x>|<with|mode|text|<verbatim|fun
    x -\<gtr\> x>>:a\<rightarrow\>a>>|<cell|<with|mode|text|since
    >b=a<with|mode|text| because >x:a<with|mode|text| matched with >e:b>>>>
  </eqnarray*>

  Because <math|a> is arbitrary, OCaml puts a <em|type variable>
  <verbatim|'a> for it:

  <\code>
    # fun x -\<gtr\> x;;

    - : 'a -\<gtr\> 'a = \<less\>fun\<gtr\>
  </code>

  <new-page>

  Let's try <verbatim|fun x -\<gtr\> x+1>, which is the same as <verbatim|fun
  x -\<gtr\> ((+) x) 1><next-line>(try it with OCaml/F#!).
  <math|<around*|[|?\<alpha\>|]>> will mean ``dunno yet, but the same as in
  other places with <math|<around*|[|?\<alpha\>|]>>''.

  <\eqnarray*>
    <tformat|<cwith|3|3|2|2|cell-halign|r>|<table|<row|<cell|>|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|fun
    x -\<gtr\> ((+) x) 1>>:<around*|[|?|]>>>|<cell|<with|mode|text|use
    >\<rightarrow\><with|mode|text| introduction:>>>|<row|<cell|>|<cell|<frac|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|((+)
    x) 1>>:<around*|[|?\<alpha\>|]>>|<with|mode|text|<verbatim|fun x -\<gtr\>
    ((+) x) 1>>:<around*|[|?|]>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<with|mode|text|use
    >\<rightarrow\><with|mode|text| elimination:>>>|<row|<cell|>|<cell|<frac|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|(+)
    x>>:<around*|[|?\<beta\>|]>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|1>>:<around*|[|?\<beta\>|]>>>>>>>|<with|mode|text|<verbatim|((+)
    x) 1>>:<around*|[|?\<alpha\>|]>>|<with|mode|text|<verbatim|fun x -\<gtr\>
    ((+) x) 1>>:<around*|[|?|]>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<with|mode|text|we
    know that <verbatim|1>>:<with|mode|text|<verbatim|int>>>>|<row|<cell|>|<cell|<frac|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|(+)
    x>>:<with|mode|text|<verbatim|int>>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<frac||<with|mode|text|<verbatim|1>>:<with|mode|text|<verbatim|int>>><very-small|<with|mode|text|(constant)>>>>>>>|<with|mode|text|<verbatim|((+)
    x) 1>>:<around*|[|?\<alpha\>|]>>|<with|mode|text|<verbatim|fun x -\<gtr\>
    ((+) x) 1>>:<around*|[|?|]>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<with|mode|text|application
    again:>>>|<row|<cell|>|<cell|<frac|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|<frac|<tabular|<tformat|<table|<row|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|(+)>>:<around*|[|?\<gamma\>|]>\<rightarrow\><with|mode|text|<verbatim|int>>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|x>>:<around*|[|?\<gamma\>|]>>>>>>>|<with|mode|text|<verbatim|(+)
    x>>:<with|mode|text|<verbatim|int>>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<frac||<with|mode|text|<verbatim|1>>:<with|mode|text|<verbatim|int>>><very-small|<with|mode|text|(constant)>>>>>>>|<with|mode|text|<verbatim|((+)
    x) 1>>:<around*|[|?\<alpha\>|]>>|<with|mode|text|<verbatim|fun x -\<gtr\>
    ((+) x) 1>>:<around*|[|?|]>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<with|mode|text|it's
    our <verbatim|x>!>>>|<row|<cell|>|<cell|<frac|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|<frac|<tabular|<tformat|<table|<row|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|(+)>>:<around*|[|?\<gamma\>|]>\<rightarrow\><with|mode|text|<verbatim|int>>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<frac||<with|mode|text|<verbatim|x>>:<around*|[|?\<gamma\>|]>><very-small|<with|mode|text|<verbatim|x>>>>>>>>|<with|mode|text|<verbatim|(+)
    x>>:<with|mode|text|<verbatim|int>>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<frac||<with|mode|text|<verbatim|1>>:<with|mode|text|<verbatim|int>>><very-small|<with|mode|text|(constant)>>>>>>>|<with|mode|text|<verbatim|((+)
    x) 1>>:<around*|[|?\<alpha\>|]>>|<with|mode|text|<verbatim|fun x -\<gtr\>
    ((+) x) 1>>:<around*|[|?\<gamma\>|]>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<with|mode|text|but
    <verbatim|(+)>>:<with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>>>|<row|<cell|>|<cell|<frac|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|<frac|<tabular|<tformat|<table|<row|<cell|<frac||<with|mode|text|<verbatim|(+)>>:<with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>><very-small|<with|mode|text|(constant)>>>|<cell|<frac||<with|mode|text|<verbatim|x>>:<with|mode|text|<verbatim|int>>><very-small|<with|mode|text|<verbatim|x>>>>>>>>|<with|mode|text|<verbatim|(+)
    x>>:<with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>>>|<cell|<frac||<with|mode|text|<verbatim|1>>:<with|mode|text|<verbatim|int>>><very-small|<with|mode|text|(constant)>>>>>>>|<with|mode|text|<verbatim|((+)
    x) 1>>:<with|mode|text|<verbatim|int>>>|<with|mode|text|<verbatim|fun x
    -\<gtr\> ((+) x) 1>>:<with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>>>|<cell|>>>>
  </eqnarray*>

  <new-page>

  <subsection|Curried form>

  When there are several arrows ``on the same depth'' in a function type, it
  means that the function returns a function: e.g.
  <math|<with|mode|text|<verbatim|(+)>>:<with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>>
  is just a shorthand for <math|<with|mode|text|<verbatim|(+)>>:<with|mode|text|<verbatim|int>>\<rightarrow\><around*|(|<with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>|)>>.
  It is very different from

  <\equation*>
    <with|mode|text|<verbatim|fun f -\<gtr\> (f 1) +
    1>>:<around*|(|<with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>|)>\<rightarrow\><with|mode|text|<verbatim|int>>
  </equation*>

  For addition, instead of <verbatim|(fun x -\<gtr\> x+1)> we can write
  <verbatim|((+) 1)>. What expanded form does <verbatim|((+) 1)> correspond
  to exactly (computationally)?

  We will get used to functions returning functions when learning about the
  <em|lambda calculus>.

  <section|<new-page*>Algebraic Data Types>

  <\itemize>
    <item>Last time we learned about the <verbatim|unit> type, variant types
    like:

    <\code>
      type int_string_choice = A of int \| B of string
    </code>

    and also tuple types, record types, and type definitions.

    <item>Variants don't have to have arguments: instead of <verbatim|A of
    unit> just use <verbatim|A>.

    <\itemize>
      <item>In OCaml, variants take multiple arguments rather than taking
      tuples as arguments: <verbatim|A of int * string> is different
      than<next-line><verbatim|A of (int * string)>. But it's not important
      <small|unless you get bitten by it.>
    </itemize>

    <item>Type definitions can be recursive!

    <\code>
      type int_list = Empty \| Cons of int * int_list
    </code>

    Let's see what we have in <verbatim|int_list>:<next-line><verbatim|Empty>,
    <verbatim|Cons (5, Cons (7, Cons (13, Empty)))>, etc.

    <item>Type <verbatim|bool> can be seen as <verbatim|type bool = true \|
    false>, type <verbatim|int> can be seen as a very large <verbatim|type
    int = 0 \| -1 \| 1 \| -2 \| 2 \| ...>

    <item>Type definitions can be <em|parametric> with respect to types of
    their components (more on this in lecture about polymorphism), for
    example a list elements of arbitrary type:

    <\code>
      type 'elem list = Empty \| Cons of 'elem * 'elem list
    </code>

    <\itemize>
      <item>Type variables must start with <verbatim|'>, but since OCaml will
      not remember the names we give, it's customary to use the names OCaml
      uses: <verbatim|'a>, <verbatim|'b>, <verbatim|'c>, <verbatim|'d>...

      <item>The syntax in OCaml is a bit strange: in F# we write
      <verbatim|list\<less\>'elem\<gtr\>>. OCaml syntax mimics English, silly
      example:

      <\code>
        type 'white_color dog = Dog of 'white_color
      </code>

      <item>With multiple parameters:

      <\itemize>
        <item>OCaml:<next-line><verbatim|type ('a, 'b) choice = Left of 'a \|
        Right of 'b>

        <item>F#:<next-line><verbatim|type choice\<less\>'a,'b\<gtr\> = Left
        of 'a \| Right of 'b>

        <item>Haskell:<next-line><verbatim|data Choice a b = Left a \| Right
        b>
      </itemize>
    </itemize>
  </itemize>

  <section|<new-page*>Syntactic Bread and Sugar>

  <\itemize>
    <item>Names of variants, called <em|constructors>, must start with
    capital letter -- so if we wanted to define our own booleans, it would be

    <\code>
      <verbatim|type my_bool = True \| False>
    </code>

    Only constructors and module names can start with capital letter.

    <\itemize>
      <item><em|Modules> are ``shelves'' with values. For example,
      <verbatim|List> has operations on lists, like <verbatim|List.map> and
      <verbatim|List.filter>.
    </itemize>

    <item>Did I mention that we can use <verbatim|record.field> to access a
    field?

    <item><verbatim|fun x y -\<gtr\> e> stands for <verbatim|fun x -\<gtr\>
    fun y -\<gtr\> e>, etc. -- and of course,<next-line><verbatim|fun x
    -\<gtr\> fun y -\<gtr\> e> parses as <verbatim|fun x -\<gtr\> (fun y
    -\<gtr\> e)>

    <item><verbatim|function A x -\<gtr\> e1 \| B y -\<gtr\> e2> stands for
    <verbatim|fun p -\<gtr\> match p with A x -\<gtr\> e1 \| B y -\<gtr\>
    e2>, etc.

    <\itemize>
      <item>the general form is: <verbatim|function <em|PATTERN-MATCHING>>
      stands for<next-line><verbatim|fun <math|v> -\<gtr\> match <math|v>
      with <em|PATTERN-MATCHING>>
    </itemize>

    <item><verbatim|let f <math|ARGS> = e> is a shorthand for <verbatim|let f
    = fun <math|ARGS> -\<gtr\> e>
  </itemize>

  \;

  <section|<new-page*>Pattern Matching>

  <\itemize>
    <item>Recall that we introduced <verbatim|fst> and <verbatim|snd> as
    means to access elements of a pair. But what about bigger tuples? The
    ``basic'' way of accessing any tuple reuses the <verbatim|match>
    construct. Functions <verbatim|fst> and <verbatim|snd> can easily be
    defined!

    <\code>
      let fst = fun p -\<gtr\> match p with (a, b) -\<gtr\> a

      let snd = fun p -\<gtr\> match p with (a, b) -\<gtr\> b
    </code>

    <item>It also works with records:

    <\code>
      type person = {name: string; surname: string; age: int}

      match {name="Walker"; surname="Johnnie"; age=207}

      with {name=n; surname=sn; age=a} -\<gtr\> "Hi "^sn^"!"
    </code>

    <item>The left-hand-sides of <verbatim|-\<gtr\>> in <verbatim|match>
    expressions are called <strong|patterns>.

    <item>Patterns can be nested:

    <\code>
      match Some (5, 7) with None -\<gtr\> "sum: nothing"

      \ \ \| Some (x, y) -\<gtr\> "sum: " ^ string_of_int (x+y)
    </code>

    <new-page*><item>A pattern can just match the whole value, without
    performing destructuring: <verbatim|match f x with v -\<gtr\>>... is the
    same as <verbatim|let v = f x in >...

    <item>When we do not need a value in a pattern, it is good practice to
    use the underscore: <verbatim|_> (which is not a variable!)

    <\code>
      let fst (a,_) = a

      let snd (_,b) = b
    </code>

    <item>A variable can only appear once in a pattern (it is called
    <em|linearity>).

    <item>But we can add conditions to the patterns after <verbatim|when>, so
    linearity is not really a problem!

    <\code>
      match p with (x, y) when x = y -\<gtr\> "diag" \| _ -\<gtr\> "off-diag"
    </code>

    <\code>
      let compare a b = match a, b with

      \ \ \| (x, y) when x \<less\> y -\<gtr\> -1

      \ \ \| (x, y) when x = y -\<gtr\> 0

      \ \ \| _ -\<gtr\> 1
    </code>

    <new-page*><item>We can skip over unused fields of a record in a pattern.

    <item>We can compress our patterns by using <verbatim|\|> inside a single
    pattern:

    <\code>
      type month =

      \ \ \| Jan \| Feb \| Mar \| Apr \| May \| Jun

      \ \ \| Jul \| Aug \| Sep \| Oct \| Nov \| Dec

      type weekday = Mon \| Tue \| Wed \| Thu \| Fri \| Sat \| Sun

      type date =

      \ \ {year: int; month: month; day: int; weekday: weekday}

      let day =

      \ \ {year = 2012; month = Feb; day = 14; weekday = Wed};;

      match day with

      \ \ \| {weekday = Sat \| Sun} -\<gtr\> "Weekend!"

      \ \ \| _ -\<gtr\> "Work day"
    </code>

    <new-page*><item>We use <verbatim|(pattern <strong|as> v)> to name a
    nested pattern:

    <\code>
      match day with

      \ \ \| {weekday = (Mon \| Tue \| Wed \| Thu \| Fri <strong|as> wday)}

      \ \ \ \ \ \ when not (day.month = Dec && day.day = 24) -\<gtr\>

      \ \ \ \ Some (work (get_plan wday))

      \ \ \| _ -\<gtr\> None
    </code>
  </itemize>

  <new-page>

  <section|Interpreting Algebraic DTs as Polynomials>

  Let's do a peculiar translation: take a data type and replace <verbatim|\|>
  with <math|+>, <verbatim|*> with <math|\<times\>>, treating record types as
  tuple types (i.e. erasing field names and translationg <verbatim|;> as
  <math|\<times\>>).

  There is a special type for which we cannot build a value:

  <\code>
    type void
  </code>

  (yes, it is its definition, no <verbatim|= something> part). Translate it
  as <math|0>.

  Translate the <verbatim|unit> type as <math|1>. Since variants without
  arguments behave as variants <verbatim|of unit>, translate them as <math|1>
  as well. Translate <verbatim|bool> as <math|2>.

  Translate <verbatim|int>, <verbatim|string>, <verbatim|float>, type
  parameters and other types of interest as variables. Translate defined
  types by their translations (substituting variables if necessary).

  Give name to the type being defined (denoting a function of the variables
  introduced). Now interpret the result as ordinary numeric polynomial! (Or
  ``rational function'' if it is recursively defined.)

  Let's have fun with it.<new-page>

  <\code>
    type date = {year: int; month: int; day: int}
  </code>

  <\equation*>
    D=x*x*x=x<rsup|3>
  </equation*>

  <\code>
    type 'a option = None \| Some of 'a \ \ (* built-in type *)
  </code>

  <\equation*>
    O=1+x
  </equation*>

  <\code>
    type 'a my_list = Empty \| Cons of 'a * 'a my_list
  </code>

  <\equation*>
    L=1+x*L
  </equation*>

  <\code>
    type btree = Tip \| Node of int * btree * btree
  </code>

  <\equation*>
    T=1+x*T*T=1+x*T<rsup|2>
  </equation*>

  When translations of two types are equal according to laws of high-school
  algebra, the types are <em|isomorphic>, that is, there exist 1-to-1
  functions from one type to the other.<new-page>

  Let's play with the type of binary trees:

  <\eqnarray*>
    <tformat|<table|<row|<cell|T>|<cell|=>|<cell|1+x*T<rsup|2>=1+x*T+x<rsup|2>*T<rsup|3>=1+x+x<rsup|2>*T<rsup|2>+x<rsup|2>*T<rsup|3>=>>|<row|<cell|>|<cell|=>|<cell|1+x+x<rsup|2>*T<rsup|2>*<around*|(|1+T|)>=1+x<around*|(|1+x*T<rsup|2>*<around*|(|1+T|)>|)>>>>>
  </eqnarray*>

  Now let's translate the resulting type:

  <\code>
    type repr =

    \ \ (int * (int * btree * btree * btree option) option) option
  </code>

  Try to find the isomorphism functions <verbatim|iso1> and <verbatim|iso2>

  <\code>
    val iso1 : btree -\<gtr\> repr

    val iso2 : repr -\<gtr\> btree
  </code>

  i.e. functions such that for all trees <verbatim|t>, <verbatim|iso2 (iso1
  t) = t>, and for all representations <verbatim|r>, <verbatim|iso1 (iso2 r)
  = r>.

  <new-page*>My first failed attempt:

  <\code>
    # let iso1 (t : btree) : repr =

    \ \ match t with

    \ \ \ \ \| Tip -\<gtr\> None

    \ \ \ \ \| Node (x, Tip, Tip) -\<gtr\> Some (x, None)

    \ \ \ \ \| Node (x, Node (y, t1, t2), Tip) -\<gtr\>

    \ \ \ \ \ \ Some (x, Some (y, t1, t2, None))

    \ \ \ \ \| Node (x, Node (y, t1, t2), t3) -\<gtr\>

    \ \ \ \ \ \ Some (x, Some (y, t1, t2, Some t3));;

    \ \ \ \ \ \ \ \ \ \ \ \ Characters 32-261: [...]

    Warning 8: this pattern-matching is not exhaustive.

    Here is an example of a value that is not matched:

    Node (_, Tip, Node (_, _, _))
  </code>

  I forgot about one case. It seems difficult to guess the solution, have you
  found it on your try?<new-page>

  Let's divide the task into smaller steps corresponding to selected
  intermediate points in the transformation of the polynomial:

  <\code>
    type ('a, 'b) choice = Left of 'a \| Right of 'b

    type interm1 =

    \ \ ((int * btree, int * int * btree * btree * btree) choice)

    \ \ option

    type interm2 =

    \ \ ((int, int * int * btree * btree * btree option) choice)

    \ \ option

    \;

    let step1r (t : btree) : interm1 =

    \ \ match t with

    \ \ \ \ \| Tip -\<gtr\> None

    \ \ \ \ \| Node (x, t1, Tip) -\<gtr\> Some (Left (x, t1))

    \ \ \ \ \| Node (x, t1, Node (y, t2, t3)) -\<gtr\>

    \ \ \ \ \ \ Some (Right (x, y, t1, t2, t3))

    \;

    <new-page*>let step2r (r : interm1) : interm2 =

    \ \ match r with

    \ \ \ \ \| None -\<gtr\> None

    \ \ \ \ \| Some (Left (x, Tip)) -\<gtr\> Some (Left x)

    \ \ \ \ \| Some (Left (x, Node (y, t1, t2))) -\<gtr\>

    \ \ \ \ \ \ Some (Right (x, y, t1, t2, None))

    \ \ \ \ \| Some (Right (x, y, t1, t2, t3)) -\<gtr\>

    \ \ \ \ \ \ Some (Right (x, y, t1, t2, Some t3))

    \;

    let step3r (r : interm2) : repr =

    \ \ match r with

    \ \ \ \ \| None -\<gtr\> None

    \ \ \ \ \| Some (Left x) -\<gtr\> Some (x, None)

    \ \ \ \ \| Some (Right (x, y, t1, t2, t3opt)) -\<gtr\>

    \ \ \ \ \ \ Some (x, Some (y, t1, t2, t3opt))

    \;

    let iso1 (t : btree) : repr =

    \ \ step3r (step2r (step1r t))
  </code>

  Define <verbatim|step1l>, <verbatim|step2l>, <verbatim|step3l>, and
  <verbatim|iso2>. Hint: now it's trivial!<new-page>

  Take-home lessons:

  <\itemize>
    <item>Try to define data structures so that only information that makes
    sense can be represented -- as long as it does not overcomplicate the
    data structures. Avoid catch-all clauses when defining functions. The
    compiler will then tell you if you have forgotten about a case.

    <item>Divide solutions into small steps so that each step can be easily
    understood and checked.
  </itemize>

  <subsection|<new-page*>Differentiating Algebraic Data Types>

  Of course, you would say, the pompous title is wrong, we will differentiate
  the translated polynomials. But what sense does it make?

  It turns out, that taking the partial derivative of a polynomial resulting
  from translating a data type, gives us, when translated back, a type
  representing how to change one occurrence of a value of type corresponding
  to the variable with respect to which we computed the partial derivative.

  Take the ``date'' example:

  <\code>
    type date = {year: int; month: int; day: int}
  </code>

  <\eqnarray*>
    <tformat|<table|<row|<cell|D>|<cell|=>|<cell|x*x*x=x<rsup|3>>>|<row|<cell|<frac|\<partial\>D|\<partial\>x>>|<cell|=>|<cell|3*x<rsup|2>=x*x+x*x+x*x>>>>
  </eqnarray*>

  (we could have left it at <math|3*x*x> as well). Now we construct the type:

  <\code>
    type date_deriv =

    \ \ Year of int * int \| Month of int * int \| Day of int * int
  </code>

  <new-page*>Now we need to introduce and use (``eliminate'') the type
  <verbatim|date_deriv>.

  <\code>
    let date_deriv {year=y; month=m; day=d} =

    \ \ [Year (m, d); Month (y, d); Day (y, m)]

    \;

    let date_integr n = function

    \ \ \| Year (m, d) -\<gtr\> {year=n; month=m; day=d}

    \ \ \| Month (y, d) -\<gtr\> {year=y; month=n; day=d}

    \ \ \| Day (y, m) -\<gtr\> {year=y; month=m, day=n}

    ;;

    List.map (date_integr 7)

    \ \ (date_deriv {year=2012; month=2; day=14})
  </code>

  <new-page>

  Let's do now the more difficult case of binary trees:

  <\code>
    type btree = Tip \| Node of int * btree * btree
  </code>

  <\eqnarray*>
    <tformat|<table|<row|<cell|T>|<cell|=>|<cell|1+x*T<rsup|2>>>|<row|<cell|<frac|\<partial\>T|\<partial\>x>>|<cell|=>|<cell|0+T<rsup|2>+2*x*T*<frac|\<partial\>T|\<partial\>x>=T*T+2*x*T*<frac|\<partial\>T|\<partial\>x>>>>>
  </eqnarray*>

  (again, we could expand further into <math|<frac|\<partial\>T|\<partial\>x>=T*T+x*T*<frac|\<partial\>T|\<partial\>x>+x*T*<frac|\<partial\>T|\<partial\>x>>).

  Instead of translating <math|2> as <verbatim|bool>, we will introduce new
  type for clarity:

  <\code>
    type btree_dir = LeftBranch \| RightBranch

    type btree_deriv =

    \ \ \| Here of btree * btree

    \ \ \| Below of btree_dir * int * btree * btree_deriv
  </code>

  (You might someday hear about <em|zippers> -- they are ``inverted'' w.r.t.
  our type, in zippers the hole comes first.)

  Write a function that takes a number and a <verbatim|btree_deriv>, and
  builds a <verbatim|btree> by putting the number into the ``hole'' in
  <verbatim|btree_deriv>.<new-page>

  Solution:

  <\code>
    let rec btree_integr n =

    \ \ \| Here (ltree, rtree) -\<gtr\> Node (n, ltree, rtree)

    \ \ \| Below (LeftBranch, m, rtree) -\<gtr\>

    \ \ \ \ Node (m, btree_integr n ltree, rtree)

    \ \ \| Below (RightBranch, m, ltree) -\<gtr\>

    \ \ \ \ Node (m, ltree, btree_integr n rtree)
  </code>

  <section|Homework>

  Write a function <verbatim|btree_deriv_at> that takes a predicate over
  integers (i.e. a function <verbatim|f: int -\<gtr\> bool>), and a
  <verbatim|btree>, and builds a <verbatim|btree_deriv> whose ``hole'' is in
  the first position for which the predicate returns true. It should actually
  return a <verbatim|btree_deriv option>, with <verbatim|None> in case the
  predicate does not hold for any node.

  <em|This homework is due for the class <strong|after> the Computation
  class, i.e. for (before) the Functions class.>
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
    <associate|auto-2|<tuple|1.1|5>>
    <associate|auto-20|<tuple|11|42>>
    <associate|auto-21|<tuple|12|45>>
    <associate|auto-22|<tuple|12|48>>
    <associate|auto-23|<tuple|12|51>>
    <associate|auto-24|<tuple|12|53>>
    <associate|auto-25|<tuple|13|55>>
    <associate|auto-3|<tuple|2|6>>
    <associate|auto-4|<tuple|3|8>>
    <associate|auto-5|<tuple|4|9>>
    <associate|auto-6|<tuple|5|13>>
    <associate|auto-7|<tuple|5.1|20>>
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
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|A
      Glimpse at Type Inference> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|Curried form
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Algebraic
      Data Types> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Syntactic
      Bread and Sugar> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Pattern
      Matching> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Interpreting
      Algebraic DTs as Polynomials> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Differentiating Algebraic Data
      Types <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-7>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Homework>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-8><vspace|0.5fn>
    </associate>
  </collection>
</auxiliary>