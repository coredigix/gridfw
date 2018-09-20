
/**
* Handle requests
* @param {HTTP_REQUEST} req - request
* @param {HTTP_RESPONSE} ctx - the app context
* @example
* app.handle(req, res)
 */
/* make server listening depending on the used protocol */
/**
* Load template file content
* @type {[type]}
 */
var Context, DEFAULT_PROTOCOL, EMPTY_OBJ, GridFW, LRUCache, LoggerFactory, ROUTE_CACHE, SERVER_LISTENING_PROTOCOLS, UNDEFINED_, VIEW_CACHE, _loadTemplateFileContent, _processUncaughtRequestErrors, fs, http, path;

http = require('http');

path = require('path');

fs = require('mz/fs');

LRUCache = require('lru-native');

Context = require('../context');

LoggerFactory = require('../lib/logger');

VIEW_CACHE = Symbol('view cache');

ROUTE_CACHE = Symbol('route cache');

// create empty attribute for performance
UNDEFINED_ = {
  value: void 0,
  configurable: true,
  writable: true
};

/**
* framework core
 */
GridFW = class GridFW extends Route {
  /**
   * @param  {number} settings [description]
   * @return {[type]}          [description]
   */
  constructor(settings) {
    var routeCache, viewCache;
    // super
    super();
    // settings
    if (settings == null) {
      settings = {};
    }
    Object.setPrototypeOf(settings, GridFW.prototype._settings);
    // view cache
    if (settings.viewCache) {
      viewCache = new LRUCache({
        maxElements: settings.viewCacheMax
      });
    }
    // routing cache
    if (settings.routeCache) {
      routeCache = new LRUCache({
        maxElements: settings.routeCacheMax
      });
    }
    // attributes
    Object.defineProperties(this, {
      /* auto reference */
      app: {
        value: this
      },
      /* app port */
      port: UNDEFINED_,
      host: UNDEFINED_,
      /* app basic path */
      path: UNDEFINED_,
      /* underline server*/
      server: UNDEFINED_,
      /* locals */
      locals: {
        value: {}
      },
      /* render function */
      render: {
        value: renderTemplates
      },
      /* settings */
      _settings: {
        value: settings
      },
      /* view cache, enable it depending  */
      [VIEW_CACHE]: {
        value: viewCache
      },
      /* route cache */
      [ROUTE_CACHE]: {
        value: routeCache
      }
    });
  }

};

// add log support
LoggerFactory(GridFW.prototype);

/**

 *

 * Events

 * 		- routeAdded

 * 		- routeRemoved

 * 		- routeHandlerOn

 * 		- routeHandlerOff

 */
/**

 * default settings

 */
GridFW.prototype._settings = {
  /*

  use cache for routes, this make it faster

  to not look for a route each time

  (route lookup is already optimized by using tree access)

  @default on in production mode

  */
  routeCache: false,
  routeCacheMax: 50, // route cache max entries
  /**

   * Ignore trailing slashes

   * 		off	: ignore

   * 		0	: ignore, make redirect when someone ask this URL

   * 		on	: 'keep it'

   */
  trailingSlash: 0,
  /**

   * when true, ignore path case

   * @type {boolean}

   */
  routeIgnoreCase: true,
  /**

   * render templates

   */
  engines: {
    '.pug': require('pug')
  },
  /* view folders */
  views: ['views'],
  /**

   * view Cache

   * @when off: disable cache

   * @when on: enable cache for ever

   * @type {boolean}

   */
  viewCache: false,
  viewCacheMax: 50, // view cache max entries
  /*

  render pretty html

  @default on in production mode, off otherwise

  */
  renderPretty: true,
  /**

   * Trust proxy

   */
  trustProxy: true,
  trustProxyFx: function() {
    return true; // compiled version
  },
  /**

   * Render JSON and XML

   * @default off on production mode

   */
  jsonPretty: true,
  /*

  Cache: generate ETag

  @param {Buffer} data - data to generate ETag

  */
  etag: function(data) {
    //TODO
    return '';
  }
};

/**
 * Render HTML template
 * @param {string} path path to template
 * @param {Object} Locals [description]
 * @return {Promise<string>} will return the rendered HTML
 */
GridFW.prototype.render = function(templatePath, locals) {
  Object.setPrototypeOf(locals, this.locals);
  return this._render(path, locals);
};

/**
* Execute render
* @private
* @param  {srting} path - path to resolve template
* @param  {Object} locals   - locals
* @return {Promise<html>}          return compiled HTML
 */
GridFW.prototype._render = function(templatePath, locals) {
  var engines, filePath, i, len, ref, renderFx, settings, template, useCache, v;
  settings = this._settings;
  useCache = settings.viewCache;
  if (typeof templatePath !== 'string') {
    // resolve file content
    throw new Error('path expected string');
  }
  // check in cache
  renderFx = useCache && this[VIEW_CACHE].get(templatePath);
  if (!renderFx) {
    
    // if add index
    filePath = templatePath.endsWith('/') ? templatePath += 'index' : templatePath;
    
    // get file string
    engines = settings.engines;
    // absolute path
    if (path.isAbsolute(filePath)) {
      template = _loadTemplateFileContent(settings.engines, filePath);
    } else {
      ref = settings.views;
      // relative to views
      for (i = 0, len = ref.length; i < len; i++) {
        v = ref[i];
        template = _loadTemplateFileContent(settings.engines, path.join(v, filePath));
        if (template.content != null) {
          break;
        }
      }
    }
    if (template.content == null) {
      throw 404; // page not found
    }
    
    // compile template
    renderFx = template.module.compile(template.content, {
      pretty: settings.renderPretty
    });
    // cache
    if (useCache) {
      this[VIEW_CACHE].set(templatePath, renderFx);
    }
  }
  // compile render fx
  return renderFx(locals);
};

_loadTemplateFileContent = async function(engines, filePath) {
  var err, ext, module, result;
  result = {
    content: null,
    module: null
  };
  for (ext in engines) {
    module = engines[ext];
    try {
      result.content = (await fs.readFile(filePath.endsWith(ext) ? filePath : filePath + ext));
      result.module = module;
      break;
    } catch (error1) {
      err = error1;
      if (err && err.code === 'ENOENT') {

      } else {
        // file not found, go to next file
        throw err;
      }
    }
  }
  return result;
};

EMPTY_OBJ = Object.freeze({}); // for performance reason, use this for empty params and query

GridFW.prototype.handle = async function(req, ctx) {
  /**
   * @throws {404} If route not found
   * n: node
   * p: params
   * m: middlewares queu, sync mode only
   * e: error handlers
   * h: handlers
   * pr:pre-process
   * ps:post-process
   * pm: param resolvers
   */
  var e, err, handler, i, idx, j, k, l, len, len1, len2, len3, len4, m, n, paramResolvers, params, queryParams, rawParams, rawPath, rawUrlQuery, ref, ref1, ref2, ref3, ref4, resp, routeCache, routeDescriptor, settings, url, useCache, v;
  try {
    // settings
    settings = this.settings;
    useCache = settings.routeCache;
    // path
    url = req.url;
    idx = url.indexOf('?');
    if (idx === -1) {
      rawPath = url;
      rawUrlQuery = null;
    } else {
      rawPath = url.substr(0, idx);
      rawUrlQuery = url.substr(idx + 1);
    }
    // get the route
    // trailing slash
    if (rawPath !== '/') {
      switch (settings.trailingSlash) {
        // redirect
        case 0:
          if (rawPath.endsWith('/')) {
            rawPath = rawPath.slice(0, -1);
            if (rawUrlQuery) {
              rawPath += '?' + rawUrlQuery;
            }
            ctx.permanentRedirect(rawPath); // ends request
            return;
          }
          break;
        // ignore
        case false:
          if (rawPath.endsWith('/')) {
            rawPath = rawPath.slice(0, -1);
          }
      }
      // when on: keep it
      // ignore case
      if (settings.routeIgnoreCase) {
        rawPath = rawPath.toLowerCase();
      }
    }
    // get from cache
    routeCache = this[ROUTE_CACHE];
    routeDescriptor = routeCache && routeCache.get(rawPath);
    // lookup for route
    if (!routeDescriptor) {
      routeDescriptor = this._find(rawPath);
      if (routeCache != null) {
        // put in cache (production mode)
        routeCache.set(rawPath, routeDescriptor);
      }
    }
    // resolve params
    rawParams = routeDescriptor.p;
    paramResolvers = routeDescriptor.pm;
    if (rawParams) {
      params = Object.create(rawParams);
      if (paramResolvers) {
        for (k in rawParams) {
          v = rawParams[k];
          if (typeof paramResolvers[k] === 'function') {
            params[k] = (await paramResolvers[k](this, v));
          }
        }
      }
    } else {
      rawParams = params = EMPTY_OBJ;
    }
    // resolve query params
    if (rawUrlQuery) {
      queryParams = this.queryParser(rawUrlQuery);
      if (paramResolvers) {
        for (k in queryParams) {
          v = queryParams[k];
          if (typeof paramResolvers[k] === 'function') {
            queryParams[k] = (await paramResolvers[k](this, v));
          }
        }
      }
    } else {
      queryParams = EMPTY_OBJ;
    }
    //TODO resolve values
    // add to current object for future use
    Object.defineProperty(this, 'query', {
      value: query
    });
    // return value
    query;
    // add to context
    Object.defineProperties(ctx, {
      app: {
        value: this
      },
      req: {
        value: req
      },
      res: {
        value: ctx
      },
      url: {
        value: req.url
      },
      // url
      path: {
        value: rawPath
      },
      rawQuery: {
        value: rawUrlQuery
      },
      query: {
        value: queryParams
      },
      // current route
      route: {
        value: routeDescriptor.n
      },
      rawParams: {
        value: rawParams
      },
      params: {
        value: params
      },
      // posible error
      error: UNDEFINED_
    });
    // add to request
    Object.defineProperties(req, {
      res: {
        value: ctx
      },
      ctx: {
        value: ctx
      },
      req: {
        value: req
      }
    });
    // execute middlewares
    if (routeDescriptor.m.length) {
      ref = routeDescriptor.m;
      for (i = 0, len = ref.length; i < len; i++) {
        handler = ref[i];
        await handler(ctx);
      }
    }
    // execute pre-processes
    if (routeDescriptor.pr.length) {
      ref1 = routeDescriptor.pr;
      for (j = 0, len1 = ref1.length; j < len1; j++) {
        handler = ref1[j];
        await handler(ctx);
      }
    }
    ref2 = routeDescriptor.h;
    // execute handlers
    for (l = 0, len2 = ref2.length; l < len2; l++) {
      handler = ref2[l];
      resp = (await handler(ctx));
      // if a value is returned
      if (resp !== void 0) {
        // if view resolver
        if (typeof resp === 'string') {
          ctx.render(resp);
        } else {
          ctx.send(resp);
        }
      }
    }
    // execute post handlers
    if (routeDescriptor.ps.length) {
      ref3 = routeDescriptor.ps;
      for (m = 0, len3 = ref3.length; m < len3; m++) {
        handler = ref3[m];
        await handler(ctx);
      }
    }
  } catch (error1) {
    e = error1;
    try {
      ctx.error = e;
      // user defined error handlers
      if (routeDescriptor && routeDescriptor.e.length) {
        ref4 = routeDescriptor.e;
        for (n = 0, len4 = ref4.length; n < len4; n++) {
          handler = ref4[n];
          await handler(ctx);
        }
      } else {
        // else
        _processUncaughtRequestErrors(this, ctx, e);
      }
    } catch (error1) {
      err = error1;
      _processUncaughtRequestErrors(this, ctx, err);
    }
  }
};


// default used protocol when non specified, in [http, https, http2]
DEFAULT_PROTOCOL = 'http';

/**
 * Listen([port], options)
 * @optional @param {number} options.port - listening port @default to arbitrary generated one
 * @optional @param {string} options.protocol - if use 'http' or 'https' or 'http2' @default to http
 * @example
 * listen() # listen on arbitrary port
 * listen(3000) # listen on port 3000
 * listen
 * 		port: 3000
 * 		protocol: 'http' or 'https' or 'http2'
 */
GridFW.prototype.listen = function(options) {
  return new Promise(function(res, rej) {
    var servFacto, server;
    // options
    if (!options) {
      options = {};
    } else if (typeof options === 'number') {
      options = {
        port: options
      };
    } else if (typeof options !== 'object') {
      throw new Error('Illegal argument');
    }
    // get server factory
    servFacto = options.protocol;
    if (servFacto) {
      if (typeof servFacto !== 'string') {
        throw new Error("Protocol expected string");
      }
      servFacto = SERVER_LISTENING_PROTOCOLS[servFacto.toLowerCase()];
      if (!servFacto) {
        throw new Error(`Unsupported protocol: ${options.protocol}`);
      }
    } else {
      servFacto = SERVER_LISTENING_PROTOCOLS[DEFAULT_PROTOCOL];
    }
    // create server
    return server = servFacto(options, this);
  });
};

SERVER_LISTENING_PROTOCOLS = {
  http: function(options, app) {
    var server;
    return server = app.server = http.createServer({
      IncomingMessage: Context.Request,
      ServerResponse: Context
    }, app.handle.bind(app));
  }
};

// ###
// App Errors
// We didnt extends "Error" for performance
// ###

// class GridError
// 	constructor: (code= -1, message)->
// 		if arguments.length is 1
// 			message = _mapCodes[code]
// 		super message
// 		Object.defineProperties this,
// 			code: value: code

// 	# const
// 	@NOT_FOUND: 404

// ### get message from code ###
// _mapCodes=
// 	'404': 'Not found'

// ### not found eror ###
// class NotFoundError extends GridError
// 	constructor: (path, message)->
// 		super GridError.NOT_FOUND, message
// 		Object.defineProperties this,
// 			path: value: path
// ------------------
// 404: not found
_processUncaughtRequestErrors = function(app, ctx, error) {
  console.error('Error>> Error handling isn\'t implemented!');
  if (typeof error === 'number') {
    switch (error) {
      // page not found
      case 404:
        return console.error('404>> page not found!');
      default:
        return console.error('Error>> ', error);
    }
  } else {
    return console.error('Error>> ', error);
  }
};
