Events = require 'events'
util = require 'util'
fs = require 'fs'
path = require 'path'
exec = require('child_process').exec
par2 = require '../src/par2'

cleanUp = ->
  fs.unlink 'test/par2cmdline-0.4.tar.gz'
  fs.unlink 'test/par2cmdline-0.4-gcc4.patch'
  exec 'rm test/test*.par2'
  
class RateLimiter
  constructor: (@limit) ->
    @limit or= 0
    @value = null
  
  ready: (value) ->
    if @value is null or value == 0 or value == 100 or value >= @value + @limit
      @value = value
      return true
    else
      return false

exec 'cp par2cmdline/par2cmdline-0.4* ./test', (err, stdout, stderr) ->
  if err
    util.log 'FAILURE: couldn\'t copy par2cmdline source files'
    cleanUp()
  else
    create = par2.create 'test/test.par2', ['-b100', '-r100', '-n5'], ['test/par2cmdline-0.4.tar.gz', 'test/par2cmdline-0.4-gcc4.patch'], (result, err) ->
      if err
        util.log 'FAILURE: create: ' + err.message
        cleanUp()
      else
        util.log 'SUCCESS: create'
        par2.verify 'test/test.par2', (result, err) ->
          if err
            util.log 'FAILURE: verify: ' + err.message
            cleanUp()
          else
            util.log 'SUCCESS: verify'
            fs.unlink 'test/par2cmdline-0.4.tar.gz', (err) ->
              if err
                util.log 'FAILURE: couldn\'t remove par2cmdline source tar'
                cleanUp()
              else
                par2.repair 'test/test.par2', (result, err) ->
                  if err
                    util.log 'FAILURE: repair: ' + err.message
                  else
                    util.log 'SUCCESS: repair'
                  cleanUp()
    
    # log the PAR2.Create events
    limitConstruct = new RateLimiter 10
    limitProcess = new RateLimiter 10
    create.on 'start', (metrics) ->
      util.log 'CREATE: start ' + util.inspect metrics
    create.on 'constructstart', (progress) ->
      util.log 'CREATE: constructstart'
    create.on 'constructprogress', (progress) ->
      util.log 'CREATE: constructprogress ' + progress + '%' if limitConstruct.ready progress
    create.on 'constructend', (progress) ->
      util.log 'CREATE: constructend'
    create.on 'processstart', (progress) ->
      util.log 'CREATE: processstart'
    create.on 'processprogress', (progress) ->
      util.log 'CREATE: processprogress ' + progress + '%' if limitProcess.ready progress
    create.on 'processend', (progress) ->
      util.log 'CREATE: processend'
    create.on 'end', (metrics) ->
      util.log 'CREATE: end ' + util.inspect metrics
