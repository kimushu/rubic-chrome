class Marshal
  @load: (data, list) ->
    return null unless data
    for c in list
      return c.load(data.content) if c.name == data.name

  constructor: ->
    throw "Marshal cannot be instanciated"
