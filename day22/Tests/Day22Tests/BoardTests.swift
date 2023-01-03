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

    func assertThat<Wrapper: WrapperProtocol>(_ type: Wrapper.Type, wraps current: Vec2, facing: Direction, to next: Vec2, facing nextFacing: Direction, line: UInt = #line) {
      let wrapper = Wrapper(fields: fields, position: current, facing: facing)
      var actualFacing = facing
      var actual = current + Vec2(facing)
      wrapper.wrap(current: current, next: &actual, facing: &actualFacing)
      XCTAssertEqual(actual, next, line: line)
      XCTAssertEqual(actualFacing, nextFacing, line: line)
    }

    assertThat(Part2Wrapper.self, wraps: Vec2(x: 11, y: 5), facing: .right, to: Vec2(x: 14, y: 8), facing: .down)
    assertThat(Part2Wrapper.self, wraps: Vec2(x: 14, y: 8), facing: .up, to: Vec2(x: 11, y: 5), facing: .left)
    assertThat(Part2Wrapper.self, wraps: Vec2(x: 1, y: 7), facing: .down, to: Vec2(x: 10, y: 11), facing: .up)
  }
}
