# Pre dependencies
WakayamaRbBoard = require("./wakayamarbboard")
Board = require("./board")
I18n = require("./i18n")

###*
@class GrCitrusBoard
  GR-CITRUS board (Model)
@extends WakayamaRbBoard
###
class GrCitrusBoard extends WakayamaRbBoard
  Board.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @property {I18n}
    Name of this board
  @readonly
  ###
  @friendlyName: new I18n(
    "GR-CITRUS"
  )

  ###*
  @static
  @property {I18n}
    Author of this board
  @readonly
  ###
  @author: new I18n(
    "Wakayama.rb"
  )

  ###*
  @static
  @property {string}
    Website URL of board
  @readonly
  ###
  @website: "https://github.com/wakayamarb/"

  ###*
  @static
  @property {I18n}
    Description of this board
  @readonly
  ###
  @description: new I18n({
    # TODO
    "en": "Compact RX631 microcontroller board with Ruby language support and Arduino-like methods."
    "ja": "Arduinoに似たメソッドを持ちつつ、Ruby言語でプログラミングができるコンパクトなRX631搭載マイコンボード。"
  })

  ###*
  @static
  @property {string[]}
    List of images of this board (The first item is used as an icon)
  @readonly
  ###
  @images: ["images/boards/grcitrus_64x64.png"]

  ###*
  @static
  @property {string}
    Rubic version
  @readonly
  ###
  @rubicVersion: ">=1.0.0"

  ###*
  @static
  @property {boolean}
    Beta
  @readonly
  ###
  @beta: true

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @inheritdoc Board#getEngineList
  ###
  getEngineList: ->
    return [
      {
        name: "mruby with V2 library"
        id: "mruby_v2lib"
        icon: "mruby"
      }
    ] # return []

