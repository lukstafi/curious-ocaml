(* Sensor Fusion Example: Typed Probabilistic Effects with GADTs *)

module GProb = struct
  type _ Effect.t +=
    | Choose : 'a list -> 'a Effect.t
    | Gaussian : float * float -> float Effect.t
    | GObserve : float -> unit Effect.t
    | GFail : 'a Effect.t

  let choose xs =
    match xs with
    | [] -> invalid_arg "choose: empty list"
    | _ -> Effect.perform (Choose xs)

  let gaussian ~mu ~sigma =
    if not (Float.is_finite mu) || not (Float.is_finite sigma) || sigma <= 0.0 then invalid_arg "gaussian: sigma must be positive";
    Effect.perform (Gaussian (mu, sigma))

  let observe w =
    if not (Float.is_finite w) || w < 0.0 then invalid_arg "observe: weight must be nonnegative";
    Effect.perform (GObserve w)

  let _fail () = Effect.perform GFail

  let pi = 4.0 *. atan 1.0

  let normal_pdf x ~mu ~sigma =
    let z = (x -. mu) /. sigma in
    (1.0 /. (sigma *. sqrt (2.0 *. pi))) *. exp (-0.5 *. z *. z)

  let sample_gaussian ~mu ~sigma =
    (* Box-Muller transform *)
    let u1 = max 1e-12 (Random.float 1.0) in
    let u2 = Random.float 1.0 in
    let r = sqrt (-2.0 *. log u1) in
    let theta = 2.0 *. pi *. u2 in
    mu +. sigma *. (r *. cos theta)
end

module GImportance = struct
  exception HardFail

  let run_once : type a. (unit -> a) -> (a * float) option = fun f ->
    let weight = ref 1.0 in
    match f () with
    | result -> Some (result, !weight)
    | effect (GProb.Choose xs), k ->
        let i = Random.int (List.length xs) in
        Effect.Deep.continue k (List.nth xs i)
    | effect (GProb.Gaussian (mu, sigma)), k ->
        Effect.Deep.continue k (GProb.sample_gaussian ~mu ~sigma)
    | effect (GProb.GObserve w), k ->
        weight := !weight *. w;
        Effect.Deep.continue k ()
    | effect GProb.GFail, k -> Effect.Deep.discontinue k HardFail
    | exception HardFail -> None

  let infer ?(samples=10000) f =
    if samples <= 0 then invalid_arg "positive sample count required";
    let results = Hashtbl.create 16 in
    let total_weight = ref 0.0 in
    for _ = 1 to samples do
      match run_once f with
      | None -> ()
      | Some (v, w) ->
          total_weight := !total_weight +. w;
          let prev = try Hashtbl.find results v with Not_found -> 0.0 in
          Hashtbl.replace results v (prev +. w)
    done;
    if !total_weight > 0.0 then
      Hashtbl.fold (fun v w acc -> (v, w /. !total_weight) :: acc) results []
      |> List.sort (fun (_, p1) (_, p2) -> compare p2 p1)
    else []
end

module GParticleFilter = struct
  exception HardFail

  type draw =
    | DChoose of int      (* index into the list *)
    | DGaussian of float  (* sampled value *)

  type trace = draw list
  exception Pause of trace * float

  type 'a step =
    | Done of 'a * trace * float
    | Paused of trace * float
    | Failed

  let run_one_step : type a. (unit -> a) -> trace -> a step = fun f trace ->
    let remaining = ref trace in
    let recorded = ref [] in
    let weight = ref 1.0 in
    match f () with
    | result -> Done (result, List.rev !recorded, !weight)
    | effect (GProb.Choose xs), k ->
        (match !remaining with
         | DChoose i :: rest ->
             remaining := rest;
             recorded := DChoose i :: !recorded;
             Effect.Deep.continue k (List.nth xs i)
         | [] ->
             let i = Random.int (List.length xs) in
             recorded := DChoose i :: !recorded;
             Effect.Deep.discontinue k (Pause (List.rev !recorded, !weight))
         | _ :: _ ->
             Effect.Deep.discontinue k HardFail)
    | effect (GProb.Gaussian (mu, sigma)), k ->
        (match !remaining with
         | DGaussian x :: rest ->
             remaining := rest;
             recorded := DGaussian x :: !recorded;
             Effect.Deep.continue k x
         | [] ->
             let x = GProb.sample_gaussian ~mu ~sigma in
             recorded := DGaussian x :: !recorded;
             Effect.Deep.discontinue k (Pause (List.rev !recorded, !weight))
         | _ :: _ ->
             Effect.Deep.discontinue k HardFail)
    | effect (GProb.GObserve w), k ->
        if !remaining = [] then weight := !weight *. w;
        Effect.Deep.continue k ()
    | effect GProb.GFail, k -> Effect.Deep.discontinue k HardFail
    | exception Pause (trace, w) -> Paused (trace, w)
    | exception HardFail -> Failed

  let resample_indices n weights =
    let total = Array.fold_left (+.) 0.0 weights in
    if total <= 0.0 then invalid_arg "cannot resample zero mass"
    else begin
      let cumulative = Array.make n 0.0 in
      let acc = ref 0.0 in
      Array.iteri (fun i w ->
        acc := !acc +. w /. total;
        cumulative.(i) <- !acc) weights;
      Array.init n (fun _ ->
        let r = Random.float 1.0 in
        let rec find i =
          if weights.(i) > 0. && (cumulative.(i) > r || i = n - 1) then i
          else if i < n - 1 then find (i + 1)
          else begin
            let j = ref (n - 1) in
            while weights.(!j) = 0. do decr j done; !j
          end
        in find 0)
    end

  let effective_sample_size weights =
    let n = float_of_int (Array.length weights) in
    let total = Array.fold_left (+.) 0.0 weights in
    if total <= 0.0 then 0.0
    else begin
      let sum_sq = Array.fold_left (fun acc w ->
        let nw = w /. total in acc +. nw *. nw) 0.0 weights in
      1.0 /. sum_sq /. n
    end

  let infer ?(n=1000) ?(resample_threshold=0.5) f =
    if n <= 0 then invalid_arg "positive particle count required";
    if not (Float.is_finite resample_threshold) || resample_threshold < 0. ||
       resample_threshold > 1. then invalid_arg "resampling threshold in [0,1]";
    let traces = Array.make n [] in
    let weights = Array.make n 1.0 in
    let active = Array.make n true in
    let final_results = ref [] in
    let n_active = ref n in

    while !n_active > 0 do
      for i = 0 to n - 1 do
        if active.(i) then
          match run_one_step f traces.(i) with
          | Done (result, _trace, w) ->
              final_results := (result, weights.(i) *. w) :: !final_results;
              active.(i) <- false;
              decr n_active
          | Paused (trace, w) ->
              traces.(i) <- trace;
              weights.(i) <- weights.(i) *. w
          | Failed ->
              active.(i) <- false;
              decr n_active
      done;

      if !n_active > 0 then begin
        let active_indices =
          Array.to_list (Array.init n (fun i -> i))
          |> List.filter (fun i -> active.(i))
          |> Array.of_list in
        let active_n = Array.length active_indices in
        let active_weights =
          Array.init active_n (fun j -> weights.(active_indices.(j))) in
        if active_n > 0 && Array.fold_left (+.) 0.0 active_weights > 0.0 &&
            effective_sample_size active_weights < resample_threshold then begin
          let indices = resample_indices active_n active_weights in
          let new_traces = Array.map (fun j -> traces.(active_indices.(j))) indices in
          let new_weight =
            Array.fold_left (+.) 0.0 active_weights /. float_of_int active_n in
          Array.iteri (fun j _ ->
            traces.(active_indices.(j)) <- new_traces.(j);
            weights.(active_indices.(j)) <- new_weight) indices
        end
      end
    done;

    let combined = Hashtbl.create 16 in
    let total = ref 0.0 in
    List.iter (fun (v, w) ->
      total := !total +. w;
      let prev = try Hashtbl.find combined v with Not_found -> 0.0 in
      Hashtbl.replace combined v (prev +. w)) !final_results;
    if !total > 0.0 then
      Hashtbl.fold (fun v w acc -> (v, w /. !total) :: acc) combined []
      |> List.sort (fun (_, p1) (_, p2) -> compare p2 p1)
    else []
end


(* Finite reference inference by replaying every uniform choice branch.
   Likelihood is recomputed from scratch and used only at completed leaves. *)
module Enumerate = struct
  exception Need of int
  exception Rejected
  type 'a attempt = Complete of 'a * float | Branch of int | Impossible
  let attempt f trace =
    let remaining = ref trace and weight = ref 1. in
    match f () with
    | value ->
      if !remaining <> [] then invalid_arg "model changed during replay";
      Complete (value, !weight)
    | effect (GProb.Choose xs), k ->
      (match !remaining with
       | [] -> Effect.Deep.discontinue k (Need (List.length xs))
       | i::rest -> remaining := rest;
         Effect.Deep.continue k (List.nth xs i))
    | effect (GProb.GObserve w), k ->
      weight := !weight *. w; Effect.Deep.continue k ()
    | effect GProb.GFail, k -> Effect.Deep.discontinue k Rejected
    | effect (GProb.Gaussian _), k ->
      Effect.Deep.discontinue k (Invalid_argument "continuous draw cannot be enumerated")
    | exception Need n -> Branch n
    | exception Rejected -> Impossible
  let infer ?(budget=100_000) f =
    if budget <= 0 then invalid_arg "positive enumeration budget required";
    let count = ref 0 in
    let rec visit trace prior =
      incr count;
      if !count > budget then invalid_arg "enumeration budget exhausted";
      match attempt f trace with
      | Impossible -> []
      | Complete (x, likelihood) -> [x, prior *. likelihood]
      | Branch n ->
        List.init n (fun i -> i) |> List.concat_map (fun i ->
          visit (trace @ [i]) (prior /. float_of_int n)) in
    let answers = visit [] 1. in
    let total = List.fold_left (fun acc (_,w) -> acc +. w) 0. answers in
    if total = 0. then [] else
    let values = List.map fst answers |> List.sort_uniq compare in
    List.map (fun value -> value,
      List.fold_left (fun acc (x,w) -> if x=value then acc+.w else acc) 0. answers
      /. total) values
end
