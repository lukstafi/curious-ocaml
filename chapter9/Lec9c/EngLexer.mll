{
  open IndexParser
  let word = ref 0
  let linebreaks = ref []
  let comment_start = ref Lexing.dummy_pos

  let reset_as_file lexbuf s =
    let pos = lexbuf.Lexing.lex_curr_p in
    lexbuf.Lexing.lex_curr_p <- { pos with
      Lexing.pos_lnum =  1;
      pos_fname = s;
      pos_bol = pos.Lexing.pos_cnum;
    };
    linebreaks := []; word := 0

  let nextline lexbuf =
    let pos = lexbuf.Lexing.lex_curr_p in
    lexbuf.Lexing.lex_curr_p <- { pos with
      Lexing.pos_lnum = pos.Lexing.pos_lnum + 1;
      pos_bol = pos.Lexing.pos_cnum;
    };
    linebreaks := !word :: !linebreaks

  let parse_error_msg startpos endpos report =
    let clbeg =
      startpos.Lexing.pos_cnum - startpos.Lexing.pos_bol in
    ignore (Format.flush_str_formatter ());
    Printf.sprintf
      "File \"%s\", lines %d-%d, characters %d-%d: %s\n"
      startpos.Lexing.pos_fname startpos.Lexing.pos_lnum
      endpos.Lexing.pos_lnum clbeg
      (clbeg+(endpos.Lexing.pos_cnum - startpos.Lexing.pos_cnum))
      report

}

let alphanum = ['0'-'9' 'a'-'z' 'A'-'Z']
let newline = ('\n' | "\r\n")
let xml_start = ("<!--" | "<?")
let xml_end = ("-->" | "?>")

rule token = parse
  | [' ' '\t']
      { token lexbuf }
  | newline
      { nextline lexbuf; token lexbuf }
  | '<' alphanum+ '>' as w
      { OPEN w }
  | "</" alphanum+ '>' as w
      { CLOSE w }
  | "'tis"
      { word := !word+2; WORDS ["it", !word-1; "is", !word] }
  | "'Tis"
      { word := !word+2; WORDS ["It", !word-1; "is", !word] }
  | "o'clock"
      { incr word; WORDS ["o'clock", !word] }
  | "O'clock"
      { incr word; WORDS ["O'clock", !word] }
  | (alphanum+ as w1) ''' (alphanum+ as w2)
      { let words = EngMorph.abridged w1 w2 in
        let words = List.map
          (fun w -> incr word; w, !word) words in
        WORDS words }
  | alphanum+ as w
      { incr word; WORDS [w, !word] }
  | "&amp;"
      { incr word; WORDS ["&", !word] }
  | ['.' '!' '?'] as p
      { SENTENCE (Char.escaped p) }
  | "--"
      { PUNCT "--" }
  | [',' ':' ''' '-' ';'] as p
      { PUNCT (Char.escaped p) }
  | eof { EOF }     
  | xml_start
      { comment_start := lexbuf.Lexing.lex_curr_p;
        let s = comment [] lexbuf in
        COMMENT s }
  | _
      { let pos = lexbuf.Lexing.lex_curr_p in
        let pos' = {pos with
          Lexing.pos_cnum = pos.Lexing.pos_cnum + 1} in
        Printf.printf "%s\n%!"
          (parse_error_msg pos pos' "lexer error");
        failwith "LEXER ERROR" }

and comment strings = parse
  | xml_end
      { String.concat "" (List.rev strings) }
  | eof
      { let pos = !comment_start in
        let pos' = lexbuf.Lexing.lex_curr_p in
        Printf.printf "%s\n%!"
          (parse_error_msg pos pos' "lexer error: unclosed comment");
        failwith "LEXER ERROR" }
  | newline
      { nextline lexbuf;
        comment (Lexing.lexeme lexbuf :: strings) lexbuf
      }
  | _
      { comment (Lexing.lexeme lexbuf :: strings) lexbuf }
