"use strict"
# Pre dependencies
Editor = require("./editor")

###*
@class SketchEditor
  Editor for sketch configuration (View)
@extends Editor
###
module.exports = class SketchEditor extends Editor
  Editor.register(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {string} title
    Title of this editor
  @readonly
  ###
  @property("title", get: -> @sketch.friendlyName)

  #--------------------------------------------------------------------------------
  # Private variables
  #

  domElement = null
  jsTree = null
  jqTreeElement = null

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method constructor
    Constructor
  @param {jQuery} $
    jQuery object
  @param {Sketch} sketch
    Sketch instance
  ###
  constructor: ($, sketch) ->
    super($, sketch, null, (domElement or= $("#sketch-editor")[0]))
    jsTree?.destroy()
    jqTreeElement = $(domElement).find(".explorer-left")
    jqTreeElement.jstree({
      core:
        animation: 0
        check_callback: true
        themes:
          dots: false
      types:
        folder: {}
        sketch: {}
        file:
          icon: "glyphicon glyphicon-file"
      plugins: ["types"]
    })
    jsTree = jqTreeElement.jstree(true)
    e = "select_node.jstree"
    jqTreeElement.unbind(e).on(e, (event, data) =>
      isFile = (data.node.type == "file")
      $(".explorer-open").prop("disabled", !isFile).next().prop("disabled", !isFile)
      $(".explorer-rename").prop("disabled", !isFile)
      $(".explorer-remove").prop("disabled", !isFile)
    )
    @_refreshTree()
    jsTree.select_node(@_rootNodeId)
    @sketch.addEventListener("change", (@_changeListener or= @_refreshTree.bind(this)))
    return

  ###*
  @inheritdoc Editor#activate
  ###
  activate: ->
    jqTreeElement.focus()
    super()
    return

  #--------------------------------------------------------------------------------
  # Private methods
  #

  _refreshTree: ->
    # Update root node
    @_rootNodeId or= jsTree.create_node(null, {text: "", type: "sketch"})
    jsTree.rename_node(@_rootNodeId, @sketch.friendlyName)
    # Get items
    items = @sketch.items.sort((a, b) =>
      ap = a.path
      bp = b.path
      return -1 if ap < bp
      return +1 if ap > bp
      return 0
    )
    @_itemNodes or= new Map()
    # Remove invalid nodes
    @_itemNodes.forEach((id, path) =>
      if items.findIndex((item) => item.path == path) < 0
        jsTree.delete_node(id)
        @_itemNodes.delete(path)
    )
    # Add new nodes
    for item in items
      @_itemNodes.set(item.path, jsTree.create_node(@_rootNodeId, {
        text: item.path
        type: "file"
      }))
    jsTree.open_node(@_rootNodeId)
    console.log(items)
    return

# Post dependencies
# (none)
