# Serial I/O wrapper for Chrome App
# Reference: https://developer.chrome.com/apps/serial
# Target version: >= 33
class SerialPort extends Port
  Port.add(this)

  ###*
  Enumerate available serial ports
  @param {Function} callback  Callback ({Array} ports)
  ###
  @enumerate: (callback) ->
    chrome.serial.getDevices((ports) ->
      list = for port in ports
        {name: port.displayName or port.path, path: port.path}
      callback(list)
    )

  ###*
  Connect to serial port
  @param {String}   path
  @param {Object}   options
  @param {Function} callback  Callback ({Boolean} result, {SerialPort} connection)
  ###
  @connect: (path, options, callback) ->
    chrome.serial.connect(path, options, (connectionInfo) =>
      callback(new this(path, connectionInfo))
    )

  ###*
  @private
  Constructor
  @param {String} path
  @param {Object} connectionInfo
  ###
  constructor: (@path, @connectionInfo) ->
    @cid = @connectionInfo.connectionId
    chrome.serial.onReceive.addListener((info) =>
      oldLength = @receivedLength
      @receivedLength += info.data.byteLength
      @receivedArray or= new Uint8Array(256)
      if @receivedLength > @receivedArray.byteLength
        newArray = new Uint8Array(@receivedArray.byteLength * 2)
        newArray.set(@receivedArray, 0)
        @receivedArray = newArray
      @receivedArray.set(new Uint8Array(info.data), oldLength)
      @dispatch(oldLength)
    )
    chrome.serial.onReceiveError.addListener((info) ->
      null
    )

  ###*
  @private
  @param {Number}       info.connectionId
  @param {ArrayBuffer}  info.data
  ###
  dispatch: (info) ->
    # Check connection ID
    return unless info.connectionId == @connectionInfo.connectionId

    # Append data
    newOffset = @receivedLength or 0
    @receivedLength = newOffset + info.data.byteLength
    newArray = new Uint8Array(@receivedLength)
    newArray.set(@receivedData, 0) if @receivedData
    newArray.set(info.data, newOffset)
    @receivedData = newArray.buffer

    # Search token
    tokenLength = null
    if @waitingToken instanceof Uint8Array
      lastOffset = @receivedLength - @waitingToken.byteLength
      for i in [newOffset...lastOffset]
        tokenLength = newOffset + @waitingToken.length
        for j in [0...@waitingToken.length]
          if newArray[i] != @waitingToken[j]
            tokenLength = null
            break
        break if tokenLength
    else
      tokenLength = @waitingToken
    return unless tokenLength and tokenLength >= @receivedLength

    # Extract token

    return unless @receivedLength >= 0 and @waiting and @callback
    #  from or= 0
    length = @waiting
    if length instanceof Uint8Array
      last = @receivedLength - @waiting.byteLength
      return unless last >= 0
      for i in [from..last]
        length = i + @waiting.byteLength
        for j in [0...@waiting.byteLength]
          unless @receivedArray[i+j] == waiting[j]
            length = null
            break
        break if length
      return unless length
    else
      return unless @receivedLength >= length
    buf = @receivedArray.buffer.slice(0, length)
    str = String.fromCharCode.apply(null, new Uint8Array(buf))
    @receivedLength -= length
    if @receivedLength > 0
      @receivedArray = new Uint8Array(@receivedArray.buffer.slice(length))
    else
      @receivedArray = null
    @callback(str)

  ###*
  @private
  @property {Number} cid
  Connection ID
  ###
  cid: null

  ###*
  @private
  @property {Uint8Array} receivedArray
  ArrayBufferView of received data
  ###
  receivedArray: null

  ###*
  @private
  @property {Number}  receivedLength
  Length of received data in bytes
  ###
  receivedLength: 0

  ###*
  @private
  @property {Uint8Array/Length} waitingToken
  Waiting token or length (in bytes)
  ###
  waitingToken: null

  ###*
  @private
  @property {Function} receiver
  Receiver function which is waiting new data
  ###
  receiver: null

  disconnect: (callback) ->
    chrome.serial.disconnect(@_cid, (result) ->
      callback() if result
    )

  write: (data, callback) ->
    throw "Illegal Serial#write" if @_write_pended
    @_write_pended = data.byteLength
    chrome.serial.send(@_cid, data, (sendInfo) ->
      @_write_pended -= sendInfo.bytesSent
      if (@_write_pended == 0)
        callback(true)
      else if (sendInfo.error)
        callback(false)
        @_write_pended = null
    )
    chrome.serial.flush(@_cid, (result) ->
      # nothing to do
    )

  read: (length, callback) ->
    throw "Illegal Serial#read" if @_read_buffer
    @_read_offset = 0
    @_read_buffer = new ArrayBuffer(length)

