let read_words file =
  let input = open_in file in
  let words = ref [] and more = ref true in
  try
    while !more do
      Scanf.fscanf input "%[^a-zA-Z0-9']%[a-zA-Z0-9']"
        (fun b x -> words := x :: !words; more := x <> "")
    done;
    List.rev (List.tl !words)
  with End_of_file -> List.rev !words

let empty () = Hashtbl.create 511
let increment h w =
  try
    let c = Hashtbl.find h w in
    Hashtbl.replace h w (c+1); h
  with Not_found -> Hashtbl.add h w 1; h
let iterate f h = Hashtbl.iter f h

let histogram words =
  List.fold_left increment (empty ()) words

let _ =
  let words = read_words "./shakespeare.xml" in
  let words = List.rev_map String.lowercase words in
  let h = histogram words in
  let output = open_out "histogram.txt" in
  iterate (Printf.fprintf output "%s: %d\n") h;
  close_out output
