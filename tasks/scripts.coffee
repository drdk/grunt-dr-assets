'use strict'

module.exports = (grunt) ->

  grunt.registerTask "dr-assets-scripts", "Builds DR Script files", ->

    config = grunt.config.get("dr-assets")[@name]

    grunt.log.ok("Successfully built DR scripts (not really, this is just a mockup)")