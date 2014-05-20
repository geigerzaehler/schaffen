w = require('when')
throttle = require('./throttle')
debounce = require('debounce')
childProcess = require('child_process')
{EventEmitter} = require('events')


# Create a worker that can be restarted on demand
#
#   var corker = require('schaffen').worker;
#   var w = createWorker('node myapp.js');
#   worker.start()
#   // hack myapp.js
#   worker.restart()
#
# If the worker exits it will be restarted automatically. If you want to
# stop the worker use
#
#   worker.stop()
#
# The restart can be debounced
#
#   restart = worker.restart.debounce(2000)
#   restart()
#   // wait a second
#   restart()
#
# The worker will only restart once after three seconds.
#
# You can listen to the restart event.
#
#   worker.on('restart', function() {
#     console.log('server restart')
#   })
#
module.exports = createWorker = (command, args..., options = {})->
  {spawn} = childProcess

  if typeof options != 'object'
    args.push(options)
    options = {}

  if command.indexOf(' ') > -1
    [command, args...] = command.split(' ')

  worker = new EventEmitter

  restart = ->
    restarted = worker.stop().then ->
      worker.emit('restart')
      worker.process = spawn command, args, stdio: ['ignore', 1, 2]
      worker.process.on 'exit', ->
        delete worker.process

    restarted.delay(1000).then (process)->
      process.on 'exit', onExitRestart

    restarted

  worker.start = restart

  if options.threshold
    worker.restart = debounce(restart, threshold)
  else
    worker.restart = restart

  worker.restart.now = restart

  # Returns a throttled and bound function that restarts the worker
  worker.restart.debounce = (threshold)->
    debounce(restart, threshold)

  worker.stop = ->
    if not worker.process?
      return w.resolve()

    worker.process.removeListener 'exit', onExitRestart
    exited = w.promise (resolve, reject)->
      worker.process.once 'exit', -> resolve()

    worker.process.kill()
    exited

  onExitRestart = worker.restart.now

  worker

class Worker extends EventEmitter

  stop: ->
    if not worker.process?
      w.resolve()

    worker.process.removeListener 'exit', @onExitRestart
    exit = w.promise (resolve, reject)->
      worker.once 'exit', -> resolve()
    .then ->
      del worker.process

    worker.process.kill()
    exit
