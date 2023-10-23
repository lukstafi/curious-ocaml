type inverted_index = {
  ii : (string, int list) Hashtbl.t;
  biword : (string * string, int list) Hashtbl.t
}
let update =
  let last = ref "" in
  fun ii (w, p) ->
    (try
       let ps = Hashtbl.find ii.ii w in
       Hashtbl.replace ii.ii w (p::ps);
     with Not_found ->
       Hashtbl.add ii.ii w [p]);
    (try
       let ps = Hashtbl.find ii.biword (!last, w) in
       Hashtbl.replace ii.biword (!last, w) (p::ps);
     with Not_found ->
       Hashtbl.add ii.biword (!last, w) [p]);
    last := w;
    ii
let empty () = Hashtbl.create 511
let find wp ii = Hashtbl.find ii wp
let mapv f ii =
  let ii' = empty () in
  Hashtbl.iter (fun k v -> Hashtbl.add ii' k (f v)) ii;
  ii'

let index file =
  let ch = open_in file in
  let lexbuf = Lexing.from_channel ch in
  EngLexer.reset_as_file lexbuf file;
  let ii = {ii=empty (); biword=empty ()} in
  let ii =
    IndexParser.inv_index update ii EngLexer.token lexbuf in
  close_in ch;
  {ii=mapv List.rev ii.ii;
   biword=mapv List.rev ii.biword},
  List.rev !EngLexer.linebreaks

let find_line linebreaks p =
  let rec aux line = function
    | [] -> line
    | bp::_ when p < bp -> line
    | _::breaks -> aux (line+1) breaks in
  aux 1 linebreaks

let rec merge_pos aux = function
  | _, [] | [], _ -> List.rev aux
  | p::ps, q::qs when p+1=q -> merge_pos (q::aux) (ps, qs)
  | p::ps, (q::_ as qs) when p+1<q -> merge_pos aux (ps, qs)
  | ps, _::qs -> merge_pos aux (ps, qs)

let search (ii, linebreaks) phrase =
  let lexbuf = Lexing.from_string phrase in
  EngLexer.reset_as_file lexbuf ("search phrase: "^phrase);
  let phrase = IndexParser.phrase EngLexer.token lexbuf in
  let rec aux lw wpos = function
    | [] -> wpos
    | w::ws ->
      let nwpos = find (lw, w) ii.biword in
      aux w (merge_pos [] (wpos, nwpos)) ws in
  let wpos =
    match phrase with
    | [] -> []
    | [w] -> find w ii.ii
    | lw::w::ws -> aux w (find (lw,w) ii.biword) ws in
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
