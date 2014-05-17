(function() {
  var WBFactory, createModule, _log,
    __hasProp = {}.hasOwnProperty;

  if (window.performance == null) {
    window.performance = {};
  }

  performance.now = (function() {
    return performance.now || performance.webkitNow || performance.mozNow || performance.msNow || performance.oNow || function() {
      return new Date().getTime();
    };
  })();

  window.URL = (function() {
    return window.URL || window.webkitURL;
  })();

  _log = function(message, type) {
    if (type == null) {
      type = 'log';
    }
    if (console && console[type]) {
      return console[type]("WorkerBench says: '" + message + "'");
    }
  };

  WBFactory = function() {
    var WB;
    return WB = (function() {
      var LN2, ceil, log, pow, result, setup, start, unavailable, workersAvailable, _finishedBenchmark, _generateResult, _inittime, _inlineWorkerFunction, _options, _result, _run, _runBenchmark;
      if (typeof Worker === "undefined" || Worker === null) {
        _result = 1;
        unavailable = function() {
          _log('WebWorkers are not available.');
          return false;
        };
        setup = start = workersAvailable = unavailable;
      } else {
        _inlineWorkerFunction = "self.onmessage = function (e) {\n  var endTime = Date.now() + e.data;\n  while (Date.now() < endTime) {\n    (function() {})();\n  }\n  self.postMessage('Finished');\n};";
        _inittime = null;
        _result = null;
        _options = {
          MAX_WORKERS_TO_TEST_FOR: 8,
          NUMBER_OF_TIMES_TO_BENCHMARK: 9,
          PATH_TO_WORKER_SCRIPT: '.',
          ON_COMPLETE: function(result) {
            return alert("Optimum Web Workers: " + result);
          }
        };
        _run = function(workersPerBenchmark, results) {
          var time;
          if (results == null) {
            results = {};
          }
          if (workersPerBenchmark.length !== 0) {
            return _runBenchmark(workersPerBenchmark, results);
          } else {
            _result = _generateResult(results);
            _log("Optimum Web Workers: " + (result()));
            time = (performance.now() - _inittime) / 1000;
            _log("Benchmarks took: " + time + " seconds.");
            return _options.ON_COMPLETE(_result);
          }
        };
        _runBenchmark = function(workersPerBenchmark, results, finished, workers) {
          var nWorkers, startTime, timeout, _i, _onMessage, _results;
          if (finished == null) {
            finished = [];
          }
          if (workers == null) {
            workers = [];
          }
          nWorkers = workersPerBenchmark.shift();
          timeout = 100 / nWorkers;
          _onMessage = function(e) {
            finished.push(e.data);
            if (finished.length === nWorkers) {
              if (results[nWorkers] == null) {
                results[nWorkers] = [];
              }
              results[nWorkers].push(performance.now() - startTime);
              workers.map(function(worker) {
                return worker.terminate();
              });
              return _finishedBenchmark(nWorkers, workersPerBenchmark, results);
            }
          };
          (function() {
            _results = [];
            for (var _i = 0; 0 <= nWorkers ? _i < nWorkers : _i > nWorkers; 0 <= nWorkers ? _i++ : _i--){ _results.push(_i); }
            return _results;
          }).apply(this).map(function(n) {
            var blob;
            if (window.URL && window.URL.createObjectURL && window.Blob) {
              blob = new Blob([_inlineWorkerFunction.toString()], {
                type: 'text/javascript'
              });
              workers[n] = new Worker(window.URL.createObjectURL(blob));
            } else {
              workers[n] = new Worker("" + _options.PATH_TO_WORKER_SCRIPT + "/worker.min.js");
            }
            return workers[n].addEventListener('message', _onMessage);
          });
          startTime = performance.now();
          return workers.map(function(worker) {
            return worker.postMessage(timeout);
          });
        };
        _finishedBenchmark = function(nWorkers, workersPerBenchmark, results) {
          var resultN, resultP, resultPP, sortedResults;
          if (results[nWorkers].length < _options.NUMBER_OF_TIMES_TO_BENCHMARK) {
            workersPerBenchmark.unshift(nWorkers);
          } else {
            if (_options.NUMBER_OF_TIMES_TO_BENCHMARK > 2) {
              sortedResults = results[nWorkers].sort();
              results[nWorkers] = sortedResults.slice(1, results[nWorkers].length - 1);
            }
            results[nWorkers] = (results[nWorkers].reduce(function(sum, next) {
              return sum + next;
            })) / _options.NUMBER_OF_TIMES_TO_BENCHMARK;
            resultN = results[nWorkers];
            resultP = results[nWorkers - 1];
            resultPP = results[nWorkers - 2];
            if (nWorkers > 2 && resultN > resultP && resultN > resultPP) {
              workersPerBenchmark = [];
            }
          }
          return _run(workersPerBenchmark, results);
        };
      }
      _generateResult = function(results, smallestTime, bestNWorkers) {
        var nResult, nWorkers;
        if (smallestTime == null) {
          smallestTime = Infinity;
        }
        if (bestNWorkers == null) {
          bestNWorkers = 0;
        }
        for (nWorkers in results) {
          if (!__hasProp.call(results, nWorkers)) continue;
          nResult = results[nWorkers];
          if (nResult < smallestTime) {
            smallestTime = nResult;
            bestNWorkers = +nWorkers;
          }
        }
        return bestNWorkers;
      };
      workersAvailable = function() {
        _log('WebWorkers are available.');
        return true;
      };
      pow = Math.pow, ceil = Math.ceil, log = Math.log, LN2 = Math.LN2;
      setup = function(options) {
        var maxWorkers;
        if (options == null) {
          options = {};
        }
        maxWorkers = options.maxWorkersToTestFor || _options.MAX_WORKERS_TO_TEST_FOR;
        _options.MAX_WORKERS_TO_TEST_FOR = pow(2, ceil(log(maxWorkers) / LN2));
        _options.NUMBER_OF_TIMES_TO_BENCHMARK = options.numberOfTimesToBenchmark || _options.NUMBER_OF_TIMES_TO_BENCHMARK;
        _options.PATH_TO_WORKER_SCRIPT = options.pathToWorkerScript || _options.PATH_TO_WORKER_SCRIPT;
        return _options.ON_COMPLETE = options.onComplete || _options.ON_COMPLETE;
      };
      start = function(callback) {
        var _i, _ref, _results;
        if ((callback != null) && typeof callback === 'function') {
          _options.ON_COMPLETE = callback;
        }
        _inittime = performance.now();
        return _run((function() {
          _results = [];
          for (var _i = 0, _ref = log(_options.MAX_WORKERS_TO_TEST_FOR) / LN2; 0 <= _ref ? _i <= _ref : _i >= _ref; 0 <= _ref ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this).map(function(n) {
          return pow(2, n);
        }));
      };
      result = function() {
        if (_result) {
          return _result;
        } else {
          _log('Benchmark not yet complete.', 'warn');
          return false;
        }
      };
      if (((typeof window !== "undefined" && window !== null ? window.navigator : void 0) != null) && window.navigator.hardwareConcurrency) {
        start = function(callback) {
          if (callback == null) {
            callback = _options.ON_COMPLETE;
          }
          if ((callback != null) && typeof callback === 'function') {
            return callback(navigator.hardwareConcurrency);
          }
        };
        result = function() {
          return navigator.hardwareConcurrency;
        };
      }
      if (((typeof window !== "undefined" && window !== null ? window.navigator : void 0) != null) && !window.navigator.hardwareConcurrency) {
        navigator.getHardwareConcurrency = start;
        Object.defineProperty(navigator, 'hardwareConcurrency', {
          get: result
        });
      }
      return {
        workersAvailable: workersAvailable,
        setup: setup,
        start: start,
        result: result
      };
    })();
  };

  createModule = function(factory) {
    if (typeof window.define === 'function' && define.amd) {
      return define(factory);
    } else {
      return window.WorkerBench = factory();
    }
  };

  createModule(WBFactory);

}).call(this);

/*
//@ sourceMappingURL=workerbench.js.map
*/