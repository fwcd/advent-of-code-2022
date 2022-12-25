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
  }
  return chamber.Height;
}

Console.WriteLine($"Part 1: {Solve(2022)}");

public record struct Pos(int x, int y)
{
  public static Pos operator+(Pos lhs, Pos rhs) => new Pos(lhs.x + rhs.x, lhs.y + rhs.y);

  public static Pos operator-(Pos lhs, Pos rhs) => new Pos(lhs.x - rhs.x, lhs.y - rhs.y);
}

public record struct Brick(List<Pos> positions);

public record struct FallingBrick(Brick brick, Pos offset);

public class Chamber
{
  private HashSet<Pos> placed = new HashSet<Pos>();
  private Nullable<FallingBrick> falling = null;
  private int width;

  public int Height
  {
    get
    {
      int min = placed.Select(p => p.y).Min();
      int max = placed.Select(p => p.y).Max();
      return max - min;
    }
  }

  public Chamber(int width)
  {
    this.width = width;
  }

  public void Drop(Brick brick)
  {
    Spawn(brick);
    FallToGround();
  }

  private void Spawn(Brick brick)
  {
    falling = new FallingBrick(brick, new Pos(2, 0));
  }

  private void FallToGround()
  {
    // TODO
  }
}
