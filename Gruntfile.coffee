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
        src: '**/*.coffee'
        dest: 'lib/'
        ext: '.js'

    copy:
      js:
        expand: true
        cwd: 'src/'
        src: '**/*.js'
        dest: 'lib/'
  )

  # load plugins
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-copy')

  # tasks
  grunt.registerTask('default', [ 'clean:lib', 'coffee:compile', 'copy:js' ])

