open System.IO
open System.Text.RegularExpressions

type Valve =
  { name : string
    rate : int
    neighbors : string list }

type Step =
  { name : string
    decision : int }

let rec dfs (name : string) (graph : Map<string, Valve>) (visited : Set<string * string>) (remainingTime : int) : (int * Step list) =
  if remainingTime > 0 then
    let valve = Map.find name graph
    let candidates =
      [0; 1]
        |> Seq.collect (fun decision ->
          let remainingTime' = remainingTime - decision - 1
          let flow = decision * valve.rate * remainingTime
          valve.neighbors
            |> Seq.filter (fun n -> not (visited |> Set.contains (name, n)))
            |> Seq.map (fun n ->
              let visited' = visited |> Set.add (name, n)
              let (subFlow, subSteps) = dfs n graph visited' remainingTime'
              flow + subFlow, { name = name; decision = decision } :: subSteps))
        |> Seq.toList
    ((0, []) :: candidates)
      |> Seq.maxBy fst
  else
    0, []

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
  File.ReadAllText("resources/mini.txt").Split("\n")
    |> Seq.choose parseLine 
    |> Seq.fold (fun m v -> Map.add v.name v m) Map.empty

let initialTime = 30
let result = dfs "AA" graph Set.empty initialTime

printfn "Solution: %A" result
