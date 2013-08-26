module.exports = (grunt) ->

  # build config
  grunt.initConfig(
    clean:
      lib:
        src: 'lib/**'

    coffee:
      compile:
        expand: true
        cwd: 'src/'
        src: [ '**/*.coffee', '**/*.coffee.md' ]
        dest: 'lib/'
        ext: '.js'

    simplemocha:
      options:
        ui: 'bdd'
        reporter: 'spec'

      all:
        src: 'test/**/*.coffee'
  )

  # load plugins
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-simple-mocha')

  # tasks
  grunt.registerTask('default', [ 'clean:lib', 'coffee:compile' ])
  grunt.registerTask('test', [ 'default', 'simplemocha:all' ])

