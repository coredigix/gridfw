gulp			= require 'gulp'
gutil			= require 'gulp-util'
# minify		= require 'gulp-minify'
include			= require "gulp-include"
rename			= require "gulp-rename"
coffeescript	= require 'gulp-coffeescript'
PluginError		= gulp.PluginError

compileCoffee = ->
	gulp.src 'assets/**/[!_]*.coffee', nodir: true
	.pipe include hardFail: true
	.pipe coffeescript(bare: true).on 'error', gutil.log
	.pipe gulp.dest 'build'
	.on 'error', gutil.log


# default task
gulp.task 'default', gulp.series compileCoffee, ->
	gulp.watch ['assets/**/*.coffee'], ['compile-coffee']
	return