var PluginError, cliTable, coffeescript, compileCoffee, gulp, gutil, include, rename, watch;

gulp = require('gulp');

gutil = require('gulp-util');

// minify   = require 'gulp-minify'
include = require("gulp-include");

rename = require("gulp-rename");

coffeescript = require('gulp-coffeescript');

PluginError = gulp.PluginError;

cliTable = require('cli-table');

compileCoffee = function() {
  return gulp.src('assets/**/[!_]*.coffee', {
    nodir: true
  }).pipe(include({
    hardFail: true
  })).pipe(coffeescript({
    bare: true
  }).on('error', function(err) {
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
  })).pipe(gulp.dest('build')).on('error', gutil.log);
};

watch = function() {
  gulp.watch(['assets/**/*.coffee'], compileCoffee);
};

// default task
gulp.task('default', gulp.series(compileCoffee, watch));