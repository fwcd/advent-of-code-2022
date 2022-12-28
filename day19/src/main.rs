use std::{fs, collections::{HashMap, BTreeMap}, str::FromStr, iter};

use once_cell::sync::Lazy;
use regex::Regex;

// TODO: Use (fixed size) structs (e.g. `Materials`) instead of `HashMap`s?

#[derive(Debug, Clone)]
struct Robot {
    name: String,
    costs: HashMap<String, usize>,
}

#[derive(Debug, Clone)]
struct Blueprint {
    robots: Vec<Robot>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct State {
    robots: BTreeMap<String, usize>,
    materials: BTreeMap<String, usize>,
}

impl FromStr for Robot {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        const PATTERN: Lazy<Regex> = Lazy::new(|| Regex::new(r"Each (?P<name>\w+) robot costs (?P<raw_costs>.+)").unwrap());
        const COST_PATTERN: Lazy<Regex> = Lazy::new(|| Regex::new(r"(\d+) (\w+)").unwrap());

        let captures = PATTERN.captures(s).ok_or_else(|| format!("Could not parse '{}'", s))?;
        let name = captures.name("name").unwrap().as_str().to_owned();
        let raw_costs = captures.name("raw_costs").unwrap();
        let costs = COST_PATTERN.captures_iter(raw_costs.as_str())
            .map(|c| (c[2].to_owned(), c[1].parse().unwrap()))
            .collect::<HashMap<String, usize>>();

        Ok(Robot { name, costs })
    }
}

impl FromStr for Blueprint {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let robots = s.split(":")
            .last().unwrap()
            .split(".")
            .filter_map(|r| r.parse().ok())
            .collect::<Vec<_>>();
        Ok(Blueprint { robots })
    }
}

impl State {
    fn new() -> Self {
        Self {
            robots: [("ore".to_owned(), 1)].into(),
            materials: [].into(),
        }
    }

    fn count(&self, material: &str) -> usize {
        *self.materials.get(material).unwrap_or(&0)
    }

    fn geodes(&self) -> usize {
        self.count("geode")
    }

    // TODO: Fixed size instead of `Vec`s?

    fn step(&mut self) {
        for (material, count) in self.robots.iter() {
            self.materials.insert(material.clone(), self.count(material) + count);
        }
    }

    fn can_spend(&self, deltas: &HashMap<String, usize>) -> bool {
        deltas.iter().all(|(m, &d)| self.count(m) >= d)
    }

    fn spend(&mut self, deltas: &HashMap<String, usize>) {
        for (material, delta) in deltas.iter() {
            self.materials.insert(material.clone(), self.count(material) - delta);
        }
    }

    fn next(&self, robot: Option<&Robot>) -> Option<Self> {
        let mut next = self.clone();
        if let Some(robot) = robot {
            if !self.can_spend(&robot.costs) {
                return None;
            }
            next.spend(&robot.costs);
        }
        next.step();
        if let Some(robot) = robot {
            let current = *next.robots.get(&robot.name).unwrap_or(&0);
            next.robots.insert(robot.name.clone(), current + 1);
        }
        Some(next)
    }

    fn childs<'a>(&'a self, blueprint: &'a Blueprint) -> impl Iterator<Item = Self> + 'a {
        iter::once(self.next(None))
            .chain(blueprint.robots.iter().map(|r| self.next(Some(r))))
            .flatten()
    }

    fn dfs_geodes(&self, blueprint: &Blueprint, memo: &mut HashMap<(usize, State), usize>, elapsed_minutes: usize, remaining_minutes: usize) -> usize {
        let memo_key = (remaining_minutes, self.clone());
        if let Some(&geodes) = memo.get(&memo_key) {
            geodes
        } else {
            let geodes = if remaining_minutes == 0 {
                self.geodes()
            } else {
                self.childs(blueprint)
                    .map(|c| {
                        if remaining_minutes > 15 {
                            println!("{}. (searching {:?})", iter::repeat(' ').take(elapsed_minutes).into_iter().collect::<String>(), self);
                        }
                        c
                    })
                    .map(|c| c.dfs_geodes(blueprint, memo, elapsed_minutes + 1, remaining_minutes - 1))
                    .max()
                    .unwrap_or(0)
            };
            memo.insert(memo_key, geodes);
            geodes
        }
    }
}

impl Blueprint {
    fn quality_level(&self, remaining_minutes: usize) -> usize {
        let mut memo = HashMap::new();
        State::new().dfs_geodes(self, &mut memo, 0, remaining_minutes)
    }
}

fn main() {
    let blueprints = fs::read_to_string("resources/demo.txt").unwrap()
        .split('\n')
        .filter(|l| !l.is_empty())
        .filter_map(|l| l.parse().ok())
        .collect::<Vec<Blueprint>>();
    
    let part1 = blueprints.iter().enumerate()
        .map(|(i, b)| (i + 1) * b.quality_level(24))
        .sum::<usize>();

    println!("Part 1: {}", part1);
}
