open System.IO
open System.Text.RegularExpressions

type Valve =
  { name : string
    rate : int
    neighbors : (string * int) list }

type Step =
  { name : string
    decision : int }

/// Searches the graph for a solution in a depth-first manner.
let rec dfs (name : string) (graph : Map<string, Valve>) (visited : Set<string * string>) (remainingTime : int) : (int * Step list) =
  if remainingTime > 0 then
    let valve = Map.find name graph
    let candidates =
      [0; 1]
        |> Seq.collect (fun decision ->
          let flow = decision * valve.rate * remainingTime
          valve.neighbors
            |> Seq.filter (fun (n, _) -> not (visited |> Set.contains (name, n)))
            |> Seq.map (fun (n, steps) ->
              let remainingTime' = remainingTime - decision - steps
              let visited' = visited |> Set.add (name, n)
              let (subFlow, subSteps) = dfs n graph visited' remainingTime'
              flow + subFlow, { name = name; decision = decision } :: subSteps))
        |> Seq.toList
    ((0, []) :: candidates)
      |> Seq.maxBy fst
  else
    0, []

/// Replaces the given neighbor, adding a delta in the given valve.
let replaceNeighbor (oldName : string) (newName : string) (stepDelta : int) (valve : Valve) : Valve =
  { valve with neighbors = valve.neighbors |> List.map (fun (n, steps) -> if n = oldName then newName, steps + stepDelta else n, steps) }

/// Optimizes the given graph by removing zero nodes and merging their steps into their neighbors.
let optimizeGraph (graph : Map<string, Valve>) : Map<string, Valve> =
  match graph
      |> Map.values
      |> Seq.filter (fun v -> v.rate = 0 && (v.neighbors |> List.length) = 2)
      |> Seq.tryHead with
    | Some { name = name; neighbors = [src, srcSteps; dst, dstSteps] } ->
        graph
          |> Map.remove name
          |> Map.change src (fun v -> Some (replaceNeighbor name dst dstSteps v.Value))
          |> Map.change dst (fun v -> Some (replaceNeighbor name src srcSteps v.Value))
    | _ -> graph

let pattern = Regex(@"Valve (\w+) has flow rate=(\d+); tunnels? leads? to valves? (.+)", RegexOptions.Compiled)

let parseLine (line : string) : Valve option = 
  match pattern.Match(line).Groups |> Seq.tail |> Seq.toList with
    | [name; rate; neighbors] ->
      Some
        { name = name.Value
          rate = rate.Value |> int
          neighbors =
            neighbors.Value.Split(", ")
              |> Seq.map (fun n -> (n, 1))
              |> Seq.toList }
    | _ -> None
  
printfn "==> Reading graph..."
let baseGraph =
  File.ReadAllText("resources/demo.txt").Split("\n")
    |> Seq.choose parseLine 
    |> Seq.fold (fun m v -> Map.add v.name v m) Map.empty

printfn "==> Optimizing graph..."
let graph =
  baseGraph
    |> optimizeGraph
printfn "Reduced size from %d to %d" baseGraph.Count graph.Count

printfn "==> Searching graph..."
let initialTime = 30
let result = dfs "AA" graph Set.empty initialTime

printfn "Solution: %A" result
