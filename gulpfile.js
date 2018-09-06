var PluginError, coffeescript, compileCoffee, gulp, gutil, include, rename;

gulp = require('gulp');

gutil = require('gulp-util');

// minify		= require 'gulp-minify'
include = require("gulp-include");

rename = require("gulp-rename");

coffeescript = require('gulp-coffeescript');

PluginError = gulp.PluginError;

compileCoffee = function() {
  return gulp.src('assets/**/[!_]*.coffee', {
    nodir: true
  }).pipe(include({
    hardFail: true
  })).pipe(gulp.dest('builde')).pipe(coffeescript({
    bare: true
  }).on('error', gutil.log)).pipe(gulp.dest('build')).on('error', gutil.log);
};

gulp.task('coffee', compileCoffee);

// default task
gulp.task('default', gulp.series(compileCoffee, function() {
  gulp.watch(['assets/**/*.coffee'], compileCoffee);
}));