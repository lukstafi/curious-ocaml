let rec fix f x = f (fix f) x

type int_list = Nil | Cons of int * int_list

let length =
  fix (fun f l ->
    match l with
      | Nil -> 0
      | Cons (x, xs) -> 1 + f xs) in
length (Cons (1, (Cons (2, Nil))))

let id = fun x -> x

let c_true = fun x y -> x
let c_false = fun x y -> y
let c_and = fun x y -> x y c_false

let encode_bool b = if b then c_true else c_false
let decode_bool c = c true false
;;
decode_bool (c_and c_false c_true);;
decode_bool (c_and c_true c_true);;

let if_then_else = fun b -> b;;
decode_bool (if_then_else c_false c_false c_true);;
decode_bool (if_then_else c_true c_false c_true);;

let c_pair m n = fun x -> x m n
let c_first = fun p -> p c_true
let c_second = fun p -> p c_false

let encode_pair enc_fst enc_snd (a, b) =
  c_pair (enc_fst a) (enc_snd b)
let decode_pair de_fst de_snd c = c (fun x y -> de_fst x, de_snd y)
let decode_bool_pair c = decode_pair decode_bool decode_bool c;;
decode_bool_pair (c_pair c_true c_false);;
decode_bool (c_second (c_pair c_true c_false));;

let c_triple l m n = fun x -> x l m n

let pn0 = fun x -> x
let pn_succ n = c_pair c_false n

let pn_pred = fun x -> x c_false
let pn_is_zero = fun x -> x c_true

let rec encode_pnat n =
  if n <= 0 then Obj.magic pn0
  else pn_succ (Obj.magic (encode_pnat (n-1)))
let rec decode_pnat pn =
  if decode_bool (pn_is_zero pn) then 0
  else 1 + decode_pnat (pn_pred (Obj.magic pn))
;;
let decode_pnat pn : int =
  decode_pnat (Obj.magic pn);;

decode_pnat pn0;;
let pn1 x = pn_succ pn0 x;;
let pn2 x = pn_succ pn1 x;;
let pn3 x = pn_succ pn2 x;;
let pn7 x = encode_pnat 7 x;;
let pn13 x = encode_pnat 13 x;;
decode_pnat (pn_succ pn3);;
decode_pnat (encode_pnat 0);;
decode_pnat pn13;;

let cn0 = fun f x -> x
let cn1 = fun f x -> f x
let cn2 = fun f x -> f (f x)
let cn3 = fun f x -> f (f (f x))

let cn_succ = fun n f x -> f (n f x)

(* Instead of #use "common.ml";; *)
let ( |- ) f g x = g (f x)
let ( -| ) f g x = f (g x)

let rec encode_cnat n f =
  if n <= 0 then (fun x -> x) else f -| encode_cnat (n-1) f
(* ignore the warning below -- we use magic *)
let decode_cnat n : int = (Obj.magic n) ((+) 1) 0
let cn7 f x = encode_cnat 7 f x
let cn13 f x = encode_cnat 13 f x
;;
decode_cnat cn13;;

let cn_add = fun n m f x -> n f (m f x)
let cn_mult = fun n m f -> n (m f)
;;
decode_cnat (cn_mult cn3 cn7);;

let cn_prev n =
  fun f x ->
    n
      (fun g v -> v (g f))
      (fun z->x)
      (fun z->z)
;;
decode_cnat (cn_prev cn13);;
let cn_pred = cn_prev;;


(* Recursion *)
#rectypes;;
let fix f' = (fun f x -> f' (f f) x) (fun f x -> f' (f f) x)

let for_to f beg_i end_i s =
  let s = ref s in
  for i = beg_i to end_i do
    s := f i !s
  done;
  !s

let for_downto f beg_i end_i s =
  let s = ref s in
  for i = beg_i downto end_i do
    s := f i !s
  done;
  !s

let while_do p f s =
  let s = ref s in
  while p !s do
    s := f !s
  done;
  !s

let do_while p f s =
  let s = ref (f s) in
  while p !s do
    s := f !s
  done;
  !s

let repeat_until p f s =
  let s = ref (f s) in
  while not (p !s) do
    s := f !s
  done;
  !s

let nil = fun x y -> y
let cons h t = fun x y -> x h t
let addlist l =
  fix (fun f l -> l (fun h t -> cn_add h (f t)) cn0) l
;;
decode_cnat
  (addlist (cons cn1 (cons cn2 (cons cn7 nil))));;
let leaf n = fun x y -> x n
let node l r = fun x y -> y l r
let addtree t =
  fix (fun f t ->
    t (fun n -> n) (fun l r -> cn_add (f l) (f r))
  ) t
;;
decode_cnat
  (addtree (node (node (leaf cn3) (leaf cn7))
              (leaf cn1)));;
(*
let pn_add m n =
  fix (fun f m n ->
    if_then_else (pn_is_zero m) n (pn_succ (f (pn_pred m) n))
  ) m n
;;
decode_pnat (pn_add pn3 pn3);;
*)
let pn_add m n =
  fix (fun f m n ->
    (if_then_else (pn_is_zero m)
       (fun x -> n) (fun x -> pn_succ (f (pn_pred m) n)))
      id
  ) m n;;
decode_pnat (pn_add pn3 pn3);;
decode_pnat (pn_add pn3 pn7);;
