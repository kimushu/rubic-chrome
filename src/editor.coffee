###*
@class Rubic.Editor
  Base class for editors/viewers (View)
###
class Rubic.Editor
  DEBUG = Rubic.DEBUG or 0

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
    (@_editors or= {})[editorClass.name] = editorClass
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
  @property {Rubic.WindowController} controller
    Controller for this view
  @readonly
  ###
  @property("controller", get: -> @_controller)

  ###*
  @protected
  @property {jQuery} $
    jQuery object for this view
  @readonly
  ###
  @property("$", get: -> @_$)

  ###*
  @protected
  @property {FileEntry} fileEntry
    FileEntry for this document
  @readonly
  ###
  @property("fileEntry", get: -> @_fileEntry)

  ###*
  @protected
  @property {DOMElement} element
    DOM Element for this editor
  @readonly
  ###
  @property("element", get: -> @_element)

  ###*
  @property {boolean} modified
    Document is modified or not
  @readonly
  ###
  @property("modified",
    get: -> @_modified
    set: (value) ->
      value = !!value
      return if @_modified == value
      @_onChange.dispatchEvent(this, (@_modified = value))
  )

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
  constructor: (@_controller, @_fileEntry, @_element) ->
    @_onSelectRequest = new Rubic.EventTarget()
    @_onCloseRequest = new Rubic.EventTarget()
    @_onChange = new Rubic.EventTarget()
    @onChange.addEventListener(=> @_updateTab())
    @_$ = @controller.$
    @_editorId = "editor_#{Editor._nextIdNumber++}"
    @_element or= (@$("#content-wrapper").append("""
      <div class="editor" id="#{@_editorId}"></div>
    """).find("##{@_editorId}")[0])
    @_name = @fileEntry?.name
    @_updateTab()
    @_modified = false
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
    suffix = name.match(/\.([^.]+)$/)?[1]?.toLowerCase()
    return unless suffix
    for name, editorClass of @_editors
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
  @return {Rubic.Editor}
    Generated instance of editor (return void if no suitable class)
  ###
  @createEditor: (controller, fileEntry) ->
    editorClass = @guessEditorClass(fileEntry.name)
    return unless editorClass
    return new editorClass(controller, fileEntry)

  ###*
  @property {string} name
    Name of this editor
  ###
  @property("name",
    get: -> "#{@_name or @fileEntry?.name}"
    set: (value) ->
      @_name = "#{value}"
      @_updateTab()
  )

  ###*
  @event onSelectRequest
    Editor select request event target
  @param {Rubic.Editor} editor
    The instance of editor
  @return {void}
  ###
  @property("onSelectRequest", get: -> @_onSelectRequest)

  ###*
  @event onCloseRequest
    Editor close request eevent target
  @param {Rubic.Editor} editor
    The instance of editor
  @return {void}
  ###
  @property("onCloseRequest", get: -> @_onCloseRequest)

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
    if elem[0]
      elem.find(".name").text(@name)
    else
      elem = @$("""
        <li id="#{tabId}"><span class="name">#{@name}</span>
          <span class="modified"> *</span>
        </li>
      """)
      elem.click(=>
        @onSelectRequest.dispatchEvent(this)
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
    @$("##{@_editorId}-tab").addClass("active")
    @$(@element).addClass("editor-active")
    callback(true)
    return

  ###*
  @event onChange
    Change event target
  @param {Rubic.Editor} editor
    The instance of editor
  @param {boolean}  state
    Change state (true: modified, false: not modified)
  @return {void}
  ###
  @property("onChange", get: -> @_onChange)

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
    @_editorId = null
    callback(true)
    return

