const std = @import("std");
const tokenizer = @import("./JackTokenizer.zig");
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

pub fn getFolderPath(path: []const u8) []const u8 {
    const last_sep = std.mem.lastIndexOfScalar(u8, path, '/');
    if (last_sep) |idx| {
        return path[0..idx];
    } else {
        return ""; // No slash found; path has no directory
    }
}

pub fn getFileName(path: []const u8) []const u8 {
    const last_sep = std.mem.lastIndexOfScalar(u8, path, '/');
    if (last_sep) |idx| {
        return path[(idx + 1)..];
    } else {
        return path; // No slash found; path is just the file name
    }
}

pub fn write_xml(writer: std.fs.File.Writer, token: Token) !void {
    const tokenType = token.type.toString();
    try writer.writeAll("<");
    try writer.writeAll(tokenType);
    try writer.writeAll("> ");

    // Tiny tokenizer to do string replacement without any allocation (by writing directly to an output file)
        var trailing: usize = 0;
    var i: usize = 0;
    while (i < token.value.len) : (i += 1) {
        switch (token.value[i]) {
            '&' => {
                try writer.writeAll(token.value[trailing..i]);
                try writer.writeAll("&amp;");
                trailing = i + 1;
            },
            '<' => {
                try writer.writeAll(token.value[trailing..i]);
                try writer.writeAll("&lt;");
                trailing = i + 1;
            },
            '>' => {
                try writer.writeAll(token.value[trailing..i]);
                try writer.writeAll("&gt;");
                trailing = i + 1;
            },
            '"' => {
                try writer.writeAll(token.value[trailing..i]);
                try writer.writeAll("&quot;");
                trailing = i + 1;
            },
            else => {},
        }
    }
    try writer.writeAll(token.value[trailing..]);

    try writer.writeAll(" </");
    try writer.writeAll(tokenType);
    try writer.writeAll(">\n");
}
