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

int Solve(int count, string jetPattern)
{
  var width = 7;
  var heightOffset = 0;
  var chamber = new Chamber(width);
  var jetStream = jetPattern.Select((jet, i) => (jet, i)).Cycle().GetEnumerator();
  var memo = new Dictionary<(int, int), int>();

  jetStream.MoveNext();

  for (int i = 0; i < count; i++)
  {
    var brickIndex = i % bricks.Count;
    var memoKey = (brickIndex, jetStream.Current.i);
    if (memo.ContainsKey(memoKey))
    {
      int memoHeight = memo[memoKey];
      heightOffset += memoHeight;
      chamber = new Chamber(width);
    }
    else
    {
      chamber.Drop(bricks[brickIndex], jetStream);
      memo[memoKey] = chamber.Height;
    }
  }
  return chamber.Height + heightOffset;
}

string jetPattern = File.ReadAllText("resources/input.txt").Trim();
Console.WriteLine($"Part 1: {Solve(2022, jetPattern)}");

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
        FallingBrick shifted = falling.Shift(jetStream.Current.jet);
        jetStream.MoveNext();
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
