debounce = require('debounce')
childProcess= require('child_process')
{EventEmitter} = require('events')


# Create a function that runs a command when called
#
#   echo = runner('echo')
#   echo('hello world')
#   // $ echo "hello world"
#
module.exports = (command, cliArgs = [], options = {})->
  {spawn} = childProcess
  eventEmitter = new EventEmitter

  if command.indexOf(' ') > -1
    options = cliArgs
    [command, cliArgs...] = command.split(' ')

  if typeof cliArgs == 'function'
    getArgs = cliArgs
  else if not cliArgs.splice?
    options = cliArgs
    cliArgs = []
  else
    getArgs = (args...)->
      cliArgs.concat(args)

  stdio = ['ignore', 1, 2]
  if options.silent
    stdio[1] = 'ignore'

  options.debounce ||= 400


  run = (additionalArgs...)->
    args = getArgs(additionalArgs...)
    process = spawn(command, args, {stdio})

    emit = process.emit.bind(process)
    process.emit = (args...)->
      emit(args...)
      eventEmitter.emit(args...)

    process.on 'exit', (code, signal)->
      if code or signal
        eventEmitter.emit('fail', code)
      else
        eventEmitter.emit('end')

    eventEmitter.emit 'run', args...

    process

  run.debounced = debounce(run, options.debounce)
  run.on = (event, cb)->
    eventEmitter.on(event, cb)
    run

  run
