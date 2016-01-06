# Dependencies
gulp        = require "gulp"

deploy       = require "gulp-gh-pages"
plugins      = require("gulp-load-plugins")(lazy: false)
react        = require("gulp-react")
reactify     = require "reactify"
browserify   = require "browserify"
source       = require('vinyl-source-stream')
run          = require "run-sequence"
critical     = require "critical"
order        = require "gulp-order"

express      = require "express"
open         = require "open"
path         = require "path"
lr           = require("tiny-lr")()
nib     = require("nib")
fs      = require "fs"
bootstrap = require "bootstrap-styl"
# fontawesome  = require "font-awesome-stylus"

pkg            = require "./package.json"

jadepath       =  ""
isHeavyWeight     = process.argv.indexOf('--light') <= -1
# Configuration

Config =
    build: "./public/"
    name: pkg.name
    port: 9000
    publish: false
    src: "./src/"
    root: "./"
    bower_path: "./bower_components/"
    node_modules_path: "./node_modules/"
    version: pkg.version

# Reset

gulp.task "reset", ->
    return gulp.src Config.build + "*", read: false
        .pipe plugins.clean
            force: true

gulp.task "coffeescript", ->
    gulp.src Config.src + "coffeescript/**/*.coffee"
    .pipe plugins.plumber()
    .pipe plugins.coffeelint()
    .pipe plugins.coffeelint.reporter()


    gulp.src Config.src + "coffeescript/main.coffee", read: false
    .pipe plugins.plumber()
    .pipe plugins.browserify
        transform: ["coffeeify","reactify"]
        shim:
            jQuery:
                path: Config.root + "bower_components/jquery/dist/jquery.js"
                exports: "$"
            transition:
                path: Config.root + "bower_components/bootstrap/js/carousel.js"
                exports: "transition"
                depends:
                    jQuery: "$"
            parsley:
                path: Config.root + "bower_components/parsleyjs/dist/parsley.js"
                exports: "parsley"
                depends:
                    jQuery: "$"

            validator:
                path: Config.root + "bower_components/bootstrap-validator/dist/validator.js"
                exports: "validator"
                depends:
                    jQuery: "$"


            modernizr:
                path: Config.root + "bower_components/modernizr/modernizr.js"
                exports: "modernizr"
                depends:
                    jQuery: "$"
            carousel:
                path: Config.root + "bower_components/bootstrap/js/carousel.js"
                exports: "carousel"
                depends:
                    jQuery: "$"
            dropdown:
                path: Config.root + "bower_components/bootstrap/js/dropdown.js"
                exports: "dropdown"
                depends:
                    jQuery: "$"
          
            affix:
                path: Config.root + "bower_components/bootstrap/js/affix.js"
                exports: "affix"
                depends:
                    jQuery: "$"
            collapse:
                path: Config.root + "bower_components/bootstrap/js/collapse.js"
                exports: "collapse"
                depends:
                    jQuery: "$"
            modal:
                path: Config.root + "bower_components/bootstrap/js/modal.js"
                exports: "modal"
                depends:
                    jQuery: "$"

            tab:
                path: Config.root + "bower_components/bootstrap/js/tab.js"
                exports: "tab"
                depends:
                    jQuery: "$"





    .pipe plugins.if Config.publish, plugins.uglify()
    .pipe plugins.rename "main.js"
    # .pipe plugins.sourcemaps.init( {loadMaps:true} )
    #  .pipe plugins.uglify()
    # .pipe plugins.sourcemaps.write( "./" )

    .pipe plugins.header "/* " + Config.name + " : " + Config.version + " : " + new Date() + " */"
    .pipe plugins.size
        showFiles: true
    .pipe gulp.dest Config.build + "scripts"
    
# add scripts
gulp.task "scripts", ->
    gulp.src Config.src + "coffeescript/map/*.js"
    .pipe(order([
            "swipe.js",
            "initMap.js",
            "locate-facility.js"
            ]))
    .pipe plugins.concat "map.js"
    .pipe plugins.uglify()
    .pipe gulp.dest Config.build + "scripts"

# Compile Stylus

# .pipe plugins.stylus({use:nib(),compress:true})
gulp.task "stylus", ->
    gulp.src Config.src + "stylus/main.styl"
    .pipe plugins.plumber()
    .pipe plugins.stylus({use:[bootstrap(),nib()],compress:true})
    .pipe plugins.autoprefixer "last 1 version", "> 1%"
    .pipe plugins.if Config.publish, plugins.minifyCss()
    .pipe plugins.rename "main.css"
    .pipe plugins.header "/* " + Config.name + " : " + Config.version + " : " + new Date() + " */"
    .pipe plugins.size
        showFiles: true
    .pipe gulp.dest Config.build + "styles"

# Inline the "above the fold" CSS

gulp.task "critical", ->

    critical.generate
        base: Config.build
        src: "index.html"
        dest: Config.build + "styles/main.css"
        width: 320
        height: 480
        minify: true
        extract: true
    , (err, output) ->
        critical.inline
            base: Config.build
            src: "index.html"
            dest: "index.html"
            minify: true

        gulp.src Config.build + "/*.css", read: false
        .pipe plugins.clean
            force: true


# .pipe plugins.data(readDir)
readDir =  ->
  fileArray = []
  files = fs.readdirSync Config.build
  for fileObj in files
    if path.extname(fileObj) == ".html"
      file = {fileName: path.basename(fileObj,'.html'), filePath: Config.build + fileObj }
      fileArray.push  file
  fileArray


fileArray = readDir()

gulp.task "sitemap", ->
  gulp.src Config.src + "jade/index.jade"
  .pipe plugins.plumber()
  # .pipe plugins.data(readDir)
  .pipe plugins.swig()
  .pipe plugins.jade
     pretty: true
     data: 
       description: pkg.description
       fileArray: fileArray
  .pipe gulp.dest Config.root
  
# Compile Jade
gulp.task "jadeone", ->
  gulp.src jadepath
  .pipe plugins.plumber()
  .pipe plugins.jade
    pretty: true
  .pipe gulp.dest Config.build

 
gulp.task "jade", ->
    gulp.src Config.src + "jade/*.jade"
    .pipe plugins.plumber()
    .pipe plugins.jade
        pretty: true
        data:
            description: pkg.description
            keywords: pkg.keywords
    .pipe gulp.dest Config.build

    gulp.src Config.src + "jade/includes/*.jade"
    .pipe plugins.plumber()
    .pipe plugins.jade
        pretty: true
        data:
            description: pkg.description
            keywords: pkg.keywords
    .pipe gulp.dest Config.build + "partials"

# Optimise images

gulp.task "images", ->
    gulp.src Config.src + "images/**/*.{jpg,png,gif}"
        .pipe plugins.plumber()
        .pipe plugins.imagemin
            cache: false
        .pipe plugins.size
            showFiles: true
        .pipe gulp.dest Config.build + "images"

    gulp.src Config.src + "images/**/*.svg"
        .pipe plugins.plumber()
        .pipe plugins.svgmin()
        .pipe plugins.size
            showFiles: true
        .pipe gulp.dest Config.build + "images"


gulp.task "icons", ->
    gulp.src Config.node_modules_path + "font-awesome-stylus/fonts/**/*"
    .pipe gulp.dest Config.build + "fonts"
# Copy additional files


gulp.task "copy-files", ->

    gulp.src Config.src + "fonts/**/*"
    .pipe gulp.dest Config.build + "fonts"

    gulp.src Config.src + "images/*.xml"
    .pipe gulp.dest Config.build + "images"

    # gulp.src Config.src + "sitemap.xml"
    # .pipe gulp.dest Config.build

# Watch for changes to files

gulp.task "watch", ->
    gulp.watch [
        Config.build + "scripts/**/*.js"
        Config.build + "styles/**/*.css"
        Config.build + "**/*.html"
        Config.build + "images/**/*.{jpg,png,gif,svg}"
    ], notifyLivereload

    gulp.watch Config.src + "coffeescript/**/*.coffee", ["coffeescript"]
    gulp.watch Config.src + "coffeescript/**/*.js", ["coffeescript"]
    gulp.watch Config.src + "stylus/**/*.styl", ["stylus"]

   
    gulp.watch Config.src + "jade/**/*.jade", (e) ->
       if(e.type=="changed" || e.type =="add" )
         if(e.path.indexOf("/includes/")>0) 
           run "jade"
         else
           jadepath = e.path
           run "jadeone"
          
         # ["jade", notifyLivereload]
    gulp.watch Config.src + "images/**/*.{jpg,png,gif,svg}", ["images"]
    #  gulp.watch Config.src + "*", ["copy-files"]
    #  gulp.watch Config.src + "images/favicons/*.xml", ["copy-files"]

# Run a test server

gulp.task "server", ->
    app = express()
    app.use require("connect-livereload")()
    app.use express.static Config.build
    app.listen Config.port
    lr.listen 35729
    setTimeout ->
        open "http://localhost:" + Config.port
    , 3000

# Update the livereload server

notifyLivereload = (event) ->
    if (isHeavyWeight) 
        fileName = "/" + path.relative Config.build, event.path
        gulp.src event.path, read: false
            .pipe require("gulp-livereload")(lr)

# Default (development) task

gulp.task "default", ->
    Config.publish = false
    list = ["icons"]
    if (isHeavyWeight) 
        list.push("coffeescript", "scripts", "stylus", "jade", "images", "copy-files")
    run list, "watch", "server"

gulp.task "deploy", ->
    Config.publish = true
    run "icons"
    run "coffeescript"
    run "scripts"
    run "stylus"
    run "jade"
    run "images"
    run "copy-files"

options = 
  branch: "gh-pages"
gulp.task "publish", ->
    gulp.src('./public/**/*').pipe(deploy(options))

