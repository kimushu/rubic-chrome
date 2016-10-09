"use strict"
###*
@class Notifier
  Promise-based wrapper for Bootstrap Notify
###
module.exports = class Notifier
  null

  ###*
  @method constructor
    Constructor of Notifier class
  @param {Object} _default_options
    Default options passed to $.notify()
  @param {Object} _default_settings
    Default settings passed to $.notify()
  ###
  constructor: (@_default_options, @_default_settings) ->
    @_notify = null
    return

  ###*
  @method
    Show notification
  @param {Object} options
    Options passed to $.notify()
  @param {Object} settings
    Settings passed to $.notify()
  @return {Promise}
    Promise object
  ###
  show: (options, settings) ->
    return new Promise((resolve, reject) =>
      @close()
      merged_options = {}
      $.extend(merged_options, @_default_options)
      $.extend(merged_options, options)
      merged_settings = {}
      $.extend(merged_settings, @_default_settings)
      $.extend(merged_settings, settings)
      onClosed = merged_settings.onClosed
      merged_settings.onClosed = =>
        @_notify = null
        onClosed?()
        resolve()
        return
      @_notify = $.notify(merged_options, merged_settings)
    )

  ###*
  @method
    Update notification (synchronously)
  @param {string/string[]} command
    Field name / Object
  @param {string} update
    New data
  @return {undefined}
  ###
  update: (command, update) ->
    @_notify?.update(command, update)
    return

  ###*
  @method
    Close notification (synchronously)
  @return {undefined}
  ###
  close: ->
    @_notify?.close()
    return

