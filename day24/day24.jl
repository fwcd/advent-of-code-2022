import Base.+
import Base.-
import Base.*
import DataStructures

struct Vec2
    x::Int
    y::Int
end

struct Blizzard
    pos::Vec2
    dir::Union{Vec2,Nothing} # only (possibly) Nothing during parsing
end

struct State
    pos::Union{Vec2,Nothing}
    time::Int
    size::Vec2
    goal::Vec2
    initial_blizzards::Vector{Blizzard}
end

"Performs vector addition."
function (+)(p::Vec2, q::Vec2)
    Vec2(p.x + q.x, p.y + q.y)
end

"Performs vector subtraction."
function (-)(p::Vec2, q::Vec2)
    Vec2(p.x - q.x, p.y - q.y)
end

"Scales a vector by the given factor."
function (*)(p::Vec2, q::Int)
    Vec2(p.x * q, p.y * q)
end

"Scales a vector by the given factor."
function (*)(p::Int, q::Vec2)
    Vec2(p * q.x, p * q.y)
end

"Performs elementwise modulo within the range (1:q[element])."
function wrap(p::Vec2, q::Vec2)
    Vec2(mod(p.x - 1, q.x) + 1, mod(p.y - 1, q.y) + 1)
end

"Iterates all positions in the rectangle bounded by the given corners."
function positions(top_left::Vec2, bottom_right::Vec2)
    Iterators.map(t -> Vec2(t[1], t[2]), Iterators.product(top_left.x:bottom_right.x, top_left.y:bottom_right.y))
end

"Iterates all positions in the rectangle bounded by (1, 1) and the given size."
function positions(size::Vec2)
    positions(Vec2(1, 1), size)
end

"Checks whether the given position is between (1, 1) and the given size."
function in_bounds(pos::Vec2, size::Vec2)
    pos.x >= 1 && pos.x <= size.x && pos.y >= 1 && pos.y <= size.y
end

"Finds all blizzards at the given position."
function blizzards_at(pos::Vec2, blizzards::Vector{Blizzard})
    Iterators.filter(b -> b.pos == pos, blizzards)
end

"Checks whether there is a blizzard at the given position."
function has_blizzard_at(pos::Vec2, blizzards::Vector{Blizzard})
    !Iterators.isempty(blizzards_at(pos, blizzards))
end

"Computes the blizzard after the given number of time steps on a board bounded by the given size."
function blizzard_after(time::Int, size::Vec2, blizzard::Blizzard)
    Blizzard(wrap(blizzard.pos + (time * blizzard.dir), size), blizzard.dir)
end

"Computes the blizzards after the given number of time steps on a board bounded by the given size."
function blizzards_after(time::Int, size::Vec2, blizzards::Vector{Blizzard})
    Iterators.map(b -> blizzard_after(time, size, b), blizzards)
end

"Finds the next possible states after the given state."
function childs(state::State)
    right_after_start = Vec2(1, 1)
    right_before_goal = state.size

    neighbors = if isnothing(state.pos)
        # We're at the start
        [state.pos, right_after_start]
    elseif state.pos == state.goal
        # We're at the goal
        [state.pos, right_before_goal]
    else
        [
            [
                state.pos - Vec2(0, 1),
                state.pos - Vec2(1, 0), state.pos, state.pos + Vec2(1, 0),
                state.pos + Vec2(0, 1),
            ];
            # We need to treat start and goal separately since they are outside the bounds
            (state.pos == right_after_start ? [nothing] : []);
            (state.pos == right_before_goal ? [state.goal] : [])
        ]
    end
    size = state.size
    next_time = mod(state.time + 1, lcm(state.size.x, state.size.y))
    blizzards = collect(blizzards_after(next_time, state.size, state.initial_blizzards))
    destinations = Iterators.filter(p -> isnothing(p) || p == state.goal || (in_bounds(p, size) && !has_blizzard_at(p, blizzards)), neighbors)
    return Iterators.map(p -> State(p, next_time, size, goal, state.initial_blizzards), destinations)
end

"Prettyprints the given direction using a single character."
function pretty_dir(dir::Vec2)
    if dir == Vec2(1, 0)
        '>'
    elseif dir == Vec2(-1, 0)
        '<'
    elseif dir == Vec2(0, 1)
        'v'
    elseif dir == Vec2(0, -1)
        '^'
    else
        nothing
    end
end

"Prettyprints the given state."
function pretty(state::State)
    blizzards = collect(blizzards_after(state.time, state.size, state.initial_blizzards))
    return Iterators.join(Iterators.map(y -> Iterators.join(Iterators.map(x -> begin
        pos = Vec2(x, y)
        bs = collect(blizzards_at(pos, blizzards))
        if state.pos == pos
            'E'
        elseif length(bs) > 0
            if length(bs) == 1
                pretty_dir(bs[1].dir)
            else
                string(length(bs))
            end
        else
            '.'
        end
    end, 1:state.size.x)), 1:state.size.y), "\n")
end

"""
Estimates the remaining distance to the given destination.
The implementation uses the Manhattan metric to compute a
lower bound for the actual minimum path, making this an
admissible and monotonic heuristic for A* search.
"""
function estimate_remaining(state::State, destination::Vec2)
    delta = something(state.pos, Vec2(0, -1)) - destination
    return abs(delta.x) + abs(delta.y)
end

"""
Finds the shortest path to the given destination using A* search.
Returns a tuple of the final state, the path to the final state and
the total length of the path.
"""
function a_star_search(state::State, destination::Vec2)
    queue = DataStructures.PriorityQueue{Tuple{State,Vector{State},Int},Int}()
    visited = Set{State}()
    queue[(state, [], 0)] = estimate_remaining(state, destination)
    iterations = 0
    while !isempty(queue)
        ((current, path, len), cost) = DataStructures.peek(queue)
        push!(visited, current)
        if mod(iterations, 1000) == 0
            println("Searching at ", current.pos, " (", len, "/", cost, ")")
        end
        DataStructures.dequeue!(queue)
        if current.pos == destination
            println("Found solution after ", iterations, " iterations")
            return (current, path, len)
        end
        for child in childs(current)
            child_len = len + 1
            child_cost = child_len + estimate_remaining(child, destination)
            if !in(child, visited)
                push!(visited, child)
                DataStructures.enqueue!(queue, (child, [path; [current]], child_len), child_cost)
            end
        end
        iterations += 1
    end
    throw("No solution found")
end

"Parses the given character to a direction."
function parse_dir(raw::Char)
    if raw == '>'
        Vec2(1, 0)
    elseif raw == '<'
        Vec2(-1, 0)
    elseif raw == 'v'
        Vec2(0, 1)
    elseif raw == '^'
        Vec2(0, -1)
    else
        nothing
    end
end

"Parses the given input to a state."
function parse_input(lines::Vector{String})
    height = length(lines) - 2
    width = length(lines[1]) - 2
    size = Vec2(width, height)
    goal = size + Vec2(0, 1)
    parsed = Iterators.map(p -> Blizzard(p, parse_dir(lines[p.y + 1][p.x + 1])), positions(size))
    blizzards = collect(Iterators.filter(b -> !isnothing(b.dir), parsed))
    return State(nothing, 0, size, goal, blizzards)
end

# Read and parse input

lines = open("resources/input.txt") do f
    readlines(f)
end
state = parse_input(lines)

# Compute part 1

start = Vec2(1, 1)
goal = state.goal
(final_state, path, final_length) = a_star_search(state, goal)

println(pretty(final_state))

part1 = final_length
println("Part 1: ", part1)

# Compute part 2

(back_at_start_state, _, length_to_start) = a_star_search(final_state, start)
println("Back to the start took ", length_to_start)
(_, _, length_to_goal_again) = a_star_search(back_at_start_state, goal)
println("Back to the goal took ", length_to_goal_again)

part2 = final_length + length_to_start + length_to_goal_again
println("Part 2: ", part2)

# TODO: Find a more efficient way to represent blizzards (e.g. as a multi-dict?)
