childProcess = require('child_process')
{EventEmitter} = require('events')

sinon = require('sinon')
sinonChai = require("sinon-chai")
chai = require('chai')

chai.use(sinonChai)
expect = chai.expect

worker = require('../worker')

describe 'worker', ->

  spawn = null
  beforeEach ->
    @process = new EventEmitter
    @process.kill = sinon.spy()
    spawn = sinon.stub(childProcess, 'spawn')
      .returns(@process)

  afterEach ->
    spawn.restore()


  it 'spawns child', ->
    worker('sleep', '1').restart()
    expect(spawn).calledOnce
    expect(spawn).calledWith('sleep', ['1'])

  it 'restarts on exit after grace period', ->
    clock = sinon.useFakeTimers()

    worker('sleep', throttle: 200).restart()
    @process.emit('exit')
    clock.tick(200)

    expect(spawn).calledTwice
    expect(spawn).calledWith('sleep')
    clock.restore()

  it 'emits restart after exiting', ->
    clock = sinon.useFakeTimers()
    onRestart = sinon.spy()

    sleep = worker('sleep')
    sleep.on 'restart', onRestart

    sleep.restart()
    expect(onRestart).calledOnce

    @process.emit('exit')
    clock.tick(200)

    expect(onRestart).calledTwice
    clock.restore()
