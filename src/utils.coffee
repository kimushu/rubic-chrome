###*
Declaration for pure (abstract) functions
###
Function::pure = ->
  throw new Error("#{@constructor.name}::#{arguments.callee.name} cannot be called")

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

