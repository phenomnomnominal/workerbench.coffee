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

  _log = function(message) {
    if (console && console.log) {
      return console.log("WorkerBench says: '" + message + "'");
    }
  };

  WBFactory = function() {
    var WB;
    WB = (function() {
      var result, setup, start, unavailable, workersAvailable, _finishedBenchmark, _generateResult, _inittime, _options, _result, _run, _runBenchmark;
      if (typeof Worker === "undefined" || Worker === null) {
        unavailable = function() {
          _log('WebWorkers are not available.');
          return false;
        };
        setup = start = result = workersAvailable = unavailable;
      } else {
        _inittime = null;
        _result = null;
        _options = {
          MAX_WORKERS_TO_TEST_FOR: 8,
          NUMBER_OF_TIMES_TO_BENCHMARK: 5,
          PATH_TO_WORKER_SCRIPT: '.',
          ON_COMPLETE: function(result) {
            return alert("Optimum Web Workers: " + result);
          }
        };
        _run = function(workersPerBenchmark, results) {
          if (results == null) {
            results = {};
          }
          if (workersPerBenchmark.length !== 0) {
            return _runBenchmark(workersPerBenchmark, results);
          } else {
            _result = _generateResult(results);
            _log("Optimum Web Workers: " + (WorkerBench.result()));
            _log("Benchmarks took: " + (performance.now() - _inittime) + ".");
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
            workers[n] = new Worker("" + _options.PATH_TO_WORKER_SCRIPT + "/worker.min.js");
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
        var nWorkers;
        if (smallestTime == null) {
          smallestTime = Infinity;
        }
        if (bestNWorkers == null) {
          bestNWorkers = 0;
        }
        for (nWorkers in results) {
          if (!__hasProp.call(results, nWorkers)) continue;
          result = results[nWorkers];
          if (result < smallestTime) {
            smallestTime = result;
            bestNWorkers = +nWorkers;
          }
        }
        return bestNWorkers;
      };
      workersAvailable = function() {
        _log('WebWorkers are available.');
        return true;
      };
      setup = function(options) {
        if (options == null) {
          options = {};
        }
        if (_options.MAX_WORKERS_TO_TEST_FOR == null) {
          _options.MAX_WORKERS_TO_TEST_FOR = options.maxWorkersToTestFor;
        }
        if (_options.NUMBER_OF_TIMES_TO_BENCHMARK == null) {
          _options.NUMBER_OF_TIMES_TO_BENCHMARK = options.numberOfTimesToBenchmark;
        }
        if (_options.PATH_TO_WORKER_SCRIPT == null) {
          _options.PATH_TO_WORKER_SCRIPT = options.pathToWorkerScript;
        }
        return _options.ON_COMPLETE != null ? _options.ON_COMPLETE : _options.ON_COMPLETE = options.onComplete;
      };
      start = function() {
        var _i, _ref, _results;
        _inittime = performance.now();
        return _run((function() {
          _results = [];
          for (var _i = 1, _ref = _options.MAX_WORKERS_TO_TEST_FOR; 1 <= _ref ? _i <= _ref : _i >= _ref; 1 <= _ref ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this));
      };
      result = function() {
        if (_result) {
          return _result;
        } else {
          _log('Benchmark not yet complete.');
          return false;
        }
      };
      return {
        workersAvailable: workersAvailable,
        setup: setup,
        start: start,
        result: result
      };
    })();
    WB.start();
    return WB;
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