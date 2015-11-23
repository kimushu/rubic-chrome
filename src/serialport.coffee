# Serial I/O wrapper for Chrome App
# Reference: https://developer.chrome.com/apps/serial
# Target version: >= 33
class SerialPort extends Port
  Port.add(this)

  unless Uint8Array::findArray
    Uint8Array::findArray = (array, startIndex) ->
      startIndex or= 0
      for i in [startIndex..(this.byteLength - array.byteLength)]
        found = true
        for j in [0...array.byteLength]
          if array[j] and array[j] != this[i + j]
            found = false
            break
        return i if found
      return

  unless Uint8Array::toUtf8String
    Uint8Array::toUtf8String = ->
      return String.fromCharCode.apply(null, this)

  unless String::toArrayBuffer
    String::toArrayBuffer = ->
      return this.toUint8Array().buffer

  unless String::toUint8Array
    String::toUint8Array = ->
      array = new Uint8Array(this.length * 4)
      i = 0
      for j in [0...(this.length)]
        c = this.charCodeAt(j)
        if c > 0x7f
          # >= 2-byte
          if c > 0x7ff
            # >= 3-byte
            if c > 0xffff
              # == 4-byte
              array[i++] = 0x80 | ((c >>> 18) & 0x3f) | 0x70
            else
              # == 3-byte
              lead = 0x60
            array[i++] = 0x80 | ((c >>> 12) & 0x3f) | lead
            lead = 0x00
          else
            # == 2-byte
            lead = 0x40
          array[i++] = 0x80 | ((c >>> 6) & 0x3f) | lead
          lead = 0x00
          array[i++] = 0x80 | ((c >>> 0) & 0x3f)
        else
          # == 1-byte
          array[i++] = (c)
      return array.slice(0, i)

  ###*
  @private
  @static
  ###
  @_map: {}

  ###*
  Enumerate available serial ports
  @param {Function} callback  Callback ({Array} ports)
  ###
  @enumerate: (callback) ->
    chrome.serial.getDevices((ports) ->
      list = for port in ports
        {name: "#{port.path or port.displayName}", path: "#{port.path}"}
      callback?(list)
    )

  ###*
  Connect to serial port
  @param {String}   path
  @param {Object}   options
  @param {Function} callback  Callback ({Boolean} result, {SerialPort} connection)
  ###
  @connect: (path, options, callback) ->
    chrome.serial.connect(path, options, (connectionInfo) =>
      callback?(new this(path, connectionInfo))
    )

  ###*
  @private
  Constructor
  @param {String} path
  @param {Object} connectionInfo
  ###
  constructor: (@path, @connectionInfo) ->
    @cid = @connectionInfo.connectionId
    @constructor._map[@cid] = this
    return

  @_onReceive: (info) ->
    instance = @_map[info.connectionId]
    instance?._onReceive(info)
    return

  _onReceive: (info) ->
    # Append received data
    oldLength = (@receivedLength or= 0)
    @receivedLength += info.data.byteLength
    @receivedArray or= new Uint8Array(256)
    if @receivedLength > @receivedArray.byteLength
      newArray = new Uint8Array(@receivedArray.byteLength * 2)
      newArray.set(@receivedArray, 0)
      @receivedArray = newArray
    @receivedArray.set(new Uint8Array(info.data), oldLength)

    return unless @waitingToken

    # Search token
    if @waitingToken instanceof Uint8Array
      i = @receivedArray.findArray(@waitingToken, oldLength - @waitingToken.length)
      return unless i
      tokenLength = i + @waitingToken.byteLength
    else
      tokenLength = @waitingToken
    return unless tokenLength <= @receivedLength

    # Extract token
    tokenFound = @receivedArray.slice(0, tokenLength)
    remainder = @receivedArray.slice(tokenLength)
    @receivedArray.set(remainder)
    @receivedLength -= tokenLength
    receiver = @receiver
    @waitingToken = null
    @receiver = null
    receiver(tokenFound)
    return

  @_onReceiveError: (info) ->
    instance = @_map[info.connectionId]
    instance?._onReceiveError(info)
    return

  _onReceiveError: (info) ->
    # To release device, automatically disconnect
    @disconnect(-> return)
    return

  disconnect: (callback) ->
    unless @cid?
      callback(false)
      return
    chrome.serial.disconnect(@cid, (result) ->
      unless result
        callback(false)
        return
      delete @constructor._map[@cid]
      @cid = null
      @onDisconnected?()
      callback(true)
    )

  write: (data, callback) ->
    unless @cid?
      callback(false)
      return
    throw "illegal Serial#write" if @writing > 0
    @writing = data.byteLength
    chrome.serial.send(@cid, data, (sendInfo) ->
      if (sendInfo.error)
        callback?(false)
        @writing = 0
    )
    chrome.serial.flush(@cid, (result) ->
      # nothing to do
    )

  read: (token, callback) ->
    unless @cid?
      callback(false)
      return
    throw "illegal SerialPort#read" if @waitingToken
    @waitingToken = token
    @receiver = callback
    return

  $(=>
    chrome.serial.onReceive.addListener((info) => @_onReceive(info))
    chrome.serial.onReceiveError.addListener((info) => @_onReceiveError(info))
  )

