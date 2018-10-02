// App consts
var app;

exports.app = app = {
  DEV: 0,
  PROD: 1
};

/* this file contains app default settings */
exports.settings = {
  //###<========================== App Id =============================>####
  /** Author */
  author: 'GridFW',
  /** Admin Email */
  email: 'contact@coredigix.com',
  //###<========================== LOG =============================>####
  /**
   * log level
   * @default prod: 'info', dev: 'debug'
   */
  logLevel: 'debug',
  //###<========================== Router =============================>####
  /**
   * Route cache
   */
  routeCacheMax: 50,
  /**
   * Ignore trailing slashes
   * 		off	: ignore
   * 		0	: ignore, make redirect when someone asks for this URL
   * 		on	: 'keep it'
   */
  trailingSlash: 0,
  /**
   * when 1, ignore path case
   * when on, ignore route static part case only (do not lowercase param values)
   * when off, case sensitive
   * @type {boolean}
   */
  routeIgnoreCase: true,
  //###<========================== Request =============================>####
  /**
   * trust proxy
   */
  trustProxyFunction: function(app, mode) {
    //TODO
    return function(req, proxyLevel) {
      return true;
    };
  },
  //###<========================== Render and output =============================>####
  /**
   * Render pretty JSON, XML and HTML
   * @default  false when prod mode
   */
  pretty: function(app, mode) {
    return mode === 0; // true if dev mode
  },
  /**
   * Etag function generator
   * generate ETag for responses
   */
  etagFunction: function(app, mode) {
    return function(data) {
      return '';
    };
  },
  /**
   * render templates
   */
  engines: {
    '.pug': require('pug')
  },
  /**
   * view Cache
   * @when off: disable cache
   * @when on: enable cache for ever
   * @type {boolean}
   */
  viewCache: function(app, mode) {
    return mode !== 0; // false if dev mode
  },
  viewCacheMax: 50, // view cache max entries
  views: ['views'], // default folder
  //###<========================== Errors =============================>####
  // Error templates
  errorTemplates: function() {
    return {
      '404': path.join(__dirname, '../../build/views/errors/404'),
      '500': path.join(__dirname, '../../build/views/errors/500'),
      // dev mode
      'd404': path.join(__dirname, '../../build/views/errors/d404'),
      'd500': path.join(__dirname, '../../build/views/errors/d500')
    };
  }
};
