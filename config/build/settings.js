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
   * Render JSON as pretty
   * @default  false when prod mode
   */
  outPutPretty: function(app, mode) {
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
  }
};
