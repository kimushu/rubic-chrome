"use strict"
# Pre dependencies
AsyncFs = require("filesystem/asyncfs")

###*
@class Html5Fs
  HTML5 file system
@extends AsyncFs
###
module.exports = class Html5Fs extends AsyncFs
  null

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
      @_dirEntry.getDirectory(path, {create: true, exclusive: true}, resolve, reject)
    )

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
              writer.onwriteend = => resolve()
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

# Post dependencies
# (none)
