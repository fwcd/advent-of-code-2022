#!/usr/bin/env julia

import Base.+

struct Vec2
    x::Int
    y::Int
end

struct State
    pos::Union{Vec2,Nothing}
    blizzards::Vector{Tuple{Vec2, Vec2}}
    size::Vec2
end

function (+)(p::Vec2, q::Vec2)
    Vec2(p.x + q.x, p.y + q.y)
end

function wrap(p::Vec2, q::Vec2)
    Vec2(mod(p.x - 1, q.x) + 1, mod(p.y - 1, q.y) + 1)
end

function next_blizzards(blizzards::Vector{Tuple{Vec2, Vec2}}, size::Vec2)
    collect(Iterators.map(t -> (wrap(t[1] + t[2], size), t[2]), blizzards))
end

function next_state(state::State)
    State(state.pos, next_blizzards(state.blizzards, state.size), state.size)
end

function positions(size::Vec2)
    Iterators.map(t -> Vec2(t[1], t[2]), Iterators.product(1:size.x, 1:size.y))
end

function positions(state::State)
    positions(state.size)
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
    parsed = Iterators.map(p -> (p, parse_dir(lines[p.y + 1][p.x + 1])), positions(size))
    blizzards = collect(Iterators.filter(t -> !isnothing(t[2]), parsed))
    return State(nothing, blizzards, size)
end

lines = open("resources/demo.txt") do f
    readlines(f)
end

state = parse_input(lines)
println(state)
for i in 1:10
    global state = next_state(state)
    println(state)
end
