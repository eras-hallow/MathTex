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
	source: string,
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

local parseSequence: (state: State, inGroup: boolean, stopAtBracket: boolean?, stopAtRight: boolean?, stopAtMatrix: boolean?) -> Sequence
local parseAtom: (state: State) -> Node
local parsePrimary: (state: State) -> Node
local parseRequiredGroup: (state: State, command: Token) -> Sequence

local function parseTextArgument(state: State, command: Token): Node
	skipWhitespace(state)
	local opening = current(state)
	if opening.kind ~= "LBrace" then
		fail(opening, "\\" .. command.value .. " expects a braced argument")
	end
	advance(state)
	local contentStart = opening.position + 1
	local nestedBraces = 0
	while true do
		local token = current(state)
		if token.kind == "EOF" then
			fail(token, "missing closing brace for \\" .. command.value)
		elseif token.kind == "LBrace" then
			nestedBraces += 1
			advance(state)
		elseif token.kind == "RBrace" then
			if nestedBraces == 0 then
				local content = string.sub(state.source, contentStart, token.position - 1)
				advance(state)
				return AST.text(content)
			end
			nestedBraces -= 1
			advance(state)
		else
			advance(state)
		end
	end
end

local function parseDelimiter(state: State, command: Token): string
	skipWhitespace(state)
	local token = advance(state)
	if token.kind == "Character" or token.kind == "Operator" then
		return if token.value == "." then "" else token.value
	elseif token.kind == "LBracket" then
		return "["
	elseif token.kind == "RBracket" then
		return "]"
	elseif token.kind == "Command" then
		local delimiters = {
			["."] = "",
			["{"] = "{",
			["}"] = "}",
			vert = "|",
			Vert = "‖",
			lVert = "‖",
			rVert = "‖",
			langle = "⟨",
			rangle = "⟩",
		}
		local delimiter = delimiters[token.value]
		if delimiter ~= nil then
			return delimiter
		end
		local symbol = Symbols.get(token.value)
		if symbol ~= nil then
			return symbol.text
		end
	end
	fail(token, "\\" .. command.value .. " expects a supported delimiter")
end

local function readEnvironmentName(state: State, command: Token): string
	local group = parseRequiredGroup(state, command)
	local parts: { string } = {}
	for _, node in group.children do
		if node.kind ~= "Glyph" then
			fail(command, "environment name must contain plain letters")
		end
		table.insert(parts, node.text)
	end
	return table.concat(parts)
end

local function parseMatrixEnvironment(state: State, command: Token): Node
	local environments = {
		matrix = { "", "" },
		pmatrix = { "(", ")" },
		bmatrix = { "[", "]" },
		Bmatrix = { "{", "}" },
		vmatrix = { "|", "|" },
		Vmatrix = { "‖", "‖" },
		cases = { "{", "" },
	}
	local environmentName = readEnvironmentName(state, command)
	local delimiters = environments[environmentName]
	if delimiters == nil then
		fail(command, "unsupported environment '" .. environmentName .. "'")
	end

	local rows: { AST.MatrixRow } = {}
	local row: AST.MatrixRow = {}
	local columnCount: number? = nil
	local function finishRow(token: Token)
		if columnCount == nil then
			columnCount = #row
		elseif #row ~= columnCount then
			fail(token, "matrix rows must have the same number of columns")
		end
		table.insert(rows, row)
	end

	while true do
		local cell = parseSequence(state, false, false, false, true)
		table.insert(row, cell)
		local token = current(state)
		if token.kind == "Character" and token.value == "&" then
			advance(state)
		elseif token.kind == "Command" and token.value == "\\" then
			advance(state)
			finishRow(token)
			row = {}
			if current(state).kind == "Command" and current(state).value == "end" then
				local endCommand = advance(state)
				local endName = readEnvironmentName(state, endCommand)
				if endName ~= environmentName then
					fail(endCommand, "expected \\end{" .. environmentName .. "}")
				end
				break
			end
		elseif token.kind == "Command" and token.value == "end" then
			advance(state)
			finishRow(token)
			local endName = readEnvironmentName(state, token)
			if endName ~= environmentName then
				fail(token, "expected \\end{" .. environmentName .. "}")
			end
			break
		else
			fail(token, "expected '&', '\\\\', or \\end{" .. environmentName .. "}")
		end
	end

	local matrix = AST.matrix(rows)
	return AST.delimited(delimiters[1], AST.sequence({ matrix }), delimiters[2])
end

parseRequiredGroup = function(state: State, command: Token): Sequence
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
		if token.value == "text" or token.value == "operatorname" then
			return parseTextArgument(state, token)
		elseif token.value == "left" then
			local left = parseDelimiter(state, token)
			local body = parseSequence(state, false, false, true)
			local rightCommand = current(state)
			if rightCommand.kind ~= "Command" or rightCommand.value ~= "right" then
				fail(rightCommand, "missing \\right for \\left")
			end
			advance(state)
			local right = parseDelimiter(state, rightCommand)
			return AST.delimited(left, body, right)
		elseif token.value == "right" then
			fail(token, "\\right has no matching \\left")
		elseif token.value == "begin" then
			return parseMatrixEnvironment(state, token)
		elseif token.value == "end" then
			fail(token, "\\end has no matching \\begin")
		elseif token.value == "frac" then
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
			return AST.glyph(symbol.text, symbol.operatorStyle)
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

parseSequence = function(state: State, inGroup: boolean, stopAtBracket: boolean?, stopAtRight: boolean?, stopAtMatrix: boolean?): Sequence
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
			if stopAtRight then
				fail(token, "missing \\right for \\left")
			end
			if stopAtMatrix then
				fail(token, "missing \\end for matrix environment")
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
		elseif token.kind == "Command" and token.value == "right" and stopAtRight then
			break
		elseif stopAtMatrix and token.kind == "Character" and token.value == "&" then
			break
		elseif stopAtMatrix and token.kind == "Command" and (token.value == "\\" or token.value == "end") then
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
	local state: State = { source = source, tokens = tokens, index = 1, depth = 0 }
	return parseSequence(state, false, false)
end

return Parser
