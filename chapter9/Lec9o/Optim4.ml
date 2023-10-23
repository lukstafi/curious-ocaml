let empty () = Hashtbl.create 511
let increment h w =
  try
    let c = Hashtbl.find h w in
    Hashtbl.replace h w (c+1)
  with Not_found -> Hashtbl.add h w 1
let iterate f h = Hashtbl.iter f h

let read_to_histogram file =
  let input = open_in file in
  let h = empty () and more = ref true in
  try
    while !more do
      Scanf.fscanf input "%[^a-zA-Z0-9']%[a-zA-Z0-9']"
        (fun b w ->
          let w = String.lowercase w in
          increment h w; more := w <> "")
    done; h
  with End_of_file -> h

let _ =
  let h = read_to_histogram "./shakespeare.xml" in
  let output = open_out "histogram.txt" in
  iterate (Printf.fprintf output "%s: %d\n") h;
  close_out output
