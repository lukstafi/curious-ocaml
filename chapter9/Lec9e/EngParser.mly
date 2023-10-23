%{
  open EngLexer
%}

%token <string> VERB NOUN ADJ ADV
%token PLURAL SINGULAR
%token A_DET THE_DET SOME_DET THIS_DET THAT_DET
%token THESE_DET THOSE_DET
%token COMMA_CNJ AND_CNJ DOT_PUNCT

%start <EngLexer.sentence> sentence

%%

%public %inline sep2_list(sep1, sep2, X):
| xs = separated_nonempty_list(sep1, X) sep2 x=X
    { xs @ [x] }
| x=option(X)
    { match x with None->[] | Some x->[x] }

sing_only_det:
| THE_DET | SOME_DET | A_DET | THIS_DET | THAT_DET { log "prs: sing_only_det" }
plu_only_det:
| THE_DET | SOME_DET | THESE_DET | THOSE_DET { log "prs: plu_only_det" }
other_det:
| THE_DET | SOME_DET { log "prs: other_det" }

np(det):
| det adjs=list(ADJ) subject=NOUN
    { log "prs: np"; adjs, subject }

vp(NUM):
| advs=separated_list(AND_CNJ,ADV) action=VERB NUM
| action=VERB NUM advs=sep2_list(COMMA_CNJ,AND_CNJ,ADV)
    { log "prs: vp"; action, advs }

sent(det,NUM):
| adjsub=np(det) NUM vbadv=vp(NUM)
    { log "prs: sent";
      {subject=snd adjsub; action=fst vbadv; plural=false;
       adjs=fst adjsub; advs=snd vbadv} }

vbsent(NUM):
| NUM vbadv=vp(NUM)    { log "prs: vbsent"; vbadv }

sentence:
| s=sent(sing_only_det,SINGULAR) DOT_PUNCT
    { log "prs: sentence1";
      {s with plural = false} }
| s=sent(plu_only_det,PLURAL) DOT_PUNCT
    { log "prs: sentence2";
      {s with plural = true} }
| adjsub=np(other_det) vbadv=vbsent(SINGULAR) DOT_PUNCT
    { log "prs: sentence3";
      {subject=snd adjsub; action=fst vbadv; plural=false;
       adjs=fst adjsub; advs=snd vbadv} }
| adjsub=np(other_det) vbadv=vbsent(PLURAL) DOT_PUNCT
    { log "prs: sentence4";
      {subject=snd adjsub; action=fst vbadv; plural=true;
       adjs=fst adjsub; advs=snd vbadv} }
