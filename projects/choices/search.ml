(* $MDX part-begin=language *)
type 'a t = Return of 'a | Fail | Choice of 'a t list
let return x = Return x
let rec bind m f = match m with
  | Return x -> f x
  | Fail -> Fail
  | Choice branches -> Choice (List.map (fun m -> bind m f) branches)
let ( let* ) = bind
let choose xs = Choice (List.map return xs)
let guard b = if b then return () else Fail
(* $MDX part-end *)

(* $MDX part-begin=interpreters *)
let rec all = function
  | Return x -> [x]
  | Fail -> []
  | Choice branches -> List.concat_map all branches

let rec first = function
  | Return x -> Some x
  | Fail -> None
  | Choice branches ->
    let rec loop = function
      | [] -> None
      | m::ms -> match first m with None -> loop ms | answer -> answer in
    loop branches

let rec count = function
  | Return _ -> 1
  | Fail -> 0
  | Choice branches -> List.fold_left (fun n m -> n + count m) 0 branches
(* $MDX part-end *)

(* $MDX part-begin=model *)
let pairs target =
  let* x = choose [1;2;3] in
  let* y = choose [1;2;3] in
  let* () = guard (x + y = target) in
  return (x,y)
(* $MDX part-end *)
