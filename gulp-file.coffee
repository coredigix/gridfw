gulp			= require 'gulp'
gutil			= require 'gulp-util'
# minify		= require 'gulp-minify'
include			= require "gulp-include"
rename			= require "gulp-rename"
coffeescript	= require 'gulp-coffeescript'
PluginError		= gulp.PluginError
cliTable		= require 'cli-table'
lnk				= require 'create-symlink'

# handlers
compileCoffee = ->
	gulp.src 'assets/**/[!_]*.coffee', nodir: true
	.pipe include hardFail: true
	.pipe coffeescript(bare: true).on 'error', errorHandler
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
gulp.task 'default', gulp.series compileCoffee, compileTest, watch

# create sym links
lnk 'assets/views', 'build/views'
.then ->
	console.log 'Symlink created: build/views -> assets/views'
.catch (err)->
	console.error 'Fail to create symlink: ', err