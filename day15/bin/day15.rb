#!/usr/bin/env ruby

require 'set'

def manhattan(p, q)
  (p[0] - q[0]).abs + (p[1] - q[1]).abs
end

class Range
  def overlaps?(other)
    other.include?(self.min) || other.include?(self.max)
  end

  def merge(other)
    [self.min, other.min].min..[self.max, other.max].max
  end
end

def scan(y, sensors)
  sensors
    .map { |s, b| [s, b, manhattan(s, b) - (s[1] - y).abs] }
    .filter { |s, b, d| d > 0 }
    .sort_by { |s, b, d| s[0] }
    .map { |s, b, d| ((s[0] - d)..(s[0] + d)) }
    .reduce([]) { |rs, r2| if rs.last&.overlaps?(r2) then [*rs[0...-1], rs.last.merge(r2)] else [*rs, r2] end }
end

def invalid_position_count(y, sensors)
  beacons = sensors
    .map { |s, b| b }
    .filter { |b| b[1] == y }
    .to_set
    .length
  scan(y, sensors)
    .map { |r| r.size }
    .sum - beacons
end

sensors = File.readlines('resources/input.txt')
  .map { |line|
    sx, sy, bx, by = line.match(/Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)/)
      .captures
      .map { |s| s.to_i }
    [[sx, sy], [bx, by]]
  }

puts "Part 1: #{invalid_position_count(2_000_000, sensors)}"
