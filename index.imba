# Vendor-prefix normalizing

def contentify(value)
	var keyword = /^none|inherit|initial|unset|normal|open-quote|close-quote|no-open-quote|no-close-quote|(url|attr|counters?)\(.+|['"].+$/

	if keyword.test(value)
		value
	else
		value = value.replace(/["\\\n]/g) do |m| "\\" + m
		'"' + value + '"'

var compileCSS =
	if typeof window == "object"
		# Browser version

		let prefixes = ["Moz", "O", "ms", "Webkit"]
		let rewrites = {}

		var normalizeKey = do |key, style|
			if `key in style`
				return key

			let capitalKey = key.charAt(0).toUpperCase + key.substring(1)

			for prefix in prefixes
				let fullKey = prefix + capitalKey
				if `fullKey in style`
					return fullKey

			return key

		do |props|
			var doc = document.createElement("div")
			var style = doc:style

			for key, val of props
				var normKey = (rewrites[key] ||= normalizeKey(key, style))
				style[normKey] = val

			var text = style:cssText
			if props:content
				text += "content: {contentify(props:content)};"
			text

	else
		# Basic server-side version
		do |props|
			var code = ""
			for key, val of props
				var cssKey = key.replace(/([A-Z]+)/g) do |match|
					"-{match.toLowerCase}"
				val = contentify(val) if key == "content"
				code += "{cssKey}: {val};"
			code

class Builder
	var UNIQ = 0

	def initialize
		@groups = []
		@blockPatchers = {}
		@isFrozen = no

		defineBlock("main") do |code|
			code

	def defineBlock(name, code)
		@blockPatchers[name] = code

	def defineBlockAlias(from, to)
		defineBlock(from) do |code|
			"{to} \{ {code} \}"

	def freeze(code)
		@isFrozen = yes
		if code
			code()
			@isFrozen = no
		self

	def create(props, className)
		if @isFrozen
			throw Error.new("Styles have been frozen")

		className ||= "imba-st-{UNIQ++}"
		var sg = StyleGroup.new(className)
		sg.parent = delete props:parent
		sg.parse(props, "&", "main")
		@groups.push(sg)
		@result = null
		sg

	def insert(t, styles)
		var proto = t:prototype
		for key, props of styles
			var ivar = "_{key}"
			var group = create(props)
			group.parent = proto[ivar]
			proto[ivar] = group
		self

	def toString
		@result ||= build

	def build
		var allRuleSets = []
		var matchingSelectors = []

		for group in @groups
			# Follow the parent-chain
			var curr = group
			while curr
				for rs in curr.ruleSets
					var idx = allRuleSets.indexOf(rs)
					if idx == -1
						idx = allRuleSets:length
						allRuleSets[idx] = rs
						matchingSelectors[idx] = []
					matchingSelectors[idx].push(".{group.className}")
				curr = curr.parent

		var blocks = {}

		for rs, idx in allRuleSets
			var selectors = matchingSelectors[idx]
			blocks[rs.block] ||= ""
			blocks[rs.block] +=	rs.toCSS(selectors)

		var result = ""

		for key, value of blocks
			var patcher = @blockPatchers[key]

			var code = if patcher
				patcher(value, key)
			else
				"{key} \{ {value} \}"

			result += code

		result

class StyleGroup
	prop className
	prop parent
	prop ruleSets

	def initialize(className)
		@className = className
		@ruleSets = []

	def addRuleSet(rs)
		@ruleSets.push(rs)
		self

	def toString
		@className

	def parse(props, scope, block)
		var ruleProps = {}
		var isEmpty = yes

		for keyString, val of props
			var keys = keyString.split(/\s*,\s*/)
			for key in keys
				if key[0] == "@"
					parse(val, scope, key)
				elif key[0] == ":"
					parse(val, scope+key, block)
				elif /&/.test(key)
					scope = key.replace(/&/, scope)
					parse(val, scope, block)
				else
					ruleProps[key] = val
					isEmpty = no

		if not isEmpty
			var rs = RuleSet.new(ruleProps, scope: scope, block: block)
			addRuleSet(rs)

class RuleSet
	prop block
	prop scope
	prop code

	def initialize(props, options)
		@props = props
		@scope = options:scope
		@block = options:block
		@code = compileCSS(props)

	def toCSS(selectors)
		var scope = @scope
		var fullSelector = (scope.replace("&", sel) for sel in selectors).join(", ")
		"{fullSelector} \{ {@code} \}"

# Default buider
module:exports = Builder.new
export var Builder = Builder

