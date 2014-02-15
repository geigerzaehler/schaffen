module.exports = function throttle(func, threshold) {
  var queued;

  function cancel() {
    clearTimeout(queued);
    queued = null;
  }

  function throttled() {
    var receiver = this, args = arguments;

    if (queued)
      return;

    queued = setTimeout(function() {
      func.apply(receiver, args);
      queued = null;
    }, threshold || 100);

  };

  throttled.cancel = cancel;
  return throttled;
}
