"use strict"
# Pre dependencies
Editor = require("editor/editor")
require("util/primitive")

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
  @property("title",
    get: -> "[#{I18n.getMessage("Sketch")}] #{@sketch.friendlyName}"
  )

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
    jqTreeElement = $(domElement).find(".explorer-left").empty()
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
      $(".explorer-open").prop("disabled", !isFile)
      $(".explorer-rename").prop("disabled", !isFile)
      $(".explorer-remove").prop("disabled", !isFile)
      @_selectItem(@_itemNodes[data.node.id]?.item)
    )
    $(".explorer-add-existing").unbind("click")
      .click(@_addExisting.bind(this))
    $(".explorer-add").unbind("click")
      .click(@_addExisting.bind(this))
    $(".explorer-open").unbind("click")
      .click(@_openItem.bind(this))
    $(".explorer-rename").unbind("click")
      .click(@_renameItem.bind(this))
    $(".explorer-remove").unbind("click")
      .click(@_removeItem.bind(this))
    @_refreshTree()
    jsTree.select_node(@_rootNodeId)
    @sketch.addEventListener("save", this)
    @sketch.addEventListener("additem", this)
    @sketch.addEventListener("removeitem", this)
    return

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method
    Event handler
  @param {Object} event
    Event object
  @return {undefined}
  ###
  handleEvent: (event) ->
    switch event.type
      when "save"
        @dispatchEvent({type: "changetitle"})
      when "additem"
        @_refreshTree()
        for k, v of @_itemNodes
          if event.item.path == v.path
            jsTree.deselect_all()
            jsTree.select_node(k)
            break
      when "removeitem"
        @_refreshTree()
    return

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Add existing item
  @return {Promise}
    Promise object
  ###
  _addExisting: ->
    $ = @$
    fs = null
    name = null
    return AsyncFs.chooseFile().catch((error) =>
      # When cancelled
      App.warn(error)
      return
    ).then((result) =>
      return unless result?
      fs = result.fs
      name = result.name
      return "yes" unless @sketch.getItem(name)
      return global.bootbox.dialog_p({
        title: I18n.getMessage("File_overwrite")
        message: I18n.getMessage("Are_you_sure_to_replace_existing_file_1_with_new_one")
        closeButton: false
        buttons: {
          yes: {
            label: I18n.getMessage("Yes")
            className: "btn-danger"
          }
          no: {
            label: I18n.getMessage("No")
            className: "btn-success"
          }
        }
      })  # return global.bootbox.dialog_p()
    ).then((result) =>
      return unless result == "yes"
      @sketch.removeItem(name)
      return fs.readFile(name).then((data) =>
        return @sketch.addNewItem(name, data)
      )
    ) # return AsyncFs.chooseFile()...

  _openItem: ->
    return

  _renameItem: ->
    return

  _removeItem: ->
    return

  _selectItem: (item) ->
    panels = {}
    if item?
      # SketchItem
      panels["{File_overview}"] = ctrls = {}
      dirs = item.path.split("/")
      ctrls["{Name}"] = dirs.pop()
      ctrls["{Folder}"] = dirs.join("/") if dirs.length > 0
      ctrls["{FileType}"] = item.fileType?.toString() or I18n.getMessage("Unknown")
      ctrls["{Generated_from}"] = item.source?.path
      ctrls["{Transfer_to_board}"] = {
        type: "checkbox"
        get: => item.transfer
        set: (v) => item.transfer = v
      }
      builder = item.builder
      if builder?
        # Builder settings
        panels[I18n.getMessage("Settings_for_1", builder.friendlyName)] = ctrls = {}
        for key, cfg of (builder.configurations or {})
          do (key, cfg) =>
            ctrl = {
              get: => builder[key]
              set: (v) => builder[key] = v
            }
            switch cfg.type
              when "boolean"  then ctrl.type = "checkbox"
              when "string"   then ctrl.type = "text"
              when "fixed"    then ctrl = builder[key]?.toString()
            ctrls[cfg.description.toString()] = ctrl
    else
      # Sketch
      notConf = "(#{I18n.getMessage("Not_configured")})"
      panels["{Sketch_overview}"] = ctrls = {}
      ctrls["{Name}"] = @_sketch?.friendlyName.toString()
      ctrls["{Board}"] = @_sketch?.board?.friendlyName.toString() or notConf
      ctrls["{Stored_location}"] =
        I18n.getMessage("fsType_#{@_sketch?.dirFs?.fsType or "Unknown"}")
      ctrls["{Startup_file}"] = {
        type: []
        get: => @_sketch.bootItem
        set: (v) => @_sketch.bootItem
      }
    @_generatePage(panels)
    return

  _generatePage: (panels) ->
    $ = @$
    div = $(".explorer-right").empty()
      .append('<div class="col-sm-12">').children("div")
    for pname, ctrls of panels
      body = $("#template-panel-table").children().clone().appendTo(div)
        .find(".panel-heading").text(I18n.translateText(pname)).end()
        .find("thead").remove().end()
        .find("tbody")
      for cname, ctrl of ctrls
        do (ctrl) =>
          if typeof(ctrl) == "string"
            value = ctrl
            ctrl = {type: "fixed", get: => value}
          switch ctrl?.type
            when "checkbox"
              input = $("#template-input-checkbox").children().clone()
                .appendTo(
                  $("#template-tr-td2").children().clone().appendTo(body).children("td")
                )
                .find(".placeholder").text(I18n.translateText(cname)).end()
                .find("input")
              input.prop("checked", ctrl.get()).click(=>
                ctrl.set(input.prop("checked"))
                return
              )
            when "text"
              input = $("#template-input-text").children().clone()
                .appendTo(
                  $("#template-tr-td2").children().clone().appendTo(body).children("td")
                ).find(".placeholder").text(I18n.translateText(cname)).end()
                .find("input")
              input.val(ctrl.get()).change(=>
                ctrl.set(input.val())
                return
              )
            when "fixed"
              $("#template-tr-td11").children().clone().appendTo(body).children("td")
                .eq(0).text(I18n.translateText(cname)).end()
                .eq(1).text(ctrl.get())
            when undefined
              null  # Do nothing
    return

  _selectSketch: ->
    $ = @$
    div = @_initPage()
    body = null
    tr = (titleId, value) =>
      $("#template-tr-td2").children().clone().appendTo(body).children("td")
        .eq(0).text(if titleId? then I18n.getMessage(titleId) else "").end()
        .eq(1).text(value or "").end()
    notConf = "(#{I18n.getMessage("Not_configured")})"

    body = $("#template-panel-table").children().clone().appendTo(div)
      .find(".panel-heading").text(I18n.getMessage("Sketch_overview")).end()
      .find("thead").remove().end()
      .find("tbody")
    tr("Name", @_sketch?.friendlyName)
    tr("Board", @_sketch.board?.friendlyName or notConf)
    tr("Stored_location", I18n.getMessage("fsType_#{@_sketch?.dirFs?.fsType}"))
    body = $("#template-panel").children().clone().appendTo(div)
      .find(".panel-heading").text(I18n.getMessage("Startup_file")).end()
      .find(".panel-body")
    ul = $("#template-dropdown").children().clone().appendTo(body)
      .find("button")
        .addClass("btn-sm").prop("disabled", !(@_sketch?.items?.length > 0))
        .find(".placeholder")
          .text(@_sketch?.bootItem or notConf)
        .end()
      .end()
      .find("ul")
    for item in (@_sketch?.items or [])
      continue unless item.builder?
      $('<li><a href="#">').appendTo(ul)
        .find("a").text(item.path)[0].dataset.path = item.path
    ul.find("li").click((event) =>
      path = $(event.currentTarget)[0]?.dataset.path
      return unless path?
      @_sketch?.bootItem = path
      ul.parent().find(".placeholder").text(path)
    )
    return

  _refreshTree: ->
    # Update root node
    @_rootNodeId or= jsTree.create_node(null, {text: "", type: "sketch"})
    jsTree.rename_node(@_rootNodeId, @sketch.friendlyName)

    # Get items
    items = @sketch.items.slice(0).sort((a, b) =>
      # Sort by path name (case insensitive)
      ap = a.path.toUpperCase()
      bp = b.path.toUpperCase()
      return -1 if ap < bp
      return +1 if ap > bp
      return 0
    )
    @_itemNodes or= {}

    # Remove invalid nodes
    idList = (k for k, v of @_itemNodes)
    for id in idList
      v = @_itemNodes[id]
      found = items.indexOf(v.item)
      if found < 0 or v.path != v.item.path
        jsTree.delete_node(id)
        delete @_itemNodes[id]

    # Add new nodes
    nextPos = 0
    for item in items
      nodeId = null
      for k, v of @_itemNodes
        if v.item == item
          nodeId = k
          break
      if nodeId
        # Already exists
        nextPos++
      else
        # New node
        nodeId = jsTree.create_node(@_rootNodeId, {
          text: item.path
          type: "file"
        }, nextPos++)
        @_itemNodes[nodeId] = {item: item, path: item.path}

    jsTree.open_node(@_rootNodeId)
    return

# Post dependencies
AsyncFs = require("filesystem/asyncfs")
App = require("app/app")
I18n = require("util/i18n")
