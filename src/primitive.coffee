Function::property = (prop, desc) ->
  Object.defineProperty(@prototype, prop, desc)

Function::classProperty = (prop, desc) ->
  Object.defineProperty(@, prop, desc)

