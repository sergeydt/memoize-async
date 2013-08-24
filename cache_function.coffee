_ = require 'underscore'
async = require 'async'
utils = require './utils'
hasher = require './hasher.coffee'


# cache function builder
module.exports = (config)->

  # storage class
  Store = require('./store')(config)

  # allows to set retries count of slow function attempts
  return cache_function = (slow_fn, retries = 1)->

    # storage instance
    store = new Store

    # allows any count of arguments
    return (callback, keys...)->

      # check for valid arguments
      is_invalid_arguments = ->
        return 'no arguments specified' if keys.length is 0
        isInvalidType = _.any keys, (key)->
          not _.isNumber(key) and not _.isString(key) and not _.isBoolean(key)
        return 'invalid argument type' if isInvalidType
        return null


      # return with an error if there is an invalid argument passed into slow_function
      if error = is_invalid_arguments()
        return callback error

      # report errors only if both cache and all retries of slow function were unsuccessfull
      anError = (->
        errors = []
        reportErrors = _.after 2, ->
          send errors
        return (err)->
          errors.push err
          reportErrors()
      ).call()


      # send function
      send = (->
        isSent = no
        return (error, result, other...)->
          return false if isSent
          callback.apply @, arguments
          # save new cached result for a given keys hash in the case if there is no error right after send a result
          store.set hash, result
          isSent = true
      ).call()


      # add 'from' argument. it could be 'cache' of 'slow', so we know where we get result from for unit tests
      doneBuilder = (from)->
        return (error, result)->
          return anError(error) if error
          send.call(@, error, result, from)


      # run slow function immediately and retry until the response is sent or the amount of retries is exceed
      retries_exceed = utils.retries_exceed_builder retries
      async.until retries_exceed, (cb)->
        iteration = (error, result)->
          if error
            console.info('an unsuccessfull try of slow function call', error)
            # next try
            cb null
          else
            doneBuilder('slow').call(@, null, result)
        # run slow function with an amount of required middlewares
        slow_fn.apply @, [iteration].concat(keys)
      , ->
        # the things go bad..
        anError 'all retries exceed'

      # build a hash of arguments
      hash = hasher.get keys

      # attempt to fetch from cache in parallel way
      store.get hash, doneBuilder('cache')




