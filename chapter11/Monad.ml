(* Fragments of the file "Lec8.ml". *)

module type MONAD = sig
  type 'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
end

module type MONAD_OPS = sig
  type 'a monad
  include MONAD with type 'a t := 'a monad
  val ( >>= ) :'a monad -> ('a -> 'b monad) -> 'b monad
  val ( >>- ) :'a monad -> 'b monad -> 'b monad
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
  let (>>-) a b = bind a (fun _ -> b)
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
  val mplus : 'a t -> 'a t Lazy.t -> 'a t
end

module type MONAD_PLUS_OPS = sig
  include MONAD_OPS
  val mzero : 'a monad
  val mplus : 'a monad -> 'a monad Lazy.t -> 'a monad
  val fail : 'a monad
  val (++) : 'a monad -> 'a monad Lazy.t -> 'a monad
  val guard : bool -> unit monad
  val msum_map : ('a -> 'b monad) -> 'a list -> 'b monad
end

module MonadPlusOps (M : MONAD_PLUS) = struct
  open M
  include MonadOps(M)
  let fail = mzero
  let (++) a b = mplus a b
  let guard p = if p then return () else fail
  let msum_map f l =
    List.fold_left
      (fun acc a -> mplus acc (lazy (f a))) mzero l
end

module MonadPlus (M : MONAD_PLUS) :
sig
  include MONAD_PLUS_OPS
  val run : 'a monad -> 'a M.t
end = struct
  include M
  include MonadPlusOps(M)
end

type 'a llist = LNil | LCons of 'a * 'a llist Lazy.t
let rec ltake n = function
 | LCons (a, l) when n > 1 -> a::(ltake (n-1) (Lazy.force l))
 | LCons (a, l) when n = 1 -> [a]
 | _ -> []
let rec lappend l1 l2 =
  match l1 with LNil -> Lazy.force l2
  | LCons (hd, tl) ->
    LCons (hd, lazy (lappend (Lazy.force tl) l2))
let rec lconcat_map f = function
  | LNil -> LNil
  | LCons (a, l) ->
    lappend (f a) (lazy (lconcat_map f (Lazy.force l)))

module LListM = MonadPlus (struct
  type 'a t = 'a llist
  let bind a b = lconcat_map b a
  let return a = LCons (a, lazy LNil)
  let mzero = LNil
  let mplus = lappend
end)

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
    let mplus ma mb = fun s ->
      MP.mplus (ma s) (lazy (Lazy.force mb s))
  end
  include M
  include MonadPlusOps(M)
  let get = fun s -> MP.return (s, s)
  let put s' = fun _ -> MP.return ((), s')
  let runT m s = MP.lift fst (m s)
end    
