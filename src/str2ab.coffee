# Pre dependencies
# (none)

###*
@method
  Convert string to ArrayBuffer
@param {string} source
  Source data
@param {string} [encoding="utf8"]
  Encoding
@return {Promise}
  Promise object
@return {ArrayBuffer} return.PromiseValue
  Converted data
###
str2ab = (source, encoding = "utf8") ->
  return new Promise((resolve, reject) ->
    return reject(TypeError("source is not a string")) unless typeof(source) == "string"
    blob = new Blob([source], {type: "text/plain;charset=#{encoding}"})
    reader = new FileReader()
    reader.onload = -> resolve(reader.result)
    reader.onerror = reject
    reader.readAsArrayBuffer(blob)
  ) # return new Promise()

module.exports = str2ab

# Post dependencies
# (none)
