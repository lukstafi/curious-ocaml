perform with (|->) in
  return 5;
  return 7

let guard p = if p then [()] else [];;
perform with (|->) in
  guard false;
  return 7;;

perform with (|->) in
  return 5;
  guard false;
  return 7;;


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

module ExceptionRM : sig
  type ('e, 'a) t = OK of 'a | Bad of 'e
  include RMONAD_OPS
  val run : ('e, 'a) monad -> ('e, 'a) t
  val throw : 'e -> ('e, 'a) monad
  val catch : ('e, 'a) monad -> ('e -> ('f, 'a) monad) -> ('f, 'a) monad
end = struct
  module M = struct
    type ('e, 'a) t = OK of 'a | Bad of 'e
    let return a = OK a
    let bind m b = match m with
      | OK a -> b a
      | Bad e -> Bad e
  end
  include M
  include RMonadOps(M)
  let throw e = Bad e
  let catch m handler = match m with
    | OK a -> OK a
    | Bad e -> handler e
end    
