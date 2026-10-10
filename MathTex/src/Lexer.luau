--!strict

local Lexer = {}

export type TokenKind = "Command" | "Number" | "Character" | "Operator" | "LBrace" | "RBrace" | "LBracket" | "RBracket" | "Superscript" | "Subscript" | "Space" | "EOF"
export type Token = { kind: TokenKind, value: string, position: number }

local function isDigit(byte: number): boolean
	return byte >= 48 and byte <= 57
end

local function isLetter(byte: number): boolean
	return (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122)
end

function Lexer.tokenize(source: string): { Token }
	local _, invalidPosition = utf8.len(source)
	if invalidPosition ~= nil then
		error(string.format("MathTex lexer: invalid UTF-8 at position %d", invalidPosition), 0)
	end
	local tokens: { Token } = {}
	local index = 1
	local length = #source

	while index <= length do
		local position = index
		local byte = string.byte(source, index)
		local character = string.sub(source, index, index)

		if character == "\\" then
			index += 1
			if index > length then
				error(string.format("MathTex lexer: trailing backslash at position %d", position), 0)
			end

			local commandStart = index
			local nextByte = string.byte(source, index)
			if isLetter(nextByte) then
				repeat
					index += 1
					nextByte = if index <= length then string.byte(source, index) else 0
				until not isLetter(nextByte)
				table.insert(tokens, {
					kind = "Command",
					value = string.sub(source, commandStart, index - 1),
					position = position,
				})
			else
				local nextPosition = utf8.offset(source, 2, index) or length + 1
				local escaped = string.sub(source, index, nextPosition - 1)
				index = nextPosition
				table.insert(tokens, { kind = "Command", value = escaped, position = position })
			end
		elseif isDigit(byte) then
			repeat
				index += 1
				byte = if index <= length then string.byte(source, index) else 0
			until not isDigit(byte)
			table.insert(tokens, {
				kind = "Number",
				value = string.sub(source, position, index - 1),
				position = position,
			})
		elseif character == "{" then
			table.insert(tokens, { kind = "LBrace", value = character, position = position })
			index += 1
		elseif character == "}" then
			table.insert(tokens, { kind = "RBrace", value = character, position = position })
			index += 1
		elseif character == "[" then
			table.insert(tokens, { kind = "LBracket", value = character, position = position })
			index += 1
		elseif character == "]" then
			table.insert(tokens, { kind = "RBracket", value = character, position = position })
			index += 1
		elseif character == "^" then
			table.insert(tokens, { kind = "Superscript", value = character, position = position })
			index += 1
		elseif character == "_" then
			table.insert(tokens, { kind = "Subscript", value = character, position = position })
			index += 1
		elseif string.find("+-=*/<>|", character, 1, true) ~= nil then
			table.insert(tokens, { kind = "Operator", value = character, position = position })
			index += 1
		elseif string.match(character, "%s") ~= nil then
			repeat
				index += 1
				character = string.sub(source, index, index)
			until index > length or string.match(character, "%s") == nil
			table.insert(tokens, {
				kind = "Space",
				value = string.sub(source, position, index - 1),
				position = position,
			})
		else
			local nextPosition = utf8.offset(source, 2, index) or length + 1
			table.insert(tokens, {
				kind = "Character",
				value = string.sub(source, index, nextPosition - 1),
				position = position,
			})
			index = nextPosition
		end
	end

	table.insert(tokens, { kind = "EOF", value = "", position = length + 1 })
	return tokens
end

return Lexer
