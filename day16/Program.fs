open System.IO
open System.Text.RegularExpressions

type Valve =
  { name : string
    rate : int
    neighbors : string list }

let pattern = Regex(@"Valve (\w+) has flow rate=(\d+); tunnels? leads? to valves? (.+)", RegexOptions.Compiled)

let parseLine (line : string) : Valve = 
  match pattern.Match(line).Groups |> Seq.tail |> Seq.toList with
    | [name; rate; neighbors] -> 
      { name = name.Value
        rate = rate.Value |> int
        neighbors = neighbors.Value.Split(", ") |> Seq.toList }
    | _ -> failwith ("Could not parse " + line)
  
let lines = File.ReadAllText("resources/demo.txt").Split("\n")
let input = lines |> Seq.map parseLine

printfn "Input: %A" input
