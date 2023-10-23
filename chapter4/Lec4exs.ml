
let c_or = fun x y -> x c_true y
;; 
decode_bool (c_or c_false c_false);;
decode_bool (c_or c_false c_true);;
decode_bool (c_or c_true c_true);;

let c_not = fun b -> fun x y -> b y x
;;
decode_bool (c_not c_false);;
decode_bool (c_not c_true);;

let cn_exp = fun m n -> n m;;
decode_cnat (cn_exp cn3 cn3);;
decode_cnat (cn_exp cn3 cn7);;
3*3*3*3*3*3*3;;

let cn_is_zero = fun n -> n (fun _ -> c_false) c_true
;;
decode_bool (cn_is_zero cn0);;
decode_bool (cn_is_zero cn7);;
decode_bool (cn_is_zero (cn_succ cn13));;

let cn_even = fun n -> n c_not c_true;;
decode_bool (cn_even cn0);;
decode_bool (cn_even cn1);;
decode_bool (cn_even cn2);;
decode_bool (cn_even cn7);;
decode_bool (cn_even (cn_succ cn13));;

let pn_mult m n =
  fix (fun f i ->
    (if_then_else (pn_is_zero i)
       (fun x -> pn0) (fun x -> pn_add n (f (pn_pred i))))
      id
  ) m;;
decode_pnat (pn_mult pn3 pn3);;
decode_pnat (pn_mult pn3 pn7);;

let pn_fact n =
  fix (fun f i ->
    (if_then_else (pn_is_zero i)
       (fun x -> pn1) (fun x -> pn_mult i (f (pn_pred i))))
      id
  ) n;;
decode_pnat (pn_fact pn3);;
let pn5 x = encode_pnat 5 x;;
decode_pnat (pn_fact pn5);;

let list_length l =
  fix (fun f l -> l (fun h t -> cn_succ (f t)) cn0) l
;;
decode_cnat (list_length nil);;
decode_cnat
  (list_length (cons cn1 (cons cn2 (cons cn3 (cons cn4 nil)))));;

let cn_subtract m n =
  fix (fun f m n ->
    (if_then_else (cn_is_zero n)
       (fun x -> m) (fun x -> f (cn_pred m) (cn_pred n)))
      id
  ) m n;;
decode_cnat (cn_subtract cn3 cn3);;
decode_cnat (cn_subtract cn7 cn3);;
decode_cnat (cn_subtract cn3 cn7);;
decode_cnat (cn_subtract cn13 cn3);;

let cn_max m n =
  cn_add m (cn_subtract n m);;
decode_cnat (cn_max cn3 cn3);;
decode_cnat (cn_max cn3 cn7);;
decode_cnat (cn_max cn13 cn3);;

let tree_depth t =
  fix (fun f t ->
    t (fun n -> cn1) (fun l r -> cn_succ (cn_max (f l) (f r)))
  ) t
;;
decode_cnat (tree_depth (leaf cn3));;
decode_cnat (tree_depth (node (leaf cn3) (leaf cn7)));;
decode_cnat
  (tree_depth (node (node (leaf cn3) (leaf cn7))
                 (leaf cn1)));;
