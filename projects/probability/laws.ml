open Probability
let observed () =
  let b = GProb.choose [false;true] in
  GProb.observe (if b then 0.8 else 0.2);
  ignore (GProb.choose [0;1]); b
let early () =
  let b = GProb.choose [false;true] in
  if b then true else begin
    GProb.observe 0.25; ignore (GProb.choose [0;1]); false
  end
let zero () =
  let b = GProb.choose [false;true] in
  GProb.observe (if b then 1. else 0.);
  ignore (GProb.choose [0;1]); b
let posterior answers = Option.value (List.assoc_opt true answers) ~default:0.
let () =
  List.iter (fun model ->
    let reference = posterior (Enumerate.infer model) in
    List.iteri (fun seed infer ->
      Random.init (781 + seed);
      assert (abs_float (posterior (infer model) -. reference) < 0.035))
      [(fun f -> GImportance.infer ~samples:20_000 f);
       (fun f -> GParticleFilter.infer ~n:20_000 ~resample_threshold:0. f);
       (fun f -> GParticleFilter.infer ~n:20_000 ~resample_threshold:1. f)])
    [observed;early;zero];
  assert (abs_float (posterior (Enumerate.infer observed) -. 0.8) < 1e-12);
  assert (abs_float (posterior (Enumerate.infer early) -. 0.8) < 1e-12);
  let impossible () = GProb.observe 0.; ignore (GProb.choose [0;1]); true in
  assert (Enumerate.infer impossible = []);
  assert (GImportance.infer ~samples:10 impossible = []);
  assert (GParticleFilter.infer ~n:10 impossible = []);
  List.iter (fun w -> assert (try GProb.observe w; false
    with Invalid_argument _ -> true)) [-1.; nan; infinity];
  assert (try ignore (GProb.choose []); false with Invalid_argument _ -> true);
  assert (try ignore (GParticleFilter.infer ~n:0 observed); false
    with Invalid_argument _ -> true);
  assert (try ignore (GImportance.infer ~samples:0 observed); false
    with Invalid_argument _ -> true);
  for _ = 1 to 100 do
    assert (GParticleFilter.resample_indices 3 [|0.;1.;0.|] = [|1;1;1|])
  done
