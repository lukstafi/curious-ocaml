(* Download "froc" from https://github.com/jaked/froc/downloads *)
(* cd froc-0.2a; ./configure; make all; sudo make install *)
(* *
#directory "+froc";;
#load "froc.cma";;
#directory "+labltk";;
#load "labltk.cma";;
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

let layout =
  [|[|"7", `Di 7.; "8", `Di 8.; "9", `Di 9.; "+", `O (+.)|];
    [|"4", `Di 4.; "5", `Di 5.; "6", `Di 6.; "-", `O (-.)|];
    [|"1", `Di 1.; "2", `Di 2.; "3", `Di 3.; "*", `O ( *.)|];
    [|"0", `Di 0.; ".", `Dot;   "=",  `O sk; "/", `O (/.)|]|]

let top = Tk.openTk ()
let btn_frame =
  Frame.create ~relief:`Groove ~borderwidth:2 top
let buttons =
  Array.map (Array.map (function
  | text, `Dot ->
    Button.create ~text
      ~command:(fun () -> F.send dot ()) btn_frame
  | text, `Di d ->
    Button.create ~text
      ~command:(fun () -> F.send digit d) btn_frame
  | text, `O f ->
    Button.create ~text
      ~command:(fun () -> F.send op f) btn_frame)) layout
let result = Label.create ~text:"0" ~relief:`Sunken top

let () =
  Wm.title_set top "Calculator";
  Tk.pack [result] ~side:`Top ~fill:`X;
  Tk.pack [btn_frame] ~side:`Bottom ~expand:true;
  Array.iteri (fun column -> Array.iteri (fun row button ->
    Tk.grid ~column ~row [button])) buttons;
  Wm.geometry_set top "200x200";
  F.notify_e calc_e
    (fun now -> Label.configure ~text:(string_of_float now) result);
  Tk.mainLoop ()
