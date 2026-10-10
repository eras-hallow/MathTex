--!strict

local Symbols = {}

export type SymbolMetadata = { text: string }

local registry: { [string]: SymbolMetadata } = {
	alpha = { text = "α" }, beta = { text = "β" }, gamma = { text = "γ" }, delta = { text = "δ" },
	epsilon = { text = "ε" }, theta = { text = "θ" }, lambda = { text = "λ" }, mu = { text = "μ" },
	pi = { text = "π" }, rho = { text = "ρ" }, sigma = { text = "σ" }, tau = { text = "τ" },
	phi = { text = "φ" }, chi = { text = "χ" }, psi = { text = "ψ" }, omega = { text = "ω" },
	Gamma = { text = "Γ" }, Delta = { text = "Δ" }, Theta = { text = "Θ" }, Lambda = { text = "Λ" },
	Pi = { text = "Π" }, Sigma = { text = "Σ" }, Phi = { text = "Φ" }, Omega = { text = "Ω" },
	times = { text = "×" }, cdot = { text = "·" }, pm = { text = "±" }, mp = { text = "∓" },
	div = { text = "÷" }, ast = { text = "∗" }, circ = { text = "∘" },
	le = { text = "≤" }, leq = { text = "≤" }, ge = { text = "≥" }, geq = { text = "≥" },
	neq = { text = "≠" }, ne = { text = "≠" }, approx = { text = "≈" }, equiv = { text = "≡" },
	["in"] = { text = "∈" }, notin = { text = "∉" }, subset = { text = "⊂" }, subseteq = { text = "⊆" },
	to = { text = "→" }, rightarrow = { text = "→" }, leftarrow = { text = "←" },
	Rightarrow = { text = "⇒" }, Leftarrow = { text = "⇐" }, mapsto = { text = "↦" },
	infty = { text = "∞" }, partial = { text = "∂" }, nabla = { text = "∇" },
	forall = { text = "∀" }, exists = { text = "∃" }, emptyset = { text = "∅" },
	sum = { text = "∑" }, prod = { text = "∏" }, int = { text = "∫" },
	["%"] = { text = "%" }, ["{"] = { text = "{" }, ["}"] = { text = "}" },
	["_"] = { text = "_" }, ["^"] = { text = "^" }, ["$"] = { text = "$" },
	["#"] = { text = "#" }, ["&"] = { text = "&" },
}

local spacingCommands: { [string]: number } = {
	[","] = 0.22,
	[":"] = 0.33,
	[";"] = 0.44,
	" " = 0.33,
	quad = 1,
	qquad = 2,
	["!"] = -0.16,
}

function Symbols.get(name: string): SymbolMetadata?
	return registry[name]
end

function Symbols.getSpacing(name: string): number?
	return spacingCommands[name]
end

function Symbols.register(name: string, metadata: SymbolMetadata)
	assert(type(name) == "string" and string.match(name, "^[A-Za-z]+$") ~= nil, "Symbol name must contain only letters")
	assert(type(metadata) == "table" and type(metadata.text) == "string" and metadata.text ~= "", "Symbol metadata must contain non-empty text")
	assert(registry[name] == nil, "Symbol is already registered: \\" .. name)
	registry[name] = { text = metadata.text }
end

return Symbols
