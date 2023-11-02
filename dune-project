(lang dune 3.10)

(using mdx 0.4)

(name curious)

(version 0.1.0)

(generate_opam_files true)

(source
 (github lukstafi/curious-ocaml))

(authors "Lukasz Stafiniak")

(maintainers "Lukasz Stafiniak")

(license LICENSE)

(documentation
 https://github.com/lukstafi/curious-ocaml/blob/master/README.md)

(package
 (name curious)
 (synopsis "A curious book about OCaml")
 (description
  "A curious book about OCaml: logic (types), algebra (values), computation (rewrite semantics), functions (lambda calculus), constraints, monads, expression.")
 (allow_empty)
 (depends
  ocaml
  dune
  base
  core
  mdx
  printbox
  printbox-text
  printbox-html
  stdio
  ppxlib
  ppx_jane
  ppx_expect
  ppx_minidebug
  conf-texlive
  ; conf-texlive-latex-recommended
  conf-pandoc)
 (tags
  (ocaml textbook)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
