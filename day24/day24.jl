#!/usr/bin/env julia

input = open("resources/demo.txt") do f
    readlines(f)
end

println(input)
