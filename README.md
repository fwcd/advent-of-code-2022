<!-- Automatically generated from README.md.gyb, do not edit directly! -->

# Advent of Code 2022

[![Run (macOS)](https://github.com/fwcd/advent-of-code-2022/actions/workflows/run-macos.yml/badge.svg)](https://github.com/fwcd/advent-of-code-2022/actions/workflows/run-macos.yml)
[![Run (Ubuntu)](https://github.com/fwcd/advent-of-code-2022/actions/workflows/run-ubuntu.yml/badge.svg)](https://github.com/fwcd/advent-of-code-2022/actions/workflows/run-ubuntu.yml)

My solutions to the [Advent of Code 2022](https://adventofcode.com/2022), written in 25 different programming languages.

- [x] Day 01: [AppleScript](day01/src/day01.applescript)
- [x] Day 02: [Vala](day02/src/day02.vala)
- [x] Day 03: [Zig](day03/src/main.zig)
- [x] Day 04: [Racket](day04/src/day04.rkt)
- [x] Day 05: [Clojure](day05/src/day05/core.clj)
- [x] Day 06: [CMake](day06/CMakeLists.txt)
- [x] Day 07: [Perl](day07/src/day07.pl)
- [x] Day 08: [Scala](day08/app/src/main/scala/day08/App.scala)
- [x] Day 09: [Haskell](day09/app/Main.hs)
- [x] Day 10: [C](day10/src/day10.c)
- [x] Day 11: [Elixir](day11/lib/day11.ex)
- [x] Day 12: [Java](day12/app/src/main/java/dev/fwcd/aoc2022/day12/App.java)
- [x] Day 13: [JavaScript](day13/src/day13.js)
- [x] Day 14: [OCaml](day14/bin/main.ml)
- [x] Day 15: [Ruby](day15/bin/day15.rb)
- [x] Day 16: [F#](day16/Program.fs)
- [x] Day 17: [C#](day17/Program.cs)
- [x] Day 18: [Apple Shortcuts](day18/day18.shortcut) ([yes, this one](https://support.apple.com/en-us/guide/shortcuts/welcome/ios))
- [x] Day 19: [Rust](day19/src/main.rs)
- [x] Day 20: [Objective-C](day20/src/day20.m)
- [x] Day 21: [Prolog](day21/day21.pl)
- [x] Day 22: [Swift](day22/Sources/Day22/main.swift)
- [x] Day 23: [C++](day23/src/day23.cpp)
- [x] Day 24: [Julia](day24/day24.jl)
- [x] Day 25: [Python](day25/day25.py)

## Scripts

Each day includes two scripts:

- `./bootstrap` installs the language (compiler or interpreter) and project dependencies if needed
- `./run` builds and runs the program

Some days that need additional configuration also have environment-related scripts invoked by CI:

- `./path` computes a list of entries to dynamically append to the `PATH`
- `./env` computes a list of environment variables to set

This standardized pattern lets CI use a single workflow (per OS) across all days. Additionally, they make it easy to get started developing locally even across the range of different languages, build tools and package managers involved.

> Note that some bootstrap scripts are still geared around CI use, so you may still prefer to install the corresponding toolchain using your package manager manually.

## Previous years

My solutions to the previous challenges can be found here:

- [`advent-of-code-2021`](https://github.com/fwcd/advent-of-code-2021)
- [`advent-of-code-2020`](https://github.com/fwcd/advent-of-code-2020)
- [`advent-of-code-2019`](https://github.com/fwcd/advent-of-code-2019)
- [`advent-of-code-2015`](https://github.com/fwcd/advent-of-code-2015)
