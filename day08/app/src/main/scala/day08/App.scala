package day08

import scala.io.Source

object App {
  type Pos = (Int, Int)
  type Grid = List[List[Int]]

  def filterVisible[A](initialTag: A, initialHeight: Int, seq: Iterable[(A, Int)]): Iterable[A] = seq
    .scanLeft((initialTag, initialHeight)) { (acc, elem) => if (elem._2 > acc._2) { elem } else { acc } }
    .filter { acc => acc._2 > initialHeight }
    .toList
    .distinctBy { acc => acc._2 }
    .map { acc => acc._1 }

  def rows(grid: Grid): Iterable[Iterable[(Pos, Int)]] = grid
    .zipWithIndex
    .map { row => row._1.zipWithIndex.map { cell => ((row._2, cell._2), cell._1) } }

  def cols(grid: Grid): Iterable[Iterable[(Pos, Int)]] = rows(grid.transpose)
    .map { col => col.map { v => (v._1.swap, v._2) } }

  def visibleFromOutside(grid: Grid): Set[Pos] =
    (rows(grid).concat(cols(grid)))
      .flatMap { v => List(v, v.toList.reverse) }
      .flatMap { v => filterVisible((-1, -1), -1, v) }
      .toSet

  def positions(grid: Grid): Iterable[Pos] =
    (0 until grid.length)
      .flatMap { i => (0 until grid(0).length).map { j => (i, j) } }

  def viewDists(grid: Grid, pos: Pos) = {
    val height = grid(pos._1)(pos._2)
    List((grid, pos), (grid.transpose, pos.swap))
      .flatMap { v => List(
        v._1(v._2._1).take(v._2._2).reverse,
        v._1(v._2._1).reverse.take(v._1(0).length - 1 - v._2._2).reverse
      ) }
      .map { v => (v, v.takeWhile { x => x < height }.toList) }
      .map { v => v._2.length + (if (v._1.length != v._2.length) { 1 } else { 0 }) }
  }

  def maxScenicScore(grid: Grid): Int =
    positions(grid)
      .map { p => viewDists(grid, p).product }
      .max

  def main(args: Array[String]): Unit = {
    val grid = Source.fromResource("input.txt").getLines()
      .map { s => s.map { c => c.asDigit }.toList }
      .toList

    val part1 = visibleFromOutside(grid).size
    println(s"Part 1: $part1")

    val part2 = maxScenicScore(grid)
    println(s"Part 2: $part2")
  }
}
