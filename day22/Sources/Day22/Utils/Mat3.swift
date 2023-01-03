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
