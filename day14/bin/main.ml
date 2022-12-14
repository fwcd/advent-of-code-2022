let read_lines filename =
  (* https://stackoverflow.com/questions/5774934/how-do-i-read-in-lines-from-a-text-file-in-ocaml/5775024#5775024 *)
  let lines = ref [] in
  let channel = open_in filename in
  try
      while true; do
          lines := input_line channel :: !lines
      done; !lines
  with End_of_file ->
      close_in channel;
  List.rev !lines;;

let () =
  let lines = read_lines "resources/demo.txt" in
  Printf.printf "Lines: %s\n" (String.concat "\n" lines)
