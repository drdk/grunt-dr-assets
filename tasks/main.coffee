'use strict'

module.exports = (grunt) ->

  grunt.registerMultiTask "dr-assets", "Main subtask controller", ->

    # Start the relevant subtasks

    switch @target
      when "styles"
        grunt.log.writeln("Starting styles subtasks")
        grunt.task.run("styles")
    
      when "scripts"
        grunt.log.writeln("Starting scripts subtasks")
        grunt.task.run("scripts")
    
      else
        grunt.fail.warn "Failed. No tasks were recognized."