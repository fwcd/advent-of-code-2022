package dev.fwcd.aoc2022.day12;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.PriorityQueue;
import java.util.Set;
import java.util.stream.IntStream;
import java.util.stream.Stream;

public class App {
    private static record Pos(int x, int y) {
        Stream<Pos> getNeighbors() {
            return Stream.of(
                new Pos(x - 1, y),
                new Pos(x + 1, y),
                new Pos(x, y - 1),
                new Pos(x, y + 1)
            );
        }

        boolean isInBounds(int width, int height) {
            return x >= 0 && x < width && y >= 0 && y < height;
        }
    }

    private static class Node implements Comparable<Node> {
        Pos pos;
        int weight;
        int steps;

        Node(Pos pos, int weight, int steps) {
            this.pos = pos;
            this.weight = weight;
            this.steps = steps;
        }

        @Override
        public int compareTo(Node o) { return Integer.compare(weight, o.weight); }
    }

    private static int height(List<String> map, Pos pos) {
        char c = map.get(pos.y).charAt(pos.x);
        if (c == 'S') {
            c = 'a';
        } else if (c == 'E') {
            c = 'z';
        }
        return c - 'a';
    }

    private static Pos locate(List<String> map, char c) {
        return IntStream.range(0, map.size())
            .boxed()
            .flatMap(y -> IntStream.range(0, map.get(y).length())
                .mapToObj(x -> new Pos(x, y)))
            .filter(p -> map.get(p.y).charAt(p.x) == c)
            .findAny()
            .orElseThrow();
    }

    private static int dijkstra(List<String> map, Pos start, Pos end) {
        Set<Pos> visited = new HashSet<>();
        PriorityQueue<Node> pq = new PriorityQueue<>();
        pq.add(new Node(start, 0, 0));

        while (!pq.isEmpty()) {
            Node node = pq.remove();
            visited.add(node.pos);
            if (node.pos.equals(end)) {
                return node.steps;
            }
            node.pos.getNeighbors()
                .filter(p -> !visited.contains(p) && p.isInBounds(map.get(0).length(), map.size()))
                .map(p -> new Node(p, node.weight + height(map, p) - height(map, node.pos), node.steps + 1))
                .filter(n -> (n.weight - node.weight) <= 1)
                .forEach(pq::add);
        }

        throw new RuntimeException("No end found");
    }

    public static void main(String[] args) throws IOException {
        List<String> map = new ArrayList<>();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(App.class.getResourceAsStream("/input.txt")))) {
            String line;
            while ((line = reader.readLine()) != null) {
                map.add(line);
            }
        }

        Pos start = locate(map, 'S');
        Pos end = locate(map, 'E');
        int part1 = dijkstra(map, start, end);

        System.out.println("Part 1: " + part1);
    }
}
