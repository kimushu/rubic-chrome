###*
@class
Hardware catalog
###
class HardwareCatalog
  WINDOW_ID = "HardwareCatalog"
  SEARCH_DELAY_MS = 300

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
      "win_catalog.html",
      {id: WINDOW_ID, innerBounds: {minWidth: 480, width: 640, height: 480}},
      (createdWindow) =>
        @_appWindow = createdWindow
        @_appWindow.onClosed.addListener(=> @_appWindow = null)
        $(@_appWindow.contentWindow).load(=>
          @$ = @_appWindow.contentWindow.jQuery
          @_uiOnLoad()
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
  Array of all configurations
  ###
  _items: []

  ###*
  @private
  Download a configuration to local persistent storage
  @param {String}   c_uuid    UUID of configuration
  @param {String}   v_uuid    UUID of version
  @param {Function} callback  Callback ({Boolean} result)
  ###
  _download: (c_uuid, v_uuid) ->
    src = (i for i in @_items when i.uuid == c_uuid)[0]
    return unless src
    merge = (json) ->
      dest = (i for i in json when i.uuid == c_uuid)[0]
      unless dest
        dest = {}
        #json.push(dest)
      # Merge only non-object (scalar data) fields
      dest[k] = v for k, v of src when typeof v != "object"
      dest.offline = true
      # Merge versions
      dest.versions or= []
      for srcv in src.versions
        do (srcv) ->
          i = (i for v, i in dest.versions when v.uuid == srcv.uuid)[0]
          if i
            dest.versions[i] = srcv
          else
            dest.versions.push(srcv)
      json
    FileUtil.requestPersistentFileSystem((fs) =>
      catalog = [fs.root, "catalog.json"]
      FileUtil.readJSON(catalog, (result, readdata) =>
        json = merge(if result then readdata else [])
        FileUtil.writeJSON(catalog, json, (result) =>
          console.log("error: cannot write catalog on local") unless result
          @close()
          @_spin.hide()
        )
      )
    )

  ###*
  @private
  Select a configuratio
  ###
  _uiSelect: (c_uuid, v_uuid) ->
    @$("##{c_uuid}-select").find(".ph-name").text(I18n("Loading"))
    @_spin.modal({show: true, backdrop: "static", keyboard: false})
    @_download(c_uuid, v_uuid)

  ###*
  @private
  Construct window events and actions
  ###
  _uiOnLoad: () ->
    I18nW(@$)
    @_spin = @$("#modal-spin").spin({color: "#fff"})
    @$("#refresh").click(=> @_refresh(true))
    @$("#search").bind("input", (=> @_search(false)))
      .keydown((e) => @_search(true) if e.keyCode == 13)
    @_refresh(false)

  ###*
  @private
  Search (filter) catalog
  ###
  _search: (now) ->
    window.clearTimeout(@_searchDelayTimer) if @_searchDelayTimer
    unless now
      @_searchDelayTimer = window.setTimeout((=> @_search(true)), SEARCH_DELAY_MS)
      return
    $ = @$
    word = $("#search").val().trim()
    # remove all markers
    $("mark").each(-> $(this).replaceWith(this.childNodes))
    if word != ""
      reg = new RegExp(word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "gi")
      # add markers
      rep = (t) -> t.replace(reg, "<mark>$&</mark>")
      $(".card").each(->
        name = $(this).find(".card-title > .ph-name")
        name.html(rep(name.html()))
        desc = $(this).find(".card-desc")
        desc.html(rep(desc.html()))
      )
    # hide unmarked cards
    $(".card").each(->
      if $(this).find("mark").size() > 0 or word == ""
        $(this).show()
      else
        $(this).hide()
    )

  ###*
  @private
  Refresh catalog
  ###
  _refresh: (force) ->
    @$("#catalog").empty()
    @_items = []
    @_addSite({service: "local"})
    GitHubRepoFileSystem.requestFileSystem(
      "kimushu",
      "rubic-catalog",
      {branch: "master"},
      ((fs) =>
        FileUtil.readText([fs.root, "sites.json"], (result, readdata) =>
          return console.log("readText failed") unless result
          sites = JSON.parse(readdata)
          # console.log({sites: sites})
          return unless App.checkVersion(sites.rubic_version)
          @_addSite(site) for site in sites.sites
          null
        ) # readText
      ),
      (-> console.log("GitHubRepoFileSystem request failed"))
    )
    null

  ###*
  @private
  Add items from a site
  @param {String} site.service  Name of service
  ###
  _addSite: (site) ->
    return unless App.checkVersion(site.rubic_version)
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
          FileUtil.requestPersistentFileSystem(
            (fs) -> sc(fs.root)
            ec
          )
    return console.log("warning: unsupported service") unless requester
    requester((root) =>
      FileUtil.readText([root, "catalog.json"], (result, readdata) =>
        return console.log("readText failed") unless result
        items = JSON.parse(readdata)
        # console.log({items: items})
        @_addItem(item) for item in items
        null
      ) # readText
    ) # requester

  _addItem: (item) ->
    @_items.push(item)
    elem = @$("#catalog")
    elem.append("""
      <div class="card" id="#{item.uuid}">
        <div class="card-header">
          <img class="card-icon" src="#{item.icon}" width="48px" height="48px">
          <div class="card-title">
            <span class="ph-name">#{I18nS(item.name)}</span>
            <div class="btn-group btn-group-xs pull-right">
              <button class="btn btn-selected" id="#{item.uuid}-select"><span
               class="glyphicon glyphicon-play"></span> <span class="ph-name"></span></button>
            </div>
          </div>
          <div class="card-versions dropdown">
            <button class="btn btn-xs dropdown-toggle" type="button" data-toggle="dropdown"
             id="#{item.uuid}-versions" aria-haspopup="true"
             aria-expanded="false"><span class="ph-name"></span> <span class="caret"></span>
            </button>
            <ul class="dropdown-menu" alia-labelledby="#{item.uuid}-versions"></ul>
          </div>
        </div>
        <div class="card-features"></div>
        <div class="card-desc"></div>
      </div>
    """)
    el_card = elem.find("##{item.uuid}")
    el_vern = el_card.find(".card-versions")
    el_vers = el_vern.find("ul")
    el_feas = el_card.find(".card-features")
    for ver in item.versions
      do (ver) =>
        el_vers.append("""
          <li class="btn-xs"><a href="#" id="#{ver.uuid}">#{ver.display_name}</a></li>
        """).find("##{ver.uuid}").unbind("click").click(=>
          el_vern.find(".ph-name").text(ver.display_name)
          el_feas.empty()
          for name, detail of ver.features
            color = @constructor._feature_classes[detail.class]?.FEATURE_COLOR
            if color
              el_feas.append("""
                <span class="label" style="background-color: #{color};">#{name}</span>\n
              """)
            else
              el_feas.append("""
                <span class="label label-default">#{name}</span>\n
              """)
          el_desc = el_card.find(".card-desc").text(I18nS(ver.description))
          el_sel = el_card.find("##{item.uuid}-select").unbind("click")
          if App.checkVersion(ver.rubic_version)
            el_sel.prop("disabled", false)
            el_sel.find(".ph-name").text(I18n("Select"))
            el_sel.attr("title", I18n("UseThisConfiguration"))
            el_sel.click(=> @_uiSelect(item.uuid, ver.uuid))
          else
            el_sel.prop("disabled", true)
            el_sel.find(".ph-name").text(I18n("NotSupported"))
            el_sel.attr("title", I18n("NotSupportedInThisRubicVersion"))
        )
    el_vers.find("##{item.versions[0].uuid}").click()
    null

$(".action-open-catalog").click(->
  return HardwareCatalog.show()
)

