class Sketch
  @defaultSuffix = ".rb"

  files: []

  modified: false

  @property('board',
    get: -> @_board
    set: (b) ->
      @_board = b
      @_board.selected()
  )

  @open: (baseurl) ->
    new Sketch baseurl

  constructor: (@baseurl) ->
    unless @baseurl
      now = new Date
      m2s = ["jan", "feb", "mar", "apr", "may", "jun",
             "jul", "aug", "sep", "oct", "nov", "dec"]
      base = "sketch_#{m2s[now.getMonth()] + now.getDate()}"
      @files.push(base + @constructor.defaultSuffix)
      @baseurl = "unsaved://#{base}/"

  save: ->
    e.save() for e in @editors

sketch = null # An instance of current sketch
sketch = new Sketch
