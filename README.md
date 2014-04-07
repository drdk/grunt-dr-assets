grunt-dr-assets
===============
## Getting Started
This plugin requires Grunt `~0.4.0`

If you haven't used [Grunt](http://gruntjs.com/) before, be sure to check out the [Getting Started](http://gruntjs.com/getting-started) guide, as it explains how to create a [Gruntfile](http://gruntjs.com/sample-gruntfile) as well as install and use Grunt plugins. Once you're familiar with that process, you may install this plugin with this command:

```shell
npm install --save-dev git+ssh://git@github01.net.dr.dk:tu-web-applikationer/grunt-dr-assets.git
```

Once the plugin has been installed, it may be enabled inside your Gruntfile with this line of JavaScript:

```js
grunt.loadNpmTasks('grunt-dr-assets');
```

*This plugin was designed to work with Grunt 0.4.x. If you're still using grunt v0.3.x it's strongly recommended that [you upgrade](http://gruntjs.com/upgrading-from-0.3-to-0.4), but in case you can't please use [v0.3.2](https://github.com/gruntjs/grunt-contrib-copy/tree/grunt-0.3-stable).*



## Styles task
Builds the DR Global styles and outputs css and less files.
### Options

#### rootPath 
Type: `String`  
**_Required parameter_**

This option defines the root path of the output files. For example, set this to "assets" to output files in this directory. Note the value must be set relative to where the Gruntfile is placed.

#### compilePaths
Type: `Object`
Default: `null`

This option sets the output paths of `.css` and `.less` files.
Example:
```javascript
compilePaths: 
  css  : "assets/css"
  less : "assets/less"
```

If this option is not defined the output paths will default to the defined rootPath.

#### cleanBeforeBuild
Type: `Boolean`
Default: `false`

This removes the output files before build if set to true. 

#### concatFiles
Type: `Boolean`
Default: `false`

If set to true `.css` files will be concatenated to a single file.

#### includeBuildFiles
Type: `Boolean`
Default: `true`

If set to true, the following files are included in the less output path: `include.less`, `csscomb.json` and `.csslintrc`.
`include.less` is to simplify the inclusion of mixins and variables. Include this from your own .less inclusion definitions.
`csscomb.json` and `.csslintrc` are to allow utilization of the same sorting and lint settings as the global assets.

#### skipIfExists
Type: `Boolean`
Default: `false`

Set to true to skip build if the output paths already exists. 

### Components

You can define which Bootstrap or DR components you wish to include in your build. These files will be outputted as `.css` in the output path. If any of the defined component files are already in the `core.css`, these files will be skipped, which will be outputted in the task log as:
_"NOTE: Some of the defined component files are already in the core. These files will be ignored: grid.less"_

### Environment Variables

It is possible to set environment variables for the task by adding ":environment" to the task. Right now, you can set ":development" to avoid compression of `.css` files.

### Usage Examples

```js
grunt.initConfig({
  "dr-assets": {
    styles: {
      options: {
        rootPath: "assets",
        compilePaths: {
          css: "src/assets/css/dr-global",
          less: "src/assets/less/dr-global"
        },
        cleanBeforeBuild: true,
        concatFiles: false,
        includeBuildFiles: true,
        buildCoreCSS: true,
        skipIfExists: true
      },
      bootstrapComponents: ["alerts", "forms", "carousel"],
      drComponents: ["player"]
    }
  }
});

grunt.registerTask("dev", "Development build", function() {
  grunt.task.run("dr-assets:styles:development");
});

grunt.registerTask("prod", "Production build", function() {
  grunt.task.run("dr-assets:styles:production");
});
```
