#include <array>
#include <initializer_list>
#include <iostream>
#include <fstream>
#include <string>
#include <utility>
#include <optional>
#include <vector>

/** A 2D integer vector. */
struct Direction {
  int dx;
  int dy;

  constexpr Direction(int dx, int dy) : dx(dx), dy(dy) {}

  /** A direction orthogonal to this one. */
  constexpr Direction orthogonal() const {
    return {-dy, dx};
  }

  /** The opposite-facing direction. */
  constexpr Direction operator-() const {
    return {-dx, -dy};
  }
};

constexpr Direction SOUTH {0, 1};
constexpr Direction EAST {1, 0};
constexpr Direction NORTH {-SOUTH};
constexpr Direction WEST {-EAST};

/** The four cardinal directions. */
constexpr std::array<Direction, 4> CARDINALS {NORTH, SOUTH, WEST, EAST};

/** A position on a board. */
struct Position {
  int x;
  int y;

  constexpr Position(int x, int y) : x(x), y(y) {}

  /** The position after adding the given direction. */
  constexpr Position operator+(Direction dir) const {
    return {x + dir.dx, y + dir.dy};
  }

  /** The position after subtracting the given direction. */
  constexpr Position operator-(Direction dir) const {
    return {x - dir.dx, y - dir.dy};
  }

  /** Fetches the three neighbors in the given cardinal direction. */
  std::array<Position, 3> neighbors(Direction cardinal) const {
    const Direction ortho {cardinal.orthogonal()};
    const Position next {*this + cardinal};
    return {next - ortho, next, next + ortho};
  }
};

/** The state of a (dynamically sized) board. */
template <typename T>
class Board {
public:
  Board(int width, int height, T initialValue) : _width(width), _height(height) {
    fields.reserve(width * height);
    for (int i = 0; i < width * height; i++) {
      fields.push_back(initialValue);
    }
  }

  /** The next direction to move in for the given field. */
  std::optional<Direction> directionToMove(Position pos) const {
    for (const Direction cardinal : CARDINALS) {
      for (const Position neighbor : pos.neighbors(cardinal)) {
        if ((*this)[neighbor]) {
          return cardinal;
        }
      }
    }
    return std::nullopt;
  }

  /** Computes the state of the board after a single round. */
  Board<bool> next() const {
    Board<bool> result {width(), height(), false};
    Board<int> dibs {width(), height(), 0};

    for (int y {0}; y < height(); y++) {
      for (int x {0}; x < width(); x++) {
        const Position pos {x, y};
        if ((*this)[pos]) {
          const std::optional<Direction> dir {directionToMove(pos)};
          if (dir.has_value()) {
            dibs[pos + *dir] += 1;
          }
        }
      }
    }

    for (int y {0}; y < height(); y++) {
      for (int x {0}; x < width(); x++) {
        const Position pos {x, y};
        result[pos] = dibs[pos] == 1;
      }
    }

    return result;
  }

  /** Computes the state of the board after the given number of rounds. */
  Board after(int rounds) const {
    Board result {*this};
    for (int i {0}; i < rounds; i++) {
      result = result.next();
    }
    return result;
  }

  /** Returns a const bit reference to the field at the given position. */
  typename std::vector<T>::const_reference operator[](Position pos) const {
    return fields[index(pos)];
  }

  /** Returns a bit reference to the field at the given position. */
  typename std::vector<T>::reference operator[](Position pos) {
    return fields[index(pos)];
  }

  /** The number of columns on the board. */
  constexpr int width() const {
    return _width;
  }

  /** The number of rows on the board. */
  constexpr int height() const {
    return _height;
  }
private:
  int _width;
  int _height;
  std::vector<T> fields;

  /** Finds the index of the given position in the internal bit vector. */
  constexpr int index(Position pos) const {
    return pos.y * width() + pos.x;
  }
};

/** Outputs a prettyprinted representation of the board to the given output stream. */
std::ostream &operator<<(std::ostream &os, const Board<bool> &board) {
  for (int y {0}; y < board.height(); y++) {
    for (int x {0}; x < board.width(); x++) {
      os << (board[{x, y}] ? '#' : '.');
    }
    os << std::endl;
  }
  return os;
}

/** Reads the lines from the given input file. */
std::vector<std::string> readInput(const std::string &filePath = "resources/demo.txt") {
  std::ifstream stream;
  stream.open(filePath);
  std::vector<std::string> lines;
  std::string line;
  while (stream.good()) {
    stream >> line;
    lines.push_back(line);
  }
  return lines;
}

/** Parses a board from the given lines. */
Board<bool> parseBoard(const std::vector<std::string> &lines) {
  int width = lines[0].size();
  int height = lines.size();
  Board<bool> board {width, height, false};
  for (int y {0}; y < height; y++) {
    for (int x {0}; x < width; x++) {
      board[{x, y}] = lines[y][x] == '#';
    }
  }
  return board;
}

int main() {
  const std::vector<std::string> lines {readInput()};
  Board<bool> board {parseBoard(lines)};
  std::cout << board.after(10);
  return 0;
}
