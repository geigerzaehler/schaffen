childProcess = require('child_process')
{EventEmitter} = require('events')

sinon = require('sinon')
sinonChai = require("sinon-chai")
chai = require('chai')

chai.use(sinonChai)
expect = chai.expect

runner = require('../runner')

describe 'runner', ->

  spawn = null
  beforeEach ->
    spawn = sinon.mock(childProcess)
      .expects('spawn')
      .returns(new EventEmitter)
  afterEach ->
    childProcess.spawn.restore()


  it 'spawns child', ->
    spawn
      .once()
      .withArgs('echo')

    runner('echo')()
    spawn.verify()

  it 'spawns child with arguments', ->
    spawn
      .once()
      .withArgs('echo', ['hello world'])

    runner('echo', ['hello world'])()
    spawn.verify()

  it 'emits run event', ->
    onRun = sinon.spy()

    echo = runner('echo', ['hello'])
      .on('run', onRun)
    echo('world')

    expect(onRun).calledOnce
    expect(onRun).calledWith 'hello', 'world'
