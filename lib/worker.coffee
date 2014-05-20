w = require('when')
throttle = require('./throttle')
debounce = require('debounce')
childProcess = require('child_process')
{EventEmitter} = require('events')


# Create a worker that can be restarted on demand
#
#   var corker = require('schaffen').worker;
#   var app = createWorker('node myapp.js');
#   app.start()
#   // hack myapp.js
#   app.restart()
#
# If the worker exits it will be restarted automatically. If you want to
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

  constructor: (@command, @args...)->
    super()
    if @command.indexOf(' ') > -1 and not @args.length
      [@command, @args...] = @command.split(' ')

    @restart = @restart.bind(this)
    @restart.now = @restart
    @stop = @stop.bind(this)
    @start = @restart

  restart: ->
    {spawn} = childProcess
    restarted = @stop().then =>
      @emit('restart')
      @process = spawn @command, @args, stdio: ['ignore', 1, 2]
      @process.on 'exit', => delete @process

    restarted.delay(1000).then (process)=>
      process.on 'exit', @restart.now

    restarted

  stop: ->
    if not @process?
      return w.resolve()

    @process.removeListener 'exit', @restart.now
    exited = w.promise (resolve, reject)=>
      @process.once 'exit', -> resolve()

    @process.kill()
    exited
