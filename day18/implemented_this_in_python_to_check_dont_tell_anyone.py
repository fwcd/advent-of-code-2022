#!/usr/bin/env python3

from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import numpy as np

ROOT_PATH = Path(__file__).parent
RESOURCES_DIR = ROOT_PATH / 'resources'
MODELS_DIR = ROOT_PATH / 'models'

@dataclass
class Point:
    values: np.ndarray

    def with_axis(self, axis: int, value: int) -> Point:
        values = self.values.copy()
        values[axis] = value
        return Point(values)

    @property
    def neighbors(self) -> Iterable[Point]:
        for d in [-1, 1]:
            for axis in range(len(self.values)):
                yield self.with_axis(axis, self[axis] + d)

    def __getitem__(self, axis: int):
        return self.values[axis]
    
    def __eq__(self, other):
        return (self.values == other.values).all()

    def __hash__(self):
        return hash(self.values.data.tobytes())
    
    def __str__(self):
        return ' '.join(map(str, self.values))

def surface_area(points: set[Point]) -> int:
    sides = {point: 6 for point in points}

    for point in points:
        for neighbor in point.neighbors:
            if neighbor in sides:
                sides[neighbor] -= 1
                assert sides[neighbor] >= 0

    return sum(sides.values())

def dfs(start: Point, boundary: set[Point]) -> set[Point]:
    point = start
    remaining = [start]
    visited = set()

    while remaining:
        point = remaining.pop()
        for neighbor in point.neighbors:
            if neighbor not in visited and neighbor not in boundary:
                visited.add(neighbor)
                remaining.append(point)
    
    return visited

def fill(boundary: set[Point]) -> set[Point]:
    center = Point(np.average([point.values for point in boundary], axis=0).astype(int))
    interior = dfs(center, boundary)
    print(interior)
    return boundary.union(interior)

def triangle_to_stl(points: list[Point], normal: np.ndarray) -> str:
    return '\n'.join([
        f"facet normal {' '.join(map(str, normal))}",
        'outer loop',
        *[f"vertex {point}" for point in points],
        'endloop',
        'endfacet',
    ])

def quad_to_stl(points: list[Point], normal: np.ndarray) -> str:
    return '\n'.join([
        triangle_to_stl(points[:3], normal),
        triangle_to_stl(points[1:], normal),
    ])

def point_to_face(point: Point, free_axes: list[int]) -> Iterable[Point]:
    if free_axes:
        axis = free_axes[0]
        for d in [0, 1]:
            yield from point_to_face(point.with_axis(axis, point[axis] + d), free_axes[1:])
    else:
        yield point

def point_to_cube_faces(point: Point) -> Iterable[tuple[list[Point], np.ndarray]]:
    axes = list(range(len(point.values)))
    for d in [0, 1]:
        for axis in axes:
            face_point = point.with_axis(axis, point[axis] + d)
            free_axes = axes[:axis] + axes[axis + 1:]
            normal = face_point.values - point.values
            yield (list(point_to_face(face_point, free_axes)), normal)

def point_to_stl_cube(point: Point) -> str:
    size = 1
    return '\n'.join([
        quad_to_stl(face, normal) for face, normal in point_to_cube_faces(point)
    ])

def points_to_stl_cubes(name: str, points: set[Point]) -> str:
    return '\n'.join([
        f'solid {name}',
        *[point_to_stl_cube(point) for point in points],
        f'endsolid {name}',
        '',
    ])

def export_stl(name: str, points: set[Point]):
    MODELS_DIR.mkdir(exist_ok=True)

    with open(MODELS_DIR / f'{name}.stl', 'w') as f:
        f.write(points_to_stl_cubes(name, points))

def main():
    with open(RESOURCES_DIR / 'input.txt', 'r') as f:
        lines = f.readlines()

    boundary = {Point(np.array([int(c) for c in line.strip().split(',')])) for line in lines if line.strip()}
    filled = fill(boundary)

    print(f'{len(boundary)} vs {len(filled)}')
    print(f'Part 1: {surface_area(boundary)}')
    print(f'Part 2: {surface_area(filled)}')
    
    export_stl('boundary', boundary)
    export_stl('filled', filled)

if __name__ == '__main__':
    main()
