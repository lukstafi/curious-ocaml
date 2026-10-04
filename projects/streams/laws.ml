let () =
  let opened = ref 0 and closed = ref 0 in
  let with_numbers consume = Scoped.with_source
    ~acquire:(fun () -> incr opened; ref [1;2;3])
    ~read:(fun r -> match !r with [] -> None | x::xs -> r:=xs; Some x)
    ~close:(fun _ -> incr closed) consume in
  assert (with_numbers (fun next -> next ()) = Some 1);
  assert (!opened = 1 && !closed = 1);
  (try with_numbers (fun _ -> failwith "consumer") with Failure _ -> ());
  assert (!closed = 2);
  let escaped = with_numbers Fun.id in
  assert (!closed = 3);
  assert (try ignore (escaped ()); false with Invalid_argument _ -> true);
  let filename = Filename.temp_file "curious-lines" ".txt" in
  Fun.protect ~finally:(fun () -> Sys.remove filename) (fun () ->
    let ch = open_out filename in
    Fun.protect ~finally:(fun () -> close_out ch)
      (fun () -> output_string ch "first\nsecond\n");
    assert (Scoped.with_lines filename (fun next -> next ()) = Some "first");
    assert (Scoped.with_lines filename (fun next ->
      let a = next () in let b = next () in let c = next () in a,b,c)
      = (Some "first", Some "second", None)))
