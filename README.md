# Advent of Code 2022

[![Run (macOS)](https://github.com/fwcd/advent-of-code-2022/actions/workflows/run-macos.yml/badge.svg)](https://github.com/fwcd/advent-of-code-2022/actions/workflows/run-macos.yml)
[![Run (Ubuntu)](https://github.com/fwcd/advent-of-code-2022/actions/workflows/run-ubuntu.yml/badge.svg)](https://github.com/fwcd/advent-of-code-2022/actions/workflows/run-ubuntu.yml)

My solutions to the [Advent of Code 2022](https://adventofcode.com/2022), written in 25 different programming languages.

- [x] Day 01: AppleScript
- [x] Day 02: Vala
- [x] Day 03: Zig
- [x] Day 04: Racket
- [x] Day 05: Clojure
- [x] Day 06: CMake
- [x] Day 07: Perl
- [x] Day 08: Scala
- [x] Day 09: Haskell
- [x] Day 10: C
- [x] Day 11: Elixir
- [x] Day 12: Java
- [x] Day 13: JavaScript
- [x] Day 14: OCaml
- [x] Day 15: Ruby
- [x] Day 16: F#
- [x] Day 17: C#
- [x] Day 18: Apple Shortcuts ([yes, this one](https://support.apple.com/en-us/guide/shortcuts/welcome/ios))
- [x] Day 19: Rust
- [x] Day 20: Objective-C
- [x] Day 21: Prolog
- [x] Day 22: Swift
- [x] Day 23: C++
- [ ] Day 24: Julia
- [ ] Day 25

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
