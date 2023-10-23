let x = 1
let y = 2

let x = y
and y = x
and z = ...
;;

let rec x () = y ()
and y () = x ()
;;



module type FIFO = sig
  type 'a t
  val put : 'a -> 'a t -> 'a t
  val pop : 'a t -> 'a t
  val top : 'a t -> 'a
  val is_empty : 'a t -> bool
  val empty : 'a t
end

module FifoSimple : FIFO = struct
end

module FifoEfficient : FIFO = struct
  type 'a t = {front : 'a list; back : 'a list}
    
end



let ( |- ) f g x = g (f x)
let ( -| ) f g x = f (g x)

let bfs t =
  let rec aux q = function
    | Empty -> []
    | Node (e, l, r) ->
      e ::
        aux ((pop -| put a -| put b) q) (top q) in
  aux () t
