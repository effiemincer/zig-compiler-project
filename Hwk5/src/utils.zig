/// General utility functions used by the compiler.

const std = @import("std");
const tokenizer = @import("./tokenizer.zig");
const Token = tokenizer.Token;

pub fn readAndCleanUserInput() ![]const u8 {
    const allocator = std.heap.page_allocator;
    const stdin = std.io.getStdIn().reader();

    var buffer: [1024]u8 = undefined;
    var i: usize = 0;

    while (i < buffer.len) {
        const byte = stdin.readByte() catch |err| {
            std.debug.print("ERROR while reading input: {}\n", .{err});
            return error.InvalidInput;
        };

        if (byte == '\n' or byte == '\r') {
            break;
        }

        buffer[i] = byte;
        i += 1;
    }

    const trimmed = std.mem.trim(u8, buffer[0..i], " \r\n");
    return try allocator.dupe(u8, trimmed); //  makes a heap copy
}