{
 type sentence = {
   subject : string;
   action : string;
   plural : bool;
   adjs : string list;
   advs : string list
 }
 type token =
 | VERB of string
 | NOUN of string
 | ADJ of string
 | ADV of string
 | PLURAL | SINGULAR
 | A_DET | THE_DET | SOME_DET | THIS_DET | THAT_DET
 | THESE_DET | THOSE_DET
 | COMMA_CNJ | AND_CNJ | DOT_PUNCT

 let tok_str = function
   | VERB w -> "VERB "^w
   | NOUN w -> "NOUN "^w
   | ADJ w -> "ADJ "^w
   | ADV w -> "ADV "^w
   | PLURAL -> "PLURAL"
   | SINGULAR -> "SINGULAR"
   | A_DET -> "A_DET"
   | THE_DET -> "THE_DET"
   | SOME_DET -> "SOME_DET"
   | THIS_DET -> "THIS_DET"
   | THAT_DET -> "THAT_DET"
   | THESE_DET -> "THESE_DET"
   | THOSE_DET -> "THOSE_DET"
   | COMMA_CNJ -> "COMMA_CNJ"
   | AND_CNJ -> "AND_CNJ"
   | DOT_PUNCT -> "DOT_PUNCT"

 let adjectives =
   ["smart"; "extreme"; "green"; "slow"; "old"; "incredible";
    "quiet"; "diligent"; "mellow"; "new"]

 let log_file = open_out "log.txt"
 let log s = Printf.fprintf log_file "%s\n%!" s

 let last_tok = ref DOT_PUNCT
 let tokbuf = Queue.create ()
 let push w =
   log ("lex: "^tok_str w);
   last_tok := w; Queue.push w tokbuf
 exception LexError of string
}

let alphanum = ['0'-'9' 'a'-'z' 'A'-'Z' ''' '-']

rule line = parse
| ([^'\n']* '\n') as l { l }
| eof { exit 0 }

and lex_word = parse
| [' ' '\t']
    { lex_word lexbuf }
| '.' { push DOT_PUNCT }
| "a" { push A_DET } | "the" { push THE_DET }
| "some" { push SOME_DET }
| "this" { push THIS_DET } | "that" { push THAT_DET }
| "these" { push THESE_DET } | "those" { push THOSE_DET }
| "A" { push A_DET } | "The" { push THE_DET }
| "Some" { push SOME_DET }
| "This" { push THIS_DET } | "That" { push THAT_DET }
| "These" { push THESE_DET } | "Those" { push THOSE_DET }
| "and" { push AND_CNJ }
| ',' { push COMMA_CNJ }
| (alphanum+ as w) "ly"
    {
      if List.mem w adjectives
      then push (ADV w)
      else if List.mem (w^"le") adjectives
      then push (ADV (w^"le"))
      else (push (NOUN w); push SINGULAR)
    }
| (alphanum+ as w) "s"
    {
      if List.mem w adjectives then push (ADJ w)
      else match !last_tok with
      | THE_DET | SOME_DET | THESE_DET | THOSE_DET
      | DOT_PUNCT | ADJ _ ->
        push (NOUN w); push PLURAL
      | _ -> push (VERB w); push SINGULAR
    }
| alphanum+ as w
    {
      if List.mem w adjectives then push (ADJ w)
      else match !last_tok with
      | A_DET | THE_DET | SOME_DET | THIS_DET | THAT_DET
      | DOT_PUNCT | ADJ _ ->
        push (NOUN w); push SINGULAR
      | _ -> push (VERB w); push PLURAL
    }
| _ as w
    { raise (LexError ("Unrecognized character "^Char.escaped w)) }
{
  let lexeme lexbuf =
    if Queue.is_empty tokbuf then lex_word lexbuf;
    Queue.pop tokbuf
}
