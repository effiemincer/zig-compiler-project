const std = @import("std");
const mainUtils = @import("utils.zig");
const write_xml = mainUtils.write_xml;

pub const TokenType = enum {
    keyword,
    symbol,
    integerConstant,
    stringConstant,
    identifier,
    pub fn toString(self: TokenType) []const u8 {
        return switch (self) {
            .keyword => "keyword",
            .symbol => "symbol",
            .integerConstant => "integerConstant",
            .stringConstant => "stringConstant",
            .identifier => "identifier",
        };
    }
};

pub const Token = struct {
    type: TokenType,
    value: []const u8,
};

const keywords = [_][]const u8{ "class", "constructor", "function", "method", "field", "static", "var", "int", "char", "boolean", "void", "true", "false", "null", "this", "let", "do", "if", "else", "while", "return" };

const State = enum {
    start,
    stringConstant,
    integerConstant,
    line_comment,
    block_comment,
    identifier,
    slash,
    star_in_comment,
};

pub const Tokenizer = struct {
    contents: []u8,
    index: usize,
    writer: std.fs.File.Writer,

    pub fn is_eof(self: *Tokenizer) bool {
        return self.index >= self.contents.len;
    }

    // using DFA state machine mechanics to parse the token using lazy evaluation
    pub fn next(self: *Tokenizer) ?Token {
        var tokenStart: usize = 0;
        var state: State = .start;

        while (self.index < self.contents.len) : (self.index += 1) {
            const c = self.contents[self.index];

            switch (state) {
                // start state
                .start => switch (c) {
                    // / --> go to slash
                    '/' => state = .slash,
                    // [0-9] --> start new token go to intConstant
                    '0'...'9' => {
                        tokenStart = self.index;
                        state = .integerConstant;
                    },
                    // " --> start new token go to strConstant
                    '"' => {
                        tokenStart = self.index + 1;
                        state = .stringConstant;
                    },
                    // white space do nothing continue
                    '\n', ' ', '\t' => {},
                    // reserved tokens
                    '{', '}', '(', ')', '[', ']', '.', ',', ';', '+', '-', '*', '&', '|', '<', '>', '=', '~' => {
                        const token = self.contents[self.index..(self.index + 1)];
                        self.index += 1;
                        return Token{ .type = .symbol, .value = token };
                    },
                    // [a-z | A-Z | _] --> start identifier
                    'a'...'z', 'A'...'Z', '_' => {
                        tokenStart = self.index;
                        state = .identifier;
                    },
                    else => {},
                },
                // if we are in the slash state
                .slash => switch (c) {
                    '/' => state = .line_comment,
                    '*' => state = .block_comment,
                    else => {
                        self.index += 1;
                        return Token{ .type = .symbol, .value = "/" };
                    },
                },
                .line_comment => switch (c) {
                    // do nothing until hitting newline for new token parsing
                    '\n' => state = .start,
                    else => {},
                },

                .block_comment => switch (c) {
                    // do nothing until hitting * for new token parsing
                    '*' => state = .star_in_comment,
                    else => {},
                },
                .star_in_comment => switch (c) {
                    '/' => state = .start,
                    else => state = .block_comment,
                },
                .integerConstant => switch (c) {
                    // continue taking in numbers
                    '0'...'9' => {},
                    // once we hit a white space or other char save all previous numbers into one intConst token
                    else => {
                        const myToken = self.contents[tokenStart..self.index];
                        // u15 is exactly the size of Jack's integer constants, and if it overflows, throw a parser error
                        _ = std.fmt.parseInt(u15, myToken, 10) catch {
                            std.debug.panic("Integer constant out of range: {s}", .{myToken});
                        };
                        // return int constant token and wait for next self.next call retain state and index info
                        return Token{ .type = .integerConstant, .value = myToken };
                    },
                },
                .stringConstant => switch (c) {
                    // once we hit another " save everything into a string constant
                    '"' => {
                        const myToken = self.contents[tokenStart..self.index];
                        self.index += 1;
                        // return str constant token and wait for next self.next call retain state and index info
                        return Token{ .type = .stringConstant, .value = myToken };
                    },
                    else => {},
                },
                .identifier => switch (c) {
                    'a'...'z', 'A'...'Z', '0'...'9', '_' => {},
                    // once we hit a white space or another char save all previus things into a id token
                    else => {
                        const myToken = self.contents[tokenStart..self.index];
                        // check if its one of the keywords in teh language
                        for (keywords) |keyword| {
                            if (std.mem.eql(u8, keyword, myToken)) {
                                return Token{ .type = .keyword, .value = myToken };
                            }
                        }
                        // else return the identifeir token
                        return Token{ .type = .identifier, .value = myToken };
                    },
                },
            }
        }
        return null;
    }


    // write out the token stream to a file to create XXXT.xml file
    pub fn writeTokenStreamToFile(self: *Tokenizer) !void {
        // 1) rewind so we start from the very first token
        self.index = 0;

            // 2) print opening container
        try self.writer.print("<tokens>\n", .{});

            // 3) loop through every token
        while (true) {
                const opt = self.next();
                if (opt == null) break;
                if (opt) |opt_val| {
                    try write_xml(self.writer, opt_val);
                }
            }

            // 4) closing container
        try self.writer.print("</tokens>\n", .{});
            // 6) reset index so parser can start fresh
        self.index = 0;
    }

};