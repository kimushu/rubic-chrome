###*
Declaration for pure class (non instantiatable)
###
Function::pureClass = ->
  throw new Error("#{@constructor.name} cannot be instantiated")

###*
@method
Escape special characters for HTML
###
escapeHtml = (content) ->
  TABLE =
    "&": "&amp;"
    "'": "&#39;"
    '"': "&quot;"
    "<": "&lt;"
    ">": "&gt;"
  content.replace(/[&"'<>]/g, (match) -> TABLE[match])

