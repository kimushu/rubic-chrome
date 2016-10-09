"use strict"
# Pre dependencies
require("util/primitive")

TR = ArrayBuffer.transfer or (oldBuffer, newByteLength = oldBuffer.byteLength) ->
  oldByteLength = oldBuffer.byteLength
  copyByteLength = Math.min(oldByteLength, newByteLength)
  newBuffer = new ArrayBuffer(newByteLength)
  new Uint8Array(newBuffer).set(new Uint8Array(oldBuffer, 0, copyByteLength))
  return newBuffer

MIN_CAPACITY = 256

module.exports = class FifoBuffer
  null

  ###*
  @property {number} byteLength
    Length of stored data in bytes
  @readonly
  ###
  @property("byteLength", get: -> @_byteLength)

  ###*
  @property {number} capacity
    Length of buffer in bytes
  @readonly
  ###
  @property("capacity", get: -> @_buffer.byteLength)

  ###*
  @method constructor
    Constructor of FifoBuffer class
  ###
  constructor: ->
    @_byteLength = 0
    @_buffer = new ArrayBuffer(MIN_CAPACITY)
    return

  ###*
  @method
    Append new data to buffer
  @param {TypedArray/ArrayBuffer} data
    Data to add
  @return {undefined}
  ###
  push: (data) ->
    if data instanceof ArrayBuffer
      array = new Uint8Array(data)
    else
      array = new Uint8Array(data.buffer, data.byteOffset, data.byteLength)
    alen = array.byteLength
    return unless alen > 0
    nlen = @_byteLength + alen
    @allocate(nlen)
    new Uint8Array(@_buffer, @_byteLength).set(array)
    @_byteLength = nlen
    return

  ###*
  @method
    Pick out data from buffer
  @param {number} byteLength
    Read length in bytes
  @return {ArrayBuffer}
    Read data
  ###
  shift: (byteLength) ->
    data = @peek(byteLength)
    rlen = data.byteLength
    @_byteLength -= rlen
    if @_byteLength > 0 and rlen > 0
      new Uint8Array(@_buffer).set(new Uint8Array(@_buffer, rlen, @_byteLength))
      @compact()
    return data

  ###*
  @method
    Read data from buffer
  @param {number} byteLength
    Read length in bytes
  @return {ArrayBuffer}
    Read data
  ###
  peek: (byteLength) ->
    if byteLength?
      byteLength = Math.min(@_byteLength, byteLength)
    else
      byteLength = @_byteLength
    return @_buffer.slice(0, byteLength)

  ###*
  @method
    Allocate (growth or reduce) buffer
  @param {number} capacity
    New capacity
  @return {undefined}
  ###
  allocate: (capacity) ->
    newCapacity = Math.max(@_byteLength, capacity) - 1
    newCapacity |= (newCapacity >>> 1)
    newCapacity |= (newCapacity >>> 2)
    newCapacity |= (newCapacity >>> 4)
    newCapacity |= (newCapacity >>> 8)
    newCapacity |= (newCapacity >>> 16)
    newCapacity = Math.max(MIN_CAPACITY, newCapacity + 1)
    oldCapacity = @_buffer.byteLength
    return if newCapacity == oldCapacity
    newBuffer = new ArrayBuffer(newCapacity)
    new Uint8Array(newBuffer).set(new Uint8Array(@_buffer, 0, @_byteLength))
    @_buffer = newBuffer
    return

  ###*
  @method
    Compactize buffer
  @return {undefined}
  ###
  compact: ->
    @allocate(0)
    return

  ###*
  @method
    Reset buffer
  @return {undefined}
  ###
  reset: ->
    @_byteLength = 0
    @compact()
    return

# Post dependencies
# (none)
