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

type ActorData =
  { valveName : string
    remainingTime : int }

type Actor =
  { name : string
    data : ActorData }

// TODO: This memoization approach is still a bit weak for the second part, could we do with a smaller key?

type MemoKey =
  { actors : ActorData list
    openValves : Set<string> }

type State =
  { visited : Map<MemoKey, Solution> }

/// The empty solution.
let emptySolution = { flow = 0; steps = [] }

/// Searches the graph for a solution in a depth-first manner with the given actors.
/// While the actors take turns, each actor has their own time, thus they semantically
/// search the graph simulatenously.
let rec dfs (actors : Actor list) (graph : Graph) (state : State) (openValves : Set<string>) : (Solution * State) =
  match actors with
    | us :: them ->
      let memoKey = { actors = actors |> List.map (fun a -> a.data); openValves = openValves }
      match Map.tryFind memoKey state.visited with
        | Some solution ->
          // Solution was memoized,
          solution, state 
        | None when us.data.remainingTime > 0 ->
          // Solution needs to be searched for and this actor still has time left
          let valve = Map.find us.data.valveName graph
          let (state' : State), candidates =
            (if (openValves |> Set.contains us.data.valveName) || valve.rate = 0 then [0] else [0; 1])
              |> Seq.collect (fun decision -> valve.neighbors |> Seq.map (fun n -> decision, n))
              |> Seq.fold (fun (state', acc) (decision, (n, steps)) ->
                let flowDelta = decision * valve.rate * (us.data.remainingTime - 1)
                let remainingTime' = us.data.remainingTime - decision - steps
                let openValves' = if decision = 1 then openValves |> Set.add us.data.valveName else openValves
                let us' = { us with data = { us.data with valveName = n; remainingTime = remainingTime' } }
                let actors' = them @ [us']
                let subSolution, state'' = dfs actors' graph state' openValves'
                let newSolution =
                  { flow = flowDelta + subSolution.flow
                    steps = { actorName = us.name
                              valveName = us.data.valveName
                              remainingTime = us.data.remainingTime
                              decision = decision
                              flow = flowDelta
                              openValves = openValves' } :: subSolution.steps }
                (state'', newSolution :: acc)) (state, [])
          let solution =
            candidates
              |> Seq.maxBy (fun c -> c.flow)
          let state'' = { state' with visited = Map.add memoKey solution state'.visited }
          solution, state''
        | _ ->
          // Solution needs to be searched for, but this actor has no time left and therefore is done
          dfs them graph state openValves 
    | [] ->
      // All actors are done, therefore don't recurse
      emptySolution, state 

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

/// Finds a node satisfying a given predicate.
let findNode (predicate : Valve -> bool) (graph : Graph) : Valve option =
  graph
    |> Map.values
    |> Seq.filter predicate
    |> Seq.tryHead

/// Optimizes the given graph by removing zero nodes and merging their steps into their neighbors.
let rec optimizeGraph (graph : Graph) : Graph =
  match findNode (fun v -> v.rate = 0 && v.neighbors.Length = 2) graph with
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
  File.ReadAllText("resources/input.txt").Split("\n")
    |> Seq.choose parseLine 
    |> Seq.fold (fun m v -> Map.add v.name v m) Map.empty

printfn "==> Optimizing graph..."
let graph =
  baseGraph
    |> optimizeGraph
printfn "Reduced size from %d to %d" baseGraph.Count graph.Count

let initialActor name time = { name = name; data = { valveName = "AA"; remainingTime = time } }
let initialState = { visited = Map.empty }

printfn "==> Searching graph for part 1..."
let initialTime1 = 30
let (part1, _) = dfs [initialActor "us" initialTime1] graph initialState Set.empty
printfn "Part 1: %d" part1.flow

printfn "==> Searching graph for part 2..."
let initialTime2 = 26
let (part2, _) = dfs [initialActor "ourselves" initialTime2; initialActor "elephant" initialTime2] graph initialState Set.empty
printfn "Part 2: %d" part2.flow

// To output a detailed list of steps, uncomment:
// printfn "%s" (prettySolution initialTime2 part2)
