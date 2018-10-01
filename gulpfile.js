var PluginError, cliTable, coffeescript, compileCoffee, compileConfig, compileTest, errorHandler, execConfig, gulp, gutil, include, rename, template, watch;

gulp = require('gulp');

gutil = require('gulp-util');

// minify   = require 'gulp-minify'
include = require("gulp-include");

rename = require("gulp-rename");

coffeescript = require('gulp-coffeescript');

PluginError = gulp.PluginError;

cliTable = require('cli-table');

template = require('gulp-template'); // compile some consts into digits


// compile final values (consts to be remplaced at compile time)
compileConfig = function() { // gulp mast be reloaded each time this file is changed!
  return gulp.src('config/*.coffee').pipe(coffeescript({
    bare: true
  }).on('error', errorHandler)).pipe(gulp.dest('config/build/')).on('error', errorHandler);
};

execConfig = function() {
  require('./config/build/build');
  return gulp.src('config/build/config.js').pipe(gulp.dest('build/core/'));
};

// handlers
compileCoffee = function() {
  return gulp.src('assets/**/[!_]*.coffee', {
    nodir: true
  // include related files
  }).pipe(include({
    hardFail: true
  // replace final values (compile time processing)
  // convert to js
  })).pipe(template(require('./config/build/settings'))).pipe(coffeescript({
    bare: true
  // save
  }).on('error', errorHandler)).pipe(gulp.dest('build')).on('error', errorHandler);
};

// compile test files
compileTest = function() {
  return gulp.src('assets-test/**/[!_]*.coffee', {
    nodir: true
  }).pipe(include({
    hardFail: true
  })).pipe(coffeescript({
    bare: true
  }).on('error', errorHandler)).pipe(gulp.dest('test')).on('error', errorHandler);
};

// watch files
watch = function() {
  gulp.watch(['assets/**/*.coffee'], compileCoffee);
  gulp.watch(['assets-test/**/*.coffee'], compileTest);
};

// error handler
errorHandler = function(err) {
  var code, col, expr, line, ref, table;
  // get error line
  expr = /:(\d+):(\d+):/.exec(err.stack);
  if (expr) {
    line = parseInt(expr[1]);
    col = parseInt(expr[2]);
    code = (ref = err.code) != null ? ref.split("\n").slice(line - 3, line + 3).join("\n") : void 0;
  } else {
    code = line = col = '??';
  }
  // Render
  table = new cliTable();
  table.push({
    Name: err.name
  }, {
    Filename: err.filename
  }, {
    Message: err.message
  }, {
    Line: line
  }, {
    Col: col
  });
  console.error(table.toString());
  console.log('\x1b[31mStack:');
  console.error('\x1b[0m┌─────────────────────────────────────────────────────────────────────────────────────────┐');
  console.error('\x1b[34m', err.stack);
  console.log('\x1b[0m└─────────────────────────────────────────────────────────────────────────────────────────┘');
  console.log('\x1b[31mCode:');
  console.error('\x1b[0m┌─────────────────────────────────────────────────────────────────────────────────────────┐');
  console.error('\x1b[34m', code);
  console.log('\x1b[0m└─────────────────────────────────────────────────────────────────────────────────────────┘');
};

// default task
gulp.task('default', gulp.series(compileConfig, execConfig, compileCoffee, compileTest, watch));