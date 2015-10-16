###*
@class Board
  Base class for embedded boards (Model)
###
class Board
  DEBUG = if DEBUG? then DEBUG else 0

  ###*
  @static
  @inheritable
  @cfg {string}
    Name of board
  @readonly
  ###
  @NAME: null

  ###*
  @static
  @inheritable
  @cfg {string}
    Author of board
  @readonly
  ###
  @AUTHOR: null

  ###*
  @static
  @inheritable
  @cfg {string}
    Website of board (if available)
  @readonly
  ###
  @WEBSITE: null

  ###*
  @private
  @static
  @property {Function[]}
    List of subclasses
  ###
  @_boards: []

  ###*
  @protected
  @static
  @method
    Register board class
  @param {Function} boardClass
    Constructor of subclass
  @return {void}
  ###
  @addBoard: (boardClass) ->
    @_boards.push(boardClass)
    return

  ###*
  @static
  @method
    Get constructor from its name
  @param {string} name
    Name of class
  @return {Function} Constructor of found class
  ###
  @getBoard: (name) ->
    (return c) for c in @_boards when c.name == name
    return

  ###*
  @static
  @method
    Enumerate connected boards
  @param {function(boolean,Object[]):void}  callback
    Callback function with result and array of boards

    - name : Name for user interface (ex: COMxx)
    - path : Path for internal use
  @return {void}
  ###
  @enumerate: (callback) ->
    callback(false, null)
    return

  ###*
  @method
    Connect to board
  @param {string} path
    Path of board to connect
  @param {function(boolean):void} callback
    Callback function with result
  @return {void}
  ###
  connect: (@path, callback) ->
    callback(false)
    return

  ###*
  @event
    Register handler for disconnect event
  @param {function(Board):void} handler
    Event handler
  ###
  onDisconnect: (handler) ->
    @_onDisconnect = handler
    return

  ###*
  @protected
  @method
    Fire disconnect event
  @return {void}
  ###
  fireDisconnect: ->
    (handler = @_onDisconnect)?(this)
    return

  ###*
  @method
    Disconnect from board
  @param {function(boolean):void} callback
    Callback function with result
  @return {void}
  ###
  disconnect: (callback) ->
    callback(false)
    return

  ###*
  @method
    Reset board
  @param {function(boolean):void} callback
    Callback function with result
  @return {void}
  ###
  reset: (callback) ->
    callback(false)
    return

  ###*
  @method
    Start sketch
  @param {function(boolean):void} callback
    Callback function with result
  @return {void}
  ###
  startSketch: (callback) ->
    callback(false)
    return

  ###*
  @event
    Register handler for end of sketch
  @param {function(Board):void} handler
    Event handler
  @return {void}
  ###
  onSketchEnd: (handler) ->
    @_onSketchEnd = handler
    return

  ###*
  @protected
  @method
    Fire end of sketch event
  @return {void}
  ###
  fireSketchEnd: ->
    (handler = @_onSketchEnd)?(this)
    return

  ###*
  @method
    Stop sketch
  @param {function(boolean):void} callback
    Callback function with result
  @return {void}
  ###
  stopSketch: (callback) ->
    callback(false)
    return

  ###*
  @method
    Request file system for sketch
  @param {function(Object):void}  successCallback
    Callback function with file system object for successful
  @param {function(Error):void} errorCallback
    Callback function for failure
  @return {void}
  ###
  requestFileSystem: (successCallback, errorCallback) ->
    errorCallback(new Error("Not implemented"))
    return

  ###*
  @method
    Request serial communication
  @param {function(boolean,SerialComm):void}  successCallback
    Callback function with result and serial comm instance
  @return {void}
  ###
  requestSerialComm: (callback) ->
    callback(false, null)
    return

  ###*
  @method
    Setup firmware
  @param {Object} setup
    Setup information
  @param {boolean} force
    Force entire setup
  @param {function(boolean):void} callback
    Callback function with result
  @return {void}
  ###
  setupFirmware: (setup, force, callback) ->
    callback(false)
    return

