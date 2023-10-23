open EngLexer
let () =
  let stdinbuf = Lexing.from_channel stdin in
  while true do
    (* Read line by line. *)
    let linebuf = Lexing.from_string (line stdinbuf) in
    try
      (* Run the parser on a single line of input. *)
      let s = EngParser.sentence lexeme linebuf in
      Printf.printf
        "subject=%s\nplural=%b\nadjectives=%s\naction=%s\nadverbs=%s\n\n%!"
        s.subject s.plural (String.concat ", " s.adjs)
        s.action (String.concat ", " s.advs)
    with
    | LexError msg ->
	Printf.fprintf stderr "%s\n%!" msg
    | EngParser.Error ->
	Printf.fprintf stderr "At offset %d: syntax error.\n%!"
          (Lexing.lexeme_start linebuf)
  done
