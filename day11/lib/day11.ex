defmodule Day11 do
  def parse_op("new = " <> raw_expr) do
    [raw_lhs, raw_op, raw_rhs] = raw_expr |> String.split(" ")
    fn old, new ->
      resolve = fn raw ->
        case raw do
          "old" -> old
          "new" -> new
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
          "Starting items: " <> raw_items       -> acc |> Map.put(:items, raw_items |> String.split(", ") |> Enum.map(&String.to_integer/1))
          "Operation: " <> raw_rule             -> acc |> Map.put(:op, raw_rule |> parse_op)
          "Test: divisible by " <> raw_n        -> acc |> Map.put(:test_divisor, raw_n |> String.to_integer)
          "If true: throw to monkey " <> raw_n  -> acc |> Map.put(:if_true, raw_n |> String.to_integer)
          "If false: throw to monkey " <> raw_n -> acc |> Map.put(:if_false, raw_n |> String.to_integer)
          _                                     -> acc
        end
      end)
  end

  def step(monkey, monkeys) do
    monkeys
  end

  def simulate_round(monkeys) do
    monkeys |> List.foldl(monkeys, &step/2)
  end

  def simulate(monkeys, rounds, inspects \\ nil) do
    if rounds > 0 do
      inspects = Enum.zip(monkeys, inspects || List.duplicate(0, length(monkeys)))
        |> Enum.map(fn {monkey, n} -> n + length(monkey[:items]) end)
      simulate_round(monkeys) |> simulate(rounds - 1, inspects)
    else
      inspects
    end
  end

  def main do
    monkeys = File.read!("resources/demo.txt")
      |> String.split("\n\n")
      |> Enum.map(&parse_monkey/1)
    
    inspects = monkeys
      |> simulate(20)
      |> Enum.sort(&(&1 >= &2))

    part1 = (inspects |> Enum.at 0) * (inspects |> Enum.at 1)
    IO.puts "Part 1: #{part1}"
  end
end
