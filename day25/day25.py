#!/usr/bin/env python3

def parse_snafu_digit(raw: str):
    return {'=': -2, '-': -1}.get(raw) or int(raw)

def parse_snafu(raw: str):
    result = 0
    factor = 1
    for raw_digit in reversed(raw):
        result += parse_snafu_digit(raw_digit) * factor
        factor *= 5
    return result

with open('resources/demo.txt', 'r') as f:
    lines = [l.strip() for l in f.readlines() if l.strip()]

part1 = sum(parse_snafu(raw) for raw in lines)
print(f'Part 1 (decimal): {part1}')
