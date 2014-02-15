module.exports = function throttle(func, threshold) {
  var queued;

  return function throttled() {
    var receiver = this, args = arguments;

    if (queued)
      return;

    queued = setTimeout(function() {
      func.apply(receiver, args);
      queued = null;
    }, threshold || 100);

  };
}
