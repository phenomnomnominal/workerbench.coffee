___
**Worker.litcoffee** contains the code that is run each time a [**`Worker`**][WW]
is spawned as part of the benchmarking process.

[WW]: http://www.whatwg.org/specs/web-apps/current-work/multipage/workers.html

___
# <section id="WorkerScript">Worker Script:</section>

## <section id='MessageHandler'>Message Handler:</section>
This is the function that is run when the **`Worker`** receives a message from
the main thread. It keeps this **`Worker`** thread busy for the period of time
defined in `e.data`.

    self.onmessage = (e) ->

First, we determine when we want to stop stalling the thread and start a while
loop so that the thread does nothing until that time.

      endTime = Date.now() + e.data
      (do ->) while Date.now() < endTime

Once the timeout is finished, we post a message back to the main thread, so
that it knows that we are done.

      self.postMessage 'Finished'
