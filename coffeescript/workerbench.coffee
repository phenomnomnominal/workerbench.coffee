# ___
# **Workerbench.coffee** is a tool that can be used to determine an appropriate number of [**`WebWorkers`**](http://www.whatwg.org/specs/web-apps/current-work/multipage/workers.html) to create when running tasks in parallel in the web browser. Currently, there is no mechanism for easy determining the best number of **WebWorkers** on a device-by-device basis.  This tool works by running a series of benchmarking tests, where it spins up a group of **WebWorkers**, the number of which increases with each test. For each test, the **Worker** threads are kept busy for a period of time, and the time taken for the whole set of **WebWorkers** to complete is monitored. Eventually, there is some number of **Worker** instances where the browser cannot maintain all the threads simultaneously, and has to wait for one of the threads to finish before starting another. This cause a significant increase in the resulting time taken. By finding the smallest time taken to complete the tasks, we can determine a faifly reliable estimate (usually correct, or one less than expected) of how many **Worker** instances are appropriate for the current device. This estimate is also dependent on what else the device is doing at the time.

# # <section id="performance">Performance.now Shim:</section>
# ___

# Ideally, we want to be able to use the [**High Resolution Timer**](https://dvcs.w3.org/hg/webperf/raw-file/tip/specs/HighResolutionTime/Overview.html) for timing the benchmark tests, but that won't be implemented in all browsers for a while (Currently only Chrome). To be ready for if/when they are implemented in other browsers, we re-assign each of the likely vendor prefixes to `performance.now` with a fall-back to `Date.getTime()` if necessary.
window.performance ?= {}
performance.now = (->
  performance.now or
  performance.webkitNow or
  performance.msNow or
  performance.oNow or
  performance.mozNow or
  -> new Date().getTime())()
performance.initTime = performance.now()

# # <section id="workerbench">WorkerBench module:</section>
# ___

# The [**`WorkerBench`**](#workerbench) module encapsulates all the functionality of this tool, and exposes three functions to the outside scope: [**`init`**](#init), [**`start`**](#start) and [**`result`**](#result). Although these function are made available externally, the [**`init`**](#init) and [**`start`**](#start) are automatically called at the end of this script.
WorkerBench = ((WorkerBench = {}) ->
  # First, we have to check that the **Worker** constructor is available, and if not, create default functions that just let the user know that the benchmark test can't be run without **Workers**.
  unless Worker? and (typeof Worker is 'function' or typeof Worker is 'object')
    WorkerBench.init = WorkerBench.run = WorkerBench.results = ->
      console.log 'WebWorkers are not available.'
      false

  # Provided that the **Worker** constructor is available, which means that we can create **WebWorkers**, we create the rest of the [**`WorkerBench`**](#workerbench) module:
  else
    
    # ## Private Variables:
    # ___
    
    # > **`_options`** is first set as an empty object, which will be added to in the [**`WorkerBench.init`**](#init) function.
    
    _options = {}
    
    # ## Public Functions:
    # ___
    
    # > ## <section id='result'>**WorkerBench.result:**</section>
    # > **`WorkerBench.result`** is initially set to just report that the benchmark hasn't finished and to return `false`. When the benchmark has finished, this is overwritten  to return the optimum number of **WebWorkers** for the current device.
    
    WorkerBench.result = ->
      console.log 'Benchmark not yet complete.'
      false

    # > ## <section id='init'>**WorkerBench.init:**</section>
    # > **`WorkerBench.init`** must be called before running the benchmarks. It allows the user to specify options for the benchmark tests, including:
    
    WorkerBench.init = (options = {}) ->
      _options = {}
      
      # > * **`MAX_WORKERS_TO_TEST_FOR`** - The maximum number of **WebWorkers** that should be tested for. *Defaults to `8`*
      #
      # > * **`NUMBER_OF_TIMES_TO_BENCHMARK`** - The number of times that the benchmark test should be run. Higher values yield more accurate results, but take longer to run. *Defaults to `5`*
      #
      # > * **`PATH_TO_WORKER_SCRIPT`** - The path to the [*worker.js*](worker.html) file. Ideally the **Worker** script would be inline with a URL generated from a single scrip to avoid the need for this, but the [**URL API**](https://developer.mozilla.org/en-US/docs/DOM/window.URL.createObjectURL) is not yet as widely supported as **WebWorkers**. *Defaults to `'javascript/workerbench'`*
      # > * **`ON_COMPLETE`** - The function that is called when the test have been completed. *Defaults to `-> alert "Optimum Web Workers: #{WorkerBench.result()}`"*
      defaultOptions =
        maxWorkersToTestFor: 8
        numberOfTimesToBenchmark: 5
        pathToWorkerScript: 'javascript/workerbench'
        onComplete: -> alert "Optimum Web Workers: #{WorkerBench.result()}"

      constant = (key, value) ->
        Object.defineProperty this, key,
          get: -> value
          set: -> throw Error 'Cannot set value of constant!'

      constant.call _options, 'MAX_WORKERS_TO_TEST_FOR', options.maxWorkersToTestFor || defaultOptions.maxWorkersToTestFor
      constant.call _options, 'NUMBER_OF_TIMES_TO_BENCHMARK', options.numberOfTimesToBenchmark || defaultOptions.numberOfTimesToBenchmark
      constant.call _options, 'PATH_TO_WORKER_SCRIPT', options.pathToWorkerScript || defaultOptions.pathToWorkerScript
      constant.call _options, 'ON_COMPLETE', options.onComplete || defaultOptions.onComplete
      
    # > ## <section id='start'>**WorkerBench.start:**</section>
    # > **`WorkerBench.start`** is used to start the benchmark process. It should be called by the user once the called the [**`WorkerBench.init`**](#init) function.
    
    WorkerBench.start = ->
      # > First, there is a check that the correct values have been set on the **`_options`** object. If they have not been set, an **`Error`** is thrown, and the benchmark process is aborted.
      unless (_options.MAX_WORKERS_TO_TEST_FOR and _options.NUMBER_OF_TIMES_TO_BENCHMARK and _options.PATH_TO_WORKER_SCRIPT)
        throw Error 'WorkerBench.init() must be called before WorkerBench.run() is called.'
      # > Otherwise [**`_run`**](#run) is called and the benchmark tests begin.
      else
        _run()

    # ## Private Functions:
    # ___

    # > ## <section id='run'>**_run:**</section>
    # > **`_run`** is used to run the next step of the benchmark process. It is a recursive function, as it is called from the end of the [**`_finishedBenchmark`**](#finished) function. The recursion is based on the **`workersPerBenchmark`** array, which contains a list of numbers, each representing a number of **WebWorkers** to use for a benchmark test. If there are any values left in **`workersPerBenchmark`**, there are more benchmark tests to run and the recursion continues. If **`workersPerBenchmark`** is empty, the benchmarks are all completed, so the [**`WorkerBench.result`**](#result) function is updated to return the results of the benchmarks and the recursion is terminated.
    
    _run = (workersPerBenchmark = [1.._options.MAX_WORKERS_TO_TEST_FOR], results = {}) ->
        
      # > First, we look to see if there are any more benchmark tests to be completed, and if there are, we run the next test.
      if workersPerBenchmark.length isnt 0
        _runBenchmark workersPerBenchmark, results
      # > Otherwise, the benchmarking is completed, and we can assign the best result (as determined by the [**`_generateResult`**](#generate) function) to the **`WorkerBench.result`** function, and report the result to the user.
      else
        WorkerBench.result = -> _generateResult results
        console.log "Optimum Web Workers: #{WorkerBench.result()}"
        console.log "Benchmarks took: #{performance.now() - performance.initTime}."
        _options.ON_COMPLETE()

    # > ## <section id='benchmark'>**_runBenchmark:**</section>
    # > **`_runBenchmark`** performs most of the heavy lifting of this tool. It creates the **WebWorkers** for a benchmark test, and measures the results. After the test is completed, it relies on [**`_finishedBenchmark`**](#finished) to tidy up the resulting data and report back to [**`_run`**](#run) to get the next test.
    
    _runBenchmark = (workersPerBenchmark, results, finished = [], workers = []) ->
      # > First, we get the number of **WebWorkers** that will be required for this test, and determine the length of time that the **Worker** thread will timeout for. This timeout is key to the operation of this tool. The more **Workers** that the device can handle, the shorter the time for all the tasks to complete should be. When the browser can't maintain some number of **Workers** there is an increase in the time taken to finish the test, which lets us make a good guess at the best number of **Workers** to use for the device.
      nWorkers = workersPerBenchmark.shift()
      timeout = 100 / nWorkers
      
      # > **`onMessage`** is the handler for the `'message'` event, which is fired when one of the generated **WebWorkers** sents a message back to the main thread to tell it that it is finished. We keep track of the number of messages received, and call the [**`_finishedBenchmark`**](#finished) function when the test is complete.
      onMessage = (e) =>
        finished.push e.data
        if finished.length is nWorkers
          results[nWorkers] ?= []
          results[nWorkers].push (performance.now() - start)
          worker.terminate() for worker in workers
          _finishedBenchmark nWorkers, workersPerBenchmark, results
          
      # > When starting the **Workers**, we do things in a certain order, to minimise the difference in their running times. First, we create the correct number of workers, and add the **`onMessage`** handler to each of them.
      
      for n in [0...nWorkers]
        workers[n] = new Worker("#{_options.PATH_TO_WORKER_SCRIPT}/worker.js")
        workers[n].addEventListener 'message', onMessage

      # > Then, we get the time that the test started,
    
      start = performance.now()
      
      # > And finally, post a message to each of the already created threads, which begins the benchmark test.
      for n in [0...nWorkers]
        workers[n].postMessage timeout

    # > ## <section id='finished'>**_finishedBenchmark:**</section>
    # > **`_finishedBenchmark`** has three main tasks:
    
    _finishedBenchmark = (nWorkers, workersPerBenchmark, results) ->
    
    # > 1. Determining the number of **WebWorkers** to use in the next benchmark.
    #
    # > 2. Removing outlying results - the highest and lowest from the set.
    #
    # > 3. Watching for when the result times begin to increase, indicating the optimum amount of **Workers** has passed.
      
      # > If the test needs to be run again with the same number of **Workers**, the previous value is added to the start of the **`workersPerBenchmark`** list.
      if results[nWorkers].length < _options.NUMBER_OF_TIMES_TO_BENCHMARK
        workersPerBenchmark.unshift nWorkers
      # > Otherwise, the data for the previous number of **Workers** is collated:
      else
        # > * If the tests were ran `3` or more times, the highest and lowest values are discarded.
        if _options.NUMBER_OF_TIMES_TO_BENCHMARK > 2
          results[nWorkers] = (results[nWorkers].sort())[1...results[nWorkers].length - 1]
        # > * The average of the remaining results is taken as the result for that number of **Workers**.
        results[nWorkers] = (results[nWorkers].reduce (sum, next) -> sum + next) / _options.NUMBER_OF_TIMES_TO_BENCHMARK
        # > * If the time taken has increased over the last two sets of benchmarks, the **`workersPerBenchmark`** list is emptied, which will terminate the tests.
        if nWorkers > 2 and results[nWorkers] > results[nWorkers - 1] and results[nWorkers] > results[nWorkers - 2]
          workersPerBenchmark = []

      # > The **`workersPerBenchmark`** list is passed back to the [**`_run`**](#run) function, which will either continue, or terminate the benchmarking process.
      _run workersPerBenchmark, results

    # > ## <section id='generate'>**_generateResult:**</section>
    # > **`_generateResult`** simply looks through the set of results and picks the smallest time taken to complete the set of tasks. This value should be the optimum number of **WebWorkers** to run on the current device.
    
    _generateResult = (results) ->
      smallestTime = Infinity
      bestNWorkers = 0
      for own nWorkers, result of results
        if result < smallestTime
          smallestTime = result
          bestNWorkers = nWorkers
      bestNWorkers
      
  # The [**`WorkerBench`**](#workerbench) module is then returned to the main scope.
  WorkerBench
)()

# # Initialisation:
#___

# Once the [**`WorkerBench`**](#workerbench) module has been created, this script automatically calls the [**`WorkerBench.init`**](#init) and [**`WorkerBench.start`**](#start) function, which initialises and launches the benchmark test. It is then up to the user to access the [**`WorkerBench.result`**](#result) function to get the best amount of **WebWorkers** to use for their application.
WorkerBench.init()
WorkerBench.start()

# # Exports:
#___

# The [**`WorkerBench`**](#workerbench) module is added to the global **`root`** object, which allows external access to the [**`WorkerBench.init`**](#init), [**`WorkerBench.start`**](#start) and [**`WorkerBench.result`**](#result) functions.
root = exports ? this
root.WorkerBench = WorkerBench