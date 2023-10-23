(* stemmer.ml: Generates stems of English words.
 *
 * Copyright (C) 2003-2010 by Erik Arneson <dybbuk@lnouv.com>
 *   No guarantees or restrictions on use.  This code is released into the
 *   public domain.
 *
 * $Id: stemmer.ml,v 1.4 2003/07/20 18:50:21 erik Exp $
 *)

exception No_stem of string ;;

(* Now for the native OCaml port *)
let rule_list_1a = [
  (101, "sses", "ss", -1);
  (102, "ies",  "i",  -1);
  (103, "ss",   "ss", -1);
  (104, "s",    "",   -1)
] ;;

let rule_list_1b = [
  (105, "eed",  "ee", 0);
  (106, "ed",   "",   -1);
  (107, "ing",  "",   -1);
] ;;

let rule_list_1b1 = [
  (108, "at", "ate", -1);
  (109, "bl", "ble", -1);
  (110, "iz", "ize", -1);
  (111, "bb", "b", -1);
  (112, "dd", "d", -1);
  (113, "ff", "f", -1);
  (114, "gg", "g", -1);
  (115, "mm", "m", -1);
  (116, "nn", "n", -1);
  (117, "pp", "p", -1);
  (118, "rr", "r", -1);
  (119, "tt", "t", -1);
  (120, "ww", "w", -1);
  (121, "xx", "x", -1);
  (122, "",   "e", -1);
] ;;

let rule_list_1c = [
  (123, "y", "i", -1);
] ;;

let rule_list_2 = [
  (203, "ational", "ate", 0);
  (204, "tional", "tion", 0);
  (205, "enci", "ence", 0);
  (206, "anci", "ance", 0);
  (207, "izer", "ize", 0);
  (208, "abli", "able", 0);
  (209, "alli", "al", 0);
  (210, "entli", "ent", 0);
  (211, "eli", "e", 0);
  (213, "ousli", "ous", 0);
  (214, "ization", "ize", 0);
  (215, "ation", "ate", 0);
  (216, "ator", "ate", 0);
  (217, "alism", "al", 0);
  (218, "iveness", "ive", 0);
  (219, "fulnes", "ful", 0);
  (220, "ousness", "ous", 0);
  (221, "aliti", "al", 0);
  (222, "iviti", "ive", 0);
  (223, "biliti", "ble", 0);
] ;;

let rule_list_3 = [
  (301, "icate", "ic", 0);
  (302, "ative", "", 0);
  (303, "alize", "al", 0);
  (304, "iciti", "ic", 0);
  (305, "ical", "ic", 0);
  (308, "ful", "", 0);
  (309, "ness", "", 0);
] ;;

let rule_list_4 = [
  (401, "al", "", 1);
  (402, "ance", "", 1);
  (403, "ence", "", 1);
  (405, "er", "", 1);
  (406, "ic", "", 1);
  (407, "able", "", 1);
  (408, "ible", "", 1);
  (409, "ant", "", 1);
  (410, "ement", "", 1);
  (411, "ment", "", 1);
  (412, "ent", "", 1);
  (423, "sion", "s", 1);
  (424, "tion", "t", 1);
  (415, "ou", "", 1);
  (416, "ism", "", 1);
  (417, "ate", "", 1);
  (418, "iti", "", 1);
  (419, "ous", "", 1);
  (420, "ive", "", 1);
  (421, "ize", "", 1);
] ;;

let rule_list_5a = [
  (501, "e", "", 1);
  (502, "e", "", -1);
] ;;

let rule_list_5b = [
  (503, "ll", "l", 1);
] ;;

let all_rules = [
  rule_list_1a;
  rule_list_1b;
  (* rule_list_1b1 is conditionally applied below *)
  rule_list_1c;
  rule_list_2;
  rule_list_3;
  rule_list_4;
  rule_list_5a;
  rule_list_5b;
] ;;

(* Returns boolean based on vowel-ness of a character *)
let is_vowel c =
  match c with
      'a' | 'e' | 'i' | 'o' | 'u' -> true
    | _ -> false
;;

(* Computes a weird word count number based on syllabels and such. *)
let word_size word =
  let wordlen = (String.length word) in
  let rec aux idx count state =
    if idx < wordlen then begin
      let call = aux (succ idx) in
        match state with
            0 ->
              if (is_vowel word.[idx]) then
                call count 1
              else
                call count 2
          | 1 ->
              if (is_vowel word.[idx]) then
                call count 1
              else
                call (succ count) 2
          | 2 ->
              if (is_vowel word.[idx]) || word.[idx] = 'y' then
                call count 1
              else
                call count 2
          | _ -> failwith "Impossible state"
    end
    else
      count
  in
    aux 0 0 0
;;

(* Various rule applications *)
let ends_with_cvc str =
  let len = (String.length str) in
  let vowel_or_y c =
    (is_vowel c) or c = 'y'
  in
  let vowel_or_wxy c =
    (vowel_or_y c) or c = 'x' or c = 'w'
  in
    if len < 3 then
      false
    else if ((not (vowel_or_wxy str.[len-1])) &&
             (vowel_or_y str.[len-2]) &&
             (not (is_vowel str.[len-3]))) then
      true
    else
      false
;;

let add_an_e word =
  if (word_size word) = 1 && (ends_with_cvc word) then
    true
 else
   false
;;

let remove_an_e word =
  if (word_size word) = 1 && not (ends_with_cvc word) then
    true
 else
   false
;;

let contains_vowel str =
  let len = String.length str in
  let rec aux idx =
    if idx = len then
      false
    else if (is_vowel str.[idx]) || str.[idx] = 'y' then
      true
    else
      aux (succ idx)
  in
    (is_vowel str.[0]) || aux 1
;;

(* Some rules have additional criteria added to them *)
let rules_criteria = [
  ([106; 107; 123], contains_vowel);
  ([122], add_an_e);
  ([502], remove_an_e);
] ;;

let match_rule word ((num,orig,_,min_root) : (int * string * string * int)) =
  let orig_len = String.length orig
  and word_len = String.length word in
  let rec aux_rule word num lst =
    match lst with
        (rules, fn) :: tl ->
          if (List.mem num rules) then
            fn word
          else
            aux_rule word num tl
      | [] -> true
  in
    if word_len > orig_len then
      let word_end = (String.sub word (word_len - orig_len) orig_len)
      and word_root = (String.sub word 0 (word_len - orig_len)) in
        if word_end = orig &&
          min_root < (word_size word_root) &&
          (aux_rule word_root num rules_criteria) then
            begin
              (*print_int num;
              print_string (" ("^word^") "^word_end^" matches "^orig^"\n");*)
              true
            end
        else
          false
    else 
      false;;

let apply_rule word ((_,orig,rep,_) : int * string * string * int)=
  let orig_len = String.length orig 
  and word_len = String.length word in
  let orig_word = word
  and new_word = (String.sub word 0 (word_len - orig_len)) ^ rep in
    (* The new stem must be 2 or more characters in length *)
    if (String.length new_word) < 2 then
      orig_word
    else
      new_word
;;

let rec replace_end word (rule_list : (int * string * string * int) list) =
  match rule_list with
      hd :: tl ->
        if (match_rule word hd) then
          let (rule, _, _, _) = hd in
            (rule, apply_rule word hd)
        else
          replace_end word tl
    | [] ->
        (0, word)
;;

let stem in_word =
  let word = String.lowercase in_word in
  let rec aux aux_word list =
    match list with
        hd :: tl ->
          begin
            match (replace_end aux_word hd) with
                (106, out) | (107, out) ->
                  let (_, out2) = replace_end out rule_list_1b1 in
                    aux out2 tl
              | (_, out) ->
                  aux out tl
          end
      | [] ->
          aux_word
  in
    aux word all_rules
;;

let stem_cmp s1 s2 =
  (stem s1) = (stem s2)
;;

let stem_gt s1 s2 =
  (stem s1) > (stem s2)
;;

let stem_gte s1 s2 =
  (stem s1) >= (stem s2)
;;

let stem_lt s1 s2 =
  (stem s1) < (stem s2)
;;

let stem_lte s1 s2 =
  (stem s1) <= (stem s2)
;;

