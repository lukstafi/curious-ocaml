(* Download "froc" from https://github.com/jaked/froc/downloads *)
(* cd froc-0.2a; ./configure; make all; sudo make install *)
(* *
#directory "+froc";;
#load "froc.cma";;
#directory "+lablgtk";;
#load "lablgtk.cma";;
#load "dynlink.cma";;
#directory "+camlp4";;
#load "camlp4o.cma";;
#load "monad/pa_monad.cmo";;   
* *)

(* ******************** Model ******************** *)

module F = Froc
open Flow
let () = F.init ()

let sk x y = y

let digits, digit = F.make_event ()
let ops, op = F.make_event ()
let dots, dot = F.make_event ()

let calc =
  let f = ref (fun x -> x) and now = ref 0.0 in
  repeat (perform
      op <-- repeat
        (perform
            d <-- await digits;
            emit (now := 10. *. !now +. d; !now))
        ~until:ops;
      emit (now := !f !now; f := op !now; !now);
      d <-- repeat
        (perform op <-- await ops; return (f := op !now))
        ~until:digits;
      emit (now := d; !now))

let calc_e, cancel_calc = event_flow calc

(* ********************* GUI ********************* *)

let _ = GtkMain.Main.init ()
let window =
  GWindow.window ~width:200 ~height:200 ~title:"Calculator" ()
let top = GPack.vbox ~packing:window#add ()
let result = GMisc.label ~text:"0" ~packing:top#add ()
let layout =
  [|[|"7", `Di 7.; "8", `Di 8.; "9", `Di 9.; "+", `O (+.)|];
    [|"4", `Di 4.; "5", `Di 5.; "6", `Di 6.; "-", `O (-.)|];
    [|"1", `Di 1.; "2", `Di 2.; "3", `Di 3.; "*", `O ( *.)|];
    [|"0", `Di 0.; ".", `Dot;   "=",  `O sk; "/", `O (/.)|]|]
let btn_frame =
  GPack.table ~rows:(Array.length layout)
    ~columns:(Array.length layout.(0)) ~packing:top#add ()
let buttons =
  Array.map (Array.map (function
  | label, `Dot ->
    let b = GButton.button ~label () in
    let _ = b#connect#clicked
      ~callback:(fun () -> F.send dot ()) in b
  | label, `Di d ->
    let b = GButton.button ~label () in
    let _ = b#connect#clicked
      ~callback:(fun () -> F.send digit d) in b
  | label, `O f ->
    let b = GButton.button ~label () in
    let _ = b#connect#clicked
      ~callback:(fun () -> F.send op f) in b)) layout

let delete_event _ = GMain.Main.quit (); false
let () =
  let _ = window#event#connect#delete ~callback:delete_event in
  Array.iteri (fun column -> Array.iteri (fun row button ->
    btn_frame#attach ~left:column ~top:row
      ~fill:`BOTH ~expand:`BOTH (button#coerce))
  ) buttons;
  F.notify_e calc_e
    (fun now -> result#set_label (string_of_float now));
  window#show ();
  GMain.Main.main ()
