throttle = require('./throttle')
childProcess = require('child_process')
{EventEmitter} = require('events')


# Create a worker that can be restarted on demand
#
#   worker = createWorker('node', 'path/to/file.js')
#   worker.restart()
#
# You can listen to the restart event.
#
#   worker.on('restart', function() {
#     console.log('server restart')
#   })
#
# You can throttle the restart using
#
#   restart = worker.restart.throttle(1000)
#   restart()
#   restart()
#
# Then the worker restarts once after one second. For convinience the
# bound function `server.restart.throttled` is throttled with a default
# value of 400ms. You can change this by passing it to the factory as
#
#   worker = createWorker('sleep', '1', {throttle: 100})
#
# If the worker exits it will be restarted automatically. If you want to
# stop the worker use
#
#   worker.stop()
#
module.exports = createWorker = (command, args..., options = {})->
  {spawn} = childProcess

  if typeof options != 'object'
    args.push(options)
    options = {}

  options.throttle ||= 400

  worker = new EventEmitter
  worker.process = null

  worker.restart = ->
    worker.stop()
    worker.emit('restart')
    worker.process = spawn command, args, stdio: ['ignore', 1, 2]
    worker.process.on 'exit', onExitRestart
    worker.process

  # Returns a throttled and bound function that restarts the worker
  worker.restart.throttle = (threshold)->
    throttle(worker.restart, threshold)

  # The throttled version of restart
  worker.restart.throttled =
    worker.restart.throttle(options.threshold)

  worker.stop = ->
    worker.process?.removeListener 'exit', onExitRestart
    worker.process?.kill()

  onExitRestart = worker.restart.throttled

  worker
