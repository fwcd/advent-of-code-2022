package day08

import scala.io.Source

object App {
  def main(args: Array[String]): Unit = {
    val lines = Source.fromResource("demo.txt").getLines().toList
    println(lines)
  }
}
