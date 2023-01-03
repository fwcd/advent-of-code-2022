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
  }
}
