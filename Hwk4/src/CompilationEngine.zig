const std = @import("std");
const mainUtils = @import("utils.zig");

const tokenizer = @import("./JackTokenizer.zig");
const parser = @import("./JackAnalyzer.zig");
const Tokenizer = tokenizer.Tokenizer;
const Token = tokenizer.Token;
const Parser = parser.Parser;

const readAndCleanUserInput = mainUtils.readAndCleanUserInput;
const getFileName = mainUtils.getFileName;
const getFolderPath = mainUtils.getFolderPath;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpa.allocator();

fn run_file(folder: std.fs.Dir, fileName: []const u8) !void {
    const file = try folder.openFile(fileName, .{});
    defer file.close();
    const contents = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(contents);

    // allocate enough for original name minus “.jack” + “T.xml” (net same length as fileName)
    var outFileT = try allocator.alloc(u8, fileName.len);
    defer allocator.free(outFileT);

    // copy the entire original name (we’ll overwrite its old “.jack”)
    std.mem.copyForwards(u8, outFileT, fileName);

    // overwrite the final 5 bytes (where “.jack” was) with “T.xml”
    std.mem.copyForwards(
        u8,
        outFileT[(fileName.len - 5) .. fileName.len],
        "T.xml"
    );

    var outputT = try folder.createFile(outFileT, .{});

    // Create a file with "Mine.xml" appended to the name (and .jack stripped).
        // allocate: drop 5 (“.jack”) and add 4 (“.xml”) ⇒ net -1
    var outFile = try allocator.alloc(u8, fileName.len - 1);
    defer allocator.free(outFile);

    // copy the base name + old extension (you’ll overwrite the extension next)
    std.mem.copyForwards(u8, outFile, fileName[0..fileName.len - 1]);

    // overwrite exactly the 4-byte slice where “.jack” was
    std.mem.copyForwards(
        u8,
        outFile[(fileName.len - 5) .. (fileName.len - 1)],
        ".xml"
    );

    var output = try folder.createFile(outFile, .{});

    // Build the tokenizer, and pass that structure to the parser
    var tokens = Tokenizer{ .contents = contents, .index = 0, .writer = outputT.writer() };
    try tokens.writeTokenStreamToFile();

    // We start with the currentToken being non-null
    const firstToken = tokens.next() orelse return;
    var myParser = Parser{ .tokens = tokens, .currentToken = firstToken, .indentation = 0, .writer = output.writer() };
    // If you want to tokenize, just do myParser.printTokens();
    myParser.parseClass();
}

// The ! means that this function is allowed to error.
pub fn main() !void {
    // Check that we've deallocated evertyhing.
    defer std.debug.assert(gpa.deinit() == .ok);

    const stdout = std.io.getStdOut().writer();

    // Prompt the user for a directory path
    try stdout.print("Enter path for file(s): ", .{});

    const fileOrFolder = readAndCleanUserInput() catch |err|{
        std.debug.print("arg failed, error: {}", .{err});
        return;
    };
    const isFile = std.mem.endsWith(u8, fileOrFolder, ".jack");

    if (isFile) {
        // const folderPath = getFolderPath(fileOrFolder);
        const fileName = getFileName(fileOrFolder);
        try run_file(std.fs.cwd(), fileName);
    } else {
        var folder = try std.fs.openDirAbsolute(fileOrFolder,  .{.iterate = true});

        defer folder.close();
        var iterator = folder.iterate();
        while (try iterator.next()) |entry| {
            if (std.mem.endsWith(u8, entry.name, ".jack")) {
                try run_file(folder, entry.name);
            }
        }
    }
}