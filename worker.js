// Generated by CoffeeScript 1.8.0
(function() {
  var EventEmitter, Worker, childProcess, spawn, w, worker,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  w = require('when');

  childProcess = require('child_process');

  EventEmitter = require('events').EventEmitter;

  module.exports = worker = function() {
    return (function(func, args, ctor) {
      ctor.prototype = func.prototype;
      var child = new ctor, result = func.apply(child, args);
      return Object(result) === result ? result : child;
    })(Worker, arguments, function(){});
  };

  worker.start = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    process.on('exit', function() {
      var _ref;
      return (_ref = w.process) != null ? _ref.kill() : void 0;
    });
    w = worker.apply(null, args);
    w.start();
    return w;
  };

  Worker = (function(_super) {
    __extends(Worker, _super);

    function Worker() {
      var args, options, _i;
      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), options = arguments[_i++];
      this.args = args;
      Worker.__super__.constructor.call(this);
      if (typeof options === 'string') {
        this.args.push(options);
        options = {};
      }
      this.gracePeriod = (options != null ? options.gracePeriod : void 0) || 1000;
      this.restart = this.restart.bind(this);
      this.stop = this.stop.bind(this);
      this.start = this.restart;
    }

    Worker.prototype.restart = function() {
      var restarted;
      restarted = this.stop().then((function(_this) {
        return function() {
          _this.process = spawn(_this.args, {
            stdio: ['ignore', 1, 2]
          });
          _this.emit('restart');
          _this.process.on('exit', function() {
            return delete _this.process;
          });
          return _this.process;
        };
      })(this));
      restarted.delay(this.gracePeriod).then((function(_this) {
        return function() {
          return _this.process.on('exit', _this.restart);
        };
      })(this));
      return restarted;
    };

    Worker.prototype.stop = function() {
      var exited;
      if (this.process == null) {
        return w.resolve();
      }
      this.process.removeListener('exit', this.restart);
      exited = w.promise((function(_this) {
        return function(resolve, reject) {
          return _this.process.once('exit', resolve);
        };
      })(this));
      this.process.kill();
      return exited;
    };

    return Worker;

  })(EventEmitter);

  spawn = function(args, options) {
    var cmd;
    args = args.slice();
    if (args.length === 1) {
      args.unshift('sh', '-c');
    }
    cmd = args.shift();
    return childProcess.spawn(cmd, args, options);
  };

}).call(this);
