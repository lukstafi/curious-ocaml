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
    if sigma <= 0.0 then invalid_arg "gaussian: sigma must be positive";
    Effect.perform (Gaussian (mu, sigma))

  let observe w =
    if w < 0.0 then invalid_arg "observe: weight must be nonnegative";
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
             Paused (List.rev !recorded, !weight)
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
             Paused (List.rev !recorded, !weight)
         | _ :: _ ->
             Effect.Deep.discontinue k HardFail)
    | effect (GProb.GObserve w), k ->
        weight := !weight *. w;
        Effect.Deep.continue k ()
    | effect GProb.GFail, k -> Effect.Deep.discontinue k HardFail
    | exception HardFail -> Failed

  let resample_indices n weights =
    let total = Array.fold_left (+.) 0.0 weights in
    if total <= 0.0 then Array.init n (fun i -> i mod n)
    else begin
      let cumulative = Array.make n 0.0 in
      let acc = ref 0.0 in
      Array.iteri (fun i w ->
        acc := !acc +. w /. total;
        cumulative.(i) <- !acc) weights;
      Array.init n (fun _ ->
        let r = Random.float 1.0 in
        let rec find i =
          if i >= n - 1 || cumulative.(i) >= r then i
          else find (i + 1)
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
        if active_n > 0 && effective_sample_size active_weights < resample_threshold then begin
          let indices = resample_indices active_n active_weights in
          let new_traces = Array.map (fun j -> traces.(active_indices.(j))) indices in
          let new_weight = 1.0 /. float_of_int active_n in
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

(* Sensor Fusion Example *)

type room = Kitchen | Living | Bedroom | Bathroom

let room_center = function
  | Kitchen -> (0.0, 0.0)
  | Living -> (5.0, 0.0)
  | Bedroom -> (0.0, 5.0)
  | Bathroom -> (5.0, 5.0)

let show_room = function
  | Kitchen -> "Kitchen"
  | Living -> "Living"
  | Bedroom -> "Bedroom"
  | Bathroom -> "Bathroom"

let sensor_fusion ~observed_x ~observed_y =
  let open GProb in
  (* Prior: uniform over rooms *)
  let room = choose [Kitchen; Living; Bedroom; Bathroom] in
  let (cx, cy) = room_center room in
  (* Sensor model: noisy reading centered on true position *)
  let sensor_noise = 1.0 in
  let x = gaussian ~mu:cx ~sigma:sensor_noise in
  let y = gaussian ~mu:cy ~sigma:sensor_noise in
  (* Observe the sensor readings *)
  observe (normal_pdf observed_x ~mu:x ~sigma:0.5);
  observe (normal_pdf observed_y ~mu:y ~sigma:0.5);
  room

let () =
  Printf.printf "=== Sensor Fusion with Typed Probabilistic Effects ===\n\n";

  let test_case name ~observed_x ~observed_y =
    Printf.printf "Observation at (%.1f, %.1f) - %s:\n" observed_x observed_y name;

    let dist1 = GImportance.infer ~samples:50000 (fun () ->
      sensor_fusion ~observed_x ~observed_y) in
    Printf.printf "  Importance Sampling: ";
    List.iter (fun (r, p) -> Printf.printf "%s: %.3f  " (show_room r) p) dist1;
    print_newline ();

    let dist2 = GParticleFilter.infer ~n:5000 (fun () ->
      sensor_fusion ~observed_x ~observed_y) in
    Printf.printf "  Particle Filter:     ";
    List.iter (fun (r, p) -> Printf.printf "%s: %.3f  " (show_room r) p) dist2;
    print_newline ();
    print_newline ()
  in

  test_case "near Living room" ~observed_x:4.8 ~observed_y:0.2;
  test_case "near Kitchen" ~observed_x:0.1 ~observed_y:(-0.3);
  test_case "between Bedroom and Bathroom" ~observed_x:2.5 ~observed_y:5.1;
  test_case "center of house" ~observed_x:2.5 ~observed_y:2.5
