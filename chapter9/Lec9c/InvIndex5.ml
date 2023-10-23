let update ii (w, p) =
  (try
    let ps = Hashtbl.find ii w in
    Hashtbl.replace ii w (p::ps)
  with Not_found -> Hashtbl.add ii w [p]);
  ii
let empty () = Hashtbl.create 511
let find w ii = Hashtbl.find ii w
let mapv f ii =
  let ii' = empty () in
  Hashtbl.iter (fun k v -> Hashtbl.add ii' k (f v)) ii;
  ii'

let ( -| ) f g x = f (g x)
let index file =
  let ch = open_in file in
  let lexbuf = Lexing.from_channel ch in
  EngLexer.reset_as_file lexbuf file;
  let ii =
    IndexParser.inv_index update (empty ()) EngLexer.token lexbuf in
  close_in ch;
  mapv (Array.of_list -| List.rev) ii, List.rev !EngLexer.linebreaks

let find_line linebreaks p =
  let rec aux line = function
    | [] -> line
    | bp::_ when p < bp -> line
    | _::breaks -> aux (line+1) breaks in
  aux 1 linebreaks

let first ii w =
  let ps = find w ii in
  if ps = [| |] then raise Not_found else ps.(0)
let last ii w =
  let ps = find w ii in
  if ps = [| |] then raise Not_found
  else ps.(Array.length ps - 1)
let prev ii w cp =
  let ps = find w ii in
  let rec aux b e =
    if e-b <= 1 then ps.(b)
    else let m = (b+e)/2 in
         if ps.(m) < cp then aux m e
         else aux b m in
  let l = Array.length ps in
  if l = 0 || ps.(0) >= cp then raise Not_found
  else aux 0 (l-1)
let next ii w cp =
  let ps = find w ii in
  let rec aux b e =
    if e-b <= 1 then ps.(e)
    else let m = (b+e)/2 in
         if ps.(m) <= cp then aux m e
         else aux b m in
  let l = Array.length ps in
  if l = 0 || ps.(l-1) <= cp then raise Not_found
  else aux 0 (l-1)

let rec next_phrase ii phrase cp =
  let rec aux cp = function
    | [] -> raise Not_found
    | [w] ->
      let np = next ii w cp in np, np
    | w::ws ->
      let np, fp = aux (next ii w cp) ws in
      prev ii w np, fp in
  let np, fp = aux cp phrase in
  if fp - np = List.length phrase - 1 then np, fp
  else next_phrase ii phrase fp

let search (ii, linebreaks) phrase =
  let lexbuf = Lexing.from_string phrase in
  EngLexer.reset_as_file lexbuf ("search phrase: "^phrase);
  let phrase = IndexParser.phrase EngLexer.token lexbuf in
  let rec aux cp =
    try
      let np, fp = next_phrase ii phrase cp in
      np :: aux fp
    with Not_found -> [] in
  List.map (find_line linebreaks) (aux (-1))

let shakespeare = index "./shakespeare.xml"

let query q =
  let lines = search shakespeare q in
  Printf.printf "%s: lines %s\n%!" q
    (String.concat ", " (List.map string_of_int lines))

let time f =
  let tbeg = Unix.gettimeofday () in
  let res = f () in
  let tend = Unix.gettimeofday () in
  tend -. tbeg, res

let queries =
  ["first witch"; "wherefore art thou";
  "captain's captain"; "flatter'd"; "of Fulvia";
  "that which we call a rose"; "the undiscovered country"]

let _ = List.iter query queries

let rec tests n () =
  if n <= 0 then ()
  else (List.iter (fun q->ignore (search shakespeare q)) queries;
        tests (n-1) ())
  
let _ = Printf.printf "\ntime: %fs\n%!" (fst (time (tests 200)))
