require "imba"
var styles = require ".."
var test = require "tape"

test "basic styles" do |t|
	var s = styles.Builder.new

	var s1 = s.create
		font-weight: "bold"

	t.ok(s1.className, "class name is missing")

	var css = s.toString

	t.ok(css.indexOf(s1.className) != -1, "CSS doesn't include the class name")
	t.ok(css.indexOf("font-weight: bold") != -1, "CSS doesn't include the rules")

	t.end

test "media blocks" do |t|
	var s = styles.Builder.new

	var s1 = s.create
		width: "35px"

		"@media (max-width: 600px)":
			width: "30px"

	var css = s.toString
	var re = /max-width: 600px\) { [^}]+ width: 30px;/
	t.ok(re.test(css))
	t.end

test "media alias" do |t|
	var s = styles.Builder.new

	var s1 = s.create
		"@mobile":
			width: "30px"

	s.defineBlockAlias("@mobile", "@media (max-width: 600px)")

	var css = s.toString
	var re = /max-width: 600px\) { [^}]+ width: 30px;/
	t.ok(re.test(css))
	t.end

test "set parent with `parent` key" do |t|
	var s = styles.Builder.new

	var s1 = s.create
		font-weight: "bold"

	var s2 = s.create
		parent: s1
		color: "red"

	t.equal(s1, s2.parent)
	t.end

test "should work with dynamic flags" do |t|
	var s = styles.Builder.new
	var s1 = s.create({font-weight: "bold"}, "foo")

	var app = <div .{s1}>
	var re = /class="foo"/
	t.ok(re.test(app.toString))
	t.end