# https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Array/includes
unless Array::includes
  Array::includes = includes = (searchElement, fromIndex) ->
    o = Object(this)
    len = parseInt(o.length) || 0
    return false if len == 0
    n = parseInt(fromIndex) || 0
    k = if n > 0 then n else len + n
    k = 0 if k < 0
    while k < len
      currentElement = o[k]
      return true if searchElement == currentElement ||
        (searchElement != searchElement && currentElement != currentElement)
      ++k
    return false

# https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/TypedArray/includes
Int8Array::includes         ||= Array::includes
Uint8Array::includes        ||= Array::includes
Uint8ClampedArray::includes ||= Array::includes
Int16Array::includes        ||= Array::includes
Uint16Array::includes       ||= Array::includes
Int32Array::includes        ||= Array::includes
Uint32Array::includes       ||= Array::includes
Float32Array::includes      ||= Array::includes
Float64Array::includes      ||= Array::includes

# https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/ArrayBuffer/transfer
# FIXME: Currently this method does *not* detach oldBuffer
unless ArrayBuffer.transfer
  ArrayBuffer.transfer = (oldBuffer, newByteLength) ->
    unless oldBuffer instanceof ArrayBuffer
      throw new TypeError("oldBuffer must be an ArrayBuffer")
    oldByteLength = oldBuffer.byteLength
    newByteLength = oldbyteLength unless newByteLength?
    unless typeof(newByteLength) == "number"
      throw new TypeError("newByteLength must be a number")
    newBuffer = new ArrayBuffer(newByteLength)
    copyByteLength = Math.min(oldByteLength, newByteLength)
    new Uint8Array(newBuffer).set(new Uint8Array(oldBuffer, 0, copyByteLength))
    return newBuffer

