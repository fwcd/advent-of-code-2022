open System.IO
open System.Text.RegularExpressions

type Valve =
  { name : string
    rate : int
    neighbors : (string * int) list }

type Step =
  { name : string
    remainingTime : int
    decision : int
    released : int
    openValves : Set<string> }

type Graph = Map<string, Valve>
type Visited = Map<string * int, int * Step list>

/// Searches the graph for a solution in a depth-first manner.
let rec dfs (name : string) (graph : Graph) (visited : Visited) (openValves : Set<string>) (remainingTime : int) : (int * Step list * Visited) =
  match Map.tryFind (name, remainingTime) visited with
    | Some (flow, steps) -> flow, steps, visited
    | None when remainingTime > 0 ->
      let valve = Map.find name graph
      let (visited' : Map<string * int, int * Step list>), candidates =
        (if (openValves |> Set.contains name) || valve.rate = 0 then [0] else [0; 1])
          |> Seq.collect (fun decision -> valve.neighbors |> Seq.map (fun n -> decision, n))
          |> Seq.fold (fun (visited', acc) (decision, (n, steps)) ->
            let flowDelta = decision * valve.rate * (remainingTime - 1)
            let remainingTime' = remainingTime - decision - steps
            let openValves' = if decision = 1 then openValves |> Set.add name else openValves
            let (subFlow, subSteps, visited'') = dfs n graph visited' openValves' remainingTime'
            let newFlow = flowDelta + subFlow
            let newSteps = { name = name; remainingTime = remainingTime; decision = decision; released = flowDelta; openValves = openValves' } :: subSteps
            (visited'', (newFlow, newSteps) :: acc)) (visited, [])
      let (flow, steps) =
        candidates
          |> Seq.maxBy fst
      let visited'' = Map.add (name, remainingTime) (flow, steps) visited'
      flow, steps, visited''
    | _ -> 0, [], visited

/// Replaces the given neighbor, adding a delta in the given valve.
let replaceNeighbor (oldName : string) (newName : string) (stepDelta : int) (valve : Valve) : Valve =
  { valve with neighbors = valve.neighbors |> List.map (fun (n, steps) -> if n = oldName then newName, steps + stepDelta else n, steps) }

/// Optimizes the given graph by removing zero nodes and merging their steps into their neighbors.
let optimizeGraph (graph : Graph) : Graph =
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
let (solution, steps, _) = dfs "AA" graph Map.empty Set.empty initialTime

printfn "Solution: %d" solution
for step in steps do
  printfn "== Minute %d ==" (initialTime - step.remainingTime + 1)
  printfn "At valve %s" step.name
  if step.decision = 1 then
    printfn "Opening it, releasing a total of %d" step.released
  printfn "Open valves: %A" step.openValves
