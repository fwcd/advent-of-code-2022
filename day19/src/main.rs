use std::{fs, collections::HashMap, str::FromStr, ops::{AddAssign, Index, IndexMut, Sub, Add}, fmt, iter, array};

use clap::Parser;
use once_cell::sync::Lazy;
use rayon::prelude::*;
use regex::Regex;

/// A material kind.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum Material {
    Ore, Clay, Obsidian, Geode
}

/// A map of materials to some other type.
/// Since we know all of the materials (i.e. keys), we can use
/// a fixed size struct for efficiency over e.g. a `HashMap<Material, T>`.
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, Hash)]
struct Materials<T> {
    ore: T,
    clay: T,
    obsidian: T,
    geode: T,
}

/// A robot template as part of a blueprint.
#[derive(Debug, Default, Clone, Copy)]
struct Robot {
    /// The material the robot produces.
    material: Option<Material>,
    /// The per-material costs of the robot.
    costs: Materials<usize>,
}

/// Robot templates for every material. Includes a precomputed map of
/// the maximum cost of any robot for every material used for pruning.
#[derive(Debug, Clone)]
struct Blueprint {
    /// The robot templates.
    robots: Materials<Robot>,
    /// The precomputed map of the maximum cost of any robot for the
    /// corresponding material.
    max_costs: Materials<usize>,
}

/// A state at a certain point in time. Searches over the space of `State`s
/// correspond to searches for solutions.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct State {
    /// The robots owned, each actively mining its material.
    robots: Materials<usize>,
    /// The materials owned.
    materials: Materials<usize>,
    /// The remaining time in minutes.
    remaining_minutes: usize,
    /// The elapsed time in minutes.
    elapsed_minutes: usize,
    /// The material of the robot purchased most recently.
    /// `None` at the initial step.
    last_robot: Option<Material>,
    /// The materials owned at the last minute.
    /// Zero for each material at the initial step.
    last_materials: Materials<usize>,
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

    /// Iterates the mapped value for every material in the order
    /// 1. ore
    /// 2. clay
    /// 3. obsidian
    /// 4. geode
    fn into_iter(self) -> Self::IntoIter {
        [self.ore, self.clay, self.obsidian, self.geode].into_iter()
    }
}

impl<T> From<HashMap<Material, T>> for Materials<T> where T: Clone + Default {
    /// Parses a (dynamic) `HashMap<Material, T>` into a (fixed-size) `Materials<T>`.
    /// Every key not present is defaulted to `Default::default()`.
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

    /// Parses a robot template from the given string.
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

    /// Parses a blueprint from the given string.
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
    /// Creates a new `State` using the given number of minutes remaining.
    /// The initial state provides a single ore robot and no material.
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

    /// Performs a step, adding the resources each robot mines and
    /// updating the elapsed and remaining time.
    fn step(&mut self) {
        self.materials += self.robots;
        self.remaining_minutes -= 1;
        self.elapsed_minutes += 1;
    }

    /// Spends the given number of each material.
    fn spend(&mut self, deltas: Materials<usize>) {
        self.materials = self.materials.zip(deltas, |c, d| c - d);
    }

    /// Computes the next state after purchasing the given robot.
    /// Returns `None` if the material is insufficient to buy the robot.
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

    /// Checks whether building the given robot makes sense in the context
    /// of the search for the maximum number of obtainable geodes. Returning
    /// `false` is effectively equivalent to pruning the corresponding branch
    /// in the DFS tree. Since the search space is huge, pruning branches is
    /// one of the most effective ways to reduce the search time.
    fn should_build(&self, robot: &Robot, blueprint: &Blueprint) -> bool {
        // Don't build a robot in the last minute.
        match (self.remaining_minutes, robot.material) {
            (1, _)
          | (2, Some(Material::Ore | Material::Clay | Material::Obsidian))
          | (3, Some(Material::Clay)) => return false,
            _ => {},
        }

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

    /// Finds the next states from this state using the given blueprint.
    fn childs<'a>(&'a self, blueprint: &'a Blueprint) -> impl Iterator<Item = Self> + 'a {
        iter::once(self.next(None))
            .chain(blueprint.robots.into_iter()
                .filter(|r| self.should_build(r, blueprint))
                .map(|r| self.next(Some(&r))))
            .flatten()
    }

    /// Finds the minimum number of minutes until (even without considering the
    /// material costs) we could possibly have a geode robot. This value is
    /// determined by our maximum 'robot level'.
    fn minimum_minutes_to_geode_robot(&self) -> usize {
        if self.robots.geode > 0 {
            0
        } else if self.robots.obsidian > 0 {
            1
        } else if self.robots.clay > 0 {
            2
        } else {
            3
        }
    }

    /// Performs a depth-first search for the maximum number of geodes that could
    /// be obtained by any course of action. Uses a number of pruning strategies
    /// to reduce the (very large) search space.
    fn dfs_geodes(&self, blueprint: &Blueprint, print_depth: usize) -> usize {
        if self.elapsed_minutes < print_depth {
            let indent = iter::repeat(' ').take(self.elapsed_minutes).into_iter().collect::<String>();
            println!("{}{:02}: (robots: {}, materials: {})", indent, self.elapsed_minutes, self.robots, self.materials);
        }
        if self.remaining_minutes == 0 {
            self.materials.geode
        } else {
            let mut max_geodes: usize = 0;
            let mut min_minutes_to_geode: usize = usize::MAX;
            for child in self.childs(blueprint) {
                let minutes_to_geode = child.minimum_minutes_to_geode_robot();
                if minutes_to_geode <= min_minutes_to_geode {
                    min_minutes_to_geode = minutes_to_geode;
                    max_geodes = max_geodes.max(child.dfs_geodes(blueprint, print_depth));
                }
            }
            max_geodes
        }
    }
}

impl Blueprint {
    /// Creates a new `Blueprint` from the given robot templates.
    fn new(robots: Materials<Robot>) -> Self {
        let max_costs = robots.into_iter()
            .map(|r| r.costs)
            .reduce(|c1, c2| c1.zip(c2, Ord::max))
            .unwrap_or_default();

        Self { robots, max_costs }
    }

    /// Computes the maximum number of geodes obtainable within the
    /// given number of minutes. The `print_depth` indicates to which
    /// depth debug log lines should be output.
    fn max_geodes(&self, remaining_minutes: usize, print_depth: usize) -> usize {
        State::new(remaining_minutes).dfs_geodes(self, print_depth)
    }
}

#[derive(Parser)]
struct Args {
    /// The path to the input file.
    #[arg(short, long, default_value = "resources/input.txt")]
    input: String,

    /// How many minutes deep the DFS results should be printed.
    #[arg(long, default_value_t = 0)]
    print_depth: usize,

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
    #[arg(short, long, default_value_t = 3)]
    part2_blueprints: usize,

    /// Whether to skip part 1.
    #[arg(long, default_value_t = false)]
    skip_part1: bool,

    /// Whether to skip part 2.
    #[arg(long, default_value_t = false)]
    skip_part2: bool,
}

fn main() {
    let args = Args::parse();

    // Parse the blueprints from the input
    let blueprints = fs::read_to_string(args.input).unwrap()
        .split('\n')
        .filter(|l| !l.is_empty())
        .filter_map(|l| l.parse().ok())
        .collect::<Vec<Blueprint>>();
    
    // Perform the part 1 search if needed
    if !args.skip_part1 {
        let part1 = blueprints.par_iter().enumerate()
            .take(if args.smoke { 1 } else { args.part1_blueprints })
            .map(|(i, b)| (i + 1) * b.max_geodes(args.part1_minutes, args.print_depth))
            .sum::<usize>();

        println!("Part 1: {}", part1);
    }

    // Perform the part 2 search if needed
    if !args.skip_part2 && !args.smoke {
        let part2 = blueprints.par_iter().enumerate()
            .take(args.part2_blueprints)
            .map(|(i, b)| {
                let geodes = b.max_geodes(args.part2_minutes, args.print_depth);
                println!("Max geodes for {}. blueprint from part 2: {}", i + 1, geodes);
                geodes
            })
            .product::<usize>();

        println!("Part 2: {}", part2);
    }
}
