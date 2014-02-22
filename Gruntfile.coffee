module.exports = (grunt) ->
  grunt.initConfig
    devserver:
      server:
        options:
          port: 8080
    coffee:
      compile:
        options:
          sourceMap: true
        files:
          'worker.js': 'coffeescript/worker.litcoffee',
          'workerbench.js': 'coffeescript/workerbench.litcoffee'
    docco:
      all:
        options:
          layout: 'linear'
        files:
          src: 'coffeescript/*.litcoffee'
    watch:
      app:
        files: ['**/*.litcoffee']
        tasks: ['build']
    uglify:
      minify:
        files:
          'worker.min.js': ['worker.js']
          'workerbench.min.js': ['workerbench.js']
    concurrent:
      default: 
        tasks: ['devserver', 'watch']
        options:
          logConcurrentOutput: true

  grunt.loadNpmTasks 'grunt-concurrent'
  grunt.loadNpmTasks 'grunt-devserver'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-docco-multi'

  grunt.registerTask 'build', ['coffee', 'docco', 'uglify']
  grunt.registerTask 'default', ['concurrent:default']