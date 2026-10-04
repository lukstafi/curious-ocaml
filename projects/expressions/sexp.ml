type t = Atom of string | Form of string * t list
exception Parse_error of string
let tokens text =
  let n = String.length text in
  let rec scan i out =
    if i = n then Array.of_list (List.rev out)
    else match text.[i] with
      | ' ' | '\t' | '\r' | '\n' -> scan (i+1) out
      | '(' | ')' as c -> scan (i+1) (String.make 1 c :: out)
      | _ ->
        let j = ref i in
        while !j < n && not (List.mem text.[!j] [' ';'\t';'\r';'\n';'(';')']) do
          incr j
        done;
        scan !j (String.sub text i (!j-i) :: out) in
  scan 0 []
let parse text =
  let input = tokens text in
  let length = Array.length input in
  let rec one i =
    if i >= length then raise (Parse_error "expected expression") else
    match input.(i) with
    | ")" -> raise (Parse_error "unexpected closing parenthesis")
    | "(" ->
      if i+1 >= length || input.(i+1) = "(" || input.(i+1) = ")" then
        raise (Parse_error "expected form name");
      (* Keep the form name outside the recursive argument parser. *)
      let name = input.(i+1) in
      let rec gather j acc =
        if j >= length then raise (Parse_error "unclosed form")
        else if input.(j) = ")" then Form (name, List.rev acc), j+1
        else let arg,k = one j in gather k (arg::acc) in
      gather (i+2) []
    | atom -> Atom atom, i+1 in
  try
    let result,finish = one 0 in
    if finish <> length then Error "trailing input" else Ok result
  with Parse_error message -> Error message
