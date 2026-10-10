--!strict

local AST = require(script.Parent.AST)
local Lexer = require(script.Parent.Lexer)
local Symbols = require(script.Parent.Symbols)

local Parser = {}

type Token = Lexer.Token
type Node = AST.Node
type Sequence = AST.Sequence

local MAX_PARSE_DEPTH = 128

type State = {
	tokens: { Token },
	index: number,
	depth: number,
}

local function current(state: State): Token
	return state.tokens[state.index]
end

local function advance(state: State): Token
	local token = current(state)
	state.index += 1
	return token
end

local function fail(token: Token, message: string): never
	error(string.format("MathTex parser: %s at position %d", message, token.position), 0)
end

local function skipWhitespace(state: State)
	while current(state).kind == "Space" do
		advance(state)
	end
end

local parseSequence: (state: State, inGroup: boolean, stopAtBracket: boolean?) -> Sequence
local parseAtom: (state: State) -> Node
local parsePrimary: (state: State) -> Node

local function parseRequiredGroup(state: State, command: Token): Sequence
	skipWhitespace(state)
	local token = current(state)
	if token.kind ~= "LBrace" then
		fail(token, "\\" .. command.value .. " expects a braced argument")
	end
	advance(state)
	local group = parseSequence(state, true, false)
	if #group.children == 0 then
		fail(command, "\\" .. command.value .. " argument cannot be empty")
	end
	return group
end

local function parseScriptArgument(state: State, marker: Token): Node
	skipWhitespace(state)
	local token = current(state)
	if token.kind == "EOF" or token.kind == "RBrace" or token.kind == "Superscript" or token.kind == "Subscript" then
		fail(marker, "script marker must be followed by an argument")
	end
	if token.kind == "LBrace" then
		advance(state)
		local body = parseSequence(state, true, false)
		if #body.children == 0 then
			fail(marker, "script argument cannot be empty")
		end
		return AST.group(body)
	end
	return parsePrimary(state)
end

parsePrimary = function(state: State): Node
	local token = advance(state)
	if token.kind == "Number" or token.kind == "Character" or token.kind == "Operator" then
		return AST.glyph(token.value)
	elseif token.kind == "LBrace" then
		return AST.group(parseSequence(state, true, false))
	elseif token.kind == "LBracket" then
		return AST.glyph("[")
	elseif token.kind == "Command" then
		if token.value == "frac" then
			local numerator = parseRequiredGroup(state, token)
			local denominator = parseRequiredGroup(state, token)
			return AST.fraction(numerator, denominator)
		elseif token.value == "sqrt" then
			local index: Sequence? = nil
			skipWhitespace(state)
			if current(state).kind == "LBracket" then
				advance(state)
				index = parseSequence(state, false, true)
				if current(state).kind ~= "RBracket" then
					fail(current(state), "missing closing bracket for root index")
				end
				advance(state)
				if #index.children == 0 then
					fail(token, "root index cannot be empty")
				end
			end
			return AST.root(parseRequiredGroup(state, token), index)
		else
			local spacing = Symbols.getSpacing(token.value)
			if spacing ~= nil then
				return AST.space(spacing)
			end
			local symbol = Symbols.get(token.value)
			if symbol == nil then
				fail(token, "unknown command \\" .. token.value)
			end
			return AST.glyph(symbol.text)
		end
	elseif token.kind == "RBrace" then
		fail(token, "unexpected closing brace")
	elseif token.kind == "RBracket" then
		fail(token, "unexpected closing bracket")
	elseif token.kind == "Superscript" or token.kind == "Subscript" then
		fail(token, "script marker has no base expression")
	elseif token.kind == "EOF" then
		fail(token, "expected an expression")
	else
		fail(token, "unexpected token")
	end
end

parseAtom = function(state: State): Node
	local base = parsePrimary(state)
	local superscript: Node? = nil
	local subscript: Node? = nil
	while current(state).kind == "Superscript" or current(state).kind == "Subscript" do
		local marker = advance(state)
		if marker.kind == "Superscript" then
			if superscript ~= nil then
				fail(marker, "duplicate superscript")
			end
			superscript = parseScriptArgument(state, marker)
		else
			if subscript ~= nil then
				fail(marker, "duplicate subscript")
			end
			subscript = parseScriptArgument(state, marker)
		end
	end
	if superscript ~= nil or subscript ~= nil then
		return AST.scripts(base, superscript, subscript)
	end
	return base
end

parseSequence = function(state: State, inGroup: boolean, stopAtBracket: boolean?): Sequence
	state.depth += 1
	if state.depth > MAX_PARSE_DEPTH then
		fail(current(state), "maximum nesting depth exceeded")
	end
	local children: { Node } = {}
	while true do
		local token = current(state)
		if token.kind == "EOF" then
			if inGroup then
				fail(token, "missing closing brace")
			end
			if stopAtBracket then
				fail(token, "missing closing bracket for root index")
			end
			break
		elseif token.kind == "RBrace" then
			if not inGroup then
				fail(token, "unexpected closing brace")
			end
			advance(state)
			break
		elseif token.kind == "RBracket" and stopAtBracket then
			break
		elseif token.kind == "RBracket" then
			advance(state)
			table.insert(children, AST.glyph("]"))
		elseif token.kind == "LBracket" then
			table.insert(children, parseAtom(state))
		elseif token.kind == "Space" then
			advance(state)
		else
			table.insert(children, parseAtom(state))
		end
	end
	state.depth -= 1
	return AST.sequence(children)
end

function Parser.parse(source: string): Sequence
	local tokens = Lexer.tokenize(source)
	local state: State = { tokens = tokens, index = 1, depth = 0 }
	return parseSequence(state, false, false)
end

return Parser
