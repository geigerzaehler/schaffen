throttle = require('./throttle')
debounce = require('debounce')
childProcess = require('child_process')
{EventEmitter} = require('events')


# Create a worker that can be restarted on demand
#
#   worker = createWorker('node myapp.js')
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
  worker.process = null

  restart = ->
    worker.stop()
    worker.emit('restart')
    worker.process = spawn command, args, stdio: ['ignore', 1, 2]
    worker.process.on 'exit', onExitRestart
    worker.process

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
    worker.process?.removeListener 'exit', onExitRestart
    worker.process?.kill()

  onExitRestart = worker.restart.now

  worker
