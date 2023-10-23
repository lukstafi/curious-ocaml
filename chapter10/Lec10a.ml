(* Binary tree zipper *)
type 'a tree = Tip | Node of 'a tree * 'a * 'a tree
type tree_dir = Left_br | Right_br
type 'a context = (tree_dir * 'a * 'a tree) list
type 'a location = {sub: 'a tree; ctx: 'a context}
let access {sub} = sub
let change {ctx} sub = {sub; ctx}
let modify f {sub; ctx} = {sub=f sub; ctx}

let ascend loc =
  match loc.ctx with
  | [] -> loc
  | (Left_br, n, l) :: up_ctx ->
    {sub=Node (l, n, loc.sub); ctx=up_ctx}
  | (Right_br, n, r) :: up_ctx ->
    {sub=Node (loc.sub, n, r); ctx=up_ctx}
let desc_left loc =
  match loc.sub with
  | Tip -> loc
  | Node (l, n, r) ->
    {sub=l; ctx=(Right_br, n, r)::loc.ctx}
let desc_right loc =
  match loc.sub with
  | Tip -> loc
  | Node (l, n, r) ->
    {sub=r; ctx=(Left_br, n, l)::loc.ctx}

(* Document tree zipper *)
type doc = Text of string | Line | Group of doc list
type contxt = (doc list * doc list) list
type doc_loc = {sub: doc; ctx: contxt}
let access {sub} = sub
let change {ctx} sub = {sub; ctx}
let modify f {sub; ctx} = {sub=f sub; ctx}

let go_up loc =
  match loc.ctx with
  | [] -> invalid_arg "go_up: at top"
  | (left, right) :: up_ctx ->
    {sub=Group (List.rev left @ loc.sub :: right); ctx=up_ctx}
let go_left loc =
  match loc.ctx with
  | [] -> invalid_arg "go_left: at top"
  | (l::left, right) :: up_ctx ->
    {sub=l; ctx=(left, loc.sub::right) :: up_ctx}
  | ([], _) :: _ -> invalid_arg "go_left: at first"
let go_right loc =
  match loc.ctx with
  | [] -> invalid_arg "go_right: at top"
  | (left, r::right) :: up_ctx ->
    {sub=r; ctx=(loc.sub::left, right) :: up_ctx}
  | (_, []) :: _ -> invalid_arg "go_right: at last"
let go_down loc =
  match loc.sub with
  | Text _ -> invalid_arg "go_down: at text"
  | Line -> invalid_arg "go_down: at line"
  | Group [] -> invalid_arg "go_down: at empty"
  | Group (doc::docs) -> {sub=doc; ctx=([], docs) :: loc.ctx}

(* Example: context rewriting *)
type op = Add | Mul
type expr = Val of int | Var of string | App of expr * op * expr
type expr_dir = Left_arg | Right_arg
type expr_ctx = (expr_dir * op * expr) list
type expr_loc = {sub: expr; ctx: expr_ctx}

let rec find_aux p e =
  if p e then Some (e, [])
  else match e with
  | Val _ | Var _ -> None
  | App (l, op, r) ->
    match find_aux p l with
    | Some (sub, up_ctx) ->
      Some (sub, (Right_arg, op, r)::up_ctx)
    | None ->
      match find_aux p r with
      | Some (sub, up_ctx) ->
        Some (sub, (Left_arg, op, l)::up_ctx)
      | None -> None

let find p e =
  match find_aux p e with
  | None -> None
  | Some (sub, ctx) -> Some {sub; ctx=List.rev ctx}

let rec close loc =
  match loc.ctx with
  | [] -> loc.sub
  | (Left_arg, op, l)::up_ctx ->
    close {sub=App(l, op, loc.sub); ctx=up_ctx}
  | (Right_arg, op, r)::up_ctx ->
    close {sub=App(loc.sub, op, r); ctx=up_ctx}

let rec pull_out loc =
  match loc.ctx with
  | [] -> loc.sub
  | (Left_arg, op, l) :: up_ctx ->
    pull_out {loc with ctx=(Right_arg, op, l) :: up_ctx}
  | (Right_arg, op1, e1) :: (_, op2, e2) :: up_ctx
      when op1 = op2 ->
    pull_out {loc with ctx=(Right_arg, op1, App(e1,op1,e2)) :: up_ctx}
  | (Right_arg, Add, e1) :: (_, Mul, e2) :: up_ctx ->
    pull_out {loc with ctx=
        (Right_arg, Mul, e2) ::
          (Right_arg, Add, App(e1,Mul,e2)) :: up_ctx}
  | (Right_arg, op, r)::up_ctx ->
    pull_out {sub=App(loc.sub, op, r); ctx=up_ctx}

let (+) a b = App (a, Add, b)
let ( * ) a b = App (a, Mul, b)
let (!) a = Val a
let x = Var "x"
let y = Var "y"
let ex = !5 + y * (!7 + x) * (!3 + y)
let op2str = function Add -> "+" | Mul -> "*"
let rec expr2str = function
  | Val n -> string_of_int n | Var x -> x
  | App (l,op,r) -> "("^expr2str l^op2str op^expr2str r^")"
let loc = find (fun e->e=x) ex
let sol =
  match loc with
  | None -> raise Not_found
  | Some loc -> pull_out loc
let _ = expr2str sol;;

(*# let _ = expr2str sol;;
- : string = "(((x*y)*(3+y))+(((7*y)*(3+y))+5))"*)

(* ************************************************************ *)
(* ***************** Self-adjusting computing ***************** *)

let concat_map f l =
  let rec cmap_f accu = function
    | [] -> accu
    | a::l -> cmap_f (List.rev_append (f a) accu) l in
  List.rev (cmap_f [] l)
external (-|) : 'a -> ('a -> 'b) -> 'b = "%revapply"

(* Download "froc" from https://github.com/jaked/froc/downloads *)
(* cd froc-0.2a; ./configure; make all; sudo make install *)
(* *)
#directory "+froc";;
#load "froc.cma";;
(* *)

open Froc_ddg
type ibtree =
| Leaf of int * int
| Node of int * int * ibtree t * ibtree t
;;

(* *)
#load "graphics.cma";;
(* *)

let rec display px py t =
  match t with
  | Leaf (x, y) ->
    return
      (Graphics.draw_poly_line [|px,py;x,y|];
       Graphics.draw_circle x y 3)
  | Node (x, y, l, r) ->
    return (Graphics.draw_poly_line [|px,py;x,y|])
    >>= fun _ -> l >>= display x y
    >>= fun _ -> r >>= display x y

open Pervasives
let i2f = float_of_int
let f2i = int_of_float
let width = 1024.
let grow_at (x, depth, upd) =
  let x_l = x-f2i (width*.(2.0**(~-.(i2f (depth+1))))) in
  let l, upd_l = changeable (Leaf (x_l, (depth+1)*20)) in
  let x_r = x+f2i (width*.(2.0**(~-.(i2f (depth+1))))) in
  let r, upd_r = changeable (Leaf (x_r, (depth+1)*20)) in
  write upd (Node (x, depth*20, l, r));
  propagate ();
  [x_l, depth+1, upd_l; x_r, depth+1, upd_r]

let rec loop t subts steps =
  if steps <= 0 then ()
  else loop t (concat_map grow_at subts) (steps-1)
let incremental steps () =
  Graphics.open_graph " 1024x600";
  let t, u = changeable (Leaf (512, 20)) in
  let d = t >>= display (f2i (width /. 2.)) 0 in
  loop t [512, 1, u] steps;
  Graphics.close_graph ();;

type tree_noninc =
| Leaf of int * int
| Node of int * int * tree_noninc * tree_noninc

let rec display_noninc px py t =
  match t with
  | Leaf (x, y) ->
    Graphics.draw_poly_line [|px,py;x,y|];
    Graphics.draw_circle x y 3
  | Node (x, y, l, r) ->
    Graphics.draw_poly_line [|px,py;x,y|];
    display_noninc x y l;
    display_noninc x y r

let rec grow_at_noninc t (x, depth) =
  match t with
  | Leaf _ ->
    let x_l = x-f2i (width*.(2.0**(~-.(i2f (depth+1))))) in
    let l = Leaf (x_l, (depth+1)*20) in
    let x_r = x+f2i (width*.(2.0**(~-.(i2f (depth+1))))) in
    let r = Leaf (x_r, (depth+1)*20) in
    Node (x, depth*20, l, r),
    [x_l, depth+1; x_r, depth+1]
  | Node (xn, yn, l, r) ->
    if x <= xn then
      let l, subts = grow_at_noninc l (x, depth) in
      Node (xn, yn, l, r), subts
    else
      let r, subts = grow_at_noninc r (x, depth) in
      Node (xn, yn, l, r), subts

let rec loop_noninc t subts steps =
  if steps <= 0 then ()
  else (
    display_noninc (f2i (width /. 2.)) 0 t;
    let t, subts = List.fold_left
      (fun (t, subts) subt ->
        let t, more_subts = grow_at_noninc t subt in
        t, more_subts @ subts)
      (t, []) subts in
    loop_noninc t subts (steps-1)
  )

let nonincremental steps () =
  Graphics.open_graph " 1024x600";
  let t = Leaf (512, 20) in
  loop_noninc t [512, 1] steps;
  Graphics.close_graph ();;

(* *)
#load "unix.cma";;
#directory "+threads";;
#load "threads.cma";;
(* *)
let time f =
  let tbeg = Unix.gettimeofday () in
  let res = f () in
  let tend = Unix.gettimeofday () in
  tend -. tbeg, res

let res = time (incremental 20);;
let res1 = List.map (fun s -> time (incremental s))
  [12;13;14;15;16;17;18;19]
let res2 = List.map (fun s -> time (nonincremental s))
  [12;13;14;15;16;17;18;19]
let _ = Printf.printf "incremental: %s\nrebuilding: %s\n%!"
  (String.concat ", " (List.map (fun (t,_)->string_of_float t) res1))
  (String.concat ", " (List.map (fun (t,_)->string_of_float t) res2))

