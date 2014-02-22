## workerbench.coffee (v1.1.0)

Need to use a whole bunch of [**WebWorkers**](http://www.whatwg.org/specs/web-apps/current-work/multipage/workers.html), but don't know what devices they will run on? Unfortunately, the spec doesn't define a mechanism to get any information about the capabilities of the device, so how can you know what the best number of **Workers** to launch is?

**WorkerBench** is a tool designed to work it out for you! It runs a series of benchmark tests to make a reasonable guess about the best number of threads to run on a given device.

## How to use:

**WorkerBench** should be pretty straightforward to use! Download the CoffeeScript source and compile it to JavaScript (or just get the JS files from the repo) and include **workerbench.js** in your page.
The only thing you need to think about is where the **worker.js** is in relation to the **workerbench.js** file.
By default, it looks for **worker.js** to be in the same folder as **workerbench.js**, but the correct path can be provided as one of the initialisation options.

## Initialisation:

By adding the script to the page, the tool will be run with the default configuration when the script loads. If you don't want this, just delete the following from the end of the script:

    WB.start()

These can then be called from any other script, as the **WorkerBench** module (with it's four public functions **workersAvailable**, **setup**, **start** and **result**) is attached to the global object. For example, the jQuery 'ready' function:

    $ ->
      WorkerBench.start()

The **WorkerBench.setup** function takes a configuration `_options` object, which currently accepts `4` options:

* `maxWorkersToTestFor` - The maximum number of **WebWorkers** that should be tested for. *Defaults to `8`*

* `numberOfTimesToBenchmark` - The number of times that the benchmark test should be run. Higher values yield more accurate results, but take longer to run. *Defaults to `5`*

* `pathToWorkerScript` - The path to the **worker.js** file. *Defaults to `'.'`*

* `onComplete` - The function that is called when the test have been completed. *Defaults to `(result) -> alert "Optimum Web Workers: #{result}"`*

## Running the tool:

**WorkerBench** can be configured and run as many times as you like. Simply pass a new `_options` object to the **`setup`** function to change the configuration, or just call the **WorkerBench.start** function again to run the benchmark tests again.
Once the `onComplete` function is called when the benchmark tests are complete, the result can be retrieved from **WorkerBench.result** at any time. There is also a **WorkerBench.workersAvailable** function, which gives a **boolean** result as to whether or not the client environment can create **WebWorkers**.
This is useful for providing fall-back functionality in situations where they aren't available.

A working demo (with the default settings) can be tried [**here**](http://phenomnomnominal.github.io/projects/workerbench)!

## Documentation:

Full documentation for the two CoffeeScript files can be viewed at:

* [**worker.coffee**](http://phenomnomnominal.github.io/projects/workerbench/docs/worker.html)

* [**workerbench.coffee**](http://phenomnomnominal.github.io/projects/workerbench/docs/workerbench.html)
