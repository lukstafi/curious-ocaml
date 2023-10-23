(* Defining control operators *)
let if_then_else cond e1 e2 =
  match cond with true -> e1 () | false -> e2 ()

let rec fact n = if_then_else (n<=1) (fun () -> 1) (fun () -> fact (n-1) * n)
;;
(* *
fact 1;;
* *)
(* implementation by function closures *)

type 'a stream = SNil | SCons of 'a * (unit -> 'a stream)

let rec stake n = function
 | SCons (a, s) when n > 0 -> a::(stake (n-1) (s ()))
 | _ -> []

let rec s_ones = SCons (1, fun () -> s_ones)
let rec s_from n =
  SCons (n, fun () ->s_from (n+1))

let rec smap f = function
 | SNil -> SNil
 | SCons (a, s) -> SCons (f a, fun () -> smap f (s ()))
let rec szip = function
 | SNil, SNil -> SNil
 | SCons (a1, s1), SCons (a2, s2) ->
     SCons ((a1, a2), fun () -> szip (s1 (), s2 ()))
 | _ -> raise (Invalid_argument "szip")

let rec sfib =
  SCons (1, fun () -> smap (fun (a,b)-> a+b)
    (szip (sfib, SCons (1, fun () -> sfib))))

(* WRONG *)
let file_stream name =
  let ch = open_in name in
  let rec ch_read_line () =
    try SCons (input_line ch, ch_read_line)
    with End_of_file -> SNil in
  ch_read_line ()
;;
let my_sfile = file_stream "diffeqs.hs";;
(* *
stake 10 my_sfile;;
   * *)

(* implementation by native lazy values *)

type 'a llist = LNil | LCons of 'a * 'a llist Lazy.t

let rec ltake n = function
 | LCons (a, lazy l) when n > 0 -> a::(ltake (n-1) l)
 | _ -> []

let rec llist_of_list = function
  | [] -> LNil
  | x::xs -> LCons (x, lazy (llist_of_list xs))

let rec l_ones = LCons (1, lazy l_ones)
let rec lfrom n = LCons (n, lazy (lfrom (n+1)))

let rec lzip = function
 | LNil, LNil -> LNil
 | LCons (a1, ll1), LCons (a2, ll2) ->
     LCons ((a1, a2), lazy (
       lzip (Lazy.force ll1, Lazy.force ll2)))
 | _ -> raise (Invalid_argument "lzip")

let rec lmap f = function
 | LNil -> LNil
 | LCons (a, ll) ->
   LCons (f a, lazy (lmap f (Lazy.force ll)))

let rec lfib =
  LCons (1, lazy (lmap (fun (a,b)-> a+b)
                    (lzip (lfib, LCons (1, lazy lfib)))))

let file_llist name =
  let ch = open_in name in
  let rec ch_read_line () =
    try LCons (input_line ch, lazy (ch_read_line ()))
    with End_of_file -> LNil in
  ch_read_line ()
;;

(* Explain difference between: *)
(* *
stake 25 sfib;;
ltake 25 lfib;;
   * *)
(* Explain benefits of: *)
(* *
let my_file = file_llist "diffeqs.hs";;
ltake 10 my_file;;
   * *)

(* ********** Power series and differential equations ********** *)

let float_too_small c =
  c <> 0. && abs_float c <= epsilon_float
;;
#load "nums.cma";;
module UseInfPrecRatio = struct
  let (+.) = Num.add_num
  let (-.) = Num.sub_num
  let (~-.) = Num.minus_num
  let ( *.) = Num.mult_num
  let (/.) = Num.div_num
  let too_small c = float_too_small (Num.float_of_num c)
  let of_int = Num.num_of_int
  let to_int x = Num.int_of_num (Num.floor_num x)
  let (=.) = Num.eq_num
  let is_zero x = Num.eq_num x (of_int 0)
  let to_str = Num.string_of_num
  let to_float = Num.float_of_num
end

module UseFloats = struct
  let of_int = float_of_int
  let to_int = int_of_float
  let to_str = string_of_float
  let to_float x = x
  let too_small = float_too_small
  let (=.) = (=)
  let is_zero x = x = 0.
end

(* Eiter *)
(* open UseFloats *)
(* or *)
open UseInfPrecRatio

let rec lfold_right f l base =
  match l with
    | LNil -> base
    | LCons (a, lazy l) -> f a (lfold_right f l base)

let horner x l =
  lfold_right (fun c sum -> c +. x *. sum) l (of_int 0)

let rec lazy_foldr f l base =
  match l with
    | LNil -> base
    | LCons (a, ll) ->
      f a (lazy (lazy_foldr f (Lazy.force ll) base))

let lhorner x l =
  let upd c sum =
    if too_small c then c
    else c +. x *. Lazy.force sum in
  lazy_foldr upd l (of_int 0)

let posints = lfrom 1
let rec lfact =
  LCons (1, lazy (lmap (fun (a,b)-> a*b)
                    (lzip (lfact, posints))))

let inv_fact = lmap (fun n -> of_int 1 /. of_int n) lfact
let e = to_float (lhorner (of_int 1) inv_fact)

let rec add xs ys =
  match xs, ys with
    | LNil, _ -> ys
    | _, LNil -> xs
    | LCons (x,xs), LCons (y,ys) ->
      LCons (x +. y, lazy (add (Lazy.force xs) (Lazy.force ys)))

let (+:) a b = add a b

let rec sub xs ys =
  match xs, ys with
    | LNil, _ -> lmap (fun x-> ~-.x) ys
    | _, LNil -> xs
    | LCons (x,xs), LCons (y,ys) ->
      LCons (x-.y, lazy (add (Lazy.force xs) (Lazy.force ys)))

let (-:) a b = sub a b

let scale s = lmap (fun x->s*.x)

let ( *:. ) s b = scale s b

let ( ~-: ) = lmap (fun x-> ~-.x)

let rec shift n xs =
  if n = 0 then xs
  else if n > 0 then LCons (of_int 0, lazy (shift (n-1) xs))
  else match xs with
    | LNil -> LNil
    | LCons (x, lazy xs) when is_zero x -> shift (n+1) xs
    | _ -> failwith "shift: fractional division"

let rec mul xs = function
  | LNil -> LNil
  | LCons (y, ys) ->
    add (scale y xs) (LCons (of_int 0, lazy (mul xs (Lazy.force ys))))

let ( *: ) a b = mul a b

let rec div xs ys =
  match xs, ys with
  | LNil, _ -> LNil
  | LCons (x, xs'), LCons (y, ys') when is_zero x && is_zero y ->
    div (Lazy.force xs') (Lazy.force ys')
  | LCons (x, xs'), LCons (y, ys') ->
    let q = x /. y in
    LCons (q, lazy (div (sub (Lazy.force xs')
                                 (scale q (Lazy.force ys'))) ys))
  | LCons _, LNil -> invalid_arg "div: division by zero"

let (/:) a b = div a b

let polynom s = llist_of_list (List.map of_int s)

let test_ones = polynom [1] /: polynom [1; -1]
let posnums = lmap of_int posints

let uncurry f (x,y) = f x y
let integrate c xs =
  LCons (c, lazy (lmap (uncurry (/.)) (lzip (xs, posnums))))

let integrate c xs =
  LCons (c, lazy (lmap (uncurry (/.)) (lzip (xs, posnums))))

let integ xs = lmap (uncurry (/.)) (lzip (xs, posnums))

let ltail = function
  | LNil -> invalid_arg "ltail"
  | LCons (_, lazy tl) -> tl

let differentiate xs =
  lmap (uncurry ( *.)) (lzip (ltail xs, posnums))
  
let draw_to_svg file ~w ~h ?title ?desc curves =
  let f = open_out file in
  Printf.fprintf f "<?xml version=\"1.0\" standalone=\"no\"?>
<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" 
  \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">
<svg width=\"%d\" height=\"%d\" viewBox=\"0 0 %d %d\"
     xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">
" w h w h;
  (match title with None -> ()
  | Some title -> Printf.fprintf f "  <title>%s</title>\n" title);
  (match desc with None -> ()
  | Some desc -> Printf.fprintf f "  <desc>%s</desc>\n" desc);
  let draw_shape (points, (r,g,b)) =
    (fun (x,y) -> Printf.fprintf f "  <path d=\"M %d %d" x (h-y)) points.(0);
    Array.iteri (fun i (x, y) ->
      if i > 0 then Printf.fprintf f " L %d %d" x (h-y)) points;
    Printf.fprintf f
      "\"\n        fill=\"none\" stroke=\"rgb(%d, %d, %d)\" stroke-width=\"1\" />\n"
      r g b in
  List.iter draw_shape curves;
  Printf.fprintf f "</svg>%!"
;;

#load "graphics.cma";;
let draw_to_screen ~w ~h curves =
  Graphics.open_graph (" "^string_of_int w^"x"^string_of_int h);
  Graphics.set_color (Graphics.rgb 50 50 0);
  Graphics.fill_rect 0 0 (Graphics.size_x ()) (Graphics.size_y ());
  List.iter (fun (points, (r,g,b)) ->
    Graphics.set_color (Graphics.rgb r g b);
    Graphics.draw_poly_line points) curves;
  if Graphics.read_key () = 'q'
  then failwith "User interrupted finding solutions.";
  Graphics.close_graph ()

(* Draw graph of function w.r.t. time. *)
let plot_1D f ~w ~h0 ~scale ~t_beg ~t_end =
  let dt = (t_end -. t_beg) /. of_int w in
  Array.init w (fun i ->
    let y = lhorner (t_beg +. dt *. of_int i) f in
    i, h0 + to_int (scale *. y))

let w = 800 and h = 800

(* Example: sinus and cosinus *)
(*
let rec sin = integrate (of_int 0) cos
and cos = integrate (of_int 1) ~-:sin
*)
let rec sin = LCons (of_int 0, lazy (integ cos))
and cos = LCons (of_int 1, lazy (integ ~-:sin))


let graph =
  let scale = of_int h /. of_int 8 in
  [plot_1D sin ~w ~h0:(h/2) ~scale
      ~t_beg:(of_int 0) ~t_end:(of_int 10),
   (250,250,0);
   plot_1D cos ~w ~h0:(h/2) ~scale
     ~t_beg:(of_int 0) ~t_end:(of_int 10),
   (250,0,250)]
(* *)
let () = draw_to_screen ~w ~h graph
let () = draw_to_svg
   "/home/lukstafi/Dropbox/Dokumenty/FunctionalCourse/sin_cos_2.svg"
   ~w ~h ~title:"approx. sin/cos graph" ~desc:"Working on floats"
  graph
(* *)

(* ********** Arbitrary precision computation ********** *)

(* Return the lazy list of approximations to l(x). *)
let infhorner x l =
  let upd c sum =
    LCons (c, lazy (lmap (fun apx -> c+.x*.apx)
                      (Lazy.force sum))) in
  lazy_foldr upd l (LCons (of_int 0, lazy LNil))

let rec exact f = function
  | LNil -> assert false
  | LCons (x0, lazy (LCons (x1, lazy (LCons (x2, _)))))
      when f x0 = f x1 && f x0 = f x2 -> f x0
  | LCons (_, lazy tl) -> exact f tl

let plot_1D f ~w ~h0 ~scale ~t_beg ~t_end =
  let dt = (t_end -. t_beg) /. of_int w in
  let eval = exact (fun y-> to_int (scale *. y)) in
  Array.init w (fun i ->
    let y = infhorner (t_beg +. dt *. of_int i) f in
    i, h0 + eval y)

let graph =
  let scale = of_int h /. of_int 8 in
  [plot_1D sin ~w ~h0:(h/2) ~scale
      ~t_beg:(of_int 0) ~t_end:(of_int 10),
   (250,250,0);
   plot_1D cos ~w ~h0:(h/2) ~scale
     ~t_beg:(of_int 0) ~t_end:(of_int 10),
   (250,0,250)]
(* *)
let () = draw_to_screen ~w ~h graph
let () = draw_to_svg
   "/home/lukstafi/Dropbox/Dokumenty/FunctionalCourse/sin_cos_3.svg"
   ~w ~h ~title:"exact sin/cos graph"
   ~desc:"Working on rational nums with iterated approximations"
  graph
(* *)

(* Example: nuclear chain reaction: A->B->C *)

let n_chain ~nA0 ~nB0 ~lA ~lB =
  let rec nA =
    LCons (nA0, lazy (integ (~-.lA *:. nA)))
  and nB =
    LCons (nB0, lazy (integ (~-.lB *:. nB +: lA *:. nA))) in
  nA, nB

let nA, nB = n_chain ~nA0:(of_int 20) ~nB0:(of_int 5)
  ~lA:(of_int 1/.of_int 2) ~lB:(of_int 1/.of_int 3)
let graph_1D ~scale ~t_end =
  [plot_1D nA ~w ~h0:0 ~scale ~t_beg:(of_int 0) ~t_end, (250, 0, 250);
   plot_1D nB ~w ~h0:0 ~scale ~t_beg:(of_int 0) ~t_end, (250, 250, 0)]
let graph = graph_1D ~scale:(of_int 30) ~t_end:(of_int 15)
(* *
let () = draw_to_screen ~w ~h graph
let () = draw_to_svg
   "/home/lukstafi/Dropbox/Dokumenty/FunctionalCourse/chain_reaction.svg"
   ~w ~h ~title:"Chain reaction model"
   ~desc:"A->B->C decay: A is purple, B is yellow."
  graph
   * *)

(* Exercise: the Hamming problem *)
let rec lfilter f = function
 | LNil -> LNil
 | LCons (n, ll) ->
     if f n then LCons (n, lazy (lfilter f (Lazy.force ll)))
     else lfilter f (Lazy.force ll)

let primes =
 let rec sieve = function
     LCons(p,nf) -> LCons(p, lazy (sieve (sift p (Lazy.force nf))))
   | LNil -> failwith "Impossible! Internal error."
 and sift p = lfilter (function n -> n mod p <> 0)
in sieve (lfrom 2)

let times ll n = lmap (fun i -> i * n) ll;;

let rec merge xs ys = match xs, ys with
  | LCons (x, lazy xr), LCons (y, lazy yr) ->
     if x < y then LCons (x, lazy (merge xr ys))
     else if x > y then LCons (y, lazy (merge xs yr))
     else LCons (x, lazy (merge xr yr))
 | r, LNil | LNil, r -> r

let hamming k =
 let pr = ltake k primes in
 let rec h = LCons (1, lazy (
   failwith "TODO" )) in
 h

(* Circular data structures: double-linked list *)
type 'a dllist =
  DLNil | DLCons of 'a dllist Lazy.t * 'a * 'a dllist

let dllist_of_list l =
  let rec dllist prev l =
    match l with
      | [] -> DLNil
      | x::xs ->
        let rec cell =
          lazy (DLCons (prev, x, dllist cell xs)) in
        Lazy.force cell in
  dllist (lazy DLNil) l

let rec dltake n l =
  match l with
    | DLCons (_, x, xs) when n>0 ->
      x::dltake (n-1) xs
    | _ -> []

let rec dlbackwards n l =
  match l with
    | DLCons (lazy xs, x, _) when n>0 ->
      x::dlbackwards (n-1) xs
    | _ -> []

let rec dldrop n l =
  match l with
    | DLCons (_, x, xs) when n>0 ->
      dldrop (n-1) xs
    | _ -> l

type 'a ldlist =
  LDNil | LDCons of 'a ldlist * 'a * 'a ldlist Lazy.t

let ldlist_of_list l =
  let rec ldlist prev l =
    match l with
      | [] -> LDNil
      | x::xs ->
        let rec tail = lazy (ldlist cell xs)
        and cell = LDCons (prev, x, tail) in
        cell in
  ldlist LDNil l


(* ********** Input-Output streams ********** *)

type ('a, 'b) iostream =
  EOS | More of 'b * ('a -> ('a, 'b) iostream)
type 'a istream = (unit, 'a) iostream
type 'a ostream = ('a, unit) iostream

let rec compose sf sg =
  match sg with
  | EOS -> EOS                        (* no more output *)
  | More (z, g) ->
    match sf with
    | EOS -> More (z, fun _ -> EOS)     (* no more input *)
    | More (y, f) ->
      let update x = compose (f x) (g y) in
      More (z, update)

type ('a, 'b) pipe =
  EOP
| Yield of 'b * ('a, 'b) pipe
| Await of ('a -> ('a, 'b) pipe)

type 'a ipipe = (unit, 'a) pipe
type void
type 'a opipe = ('a, void) pipe

let rec compose pf pg =
  match pg with
  | EOP -> EOP
  | Yield (z, pg') -> Yield (z, compose pf pg')
  | Await g ->
    match pf with
    | EOP -> EOP
    | Yield (y, pf') -> compose pf' (g y)
    | Await f ->
      let update x = compose (f x) pg in
      Await update

let (>->) pf pg = compose pf pg

let rec append pf pg =
  match pf with
  | EOP -> pg
  | Yield (z, pf') -> Yield (z, append pf' pg)
  | Await f ->
    let update x = append (f x) pg in
    Await update

let rec yield_all l tail =
  match l with
  | [] -> tail
  | x::xs -> Yield (x, yield_all xs tail)

let rec iterate f : 'a opipe =
  Await (fun x -> let () = f x in iterate f)

(* Pretty printing -- straightforward *)
type doc =
  Text of string | Line | Cat of doc * doc | Group of doc

let pretty w d =
  let rec width = function
    | Text z -> String.length z
    | Line -> 1
    | Cat (d1, d2) -> width d1 + width d2
    | Group d -> width d in
  let rec format f r = function
    | Text z -> z, r - String.length z
    | Line when f -> " ", r-1
    | Line -> "\n", w
    | Cat (d1, d2) ->
      let s1, r = format f r d1 in
      let s2, r = format f r d2 in
      s1 ^ s2, r
    | Group d -> format (f || width d <= r) r d in
  fst (format false w d)

let (++) d1 d2 = Cat (d1, Cat (Line, d2))
let (!) s = Text s
let test_doc =
  Group (!"Document" ++
            Group (!"First part" ++ !"Second part"))

let () = print_endline (pretty 30 test_doc)
let () = print_endline (pretty 20 test_doc)
let () = print_endline (pretty 60 test_doc)

(* Pretty printing -- streams *)
type ('a, 'b) doc_e =
  TE of 'a * string | LE of 'a | GBeg of 'b | GEnd of 'a

let rec norm = function
  | Group d -> norm d
  | Text "" -> None
  | Cat (Text "", d) -> norm d
  | d -> Some d

let rec gen = function
  | Text z -> Yield (TE ((),z), EOP)
  | Line -> Yield (LE (), EOP)
  | Cat (d1, d2) -> append (gen d1) (gen d2)
  | Group d ->
    match norm d with
    | None -> EOP
    | Some d ->
      Yield (GBeg (),
             append (gen d) (Yield (GEnd (), EOP)))

let rec docpos curpos =
  Await (function
  | TE (_, z) ->
    Yield (TE (curpos, z),
           docpos (curpos + String.length z))
  | LE _ ->
    Yield (LE curpos, docpos (curpos + 1))
  | GBeg _ ->
    Yield (GBeg curpos, docpos curpos)
  | GEnd _ ->
    Yield (GEnd curpos, docpos curpos))
  
let docpos = docpos 0

let rec grends grstack =
  Await (function
  | TE _ | LE _ as e ->
    (match grstack with
    | [] -> Yield (e, grends [])
    | gr::grs -> grends ((e::gr)::grs))
  | GBeg _ -> grends ([]::grstack)
  | GEnd endp ->
    match grstack with
    | [] -> failwith "grends: unmatched group end marker"
    | [gr] ->
      yield_all
        (GBeg endp::List.rev (GEnd endp::gr))
        (grends [])
    | gr::par::grs ->
      let par = GEnd endp::gr @ [GBeg endp] @ par in
      grends (par::grs))


let rev_concat_map ~prep f l =
  let rec cmap_f accu = function
    | [] -> accu
    | a::l -> cmap_f (prep::List.rev_append (f a) accu) l in
  cmap_f [] l

(* Mark group start with group end position *)
type group_end = Pos of int | Too_far

(* Modified for low latency: yield results early. *)
let rec grends w grstack =
  let flush tail =
    yield_all
      (rev_concat_map ~prep:(GBeg Too_far) snd grstack)
      tail in
  Await (function
  | TE (curp, _) | LE curp as e ->
    (match grstack with
    | [] -> Yield (e, grends w [])
    | (begp, _)::_ when curp-begp > w ->
      flush (Yield (e, grends w []))
    | (begp, gr)::grs -> grends w ((begp, e::gr)::grs))
  | GBeg begp -> grends w ((begp, [])::grstack)
  | GEnd endp as e ->
    match grstack with
    | [] -> Yield (e, grends w [])
    | (begp, _)::_ when endp-begp > w ->
      flush (Yield (e, grends w []))
    | [_, gr] ->
      yield_all
        (GBeg (Pos endp)::List.rev (GEnd endp::gr))
        (grends w [])
    | (_, gr)::(par_begp, par)::grs ->
      let par =
        GEnd endp::gr @ [GBeg (Pos endp)] @ par in
      grends w ((par_begp, par)::grs))
        
let grends w = grends w []

let rec format w (inline, endlpos as st) =
  Await (function
  | TE (_, z) -> Yield (z, format w st)
  | LE p when List.hd inline ->
    Yield (" ", format w st)
  | LE p -> Yield ("\n", format w (inline, p+w))
  | GBeg Too_far ->
    format w (false::inline, endlpos)
  | GBeg (Pos p) ->
    format w ((p<=endlpos)::inline, endlpos)
  | GEnd _ -> format w (List.tl inline, endlpos))

let format w = format w ([false], w)  

let pretty_print w doc =
  gen doc >-> docpos >-> grends w >-> format w >-> iterate print_string



let rec breaks w (inline, endlpos as st) =
  Await (function
  | TE _ as e -> Yield (e, breaks w st)
  | LE p when List.hd inline ->
    Yield (TE (p, " "), breaks w st)
  | LE p as e -> Yield (e, breaks w (inline, p+w))
  | GBeg Too_far as e ->
    Yield (e, breaks w (false::inline, endlpos))
  | GBeg (Pos p) as e ->
    Yield (e, breaks w ((p<=endlpos)::inline, endlpos))
  | GEnd _ as e ->
    Yield (e, breaks w (List.tl inline, endlpos)))

let breaks w = breaks w ([false], w)  

let rec emit =
  Await (function
  | TE (_, z) -> Yield (z, emit)
  | LE _ -> Yield ("\n", emit)
  | GBeg _ | GEnd _ -> emit)

let pretty_print w doc =
  gen doc >-> docpos >-> grends w >-> breaks w >->
  emit >-> iterate print_string



(* Tests *)
let print_e_doc pr_p pr_ep = function
  | TE (p,z) -> pr_p p; print_endline (": "^z)
  | LE p -> pr_p p; print_endline ": endline"
  | GBeg ep -> pr_ep ep; print_endline ": GBeg"
  | GEnd p -> pr_p p; print_endline ": GEnd"
let noop () = ()
let print_pos = function
  | Pos p -> print_int p
  | Too_far -> print_string "Too far"

let _ = gen test_doc >->
  iterate (print_e_doc noop noop)
let _ = gen test_doc >-> docpos >->
  iterate (print_e_doc print_int print_int)
let _ = gen test_doc >-> docpos >-> grends 20 >->
  iterate (print_e_doc print_int print_pos)
let _ = gen test_doc >-> docpos >-> grends 30 >->
  iterate (print_e_doc print_int print_pos)
let _ = gen test_doc >-> docpos >-> grends 60 >->
  iterate (print_e_doc print_int print_pos)
let _ = pretty_print 20 test_doc
let _ = pretty_print 30 test_doc
let _ = pretty_print 60 test_doc

