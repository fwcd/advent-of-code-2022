import Foundation

enum Field: Character {
  case border = " "
  case solid = "#"
  case space = "."
}

struct Vec2: Hashable {
  var x: Int
  var y: Int

  static func +(lhs: Self, rhs: Self) -> Self {
    Self(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }

  static func *(lhs: Self, rhs: Int) -> Self {
    Self(x: lhs.x * rhs, y: lhs.y * rhs)
  }
}

enum Direction: Int, CaseIterable {
  case right = 0
  case down
  case left
  case up

  init?(rawString: String) {
    switch rawString {
    case "L": self = .left
    case "R": self = .right
    default:  return nil
    }
  }

  var arrow: Character {
    switch self {
    case .right: return ">"
    case .down: return "v"
    case .left: return "<"
    case .up: return "^"
    }
  }

  static func +=(lhs: inout Self, rhs: Self) {
    lhs = Self(rawValue: (lhs.rawValue + rhs.rawValue + 1) % Self.allCases.count)!
  }
}

extension Vec2 {
  init(_ direction: Direction) {
    switch direction {
    case .left:  self.init(x: -1, y:  0)
    case .up:    self.init(x:  0, y: -1)
    case .right: self.init(x:  1, y:  0)
    case .down:  self.init(x:  0, y:  1)
    }
  }
}

enum Instruction {
  case tiles(Int)
  case turn(Direction)
}

extension Array where Element == Field {
  var boardRange: Range<Int> {
    let start = drop { $0 == .border }
    let end = start.drop { $0 != .border }
    return start.startIndex..<end.startIndex
  }
}

extension Range where Bound == Int {
  func wrap(_ value: Int) -> Int {
    ((value - lowerBound) % count + count) % count + lowerBound
  }
}

struct Board: CustomStringConvertible {
  var fields: [[Field]]
  var facing: Direction
  var position: Vec2

  var transposed: Board {
    var t = self
    let width = fields.map(\.count).max() ?? 0
    t.fields = (0..<width).map { x in fields.map { $0[min(x, $0.count - 1)] } }
    return t
  }
  var password: Int {
    1000 * (position.y + 1) + 4 * (position.x + 1) + facing.rawValue
  }
  var description: String {
    fields
      .enumerated()
      .map { (y, row) in String(row.enumerated().map { (x, f) in
        position == Vec2(x: x, y: y) ? facing.arrow : f.rawValue
      }) }
      .joined(separator: "\n")
  }

  mutating func perform(instruction: Instruction) {
    switch instruction {
    case .tiles(let tiles):
      let rowRange = fields[position.y].boardRange
      let colRange = transposed.fields[position.x].boardRange
      loop:
      for _ in 0..<tiles {
        var next = position + Vec2(facing)
        next.x = rowRange.wrap(next.x)
        next.y = colRange.wrap(next.y)
        let row = fields[next.y]
        switch row[min(row.count - 1, next.x)] {
          case .space: position = next
          case .solid: break loop
          case .border: fatalError("Unreachable")
        }
      }
    case .turn(let turn):
      facing += turn
    }
  }

  func performing(instruction: Instruction) -> Self {
    var next = self
    next.perform(instruction: instruction)
    return next
  }
}

extension Board {
  init(rawFields: [[Character]]) {
    fields = rawFields.map { $0.map { Field(rawValue: $0)! } }
    facing = .right
    position = Vec2(x: fields[0].firstIndex { $0 != .border }!, y: 0)
  }
}

let url = URL(filePath: "Resources/input.txt")
let input = String(data: try Data(contentsOf: url), encoding: .utf8)!
let rawParts = input.split(separator: "\n\n")

let board = Board(rawFields: Array(rawParts[0].split(separator: "\n").map(Array.init)))
let instructions = rawParts[1].matches(of: /(?<tiles>\d+)|(?<turn>[LR])/).map { match -> Instruction in
  let output = match.output
  if let tiles = output.tiles {
    return .tiles(Int(tiles)!)
  } else if let turn = output.turn {
    return .turn(Direction(rawString: String(turn))!)
  } else {
    fatalError("Unreachable")
  }
}

let finalBoard = instructions.reduce(board) { $0.performing(instruction: $1) }
print("Part 1: \(finalBoard.password)")
