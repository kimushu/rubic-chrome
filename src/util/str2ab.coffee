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
    if Blob? and FileReader?
      blob = new Blob([source], {type: "text/plain;charset=#{encoding}"})
      reader = new FileReader()
      reader.onload = -> resolve(reader.result)
      reader.onerror = reject
      reader.readAsArrayBuffer(blob)
    else
      array = new Uint8Array(source.length * 4)
      o = 0
      for i in [0...source.length] by 1
        c = source.charCodeAt(i)
        if c <= 0x7f
          array[o++] = c
        else if c <= 0x7ff
          array[o++] = 0xc0 | (c >>> 6)
          array[o++] = 0x80 | (c & 0x3f)
        else if c <= 0xffff
          array[o++] = 0xe0 | (c >>> 12)
          array[o++] = 0x80 | ((c >>> 6) & 0x3f)
          array[o++] = 0x80 | (c & 0x3f)
        else
          array[o++] = 0xf0 | (c >>> 18)
          array[o++] = 0x80 | ((c >>> 12) & 0x3f)
          array[o++] = 0x80 | ((c >>> 6) & 0x3f)
          array[o++] = 0x80 | (c & 0x3f)
      resolve(array.buffer.slice(0, o))
  ) # return new Promise()

module.exports = str2ab

# Post dependencies
# (none)
