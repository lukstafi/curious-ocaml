let rand_string n =
  let s = String.make n 'a' in
  for i=0 to n-1 do
    s.[i] <- Char.chr (Random.int 26 + Char.code 'a')
  done;
  s

let time f =
  let tbeg = Unix.gettimeofday () in
  let res = f () in
  let tend = Unix.gettimeofday () in
  tend -. tbeg, res

let create make add n k =
  let dom = Array.init n (fun _ -> rand_string 15) in
  let m () = Array.fold_left
    (fun m x -> add x x.[0] m) (make ()) dom in
  let f () =
    for i=0 to k/n do
      ignore (m ())
    done;
    m () in
  let t, m = time f in
  dom, t, m
    
let use_known find dom m n =
  let l = Array.length dom in
  let use () =
    for i=1 to n do
      let ch = find dom.(Random.int l) m in
      ignore (Char.code ch)
    done in
  fst (time use)
    
let use_unknown find m n =
  let undom = Array.init 15 (fun _ -> rand_string 15) in
  let use () =
    for i=1 to n do
      try
        let ch = find undom.(Random.int 15) m in
        ignore (Char.code ch)
      with Not_found _ -> ()
    done in
  fst (time use)

let suite msg make add find =
  let rec aux n k =
    if k > 0 then
      let dom, t1, m = create make add n 10000000 in
      Printf.printf "%s: create    k=%2d n=%8d t=%10.2fs\n%!" msg (23-k) n t1;
      let t2 = use_known find dom m 10000000 in
      Printf.printf "%s: use known k=%2d n=%8d t=%10.2fs\n%!" msg (23-k) n t2;
      let t3 = use_unknown find m 10000000 in
      Printf.printf "%s: use fresh k=%2d n=%8d t=%10.2fs\n%!" msg (23-k) n t3;
      if t1+.t2+.t3 < 300. then aux (n*2) (k-1) in
  aux 2 22

module M = Map.Make (String)

let _ =
  suite "assoc-l"
    (fun ()->[]) (fun k v m -> (k, v)::m) List.assoc;
  suite "treemap"
    (fun ()->M.empty) M.add M.find;
  suite "hashtbl"
    (fun ()->Hashtbl.create 511)
    (fun k v m -> Hashtbl.add m k v; m)
    (fun k m -> Hashtbl.find m k)
