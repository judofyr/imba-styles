# Vendor-prefix normalizing
require "imba"

let prefixes = ["Moz", "O", "ms", "Webkit"]
let rewrites = {}

def assign(target, *sources)
	for source in sources
		for key, val of source
			target[key] = val
	target

def normalizeKey(key, style)
	if `key in rewrites`
		return rewrites[key]

	if `key in style`
		return rewrites[key] = key

	let capitalKey = key.charAt(0).toUpperCase + key.substring(1)

	for prefix in prefixes
		let fullKey = prefix + capitalKey
		if `fullKey in style`
			return rewrites[key] = fullKey

	return rewrites[key] = key

var buildCss = do |props|
	var doc = document.createElement("div")
	var style = doc:style

	for key, val of props
		var normKey = normalizeKey(key, style)
		style[normKey] = val

	style:cssText

if typeof window != 'object'
	# TODO: Support auto-prefixes?
	buildCss = do |props|
		var code = ""
		for key, val of props
			var cssKey = key.replace(/([A-Z]+)/g) do |match|
				"-{match.toLowerCase}"
			code += "{cssKey}:{val};"
		code

var isIgnoring = no
var RULESETS = []

class RuleSet
	prop block

	def initialize(props, options)
		@selectors = []
		@scope = options:scope || ""
		@block = options:block || "main"
		@code = buildCss(props)

		RULESETS.push(self) if !isIgnoring

	def addSelector(sel)
		@selectors.push(sel)
		self

	def toString
		if @selectors:length == 0
			""
		else
			var fullSelector = (@scope.replace(/&/, sel) for sel in @selectors)
			"{fullSelector.join(",")} \{ {@code} \}"

class StyleGroup
	prop className
	prop groups

	def initialize(props, name)
		@className = name
		@rules = []

		let options = {scope: "&"}
		parse(props, options)

	def addRule(rule)
		@rules.push(rule)
		rule.addSelector(".{@className}")
		self

	def setParent(parent)
		if parent
			parent.includeInto(self)

	def includeInto(other)
		for rule in @rules
			other.addRule(rule)

	def parse(props, options)
		var ruleProps = {}
		var isEmpty = yes

		for keyString, val of props
			var keys = keyString.split(/\s*,\s*/)
			for key in keys
				if key[0] == "@"
					let opt = assign({}, options, block: key)
					parse(val, opt)
				elif key[0] == ":"
					let opt = assign({}, options, scope: options:scope+key)
					parse(val, opt)
				elif /&/.test(key)
					let opt = assign({}, options, scope: key.replace(/&/, options:scope))
					parse(val, opt)
				else
					ruleProps[key] = val
					isEmpty = no

		if not isEmpty
			addRule RuleSet.new(ruleProps, options)

let isFrozen = no
let result = null

let css = do |t, styles|
	if isFrozen
		throw Error.new("Styles have been frozen")

	result = null

	var proto = t:prototype
	for key, props of styles
		var ivar = "_{key}"
		var name = "__{t:name or t.@name}__{key}".replace(/-/g, "_")
		var group = StyleGroup.new(props, name)
		group.parent = proto[ivar]
		proto[ivar] = group

module.exports = exports = css

# We want `import css from "imba-styles"` to work as well
export var css = css

export def freeze
	isFrozen = yes

export def ignore(code)
	isIgnoring = yes
	if code
		code()
		isIgnoring = no

var blockAlias = {}

export def aliasBlock(from, to)
	blockAlias[from] = to

export def toString
	if result
		return result

	var blocks = {}

	for rule in RULESETS
		var prev = blocks[rule.block] || ""
		blocks[rule.block] = prev + rule.toString

	result = ""

	for key of blocks
		var val = blocks[key]
		key = blockAlias[key] || key

		if key == "main"
			result = val + result
		else
			result += "{key} \{ {val} \}"

	return result


extend tag htmlelement
	def setClass(val)
		if val:className
			val = val.className
		flag(val)
		self
