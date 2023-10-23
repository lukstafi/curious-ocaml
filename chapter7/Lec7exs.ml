(* Lazy evaluation strategies, argument passing. *)
let rec wrong_lzip = function
 | LNil, LNil -> LNil
 | LCons (a1, lazy l1), LCons (a2, lazy l2) ->
     LCons ((a1, a2), lazy (wrong_lzip (l1, l2)))
 | _ -> raise (Invalid_argument "lzip")

let rec wrong_lmap f = function
 | LNil -> LNil
 | LCons (a, lazy l) -> LCons (f a, lazy (wrong_lmap f l))

let cycle = function
  | [] -> invalid_arg "cycle: empty list"
  | hd::tl ->
    let rec result =
      LCons (hd, lazy (aux tl))
    and aux = function
      | [] -> result
      | x::xs -> LCons (x, lazy (aux xs)) in
    result
    
let sinPS =
  lmap (uncurry ( *.)) (lzip (cycle [0.;1.;0.;-1.], inv_fact))
let cosPS =
  lmap (uncurry ( *.)) (lzip (cycle [1.;0.;-1.;0.], inv_fact))

let graph_sc_1D ~scale ~t_end =
  [plot_1D sinPS ~w ~h ~scale ~t_beg:0. ~t_end, (0, 0, 250);
   plot_1D cosPS ~w ~h ~scale ~t_beg:0. ~t_end, (250, 0, 0)]

let () = draw_to_screen ~w:800 ~h:800 (graph_sc_1D ~scale:200. ~t_end:10.)

(* Documents with annotations -- last exercise. *)
type 'a doc =
  Text of 'a * string | Line of 'a | Cat of doc * doc | Group of 'a * doc
