module type MAP = sig
  type ('a, 'b) map
  val empty : ('a, 'b) map
  val isEmpty : ('a, 'b) map -> bool
  val member : 'a -> ('a,'b)map -> ('a,'b)map
  val add : 'a -> 'b ->  ('a, 'b) map -> ('a,'b)map
  val remove : 'a ->  ('a, 'b) map -> ('a,'b)map
  val find : 'a -> ('a, 'b) map -> 'b
end

let rec remove_assoc x = function
  | [] -> []
  | (a,b as pair) :: l ->
    if a = x then remove_assoc x l
    else pair::remove_assoc x l
;;

