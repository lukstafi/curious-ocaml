(* A solution consumer: SVG output has no influence on search. *)
let write file task eaten =
  Honey.validate task;
  if not (Honey.valid task eaten) then invalid_arg "drawing requires a solution";
  let radius = 18. in
  let center (x,y) = sqrt 3. *. radius *. float x /. 2.,
                     1.5 *. radius *. float y in
  let centers = List.map center task.Honey.honey in
  let xmin,ymin,xmax,ymax = List.fold_left (fun (xl,yl,xh,yh) (x,y) ->
    min xl (x-.radius), min yl (y-.radius),
    max xh (x+.radius), max yh (y+.radius)) (-.radius,-.radius,radius,radius) centers in
  let out = open_out file in
  Fun.protect ~finally:(fun () -> close_out_noerr out) (fun () ->
    Printf.fprintf out
      "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"%g %g %g %g\" role=\"img\" aria-labelledby=\"title desc\">\n<title id=\"title\">Honey Islands solution</title>\n<desc id=\"desc\">Gold cells are retained; white crossed cells are eaten.</desc>\n"
      (xmin-.2.) (ymin-.2.) (xmax-.xmin+.4.) (ymax-.ymin+.4.);
    List.iter2 (fun cell (x,y) ->
      let removed = List.mem cell eaten in
      let points = List.init 6 (fun i ->
        let angle = Float.pi *. (float i /. 3. +. 1. /. 6.) in
        Printf.sprintf "%g,%g" (x+.radius*.cos angle) (y+.radius*.sin angle)) in
      Printf.fprintf out "<polygon points=\"%s\" fill=\"%s\" stroke=\"black\"/>\n"
        (String.concat " " points) (if removed then "white" else "gold");
      if removed then Printf.fprintf out
        "<path d=\"M %g %g l 12 12 m -12 0 l 12 -12\" stroke=\"black\"/>\n"
        (x-.6.) (y-.6.)) task.honey centers;
    output_string out "</svg>\n")

let () =
  if Array.length Sys.argv <> 2 then invalid_arg "usage: draw.exe output.svg";
  let task = Honey.{honey=board 1; islands=2; size=2} in
  match Honey.optimized task with
  | [] -> failwith "no solution"
  | eaten::_ -> write Sys.argv.(1) task eaten
