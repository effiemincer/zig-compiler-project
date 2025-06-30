/// Symbol table manager for the compiler.
/// Stores symbols (variables) in separate lists by kind: static, field, argument, and local.
/// Provides functions to add, lookup, clear, and count symbols.
/// Used by the compiler to resolve identifiers and determine their VM segment and index.

const std = @import("std");

pub const Kinds = enum {
    static,
    field,
    argument,
    local,
    pub fn toString(self: Kinds) []const u8 {
        return switch (self) {
            .static => "static",
            .field => "this",
            .argument => "argument",
            .local => "local",
        };
    }
};

pub const Symbol = struct {
    type: []const u8,
    name: []const u8,
};

const SymbolList = std.ArrayList(Symbol);

const kindsLen = @typeInfo(Kinds).@"enum".fields.len; // otherwise known as 4

const SymbolReturn = struct {
    symbol: Symbol,
    index: u32,
    kind: Kinds,
};

pub const SymbolTable = struct {
    // We don't need to store a parent
    symbol_list: [kindsLen]SymbolList,
    pub fn init(allocator: std.mem.Allocator) SymbolTable {
        var list: [kindsLen]SymbolList = undefined;
        comptime var i: usize = 0;
        inline while (i < kindsLen) : (i += 1) {
            list[i] = SymbolList.init(allocator);
        }
        return SymbolTable{
            .symbol_list = list,
        };
    }
    // Deinit will deallocate all the ArrayLists
    pub fn deinit(self: *SymbolTable) void {
        for (self.symbol_list) |list| {
            list.deinit();
        }
    }
    pub fn add(self: *SymbolTable, kind: Kinds, stype: []const u8, name: []const u8) void {
        const symbol = Symbol{
            .type = stype,
            .name = name,
        };
        self.symbol_list[@intFromEnum(kind)].append(symbol) catch return;
    }
    // When we exit a method we need to clear the locals and arguments
    pub fn clear(self: *SymbolTable) void {
        self.symbol_list[@intFromEnum(Kinds.local)].clearRetainingCapacity();
        self.symbol_list[@intFromEnum(Kinds.argument)].clearRetainingCapacity();
    }
    // When we want to find a symbol, we look through all of the symbols in each of the symbol types
    pub fn lookup(self: *SymbolTable, name: []const u8) ?SymbolReturn {
        for (self.symbol_list, 0..) |list, i| {
            for (list.items, 0..) |symbol, j| {
                if (std.mem.eql(u8, symbol.name, name)) {
                    return SymbolReturn{ .index = @truncate(j), .kind = @enumFromInt(i), .symbol = symbol };
                }
            }
        }
        return null;
    }
    // We parse the classVarDecs (fields), then we just need to count the number of them
    pub fn classVarCount(self: SymbolTable) u32 {
        return @truncate(self.symbol_list[@intFromEnum(Kinds.field)].items.len);
    }
    // We parse the varDecs, then we just need to count the number of them
    pub fn varCount(self: SymbolTable) u32 {
        return @truncate(self.symbol_list[@intFromEnum(Kinds.local)].items.len);
    }
};
