Function::property = (prop, desc) ->
  Object.defineProperty(@::, prop, desc)

Function::staticProperty = (prop, desc) ->
  Object.defineProperty(@, prop, desc)

Function::classProperty = (prop, desc) ->
  Object.defineProperty(@, prop, desc)

Function::getter = (prop, get) ->
  Object.defineProperty(@::, prop, {get, configurable: true})

Function::setter = (prop, set) ->
  Object.defineProperty(@::, prop, {set, configurable: true})

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
    stop = false
    e = {}
    Object.defineProperty(e, "type", {value: event.type.toLowerCase()})
    Object.defineProperty(e, "target", {value: this})
    Object.defineProperty(e, "stopPropagation", {value: -> stop = true; return})
    for k, v of event
      Object.defineProperty(e, k, {value: v}) unless e.hasOwnProperty(k)
    l = (@__listeners__ or {})
    a = (l[e.type] or= [])
    for listener in a
      if typeof(listener) == "function"
        fn = listener
      else if typeof(listener?.handleEvent) == "function"
        fn = listener.handleEvent.bind(listener)
      try
        fn?(e)
      catch error
        console.error(error)
      return false if stop
    return true

