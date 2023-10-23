{
  open Lexing
  let nextline lexbuf =
    let pos = lexbuf.lex_curr_p in
    lexbuf.lex_curr_p <- { pos with
      pos_lnum = pos.pos_lnum + 1;
      pos_bol = pos.pos_cnum;
    }
  type state =
  | Seek
  | Addr of bool * string * string list
  let report state lexbuf =
    match state with
    | Seek -> ()
    | Addr (false, _, _) -> ()
    | Addr (true, name, addr) ->
      Printf.printf "%d: %s@%s\n" lexbuf.lex_curr_p.pos_lnum
        name (String.concat "." (List.rev addr))
}

let newline = ('\n' | "\r\n")
let addr_char = ['a'-'z' 'A'-'Z' '0'-'9' '-' '_']
let at_w_symb = "where" | "WHERE" | "at" | "At" | "AT"
let at_nw_symb = '@' | "&#x40;" | "&#64;"
let open_symb = ' '* '(' ' '* | ' '+
let close_symb = ' '* ')' ' '* | ' '+
let at_sep_symb =
  open_symb? at_nw_symb close_symb? |
  open_symb at_w_symb close_symb
let dot_w_symb = "dot" | "DOT" | "dt" | "DT"
let dom_w_symb = dot_w_symb | "dom" | "DOM"
let dot_sep_symb =
  open_symb dot_w_symb close_symb |
  open_symb? '.' close_symb?
let dom_sep_symb =
  open_symb dom_w_symb close_symb |
  open_symb? '.' close_symb?
let addr_dom = addr_char addr_char
  | "edu" | "EDU" | "org" | "ORG" | "com" | "COM"

rule email state = parse
| newline
    { report state lexbuf; nextline lexbuf;
      email Seek lexbuf }
| (addr_char+ as name) at_sep_symb (addr_char+ as addr)
    { email (Addr (false, name, [addr])) lexbuf }
| dom_sep_symb (addr_dom as dom)
    { let state =
        match state with
        | Seek -> Seek
        | Addr (_, name, addrs) ->
          Addr (true, name, dom::addrs) in
      email state lexbuf }
| dot_sep_symb (addr_char+ as addr)
    { let state =
        match state with
        | Seek -> Seek
        | Addr (_, name, addrs) ->
          Addr (false, name, addr::addrs) in
      email state lexbuf }
| eof
     { report state lexbuf }
| _
     { report state lexbuf; email Seek lexbuf }

{
  let _ =
    let ch = open_in Sys.argv.(1) in
    email Seek (Lexing.from_channel ch);
    close_in ch
}
