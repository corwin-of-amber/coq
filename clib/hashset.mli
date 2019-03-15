(************************************************************************)
(*         *   The Coq Proof Assistant / The Coq Development Team       *)
(*  v      *   INRIA, CNRS and contributors - Copyright 1999-2018       *)
(* <O___,, *       (see CREDITS file for the list of authors)           *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

(** Adapted from Damien Doligez, projet Para, INRIA Rocquencourt,
    OCaml stdlib. *)

(** The following functor is a specialized version of [Weak.Make].
    Here, the responsibility of computing the hash function is now
    given to the caller, which makes possible the interleaving of the
    hash key computation and the hash-consing. *)

module type EqType = sig
  type t
  val eq : t -> t -> bool
end

type statistics = {
  num_bindings: int;
  num_buckets: int;
  max_bucket_length: int;
  bucket_histogram: int array
}

module type S = sig
  type elt
  (** Type of hashsets elements. *)
  type t
  (** Type of hashsets. *)
  val create : int -> t
  (** [create n] creates a fresh hashset with initial size [n]. *)
  val clear : t -> unit
  (** Clear the contents of a hashset. *)
  val repr : int -> elt -> t -> elt
  (** [repr key constr set] uses [key] to look for [constr]
      in the hashet [set]. If [constr] is in [set], returns the
      specific representation that is stored in [set]. Otherwise,
      [constr] is stored in [set] and will be used as the canonical
      representation of this value in the future. *)
  val stats : t -> statistics
  (** Recover statistics on the table. *)
end

module Make (E : EqType) : S with type elt = E.t

module Combine : sig
  val combine : int32 -> int32 -> int32
  val combinei : int -> int32 -> int32
  val combineii : int -> int -> int32
  val combine_i : int32 -> int -> int32
  val combinesmall : int32 -> int32 -> int32
  val combinesmalli : int -> int32 -> int32
  val combinesmallii : int -> int -> int32

  val combine3 : int32 -> int32 -> int32 -> int32
  val combine4 : int32 -> int32 -> int32 -> int32 -> int32
  val combine5 : int32 -> int32 -> int32 -> int32 -> int32 -> int32
end
