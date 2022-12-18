#!/usr/bin/env python3

from pathlib import Path

ROOT_PATH = Path(__file__).parent
RESOURCES_DIR = ROOT_PATH / 'resources'
POINTCLOUDS_DIR = ROOT_PATH / 'pointclouds'

def surface_area(poss: list[list[int]]) -> int:
    sides = {str(pos): 6 for pos in poss}

    for pos in poss:
        for d in [-1, 1]:
            for axis, _ in enumerate(pos):
                neighbor = list(pos)
                neighbor[axis] += d
                if str(neighbor) in sides:
                    sides[str(pos)] -= 1
                    assert sides[str(pos)] >= 0

    return sum(sides.values())

def ranges_along(axis: int, boundary: list[list[int]]) -> dict[str, tuple[int, int]]:
    ranges = {}
    others = {}

    for pos in boundary:
        rest = pos[:axis] + pos[axis + 1:]
        key = str(rest)
        current = pos[axis]
        other = others.get(key, None)
        if other is None:
            others[key] = current
        else:
            ranges[key] = (min(current, other), max(current, other))

    return ranges

def interiors_along(axis: int, boundary: list[list[int]]) -> set[str]:
    ranges = ranges_along(axis, boundary)
    boundary_set = {str(pos) for pos in boundary}
    interiors = set()

    for key, (min_v, max_v) in ranges.items():
        rest = eval(key)
        assert str(rest[:axis] + [min_v] + rest[axis:]) in boundary_set
        assert str(rest[:axis] + [max_v] + rest[axis:]) in boundary_set
        for v in range(min_v + 1, max_v):
            pos = rest[:axis] + [v] + rest[axis:]
            if str(pos) not in boundary_set:
                interiors.add(str(pos))

    return interiors

def fill(boundary: list[list[int]]) -> list[list[int]]:
    interior = interiors_along(0, boundary)

    for axis in [1, 2]:
        interior = interior.intersection(interiors_along(axis, boundary))

    boundary_set = {str(pos) for pos in boundary}
    return [eval(str_pos) for str_pos in boundary_set.union(interior)]

def to_ply_pointcloud(poss: list[list[int]]) -> str:
    return '\n'.join([
        'ply',
        'format ascii 1.0',
        f'element vertex {len(poss)}',
        'property float x',
        'property float y',
        'property float z',
        'end_header',
        *[f' '.join(map(str, pos)) for pos in poss],
        '',
    ])

def main():
    with open(RESOURCES_DIR / 'input.txt', 'r') as f:
        lines = f.readlines()

    boundary = [[int(c) for c in line.strip().split(',')] for line in lines if line.strip()]
    filled = fill(boundary)

    print(f'{len(boundary)} vs {len(filled)}')

    print(f'Part 1: {surface_area(boundary)}')
    print(f'Part 2: {surface_area(filled)}')

    POINTCLOUDS_DIR.mkdir(exist_ok=True)

    with open(POINTCLOUDS_DIR / 'boundary.ply', 'w') as f:
        f.write(to_ply_pointcloud(boundary))

    with open(POINTCLOUDS_DIR / 'filled.ply', 'w') as f:
        f.write(to_ply_pointcloud(filled))

if __name__ == '__main__':
    main()
