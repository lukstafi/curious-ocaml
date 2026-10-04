open Honey
let normalize = List.map (List.sort compare) |> fun f -> fun xs ->
  List.sort_uniq compare (f xs)
let check t =
  let expected = normalize (reference t) in
  List.iter (fun solve ->
    let answers = solve t in
    assert (List.for_all (valid t) answers);
    assert (normalize answers = expected))
    [direct; optimized; Monadic.solve; transformer]
let () =
  (* All initial occupancies of the seven-cell radius-one board. *)
  List.iter (fun honey ->
    for size = 1 to 3 do
      for islands = 0 to 3 do check {honey; size; islands} done
    done) (subsets (board 1));
  let t = {honey=[-4,0; 2,0; 4,0]; size=2; islands=1} in
  check t;
  assert (normalize (optimized t) = [[-4,0]]);
  (* Relabeling the traversal order must not lose solutions. *)
  check {t with honey=List.rev t.honey};
  check {t with islands=max_int};
  let rejected = try ignore (direct {t with size=0}); false
    with Invalid_argument _ -> true in
  assert rejected
