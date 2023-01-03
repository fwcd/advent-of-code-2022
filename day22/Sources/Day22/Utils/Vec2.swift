struct Vec2: Hashable, CustomStringConvertible {
  var x: Int = 0
  var y: Int = 0

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
