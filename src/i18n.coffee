I18n = (id, args...) ->
  m = chrome.i18n.getMessage(id, [args...])
  return escapeHtml(m) if m != ""
  m = id.replace(/(.)([A-Z][a-z])/g, (m, p1, p2) -> "#{p1} #{p2.toLowerCase()}")
  m = m.replace(/_/g, ' ')
  escapeHtml(m)

I18nS = (dict) ->
  return dict if typeof dict == "string"
  dict[chrome.i18n.getUILanguage()] or dict["en"]

I18nW = ($) ->
  pat = /__MSG_([A-Za-z0-9]+)__/
  rep = (text, setter) ->
    return unless text
    newText = text.replace(pat, (m, p1) -> I18n(p1))
    setter(newText) if newText != text
  $(".i18n").each((i, v) ->
    e = $(v)
    rep(e.attr?("title"), (t) -> e.attr("title", t))
    rep(e.attr?("placeholder"), (t) -> e.attr("placeholder", t))
    rep(e.html(), (t) -> e.html(t))
  )

$(-> I18nW($))
