#!/usr/bin/env ruby

require 'set'

sensors = File.readlines('resources/demo.txt')
  .map { |line|
    line.match(/Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)/)
      .captures
      .map { |s| s.to_i }
  }

puts sensors.map { |s| s.join(', ') }
