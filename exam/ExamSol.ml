(int -> int) -> int

(('a ->'a ) ->'a)  
  'a ->'a -> (('a -> 'a) -> 'a)
;;

'a list -> 'a list list


('a list -> 'a list list)
;;

5,

[[1,2,3],[2,3]];

e3a  fun f -> f(1)<1;
e3b  fun l -> match l with None -> [];

let rec helper l1 = 
  match l with 
    | [] -> []
    | x::xs -> helper xs
  let rec drop2 l = 
    match l with
      |[] -> []
      |x :: xs ->  x ::  drop2 xs  
