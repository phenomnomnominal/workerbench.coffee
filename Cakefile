{spawn, exec} = require 'child_process'

task 'compile', 'compile everything', ->
  exec 'coffee -o javascript/ -cw coffeescript/'
  console.log 'Done compile, now watching for changes...'

task 'docs', 'create docs', ->
  exec 'docco -c docs/docco.css coffeescript/workerbench.coffee'
  exec 'docco -c docs/docco.css coffeescript/worker.coffee'
  console.log 'Done docs.'

task 'lint', 'run Coffeelint on all CoffeeScripts', ->
  lint = exec "coffeelint -r coffeescript"
  lint.stdout.on 'data', (data) -> console.log data.toString()
  lint.stderr.on 'data', (data) -> console.log data.toString()
  console.log 'Done lint'

task 'all', 'compile everything and create the docs', ->
  console.log 'Running compile...'
  invoke 'compile'
  console.log 'Running docs...'
  invoke 'docs'
  console.log 'Running Coffeelint'
  invoke 'lint'