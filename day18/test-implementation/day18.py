#!/usr/bin/env python3

# A Python implementation to debug and verify.

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

def area(points: set[Point]) -> int:
    sides = {point: 6 for point in points}

    for point in points:
        for neighbor in point.neighbors:
            if neighbor in sides:
                sides[neighbor] -= 1
                assert sides[neighbor] >= 0

    return sum(sides.values())

def dfs_exterior_area(points: set[Point]) -> int:
    raw_points = [point.values for point in points]
    min_corner = Point(np.min(raw_points, axis=0) - np.array([1, 1, 1]))
    max_corner = Point(np.max(raw_points, axis=0) + np.array([1, 1, 1]))

    exterior_sides = 0

    point = min_corner
    remaining = [min_corner]
    visited = set()

    while remaining:
        point = remaining.pop()
        if (point.values >= min_corner.values).all() and (point.values <= max_corner.values).all():
            if point in points:
                exterior_sides += 1
            elif point not in visited:
                visited.add(point)
                for neighbor in point.neighbors:
                    remaining.append(neighbor)
    
    return exterior_sides

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

    points = {Point(np.array([int(c) for c in line.strip().split(',')])) for line in lines if line.strip()}

    print(f'Part 1: {area(points)}')
    print(f'Part 2: {dfs_exterior_area(points)}')
    
    export_stl('points', points)

if __name__ == '__main__':
    main()
