class GitHubRepoFileSystem
  API_URL = "https://api.github.com"

  class GitHubRepoDirectoryReader
    constructor: (@_entry) ->
      null

  class GitHubRepoDirectoryEntry
    constructor: (@_fs, @_sha) ->
      null

    _getEntry: (type, path, options, successCallback, errorCallback) ->
      options or= {}
      return errorCallback?() if options.create # Because read-only
      req = @_fs._createXHR("trees/#{@_sha}")
      req.onreadystatechange = ->
        return unless req.readyState == @DONE
        return errorCallback?() unless req.status == 200
        for f in (req.response.tree or [])
          continue unless f.path == path
          return errorCallback?() unless f.type == type and f.sha
          return successCallback(new GitHubRepoFileEntry(@_fs, f.sha))
      req.send()

    createReader: () ->
      new GitHubRepoDirectoryReader(this)

    getFile: (type, path, options, successCallback, errorCallback) ->
      @_getEntry("blob", path, options, successCallback, errorCallback)

    getDirectory: (path, options, successCallback, errorCallback) ->
      @_getEntry("tree", path, options, successCallback, errorCallback)

    removeRecursively: (successCallback, errorCallback) ->
      errorCallback?()  # Because read-only

  class GitHubRepoFileEntry
    constructor: (@_fs, @_sha) ->
      null

  _createXHR: (func) ->
    req = new XMLHttpRequest()
    req.open("GET", "#{API_URL}/repos/#{@_owner}/#{@_repo}/git/#{func}")
    req.responseType = "json"
    return req

  ###*
  @static
  Request filesystem for GitHub repository storage
  @param {Function} callback    Callback ({FileSystem} fs)
  @param {String}   owner       Onwer of repository
  @param {String}   repo        Name of repository
  @param {String}   branch      Name of branch (default: heads/master) @nullable
  ###
  @request: (callback, onwer, repo, branch) ->
    branch or= "heads/master"
    fs = new GitHubRepoFileSystem(owner, repo, branch)
    req = fs._createXHR("refs/#{branch}")
    req.onreadystatechange = ->
      return unless req.readyState == @DONE
      return callback(null) unless req.status == 200
      sha = req.response.object?.sha
      return callback(null) unless sha
      fs.root = new GitHubRepoDirectoryEntry(fs, sha)
      callback(fs)
    req.send()

  # Register alias to GitHubRepoFileSystem.request
  FileSystem.requestGitHubRepo = (args...) => @request(args...)

  ###*
  @private
  ###
  constructor: (@_owner, @_repo, @_branch) ->
    null

