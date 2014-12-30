Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

class Marshal
  @loadClass: (data, classes) ->
    for c in classes
      continue unless data.classname == c.name
      return c.load(data.content)
    null  # TODO: crash

  @saveClass: (instance) ->
    return {classname: instance.name, content: instance.save()}

