w = require('when')
childProcess = require('child_process')
{EventEmitter} = require('events')


# Create a worker that can be restarted on demand
#
#   var worker = require('schaffen').worker;
#   var app = worker('node myapp.js');
#   app.start()
#   // hack myapp.js
#   app.restart()
#
# If the worker exits, it will be restarted automatically. If you want to
# stop the worker use
#
#   app.stop()
#
# You can listen to the restart event.
#
#   app.on('restart', function() {
#     console.log('server restart')
#   })
#
module.exports = worker = ->
  return new Worker(arguments...)


worker.start = (args...)->
  process.on 'exit', -> worker_.process?.kill()
  worker_ = worker(args...)
  worker_.start()
  worker_


class Worker extends EventEmitter

  constructor: (@args..., options)->
    super()

    if typeof options == 'string'
      @args.push(options)
      options = {}

    @gracePeriod = options?.gracePeriod || 1000

    @restart = @restart.bind(this)
    @stop = @stop.bind(this)
    @start = @restart

  restart: ->
    restarted = @stop().then =>
      @process = spawn @args, stdio: ['ignore', 1, 2]
      @emit('restart')
      @process.on 'exit', => delete @process
      return @process

    # Restart the process if it exits after more than a the grace
    # period.
    restarted.delay(@gracePeriod).then =>
      if @process
        @process.on 'exit', @restart
      else
        @restart()

    restarted

  # Send KILL signal to the worker and return a promise that is
  # resolved, when the worker exits.
  stop: ->
    if not @process?
      return w.resolve()

    @process.removeListener 'exit', @restart
    exited = w.promise (resolve, reject)=>
      @process.once 'exit', resolve

    @process.kill()
    exited


spawn = (args, options)->
  childProcess.spawn args[0], args[1..], options
