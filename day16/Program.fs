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
    flow : int
    openValves : Set<string> }

type Graph = Map<string, Valve>

type Solution =
  { flow : int
    steps : Step list }

type State =
  { visited : Map<string * int * Set<string>, Solution> }

/// The empty solution.
let emptySolution = { flow = 0; steps = [] }

/// Searches the graph for a solution in a depth-first manner.
let rec dfs (name : string) (graph : Graph) (state : State) (openValves : Set<string>) (remainingTime : int) : (Solution * State) =
  match Map.tryFind (name, remainingTime, openValves) state.visited with
    | Some solution -> solution, state
    | None when remainingTime > 0 ->
      let valve = Map.find name graph
      let (state' : State), candidates =
        (if (openValves |> Set.contains name) || valve.rate = 0 then [0] else [0; 1])
          |> Seq.collect (fun decision -> valve.neighbors |> Seq.map (fun n -> decision, n))
          |> Seq.fold (fun (state', acc) (decision, (n, steps)) ->
            let flowDelta = decision * valve.rate * (remainingTime - 1)
            let remainingTime' = remainingTime - decision - steps
            let openValves' = if decision = 1 then openValves |> Set.add name else openValves
            let (subSolution, state'') = dfs n graph state' openValves' remainingTime'
            let newSolution =
              { flow = flowDelta + subSolution.flow
                steps = { name = name; remainingTime = remainingTime; decision = decision; flow = flowDelta; openValves = openValves' } :: subSolution.steps }
            (state'', newSolution :: acc)) (state, [])
      let solution =
        candidates
          |> Seq.maxBy (fun c -> c.flow)
      assert (solution.steps.Head.name = name)
      let state'' = { state' with visited = Map.add (name, remainingTime, openValves) solution state'.visited }
      solution, state''
    | _ -> emptySolution, state

/// Prettyprints a step.
let prettyStep (initialTime : int) (step : Step) : string = 
  [ $"== Minute {initialTime - step.remainingTime + 1} =="
    $"At valve {step.name}"
    $"Releasing {step.flow}"
    $"Open valves: {step.openValves}" ]
    |> String.concat "\n"

/// Prettyprints a solution.
let prettySolution (initialTime : int) (solution : Solution) : string =
  ($"Flow: {solution.flow}" :: (solution.steps |> List.map (prettyStep initialTime)))
    |> String.concat "\n"

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
  File.ReadAllText("resources/input.txt").Split("\n")
    |> Seq.choose parseLine 
    |> Seq.fold (fun m v -> Map.add v.name v m) Map.empty

printfn "==> Optimizing graph..."
let graph =
  baseGraph
    |> optimizeGraph
printfn "Reduced size from %d to %d" baseGraph.Count graph.Count

printfn "==> Searching graph..."
let initialTime = 30
let initialState = { visited = Map.empty }
let (solution, _) = dfs "AA" graph initialState Set.empty initialTime

printfn "%s" (prettySolution initialTime solution)

