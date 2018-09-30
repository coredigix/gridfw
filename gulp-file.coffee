gulp			= require 'gulp'
gutil			= require 'gulp-util'
# minify		= require 'gulp-minify'
include			= require "gulp-include"
rename			= require "gulp-rename"
coffeescript	= require 'gulp-coffeescript'
PluginError		= gulp.PluginError
cliTable		= require 'cli-table'
template		= require 'gulp-template' # compile some consts into digits

# compile final values (consts to be remplaced at compile time)
compileTemplate= -> # gulp mast be reloaded each time this file is changed!
	gulp.src 'consts-symbols.coffee'
	.pipe coffeescript(bare: true).on 'error', errorHandler
	.pipe gulp.dest '.'
	.on 'error', errorHandler
# handlers
compileCoffee = ->
	gulp.src 'assets/**/[!_]*.coffee', nodir: true
	# include related files
	.pipe include hardFail: true
	# replace final values (compile time processing)
	.pipe template require './consts-symbols'
	# convert to js
	.pipe coffeescript(bare: true).on 'error', errorHandler
	# save
	.pipe gulp.dest 'build'
	.on 'error', errorHandler

# compile test files
compileTest = ->
	gulp.src 'assets-test/**/[!_]*.coffee', nodir: true
	.pipe include hardFail: true
	.pipe coffeescript(bare: true).on 'error', errorHandler
	.pipe gulp.dest 'test'
	.on 'error', errorHandler
# watch files
watch = ->
	gulp.watch ['assets/**/*.coffee'], compileCoffee
	gulp.watch ['assets-test/**/*.coffee'], compileTest
	return

# error handler
errorHandler= (err)->
	# get error line
	expr = /:(\d+):(\d+):/.exec err.stack
	if expr
		line = parseInt expr[1]
		col = parseInt expr[2]
		code = err.code?.split("\n")[line-3 ... line + 3].join("\n")
	else
		code = line = col = '??'
	# Render
	table = new cliTable()
	table.push {Name: err.name},
		{Filename: err.filename},
		{Message: err.message},
		{Line: line},
		{Col: col}
	console.error table.toString()
	console.log '\x1b[31mStack:'
	console.error '\x1b[0m┌─────────────────────────────────────────────────────────────────────────────────────────┐'
	console.error '\x1b[34m', err.stack
	console.log '\x1b[0m└─────────────────────────────────────────────────────────────────────────────────────────┘'
	console.log '\x1b[31mCode:'
	console.error '\x1b[0m┌─────────────────────────────────────────────────────────────────────────────────────────┐'
	console.error '\x1b[34m', code
	console.log '\x1b[0m└─────────────────────────────────────────────────────────────────────────────────────────┘'
	return

# default task
gulp.task 'default', gulp.series compileTemplate, compileCoffee, compileTest, watch