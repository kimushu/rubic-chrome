# Pre dependencies

###*
@class App
  Application top class (Not instanciatable)
###
class App
  null

  # Version emulation for browser view
  VER_EMULATION = "2.0.0"

  # Conversion from version string to integer
  v2i = (v) ->
    [p1, p2, p3, p4] = v.split(".", 4).map((p) -> parseInt(p) & 0xffff)
    return (p1 << 48) | (p2 << 32) | (p3 << 16) | (p4 << 0)

  ###*
  @static
  @property {string}
    Version string for Rubic
  @readonly
  ###
  @classProperty("version", value: chrome.runtime.getManifest?()["version"] or VER_EMULATION)

  ###*
  @static
  @method
    Check if current version matches an version-check expression
  @param {string} versionExpr
    Expression for version check
  @return {boolean}
    Result of version check
  ###
  @versionCheck: (expr) ->
    return true unless expr?
    current = v2i(@version)
    for expr2 in expr.split(",")
      result = true
      for expr3 in expr.split("&")
        [operator, value] = expr3.trim().split(" ")
        target = v2i(value)
        switch operator
          when ">"  then result and= (current >  target)
          when "<"  then result and= (current <  target)
          when ">=" then result and= (current >= target)
          when "<=" then result and= (current >= target)
          when "==" then result and= (current == target)
          else result = false
        break unless result
      return true if result
    return false

module.exports = App
