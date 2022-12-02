class Day02 : GLib.Object {
  enum Move {
    ROCK = 0,
    PAPER = 1,
    SCISSORS = 2;

    /**
     * The outcome against the other move.
     * (0 -> loss, 1 -> draw, 2 -> win)
     */
    public int against(Move other) {
      // Observe: We win iff we are 'one step ahead'
      // of them (mod 3). We thus only need to compute
      // the difference/distance and add 1 to get it
      // into the [0, 2] range.
      return ((this - other) + 4) % 3;
    }

    /** The move that produces the given outcome. */
    public Move produce(int outcome) {
      // Again, we view (outcome - 1) as a kind of difference (mod 3)
      // and add it to us to get the desired outcome.
      return (this + outcome + 2) % 3;
    }

    /** The score against the given move. */
    public int score_against(Move other) {
      return 3 * against(other) + this + 1;
    }

    /** Parses a move from the given character. */
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
      int part2 = 0;

      while ((line = dis.read_line()) != null) {
        Move theirs = Move.parse(line[0]);
        Move ours = Move.parse(line[2]);

        part1 += ours.score_against(theirs);
        // We use another trick here: Since moves (rock, paper, scissors)
        // are isomorphic to outcomes (lose, draw, win), we just pretend
        // that ours (despite being parsed as a move) is an outcome.
        part2 += theirs.produce(ours).score_against(theirs);
      }

      print("Part 1: %d\n", part1);
      print("Part 2: %d\n", part2);
    } catch (Error e) {
      print("Error: %s\n", e.message);
    }
    return 0;
  }
}
