
module type MONAD = sig
  type 'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
end

module type MONAD_PLUS = sig
  include MONAD
  val mzero : 'a t
  val mplus : 'a t -> 'a t -> 'a t
end

module type Monad = sig
  type a
  module Repr (M : MONAD) : sig
    val extract : a M.t
  end
end

type 'a monad = (module Monad with type a = 'a)

module Make (M : MONAD) = struct
  include M
  let run (type s) (mx : s monad) : s t =
    let module MX = (val mx : Monad with type a = s) in
    let module RX = MX.Repr(M) in
    RX.extract
end

module type MonadPlus = sig
  type a
  module Repr (M : MONAD_PLUS) : sig
    val extract : a M.t
  end
end

type 'a monad_plus = (module MonadPlus with type a = 'a)

module MakePlus (M : MONAD_PLUS) = struct
  include M
  let run (type s) (mx : s monad_plus) : s t =
    let module MX = (val mx : MonadPlus with type a = s) in
    let module RX = MX.Repr(M) in
    RX.extract
end

let return : 'a . 'a -> 'a monad =
  fun (type s) x ->
  (module struct
    type a = s
    module Repr (M : MONAD) = struct
      let extract = M.return x
    end
  end : Monad with type a = s)

let bind : 'a . 'a monad -> ('a -> 'b monad) -> 'b monad =
  fun (type s) (type t) mx f ->
  (module struct
    type a = t
    type res = t
    module Repr (M : MONAD) = struct
      let extract =
        let module MX = (val mx : Monad with type a = s) in
        let module RX = MX.Repr(M) in
        M.(bind RX.extract (fun x ->
          let my = f x in
          let module MY = (val my : Monad with type a = res) in
          let module RY = MY.Repr(M) in
          RY.extract)
        )
    end
  end : Monad with type a = t)

let mzero : 'a . 'a monad_plus =
  fun (type s) ->
  (module struct
    type a = s
    module Repr (M : MONAD_PLUS) = struct
      let extract = M.mzero
    end
  end : MonadPlus with type a = s)

let mplus : 'a . 'a monad_plus ->'a monad_plus -> 'a monad_plus =
  fun (type s) mx my ->
  (module struct
    type a = s
    module Repr (M : MONAD_PLUS) = struct
      let extract =
        let module MX = (val mx : Monad with type a = s) in
        let module RX = MX.Repr(M) in
        let module MY = (val my : Monad with type a = s) in
        let module RY = MY.Repr(M) in
        M.(mplus RX.extract RY.extract)
    end
  end : MonadPlus with type a = s)

