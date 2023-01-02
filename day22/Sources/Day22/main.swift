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

struct Vec3: Hashable {
  var x: Int
  var y: Int
  var z: Int

  func dot(_ rhs: Self) -> Int {
    x * rhs.x + y * rhs.y + z * rhs.z
  }
}

struct Mat3: Hashable {
  var e0: Vec3
  var e1: Vec3
  var e2: Vec3

  static func *(lhs: Self, rhs: Vec3) -> Vec3 {
    Vec3(
      x: Vec3(x: lhs.e0.x, y: lhs.e1.x, z: lhs.e2.x).dot(rhs),
      y: Vec3(x: lhs.e0.y, y: lhs.e1.y, z: lhs.e2.y).dot(rhs),
      z: Vec3(x: lhs.e0.z, y: lhs.e1.z, z: lhs.e2.z).dot(rhs)
    )
  }

  static func *(lhs: Self, rhs: Self) -> Self {
    Self(e0: lhs * rhs.e0, e1: lhs * rhs.e1, e2: lhs * rhs.e2)
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

class Fields {
  let rows: [[Field]]
  let columns: [[Field]]

  init(rows: [[Field]]) {
    self.rows = rows
    let width = rows.map(\.count).max() ?? 0
    columns = (0..<width).map { x in rows.map { x < $0.count ? $0[x] : .border } }
  }
}

protocol WrapperProtocol {
  init(fields: Fields, position: Vec2, facing: Direction)

  func wrap(next: Vec2) -> Vec2
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
      let wrapper = Wrapper(fields: fields, position: position, facing: facing)
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
  var rowRange: Range<Int>
  var colRange: Range<Int>

  init(fields: Fields, position: Vec2, facing: Direction) {
    self.fields = fields
    rowRange = fields.rows[position.y].boardRange
    colRange = fields.columns[position.x].boardRange
  }

  func wrap(next: Vec2) -> Vec2 {
    var next = next
    next.x = rowRange.wrap(next.x)
    next.y = colRange.wrap(next.y)
    return next
  }
}

struct Part2Wrapper: WrapperProtocol {
  private static let cubeSize = 50

  private let fields: Fields
  private let cubeMap: [Vec2: Vec3]

  init(fields: Fields, position: Vec2, facing: Direction) {
    self.fields = fields
    cubeMap = [:] // TODO
  }

  func wrap(next: Vec2) -> Vec2 {
    fatalError("TODO")
  }
}

extension Board {
  init(rawFields: [[Character]]) {
    fields = Fields(rows: rawFields.map { $0.map { Field(rawValue: $0)! } })
    position = Vec2(x: fields.rows[0].firstIndex { $0 != .border }!, y: 0)
  }
}

let url = URL(filePathWithURL: "Resources/input.txt")
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

