'use strict'

module.exports = (grunt) ->

  grunt.registerTask "scripts", "Builds DR script files", (env) ->

    # Load libraries
    _  = require('lodash')
    fs = require('fs')

    # Set this module path
    taskPath   = __dirname + "/.."    

    # Reference config settings
    config = grunt.config.get("dr-assets")[@name]

    # Read environment variables
    if env? and env is "development"
      config.options.compressJS = false
    else
      config.options.compressJS = true

    # Set the other default values
    config.options = _.defaults config.options, 
      tempPath            : config.options.rootPath + "dr-assets-tmp/"
      compilePaths        : {}
      drScriptsPath       : taskPath + "/node_modules/dr-assets/js"
      bootstrapPath       : taskPath + "/node_modules/dr-assets/node_modules/bootstrap/js"
      buildCorejs         : false
      cleanBeforeBuild    : false
      concatFiles         : false
      bootstrapComponents : []
      drComponents        : []

    # Make sure DR Assets path exists.
    if not fs.existsSync(config.options.drScriptsPath)
      grunt.fail.warn('An error occured. Could not find DR Assets at ' + config.options.drScriptsPath + ' .')

    # Make sure Bootstrap path exists.
    if not fs.existsSync(config.options.bootstrapPath)
      grunt.fail.warn('An error occured. Could not find Bootstrap at ' + config.options.bootstrapPath + ' .')

    # Load styles config file
    scriptsConfig = grunt.file.readJSON(taskPath + "/config/scripts.json")
    if not scriptsConfig? then grunt.fail.warn('An error occured. Config (' + taskPath + "/config/scripts.json" + ') was not found.')

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
    bootstrapComponentFiles = []
    drComponentFiles        = []
    drCoreFiles             = scriptsConfig["dr-core"].files
    tempPath                = config.options.tempPath

    # Add Bootstrap Components
    if config.bootstrapComponents? and _.isArray(config.bootstrapComponents) and config.bootstrapComponents.length > 0
      # Make sure the user isn't trying to include all bootstrap files!
      if config.bootstrapComponents.indexOf("*") isnt -1 or config.bootstrapComponents.indexOf("**/*") isnt -1
        grunt.fail.warn('An error occured. Forbidden path (* or */**). Only choose the necessary files.')

      bootstrapComponentFiles.push file + ".js" for file in config.bootstrapComponents
      runTasks.push("bootstrap-components")

    # Add DR Components
    if config.drComponents? and _.isArray(config.drComponents) and config.drComponents.length > 0
      drComponentFiles.push file + ".js" for file in config.drComponents
      runTasks.push("dr-components")

    # Should we build core.js?
    if config.options.buildCorejs
      runTasks.push("dr-core")

    if config.options.cleanBeforeBuild
      for name, settings of scriptsConfig
        if scriptsConfig[name].compile
          compileFiles.push config.options.compilePaths.js + scriptsConfig[name].compile.dest 
          compileFiles.push config.options.compilePaths.js + scriptsConfig[name].compile.dest.split("/")[0]

    # Set task config
    taskConfigs =
      "dr-scripts-copy":
        "bootstrap-components":
          expand  : true
          cwd     : tempPath + scriptsConfig["bootstrap-components"].cwd
          src     : bootstrapComponentFiles
          dest    : config.options.compilePaths.js + scriptsConfig["bootstrap-components"].dest
    
        "dr-components":
          nonull  : true
          expand  : true
          cwd     : tempPath + scriptsConfig["dr-components"].cwd
          src     : drComponentFiles
          dest    : config.options.compilePaths.js + scriptsConfig["dr-components"].dest

        "dr-core":
          expand  : true
          cwd     : config.options.drScriptsPath + scriptsConfig["dr-core"].cwd
          src     : drCoreFiles
          dest    : config.options.compilePaths.js + scriptsConfig["dr-core"].dest

      "dr-scripts-concat":
        options:
          separator: ";"
          nonull: true
        default:
          files: {}

      "dr-scripts-clean": 
        all       : compileFiles



    (-> #processYAMLfile
      grunt.file.expand(config.options.drScriptsPath + "/**/*.yaml").forEach (file) ->
        outputName = config.options.compilePaths.js + file.slice(file.lastIndexOf("/") + 1, -5)
        concatFiles = grunt.file.readYAML(file).files
        for file, index in concatFiles
          concatFiles[index] = tempPath + file.slice(0, file.lastIndexOf("/")) + "/" + file
        taskConfigs["dr-scripts-concat"].default.files[outputName] = concatFiles
    )()




    #(-> #processYAMLfile
    #  grunt.file.expand(config.basePath + "/js/**/*.yaml").forEach (file) ->
    #    index = undefined
    #    path = undefined
    #    outputName = file.slice(0, file.length - 5)
    #    concatFiles = grunt.file.readYAML(file).files
    #    for index of concatFiles
    #      path = concatFiles[index]
    #      concatFiles[index] = file.slice(0, file.lastIndexOf("/")) + "/" + path
    #    config["concat"]["default"].files[outputName] = concatFiles
    #    return
    #  return
    #)()


    # Load grunt npm tasks
    grunt.loadNpmTasks('grunt-contrib-copy')
    grunt.renameTask('copy', 'dr-scripts-copy')

    grunt.loadNpmTasks('grunt-contrib-clean')
    grunt.renameTask('clean', 'dr-scripts-clean')

    grunt.loadNpmTasks('grunt-contrib-concat')
    grunt.renameTask('concat', 'dr-scripts-concat')

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
        # Run copy tasks
        copyTasks.push "dr-scripts-copy:" + task
      
      grunt.task.run("dr-scripts-concat")
      grunt.task.run(copyTasks) 
      grunt.task.run(compileTasks)

      #grunt.task.run("dr-scripts-clean:temp")
    else
      # No tasks were defined
      grunt.fail.warn "Not running any tasks."