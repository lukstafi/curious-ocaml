#rectypes;;
#warnings "-20";;

let (-|) f g x = f (g x)
let (|-) f g x = g (f x)
let id x = x
let rec fix f x = f (fix f) x

(* Lambda-calculus encodings for untyped programming *)

(* Booleans *)
let c_true = fun x y -> x
let c_false = fun x y -> y
let c_and = fun m n -> m n c_false
let encode_bool b = if b then c_true else c_false
let decode_bool c = c true false

(* If-then-else (just boolean application) *)
let if_then_else = fun b -> b

(* Pairs *)
let c_pair m n = fun x -> x m n
let c_first = fun p -> p c_true
let c_second = fun p -> p c_false
let encode_pair enc_fst enc_snd (a, b) = c_pair (enc_fst a) (enc_snd b)
let decode_pair de_fst de_snd c = c (fun x y -> de_fst x, de_snd y)

(* Pair-encoded natural numbers *)
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

(* Church numerals *)
let cn0 = fun f x -> x
let cn_succ n = fun f x -> f (n f x)
let cn_add m n = fun f x -> m f (n f x)
let cn_mult m n = fun f x -> m (n f) x
let rec encode_cnat n = if n <= 0 then cn0 else cn_succ (encode_cnat (n-1))
let decode_cnat n = n (fun x -> x + 1) 0
