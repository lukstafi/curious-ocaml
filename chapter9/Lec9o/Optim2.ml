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

let iterate f h =
  List.iter (fun (k,v)->f k v) h

let histogram words =
  let words = List.sort String.compare words in
  let k,c,h = List.fold_left
    (fun (k,c,h) w ->
      if k = w then k, c+1, h else w, 1, ((k,c)::h))
    ("", 0, []) words in
  (k,c)::h

let _ =
  let words = read_words "./shakespeare.xml" in
  let words = List.rev_map String.lowercase words in
  let h = histogram words in
  let output = open_out "histogram.txt" in
  iterate (Printf.fprintf output "%s: %d\n") h;
  close_out output
