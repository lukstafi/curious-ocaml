(* Chapter 10: Functional Reactive Programming -- Runnable Examples

   Usage:
     dune exec chapter10/chapter10.exe          # List available examples
     dune exec chapter10/chapter10.exe zipper   # Run zipper example
     dune exec chapter10/chapter10.exe expr     # Run expression rewriting
     dune exec chapter10/chapter10.exe lwd      # Run Lwd incremental demo
     dune exec chapter10/chapter10.exe incr     # Run Incremental demo
     dune exec chapter10/chapter10.exe paddle   # Run Lwd paddle game (GUI)
     dune exec chapter10/chapter10.exe stream   # Run stream FRP paddle game (GUI)
     dune exec chapter10/chapter10.exe effects  # Run effects click-and-drag demo
*)

[@@@warning "-32-37"]

(* ========== 10.1 Zippers ========== *)

module Zipper = struct
  type 'a tree = Tip | Node of 'a tree * 'a * 'a tree
  type tree_dir = Left_br | Right_br
  type 'a context = (tree_dir * 'a * 'a tree) list
  type 'a location = {sub: 'a tree; ctx: 'a context}

  let access {sub; _} = sub
  let change {ctx; _} sub = {sub; ctx}
  let modify f {sub; ctx} = {sub = f sub; ctx}

  let ascend loc =
    match loc.ctx with
    | [] -> loc
    | (Left_br, n, l) :: up_ctx ->
      {sub = Node (l, n, loc.sub); ctx = up_ctx}
    | (Right_br, n, r) :: up_ctx ->
      {sub = Node (loc.sub, n, r); ctx = up_ctx}

  let desc_left loc =
    match loc.sub with
    | Tip -> loc
    | Node (l, n, r) ->
      {sub = l; ctx = (Right_br, n, r) :: loc.ctx}

  let desc_right loc =
    match loc.sub with
    | Tip -> loc
    | Node (l, n, r) ->
      {sub = r; ctx = (Left_br, n, l) :: loc.ctx}

  let rec tree_to_string = function
    | Tip -> "."
    | Node (l, n, r) ->
      Printf.sprintf "(%s %d %s)" (tree_to_string l) n (tree_to_string r)

  let location_to_string loc =
    Printf.sprintf "focus: %s, depth: %d"
      (tree_to_string loc.sub) (List.length loc.ctx)

  let demo () =
    print_endline "=== Zipper Demo ===";
    let tree = Node (Node (Tip, 1, Tip), 2, Node (Tip, 3, Node (Tip, 4, Tip))) in
    print_endline ("Original tree: " ^ tree_to_string tree);
    let loc = {sub = tree; ctx = []} in
    print_endline ("At root: " ^ location_to_string loc);
    let loc = desc_right loc in
    print_endline ("After desc_right: " ^ location_to_string loc);
    let loc = desc_right loc in
    print_endline ("After desc_right again: " ^ location_to_string loc);
    let loc = modify (fun _ -> Node (Tip, 99, Tip)) loc in
    print_endline ("After modify to 99: " ^ location_to_string loc);
    let loc = ascend loc in
    print_endline ("After ascend: " ^ location_to_string loc);
    let loc = ascend loc in
    print_endline ("After ascend to root: " ^ location_to_string loc);
    print_endline ("Final tree: " ^ tree_to_string (access loc));
    ignore (change loc Tip)
end

(* ========== 10.2 Context Rewriting ========== *)

module ExprRewrite = struct
  type op = Add | Mul
  type expr = Val of int | Var of string | App of expr * op * expr
  type expr_dir = Left_arg | Right_arg
  type context = (expr_dir * op * expr) list
  type location = {sub: expr; ctx: context}

  let rec find_aux p e =
    if p e then Some (e, [])
    else match e with
    | Val _ | Var _ -> None
    | App (l, op, r) ->
      match find_aux p l with
      | Some (sub, up_ctx) ->
        Some (sub, (Right_arg, op, r) :: up_ctx)
      | None ->
        match find_aux p r with
        | Some (sub, up_ctx) ->
          Some (sub, (Left_arg, op, l) :: up_ctx)
        | None -> None

  let find p e =
    match find_aux p e with
    | None -> None
    | Some (sub, ctx) -> Some {sub; ctx = List.rev ctx}

  let rec pull_out loc =
    match loc.ctx with
    | [] -> loc
    | (Left_arg, op, l) :: up_ctx ->
      pull_out {loc with ctx = (Right_arg, op, l) :: up_ctx}
    | (Right_arg, op1, e1) :: (_, op2, e2) :: up_ctx
        when op1 = op2 ->
      pull_out {loc with ctx = (Right_arg, op1, App(e1, op1, e2)) :: up_ctx}
    | (Right_arg, Add, e1) :: (_, Mul, e2) :: up_ctx ->
      pull_out {loc with ctx =
          (Right_arg, Mul, e2) ::
            (Right_arg, Add, App(e1, Mul, e2)) :: up_ctx}
    | (Right_arg, op, r) :: up_ctx ->
      pull_out {sub = App(loc.sub, op, r); ctx = up_ctx}

  let rec expr_to_string = function
    | Val n -> string_of_int n
    | Var s -> s
    | App (l, Add, r) -> Printf.sprintf "(%s + %s)" (expr_to_string l) (expr_to_string r)
    | App (l, Mul, r) -> Printf.sprintf "(%s * %s)" (expr_to_string l) (expr_to_string r)

  module ExprOps = struct
    let (+) a b = App (a, Add, b)
    let ( * ) a b = App (a, Mul, b)
    let (!) a = Val a
  end

  let demo () =
    print_endline "=== Expression Rewriting Demo ===";
    let x = Var "x" in
    let y = Var "y" in
    let ex = ExprOps.(!5 + y * (!7 + x) * (!3 + y)) in
    print_endline ("Original: " ^ expr_to_string ex);
    match find (fun e -> e = x) ex with
    | None -> print_endline "Variable x not found"
    | Some loc ->
      print_endline ("Found x at depth: " ^ string_of_int (List.length loc.ctx));
      let result = pull_out loc in
      print_endline ("After pull_out: " ^ expr_to_string result.sub);
      print_endline "The x has been pulled out to the leftmost position!"
end

(* ========== 10.3 Lwd Incremental Demo ========== *)

module LwdDemo = struct
  let demo () =
    print_endline "=== Lwd Incremental Demo ===";
    let a = Lwd.var 10 in
    let b = Lwd.var 32 in
    let sum = Lwd.map2 (Lwd.get a) (Lwd.get b) ~f:( + ) in
    let root = Lwd.observe sum in
    let now () = Lwd.quick_sample root in

    Printf.printf "Initial: a=10, b=32, sum=%d\n" (now ());
    Lwd.set a 11;
    Printf.printf "After a=11: sum=%d\n" (now ());
    Lwd.set b 100;
    Printf.printf "After b=100: sum=%d\n" (now ());

    print_endline "\n--- Dependency graph demo ---";
    let x = Lwd.var 5 in
    let y = Lwd.var 3 in
    let prod = Lwd.map2 (Lwd.get x) (Lwd.get y) ~f:( * ) in
    let combined = Lwd.map2 sum prod ~f:(fun s p -> s + p) in
    let root2 = Lwd.observe combined in
    let now2 () = Lwd.quick_sample root2 in

    Printf.printf "x=5, y=3, prod=15, sum=%d, combined=%d\n" (now ()) (now2 ());
    Lwd.set x 10;
    Printf.printf "After x=10: combined=%d (only prod path recomputed)\n" (now2 ())
end

(* ========== 10.3 Jane Street Incremental Demo ========== *)

module IncrDemo = struct
  module Incr = Incremental.Make ()

  let demo () =
    print_endline "=== Incremental Demo ===";
    let a = Incr.Var.create 10 in
    let b = Incr.Var.create 32 in
    let sum = Incr.map2 (Incr.Var.watch a) (Incr.Var.watch b) ~f:( + ) in
    let obs = Incr.observe sum in
    let now () =
      Incr.stabilize ();
      Incr.Observer.value_exn obs
    in

    Printf.printf "Initial: a=10, b=32, sum=%d\n" (now ());
    Incr.Var.set a 11;
    Printf.printf "After a=11: sum=%d\n" (now ());
    Incr.Var.set b 100;
    Printf.printf "After b=100: sum=%d\n" (now ());

    print_endline "\n--- Cutoff demo ---";
    let x = Incr.Var.create 5.0 in
    let rounded = Incr.map (Incr.Var.watch x) ~f:(fun v -> Float.round v) in
    let obs2 = Incr.observe rounded in
    let now2 () =
      Incr.stabilize ();
      Incr.Observer.value_exn obs2
    in

    Printf.printf "x=5.0, rounded=%.0f\n" (now2 ());
    Incr.Var.set x 5.2;
    Printf.printf "After x=5.2: rounded=%.0f\n" (now2 ());
    Incr.Var.set x 5.6;
    Printf.printf "After x=5.6: rounded=%.0f\n" (now2 ())
end

(* ========== 10.6 Lwd Paddle Game (GUI) ========== *)

module LwdPaddle = struct
  type color = int * int * int

  type scene =
    | Rect of int * int * int * int
    | Circle of int * int * int
    | Group of scene list
    | Color of color * scene
    | Translate of float * float * scene

  type ball_state =
    { mutable x : float
    ; mutable y : float
    ; mutable vx : float
    ; mutable vy : float
    }

  let draw area ~h sc =
    let open Bogue in
    let f2i = int_of_float in
    let flip_y y = h - y in
    let rec aux t_x t_y (r, g, b) = function
      | Rect (x, y, w, ht) ->
        let color = Draw.opaque (r, g, b) in
        let x0, y0 = f2i t_x + x, flip_y (f2i t_y + y + ht) in
        Sdl_area.draw_rectangle area ~color ~thick:2 ~w ~h:ht (x0, y0)
      | Circle (x, y, rad) ->
        let color = Draw.opaque (r, g, b) in
        let cx, cy = f2i t_x + x, flip_y (f2i t_y + y) in
        Sdl_area.draw_circle area ~color ~thick:2 ~radius:rad (cx, cy)
      | Group scs ->
        List.iter (aux t_x t_y (r, g, b)) scs
      | Color (c, sc) ->
        aux t_x t_y c sc
      | Translate (dx, dy, sc) ->
        aux (t_x +. dx) (t_y +. dy) (r, g, b) sc
    in
    aux 0. 0. (255, 255, 255) sc

  let time_v : float Lwd.var = Lwd.var 0.0
  let time_b : float Lwd.t = Lwd.get time_v
  let mouse_v : (int * int) Lwd.var = Lwd.var (0, 0)
  let mouse_x : int Lwd.t = Lwd.map (Lwd.get mouse_v) ~f:fst
  let width_v : int Lwd.var = Lwd.var 640
  let height_v : int Lwd.var = Lwd.var 512
  let width : int Lwd.t = Lwd.get width_v
  let height : int Lwd.t = Lwd.get height_v

  let blue = (0, 0, 255)
  let black = (0, 0, 0)
  let red = (255, 0, 0)

  let clamp_int ~lo ~hi x = max lo (min hi x)

  let wall_thickness = 20
  let ball_r = 7
  let paddle_w = 70
  let paddle_h = 10

  let walls : scene Lwd.t =
    Lwd.map2 width height ~f:(fun w h ->
      Color (blue, Group
        [Rect (0, 0, 20, h-1); Rect (0, h-21, w-1, 20);
         Rect (w-21, 0, 20, h-1)]))

  let paddle_x : int Lwd.t =
    Lwd.map2 mouse_x width ~f:(fun mx w ->
      let lo = wall_thickness in
      let hi = max lo (w - 21 - paddle_w) in
      clamp_int ~lo ~hi (mx - (paddle_w / 2)))

  let paddle : scene Lwd.t =
    Lwd.map paddle_x ~f:(fun px ->
      Color (black, Rect (px, 0, paddle_w, paddle_h)))

  let ball : scene Lwd.t =
    let st : ball_state = { x = 0.0; y = 0.0; vx = 120.0; vy = 160.0 } in
    let prev_t : float option ref = ref None in
    let prev_wh : (int * int) option ref = ref None in
    let dir : float ref = ref 1.0 in

    let reset ~w ~h =
      st.x <- float_of_int w /. 2.0;
      st.y <- float_of_int h /. 2.0;
      st.vx <- !dir *. 120.0;
      st.vy <- 180.0;
      dir := -. !dir
    in

    let clamp_speed ~max_speed v = max (-.max_speed) (min max_speed v) in

    let step_physics ~w ~h ~paddle_x ~dt =
      let max_step = 1.0 /. 240.0 in
      let paddle_plane = float_of_int (paddle_h + ball_r) in
      let xmin = float_of_int (wall_thickness + ball_r) in
      let xmax = float_of_int (max (wall_thickness + ball_r) (w - 21 - ball_r)) in
      let ymax = float_of_int (max (paddle_h + ball_r) (h - 21 - ball_r)) in
      let max_speed = 500.0 in

      let rec loop remaining =
        if remaining <= 0.0 then ()
        else begin
          let dt1 = min max_step remaining in
          let x0, y0 = st.x, st.y in
          let x1 = x0 +. dt1 *. st.vx in
          let y1 = y0 +. dt1 *. st.vy in
          let x1, vx =
            if x1 < xmin then (xmin +. (xmin -. x1), -. st.vx)
            else if x1 > xmax then (xmax -. (x1 -. xmax), -. st.vx)
            else (x1, st.vx)
          in
          let y1, vy =
            if y1 > ymax then (ymax -. (y1 -. ymax), -. st.vy)
            else (y1, st.vy)
          in
          st.x <- x1;
          st.y <- y1;
          st.vx <- vx;
          st.vy <- vy;

          (* Paddle hit/miss: detect crossing of the paddle plane. *)
          if st.vy < 0.0 && y0 >= paddle_plane && st.y < paddle_plane then begin
            let alpha = (y0 -. paddle_plane) /. (y0 -. st.y) in
            let x_hit = x0 +. alpha *. (st.x -. x0) in
            let paddle_left = float_of_int paddle_x -. float_of_int ball_r in
            let paddle_right = float_of_int (paddle_x + paddle_w) +. float_of_int ball_r in
            if x_hit >= paddle_left && x_hit <= paddle_right then begin
              st.y <- paddle_plane +. (paddle_plane -. st.y);
              st.vy <- abs_float st.vy;
              let paddle_center = float_of_int paddle_x +. (float_of_int paddle_w /. 2.0) in
              let offset =
                (x_hit -. paddle_center) /. (float_of_int paddle_w /. 2.0)
                |> clamp_speed ~max_speed:1.0
              in
              st.vx <- clamp_speed ~max_speed (st.vx +. offset *. 120.0)
            end else (
              reset ~w ~h
            )
          end else if st.y < -50.0 then (
            reset ~w ~h
          );

          st.vx <- clamp_speed ~max_speed st.vx;
          st.vy <- clamp_speed ~max_speed st.vy;
          loop (remaining -. dt1)
        end
      in
      loop dt
    in

    let inputs : (int * int * int * float) Lwd.t =
      let wh_px : ((int * int) * int) Lwd.t =
        Lwd.pair (Lwd.pair width height) paddle_x
      in
      Lwd.map2 wh_px time_b ~f:(fun ((w, h), px) t -> (w, h, px, t))
    in
    Lwd.map inputs ~f:(fun (w, h, px, t) ->
      let reset_if_needed () =
        match !prev_wh with
        | Some (w0, h0) when w0 = w && h0 = h -> ()
        | _ ->
          prev_wh := Some (w, h);
          reset ~w ~h
      in
      reset_if_needed ();

      let dt =
        match !prev_t with
        | None -> 0.0
        | Some t0 ->
          let dt = t -. t0 in
          if dt <= 0.0 then 0.0 else min dt 0.25
      in
      prev_t := Some t;
      if dt > 0.0 then step_physics ~w ~h ~paddle_x:px ~dt;
      Color (red, Circle (int_of_float st.x, int_of_float st.y, ball_r)))

  let game : scene Lwd.t =
    Lwd.map2 walls (Lwd.pair paddle ball) ~f:(fun w (p, b) -> Group [w; p; b])

  let demo () =
    print_endline "=== Lwd Paddle Game ===";
    print_endline "Starting Bogue GUI... Move mouse to control paddle.";
    print_endline "Close the window to exit.";
    let open Bogue in
    let w, h = 640, 512 in
    Lwd.set width_v w;
    Lwd.set height_v h;
    let area_widget = Widget.sdl_area ~w ~h () in
    let area = Widget.get_sdl_area area_widget in
    let root = Lwd.observe game in
    let t0 = Unix.gettimeofday () in

    Sdl_area.add area (fun _renderer ->
      let t = Unix.gettimeofday () -. t0 in
      Lwd.set time_v t;
      Sdl_area.fill_rectangle area ~color:(Draw.opaque Draw.grey)
        ~w ~h (0, 0);
      let sc = Lwd.quick_sample root in
      draw area ~h sc);

    let layout = Layout.resident area_widget in

    let action _w _l ev =
      let mx, _my = Mouse.pointer_pos ev in
      Lwd.set mouse_v (mx, 0);
      Sdl_area.update area
    in
    let connection = Widget.connect area_widget area_widget action Trigger.pointer_motion in
    Widget.add_connection area_widget connection;

    (* Animation tick: reschedule itself every ~16ms. *)
    let rec tick () =
      Sdl_area.update area;
      Widget.update area_widget;
      Timeout.add_ignore 16 tick
    in
    Timeout.add_ignore 16 tick;

    let board = Main.of_layout layout in
    Main.run board
end

(* ========== 10.5 Stream-Based FRP Paddle Game (GUI) ========== *)

module StreamFRP = struct
  (* Stream infrastructure *)
  type 'a stream = 'a stream_ Lazy.t
  and 'a stream_ = Cons of 'a * 'a stream

  let rec lmap f l = lazy (
    let Cons (x, xs) = Lazy.force l in
    Cons (f x, lmap f xs))

  let rec lmap2 f xs ys = lazy (
    let Cons (x, xs) = Lazy.force xs in
    let Cons (y, ys) = Lazy.force ys in
    Cons (f x y, lmap2 f xs ys))

  let rec lmap3 f xs ys zs = lazy (
    let Cons (x, xs) = Lazy.force xs in
    let Cons (y, ys) = Lazy.force ys in
    let Cons (z, zs) = Lazy.force zs in
    Cons (f x y z, lmap3 f xs ys zs))

  let rec lfold acc f (l : 'a stream) = lazy (
    let Cons (x, xs) = Lazy.force l in
    let acc = f acc x in
    Cons (acc, lfold acc f xs))

  (* User actions *)
  type user_action =
    | Key of char * bool
    | Button of int * int * bool * bool
    | MouseMove of int * int
    | Resize of int * int

  type time = float

  (* Memoization for behaviors *)
  type ('a, 'b) memo1 =
    {memo_f : 'a -> 'b; mutable memo_r : ('a * 'b) option}

  let memo1 f = {memo_f = f; memo_r = None}

  let memo1_app f x =
    match f.memo_r with
    | Some (y, res) when x == y -> res
    | _ ->
      let res = f.memo_f x in
      f.memo_r <- Some (x, res);
      res

  let ($) = memo1_app

  type 'a behavior =
    ((user_action option * time) stream, 'a stream) memo1

  type 'a event = 'a option behavior

  (* Behavior combinators *)
  let returnB x : 'a behavior =
    let rec xs = lazy (Cons (x, xs)) in
    memo1 (fun _ -> xs)

  let ( !* ) = returnB

  let liftB f fb = memo1 (fun uts -> lmap f (fb $ uts))

  let liftB2 f fb1 fb2 = memo1
    (fun uts -> lmap2 f (fb1 $ uts) (fb2 $ uts))

  let liftB3 f fb1 fb2 fb3 = memo1
    (fun uts -> lmap3 f (fb1 $ uts) (fb2 $ uts) (fb3 $ uts))

  let liftE f (fe : 'a event) : 'b event = memo1
    (fun uts -> lmap
      (function Some e -> Some (f e) | None -> None)
      (fe $ uts))

  let (=>>) fe f = liftE f fe
  let (->>) e v = e =>> fun _ -> v

  (* Event/behavior conversions *)
  let whileB (fb : bool behavior) : unit event =
    memo1 (fun uts ->
      lmap (function true -> Some () | false -> None)
        (fb $ uts))

  let unique fe : 'a event =
    memo1 (fun uts ->
      let xs = fe $ uts in
      lmap2 (fun x y -> if x = y then None else y)
        (lazy (Cons (None, xs))) xs)

  let whenB fb =
    memo1 (fun uts -> unique (whileB fb) $ uts)

  let step acc fe =
    memo1 (fun uts -> lfold acc
      (fun acc -> function None -> acc | Some v -> v)
      (fe $ uts))

  let step_accum acc ff =
    memo1 (fun uts ->
      lfold acc (fun acc -> function
        | None -> acc | Some f -> f acc)
        (ff $ uts))

  let integral fb =
    let rec loop t0 acc uts bs =
      let Cons ((_, t1), uts) = Lazy.force uts in
      let Cons (b, bs) = Lazy.force bs in
      let acc = acc +. (t1 -. t0) *. b in
      Cons (acc, lazy (loop t1 acc uts bs)) in
    memo1 (fun uts -> lazy (
      let Cons ((_, t), uts') = Lazy.force uts in
      Cons (0., lazy (loop t 0. uts' (fb $ uts)))))

  (* Input extraction *)
  let mm : (int * int) event =
    memo1 (fun uts -> lmap
      (function Some (MouseMove (x, y)), _ -> Some (x, y) | _ -> None)
      uts)

  let screen : (int * int) event =
    memo1 (fun uts -> lmap
      (function Some (Resize (x, y)), _ -> Some (x, y) | _ -> None)
      uts)

  let mouse_x : int behavior = step 0 (liftE fst mm)
  let width : int behavior = step 640 (liftE fst screen)
  let height : int behavior = step 512 (liftE snd screen)

  (* Lifted operators *)
  let (+*) = liftB2 (+)
  let (-*) = liftB2 (-)
  let (/*) = liftB2 (/)
  let (||*) = liftB2 (||)
  let (&&*) = liftB2 (&&)
  let (<*) = liftB2 (<)
  let (>*) = liftB2 (>)

  (* Scene graph *)
  type color = int * int * int

  type scene =
    | Rect of int * int * int * int
    | Circle of int * int * int
    | Group of scene list
    | Color of color * scene
    | Translate of float * float * scene

  let draw area ~h sc =
    let open Bogue in
    let f2i = int_of_float in
    let flip_y y = h - y in
    let rec aux t_x t_y (r, g, b) = function
      | Rect (x, y, w, ht) ->
        let color = Draw.opaque (r, g, b) in
        let x0, y0 = f2i t_x + x, flip_y (f2i t_y + y + ht) in
        Sdl_area.draw_rectangle area ~color ~thick:2 ~w ~h:ht (x0, y0)
      | Circle (x, y, rad) ->
        let color = Draw.opaque (r, g, b) in
        let cx, cy = f2i t_x + x, flip_y (f2i t_y + y) in
        Sdl_area.draw_circle area ~color ~thick:2 ~radius:rad (cx, cy)
      | Group scs ->
        List.iter (aux t_x t_y (r, g, b)) scs
      | Color (c, sc) ->
        aux t_x t_y c sc
      | Translate (dx, dy, sc) ->
        aux (t_x +. dx) (t_y +. dy) (r, g, b) sc
    in
    aux 0. 0. (255, 255, 255) sc

  let blue = (0, 0, 255)
  let black = (0, 0, 0)
  let red = (255, 0, 0)

  let clamp_int ~lo ~hi x = max lo (min hi x)

  let wall_thickness = 20
  let paddle_w = 70
  let paddle_h = 10

  let walls =
    liftB2 (fun w h -> Color (blue, Group
      [Rect (0, 0, 20, h-1); Rect (0, h-21, w-1, 20);
       Rect (w-21, 0, 20, h-1)]))
      width height

  let paddle_x : int behavior =
    liftB2 (fun mx w ->
      let lo = wall_thickness in
      let hi = max lo (w - 21 - paddle_w) in
      clamp_int ~lo ~hi (mx - (paddle_w / 2)))
      mouse_x width

  let paddle : scene behavior =
    liftB (fun px -> Color (black, Rect (px, 0, paddle_w, paddle_h))) paddle_x

  (* Ball with bouncing - tying the knot with memo1 records.

     The mutual recursion between xvel, xpos, and xbounce requires care.
     If we naively wrote mutually recursive *functions* that call each other,
     we would get an infinite loop at definition time (before any stream is
     consumed). The trick is to define the recursion at the *memo1 record*
     level: we use `let rec ... and ...` to create mutually recursive records
     where each record's memo_f field references the other records by name.
     The actual computation is deferred until `$ uts` is applied. *)
  let ball : scene behavior =
    let wall_margin = 27 in
    let vel = 100.0 in
    (* Horizontal motion with bouncing *)
    let rec xvel_ uts = step_accum vel (xbounce ->> (~-.)) $ uts
    and xvel = {memo_f = xvel_; memo_r = None}
    and xpos_ uts = (liftB int_of_float (integral xvel) +* width /* !*2) $ uts
    and xpos = {memo_f = xpos_; memo_r = None}
    and xbounce_ uts =
      whenB ((xpos >* width -* !*wall_margin) ||* (xpos <* !*wall_margin)) $ uts
    and xbounce = {memo_f = xbounce_; memo_r = None} in
    (* Vertical motion with bouncing *)
    let rec yvel_ uts = step_accum vel (ybounce ->> (~-.)) $ uts
    and yvel = {memo_f = yvel_; memo_r = None}
    and ypos_ uts = (liftB int_of_float (integral yvel) +* height /* !*2) $ uts
    and ypos = {memo_f = ypos_; memo_r = None}
    and ybounce_ uts =
      whenB ((ypos >* height -* !*wall_margin) ||* (ypos <* !*wall_margin)) $ uts
    and ybounce = {memo_f = ybounce_; memo_r = None} in
    liftB2 (fun x y -> Color (red, Circle (x, y, 7))) xpos ypos

  let game : scene behavior =
    liftB3 (fun w p b -> Group [w; p; b]) walls paddle ball

  let demo () =
    print_endline "=== Stream FRP Paddle Game ===";
    print_endline "Starting Bogue GUI... Move mouse to control paddle.";
    print_endline "Close the window to exit.";
    let open Bogue in
    let w, h = 640, 512 in
    let area_widget = Widget.sdl_area ~w ~h () in
    let area = Widget.get_sdl_area area_widget in
    (* Build the input stream *forwards* (append-only) so behaviors can
       integrate over time. We then consume the resulting scene stream one
       step at a time. *)
    let mk_node (x : user_action option * time) :
      (user_action option * time) stream * (user_action option * time) stream ref =
      let next_ref : (user_action option * time) stream ref = ref (lazy (assert false)) in
      let tail : (user_action option * time) stream = lazy (Lazy.force !next_ref) in
      (lazy (Cons (x, tail)), next_ref)
    in
    let t0 = Unix.gettimeofday () in
    let uts0, hole0 = mk_node (Some (Resize (w, h)), t0) in
    let hole : (user_action option * time) stream ref ref = ref hole0 in
    let pending = ref 0 in
    let last_time = ref t0 in

    let append_input (x : user_action option * time) =
      let node, next = mk_node x in
      (!hole) := node;
      hole := next;
      incr pending
    in

    let advance_time_to (t : time) =
      if t <= !last_time then ()
      else begin
        let max_step = 1.0 /. 240.0 in
        let max_catchup = 0.25 in
        let target = min t (!last_time +. max_catchup) in
        while !last_time +. 1e-9 < target do
          let dt = min max_step (target -. !last_time) in
          last_time := !last_time +. dt;
          append_input (None, !last_time)
        done
      end
    in

    let scene_stream = game $ uts0 in
    let current_scene : scene ref =
      let Cons (sc0, rest0) = Lazy.force scene_stream in
      let scene_cursor : scene stream ref = ref rest0 in
      let r = ref sc0 in

      Sdl_area.add area (fun _renderer ->
        Sdl_area.fill_rectangle area ~color:(Draw.opaque Draw.grey)
          ~w ~h (0, 0);
        while !pending > 0 do
          decr pending;
          let Cons (sc, rest) = Lazy.force !scene_cursor in
          r := sc;
          scene_cursor := rest
        done;
        draw area ~h !r);

      r
    in
    ignore current_scene;

    let layout = Layout.resident area_widget in

    let action _w _l ev =
      let mx, my = Mouse.pointer_pos ev in
      let t = Unix.gettimeofday () in
      advance_time_to t;
      append_input (Some (MouseMove (mx, my)), !last_time);
      Sdl_area.update area
    in
    let connection = Widget.connect area_widget area_widget action Trigger.pointer_motion in
    Widget.add_connection area_widget connection;

    (* Animation tick: reschedule itself every ~16ms. *)
    let rec tick () =
      advance_time_to (Unix.gettimeofday ());
      Sdl_area.update area;
      Widget.update area_widget;
      Timeout.add_ignore 16 tick
    in
    Timeout.add_ignore 16 tick;

    let board = Main.of_layout layout in
    Main.run board
end

(* ========== 10.7 Effects-Based Reactivity ========== *)

module EffectsDemo = struct
  type user_action =
    | Key of char * bool
    | Button of int * int * bool * bool
    | MouseMove of int * int
    | Resize of int * int

  type _ Effect.t +=
    | Await : (user_action -> 'a option) -> 'a Effect.t
    | Emit : string -> unit Effect.t

  let await p = Effect.perform (Await p)
  let emit (s : string) = Effect.perform (Emit s)

  let await_either p q =
    await (fun u ->
      match p u with
      | Some a -> Some (`A a)
      | None ->
        match q u with
        | Some b -> Some (`B b)
        | None -> None)

  type 'a paused =
    | Done of 'a
    | Awaiting of {feed : user_action -> 'a paused}

  let step ~(on_emit : string -> unit) (th : unit -> 'a) : 'a paused =
    Effect.Deep.match_with th () {
      retc = (fun v -> Done v);
      exnc = raise;
      effc = fun (type c) (eff : c Effect.t) ->
        match eff with
        | Emit x ->
          Some (fun (k : (c, _) Effect.Deep.continuation) ->
            on_emit x;
            Effect.Deep.continue k ())
        | Await p ->
          Some (fun (k : (c, _) Effect.Deep.continuation) ->
            let rec feed (u : user_action) =
              match p u with
              | None -> Awaiting {feed}
              | Some v -> Effect.Deep.continue k v
            in
            Awaiting {feed})
        | _ -> None
    }

  let run_script ~(inputs : user_action list) ~(on_emit : string -> unit) (f : unit -> 'a) : 'a =
    let rec drive (st : 'a paused) (inputs : user_action list) : 'a =
      match st with
      | Done a -> a
      | Awaiting {feed} ->
        (match inputs with
         | [] -> failwith "run_script: no more inputs"
         | u :: us -> drive (feed u) us)
    in
    drive (step ~on_emit f) inputs

  let is_down = function
    | Button (x, y, true, _) -> Some (x, y)
    | _ -> None

  let is_move = function
    | MouseMove (x, y) -> Some (x, y)
    | _ -> None

  let is_up = function
    | Button (_, _, false, _) -> Some ()
    | _ -> None

  let rec drag_loop acc =
    match await_either is_move is_up with
    | `A p ->
      let acc = p :: acc in
      emit (Printf.sprintf "polyline points=%d" (List.length acc));
      drag_loop acc
    | `B () ->
      List.rev acc

  let paint_once () =
    let start = await is_down in
    emit "start";
    let path = drag_loop [start] in
    emit (Printf.sprintf "done, points=%d" (List.length path));
    path

  let demo () =
    print_endline "=== Effects-Based Reactivity Demo ===";
    print_endline "Simulating a click-and-drag interaction:";

    let inputs = [
      Button (100, 100, true, false);   (* Mouse down at (100, 100) *)
      MouseMove (110, 105);
      MouseMove (120, 110);
      MouseMove (130, 120);
      Button (130, 120, false, false);  (* Mouse up *)
    ] in

    let path = run_script ~inputs ~on_emit:print_endline paint_once in
    print_endline "\nFinal path:";
    List.iter (fun (x, y) -> Printf.printf "  (%d, %d)\n" x y) path
end

(* ========== Main ========== *)

let print_usage () =
  print_endline "Chapter 10: Functional Reactive Programming -- Examples";
  print_endline "";
  print_endline "Usage: chapter10 <example>";
  print_endline "";
  print_endline "Available examples:";
  print_endline "  zipper  - Binary tree zipper navigation demo";
  print_endline "  expr    - Expression rewriting (pull out subexpression)";
  print_endline "  lwd     - Lwd incremental computing demo";
  print_endline "  incr    - Jane Street Incremental demo";
  print_endline "  paddle  - Lwd paddle game (requires GUI/Bogue)";
  print_endline "  stream  - Stream FRP paddle game (requires GUI/Bogue)";
  print_endline "  effects - Effects-based click-and-drag demo";
  print_endline "";
  print_endline "Run 'dune exec chapter10/chapter10.exe <example>' to try one."

let () =
  match Sys.argv with
  | [| _ |] -> print_usage ()
  | [| _; "zipper" |] -> Zipper.demo ()
  | [| _; "expr" |] -> ExprRewrite.demo ()
  | [| _; "lwd" |] -> LwdDemo.demo ()
  | [| _; "incr" |] -> IncrDemo.demo ()
  | [| _; "paddle" |] -> LwdPaddle.demo ()
  | [| _; "stream" |] -> StreamFRP.demo ()
  | [| _; "effects" |] -> EffectsDemo.demo ()
  | [| _; "all" |] ->
    Zipper.demo ();
    print_endline "";
    ExprRewrite.demo ();
    print_endline "";
    LwdDemo.demo ();
    print_endline "";
    IncrDemo.demo ();
    print_endline "";
    EffectsDemo.demo ();
    print_endline "";
    print_endline "(Skipping paddle and stream GUIs in 'all' mode)"
  | _ ->
    print_endline "Unknown example.";
    print_usage ();
    exit 1
