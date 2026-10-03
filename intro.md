![Curious OCaml](Curious_OCaml-cover.jpg){.cover-image}

::: {.illustrator-credit}
*Illustrated by: Gemini 3 Nano Banana*
:::

# Curious OCaml

*Curious OCaml* invites you to explore programming through the lens of types, logic, and algebra. OCaml is a language that rewards curiosity—its type system catches errors before your code runs, its functional style encourages clear thinking about data transformations, and its mathematical foundations reveal deep connections between programming and logic. Whether you're new to programming, experienced with OCaml, or a seasoned developer discovering functional programming for the first time, this book aims to spark that "aha!" moment when abstract concepts click into place.

This book is intended for three audiences:

- New to programming: ambitious students in areas with formal rigor -- math, computer science, philosophy, linguistics, etc.
- Intermediate: OCaml programmers.
- Advanced: programmers who are new to functional programming.


## Reading and running

The book assumes willingness to work through mathematical notation and small programs. Readers entirely new to programming should also practice using the OCaml toplevel, loading a file, and reading a compiler error before tackling the longer derivations. The later chapters build on functions, algebraic data types, pattern matching, and modules.

Use OCaml 5.3 or later for the whole book: Chapter 9 uses the effect-pattern syntax introduced in 5.3. The source repository contains one current `chapterN/README.md` per chapter. Root `README.md` is generated from them; the `functional-lecture*.md` and `Lec*.ml` files are historical course material.

The examples are checked with Dune and mdx. In a checkout with the dependencies from `curious.opam` installed, run `dune runtest`. To check selected chapters, for example, run `dune runtest chapter1 chapter2`. Run `dune build README.md @site/new_book` to regenerate the combined manuscript and HTML edition.

Code blocks sharing an `env` label within a chapter share definitions and load that chapter's `prelude.ml`. Inspect that prelude when running excerpts independently. Blocks marked `skip` include exercises, pseudo-code, and deliberately non-running or expensive examples. Chapters 6 and 10 additionally require GUI/incremental libraries; their interactive demonstrations need a graphical environment.

For a first reading, follow Chapters 1–3 and 5–6 before the larger applications in Chapters 7–11. Chapter 4 is an optional deeper study of lambda calculus; return to it when encodings and evaluation strategies become useful. Chapter 12 is a synthesis for readers already comfortable with the earlier constructions, rather than a prerequisite for using them.
