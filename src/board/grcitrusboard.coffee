"use strict"
# Pre dependencies
WakayamaRbBoard = require("board/wakayamarbboard")
Board = require("board/board")
I18n = require("util/i18n")
require("util/primitive")

###*
@class GrCitrusBoard
  GR-CITRUS board (Model)
@extends WakayamaRbBoard
###
module.exports = class GrCitrusBoard extends WakayamaRbBoard
  Board.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @property {string} id
    ID of this board class
  @readonly
  ###
  @classProperty("id", value: "24f62778-b930-4c1b-8fc0-4fcf4884c09f")

  ###*
  @static
  @property {string} rubicVersion
    Rubic version
  @readonly
  ###
  @classProperty("rubicVersion", value: ">= 0.9.0")

  ###*
  @static
  @property {I18n} friendlyName
    Name of this board class
  @readonly
  ###
  @classProperty("friendlyName", value: new I18n("GR-CITRUS"))

  ###*
  @static
  @property {I18n} author
    Author of this board class
  @readonly
  ###
  @classProperty("author", value: new I18n("Wakayama.rb"))

  ###*
  @static
  @property {string} website
    Website URL of board class
  @readonly
  ###
  @classProperty("website", value: "https://github.com/wakayamarb/")

  ###*
  @static
  @property {string[]} images
    List of images of this board class
    (The first item is used as an icon)
  @readonly
  ###
  @classProperty("images", get: -> [
    "images/boards/grcitrus_64x64.png"
  ])

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  TOL5V = new I18n({en: "5V tolerant", ja: "5Vトレラント"})
  ADPIN = new I18n({en: "With analog input", ja: "アナログ入力対応"})
  DAPIN = new I18n({en: "With analog output", ja: "アナログ出力対応"})
  RXPIN = new I18n({en: "Pin number of RX631", ja: "RX631ピン番号"})
  ANPIN = new I18n({en: "Analog pins", ja: "アナログピン名称"})

  @VID_PID_LIST: [
    # VID)PID)
    0x2a500277  # Akiduki (GR-CITRUS)
  ].concat(
    WakayamaRbBoard.VID_PID_LIST
  )

  @POLL_BY_FEH: null  # Disable polling by 0xfe
  @BINARY_MODE: false

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @inheritdoc Board#getProgrammer
  ###
  getProgrammer: ->
    return new MbedProgrammer(
      this
      {
        name: "GR-CITRUS"
        guidance: "Gadget Renesas Project Home.html"
      }
      {
        message: I18n.getMessage("Push_switch_1", "RESET")
        image: null
      }
    )

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

# Post dependencies
# MbedProgrammer = require("programmer/mbedprogrammer")
