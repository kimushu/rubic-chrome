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
  @static
  @inheritdoc Editor#editable
  @readonly
  ###
  @editable: true


  ###*
  @static
  @property {boolean} closable
    Is editor closable
  @readonly
  ###
  @closable: false

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
  FILE_ICONTYPE = {true: "file_transfer", false: "file"}

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
    @_selectedItem = null
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
        file_transfer:
          icon: "glyphicon glyphicon-save-file"
      plugins: ["types"]
    })
    jsTree = jqTreeElement.jstree(true)
    e = "select_node.jstree"
    jqTreeElement.unbind(e).on(e, (event, data) =>
      @_selectedItem = @_itemNodes[data.node.id]?.item
      @_selectItem()
    )
    e = "dblclick.jstree"
    jqTreeElement.unbind(e).on(e, (event) =>
      item = @_itemNodes[$(event.target).closest("li")[0]?.id]?.item
      return unless item == @_selectedItem and item?
      $(".explorer-open").click()
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
    @sketch.addEventListener("save.sketch", this)
    @sketch.addEventListener("change.sketch", this)
    @sketch.addEventListener("additem.sketch", this)
    @sketch.addEventListener("removeitem.sketch", this)
    return

  ###*
  @inheritdoc Editor#deactivate
  ###
  deactivate: ->
    return super()

  ###*
  @method
    Event handler
  @param {Object} event
    Event object
  @return {undefined}
  ###
  handleEvent: (event) ->
    switch event.type
      when "save.sketch"
        @modified = false
        @dispatchEvent({type: "changetitle.editor"})
      when "change.sketch"
        @modified = true
        @dispatchEvent({type: "change.editor"})
      when "additem.sketch"
        @_refreshTree()
        for k, v of @_itemNodes
          if event.item.path == v.path
            jsTree.deselect_all()
            jsTree.select_node(k)
            break
      when "removeitem.sketch"
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
      return App.safeConfirm_yes_no(
        title: "{File_overwrite}"
        rawMessage: I18n.getMessage("Are_you_sure_to_replace_existing_file_1_with_new_one", name)
      )
    ).then((result) =>
      return unless result == "yes"
      @sketch.removeItem(name)
      return fs.readFile(name).then((data) =>
        item = @sketch.getItem(name, true)
        return item.writeContent(data)
      )
    ) # return AsyncFs.chooseFile()...

  _openItem: ->
    item = @_selectedItem
    return unless item?
    editor = item.editor
    unless editor?
      editorClass = Editor.findEditor(item)
      unless editorClass?
        App.popupError(I18n.getMessage("Cannot_find_editor"))
        return false
      editor = new editorClass(@$, @_sketch, item)
    MainController.instance.addEditor(editor, null, true)
    return true

  _renameItem: ->
    item = @_selectedItem
    return unless item?
    oldPath = item.path
    dirs = oldPath.split("/")
    oldName = dirs.pop()
    return Promise.resolve(
    ).then(=>
      return global.bootbox.prompt_p({
        title: I18n.getMessage("Input_new_name_for_1", oldName)
        value: oldName
      })  # return global.bootbox.prompt_p()
    ).catch(=>
      return  # Cancelled
    ).then((newName) =>
      return unless newName?
      return if newName == oldName  # No change
      newPath = dirs.concat(newName).join("/")
      return item.rename(newPath).then(=>
        return item.sketch.setupItems()
      )
    ) # return Promise.resolve().then()...

  _removeItem: ->
    item = @_selectedItem
    return unless item?
    return Promise.resolve(
    ).then(=>
      return App.safeConfirm_yes_no(
        title: "{File_remove}"
        rawMessage: I18n.getMessage("Are_you_sure_to_remove_file_1", item.path)
      )
    ).then((result) =>
      return unless result == "yes"
      return item.removeContent().catch(=>
        return
      ).then(=>
        return item.sketch.removeItem(item)
      )
    ) # return Promise.resolve().then()...
    return

  _selectItem: ->
    $ = @$
    item = @_selectedItem
    $(".explorer-open").prop("disabled", !item?)
    $(".explorer-rename").prop("disabled", !item? or !!(item?.source?))
    $(".explorer-remove").prop("disabled", !item? or !!(item?.source?))
    return @_generatePageForItems(item) if item?
    unless App.sketch?.board?
      App.popupInfo(
        """
        <span class="glyphicon glyphicon-share-alt"
          style="transform: matrix(0, 1, 1, 0, 0, 0);"></span>
        #{I18n.getMessage("Hint_select_board")}
        """
        null
        "sw"
      )
    return @_generatePageForSketch()

  _generatePageForItems: (item) ->
    panels = {}
    panels["{File_overview}"] = ctrls = {}
    dirs = item.path.split("/")
    ctrls["{Name}"] = dirs.pop()
    ctrls["{Folder}"] = dirs.join("/") if dirs.length > 0
    ctrls["{FileType}"] = item.fileType?.toString() or I18n.getMessage("Unknown")
    ctrls["{Generated_from}"] = item.source?.path
    ctrls["{Transfer_to_board}"] = {
      type: "checkbox"
      get: => item.transfer
      set: (v) =>
        item.transfer = v
        for id, info of @_itemNodes
          if info.item == item
            jsTree.set_type(id, FILE_ICONTYPE[!!v])
            break
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
    @_generatePage(panels)
    return

  _generatePageForSketch: ->
    panels = {}
    Promise.resolve(
    ).then(=>
      return @_sketch?.board?.loadFirmRevision()
    ).then((firmRevision) =>
      panels["{Sketch_overview}"] = ctrls = {}
      ctrls["{Name}"] = @_sketch?.friendlyName.toString()
      ctrls["{Board}"] = @_sketch?.board?.friendlyName.toString() or I18n.getMessage("Not_configured")
      ctrls["{Stored_location}"] =
        I18n.getMessage("fsType_#{@_sketch?.dirFs?.fsType or "Unknown"}")
      bootables = []
      executables = firmRevision?.executables or []
      for item in @_sketch.items
        path = item.path
        for e in executables
          if e.test(path)
            bootables.push(path)
            break
      panels["{Startup_settings}"] = ctrls = {}
      ctrls["{Executable_file}"] = {
        type: bootables
        get: => @_sketch.bootItem
        set: (v) => @_sketch.bootItem = v
      }
    ).then(=>
      @_generatePage(panels)
    )
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
          type = ctrl?.type
          type = "list" if type instanceof Array
          switch type
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
            when "list"
              td = $("#template-tr-td11").children().clone().appendTo(body).children("td")
                .eq(0).text(I18n.translateText(cname)).addClass("vmiddle").end()
                .eq(1)
              dd = $("#template-dropdown").children().clone().appendTo(td)
              dd.find("button .placeholder").text("N/A")
              ul = dd.children("ul")
              selected = null
              sel_item = ctrl.get()
              for item, index in ctrl.type
                a = $("#template-dropdown-item").children().clone().appendTo(ul)
                  .find(".placeholder").text(item).closest("a")
                a[0].dataset.index = index
                selected = a if item == sel_item
              if ctrl.type.length == 0
                dd.find("button").prop("disabled", true)
              ul.find("a").click((event) =>
                index = parseInt($(event.currentTarget)[0].dataset.index)
                item = ctrl.type[index]
                return unless item?
                ul.closest(".dropdown").find(".placeholder").eq(0).text(item)
                ctrl.set(item) if ctrl.get() != item
                return
              )
              selected?.click()
            when undefined
              null  # Do nothing
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
          type: FILE_ICONTYPE[!!item.transfer]
        }, nextPos++)
        @_itemNodes[nodeId] = {item: item, path: item.path}

    jsTree.open_node(@_rootNodeId)
    nodeId = null
    for k, v of @_itemNodes
      if v.item == @_selectedItem
        nodeId = k
        break
    jsTree.select_node(nodeId or @_rootNodeId)
    return

# Post dependencies
AsyncFs = require("filesystem/asyncfs")
App = require("app/app")
I18n = require("util/i18n")
MainController = require("controller/maincontroller")
