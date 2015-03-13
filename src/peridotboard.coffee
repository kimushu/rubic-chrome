class PeridotBoard extends Board
  Board.addBoard(this)
  @boardname: "PERIDOT"
  @author: "Shun Osafune (@s_osafune)"
  @website: "https://peridotcraft.com/"
  @portClasses: [SerialPort]

  ###*
  Constructor
  ###
  constructor: (config) ->
    super()
    @canarium = new Canarium()

  ###*
  Connect to PERIDOT board
  @param {Object}   port      Port object
  @param {Function} callback  Callback ({Boolean} result)
  ###
  connect: (port, callback) ->
    return callback(true) if @isConnected
    @onConnected(false)
    @canarium.open(port.name, (result) =>
      return callback(false) unless result
      callback(true)
      xhr = new XMLHttpRequest
      url = chrome.runtime.getURL("firmware.rpd")
      xhr.open("GET", url, true)
      xhr.responseType = "arraybuffer"
      self = this
      xhr.onload = ->
        unless @status == 200
          self._log(1, "connect>canarium.open>xhr>send>failed!")
          return callback(false)
        #  self.canarium.config(null, @response, (result) ->
        self.canarium.avm.option({forceConfigured: true}, (result) ->
          return callback(false) unless result
          self.canarium.reset((result) ->
            return callback(false) unless result
            self.onConnected(true)
            callback(true)
          )
        )
      xhr.send()
    )

  ###*
  Disconnect from PERIDOT board
  @param {Function} callback  Callback ({Boolean} result)
  ###
  disconnect: (callback) ->
    return callback(true) unless @isConnected
    @canarium.close((result) =>
      return callback(false) unless result
      super(callback)
    )

  dumpMemory: (addr, words) ->
    @canarium.avm.read(addr, words * 4, (result, readdata) =>
      return console.log("MEM_READ @ 0x#{addr.toString(16)}: failed") unless result
      arr = new Uint8Array(readdata)
      for i in [0...words]
        v = "0x"
        v += ("0" + arr[i*4+3].toString(16)).substr(-2)
        v += ("0" + arr[i*4+2].toString(16)).substr(-2)
        v += ("0" + arr[i*4+1].toString(16)).substr(-2)
        v += ("0" + arr[i*4+0].toString(16)).substr(-2)
        console.log("MEM_READ @ 0x#{addr.toString(16)}: #{v}")
        addr += 4
    )
  ###*
  Get board information
  @param {Function} callback  Callback ({Object} result)
  ###
  getInfo: (callback) ->
    return callback(false) unless @isConnected
    @canarium.getinfo((result) =>
      return callback(null) unless result
      callback(@canarium.boardInfo)
    )

  ###*
  Reset board
  @param {Function} callback  Callback ({Boolean} result)
  ###
  reset: (callback) ->
    @irqBase = @nextTxPacket = @nextRxPacket = null
    @canarium.reset((result, respbyte) =>
      callback(result)
    )

  SERVER_HOST         = "peridot"
  SERVER_FS_PATH      = "/mnt/spiffs"

  test: (callback) ->
    req = @newHttpRequest()
    req.timeout = 3000
    req.onreadystatechange = ->
      switch req.readyState
        when req.DONE
          null#  callback(not req.errorFlag)
    #  req.open("GET", "http://#{SERVER_HOST}/dev/epcs")
    req.open("GET", "http://#{SERVER_HOST}#{SERVER_FS_PATH}/main.rb")
    req.send()

  ###*
  @private
  @method newHttpRequest
  Make new XMLHttpRequest compatible object
  ###
  newHttpRequest: () ->
    new MemHttpRequest(this)

  MEM_BASE            = 0xfffc000
  MEM_HTTP_SIGNATURE  = "MHttp1.0"
  MEM_HTTP_VALID      = 1
  MEM_HTTP_SOM        = 2
  MEM_HTTP_EOM        = 4

  ###*
  @method getTxPacket
  Get next empty TX packet
  ###
  getTxPacket: (callback) ->
    @connectDataLink((result) =>
      return callback(null) unless result
      base = @nextTxPacket
      @canarium.avm.read(base, 8, (result, readdata) =>
        return callback(null) unless result
        header = new Uint8Array(readdata)
        flags = (header[5] << 8) | header[4]
        return callback(null) unless (flags & MEM_HTTP_VALID) == 0
        packet =
          capacity: (header[3] << 8) | header[2]
          startOfMessage: null
          endOfMessage: null
          length: null
          buffer: null
          transmit: (tx_callback) ->
            @peridot.canarium.avm.write(base + 8, @buffer, (result) =>
              return tx_callback(false) unless result
              word = (@length << 16) | MEM_HTTP_VALID
              word |= MEM_HTTP_SOM if @startOfMessage
              word |= MEM_HTTP_EOM if @endOfMessage
              @peridot.canarium.avm.iowr(base, 1, word, (result) =>
                return tx_callback(false) unless result
                @peridot.raiseIrq((result) => tx_callback(result))
              )
            )
          peridot: this
        @nextTxPacket = MEM_BASE + ((header[1] << 8) | header[0])
        callback(packet)
      )
    )

  ###*
  @method getRxPacket
  Get next full RX packet
  ###
  getRxPacket: (callback) ->
    @connectDataLink((result) =>
      return callback(null) unless result
      base = @nextRxPacket
      @canarium.avm.read(base, 8, (result, readdata) =>
        return callback(null) unless result
        header = new Uint8Array(readdata)
        flags = (header[5] << 8) | header[4]
        length = (header[7] << 8) | header[6]
        return callback(null) unless (flags & MEM_HTTP_VALID) != 0
        @canarium.avm.read(base + 8, length, (result, readdata) =>
          return callback(null) unless result
          packet =
            capacity: (header[3] << 8) | header[2]
            startOfMessage: (flags & MEM_HTTP_SOM) != 0
            endOfMessage: (flags & MEM_HTTP_EOM) != 0
            length: length
            buffer: readdata
            discard: (rx_callback) ->
              @peridot.canarium.avm.iowr(base, 1, 0, (result) =>
                return rx_callback(false) unless result
                @peridot.raiseIrq((result) => rx_callback(result))
              )
            peridot: this
          @nextRxPacket = MEM_BASE + ((header[1] << 8) | header[0])
          callback(packet)
        )
      )
    )

  ###*
  @private
  @method connectDataLink
  ###
  connectDataLink: (callback) ->
    return callback(true) if @irqBase? and @nextTxPacket? and @nextRxPacket?
    @canarium.avm.read(MEM_BASE, 16, (result, readdata) =>
      return callback(false) unless result
      sign = String.fromCharCode.apply(null, new Uint8Array(readdata.slice(0, 8)))
      return callback(false) unless sign == MEM_HTTP_SIGNATURE
      array = new Uint8Array(readdata)
      @irqBase = (array[11] << 24) | (array[10] << 16) | (array[9] << 8) | array[8]
      @nextTxPacket = MEM_BASE + ((array[13] << 8) | array[12])
      @nextRxPacket = MEM_BASE + ((array[15] << 8) | array[14])
      callback(true)
    )

  ###*
  @private
  @method raiseIrq
  ###
  raiseIrq: (callback) ->
    return callback(false) unless @irqBase?
    return callback(true) if @irqBase == 0
    @canarium.avm.iowr(@irqBase, 0, 1, (result) ->
      callback(result)
    )

  ###*
  @private
  Send HTTP request to PERIDOT board
  @param {String}       method
  @param {String}       target
  @param {ArrayBuffer}  data @nullable
  @param {Function}     callback ({Integer} code, {ArrayBuffer} response)
  ###
  sendHttpRequest: (method, target, data, callback) ->
    dataLength = if data then data.byteLength else 0
    req = "#{method} #{encodeURI(target)} HTTP/1.1\r\nHost: #{@MEM_HTTP_HOST}\r\n"
    req += "Content-Length: #{dataLength}\r\n" if dataLength > 0
    req += "\r\n"
    @_log(1, "sendHttpRequest>send(\"#{req}\" + #{dataLength} bytes)")
    req = unescape(encodeURIComponent(req))
    length = req.length + dataLength
    arr = new Uint8Array(length)
    arr[i] = req.charCodeAt(i) for i in [0...length]
    arr.set(data, req.length) if dataLength > 0
    @sendRequest(arr.buffer, (response) ->
      return callback(null) unless response
      arr = new Uint8Array(response)
      offset = null
      #for i in [4..arr.byteLength]
      #  if (arr[i-4] == 0xd and arr[i-3] == 0xa and arr[i-2] == 0xd and arr[i-1] == 0xa)
      #    offset = i
      #    break
      return callback(null) unless offset
      res = String.fromCharCode.apply(null, arr.subarray(0, offset - 4))
      @_log(1, "sendHttpRequest>recv(\"#{res}\r\n\r\n\" + #{arr.byteLength - offset} bytes)")
      res = res.split("\r\n")
      res[0] = res[0].split(" ", 3)
      return callback(null) unless res[0][0] == "HTTP/1.1"
      callback(parseInt(res[0][1], 10), response.slice(offset))
    )

  ###*
  @private
  Send request to PERIDOT board
  @param {ArrayBuffer}  request   Request data
  @param {Function}     callback  Callback ({ArrayBuffer} response)
  ###
  sendRequest: (request, callback) ->
    @connectServer((sender) =>
      unless sender
        @_log(1, "sendRequest>nosender!")
        return callback(null)
      sender(request, callback)
    )

  ###*
  @private
  Create connection to server on PERIDOT board
  @param {Function} requester Callback ({Function} sender)
  ###
  connectServer: (requester) ->
    # ({Integer} num, {ArrayBuffer} data, {Function} callback)
    recv = (num, data, callback) ->
      @canarium.avm.read(@rx_next, 8, (result, readdata) =>
        unless result
          @_log(2, "connectServer>recv>readHeader>failed!")
          return callback(null)
        arr = new Uint8Array(readdata)
        frame =
          next:   (arr[1] << 8) | arr[0]
          flags:  (arr[5] << 8) | arr[4]
          length: (arr[7] << 8) | arr[6]
        if ((frame.flags & @MEM_HTTP_VALID) == 0)
          @_log(3, "connectServer>recv>retry")
          return setTimeout((-> recv(num, data, callback)), @RETRY_MS)
        if (num == 0 and (frame.flags & @MEM_HTTP_SOF) == 0)
          @_log(2, "connectServer>recv>sofExpected!")
          return callback(null)
        @canarium.avm.read(@rx_next + 8, frame.length, (result, readdata) =>
          unless result
            @_log(2, "connectServer>recv>readData>failed!")
            return callback(null)
          data.push_back(readdata.slice(0))
          if ((frame.flags & @MEM_HTTP_SOF) == 0)
            @rx_next = @mem_base + frame.next
            @_log(3, "connectServer>recv(##{num+1}, @0x#{@rx_next.toString(16)})")
            return recv(num + 1, data, callback)
          length = 0
          length += d.length for d in data
          arr = new Uint8Array(length)
          offset = 0
          for d in data
            arr.set(d, offset)
            offset += d.length
          @canarium.avm.iowr(@rx_next + 4, 0, (result) =>
            unless result
              @_log(2, "connectServer>recv>writeHeader>failed!")
              return callback(null)
            callback(arr.buffer)
          )
        )
      )
    # ({Integer} num, {ArrayBuffer} data, {Function} callback)
    send = (num, data, callback) ->
      if data.byteLength == 0
        @_log(3, "connectServer>recv(#0, @0x#{@rx_next.toString(16)})")
        return recv(0, [], callback)
      @canarium.avm.read(@tx_next, 8, (result, readdata) =>
        unless result
          @_log(2, "connectServer>send>readHeader>failed!")
          return callback(null)
        arr = new Uint8Array(readdata)
        frame =
          next:     (arr[1] << 8) | arr[0]
          capacity: (arr[3] << 8) | arr[2]
          flags:    (arr[5] << 8) | arr[4]
        if ((frame.flags & @MEM_HTTP_VALID) != 0)
          @_log(3, "connectServer>send>retry")
          return setTimeout((-> send(num, data, callback)), @RETRY_MS)
        length = Math.min(arr.bytesLength, frame.capacity)
        buf = readdata.slice(0, length)
        rem = readdata.slice(length)
        flags = @MEM_HTTP_VALID
        flags |= @MEM_HTTP_SOF if num == 0
        flags |= @MEM_HTTP_EOF if arr.byteLength == length
        @canarium.avm.write(@tx_next + 8, buf, (result) =>
          unless result
            @_log(2, "connectServer>send>writeData>failed!")
            return callback(null)
          @canarium.avm.iowr(@tx_next + 4, (length << 8) | flags, (result) =>
            unless result
              @_log(2, "connectServer>send>writeHeader>failed!")
              return callback(null)
            @canarium.avm.iowr(@irq_base, 1, (result) =>
              unless result
                @_log(2, "connectServer>send>sendTxIrq>failed!")
                return callback(null)
              @tx_next = @mem_base + frame.next
              @_log(3, "connectServer>send(##{num+1}, @0x#{@tx_next.toString(16)}")
              send(num + 1, rem, callback)
            )
          )
        )
      )
    sender = (data, callback) ->
      @_log(3, "connectServer>send(#0, @0x#{@tx_next.toString(16)})")
      send(0, data, callback)
    if (@irq_base and @tx_next and @rx_next)
      return requester(sender)
    @canarium.avm.read(@mem_base, 16, (result, readdata) =>
      return requester(null) unless result
      arr = new Uint8Array(readdata)
      sig = String.fromCharCode.apply(null, arr.subarray(0, 8))
      return requester(null) unless sig == @MEM_HTTP_SIGNATURE
      @irq_base = (arr[8]) | (arr[9] << 8) | (arr[10] << 16) | (arr[11] << 24)
      @tx_next = @mem_base + ((arr[12]) | (arr[13] << 8))
      @rx_next = @mem_base + ((arr[14]) | (arr[15] << 8))
      requester(sender)
    )

  ###*
  Write firmware to board
  @param arraybuf   ArrayBuffer which contains firmware data
  @param callback   Callback (bool result)
  ###
  writeFirmware: (arraybuf, callback) ->
    @canarium.config(null, arraybuf, callback)

  _log: (level, value) ->
    console.log(value) if @verbose >= level

