[@@@warnerror "-unused-field"]
[@@@warnerror "-unused-type-declaration"]
[@@@warnerror "-unused-var-strict"]

type pos = { x: int; y: int }
type field = Rock | Space
type cave = { map: field array; width: int; height: int; top_left: pos }

let (<<) f g x = f (g x);;

let flip f x y = f y x;;

let range n = List.map (fun x -> x - 1) (List.init n (fun x -> x + 1));;

let rec drop_last xs = match xs with
  | []        -> []
  | [_]       -> []
  | (x :: xs) -> x :: drop_last xs
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
  | Rock -> '#'
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

let parse_cave (lines: string list): cave =
  let paths: pos list list = List.map parse_line lines in
  let poss: pos list = List.flatten paths in
  let top_left = List.fold_right (zip_pos min) poss { x = max_int; y = max_int } in
  let bottom_right = List.fold_right (zip_pos max) poss { x = min_int; y = min_int } in
  let size = zip_pos (+) (zip_pos (-) bottom_right top_left) { x = 1; y = 1 } in
  let initial = { map = Array.make (size.x * size.y) Space; width = size.x; height = size.y; top_left = top_left } in
  List.fold_right draw_path paths initial
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
  let cave = parse_cave lines in
  Printf.printf "Cave: \n%s\n" (pretty_cave cave)
  ;;
