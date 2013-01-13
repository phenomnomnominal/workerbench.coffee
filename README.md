## workerbench.coffee (v0.1.0)

Need to use a whole bunch of [**WebWorkers**](http://www.whatwg.org/specs/web-apps/current-work/multipage/workers.html), but don't know what devices they will run on? Unfortunately, the spec doesn't define a mechanism to get any information about the capabilities of the device, so how can you know what the best number of **Workers** to launch is?

**WorkerBench** is a tool designed to work out just this! It runs a series of benchmark tests to make a reasonable guess about the best number of threads to run on a given device.

## How to use:

**WorkerBench** should be pretty straightforward to use! Download the CoffeeScript source, compile it to JavaScript and just include it in your page as you would any other scripts. 
The only consideration that needs to be made is where the **worker.js** file is placed relative to the **workerbench.js** file.
By default, it looks for the **worker.js** script in a `'javascript/workerbench'` folder, but the correct path can be provided as one of the initialisation options.

## Initialisation:

By adding the script to the page, the tool will be run with the default configuration when the script loads. This can be prevented by removing lines 164-166 from **workerbench.js**

    WorkerBench.init();

    WorkerBench.start();
    
These can then be called from any other script, as the **WorkerBench** module (with it's three public functions **init**, **start** and **result**) is attached to the global object. For example, the jQuery 'ready' function:

    $(function() {
      WorkerBench.init();
      WorkerBench.start();
    });
    
The **WorkerBench.init** function takes a configuration `_options` object, which currently accepts `4` options:

* `maxWorkersToTestFor` - The maximum number of **WebWorkers** that should be tested for. *Defaults to `8`*

* `numberOfTimesToBenchmark` - The number of times that the benchmark test should be run. Higher values yield more accurate results, but take longer to run. *Defaults to `5`*

* `pathToWorkerScript` - The path to the **worker.js** file. Ideally the **Worker** script would be inline with a URL generated from a single script to avoid the need for this, but the [**URL API**](https://developer.mozilla.org/en-US/docs/DOM/window.URL.createObjectURL) is not yet as widely supported as **WebWorkers**. *Defaults to `'javascript/workerbench'`*

* `onComplete` - The function that is called when the test have been completed. *Defaults to `-> alert "Optimum Web Workers: #{WorkerBench.result()}`"*

Rather than launching the tool from a seperate script, the **WorkerBench.init** function call on line 164 of **workerbench.js** can be modified to take an `_options` object as well.

## Running the tool:

**WorkerBench** can be configured and run as many times as you like within a programme. Simply pass a new `_options` object to the `init` function to change the configuration, or just call the **WorkerBench.start** function again to run the benchmark tests again.
Once the `onComplete` function is called when the benchmark tests are complete, the result can be retrieved from **WorkerBench.result** at any time.

A working demo (with the default settings) can be tried [**here**](http://phenomnomnominal.github.com/workerbench)!

## Documentation:

Full documentation for the two CoffeeScript files can be viewed at:

* [**worker.coffee**](http://phenomnomnominal.github.com/docs/worker.html)

* [**workerbench.coffee**](http://phenomnomnominal.github.com/docs/workerbench.html)
