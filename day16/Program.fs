open System.IO
open System.Text.RegularExpressions

type Valve =
  { name : string
    rate : int
    neighbors : string list }

let rec dfs (name : string) (graph : Map<string, Valve>) (visited : Set<string>) (remainingTime : int) : int =
  if remainingTime > 0 && not (visited |> Set.contains name) then
    let visited' = visited |> Set.add name
    let valve = Map.find name graph
    [0; 1]
      |> List.toSeq
      |> Seq.map (fun delta -> (remainingTime - delta - 1, delta * valve.rate * remainingTime))
      |> Seq.collect (fun (remainingTime', flow) ->
        valve.neighbors
          |> List.map (fun n -> flow + dfs n graph visited' remainingTime'))
      |> Seq.max
  else
    0

let pattern = Regex(@"Valve (\w+) has flow rate=(\d+); tunnels? leads? to valves? (.+)", RegexOptions.Compiled)

let parseLine (line : string) : Valve option = 
  match pattern.Match(line).Groups |> Seq.tail |> Seq.toList with
    | [name; rate; neighbors] ->
      Some
        { name = name.Value
          rate = rate.Value |> int
          neighbors = neighbors.Value.Split(", ") |> Seq.toList }
    | _ -> None
  
let graph =
  File.ReadAllText("resources/demo.txt").Split("\n")
    |> Seq.choose parseLine 
    |> Seq.fold (fun m v -> Map.add v.name v m) Map.empty

let initialTime = 30
let result = dfs "AA" graph Set.empty initialTime

printfn "Graph: %A" graph
printfn "Solution: %A" result
