**WorkerBench** is a tool that can be used to determine an appropriate number
of [**`WebWorkers`**][WW] to create when running tasks in parallel in the web
browser. It is an attempt at a polyfill of the [Hardware Concurrency API][API].
It works by running a series of benchmarking tests, where it spins up a group of
`WebWorkers`, the number of which increases with each test. For each test, the
`Worker` threads are kept busy for a period of time, and the time taken for the
whole set of `WebWorkers` to complete is monitored. Eventually, there is some
number of `Worker` instances where the browser can't maintain all the threads
simultaneously, and has to wait for one of the threads to finish before
starting another. This cause a significant increase in the overall time taken.
By finding the smallest time taken to run the tasks, **WorkerBench** determines
a fairly reliable estimate (usually correct, or one less than expected) of how
many `Worker` instances are appropriate for the current device. This estimate
is of course dependent on what else the device is doing at the time.

[WW]: http://www.whatwg.org/specs/web-apps/current-work/multipage/workers.html
[API]: http://wiki.whatwg.org/wiki/Navigator_HW_Concurrency

___
# <section id="Shims">Shims</section>

## <section id="PerformanceNow">performance.now:</section>

Ideally, we want to be able to use the [**High Resolution Timer**][HRT] for
timing the benchmark tests, but that won't be implemented in all browsers for
a while (Currently only Chrome). To be ready for if/when they are implemented
in other browsers, we re-assign each of the likely vendor prefixes to
`performance.now` with a fall-back to `Date.getTime()` if necessary.

[HRT]: https://dvcs.w3.org/hg/webperf/raw-file/tip/specs/HighResolutionTime/Overview.html

    window.performance ?= {}
    performance.now = do ->
      performance.now or
      performance.webkitNow or
      performance.mozNow or
      performance.msNow or
      performance.oNow or
      -> new Date().getTime()

## <section id="windowURL">window.URL:</section>

In order to create a `Worker` inline, we need `window.URL.createObjectURL` which
was prefixed in older versions of Webkit.

    window.URL = do ->
      window.URL or
      window.webkitURL

___
# <section id="Utitlities">Utilities</section>

## <section id="log">_log:</section>

We have a silly utility function just to make sure that `console.log` exists,
and to wrap anything that is logged from **WorkerBench** so the user can see
where the log came from.

    _log = (message, type = 'log') ->
      if console and console[type]
        console[type] "WorkerBench says: '#{message}'"

___
# <section id="WorkerBench">WorkerBench Factory</section>

The [**`WorkerBench`**][WB] module encapsulates all the functionality of
**WorkerBench**, and exposes four functions to the outside scope:
[**`workersAvailable`**][wA], [**`setup`**][setup], [**`start`**][start] and
[**`result`**][result]. All these function are made available externally, but
**`start`** is automatically called at the end of this script by default.

[WB]: #WorkerBench
[wA]: #workersAvailable
[setup]: #setup
[start]: #start
[result]: #result

    WBFactory = ->
      WB = do ->

First, we have to check that the **Worker** constructor is available, and if
not, create default functions that let the user know that the benchmark tests
can't be run without **Workers**.

        unless Worker?
          _result = 1
          unavailable = ->
            _log 'WebWorkers are not available.'
            false
          setup = start = workersAvailable = unavailable

Provided that the **Worker** constructor is available, which means that we can
create **WebWorkers**, we create the rest of the [**`WorkerBench`**][WB] module:

[WB]: #WorkerBench

        else

## <section id="PrivateVariables">Private Variables</section>
___

**`inlineWorkerFunction`** is an inline version of the script in [Worker.litcoffee][w]
allowing us to create the `Worker` without needing to make more requests for the
seperate file.

[w]: /docs/worker.html

          _inlineWorkerFunction = """
                                  self.onmessage = function (e) {
                                    var endTime = Date.now() + e.data;
                                    while (Date.now() < endTime) {
                                      (function() {})();
                                    }
                                    self.postMessage('Finished');
                                  };
                                  """

**`_inittime`** is set each time the [**`WorkerBench.start`**][start] function
is called. It is used to measure the time that the benchmark tests take.

[start]: #start

          _inittime = null

**`_result`** is set whenever the benchmark tests are completed. It is available
to the user via the [**`WorkerBench.result`**][result] function.

[result]: #result

          _result = null

**`_options`** is first set with the deafult benchmark options, which can be
changed via the [**`WorkerBench.setup`**][setup] function.

[setup]: #setup

          _options =
            MAX_WORKERS_TO_TEST_FOR: 8
            NUMBER_OF_TIMES_TO_BENCHMARK: 9
            PATH_TO_WORKER_SCRIPT: '.'
            ON_COMPLETE: (result) -> alert "Optimum Web Workers: #{result}"

## <section id="PrivateFunctions">Private Functions</section>
___

## <section id="run">_run:</section>

          _run = (workersPerBenchmark, results = {}) ->

**`_run`** is used to run the next step of the benchmark process. It is a
recursive function, as it is called from the [`_finishedBenchmark`][fB]
function. The recursion is based on the **`workersPerBenchmark`** array,
which contains a list of numbers which represent a number of **WebWorkers**
to use for a benchmark test. If there are any values left in
**`workersPerBenchmark`**, there are more benchmark tests to run and the
recursion continues. If **`workersPerBenchmark`** is empty, the benchmarks
are all completed, so the [**`WorkerBench.result`**][result] function is
updated to return the results of the benchmarks and the recursion is
terminated.

[fB]: #finishedBenchmark
[result]: #result

First, we look to see if there are any more benchmark tests to be completed,
and if there are, we run the next test.

            if workersPerBenchmark.length isnt 0
              _runBenchmark workersPerBenchmark, results

Otherwise, the benchmarking is completed, and we can assign the best result
(as determined by the [**`_generateResult`**][gR] function) to the
**`WorkerBench.result`** function, and report the result to the user.

[gR]: #generateResult

            else
              _result = _generateResult results
              _log "Optimum Web Workers: #{result()}"
              time = (performance.now() - _inittime) / 1000
              _log "Benchmarks took: #{time} seconds."
              _options.ON_COMPLETE _result

## <section id="runBenchmark">_runBenchmark:</section>

          _runBenchmark = (workersPerBenchmark, results, finished = [], workers = []) ->

**`_runBenchmark`** performs most of the heavy lifting. It creates the
**WebWorkers** for a benchmark test, and measures the results. After
the test is completed, it relies on [`_finishedBenchmark`][fB] to tidy
up the resulting data and report back to [`_run`][run] to get the next
test.

[fB]: #finishedBenchmark
[run]: #run

First, we get the number of **WebWorkers** that will be required for this test,
and determine the length of time that the **Worker** thread will timeout for.
This timeout is key to the operation of this tool. The more **Workers** that
the device can handle, the shorter the time for all the tasks to complete
should be. When the browser can't maintain some number of **Workers** there
is an increase in the time taken to finish the test, which lets us make a good
guess at the best number of **Workers** to use for the device.

            nWorkers = workersPerBenchmark.shift()
            timeout = 100 / nWorkers

`_onMessage` is the handler for the `'message'` event, which is fired when
one of the generated **WebWorkers** sents a message back to the main thread to
tell it that it is finished. We keep track of the number of messages received,
and call the [`_finishedBenchmark`][fb] function when the test is complete.

[fB]: #finishedBenchmark

            _onMessage = (e) ->
              finished.push e.data
              if finished.length is nWorkers
                results[nWorkers] ?= []
                results[nWorkers].push (performance.now() - startTime)
                workers.map (worker) -> worker.terminate()
                _finishedBenchmark nWorkers, workersPerBenchmark, results

When starting the **Workers**, we do things in a certain order, to minimise the
difference in their running times. First, we create the correct number of
workers, and add the `_onMessage` handler to each of them.

            [0...nWorkers].map (n) ->
              if window.URL and window.URL.createObjectURL and window.Blob
                blob = new Blob([_inlineWorkerFunction.toString()], type: 'text/javascript')
                workers[n] = new Worker(window.URL.createObjectURL blob)
              else
                workers[n] = new Worker("#{_options.PATH_TO_WORKER_SCRIPT}/worker.min.js")
              workers[n].addEventListener 'message', _onMessage

Then, we get the time that the test started,

            startTime = performance.now()

And finally, post a message to each of the already created threads, which
begins the benchmark test.

            workers.map (worker) -> worker.postMessage timeout

## <section id="finishedBenchmark">_finishedBenchmark:</section>

          _finishedBenchmark = (nWorkers, workersPerBenchmark, results) ->

**`_finishedBenchmark`** has three main tasks:

1. Determining the number of **WebWorkers** to use in the next benchmark.

2. Removing outlying results - the highest and lowest from the set.

3. Watching for when the result times begin to increase, indicating the
optimum amount of **Workers** has passed.

If the test needs to be run again with the same number of **Workers**, the
previous value is added to the start of the **`workersPerBenchmark`** list.

            if results[nWorkers].length < _options.NUMBER_OF_TIMES_TO_BENCHMARK
              workersPerBenchmark.unshift nWorkers

Otherwise, the data for the previous number of **Workers** is collated:

            else

If the tests were ran `3` or more times, the highest and lowest values are
discarded.

              if _options.NUMBER_OF_TIMES_TO_BENCHMARK > 2
                sortedResults = results[nWorkers].sort()
                results[nWorkers] = sortedResults[1...results[nWorkers].length - 1]

Then the average of the remaining results is taken as the result for that number
of **Workers**.

              results[nWorkers] = (results[nWorkers].reduce (sum, next) ->
                sum + next) / _options.NUMBER_OF_TIMES_TO_BENCHMARK

If the time taken has increased over the last two sets of benchmarks, the
**`workersPerBenchmark`** list is emptied, which will terminate the tests.

              resultN = results[nWorkers]
              resultP = results[nWorkers - 1]
              resultPP = results[nWorkers - 2]

              if nWorkers > 2 and resultN > resultP and resultN > resultPP
                workersPerBenchmark = []

The **`workersPerBenchmark`** list is passed back to the [`_run`][run]
function, which will either continue, or terminate the benchmarking process.

[run]: #run

            _run workersPerBenchmark, results

## <section id="generateResult">_generateResult:</section>

        _generateResult = (results, smallestTime = Infinity, bestNWorkers = 0) ->

**`_generateResult`** simply looks through the set of results and picks the
smallest time taken to complete the set of tasks. This value should be the
optimum number of **WebWorkers** to run on the current device.

            for own nWorkers, nResult of results
              if nResult < smallestTime
                smallestTime = nResult
                bestNWorkers = +nWorkers
            bestNWorkers

## <section id="PublicFunctions">Public Functions</section>
___

### <section id="workersAvailable">WorkerBench.workersAvailable:</section>

**`WorkerBench.workersAvailable`** provides an easy **boolean** check for whether
this browser can use **WebWorkers**. It can be used to provide different
functionality for a page if **`Workers`** aren't available.

          workersAvailable = ->
            _log 'WebWorkers are available.'
            true

### <section id='setup'>WorkerBench.setup:</section>
**`WorkerBench.setup`** can be called before running the benchmarks. It allows
the user to specify options for the benchmark tests, including:

* `maxWorkersToTestFor` - The maximum number of **WebWorkers** that should be
tested for. *Defaults to `8`*, rounded up to the nearest power of two.

* `numberOfTimesToBenchmark` - The number of times that the benchmark test
should be run. Higher values yield more accurate results, but take longer to
run. *Defaults to `5`*

* `pathToWorkerScript` - The path to the [*worker.js*][worker] file. *Defaults
to `'.'`*

* `onComplete` - The function that is called when the test have been completed.
*Defaults to `(result) -> alert "Optimum Web Workers: #{result}"`*

[worker]: worker.html

          { pow, ceil, log, LN2 } = Math
          setup = (options = {}) ->
            maxWorkers = options.maxWorkersToTestFor or _options.MAX_WORKERS_TO_TEST_FOR
            _options.MAX_WORKERS_TO_TEST_FOR = pow(2, ceil(log(maxWorkers) / LN2))
            _options.NUMBER_OF_TIMES_TO_BENCHMARK = options.numberOfTimesToBenchmark or _options.NUMBER_OF_TIMES_TO_BENCHMARK
            _options.PATH_TO_WORKER_SCRIPT = options.pathToWorkerScript or _options.PATH_TO_WORKER_SCRIPT
            _options.ON_COMPLETE = options.onComplete or _options.ON_COMPLETE

### <section id="start">WorkerBench.start:</section>

**`WorkerBench.start`** is used to start the benchmark process. It resets the
*_inittime* and calls the [`_run`][run] function with the maximum number of
**Workers** to try to run.

[run]: #run

          start = (callback) ->
            if callback? and typeof callback is 'function'
              _options.ON_COMPLETE = callback
            _inittime = performance.now()
            _run [0..log(_options.MAX_WORKERS_TO_TEST_FOR) / LN2].map (n) -> pow 2, n

### <section id="result">WorkerBench.result:</section>

**`WorkerBench.result`** is initially set to just report that the benchmark
hasn't finished and to return `false`. When the benchmark has finished, it
will return the optimum number of **WebWorkers** for the current device.

          result = ->
            if _result
              _result
            else
              _log 'Benchmark not yet complete.', 'warn'
              false

**`navigator.getHardwareConcurrency`** and **`navigator.hardwareConcurrency`**
are set so that **WorkerBench** can act as a polyfill for the
[Hardware Concurrency API][API]

[API]: http://wiki.whatwg.org/wiki/Navigator_HW_Concurrency

        if window?.navigator? and window.navigator.hardwareConcurrency
          start = (callback = _options.ON_COMPLETE) ->
            if callback? and typeof callback is 'function'
              callback navigator.hardwareConcurrency

          result = ->
            navigator.hardwareConcurrency

        if window?.navigator? and !window.navigator.hardwareConcurrency
          navigator.getHardwareConcurrency = start
          Object.defineProperty navigator, 'hardwareConcurrency', get: result

        { workersAvailable, setup, start, result }

___
## <section id="ModuleDefinition">Module Definition</section>

**WorkerBench** tries to define itself as an AMD module, but will fall back to
assigning itself to `window` if `define` isn't available.

    createModule = (factory) ->
      if typeof window.define is 'function' and define.amd
        define factory
      else
        window.WorkerBench = factory()

    createModule WBFactory
