childProcess = require('child_process')
{EventEmitter} = require('events')

sinon = require('sinon')
sinonChai = require("sinon-chai")
chai = require('chai')

chai.use(sinonChai)
expect = chai.expect

worker = require('../lib/worker')

describe 'worker', ->

  spawn = null
  beforeEach ->
    @process = new EventEmitter
    @process.kill = sinon.spy()
    spawn = sinon.stub(childProcess, 'spawn')
      .returns(@process)

  afterEach ->
    spawn.restore()


  it 'spawns child', (done)->
    worker('sleep', '1').start().then ->
      expect(spawn).calledOnce
      expect(spawn).calledWith('sleep', ['1'])
    .finally(done)

  it 'splits arguments', (done)->
    worker('sleep 1').start().then ->
      expect(spawn).calledOnce
      expect(spawn).calledWith('sleep', ['1'])
    .finally(done)

  it 'restarts on exit after grace period', (done)->
    clock = sinon.useFakeTimers()

    worker('sleep', throttle: 200).start().then ->
      @process.emit('exit')
      clock.tick(200)

      expect(spawn).calledTwice
      expect(spawn).calledWith('sleep')
    .finally ->
      clock.restore()
      done()

  it 'emits restart after exiting', (done)->
    clock = sinon.useFakeTimers()
    onRestart = sinon.spy()

    sleep = worker('sleep')
    sleep.on 'restart', onRestart

    sleep.start().then ->
      expect(onRestart).calledOnce

      @process.emit('exit')
      clock.tick(200)

      expect(onRestart).calledTwice
    .finally ->
      clock.restore()
      done()
