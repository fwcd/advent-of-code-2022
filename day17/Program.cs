List<Brick> bricks = new List<Brick>
{
  new Brick(new List<Pos>
  {
    new Pos(0, 0), new Pos(1, 0), new Pos(2, 0), new Pos(3, 0),
  }),
  new Brick(new List<Pos>
  {
                    new Pos(1, -2),
    new Pos(0, -1), new Pos(1, -1), new Pos(2, -1),
                    new Pos(1,  0),
  }),
  new Brick(new List<Pos>
  {
                                  new Pos(2, -2),
                                  new Pos(2, -1),
    new Pos(0, 0), new Pos(1, 0), new Pos(2,  0),
  }),
  new Brick(new List<Pos>
  {
    new Pos(0, -3),
    new Pos(0, -2),
    new Pos(0, -1),
    new Pos(0,  0),
  }),
  new Brick(new List<Pos>
  {
    new Pos(0, -1), new Pos(1, -1),
    new Pos(0,  0), new Pos(1,  0),
  }),
};

long Solve(long count, string jetPattern)
{
  var width = 7;
  var chamber = new Chamber(width);
  var lastHeight = 0;
  var jetStream = jetPattern.Select((jet, i) => (jet, i)).Cycle().GetEnumerator();
  var diffs = new List<int>();

  // By manual inspection, we know that the diffs are eventually periodic, at least
  // by the 1000st diff. Therefore we set the minimum period length to 1000.
  var minPeriodLength = 1000;
  var tortoise = minPeriodLength;
  var hare = minPeriodLength;

  for (long i = 0; i < count; i++)
  {
    var brickIndex = (int) (i % bricks.Count);
    chamber.Drop(bricks[brickIndex], jetStream);

    var diff = chamber.Height - lastHeight;
    diffs.Add(diff);

    // Start Floyd's tortoise and hare to find period (cycle)
    if (diffs.Count > 2 * minPeriodLength)
    {
      hare++;
      if (i % 2 == 0)
      {
        tortoise++;
        if (hare - tortoise > 0 && diffs.GetRange(tortoise, minPeriodLength).SequenceEqual(diffs.GetRange(hare, minPeriodLength)))
        {
          // Found period, now we can compute the rest
          var periodLength = hare - tortoise;
          var period = diffs.GetRange(tortoise, periodLength);
          var remaining = count - tortoise;
          var remainingPeriods = remaining / periodLength;
          var remainingRounds = (int) (remaining % periodLength);

          Console.WriteLine($"Found period between {tortoise} and {hare} (length: {periodLength}, remainingPeriods: {remainingPeriods}, remainingRounds: {remainingRounds}):");
          Console.WriteLine(string.Concat(period));

          return ((long) diffs.GetRange(0, tortoise).Sum())
            + remainingPeriods * ((long) period.Sum())
            + ((long) period.GetRange(0, remainingRounds).Sum());
        }
      }
    }

    lastHeight = chamber.Height;
  }
  return chamber.Height;
}

string jetPattern = File.ReadAllText("resources/input.txt").Trim();
Console.WriteLine($"Part 1: {Solve(2022, jetPattern)}");
Console.WriteLine($"Part 2: {Solve(1000000000000, jetPattern)}");

public static class Extensions
{
  public static IEnumerable<T> Cycle<T>(this IEnumerable<T> enumerable)
  {
    List<T> list = enumerable.ToList();
    for (int i = 0;; i++)
    {
      yield return list[i % list.Count];
    }
  }
}

public record struct Pos(int X, int Y)
{
  public static Pos operator+(Pos lhs, Pos rhs) => new Pos(lhs.X + rhs.X, lhs.Y + rhs.Y);

  public static Pos operator-(Pos lhs, Pos rhs) => new Pos(lhs.X - rhs.X, lhs.Y - rhs.Y);
}

public record struct Brick(List<Pos> Positions);

public record struct FallingBrick(Brick Brick, Pos Offset)
{
  public IEnumerable<Pos> Positions
  {
    get
    {
      Pos Offset = this.Offset;
      return Brick.Positions.Select(p => p + Offset);
    }
  }

  public FallingBrick Next() => new FallingBrick(Brick, Offset + new Pos(0, 1));

  public FallingBrick Shift(char jet) => new FallingBrick(Brick, Offset + new Pos(jet switch
  {
    '>' => 1,
    '<' => -1,
    _   => throw new ArgumentException($"Invalid jet: {jet}"),
  }, 0));
}

public class Chamber
{
  private HashSet<Pos> placedPositions = new HashSet<Pos>();
  private Nullable<FallingBrick> falling = null;

  public IEnumerable<Pos> Positions =>
    placedPositions.Concat(falling?.Positions ?? Enumerable.Empty<Pos>());

  private int minY => Positions.Select(p => p.Y).DefaultIfEmpty().Min();
  private int maxY => Positions.Select(p => p.Y).DefaultIfEmpty().Max();

  public readonly int Width;
  public int Height => maxY - minY + 1;

  public Chamber(int width)
  {
    Width = width;
  }

  public void Drop(Brick brick, IEnumerator<(char jet, int i)> jetStream)
  {
    Spawn(brick);
    FallToGround(jetStream);
    Place();
  }

  private void Spawn(Brick brick)
  {
    falling = new FallingBrick(brick, new Pos(2, minY - 4));
  }

  private void FallToGround(IEnumerator<(char jet, int i)> jetStream)
  {
    if (this.falling is FallingBrick falling)
    {
      FallingBrick last = falling;
      do
      {
        jetStream.MoveNext();
        FallingBrick shifted = falling.Shift(jetStream.Current.jet);
        last = IntersectsWalls(shifted) || IntersectsGround(shifted) ? falling : shifted;
        falling = last.Next();
      } while (!IntersectsGround(falling));
      this.falling = last;
    }
  }

  private void Place()
  {
    if (falling != null)
    {
      placedPositions.UnionWith(falling.Value.Positions);
    }
    falling = null;
  }

  private bool IntersectsWalls(FallingBrick falling) =>
    falling.Positions.Any(p => p.X < 0 || p.X >= Width);

  private bool IntersectsGround(FallingBrick falling) =>
    falling.Offset.Y >= 0 || falling.Positions.Any(placedPositions.Contains);

  public override string ToString()
  {
    HashSet<Pos> fallingPositions = falling?.Positions.ToHashSet() ?? new HashSet<Pos>();
    return "Chamber:\n" + string.Join('\n', Enumerable.Range(0, Height)
      .Select(dy => minY + dy)
      .Select(y => Enumerable.Range(0, Width)
        .Select(x => new Pos(x, y))
        .Select(p => fallingPositions.Contains(p)
          ? '@'
          : placedPositions.Contains(p) ? '#' : '.'))
      .Select(cs => string.Concat(cs)));
  }
}
