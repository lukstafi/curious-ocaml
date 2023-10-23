<TeXmacs|1.0.7.14>

<style|beamer>

<\body>
  <doc-data|<doc-title|Functional Programming>|<\doc-author-data|<author-name|Šukasz
  Stafiniak>>
    \;
  </doc-author-data|<author-email|lukstafi@gmail.com,
  lukstafi@ii.uni.wroc.pl>|<author-homepage|www.ii.uni.wroc.pl/~lukstafi>>>

  <doc-data|<doc-title|Lecture 2: Algebra, Fig. 1>|<\doc-subtitle>
    Type inference example derivation
  </doc-subtitle>|>

  <new-page>

  <\very-large>
    <\equation*>
      <frac|<around*|[|?|]>|<with|mode|text|<verbatim|fun x -\<gtr\> ((+) x)
      1>>:<around*|[|?|]>>
    </equation*>
  </very-large>

  <new-page>

  <\very-large>
    <\equation*>
      <with|mode|text|use >\<rightarrow\><with|mode|text| introduction:>
    </equation*>
  </very-large>

  <new-page>

  <\very-large>
    <\equation*>
      <frac|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|((+) x)
      1>>:<around*|[|?\<alpha\>|]>>|<with|mode|text|<verbatim|fun x -\<gtr\>
      ((+) x) 1>>:<around*|[|?|]>\<rightarrow\><around*|[|?\<alpha\>|]>>
    </equation*>
  </very-large>

  <new-page>

  <\very-large>
    <\equation*>
      <with|mode|text|use >\<rightarrow\><with|mode|text| elimination:>
    </equation*>
  </very-large>

  <new-page>

  <\very-large>
    <\equation*>
      <frac|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|(+)
      x>>:<around*|[|?\<beta\>|]>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|1>>:<around*|[|?\<beta\>|]>>>>>>>|<with|mode|text|<verbatim|((+)
      x) 1>>:<around*|[|?\<alpha\>|]>>|<with|mode|text|<verbatim|fun x
      -\<gtr\> ((+) x) 1>>:<around*|[|?|]>\<rightarrow\><around*|[|?\<alpha\>|]>>
    </equation*>
  </very-large>

  <new-page>

  <\very-large>
    <\equation*>
      <with|mode|text|we know that <verbatim|1>>:<with|mode|text|<verbatim|int>>
    </equation*>
  </very-large>

  <new-page>

  <\very-large>
    <\equation*>
      <frac|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|(+)
      x>>:<with|mode|text|<verbatim|int>>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<frac||<with|mode|text|<verbatim|1>>:<with|mode|text|<verbatim|int>>><very-small|<with|mode|text|(constant)>>>>>>>|<with|mode|text|<verbatim|((+)
      x) 1>>:<around*|[|?\<alpha\>|]>>|<with|mode|text|<verbatim|fun x
      -\<gtr\> ((+) x) 1>>:<around*|[|?|]>\<rightarrow\><around*|[|?\<alpha\>|]>>
    </equation*>
  </very-large>

  <new-page>

  <\very-large>
    <\equation*>
      <with|mode|text|application again:>
    </equation*>
  </very-large>

  <new-page>

  <\very-large>
    <\equation*>
      <frac|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|<frac|<tabular|<tformat|<table|<row|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|(+)>>:<around*|[|?\<gamma\>|]>\<rightarrow\><with|mode|text|<verbatim|int>>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|x>>:<around*|[|?\<gamma\>|]>>>>>>>|<with|mode|text|<verbatim|(+)
      x>>:<with|mode|text|<verbatim|int>>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<frac||<with|mode|text|<verbatim|1>>:<with|mode|text|<verbatim|int>>><very-small|<with|mode|text|(constant)>>>>>>>|<with|mode|text|<verbatim|((+)
      x) 1>>:<around*|[|?\<alpha\>|]>>|<with|mode|text|<verbatim|fun x
      -\<gtr\> ((+) x) 1>>:<around*|[|?|]>\<rightarrow\><around*|[|?\<alpha\>|]>>
    </equation*>
  </very-large>

  <new-page>

  <\very-large>
    <\equation*>
      <with|mode|text|it's our <verbatim|x>!>
    </equation*>
  </very-large>

  <new-page>

  <\very-large>
    <\equation*>
      <frac|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|<frac|<tabular|<tformat|<table|<row|<cell|<frac|<around*|[|?|]>|<with|mode|text|<verbatim|(+)>>:<around*|[|?\<gamma\>|]>\<rightarrow\><with|mode|text|<verbatim|int>>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<frac||<with|mode|text|<verbatim|x>>:<around*|[|?\<gamma\>|]>><with|mode|text|<verbatim|x>>>>>>>|<with|mode|text|<verbatim|(+)
      x>>:<with|mode|text|<verbatim|int>>\<rightarrow\><around*|[|?\<alpha\>|]>>>|<cell|<frac||<with|mode|text|<verbatim|1>>:<with|mode|text|<verbatim|int>>><very-small|<with|mode|text|(constant)>>>>>>>|<with|mode|text|<verbatim|((+)
      x) 1>>:<around*|[|?\<alpha\>|]>>|<with|mode|text|<verbatim|fun x
      -\<gtr\> ((+) x) 1>>:<around*|[|?\<gamma\>|]>\<rightarrow\><around*|[|?\<alpha\>|]>>
    </equation*>
  </very-large>

  <new-page>

  <\very-large>
    <\equation*>
      <with|mode|text|but <verbatim|(+)>>:<with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>
    </equation*>
  </very-large>

  <new-page>

  <\very-large>
    <\equation*>
      <frac|<frac|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|<frac|<tabular|<tformat|<table|<row|<cell|<frac||<with|mode|text|<verbatim|(+)>>:<with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>><very-small|<with|mode|text|(constant)>>>|<cell|<frac||<with|mode|text|<verbatim|x>>:<with|mode|text|<verbatim|int>>><with|mode|text|<verbatim|x>>>>>>>|<with|mode|text|<verbatim|(+)
      x>>:<with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>>>|<cell|<frac||<with|mode|text|<verbatim|1>>:<with|mode|text|<verbatim|int>>><very-small|<with|mode|text|(constant)>>>>>>>|<with|mode|text|<verbatim|((+)
      x) 1>>:<with|mode|text|<verbatim|int>>>|<with|mode|text|<verbatim|fun x
      -\<gtr\> ((+) x) 1>>:<with|mode|text|<verbatim|int>>\<rightarrow\><with|mode|text|<verbatim|int>>>
    </equation*>
  </very-large>

  \;
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
    <associate|auto-2|<tuple|1|3>>
    <associate|auto-20|<tuple|11|42>>
    <associate|auto-21|<tuple|12|45>>
    <associate|auto-22|<tuple|12|48>>
    <associate|auto-23|<tuple|12|51>>
    <associate|auto-24|<tuple|12|53>>
    <associate|auto-25|<tuple|13|55>>
    <associate|auto-3|<tuple|2|7>>
    <associate|auto-4|<tuple|3|9>>
    <associate|auto-5|<tuple|2.0.2|13>>
    <associate|auto-6|<tuple|3|14>>
    <associate|auto-7|<tuple|4|15>>
    <associate|auto-8|<tuple|4.0.3|16>>
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