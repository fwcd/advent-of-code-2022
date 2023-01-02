import Foundation

infix operator %%

extension Int {
  static func %%(lhs: Self, rhs: Self) -> Self {
    ((lhs % rhs) + rhs) % rhs
  }
}

enum Field: Character, Hashable {
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

enum Direction: Int, Hashable, CaseIterable {
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
    case .down:  return "v"
    case .left:  return "<"
    case .up:    return "^"
    }
  }

  static func +(lhs: Self, rhs: Self) -> Self {
    Self(rawValue: (lhs.rawValue + rhs.rawValue + 1) % Self.allCases.count)!
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

enum Axis: Int, Hashable, CaseIterable {
  case x = 0
  case y
  case z

  var leftRightAxis: Axis {
    switch self {
    case .x, .z: return .y
    case .y:     return .z
    }
  }
  var upDownAxis: Axis {
    switch self {
    case .x:     return .z
    case .y, .z: return .x
    }
  }
}

struct CubeFace: Hashable {
  var axis: Axis
  var up: Bool

  static func +(lhs: Self, rhs: Direction) -> Self {
    switch rhs {
    case .left:  return lhs.rotating(around: lhs.axis.leftRightAxis, delta: -1)
    case .right: return lhs.rotating(around: lhs.axis.leftRightAxis, delta:  1)
    case .up:    return lhs.rotating(around: lhs.axis.upDownAxis,    delta: -1)
    case .down:  return lhs.rotating(around: lhs.axis.upDownAxis,    delta:  1)
    }
  }

  func rotating(around rotationAxis: Axis, delta: Int) -> Self {
    func swapBits(_ x: Int) -> Int {
      ((x & 1) << 1) | ((x >> 1) & 1)
    }
    let axes = Axis.allCases.filter { $0 != rotationAxis }
    let axisIndex = axes.firstIndex(of: axis)!
    let upIndex = up ? 1 : 0
    let encodedCurrent = (axisIndex << 1) | upIndex
    let encodedNext = swapBits((swapBits(encodedCurrent) + delta) %% 4)
    return Self(axis: axes[(encodedNext >> 1) & 1], up: (encodedNext & 1) == 1)
  }
}

enum Instruction: Hashable {
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
    ((value - lowerBound) %% count) + lowerBound
  }
}

struct Fields {
  let rows: [[Field]]
  lazy private(set) var columns: [[Field]] = {
    let width = rows.map(\.count).max() ?? 0
    return (0..<width).map { x in rows.map { x < $0.count ? $0[x] : .border } }
  }()
}

struct Board: CustomStringConvertible {
  var fields: Fields
  var position: Vec2 {
    willSet {
      track[position] = facing
    }
  }
  var facing: Direction = .right
  var track: [Vec2: Direction] = [:]

  var password: Int {
    1000 * (position.y + 1) + 4 * (position.x + 1) + facing.rawValue
  }
  var description: String {
    fields.rows
      .enumerated()
      .map { (y, row) in String(row.enumerated().map { (x, f) in
        track[Vec2(x: x, y: y)]?.arrow ?? f.rawValue
      }) }
      .joined(separator: "\n")
  }

  mutating func perform(instruction: Instruction) {
    switch instruction {
    case .tiles(let tiles):
      let rowRange = fields.rows[position.y].boardRange
      let colRange = fields.columns[position.x].boardRange
      loop:
      for _ in 0..<tiles {
        var next = position + Vec2(facing)
        next.x = rowRange.wrap(next.x)
        next.y = colRange.wrap(next.y)
        let row = fields.rows[next.y]
        switch row[min(row.count - 1, next.x)] {
          case .space: position = next
          case .solid: break loop
          case .border: fatalError("Unreachable")
        }
      }
    case .turn(let turn):
      facing = facing + turn
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
    fields = Fields(rows: rawFields.map { $0.map { Field(rawValue: $0)! } })
    position = Vec2(x: fields.rows[0].firstIndex { $0 != .border }!, y: 0)
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
