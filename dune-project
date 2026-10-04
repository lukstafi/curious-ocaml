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
  "A curious book about OCaml: representations, interpreters, executable laws, and OCaml 5 effects.")
 (allow_empty)
 (depends
  (ocaml (>= 5.3))
  dune
  mdx
  (conf-texlive :with-doc)
  (conf-pandoc :with-doc))
 (tags
  (ocaml textbook)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
