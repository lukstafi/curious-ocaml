---
title: Curious OCaml
author: Lukasz Stafiniak
header-includes:
  - <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css"
       integrity="sha384-n8MVd4RsNIU0tAv4ct0nTaAbDJwPJzDEaqSD1odI+WdtXRGWt2kTvGFasHpSy3SV" crossorigin="anonymous">
  - <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"
       integrity="sha384-XjKyOOlGwcjNTAIQHIpgOno0Hl1YQqzUOEleOLALmuqehneUG+vnGctmUb0ZY0l8"
       crossorigin="anonymous"></script>
  - <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"
       integrity="sha384-+VBxd3r6XgURycqtZ117nYw44OOcIax56Z4dCRWbxyPt0Koah1uHoK0o4+/RRE05" crossorigin="anonymous"
       onload="renderMathInElement(document.body);"></script>
---
<!-- Do NOT modify this file, it is automatically generated -->
# Curious OCaml
## From logic rules to programming constructs

What logical connectives do you know?

|$\top$ | $\bot$ | $\wedge$ | $\vee$ | $\rightarrow$
|---|---|---|---|---
|   |   | $a \wedge b$ | $a \vee b$ | $a \rightarrow b$
| truth | falsehood | conjunction | disjunction | implication
| "trivial" | "impossible" | $a$ and $b$ | $a$ or $b$ | $a$ gives $b$
|   | shouldn't get | got both | got at least one | given $a$, we get $b$

How can we define them? Think in terms of _derivation trees_:

$$
\frac{
\frac{\frac{\,}{\text{a premise}} \; \frac{\,}{\text{another premise}}}{\frac{\,}{\text{some fact}}} \;
\frac{\frac{\,}{\text{a premise}} \; \frac{\,}{\text{another premise}}}{\frac{\,}{\text{another fact}}}}
{\text{final conclusion}}
$$

To define the connectives, we provide rules for using them: for example, a rule $\frac{a \; b}{c}$
matches parts of the tree that have two premises, represented by variables $a$
and $b$, and have any conclusion, represented by variable $c$.

### Rules for Logical Connectives

Introduction rules say how to produce a connective. Elimination rules say how to use it.
Text in parentheses is comments. Letters are variables: stand for anything.

<details><summary>Try to use only the connective you define in its definition.</summary>
TODO
</details>
