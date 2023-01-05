#!/usr/bin/env julia

struct Vec2
    x::Int
    y::Int
end

struct State
    pos::Union{Vec2,Nothing}
    blizzards::Dict{Vec2, Vec2}
    size::Vec2
end

function positions(width::Int, height::Int)
    Iterators.map(t -> Vec2(t[1], t[2]), Iterators.product(1:width, 1:height))
end

function positions(state::State)
    positions(state.size.x, state.size.y)
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
    parsed = Iterators.map(p -> (p, parse_dir(lines[p.y + 1][p.x + 1])), positions(width, height))
    blizzards = Dict(Iterators.filter(t -> !isnothing(t[2]), parsed))
    return State(nothing, blizzards, size)
end

lines = open("resources/demo.txt") do f
    readlines(f)
end

state = parse_input(lines)
print(state)
