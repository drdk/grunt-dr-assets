'use strict'

module.exports = (grunt) ->

  grunt.registerTask "styles", "Builds DR LESS and CSS files", (env) ->

    # Load libraries
    _  = require('lodash')
    fs = require('fs')

    # Set this module path
    taskPath   = __dirname + "/.."    

    # Reference config settings
    config = grunt.config.get("dr-assets")[@name]

    # Read environment variables
    if env? and env is "development"
      config.options.compressCSS = false
    else
      config.options.compressCSS = true

    # Set the other default values
    config.options = _.defaults config.options, 
      tempPath            : config.options.rootPath + "dr-assets-tmp/"
      compilePaths        : {}
      drStylesPath        : taskPath + "/node_modules/dr-assets/less"
      bootstrapPath       : taskPath + "/node_modules/dr-assets/node_modules/bootstrap/less"
      buildMixins         : true
      buildCoreCSS        : false
      cleanBeforeBuild    : false
      concatFiles         : false
      includeBuildFiles   : false
      bootstrapComponents : []
      drComponents        : []

    # Make sure DR Assets path exists.
    if not fs.existsSync(config.options.drStylesPath)
      grunt.fail.warn('An error occured. Could not find DR Assets at ' + config.options.drStylesPath + ' .')

    # Make sure Bootstrap path exists.
    if not fs.existsSync(config.options.bootstrapPath)
      grunt.fail.warn('An error occured. Could not find Bootstrap at ' + config.options.bootstrapPath + ' .')

    # Load styles config file
    stylesConfig = grunt.file.readJSON(taskPath + "/config/styles.json")
    if not stylesConfig? then grunt.fail.warn('An error occured. Config (' + taskPath + "/config/styles.json" + ') was not found.')

    # Define paths
    if not config.options.compilePaths.css?
      config.options.compilePaths.css  = config.options.rootPath + "css/" 
    else
      config.options.compilePaths.css = config.options.compilePaths.css + "/" if config.options.compilePaths.css.substr(-1) isnt "/"

    if not config.options.compilePaths.less?
      config.options.compilePaths.less = config.options.rootPath + "less/" if not config.options.compilePaths.less?
    else
      config.options.compilePaths.less = config.options.compilePaths.less + "/" if config.options.compilePaths.less.substr(-1) isnt "/"

    # Only build if it doesnt exist?
    if config.options.skipIfExists
      if fs.existsSync(config.options.compilePaths.css) and fs.existsSync(config.options.compilePaths.less)
        return grunt.log.ok('Skipping build as the following paths already exists: ' + config.options.compilePaths.css + ', ' + config.options.compilePaths.less)

    # Read and set vars for running the tasks
    runTasks                = []
    compileFiles            = []
    bootstrapComponentFiles = []
    bootstrapMixinFiles     = stylesConfig["bootstrap-mixins"].files
    bootstrapCoreFiles      = stylesConfig["bootstrap-core"].files
    drComponentFiles        = []
    drMixinFiles            = stylesConfig["dr-mixins"].files
    drCoreFiles             = stylesConfig["dr-core"].files
    drBuildFiles            = stylesConfig["dr-build"].files
    tempPath                = config.options.tempPath

    # Add LESS files
    if config.options.buildMixins
      runTasks.push("bootstrap-mixins", "dr-mixins")
    else
      if config.bootstrapComponents? or config.drComponents?
        grunt.fail.warn('An error occured. Cannot build components when `buildMixins` is false. Set this to true to enable components.') 

    # Add Bootstrap Components
    if config.bootstrapComponents? and _.isArray(config.bootstrapComponents) and config.bootstrapComponents.length > 0
      # Make sure the user isn't trying to include all bootstrap files!
      if config.bootstrapComponents.indexOf("*") isnt -1 or config.bootstrapComponents.indexOf("**/*") isnt -1
        grunt.fail.warn('An error occured. Forbidden path (* or */**). Only choose the necessary files. Btw, mixins are always included.')

      bootstrapComponentFiles.push file + ".less" for file in config.bootstrapComponents
      intersection = _.intersection(bootstrapComponentFiles, bootstrapCoreFiles)

      if intersection.length > 0
        grunt.log.subhead "NOTE: Some of the defined component files are already in the core. These files will be ignored: " + intersection.join(", ")
        bootstrapComponentFiles = _.difference bootstrapComponentFiles, bootstrapCoreFiles
      runTasks.push("bootstrap-components")

    # Add DR Components
    if config.drComponents? and _.isArray(config.drComponents) and config.drComponents.length > 0
      drComponentFiles.push file + ".less" for file in config.drComponents
      runTasks.push("dr-components")

    # Should we build core.css?
    if config.options.buildCoreCSS
      logosPath = config.options.compilePaths.css + "../shared/dr-logos.less"
      if not fs.existsSync(logosPath)
        grunt.fail.warn('An error occured. Could not find logos.less at ' + logosPath + ' . This type of build is only for global-assets.')
      runTasks.push("bootstrap-core", "dr-core")

    if config.options.includeBuildFiles
      runTasks.push("dr-build")

    if config.options.cleanBeforeBuild
      for name, settings of stylesConfig
        if stylesConfig[name].compile
          compileFiles.push config.options.compilePaths.css + stylesConfig[name].compile.dest 
          compileFiles.push config.options.compilePaths.css + stylesConfig[name].compile.dest.split("/")[0]
        compileFiles.push config.options.compilePaths.less + stylesConfig[name].dest if stylesConfig[name].dest.length > 0
      compileFiles.push config.options.compilePaths.less + drBuildFile for drBuildFile in drBuildFiles 

    # Set task config
    taskConfigs =
      "dr-styles-copy":
        "bootstrap-mixins":
          expand  : true
          cwd     : config.options.bootstrapPath + stylesConfig["bootstrap-mixins"].cwd
          src     : bootstrapMixinFiles
          dest    : config.options.compilePaths.less + stylesConfig["bootstrap-mixins"].dest

        "bootstrap-components":
          expand  : true
          cwd     : config.options.bootstrapPath + stylesConfig["bootstrap-components"].cwd
          src     : bootstrapComponentFiles
          dest    : tempPath + stylesConfig["bootstrap-components"].dest

        "bootstrap-core":
          expand  : true
          cwd     : config.options.bootstrapPath + stylesConfig["bootstrap-core"].cwd
          src     : bootstrapCoreFiles
          dest    : tempPath + stylesConfig["bootstrap-core"].dest

        "dr-mixins":
          expand  : true
          cwd     : config.options.drStylesPath + stylesConfig["dr-mixins"].cwd
          src     : drMixinFiles
          dest    : config.options.compilePaths.less + stylesConfig["dr-mixins"].dest
    
        "dr-components":
          nonull  : true
          expand  : true
          cwd     : config.options.drStylesPath + stylesConfig["dr-components"].cwd
          src     : drComponentFiles
          dest    : tempPath + stylesConfig["dr-components"].dest

        "dr-core":
          expand  : true
          cwd     : config.options.drStylesPath + stylesConfig["dr-core"].cwd
          src     : drCoreFiles
          dest    : tempPath + stylesConfig["dr-core"].dest

        "dr-build":
          expand  : true
          cwd     : config.options.drStylesPath + stylesConfig["dr-build"].cwd
          src     : drBuildFiles
          dest    : config.options.compilePaths.less + stylesConfig["dr-build"].dest

      "dr-styles-clean": 
        all: compileFiles
        temp: [tempPath]

      "dr-styles-less":
        "bootstrap-components":
          options: 
            ieCompat: true
            strictMath: true
            sourceMap: false
            cleancss: config.options.compressCSS
            paths: [config.options.compilePaths.less]
            imports: 
              reference: ["dr/variables.less", "bootstrap/mixins.less"]
          files: [
            expand: true
            cwd: tempPath + stylesConfig["bootstrap-components"].dest
            src: bootstrapComponentFiles
            dest: config.options.compilePaths.css + stylesConfig["bootstrap-components"].compile.dest
            ext: ".css"
          ]

        "dr-components":
          options: 
            ieCompat: true
            strictMath: true
            sourceMap: false
            cleancss: config.options.compressCSS
            paths: [config.options.compilePaths.less]
            imports: 
              reference: ["dr/variables.less", "bootstrap/mixins.less", "dr/mixins.less"]
          files: [
            expand: true
            cwd: tempPath + stylesConfig["dr-components"].dest
            src: drComponentFiles
            dest: config.options.compilePaths.css + stylesConfig["dr-components"].compile.dest
            ext: ".css"
          ]

        "dr-core":
          "core":
            options:
              strictMath: true
              sourceMap: false
              cleancss: config.options.compressCSS
              expand: true
              flatten: false
              ieCompat: true
              stripBanners:
                options:
                  block: true
                  line: true
            files: [
              { src: tempPath + stylesConfig["dr-core"].dest + "core.less", dest: config.options.compilePaths.css + stylesConfig["dr-core"].compile.dest }
            ]
          "dr-fonts":
            options:
              strictMath: true
              sourceMap: false
              expand: true
            files: [
              { src: tempPath + stylesConfig["dr-core"].dest + "fonts-svg.less", dest: config.options.compilePaths.css + "fonts-svg.css" }
              { src: tempPath + stylesConfig["dr-core"].dest + "fonts-ttf.less", dest: config.options.compilePaths.css + "fonts-ttf.css" }
              { src: tempPath + stylesConfig["dr-core"].dest + "fonts-woff.less", dest: config.options.compilePaths.css + "fonts-woff.css" }
            ]

          #src: tempPath + stylesConfig["dr-core"].dest + "core.less"
          #dest: config.options.compilePaths.css + stylesConfig["dr-core"].compile.dest

      "dr-styles-csscomb":
        "bootstrap-components":
          options:
            config: config.options.rootPath + stylesConfig["dr-build"].dest + ".csscomb.json"
          files: [
            expand: true
            cwd: config.options.rootPath + stylesConfig["bootstrap-components"].compile.dest
            src: "**/*.css"
            dest: config.options.compilePaths.css + stylesConfig["bootstrap-components"].compile.dest
          ]

        "dr-components":
          options:
            config: config.options.rootPath + stylesConfig["dr-build"].dest + ".csscomb.json"
          files: [
            expand: true
            cwd: config.options.rootPath + stylesConfig["dr-components"].compile.dest
            src: "**/*.css"
            dest: config.options.compilePaths.css + stylesConfig["dr-components"].compile.dest
          ]

        "dr-core":
          options:
            config: config.options.rootPath + stylesConfig["dr-build"].dest + ".csscomb.json"
          files: [
            expand: true
            cwd: config.options.rootPath + stylesConfig["dr-core"].compile.dest
            src: "**/*.css"
            dest: config.options.compilePaths.css + stylesConfig["dr-core"].compile.dest
          ]

    concatLessFiles = (subtask, componentFiles) =>
      return if not subtask? or not componentFiles?
      taskConfigs["dr-styles-less"][subtask].files = {}
      componentSrcFiles = []
      componentSrcFiles.push tempPath + stylesConfig[subtask].dest + componentFile for componentFile in componentFiles
      taskConfigs["dr-styles-less"][subtask].files[config.options.compilePaths.css + stylesConfig[subtask].compile.dest + '/' + subtask + '.css'] = componentSrcFiles
  
    grunt.registerTask "inline-webfonts", "Inline webfonts in stylesheets", ->
        inline = require("dr-webfont-inliner")
        ["woff", "ttf", "svg"].forEach (type) ->
          targetPath = config.options.compilePaths.css
          inline(targetPath + "fonts-" + type + ".css", targetPath + "fonts-" + type + ".css")

    if config.options.concatFiles
      concatLessFiles("bootstrap-components", bootstrapComponentFiles)
      concatLessFiles("dr-components", drComponentFiles)

    # Load grunt npm tasks
    grunt.loadNpmTasks('grunt-contrib-copy')
    grunt.renameTask('copy', 'dr-styles-copy')

    grunt.loadNpmTasks('grunt-contrib-clean')
    grunt.renameTask('clean', 'dr-styles-clean')

    grunt.loadNpmTasks('assemble-less')
    grunt.renameTask('less', 'dr-styles-less')

    grunt.loadNpmTasks('grunt-csscomb')
    grunt.renameTask('csscomb', 'dr-styles-csscomb')

    # Run the relevant tasks
    if runTasks.length > 0
      copyTasks         = []
      compileTasks      = []
      resortTasks       = []
    
      for name, settings of taskConfigs
        grunt.config.set name, settings

      if config.options.cleanBeforeBuild
        grunt.task.run("dr-styles-clean:all") 

      for task in runTasks
        # Run copy tasks
        copyTasks.push "dr-styles-copy:" + task

        # Run css compilation
        if stylesConfig[task].compile isnt false
          compileTasks.push "dr-styles-less:" + task
          resortTasks.push "dr-styles-csscomb:" + task
      
      grunt.task.run(copyTasks) 
      grunt.task.run(compileTasks) 
      grunt.task.run(resortTasks) 

      if config.options.buildCoreCSS
        grunt.task.run("inline-webfonts")

      grunt.task.run("dr-styles-clean:temp")
    else
      # No tasks were defined
      grunt.fail.warn "Not running any tasks."