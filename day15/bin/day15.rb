#!/usr/bin/env ruby

require 'set'

def manhattan(p, q)
  (p[0] - q[0]).abs + (p[1] - q[1]).abs
end

def solve(y, sensors)
  beacons = sensors
    .map { |s, b| b }
    .to_set
  sensors
    .map { |s, b| [s, b, manhattan(s, b) - (s[1] - y).abs] }
    .filter { |s, b, d| d > 0 }
    .flat_map { |s, b, d| ((s[0] - d)..(s[0] + d)).map { |x| [x, y] } }
    .to_set
    .filter { |p| !beacons.include?(p) }
    .length
end

sensors = File.readlines('resources/input.txt')
  .map { |line|
    sx, sy, bx, by = line.match(/Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)/)
      .captures
      .map { |s| s.to_i }
    [[sx, sy], [bx, by]]
  }

puts "Part 1: #{solve(2000000, sensors)}"
