# Serial I/O wrapper for Chrome App
# Reference: https://developer.chrome.com/apps/serial
# Target version: >= 33
class Serial
  @enumerate: (callback) ->
    chrome.serial.getDevices((ports) ->
      list = for port of ports
        {name: port.displayName, path: port.path}
      callback(list)
    )
    #debug
    callback([{name: "COM 99", path: "/path/to/ser99"}])

  @connect: (path, options, callback) ->
    chrome.serial.connect(path, options, (connectionInfo) ->
      instance = new Serial(path, connectionInfo)
      callback(instance)
    )

  # private
  constructor: (@path, @connectionInfo) ->
    @_cid = @connectionInfo.connectionId
    chrome.serial.onReceive.addListener((info) ->
      return unless @_read_buffer
      src = new Uint8Array(info.data)
      dst = new Uint8Array(@_read_buffer, @_read_offset, info.data.byteLength)
      dst[i] = src[i] for i in [0...src.byteLength]
      @_read_offset += src.byteLength
      if (@_read_offset >= @_read_buffer.byteLength)
        buffer = @_read_buffer
        @_read_buffer = null
        @_read_callback(buffer)
    )
    chrome.serial.onReceiveError.addListener((info) ->
      @_read_buffer = null
      @_read_callback(null)
    )

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

