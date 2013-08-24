_ = require 'underscore'


module.exports =

  timer: (name, time, callback)->
    setTimeout =>
      pretty_time = Math.round(time / 100) / 10
      console.log "Timeout[#{name}] with delay #{pretty_time} is completed"
      callback.call(@)
    , time

  sum: (array)->
    _.reduce(array, (memo, num) ->
      memo + num
    , 0)

  print_results: (comment)->
    return (error, result)->
      console.log comment, {error, result}

  retries_exceed_builder: (retries)->
    _.after (retries + 1), -> true