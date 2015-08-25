unless Function::property
  Function::property = (prop, desc) ->
    Object.defineProperty @prototype, prop, desc

class GitHubRepoFileSystem
  API_URL = "https://api.github.com"

  ###*
  @class
  Entry compatible class for GitHubRepoFileSystem
  ###
  class GitHubRepoEntry
    ###*
    @property {GitHubRepoFileSystem} filesystem
    @readonly
    The file system where the entry resides
    ###
    @property "filesystem", get: -> @_fs

    ###*
    @property
    @readonly
    The full absolute path from the root directory
    ###
    @property "fullPath", get: -> @_fullPath

    ###*
    @property {Boolean} isDirectory
    @readonly
    True if the entry is a directory
    ###
    @property "isDirectory", get: -> not @_isFile

    ###*
    @property {Boolean} isFile
    @readonly
    True if the entry is a file
    ###
    @property "isFile", get: -> @_isFile

    ###*
    @property {String} name
    @readonly
    Ther name of the entry
    ###
    @property "name", get: -> @_name

    ###*
    @method
    Get last modification date of the entry
    ###
    getMetadata: (successCallback, errorCallback) ->
      successCallback(@_mdate)
      undefined

    ###*
    @method
    Move an entry to a different location on the file system (not supported)
    ###
    moveTo: (parent, newName, successCallback, errorCallback) ->
      errorCallback?()
      undefined

    ###*
    @method
    Copy an entry to a different location on the file system (not supported)
    ###
    copyTo: (parent, newName, successCallback, errorCallback) ->
      errorCallback?()
      undefined

    ###*
    @method
    Returns a URL that can be used to identify this entry
    ###
    toURL: () -> @_url

    ###*
    @method
    Deletes a file or directory
    ###
    remove: (successCallback, errorCallback) ->
      errorCallback?()
      undefined

    ###*
    @method
    Get the parent DirectoryEntry containing this entry
    ###
    getParent: (successCallback, errorCallback) ->
      successCallback(@_parent or this)
      undefined

    ###*
    @protected
    Constructor of GitHubRepoEntry
    ###
    constructor: (@_fs, @_parent, @_url, @_name, @_mdate) ->
      @_mdate or= (@_parent or this)._mdate
      @_isFile = true
      @_fullPath = "#{(@_parent?.fullPath or "").replace(/\/$/, '')}/#{@_name}"

  ###*
  @class
  DirectoryEntry compatible class for GitHubRepoFileSystem
  ###
  class GitHubRepoDirectoryEntry extends GitHubRepoEntry
    ###*
    @method
    Creates a new DirectoryReader compatible object to read entries from this directory
    ###
    createReader: () ->
      new GitHubRepoDirectoryReader(this)

    ###*
    @method
    Opens an existing file
    ###
    getFile: (path, options, successCallback, errorCallback) ->
      @_getEntry("blob", GitHubRepoFileEntry, path, options, successCallback, errorCallback)
      undefined

    ###*
    @method
    Opens an existing directory
    ###
    getDirectory: (path, options, successCallback, errorCallback) ->
      @_getEntry("tree", GitHubDirectoryEntry, path, options, successCallback, errorCallback)
      undefined

    ###*
    @method
    Deletes a directory and all of its contents (not supported)
    ###
    removeRecursively: (successCallback, errorCallback) ->
      errorCallback?()  # Because read-only
      undefined

    ###*
    @private
    Constructor of GitHubRepoDirectoryEntry
    ###
    constructor: (fs, parent, url, name, mdate) ->
      super
      @_isFile = false

    ###*
    @private
    Get a tree information from GitHub
    ###
    _getTree: (successCallback, errorCallback) ->
      req = new XMLHttpRequest
      req.open("GET", @_url)
      req.responseType = "json"
      req.onreadystatechange = ->
        return unless req.readyState == @DONE
        return errorCallback?() unless req.status == 200
        successCallback(req.response.tree or [])
      req.send()

    ###*
    @private
    Get a new entry (file or directory)
    ###
    _getEntry: (type, eclass, path, options, successCallback, errorCallback) ->
      options or= {}
      return errorCallback?() if options.create # Because read-only
      @_getTree(
        ((tree) =>
          for f in tree
            continue unless f.path == path
            return errorCallback?() unless f.type == type and f.url
            return successCallback(new eclass(@_fs, this, f.url, f.path))
          return errorCallback?() # Entry not found
        ),
        errorCallback
      ) # @_getTree

  ###*
  @class
  DirectoryReader compatible class for GitHubRepoFileSystem
  ###
  class GitHubRepoDirectoryReader
    ###*
    @method
    Returns a list of entries from a specific directory
    ###
    readEntries: (successCallback, errorCallback) ->
      if @_done
        successCallback([])
        return undefined
      @_dirEntry._getTree(
        ((tree) =>
          entries = []
          for f in tree
            if f.type == "tree"
              eclass = GitHubRepoDirectoryEntry
            else
              eclass = GitHubRepoFileEntry
            entries.push(new eclass(@_dirEntry._fs, @_dirEntry, f.url, f.path))
          @_done = true
          successCallback(entries)
        ),
        errorCallback
      ) # @_entry._getTree
      undefined

    ###*
    @private
    Constructor of GitHubRepoDirectoryReader
    ###
    constructor: (@_dirEntry) ->
      @_tree = null
      @_done = false

  ###*
  @class
  FileEntry compatible class for GitHubRepoFileSystem
  ###
  class GitHubRepoFileEntry extends GitHubRepoEntry
    ###*
    Creates a new FileWriter compatible object associated with this file
    ###
    createWriter: (successCallback, errorCallback) ->
      errorCallback?() # Because read-only
      undefined

    ###*
    Returns a File object associated with this file
    ###
    file: (successCallback, errorCallback) ->
      req = new XMLHttpRequest
      req.open("GET", @_url)
      req.responseType = "json"
      req.onreadystatechange = =>
        return unless req.readyState == XMLHttpRequest.DONE
        return errorCallback?() unless req.status == 200
        array = new Uint8Array(req.response.size)
        switch req.response.encoding
          when "base64"
            bin = atob(req.response.content)
            (array[i] = bin.charCodeAt(i)) for i in [0...array.length]
          else
            return errorCallback?()
        successCallback(new File([array], @_name, {lastModified: @_mdate}))
      req.send()
      undefined

    ###*
    @private
    Constructor of GitHubRepoFileEntry
    ###
    constructor: (fs, parent, url, name, mdate) ->
      super

  ###*
  @property {String} name
  @readonly
  Name of the file system
  ###
  @property "name", get: -> "GitHub"

  ###*
  @property {DirectoryEntry} root
  @readonly
  The root directory of the file system
  ###
  @property "root", get: -> @_root

  ###*
  @static
  Request filesystem for GitHub repository storage
  @param {String}   owner             Owner of repository
  @param {String}   repo              Name of repository
  @param {String}   ref.branch        Name of branch (default: master) @nullable
  @param {String}   ref.tag           Name of tag @nullable
  @param {Function} successCallback   Callback ({FileSystem} fs)
  @param {Function} errorCallback     Callback () @nullable
  ###
  @requestFileSystem: (owner, repo, ref, successCallback, errorCallback) ->
    if ref?.tag
      path = "tags/#{ref.tag}"
    else
      path = "heads/#{ref?.branch or "master"}"
    fs = new GitHubRepoFileSystem(owner, repo, path)
    fs._request(successCallback, errorCallback)

  ###*
  @private
  Request filesystem (body)
  @param {Function} successCallback   Callback ({FileSystem} fs)
  @param {Function} errorCallback     Callback () @nullable
  ###
  _request: (successCallback, errorCallback) ->
    url = "#{API_URL}/repos/#{@_owner}/#{@_repo}/git"
    req = new XMLHttpRequest
    req.open("GET", "#{url}/refs/#{@_ref}")
    req.responseType = "json"
    req.onreadystatechange = =>
      return unless req.readyState == XMLHttpRequest.DONE
      return errorCallback?() unless req.status == 200
      sha = req.response.object?.sha
      return errorCallback?() unless sha
      req = new XMLHttpRequest
      req.open("GET", "#{url}/commits/#{sha}")
      req.responseType = "json"
      req.onreadystatechange = =>
        return unless req.readyState == XMLHttpRequest.DONE
        return errorCallback?() unless req.status == 200
        date = new Date(req.response.author.date)
        @_root = new GitHubRepoDirectoryEntry(this, null, "#{url}/trees/#{sha}", "", date)
        successCallback(this)
      req.send()
    req.send()
    undefined

  ###*
  @private
  Constructor of GitHubRepoFileSystem
  ###
  constructor: (@_owner, @_repo, @_ref) ->
    null

