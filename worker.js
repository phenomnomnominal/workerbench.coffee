(function() {
  self.onmessage = function(e) {
    var endTime;
    endTime = Date.now() + e.data;
    while (Date.now() < endTime) {
      (function() {})();
    }
    return self.postMessage('Finished');
  };

}).call(this);

/*
//@ sourceMappingURL=worker.js.map
*/