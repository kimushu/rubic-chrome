I18n = (args...) ->
  m = chrome.i18n.getMessage(args...)
  return escapeHtml(m) if m != ""
  m = args[0].replace(/(.)([A-Z][a-z])/g, (m, p1, p2) -> "#{p1} #{p2.toLowerCase()}")
  m = m.replace(/_/g, ' ')
  escapeHtml(m)

$(->
  pat = /__MSG_([A-Za-z0-9]+)__/
  $("a,button").each((i, v) ->
    e = $(v)
    title = e.attr?("title")
    if title
      newTitle = title.replace(pat, (m, p1) -> I18n(p1))
      e.attr("title", newTitle) if title != newTitle
    html = e.html()
    return true unless html
    newHtml = html.replace(pat, (m, p1) -> I18n(p1))
    e.html(newHtml) if html != newHtml
  )
)
