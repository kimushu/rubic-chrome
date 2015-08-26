unless Function::property
  Function::property = (prop, desc) ->
    Object.defineProperty @prototype, prop, desc

class GitHubRepoFileSystem
  API_URL = "https://api.github.com"
  RAW_URL = "https://raw.githubusercontent.com"

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
      @_fs._getCommitInfo((result) =>
        return errorCallback?({code: FileError.NOT_READABLE_ERR}) unless result
        successCallback(new Date(@_fs._commit.committer.date))
      )
      undefined

    ###*
    @method
    Move an entry to a different location on the file system (not supported)
    ###
    moveTo: (parent, newName, successCallback, errorCallback) ->
      errorCallback?({code: FileError.NO_MODIFICATION_ALLOWED_ERR})
      undefined

    ###*
    @method
    Copy an entry to a different location on the file system (not supported)
    ###
    copyTo: (parent, newName, successCallback, errorCallback) ->
      errorCallback?({code: FileError.NO_MODIFICATION_ALLOWED_ERR})
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
      errorCallback?({code: FileError.NO_MODIFICATION_ALLOWED_ERR})
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
    @param {GitHubRepoFileSystem}     _fs     File system object
    @param {GitHubRepoDirectoryEntry} parent  Parent directory @nullable
    @param {String}                   path    Relative path from parent
    ###
    constructor: (@_fs, parent, path) ->
      @_fullPath = "#{(parent?.fullPath or "").replace(/\/$/, '')}/#{path}"
      @_name = @_fullPath.split("/").pop()

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
      options or= {}
      if options.create
        errorCallback?({code: FileError.NO_MODIFICATION_ALLOWED_ERR})
        return undefined
      successCallback(new GitHubRepoFileEntry(@_fs, this, path.replace(/\/$/, '')))
      undefined

    ###*
    @method
    Opens an existing directory
    ###
    getDirectory: (path, options, successCallback, errorCallback) ->
      options or= {}
      if options.create
        errorCallback?({code: FileError.NO_MODIFICATION_ALLOWED_ERR})
        return undefined
      successCallback(new GitHubRepoDirectoryEntry(@_fs, this, path.replace(/\/$/, '')))
      undefined

    ###*
    @method
    Deletes a directory and all of its contents (not supported)
    ###
    removeRecursively: (successCallback, errorCallback) ->
      errorCallback?({code: FileError.NO_MODIFICATION_ALLOWED_ERR})
      undefined

    ###*
    @private
    Constructor of GitHubRepoDirectoryEntry
    @param {GitHubRepoFileSystem}     fs      File system object
    @param {GitHubRepoDirectoryEntry} parent  Parent directory @nullable
    @param {String}                   path    Relative path from parent
    ###
    constructor: (fs, parent, path) ->
      super
      @_isFile = false
      @_url = undefined

  ###*
  @class
  DirectoryReader compatible class for GitHubRepoFileSystem
  ###
  class GitHubRepoDirectoryReader
    ###*
    @method
    (NOT SUPPORTED) Returns a list of entries from a specific directory
    @param {Function} successCallback   Callback ({Entry[]} entries)
    @param {Function} errorCallback     Callback ({FileError} err) @nullable
    ###
    readEntries: (successCallback, errorCallback) ->
      errorCallback?({code: FileError.NOT_READABLE_ERR})
      undefined

    ###*
    @private
    Constructor of GitHubRepoDirectoryReader
    @param {GitHubRepoDirectoryEntry} _dir  Entry of target directory
    ###
    constructor: (@_dir) ->
      null

  ###*
  @class
  FileEntry compatible class for GitHubRepoFileSystem
  ###
  class GitHubRepoFileEntry extends GitHubRepoEntry
    ###*
    Creates a new FileWriter compatible object associated with this file
    ###
    createWriter: (successCallback, errorCallback) ->
      errorCallback?({code: FileError.NO_MODIFICATION_ALLOWED_ERR})
      undefined

    ###*
    Returns a File object associated with this file
    ###
    file: (successCallback, errorCallback) ->
      req = new XMLHttpRequest
      req.open("GET", @_url)
      req.responseType = "arraybuffer"
      req.onreadystatechange = =>
        return unless req.readyState == XMLHttpRequest.DONE
        unless req.status == 200
          return errorCallback?({code: FileError.NOT_FOUND_ERR})
        array = new Uint8Array(req.response.size)
        successCallback(new File([req.response], @_name))
      req.send()
      undefined

    ###*
    @private
    Constructor of GitHubRepoFileEntry
    @param {GitHubRepoFileSystem}     fs      File system object
    @param {GitHubRepoDirectoryEntry} parent  Parent directory @nullable
    @param {String}                   path    Relative path from parent
    ###
    constructor: (fs, parent, path) ->
      super
      @_isFile = true
      ref = @_fs._ref
      @_url = "#{RAW_URL}/#{@_fs._owner}/#{@_fs._repo}/" +
        "#{ref.commit or ref.tag or ref.branch}#{@_fullPath}"

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
  @param {String}   owner             Owner name
  @param {String}   repo              Repository name
  @param {String}   ref.branch        Branch name (default: "master") @nullable
  @param {String}   ref.tag           Tag name @nullable
  @param {String}   ref.commit        Commit hash @nullable
  @param {Function} successCallback   Callback ({FileSystem} fs)
  @param {Function} errorCallback     Callback ({FileError} err) @nullable
  ###
  @requestFileSystem: (owner, repo, ref, successCallback, errorCallback) ->
    successCallback(new GitHubRepoFileSystem(owner, repo, ref))
    undefined

  ###*
  @private
  Get commit information from GitHub API
  @param {String}   commit      Commit hash @nullable
  @param {Function} callback    Callback ({Boolean} result)
  ###
  _getCommitInfo: (commit, callback) ->
    req = new XMLHttpRequest
    base = "#{API_URL}/repos/#{@_owner}/#{@_repo}/git"
    commit or= @_ref.commit
    if commit
      req.open("GET", "#{base}/commits/#{commit}")
      req.responseType = "json"
      req.onreadystatechange = =>
        return unless req.readyState == XMLHttpRequest.DONE
        return callback(false) unless req.status == 200
        @_commit = req.response
        callback(true)
      req.send()
    else
      base += "/refs/"
      if @_ref.tag
        base += "tags/#{@_ref.tag}"
      else
        base += "heads/#{@_ref.branch}"
      req.open("GET", base)
      req.responseType = "json"
      req.onreadystatechange = =>
        return unless req.readyState == XMLHttpRequest.DONE
        return callback(false) unless req.status == 200
        @_getCommitInfo(req.response.object.sha, callback)
      req.send()
    undefined

  ###*
  @private
  Constructor of GitHubRepoFileSystem
  @param {String} _owner        Owner name
  @param {String} _repo         Repository name
  @param {String} _ref.branch   Branch name (default: "master") @nullable
  @param {String} _ref.tag      Tag name @nullable
  @param {String} _ref.commit   Commit hash @nullable
  ###
  constructor: (@_owner, @_repo, @_ref) ->
    @_root = new GitHubRepoDirectoryEntry(this, null, "/")
    @_ref or= {}
    @_ref.branch or= "master" unless @_ref.tag or @_ref.commit
    @_commit = null

