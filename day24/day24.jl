import Base.+
import Base.-

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

function has_blizzard_at(pos::Vec2, blizzards::Vector{Blizzard})
    Iterators.any(Iterators.map(b -> b.pos == pos, blizzards))
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
        positions(state.pos - Vec2(1, 1), state.pos + Vec2(1, 1)) # includes pos itself
    end
    size = state.size
    blizzards = next(state.blizzards, size)
    destinations = Iterators.filter(p -> isnothing(p) || (in_bounds(p, size) && !has_blizzard_at(p, blizzards)), neighbors)
    return Iterators.map(p -> State(p, blizzards, size), destinations)
end

function a_star_search(state::State)
    
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

lines = open("resources/demo.txt") do f
    readlines(f)
end

state = parse_input(lines)
for s in collect(childs(state))
    println(s)
    for s2 in collect(childs(s))
        println("  ", s2)
    end
end

# TODO: Implement Dijkstra
# TODO: Find a more efficient way to represent blizzards (e.g. as a multi-dict?)
