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

let empty () = []
let increment h w =
  try
    let c = List.assoc w h in
    (w, c+1) :: List.remove_assoc w h
  with Not_found -> (w, 1)::h
let iterate f h =
  List.iter (fun (k,v)->f k v) h

let histogram words =
  List.fold_left increment (empty ()) words

let _ =
  let words = read_words "./shakespeare.xml" in
  let words = List.rev_map String.lowercase words in
  let h = histogram words in
  let output = open_out "histogram.txt" in
  iterate (Printf.fprintf output "%s: %d\n") h;
  close_out output
