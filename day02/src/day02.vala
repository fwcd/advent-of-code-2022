class Day02 : GLib.Object {
  enum Move {
    ROCK = 0,
    PAPER = 1,
    SCISSORS = 2;

    public int against(Move other) {
      int base_score = ((this - other) + 4) % 3;
      return base_score * 3;
    }

    public int score_against(Move other) {
      return against(other) + this + 1;
    }

    public static Move parse(char raw) {
      switch (raw) {
      case 'A': case 'X': return ROCK;
      case 'B': case 'Y': return PAPER;
      case 'C': case 'Z': return SCISSORS;
      }
      print("Cannot parse move from %c\n", raw);
      Process.exit(1);
    }
  }

  public static int main(string[] args) {
    File file = File.new_for_path("resources/input.txt");

    try {
      FileInputStream fis = file.read();
      DataInputStream dis = new DataInputStream(fis);
      string line;
      int part1 = 0;

      while ((line = dis.read_line()) != null) {
        Move theirs = Move.parse(line[0]);
        Move ours = Move.parse(line[2]);
        part1 += ours.score_against(theirs);
      }

      print("Part 1: %d\n", part1);
    } catch (Error e) {
      print("Error: %s\n", e.message);
    }
    return 0;
  }
}
