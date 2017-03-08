"use strict"
Editor = require("./editor")
once = require("once")

###*
Pseudo-viewer for welcome screen (shown when sketch is not opened)

@class WelcomeViewer
@extends Editor
@constructor
###
module.exports =
class WelcomeEditor extends Editor

  constructor: ->

  @editable: false

  activate: ->
    return super(
    ).then(=>
      return @_setupWelcome()
    ).then(=>
      return global.rubic.settings.get({recent_sketches: null})
    ).then(({recent_sketches}) =>
      recent_sketches.max ?= 10
      recent_sketches.items ?= []
    )

  deactivate: ->
    return super()

  _setupWelcome: once ->
    $(".clear-recent-sketch").click(@_clearRecentSketch.bind(this))

