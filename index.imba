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

	def parse(props, options)
		let lines = []

		for key, val of props
			if key[0] == "@"
				let opt = Object.assign({block: key}, options)
				parse(val, opt)
			elif key[0] == ":"
				let opt = Object.assign({selector: options:selector+key}, options)
				parse(val, opt)
			else
				key = normalizeKey(key)
				val = normalizeValue(val, key)
				lines.push("{key}:{val}")

		if lines:length
			let group = Object.assign({code: lines.join(";")}, options)
			@groups.push(group)

	def normalizeKey(key)
		key.replace(/[A-Z]/) do |x|
			"-{x.toLowerCase}"

	let assumePixel = /margin|padding|border|left|right|top|bottom/

	def normalizeValue(val, key)
		if typeof val == 'number' and assumePixel.test(key)
			val + "px"
		else
			val
		
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
