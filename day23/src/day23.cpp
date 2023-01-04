#include <iostream>
#include <fstream>
#include <string>
#include <vector>

std::vector<std::string> readInput() {
  std::ifstream stream;
  stream.open("resources/demo.txt");
  std::vector<std::string> lines;
  std::string line;
  while (stream.good()) {
    stream >> line;
    lines.push_back(line);
  }
  return lines;
}

int main() {
  const std::vector<std::string> input {readInput()};
  for (const std::string &line : input) {
    std::cout << line << std::endl;
  }
  return 0;
}
