#!/usr/bin/env python3

def parse_snafu_digit(raw: str) -> int:
    return {'=': -2, '-': -1}.get(raw) or int(raw)

def parse_snafu(raw: str) -> int:
    result = 0
    factor = 1
    for raw_digit in reversed(raw):
        result += parse_snafu_digit(raw_digit) * factor
        factor *= 5
    return result

def snafu(n: int) -> str:
    digits = []
    base = 5
    offset = 2
    while n != 0:
        n += offset
        d = n % base - offset
        digits.append({-2: '=', -1: '-'}.get(d) or str(d))
        n //= base
    return ''.join(reversed(digits))

with open('resources/input.txt', 'r') as f:
    lines = [l.strip() for l in f.readlines() if l.strip()]

part1 = sum(parse_snafu(raw) for raw in lines)
print(f'Part 1 (decimal): {part1}')
print(f'Part 1 (SNAFU): {snafu(part1)}')
