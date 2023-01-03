import Foundation
import Collections

enum Field: Character, Hashable {
  case border = " "
  case solid = "#"
  case space = "."
}

enum Instruction: Hashable {
  case tiles(Int)
  case turn(Direction)
}

fileprivate extension Array where Element == Field {
  var boardRange: Range<Int> {
    let start = drop { $0 == .border }
    let end = start.drop { $0 != .border }
    return start.startIndex..<end.startIndex
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

    // Idea: Map net positions aka. cube faces (on a grid where each cell has the size of the cube's
    //       side length) to rotations of the cube. These rotations are represented as orthogonal 3x3 matrices
    //       where the first base vector is the normal of the mapped face and the other two base vectors
    //       represent the face's orientation. Since all matrices are orthogonal, we can easily invert them
    //       by transposing them (we'll use that quite a bit in the wrapper implementation).

    /// Perform a BFS over the cube net to find the rotations.
    func constructCubeMap(mapPos: Vec2, cubeRotation: Mat3 = .identity, cubeMap: inout [Vec2: Mat3]) {
      var queue: Deque<(mapPos: Vec2, cubeRotation: Mat3, origin: Direction?)> = [(mapPos: mapPos, cubeRotation: cubeRotation, origin: nil)]
      while let node = queue.popFirst() {
        let position = node.mapPos * cubeSize
        guard position.y >= 0 && position.y < rows.count,
              position.x >= 0 && position.x < rows[position.y].count,
              rows[position.y][position.x] != .border else { continue }
        if !cubeMap.keys.contains(node.mapPos) {
          // Assert that no normal is mapped twice
          assert(!cubeMap.values.contains { $0.e0 == node.cubeRotation.e0 })
          cubeMap[node.mapPos] = node.cubeRotation
          for direction in Direction.allCases {
            queue.append((mapPos: node.mapPos + Vec2(direction), cubeRotation: node.cubeRotation * direction.rotation, origin: direction))
          }
        }
      }
    }

    var cubeMap: [Vec2: Mat3] = [:]
    constructCubeMap(mapPos: rows[0].enumerated().first { $0.element != .border }.map { Vec2(x: $0.offset, y: 0) / cubeSize }!, cubeMap: &cubeMap)
    assert(cubeMap.count == 6, "Not the entire cube was mapped (only \(cubeMap.count) faces)")
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
  init(fields: Fields)

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
    switch instruction {
    case .tiles(let tiles):
      let wrapper = Wrapper(fields: fields)
      loop:
      for _ in 0..<tiles {
        var next = position + Vec2(facing)
        var nextFacing = facing
        wrapper.wrap(current: position, next: &next, facing: &nextFacing)
        let row = fields.rows[next.y]
        switch row[min(row.count - 1, next.x)] {
          case .space: (position, facing) = (next, nextFacing)
          case .solid: break loop
          case .border: fatalError("Cannot move to border position \(next)")
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
  let fields: Fields

  func wrap(current: Vec2, next: inout Vec2, facing: inout Direction) {
    let rowRange = fields.rows[current.y].boardRange
    let colRange = fields.columns[current.x].boardRange
    next.x = rowRange.wrap(next.x)
    next.y = colRange.wrap(next.y)
  }
}

struct Part2Wrapper: WrapperProtocol {
  let fields: Fields

  func wrap(current: Vec2, next: inout Vec2, facing: inout Direction) {
    // Check that we are actually out of range
    if next.y >= 0 && next.y < fields.rows.count && next.x >= 0 && next.x < fields.columns.count {
      let rowRange = fields.rows[next.y].boardRange
      let colRange = fields.columns[next.x].boardRange
      guard !colRange.contains(next.y) || !rowRange.contains(next.x) else { return }
    }
    // Compute the cube face and normal we are currently in
    let mapPos = current / fields.cubeSize
    guard let cubeRotation = fields.cubeMap[mapPos] else { fatalError("No cube normal mapped for \(mapPos) (cube map: \(fields.cubeMap))") }
    // Compute the normal of the next face
    let nextUnalignedRotation = cubeRotation * facing.rotation
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

let url = URL(fileURLWithPath: "Resources/input.txt")
let cubeSize = 50

let input = String(data: try Data(contentsOf: url), encoding: .utf8)!
let rawParts = input.split(separator: "\n\n")

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
