class Sketch
  files: []

  board: null

  editors: []

  @load: (baseurl) ->
    new Sketch baseurl

  constructor: (@baseurl) ->
    unless @baseurl
      now = new Date
      m2s = ["jan", "feb", "mar", "apr", "may", "jun",
             "jul", "aug", "sep", "oct", "nov", "dec"]
      base = "sketch_" + m2s[now.getMonth()] + now.getDate()
      doc = base + ".rb"
      @files.push(doc)
      @baseurl = "unsaved://" + base + "/" + doc

  save: ->
    e.save() for e in @editors

