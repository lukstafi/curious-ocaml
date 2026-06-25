# Fix `@pdfs/new_book` PDF build: add `\newcounter{none}` to template.latex

## Goal

`dune build @pdfs/new_book` fails with repeated `LaTeX Error: No counter 'none'
defined`, so the book PDF can no longer be regenerated. The defect is
pre-existing (it predates `task-8f7e5362` / PR #13) and was surfaced as a
durable coder learning during that task's retrospective. It affects only PDF
generation of the book — not the HTML render and not `dune runtest`.

Root cause is a LaTeX-toolchain regression, not a content problem: the modern
LaTeX-team `longtable.sty` shipped in current TeXLive does
`\@kernel@refstepcounter{\LTcaptype}` at every `\begin{longtable}`. For
caption-less tables pandoc emits the sentinel `\def\LTcaptype{none}` ("do not
number this table"), so modern longtable now tries to step a counter named
`none`, which the project's hand-rolled `pdfs/template.latex` never defines.
Pandoc's own default template defines it (`\newcounter{none} % for unnumbered
tables`); the project template, derived from that default, dropped that single
line. Curious-OCaml has many caption-less tables (truth tables for logic
connectives, etc.), so every one of them now raises the error.

## Acceptance Criteria

- [ ] `pdfs/template.latex` declares a `none` counter immediately after the
  longtable package load in the "Tables" preamble block (the
  `\usepackage{longtable,booktabs,array}` line), mirroring pandoc's
  default-template line `\newcounter{none} % for unnumbered tables`.
- [ ] `cd ~/curious-ocaml && dune build @pdfs/new_book` exits 0 with no
  `No counter 'none' defined` error in the build output.
- [ ] The build (re)produces `pdfs/new_book.pdf` (a promoted target); the
  generated PDF contains the full book (the truth-table / caption-less-table
  pages render without a numbered caption).
- [ ] No other preamble customizations in `pdfs/template.latex` are changed
  (the `\setcounter{secnumdepth}{3}` / `\renewcommand{\numberline}{}`
  table-of-contents tweaks and the `\patchcmd\longtable` block stay intact).
- [ ] No change to `pdfs/dune` (the pandoc invocation and `new_book` rule are
  correct as-is).

## Context

The PDF build pipeline lives in `pdfs/dune`'s `(rule (alias new_book) ...)`: it
`sed`-cleans `README.md`, then runs `pandoc -s --toc
--template=template.latex --top-level-division=chapter
--shift-heading-level-by=-1 --pdf-engine=lualatex`, and promotes
`pdfs/new_book.pdf`. Caption-less tables in the source produce, per table:

```latex
{\def\LTcaptype{none} % do not increment counter
\begin{longtable}[]{@{} ... @{}}
```

The relevant preamble in `pdfs/template.latex` is the "Tables" block:

```latex
% Tables
\usepackage{longtable,booktabs,array}
\usepackage{calc}
\usepackage{etoolbox}
\makeatletter
\patchcmd\longtable{\par}{\if@noskipsec\mbox{}\fi\par}{}{}
\makeatother
```

The committed `pdfs/new_book.pdf` was built under an older `longtable` that only
touched `\LTcaptype` from inside `\caption`, so caption-less tables never
referenced the counter — which is why the error is "pre-existing but newly
fatal."

## Approach

*Suggested approach — agents may deviate if they find a better path.*

Add one line to `pdfs/template.latex` directly after
`\usepackage{longtable,booktabs,array}`:

```latex
\usepackage{longtable,booktabs,array}
\newcounter{none} % for unnumbered tables (pandoc \def\LTcaptype{none} sentinel)
```

A dummy `none` counter is harmless: it is `\refstepcounter`'d but never printed,
which is exactly pandoc's intent (absorb the step into a throwaway counter). No
table gains a visible number. This is forward-compatible: if the project ever
regenerates `template.latex` from pandoc's default, the same line is present.

Validation is the real build, not an isolated scratchpad: `dune build
@pdfs/new_book` must exit 0 and (re)produce the promoted `pdfs/new_book.pdf`.
The `new_book` rule copies every `chapterN/*.{png,jpg,eps}` via `copy_files`, so
in-tree there is no missing-image gap.

## Scope

In scope: the single `\newcounter{none}` line in `pdfs/template.latex`.

Out of scope:
- `pdfs/dune` (no change needed).
- The commented-out `old_lectures_as_book` rule (separately disabled for
  unrelated markdown-extraction issues).
- Any other preamble or TOC customization in `template.latex`.

Dependencies: none. Relates to `task-8f7e5362` (the PR #13 test-fix whose
retrospective surfaced this defect).
