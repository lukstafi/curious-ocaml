(* Download "froc" from https://github.com/jaked/froc/downloads *)
(* cd froc-0.2a; ./configure; make all; sudo make install *)
(* *
#directory "+froc";;
#load "froc.cma";;
#load "graphics.cma";;
#load "dynlink.cma";;
#directory "+camlp4";;
#load "camlp4o.cma";;
#load "monad/pa_monad.cmo";;   
* *)

module F = Froc
open Flow
let () = F.init ()

let ( -| ) f g x = f (g x)

type scene = (int * int) list list

let draw sc =
  let open Graphics in
  clear_graph ();
  (match sc with
  | [] -> ()
  | opn::cld ->
    draw_poly_line (Array.of_list opn);
    List.iter (fill_poly -| Array.of_list) cld);
  synchronize ()

let mouse_move, move_mouse = F.make_event ()
let mouse = F.hold (0, 0) mouse_move
let mbutton_pressed, press_mbutton = F.make_event ()
let mbutton_released, release_mbutton = F.make_event ()
let key_pressed, press_key = F.make_event ()

let reactimate (anim : scene F.behavior) =
  let open Graphics in
  let rec loop omouse omb =
    let s = wait_next_event
      [Button_down; Button_up; Key_pressed; Mouse_motion] in
    let mouse = s.mouse_x, s.mouse_y in
    if s.keypressed then F.send press_key s.key;
    if s.button && not omb then F.send press_mbutton ();
    if omb && not s.button then F.send release_mbutton ();
    if mouse <> omouse then F.send move_mouse mouse;
    draw (F.sample anim);
    loop mouse s.button in
  open_graph "";
  display_mode false;
  loop (0, 0) false;
  close_graph ()

let painter =
  let cld = ref [] in
  repeat (perform
      await mbutton_pressed;
      let opn = ref [] in
      repeat (perform
          mpos <-- await mouse_move;
          emit (opn := mpos :: !opn; !opn :: !cld))
        ~until:mbutton_released;
      emit (cld := !opn :: !cld; opn := []; [] :: !cld))
let painter, cancel_painter = behavior_flow [] painter
let () = reactimate painter
