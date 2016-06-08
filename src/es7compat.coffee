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

