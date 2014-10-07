w = require('when')
throttle = require('./throttle')
debounce = require('debounce')
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
# The restart can be debounced
#
#   restart = app.restart.debounce(2000)
#   restart()
#   // wait a second
#   restart()
#
# The worker will only restart once, after another two seconds.
#
# You can listen to the restart event.
#
#   app.on('restart', function() {
#     console.log('server restart')
#   })
#
module.exports = worker = ->
  return new Worker(arguments...)

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
      @process.on 'exit', @restart

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
  args = args.slice()
  if args.length == 1
    args.unshift('sh', '-c')
  cmd = args.shift()
  childProcess.spawn cmd, args, options

