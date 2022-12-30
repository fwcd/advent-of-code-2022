use std::{fs, collections::HashMap, str::FromStr, ops::{AddAssign, Index, IndexMut, Sub, Add}, fmt, iter, array};

use clap::Parser;
use once_cell::sync::Lazy;
use quick_cache::sync::Cache;
use rayon::prelude::*;
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

#[derive(Debug, Default, Clone, Copy)]
struct Robot {
    material: Option<Material>,
    costs: Materials<usize>,
}

#[derive(Debug, Clone)]
struct Blueprint {
    robots: Materials<Robot>,
    max_costs: Materials<usize>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct State {
    robots: Materials<usize>,
    materials: Materials<usize>,
    remaining_minutes: usize,
    elapsed_minutes: usize,
    last_robot: Option<Material>,
    last_materials: Materials<usize>,
}

type Memo = Cache<State, usize>;

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

impl fmt::Display for Materials<usize> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        for _ in 0..self.ore { write!(f, "O")?; }
        for _ in 0..self.clay { write!(f, "C")?; }
        for _ in 0..self.obsidian { write!(f, "B")?; }
        for _ in 0..self.geode { write!(f, "G")?; }
        Ok(())
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

impl Materials<usize> {
    fn can_spend(self, deltas: Self) -> bool {
        self.zip(deltas, |c, d| c >= d).all()
    }
}

impl<T> Add for Materials<T> where T: Add {
    type Output = Materials<T::Output>;

    fn add(self, rhs: Self) -> Self::Output {
        self.zip(rhs, Add::add)
    }
}

impl<T> Sub for Materials<T> where T: Sub {
    type Output = Materials<T::Output>;

    fn sub(self, rhs: Self) -> Self::Output {
        self.zip(rhs, Sub::sub)
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

impl<T> IntoIterator for Materials<T> {
    type IntoIter = array::IntoIter<T, 4>;
    type Item = T;

    fn into_iter(self) -> Self::IntoIter {
        [self.ore, self.clay, self.obsidian, self.geode].into_iter()
    }
}

impl<T> From<HashMap<Material, T>> for Materials<T> where T: Clone + Default {
    fn from(map: HashMap<Material, T>) -> Self {
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
        let material = Some(captures.name("name").unwrap().as_str().parse()?);
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
            .map(|r: Robot| (r.material.unwrap(), r))
            .collect::<HashMap<Material, Robot>>()
            .into();
        Ok(Blueprint::new(robots))
    }
}

impl State {
    fn new(remaining_minutes: usize) -> Self {
        Self {
            robots: Materials { ore: 1, ..Default::default() },
            materials: Materials::default(),
            remaining_minutes,
            elapsed_minutes: 0,
            last_robot: Some(Material::Ore),
            last_materials: Materials::default(),
        }
    }

    // TODO: Fixed size instead of `Vec`s?

    fn step(&mut self) {
        self.materials += self.robots;
        self.remaining_minutes -= 1;
        self.elapsed_minutes += 1;
    }

    fn spend(&mut self, deltas: Materials<usize>) {
        self.materials = self.materials.zip(deltas, |c, d| c - d);
    }

    fn next(&self, robot: Option<&Robot>) -> Option<Self> {
        let mut next = *self;
        if let Some(robot) = robot {
            if !self.materials.can_spend(robot.costs) {
                return None;
            }
            next.spend(robot.costs);
        }
        next.step();
        next.last_robot = robot.and_then(|r| r.material);
        next.last_materials = self.materials;
        if let Some(robot) = robot {
            let material = robot.material.unwrap();
            next.robots[material] += 1;
        }
        Some(next)
    }

    fn should_build(&self, robot: &Robot, blueprint: &Blueprint) -> bool {
        // Skip building the robot if we already produce enough of this resource per minute
        let material = robot.material.unwrap();
        if material != Material::Geode && self.robots[material] > blueprint.max_costs[material] {
            return false;
        }

        // Skip building the robot if we decided to skip the last round despite being able to afford it
        if self.last_robot.is_none() && self.last_materials.can_spend(robot.costs) {
            return false;
        }

        true
    }

    fn childs<'a>(&'a self, blueprint: &'a Blueprint) -> impl Iterator<Item = Self> + 'a {
        iter::once(self.next(None))
            .chain(blueprint.robots.into_iter()
                .filter(|r| self.should_build(r, blueprint))
                .map(|r| self.next(Some(&r))))
            .flatten()
    }

    fn upper_bound_for_geodes(&self) -> usize {
        // There is a minimum number of minutes until (even without considering the
        // material costs) we could possibly have a geode robot. This value is
        // determined by our maximum 'robot level'.

        let minutes_to_geode_robot = if self.robots.geode > 0 {
            0
        } else if self.robots.obsidian > 0 {
            1
        } else if self.robots.clay > 0 {
            2
        } else {
            3
        };

        // Assuming we build a geode robot at every minute, we can use the Gauss formula
        // to get a (very rough) upper bound for the total number of geodes we can harvest
        // by computing
        //
        //     robot_count + (robot_count + 1) + ... + (robot_count + geode_minutes)
        //

        let geode_minutes = self.remaining_minutes - minutes_to_geode_robot;
        let robot_count = self.robots.geode;
        let harvested = (robot_count * (robot_count + 1) + (geode_minutes * (geode_minutes + 1))) / 2;

        self.materials.geode + harvested
    }

    fn dfs_geodes(&self, blueprint: &Blueprint, memo: &Memo) -> usize {
        if self.elapsed_minutes < 6 {
            println!("{}. (robots: {}, materials: {})", iter::repeat(' ').take(self.elapsed_minutes).into_iter().collect::<String>(), self.robots, self.materials);
        }
        if let Some(geodes) = memo.get(self) {
            geodes
        } else {
            let geodes = if self.remaining_minutes == 0 {
                self.materials.geode
            } else {
                let mut max_geodes: usize = 0;
                for child in self.childs(blueprint) {
                    if child.upper_bound_for_geodes() > max_geodes {
                        max_geodes = max_geodes.max(child.dfs_geodes(blueprint, memo));
                    }
                }
                max_geodes
            };
            memo.insert(*self, geodes);
            geodes
        }
    }
}

impl Blueprint {
    fn new(robots: Materials<Robot>) -> Self {
        let max_costs = robots.into_iter()
            .map(|r| r.costs)
            .reduce(|c1, c2| c1.zip(c2, Ord::max))
            .unwrap_or_default();

        Self { robots, max_costs }
    }

    fn max_geodes(&self, remaining_minutes: usize, cache_size: usize) -> usize {
        let mut memo = Cache::new(cache_size);
        State::new(remaining_minutes).dfs_geodes(self, &mut memo)
    }
}

#[derive(Parser)]
struct Args {
    /// The path to the input file.
    #[arg(short, long, default_value = "resources/demo.txt")]
    input: String,

    /// Only runs the first blueprint of part 1 (for debugging).
    #[arg(long, default_value_t = false)]
    smoke: bool,

    /// The number of minutes to search deep for part 1.
    #[arg(short, long, default_value_t = 24)]
    part1_minutes: usize,

    /// The maximum number of blueprints to use (from the beginning) for part 1.
    #[arg(short, long, default_value_t = usize::MAX)]
    part1_blueprints: usize,

    /// The number of minutes to search deep for part 2.
    #[arg(short, long, default_value_t = 32)]
    part2_minutes: usize,

    /// The maximum number of blueprints to use (from the beginning) for part 2.
    #[arg(short, long, default_value_t = usize::MAX)]
    part2_blueprints: usize,

    /// The number of cache entries per thread.
    #[arg(short, long, default_value_t = 60_000_000)]
    cache_size: usize,

    /// Whether to skip part 1.
    #[arg(long, default_value_t = false)]
    skip_part1: bool,

    /// Whether to skip part 2.
    #[arg(long, default_value_t = false)]
    skip_part2: bool,
}

fn main() {
    let args = Args::parse();

    let blueprints = fs::read_to_string(args.input).unwrap()
        .split('\n')
        .filter(|l| !l.is_empty())
        .filter_map(|l| l.parse().ok())
        .collect::<Vec<Blueprint>>();
    
    if !args.skip_part1 {
        let part1 = blueprints.par_iter().enumerate()
            .take(if args.smoke { 1 } else { args.part1_blueprints })
            .map(|(i, b)| (i + 1) * b.max_geodes(args.part1_minutes, args.cache_size))
            .sum::<usize>();

        println!("Part 1: {}", part1);
    }

    if !args.skip_part2 && !args.smoke {
        let part2 = blueprints.par_iter()
            .take(args.part2_blueprints)
            .map(|b| b.max_geodes(args.part2_minutes, args.cache_size))
            .product::<usize>();

        println!("Part 2: {}", part2);
    }
}
