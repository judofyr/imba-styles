module:exports = require "./core"

require "imba"

extend tag htmlelement
	def setClass(val)
		if typeof val:className == "function"
			val = val.className
		flag(val)
		self