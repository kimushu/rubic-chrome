"use strict"
# Pre dependencies
# (none)

TR = ArrayBuffer.transfer or (oldBuffer, newByteLength = oldBuffer.byteLength) ->
  oldByteLength = oldBuffer.byteLength
  copyByteLength = Math.min(oldByteLength, newByteLength)
  newBuffer = new ArrayBuffer(newByteLength)
  new Uint8Array(newBuffer).set(new Uint8Array(oldBuffer, 0, copyByteLength))
  return newBuffer

MIN_CAPACITY = 256

module.exports = class FifoBuffer
  SB = Symbol("Buffer")
  SF = Symbol("FirstPart")
  SS = Symbol("SecondPart")

  Object.defineProperty(@prototype, "byteLength", get: ->
    return (@[SF]?.byteLength or 0) + (@[SS]?.byteLength or 0)
  )

  Object.defineProperty(@prototype, "capacity", get: ->
    return @[SB].byteLength
  )

  constructor: ->
    @[SB] = new ArrayBuffer(0)
    @[SF] = null
    @[SS] = null
    return

  push: (data) ->
    data = new Uint8Array(data) unless data instanceof Uint8Array
    alen = data.byteLength
    return if alen == 0

    # Extend buffer size
    @extend(@byteLength + alen)

    foff = @[SF]?.byteOffset or 0
    flen = @[SF]?.byteLength or 0
    slen = @[SS]?.byteLength or 0
    if slen > 0
      # Extend second part only
      (@[SS] = new Uint8Array(@[SB], 0, slen + alen)).set(data, slen)
    else
      # Extend first part
      frem = @[SB].byteLength - (foff + flen)
      fadd = Math.min(alen, frem)
      (@[SF]= new Uint8Array(@[SB], foff, flen + fadd)).set(data, foff + flen)
      alen -= fadd
      if alen > 0
        # Create second part
        (@[SS] = new Uint8Array(@[SB], 0, alen)).set(data.subarray(fadd), 0)
    return

  pop: (byteLength) ->
    if byteLength?
      byteLength = Math.min(byteLength, @byteLength)
    else
      byteLength = @byteLength
    array = new Uint8Array(byteLength)
    if byteLength > 0
      flen = @[SF].byteLength
      fpop = Math.min(byteLength, flen)
      # Copy from first part
      array.set(@[SF].subarray(0, fpop), 0)
      byteLength -= fpop
      if byteLength > 0
        # Switch to second part
        array.set(@[SS].subarray(0, byteLength), fpop)
        slen = @[SS].byteLength - byteLength
        if slen > 0
          @[SF] = @[SS].subarray(byteLength, slen)
        else
          @[SF] = null
        @[SS] = null
      else
        flen -= fpop
        if flen > 0
          @[SF] = @[SF].subarray(fpop, flen)
        else
          @[SF] = null
    return array.buffer

  peek: (byteLength) ->
    if byteLength?
      byteLength = Math.max(0, Math.min(byteLength, @byteLength))
    else
      byteLength = @byteLength
    array = new Uint8Array(byteLength)
    if byteLength > 0
      flen = @[SF].byteLength
      fpek = Math.min(byteLength, flen)
      # Copy from first part
      array.set(@[SF].subarray(0, fpek), 0)
      byteLength -= fpek
      if byteLength > 0
        # Copy from second part
        array.set(@[SS].subarray(0, byteLength), fpek)
    return array.buffer

  extend: (byteLength) ->
    newCapacity = @[SB].byteLength
    return if byteLength <= newCapacity
    newCapacity or= MIN_CAPACITY
    newCapacity *= 2 while newCapacity < byteLength
    foff = @[SF]?.byteOffset
    flen = @[SF]?.byteLength or 0
    slen = @[SS]?.byteLength or 0
    @[SF] = null
    @[SS] = null
    @[SB] = TR(@[SB], newCapacity)
    @[SF] = new Uint8Array(@[SB], foff, flen + slen) if flen > 0
    @[SF].set(new Uint8Array(@[SB], 0, slen), foff + flen) if slen > 0
    return

  clear: ->
    @[SB] = TR(@[SB], 0)
    @[SF] = null
    @[SS] = null
    return

# Post dependencies
# (none)
