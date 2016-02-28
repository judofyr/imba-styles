require "imba"

var styles = require ".."
var test = require "tape"

extern phantom

test.onFinish do
	var exitCode = test.getHarness.@exitCode
	if typeof phantom == "object"
		phantom.exit(exitCode)

test "basic styles" do |t|
	var s = styles.Builder.new

	tag hello1
		s.insert self,
			header-css:
				font-size: "28px"
				font-weight: "bold"


		def render
			<self>
				<style> s.toString
				<@header .{@header-css}> "Hello"

		def verify
			var style = window.getComputedStyle(@header.dom)
			t.equal(style:fontSize, "28px")
			t.equal(style:fontWeight, "bold")

	var app = <hello1>
	document:body.appendChild(app.dom)
	app.verify
	t.end

test "content pseudo class" do |t|
	var s = styles.Builder.new

	tag hello2
		s.insert self,
			header-css:
				":after":
					content: "World"

		def render
			<self>
				<style> s.toString
				<@header .{@header-css}> "Hello"

		def verify
			var style = window.getComputedStyle(@header.dom, ":after")
			t.equal(style:content, "World")

	var app = <hello2>
	document:body.appendChild(app.dom)
	app.verify
	t.end



