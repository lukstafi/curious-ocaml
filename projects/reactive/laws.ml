open Game
let () =
  let reference = through_stream recorded in
  assert (List.map (fun (s,_) -> s.x,s.y) reference = expected_positions);
  assert (List.filter_map (fun (s,e) -> if e=[] then None else Some (s.tick,e)) reference
    = [2,[Paddle];5,[Wall];8,[Ceiling];14,[Miss]]);
  assert ((fst (List.hd (List.rev reference))).status = Lost);
  assert (through_incremental recorded = reference);
  assert (through_effects recorded = reference);
  let rng = Random.State.make [|2026;10|] in
  for _ = 1 to 100 do
    let inputs = List.init 30 (fun _ -> {move=Random.State.int rng 3 - 1}) in
    let reference = through_stream inputs in
    assert (through_incremental inputs = reference);
    assert (through_effects inputs = reference)
  done;
  let update,sample,cost = incremental () in
  update {move=1}; let first = sample () in
  assert (sample () = first && cost () = 1);
  update {move=1}; let second = sample () in
  assert (snd second = [Paddle] && cost () = 2);
  let poll = consumer () in
  assert (poll second = [Paddle]); assert (poll second = []);
  let edge = rising_edge () in
  assert (edge ~tick:1 true); assert (edge ~tick:1 true);
  assert (not (edge ~tick:2 true)); (* Tick invalidates an unchanged Boolean. *)
  assert (not (edge ~tick:3 false)); assert (edge ~tick:4 true);
  let released = ref 0 in
  let session = start ~publish:ignore ~release:(fun () -> incr released) in
  session.push {move=0}; session.close (); session.close ();
  assert (!released = 1);
  assert (try session.push {move=0}; false with Invalid_argument _ -> true);
  let bad = start ~publish:(fun _ -> failwith "renderer") ~release:(fun () -> incr released) in
  assert (try bad.push {move=0}; false with Failure _ -> true);
  bad.close (); assert (!released = 2)
