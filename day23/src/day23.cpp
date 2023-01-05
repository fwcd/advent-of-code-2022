#include <array>
#include <algorithm>
#include <cassert>
#include <initializer_list>
#include <iostream>
#include <fstream>
#include <stdexcept>
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

/** Outputs a prettyprinted representation of the direction to the given output stream. */
std::ostream &operator<<(std::ostream &os, const Direction dir) {
  os << '{' << dir.dx << ", " << dir.dy << '}';
  return os;
}

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

  /** The position after adding the given position. */
  constexpr Position operator+(Position rhs) const {
    return {x + rhs.x, y + rhs.y};
  }

  /** The position after subtracting the given position. */
  constexpr Position operator-(Position rhs) const {
    return {x - rhs.x, y - rhs.y};
  }

  /** The elementwise minimum of this and the given position. */
  constexpr Position min(Position rhs) const {
    return {std::min(x, rhs.x), std::min(y, rhs.y)};
  }

  /** The elementwise maximum of this and the given position. */
  constexpr Position max(Position rhs) const {
    return {std::max(x, rhs.x), std::max(y, rhs.y)};
  }

  /** Fetches the three neighbors in the given cardinal direction. */
  std::array<Position, 3> neighbors(Direction cardinal) const {
    const Direction ortho {cardinal.orthogonal()};
    const Position next {*this + cardinal};
    return {next - ortho, next, next + ortho};
  }
};

/** Outputs a prettyprinted representation of the position to the given output stream. */
std::ostream &operator<<(std::ostream &os, const Position board) {
  os << '{' << board.x << ", " << board.y << '}';
  return os;
}

/** A 2D map of fields. */
template <typename T>
class Fields {
public:
  Fields(int width, int height, T initialValue) : _width(width), _height(height) {
    fields.reserve(width * height);
    for (int i = 0; i < width * height; i++) {
      fields.push_back(initialValue);
    }
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
    assert(inBounds(pos));
    return pos.y * width() + pos.x;
  }

  /** Whether the given position is within the board's bounds. */
  constexpr bool inBounds(Position pos) const {
    return pos.x >= 0 && pos.x < width() && pos.y >= 0 && pos.y < height();
  }
};

/** Outputs a prettyprinted representation of the field map to the given output stream. */
template <typename T>
std::ostream &operator<<(std::ostream &os, const Fields<T> &fields) {
  for (int y {0}; y < fields.height(); y++) {
    for (int x {0}; x < fields.width(); x++) {
      os << fields[{x, y}];
    }
    os << std::endl;
  }
  return os;
}

/** The game state, i.e. a 2D map of elves. */
class Board {
public:
  Board(Fields<bool> fields) : fields(fields) {}

  /** Computes the state of the board after a single round. */
  Board next() const {
    Board result {{width(), height(), false}};
    Fields<std::vector<Position>> dibs {width(), height(), {}};

    result.cardinalOffset = (result.cardinalOffset + 1) % CARDINALS.size();

    for (int y {0}; y < height(); y++) {
      for (int x {0}; x < width(); x++) {
        const Position pos {x, y};
        if ((*this)[pos]) {
          if (isIsolated(pos)) {
            result[pos] = true;
          } else {
            const std::optional<Direction> dir {directionToMove(pos)};
            if (dir.has_value()) {
              dibs[pos + *dir].push_back(pos);
            } else {
              result[pos] = true;
            }
          }
        }
      }
    }

    for (int y {0}; y < height(); y++) {
      for (int x {0}; x < width(); x++) {
        const Position pos {x, y};
        if (dibs[pos].size() == 1) {
          result[pos] = true;
        } else {
          for (const Position original : dibs[pos]) {
            result[original] = true;
          }
        }
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

  /** Finds the top-left corner of the box bounding the occupied fields. */
  Position topLeft() const {
    Position result {width() - 1, height() - 1};
    for (int y {0}; y < height(); y++) {
      for (int x {0}; x < width(); x++) {
        const Position pos {x, y};
        if ((*this)[pos]) {
          result = pos.min(result);
        }
      }
    }
    return result;
  }

  /** Finds the bottom-right corner of the box bounding the occupied fields. */
  Position bottomRight() const {
    Position result {0, 0};
    for (int y {0}; y < height(); y++) {
      for (int x {0}; x < width(); x++) {
        const Position pos {x, y};
        if ((*this)[pos]) {
          result = pos.max(result);
        }
      }
    }
    return result;
  }

  /** Counts the number of empty tiles within the bounding box of occupied fields. */
  int emptyGroundTilesInBoundingBox() {
    const Position tl {topLeft()};
    const Position br {bottomRight()};
    int count {0};
    for (int y {tl.y}; y <= br.y; y++) {
      for (int x {tl.x}; x <= br.x; x++) {
        const Position pos {x, y};
        if (!(*this)[pos]) {
          count++;
        }
      }
    }
    return count;
  }

  /** Returns a const bit reference to the field at the given position. */
  std::vector<bool>::const_reference operator[](Position pos) const {
    return fields[pos];
  }

  /** Returns a bit reference to the field at the given position. */
  std::vector<bool>::reference operator[](Position pos) {
    return fields[pos];
  }

  /** The number of columns on the board. */
  constexpr int width() const {
    return fields.width();
  }

  /** The number of rows on the board. */
  constexpr int height() const {
    return fields.height();
  }
private:
  Fields<bool> fields;
  int cardinalOffset;

  /** Whether the given field can propose moving into the given cardinal direction. */
  bool canProposeDirection(Position pos, Direction cardinal) const {
    for (const Position neighbor : pos.neighbors(cardinal)) {
      if ((*this)[neighbor]) {
        return false;
      }
    }
    return true;
  }

  /** Whether the given field is not surrounded by any occupied fields. */
  bool isIsolated(Position pos) const {
    for (int i {0}; i < CARDINALS.size(); i++) {
      const Direction cardinal {CARDINALS[(i + cardinalOffset) % CARDINALS.size()]};
      if (!canProposeDirection(pos, cardinal)) {
        return false;
      }
    }
    return true;
  }

  /** The next direction to move in for the given field. */
  std::optional<Direction> directionToMove(Position pos) const {
    for (int i {0}; i < CARDINALS.size(); i++) {
      const Direction cardinal {CARDINALS[(i + cardinalOffset) % CARDINALS.size()]};
      if (canProposeDirection(pos, cardinal)) {
        return cardinal;
      }
    }
    return std::nullopt;
  }
};

/** Outputs a prettyprinted representation of the board to the given output stream. */
std::ostream &operator<<(std::ostream &os, const Board &board) {
  for (int y {0}; y < board.height(); y++) {
    for (int x {0}; x < board.width(); x++) {
      os << (board[{x, y}] ? '#' : '.');
    }
    os << std::endl;
  }
  return os;
}

/** Reads the lines from the given input file. */
std::vector<std::string> readInput(const std::string &filePath = "resources/input.txt") {
  std::ifstream stream;
  stream.open(filePath);
  if (!stream.is_open()) {
    throw new std::runtime_error("Could not open input file!");
  }
  std::vector<std::string> lines;
  std::string line;
  while (std::getline(stream, line)) {
    if (!line.empty()) {
      lines.push_back(line);
    }
  }
  return lines;
}

/** Parses a board from the given lines. */
Board parseBoard(const std::vector<std::string> &lines, int padding = 0) {
  int width {static_cast<int>(lines[0].size())};
  int height {static_cast<int>(lines.size())};
  Board board {{width + 2 * padding, height + 2 * padding, false}};

  for (int y {0}; y < height; y++) {
    for (int x {0}; x < width; x++) {
      board[{x + padding, y + padding}] = lines[y][x] == '#';
    }
  }

  return board;
}

int main() {
  const std::vector<std::string> lines {readInput()};
  int padding {10};
  Board board {parseBoard(lines, padding)};

  std::cout << "Part 1: " << board.after(10).emptyGroundTilesInBoundingBox() << std::endl;

  return 0;
}
