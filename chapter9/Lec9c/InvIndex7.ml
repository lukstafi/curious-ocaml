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
  mapv (fun ps->ref 0, Array.of_list (List.rev ps)) ii,
  List.rev !EngLexer.linebreaks

let find_line linebreaks p =
  let rec aux line = function
    | [] -> line
    | bp::_ when p < bp -> line
    | _::breaks -> aux (line+1) breaks in
  aux 1 linebreaks

let first ii w =
  let cw,ps = find w ii in
  cw := 0;
  if ps = [| |] then raise Not_found else ps.(0)
let last ii w =
  let cw,ps = find w ii in
  cw := Array.length ps - 1;
  if ps = [| |] then raise Not_found
  else ps.(Array.length ps - 1)
let prev ii w cp =
  let cw,ps = find w ii in
  let l = Array.length ps in
  if l = 0 || ps.(0) >= cp then raise Not_found;
  let rec jump (b,e as bounds) j =
    if b > 0 && ps.(b) >= cp then jump (b-j,b) (2*j)
    else bounds in
  let rec binse b e =
    if e-b <= 1 then b
    else let m = (b+e)/2 in
         if ps.(m) < cp then binse m e
         else binse b m in
  if ps.(l-1) < cp then cw := l-1
  else (
    let e =
      if !cw < l-1 && ps.(!cw+1) > cp then !cw+1 else l-1 in
    let b,e = jump (e-1,e) 2 in
    let b = if b < 0 then 0 else b in
    cw := binse b e
  );
  ps.(!cw)
let next ii w cp =
  let cw,ps = find w ii in
  let l = Array.length ps in
  if l = 0 || ps.(l-1) <= cp then raise Not_found;
  let rec jump (b,e as bounds) j =
    if e < l-1 && ps.(e) <= cp then jump (e,e+j) (2*j)
    else bounds in
  let rec binse b e =
    if e-b <= 1 then e
    else let m = (b+e)/2 in
         if ps.(m) <= cp then binse m e
         else binse b m in
  if ps.(0) > cp then cw := 0
  else (
    let b =
      if !cw > 0 && ps.(!cw-1) <= cp then !cw-1 else 0 in
    let b,e = jump (b,b+1) 2 in
    let e = if e > l-1 then l-1 else e in
    cw := binse b e
  );
  ps.(!cw)

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
