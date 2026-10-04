(* $MDX part-begin=transition *)
type status = Playing | Lost
type state = { tick:int; x:int; y:int; vx:int; vy:int; paddle:int; status:status }
type input = { move:int }
type event = Paddle | Wall | Ceiling | Miss
let initial = {tick=0; x=5; y=2; vx=1; vy=(-1); paddle=5; status=Playing}
let clamp lo hi x = max lo (min hi x)
let step s input =
  if input.move < -1 || input.move > 1 then invalid_arg "move must be -1, 0 or 1";
  let paddle = clamp 1 9 (s.paddle + input.move) in
  let tick = s.tick + 1 in
  if s.status = Lost then {s with tick; paddle}, []
  else
    let x = s.x + s.vx and y = s.y + s.vy in
    let wall = x = 0 || x = 10 in
    let ceiling = y = 6 in
    let bottom = y = 0 in
    let hit = bottom && abs (x - paddle) <= 1 in
    let missed = bottom && not hit in
    let state = {tick; x; y; paddle;
      vx=(if wall then -s.vx else s.vx);
      vy=(if ceiling || hit then -s.vy else s.vy);
      status=(if missed then Lost else Playing)} in
    let events =
      (if wall then [Wall] else []) @ (if ceiling then [Ceiling] else []) @
      (if hit then [Paddle] else []) @ (if missed then [Miss] else []) in
    state, events
(* $MDX part-end *)

let recorded = List.map (fun move -> {move}) [1;1;0;-1;0;0;0;0;0;0;0;0;0;0]
let expected_positions =
  [6,1;7,0;8,1;9,2;10,3;9,4;8,5;7,6;6,5;5,4;4,3;3,2;2,1;1,0]

let rec stream state inputs () = match inputs with
  | [] -> Seq.Nil
  | input::rest ->
    let next,events = step state input in
    Seq.Cons ((next,events), stream next rest)
let through_stream inputs = List.of_seq (stream initial inputs)

(* A small static dependency graph. A node caches by dependency revisions. *)
module Signal = struct
  type 'a t = unit -> int * 'a
  let var value =
    let value = ref value and revision = ref 0 in
    let set next =
      if next <> !value then (value := next; incr revision) in
    set, (fun () -> !revision, !value)
  let sample signal = snd (signal ())
  let map2 f a b =
    let cached = ref None and revision = ref 0 in
    fun () ->
      let ra,va = a () in let rb,vb = b () in
      match !cached with
      | Some (old_a,old_b,value) when old_a=ra && old_b=rb -> !revision,value
      | _ ->
        let value = f va vb in
        incr revision; cached := Some (ra,rb,value); !revision,value
end

(* The scan node depends on a logical tick as well as the input value. *)
let incremental () =
  let current_tick = ref 0 and state = ref initial in
  let set_tick,tick = Signal.var 0 in
  let set_input,input = Signal.var {move=0} in
  let recomputations = ref 0 in
  let output = Signal.map2 (fun tick input ->
    if tick = 0 then initial,[] else begin
      if tick <> (!state).tick + 1 then invalid_arg "skipped logical tick";
      let next,events = step !state input in
      state := next; incr recomputations; next,events
    end) tick input in
  let sample () = Signal.sample output in
  let update next_input =
    if (!state).tick <> !current_tick then invalid_arg "previous tick not sampled";
    set_input next_input; incr current_tick; set_tick !current_tick in
  update,sample,(fun () -> !recomputations)
let through_incremental inputs =
  let update,sample,_ = incremental () in
  List.map (fun input -> update input; sample ()) inputs

type _ Effect.t += Input : input Effect.t
exception Stop

type session = { push : input -> unit; close : unit -> unit }
let start ~publish ~release =
  let pending : (input,unit) Effect.Deep.continuation option ref = ref None in
  let closed = ref false in
  let rec script state =
    let input = Effect.perform Input in
    let next,events = step state input in
    publish (next,events);
    script next in
  (match Fun.protect ~finally:release (fun () -> script initial) with
   | () -> closed := true
   | effect Input, k -> pending := Some k
   | exception Stop -> closed := true
   | exception exn -> closed := true; raise exn);
  let consume () = match !pending with
    | None -> invalid_arg "reactive script has no suspended input"
    | Some k -> pending := None; k in
  let push input =
    if !closed then invalid_arg "reactive script is closed";
    let k = consume () in Effect.Deep.continue k input in
  let close () = if not !closed then begin
    closed := true;
    let k = consume () in Effect.Deep.discontinue k Stop
  end in
  {push;close}
let through_effects inputs =
  let output = ref [] in
  let session = start ~publish:(fun x -> output := x :: !output) ~release:(fun () -> ()) in
  Fun.protect ~finally:session.close (fun () -> List.iter session.push inputs);
  List.rev !output

(* Each consumer chooses its own once-per-tick consumption policy. *)
let consumer () =
  let seen = ref (-1) in
  fun (state, events) ->
    if state.tick = !seen then [] else (seen := state.tick; events)

let rising_edge () =
  let previous = ref false and last_tick = ref (-1) and cached = ref false in
  fun ~tick value ->
    if tick < !last_tick then invalid_arg "ticks must be monotone";
    if tick <> !last_tick then begin
      cached := value && not !previous;
      previous := value; last_tick := tick
    end;
    !cached
