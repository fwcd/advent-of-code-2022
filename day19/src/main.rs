use std::{fs, collections::HashMap, str::FromStr, iter, ops::{AddAssign, Index, IndexMut}};

use once_cell::sync::Lazy;
use regex::Regex;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum Material {
    Ore, Clay, Obsidian, Geode
}

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, Hash)]
struct Materials<T> {
    ore: T,
    clay: T,
    obsidian: T,
    geode: T,
}

#[derive(Debug, Clone)]
struct Robot {
    material: Material,
    costs: Materials<usize>,
}

#[derive(Debug, Clone)]
struct Blueprint {
    robots: Vec<Robot>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct State {
    robots: Materials<usize>,
    materials: Materials<usize>,
}

impl FromStr for Material {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "ore" => Ok(Self::Ore),
            "clay" => Ok(Self::Clay),
            "obsidian" => Ok(Self::Obsidian),
            "geode" => Ok(Self::Geode),
            _ => Err(format!("Could not parse material '{}'", s)),
        }
    }
}

impl<T> Index<Material> for Materials<T> {
    type Output = T;

    fn index(&self, index: Material) -> &Self::Output {
        match index {
            Material::Ore => &self.ore,
            Material::Clay => &self.clay,
            Material::Obsidian => &self.obsidian,
            Material::Geode => &self.geode,
        }
    }
}

impl<T> IndexMut<Material> for Materials<T> {
    fn index_mut(&mut self, index: Material) -> &mut Self::Output {
        match index {
            Material::Ore => &mut self.ore,
            Material::Clay => &mut self.clay,
            Material::Obsidian => &mut self.obsidian,
            Material::Geode => &mut self.geode,
        }
    }
}

impl<T> Materials<T> {
    fn map<U>(self, f: impl Fn(T) -> U) -> Materials<U> {
        Materials {
            ore: f(self.ore),
            clay: f(self.clay),
            obsidian: f(self.obsidian),
            geode: f(self.geode),
        }
    }

    fn zip<U, V>(self, rhs: Materials<U>, f: impl Fn(T, U) -> V) -> Materials<V> {
        Materials {
            ore: f(self.ore, rhs.ore),
            clay: f(self.clay, rhs.clay),
            obsidian: f(self.obsidian, rhs.obsidian),
            geode: f(self.geode, rhs.geode),
        }
    }
}

impl Materials<bool> {
    fn all(self) -> bool {
        self.ore && self.clay && self.obsidian && self.geode
    }
}

impl<T> AddAssign for Materials<T> where T: AddAssign {
    fn add_assign(&mut self, rhs: Self) {
        self.ore += rhs.ore;
        self.clay += rhs.clay;
        self.obsidian += rhs.obsidian;
        self.geode += rhs.geode;
    }
}

impl From<HashMap<Material, usize>> for Materials<usize> {
    fn from(map: HashMap<Material, usize>) -> Self {
        Self {
            ore: map.get(&Material::Ore).cloned().unwrap_or_default(),
            clay: map.get(&Material::Clay).cloned().unwrap_or_default(),
            obsidian: map.get(&Material::Obsidian).cloned().unwrap_or_default(),
            geode: map.get(&Material::Geode).cloned().unwrap_or_default(),
        }
    }
}

impl FromStr for Robot {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        const PATTERN: Lazy<Regex> = Lazy::new(|| Regex::new(r"Each (?P<name>\w+) robot costs (?P<raw_costs>.+)").unwrap());
        const COST_PATTERN: Lazy<Regex> = Lazy::new(|| Regex::new(r"(\d+) (\w+)").unwrap());

        let captures = PATTERN.captures(s).ok_or_else(|| format!("Could not parse '{}'", s))?;
        let material = captures.name("name").unwrap().as_str().parse()?;
        let raw_costs = captures.name("raw_costs").unwrap();
        let costs = COST_PATTERN.captures_iter(raw_costs.as_str())
            .map(|c| Ok((c[2].parse()?, c[1].parse().unwrap())))
            .collect::<Result<HashMap<Material, usize>, String>>()?
            .into();

        Ok(Robot { material, costs })
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
            robots: Materials { ore: 1, ..Default::default() },
            materials: Materials::default(),
        }
    }

    // TODO: Fixed size instead of `Vec`s?

    fn step(&mut self) {
        self.materials += self.robots;
    }

    fn can_spend(&self, deltas: Materials<usize>) -> bool {
        self.materials.zip(deltas, |c, d| c >= d).all()
    }

    fn spend(&mut self, deltas: Materials<usize>) {
        self.materials = self.materials.zip(deltas, |c, d| c - d);
    }

    fn next(&self, robot: Option<&Robot>) -> Option<Self> {
        let mut next = self.clone();
        if let Some(robot) = robot {
            if !self.can_spend(robot.costs) {
                return None;
            }
            next.spend(robot.costs);
        }
        next.step();
        if let Some(robot) = robot {
            next.robots[robot.material] += 1;
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
                self.materials.geode
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
