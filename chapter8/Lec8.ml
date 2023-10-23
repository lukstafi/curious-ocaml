#load "dynlink.cma";;
#load "camlp4o.cma";;
#load "Camlp4Parsers/Camlp4ListComprehension.cmo";;

let rec from_to m n =
  if m > n then []
  else m :: from_to (m+1) n

let test = [i * 2 | i <- from_to 2 22; i mod 3 = 0]

#use "Lec6.ml";;
let rec exprs = function
  | [] -> []
  | [n] -> [Val n]
  | ns ->
    [App (o,l,r) | (ls,rs) <- split ns;
     l <- exprs ls; r <- exprs rs;
     o <- [Add; Sub; Mul; Div]]

let solutions ns n =
  [e | ns' <- choices ns;
   e <- exprs ns'; eval e = Some n]

let rec subseqs l =
  match l with
    | [] -> [[]]
    | x::xs -> [ys | px <- subseqs xs; ys <- [px; x::px]]

let rec insert x = function
  | [] -> [[x]]
  | y::ys' as ys ->
    (x::ys) :: [y::zs | zs <- insert x ys']
let rec ins_perms = function
  | [] -> [[]]
  | x::xs -> [zs | ys <- ins_perms xs; zs <- insert x ys]

let rec select = function
  | [x] -> [x,[]]
  | x::xs -> (x,xs) :: [ y, x::ys | y,ys <- select xs]
let rec sel_perms = function
  | [] -> [[]]
  | xs ->
    [x::ys | x,xs' <- select xs; ys <- sel_perms xs']
;;

(* If you have copied pa_monad into your working directory, try:
   #load "./pa_monad.cmo";; *)
#load "monad/pa_monad.cmo";;

let rec exprs = function
  | [] -> []
  | [n] -> [Val n]
  | ns ->
    perform with (|->) in
      (ls,rs) <-- split ns;
      l <-- exprs ls; r <-- exprs rs;
      o <-- [Add; Sub; Mul; Div];
      [App (o,l,r)]

(*
let solutions ns n =
  perform
    ns' <-- choices ns;
    e <-- exprs ns';
    eval e = Some n;
    [e]
      eval e = Some n;
      ^^^^^^^^^^^^^^^
Error: This expression has type bool but an expression was expected of type
         'a list
*)
let solutions ns n =
  perform with (|->) in
    ns' <-- choices ns;
    e <-- exprs ns';
    if eval e = Some n then [e] else []

let guard p = if p then [()] else []

let solutions ns n =
  perform with (|->) in
    ns' <-- choices ns;
    e <-- exprs ns';
    guard (eval e = Some n);
    [e]

let bind a b = concat_map b a
let return x = [x]  
let solutions ns n =
  perform
    ns' <-- choices ns;
    e <-- exprs ns';
    guard (eval e = Some n);
    return e
;;

(*
perform exp ===> exp
perform pat <-- exp; rest ===> bind exp (fun pat -> perform rest)
perform exp; rest ===> bind exp (fun _ -> perform rest)
perform let ... in rest ===> let ... in perform rest
perform rpat <-- exp; rest ===>
 bind exp
 (function
 | rpat -> perform rest
 | _ -> failwith "pattern match")
perform with bexp [and fexp] in body ===> perform body
*)

let mzero = []
let mplus = List.append
let fail = mzero
let guard p = if p then return () else fail
let foldM f v l = concat_fold f v l

let find_to_eat n island_size num_islands empty_cells =
  let honey = honey_cells n empty_cells in

  let rec find_board s =
    (* Printf.printf "find_board: %s\n" (state_str s); *)
    match visit_cell s with
    | None ->
      perform
        guard (s.been_islands = num_islands);
        return s.eaten
    | Some (cell, s) ->
      perform
        s <-- find_island cell (fresh_island s);
        guard (s.been_size = island_size);
        find_board s

  and find_island current s =
    let s = keep_cell current s in
    (* Printf.printf "find_island: %s\n" (state_str s); *)
    neighbors n empty_cells current
    |> foldM
        (fun neighbor s ->
          if CellSet.mem neighbor s.visited then return s
          else
            let choose_eat =
              if s.more_to_eat <= 0 then fail
              else return (eat_cell neighbor s)
            and choose_keep =
              if s.been_size >= island_size then fail
              else find_island neighbor s in
            mplus choose_eat choose_keep)
        s in
  
  let cells_to_eat =
    List.length honey - island_size * num_islands in
  find_board (init_state honey cells_to_eat)


module type MONAD = sig
  type 'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
end

module type MONAD_OPS = sig
  type 'a monad
  include MONAD with type 'a t := 'a monad
  val ( >>= ) :'a monad -> ('a -> 'b monad) -> 'b monad
  val foldM :
    ('a -> 'b -> 'a monad) -> 'a -> 'b list -> 'a monad
  val whenM : bool -> unit monad -> unit monad
  val lift : ('a -> 'b) -> 'a monad -> 'b monad
  val (>>|) : 'a monad -> ('a -> 'b) -> 'b monad
  val join : 'a monad monad -> 'a monad
  val ( >=> ) :
    ('a -> 'b monad) -> ('b -> 'c monad) -> 'a -> 'c monad
end

module MonadOps (M : MONAD) = struct
  open M
  type 'a monad = 'a t
  let run x = x
  let (>>=) a b = bind a b
  let rec foldM f a = function
    | [] -> return a
    | x::xs -> f a x >>= fun a' -> foldM f a' xs
  let whenM p s = if p then s else return ()
  let lift f m = perform x <-- m; return (f x)
  let (>>|) a b = lift b a
  let join m = perform x <-- m; x
  let (>=>) f g = fun x -> f x >>= g
end

module Monad (M : MONAD) :
sig
  include MONAD_OPS
  val run : 'a monad -> 'a M.t
end = struct
  include M
  include MonadOps(M)
end

module type MONAD_PLUS = sig
  include MONAD
  val mzero : 'a t
  val mplus : 'a t -> 'a t -> 'a t
end

module type MONAD_PLUS_OPS = sig
  include MONAD_OPS
  val mzero : 'a monad
  val mplus : 'a monad -> 'a monad -> 'a monad
  val fail : 'a monad
  val (++) : 'a monad -> 'a monad -> 'a monad
  val guard : bool -> unit monad
  val msum_map : ('a -> 'b monad) -> 'a list -> 'b monad
end

module MonadPlusOps (M : MONAD_PLUS) = struct
  open M
  include MonadOps(M)
  let fail = mzero
  let (++) a b = mplus a b
  let guard p = if p then return () else fail
  let msum_map f l = List.fold_right
    (fun a acc -> mplus (f a) acc) l mzero
end

module MonadPlus (M : MONAD_PLUS) :
sig
  include MONAD_PLUS_OPS
  val run : 'a monad -> 'a M.t
end = struct
  include M
  include MonadPlusOps(M)
end

module LazyM = Monad (struct
  type 'a t = 'a Lazy.t
  let bind a b = lazy (Lazy.force (b (Lazy.force a)))
  let return a = lazy a
end)
let laccess m = Lazy.force (LazyM.run m)

module ListM = MonadPlus (struct
  type 'a t = 'a list
  let bind a b = concat_map b a
  let return a = [a]
  let mzero = []
  let mplus = List.append
end)

module Countdown (M : MONAD_PLUS_OPS) = struct
  open M

  let rec insert x = function
    | [] -> return [x]
    | y::ys as xs ->
      return (x::xs) ++
        perform xys <-- insert x ys; return (y::xys)

  let rec choices = function
    | [] -> return []
    | x::xs -> perform
        cxs <-- choices xs;
        return cxs ++ insert x cxs

  type op = Add | Sub | Mul | Div

  let apply op x y =
    match op with
    | Add -> x + y
    | Sub -> x - y
    | Mul -> x * y
    | Div -> x / y

  let valid op x y =
    match op with
    | Add -> x <= y
    | Sub -> x > y
    | Mul -> x <= y && x <> 1 && y <> 1
    | Div -> x mod y = 0 && y <> 1

  type expr = Val of int | App of op * expr * expr

  let op2str = function
    | Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/"
  let rec expr2str = function
    | Val n -> string_of_int n
    | App (op,l,r) -> "("^expr2str l^op2str op^expr2str r^")"

  let combine (l,x) (r,y) o = perform
      guard (valid o x y);
      return (App (o,l,r), apply o x y)

  let split l =
    let rec aux lhs = function
      | [] | [_] -> fail
      | [y; z] -> return (List.rev (y::lhs), [z])
      | hd::rhs ->
        let lhs = hd::lhs in
        return (List.rev lhs, rhs)
          ++ aux lhs rhs in
    aux [] l

  let rec results = function
    | [] -> fail
    | [n] -> perform
        guard (n > 0); return (Val n, n)
    | ns -> perform
        (ls, rs) <-- split ns;
        lx <-- results ls;
        ly <-- results rs;
        msum_map (combine lx ly) [Add; Sub; Mul; Div]

  let solutions ns n = perform
      ns' <-- choices ns;
      (e,m) <-- results ns';
      guard (m=n);
      return (expr2str e)
end

#load "unix.cma";;
let time f =
  let tbeg = Unix.gettimeofday () in
  let res = f () in
  let tend = Unix.gettimeofday () in
  tend -. tbeg, res

module ListCountdown = Countdown (ListM)
let test1 () = ListM.run (ListCountdown.solutions [1;3;7;10;25;50] 765)
let t1, sol1 = time test1

(*
val t1 : float = 2.2856600284576416
val sol1 : string list =
  ["((25-(3+7))*(1+50))"; "(((25-3)-7)*(1+50))"; ...
  "(((25-7)-3)*(1+50))";
*)

type 'a llist = LNil | LCons of 'a * 'a llist Lazy.t
let rec ltake n = function
 | LCons (a, lazy l) when n > 0 -> a::(ltake (n-1) l)
 | _ -> []
let rec lappend l1 l2 =
  match l1 with LNil -> l2
  | LCons (hd, tl) ->
    LCons (hd, lazy (lappend (Lazy.force tl) l2))
let rec lconcat_map f = function
  | LNil -> LNil
  | LCons (a, lazy l) ->
    lappend (f a) (lconcat_map f l)
  
module LListM = MonadPlus (struct
  type 'a t = 'a llist
  let bind a b = lconcat_map b a
  let return a = LCons (a, lazy LNil)
  let mzero = LNil
  let mplus = lappend
end)

module LListCountdown = Countdown (LListM)
let test2 () = LListM.run (LListCountdown.solutions [1;3;7;10;25;50] 765)
let t2a, sol2 = time test2
let t2b, sol2_1 = time (fun () -> ltake 1 sol2)
let t2c, sol2_9 = time (fun () -> ltake 10 sol2)
let t2d, sol2_39 = time (fun () -> ltake 49 sol2)

(*
# let t2a, sol2 = time test2;;
val t2a : float = 2.51197600364685059
val sol2 : string llist = LCons ("((25-(3+7))*(1+50))", <lazy>)
# let t2b, sol2_1 = time (fun () -> ltake 1 sol2);;
val t2b : float = 2.86102294921875e-06
val sol2_1 : string list = ["((25-(3+7))*(1+50))"]
# let t2c, sol2_9 = time (fun () -> ltake 10 sol2);;
val t2c : float = 9.059906005859375e-06
val sol2_9 : string list =
  ["((25-(3+7))*(1+50))"; "(((25-3)-7)*(1+50))"; ... ]
# let t2d, sol2_39 = time (fun () -> ltake 49 sol2);;
val t2d : float = 4.00543212890625e-05
val sol2_39 : string list =
  ["((25-(3+7))*(1+50))"; "(((25-3)-7)*(1+50))"; ... ]
*)

module OptionM = MonadPlus (struct
  type 'a t = 'a option
  let bind a b =
    match a with None -> None | Some x -> b x
  let return a = Some a
  let mzero = None
  let mplus a b = match a with None -> b | Some _ -> a
end)

module OptCountdown = Countdown (OptionM)
let test3 () = OptionM.run (OptCountdown.solutions [1;3;7;10;25;50] 765)
let t3, sol3 = time test3
(* 
# let t3, sol3 = time test3;;
val t3 : float = 5.0067901611328125e-06
val sol3 : string option = None
 *)

type 'a lazy_list = 'a lazy_list_ Lazy.t
and 'a lazy_list_ = LazNil | LazCons of 'a * 'a lazy_list
let rec laztake n = function
 | lazy (LazCons (a, l)) when n > 0 ->
   a::(laztake (n-1) l)
 | _ -> []
let rec append_aux l1 l2 =
  match l1 with lazy LazNil -> Lazy.force l2
  | lazy (LazCons (hd, tl)) ->
    LazCons (hd, lazy (append_aux tl l2))
let lazappend l1 l2 = lazy (append_aux l1 l2)
let rec concat_map_aux f = function
  | lazy LazNil -> LazNil
  | lazy (LazCons (a, l)) ->
    append_aux (f a) (lazy (concat_map_aux f l))
let lazconcat_map f l = lazy (concat_map_aux f l)
  
module LazyListM = MonadPlus (struct
  type 'a t = 'a lazy_list
  let bind a b = lazconcat_map b a
  let return a = lazy (LazCons (a, lazy LazNil))
  let mzero = lazy LazNil
  let mplus = lazappend
end)

module LazyCountdown = Countdown (LazyListM)
let test4 () = LazyListM.run (LazyCountdown.solutions [1;3;7;10;25;50] 765)
let t4a, sol4 = time test4
let t4b, sol4_1 = time (fun () -> laztake 1 sol4)
let t4c, sol4_9 = time (fun () -> laztake 10 sol4)
let t4d, sol4_39 = time (fun () -> laztake 49 sol4)

(* 
# let t4a, sol4 = time test4;;
val t4a : float = 2.86102294921875e-06
val sol4 : string lazy_list = <lazy>
# let t4b, sol4_1 = time (fun () -> laztake 1 sol4);;
val t4b : float = 0.367874860763549805
val sol4_1 : string list = ["((25-(3+7))*(1+50))"]
# let t4c, sol4_9 = time (fun () -> laztake 10 sol4);;
val t4c : float = 0.234670877456665039
val sol4_9 : string list =
  ["((25-(3+7))*(1+50))"; "(((25-3)-7)*(1+50))"; ...]
# let t4d, sol4_39 = time (fun () -> laztake 49 sol4);;
val t4d : float = 4.0594940185546875
val sol4_39 : string list =
  ["((25-(3+7))*(1+50))"; "(((25-3)-7)*(1+50))"; ...]
 *)

let rec badappend l1 l2 =
  match l1 with lazy LazNil -> l2
  | lazy (LazCons (hd, tl)) ->
    lazy (LazCons (hd, badappend tl l2))
let rec badconcat_map f = function
  | lazy LazNil -> lazy LazNil
  | lazy (LazCons (a, l)) ->
    badappend (f a) (badconcat_map f l)

module BadyListM = MonadPlus (struct
  type 'a t = 'a lazy_list
  let bind a b = badconcat_map b a
  let return a = lazy (LazCons (a, lazy LazNil))
  let mzero = lazy LazNil
  let mplus = badappend
end)

module BadyCountdown = Countdown (BadyListM)
let test5 () = BadyListM.run (BadyCountdown.solutions [1;3;7;10;25;50] 765)
let t5a, sol5 = time test5
let t5b, sol5_1 = time (fun () -> laztake 1 sol5)
let t5c, sol5_9 = time (fun () -> laztake 10 sol5)
let t5d, sol5_39 = time (fun () -> laztake 49 sol5)

(* 
# let t5a, sol5 = time test5;;
val t5a : float = 3.3954310417175293
val sol5 : string lazy_list = <lazy>
# let t5b, sol5_1 = time (fun () -> laztake 1 sol5);;
val t5b : float = 3.0994415283203125e-06
val sol5_1 : string list = ["((25-(3+7))*(1+50))"]
# let t5c, sol5_9 = time (fun () -> laztake 10 sol5);;
val t5c : float = 7.8678131103515625e-06
val sol5_9 : string list =
  ["((25-(3+7))*(1+50))"; "(((25-3)-7)*(1+50))"; ... ]
# let t5d, sol5_39 = time (fun () -> laztake 49 sol5);;
val t5d : float = 2.59876251220703125e-05
val sol5_39 : string list =
  ["((25-(3+7))*(1+50))"; "(((25-3)-7)*(1+50))"; ... ]
 *)

module ExceptionM(Excn : sig type t end) : sig
  type excn = Excn.t
  type 'a t = OK of 'a | Bad of excn
  include MONAD_OPS
  val run : 'a monad -> 'a t
  val throw : excn -> 'a monad
  val catch : 'a monad -> (excn -> 'a monad) -> 'a monad
end = struct
  type excn = Excn.t
  module M = struct
    type 'a t = OK of 'a | Bad of excn
    let return a = OK a
    let bind m b = match m with
      | OK a -> b a
      | Bad e -> Bad e
  end
  include M
  include MonadOps(M)
  let throw e = Bad e
  let catch m handler = match m with
    | OK _ -> m
    | Bad e -> handler e
end    

(* Exercise 4
type 'a tree = Empty | Leaf of 'a | T of 'a t * 'a t
module TreeM = MonadPlus (struct
  type 'a t = 'a tree
  let bind a b = TODO
  let return a = TODO
  let mzero = TODO
  let mplus a b = TODO
end)
*)

(* For Exercise 8 *)
module type RMONAD = sig
  type ('s, 'a) t
  val return : 'a -> ('s, 'a) t
  val bind : ('s, 'a) t -> ('a -> ('s, 'b) t) -> ('s, 'b) t
end

module type RMONAD_OPS = sig
  type ('s, 'a) monad
  include RMONAD with type ('s, 'a) t := ('s, 'a) monad
  val ( >>= ) : ('s, 'a) monad -> ('a -> ('s, 'b) monad) -> ('s, 'b) monad
  val foldM :
    ('a -> 'b -> ('s, 'a) monad) -> 'a -> 'b list -> ('s, 'a) monad
  val whenM : bool -> ('s, unit) monad -> ('s, unit) monad
  val lift : ('a -> 'b) -> ('s, 'a) monad -> ('s, 'b) monad
  val join : ('s, ('s, 'a) monad) monad -> ('s, 'a) monad
  val ( >=> ) :
    ('a -> ('s, 'b) monad) -> ('b -> ('s, 'c) monad) -> 'a -> ('s, 'c) monad
end

module RMonadOps (M : RMONAD) = struct
  open M
  type ('s, 'a) monad = ('s, 'a) t
  let run x = x
  let (>>=) a b = bind a b
  let rec foldM f a = function
    | [] -> return a
    | x::xs -> f a x >>= fun a' -> foldM f a' xs
  let whenM p s = if p then s else return ()
  let lift f m = perform x <-- m; return (f x)
  let join m = perform x <-- m; x
  let (>=>) f g = fun x -> f x >>= g
end

module RMonad (M : RMONAD) :
sig
  include RMONAD_OPS
  val run : ('s, 'a) monad -> ('s, 'a) M.t
end = struct
  include M
  include RMonadOps(M)
end


(* The state monad *)

module type STATE = sig
  type store
  type 'a t
  val get : store t
  val put : store -> unit t
end

module StateM(Store : sig type t end) : sig
  type store = Store.t
  type 'a t = store -> 'a * store
  include MONAD_OPS
  include STATE with type 'a t := 'a monad
                and type store := store
  val run : 'a monad -> 'a t
end = struct
  type store = Store.t
  module M = struct
    type 'a t = store -> 'a * store
    let return a = fun s -> a, s
    let bind m b = fun s -> let a, s' = m s in b a s'
  end
  include M
  include MonadOps(M)
  let get = fun s -> s, s
  let put s' = fun _ -> (), s'
end    

type term =
| Var of string
| Lam of string * term
| App of term * term

module S =
  StateM(struct type t = int * (string * string) list end)
open S
let rec alpha_conv = function
  | Var x as v -> perform
    (fresh, env) <-- get;
    let v = try Var (List.assoc x env)
      with Not_found -> v in
    return v
  | Lam (x, t) -> perform
    (fresh, env) <-- get;
    let x' = x ^ string_of_int fresh in
    put (fresh+1, (x, x')::env);
    t' <-- alpha_conv t;
    (fresh', _) <-- get;
    put (fresh', env);
    return (Lam (x', t'))
  | App (t1, t2) -> perform
    t1 <-- alpha_conv t1;
    t2 <-- alpha_conv t2;
    return (App (t1, t2))

let (!.) x = Var x
let (|->) x t = Lam (x, t)
let (@.) t1 t2 = App (t1, t2)
let test = "x" |-> ("x" |-> !."y" @. !."x") @. !."x"
let _ = S.run (alpha_conv test) (5, [])

let alpha_conv t =
  let module S = StateM
        (struct type t = int * (string * string) list end) in
  let open S in
  let rec aux = function
    | Var x as v -> perform
      (fresh, env) <-- get;
      let v = try Var (List.assoc x env)
        with Not_found -> v in
      return v
    | Lam (x, t) -> perform
      (fresh, env) <-- get;
      let x' = x ^ string_of_int fresh in
      put (fresh+1, (x, x')::env);
      t' <-- aux t;
      (fresh', _) <-- get;
      put (fresh', env);
      return (Lam (x', t'))
    | App (t1, t2) -> perform
      t1 <-- aux t1; t2 <-- aux t2;
      return (App (t1, t2)) in
  run (aux t) (0, [])

(* Monad transformers: transformer adding state to a monad-plus.
   After running the transformed monad we get the original monad. *)

module StateT (MP : MONAD_PLUS_OPS) (Store : sig type t end) : sig
  type store = Store.t
  type 'a t = store -> ('a * store) MP.monad
  include MONAD_PLUS_OPS
  include STATE with type 'a t := 'a monad
                and type store := store
  val run : 'a monad -> 'a t
  val runT : 'a monad -> store -> 'a MP.monad
end = struct
  type store = Store.t
  module M = struct
    type 'a t = store -> ('a * store) MP.monad
    let return a = fun s -> MP.return (a, s)
    let bind m b = fun s ->
      MP.bind (m s) (fun (a, s') -> b a s')
    let mzero = fun _ -> MP.mzero
    let mplus ma mb = fun s -> MP.mplus (ma s) (mb s)
  end
  include M
  include MonadPlusOps(M)
  let get = fun s -> MP.return (s, s)
  let put s' = fun _ -> MP.return ((), s')
  let runT m s = MP.lift fst (m s)
end    

(* We are ready to recreate Honey Islands solver monadically. *)
module HoneyIslands (M : MONAD_PLUS_OPS) = struct

  type state = {
    been_size: int;
    been_islands: int;
    unvisited: cell list;
    visited: CellSet.t;
    eaten: cell list;
    more_to_eat: int;
  }

  let init_state unvisited more_to_eat = {
    been_size = 0;
    been_islands = 0;
    unvisited;
    visited = CellSet.empty;
    eaten = [];
    more_to_eat;
  }

  module BacktrackingM =
    StateT (M) (struct type t = state end)
  open BacktrackingM

  let rec visit_cell () = perform
      s <-- get;
      match s.unvisited with
      | [] -> return None
      | c::remaining when CellSet.mem c s.visited -> perform
        put {s with unvisited=remaining};
        visit_cell ()
    | c::remaining (* when c not visited *) -> perform
        put {s with
          unvisited=remaining;
          visited = CellSet.add c s.visited};
        return (Some c)

  let eat_cell c = perform
      s <-- get;
      put {s with eaten = c::s.eaten;
        visited = CellSet.add c s.visited;
        more_to_eat = s.more_to_eat - 1};
      return ()

  let keep_cell c = perform
      s <-- get;
      put {s with
        visited = CellSet.add c s.visited;
        been_size = s.been_size + 1};
      return ()

  let fresh_island = perform
      s <-- get;
      put {s with been_size = 0;
        been_islands = s.been_islands + 1};
      return ()

  let find_to_eat n island_size num_islands empty_cells =
    let honey = honey_cells n empty_cells in

    let rec find_board () = perform
        cell <-- visit_cell ();
        match cell with
        | None -> perform
            s <-- get;
            guard (s.been_islands = num_islands);
            return s.eaten
        | Some cell -> perform
            fresh_island;
            find_island cell;
            s <-- get;
            guard (s.been_size = island_size);
            find_board ()

    and find_island current = perform
        keep_cell current;
        neighbors n empty_cells current
        |> foldM
            (fun () neighbor -> perform
                s <-- get;
                whenM (not (CellSet.mem neighbor s.visited))
                  (let choose_eat = perform
                      guard (s.more_to_eat > 0);
                      eat_cell neighbor
                  and choose_keep = perform
                      guard (s.been_size < island_size);
                      find_island neighbor in
                  choose_eat ++ choose_keep)) () in
    
    let cells_to_eat =
      List.length honey - island_size * num_islands in
    init_state honey cells_to_eat
    |> runT (find_board ())

end

module HoneyL = HoneyIslands (ListM)
let find_to_eat a b c d =
  ListM.run (HoneyL.find_to_eat a b c d)

(* *
let ans0 = find_to_eat test_task0.board_size test_task0.island_size
  test_task0.num_islands test_task0.empty_cells
let _ = draw_to_screen ~w ~h
  (draw_honeycomb ~w ~h test_task0 (List.hd ans0))
let ans1 = find_to_eat test_task1.board_size test_task1.island_size
  test_task1.num_islands test_task1.empty_cells
let _ = draw_to_screen ~w ~h
  (draw_honeycomb ~w ~h test_task1 (List.hd ans1))
let ans3 = find_to_eat test_task3.board_size test_task3.island_size
  test_task3.num_islands test_task3.empty_cells
let _ = draw_to_screen ~w ~h
  (draw_honeycomb ~w ~h test_task3 (List.hd ans3))
* *)


(* ********** Probabilistic Programming ********** *)

module type PROBABILITY = sig
  include MONAD_OPS
  val choose : float -> 'a monad -> 'a monad -> 'a monad
  val pick : ('a * float) list -> 'a monad
  val uniform : 'a list -> 'a monad
  val coin : bool monad
  val flip : float -> bool monad
  val prob : ('a -> bool) -> 'a monad -> float
  val distrib : 'a monad -> ('a * float) list
  val access : 'a monad -> 'a
end

(* General helper functions. *)
let total dist =
  List.fold_left (fun a (_,b)->a+.b) 0. dist
let merge dist =
  map_reduce (fun x->x) (+.) 0. dist
let normalize dist = 
  let tot = total dist in
  if tot = 0. then dist
  else List.map (fun (e,w)->e,w/.tot) dist
let roulette dist =
  let tot = total dist in
  let rec aux r = function [] -> assert false
    | (e,w)::_ when w <= r -> e
    | (_,w)::tl -> aux (r-.w) tl in
  aux (Random.float tot) dist

(* Exact distribution monad, naive implementation. *)
module DistribM : PROBABILITY = struct
  module M = struct
    type 'a t = ('a * float) list
    let bind a b = merge
      [y, q*.p | (x,p) <- a; (y,q) <- b x]
    let return a = [a, 1.]
  end
  include M include MonadOps (M)
  let choose p a b =
    List.map (fun (e,w) -> e, p*.w) a @
      List.map (fun (e,w) -> e, (1. -.p)*.w) b
  let pick dist = dist
  let uniform elems = normalize
    (List.map (fun e->e,1.) elems)
  let coin = [true, 0.5; false, 0.5]
  let flip p = [true, p; false, 1. -. p]
  let prob p m = m
    |> List.filter (fun (e,_) -> p e)
    |> List.map snd |> List.fold_left (+.) 0.
  let distrib m = m
  let access m = roulette m
end

module SamplingM (S : sig val samples : int end)
  : PROBABILITY = struct
  module M = struct
    type 'a t = unit -> 'a
    let bind a b () = b (a ()) ()
    let return a = fun () -> a
  end
  include M include MonadOps (M)
  let choose p a b () =
    if Random.float 1. <= p then a () else b ()
  let pick dist = fun () -> roulette dist
  let uniform elems =
    let n = List.length elems in
    fun () -> List.nth elems (Random.int n)
  let coin = Random.bool
  let flip p = choose p (return true) (return false)
  let prob p m =
    let count = ref 0 in
    for i = 1 to S.samples do
      if p (m ()) then incr count
    done;
    float_of_int !count /. float_of_int S.samples
  let distrib m =
    let dist = ref [] in
    for i = 1 to S.samples do
      dist := (m (), 1.) :: !dist done;
    normalize (merge !dist)
  let access m = m ()
end

(* Example: The Monty Hall problem *)
module MontyHall (P : PROBABILITY) = struct
  open P
  type door = A | B | C
  let doors = [A; B; C]

  let monty_win switch = perform
      prize <-- uniform doors;
      chosen <-- uniform doors;
      opened <-- uniform
        (list_diff doors [prize; chosen]);
      let final =
        if switch then List.hd
          (list_diff doors [opened; chosen])
        else chosen in
      return (final = prize)
end

module MontyExact = MontyHall (DistribM)
module Sampling1000 =
  SamplingM (struct let samples = 1000 end)
module MontySimul = MontyHall (Sampling1000)

let t1 = DistribM.distrib (MontyExact.monty_win false)
let t2 = DistribM.distrib (MontyExact.monty_win true)
let t3 = Sampling1000.distrib (MontySimul.monty_win false)
let t4 = Sampling1000.distrib (MontySimul.monty_win true)
;;
(* Conditionals *)

module type COND_PROBAB = sig
  include PROBABILITY
  include MONAD_PLUS_OPS with type 'a monad := 'a monad
end

module DistribMP : COND_PROBAB = struct
  module MP = struct
    type 'a t = ('a * float) list
    let bind a b = merge
      [y, q*.p | (x,p) <- a; (y,q) <- b x]
    let return a = [a, 1.]
    let mzero = []
    let mplus = List.append
  end
  include MP include MonadPlusOps (MP)
  let choose p a b =
    List.map (fun (e,w) -> e, p*.w) a @
      List.map (fun (e,w) -> e, (1. -.p)*.w) b
  let pick dist = dist
  let uniform elems = normalize
    (List.map (fun e->e,1.) elems)
  let coin = [true, 0.5; false, 0.5]
  let flip p = [true, p; false, 1. -. p]
  let prob p m = normalize m
    |> List.filter (fun (e,_) -> p e)
    |> List.map snd |> List.fold_left (+.) 0.
  let distrib m = normalize m
  let access m = roulette m
end

module SamplingMP (S : sig val samples : int end)
  : COND_PROBAB = struct
  exception Rejected
  module MP = struct
    type 'a t = unit -> 'a
    let bind a b () = b (a ()) ()
    let return a = fun () -> a
    let mzero = fun () -> raise Rejected
    let mplus a b = fun () ->
      failwith "SamplingMP.mplus not implemented"
  end
  include MP include MonadPlusOps (MP)
  let choose p a b () =
    if Random.float 1. <= p then a () else b ()
  let pick dist = fun () -> roulette dist
  let uniform elems =
    let n = List.length elems in
    fun () -> List.nth elems (Random.int n)
  let coin = Random.bool
  let flip p = choose p (return true) (return false)
  let prob p m =
    let count = ref 0 and tot = ref 0 in
    while !tot < S.samples do
      try
        if p (m ()) then incr count;
        incr tot
      with Rejected -> ()
    done;
    float_of_int !count /. float_of_int S.samples
  let distrib m =
    let dist = ref [] and tot = ref 0 in
    while !tot < S.samples do
      try
        dist := (m (), 1.) :: !dist;
        incr tot
      with Rejected -> ()
    done;
    normalize (merge !dist)
  let rec access m =
    try m () with Rejected -> access m
end

module Burglary (P : COND_PROBAB) = struct
  open P
  type what_happened =
    Safe | Burgl | Earthq | Burgl_n_earthq

  let check ~john_called ~mary_called ~radio = perform
    earthquake <-- flip 0.002;
    guard (radio = None || radio = Some earthquake);
    burglary <-- flip 0.001;
    let alarm_p =
      match burglary, earthquake with
      | false, false -> 0.001
      | false, true -> 0.29
      | true, false -> 0.94
      | true, true -> 0.95 in
    alarm <-- flip alarm_p;
    let john_p = if alarm then 0.9 else 0.05 in
    john_calls <-- flip john_p;
    guard (john_calls = john_called);
    let mary_p = if alarm then 0.7 else 0.01 in
    mary_calls <-- flip mary_p;
    guard (mary_calls = mary_called);
    match burglary, earthquake with
    | false, false -> return Safe
    | true, false -> return Burgl
    | false, true -> return Earthq
    | true, true -> return Burgl_n_earthq
end
    
module BurglaryExact = Burglary (DistribMP)
module Sampling2000 =
  SamplingMP (struct let samples = 2000 end)
module BurglarySimul = Burglary (Sampling2000)

let t1 = DistribMP.distrib
  (BurglaryExact.check ~john_called:true ~mary_called:false
     ~radio:None)
let t2 = DistribMP.distrib
  (BurglaryExact.check ~john_called:true ~mary_called:true
     ~radio:None)
let t3 = DistribMP.distrib
  (BurglaryExact.check ~john_called:true ~mary_called:true
     ~radio:(Some true))
let t4 = Sampling2000.distrib
  (BurglarySimul.check ~john_called:true ~mary_called:false
     ~radio:None)
let t5 = Sampling2000.distrib
  (BurglarySimul.check ~john_called:true ~mary_called:true
     ~radio:None)
let t6 = Sampling2000.distrib
  (BurglarySimul.check ~john_called:true ~mary_called:true
     ~radio:(Some true))

  (* 
# let t1 = DistribMP.distrib
  (BurglaryExact.check ~john_called:true ~mary_called:false
     ~radio:None);;
    val t1 : (BurglaryExact.what_happened * float) list =
  [(BurglaryExact.Burgl_n_earthq, 1.03476433660005444e-05);
   (BurglaryExact.Earthq, 0.00452829235738691407);
   (BurglaryExact.Burgl, 0.00511951049003530299);
   (BurglaryExact.Safe, 0.99034184950921178)]
# let t2 = DistribMP.distrib
  (BurglaryExact.check ~john_called:true ~mary_called:true
     ~radio:None);;
    val t2 : (BurglaryExact.what_happened * float) list =
  [(BurglaryExact.Burgl_n_earthq, 0.00057437256500405794);
   (BurglaryExact.Earthq, 0.175492465840075218);
   (BurglaryExact.Burgl, 0.283597462799388911);
   (BurglaryExact.Safe, 0.540335698795532)]
# let t3 = DistribMP.distrib
  (BurglaryExact.check ~john_called:true ~mary_called:true
     ~radio:(Some true));;
    val t3 : (BurglaryExact.what_happened * float) list =
  [(BurglaryExact.Burgl_n_earthq, 0.0032622416021499262);
   (BurglaryExact.Earthq, 0.99673775839785006)]
# let t4 = Sampling2000.distrib
  (BurglarySimul.check ~john_called:true ~mary_called:false
     ~radio:None);;
    val t4 : (BurglarySimul.what_happened * float) list =
  [(BurglarySimul.Earthq, 0.0035); (BurglarySimul.Burgl, 0.0035);
   (BurglarySimul.Safe, 0.993)]
# let t5 = Sampling2000.distrib
  (BurglarySimul.check ~john_called:true ~mary_called:true
     ~radio:None);;
    val t5 : (BurglarySimul.what_happened * float) list =
  [(BurglarySimul.Burgl_n_earthq, 0.0005); (BurglarySimul.Earthq, 0.1715);
   (BurglarySimul.Burgl, 0.2875); (BurglarySimul.Safe, 0.5405)]
# let t6 = Sampling2000.distrib
  (BurglarySimul.check ~john_called:true ~mary_called:true
     ~radio:(Some true));;
    val t6 : (BurglarySimul.what_happened * float) list =
  [(BurglarySimul.Burgl_n_earthq, 0.0015); (BurglarySimul.Earthq, 0.9985)]

 *)


(* ********** Cooperative threads ********** *)
module type THREADS = sig
  include MONAD
  val parallel :
    'a t -> 'b t -> ('a -> 'b -> 'c t) -> 'c t
end

module type THREAD_OPS = sig
  include MONAD_OPS 
  include THREADS with type 'a t := 'a monad
  val parallel_map :
    'a list -> ('a -> 'b monad) -> 'b list monad
  val (>||=) :
    'a monad -> 'b monad -> ('a -> 'b -> 'c monad) ->
    'c monad
  val (>||) :
    'a monad -> 'b monad -> (unit -> 'c monad) ->
    'c monad
end

module type THREADSYS = sig
  include THREADS
  val access : 'a t -> 'a
  val kill_threads : unit -> unit
end

module ThreadOps (M : THREADS) = struct
  open M
  include MonadOps (M)
  let parallel_map l f =
    List.fold_right (fun a bs ->
      parallel (f a) bs
        (fun a bs -> return (a::bs))) l (return [])
  let (>||=) = parallel
  let (>||) a b c = parallel a b (fun _ _ -> c ())
end

module Threads (M : THREADSYS) :
sig
  include THREAD_OPS
  val access : 'a monad -> 'a
  val kill_threads : unit -> unit
end = struct
  include M
  include ThreadOps(M)
end

module Cooperative = Threads(struct
  type 'a state =
  | Return of 'a
  | Sleep of ('a -> unit) list
  | Link of 'a t
  and 'a t = {mutable state : 'a state}

  let rec find t =
    match t.state with
    | Link t -> find t
    | _ -> t

  let jobs = Queue.create ()

  let wakeup m a =
    let m = find m in
    match m.state with
    | Return _ -> assert false
    | Sleep waiters ->
      m.state <- Return a;
      List.iter ((|>) a) waiters
    | Link _ -> assert false

  let return a = {state = Return a}

  let connect t t' =
    let t' = find t' in
    match t'.state with
    | Sleep waiters' ->
      let t = find t in
      (match t.state with
      | Sleep waiters ->
        t.state <- Sleep (waiters' @ waiters);
        t'.state <- Link t
      | _ -> assert false)
    | Return x -> wakeup t x
    | Link _ -> assert false

  let rec bind a b =
    let a = find a in
    let m = {state = Sleep []} in
    (match a.state with
    | Return x ->
      let job () = connect m (b x) in
      Queue.push job jobs
    | Sleep waiters ->
      let job x = connect m (b x) in
      a.state <- Sleep (job::waiters)
    | Link _ -> assert false);
    m

  let parallel a b c = perform
    x <-- a;
    y <-- b;
    c x y

  let rec access m =
    let m = find m in
    match m.state with
    | Return x -> x
    | Sleep _ ->
      (try Queue.pop jobs ()
       with Queue.Empty ->
         failwith "access: result not available");
      access m
    | Link _ -> assert false

  let kill_threads () = Queue.clear jobs
end)

module TTest (T : THREAD_OPS) = struct
  open T
  let rec loop s n = perform
    return (Printf.printf "-- %s(%d)\n%!" s n);
    if n > 0 then loop s (n-1)
    else return ()
end
module TT = TTest (Cooperative)

let test =
  Cooperative.kill_threads ();
  let thread1 = TT.loop "A" 5 in
  let thread2 = TT.loop "B" 4 in
  Cooperative.access thread1;
  Cooperative.access thread2

(* 
# let test =
  Cooperative.kill_threads ();
  let thread1 = TT.loop "A" 5 in
  let thread2 = TT.loop "B" 4 in
  Cooperative.access thread1;
  Cooperative.access thread2;;
          -- A(5)
-- B(4)
-- A(4)
-- B(3)
-- A(3)
-- B(2)
-- A(2)
-- B(1)
-- A(1)
-- B(0)
-- A(0)
val test : unit = ()
 *)
