md5 = require 'MD5'

module.exports =
  get: (args...)->
    md5 JSON.stringify(args)


