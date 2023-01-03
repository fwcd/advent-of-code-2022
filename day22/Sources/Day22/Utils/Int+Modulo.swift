infix operator %%

extension Int {
  static func %%(lhs: Self, rhs: Self) -> Self {
    ((lhs % rhs) + rhs) % rhs
  }
}
