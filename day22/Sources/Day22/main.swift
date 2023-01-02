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

func dot(_ lhs: (Int, Int, Int), _ rhs: (Int, Int, Int)) -> Int {
  lhs.0 * rhs.0 + lhs.1 * rhs.1 + lhs.2 * rhs.2
}

struct Mat3: Hashable {
  var x0, x1, x2: Int
  var y0, y1, y2: Int
  var z0, z1, z2: Int

  var x: (Int, Int, Int) { (x0, x1, x2) }
  var y: (Int, Int, Int) { (y0, y1, y2) }
  var z: (Int, Int, Int) { (z0, z1, z2) }

  var transposed: Self {
    Self(
      x0: x.0, x1: y.0, x2: z.0,
      y0: x.1, y1: y.1, y2: z.1,
      z0: x.2, z1: y.2, z2: z.2
    )
  }

  static func *(lhs: Self, rhs: Self) -> Self {
    let rhsT = rhs.transposed
    return Self(
      x0: dot(lhs.x, rhsT.x), x1: dot(lhs.x, rhsT.y), x2: dot(lhs.x, rhsT.z),
      y0: dot(lhs.y, rhsT.x), y1: dot(lhs.y, rhsT.y), y2: dot(lhs.y, rhsT.z),
      z0: dot(lhs.z, rhsT.x), z1: dot(lhs.z, rhsT.y), z2: dot(lhs.z, rhsT.z)
    )
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

protocol WrapperProtocol {
  init(fields: Fields, position: Vec2)

  mutating func wrap(next: Vec2) -> Vec2
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

  mutating func perform<Wrapper: WrapperProtocol>(instruction: Instruction, with wrapperType: Wrapper.Type) {
    switch instruction {
    case .tiles(let tiles):
      var wrapper = Wrapper(fields: fields, position: position)
      loop:
      for _ in 0..<tiles {
        let next = wrapper.wrap(next: position + Vec2(facing))
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

  func performing<Wrapper: WrapperProtocol>(instruction: Instruction, with wrapperType: Wrapper.Type) -> Self {
    var next = self
    next.perform(instruction: instruction, with: wrapperType)
    return next
  }

  func performing<Wrapper: WrapperProtocol>(instructions: [Instruction], with wrapperType: Wrapper.Type) -> Self {
    instructions.reduce(self) { $0.performing(instruction: $1, with: wrapperType) }
  }
}

struct Part1Wrapper: WrapperProtocol {
  var fields: Fields
  var position: Vec2

  mutating func wrap(next: Vec2) -> Vec2 {
    let rowRange = fields.rows[position.y].boardRange
    let colRange = fields.columns[position.x].boardRange
    var next = next
    next.x = rowRange.wrap(next.x)
    next.y = colRange.wrap(next.y)
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

print("Part 1: \(board.performing(instructions: instructions, with: Part1Wrapper.self).password)")

