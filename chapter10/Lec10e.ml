(* Download "froc" from https://github.com/jaked/froc/downloads *)
(* cd froc-0.2a; ./configure; make all; sudo make install *)
(* *
#directory "+froc";;
#load "froc.cma";;
#load "dynlink.cma";;
#directory "+camlp4";;
#load "camlp4o.cma";;
#load "monad/pa_monad.cmo";;   
* *)

module F = Froc
open Flow
let () = F.init ()

let aas, a = F.make_event ()
let () =
  F.notify_e aas (fun c -> Printf.printf "event: a\n%!")
let bs, b = F.make_event ()
let () =
  F.notify_e bs (fun c -> Printf.printf "event: b\n%!")
let cs, c = F.make_event ()
let () =
  F.notify_e cs (fun c -> Printf.printf "event: c\n%!")
let ds, d = F.make_event ()
let () =
  F.notify_e ds (fun c -> Printf.printf "event: d\n%!")

let f =
  repeat (perform
      emit (Printf.printf "[0]\n%!"; '0');
      () <-- await aas;
      emit (Printf.printf "[1]\n%!"; '1');
      () <-- await bs;
      emit (Printf.printf "[2]\n%!"; '2');
      () <-- await cs;
      emit (Printf.printf "[3]\n%!"; '3');
      () <-- await ds;
      emit (Printf.printf "[4]\n%!"; '4'))
let e, cancel_e = event_flow f
let () =
  F.notify_e e (fun c -> Printf.printf "flow: %c\n%!" c);
  Printf.printf "notification installed\n%!"
let () =
  F.send a (); F.send b (); F.send c (); F.send d ();
  F.send a (); F.send b (); F.send c (); F.send d ()

(* 

[0]
notification installed
event: a
[1]
flow: 1
event: b
[2]
flow: 2
event: c
[3]
flow: 3
event: d
[4]
flow: 4
flow: 0
event: a
[1]
flow: 1
event: b
[2]
flow: 2
event: c
[3]
flow: 3
event: d
[4]
flow: 4
flow: 0

 *)
