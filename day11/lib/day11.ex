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

  def main do
    monkeys = File.read!("resources/demo.txt")
      |> String.split("\n\n")
      |> Enum.map(&parse_monkey/1)
    monkeys
      |> Enum.map(&IO.inspect/1)
  end
end
