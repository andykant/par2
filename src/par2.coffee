Events = require 'events'
util = require 'util'
path = require 'path'
spawn = require('child_process').spawn

PATH = path.resolve './par2cmdline/par2'
EXISTS = path.existsSync PATH
Errors =
  MISSING:
    message: 'Cannot find "par2" executable.'
    
Parser =
  create:
    stage1:
      BLOCK_SIZE: /Block size: (\d+)/
      SOURCE_FILE_COUNT: /Source file count: (\d+)/
      SOURCE_BLOCK_COUNT: /Source block count: (\d+)/
      REDUNDANCY: /Redundancy: (\d+(\.\d+)?)%/
      RECOVERY_BLOCK_COUNT: /Recovery block count: (\d+)/
      RECOVERY_FILE_COUNT: /Recovery file count: (\d+)/
    stage2:
      CONSTRUCTING_STATE: /Constructing: (\d+\.?\d+?)%/
      SUCCESS: /Constructing: done./
    stage3:
      PROCESSING_STATE: /Processing: (\d+(\.\d+)?)%/
      SUCCESS: /Wrote \d+ bytes to disk/
    stage4:
      WRITING_RECOVERY: /Writing recovery packets/
      WRITING_VERIFICATION: /Writing verification packets/
      SUCCESS: /Done/
  verify:
    # 0..n
    stage1:
      LOAD_FILE: /Loading "(.+?)"\./
      LOAD_FILE_STATE: /Loading: (\d+(\.\d+)?)%/
      SUCCESS: /Loaded (\d+) new packets including (\d+) recovery blocks/
    stage2:
      RECOVERABLE_FILES: /There are (\d+) recoverable files and (\d+) other files./
      BLOCK_SIZE: /The block size used was (\d+) bytes./
      DATA_BLOCKS: /There are a total of (\d+) data blocks./
      TOTAL_SIZE: /The total size of the data files is (\d+) bytes./
    # 0..n
    stage3:
      SCAN_FILE: /Scanning: "(.+?)": (\d+(\.\d+)?)%/
      SUCCESS: /Target: "(.+?)" - found./
      FAILURE: /Target: "(.+?)" - missing./
    stage4:
      SUCCESS: /All files are correct, repair is not required./
  repair:
    DO_NOTHING: true
    
class PAR2Command extends Events.EventEmitter
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
      
class Create extends PAR2Command
  constructor: (par2file, options, files, callback) ->
    return @_error Errors.MISSING if not EXISTS
    callback or= @_callback arguments
    par2 = @_spawn 'create', arguments
    
    # cache parsers
    parser = Parser.create
    stage1 = parser.stage1
    stage2 = parser.stage2
    stage3 = parser.stage3
    stage4 = parser.stage4
    # checks for a non-ready stage
    stageFinished = (stage) ->
      return false if stage is null or (typeof stage is 'number' and stage < 100)
      if typeof stage is 'object'
        for prop of stage
          return false if stage[prop] is null
      return true
    # state management object
    state =
      stage1:
        blockSize: null
        sourceFileCount: null
        sourceBlockCount: null
        redundancy: null
        recoveryBlockCount: null
        recoveryFileCount: null
      stage2: null
      stage3: null
      stage4: null
      
    # event lifecycle
    #   start METRICS
    #   constructstart PERCENTAGE
    #   constructprogress PERCENTAGE
    #   constructend PERCENTAGE
    #   processstart PERCENTAGE
    #   processprogress PERCENTAGE
    #   processend PERCENTAGE
    #   end METRICS
    
    par2.stdout.on 'data', (data) =>
      for line in data.toString().split(/\r\n/)
        # @log 'LINE: ' + line
        if not stageFinished state.stage1
          state.stage1.blockSize = parseInt(test[1],10) if test = line.match stage1.BLOCK_SIZE
          state.stage1.sourceFileCount = parseInt(test[1],10) if test = line.match stage1.SOURCE_FILE_COUNT
          state.stage1.sourceBlockCount = parseInt(test[1],10) if test = line.match stage1.SOURCE_BLOCK_COUNT
          state.stage1.redundancy = parseFloat(test[1]) if test = line.match stage1.REDUNDANCY
          state.stage1.recoveryBlockCount = parseInt(test[1],10) if test = line.match stage1.RECOVERY_BLOCK_COUNT
          state.stage1.recoveryFileCount = parseInt(test[1],10) if test = line.match stage1.RECOVERY_FILE_COUNT
          if stageFinished state.stage1
            @emit 'start', state.stage1
            state.stage2 = 0
            @emit 'constructstart', state.stage2
            @emit 'constructprogress', state.stage2
        else if not stageFinished state.stage2
          if test = line.match stage2.CONSTRUCTING_STATE
            state.stage2 = parseFloat(test[1])
            @emit 'constructprogress', state.stage2
          if line.match(stage2.SUCCESS) or state.stage2 >= 100
            oldStage2 = state.stage2
            state.stage2 = 100
            @emit 'constructprogress', state.stage2 if oldStage2 < state.stage2
            @emit 'constructend', state.stage2
            state.stage3 = 0
            @emit 'processstart', state.stage3
            @emit 'processprogress', state.stage3
        else if not stageFinished state.stage3
          if test = line.match stage3.PROCESSING_STATE
            state.stage3 = parseFloat(test[1])
            @emit 'processprogress', state.stage3
          if line.match(stage3.SUCCESS) or state.stage3 >= 100
            oldStage3 = state.stage3
            state.stage3 = 100
            @emit 'processprogress', state.stage3 if oldStage3 < state.stage3
            @emit 'processend', state.stage3
            state.stage4 = 0
        else if not stageFinished state.stage4
          ++state.stage4 if line.match stage4.WRITING_VERIFICATION
          if state.stage4 > 0 and line.match stage4.SUCCESS
            state.stage4 = state.stage1
            @emit 'end', state.stage4
      
      # @log par2file + ' - ' + data.toString()
    
    par2.on 'exit', (code) =>
      @log par2file + ' - ' + code
      callback code if callback
    
class Verify extends PAR2Command
  constructor: (par2file, options, files, callback) ->
    return @_error Errors.MISSING if not EXISTS
    callback or= @_callback arguments
    par2 = @_spawn 'verify', arguments
    
    par2.stdout.on 'data', (data) =>
      @log par2file + ' - ' + data.toString()
    
    par2.on 'exit', (code) =>
      @log par2file + ' - ' + code
      callback code if callback
    
class Repair extends PAR2Command
  constructor: (par2file, options, files, callback) ->
    return @_error Errors.MISSING if not EXISTS
    callback or= @_callback arguments
    par2 = @_spawn 'repair', arguments
    
    par2.stdout.on 'data', (data) =>
      @log par2file + ' - ' + data.toString()
    
    par2.on 'exit', (code) =>
      @log par2file + ' - ' + code
      callback code if callback

# export the library both as a class and singleton methods
exports.Create = Create
exports.Verify = Verify
exports.Repair = Repair
exports.Errors = Errors
exports.create = (par2file, options, files, callback) ->
  new Create(par2file, options, files, callback)
exports.verify = (par2file, options, files, callback) ->
  new Verify(par2file, options, files, callback)
exports.repair = (par2file, options, files, callback) ->
  new Repair(par2file, options, files, callback)
