"use strict"
# Pre dependencies
AsyncFs = require("filesystem/asyncfs")

###*
@class Html5Fs
  HTML5 file system
@extends AsyncFs
###
module.exports = class Html5Fs extends AsyncFs
  AsyncFs.retainable(this)

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method constructor
    Constructor of Html5Fs class
  @param {DirectoryEntry} _dirEntry
    DirectoryEntry
  ###
  constructor: (@_dirEntry, fsType) ->
    super(fsType)
    return

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @method
  @inheritdoc AsyncFs#getNameImpl
  ###
  getNameImpl: ->
    return @_dirEntry.name

  ###*
  @protected
  @method
  @inheritdoc AsyncFs#mkdirImpl
  ###
  mkdirImpl: (path, mode) ->
    return new Promise((resolve, reject) =>
      @_dirEntry.getDirectory(
        path
        {create: true, exclusive: true}
        (=> resolve())
        reject
      ) # @_dirEntry.getDirectory()
    ) # return new Promise()

  ###*
  @protected
  @method
  @inheritdoc AsyncFs#readFileImpl
  ###
  readFileImpl: (path, options) ->
    return new Promise((resolve, reject) =>
      @_dirEntry.getFile(
        path
        {create: false}
        (fileEntry) =>
          fileEntry.file((file) =>
            reader = new FileReader()
            reader.onload = => resolve(reader.result)
            reader.onerror = reject
            if options.encoding?
              reader.readAsText(file, options.encoding)
            else
              reader.readAsArrayBuffer(file)
          ) # fileEntry.file()
        reject
      ) # @_dirEntry.getFile()
    ) # return new Promise()

  ###*
  @protected
  @method
  @inheritdoc AsyncFs#rmdirImpl
  ###
  rmdirImpl: (path) ->
    return new Promise((resolve, reject) =>
      @_dirEntry.getDirectory(
        path
        {create: false}
        (dirEntry) =>
          dirEntry.remove((=> resolve()), reject)
        reject
      ) # @_dirEntry.getDirectory()
    ) # return new Promise()

  ###*
  @protected
  @method
  @inheritdoc AsyncFs#writeFileImpl
  ###
  writeFileImpl: (path, data, options) ->
    return new Promise((resolve, reject) =>
      @_dirEntry.getFile(
        path
        {create: true}
        (fileEntry) =>
          fileEntry.createWriter(
            (writer) =>
              if options.encoding?
                blob = new Blob([data], {type: "text/plain;charset=#{options.encoding}"})
              else
                blob = new Blob([data])
              truncated = false
              writer.onwriteend = =>
                return resolve() if truncated
                truncated = true
                writer.truncate(writer.position)
              writer.onerror = reject
              writer.write(blob)
            reject
          ) # fileEntry.createWriter()
        reject
      ) # @_dirEntry.getFile()
    ) # return new Promise()

  ###*
  @protected
  @method
  @inheritdoc AsyncFs#unlinkImpl
  ###
  unlinkImpl: (path) ->
    return new Promise((resolve, reject) =>
      @_dirEntry.getFile(
        path
        {create: false}
        (fileEntry) =>
          fileEntry.remove((=> resolve()), reject)
        reject
      ) # @_dirEntry.getFile()
    ) # return new Promise()

  ###*
  @protected
  @method
  @inheritdoc AsyncFs#opendirfsImpl
  ###
  opendirfsImpl: (path) ->
    return new Promise((resolve, reject) =>
      @_dirEntry.getDirectory(
        path
        {create: false}
        (dirEntry) => resolve(new Html5Fs(dirEntry, @fsType))
        reject
      ) # @_dirEntry.getDirectory()
    ) # return new Promise()

  ###*
  @protected
  @method
  @inheritdoc AsyncFs#retainfsImpl
  ###
  retainfsImpl: ->
    obj = {fsType: @fsType}
    switch obj.fsType
      when AsyncFs.TEMPORARY
        obj.fullPath = @_dirEntry.fullPath
        return Promise.resolve(obj)
      when AsyncFs.LOCAL
        obj.id = chrome?.fileSystem.retainEntry(@_dirEntry) or ""
        return Promise.resolve(obj) if obj.id != ""
    return Promise.reject(Error("Retain is not supported"))

  ###*
  @static
  @protected
  @method
    Restore filesystem
  @param {Object} retainInfo
    Object to describe retain information
  @return {Promise}
    Promise object
  @return {AsyncFs} return.PromiseValue
    Restored filesystem object
  ###
  @restorefs: (retainInfo) ->
    switch retainInfo.fsType
      when AsyncFs.TEMPORARY
        return AsyncFs.opentmpfs().then((fs) =>
          return fs.opendirfs(retainInfo.fullPath)  # Last PromiseValue
        )
      when AsyncFs.LOCAL
        return Promise.resolve(
        ).then(=>
          return new Promise((resolve, reject) =>
            chrome.fileSystem.isRestorable(retainInfo.id, resolve)
          )
        ).then((isRestorable) =>
          return unless isRestorable
          return new Promise((resolve, reject) =>
            chrome.fileSystem.restoreEntry(retainInfo.id, resolve)
          )
        ).then((entry) =>
          return Promise.reject(Error("Cannot restore this filesystem")) unless entry?
          return new Html5Fs(entry, retainInfo.fsType)  # Last PromiseValue
        )
    return Promise.reject(Error("Restore is not supported"))

# Post dependencies
# (none)
