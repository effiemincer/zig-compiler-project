const std = @import("std");
const tokenizer = @import("./JackTokenizer.zig");
const Tokenizer = tokenizer.Tokenizer;
const TokenType = tokenizer.TokenType;
const Token = tokenizer.Token;
const mainUtils = @import("utils.zig");
const write_xml = mainUtils.write_xml;

pub const Parser = struct {
    tokens: Tokenizer,
    currentToken: Token,
    indentation: usize,
    writer: std.fs.File.Writer,

    // 'class' className '{' classVarDec* subroutineDec* '}'
    pub fn parseClass(self: *Parser) void {
        self.writeTag("class");
        // write end tag after all class parsing is done
        defer self.writeTagEnd("class");
        self.checkAndWrite(.keyword, "class"); // class className {
        self.checkAndWriteType(.identifier); // className
        self.checkAndWrite(.symbol, "{");
        while (self.checkTokenList(&.{ "static", "field" })) {
            self.parseClassVarDec(); // classVarDec*
        }
        while (self.checkTokenList(&.{ "constructor", "function", "method" })) {
            self.parseSubroutineDec(); // subroutineDec*
        }
        self.checkAndWrite(.symbol, "}");
    }

    // ('static' | 'field' ) type varName (',' varName)* ';'
    fn parseClassVarDec(self: *Parser) void {
        self.writeTag("classVarDec");
        // write end tag after all class var declaration parsing is done
        defer self.writeTagEnd("classVarDec");
        // check if current token value is either static or field
        // write the static/field tags
        self.checkAndWriteList(&.{ "static", "field" });
        self.writeToken(); // type
        self.checkAndWriteType(.identifier); // varName
        while (self.trycheckAndWriteToken(.symbol, ",")) {
            self.checkAndWriteType(.identifier); // (, varName)*
        }
        self.checkAndWrite(.symbol, ";");
    }

    // ('constructor' | 'function' | 'method') ('void' | type) subroutineName '('parameterList ')' subroutineBody
    fn parseSubroutineDec(self: *Parser) void {
        self.writeTag("subroutineDec");
        // write end tag after all subroutine parsing is done
        defer self.writeTagEnd("subroutineDec");
        self.checkAndWriteList(&.{ "constructor", "function", "method" });
        self.writeToken(); // type
        self.checkAndWriteType(.identifier); // subroutineName
        self.checkAndWrite(.symbol, "(");
        self.parseParameterList();
        self.checkAndWrite(.symbol, ")");
        self.parseSubroutineBody();
    }

    // ( (type varName) (',' type varName)*)?
    fn parseParameterList(self: *Parser) void {
        self.writeTag("parameterList");
        // write end tag after all subroutine parsing is done
        defer self.writeTagEnd("parameterList");
        if (self.checkToken(.symbol, ")")) {
            return;
        }
        self.writeToken(); // type
        self.checkAndWriteType(.identifier); // varName
        while (self.trycheckAndWriteToken(.symbol, ",")) {
            self.writeToken(); // type
            self.checkAndWriteType(.identifier); // varName
        }
    }

    // '{' varDec* statements '}'
    fn parseSubroutineBody(self: *Parser) void {
        self.writeTag("subroutineBody");
        defer self.writeTagEnd("subroutineBody");
        self.checkAndWrite(.symbol, "{");
        while (self.checkToken(.keyword, "var")) {
            self.parseVarDec();
        }
        self.parseStatements();
        self.checkAndWrite(.symbol, "}");
    }

    // 'var' type varName (',' varName)* ';
    fn parseVarDec(self: *Parser) void {
        self.writeTag("varDec");
        defer self.writeTagEnd("varDec");
        self.checkAndWrite(.keyword, "var");
        self.writeToken(); // type
        self.checkAndWriteType(.identifier); // varName
        while (self.trycheckAndWriteToken(.symbol, ",")) {
            self.checkAndWriteType(.identifier); // varName
        }
        self.checkAndWrite(.symbol, ";");
    }

    // letStatement | ifStatement | whileStatement | doStatement | returnStatement
    fn parseStatements(self: *Parser) void {
        self.writeTag("statements");
        defer self.writeTagEnd("statements");
        while (self.checkTokenList(&.{ "let", "if", "while", "do", "return" })) {
            if (self.checkToken(.keyword, "let")) {
                self.parseLet();
            } else if (self.checkToken(.keyword, "if")) {
                self.parseIf();
            } else if (self.checkToken(.keyword, "while")) {
                self.parseWhile();
            } else if (self.checkToken(.keyword, "do")) {
                self.parseDo();
            } else if (self.checkToken(.keyword, "return")) {
                self.parseReturn();
            }
        }
    }

    // 'let' varName ('[' expression ']')? '=' expression ';'
    fn parseLet(self: *Parser) void {
        self.writeTag("letStatement");
        defer self.writeTagEnd("letStatement");
        self.checkAndWrite(.keyword, "let");
        self.checkAndWriteType(.identifier); // varName
        if (self.trycheckAndWriteToken(.symbol, "[")) {
            self.parseExpression();
            self.checkAndWrite(.symbol, "]");
        }
        self.checkAndWrite(.symbol, "=");
        self.parseExpression();
        self.checkAndWrite(.symbol, ";");
    }

    // 'if' '(' expression ')' '{' statements '}' ( 'else' '{' statements '}' )?
    fn parseIf(self: *Parser) void {
        self.writeTag("ifStatement");
        defer self.writeTagEnd("ifStatement");
        self.checkAndWrite(.keyword, "if");
        self.checkAndWrite(.symbol, "(");
        self.parseExpression();
        self.checkAndWrite(.symbol, ")");
        self.checkAndWrite(.symbol, "{");
        self.parseStatements();
        self.checkAndWrite(.symbol, "}");
        if (self.trycheckAndWriteToken(.keyword, "else")) {
            self.checkAndWrite(.symbol, "{");
            self.parseStatements();
            self.checkAndWrite(.symbol, "}");
        }
    }

    // 'while' '(' expression ')' '{' statements '}'
    fn parseWhile(self: *Parser) void {
        self.writeTag("whileStatement");
        defer self.writeTagEnd("whileStatement");
        self.checkAndWrite(.keyword, "while");
        self.checkAndWrite(.symbol, "(");
        self.parseExpression();
        self.checkAndWrite(.symbol, ")");
        self.checkAndWrite(.symbol, "{");
        self.parseStatements();
        self.checkAndWrite(.symbol, "}");
    }

    // 'do' subroutineCall ';'
    fn parseDo(self: *Parser) void {
        self.writeTag("doStatement");
        defer self.writeTagEnd("doStatement");
        self.checkAndWrite(.keyword, "do");
        self.parseSubroutineCall();
        self.checkAndWrite(.symbol, ";");
    }

    // subroutineName '(' expressionList ')' | ( className | varName) '.' subroutineName '(' expressionList ')'
    fn parseSubroutineCall(self: *Parser) void {
        self.checkAndWriteType(.identifier); // subroutineName | className | varName
        if (self.trycheckAndWriteToken(.symbol, "(")) {
            self.parseExpressionList();
            self.checkAndWrite(.symbol, ")");
        } else if (self.trycheckAndWriteToken(.symbol, ".")) { // (className | varName).subroutine( )
            self.checkAndWriteType(.identifier); // subroutineName
            self.checkAndWrite(.symbol, "(");
            self.parseExpressionList();
            self.checkAndWrite(.symbol, ")");
        }
    }

    // 'return' expression? ';'
    fn parseReturn(self: *Parser) void {
        self.writeTag("returnStatement");
        defer self.writeTagEnd("returnStatement");
        self.checkAndWrite(.keyword, "return");
        if (!self.checkToken(.symbol, ";")) {
            self.parseExpression();
        }
        self.checkAndWrite(.symbol, ";");
    }

    // term (operation term)*
    fn parseExpression(self: *Parser) void {
        self.writeTag("expression");
        defer self.writeTagEnd("expression");
        self.parseTerm(); // term
        while (self.trycheckAndWriteOp()) { // operation
            self.parseTerm(); // term
        }
    }

    // integerConstant | stringConstant | keywordConstant | varName | varName '[' expression ']' | subroutineCall | '(' expression ')' | unaryOp term
    fn parseTerm(self: *Parser) void {
        self.writeTag("term"); // <term>
        defer self.writeTagEnd("term"); // </term> --> after scope exits
        if (self.trycheckAndWriteToken(.symbol, "(")) { // ( expression )
            self.parseExpression();
            self.checkAndWrite(.symbol, ")");
        } else if (self.trycheckAndWriteToken(.symbol, "-") or self.trycheckAndWriteToken(.symbol, "~")) { // unaryOp
            self.parseTerm();
            //  intConstant | strConstant | kwConstant
        } else if (self.checkKeywordConstant() or self.checkTokenType(.stringConstant) or self.checkTokenType(.integerConstant)) {
            self.writeToken(); // keywordConstant | stringConstant | integerConstant
        } else if (self.checkTokenType(.identifier)) {
            self.checkAndWriteType(.identifier); // varName | className
            if (self.trycheckAndWriteToken(.symbol, "[")) { // varName [ expression ]
                self.parseExpression();
                self.checkAndWrite(.symbol, "]");
            } else if (self.trycheckAndWriteToken(.symbol, ".")) { // id.id --> className.(expressionList)
                self.checkAndWriteType(.identifier); // identifier
                if (self.trycheckAndWriteToken(.symbol, "(")) {
                    self.parseExpressionList();
                    self.checkAndWrite(.symbol, ")");
                }
            } else if (self.trycheckAndWriteToken(.symbol, "(")) { // functionName( expressionList )
                self.parseExpressionList();
                self.checkAndWrite(.symbol, ")");
            }
        } else {
            std.debug.panic("Inavlid expression: unexpected token {}", .{self.currentToken});
        }
    }

    // (expression (',' expression)* )?
    fn parseExpressionList(self: *Parser) void {
        self.writeTag("expressionList");
        defer self.writeTagEnd("expressionList");
        if (self.checkToken(.symbol, ")")) { // ()
            return;
        }
        self.parseExpression();
        while (self.trycheckAndWriteToken(.symbol, ","))  { // (expression (, expression)* )
            self.parseExpression();
        }
    }

    // 'true' | 'false' | 'null' | 'this'
    fn checkKeywordConstant(self: *Parser) bool {
        return self.checkTokenType(.keyword) and self.checkTokenList(&.{ "true", "false", "null", "this" });
    }

    // '+' | '-' | '*' | '/' | '&' | '|' | '<' | '>' | '='
    fn trycheckAndWriteOp(self: *Parser) bool {
        const isOp = self.checkTokenType(.symbol) and (self.checkTokenList(&.{ "+", "-", "*", "/", "&", "|", "<", ">", "=" }));
        if (isOp) {
            self.writeToken();
        }
        return isOp;
    }

    // If the token exists, return true and write it, else return false
    fn trycheckAndWriteToken(self: *Parser, tokenType: TokenType, value: []const u8) bool {
        const isValid = self.checkToken(tokenType, value);
        if (isValid) {
            self.writeToken();
        }
        return isValid;
    }

    // Check current token has given type and value
    fn checkToken(self: *Parser, tokenType: TokenType, value: []const u8) bool {
        return self.checkTokenType(tokenType) and self.checkTokenValue(value);
    }
    // confirm the current token has a given type
    fn checkTokenType(self: *Parser, tokenType: TokenType) bool {
        return self.currentToken.type == tokenType;
    }
    // confirm the current token has a given value
    fn checkTokenValue(self: *Parser, value: []const u8) bool {
        return std.mem.eql(u8, self.currentToken.value, value);
    }

    // Check if the current token has a value that is a member in the tokenList
    fn checkTokenList(self: *Parser, tokenList: []const []const u8) bool {
        for (tokenList) |token| {
            if (self.checkTokenValue(token)) {
                return true;
            }
        }
        return false;
    }

    // These checkAndWrite functions are just check and then writeToken or error
    fn checkAndWriteList(self: *Parser, tokenList: []const []const u8) void {
        if (!self.checkTokenList(tokenList)) {
            std.debug.panic("Expected token of value {s} but got token {s}\n", .{ tokenList, self.currentToken.value });
        }
        self.writeToken();
    }
    fn checkAndWrite(self: *Parser, tokenType: TokenType, value: []const u8) void {
        if (!self.checkToken(tokenType, value)) {
            std.debug.panic("Expected token of type {s} with value {s} but got {s} with value {s}\n", .{ tokenType.toString(), value, self.currentToken.type.toString(), self.currentToken.value });
        }
        self.writeToken();
    }
    fn checkAndWriteType(self: *Parser, tokenType: TokenType) void {
        if (!self.checkTokenType(tokenType)) {
            std.debug.panic("Expected token of type {s} but got {s}\n", .{ tokenType.toString(), self.currentToken.type.toString() });
        }
        self.writeToken();
    }

    fn writeToken(self: *Parser) void {
        self.writer.writeByteNTimes(' ', self.indentation * 2) catch return;
        write_xml(self.writer, self.currentToken) catch return;
        self.currentToken = self.tokens.next() orelse return;
    }
    fn writeTag(self: *Parser, tag: []const u8) void {
        self.writer.writeByteNTimes(' ', self.indentation * 2) catch return;
        self.writer.print("<{s}>\n", .{tag}) catch return;
        self.indentation += 1;
    }
    fn writeTagEnd(self: *Parser, tag: []const u8) void {
        self.indentation -= 1;
        self.writer.writeByteNTimes(' ', self.indentation * 2) catch return;
        self.writer.print("</{s}>\n", .{tag}) catch return;
    }
};
