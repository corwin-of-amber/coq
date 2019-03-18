type t = Int32.t

let _0 = Int32.zero
let _1 = Int32.one
let minus_1 = Int32.minus_one

let is_neg i = Int32.compare i _0 < 0
let force_nonneg i = Int32.logand i (Int32.of_int 0x3FFFFFFF)

let equal = Int32.equal
let compare = Int32.compare

let of_int = Int32.of_int
let to_int = Int32.to_int
let succ = Int32.succ

let ( land ) = Int32.logand

let (+) = Int32.add
let ( * ) = Int32.mul

type _t = t
module type Type =
sig
  type t
  val hash : t -> _t
end
