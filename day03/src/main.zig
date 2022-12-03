const std = @import("std");

pub fn main() !void {
    // Set up stdout
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Read input
    var file = try std.fs.cwd().openFile("resources/demo.txt", .{});
    defer file.close();
    var br = std.io.bufferedReader(file.reader());
    var input = br.reader();

    var buf: [1024]u8 = undefined;
    while (try input.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try stdout.print("Line: {s} of len {d}\n", .{line, line.len});
    }

    try bw.flush();
}
