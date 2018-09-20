  /**
   * Add Logging service to an object
   * we didn't use closure to uncrease performance
   * @example
   * app.log('title', ...args)
   */
var CONSOLE_COLORS, LEVELS, _VOID, _createConsoleLogMethod, _setLogLevel,
  indexOf = [].indexOf;

LEVELS = ['debug', 'log', 'warn', 'info', 'error', 'fatalError'];

_VOID = function() {};

module.exports = function(obj, options) {
  var level;
  // set log level
  Object.defineProperty(obj, 'logLevel', {
    value: _setLogLevel,
    configurable: true // enable to change this default logger
  });
  // options
  if (options) {
    return level = LEVELS.indexOf(options.level);
  } else {
    return level = 0;
  }
};

_setLogLevel = function(level) {
  var i, len, logMethod;
  if (indexOf.call(LEVELS, level) < 0) {
    //TODO use console.log in dev mode
    //TODO use performante logger in 
    throw new Error(`Usupported level: ${level}, supported are: ${LEVELS}`);
  }
  for (i = 0, len = LEVELS.length; i < len; i++) {
    logMethod = LEVELS[i];
    _createConsoleLogMethod(level, this, logMethod);
  }
};

CONSOLE_COLORS = {
  log: '',
  warn: "\x1b[33m",
  info: "\x1b[34m",
  error: "\x1b[31m",
  fatalError: "\x1b[31m"
};

_createConsoleLogMethod = function(level, obj, method) {
  var color, mt;
  color = CONSOLE_COLORS[method];
  mt = "\x1b[7m" + color + method.toUpperCase() + " \x1b[0m" + color;
  // fatalError: add blink
  if (method === 'fatalError') {
    mt = "\x1b[5m" + mt;
  }
  // Add
  Object.defineProperty(obj, method, {
    value: LEVELS.indexOf(method) < level ? _VOID : function(value, ...args) {
      return console.log(mt, value, '>> ', args, "\x1b[0m");
    },
    configurable: true
  });
};
