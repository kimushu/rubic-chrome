###*
@class Rubic
###
###*
@method I18n
  Get localized message from message ID
@param {string} id
  ID of message
@param {string} [args]
  List of string to substitute
@return {string} Localized message
###
Rubic.I18n = (id, args...) ->
  XESCAPE = {c: ":", p: ".", q: "?", s: " ", x: "X"}
  m = chrome.i18n.getMessage(id, [args...])
  return m.escapeHtml() if m != ""
  m = id
  m = m.replace(/X([cpqsx])/g, (n, p1) -> "#{XESCAPE[p1]}")
  m = m.replace(/([.?])([A-Z])/g, (n, p1, p2) -> "#{p1} #{p2}")
  m = m.replace(/([A-Za-z])([A-Z])/g, (n, p1, p2) -> "#{p1} #{p2.toLowerCase()}")
  m = m.replace(/_/g, ' ')
  return m.escapeHtml()

Rubic.I18nS = (dict) ->
  return dict if typeof dict == "string"
  return dict[chrome.i18n.getUILanguage()] or dict["en"]

###*
@method I18nT
  Translate all elements in the window
@param {Object} JQuery object to process
@return {void}
###
Rubic.I18nT = ($) ->
  pat = /__MSG_([A-Za-z0-9]+)__/
  rep = (text, setter) ->
    return unless text
    newText = text.replace(pat, (m, p1) -> Rubic.I18n(p1))
    setter(newText) if newText != text
  $(".i18n").each((i, v) ->
    e = $(v)
    rep(e.attr?("title"), (t) -> e.attr("title", t))
    rep(e.attr?("placeholder"), (t) -> e.attr("placeholder", t))
    rep(e.html(), (t) -> e.html(t))
  )
  return

