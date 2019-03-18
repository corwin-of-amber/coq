(* Hash type *)
type t

val _0 : t
val _1 : t
val minus_1 : t

val succ : t -> t

val is_neg : t -> bool
val force_nonneg : t -> t

val equal : t -> t -> bool
val compare : t -> t -> int

val of_int : int -> t
val to_int : t -> int

val (+) : t -> t -> t
val ( * ) : t -> t -> t

val ( land ) : t -> t -> t

type _t = t

module type Type =
sig
  type t
  val hash : t -> _t
end
