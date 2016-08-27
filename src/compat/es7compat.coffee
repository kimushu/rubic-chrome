# https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Array/includes
Array::includes or= (searchElement, fromIndex) ->
  o = Object(this)
  len = parseInt(o.length) or 0
  return false if len == 0
  n = parseInt(fromIndex) or 0
  k = if n > 0 then n else len + n
  k = 0 if k < 0
  while k < len
    currentElement = o[k]
    return true if searchElement == currentElement or
      (searchElement != searchElement && currentElement != currentElement)
    ++k
  return false

# https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/TypedArray/includes
Int8Array::includes         or= Array::includes
Uint8Array::includes        or= Array::includes
Uint8ClampedArray::includes or= Array::includes
Int16Array::includes        or= Array::includes
Uint16Array::includes       or= Array::includes
Int32Array::includes        or= Array::includes
Uint32Array::includes       or= Array::includes
Float32Array::includes      or= Array::includes
Float64Array::includes      or= Array::includes

# https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/ArrayBuffer/transfer
# FIXME: Currently this method does *not* detach oldBuffer
ArrayBuffer.transfer or= (oldBuffer, newByteLength) ->
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

