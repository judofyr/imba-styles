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

