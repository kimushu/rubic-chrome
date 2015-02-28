class MemHttpRequest
  DEBUG = 0

  # XMLHttpRequest compatible constants
  @UNSENT:            XMLHttpRequest.UNSENT
  @OPENED:            XMLHttpRequest.OPENED
  @HEADERS_RECEIVED:  XMLHttpRequest.HEADERS_RECEIVED
  @LOADING:           XMLHttpRequest.LOADING
  @DONE:              XMLHttpRequest.DONE
  UNSENT:             @UNSENT
  OPENED:             @OPENED
  HEADERS_RECEIVED:   @HEADERS_RECEIVED
  LOADING:            @LOADING
  DONE:               @DONE

  #------------------------------------------------
  # XMLHttpRequest compatible members
  #
  onloadstart: null
  onprogress: null
  onabort: null
  onerror: null
  onload: null
  ontimeout: null
  onloadend: null
  onreadystatechange: null

  ###*
  @property {Number} readyState
  @readonly
  Attribute for XMLHttpRequest compatibility.
  ###
  readyState: @UNSENT

  ###*
  @method open
  @param {String} method    Request method (GET/POST/etc.)
  @param {String} url       Request URL (http://xx/yy/zz?query)
  @return {void}
  Method for XMLHttpRequest compatibility.
  But no sync mode and no user authentication.
  ###
  open: (method, url) ->
    parser = document.createElement("a")
    parser.href = url
    throw new TypeError("Unsupported protocol") unless parser.protocol == "http:"
    @requestMethod = "#{method}".toUpperCase()
    @requestStartLine = "\
    #{@requestMethod} #{encodeURI(parser.pathname + parser.search)} HTTP/1.1\r\n\
    "
    @requestHeaders = {host: ["Host", encodeURI(parser.hostname)]}
    console.log({"MemHttpRequest#open": this}) if DEBUG > 0
    @sendFlag = false
    @changeState(@OPENED)
    null

  ###*
  @method setRequestHeader
  @param {String} header    Header string (ex: User-Agent)
  @param {String} value     Value string
  @return {void}
  Method for XMLHttpRequest compatibility.
  ###
  setRequestHeader: (header, value) ->
    unless @readyState == @OPENED and @sendFlag == false
      throw new Error("InvalidStateError")
    key = "#{header}".toLowerCase()
    if @requestHeaders[key]
      @requestHeaders[key][1] = "#{value}"
    else
      @requestHeaders[key] = ["#{header}", "#{value}"]
    null

  ###*
  @property {Number} timeout
  Attribute for XMLHttpRequest compatibility.
  ###
  timeout: 0

  ###*
  @property {Boolean} withCredentials
  Attribute for XMLHttpRequest compatibility. But not supported.
  ###
  withCredentials: false  # not supported

  ###*
  @property {Object} upload
  Attribute for XMLHttpRequest compatibility. But not supported.
  ###
  upload: null            # not supported

  ###*
  @method send
  @param {Uint8Array/String} data  Request body
  @return {void}
  Method for XMLHttpRequest compatibility.
  Supported type of data are Uint8Array and String only.
  ###
  send: (data) ->
    unless @readyState == @OPENED and @sendFlag == false
      throw new Error("InvalidStateError")
    data = null if @requestMethod == "GET" or @requestMethod == "HEAD"
    if data instanceof Uint8Array
      contentType = "application/octet-stream"
    else if data instanceof String
      contentType = "text/plain;charset=UTF-8"
    else unless data?
      contentType = null
    else
      throw new TypeError("Unsupported data type")
    @sendFlag = true
    @requestHeaders["content-type"] or= ["Content-Type", contentType] if contentType?
    sendArrayBuffer = (buffer) =>
      dataLength = if buffer? then buffer.byteLength else 0
      @requestHeaders["content-length"] or= ["Content-Length", "#{dataLength}"]
      request = @requestStartLine
      request += "#{pair[0]}: #{pair[1]}\r\n" for key, pair of @requestHeaders
      request += "\r\n"
      reader = new FileReader()
      reader.onload = =>
        console.log({"request-header": request})
        console.log({"request-body": new Uint8Array(buffer)})
        array = new Uint8Array(reader.result.byteLength + dataLength)
        array.set(new Uint8Array(reader.result), 0)
        array.set(new Uint8Array(buffer), reader.result.byteLength) if buffer?
        @requestBuffer = array.buffer
        @requestOffset = 0
        @responseOffset = 0
        @clearTimeStamp()
        @transmitMessage()
      reader.readAsArrayBuffer(new Blob([request]))
    if data instanceof String
      reader = new FileReader()
      reader.onload = -> sendArrayBuffer(reader.result)
      reader.readAsArrayBuffer(new Blob([data]))
    else
      sendArrayBuffer(data or new ArrayBuffer(0))
    null

  ###*
  @method abort
  @return {void}
  Method for XMLHttpRequest compatibility. But not supported.
  ###
  abort: () ->
    throw new Error("NotSupportedError")

  ###*
  @property {Number} status
  @readonly
  Attribute for XMLHttpRequest compatibility.
  ###
  status: 0

  ###*
  @property {String} statusText
  @readonly
  Attribute for XMLHttpRequest compatibility.
  ###
  statusText: ""

  ###*
  @method getResponseHeader
  @param {String} header  Response header
  @return {void/String}
  Method for XMLHttpRequest compatibility.
  ###
  getResponseHeader: (header) ->
    return null if @readyState == UNSENT or @readyState == OPENED
    return null if @errorFlag == true
    key = "#{header}".toLowerCase()
    return @responseHeaders[key] if @responseHeaders[key][1]
    null

  ###*
  @method getAllResponseHeaders
  @return {String}
  Method for XMLHttpRequest compatibility.
  ###
  getAllResponseHeaders: () ->
    return "" if @readyState == UNSENT or @readyState == OPENED
    return "" if @errorFlag == true
    result = ""
    for key, pair of @responseHeaders
      result += "#{pair[0]}: #{pair[1]}\r\n"
    result

  ###*
  @method overrideMimeType
  @return {void}
  Method for XMLHttpRequest compatibility. But not supported.
  ###
  overrideMimeType: (mime) ->
    throw new Error("NotSupportedError")

  ###*
  @property {String} responseType
  Attribute for XMLHttpRequest compatibility.
  ###
  responseType: ""

  ###*
  @property {Object} response
  @readonly
  Attribute for XMLHttpRequest compatibility.
  ###
  response: null

  ###*
  @property {Object} responseXML
  @readonly
  Attribute for XMLHttpRequest compatibility. But not supported.
  ###
  responseXML: null   # not supported

  #------------------------------------------------
  # Private member
  #

  TX_RETRY_MS = 100
  RX_RETRY_MS = 100

  constructor: (@datalink) ->
    null

  ###*
  @private
  @method changeState
  @param {Integer} newState
  Update state and invoke callbacks
  ###
  changeState: (newState) ->
    return if @readyState == newState
    console.log({
      "MemHttpRequest#changeState": this
      oldState: @readyState
      newState: newState
    }) if DEBUG > 0
    @readyState = newState
    @onreadystatechange and @onreadystatechange() if newState != @UNSENT

  ###*
  @private
  @method failed
  @param {String}   message
  @param {Function} callback
  Set error flag and update state to DONE
  ###
  failed: (message, callback) ->
    console.log({"MemHttpRequest#failed": this, message: message})
    @errorFlag = true
    @changeState(@DONE)
    callback() if callback

  ###*
  @private
  @method transmitMessage
  Transmit a request message
  ###
  transmitMessage: () ->
    @datalink.getTxPacket((packet) =>
      return @isTimedOut("Transmit") or \
        setTimeout((=> @transmitMessage()), TX_RETRY_MS) unless packet?
      offset = @requestOffset
      packet.length = Math.min(@requestBuffer.byteLength - offset, packet.capacity)
      @requestOffset += packet.length
      packet.buffer = @requestBuffer.slice(offset, offset + packet.length)
      console.log({
        "MemHttpRequest#transmitMessage": this
        packet: packet
        array: new Uint8Array(packet.buffer)
      }) if DEBUG > 0
      packet.startOfMessage = (offset == 0)
      if @requestOffset >= @requestBuffer.byteLength
        packet.endOfMessage = true
        packet.transmit((result) =>
          return @failed("Transmitting last packet") unless result
          @clearTimeStamp()
          @receiveMessage()
        )
      else
        packet.endOfMessag = false
        packet.transmit((result) =>
          return @failed("Transmitting packet") unless result
          @clearTimeStamp()
          @transmitMessage()
        )
      null
    )

  ###*
  @private
  @method receiveMessage
  Receive a response message
  ###
  receiveMessage: () ->
    @datalink.getRxPacket((packet) =>
      return @isTimedOut("Receive") or \
        setTimeout((=> @receiveMessage()), RX_RETRY_MS) unless packet?
      console.log({
        "MemHttpRequest#receiveMessage": this
        packet: packet
        data: new Uint8Array(packet.buffer)
      }) if DEBUG > 0
      failed = (message) => @failed(message, packet.discard)
      if @responseOffset == 0
        return failed("Received invalid first packet") unless packet.startOfMessage
        headerLength = null
        array = new Uint8Array(packet.buffer)
        for i in [0..packet.length-4]
          if array[i+0] == 0xd and array[i+1] == 0xa and \
             array[i+2] == 0xd and array[i+3] == 0xa
            headerLength = i
            break
        return failed("No splitter in first packet") unless headerLength
        resp = String.fromCharCode.apply(null, new Uint8Array(array.buffer, 0, headerLength))
        headerLength += 4
        lines = resp.split("\r\n")
        [http, @statusText] = lines.shift().split(" ", 2)
        unless http == "HTTP/1.0" or http == "HTTP/1.1"
          return failed("Invalid response start line")
        @status = parseInt(@statusText)
        console.log({"response-status": @status})
        console.log({"response-header": "#{resp}\r\n\r\n"})
        @responseHeaders = {}
        for line in lines
          [name, value] = line.split(":", 2)
          key = name.toLowerCase()
          @responseHeaders[key] = [name, value.trim()]
        @responseLength = parseInt((@responseHeaders["content-length"] or [null, "0"])[1])
        @responseBuffer = new ArrayBuffer(@responseLength)
      else
        headerLength = 0
      if @responseBuffer.byteLength > 0
        copyLength = Math.min(@responseLength - @responseOffset,
                              packet.length - headerLength)
        if copyLength > 0
          array = new Uint8Array(@responseBuffer, @responseOffset, copyLength)
          array.set(new Uint8Array(array.buffer, headerLength, copyLength))
          @responseOffset += copyLength
      return packet.discard(=>
        @clearTimeStamp()
        @receiveMessage()
      ) unless packet.endOfMessage
      return failed("Broken message") unless @responseOffset >= @responseLength
      switch @responseType
        when "", "string"
          @response = String.fromCharCode.apply(null, new Uint8Array(@responseBuffer))
        when "arraybuffer"
          @response = @responseBuffer
        else
          throw new TypeError("Unsupported responseType")
      console.log({"response-body": @response})
      packet.discard(=> @changeState(@DONE))
    )

  ###*
  @private
  @method clearTimeStamp
  @return {Boolean} Always true
  ###
  clearTimeStamp: () ->
    @timeStamp = +new Date()
    true

  ###*
  @private
  @method isTimedOut
  @retval true    Timed out
  @retval false   Not timed out
  ###
  isTimedOut: (message) ->
    duration = (new Date() - @timeStamp)
    return false if @timeout == 0 or duration < @timeout
    @failed(message)
    true

