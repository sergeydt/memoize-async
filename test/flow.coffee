assert = require 'assert'
async = require 'async'
utils = require '../utils'


cache_function_builder = require '..'



get_slow_function = (config)->
  # example of slow function
  slow_function = (callback, keys...)->
    # execution of a slow function takes time...
    utils.timer 'slow_function', config.timings.slow_function(), ->
      # sometimes error may happen inside..
      if config.events.error.slow_function()
        return callback 'some error in the slow function'
      callback null, utils.sum(keys)




describe '[unit test]', ->



  describe 'slow function', ->

    it 'should call slow function without an error', (done)->
      config =
        timings:
          slow_function: ->
            100
        events:
          error:
            slow_function: ->
              no
      end = (error)->
        assert.equal null, error
        done()
      get_slow_function(config) end, 2, 5


    it 'should call slow function with an error', (done)->
      config =
        timings:
          slow_function: ->
            100
        events:
          error:
            slow_function: ->
              yes
      end = (error)->
        assert.notEqual null, error
        done()
      get_slow_function(config) end, 2, 5




  describe 'cache function', ->

    it 'should return slow function result if retrieving of cache is more slower', (done)->
      config =
        timings:
          slow_function: ->
            100
          store_set: ->
            100
          store_get: ->
            200 + Math.random() * 200
        events:
          error:
            slow_function: ->
              no
      end = (error, result, from)->
        assert.equal null, error
        assert.equal 'slow', from
        done()
      slow_function = get_slow_function(config)
      fast_function = cache_function_builder(config)(slow_function)
      fast_function end, 2, 7



    it 'should return cached result if retrieving from cache is more faster', (done)->
      config =
        timings:
          slow_function: ->
            400
          store_set: ->
            100
          store_get: ->
            100
        events:
          error:
            slow_function: ->
              no
            cache_get: ->
              no

      fromArray = []

      end = (error, result, from)->
        assert.equal null, error
        assert.deepEqual ['slow', 'slow', 'cache'], fromArray
        done()

      slow_function = get_slow_function(config)
      fast_function = cache_function_builder(config)(slow_function)

      retries_exceed = utils.retries_exceed_builder 3
      fn = (cb)->
        iteration = (error, result, from)->
          fromArray.push from
          cb null
        fast_function iteration, 2, 5

      async.until retries_exceed, fn, end


    it 'should return special errors in the case when there is no cache and all tries of slow function are failed', (done)->
      config =
        timings:
          slow_function: ->
            100
          store_set: ->
            100
          store_get: ->
            400
        events:
          error:
            slow_function: ->
              yes
      end = (errors, result, from)->
        assert.deepEqual ["no cached results", "all retries exceed"], errors
        done()
      slow_function = get_slow_function(config)
      fast_function = cache_function_builder(config)(slow_function, 4)
      fast_function end, 2, 5



