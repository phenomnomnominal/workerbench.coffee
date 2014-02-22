(function() {
  var benchmark;

  benchmark = function(e) {
    var endTime;
    endTime = Date.now() + e.data;
    while (Date.now() < endTime) {
      (function() {})();
    }
    return self.postMessage('Finished');
  };

  self.addEventListener('message', benchmark);

}).call(this);

/*
//@ sourceMappingURL=worker.js.map
*/