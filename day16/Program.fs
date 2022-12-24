open System.IO
open System.Text.RegularExpressions

type Valve =
  { name : string
    rate : int
    neighbors : (string * int) list }

type Step =
  { actorName : string
    valveName : string
    remainingTime : int
    decision : int
    flow : int
    openValves : Set<string> }

type Graph = Map<string, Valve>

type Solution =
  { flow : int
    steps : Step list }

type Actor =
  { name : string
    valveName : string
    remainingTime : int }

type MemoKey =
  { us : Actor
    them : Actor option
    openValves : Set<string> }

type State =
  { visited : Map<MemoKey, Solution> }

/// The empty solution.
let emptySolution = { flow = 0; steps = [] }

/// Searches the graph for a solution in a depth-first manner.
let rec dfs (us : Actor) (them : Actor option) (graph : Graph) (state : State) (openValves : Set<string>) : (Solution * State) =
  let memoKey = { us = us; them = them; openValves = openValves }
  match Map.tryFind memoKey state.visited with
    | Some solution -> solution, state
    | None when us.remainingTime > 0 ->
      let valve = Map.find us.valveName graph
      let (state' : State), candidates =
        (if (openValves |> Set.contains us.valveName) || valve.rate = 0 then [0] else [0; 1])
          |> Seq.collect (fun decision -> valve.neighbors |> Seq.map (fun n -> decision, n))
          |> Seq.fold (fun (state', acc) (decision, (n, steps)) ->
            let flowDelta = decision * valve.rate * (us.remainingTime - 1)
            let remainingTime' = us.remainingTime - decision - steps
            let openValves' = if decision = 1 then openValves |> Set.add us.valveName else openValves
            let us' = { us with valveName = n; remainingTime = remainingTime' }
            let nextUs, nextThem =
              match them with
                | Some them -> (them, Some us')
                | None -> (us', None)
            let (subSolution, state'') = dfs nextUs nextThem graph state' openValves'
            let newSolution =
              { flow = flowDelta + subSolution.flow
                steps = { actorName = us.name
                          valveName = us.valveName
                          remainingTime = us.remainingTime
                          decision = decision
                          flow = flowDelta
                          openValves = openValves' } :: subSolution.steps }
            (state'', newSolution :: acc)) (state, [])
      let solution =
        candidates
          |> Seq.maxBy (fun c -> c.flow)
      let state'' = { state' with visited = Map.add memoKey solution state'.visited }
      solution, state''
    | _ -> emptySolution, state

/// Prettyprints a step.
let prettyStep (initialTime : int) (step : Step) : string = 
  $"{step.actorName} @ Minute {initialTime - step.remainingTime + 1} \t => {step.valveName} += {step.flow} \t {step.openValves}"

/// Prettyprints a solution.
let prettySolution (initialTime : int) (solution : Solution) : string =
  ($"Flow: {solution.flow}" :: (solution.steps |> List.map (prettyStep initialTime)))
    |> String.concat "\n"

/// Replaces the given neighbor, adding a delta in the given valve.
let replaceNeighbor (oldName : string) (newName : string) (stepDelta : int) (valve : Valve) : Valve =
  { valve with neighbors = valve.neighbors |> List.map (fun (n, steps) -> if n = oldName then newName, steps + stepDelta else n, steps) }

/// Optimizes the given graph by removing zero nodes and merging their steps into their neighbors.
let rec optimizeGraph (graph : Graph) : Graph =
  match graph
      |> Map.values
      |> Seq.filter (fun v -> v.rate = 0 && (v.neighbors |> List.length) = 2)
      |> Seq.tryHead with
    | Some { name = name; neighbors = [src, srcSteps; dst, dstSteps] } ->
        graph
          |> Map.remove name
          |> Map.change src (fun v -> Some (replaceNeighbor name dst dstSteps v.Value))
          |> Map.change dst (fun v -> Some (replaceNeighbor name src srcSteps v.Value))
          |> optimizeGraph
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

let initialActor name time = { name = name; valveName = "AA"; remainingTime = time }
let initialState = { visited = Map.empty }

printfn "==> Searching graph for part 1..."
let initialTime1 = 30
let (part1, _) = dfs (initialActor "us" initialTime1) None graph initialState Set.empty
printfn "Part 1: %d" part1.flow

printfn "==> Searching graph for part 2..."
let initialTime2 = 26
let (part2, _) = dfs (initialActor "ourselves" initialTime2) (Some (initialActor "elephant" initialTime2)) graph initialState Set.empty
printfn "Part 2:"
printfn "%s" (prettySolution initialTime2 part2)
