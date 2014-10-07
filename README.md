schaffen
========

A small library to control child processes.


Runner
------

A *Runner* is a programm that is expected to finish in a short amount
of time.

```js
var runner = require('schaffen').runner;
var echo = runner('echo hi');
echo().then(function() {
  console.log('echoed')
})
// -> hi
// -> echoed
```

Worker
------

A *Worker* is a process that is expected to run continuously, but can be
restarted on demand or if it exits.

```js
var worker = require('schaffen').worker;
var app = worker('node myapp.js');
app.start();
// hack myapp.js
app.restart();
```

If you pass a single string command to the constructor, this command
will be executed in the shell. You can also pass multiple arguments
that will be executed like `childProcess.spawn`.

```js
var app = worker('node', 'my app.js')
```

If the process terminates, it will be restarted automatically. To stop
it, use

```js
app.stop()
```

The `start()`, `restart()`, and `stop()`, methods return a promise that
is resolved when the action has finished. They are also bound to the
worker, so you can pass them around freely.

Every time the server is started or restarted, the `restart` event is
fired.

```js
app.on('restart', function() {
  console.log('restarted my app')
});
```
