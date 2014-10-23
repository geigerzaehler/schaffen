childProcess= require('child_process')
{EventEmitter} = require('events')


# Create a function that runs a command when called
#
#   echo = runner('echo hi')
#   echo()
#   // $ echo hi
#
# You can use command templates to fill in function arguments
#
#   echo = runner('echo {} {}')
#   echo('hello', 'world')
#   // $ echo hello world
#
# Or better yet
#
#   echo = runner('echo', 'hi', '{}')
#   echo('there')
#   // $ echo hi there
#
# There are several events that are emitted by the runner.
#
# * 'run' is emitted every time the runner is executed.
# * 'end' is emmited when the executed process exists normally.
# * 'fail' is emitted when the executed process exits with a non-zero
#    exit code.
#
# @param options.silent  If set to true, do not show stdout of the
#                        command.
module.exports = (args..., options)->
  {spawn, exec} = childProcess
  eventEmitter = new EventEmitter

  if typeof options == 'string'
    args.push(options)
    options = {}

  stdio = ['ignore', 1, 2]
  if options.silent
    stdio[1] = 'ignore'


  run = (vars...)->
    compiledArgs = for arg in args
      render(arg, vars)

    if compiledArgs.length == 1
      compiledArgs.unshift('bash', '-c')

    process = spawn(compiledArgs[0], compiledArgs[1..], {stdio})

    # Delegate events to our eventEmitter
    emit = process.emit.bind(process)
    process.emit = (args...)->
      emit(args...)
      eventEmitter.emit(args...)

    process.on 'exit', (code, signal)->
      if code or signal
        eventEmitter.emit('fail', code)
      else
        eventEmitter.emit('end')

    eventEmitter.emit 'run', compiledArgs...

    process


  run.on = (event, cb)->
    eventEmitter.on(event, cb)
    run

  run


# Replaces each occurence of '{}' in the string template by consuming
# values from `vars`.
#
# Each value that is rendered is shifted from the `vars` array.
# If there are fewer elements in `vars` than occruences in '{}', then
# the placeholders are filled with the empty string
render = (template, vars)->
  template.split('{}').reduce (rendered, next, index)->
    rendered + (vars.shift() || '') + next
