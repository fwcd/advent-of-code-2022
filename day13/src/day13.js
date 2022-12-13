#!/usr/bin/env node

const fs = require('fs').promises;

function compare(a, b) {
  if (typeof a == 'number' && typeof b == 'number') {
    return a < b ? -1 : a > b ? 1 : 0;
  } else if (typeof a == 'number') {
    return compare([a], b);
  } else if (typeof b == 'number') {
    return compare(a, [b]);
  } else {
    for (let i = 0; i < Math.max(a.length, b.length); i++) {
      if (i >= a.length) {
        return -1;
      } else if (i >= b.length) {
        return 1;
      }
      const cmp = compare(a[i], b[i]);
      if (cmp !== 0) {
        return cmp;
      }
    }
    return 0;
  }
}

function parsePackets(raw) {
  return raw.split('\n')
    .filter(line => line.trim())
    .flatMap(line => line ? [JSON.parse(line)] : []);
}

(async () => {
  const input = await fs.readFile('resources/input.txt', { encoding: 'utf8' });
  const pairs = input.split('\n\n').map(parsePackets);
  
  const part1 = pairs
    .flatMap(([l, r], i) => compare(l, r) <= 0 ? [i + 1] : [])
    .reduce((x, y) => x + y);
  
  console.log(`Part 1: ${part1}`);

  const dividers = [[[2]], [[6]]];
  const all = parsePackets(input);
  const sorted = [...all, ...dividers].sort(compare);
  const part2 = dividers
    .map(d => sorted.map(JSON.stringify).indexOf(JSON.stringify(d)) + 1)
    .reduce((x, y) => x * y);

  console.log(`Part 2: ${part2}`);
})();
