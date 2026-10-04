open Search
let () =
  assert (all (pairs 4) = [1,3;2,2;3,1]);
  assert (first (pairs 4) = Some (1,3));
  assert (first (pairs 9) = None);
  List.iter (fun target ->
    let answers = all (pairs target) in
    assert (first (pairs target) = List.nth_opt answers 0);
    assert (count (pairs target) = List.length answers)) [0;2;3;4;5;6;7];
  let examples = [Fail; Return 1; choose [1;2]; Choice [choose [1;2]; Fail]] in
  let f x = choose [x; x+10] in
  let g x = if x mod 2 = 0 then Fail else return (x+1) in
  List.iter (fun m ->
    assert (all (bind m return) = all m);
    assert (all (bind (bind m f) g) = all (bind m (fun x -> bind (f x) g)))) examples;
  List.iter (fun x -> assert (all (bind (return x) f) = all (f x))) [1;2;3];
  (* First success must happen after downstream failures have been considered. *)
  assert (first (bind (choose [1;2]) (fun x -> if x=2 then return x else Fail)) = Some 2)
