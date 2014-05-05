'use strict'

module.exports = (grunt) ->

  grunt.registerMultiTask "dr-assets", "Main subtask controller", ->

    # Make sure the requires config properties are defined
    grunt.config.requires(
      @name
      @name + "." + @target + "." + "options"
      @name + "." + @target + "." + "options" + "." + "rootPath"
    )

    # Reference config settings
    config = grunt.config.get(@name)
    
    # Make sure root path has ending slash
    config[@target].options.rootPath = config[@target].options.rootPath + "/" if config[@target].options.rootPath.substr(-1) isnt "/"

    # Update processed config parameters
    grunt.config.set(@name, config)


    # Start subtasks

    switch @target
      when "styles"
        grunt.log.writeln("Starting styles subtasks")
        grunt.task.run("styles")
    
      when "scripts"
        grunt.log.writeln("Starting scripts subtasks")
        grunt.task.run("scripts")
    
      else
        grunt.fail.warn "Failed. No tasks were recognized."