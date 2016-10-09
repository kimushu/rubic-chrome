# Rubic Coding Rules
## CoffeeScript
### Basic rules
* Indent
  * Use "two spaces" (Do not use TABs)

### Grammertical naming rules
|Target       |Attribute             |Rules                           |
|-------------|----------------------|--------------------------------|
|Class name   |\*                    |UpperCamelCase                  |
|Method name  |public/protected      |lowerCamelCase                  |
|Method name  |private               |\_lowerCamelCase with underscore|
|Variable name|local/public/protected|lowerCamelCase                  |
|Variable name|private               |\_lowerCamelCase with underscore|

### Lexical naming rules
|Word  |Description                    |Example                  |
|------|-------------------------------|-------------------------|
|get   |Get some data synchronously    |val = getData()          |
|set   |Set some data synchronously    |setData(val)             |
|load  |Load some data asynchronously  |load().then((val) => ...)|
|store |Store some data asynchronously |store(val).then(=> ...)  |

