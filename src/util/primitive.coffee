Function::property = (prop, desc) ->
  Object.defineProperty(@prototype, prop, desc)

Function::classProperty = (prop, desc) ->
  Object.defineProperty(@, prop, desc)

Function::event = (type) ->
  (@__events__ or= []).push(type.toLowerCase())
  @prototype.addEventListener or= (type, listener) ->
    type = type.toLowerCase()
    if @constructor.__events__.includes(type)
      l = (@__listeners__ or= {})
      a = (l[type] or= [])
      a.push(listener) unless a.includes(listener)
    return
  @prototype.removeEventListener or= (type, listener) ->
    type = type.toLowerCase()
    l = (@__listeners__ or= {})
    a = (l[type] or= [])
    i = a.indexOf(listener)
    a.splice(i, 1) if i >= 0
    return
  @prototype.dispatchEvent or= (event) ->
    e = {}
    e[k] = v for k, v of event
    e.type = e.type.toLowerCase()
    e.target = this
    l = (@__listeners__ or {})
    a = (l[e.type] or= [])
    for listener in a
      return false if listener() == false
    return true

