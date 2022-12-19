#!/usr/bin/env python3

from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import numpy as np

ROOT_PATH = Path(__file__).parent
RESOURCES_DIR = ROOT_PATH / 'resources'
POINTCLOUDS_DIR = ROOT_PATH / 'pointclouds'

AXES = 3

@dataclass
class Point:
    values: np.ndarray

    @property
    def neighbors(self) -> Iterable[Point]:
        for d in [-1, 1]:
            for axis in range(len(self.values)):
                neighbor = self.values.copy()
                neighbor[axis] += d
                yield Point(neighbor)

    def __eq__(self, other):
        return (self.values == other.values).all()

    def __hash__(self):
        return hash(self.values.data.tobytes())
    
    def __str__(self):
        return ' '.join(map(str, self.values))

def surface_area(points: list[Point]) -> int:
    sides = {point: 6 for point in points}

    for point in points:
        for neighbor in point.neighbors:
            if neighbor in sides:
                sides[neighbor] -= 1
                assert sides[neighbor] >= 0

    return sum(sides.values())

def fill(boundary: list[Point]) -> list[Point]:
    avg = Point(np.average([point.values for point in boundary]))
    return boundary # TODO

def to_ply_pointcloud(points: list[Point]) -> str:
    return '\n'.join([
        'ply',
        'format ascii 1.0',
        f'element vertex {len(points)}',
        'property float x',
        'property float y',
        'property float z',
        'end_header',
        *[str(point) for point in points],
        '',
    ])

def main():
    with open(RESOURCES_DIR / 'input.txt', 'r') as f:
        lines = f.readlines()

    boundary = [Point(np.array([int(c) for c in line.strip().split(',')])) for line in lines if line.strip()]
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
