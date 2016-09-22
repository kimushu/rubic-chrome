"use strict"
# Pre dependencies
UnJSONable = require("util/unjsonable")
require("util/primitive")

###*
@class BoardConsole
  Base class for console of boards (Model)
@extends JSONable
###
module.exports = class BoardConsole extends UnJSONable
  null

  ###*
  @property {Board} board
    Board instance associated to this console
  @readonly
  ###
  @property("board", get: -> @_board)

  ###*
  @event receive.console
    Event triggered when data receive
  @param {Object} event
    Event object
  @param {Board} event.board
    Board instance
  @param {BoardConsole} event.target
    BoardConsole instance
  @param {ArrayBuffer} event.data
    Received data
  ###
  @event("receive.console")

  ###*
  @event close.console
    Event triggered when console closed
  @param {Object} event
    Event object
  @param {Board} event.board
    Board instance
  @param {BoardConsole} event.target
    BoardConsole instance
  ###
  @event("close.console")

  ###*
  @method
    Open console (Start receiving data9
  @return {Promise}
    Promise object
  ###
  open: null  # pure virtual

  ###*
  @method
    Send data
  @param {ArrayBuffer} data
    Data to send
  @return {Promise}
    Promise object
  ###
  send: null  # pure virtual

  ###*
  @method
    Close console
  @return {Promise}
    Promise object
  ###
  close: null # pure virtual

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @method constructor
    Constructor of BoardConsole class
  @param {Board} _board
    Board instance
  ###
  constructor: (@_board) ->
    return

# Post dependencies
# (none)
