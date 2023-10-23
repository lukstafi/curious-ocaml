(* Type inference and ADTs. *)

let f = fun l -> List.hd (List.tl l) :: l

let f = List.hd
let x = ref []

let cadr l = List.hd (List.tl l) in cadr (1::2::[]), cadr (true::false::[])

# let f = List.hd;;
val f : 'a list -> 'a

# let x = ref [];;
val x : '_a list ref
  float (int -> int)

let f x = expr x

let f = List.append []
let f l = List.append [] l

(*
# let f = List.append [];;
val f : '_a list -> '_a list = <fun>
# let f l = List.append [] l;;
val f : 'a list -> 'a list = <fun>
*)
type 'a my_list = Empty | Cons of 'a * 'a my_list

let tail l =
  match l with
    | Empty -> invalid_arg "tail"
    | Cons (_, tl) -> tl
(*
# let tail l =
  match l with
    | Empty -> invalid_arg "tail"
    | Cons (_, tl) -> tl;;
      val tail : 'a my_list -> 'a my_list
*)

type ('a, 'b) choice = Left of 'a | Right of 'b
let l = Left 7
let r = Right "a"
;;
[l; r];;
[Left "b"; l; r];;


let get_int c =
  match c with
    | Left i -> i
    | Right b -> if b then 1 else 0

(*
# let get_int c =
  match c with
    | Left i -> i
    | Right b -> if b then 1 else 0;;
      val get_int : (int, bool) choice -> int
*)

(* Polymorphic Recursion *)

(* 1. A list alternating between two types of elements. *)
type ('x, 'o) alterning =
| Stop
| One of 'x * ('o, 'x) alterning

(* If we try:
let rec to_list =
  fun x2a o2a ->
    function
    | Stop -> []
    | One (x, rest) -> x2a x::to_list o2a x2a rest
we get:
val to_list : ('a -> 'b) -> ('a -> 'b) -> ('a, 'a) alterning -> 'b list =
  <fun>
which disallows alternation of different types.
*)

let rec to_list :
    'x 'o 'a. ('x->'a) -> ('o->'a) -> ('x, 'o) alterning -> 'a list =
  fun x2a o2a ->
    function
    | Stop -> []
    | One (x, rest) -> x2a x::to_list o2a x2a rest

let to_choice_list alt = to_list (fun x->Left x) (fun o->Right o) alt

let it = to_choice_list (One (1, One ("o", One (2, One ("oo", Stop)))))

(* 2. Data-Structural Bootstrapping: Binary Random-Access Lists *)

type 'a seq = Nil | Zero of ('a * 'a) seq | One of 'a * ('a * 'a) seq

let example =
  One (0, One ((1,2), Zero (One ((((3,4),(5,6)), ((7,8),(9,10))), Nil))))

let rec cons : 'a. 'a -> 'a seq -> 'a seq =
  fun x -> function
  | Nil -> One (x, Nil)
  | Zero ps -> One (x, ps)
  | One (y, ps) -> Zero (cons (x,y) ps)

let rec lookup : 'a. int -> 'a seq -> 'a =
  fun i s -> match i, s with
  | _, Nil -> raise Not_found
  | 0, One (x, _) -> x
  | i, One (_, ps) -> lookup (i-1) (Zero ps)
  | i, Zero ps ->
    let x, y = lookup (i / 2) ps in
    if i mod 2 = 0 then x else y


type a seq = Nil | Zero of (a * a) seq | One of a * (a * a) seq

let example =
  One (0, One ((1,2), Zero (One ((((3,4),(5,6)), ((7,8),(9,10))), Nil))))

(* If we try:
let rec cons =
  fun x -> function
  | Nil -> One (x, Nil)
  | Zero ps -> One (x, ps)
  | One (y, ps) -> Zero (cons (x,y) ps)
We get:
        Characters 116-121:
    | One (y, ps) -> Zero (cons (x,y) ps);;
                                ^^^^^
Error: This expression has type 'a * 'a
       but an expression was expected of type 'a
*)

let rec cons : a. a -> a seq -> a seq =
  fun x -> function
  | Nil -> One (x, Nil)
  | Zero ps -> One (x, ps)
  | One (y, ps) -> Zero (cons (x,y) ps)

let rec lookup : a. int -> a seq -> a =
  fun i s -> match i, s with
  | _, Nil -> raise Not_found
  | 0, One (x, _) -> x
  | i, One (_, ps) -> lookup (i-1) (Zero ps)
  | i, Zero ps ->
    let x, y = lookup (i / 2) ps in
    if i mod 2 = 0 then x else y

(* Abstract Data Structures *)

module StrMap = Map.Make (String)

module type MAP = sig
  type ('a, 'b) t
  val empty : ('a, 'b) t
  val member : 'a -> ('a, 'b) t -> bool
  val add : 'a -> 'b -> ('a, 'b) t -> ('a, 'b) t
  val remove : 'a -> ('a, 'b) t -> ('a, 'b) t
  val find : 'a -> ('a, 'b) t -> 'b
end

module ListMap : MAP = struct
  type ('a, 'b) t = ('a * 'b) list
  let empty = []
  let member = List.mem_assoc
  let add k v m = Add(k, v, m)
  let remove = List.remove_assoc
  let find = List.assoc
end

module TrivialMap (* : MAP *) = struct
  type ('a, 'b) t =
    | Empty
    | Add of 'a * 'b * ('a, 'b) t
    | Remove of 'a * ('a, 'b) t        
  let empty = Empty
  let rec member k m =
    match m with
      | Empty -> false
      | Add (k2, _, _) when k = k2 -> true
      | Remove (k2, _) when k = k2 -> false
      | Add (_, _, m2) -> member k m2
      | Remove (_, m2) -> member k m2
  let add k v m = Add (k, v, m)
  let remove k m = Remove (k, m)
  let rec find k m =
    match m with
      | Empty -> raise Not_found
      | Add (k2, v, _) when k = k2 -> v
      | Remove (k2, _) when k = k2 -> raise Not_found
      | Add (_, _, m2) -> find k m2
      | Remove (_, m2) -> find k m2
end


module MyListMap : MAP = struct
  type ('a, 'b) t = Empty | Add of 'a * 'b * ('a, 'b) t
  let empty = Empty
  let rec member k m =
    match m with
      | Empty -> false
      | Add (k2, _, _) when k = k2 -> true
      | Add (_, _, m2) -> member k m2
  let rec add k v m =
    match m with
      | Empty -> Add (k, v, Empty)
      | Add (k2, _, m) when k = k2 -> Add (k, v, m)
      | Add (k2, v2, m) -> Add (k2, v2, add k v m)
  let rec remove k m =
    match m with
      | Empty -> Empty
      | Add (k2, _, m) when k = k2 -> m
      | Add (k2, v, m) -> Add (k2, v, remove k m)
  let rec find k m =
    match m with
      | Empty -> raise Not_found
      | Add (k2, v, _) when k = k2 -> v
      | Add (_, _, m2) -> find k m2
end

module BTreeMap : MAP = struct
  type ('a, 'b) t = Empty | T of ('a, 'b) t * 'a * 'b * ('a, 'b) t
  let empty = Empty
  let rec member k m =
    match m with
      | Empty -> false
      | T (_, k2, _, _) when k = k2 -> true
      | T (m1, k2, _, _) when k < k2 -> member k m1
      | T (_, _, _, m2) -> member k m2
  let rec add k v m =
    match m with
      | Empty -> T (Empty, k, v, Empty)
      | T (m1, k2, _, m2) when k = k2 -> T (m1, k, v, m2)
      | T (m1, k2, v2, m2) when k < k2 -> T (add k v m1, k2, v2, m2)
      | T (m1, k2, v2, m2) -> T (m1, k2, v2, add k v m2)
  let rec split_rightmost m =
    match m with
      | Empty -> raise Not_found
      | T (Empty, k, v, Empty) -> k, v, Empty
      | T (m1, k, v, m2) ->
        let rk, rv, rm = split_rightmost m2 in
        rk, rv, T (m1, k, v, rm)
  let rec remove k m =
    match m with
      | Empty -> Empty
      | T (m1, k2, _, Empty) when k = k2 -> m1
      | T (Empty, k2, _, m2) when k = k2 -> m2
      | T (m1, k2, _, m2) when k = k2 ->
        let rk, rv, rm = split_rightmost m2 in
        T (rm, rk, rv, m2)
      | T (m1, k2, v, m2) when k < k2 -> T (remove k m1, k2, v, m2)
      | T (m1, k2, v, m2) -> T (m1, k2, v, remove k m2)
  let rec find k m =
    match m with
      | Empty -> raise Not_found
      | T (_, k2, v, _) when k = k2 -> v
      | T (m1, k2, _, _) when k < k2 -> find k m1
      | T (_, _, _, m2) -> find k m2
end

(* Red-Black tree based sets, without deletion. *)
module RBTree = struct
  type color = R | B
  type 'a t =
    | E
    | T of color * 'a t * 'a * 'a t
  let empty = E
  let rec member x m =
    match m with
      | E -> false
      | T (_, _, y, _) when x = y -> true
      | T (_, a, y, _) when x < y -> member x a
      | T (_, _, _, b) -> member x b
  let balance = function
    | B,T (R,T (R,a,x,b),y,c),z,d
    | B,T (R,a,x,T (R,b,y,c)),z,d
    | B,a,x,T (R,T (R,b,y,c),z,d)
    | B,a,x,T (R,b,y,T (R,c,z,d))
      -> T (R,T (B,a,x,b),y,T (B,c,z,d))
    | color,a,x,b -> T (color,a,x,b)
  let insert x s =
    let rec ins = function
      | E -> T (R,E,x,E)
      | T (color,a,y,b) as s ->
        if x<y then balance (color,ins a,y,b)
        else if x>y then balance (color,a,y,ins b)
        else s in
    match ins s with
    | T (_,a,y,b) -> T (B,a,y,b)
    | E -> failwith "insert: impossible"
end

(* Red-Black tree based maps. Four colors to hanlde deletion. *)
module RBTreeMap : MAP = struct
  type color = R | B | BB | NB
  type ('a, 'b) t =
    | L | BBL
    | T of color * ('a, 'b) t * ('a * 'b) * ('a, 'b) t
  let empty = L
  let blacken = function
    | R -> B
    | B -> BB
    | BB -> failwith "blacken: impossible"
    | NB -> R
  let whiten = function
    | R -> NB
    | B -> R
    | BB -> B
    | NB -> failwith "whiten: impossible"
  let rec member k m =
    match m with
      | BBL -> failwith "member: impossible"
      | L -> false
      | T (_, _, (k2, _), _) when k = k2 -> true
      | T (_, m1, (k2, _), _) when k < k2 -> member k m1
      | T (_, _, _, m2) -> member k m2
  let rec balance = function
    | ((B | BB) as col,T (R,T (R,a,x,b), y, c),z,d)
    | ((B | BB) as col,T (R,a,x,T (R,b,y,c)),z,d)
    | ((B | BB) as col,a,x,T (R,T (R,b,y,c),z,d))
    | ((B | BB) as col,a,x,T (R,b,y,T (R,c,z,d))) ->
      T (whiten col,T (B,a,x,b),y,T (B,c,z,d))

    | (BB,T (NB,T (B,a,w,b),x,T (B,c,y,d)),z,e) ->
      T (B,balance (B,T (R,a,w,b),x,c),y,T (B,d,z,e))
    | (BB,a,x,T (NB,T (B,b,y,c),z,T (B,d,w,e))) ->
      T (B,T (B,a,x,b),y,balance (B,c,z,T (R,d,w,e)))
    | (color,a,x,b) -> T (color,a,x,b)
  let add k v m =
    let rec ins = function
      | BBL -> failwith "add: impossible"
      | L -> T (R,L,(k,v),L)
      | T (c,a,(k2,_),b) when k = k2 -> T (c,a,(k,v),b)
      | T (c,a,(k2,v2),b) when k < k2 -> balance (c,ins a,(k2,v2),b)
      | T (c,a,(k2,v2),b) -> balance (c,a,(k2,v2),ins b) in
    match ins m with
      | L | BBL -> failwith "add: impossible"
      | T (_,a,(k,v),b) -> T (B,a,(k,v),b)
  let bubble = function
    | (c1,T (c2,a,x,b),y,T (c3,c,z,d)) when c1=BB or c2=BB ->
      balance (blacken c1,T (whiten c2,a,x,b),y,T (whiten c3,c,z,d))
    | (c,a,x,b) -> T (c,a,x,b)
  let rec find_max = function
    | BBL -> failwith "find_max: impossible"
    | L -> raise Not_found
    | T (_,_,x,L) -> x
    | T (_,_,_,m) -> find_max m
  let rec delete = function
    | T (R,L,_,L) -> L
    | T (B,L,_,L) -> BBL
    | T (B,T (R,a,p,b),_,L)
    | T (B,L,_,T (R,a,p,b)) -> T (B,a,p,b)
    | T (c,(T _ as a),x,(T _ as b)) ->
      bubble (c,remove_max a,find_max a,b)
    | _ -> failwith "delete: impossible"
  and remove k = function
    | BBL -> failwith "remove: impossible"
    | L -> L
    | T (_,_,(k2,_),_) as m when k = k2 -> delete m
    | T (c,a,(k2,_ as x),b) when k < k2 -> bubble (c,remove k a,x,b)
    | T (c,a,x,b) -> bubble (c,a,x,remove k b)
  and remove_max = function
    | T (_,_,_,L) as m -> delete m
    | T (c,a,x,b) -> balance (c,a,x,remove_max b)
    | _ -> failwith "remove_max: impossible"
  let rec find k = function
    | BBL -> failwith "find: impossible"
    | L -> raise Not_found
    | T (_,_,(k2,v),_) when k = k2 -> v
    | T (_,m,(k2,_),_) when k < k2 -> find k m
    | T (_,_,_,m) -> find k m
end

module M = BTreeMap

let m = M.empty
let v = M.find 3 m
let m = M.add 3 "3" m
let v = M.find 3 m
let m = M.add 6 "6" m
let m = M.add 7 "7" m
let v = M.find 3 m
let v = M.find 7 m
