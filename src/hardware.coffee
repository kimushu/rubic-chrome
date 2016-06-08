###*
@class Rubic.Hardware
  Combination of board and firmware (Model)
@extends Rubic.JSONable
###
class Rubic.Hardware extends Rubic.JSONable
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {string} name
    Name of this hardware
  @readonly
  ###
  @property("name", get: -> @_name)

  ###*
  @property {Date} timestamp
    Timestamp of this hardware
  @readonly
  ###
  @property("timestamp", get: -> @_timestamp)

  ###*
  @property {string} description
    Description of this hardware
  @readonly
  ###
  @property("description", get: -> @_description)

  ###*
  @property {Rubic.Board} board
    Board definition
  @readonly
  ###
  @property("board", get: -> @_board)

  ###*
  @property {Rubic.Engine[]} engines
    List of script engines
  ###
  @property("engines", get: -> @_engines)

  ###*
  @property {Rubic.IOPinDef[]} io_pins
    List of I/O pin definitions
  ###
  @property("io_pins", get: -> @_io_pins)

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method constructor
    Constructor of Hardware class
  @param {Object} obj
    JSON object
  ###
  constructor: (obj) ->
    @_name        = obj.name
    @_timestamp   = obj.timestamp
    @_description = obj.description
    @_board       = Rubic.Board.parseJSON(obj.board)
    @_engines     = Rubic.Engine.parseJSON(x) for x in obj.engines
    @_io_pins     = Rubic.IoPinDef.parseJSON(x) for x in obj.io_pins
    return

  ###*
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return super().extends({
      name        : @_name
      timestamp   : @_timestamp
      description : @_description
      board       : @_board
      engines     : @_engines
      io_pins     : @_io_pins
    })

