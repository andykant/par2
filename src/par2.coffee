Events = require 'events'
util = require 'util'
path = require 'path'
spawn = require('child_process').spawn

PATH = path.resolve './par2cmdline/par2'
EXISTS = path.existsSync PATH
Errors =
  MISSING:
    message: 'Cannot find "par2" executable.'

class PAR2 extends Events.EventEmitter
  constructor: (@options) ->
    @options or= {}

  log: (message) ->
    util.log 'par2: ' + message

  _error: (err, callback) ->
    @emit 'error', err
    callback null, err if callback
    return err
    
  _spawn: (command, args) ->
    spawnArgs = [command, '-v']
    spawnArgs = spawnArgs.concat args[1] if args[1] and args[1] instanceof Array and args[1].length > 0 and args[1][0].indexOf('-') is 0
    spawnArgs.push args[0]
    spawnArgs = spawnArgs.concat args[2] if args[2] and args[2] instanceof Array
    @log 'EXECUTING: ' + PATH + ' ' + spawnArgs.join(' ')
    return spawn PATH, spawnArgs
  
  _callback: (args) ->
    if typeof args[1] is 'function'
      return args[1]
    else if typeof args[2] is 'function'
      return args[2]
    else
      return args[3] or null
    
  create: (par2file, options, files, callback) ->
    return @_error Errors.MISSING if not EXISTS
    callback or= @_callback arguments
    par2 = @_spawn 'create', arguments
    
    par2.stdout.on 'data', (data) =>
      @log par2file + ' - ' + data.toString()
    
    par2.on 'exit', (code) =>
      @log par2file + ' - ' + code
      callback code if callback
    
  verify: (par2file, options, files, callback) ->
    return @_error Errors.MISSING if not EXISTS
    callback or= @_callback arguments
    par2 = @_spawn 'verify', arguments
    
    par2.stdout.on 'data', (data) =>
      @log par2file + ' - ' + data.toString()
    
    par2.on 'exit', (code) =>
      @log par2file + ' - ' + code
      callback code if callback
    
  repair: (par2file, options, files, callback) ->
    return @_error Errors.MISSING if not EXISTS
    callback or= @_callback arguments
    par2 = @_spawn 'repair', arguments
    
    par2.stdout.on 'data', (data) =>
      @log par2file + ' - ' + data.toString()
    
    par2.on 'exit', (code) =>
      @log par2file + ' - ' + code
      callback code if callback

# export the library both as a class and singleton methods
par2 = new PAR2
exports.PAR2 = PAR2
exports.Errors = Errors
exports.create = (par2file, options, files, callback) ->
  par2.create.apply par2, arguments
exports.verify = (par2file, options, files, callback) ->
  par2.verify.apply par2, arguments
exports.repair = (par2file, options, files, callback) ->
  par2.repair.apply par2, arguments
