_ = require 'underscore'

utils = require './utils'


module.exports = (config)->

  class Store

    constructor: ->
      @memo = {}

    set: (hash, value)->
      # saving results to a store takes time...
      utils.timer 'store_set', config.timings.store_set(), =>
        @memo[hash] = value

    get: (hash, callback)->
      # fetching results from a store takes time...
      utils.timer 'store_get', config.timings.store_get(), =>
        if _.has(@memo, hash)
          return callback null, @memo[hash]
        callback 'no cached results'
