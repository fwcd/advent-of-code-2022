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
  var x: Int = 0
  var y: Int = 0

  var sum: Int { x + y }
  var description: String { "(\(x), \(y))" }

  static var zero = Self()

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

  static prefix func -(lhs: Self) -> Self {
    Self(x: -lhs.x, y: -lhs.y)
  }
}

struct Vec3: Hashable, CustomStringConvertible {
  var x: Int = 0
  var y: Int = 0
  var z: Int = 0

  var sum: Int { x + y }
  var description: String { "(\(x), \(y), \(z))" }

  static var zero = Self()

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
      e0: Vec3(x: 1, y:  0, z: 0),
      e1: Vec3(x: 0, y:  0, z: 1),
      e2: Vec3(x: 0, y: -1, z: 0)
    )
  }
  static var rotY: Self {
    Self(
      e0: Vec3(x: 0, y: 0, z: -1),
      e1: Vec3(x: 0, y: 1, z:  0),
      e2: Vec3(x: 1, y: 0, z:  0)
    )
  }
  static var rotZ: Self {
    Self(
      e0: Vec3(x:  0, y: 1, z: 0),
      e1: Vec3(x: -1, y: 0, z: 0),
      e2: Vec3(x:  0, y: 0, z: 1)
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
    case .down: return .rotY.transpose
    case .left: return .rotZ.transpose
    case .up: return .rotY
    }
  }

  static func +(lhs: Self, rhs: Self) -> Self {
    Self(rawValue: (lhs.rawValue + rhs.rawValue + 1) % Self.allCases.count)!
  }
}

extension Vec2 {
  init(fromXy vec3: Vec3) {
    self.init(x: vec3.x, y: vec3.y)
  }
  
  init(fromYz vec3: Vec3) {
    self.init(x: vec3.y, y: vec3.z)
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

extension Direction {
  init?(_ vec2: Vec2) {
    guard let direction = Self.allCases.first(where: { Vec2($0) == vec2 }) else {
      return nil
    }
    self = direction
  }
}

extension Vec3 {
  init(xy vec2: Vec2) {
    self.init(x: vec2.x, y: vec2.y)
  }

  init(yz vec2: Vec2) {
    self.init(y: vec2.x, z: vec2.y)
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

final class Fields {
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
      var queue: Deque<(mapPos: Vec2, cubeRotation: Mat3, origin: Direction?)> = [(mapPos: mapPos, cubeRotation: cubeRotation, origin: nil)]
      while let node = queue.popFirst() {
        let position = node.mapPos * cubeSize
        guard position.y >= 0 && position.y < rows.count,
              position.x >= 0 && position.x < rows[position.y].count,
              rows[position.y][position.x] != .border else { continue }
        if !cubeMap.keys.contains(node.mapPos) {
          cubeMap[node.mapPos] = node.cubeRotation
          for direction in Direction.allCases {
            queue.append((mapPos: node.mapPos + Vec2(direction), cubeRotation: node.cubeRotation * direction.rotation, origin: direction))
          }
        }
      }
    }

    var cubeMap: [Vec2: Mat3] = [:]
    constructCubeMap(mapPos: rows[0].enumerated().first { $0.element != .border }.map { Vec2(x: $0.offset, y: 0) / cubeSize }!, cubeMap: &cubeMap)
    self.cubeMap = cubeMap
  }

  convenience init(rawFields: [[Character]], cubeSize: Int) {
    self.init(rows: rawFields.map { $0.map { Field(rawValue: $0)! } }, cubeSize: cubeSize)
  }

  convenience init(rawString: String, cubeSize: Int) {
    self.init(rawFields: rawString.split(separator: "\n").map(Array.init), cubeSize: cubeSize)
  }
}

protocol WrapperProtocol {
  init(fields: Fields, position: Vec2, facing: Direction)

  func wrap(current: Vec2, next: inout Vec2, facing: inout Direction)
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
    if wrapperType == Part2Wrapper.self {
      print(self)
      print()
    }
    switch instruction {
    case .tiles(let tiles):
      let wrapper = Wrapper(fields: fields, position: position, facing: facing)
      loop:
      for _ in 0..<tiles {
        var next = position + Vec2(facing)
        wrapper.wrap(current: position, next: &next, facing: &facing)
        let row = fields.rows[next.y]
        switch row[min(row.count - 1, next.x)] {
          case .space: position = next
          case .solid: break loop
          case .border: fatalError("Cannot move to border position \(next)")
        }
      }
    case .turn(let turn):
      facing = facing + turn
    }
    if wrapperType == Part2Wrapper.self {
      print(self)
      print()
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

  func wrap(current: Vec2, next: inout Vec2, facing: inout Direction) {
    next.x = rowRange.wrap(next.x)
    next.y = colRange.wrap(next.y)
  }
}

struct Part2Wrapper: WrapperProtocol {
  private let fields: Fields
  private let rotation: Mat3

  init(fields: Fields, position: Vec2, facing: Direction) {
    self.fields = fields
    rotation = facing.rotation
  }

  func wrap(current: Vec2, next: inout Vec2, facing: inout Direction) {
    // Check that we are actually out of range
    let rowRange = fields.rows[next.y].boardRange
    let colRange = fields.columns[next.x].boardRange
    guard !rowRange.contains(next.y) || !colRange.contains(next.x) else { return }
    // Compute the cube face and normal we are currently in
    let mapPos = current / fields.cubeSize
    guard let cubeRotation = fields.cubeMap[mapPos] else { fatalError("No cube normal mapped for \(mapPos) (cube map: \(fields.cubeMap))") }
    // Compute the normal of the next face
    let nextUnalignedRotation = cubeRotation * rotation
    let cubeNormal = nextUnalignedRotation.e0
    assert(cubeNormal != .zero)
    // Look up the rotation/orientation of the next face in the cube map
    guard let (nextMapPos, nextCubeRotation) = fields.cubeMap.first(where: { $0.value.e0 == cubeNormal }) else { fatalError("No aligned rotation for cube normal \(cubeNormal) (cube map: \(fields.cubeMap))") }
    // Compute the (wrapped) position within our current cube face
    var baseIntraPos = next - (mapPos * fields.cubeSize)
    baseIntraPos.x = baseIntraPos.x %% fields.cubeSize
    baseIntraPos.y = baseIntraPos.y %% fields.cubeSize
    // Compute the position within the next cube face by performing a centered rotation
    let intraRotation: Mat3 = nextCubeRotation.transpose * nextUnalignedRotation
    let centerOffset = Vec2(x: fields.cubeSize - 1, y: fields.cubeSize - 1)
    let nextIntraPos = (Vec2(fromYz: intraRotation * Vec3(yz: baseIntraPos * 2 - centerOffset)) + centerOffset) / 2
    assert(nextIntraPos.x >= 0 && nextIntraPos.y >= 0)
    next = (nextMapPos * fields.cubeSize) + nextIntraPos
    let rawDir = Vec2(fromYz: intraRotation * Vec3(yz: Vec2(facing)))
    guard let nextFacing = Direction(rawDir) else { fatalError("Could not compute next facing") }
    facing = nextFacing
  }
}

extension Board {
  init(fields: Fields) {
    self.fields = fields
    position = Vec2(x: fields.rows[0].firstIndex { $0 != .border }!, y: 0)
  }
}

let url = URL(fileURLWithPath: "Resources/demo.txt")
let input = String(data: try Data(contentsOf: url), encoding: .utf8)!
let rawParts = input.split(separator: "\n\n")

let cubeSize = 4
let board = Board(fields: Fields(rawString: String(rawParts[0]), cubeSize: cubeSize))
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

