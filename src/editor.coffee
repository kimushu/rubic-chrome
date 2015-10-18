###*
@class Rubic.Editor
  Base class for editors/viewers (View)
###
class Rubic.Editor
  DEBUG = Rubic.DEBUG or 0

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
  @static
  @inheritable
  @method
    Get new file template
  @param {Object} header
    Header information
  @return {string}
    Template text
  ###
  @getTemplate: (header) ->
    return ""

  ###*
  @private
  @static
  @property {number}
    Next unique number for editor IDs
  ###
  @_nextIdNumber: 0

  ###*
  @protected
  @property {Rubic.WindowController}
    Controller for this view
  @readonly
  ###
  controller: null

  ###*
  @protected
  @property {jQuery}
    jQuery object for this view
  @readonly
  ###
  $: null

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
  @param {Rubic.WindowController} controller
    Controller for this view
  @param {FileEntry} [fileEntry]
    FileEntry for this document
  @param {DOMElement/null} [element]
    DOMElement for this editor (if null, new &lt;div&gt; element will be created)
  ###
  constructor: (@controller, @fileEntry, @element) ->
    @$ = @controller.$
    @_editorId = "editor_#{Editor._nextIdNumber++}"
    @element or= (@$("#content-wrapper").append("""
      <div class="editor" id="#{@_editorId}"></div>
    """).find("##{@_editorId}")[0])
    @_name = @fileEntry?.name
    @_updateTab() if @_name
    return

  ###*
  @static
  @method
    Guess editor class from filename
  @param {string} name
    File name
  @return {Function}
    Constructor of editor (return void if no suitable class)
  ###
  @guessEditorClass: (name) ->
    suffix = (name.match(/\.([^.]+)$/) or [])[1]
    return unless suffix
    suffix = suffix.toLowerCase()
    for editorClass in @_editors
      return editorClass if editorClass.SUFFIXES.includes(suffix)
    return

  ###*
  @static
  @method
    Create an editor with automatic filetype selection
  @param {Rubic.WindowController} controller
    Controller for this view
  @param {FileEntry}  fileEntry
    FileEntry to open
  @return {Editor}
    Generated instance of editor (return void if no suitable class)
  ###
  @createEditor: (controller, fileEntry) ->
    editorClass = @guessEditorClass(fileEntry.name)
    return unless editorClass
    return new editorClass(controller, fileEntry)

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
  @param {function(Rubic.Editor):void}  handler
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
  @param {function(Rubic.Editor):void}  handler
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
    elem = @$("##{tabId}")
    if remove
      elem?.remove()
      return
    unless elem[0]
      name = @_name or @fileEntry?.name
      elem = @$("""
        <li id="#{tabId}">#{name}
          <span class="modified" style="display: none;"> *</span>
        </li>
      """)
      elem.click(=>
        (handler = @_onSelectRequest)?(this)
      )
      @$("#editor-tabbar").append(elem)

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
    @$(".editor-active").removeClass("editor-active")
    @$("ul.tabbar > li.active").removeClass("active")
    @$(@element).addClass("editor-active")
    @$("##{@_editorId}-tab").addClass("active")
    callback(true)
    return

  ###*
  @event
    Register handler for change event
  @param {function(Rubic.Editor,boolean):void} handler
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
    @$("##{@_editorId}").remove()
    @_updateTab(true)
    callback(true)
    return

