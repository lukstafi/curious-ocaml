type ('a, 'b) choice = Left of 'a | Right of 'b

type btree = Tip | Node of int * btree * btree
type repr = (int * (int * btree * btree * btree option) option) option

