###*
@class
Hardware catalog
###
class HardwareCatalog
  WINDOW_ID = "HardwareCatalog"

  #----------------------------------------------------------------
  # Class variables/methods

  ###*
  @static
  Show hardware catalog window
  ###
  @show: () ->
    (@_instance or= new HardwareCatalog).open()

  ###*
  @static
  Hide hardware catalog window
  ###
  @hide: () ->
    @_instance?.close()

  ###*
  @static
  Register feature realization class
  ###
  @addFeature: (feature_class) ->
    @_feature_classes[feature_class.name] = feature_class

  ###*
  @static
  @private
  Only instance of this class (singleton)
  ###
  @_instance: null

  ###*
  @static
  @private
  Dictionary of feature classes
  ###
  @_feature_classes: {}

  #----------------------------------------------------------------
  # Instance variables/methods

  ###*
  Open new window / Bring existing window to top
  ###
  open: () ->
    return @_appWindow.focus() if @_appWindow
    chrome.app.window.create(
      "catalog.html",
      {id: WINDOW_ID},
      (createdWindow) =>
        @_appWindow = createdWindow
        @_appWindow.onClosed.addListener(=> @_appWindow = null)
        $(@_appWindow.contentWindow).load(=>
          @_onLoad(@_appWindow.contentWindow.jQuery)
        )
    )

  ###*
  Close window
  ###
  close: () ->
    @_appWindow?.close()

  ###*
  @private
  Chrome AppWindow instance
  ###
  _appWindow: null

  ###*
  @private
  Construct window events and actions
  @param {jQuery} $   jQuery object of catalog window
  ###
  _onLoad: ($) ->
    # return
    console.log({_onLoad: {$: $}})
    GitHubRepoFileSystem.requestFileSystem(
      "kimushu",
      "rubic-catalog",
      {branch: "master"},
      ((fs) =>
        console.log({githubfs: fs})
        fs.root.getFile(
          "sites.json",
          {},
          ((entry) =>
            console.log({getFile: entry})
            FileUtil.readText(entry, (result, readdata) =>
              return console.log("readText failed") unless result
              sites = JSON.parse(readdata)
              console.log({sites: sites})
              return unless App.checkVersion(sites.rubic_version)
              @_addSite($, site) for site in sites.sites
              null
            ) # readText
          ),
          (-> console.log("getFile failed"))
        ) # getFile
      ),
      (-> console.log("GitHubRepoFileSystem request failed"))
    )
    null

  _addSite: ($, site) ->
    console.log({_addSite: {$: $, site: site}})
    return unless App.checkVersion(site.rubic_version)
    $("#catalog").append("""
    <div class="card-group" id="#{site.uuid}">
      <div class="card-group-header">
        <span id="glyphicon glyphicon-menu-down"></span> #{I18nS(site.name)}
      </div>
    </div>
    """)
    elem = $("#catalog").find("##{site.uuid}")
    switch site.service
      when "github"
        requester = (sc, ec) ->
          GitHubRepoFileSystem.requestFileSystem(
            site.owner,
            site.repo,
            site.ref,
            (fs) -> sc(fs.root),
            ec
          ) # requestFileSystem
      when "local"
        requester = (sc, ec) ->
          navigator.webkitPersistentStorage.queryUsageAndQuota(
            ((used, granted) ->
              window.webkitRequestFileSystem(
                window.PERSISTENT,
                granted,
                (fs) -> sc(fs.root),
                ec
              ) # webkitRequestFileSystem
            ),
            ec
          ) # queryUsageAndQuota
    return console.log("warning: unsupported service") unless requester
    requester((root) =>
      root.getFile(
        "catalog.json",
        {},
        ((entry) =>
          FileUtil.readText(entry, (result, readdata) =>
            return console.log("readText failed") unless result
            items = JSON.parse(readdata)
            console.log({items: items})
            @_addItem(elem, item) for item in items
            null
          ) # readText
        ),
        (-> console.log("getFile() failed"))
      ) # getFile
    ) # requester

  _addItem: (elem, item) ->
    console.log({_addItem: {elem: elem, item: item}})
    elem.append("""
      <div class="card" id="#{item.uuid}">
        <div class="card-header">
          <img class="card-icon" src="#{item.icon}" width="48px" height="48px">
          <div class="card-title">#{I18nS(item.name)}</div>
          <div class="card-versions">
            <button class="btn btn-xs dropdown-toggle" type="button" data-toggle="dropdown"
             aria-haspopup="true" aria-expanded="true">
              #{item.versions[0].display_name} <span class="caret"></span>
            </button>
            <ul class="dropdown-menu"></ul>
          </div>
        </div>
        <div class="card-features"></div>
        <div class="card-desc"></div>
      </div>
    """)
    el_card = elem.find("##{item.uuid}")
    el_vers = el_card.find(".card-versions")
    el_feas = el_card.find(".card-features")
    for name, detail of item.versions[0].features
      console.log(@constructor._feature_classes)
      console.log(detail)
      console.log(detail["class"])
      color = @constructor._feature_classes[detail.class]?.FEATURE_COLOR
      if color
        el_feas.append("""
          <span class="label" style="background-color: #{color};">#{name}</span>\n
        """)
      else
        el_feas.append("""
          <span class="label label-default">#{name}</span>\n
        """)
    el_desc = el_card.find(".card-desc")
    el_desc.append(I18nS(item.versions[0].description))
    null

console.log({"HardwareCatalog": HardwareCatalog})

