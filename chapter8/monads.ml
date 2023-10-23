(*
 * monads.ml
 *
 * Relies on features introduced in OCaml 3.12
 *
 * This library uses parameterized modules, see tree_monadize.ml for
 * more examples and explanation.
 *
 * Some comparisons with the Haskell monadic libraries, which we mostly follow:
 * In Haskell, the Reader 'a monadic type would be defined something like this:
 *     newtype Reader a = Reader { runReader :: env -> a }
 * (For simplicity, I'm suppressing the fact that Reader is also parameterized
 * on the type of env.)
 * This creates a type wrapper around `env -> a`, so that Haskell will
 * distinguish between values that have been specifically designated as
 * being of type `Reader a`, and common-garden values of type `env -> a`.
 * To lift an aribtrary expression E of type `env -> a` into an `Reader a`,
 * you do this:
 *     Reader { runReader = E }
 * or use any of the following equivalent shorthands:
 *     Reader (E)
 *     Reader $ E
 * To drop an expression R of type `Reader a` back into an `env -> a`, you do
 * one of these:
 *     runReader (R)
 *     runReader $ R
 * The `newtype` in the type declaration ensures that Haskell does this all
 * efficiently: though it regards E and R as type-distinct, their underlying
 * machine implementation is identical and doesn't need to be transformed when
 * lifting/dropping from one type to the other.
 *
 * Now, you _could_ also declare monads as record types in OCaml, too, _but_
 * doing so would introduce an extra level of machine representation, and
 * lifting/dropping from the one type to the other wouldn't be free like it is
 * in Haskell.
 *
 * This library encapsulates the monadic types in another way: by
 * making their implementations private. The interpreter won't let
 * let you freely interchange the `'a Reader_monad.m`s defined below
 * with `Reader_monad.env -> 'a`. The code in this library can see that
 * those are equivalent, but code outside the library can't. Instead, you'll
 * have to use operations like `run` to convert the abstract monadic types
 * to types whose internals you have free access to.
 *
 * Acknowledgements: This is largely based on the mtl library distributed
 * with the Glasgow Haskell Compiler. I've also been helped in
 * various ways by posts and direct feedback from Oleg Kiselyov and
 * Chung-chieh Shan. The following were also useful:
 * - <http://pauillac.inria.fr/~xleroy/mpri/progfunc/>
 * - Ken Shan "Monads for natural language semantics" <http://arxiv.org/abs/cs/0205026v1>
 * - http://www.grabmueller.de/martin/www/pub/Transformers.pdf
 * - http://en.wikibooks.org/wiki/Haskell/Monad_transformers
 *
 * Licensing: MIT (if that's compatible with the ghc sources this is partly
 * derived from)
 *)


(* Some library functions used below. *)

exception Undefined

module Util = struct
  let fold_right = List.fold_right
  let map = List.map
  let append = List.append
  let reverse = List.rev
  let concat = List.concat
  let concat_map f lst = List.concat (List.map f lst)
  (* let zip = List.combine *)
  let unzip = List.split
  let zip_with = List.map2
  let replicate len fill =
    let rec loop n accu =
      if n == 0 then accu else loop (pred n) (fill :: accu)
    in loop len []
  (* Dirty hack to be a default polymorphic zero.
   * To implement this cleanly, monads without a natural zero
   * should always wrap themselves in an option layer (see Tree_monad). *)
  let undef = Obj.magic (fun () -> raise Undefined)
end

(*
 * This module contains factories that extend a base set of
 * monadic definitions with a larger family of standard derived values.
 *)

module Monad = struct

  (*
   * Signature extenders:
   *   Make :: BASE -> S
   *   MakeT :: BASET (with Wrapped : S) -> result sig not declared
   *)


  (* type of base definitions *)
  module type BASE = sig
    (* We make all monadic types doubly-parameterized so that they
     * can layer nicely with Continuation, which needs the second
     * type parameter. *)
    type ('x,'a) m
    type ('x,'a) result
    type ('x,'a) result_exn
    val unit : 'a -> ('x,'a) m
    val bind : ('x,'a) m -> ('a -> ('x,'b) m) -> ('x,'b) m
    val run : ('x,'a) m -> ('x,'a) result
    (* run_exn tries to provide a more ground-level result, but may fail *)
    val run_exn : ('x,'a) m -> ('x,'a) result_exn
    (* To simplify the library, we require every monad to supply a plus and zero. These obey the following laws:
     *     zero >>= f   ===  zero
     *     plus zero u  ===  u
     *     plus u zero  ===  u
     * Additionally, they will obey one of the following laws:
     *     (Catch)   plus (unit a) v  ===  unit a
     *     (Distrib) plus u v >>= f   ===  plus (u >>= f) (v >>= f)
     * When no natural zero is available, use `let zero () = Util.undef`.
     * The Make functor automatically detects for zero >>= ..., and
     * plus zero _, plus _ zero; it also substitutes zero for pattern-match failures.
     *)
    val zero : unit -> ('x,'a) m
    (* zero has to be thunked to ensure results are always poly enough *)
    val plus : ('x,'a) m -> ('x,'a) m -> ('x,'a) m
  end
  module type S = sig
    include BASE
    val (>>=) : ('x,'a) m -> ('a -> ('x,'b) m) -> ('x,'b) m
    val (>>) : ('x,'a) m -> ('x,'b) m -> ('x,'b) m
    val join : ('x,('x,'a) m) m -> ('x,'a) m
    val apply : ('x,'a -> 'b) m -> ('x,'a) m -> ('x,'b) m
    val lift : ('a -> 'b) -> ('x,'a) m -> ('x,'b) m
    val lift2 :  ('a -> 'b -> 'c) -> ('x,'a) m -> ('x,'b) m -> ('x,'c) m
    val (>=>) : ('a -> ('x,'b) m) -> ('b -> ('x,'c) m) -> 'a -> ('x,'c) m
    val do_when :  bool -> ('x,unit) m -> ('x,unit) m
    val do_unless :  bool -> ('x,unit) m -> ('x,unit) m
    val forever : (unit -> ('x,'a) m) -> ('x,'b) m
    val sequence : ('x,'a) m list -> ('x,'a list) m
    val sequence_ : ('x,'a) m list -> ('x,unit) m
    val guard : bool -> ('x,unit) m
    val sum : ('x,'a) m list -> ('x,'a) m
  end

  module Make(B : BASE) : S with type ('x,'a) m = ('x,'a) B.m and type ('x,'a) result = ('x,'a) B.result and type ('x,'a) result_exn = ('x,'a) B.result_exn = struct
    include B
    let bind (u : ('x,'a) m) (f : 'a -> ('x,'b) m) : ('x,'b) m =
      if u == Util.undef then Util.undef
      else B.bind u (fun a -> try f a with Match_failure _ -> zero ())
    let plus u v =
      if u == Util.undef then v else if v == Util.undef then u else B.plus u v
    let run u =
      if u == Util.undef then raise Undefined else B.run u
    let run_exn u =
      if u == Util.undef then raise Undefined else B.run_exn u
    let (>>=) = bind
    (* expressions after >> will be evaluated before they're passed to
     * bind, so you can't do `zero () >> assert false`
     * this works though: `zero () >>= fun _ -> assert false`
     *)
    let (>>) u v = u >>= fun _ -> v
    let lift f u = u >>= fun a -> unit (f a)
    (* lift is called listM, fmap, and <$> in Haskell *)
    let join uu = uu >>= fun u -> u
    (* u >>= f === join (lift f u) *)
    let apply u v = u >>= fun f -> v >>= fun a -> unit (f a)
    (* [f] <*> [x1,x2] = [f x1,f x2] *)
    (* let apply u v = u >>= fun f -> lift f v *)
    (* let apply = lift2 id *)
    let lift2 f u v = u >>= fun a -> v >>= fun a' -> unit (f a a')
    (* let lift f u === apply (unit f) u *)
    (* let lift2 f u v = apply (lift f u) v *)
    let (>=>) f g = fun a -> f a >>= g
    let do_when test u = if test then u else unit ()
    let do_unless test u = if test then unit () else u
    (* A Haskell-like version works:
         let rec forever uthunk = uthunk () >>= fun _ -> forever uthunk
     * but the recursive call is not in tail position so this can stack overflow. *)
    let forever uthunk =
        let z = zero () in
        let id result = result in
        let kcell = ref id in
        let rec loop _ =
            let result = uthunk (kcell := id) >>= chained
            in !kcell result
        and chained _ =
            kcell := loop; z (* we use z only for its polymorphism *)
        in loop z
    (* Reimplementations of the preceding using a hand-rolled State or StateT
can also stack overflow. *)
    let sequence ms =
      let op u v = u >>= fun x -> v >>= fun xs -> unit (x :: xs) in
        Util.fold_right op ms (unit [])
    let sequence_ ms =
      Util.fold_right (>>) ms (unit ())

    (* Haskell defines these other operations combining lists and monads.
     * We don't, but notice that M.mapM == ListT(M).distribute
     * There's also a parallel TreeT(M).distribute *)
    (*
    let mapM f alist = sequence (Util.map f alist)
    let mapM_ f alist = sequence_ (Util.map f alist)
    let rec filterM f lst = match lst with
      | [] -> unit []
      | x::xs -> f x >>= fun flag -> filterM f xs >>= fun ys -> unit (if flag then x :: ys else ys)
    let forM alist f = mapM f alist
    let forM_ alist f = mapM_ f alist
    let map_and_unzipM f xs = sequence (Util.map f xs) >>= fun x -> unit (Util.unzip x)
    let zip_withM f xs ys = sequence (Util.zip_with f xs ys)
    let zip_withM_ f xs ys = sequence_ (Util.zip_with f xs ys)
    let rec foldM f z lst = match lst with
      | [] -> unit z
      | x::xs -> f z x >>= fun z' -> foldM f z' xs
    let foldM_ f z xs = foldM f z xs >> unit ()
    let replicateM n x = sequence (Util.replicate n x)
    let replicateM_ n x = sequence_ (Util.replicate n x)
    *)
    let guard test = if test then B.unit () else zero ()
    let sum ms = Util.fold_right plus ms (zero ())
  end

  (* Signatures for MonadT *)
  module type BASET = sig
    module Wrapped : S
    type ('x,'a) m
    type ('x,'a) result
    type ('x,'a) result_exn
    val bind : ('x,'a) m -> ('a -> ('x,'b) m) -> ('x,'b) m
    val run : ('x,'a) m -> ('x,'a) result
    val run_exn : ('x,'a) m -> ('x,'a) result_exn
    val elevate : ('x,'a) Wrapped.m -> ('x,'a) m
    (* lift/elevate laws:
     *     elevate (W.unit a) == unit a
     *     elevate (W.bind w f) == elevate w >>= fun a -> elevate (f a)
     *)
    val zero : unit -> ('x,'a) m
    val plus : ('x,'a) m -> ('x,'a) m -> ('x,'a) m
  end
  module MakeT(T : BASET) = struct
    include Make(struct
        include T
        let unit a = elevate (Wrapped.unit a)
    end)
    let elevate = T.elevate
  end

end





module Identity_monad : sig
  (* expose only the implementation of type `'a result` *)
  type ('x,'a) result = 'a
  type ('x,'a) result_exn = 'a
  include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
end = struct
  module Base = struct
    type ('x,'a) m = 'a
    type ('x,'a) result = 'a
    type ('x,'a) result_exn = 'a
    let unit a = a
    let bind a f = f a
    let run a = a
    let run_exn a = a
    let zero () = Util.undef
    let plus u v = u
  end
  include Monad.Make(Base)
end


module Maybe_monad : sig
  (* expose only the implementation of type `'a result` *)
  type ('x,'a) result = 'a option
  type ('x,'a) result_exn = 'a
  include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
  (* MaybeT transformer *)
  module T : functor (Wrapped : Monad.S) -> sig
    type ('x,'a) result = ('x,'a option) Wrapped.result
    type ('x,'a) result_exn = ('x,'a) Wrapped.result_exn
    include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
    val elevate : ('x,'a) Wrapped.m -> ('x,'a) m
  end
end = struct
  module Base = struct
    type ('x,'a) m = 'a option
    type ('x,'a) result = 'a option
    type ('x,'a) result_exn = 'a
    let unit a = Some a
    let bind u f = match u with Some a -> f a | None -> None
    let run u = u
    let run_exn u = match u with
      | Some a -> a
      | None -> failwith "no value"
    let zero () = None
    (* satisfies Catch *)
    let plus u v = match u with None -> v | _ -> u
  end
  include Monad.Make(Base)
  module T(Wrapped : Monad.S) = struct
    module BaseT = struct
      include Monad.MakeT(struct
        module Wrapped = Wrapped
        type ('x,'a) m = ('x,'a option) Wrapped.m
        type ('x,'a) result = ('x,'a option) Wrapped.result
        type ('x,'a) result_exn = ('x,'a) Wrapped.result_exn
        let elevate w = Wrapped.bind w (fun a -> Wrapped.unit (Some a))
        let bind u f = Wrapped.bind u (fun t -> match t with
          | Some a -> f a
          | None -> Wrapped.unit None)
        let run u = Wrapped.run u
        let run_exn u =
          let w = Wrapped.bind u (fun t -> match t with
            | Some a -> Wrapped.unit a
            | None -> Wrapped.zero ()
          ) in Wrapped.run_exn w
        let zero () = Wrapped.unit None
        let plus u v = Wrapped.bind u (fun t -> match t with | None -> v | _ -> u)
      end)
    end
    include BaseT
  end
end


module List_monad : sig
  (* declare additional operation, while still hiding implementation of type m *)
  type ('x,'a) result = 'a list
  type ('x,'a) result_exn = 'a
  include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
  val permute : ('x,'a) m -> ('x,('x,'a) m) m
  val select : ('x,'a) m -> ('x,'a * ('x,'a) m) m
  (* ListT transformer *)
  module T : functor (Wrapped : Monad.S) -> sig
    type ('x,'a) result = ('x,'a list) Wrapped.result
    type ('x,'a) result_exn = ('x,'a) Wrapped.result_exn
    include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
    val elevate : ('x,'a) Wrapped.m -> ('x,'a) m
    (* note that second argument is an 'a list, not the more abstract 'a m *)
    (* type is ('a -> 'b W) -> 'a list -> 'b list W == 'b listT(W) *)
    val distribute : ('a -> ('x,'b) Wrapped.m) -> 'a list -> ('x,'b) m
    val permute : ('x,'a) m -> ('x,('x,'a) m) m
    val select : ('x,'a) m -> ('x,('a * ('x,'a) m)) m
    val expose : ('x,'a) m -> ('x,'a list) Wrapped.m
  end
end = struct
  module Base = struct
   type ('x,'a) m = 'a list
   type ('x,'a) result = 'a list
   type ('x,'a) result_exn = 'a
   let unit a = [a]
   let bind u f = Util.concat_map f u
   let run u = u
   let run_exn u = match u with
     | [] -> failwith "no values"
     | [a] -> a
     | many -> failwith "multiple values"
   let zero () = []
   (* satisfies Distrib *)
   let plus = Util.append
  end
  include Monad.Make(Base)
  (* let either u v = plus u v *)
  (* insert 3 [1;2] ~~> [[3;1;2]; [1;3;2]; [1;2;3]] *)
  let rec insert a u =
    plus (unit (a :: u)) (match u with
        | [] -> zero ()
        | x :: xs -> (insert a xs) >>= fun v -> unit (x :: v)
    )
  (* permute [1;2;3] ~~> [1;2;3]; [2;1;3]; [2;3;1]; [1;3;2]; [3;1;2]; [3;2;1] *)
  let rec permute u = match u with
      | [] -> unit []
      | x :: xs -> (permute xs) >>= (fun v -> insert x v)
  (* select [1;2;3] ~~> [(1,[2;3]); (2,[1;3]), (3;[1;2])] *)
  let rec select u = match u with
    | [] -> zero ()
    | x::xs -> plus (unit (x, xs)) (select xs >>= fun (x', xs') -> unit (x', x :: xs'))
  module T(Wrapped : Monad.S) = struct
    (* Wrapped.sequence ms  ===
         let plus1 u v =
           Wrapped.bind u (fun x ->
           Wrapped.bind v (fun xs ->
           Wrapped.unit (x :: xs)))
         in Util.fold_right plus1 ms (Wrapped.unit []) *)
    (* distribute  ===  Wrapped.mapM; copies alist to its image under f *)
    let distribute f alist = Wrapped.sequence (Util.map f alist)

    include Monad.MakeT(struct
      module Wrapped = Wrapped
      type ('x,'a) m = ('x,'a list) Wrapped.m
      type ('x,'a) result = ('x,'a list) Wrapped.result
      type ('x,'a) result_exn = ('x,'a) Wrapped.result_exn
      let elevate w = Wrapped.bind w (fun a -> Wrapped.unit [a])
      let bind u f =
        Wrapped.bind u (fun ts ->
        Wrapped.bind (distribute f ts) (fun tts ->
        Wrapped.unit (Util.concat tts)))
      let run u = Wrapped.run u
      let run_exn u =
        let w = Wrapped.bind u (fun ts -> match ts with
          | [] -> Wrapped.zero ()
          | [a] -> Wrapped.unit a
          | many -> Wrapped.zero ()
        ) in Wrapped.run_exn w
      let zero () = Wrapped.unit []
      let plus u v =
        Wrapped.bind u (fun us ->
        Wrapped.bind v (fun vs ->
        Wrapped.unit (Base.plus us vs)))
    end)

   (* insert 3 {[1;2]} ~~> {[ {[3;1;2]}; {[1;3;2]}; {[1;2;3]} ]} *)
   let rec insert a u =
     plus
     (unit (Wrapped.bind u (fun us -> Wrapped.unit (a :: us))))
     (Wrapped.bind u (fun us -> match us with
         | [] -> zero ()
         | x::xs -> (insert a (Wrapped.unit xs)) >>= fun v -> unit (Wrapped.bind v (fun vs -> Wrapped.unit (x :: vs)))))

   (* select {[1;2;3]} ~~> {[ (1,{[2;3]}); (2,{[1;3]}), (3;{[1;2]}) ]} *)
   let rec select u =
     Wrapped.bind u (fun us -> match us with
         | [] -> zero ()
         | x::xs -> plus (unit (x, Wrapped.unit xs))
             (select (Wrapped.unit xs) >>= fun (x', xs') -> unit (x', Wrapped.bind xs' (fun ys -> Wrapped.unit (x :: ys)))))

   (* permute {[1;2;3]} ~~> {[ {[1;2;3]}; {[2;1;3]}; {[2;3;1]}; {[1;3;2]}; {[3;1;2]}; {[3;2;1]} ]} *)

   let rec permute u =
     Wrapped.bind u (fun us -> match us with
         | [] -> unit (zero ())
         | x::xs -> permute (Wrapped.unit xs) >>= (fun v -> insert x v))

    let expose u = u
  end
end


(* must be parameterized on (struct type err = ... end) *)
module Error_monad(Err : sig
  type err
  exception Exc of err
  (*
  val zero : unit -> err
  val plus : err -> err -> err
  *)
end) : sig
  (* declare additional operations, while still hiding implementation of type m *)
  type err = Err.err
  type 'a error = Error of err | Success of 'a
  type ('x,'a) result = 'a error
  type ('x,'a) result_exn = 'a
  include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
  val throw : err -> ('x,'a) m
  val catch : ('x,'a) m -> (err -> ('x,'a) m) -> ('x,'a) m
  (* ErrorT transformer *)
  module T : functor (Wrapped : Monad.S) -> sig
    type ('x,'a) result = ('x,'a) Wrapped.result
    type ('x,'a) result_exn = ('x,'a) Wrapped.result_exn
    include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
    val elevate : ('x,'a) Wrapped.m -> ('x,'a) m
    val throw : err -> ('x,'a) m
    val catch : ('x,'a) m -> (err -> ('x,'a) m) -> ('x,'a) m
  end
end = struct
  type err = Err.err
  type 'a error = Error of err | Success of 'a
  module Base = struct
    type ('x,'a) m = 'a error
    type ('x,'a) result = 'a error
    type ('x,'a) result_exn = 'a
    let unit a = Success a
    let bind u f = match u with
      | Success a -> f a
      | Error e -> Error e (* input and output may be of different 'a types *)
    let run u = u
    let run_exn u = match u with
      | Success a -> a
      | Error e -> raise (Err.Exc e)
    let zero () = Util.undef
    (* satisfies Catch *)
    let plus u v = match u with
      | Success _ -> u
      | Error _ -> if v == Util.undef then u else v
  end
  include Monad.Make(Base)
  (* include (Monad.MakeCatch(Base) : Monad.PLUS with type 'a m := 'a m) *)
  let throw e = Error e
  let catch u handler = match u with
    | Success _ -> u
    | Error e -> handler e
  module T(Wrapped : Monad.S) = struct
    include Monad.MakeT(struct
      module Wrapped = Wrapped
      type ('x,'a) m = ('x,'a error) Wrapped.m
      type ('x,'a) result = ('x,'a) Wrapped.result
      type ('x,'a) result_exn = ('x,'a) Wrapped.result_exn
      let elevate w = Wrapped.bind w (fun a -> Wrapped.unit (Success a))
      let bind u f = Wrapped.bind u (fun t -> match t with
        | Success a -> f a
        | Error e -> Wrapped.unit (Error e))
      let run u =
        let w = Wrapped.bind u (fun t -> match t with
          | Success a -> Wrapped.unit a
          | Error e -> Wrapped.zero ()
        ) in Wrapped.run w
      let run_exn u =
        let w = Wrapped.bind u (fun t -> match t with
          | Success a -> Wrapped.unit a
          | Error e -> raise (Err.Exc e))
        in Wrapped.run_exn w
      let plus u v = Wrapped.plus u v
      let zero () = Wrapped.zero () (* elevate (Wrapped.zero ()) *)
    end)
    let throw e = Wrapped.unit (Error e)
    let catch u handler = Wrapped.bind u (fun t -> match t with
      | Success _ -> Wrapped.unit t
      | Error e -> handler e)
  end
end

(* pre-define common instance of Error_monad *)
module Failure = Error_monad(struct
  type err = string
  exception Exc = Failure
  (*
  let zero = ""
  let plus s1 s2 = s1 ^ "\n" ^ s2
  *)
end)


(* must be parameterized on (struct type env = ... end) *)
module Reader_monad(Env : sig type env end) : sig
  (* declare additional operations, while still hiding implementation of type m *)
  type env = Env.env
  type ('x,'a) result = env -> 'a
  type ('x,'a) result_exn = env -> 'a
  include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
  val ask : ('x,env) m
  val asks : (env -> 'a) -> ('x,'a) m
  (* lookup i == `fun e -> e i` would assume env is a functional type *)
  val local : (env -> env) -> ('x,'a) m -> ('x,'a) m
  (* ReaderT transformer *)
  module T : functor (Wrapped : Monad.S) -> sig
    type ('x,'a) result = env -> ('x,'a) Wrapped.result
    type ('x,'a) result_exn = env -> ('x,'a) Wrapped.result_exn
    include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
    val elevate : ('x,'a) Wrapped.m -> ('x,'a) m
    val ask : ('x,env) m
    val asks : (env -> 'a) -> ('x,'a) m
    val local : (env -> env) -> ('x,'a) m -> ('x,'a) m
    val expose : ('x,'a) m -> env -> ('x,'a) Wrapped.m
  end
end = struct
  type env = Env.env
  module Base = struct
    type ('x,'a) m = env -> 'a
    type ('x,'a) result = env -> 'a
    type ('x,'a) result_exn = env -> 'a
    let unit a = fun e -> a
    let bind u f = fun e -> let a = u e in let u' = f a in u' e
    let run u = fun e -> u e
    let run_exn = run
    let zero () = Util.undef
    let plus u v = u
  end
  include Monad.Make(Base)
  let ask = fun e -> e
  let asks selector = ask >>= (fun e -> unit (selector e)) (* may fail *)
  let local modifier u = fun e -> u (modifier e)
  module T(Wrapped : Monad.S) = struct
    module BaseT = struct
      module Wrapped = Wrapped
      type ('x,'a) m = env -> ('x,'a) Wrapped.m
      type ('x,'a) result = env -> ('x,'a) Wrapped.result
      type ('x,'a) result_exn = env -> ('x,'a) Wrapped.result_exn
      let elevate w = fun e -> w
      let bind u f = fun e -> Wrapped.bind (u e) (fun a -> f a e)
      let run u = fun e -> Wrapped.run (u e)
      let run_exn u = fun e -> Wrapped.run_exn (u e)
      (* satisfies Distrib *)
      let plus u v = fun e -> Wrapped.plus (u e) (v e)
      let zero () = fun e -> Wrapped.zero () (* elevate (Wrapped.zero ()) *)
    end
    include Monad.MakeT(BaseT)
    let ask = Wrapped.unit
    let local modifier u = fun e -> u (modifier e)
    let asks selector = ask >>= (fun e ->
      try unit (selector e)
      with Not_found -> fun e -> Wrapped.zero ())
    let expose u = u
  end
end


(* must be parameterized on (struct type store = ... end) *)
module State_monad(Store : sig type store end) : sig
  (* declare additional operations, while still hiding implementation of type m *)
  type store = Store.store
  type ('x,'a) result =  store -> 'a * store
  type ('x,'a) result_exn = store -> 'a
  include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
  val get : ('x,store) m
  val gets : (store -> 'a) -> ('x,'a) m
  val put : store -> ('x,unit) m
  val puts : (store -> store) -> ('x,unit) m
  (* StateT transformer *)
  module T : functor (Wrapped : Monad.S) -> sig
    type ('x,'a) result = store -> ('x,'a * store) Wrapped.result
    type ('x,'a) result_exn = store -> ('x,'a) Wrapped.result_exn
    include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
    val elevate : ('x,'a) Wrapped.m -> ('x,'a) m
    val get : ('x,store) m
    val gets : (store -> 'a) -> ('x,'a) m
    val put : store -> ('x,unit) m
    val puts : (store -> store) -> ('x,unit) m
    (* val passthru : ('x,'a) m -> (('x,'a * store) Wrapped.result * store -> 'b) -> ('x,'b) m *)
    val expose : ('x,'a) m -> store -> ('x,'a * store) Wrapped.m
  end
end = struct
  type store = Store.store
  module Base = struct
    type ('x,'a) m =  store -> 'a * store
    type ('x,'a) result =  store -> 'a * store
    type ('x,'a) result_exn = store -> 'a
    let unit a = fun s -> (a, s)
    let bind u f = fun s -> let (a, s') = u s in let u' = f a in u' s'
    let run u = fun s -> (u s)
    let run_exn u = fun s -> fst (u s)
    let zero () = Util.undef
    let plus u v = u
  end
  include Monad.Make(Base)
  let get = fun s -> (s, s)
  let gets viewer = fun s -> (viewer s, s) (* may fail *)
  let put s = fun _ -> ((), s)
  let puts modifier = fun s -> ((), modifier s)
  module T(Wrapped : Monad.S) = struct
    module BaseT = struct
      module Wrapped = Wrapped
      type ('x,'a) m = store -> ('x,'a * store) Wrapped.m
      type ('x,'a) result = store -> ('x,'a * store) Wrapped.result
      type ('x,'a) result_exn = store -> ('x,'a) Wrapped.result_exn
      let elevate w = fun s ->
        Wrapped.bind w (fun a -> Wrapped.unit (a, s))
      let bind u f = fun s ->
        Wrapped.bind (u s) (fun (a, s') -> f a s')
      let run u = fun s -> Wrapped.run (u s)
      let run_exn u = fun s ->
        let w = Wrapped.bind (u s) (fun (a,s) -> Wrapped.unit a)
        in Wrapped.run_exn w
      (* satisfies Distrib *)
      let plus u v = fun s -> Wrapped.plus (u s) (v s)
      let zero () = fun s -> Wrapped.zero () (* elevate (Wrapped.zero ()) *)
    end
    include Monad.MakeT(BaseT)
    let get = fun s -> Wrapped.unit (s, s)
    let gets viewer = fun s ->
      try Wrapped.unit (viewer s, s)
      with Not_found -> Wrapped.zero ()
    let put s = fun _ -> Wrapped.unit ((), s)
    let puts modifier = fun s -> Wrapped.unit ((), modifier s)
    (* let passthru u f = fun s -> Wrapped.unit (f (Wrapped.run (u s), s), s) *)
    let expose u = u
  end
end


(* State monad with different interface (structured store) *)
module Ref_monad(V : sig
  type value
end) : sig
  type ref
  type value = V.value
  type ('x,'a) result = 'a
  type ('x,'a) result_exn = 'a
  include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
  val newref : value -> ('x,ref) m
  val deref : ref -> ('x,value) m
  val change : ref -> value -> ('x,unit) m
  (* RefT transformer *)
  module T : functor (Wrapped : Monad.S) -> sig
    type ('x,'a) result = ('x,'a) Wrapped.result
    type ('x,'a) result_exn = ('x,'a) Wrapped.result_exn
    include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
    val elevate : ('x,'a) Wrapped.m -> ('x,'a) m
    val newref : value -> ('x,ref) m
    val deref : ref -> ('x,value) m
    val change : ref -> value -> ('x,unit) m
  end
end = struct
  type ref = int
  type value = V.value
  module D = Map.Make(struct type t = ref let compare = compare end)
  type dict = { next: ref; tree : value D.t }
  let empty = { next = 0; tree = D.empty }
  let alloc (value : value) (d : dict) =
    (d.next, { next = succ d.next; tree = D.add d.next value d.tree })
  let read (key : ref) (d : dict) =
    D.find key d.tree
  let write (key : ref) (value : value) (d : dict) =
    { next = d.next; tree = D.add key value d.tree }
  module Base = struct
    type ('x,'a) m = dict -> 'a * dict
    type ('x,'a) result = 'a
    type ('x,'a) result_exn = 'a
    let unit a = fun s -> (a, s)
    let bind u f = fun s -> let (a, s') = u s in let u' = f a in u' s'
    let run u = fst (u empty)
    let run_exn = run
    let zero () = Util.undef
    let plus u v = u
  end
  include Monad.Make(Base)
  let newref value = fun s -> alloc value s
  let deref key = fun s -> (read key s, s) (* shouldn't fail because key will have an abstract type, and we never garbage collect *)
  let change key value = fun s -> ((), write key value s) (* shouldn't allocate because key will have an abstract type *)
  module T(Wrapped : Monad.S) = struct
    module BaseT = struct
      module Wrapped = Wrapped
      type ('x,'a) m = dict -> ('x,'a * dict) Wrapped.m
      type ('x,'a) result = ('x,'a) Wrapped.result
      type ('x,'a) result_exn = ('x,'a) Wrapped.result_exn
      let elevate w = fun s ->
        Wrapped.bind w (fun a -> Wrapped.unit (a, s))
      let bind u f = fun s ->
        Wrapped.bind (u s) (fun (a, s') -> f a s')
      let run u =
        let w = Wrapped.bind (u empty) (fun (a,s) -> Wrapped.unit a)
        in Wrapped.run w
      let run_exn u =
        let w = Wrapped.bind (u empty) (fun (a,s) -> Wrapped.unit a)
        in Wrapped.run_exn w
      (* satisfies Distrib *)
      let plus u v = fun s -> Wrapped.plus (u s) (v s)
      let zero () = fun s -> Wrapped.zero () (* elevate (Wrapped.zero ()) *)
    end
    include Monad.MakeT(BaseT)
    let newref value = fun s -> Wrapped.unit (alloc value s)
    let deref key = fun s -> Wrapped.unit (read key s, s)
    let change key value = fun s -> Wrapped.unit ((), write key value s)
  end
end


(* must be parameterized on (struct type log = ... end) *)
module Writer_monad(Log : sig
  type log
  val zero : log
  val plus : log -> log -> log
end) : sig
  (* declare additional operations, while still hiding implementation of type m *)
  type log = Log.log
  type ('x,'a) result = 'a * log
  type ('x,'a) result_exn = 'a * log
  include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
  val tell : log -> ('x,unit) m
  val listen : ('x,'a) m -> ('x,'a * log) m
  val listens : (log -> 'b) -> ('x,'a) m -> ('x,'a * 'b) m
  (* val pass : ('x,'a * (log -> log)) m -> ('x,'a) m *)
  val censor : (log -> log) -> ('x,'a) m -> ('x,'a) m
  (* WriterT transformer *)
  module T : functor (Wrapped : Monad.S) -> sig
    type ('x,'a) result = ('x,'a * log) Wrapped.result
    type ('x,'a) result_exn = ('x,'a * log) Wrapped.result_exn
    include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
    val elevate : ('x,'a) Wrapped.m -> ('x,'a) m
    val tell : log -> ('x,unit) m
    val listen : ('x,'a) m -> ('x,'a * log) m
    val listens : (log -> 'b) -> ('x,'a) m -> ('x,'a * 'b) m
    val censor : (log -> log) -> ('x,'a) m -> ('x,'a) m
  end
end = struct
  type log = Log.log
  module Base = struct
    type ('x,'a) m = 'a * log
    type ('x,'a) result = 'a * log
    type ('x,'a) result_exn = 'a * log
    let unit a = (a, Log.zero)
    let bind (a, w) f = let (b, w') = f a in (b, Log.plus w w')
    let run u = u
    let run_exn = run
    let zero () = Util.undef
    let plus u v = u
  end
  include Monad.Make(Base)
  let tell entries = ((), entries) (* add entries to log *)
  let listen (a, w) = ((a, w), w)
  let listens selector u = listen u >>= fun (a, w) -> unit (a, selector w) (* filter listen through selector *)
  let pass ((a, f), w) = (a, f w) (* usually use censor helper *)
  let censor f u = pass (u >>= fun a -> unit (a, f))
  module T(Wrapped : Monad.S) = struct
    module BaseT = struct
      module Wrapped = Wrapped
      type ('x,'a) m = ('x,'a * log) Wrapped.m
      type ('x,'a) result = ('x,'a * log) Wrapped.result
      type ('x,'a) result_exn = ('x,'a * log) Wrapped.result_exn
      let elevate w =
        Wrapped.bind w (fun a -> Wrapped.unit (a, Log.zero))
      let bind u f =
        Wrapped.bind u (fun (a, w) ->
        Wrapped.bind (f a) (fun (b, w') ->
        Wrapped.unit (b, Log.plus w w')))
      let zero () = elevate (Wrapped.zero ())
      let plus u v = Wrapped.plus u v
      let run u = Wrapped.run u
      let run_exn u = Wrapped.run_exn u
    end
    include Monad.MakeT(BaseT)
    let tell entries = Wrapped.unit ((), entries)
    let listen u = Wrapped.bind u (fun (a, w) -> Wrapped.unit ((a, w), w))
    let pass u = Wrapped.bind u (fun ((a, f), w) -> Wrapped.unit (a, f w))
    (* rest are derived in same way as before *)
    let listens selector u = listen u >>= fun (a, w) -> unit (a, selector w)
    let censor f u = pass (u >>= fun a -> unit (a, f))
  end
end

(* pre-define simple Writer *)
module Writer1 = Writer_monad(struct
  type log = string
  let zero = ""
  let plus s1 s2 = s1 ^ "\n" ^ s2
end)

(* slightly more efficient Writer *)
module Writer2 = struct
  include Writer_monad(struct
    type log = string list
    let zero = []
    let plus w w' = Util.append w' w
  end)
  let tell_string s = tell [s]
  let tell entries = tell (Util.reverse entries)
  let run u = let (a, w) = run u in (a, Util.reverse w)
  let run_exn = run
end


(* TODO needs a T *)
module IO_monad : sig
  (* declare additional operation, while still hiding implementation of type m *)
  type ('x,'a) result = 'a
  type ('x,'a) result_exn = 'a
  include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
  val printf : ('a, unit, string, ('x,unit) m) format4 -> 'a
  val print_string : string -> ('x,unit) m
  val print_int : int -> ('x,unit) m
  val print_hex : int -> ('x,unit) m
  val print_bool : bool -> ('x,unit) m
end = struct
  module Base = struct
    type ('x,'a) m = { run : unit -> unit; value : 'a }
    type ('x,'a) result = 'a
    type ('x,'a) result_exn = 'a
    let unit a = { run = (fun () -> ()); value = a }
    let bind (a : ('x,'a) m) (f: 'a -> ('x,'b) m) : ('x,'b) m =
     let fres = f a.value in
       { run = (fun () -> a.run (); fres.run ()); value = fres.value }
    let run a = let () = a.run () in a.value
    let run_exn = run
    let zero () = Util.undef
    let plus u v = u
  end
  include Monad.Make(Base)
  let printf fmt =
    Printf.ksprintf (fun s -> { Base.run = (fun () -> Pervasives.print_string s); value = () }) fmt
  let print_string s = { Base.run = (fun () -> Printf.printf "%s\n" s); value = () }
  let print_int i = { Base.run = (fun () -> Printf.printf "%d\n" i); value = () }
  let print_hex i = { Base.run = (fun () -> Printf.printf "0x%x\n" i); value = () }
  let print_bool b = { Base.run = (fun () -> Printf.printf "%B\n" b); value = () }
end


module Continuation_monad : sig
  (* expose only the implementation of type `('r,'a) result` *)
  type ('r,'a) m
  type ('r,'a) result = ('r,'a) m
  type ('r,'a) result_exn = ('a -> 'r) -> 'r
  include Monad.S with type ('r,'a) result := ('r,'a) result and type ('r,'a) result_exn := ('r,'a) result_exn and type ('r,'a) m := ('r,'a) m
  val callcc : (('a -> ('r,'b) m) -> ('r,'a) m) -> ('r,'a) m
  val reset : ('a,'a) m -> ('r,'a) m
  val shift : (('a -> ('q,'r) m) -> ('r,'r) m) -> ('r,'a) m
  (* val abort : ('a,'a) m -> ('a,'b) m *)
  val abort : 'a -> ('a,'b) m
  val run0 : ('a,'a) m -> 'a
  (* ContinuationT transformer *)
  module T : functor (Wrapped : Monad.S) -> sig
    type ('r,'a) m
    type ('r,'a) result = ('a -> ('r,'r) Wrapped.m) -> ('r,'r) Wrapped.result
    type ('r,'a) result_exn = ('a -> ('r,'r) Wrapped.m) -> ('r,'r) Wrapped.result_exn
    include Monad.S with type ('r,'a) result := ('r,'a) result and type ('r,'a) result_exn := ('r,'a) result_exn and type ('r,'a) m := ('r,'a) m
    val elevate : ('x,'a) Wrapped.m -> ('x,'a) m
    val callcc : (('a -> ('r,'b) m) -> ('r,'a) m) -> ('r,'a) m
    (* TODO: reset,shift,abort,run0 *)
  end
end = struct
  let id = fun i -> i
  module Base = struct
    (* 'r is result type of whole computation *)
    type ('r,'a) m = ('a -> 'r) -> 'r
    type ('r,'a) result = ('a -> 'r) -> 'r
    type ('r,'a) result_exn = ('r,'a) result
    let unit a = (fun k -> k a)
    let bind u f = (fun k -> (u) (fun a -> (f a) k))
    let run u k = (u) k
    let run_exn = run
    let zero () = Util.undef
    let plus u v = u
  end
  include Monad.Make(Base)
  let callcc f = (fun k ->
    let usek a = (fun _ -> k a)
    in (f usek) k)
  (*
  val callcc : (('a -> 'r) -> ('r,'a) m) -> ('r,'a) m
  val throw : ('a -> 'r) -> 'a -> ('r,'b) m
  let callcc f = fun k -> f k k
  let throw k a = fun _ -> k a
  *)

  (* from http://www.haskell.org/haskellwiki/MonadCont_done_right
   *
   *  reset :: (Monad m) => ContT a m a -> ContT r m a
   *  reset e = ContT $ \k -> runContT e return >>= k
   *
   *  shift :: (Monad m) => ((a -> ContT r m b) -> ContT b m b) -> ContT b m a
   *  shift e = ContT $ \k ->
   *              runContT (e $ \v -> ContT $ \c -> k v >>= c) return *)
  let reset u = unit ((u) id)
  let shift f = (fun k -> (f (fun a -> unit (k a))) id)
  (* let abort a = shift (fun _ -> a) *)
  let abort a = shift (fun _ -> unit a)
  let run0 (u : ('a,'a) m) = (u) id
  module T(Wrapped : Monad.S) = struct
    module BaseT = struct
      module Wrapped = Wrapped
      type ('r,'a) m = ('a -> ('r,'r) Wrapped.m) -> ('r,'r) Wrapped.m
      type ('r,'a) result = ('a -> ('r,'r) Wrapped.m) -> ('r,'r) Wrapped.result
      type ('r,'a) result_exn = ('a -> ('r,'r) Wrapped.m) -> ('r,'r) Wrapped.result_exn
      let elevate w = fun k -> Wrapped.bind w k
      let bind u f = fun k -> u (fun a -> f a k)
      let run u k = Wrapped.run (u k)
      let run_exn u k = Wrapped.run_exn (u k)
      let zero () = Util.undef
      let plus u v = u
    end
    include Monad.MakeT(BaseT)
    let callcc f = (fun k ->
      let usek a = (fun _ -> k a)
      in (f usek) k)
  end
end


(*
 * Scheme:
 * (define (example n)
 *    (let ([u (let/cc k ; type int -> int pair
 *               (let ([v (if (< n 0) (k 0) (list (+ n 100)))])
 *                 (+ 1 (car v))))]) ; int
 *      (cons u 0))) ; int pair
 * ; (example 10) ~~> '(111 . 0)
 * ; (example -10) ~~> '(0 . 0)
 *
 * OCaml monads:
 * let example n : (int * int) =
 *   Continuation_monad.(let u = callcc (fun k ->
 *       (if n < 0 then k 0 else unit [n + 100])
 *       (* all of the following is skipped by k 0; the end type int is k's input type *)
 *       >>= fun [x] -> unit (x + 1)
 *   )
 *   (* k 0 starts again here, outside the callcc (...); the end type int * int is k's output type *)
 *   >>= fun x -> unit (x, 0)
 *   in run u)
 *
 *)


module Tree_monad : sig
  (* We implement the type as `'a tree option` because it has a natural`plus`,
   * and the rest of the library expects that `plus` and `zero` will come together. *)
  type 'a tree = Leaf of 'a | Node of ('a tree * 'a tree)
  type ('x,'a) result = 'a tree option
  type ('x,'a) result_exn = 'a tree
  include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
  (* TreeT transformer *)
  module T : functor (Wrapped : Monad.S) -> sig
    type ('x,'a) result = ('x,'a tree option) Wrapped.result
    type ('x,'a) result_exn = ('x,'a tree) Wrapped.result_exn
    include Monad.S with type ('x,'a) result := ('x,'a) result and type ('x,'a) result_exn := ('x,'a) result_exn
    val elevate : ('x,'a) Wrapped.m -> ('x,'a) m
    (* note that second argument is an 'a tree?, not the more abstract 'a m *)
    (* type is ('a -> 'b W) -> 'a tree? -> 'b tree? W == 'b treeT(W) *)
    val distribute : ('a -> ('x,'b) Wrapped.m) -> 'a tree option -> ('x,'b) m
    val expose : ('x,'a) m -> ('x,'a tree option) Wrapped.m
  end
end = struct
  type 'a tree = Leaf of 'a | Node of ('a tree * 'a tree)
  (* uses supplied plus and zero to copy t to its image under f *)
  let mapT (f : 'a -> 'b) (t : 'a tree option) (zero : unit -> 'b) (plus : 'b -> 'b -> 'b) : 'b = match t with
      | None -> zero ()
      | Some ts -> let rec loop ts = (match ts with
                     | Leaf a -> f a
                     | Node (l, r) ->
                         (* recursive application of f may delete a branch *)
                         plus (loop l) (loop r)
                   ) in loop ts
  module Base = struct
    type ('x,'a) m = 'a tree option
    type ('x,'a) result = 'a tree option
    type ('x,'a) result_exn = 'a tree
    let unit a = Some (Leaf a)
    let zero () = None
    (* satisfies Distrib *)
    let plus u v = match (u, v) with
      | None, _ -> v
      | _, None -> u
      | Some us, Some vs -> Some (Node (us, vs))
    let bind u f = mapT f u zero plus
    let run u = u
    let run_exn u = match u with
      | None -> failwith "no values"
      (*
      | Some (Leaf a) -> a
      | many -> failwith "multiple values"
      *)
      | Some us -> us
  end
  include Monad.Make(Base)
  module T(Wrapped : Monad.S) = struct
    module BaseT = struct
      include Monad.MakeT(struct
        module Wrapped = Wrapped
        type ('x,'a) m = ('x,'a tree option) Wrapped.m
        type ('x,'a) result = ('x,'a tree option) Wrapped.result
        type ('x,'a) result_exn = ('x,'a tree) Wrapped.result_exn
        let zero () = Wrapped.unit None
        let plus u v =
          Wrapped.bind u (fun us ->
          Wrapped.bind v (fun vs ->
          Wrapped.unit (Base.plus us vs)))
        let elevate w = Wrapped.bind w (fun a -> Wrapped.unit (Some (Leaf a)))
        let bind u f = Wrapped.bind u (fun t -> mapT f t zero plus)
        let run u = Wrapped.run u
        let run_exn u =
            let w = Wrapped.bind u (fun t -> match t with
              | None -> Wrapped.zero ()
              | Some ts -> Wrapped.unit ts
            ) in Wrapped.run_exn w
      end)
    end
    include BaseT
    let distribute f t = mapT (fun a -> elevate (f a)) t zero plus
    let expose u = u
  end

end;;


