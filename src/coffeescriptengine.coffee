###*
@class Rubic.CoffeeScriptEngine
  Script execution engine for CoffeeScript (Model)
@extends Rubic.Engine
###
class Rubic.CoffeeScriptEngine extends Rubic.Engine
  Rubic.Engine.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method
  ###
  build: (name, source, options = []) ->
    return Promise.resolve(
    ).then(=>
      dest = name.replace(/\.coffee$/i, "") + ".js"
      output = @constructor._module.compiler(source)
      return [{
        name: dest
        data: output
      }]
    ) # return Promise.resolve().then()


