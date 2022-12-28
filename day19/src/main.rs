use std::{fs, collections::HashMap, str::FromStr, iter};

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

#[derive(Debug, Clone)]
struct State {
    robots: HashMap<String, usize>,
    materials: HashMap<String, usize>,
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

    fn geodes(&self) -> usize {
        *self.materials.get("geode").unwrap_or(&0)
    }

    // TODO: Fixed size instead of `Vec`s?

    fn step(&mut self) {
        for (material, count) in self.robots.iter() {
            let current = *self.materials.get(material).unwrap_or(&0);
            self.materials.insert(material.clone(), current + count);
        }
    }

    fn spend(&mut self, deltas: &HashMap<String, usize>) {
        for (material, delta) in deltas.iter() {
            let current = *self.materials.get(material).unwrap_or(&0);
            self.materials.insert(material.clone(), current - delta);
        }
    }

    fn next(&self, robot: Option<&Robot>) -> Self {
        let mut next = self.clone();
        if let Some(robot) = robot {
            next.spend(&robot.costs);
        }
        next.step();
        if let Some(robot) = robot {
            let current = *next.robots.get(&robot.name).unwrap_or(&0);
            next.robots.insert(robot.name.clone(), current + 1);
        }
        next
    }

    fn childs<'a>(&'a self, blueprint: &'a Blueprint) -> impl Iterator<Item = Self> + 'a {
        iter::once(self.next(None)).chain(
            blueprint.robots.iter()
                .map(|r| self.next(Some(r)))
        )
    }

    fn dfs_geodes(&self, blueprint: &Blueprint, remaining_minutes: usize) -> usize {
        if remaining_minutes == 0 {
            self.geodes()
        } else {
            self.childs(blueprint)
                .map(|c| c.dfs_geodes(blueprint, remaining_minutes - 1))
                .max()
                .unwrap_or(0)
        }
    }
}

impl Blueprint {
    fn quality_level(&self, remaining_minutes: usize) -> usize {
        State::new().dfs_geodes(self, remaining_minutes)
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
