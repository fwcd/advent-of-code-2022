defmodule Day11 do
  def parse_op("new = " <> raw_expr) do
    [raw_lhs, raw_op, raw_rhs] = raw_expr |> String.split(" ")
    fn old ->
      resolve = fn raw ->
        case raw do
          "old" -> old
          lit   -> String.to_integer(lit)
        end
      end
      op = case raw_op do
        "*" -> &*/2
        "+" -> &+/2
      end
      op.(resolve.(raw_lhs), resolve.(raw_rhs))
    end
  end

  def parse_monkey(raw) do
    raw
      |> String.split("\n")
      |> Enum.reduce(%{}, fn line, acc ->
        case String.trim(line) do
          "Starting items: " <> raw_items       -> acc |> Map.put(:items, raw_items |> String.split(", ") |> Enum.map(&String.to_integer/1) |> Enum.reverse)
          "Operation: " <> raw_rule             -> acc |> Map.put(:op, raw_rule |> parse_op)
          "Test: divisible by " <> raw_n        -> acc |> Map.put(:test_divisor, raw_n |> String.to_integer)
          "If true: throw to monkey " <> raw_n  -> acc |> Map.put(:if_true, raw_n |> String.to_integer)
          "If false: throw to monkey " <> raw_n -> acc |> Map.put(:if_false, raw_n |> String.to_integer)
          _                                     -> acc
        end
      end)
  end

  def step(i, state) do
    monkey = state[:monkeys] |> Enum.at(i)
    monkey[:items]
      |> Enum.reverse
      |> List.foldl(state, fn item, state ->
        new = monkey[:op].(item) |> div(state[:worry_divisor]) |> rem(state[:worry_mod])
        j = if rem(new, monkey[:test_divisor]) == 0 do monkey[:if_true] else monkey[:if_false] end
        state
          |> Map.update!(:monkeys, fn monkeys ->
            monkeys
              |> List.update_at(j, fn other ->
                other |> Map.update!(:items, &([new | &1]))
              end)
          end)
      end)
      |> Map.update!(:inspects, fn inspects -> inspects |> List.update_at(i, &(&1 + length(monkey[:items]))) end)
      |> Map.update!(:monkeys, &(List.replace_at(&1, i, Map.put(monkey, :items, []))))
  end

  def simulate_round(state) do
    (0..(length(state[:monkeys]) - 1))
      |> Enum.to_list
      |> List.foldl(state, &step/2)
  end

  def simulate(state, rounds) do
    if rounds > 0 do
      state
        |> simulate_round
        |> simulate(rounds - 1)
    else
      state
    end
  end

  def solve(monkeys, worry_divisor, rounds) do
    state = %{
      monkeys: monkeys,
      inspects: List.duplicate(0, length(monkeys)),
      worry_divisor: worry_divisor,
      # The trick to part 2 is that divisibility by any of the test_divisors
      # is unaffected by taking the worry levels mod the product of all test_divisors.
      worry_mod: monkeys |> Enum.map(&(&1[:test_divisor])) |> Enum.product
    }

    inspects = state
      |> simulate(rounds)
      |> Map.get(:inspects)
      |> Enum.sort(&(&1 >= &2))

    Enum.at(inspects, 0) * Enum.at(inspects, 1)
  end

  def main do
    monkeys = File.read!("resources/input.txt")
      |> String.split("\n\n")
      |> Enum.map(&parse_monkey/1)

    part1 = monkeys |> solve(3, 20)
    IO.puts "Part 1: #{part1}"

    part2 = monkeys |> solve(1, 10000)
    IO.puts "Part 2: #{part2}"
  end
end
