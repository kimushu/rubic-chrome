"use strict"
# Pre dependencies
Editor = require("editor/editor")
require("util/primitive")

###*
@class TextEditor
  Base class for text editors (View)
@extends Editor
###
module.exports = class TextEditor extends Editor
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  #--------------------------------------------------------------------------------
  # Private variables
  #

  Ace = null
  domElement = null
  aceEditor = null
  aceEmptySession = null

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @inheritdoc Editor#load
  ###
  load: ->
    return Promise.resolve(
    ).then(=>
      return @sketchItem.readContent()
    ).then((rawdata) =>
      return @convertForReading(rawdata)
    ).then((text) =>
      @_quiet(=>
        @_aceSession.setValue(text)
      )
      @modified = false
      return  # Last PromiseValue
    ) # return Promise.resolve().then()...

  ###*
  @inheritdoc Editor#save
  ###
  save: ->
    return Promise.resolve() unless @constructor.editable
    return Promise.resolve(
    ).then(=>
      return @convertForWriting(@_aceSession.getValue())
    ).then((rawdata) =>
      return @sketchItem.writeContent(rawdata)
    ).then(=>
      @modified = false
      return  # Last PromiseValue
    ) # return Promise.resolve().then()...

  ###*
  @inheritdoc Editor#activate
  ###
  activate: ->
    return super(
    ).then(=>
      aceEditor.setSession(@_aceSession)
      aceEditor.focus()
    ) # return super().then()

  ###*
  @inheritdoc Editor#deactivate
  ###
  deactivate: ->
    aceEditor.setSession(aceEmptySession)
    return super()

  ###*
  @inheritdoc Editor#focus
  ###
  focus: ->
    super()
    aceEditor.focus()
    return

  ###*
  @inheritdoc Editor#close
  ###
  close: ->
    @deactivate() if aceEditor.getSession() == @_aceSession
    @_aceSession = null
    return

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @static
  @protected
  @inheritdoc Editor#register
  ###
  @register: (subclass) ->
    return Editor.register(subclass)

  ###*
  @protected
  @method constructor
    Constructor of TextEditor class
  @param {jQuery} $
    jQuery object
  @param {Sketch} sketch
    Sketch instance
  @param {SketchItem} sketchItem
    SketchItem instance
  @param {string} _aceMode
    Ace mode name
  ###
  constructor: ($, sketch, sketchItem, @_aceMode) ->
    super($, sketch, sketchItem, (domElement or= $("#text-editor")[0]))
    Ace or= window.ace
    unless aceEditor
      aceEditor = Ace.edit(domElement)
      aceEmptySession = aceEditor.getSession()
      aceEditor.setShowPrintMargin(false)
    @_aceSession = new Ace.createEditSession("", @_aceMode)
    @_aceSession.on("change", =>
      @modified = true unless @_ignoreEvents
      # TODO raise event listener
    )
    @_ignoreEvents = false
    @_quiet = (action) =>
      try
        @_ignoreEvents = true
        action()
      finally
        @_ignoreEvents = false
    return

  ###*
  @protected
  @template
  @method
    Convert data for reading (Raw to Text)
  @param {ArrayBuffer} rawdata
    Raw data to convert
  @return {Promise}
    Promise object
  @return {string} return.PromiseValue
    Converted text
  ###
  convertForReading: (rawdata) ->
    return new Promise((resolve, reject) =>
      reader = new FileReader()
      reader.onloadend = => resolve(reader.result)
      reader.onerror = => reject(I18n.error("Conversion_failed"))
      reader.readAsText(new Blob([rawdata]))
    ) # return new Promise()

  ###*
  @protected
  @template
  @method
    Convert data for reading (Raw to Text)
  @param {string} text
    Text to convert
  @return {Promise}
    Promise object
  @return {string} return.PromiseValue
    Converted raw data
  ###
  convertForWriting: (text) ->
    return new Promise((resolve, reject) =>
      reader = new FileReader()
      reader.onloadend = => resolve(reader.result)
      reader.onerror = => reject(I18n.error("Conversion_failed"))
      reader.readAsArrayBuffer(new Blob([text]))
    ) # return new Promise()

# Post dependencies
I18n = require("util/i18n")
