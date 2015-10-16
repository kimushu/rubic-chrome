###*
@class Editor
  Base class for editors/viewers (View)
###
class Editor
  DEBUG = if DEBUG? then DEBUG else 0

  ###*
  @private
  @static
  @property {Function[]}
    List of subclasses
  ###
  @_editors: []

  ###*
  @protected
  @static
  @method
    Register editor class
  @param {Function} editorClass
    Constructor of subclass
  @return {void}
  ###
  @addEditor: (editorClass) ->
    @_editors.push(editorClass)
    return

  ###*
  @static
  @inheritable
  @cfg {string[]}
    List of suffixes
  @readonly
  ###
  @SUFFIXES: []

  ###*
  @static
  @inheritable
  @cfg {boolean}
    Editable or not
  @readonly
  ###
  @EDITABLE: false

  ###*
  @private
  @static
  @property {number}
    Next unique number for editor IDs
  ###
  @_nextIdNumber: 0

  ###*
  @private
  @property {string}
    Unique ID of this editor
  @readonly
  ###
  _editorId: null

  ###*
  @protected
  @property {FileEntry}
    FileEntry for this document
  @readonly
  ###
  fileEntry: null

  ###*
  @protected
  @property {DOMElement}
    DOM Element for this editor
  @readonly
  ###
  element: null

  ###*
  @property {boolean}
    Document is modified or not
  @readonly
  ###
  modified: null

  ###*
  @protected
  @method constructor
    Constructor
  @param {FileEntry} fileEntry
    FileEntry for this document
  @param {DOMElement/null} element
    DOMElement for this editor (if null, new &lt;div&gt; element will be created)
  ###
  constructors: (@fileEntry, @element) ->
    @_editorId = "editor_#{@constructor._nextIdNumber++}"
    @element or= $("content-wrapper").append("""
      <div class="editor" id="#{@_editorId}></div>
    """).find("##{@_editorId}")[0]
    return

  ###*
  @static
  @method
    Create an editor with automatic filetype selection
  @param {FileEntry}  fileEntry
    FileEntry to open
  @return {Editor}
    Generated instance of editor (return void if no suitable class)
  ###
  createEditor: (fileEntry) ->
    suffix = (fileEntry.name.match(/\.([^.]+)$/) or [])[1]
    return unless suffix
    for editorClass in @_editors
      if editorClass.SUFFIXES.includes(suffix)
        return new editorClass(fileEntry)
    return

  ###*
  @private
  @property {string/null}
    Name of this editor
  ###
  _name: null

  ###*
  @method
    Set name of this editor
  @param {string} name
    New name
  @return {void}
  ###
  setName: (name) ->
    @_name = name
    @_updateTab()
    return

  ###*
  @event
    Register handler for select request
  @param {function(Editor):void}  handler
    Event handler
  @return {void}
  ###
  onSelectRequest: (handler) ->
    @_onSelectRequest = handler
    return

  ###*
  @protected
  @method
    Fire select request event
  @return {void}
  ###
  fireSelectRequest: ->
    (handler = @_onSelectRequest)?(this)
    return

  ###*
  @event
    Register handler for close request
  @param {function(Editor):void}  handler
    Event handler
  @return {void}
  ###
  onCloseRequest: (handler) ->
    @_onCloseRequest = handler
    return

  ###*
  @protected
  @method
    Fire close request event
  @return {void}
  ###
  fireCloseRequest: ->
    (handler = @_onCloseRequest)?(this)
    return

  ###*
  @private
  @method
    Update tab
  @param {boolean} [remove=false]
    Remove tab
  @return {void}
  ###
  _updateTab: (remove) ->
    tabId = @_editorId + "-tab"
    elem = $("##{tabId}")
    if remove
      elem?.empty()
      return
    unless elem
      elem = $("""
        <li id="#{@_tabId}">#{@_name or @fileEntry?.name or ""}
          <span class="modified" style="display: none;"> *</span>
        </li>
      """)
      elem.click(=>
        (handler = @_onSelectRequest)?(this)
      )
      $("#editor-tabbar").append(elem)

    mod = elem.find(".modified")
    if @modified
      mod.removeClass("not-modified")
    else
      mod.addClass("not-modified")
    return

  ###*
  @method
    Activate editor
  @param {function(boolean):void} callback
    Callback function with result
  @return {void}
  ###
  activate: (callback) ->
    callback(false)
    return

  ###*
  @event
    Register handler for change event
  @param {function(Editor,boolean):void} handler
    Event handler
  @return {void}
  ###
  onChange: (handler) ->
    @_onChange = handler
    return

  ###*
  @protected
  @method
    Fire change event
  @return {void}
  ###
  fireChange: ->
    (handler = @_onChange)?(this, @modified)
    return

  ###*
  @method
    Load document
  @param {function(boolean):void} callback
    Callback function with result
  @return {void}
  ###
  load: (callback) ->
    callback(false)
    return

  ###*
  @method
    Save document
  @param {function(boolean):void} callback
    Callback function with result
  @return {void}
  ###
  save: (callback) ->
    callback(false)
    return

  ###*
  @method
    Close document
  @param {function(boolean):void} callback
    Callback function with result
  @return {void}
  ###
  close: (callback) ->
    callback(false)
    return

