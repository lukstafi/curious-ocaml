(* Sensor-fusion application of the shared third-edition inference project. *)
open Probability

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
