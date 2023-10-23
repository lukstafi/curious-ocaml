(* Parsing tokens to form an inverted index, without the use of
   ocamlyacc or Menhir. *)


type token =
| WORDS of (string * int) list
| OPEN of string | CLOSE of string | COMMENT of string
| SENTENCE of string | PUNCT of string
| EOF

let inv_index update ii lexer lexbuf =
  let rec aux ii =
    match lexer lexbuf with
    | WORDS ws ->
      let ws = List.map (fun (w,p)->EngMorph.normalize w, p) ws in
      aux (List.fold_left update ii ws)
    | OPEN _ | CLOSE _ | SENTENCE _ | PUNCT _ | COMMENT _ ->
      aux ii
    | EOF -> ii in
  aux ii

let phrase lexer lexbuf =
  let rec aux words =
    match lexer lexbuf with
    | WORDS ws ->
      let ws = List.map (fun (w,p)->EngMorph.normalize w) ws in
      aux (List.rev_append ws words)
    | OPEN _ | CLOSE _ | SENTENCE _ | PUNCT _ | COMMENT _ ->
      aux words
    | EOF -> List.rev words in
  aux []
