import Foundation

enum Direction: String {
  case left = "L"
  case right = "R"
}

enum Instruction {
  case tiles(Int)
  case turn(Direction)
}

let url = URL(filePath: "Resources/demo.txt")
let input = String(data: try Data(contentsOf: url), encoding: .utf8)!
let rawParts = input.split(separator: "\n\n")

let map = Array(rawParts[0].split(separator: "\n").map(Array.init))
let instructions = rawParts[1].matches(of: /(?<tiles>\d+)|(?<dir>[LR])/).map { match -> Instruction in
  let output = match.output
  if let tiles = output.tiles {
    return .tiles(Int(tiles)!)
  } else if let dir = output.dir {
    return .turn(Direction(rawValue: String(dir))!)
  } else {
    fatalError("Unreachable")
  }
}

print(instructions)
