/// Entry point and general utility functions for the compiler.

const std = @import("std");
const mainUtils = @import("utils.zig");

const tokenizer = @import("./tokenizer.zig");
const compiler = @import("./compiler.zig");
const symbolTable = @import("./symbolTable.zig");
const Tokenizer = tokenizer.Tokenizer;
const Token = tokenizer.Token;
const Compiler = compiler.Compiler;
const SymbolTable = symbolTable.SymbolTable;

const readAndCleanUserInput = mainUtils.readAndCleanUserInput;
const getFileName = mainUtils.getFileName;
const getFolderPath = mainUtils.getFolderPath;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpa.allocator();

fn run_file(folder: std.fs.Dir, fileName: []const u8) !void {
    // Open and read file
    const file = try folder.openFile(fileName, .{});
    defer file.close();
    const contents = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(contents);

    // Create a file with "Mine.xml" appended to the name (and .jack stripped).
    var outFile = try allocator.alloc(u8, fileName.len - 2);
    defer allocator.free(outFile);
    std.mem.copyForwards(u8, outFile, fileName[0 .. fileName.len - 2]);
    std.mem.copyForwards(u8, outFile[(fileName.len - 5) .. fileName.len - 2], ".vm");
    var output = try folder.createFile(outFile, .{});

    // Build the tokenizer, and pass that structure to the parser
    var tokens = Tokenizer{ .contents = contents, .index = 0 };
    var myCompiler = try Compiler.init(&tokens, output.writer(), allocator);
    defer myCompiler.deinit();

    myCompiler.compileClass();
}


// The ! means that this function is allowed to error.
pub fn main() !void {
    // Check that we've deallocated evertyhing.
    defer std.debug.assert(gpa.deinit() == .ok);

    const stdout = std.io.getStdOut().writer();

    // Prompt the user for a directory path
    try stdout.print("Enter directory path for file(s): ", .{});

    const userInput = readAndCleanUserInput() catch |err|{
        std.debug.print("arg failed, error: {}", .{err});
        return;
    };

    var folder = try std.fs.openDirAbsolute(userInput,  .{.iterate = true});

    defer folder.close();
    var iterator = folder.iterate();
    while (try iterator.next()) |entry| {
        if (std.mem.endsWith(u8, entry.name, ".jack")) {
            try run_file(folder, entry.name);
        }
    }
}
