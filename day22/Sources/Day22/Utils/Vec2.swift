struct Vec2: Hashable, CustomStringConvertible {
  var x: Int = 0
  var y: Int = 0

  var description: String { "(\(x), \(y))" }

  static var zero = Self()

  func zip(_ rhs: Self, with f: (Int, Int) -> Int) -> Self { return Self(x: f(x, rhs.x), y: f(y, rhs.y)) }

  func map(_ f: (Int) -> Int) -> Self { return Self(x: f(x), y: f(y)) }

  static func +(lhs: Self, rhs: Self) -> Self { lhs.zip(rhs, with: +) }

  static func -(lhs: Self, rhs: Self) -> Self { lhs.zip(rhs, with: -) }

  static func *(lhs: Self, rhs: Int) -> Self { lhs.map { $0 * rhs } }

  static func /(lhs: Self, rhs: Int) -> Self { lhs.map { $0 / rhs } }
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

  init(fromYz vec3: Vec3) {
    self.init(x: vec3.y, y: vec3.z)
  }
}
