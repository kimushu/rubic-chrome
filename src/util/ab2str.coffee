"use strict"
# Pre dependencies
# (none)

###*
@method ab2str
  Convert ArrayBuffer to string
@param {ArrayBuffer} source
  Source data
@param {string} [encoding="utf8"]
  Encoding
@return {Promise}
  Promise object
@return {string} return.PromiseValue
  Converted string
###
module.exports = ab2str = (source, encoding = "utf8") ->
  return new Promise((resolve, reject) ->
    return reject(TypeError("source is not an ArrayBuffer")) unless source instanceof ArrayBuffer
    blob = new Blob([source])
    reader = new FileReader()
    reader.onload = -> resolve(reader.result)
    reader.onerror = reject
    reader.readAsText(blob, encoding)
  ) # return new Promise()

# Post dependencies
# (none)
