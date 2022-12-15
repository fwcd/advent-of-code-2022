#!/usr/bin/env ruby

require 'set'

def manhattan(p, q)
  (p[0] - q[0]).abs + (p[1] - q[1]).abs
end

def tuning_frequency(p)
  p[0] * 4000000 + p[1]
end

class Range
  def overlaps?(other)
    other.include?(self.min) || other.include?(self.max) || self.include?(other.min) || self.include?(other.max)
  end

  def merge(other)
    [self.min, other.min].min..[self.max, other.max].max
  end
end

def scan(y, sensors)
  sensors
    .map { |s, b| [s, b, manhattan(s, b) - (s[1] - y).abs] }
    .filter { |s, b, d| d > 0 }
    .map { |s, b, d| ((s[0] - d)..(s[0] + d)) }
    .sort_by { |r| r.min }
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

def valid_positions(y, sensors)
  if y % 1_000_000 == 0 then
    puts "Searching y = #{y}..."
  end
  rs = scan(y, sensors)
  rs[...-1].zip(rs[1..])
    .filter { |l, r| r.min - l.max == 2 }
    .map { |l, r| [l.max + 1, y] }
end

def valid_positions_in(ys, sensors)
  ys.flat_map { |y| valid_positions(y, sensors) }
end

sensors = File.readlines('resources/input.txt')
  .map { |line|
    sx, sy, bx, by = line.match(/Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)/)
      .captures
      .map { |s| s.to_i }
    [[sx, sy], [bx, by]]
  }

puts "Part 1: #{invalid_position_count(2_000_000, sensors)}"
puts "Part 2: #{tuning_frequency(valid_positions_in(0..4_000_000, sensors).last)}"
