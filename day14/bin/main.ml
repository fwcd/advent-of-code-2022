[@@@warnerror "-unused-field"]
[@@@warnerror "-unused-type-declaration"]
[@@@warnerror "-unused-var-strict"]

type pos = { x: int; y: int }
type field = Rock | Sand | Space
type cave = { map: field array; width: int; height: int; top_left: pos }
type state = { cave: cave; spawn_pos: pos; landed_sand: int; reached_end: bool }

let (<<) f g x = f (g x);;
let flip f y x = f x y;;
let range n = List.map (fun x -> x - 1) (List.init n (fun x -> x + 1));;

let rec any f xs = match xs with
  | []      -> false
  | x :: xs -> if f x then true else any f xs

let rec drop_last xs = match xs with
  | []       -> []
  | [_]      -> []
  | x :: xs -> x :: drop_last xs
  ;;

let pos_of_list (l: int list): pos = match l with
  | [x; y] -> { x = x; y = y}
  | _      -> failwith "List cannot be converted to pos"
  ;;

let parse_line (line: string): pos list = line
  |> Str.split (Str.regexp " -> ")
  |> List.map (pos_of_list << (List.map int_of_string << String.split_on_char ','))
  ;;

let zip_pos (f: int -> int -> int) (p1: pos) (p2: pos): pos = { x = f p1.x p2.x; y = f p1.y p2.y };;

let row (y: int) (cave: cave): field array = Array.sub cave.map (y * cave.width) cave.width;;

let char_of_field (field: field): char = match field with
  | Rock  -> '#'
  | Sand  -> 'o'
  | Space -> ' '
  ;;

let pretty_pos (pos: pos): string = String.concat ", " (List.map string_of_int [pos.x; pos.y]);;

let pretty_cave (cave: cave): string = String.concat "\n" (List.map (String.of_seq << Seq.map char_of_field << Array.to_seq << flip row cave) (range cave.height));;

let in_bounds (pos: pos) (cave: cave): bool =
     pos.x >= cave.top_left.x
  && pos.x < (cave.top_left.x + cave.width)
  && pos.y >= cave.top_left.y
  && pos.y < (cave.top_left.y + cave.height)
  ;;

let index (pos: pos) (cave: cave): int =
  if in_bounds pos cave
    then ((pos.y - cave.top_left.y) * cave.width) + (pos.x - cave.top_left.x)
    else failwith (String.concat " " [pretty_pos pos ;"out of bounds, expected between"; pretty_pos cave.top_left; "and"; pretty_pos (zip_pos (+) cave.top_left { x = cave.width; y = cave.height })])
  ;;

let get (pos: pos) (cave: cave): field = Array.get cave.map (index pos cave);;

let place (field: field) (pos: pos) (cave: cave): cave =
  let new_map = Array.copy cave.map in
  Array.set new_map (index pos cave) field;
  { cave with map = new_map }
  ;;

let draw_line ((start_pos: pos), (end_pos: pos)) (cave: cave) =
  let new_map = Array.copy cave.map in
  let min_pos = zip_pos min start_pos end_pos in
  let max_pos = zip_pos max start_pos end_pos in
  if min_pos.x == max_pos.x then
    for y = min_pos.y to max_pos.y do
      Array.set new_map (index { x = min_pos.x; y = y } cave) Rock
    done
  else
    for x = min_pos.x to max_pos.x do
      Array.set new_map (index { x = x; y = min_pos.y } cave) Rock
    done;
  { cave with map = new_map }
  ;;

let draw_path (path: pos list) (cave: cave) =
  List.fold_right draw_line (List.combine (drop_last path) (List.tl path)) cave
  ;;

let parse_paths (lines: string list): pos list list = List.map parse_line lines;;

let parse_cave (paths: pos list list) (extra_poss: pos list): cave =
  let poss: pos list = extra_poss @ List.flatten paths in
  let top_left = List.fold_right (zip_pos min) poss { x = max_int; y = max_int } in
  let bottom_right = List.fold_right (zip_pos max) poss { x = min_int; y = min_int } in
  let size = zip_pos (+) (zip_pos (-) bottom_right top_left) { x = 1; y = 1 } in
  let initial = { map = Array.make (size.x * size.y) Space; width = size.x; height = size.y; top_left = top_left } in
  List.fold_right draw_path paths initial
  ;;

let is_free (pos: pos) (cave: cave): bool = get pos cave == Space;;

let fall (dx: int) (pos: pos): pos = { x = pos.x + dx; y = pos.y + 1 };;

type pour_loc = AtRoot | Airborne

let rec pour_sand (loc: pour_loc) (pos: pos) (state: state): state =
  let below = List.map (flip fall pos) [0; -1; 1] in
  if any (not << flip in_bounds state.cave) below then
    { state with reached_end = true } (* Reached void *)
  else
    let free = List.filter (flip is_free state.cave) below in
    match free with
      | []                    -> { state with cave = place Sand pos state.cave; landed_sand = state.landed_sand + 1; reached_end = loc == AtRoot }
      | f :: _                -> pour_sand Airborne f state
  ;;

let rec simulate (state: state): state =
  if state.reached_end then
    state
  else
    simulate (pour_sand AtRoot state.spawn_pos state)
  ;;

let read_lines (filename: string): string list =
  (* https://stackoverflow.com/questions/5774934/how-do-i-read-in-lines-from-a-text-file-in-ocaml/5775024#5775024 *)
  let lines = ref [] in
  let channel = open_in filename in
  try
    while true; do
      lines := input_line channel :: !lines
    done; !lines
  with End_of_file ->
    close_in channel;
  List.rev !lines
  ;;

let () =
  let lines = read_lines "resources/demo.txt" in
  let paths = parse_paths lines in
  let spawn_pos = { x = 500; y = 0 } in
  let state cave = { cave = cave spawn_pos; spawn_pos = spawn_pos; landed_sand = 0; reached_end = false } in

  let final1 = simulate (state (fun spawn_pos -> parse_cave paths [spawn_pos])) in
  Printf.printf "Cave 1: \n%s\n" (pretty_cave final1.cave);
  Printf.printf "Part 1: %d\n" final1.landed_sand;

  let height = final1.cave.height in
  let ground_y = final1.cave.top_left.y + height + 1 in
  let floor = [{ x = spawn_pos.x - height - 1; y = ground_y }; { x = spawn_pos.x + height + 1; y = ground_y }] in
  let final2 = simulate (state (fun spawn_pos -> parse_cave (floor :: paths) [spawn_pos])) in
  Printf.printf "Cave 2: \n%s\n" (pretty_cave final2.cave);
  Printf.printf "Part 2: %d\n" final2.landed_sand
  ;;
