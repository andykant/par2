Events = require 'events'
util = require 'util'
path = require 'path'
exec = require('child_process').exec

EXISTS = path.existsSync './par2cmdline/par2'
Errors =
  MISSING:
    message: 'Cannot find "par2" executable.'

class PAR2 extends Events.EventEmitter
  constructor: (@options) ->
    @options or= {}
    
  error: (err, callback) ->
    @emit 'error', err
    callback null, err if callback
    return err
    
  create: (options, par2file, files, callback) ->
    return @error Errors.MISSING if not EXISTS
    
    result = {}
    callback result if callback
    
  verify: (options, par2file, files, callback) ->
    return @error Errors.MISSING if not EXISTS
    
    result = {}
    callback result if callback
    
  repair: (options, par2file, files, callback) ->
    return @error Errors.MISSING if not EXISTS
    
    result = {}
    callback result if callback

# export the library both as a class and singleton methods
par2 = new PAR2
exports.PAR2 = PAR2
exports.EXISTS = EXISTS
exports.Errors = Errors
exports.create = (options, par2file, files, callback) ->
  par2.create options, par2file, files, callback
exports.verify = (options, par2file, files, callback) ->
  par2.verify options, par2file, files, callback
exports.repair = (options, par2file, files, callback) ->
  par2.repair options, par2file, files, callback
