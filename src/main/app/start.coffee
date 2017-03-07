"use strict"
#================================================================
# Main-process entry
#================================================================

# Get arguments
if process.argv0.match(/\belectron(?:\.exe)?$/i)
  args = process.argv.slice(2)  # Skip electron(.exe) and path
else
  args = process.argv.slice(1)  # Skip binary name only

# Parse options
options = {files: []}
index = 0
while index < args.length
  key = args[index]
  val = args[index + 1]
  if !key.startsWith("-")
    options.files.push(key)
  else if (val ? "").startsWith("-")
    options[key] = val
    index += 1
  else
    options[key] = true
  index += 1

# Start Rubic
require("./rubic-application").open(options)
return
