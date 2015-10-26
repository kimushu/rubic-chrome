###*
@class Rubic.PeridotBoard
  PERIDOT board (Model)
@extends Rubic.Board
###
class Rubic.PeridotBoard extends Rubic.Board
  DEBUG = Rubic.DEBUG or 0
  Rubic.Board.addBoard(this)

  ###*
  @static
  @cfg {string}
    Name of board
  @readonly
  ###
  @NAME: "Peridot board"

  ###*
  @static
  @cfg {string}
    Author of board
  @readonly
  ###
  @AUTHOR: "Shun Osafune (@s_osafune)"

  ###*
  @static
  @cfg {string}
    Website of board (if available)
  @readonly
  ###
  @WEBSITE: "http://osafune.github.io/peridot.html"

  ###*
  @static
  @inheritdoc Board#enumerate
  ###
  @enumerate: (callback) ->
    Canarium.enumerate(callback)
    return

  ###*
  @property {Canarium}
    Instance of canarium
  @readonly
  ###
  @property("canarium", get: -> @_canarium)

  ###*
  @method constructor
    Constructor
  ###
  constructor: ->
    @_canarium = new Canarium()
    return

  ###*
  @inheritdoc Board#connect
  ###
  connect: (path, callback) ->
    @_canarium.open(path, callback)
    return

  ###*
  @inheritdoc Board#disconnect
  ###
  disconnect: (callback) ->
    @_canarium.close(callback)
    return

  ###*
  @inheritdoc Board#reset
  ###
  reset: (callback) ->
    @_canarium.reset(callback)
    return

  ###*
  @inheritdoc Board#startSketch
  ###
  startSketch: (callback) ->
    @_sendRequest("start", callback)
    return

  ###*
  @inheritdoc Board#stopSketch
  ###
  stopSketch: (callback) ->
    @_sendRequest("stop", callback)
    return

  ###*
  @inheritdoc Board#requestFileSystem
  ###
  requestFileSystem: (successCallback, errorCallback) ->
    # TODO
    errorCallback(new Error("Not implemented"))
    return

  ###*
  @inheritdoc Board#requestSerialComm
  ###
  requestSerialComm: (callback) ->
    # TODO
    callback(false, null)
    return

  ###*
  @inheritdoc Board#setupFirmware
  ###
  setupFirmware: (setup, force, callback) ->
    # TODO
    callback(false)
    return

# ###*
# @class
#   Pseudo file system class for Peridot
# @uses PeridotBoard
# ###
# class PeridotBoard.FileSystem
#   DEBUG = if DEBUG? then DEBUG else 0


