(* Download "froc" from https://github.com/jaked/froc/downloads *)
(* cd froc-0.2a; ./configure; make all; sudo make install *)
(* *
#directory "+froc";;
#load "froc.cma";;
#load "unix.cma";;
#load "graphics.cma";;
#directory "+threads";;
#load "threads.cma";;
* *)

open Froc
let () = init ()

let clock, tick = make_event ()
let time = hold (Unix.gettimeofday ()) clock

let integral fb =
  let aux (sum, t0) t1 =
    sum +. (t1 -. t0) *. sample fb, t1 in
  collect_b aux (0., sample time) clock

let pair fa fb = lift2 (fun x y -> x, y) fa fb
let integral_nice fb =
  let samples = changes (pair fb time) in
  let aux (sum, t0) (fv, t1) =
    sum +. (t1 -. t0) *. fv, t1 in
  collect_b aux (0., sample time) samples

let integ_res fb =
  lift (fun (v,_) -> int_of_float v) (integral fb)

type scene =
| Rect of int * int * int * int
| Circle of int * int * int
| Group of scene list
| Color of Graphics.color * scene
| Translate of float * float * scene

let translate (bx : float behavior) (by : float behavior)
    (br : scene behavior) : scene behavior =
  lift3 (fun tx ty -> function
  | Translate (x, y, r) -> Translate (x+.tx, y+.ty, r)
  | r -> Translate (tx, ty, r)) bx by br

let draw sc =
  let f2i = int_of_float in
  let open Graphics in
  let rec aux t_x t_y = function
  | Rect (x, y, w, h) ->
    fill_rect (f2i t_x+x) (f2i t_y+y) w h
  | Circle (x, y, r) ->
    fill_circle (f2i t_x+x) (f2i t_y+y) r
  | Group scs ->
    List.iter (aux t_x t_y) scs
  | Color (c, sc) -> set_color c; aux t_x t_y sc
  | Translate (x, y, sc) -> aux (t_x+.x) (t_y+.y) sc in
  clear_graph ();
  aux 0. 0. sc;
  synchronize ()

let mouse_move_x, move_mouse_x = make_event ()
let mouse_move_y, move_mouse_y = make_event ()
let mouse_x = hold 0 mouse_move_x
let mouse_y = hold 0 mouse_move_x
let width_resized, resize_width = make_event ()
let height_resized, resize_height = make_event ()
let width = hold 640 width_resized
let height = hold 512 height_resized
let mbutton_pressed, press_mbutton = make_event ()
let key_pressed, press_key = make_event ()

let reactimate (anim : scene behavior) =
  let open Graphics in
  let rec loop omx omy osx osy omb t0 =
    let rec delay () =
      let t1 = Unix.gettimeofday () in
      let d = 0.01 -. (t1 -. t0) in
      try if d > 0. then Thread.delay d;
          Unix.gettimeofday ()
      with Unix.Unix_error ((* Unix.EAGAIN *)_, _, _) -> delay () in
    let t1 = delay () in
    let s = Graphics.wait_next_event [Poll] in
    let x = s.mouse_x and y = s.mouse_y
    and scr_x = Graphics.size_x () and scr_y = Graphics.size_y () in
    if s.keypressed then send press_key s.key;
    if scr_x <> osx then send resize_width scr_x;
    if scr_y <> osy then send resize_height scr_y;
    if s.button && not omb then send press_mbutton ();
    if x <> omx then send move_mouse_x x;
    if y <> omy then send move_mouse_y y;
    send tick t1;
    draw (sample anim);
    loop x y scr_x scr_y s.button t1 in
  open_graph "";
  display_mode false;
  loop 0 0 640 512 false (Unix.gettimeofday ());
  close_graph ()

let (+*) = lift2 (+)
let (-*) = lift2 (-)
let ( *** ) = lift2 ( * )
let (/*) = lift2 (/)
let (&&*) = lift2 (&&)
let (||*) = lift2 (||)
let (<*) a b = lift2 (<) a b
let (>*) a b = lift2 (>) a b
let (!*) b = return b

(* The Paddleball game. *)
let walls =
  lift2 (fun w h -> Color (Graphics.blue, Group
    [Rect (0, 0, 20, h-1); Rect (0, h-21, w-1, 20);
     Rect (w-21, 0, 20, h-1)]))
    width height
let paddle = lift (fun mx ->
  Color (Graphics.black, Rect (mx, 0, 50, 10))) mouse_x

let pbal vel =
  let xbounce, bounce_x = make_event () in
  let ybounce, bounce_y = make_event () in
  let xvel = collect_b (fun v _ -> ~-.v) vel xbounce in
  let yvel = collect_b (fun v _ -> ~-.v) vel ybounce in
  let xpos = integ_res xvel +* width /* !*2 in
  let ypos = integ_res yvel +* height /* !*2 in
  let xbounce_ = when_true
    ((xpos >* width -* !*27) ||* (xpos <* !*27)) in
  notify_e xbounce_ (send bounce_x);
  let ybounce_ = when_true (
    (ypos >* height -* !*27) ||*
      ((ypos <* !*17) &&* (ypos >* !*7) &&*
          (xpos >* mouse_x) &&* (xpos <* mouse_x +* !*50))) in
  notify_e ybounce_ (send bounce_y);
  lift4 (fun x y _ _ -> Color (Graphics.red, Circle (x, y, 6)))
    xpos ypos (hold () xbounce_) (hold () ybounce_)

let game = lift3 (fun walls paddle ball ->
  Group [walls; paddle; ball]) walls paddle (pbal 100.)

let () = reactimate game

