# imba-styles

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
            <div class=@header-css> object.title
            <div class=@body-css> object.body

tag main
    def render
        <self>
            <style> styles.toString
            <article>
```
