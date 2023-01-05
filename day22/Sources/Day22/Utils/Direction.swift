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

  var rotation: Mat3 {
    switch self {
    case .right: return .rotZ
    case .down: return .rotY.transpose
    case .left: return .rotZ.transpose
    case .up: return .rotY
    }
  }

  init?(_ vec2: Vec2) {
    guard let direction = Self.allCases.first(where: { Vec2($0) == vec2 }) else {
      return nil
    }
    self = direction
  }

  static func +(lhs: Self, rhs: Self) -> Self {
    Self(rawValue: (lhs.rawValue + rhs.rawValue + 1) % Self.allCases.count)!
  }
}
