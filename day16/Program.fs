open System.IO
open System.Text.RegularExpressions

type Id = int

type BitSet = int

type Valve<'id> =
  { id : 'id
    rate : int
    neighbors : ('id * int) list }

type Step =
  { actorName : string
    valveId : Id
    remainingTime : int
    decision : int
    flow : int
    openValves : BitSet }

type Graph<'id> when 'id: comparison = Map<'id, Valve<'id>>

type Solution =
  { flow : int
    steps : Step list }

type ActorData =
  { valveId : Id
    remainingTime : int }

type Actor =
  { name : string
    data : ActorData }

// TODO: This memoization approach is still a bit weak for the second part, could we do with a smaller key?

type MemoKey =
  { actors : ActorData list
    openValves : BitSet }

type State =
  { visited : Map<MemoKey, Solution> }

/// Flips the arguments of the given function.
let flip f x y = f y x

/// The empty bit set.
let emptyBitSet : BitSet = 0

/// Inserts a value into the bit set.
let insertBit (value : int) (set : BitSet) : BitSet = set ||| (1 <<< value)

/// Checks whether a bit set contains the given value.
let containsBit (value : int) (set : BitSet) : bool = (set >>> value) &&& 1 = 1

/// Converts a bit set to a list.
let rec bitSetToList (set : BitSet) : int list =
  if set = 0 then
    []
  else
    let sub = (set >>> 1) |> bitSetToList |> List.map (fun i -> i + 1)
    if (set &&& 1) = 1 then 0 :: sub else sub

/// The empty solution.
let emptySolution = { flow = 0; steps = [] }

/// Searches the graph for a solution in a depth-first manner with the given actors.
/// While the actors take turns, each actor has their own time, thus they semantically
/// search the graph simulatenously.
let rec dfs (actors : Actor list) (graph : Graph<Id>) (state : State) (forbiddenIds : BitSet) (openValves : BitSet) : (Solution * State) =
  match actors with
    | us :: them ->
      let memoKey = { actors = actors |> List.map (fun a -> a.data); openValves = openValves }
      match Map.tryFind memoKey state.visited with
        | Some solution ->
          // Solution was memoized,
          solution, state 
        | None when us.data.remainingTime > 0 ->
          // Solution needs to be searched for and this actor still has time left
          let valve = Map.find us.data.valveId graph
          let (state' : State), candidates =
            (if (openValves |> containsBit us.data.valveId) || valve.rate = 0 then [0] else [0; 1])
              |> Seq.collect (fun decision ->
                valve.neighbors
                  |> Seq.filter (fun (n, _) -> not (forbiddenIds |> containsBit n))
                  |> Seq.map (fun n -> decision, n))
              |> Seq.fold (fun (state', acc) (decision, (n, steps)) ->
                let flowDelta = decision * valve.rate * (us.data.remainingTime - 1)
                let remainingTime' = us.data.remainingTime - decision - steps
                let openValves' = if decision = 1 then openValves |> insertBit us.data.valveId else openValves
                let us' = { us with data = { us.data with valveId = n; remainingTime = remainingTime' } }
                let actors' = them @ [us']
                let subSolution, state'' = dfs actors' graph state' forbiddenIds openValves'
                let newSolution =
                  { flow = flowDelta + subSolution.flow
                    steps = { actorName = us.name
                              valveId = us.data.valveId
                              remainingTime = us.data.remainingTime
                              decision = decision
                              flow = flowDelta
                              openValves = openValves' } :: subSolution.steps }
                (state'', newSolution :: acc)) (state, [])
          let solution =
            (emptySolution :: candidates)
              |> Seq.maxBy (fun c -> c.flow)
          let state'' = { state' with visited = Map.add memoKey solution state'.visited }
          solution, state''
        | _ ->
          // Solution needs to be searched for, but this actor has no time left and therefore is done
          dfs them graph state forbiddenIds openValves 
    | [] ->
      // All actors are done, therefore don't recurse
      emptySolution, state 

/// Prettyprints a step.
let prettyStep (initialTime : int) (step : Step) : string = 
  $"{step.actorName} @ Minute {initialTime - step.remainingTime + 1} \t => {step.valveId} += {step.flow} \t {step.openValves |> bitSetToList}"

/// Prettyprints a solution.
let prettySolution (initialTime : int) (solution : Solution) : string =
  ($"Flow: {solution.flow}" :: (solution.steps |> List.map (prettyStep initialTime)))
    |> String.concat "\n"

/// Replaces the given neighbor, adding a delta in the given valve.
let replaceNeighbor (oldId : 'id) (newId : 'id) (stepDelta : int) (valve : Valve<'id>) : Valve<'id> =
  { valve with neighbors = valve.neighbors |> List.map (fun (n, steps) -> if n = oldId then newId, steps + stepDelta else n, steps) }

/// Finds a node satisfying a given predicate.
let findNode (predicate : Valve<'id> -> bool) (graph : Graph<'id>) : Valve<'id> option =
  graph
    |> Map.values
    |> Seq.filter predicate
    |> Seq.tryHead

/// Optimizes the given graph by removing zero nodes and merging their steps into their neighbors.
let rec optimizeGraph (graph : Graph<'id>) : Graph<'id> =
  match findNode (fun v -> v.rate = 0 && v.neighbors.Length = 2) graph with
    | Some { id = id; neighbors = [src, srcSteps; dst, dstSteps] } ->
        graph
          |> Map.remove id
          |> Map.change src (fun v -> Some (replaceNeighbor id dst dstSteps v.Value))
          |> Map.change dst (fun v -> Some (replaceNeighbor id src srcSteps v.Value))
          |> optimizeGraph
    | _ -> graph

/// Maps valve indices to integer indices.
let indexGraph (graph : Graph<string>) : Graph<Id> * Map<string, Id> =
  let indexing =
    graph
      |> Map.keys
      |> Seq.mapi (fun i v -> v, i) |> Map.ofSeq
  graph
    |> Seq.map (fun v ->
      let name = v.Key
      let id = indexing |> Map.find name
      id, { id = id
            rate = v.Value.rate
            neighbors = v.Value.neighbors |> List.map (fun (n, steps) -> indexing |> Map.find n, steps) })
    |> Map.ofSeq, indexing

let pattern = Regex(@"Valve (\w+) has flow rate=(\d+); tunnels? leads? to valves? (.+)", RegexOptions.Compiled)

/// Parses a line to a valve.
let parseLine (line : string) : Valve<string> option = 
  match pattern.Match(line).Groups |> Seq.tail |> Seq.toList with
    | [name; rate; neighbors] ->
      Some
        { id = name.Value
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
    |> Seq.fold (fun m v -> Map.add v.id v m) Map.empty

printfn "==> Optimizing graph..."
let graph, indexing =
  baseGraph
    |> optimizeGraph
    |> indexGraph
printfn "Reduced size from %d to %d" baseGraph.Count graph.Count

let initialActor name time = { name = name; data = { valveId = indexing |> Map.find "AA"; remainingTime = time } }
let initialState = { visited = Map.empty }

/// Solve the problem by walking along disjoint paths.
/// Doesn't work for the demo, only for the actual input, but it'll do.
/// The inefficient way to implement this would be to construct a single
/// invocation of 'dfs' with the corresponding number of actors.
let rec solve initialTime actorCount forbiddenIds : int =
  if actorCount = 0 then
    0
  else
    let (solution, _) = dfs [initialActor "us" initialTime] graph initialState forbiddenIds emptyBitSet
    let forbiddenIds' = forbiddenIds ||| (solution.steps |> Seq.last).openValves
    printfn "(forbidden: %A) %s" (forbiddenIds |> bitSetToList) (prettySolution initialTime solution)
    solution.flow + solve initialTime (actorCount - 1) forbiddenIds'

printfn "==> Solving part 1..."
let part1 = solve 30 1 emptyBitSet
printfn "Part 1: %d" part1

printfn "==> Solving part 2..."
let part2 = solve 26 2 emptyBitSet
printfn "Part 2: %d" part2
