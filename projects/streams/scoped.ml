(* The callback owns the resource scope; an escaped reader is invalidated. *)
let with_source ~acquire ~read ~close consume =
  let resource = acquire () in
  let active = ref true in
  let next () =
    if not !active then invalid_arg "reader used outside its scope";
    read resource in
  Fun.protect
    ~finally:(fun () -> active := false; close resource)
    (fun () -> consume next)

let with_lines filename consume =
  with_source
    ~acquire:(fun () -> open_in filename)
    ~read:(fun ch -> try Some (input_line ch) with End_of_file -> None)
    ~close:close_in_noerr consume
