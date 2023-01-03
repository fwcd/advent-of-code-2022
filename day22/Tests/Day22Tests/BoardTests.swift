import XCTest
@testable import Day22

class BoardTests: XCTestCase {
  func testPart2Wrapping() {
    let fields = Fields(rawString: """
              ...#
              .#..
              #...
              ....
      ...#.......#
      ........#...
      ..#....#....
      ..........#.
              ...#....
              .....#..
              .#......
              ......#.
      """, cubeSize: 4)

    XCTAssertEqual(fields.cubeMap, [
      Vec2(x: 2, y: 0): Mat3(e0: Vec3(x: 1, y: 0, z: 0), e1: Vec3(x: 0, y: 1, z: 0), e2: Vec3(x: 0, y: 0, z: 1)), // top
      Vec2(x: 2, y: 1): Mat3(e0: Vec3(x: 0, y: 0, z: 1), e1: Vec3(x: 0, y: 1, z: 0), e2: Vec3(x: -1, y: 0, z: 0)), // front
      Vec2(x: 2, y: 2): Mat3(e0: Vec3(x: -1, y: 0, z: 0), e1: Vec3(x: 0, y: 1, z: 0), e2: Vec3(x: 0, y: 0, z: -1)), // bottom
      Vec2(x: 1, y: 1): Mat3(e0: Vec3(x: 0, y: -1, z: 0), e1: Vec3(x: 0, y: 0, z: 1), e2: Vec3(x: -1, y: 0, z: 0)), // left
      Vec2(x: 3, y: 2): Mat3(e0: Vec3(x: 0, y: 1, z: 0), e1: Vec3(x: 1, y: 0, z: 0), e2: Vec3(x: 0, y: 0, z: -1)), // right
      Vec2(x: 0, y: 1): Mat3(e0: Vec3(x: 0, y: 0, z: -1), e1: Vec3(x: 0, y: -1, z: 0), e2: Vec3(x: -1, y: 0, z: 0)), // back
    ])
  }
}
