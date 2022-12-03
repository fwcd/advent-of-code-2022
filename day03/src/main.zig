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

pub fn findCommonItem(s: []u8) u8 {
    var freqs = std.mem.zeroes([52]u8);
    for (s[0..(s.len / 2)]) |c| {
        freqs[charToIndex(c)] += 1;
    }
    for (s[(s.len / 2)..]) |c| {
        if (freqs[charToIndex(c)] > 0) {
            return c;
        }
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

    var buf: [1024]u8 = undefined;
    var part1: u32 = 0;
    while (try input.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const c = findCommonItem(line);
        part1 += score(c);
    }

    try stdout.print("Part 1: {d}\n", .{part1});

    try bw.flush();
}
