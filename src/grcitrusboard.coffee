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
    "ja": "Arduinoに似たメソッドを持ち、Ruby言語でプログラミングができるコンパクトなRX631搭載マイコンボード。"
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
  @rubicVersion: ">= 0.9.0"

  ###*
  @static
  @property {boolean}
    Beta
  @readonly
  ###
  @beta: true

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  TOL5V = new I18n({en: "5V tolerant", ja: "5Vトレラント"})
  ADPIN = new I18n({en: "With analog input", ja: "アナログ入力対応"})
  DAPIN = new I18n({en: "With analog output", ja: "アナログ出力対応"})
  RXPIN = new I18n({en: "Pin number of RX631", ja: "RX631ピン番号"})
  ANPIN = new I18n({en: "Analog pins", ja: "アナログピン名称"})

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @inheritdoc Board#getPinList
  ###
  getPinList: ->
    return {
      left: [
        {name: "0",   aliases: ["P20"], specials: [TOL5V]}
        {name: "1",   aliases: ["P21"], specials: [TOL5V]}
        {name: "18",  aliases: ["P12"], specials: [TOL5V]}
        {name: "19",  aliases: ["P13/P15"], specials: [TOL5V]}
        {name: "2",   aliases: ["PC0/P31"], specials: [TOL5V]}
        {name: "3",   aliases: ["PC1"], specials: [TOL5V]}
        {name: "4",   aliases: ["PC2"], specials: [TOL5V]}
        {name: "5",   aliases: ["P25/P34"]}
        {name: "6",   aliases: ["P52"]}
        {name: "7",   aliases: ["P32"], specials: [TOL5V]}
        {name: "8",   aliases: ["P33"], specials: [TOL5V]}
        {name: "9",   aliases: ["P05","DA1"], specials: [DAPIN]}
      ]
      right: [
        {private: "5V"}
        {private: "GND"}
        {private: "RESET"}
        {private: "3.3V"}
        {name: "17",  aliases: ["P43","A3"], specials: [ADPIN]}
        {name: "16",  aliases: ["P42","A2"], specials: [ADPIN]}
        {name: "15",  aliases: ["P41","A1"], specials: [ADPIN]}
        {name: "14",  aliases: ["P40","A0"], specials: [ADPIN]}
        {name: "13",  aliases: ["PC5"]}
        {name: "12",  aliases: ["PC7"]}
        {name: "11",  aliases: ["PC6"]}
        {name: "10",  aliases: ["PC4"]}
      ]
      aliases: [RXPIN, ANPIN]
      image: {
      }
    } # return {}

module.exports = GrCitrusBoard

# Post dependencies
# (none)
