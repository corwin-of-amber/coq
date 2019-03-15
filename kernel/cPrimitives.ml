(************************************************************************)
(*         *   The Coq Proof Assistant / The Coq Development Team       *)
(*  v      *   INRIA, CNRS and contributors - Copyright 1999-2018       *)
(* <O___,, *       (see CREDITS file for the list of authors)           *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

type t =
  | Int31head0
  | Int31tail0
  | Int31add
  | Int31sub
  | Int31mul
  | Int31div
  | Int31mod
(*
  | Int31lsr
  | Int31lsl
 *)
  | Int31land
  | Int31lor
  | Int31lxor
  | Int31addc
  | Int31subc
  | Int31addcarryc
  | Int31subcarryc
  | Int31mulc
  | Int31diveucl
  | Int31div21
  | Int31addmuldiv
  | Int31eq
  | Int31lt
  | Int31le
  | Int31compare

let hash = function
  | Int31head0 -> Int32.of_int 1
  | Int31tail0 -> Int32.of_int 2
  | Int31add -> Int32.of_int 3
  | Int31sub -> Int32.of_int 4
  | Int31mul -> Int32.of_int 5
  | Int31div -> Int32.of_int 6
  | Int31mod -> Int32.of_int 7
(*
  | Int31lsr -> Int32.of_int 8
  | Int31lsl -> Int32.of_int 9
 *)
  | Int31land -> Int32.of_int 10
  | Int31lor -> Int32.of_int 11
  | Int31lxor -> Int32.of_int 12
  | Int31addc -> Int32.of_int 13
  | Int31subc -> Int32.of_int 14
  | Int31addcarryc -> Int32.of_int 15
  | Int31subcarryc -> Int32.of_int 16
  | Int31mulc -> Int32.of_int 17
  | Int31diveucl -> Int32.of_int 18
  | Int31div21 -> Int32.of_int 19
  | Int31addmuldiv -> Int32.of_int 20
  | Int31eq -> Int32.of_int 21
  | Int31lt -> Int32.of_int 22
  | Int31le -> Int32.of_int 23
  | Int31compare -> Int32.of_int 24

let to_string = function
  | Int31head0 -> "head0"
  | Int31tail0 -> "tail0"
  | Int31add -> "add"
  | Int31sub -> "sub"
  | Int31mul -> "mul"
  | Int31div -> "div"
  | Int31mod -> "mod"
(*
  | Int31lsr -> "l_sr"
  | Int31lsl -> "l_sl"
 *)
  | Int31land -> "l_and"
  | Int31lor -> "l_or"
  | Int31lxor -> "l_xor"
  | Int31addc -> "addc"
  | Int31subc -> "subc"
  | Int31addcarryc -> "addcarryc"
  | Int31subcarryc -> "subcarryc"
  | Int31mulc -> "mulc"
  | Int31diveucl -> "diveucl"
  | Int31div21 -> "div21"
  | Int31addmuldiv -> "addmuldiv"
  | Int31eq -> "eq"
  | Int31lt -> "lt"
  | Int31le -> "le"
  | Int31compare -> "compare"
