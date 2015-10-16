###*
@class
  Hardware catalog (Model)
@uses FileUtil
###
class HardwareCatalog
  DEBUG = if DEBUG? then DEBUG else 1

  ###*
  @private
  @cfg {string}
    File name of catalog
  @readonly
  ###
  CATALOG_FILE = "catalog.json"

  ###*
  @private
  @cfg {Object} SITES_INFO
    Site list information
  @cfg {string} service
    Name of service
  @cfg {string} file
    File name of site list
  @readonly
  ###
  SITES_INFO = {
    service: "github"
    owner: "kimushu"
    repo: "rubic-catalog"
    branch: "master"
    file: "sites.json"
  }

  ###*
  @static
  @method
    Load local (offline) catalog
  @param {function(result,HardwareCatalog)} callback
    Callback function with result and generated instance
  @return {void}
  ###
  @load: (callback) ->
    @_loadSpecFromSite(
      {service: "persistent"}
      (result, spec) ->
        return callback(false, null) unless result
        return callback(true, new HardwareCatalog(spec))
    )
    return

  ###*
  @method
    Load remote (online) catalog
  @param {function(result,HardwareCatalog)} callback
    Callback function with result and generated instance
  @return {void}
  ###
  update: (callback) ->
    sitesFS = null
    sites = null
    spec = {}
    new Function.Sequence(
      (seq) ->
        FileUtil.requestFileSystem(
          SITES_INFO
          (fs) ->
            sitesFS = fs
            return seq.next()
          ->
            return seq.abort()
        )
      (seq) ->
        FileUtil.readJSON(
          [sitesFS.root, SITES_INFO.file]
          (result, readdata) ->
            return seq.abort() unless result
            unless App.checkVersion(readdata.rubic_version)
              return seq.abort()
            sites = readdata.sites
            return seq.next()
        )
      (seq) =>
        return seq.next() unless sites.length > 0
        site = sites.shift()
        spec = null
        new Function.Sequence(
          (seq2) =>
            @constructor._loadSpecFromSite(
              site
              (result, siteSpec) =>
                return seq2.next(result)
                spec = siteSpec
            )
          (seq2) =>
            @_merge(
              spec
              (result) ->
                return seq2.next(result)
            )
        ).final(
          (seq2) ->
            unless seq2.finished
              # TODO: warning
              null
            return seq.redo()
        ).start()
    ).final(
      (seq) ->
        return callback(false, null) unless seq.finished
        return callback(true, new HardwareCatalog(spec))
    ).start()
    return

  ###*
  @private
  @static
  @method
    Load spec data from site
  @param {function(result,Object)}  callback
    Callback function with result and catalog data
  @return {void}
  ###
  @_loadSpecFromSite: (site, callback) ->
    siteFS = null
    spec = null
    new Function.Sequence(
      (seq) ->
        FileUtil.requestFileSystem(
          site
          (fs) ->
            siteFS = fs
            return seq.next()
          ->
            return seq.abort()
        )
      (seq) ->
        FileUtil.readText(
          [siteFS.root, CATALOG_FILE]
          (result, readdata) ->
            return seq.abort() unless result
            try
              if readdata != ""
                spec = JSON.parse(readdata)
              else
                spec = {}
            catch
              return seq.abort()
            return seq.next()
          {create: (site.service == "persistent")}
        )
    ).final(
      (seq) ->
        return callback(false, null) unless seq.finished
        return callback(true, spec)
    ).start()
    return

  #----------------------------------------------------------------
  # >>>> OLD contents >>>>

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
    cfg = @_catalog[c_uuid]
    ver = cfg.versions[v_uuid]
    assets = ver.asset.slice(0)
    new Function.Sequence(
      (seq) =>
        return seq.next() if ver.date_downloaded
        return seq.next() unless assets.length > 0
        return seq.redo()
    ).final(
      (seq) ->
    ).start()
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
  Select a configuration
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

  SITES_OWNER   = "kimushu"
  SITES_REPO    = "rubic-catalog"
  SITES_BRANCH  = "master"

  ###*
  @private
  @method
    Load local(offline) catalog
  @param {function(boolean)}  callback
    Callback function with result
  @return {void}
  ###
  _loadCatalog: (callback) ->
    localFS = null
    new Function.Sequence(
      (seq) ->
        FileUtil.requestPersistentFileSystem(
          (fs) ->
            localFS = fs
            return seq.next()
          ->
            return seq.abort()
        )
      (seq) =>
        FileUtil.readJSON(
          [localFS.root, "catalog.json"],
          (result, readdata) =>
            unless result
              return seq.abort()
            @_catalog = readdata
            return seq.next()
          {create: true}
        )
    ).final(
      (seq) ->
        return callback(seq.finished)
    ).start()
    return

  _refresh: () ->
    @constructor._refreshCatalog((result) =>
      @_loadCatalog((result) =>
        return unless result
        @_refreshList()
      )
    )
    return

  ###*
  @private
  @static
  @method
    Refresh catalog
  @param {function(boolean)}  callback
    Callback function with result
  @return {void}
  ###
  @_refreshCatalog: (callback) ->
    fetch_start = Date.now()
    localFS = null
    catalog = null
    sitesFS = null
    sites   = null
    new Function.Sequence(
      (seq) ->
        FileUtil.requestPersistentFileSystem(
          (fs) ->
            localFS = fs
            return seq.next()
          ->
            return seq.abort()
        )
      (seq) ->
        FileUtil.readJSON(
          [localFS.root, "catalog.json"],
          (result, readdata) ->
            unless result
              return seq.abort()
            catalog = readdata
            # TODO: return unless App.checkVersion(catalog.rubic_version)
            return seq.next()
          {create: true}
        )
      (seq) ->
        GitHubRepoFileSystem.requestFileSystem(
          SITES_OWNER
          SITES_REPO
          {branch: SITES_BRANCH}
          (fs) ->
            sitesFS = fs
            return seq.next()
          ->
            return seq.abort()
        )
      (seq) ->
        FileUtil.readJSON([sitesFS.root, "sites.json"], (result, readdata) ->
          unless result
            return seq.abort()
          unless App.checkVersion(readdata.rubic_version)
            return seq.abort()
          sites = readdata.sites
          return seq.next()
        )
      (seq) =>
        return seq.next() unless sites.length > 0
        site = sites.shift()
        @_fetchCatalog(
          catalog
          site
          (result) ->
            unless result
              null  # TODO
            return seq.redo()
        )
      (seq) ->
        return seq.next() if catalog.date_fetched < fetch_start
        FileUtil.writeJSON([localFS.root, "catalog.json"], catalog, (result) ->
          return seq.next(result)
        )
    ).final(
      (seq) ->
        console.log({_refreshCatalog: seq.finished})
        console.log({_refreshCatalog: catalog})
        return callback(seq.finished)
    ).start()
    return

  ###*
  @private
  @static
  @method
    Request file system for catalog site
  @param {Object} site
    Site information
  @param {string} site.service
    Name of host service
  @param {function(boolean,Object)} callback
    Callback function with result and FileSystem object
  @return {void}
  ###
  @_requestSiteFS: (site, callback) ->
    switch site.service
      when "github"
        GitHubRepoFileSystem.requestFileSystem(
          site.owner
          site.repo
          site.ref
          (fs) -> return callback(true, fs)
          -> return callback(false, null)
        )
      else
        callback(false, null)
    return

  ###*
  @private
  @static
  @method
    Fetch online catalog and merge into offline catalog
  @return {void}
  ###
  @_fetchCatalog: (catalog, site, callback) ->
    now = Date.now()
    seq = new Function.Sequence()
    fs = null
    items = null
    modified = 0
    merge = (dst, src, n) ->
      return v if dst[n] == (v = src[n])
      modified += 1
      return (dst[n] = v)
    assets = []
    new Function.Sequence(
      (seq) =>
        @_requestSiteFS(
          site
          (result, siteFS) ->
            return seq.abort() unless result
            fs = siteFS
            return seq.next()
        )
      (seq) ->
        FileUtil.readJSON([fs.root, "catalog.json"], (result, readdata) ->
          unless result
            return seq.abort()
          items = readdata
          return seq.next()
        )
      (seq) ->
        for iuuid, si of items
          di = (catalog[iuuid] or= {})
          di.date_fetched or= now
          di.site = site
          merge(di, si, "name")
          merge(di, si, "board_class")
          assets.push([iuuid, merge(di, si, "icon")])
          for vuuid, sv of (si.versions or {})
            dv = ((di.versions or= {})[vuuid] or= {})
            dv.date_fetched or= now
            merge(dv, sv, "date_added")
            merge(dv, sv, "display_name")
            merge(dv, sv, "rubic_version")
            merge(dv, sv, "features")
            merge(dv, sv, "description")
            merge(dv, sv, "asset")
        return seq.next()
      (seq) ->
        return seq.next() unless assets.length > 0
        [iuuid, asset] = assets.shift()
        return seq.redo() unless asset and asset != ""
        # TODO
        return seq.redo()
    ).final(
      (seq) ->
        catalog.date_fetched = now if modified > 0
        callback(seq.finished)
    ).start()
    return

  ###*
  @private
  @method
    Refresh item list
  @return {void}
  ###
  _refreshList: ->
    return unless @_catalog
    @$("#catalog").empty()
    iuuids = (k for k, v of @_catalog)
    # TODO: sort
    @_addItem(iuuid) for iuuid in iuuids
    return

  ###*
  @private
  @method
    Add one item
  @param {string} iuuid
    UUID of item
  @return {void}
  ###
  _addItem: (iuuid) ->
    item = @_catalog[iuuid]
    return unless item.name?
    elem = @$("#catalog")
    elem.append("""
      <div class="card" id="#{iuuid}">
        <div class="card-header">
          <img class="card-icon" src="#{item.icon}" width="48px" height="48px">
          <div class="card-title">
            <span class="ph-name">#{I18nS(item.name)}</span>
            <div class="btn-group btn-group-xs pull-right">
              <button class="btn btn-selected" id="#{iuuid}-select"><span
               class="glyphicon glyphicon-play"></span> <span class="ph-name"></span></button>
            </div>
          </div>
          <div class="card-versions dropdown">
            <button class="btn btn-xs dropdown-toggle" type="button" data-toggle="dropdown"
             id="#{iuuid}-versions" aria-haspopup="true"
             aria-expanded="false"><span class="ph-name"></span> <span class="caret"></span>
            </button>
            <ul class="dropdown-menu" alia-labelledby="#{iuuid}-versions"></ul>
          </div>
        </div>
        <div class="card-features"></div>
        <div class="card-desc"></div>
      </div>
    """)
    el_card = elem.find("##{iuuid}")
    el_vern = el_card.find(".card-versions")
    el_vers = el_vern.find("ul")
    el_feas = el_card.find(".card-features")
    vuuids = (k for k, v of item.versions)
    vuuids.sort((a, b) -> a.date_added - b.date_added)
    for vuuid in vuuids
      ver = item.versions[vuuid]
      do (ver) =>
        el_vers.append("""
          <li class="btn-xs"><a href="#" id="#{vuuid}">#{ver.display_name}</a></li>
        """).find("##{vuuid}").unbind("click").click(=>
          el_vern.find(".ph-name").text(ver.display_name)
          el_feas.empty()
          for name, detail of ver.features
            color = @constructor._feature_classes[detail.class]?.FEATURE_COLOR
            color = if color then " style=\"background-color: #{color};\"" else ""
            ttext = detail.description or ""
            ttext += " (Version: #{detail.version})" if detail.version
            dtext = if detail.channels then " x #{detail.channels}ch" else ""
            el_feas.append("""
              <span class="label label-default"#{color} title="#{ttext.trim()}"
              >#{name}<!--<span class="label-detail">#{dtext}</span>--></span>\n
            """)
          el_desc = el_card.find(".card-desc").text(I18nS(ver.description))
          el_sel = el_card.find("##{iuuid}-select").unbind("click")
          if App.checkVersion(ver.rubic_version)
            el_sel.prop("disabled", false)
            el_sel.find(".ph-name").text(I18n("Select"))
            el_sel.attr("title", I18n("UseThisConfiguration"))
            el_sel.click(=> @_uiSelect(iuuid, vuuid))
          else
            el_sel.prop("disabled", true)
            el_sel.find(".ph-name").text(I18n("NotSupported"))
            el_sel.attr("title", I18n("NotSupportedInThisRubicVersion"))
        )
    el_vers.find("##{vuuids[0]}").click() if vuuids.length > 0
    return

$(".action-open-catalog").click(->
  return HardwareCatalog.show()
)

