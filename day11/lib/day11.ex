defmodule Day11 do
  def parse_monkey(raw) do
    raw
      |> String.split("\n")
      |> Enum.reduce(%{}, fn line, acc ->
        case String.trim(line) do
          "Starting items: " <> items       -> acc |> Map.put(:items, items |> String.split(", ") |> Enum.map(&String.to_integer/1))
          "Operation: " <> op               -> acc |> Map.put(:op, op)
          "Test: divisible by " <> n        -> acc |> Map.put(:test_divisor, String.to_integer(n))
          "If true: throw to monkey " <> n  -> acc |> Map.put(:if_true, String.to_integer(n))
          "If false: throw to monkey " <> n -> acc |> Map.put(:if_false, String.to_integer(n))
          _                                 -> acc
        end
      end)
  end

  def step(monkey, monkeys) do
    monkeys
    # TODO
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

    part1 = Enum.at(inspects, 0) * Enum.at(inspects, 1)
    IO.puts "Part 1: #{part1}"
  end
end
