


type 'a thunk =
    | Fin of 'a
    | TailCall of (unit -> 'a thunk)
    | Bind of 'a thunk * ('a -> 'a thunk)

let rec trampoline_0 r cont = match r with
    | Fin a -> unroll a cont
    | TailCall f -> trampoline_0 (f ()) cont
    | Bind (f, g) -> trampoline_0 f (g :: cont)

and unroll v stack = match stack with
    | [] -> v
    | cont :: rest -> trampoline_0 (cont v) rest

let trampoline r = trampoline_0 r []

let ret a = Fin a
let bind f g = Bind (f, g)

let seq f = bind (TailCall f)

let lift f x = ret @@ f x
let unlift f x = trampoline @@ f x
let unlift2 f x y = trampoline @@ f x y

let fmap f a g =
  if Array.length a = 1 then
    let a0 = a.(0) in
    let arr_of_one v = if a0 = v then a else [|v|] in
    Bind (TailCall (fun () -> f a0), fun v -> g (arr_of_one v))
  else g @@ CArray.Smart.map (unlift f) a
