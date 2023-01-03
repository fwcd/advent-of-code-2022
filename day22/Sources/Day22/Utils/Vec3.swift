struct Vec3: Hashable, CustomStringConvertible {
  var x: Int = 0
  var y: Int = 0
  var z: Int = 0

  var description: String { "(\(x), \(y), \(z))" }

  static var zero = Self()

  init(yz vec2: Vec2) {
    self.init(y: vec2.x, z: vec2.y)
  }

  func dot(_ rhs: Self) -> Int {
    x * rhs.x + y * rhs.y + z * rhs.z
  }
}
