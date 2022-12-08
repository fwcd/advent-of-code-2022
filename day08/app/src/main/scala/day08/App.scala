package day08

import scala.io.Source

object App {
  type Pos = (Int, Int)

  def filterVisible(seq: Iterable[(Pos, Int)]): Iterable[Pos] = seq
    .scanLeft(((-1, -1), -1)) { (acc, elem) => if (elem._2 > acc._2) { elem } else { acc } }
    .filter { acc => acc._2 >= 0 }
    .toList
    .distinct
    .map { acc => acc._1 }

  def rows(grid: List[List[Int]]): Iterable[Iterable[(Pos, Int)]] = grid
    .zipWithIndex
    .map { row => row._1.zipWithIndex.map { cell => ((row._2, cell._2), cell._1) } }

  def cols(grid: List[List[Int]]): Iterable[Iterable[(Pos, Int)]] = rows(grid.transpose)
    .map { col => col.map { v => (v._1.swap, v._2) } }

  def totalVisible(grid: List[List[Int]]): Set[Pos] =
    (rows(grid).concat(cols(grid)))
      .flatMap { v => List(v, v.toList.reverse) }
      .flatMap { v => filterVisible(v) }
      .toSet

  def main(args: Array[String]): Unit = {
    val grid = Source.fromResource("input.txt").getLines()
      .map { s => s.map { c => c.toInt }.toList }
      .toList

    val visible = totalVisible(grid)
    val part1 = visible.size

    println(s"Part 1: $part1")
  }
}
