const std = @import("std");

pub fn charToIndex(c: u8) usize {
    if (c >= 'a' and c <= 'z') {
        return @as(usize, c - 'a');
    } else {
        return @as(usize, c - 'A') + 26;
    }
}

pub fn indexToChar(i: usize) u8 {
    if (i >= 26) {
        return @truncate(u8, i - 26) + 'A';
    } else {
        return @truncate(u8, i + 'a');
    }
}

pub fn score(c: u8) u32 {
    return @truncate(u32, charToIndex(c)) + 1;
}

pub fn toSet(s: []u8) u64 {
    var set: u64 = 0;
    for (s) |c| {
        set |= @as(u64, 1) << @intCast(u6, charToIndex(c));
    }
    return set;
}

pub fn firstChar(set: u64) u8 {
    var value = set;
    var i: u32 = 0;
    while (i < 64) : (i += 1) {
        if ((value & 1) == 1) {
            return indexToChar(i);
        }
        value = value >> 1;
    }
    return 0;
}

pub fn main() !void {
    // Set up stdout
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Read input
    var file = try std.fs.cwd().openFile("resources/input.txt", .{});
    defer file.close();
    var br = std.io.bufferedReader(file.reader());
    var input = br.reader();

    // Solve the problem
    var buf: [1024]u8 = undefined;
    var part1: u32 = 0;
    while (try input.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const left = toSet(line[0..(line.len / 2)]);
        const right = toSet(line[(line.len / 2)..]);
        part1 += score(firstChar(left & right));
    }

    try stdout.print("Part 1: {d}\n", .{part1});
    try bw.flush();
}
