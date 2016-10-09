"use strict"
# Pre dependencies
UnJSONable = require("util/unjsonable")

###*
@class Programmer
  Firmware updater class
###
module.exports = class Programmer extends UnJSONable
  null

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method
    Execute firmware update
  @param {ArrayBuffer} data
    Data to write
  @return {Promise}
    Promise object
  ###
  update: null  # pure virtual

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @method constructor
    Constructor of Programmer class
  @param {Board} _board
    Board instance
  ###
  constructor: (@_board) ->
    return

# Post dependencies
# (none)
