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

let index file =
  let ch = open_in file in
  let lexbuf = Lexing.from_channel ch in
  EngLexer.reset_as_file lexbuf file;
  let ii =
    IndexParser.inv_index update (empty ()) EngLexer.token lexbuf in
  close_in ch;
  mapv List.rev ii, List.rev !EngLexer.linebreaks

let find_line linebreaks p =
  let rec aux line = function
    | [] -> line
    | bp::_ when p < bp -> line
    | _::breaks -> aux (line+1) breaks in
  aux 1 linebreaks

let search (ii, linebreaks) phrase =
  let lexbuf = Lexing.from_string phrase in
  EngLexer.reset_as_file lexbuf ("search phrase: "^phrase);
  let phrase = IndexParser.phrase EngLexer.token lexbuf in
  let rec aux wpos = function
    | [] -> wpos
    | w::ws ->
      let nwpos = find w ii in
      aux (List.filter (fun p->List.mem (p-1) wpos) nwpos) ws in
  let wpos =
    match phrase with
    | [] -> []
    | w::ws -> aux (find w ii) ws in
  List.map (find_line linebreaks) wpos

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
