(* *************** Functional Reactive Programming *************** *)
(* ***************** Stream Processing approach ****************** *)

type 'a stream = 'a stream_ Lazy.t
and 'a stream_ = Cons of 'a * 'a stream
let rec lmap f l = lazy (
  let Cons (x, xs) = Lazy.force l in
  Cons (f x, lmap f xs))
let rec liter (f : 'a -> unit) (l : 'a stream) : unit =
  let Cons (x, xs) = Lazy.force l in
  f x; liter f xs
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
(*let rec ltails l = lazy (
  let Cons (_, tl) = Lazy.force l in
  Cons (l, ltails tl))*)

type time = float
(*type 'a behavior = time -> 'a
type 'a event = ('a, time) stream*)

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

type user_action =
| Key of char
| Button of int * int
| MouseMove of int * int
| Resize of int * int
(*type 'a behavior = user_action event -> time -> 'a
type 'a behavior =
  user_action event -> time stream -> 'a stream*)
type 'a behavior =
  ((user_action option * time) stream, 'a stream) memo1
type 'a event = 'a option behavior

let returnB x : 'a behavior =
  let rec xs = lazy (Cons (x, xs)) in
  memo1 (fun _ -> xs)
let ( !* ) = returnB
(*let bindB (m : 'a behavior) (f : 'a -> 'b behavior) : 'b behavior =
  memo1 (fun uts -> lmap2
    (fun uts x ->
      let Cons (y, _) = Lazy.force (f x $ uts) in y)
    (ltails uts) (m $ uts))*)

let liftB f (fb : 'a behavior) : 'b behavior =
  memo1 (fun uts -> lmap f (fb $ uts))

let liftB2 f fb1 fb2 : 'b behavior =
  memo1 (fun uts -> lmap2 f (fb1 $ uts) (fb2 $ uts))

let liftB3 f (fb1 : 'a behavior) (fb2 : 'b behavior)
    (fb3 : 'c behavior) : 'd behavior =
  memo1 (fun uts -> lmap3 f (fb1 $ uts) (fb2 $ uts) (fb3 $ uts))


(*type 'a behavior = time -> 'a
val return : 'a -> 'a behavior
let return a = fun _ -> a
val bind :
  'a behavior -> ('a -> 'b behavior) -> 'b behavior
let bind a f = fun t -> f (a t) t

val ap : ('a -> 'b) monad -> 'a monad -> 'b monad
let ap fm am = perform
  f <-- fm;
  a <-- am;
  return (f a)

'a behavior -> 'a behavior event -> 'a behavior*)
(*
let until (fb : 'a behavior) (fe : 'a behavior event) : 'a behavior =
  let rec loop uts (es : 'a behavior option stream) (bs : 'a stream) =
    let Cons (b, bs) = Lazy.force bs in
    Cons (b, lazy (handle uts es bs))
  and handle uts es bs =
    let Cons (_, uts) = Lazy.force uts in
    match Lazy.force es with
    | Cons (None, es) -> loop uts es bs
    | Cons (Some fb, es) -> Lazy.force (fb $ uts) in
  memo1 (fun uts -> lazy (loop uts (fe $ uts) (fb $ uts)))

let switch (fb : 'a behavior) (fe : 'a behavior event) : 'a behavior =
  let rec loop uts (es : 'a behavior option stream) (bs : 'a stream) =
    let Cons (b, bs) = Lazy.force bs in
    Cons (b, lazy (handle uts es bs))
  and handle uts es bs =
    let Cons (_, uts) = Lazy.force uts in
    match Lazy.force es with
    | Cons (None, es) -> loop uts es bs
    | Cons (Some fb, es) -> loop uts es (fb $ uts) in
  memo1 (fun uts -> lazy (loop uts (fe $ uts) (fb $ uts)))
*)
  
let liftE f (fe : 'a event) : 'b event =
  memo1 (fun uts ->
    lmap (function Some e -> Some (f e) | None -> None)
      (fe $ uts))
let (=>>) fe f = liftE f fe
let (->>) e v = e =>> fun _ -> v

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

let snapshot (fe : 'a event) (fb : 'b behavior) : ('a * 'b) event =
  memo1 (fun uts ->
    lmap2 (fun x -> function Some y -> Some (y,x) | None -> None)
      (fb $ uts) (fe $ uts))

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
    let Cons ((_,t1), uts) = Lazy.force uts in
    let Cons (b, bs) = Lazy.force bs in
    let acc = acc +. (t1 -. t0) *. b in
    Cons (acc, lazy (loop t1 acc uts bs)) in
  memo1 (fun uts -> lazy (
    let Cons ((_,t), uts') = Lazy.force uts in
    Cons (0., lazy (loop t 0. uts' (fb $ uts)))))

let lbp : unit event =
  memo1 (fun uts -> lmap
    (function Some (Button (_,_)), _ -> Some () | _ -> None)
    uts)
let mm : (int * int) event =
  memo1 (fun uts -> lmap
    (function Some (MouseMove (x,y)),_ -> Some (x,y) | _ -> None)
    uts)
let screen : (int * int) event =
  memo1 (fun uts -> lmap
    (function Some (Resize (x,y)),_ -> Some (x,y) | _ -> None)
    uts)
let mouse_x : int behavior = step 0 (liftE fst mm)
let mouse_y : int behavior = step 0 (liftE snd mm)
let width : int behavior = step 640 (liftE fst screen)
let height : int behavior = step 512 (liftE snd screen)


type scene =
| Rect of int * int * int * int
| Circle of int * int * int
| Group of scene list
| Color of Graphics.color * scene
| Translate of float * float * scene

let translate (bx : float behavior) (by : float behavior)
    (br : scene behavior) : scene behavior =
  liftB3 (fun tx ty -> function
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

let reactimate (anim : scene behavior) =
  let open Graphics in
  let not_b = function Some (Button (_,_)) -> false | _ -> true in
  let current old_m old_scr (old_u, t0) =
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
    let ue =
      if s.keypressed then Some (Key s.key)
      else if (scr_x, scr_y) <> old_scr then Some (Resize (scr_x, scr_y))
      else if s.button && not_b old_u then Some (Button (x, y))
      else if (x, y) <> old_m then Some (MouseMove (x, y))
      else None in
    (x, y), (scr_x, scr_y), (ue, t1) in
  open_graph "";
  display_mode false;
  let t0 = Unix.gettimeofday () in
  let rec utstep mpos scr ut = lazy (
    let mpos, scr, ut = current mpos scr ut in
    Cons (ut, utstep mpos scr ut)) in
  let scr = Graphics.size_x (), Graphics.size_y () in
  let ut0 = Some (Resize (fst scr, snd scr)), t0 in
  liter draw (anim $ lazy (Cons (ut0, utstep (0,0) scr ut0)));
  close_graph ()

let (+*) = liftB2 (+)
let (-*) = liftB2 (-)
let ( *** ) = liftB2 ( * )
let (/*) = liftB2 (/)
let (&&*) = liftB2 (&&)
let (||*) = liftB2 (||)
let (<*) = liftB2 (<)
let (>*) = liftB2 (>)

(* The Paddleball game. *)
let walls =
  liftB2 (fun w h -> Color (Graphics.blue, Group
    [Rect (0, 0, 20, h-1); Rect (0, h-21, w-1, 20);
     Rect (w-21, 0, 20, h-1)]))
    width height
let paddle = liftB (fun mx ->
  Color (Graphics.black, Rect (mx, 0, 50, 10))) mouse_x
let pbal vel =
  let rec xvel_ uts =
    step_accum vel (xbounce ->> (~-.)) $ uts
  and xvel = {memo_f = xvel_; memo_r = None}
  and xpos_ uts =
    (liftB int_of_float (integral xvel) +* width /* !*2) $ uts
  and xpos = {memo_f = xpos_; memo_r = None}
  and xbounce_ uts = whenB
    ((xpos >* width -* !*27) ||* (xpos <* !*27)) $ uts
  and xbounce = {memo_f = xbounce_; memo_r = None} in
  let rec yvel_ uts =
    (step_accum vel (ybounce ->> (~-.))) $ uts
  and yvel = {memo_f = yvel_; memo_r = None}
  and ypos_ uts =
    (liftB int_of_float (integral yvel) +* height /* !*2) $ uts
  and ypos = {memo_f = ypos_; memo_r = None}
  and ybounce_ uts = whenB (
    (ypos >* height -* !*27) ||*
      ((ypos <* !*17) &&* (ypos >* !*7) &&*
          (xpos >* mouse_x) &&* (xpos <* mouse_x +* !*50))) $ uts
  and ybounce = {memo_f = ybounce_; memo_r = None} in
  liftB2 (fun x y -> Color (Graphics.red, Circle (x, y, 6)))
    xpos ypos

let game = liftB3 (fun walls paddle ball ->
  Group [walls; paddle; ball]) walls paddle (pbal 100.)

let () = reactimate game
