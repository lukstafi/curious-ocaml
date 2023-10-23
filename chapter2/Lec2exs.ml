(* Exercise 1. *)
type connection_state =
  | Connecting
  | Connected
  | Disconnected

type connection_info = {
  state : connection_state;
  server : Inet_addr.t;
  last_ping_time : Time.t option;
  last_ping_id : int option;
  session_id : string option;
  when_initiated : Time.t option;
  when_disconnected : Time.t option;
}

(* Exercise 2. *)
let f ~meaningful_name:n = n+1
let _ = f ~meaningful_name:5

let g ~pos ~len =
  StringLabels.sub "0123456789abcdefghijklmnopqrstuvwxyz" ~pos ~len
let () =
  let pos = Random.int 26 in
  let len = Random.int 10 in
  print_endline (g ~pos ~len)

let h ?(len=1) pos = g ~pos ~len
let () = print_endline (h ~len:3 10)

let foo ?bar n =
  match bar with
    | None -> "Argument = " ^ string_of_int n
    | Some m -> "Sum = " ^ string_of_int (m + n)
;;
foo 5;;
foo ~bar:5 7;;

let bar=3 in foo ~bar 7;;

let bar = if Random.int 10 < 5 then None else Some 7 in
foo ?bar 7;;

let draw_rect ?left ?right ?size .....
