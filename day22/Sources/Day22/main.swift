import Foundation
import Collections

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

struct Vec2: Hashable, CustomStringConvertible {
  var x: Int
  var y: Int

  var description: String { "(\(x), \(y))" }

  static func +(lhs: Self, rhs: Self) -> Self {
    Self(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }

  static func -(lhs: Self, rhs: Self) -> Self {
    Self(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
  }

  static func *(lhs: Self, rhs: Int) -> Self {
    Self(x: lhs.x * rhs, y: lhs.y * rhs)
  }

  static func /(lhs: Self, rhs: Int) -> Self {
    Self(x: lhs.x / rhs, y: lhs.y / rhs)
  }
}

struct Vec3: Hashable, CustomStringConvertible {
  var x: Int
  var y: Int
  var z: Int

  var description: String { "(\(x), \(y), \(z))" }

  func dot(_ rhs: Self) -> Int {
    x * rhs.x + y * rhs.y + z * rhs.z
  }
}

struct Mat3: Hashable, CustomStringConvertible {
  var e0: Vec3
  var e1: Vec3
  var e2: Vec3

  var description: String {
    "(\(e0), \(e1), \(e2))"
  }

  var transpose: Self {
    Self(
      e0: Vec3(x: e0.x, y: e1.x, z: e2.x),
      e1: Vec3(x: e0.y, y: e1.y, z: e2.y),
      e2: Vec3(x: e0.z, y: e1.z, z: e2.z)
    )
  }

  static var identity: Self {
    Self(
      e0: Vec3(x: 1, y: 0, z: 0),
      e1: Vec3(x: 0, y: 1, z: 0),
      e2: Vec3(x: 0, y: 0, z: 1)
    )
  }
  static var rotX: Self {
    Self(
      e0: Vec3(x: 1, y: 0, z:  0),
      e1: Vec3(x: 0, y: 0, z: -1),
      e2: Vec3(x: 0, y: 1, z:  0)
    )
  }
  static var rotY: Self {
    Self(
      e0: Vec3(x:  0, y: 0, z: 1),
      e1: Vec3(x:  0, y: 1, z: 0),
      e2: Vec3(x: -1, y: 0, z: 0)
    )
  }
  static var rotZ: Self {
    Self(
      e0: Vec3(x: 0, y: -1, z: 0),
      e1: Vec3(x: 1, y:  0, z: 0),
      e2: Vec3(x: 0, y:  0, z: 1)
    )
  }

  static func *(lhs: Self, rhs: Vec3) -> Vec3 {
    let t = lhs.transpose
    return Vec3(x: t.e0.dot(rhs), y: t.e1.dot(rhs), z: t.e2.dot(rhs))
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

  var rotation: Mat3 {
    switch self {
    case .right: return .rotZ
    case .down: return .rotY
    case .left: return .rotZ.transpose
    case .up: return .rotY.transpose
    }
  }

  static func +(lhs: Self, rhs: Self) -> Self {
    Self(rawValue: (lhs.rawValue + rhs.rawValue + 1) % Self.allCases.count)!
  }
}

extension Vec2 {
  init(_ vec3: Vec3) {
    self.init(x: vec3.x, y: vec3.y)
  }

  init(_ direction: Direction) {
    switch direction {
    case .left:  self.init(x: -1, y:  0)
    case .up:    self.init(x:  0, y: -1)
    case .right: self.init(x:  1, y:  0)
    case .down:  self.init(x:  0, y:  1)
    }
  }
}

extension Vec3 {
  init(_ vec2: Vec2) {
    self.init(x: vec2.x, y: vec2.y, z: 0)
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
  let cubeSize: Int
  let cubeMap: [Vec2: Mat3]

  init(rows: [[Field]], cubeSize: Int) {
    self.rows = rows
    self.cubeSize = cubeSize

    let width = rows.map(\.count).max() ?? 0
    let columns = (0..<width).map { x in rows.map { x < $0.count ? $0[x] : .border } }
    self.columns = columns

    /// Construct a cube map by performing a DFS on the unrolled cube net.
    func constructCubeMap(mapPos: Vec2, cubeRotation: Mat3 = .identity, cubeMap: inout [Vec2: Mat3]) {
      var queue = Deque([(mapPos: mapPos, cubeRotation: cubeRotation)])
      while let node = queue.popFirst() {
        let position = node.mapPos * cubeSize
        guard position.y >= 0 && position.y < rows.count,
              position.x >= 0 && position.x < rows[position.y].count,
              rows[position.y][position.x] != .border else { continue }
        if !cubeMap.keys.contains(node.mapPos) {
          cubeMap[node.mapPos] = node.cubeRotation
          print(node.cubeRotation)
          for direction in Direction.allCases {
            queue.append((mapPos: node.mapPos + Vec2(direction), cubeRotation: direction.rotation * node.cubeRotation))
          }
        }
      }
    }

    var cubeMap: [Vec2: Mat3] = [:]
    constructCubeMap(mapPos: rows[0].enumerated().first { $0.element != .border }.map { Vec2(x: $0.offset, y: 0) / cubeSize }!, cubeMap: &cubeMap)
    self.cubeMap = cubeMap
  }
}

protocol WrapperProtocol {
  init(fields: Fields, position: Vec2, facing: Direction)

  func wrap(current: Vec2, next: Vec2) -> Vec2
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
        let next = wrapper.wrap(current: position, next: position + Vec2(facing))
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

  func wrap(current: Vec2, next: Vec2) -> Vec2 {
    var next = next
    next.x = rowRange.wrap(next.x)
    next.y = colRange.wrap(next.y)
    return next
  }
}

struct Part2Wrapper: WrapperProtocol {
  private let fields: Fields
  private let rotation: Mat3

  init(fields: Fields, position: Vec2, facing: Direction) {
    self.fields = fields
    rotation = facing.rotation
  }

  func wrap(current: Vec2, next: Vec2) -> Vec2 {
    let rowRange = fields.rows[next.y].boardRange
    let colRange = fields.columns[next.x].boardRange
    guard !rowRange.contains(next.y) || !colRange.contains(next.x) else { return next }
    let mapPos = current / fields.cubeSize
    guard let cubeRotation = fields.cubeMap[mapPos] else { fatalError("No cube normal mapped for \(mapPos) (cube map: \(fields.cubeMap))") }
    let nextRotation = rotation * cubeRotation
    var axisChangeOfBasis = Mat3.identity
    axisChangeOfBasis.e0 = nextRotation.e0
    let rotationAroundNormal = axisChangeOfBasis * nextRotation * axisChangeOfBasis.transpose
    var flatRotation = Mat3.identity
    var additionalRotation = Mat3.identity
    for _ in 0..<4 {
      let totalRotation = additionalRotation * nextRotation
      if let nextMapPos = fields.cubeMap.first(where: { $0.value == totalRotation })?.key {
        let baseIntraPos = next - ((next / fields.cubeSize) * fields.cubeSize)
        let nextIntraPos = Vec2(flatRotation * Vec3(baseIntraPos))
        return (nextMapPos * fields.cubeSize) + nextIntraPos
      }
      additionalRotation = rotationAroundNormal * additionalRotation
      flatRotation = nextRotation * flatRotation
    }
    fatalError("No aligned rotation of \(nextRotation) was mapped (cube map: \(fields.cubeMap))")
  }
}

extension Board {
  init(rawFields: [[Character]], cubeSize: Int) {
    fields = Fields(rows: rawFields.map { $0.map { Field(rawValue: $0)! } }, cubeSize: cubeSize)
    position = Vec2(x: fields.rows[0].firstIndex { $0 != .border }!, y: 0)
  }
}

let url = URL(fileURLWithPath: "Resources/demo.txt")
let input = String(data: try Data(contentsOf: url), encoding: .utf8)!
let rawParts = input.split(separator: "\n\n")

let cubeSize = 4
let board = Board(rawFields: Array(rawParts[0].split(separator: "\n").map(Array.init)), cubeSize: cubeSize)
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
print("Part 2: \(board.performing(instructions: instructions, with: Part2Wrapper.self).password)")

