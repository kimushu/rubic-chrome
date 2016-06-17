throw Error("This tester cannot be used in Chrome App/Extensions") if chrome.i18n?
console.warn("chrome.i18n is provided as an emulation module for language \"#{L}\"")

chrome.i18n =
  getAcceptLanguages: (callback) ->
    callback([L])
    return

  getMessage: (id, subs...) ->
    i = M[id]
    m = i?.message
    return "" unless m?
    m = m.replace(/\$([1-9$])/g, (match, number) ->
      return "$" if number == "$"
      return subs[parseInt(number) - 1] or ""
    )
    return m

  getUILanguage: ->
    return L

