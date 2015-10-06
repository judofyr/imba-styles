var STYLES = []
let ID = 0

class StyleSet
	prop className
	prop groups

	def initialize(props)
		@groups = []
		@className = "imba-styles-" + (ID++)

		let options =
			selector: ".{@className}"

		parse(props, options)

	let prefixes = ["Moz", "O", "ms", "Webkit"]
	let rewrites = {}

	let normalizeKey = do |key, style|
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

	def parse(props, options)
		let doc = document.createElement("div")
		let style = doc:style

		for key, val of props
			if key[0] == "@"
				let opt = Object.assign({}, options, block: key)
				parse(val, opt)
			elif key[0] == ":"
				let opt = Object.assign({}, options, selector: options:selector+key)
				parse(val, opt)
			else
				key = normalizeKey(key, style)
				style[key] = val

		let group = Object.assign({code: style:cssText}, options)
		@groups.push(group)

let isFrozen = no
let result = null

let css = do |props|
	if isFrozen
		throw Error.new("styles have been frozen")

	Object.freeze(props)
	let s = StyleSet.new(props)
	STYLES.push(s)
	result = null # invalidate the result from toString
	s

module.exports = exports = css

# We want `import css from "imba-styles"` to work as well
export var css = css

export def freeze
	isFrozen = yes

export def toString
	if result
		return result

	let blocks = {}
	let main = ""

	for s in STYLES
		for group in s.groups
			let code = "{group:selector}\{{group:code}\}"

			if group:block
				blocks[group:block] = (blocks[group:block] or "") + code
			else
				main += code

	for name, val of blocks
		main += "{name}\{{val}\}"

	result = main
	return main


extend tag htmlelement
	let flatten = do |styles, res = []|
		if !styles
			return res

		if styles isa Array
			for s in styles
				flatten(s, res)
		else
			res.push(styles)

		return res
		

	def setStyles newStyles
		newStyles = flatten(newStyles)

		var idx = 0

		if @styles
			# Find the common prefix
			while idx < newStyles:length
				if @styles[idx] !== newStyles[idx]
					break
				idx += 1

			# Then remove everything that was there
			let oldIdx = idx
			while oldIdx < @styles:length
				unflag(@styles[oldIdx].className)
				oldIdx += 1

		# And flag the new classes
		while idx < newStyles:length
			flag(newStyles[idx].className)
			idx += 1

		@styles = newStyles

		self
