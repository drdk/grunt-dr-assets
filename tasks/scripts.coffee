'use strict'

module.exports = (grunt) ->

  grunt.registerTask "scripts", "Builds DR script files", ->

    # Load libraries
    _  = require('lodash')
    fs = require('fs')

    # Set this module path
    taskPath   = __dirname + "/.."    

    # Reference config settings
    config = grunt.config.get("dr-assets")[@name]

    # Set the other default values
    config.options = _.defaults config.options,
      tempPath            : config.options.rootPath + "dr-assets-tmp/"
      compilePaths        : {}
      drScriptsPath       : taskPath + "/node_modules/dr-assets/js"
      buildCore           : false
      cleanBeforeBuild    : false
      sourceMap           : false
      compress            : false
      concatFiles         : false

    config.drComponents = [] if not config.drComponents?

    # Make sure DR Assets path exists.
    if not fs.existsSync(config.options.drScriptsPath)
      grunt.fail.warn('An error occured. Could not find DR Assets at ' + config.options.drScriptsPath + ' .')

    # Load styles config file
    scriptsConfigPath = taskPath + "/config/scripts.json"
    scriptsConfig = grunt.file.readJSON(scriptsConfigPath)
    if not scriptsConfig? then grunt.fail.warn('An error occured. Config (' + scriptsConfigPath + ') was not found.')

    # Define paths
    if not config.options.compilePaths.js?
      config.options.compilePaths.js  = config.options.rootPath + "js/" 
    else
      config.options.compilePaths.js = config.options.compilePaths.js + "/" if config.options.compilePaths.js.substr(-1) isnt "/"

    # Only build if it doesnt exist?
    if config.options.skipIfExists
      if fs.existsSync(config.options.compilePaths.js)
        return grunt.log.ok('Skipping build as the following paths already exists: ' + config.options.compilePaths.js)

    # Read and set vars for running the tasks
    runTasks                = []
    compileFiles            = []
    drComponentFiles        = []
    drCoreFiles             = scriptsConfig["dr-core"].files
    thirdPartyFiles         = scriptsConfig["third"].files
    tempPath                = config.options.tempPath

    # Should we build core.js?
    if config.options.buildCore
      config.drComponents.push("core")
      runTasks.push("dr-core")

    # Add DR Components
    if config.drComponents? and _.isArray(config.drComponents) and config.drComponents.length > 0
      runTasks.push("dr-components")

    # Should we build third party js
    if config.options.buildThird
      runTasks.push("third")

    # Set task config
    taskConfigs =
      "dr-scripts-copy":
        "dr-components":
          expand  : true
          cwd     : tempPath + scriptsConfig["dr-components"].cwd
          src     : drComponentFiles
          dest    : config.options.compilePaths.js + scriptsConfig["dr-components"].dest

        "dr-core":
          expand  : true
          cwd     : config.options.drScriptsPath + scriptsConfig["dr-core"].cwd
          src     : drCoreFiles # Gets processed and automagically added.
          dest    : tempPath + scriptsConfig["dr-core"].dest

        "third":
          expand  : true
          cwd     : config.options.drScriptsPath + scriptsConfig["third"].cwd
          src     : thirdPartyFiles
          dest    : config.options.compilePaths.js + scriptsConfig["third"].dest

      "dr-scripts-concat":
        options:
          separator: ";"
          nonull: true
        default:
          files: {} # Gets processed and automagically added.

      "dr-scripts-uglify":
        "dr-core":
          options:
            compress: config.options.compress is true
            beautify: config.options.compress is false
            mangle: false
            sourceMap: config.options.sourceMap
          files: [
            { src: _.map(drCoreFiles, (file) -> return tempPath + file), dest: config.options.compilePaths.js + scriptsConfig["dr-core"].compile.dest }
          ]

        "dr-components":
          options:
            compress: config.options.compress is true
            beautify: config.options.compress is false
            mangle: false
            sourceMap: config.options.sourceMap
          files: [{
            expand: true
            cwd: tempPath + scriptsConfig["dr-components"].cwd  
            src: drComponentFiles
            dest: config.options.compilePaths.js + scriptsConfig["dr-components"].dest        
          }]

        "third":
          options:
            compress: scriptsConfig["third"].compile
            mangle: false
          files: [{
            expand: true
            cwd: config.options.compilePaths.js
            src: thirdPartyFiles
            dest: config.options.compilePaths.js + scriptsConfig["third"].dest        
          }]

      "dr-scripts-clean": 
        all: [config.options.compilePaths.js + "**/*", "!" + config.options.compilePaths.js + "**/README"]
        temp: [tempPath]

    processYAMLfile = (component) ->
      if not fs.existsSync(config.options.drScriptsPath + scriptsConfig["dr-components"].cwd + component + "/" + component + ".js.yaml")
        grunt.fail.warn('An error occured. Could not find the requested component (' + component + '). Missing YAML file.')

      grunt.file.expand(config.options.drScriptsPath + scriptsConfig["dr-components"].cwd + component + "/" + component + ".js.yaml").forEach (file) ->
        cwd         = file.slice(0, file.lastIndexOf("/") + 1)
        outputName  = tempPath.slice(0, tempPath.lastIndexOf("/")) + scriptsConfig["dr-components"].cwd + file.slice(file.lastIndexOf("/") + 1, -5)
        concatFiles = grunt.file.readYAML(file).files
        for file, index in concatFiles
          path = concatFiles[index]
          concatFiles[index] = cwd + path
        taskConfigs["dr-scripts-concat"].default.files[outputName] = concatFiles

    processCoreFiles = (files) ->
      if files.length > 0
        # Exclude components
        files = _.filter files, (file) -> file.indexOf("components") is -1
      return files

    # Load grunt npm tasks
    grunt.loadNpmTasks('grunt-contrib-copy')
    grunt.renameTask('copy', 'dr-scripts-copy')

    grunt.loadNpmTasks('grunt-contrib-clean')
    grunt.renameTask('clean', 'dr-scripts-clean')

    grunt.loadNpmTasks('grunt-contrib-concat')
    grunt.renameTask('concat', 'dr-scripts-concat')

    grunt.loadNpmTasks('grunt-contrib-uglify')
    grunt.renameTask('uglify', 'dr-scripts-uglify')

    # Make sure there are no duplicates
    runTasks = _.uniq(runTasks)

    # Run the relevant tasks
    if runTasks.length > 0
      copyTasks         = []
      compileTasks      = []
    
      for name, settings of taskConfigs
        grunt.config.set name, settings

      if config.options.cleanBeforeBuild
        grunt.task.run("dr-scripts-clean:all")

      for task in runTasks
        if task is "dr-components"
          for file in config.drComponents
            processYAMLfile(file)
            drComponentFiles.push file + ".js"
          grunt.task.run("dr-scripts-concat")
          compileTasks.push "dr-scripts-uglify:dr-components"

        if task is "dr-core"
          taskConfigs["dr-scripts-copy"]["dr-core"].src = processCoreFiles(drCoreFiles)
          compileTasks.push "dr-scripts-uglify:dr-core"
        
        if task is "third"
          compileTasks.push "dr-scripts-uglify:third"

        # Run copy tasks
        copyTasks.push "dr-scripts-copy:" + task
        
      grunt.task.run(copyTasks) 

      grunt.task.run(compileTasks)

      grunt.task.run("dr-scripts-clean:temp")
    else
      # No tasks were defined
      grunt.fail.warn "Not running any tasks."