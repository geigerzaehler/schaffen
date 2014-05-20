w = require('when')
childProcess = require('child_process')
{EventEmitter} = require('events')

sinon = require('sinon')
sinonChai = require("sinon-chai")
chai = require('chai')

chai.use(sinonChai)
expect = chai.expect

worker = require('../lib/worker')

promise = (p)->
  (done)-> p().done (->done()), done

describe 'worker', ->

  spawn = null
  beforeEach ->
    @process = new EventEmitter
    @process.kill = sinon.spy => @process.emit 'exit'
    spawn = sinon.stub(childProcess, 'spawn')
      .returns(@process)

  afterEach ->
    spawn.restore()


  it 'spawns child', promise ->
    worker('sleep', '1').start().then ->
      expect(spawn).calledOnce
      expect(spawn).calledWith('sleep', ['1'])

  it 'splits arguments', promise ->
    worker('sleep 1').start().then ->
      expect(spawn).calledOnce
      expect(spawn).calledWith('sleep', ['1'])

  it 'restarts on exit after grace period', promise ->
    clock = sinon.useFakeTimers()

    worker('sleep').start().tap ->
      expect(spawn).calledOnce
      clock.tick(1000)
    .then (process)->
      process.emit('exit')
    .then ->
      expect(spawn).calledTwice
    .finally ->
      clock.restore()

  it 'kills process on restart', promise ->
    sleep = worker('sleep')

    sleep.start().tap (process)->
      expect(process.kill).not.called
      sleep.restart()
    .then (process)->
      expect(process.kill).calledOnce
