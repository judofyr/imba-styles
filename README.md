# imba-styles (1.5kB min+gzip)

Write CSS in Imba/JavaScript:

```imba
var styles = require "imba-styles"

tag article
    styles.insert self,
        header-css:
            font-weight: "bold"
            font-size: "28px"
            margin-bottom: "0.5em"

        body-css:
            "& p":
                margin-bottom: "1em"

    def render
        <self>
            <div .{@header-css}> object.title
            <div .{@body-css}> object.body

tag main
    def render
        <self>
            <style> styles.toString
            <article>
```

## Usage in JavaScript

You can also use `imba-styles` in plain JavaScript projects:

```javascript
var styles = require("imba-styles")

var header = styles.create({
  fontWeight: "bold",
  fontSize: "28px",
  marginBottom: "0.5em"
});

var customHeader = styles.create({
  parent: header,
  color: "red"
})

class HelloWorld extends React.Component {
  render() {
    return <div>
      <style>{styles.toString()}</style>
      <div className={customHeader.className()}>Hello world</div>
    </div
  }
}
```
