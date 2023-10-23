(* Exercise 1. *)
type connecting = { when_initiated : Time.t }
type connected = {
  last_ping : (Time.t * int) option;
  session_id : string;
}
type disconnected = { when_disconnected : Time.t }
    
type connection_state =
  | Connecting of connecting
  | Connected of connected
  | Disconnected of disconnected

type connection_info = {
  state : connection_state;
  server : Inet_addr.t;
}

(* Exercise 2. *)

let baz ?x f = f ?x ()
