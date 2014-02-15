childProcess = require('child_process')
{EventEmitter} = require('events')

sinon = require('sinon')
sinonChai = require('sinon-chai')
chai = require('chai')

chai.use(sinonChai)
expect = chai.expect

runner = require('../lib/runner')

describe 'runner', ->

  spawn = null
  beforeEach ->
    @process = new EventEmitter
    @process.kill = sinon.spy()
    spawn = sinon.stub(childProcess, 'spawn')
      .returns(@process)

  afterEach ->
    spawn.restore()

  it 'spawns child', ->
    runner('echo')()
    expect(spawn).calledOnce
    expect(spawn).calledWith('echo')

  it 'spawns child with arguments', ->
    runner('echo', ['hello world'])()
    expect(spawn).calledOnce
    expect(spawn).calledWith('echo', ['hello world'])

  it 'emits run event', ->
    onRun = sinon.spy()
    runner('echo', ['hello'])
      .on('run', onRun)('world')

    expect(onRun).calledOnce
    expect(onRun).calledWith 'hello', 'world'

  it 'spawns silently with split arguments', ->
    runner('echo hello', silent: true)()
    expect(spawn).calledWith 'echo', ['hello'], stdio: ['ignore', 'ignore', 2]

  it 'emits end on succesful exit', ->
    onEnd = sinon.spy()
    echo = runner('echo').on('end', onEnd)()
    @process.emit 'exit', 0
    
    expect(onEnd).calledOnce

  it 'emits error on non-zero exit', ->
    onError = sinon.spy()
    echo = runner('echo').on('error', onError)()
    @process.emit 'exit', 200

    expect(onError).calledOnce
    expect(onError).calledWith 200
