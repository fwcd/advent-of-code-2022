import Base.+
import Base.-
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
    blizzards::Vector{Blizzard}
    size::Vec2
end

function (+)(p::Vec2, q::Vec2)
    Vec2(p.x + q.x, p.y + q.y)
end

function (-)(p::Vec2, q::Vec2)
    Vec2(p.x - q.x, p.y - q.y)
end

function wrap(p::Vec2, q::Vec2)
    Vec2(mod(p.x - 1, q.x) + 1, mod(p.y - 1, q.y) + 1)
end

function positions(top_left::Vec2, bottom_right::Vec2)
    Iterators.map(t -> Vec2(t[1], t[2]), Iterators.product(top_left.x:bottom_right.x, top_left.y:bottom_right.y))
end

function positions(size::Vec2)
    positions(Vec2(1, 1), size)
end

function in_bounds(pos::Vec2, size::Vec2)
    pos.x >= 1 && pos.x <= size.x && pos.y >= 1 && pos.y <= size.y
end

function blizzards_at(pos::Vec2, blizzards::Vector{Blizzard})
    Iterators.filter(b -> b.pos == pos, blizzards)
end

function has_blizzard_at(pos::Vec2, blizzards::Vector{Blizzard})
    !Iterators.isempty(blizzards_at(pos, blizzards))
end

function next(blizzard::Blizzard, size::Vec2)
    Blizzard(wrap(blizzard.pos + blizzard.dir, size), blizzard.dir)
end

function next(blizzards::Vector{Blizzard}, size::Vec2)
    collect(Iterators.map(b -> next(b, size), blizzards))
end

function next(state::State)
    State(state.pos, next(state.blizzards, state.size), state.size)
end

function childs(state::State)
    neighbors = if isnothing(state.pos)
        [nothing, Vec2(1, 1)]
    else
        [
            state.pos - Vec2(0, 1),
            state.pos - Vec2(1, 0), state.pos, state.pos + Vec2(1, 0),
            state.pos + Vec2(0, 1),
        ]
    end
    size = state.size
    blizzards = next(state.blizzards, size)
    destinations = Iterators.filter(p -> isnothing(p) || (in_bounds(p, size) && !has_blizzard_at(p, blizzards)), neighbors)
    return Iterators.map(p -> State(p, blizzards, size), destinations)
end

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

function pretty(state::State)
    Iterators.join(Iterators.map(y -> Iterators.join(Iterators.map(x -> begin
        pos = Vec2(x, y)
        blizzards = collect(blizzards_at(pos, state.blizzards))
        if state.pos == pos
            'E'
        elseif length(blizzards) > 0
            if length(blizzards) == 1
                pretty_dir(blizzards[1].dir)
            else
                string(length(blizzards))
            end
        else
            '.'
        end
    end, 1:state.size.x)), 1:state.size.y), "\n")
end

function estimate_remaining(state::State)
    delta = something(state.pos, Vec2(0, -1)) - state.size
    return abs(delta.x) + abs(delta.y)
end

function a_star_search(state::State)
    queue = DataStructures.PriorityQueue{Tuple{State,Int},Int}()
    visited = Set{State}()
    queue[(state, 0)] = estimate_remaining(state)
    while !isempty(queue)
        ((current, len), cost) = DataStructures.peek(queue)
        push!(visited, current)
        if mod(length(visited), 10_000) == 0
            println("Searching ", current.pos, " (", len, "/", cost, ")")
        end
        DataStructures.dequeue!(queue)
        if current.pos == current.size
            return (current, len)
        end
        for child in childs(current)
            if !in(child, visited)
                child_len = len + 1
                child_cost = child_len + estimate_remaining(child)
                DataStructures.enqueue!(queue, (child, child_len), child_cost)
            end
        end
    end
    throw("No solution found")
end

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

function parse_input(lines::Vector{String})
    height = length(lines) - 2
    width = length(lines[1]) - 2
    size = Vec2(width, height)
    parsed = Iterators.map(p -> Blizzard(p, parse_dir(lines[p.y + 1][p.x + 1])), positions(size))
    blizzards = collect(Iterators.filter(b -> !isnothing(b.dir), parsed))
    return State(nothing, blizzards, size)
end

lines = open("resources/input.txt") do f
    readlines(f)
end

state = parse_input(lines)
(final_state, final_length) = a_star_search(state)

println(pretty(final_state))
println("Part 1: ", final_length + 1)

# TODO: Find a more efficient way to represent blizzards (e.g. as a multi-dict?)
