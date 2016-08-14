# Pre dependencies
# (none)

###*
@class GitHubFetcher
  GitHub raw data fetcher class
###
module.exports = class GitHubFetcher
  ###*
  @property {string} owner
    Repository owner's name
  ###
  @property("owner",
    get: -> @_owner
    set: (v) -> @_owner = "#{v}"
  )

  ###*
  @property {string} repo
    Repository's name
  ###
  @property("repo",
    get: -> @_repo
    set: (v) -> @_repo = "#{v}"
  )

  ###*
  @property {string} ref
    Reference path (heads/xxx or tags/yyy)
  @readonly
  ###
  @property("ref", get: ->
    return "heads/#{@_branch}" if @_branch?
    return "tags/#{@_tag}" if @_tag?
    return null
  )

  ###*
  @property {string} branch
    Branch name
  ###
  @property("branch",
    get: -> @_branch
    set: (v) -> @_tag = null; @_branch = "#{v}"
  )

  ###*
  @property {string} tag
    Tag name
  ###
  @property("tag",
    get: -> @_tag
    set: (v) -> @_branch = null; @_tag = "#{v}"
  )

  ###
  ###
  @fakeApiBase: null

  ###*
  @static
  @property {string} rawContentUrl
    URL for raw GitHub user content
  ###
  # @rawContentUrl: "https://raw.githubusercontent.com/$owner/$repo/$branch$tag/$path"
  @rawContentUrl: "http://$host/api/repos/$owner/$repo/contents/$path"

  ###*
  @method constructor
    Constructor of GitHubFetcher class
  @param {string} owner
    Repository owner's name
  @param {string} repo
    Repository's name
  @param {string} [branch="master"]
    Branche name
  ###
  constructor: (@owner, @repo, @branch = "master") ->
    return

  ###*
  @method
    Get data as an ArrayBuffer
  @param {string} path
    File path
  @return {Promise}
    Promise object
  @return {ArrayBuffer} return.PromiseValue
    Received data
  ###
  getAsArrayBuffer: (path) ->
    return @_get(path, (url) =>
      return XhrPromise.getAsArrayBuffer(url)
    ).then((xhr) =>
      return xhr.response
    )

  ###*
  @method
    Get data as a JSON object
  @param {string} path
    File pat
  @return {Promise}
    Promise object
  @return {Object} return.PromiseValue
    Received data
  ###
  getAsJSON: (path) ->
    return @_get(path, (url) =>
      return XhrPromise.getAsText(url, {headers: {"Pragma": "no-cache", "Cache-Control": "no-cache"}})
    ).then((xhr) =>
      return JSON.parse(xhr.response)
    )

  ###*
  @private
  @method
    Get data
  @param {string} path
    File path
  @param {function(string):Promise} getter
    Getter function
  @return {Promise}
    Promise object
  ###
  _get: (path, getter) ->
    return Promise.resolve(
    ).then(=>
      url = @constructor.rawContentUrl
      return unless url?
      url = url.replace("$host", window.location.host).
                replace("$owner", @owner).
                replace("$repo", @repo).
                replace("$branch", @branch || "").
                replace("$tag", @tag || "").
                replace("$ref", @ref || "").
                replace("$path", path)
      return getter(url)
    ).then((content) =>
      return content if content?
      # TODO
      return Promise.reject(Error("Cannot receive data from GitHub"))
    )
    return

# Post dependencies
XhrPromise = require("./xhrpromise")
# GitHub = global.Libs.GitHub
