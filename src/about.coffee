###*
@class
About dialog
###
class About
  @show: ->
    manifest = chrome.runtime.getManifest()
    msg = """
    <div class="row text-center"><span style="font-size: xx-large">#{manifest.name}</span></div>
    <div class="row text-center">Version: #{manifest.version}</div>
    <div class="row text-center">Rubic platform is supported by:</div>
    <div class="row text-center">
      <div class="col-md-4 text-center">
        <img class="supporter-logo" src="images/mruby_logo_red.svg" title="mruby">
      </div>
      <div class="col-md-4 text-center">
        <img class="supporter-logo" src="images/peridotcraft_logo_1.png" title="PERIDOT CRAFT">
      </div>
      <div class="col-md-4 text-center">
        <img class="supporter-logo" src="images/Emscripten_logo_full.png" title="Emscripten">
      </div>
    </div>
    """
    bootbox.dialog({
      # title: "About this application"
      message: msg
      # buttons: {
      #   success: {
      #     label: "Close"
      #     className: "btn-success"
      #   }
      # }
    })

