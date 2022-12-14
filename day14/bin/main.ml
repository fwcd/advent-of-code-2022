[@@@warnerror "-unused-field"]
[@@@warnerror "-unused-type-declaration"]
[@@@warnerror "-unused-var-strict"]

type pos = int * int
type cave = { map: char array; width: int; height: int; top_left: pos }

let (<<) f g x = f (g x);;

let flip f x y = f y x;;

let range n = List.map (fun x -> x - 1) (List.init n (fun x -> x + 1));;

let pos_of_list (l: int list): pos = match l with
  | [x; y] -> (x, y)
  | _      -> failwith "List cannot be converted to pos"
  ;;

let parse_line (line: string): pos list = line
  |> Str.split (Str.regexp " -> ")
  |> List.map (pos_of_list << (List.map int_of_string << String.split_on_char ','))
  ;;

let zip_pos (f: int -> int -> int) ((x1, y1): pos) ((x2, y2): pos): pos = (f x1 x2, f y1 y2);;

let row (i: int) (cave: cave): char array = Array.sub cave.map (i * cave.width) cave.width;;

let pretty (cave: cave): string = String.concat "\n" (List.map (String.of_seq << Array.to_seq << flip row cave) (range cave.height));;

let parse_cave (lines: string list): cave =
  let paths: pos list list = List.map parse_line lines in
  let poss: pos list = List.flatten paths in
  let top_left = List.fold_right (zip_pos min) poss (max_int, max_int) in
  let bottom_right = List.fold_right (zip_pos max) poss (min_int, min_int) in
  let width = fst bottom_right - fst top_left in
  let height = snd bottom_right - snd top_left in
  { map = Array.make (width * height) ' '; width = width; height = height; top_left = top_left }
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
  Printf.printf "Cave: %s\n" (pretty cave)
  ;;
