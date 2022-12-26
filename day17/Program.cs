List<Brick> bricks = new List<Brick> {
  new Brick(new List<Pos> {
    new Pos(0, 0), new Pos(1, 0), new Pos(2, 0), new Pos(3, 0),
  }),
  new Brick(new List<Pos> {
                   new Pos(1, 0),
    new Pos(0, 1), new Pos(1, 1), new Pos(2, 1),
                   new Pos(1, 2),
  }),
  new Brick(new List<Pos> {
                                  new Pos(2, 0),
                                  new Pos(2, 1),
    new Pos(0, 2), new Pos(1, 2), new Pos(2, 2),
  }),
  new Brick(new List<Pos> {
    new Pos(0, 0),
    new Pos(0, 1),
    new Pos(0, 2),
    new Pos(0, 3),
  }),
  new Brick(new List<Pos> {
    new Pos(0, 0), new Pos(1, 0),
    new Pos(0, 1), new Pos(1, 1),
  }),
};

int Solve(int count)
{
  Chamber chamber = new Chamber(7);
  for (int i = 0; i < count; i++)
  {
    chamber.Drop(bricks[i % bricks.Count]);
    Console.WriteLine($"{chamber}");
  }
  return chamber.Height;
}

Console.WriteLine($"Part 1: {Solve(2022)}");

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

  public FallingBrick Next => new FallingBrick(Brick, Offset + new Pos(0, 1));
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

  public void Drop(Brick brick)
  {
    Spawn(brick);
    FallToGround();
    Place();
  }

  private void Spawn(Brick brick)
  {
    falling = new FallingBrick(brick, new Pos(2, minY - 4));
  }

  private void FallToGround()
  {
    if (falling != null)
    {
      FallingBrick falling = this.falling.Value;
      while (!IntersectsGround(falling.Next))
      {
        falling = falling.Next;
      }
      this.falling = falling;
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

  private bool IntersectsGround(FallingBrick falling) =>
    (!placedPositions.Any() && falling.Offset.Y >= 4)
    || falling.Positions.Any(placedPositions.Contains);

  public override string ToString()
  {
    HashSet<Pos> fallingPositions = falling?.Positions.ToHashSet() ?? new HashSet<Pos>();
    return "Chamber:\n" + string.Join('\n', Enumerable.Range(0, Height)
      .Select(dy => minY + dy)
      .Select(y => Enumerable.Range(0, Width)
        .Select(x => new Pos(x, y))
        .Select(p => fallingPositions.Contains(p)
          ? '@'
          : placedPositions.Contains(p) ? '#' : ' '))
      .Select(cs => string.Concat(cs)));
  }
}
