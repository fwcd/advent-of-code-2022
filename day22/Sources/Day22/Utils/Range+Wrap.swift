extension Range where Bound == Int {
  func wrap(_ value: Int) -> Int {
    ((value - lowerBound) %% count) + lowerBound
  }
}
