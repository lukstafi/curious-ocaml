# CLAUDE.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

"Curious OCaml" is an educational textbook about OCaml covering logic (types), algebra (values), computation (rewrite semantics), functions (lambda calculus), constraints, monads, and more. The content is organized as markdown files with embedded OCaml code blocks that are tested using mdx.

## Build Commands

```bash
# Build the project (compiles code, runs mdx tests, generates combined markdown files)
dune build

# Run mdx tests to verify code examples in markdown
dune runtest

# Build HTML output (in site/ directory)
dune build @site/old_lectures_as_book
dune build @site/new_book

# Build PDF output (requires pandoc and texlive)
dune build @pdfs/old_lectures_as_book
dune build @pdfs/new_book
```

## Architecture

### Content Structure
- `chapter1/` through `chapter11/`: Main lecture content
  - `functional-lectureNN.md`: Primary lecture content with embedded OCaml code
  - `lectureNN-exercises.md`: Exercise files
  - `README.md`: The translation and expansion of the lecture into a textbook chapter 
  - `prelude.ml`: Prelude code loaded before mdx tests for that chapter
  - `LecN*.ml`: Standalone OCaml example files (outdated)
- `exam/`: Exam problems and solutions

### Build System
- Uses dune with mdx plugin (version 0.4) for testing OCaml code blocks in markdown
- Each chapter has a `dune` file with `(mdx (files README.md) (preludes prelude.ml))`
- Root `dune` file concatenates chapter files into:
  - `README.md`: Combined textbook content i.e. READMEs (auto-generated, do not edit)
  - `old_lectures_as_book.md`: Full non-adapted content combining all outdated lectures and exercises (auto-generated)
- `site/dune`: Generates HTML via pandoc with KaTeX for math rendering
- `pdfs/dune`: Generates PDF via pandoc

### Key Dependencies
- mdx: Tests OCaml code blocks embedded in markdown
- pandoc: Converts markdown to HTML/PDF
- KaTeX: Renders LaTeX math in HTML output
- printbox, printbox-text, printbox-html: Pretty-printing libraries used in examples
- ppx_jane, ppx_expect: PPX extensions used in code examples

## Content Conventions

- Math formulas use LaTeX syntax rendered by KaTeX
- OCaml code blocks use triple backticks with `ocaml` language tag
- Auto-generated files (README.md, old_lectures_as_book.md) have a comment: `<!-- Do NOT modify this file, it is automatically generated -->`
- MD_metadata.md contains YAML frontmatter with KaTeX configuration included in generated outputs

## TeXmacs Source File Extraction

The source materials are in TeXmacs format (.tm files). Key knowledge for extracting content:

### TeXmacs Format Basics

TeXmacs uses angle-bracket meta-language syntax:
- Commands: `<command|arg>`, `<command|arg1|arg2>`, etc.
- Document structure in nested format with closing tags
- UTF-8 encoding with special characters preserved

### Custom Syntax Highlighting

The author uses a custom highlighting style with semantic commands:
- `hlkwa`: Keywords (e.g., `if`, `then`, `let`, `fun`)
- `hlstd`: Standard text/identifiers
- `hlopt`: Operators (e.g., `+`, `-`, `=`, `::`)
- `hlnum`: Numeric literals
- `hlcom`: Comments
- `hlendline`: **Margin comments** - explanatory notes appearing in the margin of code blocks

**Important**: The `hlendline` content is particularly valuable as it contains pedagogical commentary explaining what the code does. These should be preserved as inline comments in the extracted code.

### Textbook-ization Strategy

1. Use the automatically extracted `.md` files e.g. chapter1/functional-lecture01.md as scaffolding, audit them against the original `.tm` files e.g. chapter1/functional-lecture01.tm , extract **all** information to README files e.g. chapter1/README.md while adjusting the content and presentation to be more like in a textbook
2. **Use Task agents** for large files (>25k tokens) - they can handle the full document in one pass
3. **Preserve margin comments** by converting `hlendline` content to inline code comments
4. **Extract code blocks** with proper language tagging (```ocaml for this project)
5. **YAML front matter** for metadata (title, author, lecture number, etc.)
6. **Pandoc-flavored Markdown** for enhanced styling (tables, code blocks, math)
7. **Fix escape sequences** - wrap literal `\n`, `\r`, etc. in backticks to avoid LaTeX errors
8. The README.md files e.g. chapter1/README.md should contain the **complete contents**, adjusted for a more textbook-like presentation relative to the slide sources

### Custom Highlighting Command Reference

When encountering TeXmacs code blocks with highlighting:

```
<\code>
  <\with|par-mode|center|par-hyphen|normal>
    <hlkwa|let> <hlstd|x> <hlopt|=> <hlnum|42> <hlendline|This is a margin comment>
  </with>
</code>
```

Should be extracted as:

```ocaml
let x = 42  (* This is a margin comment *)
```

The semantic highlighting commands can be stripped during extraction - they're primarily for visual presentation in TeXmacs.
