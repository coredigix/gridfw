  /**
   * Route
   * @todo add route.path to get full descriptor path of this route
   *
   * @author COREDIGIX
   * @copyright 2018
   * @format
   * node
   * 		[FIXED_SUB_ROUTE]
   * 			name: {RouteNode}
   * 			name2: {RouteNode}
   * 		#parametred routes (this architecture to boost performance)
   * 		[SR_PARAM_NAMES] : [paramName1, ...]
   * 		[SR_PARAM_REGEXES] : [paramRegex1, ...]
   * 		[SR_PARAM_NODES] : [paramNode1, ...]
   * 
   */
  /* sub routes */
  /* Route Prototype */
  /* route to be rejected */
  /**
  * Param manager
  * (Affect both Path params and query params)
  * @author COREDIGIX
   */
  /* others */
  /**
   * build handler
   * @param {Object} route current route
   * @param {string | list<string>} [varname] [description]
   */
  /**
   * check http method
   * @return {string} useful key to access method data
   */
  /**
   * Detach node from parent
   * @private
   */
  /**
  * remove route handlers
   */
  /**
   * Append handler to a route
   * @private
   * @param {Object} route - route Object
   * @param {string | list<strin>} method - http method or list of http methods
   * @param {string} type - typeof handler in [h, m, p, e], see bellow
   * @param {function} handler - the handler to add
   */
var Context, FIXED_SUB_ROUTE, HTTP_METHODS, PARAM_HANDLERS, REJ_ROUTE_REGEX, ROUTE_ALL, ROUTE_ERR_HANDLER, ROUTE_HANDLER, ROUTE_MIDDLEWARE, ROUTE_PARAM, ROUTE_POST_PROCESS, ROUTE_PRE_PROCESS, ROUTE_PROTO, Route, SR_PARAM_NAMES, SR_PARAM_NODES, SR_PARAM_REGEXES, VOID_REGEX, _OnHandlerBuilder, _attachNode, _buildHandler, _checkHttpMethod, _detachNode, _rmRouteHandlers, _routeAppendHandler, fastDecode,
  indexOf = [].indexOf;

fastDecode = require('fast-decode-uri-component');

Context = require('../context');

Route = class Route {
  /**
   * [constructor description]
   * @param {Route} parent - parent Route object
   * @type {[type]}
   */
  constructor(parent, lazyName, lazyParam) {
    var undefined_;
    // init attributes with undefined value
    undefined_ = {
      value: void 0,
      configurable: true,
      writable: true
    };
    // sub routes
    Object.defineProperties(this, {
      /* parent route node */
      parent: {
        value: parent,
        configurable: true,
        writable: true
      },
      /* app */
      app: {
        value: parent && parent.app,
        configurable: true,
        writable: true
      },
      /* @private static name sub routes */
      [FIXED_SUB_ROUTE]: {
        value: {}
      },
      /* @private parametred sub routes */
      [SR_PARAM_NAMES]: {
        value: []
      },
      [SR_PARAM_NODES]: {
        value: []
      },
      [SR_PARAM_REGEXES]: {
        value: []
      },
      /* name of the route, undefined when it a parametred route */
      name: undefined_,
      /* param name (case of parametred route )*/
      paramName: undefined_,
      /* parents: in case node is attached to multiple parents */
      parents: {
        value: parent ? [parent] : []
      },
      /* lazy append */
      lazyAttach: undefined_,
      /*
      param manger for this route and it's subroutes
      @private
      */
      [ROUTE_PARAM]: undefined_
    });
    // Route lazy add
    if (lazyName || lazyParam) {
      if (!parent) {
        throw new Error('Lazy mode needs parent node');
      }
      // check
      if (lazyName) {
        if (typeof lazyName !== 'string') {
          throw new Error('Route name expected string');
        }
        if (lazyParam) {
          throw new Error('Could not set route name and param at the same time');
        }
      } else {
        if (typeof lazyParam !== 'string') {
          throw new Error('Route param name expected string');
        }
      }
      // add as lazy
      this.lazyAttach = [parent, lazyName, lazyParam];
    }
    return;
  }

  /**
   * Router events
   * @param {string | list<string>} method - http methods
   * @param {function | string} handler handler or sub-route
   * @optional @param {function} extra when subroute set, contains handler
   * @example Simple use
   *** Add handler (controller)
   * route.on('GET', handler)
   * route.on(['GET', 'HEAD'], handler)
   *** Add middleware
   * route.on('GET')
   * 		.use(middleware)
   *** promise like form
   * route.on('GET')
   * 		.then(handler)
   * 		.then(handler2)
   * 		.catch(errHandler)
   * 		.then(handler3, errHandler3)
   * 		.finally(handler)
   * 		.then(handler4)
   *** Add global handlers
   * route.on('GET')
   * 		.filter(preHandler)
   * 		.catch(errHandler)	# global error handler
   * 		.finally(handler)	# post process handler
   * @example Sub routes
   * route.on('GET', '/sub-route', handler)
   * route.on('GET', '/sub-route')
   * 		.then(handler)
   */
  on(method, handler, extra) {
    var j, len, v;
    switch (arguments.length) {
      // route.on('GET')
      case 1:
        return _buildHandler(this, method);
      // route.on('GET', '/subroute')
      // route.on('GET', ['/subroute'])
      // route.on('GET', handler)
      case 2:
        // handler
        if (typeof handler === 'function') {
          _routeAppendHandler(this, method, ROUTE_HANDLER, handler);
          return this;
        } else {
          // return _buildHandler currentRoute, method, subRoutes
          // subRoute
          return _buildHandler(this, method, handler);
        }
        break;
      // route.on('GET', '/route', handler)
      // route.on('GET', ['/route'], handler)
      case 3:
        if (Array.isArray(handler)) {
          for (j = 0, len = handler.length; j < len; j++) {
            v = handler[j];
            this.route(v).on(method, extra);
          }
        } else {
          this.route(handler).on(method, extra);
        }
        return this;
      default:
        throw new Error('Illegal arguments');
    }
  }

  /**
   * Remove this handler from route
   * @param  {string} type    - http method
   * @param  {string|list<string>} route   route or list of routes
   * @param  {function} handler - handler to remove
   *
   * @example
   * route.off() # remove all handlers
   * router.off('GET') # remove all GET handlers
   * router.off(['GET', 'POST']) # remove all GET handlers
   * router.off(handler) # remove this handler from all methods
   * router.off(Route.MIDDLEWARE) remove all middleware from this route
   * 
   * router.off('GET', handler) # remove this handler from 'GET' method
   * router.off('GET', Route.MIDDLEWARE) remove all middlewares from get method
   * router.off(Route.MIDDLEWARE, hander) remove this middleware from this route
   * 
   * router.off('GET', Route.MIDDLEWARE, handler) remove this middle ware
   */
  off(method, type, handler) {
    switch (arguments.length) {
      // remove all handlers
      case 0:
        // off()
        this.off(HTTP_METHODS, ROUTE_ALL);
        break;
      case 1:
        // off(Route.MIDDLEWARE)
        if (typeof method === 'number') {
          this.off(HTTP_METHODS, ROUTE_ALL, method);
        // off(handler)
        } else if (typeof method === 'function') {
          this.off(HTTP_METHODS, ROUTE_ALL, method);
        // off('GET')
        // off(['GET'])
        } else if (typeof method === 'string' || Array.isArray(method)) {
          this.off(method, ROUTE_ALL);
        } else {
          throw new Error(`Illegal Argument ${method}`);
        }
        break;
      case 2:
        if (typeof type === 'function') {
          // off(Route.MIDDLEWARE, hander)
          if (typeof method === 'number') {
            this.off(HTTP_METHODS, method, type);
          } else {
            // off('GET', handler)
            this.off(method, ROUTE_ALL, type);
          }
        // off('GET', Route.MIDDLEWARE)
        } else if (typeof type === 'number') {
          if (typeof type !== 'number') {
            throw new Error(`Illegal type: ${type}`);
          }
          _rmRouteHandlers(this, method, type);
        } else {
          throw new Error(`Illegal arguments: ${arguments}`);
        }
        break;
      case 3:
        if (typeof type !== 'number') {
          throw new Error(`Illegal type: ${type}`);
        }
        if (typeof handler !== 'function') {
          throw new Error(`Illegal handler: ${handler}`);
        }
        // off('GET', Route.MIDDLEWARE, handler)
        _rmRouteHandlers(this, method, type, handler);
    }
    return this;
  }

  /**
   * add listener to all routes
   * @example
   * route.all()
   * 		.then(handler)
   * route.all(handler)
   * route.all()
   * 		.then(handler)
   * route.all('/example', handler)
   * route.all(['/example'], handler)
   * route.all('/example')
   * 		.then(handler)
   */
  all(subRoute, handler) {
    switch (arguments.length) {
      // all()
      case 0:
        return this.on(HTTP_METHODS);
      // all('/subRoute')
      // all(handler)
      case 1:
        return this.on(HTTP_METHODS, subRoute);
      // all('/subroute', handler)
      case 2:
        return this.on(HTTP_METHODS, subRoute, handler);
      default:
        throw new Error('Illegal arguments count');
    }
  }

  /**
   * Find sub route / lazy create sub route
   * note particular nodes:
   * 		+ empty text as node name
   * 			Could not have sub nodes
   * 			exists when trailing slashes is enabled
   * 			represent the trailing slash node
   * 		+ "*" node
   * 			has no sub nodes
   * 			matches all sub URL
   * 			has the lowest priority
   * @param {string} route - sub route path
   * @example
   * route.route('/subRoute')
   */
  route(route) {
    var cRoute, currentRouteNode, idx, j, len, routeIgnoreCase, routeParams, routeTokens, settings, token;
    if (typeof route !== 'string') {
      throw new Error(`Route expected string, found: ${route}`);
    }
    if (REJ_ROUTE_REGEX.test(route)) {
      throw new Error(`Illegal route: ${route}`);
    }
    settings = this.app._settings;
    routeIgnoreCase = settings.routeIgnoreCase;
    // remove end spaces and starting slash
    route = route.trimRight();
    if (route.startsWith('/')) {
      route = route.substr(1);
    }
    // if ends with "/" is ignored, removeit
    if (!settings.trailingSlash) {
      if (route.endsWith('/')) {
        route = route.slice(0, -1);
      }
    }
    // if empty, keep current node
    currentRouteNode = this;
    // check for uniqueness of path params
    routeParams = new Set();
    if (route) {
      // split into tokens
      routeTokens = route.split('/');
// find route
      for (j = 0, len = routeTokens.length; j < len; j++) {
        token = routeTokens[j];
        // <!> param names are case sensitive!
        // param
        if (token.startsWith(':')) {
          token = token.substr(1);
          if (token === '__proto__') {
            // check it's not named __proto__
            throw new Error('__proto__ Could not be used as param name');
          }
          if (routeParams.has(token)) {
            // check for uniqueness
            throw new Error(`Duplicated path param <${token}> at: ${route}`);
          }
          routeParams.add(token);
          // relations are stored as array (for performance)
          // [0]: contains param name
          // [1]: contains reference to route object
          idx = currentRouteNode[SR_PARAM_NAMES].indexOf(token);
          if (idx === -1) {
            currentRouteNode = new Route(currentRouteNode, null, token);
          } else {
            currentRouteNode = currentRouteNode[SR_PARAM_NODES][idx];
          }
        } else {
          // replace "\:" with ":"
          // fixed name
          if (token.startsWith('\\:')) {
            token = token.substr(1);
          }
          // when route isn't case sensitive
          if (routeIgnoreCase) {
            token = token.toLowerCase();
          }
          // decode token
          token = fastDecode(token);
          // find route
          cRoute = currentRouteNode[FIXED_SUB_ROUTE][token];
          // create route if not exist
          if (cRoute) {
            currentRouteNode = cRoute;
          } else {
            currentRouteNode = new Route(currentRouteNode, token);
          }
        }
      }
    }
    // return route node
    return currentRouteNode;
  }

  /**
   * Attach route
   * case of lazy add, or attach this node to other parent node
   * @optional @param {Route node} parent - node to attach to
   * @optional @param {string} name - node name
   * @optional @param {string} paramName - node param name (in case of parametred route)
   * @example
   * attach(parent)  # if node is lazy, the attachement will be when node change state to active
   * attach()	# if node is lazy, change it state to active, and index it inside all parents
   * this will propagate to lazy parents to (will change to active too)
   */
  attach(parent, nodeName, nodeParamName) {
    var currentNode, currentNodes, j, l, len, len1, lz, n, nextStepNodes, ref1;
    // attach lazy nodes, use this algo to avoid recursive calls
    currentNodes = [this];
    nextStepNodes = [];
    while (true) {
      nextStepNodes.length = 0;
      for (j = 0, len = currentNodes.length; j < len; j++) {
        currentNode = currentNodes[j];
        lz = currentNode.lazyAttach;
        _attachNode(currentNode, lz[0], lz[1], lz[2]);
        currentNode.lazyAttach = null;
        ref1 = currentNode.parents;
        // add parents if lazy
        for (l = 0, len1 = ref1.length; l < len1; l++) {
          n = ref1[l];
          if (n.lazyAttach) {
            nextStepNodes.push(n);
          }
        }
      }
      if (!nextStepNodes.length) {
        break;
      }
    }
    // attach to other parent
    if (parent) {
      if (!(parent instanceof Route)) {
        // check
        throw new Error('Expected Route object as argument');
      }
      if (nodeName) {
        if (typeof nodeName !== 'string') {
          throw new Error('Route name expected string');
        }
        if (nodeParamName) {
          throw new Error('Could not set route name and param at the same time');
        }
      } else {
        if (typeof nodeParamName !== 'string') {
          throw new Error('Route param name expected string');
        }
      }
      // add
      this.parent = null;
      this.parents.push(parent);
      // attach
      _attachNode(this, parent, nodeName, nodeParamName);
    }
    return this;
  }

  /**
   * detach node from parent
   * when no parent is specified, detach from all parents
   * @optional @param  {Route} parent - node to detach from
   * @example
   * detach(parentNode)	# detach from this parent node
   * detach()				# detach from all parent nodes
   */
  detach(parent) {
    var idx, j, len, parents;
    // remove from list
    parents = this.parents;
    switch (arguments.length) {
      // detach from all parents
      case 0:
        for (j = 0, len = parents.length; j < len; j++) {
          parent = parents[j];
          _detachNode(this, parent);
        }
        this.parents.length = 0;
        this.parent = void 0;
        break;
      // detach from this parent
      case 1:
        idx = parents.indexOf(parent);
        if (idx >= 0) {
          parents.splice(idx, 1);
          if (parents.length === 1) {
            this.parent = parents[0];
          }
          _detachNode(this, parent);
        }
        break;
      default:
        // Illegal
        throw new Error('Illegal arguments');
    }
    return this;
  }

  /**
   * Use a handler
   */
  use(middleware) {
    return this.all().use(middleware).end;
  }

};

HTTP_METHODS = http.METHODS;

/* Route handlers */
ROUTE_PROTO.HANDLER = ROUTE_HANDLER = 0;

ROUTE_PROTO.MIDDLEWARE = ROUTE_MIDDLEWARE = 1;

ROUTE_PROTO.PRE_PROCESS = ROUTE_PRE_PROCESS = 2;

ROUTE_PROTO.POST_PROCESS = ROUTE_POST_PROCESS = 3;

ROUTE_PROTO.ERR_HANDLER = ROUTE_ERR_HANDLER = 4;

ROUTE_PROTO.ALL = ROUTE_ALL = -1;

FIXED_SUB_ROUTE = Symbol('static routes');

PARAM_HANDLERS = Symbol('param handlers');

SR_PARAM_NAMES = Symbol('param names');

SR_PARAM_REGEXES = Symbol('param regexes');

SR_PARAM_NODES = Symbol('param nodes');

ROUTE_PROTO = Route.prototype;

REJ_ROUTE_REGEX = /\/\/|\?/;

/**
 * get app, called once for performance
 */
Object.defineProperty(Route, 'app', {
  get: function() {
    var app, j, len, parent, ref1;
    ref1 = this.parents;
    for (j = 0, len = ref1.length; j < len; j++) {
      parent = ref1[j];
      app = parent.app;
      if (app) {
        break;
      }
    }
    // save app (to not call this getter again)
    if (app) {
      Object.defineProperty(this, 'app', {
        value: app
      });
    }
    // return app
    return app;
  }
});

_buildHandler = function(currentRoute, method, subroutes) {
  // affected routes
  if (subroutes) {
    if (typeof subroutes === 'string') {
      subroutes = currentRoute.route(subroutes);
    } else {
      subroutes = subroutes.map(function(route) {
        return currentRoute.route(route);
      });
    }
  } else {
    subroutes = currentRoute;
  }
  // return builder
  return new _OnHandlerBuilder(currentRoute, ({promiseQueu, middlewares, preHandlers, postHandlers, errHandlers}) => {
    var handler, j, l, len, len1, len2, len3, len4, len5, m, o, r, s, usePromise, v;
    // add simple handler
    if (promiseQueu.length === 1) {
      _routeAppendHandler(subroutes, method, ROUTE_HANDLER, promiseQueu[0]);
    // multiple handlers
    } else if (promiseQueu.length > 1) {
      // check if add handlers separated or use promise generator
      usePromise = false;
      for (j = 0, len = promiseQueu.length; j < len; j++) {
        v = promiseQueu[j];
        if (v[1]) {
          usePromise = true;
          break;
        }
      }
      // if use promise
      if (usePromise) {
        _routeAppendHandler(subroutes, method, ROUTE_HANDLER, function(ctx) {
          return promiseQueu.reduce((function(p, fx) {
            return p.then(fx[0], fx[1]);
          }), Promise.resolve(ctx));
        });
      } else {
        for (l = 0, len1 = promiseQueu.length; l < len1; l++) {
          v = promiseQueu[l];
          _routeAppendHandler(subroutes, method, ROUTE_HANDLER, v[0]);
        }
      }
    }
    // add middlewares
    if (middlewares.length) {
      for (m = 0, len2 = middlewares.length; m < len2; m++) {
        handler = middlewares[m];
        _routeAppendHandler(subroutes, method, ROUTE_MIDDLEWARE, handler);
      }
    }
    // add preHandlers
    if (preHandlers.length) {
      for (o = 0, len3 = preHandlers.length; o < len3; o++) {
        handler = preHandlers[o];
        _routeAppendHandler(subroutes, method, ROUTE_PRE_PROCESS, handler);
      }
    }
    // add postHandlers
    if (postHandlers.length) {
      for (r = 0, len4 = postHandlers.length; r < len4; r++) {
        handler = postHandlers[r];
        _routeAppendHandler(subroutes, method, ROUTE_POST_PROCESS, handler);
      }
    }
    // add error handlers
    if (errHandlers.length) {
      for (s = 0, len5 = errHandlers.length; s < len5; s++) {
        handler = errHandlers[s];
        _routeAppendHandler(subroutes, method, ROUTE_ERR_HANDLER, handler);
      }
    }
  });
};

_routeAppendHandler = function(route, method, type, handler) {
  var arr, j, l, len, len1, methodObj, v;
  if (Array.isArray(route)) {
    for (j = 0, len = route.length; j < len; j++) {
      v = route[j];
      _routeAppendHandler(v, method, type, handler);
    }
  } else if (Array.isArray(method)) {
    for (l = 0, len1 = method.length; l < len1; l++) {
      v = method[l];
      _routeAppendHandler(route, v, type, handler);
    }
  } else {
    method = _checkHttpMethod(method);
    // create method object if not already
    methodObj = route[method] != null ? route[method] : route[method] = [[], [], [], [], []];
    // add handler
    arr = methodObj[type];
    if (arr == null) {
      throw new Error(`Illegal type: ${type}`);
    }
    arr.push(handler);
    if (route.lazyAttach) {
      // attach this route if not already attached
      route.attach();
    }
  }
};

_rmRouteHandlers = function(currentRoute, method, type, handler) {
  var arr, j, l, len, len1, methodObj, remover, v;
  if (Array.isArray(method)) {
    for (j = 0, len = method.length; j < len; j++) {
      v = method[j];
      _rmRouteHandlers(currentRoute, v, type, handler);
    }
  } else {
    // method key
    method = _checkHttpMethod(method);
    methodObj = currentRoute[method];
    if (methodObj) {
      // remover
      remover = (arr) => {
        var idx, results;
        // remove handler only
        if (handler) {
          results = [];
          while (true) {
            idx = arr.indexOf(handler);
            if (idx === -1) {
              break;
            }
            results.push(arr.splice(idx, 1));
          }
          return results;
        } else {
          // remove all handlers
          return arr.length = 0;
        }
      };
      // remove
      if (type === ROUTE_ALL) {
        for (l = 0, len1 = methodObj.length; l < len1; l++) {
          arr = methodObj[l];
          remover(arr);
        }
      } else {
        arr = methodObj[type];
        if (arr == null) {
          throw new Error(`Illegal type: ${type}`);
        }
        remover(arr);
      }
    }
  }
};

/**
* shorthand routes
* @example
* route.get()
* 		.then(handler)
* 		
* route.get(handler)
* route.get('/subRoute')
* 		.then(handler)
* 
* route.get('/route', handler)
* route.get(['/route', '/route2'], handler)
 */
HTTP_METHODS.forEach(function(method, i) {
  // mehtod
  return Object.defineProperty(ROUTE_PROTO, method, {
    value: function(route, handler) {
      switch (arguments.length) {
        case 0:
          return this.on(method);
        case 1:
          return this.on(method, route);
        case 2:
          return this.on(method, route, handler);
        default:
          throw new Error('Illegal arguments count');
      }
    }
  });
});


// Add param hand
/**
 * Attach node to an other
 * @private
 * @example
 * _attachNode node, [parentNode, 'nodeName', 'nodeParamName']
 */
_attachNode = function(node, parentNode, nodeName, nodeParamName) {
  var idx, ref;
  // as static name
  if (nodeName) {
    // convert to lower case if ignore case is active
    if (node.app._settings.routeIgnoreCase) {
      nodeName = nodeName.loLowerCase();
    }
    nodeName = fastDecode(nodeName);
    // attach
    ref = parentNode[FIXED_SUB_ROUTE];
    if (ref.hasOwnProperty(nodeName)) {
      if (ref[nodeName] !== node) {
        throw new Error('Route already set');
      }
    } else {
      ref[nodeName] = route;
    }
  }
  // as param
  if (nodeParamName) {
    idx = parentNode[SR_PARAM_NAMES].indexOf(nodeParamName);
    if (idx === -1) {
      parentNode[SR_PARAM_NAMES].push(nodeName);
      parentNode[SR_PARAM_NODES].push(node);
      return parentNode[SR_PARAM_REGEXES].push(parentNode._paramToRegex(nodeParamName));
    } else {
      if (parentNode[SR_PARAM_NODES][idx] !== node) {
        throw new Error('Route already set');
      }
    }
  }
};

_detachNode = function(node, parentNode) {
  var idx, k, ref, refNames, refNodes, refRegexes, results, v;
  // remove static
  ref = parentNode[FIXED_SUB_ROUTE];
  for (k in ref) {
    v = ref[k];
    if (v === node) {
      delete ref[k];
    }
  }
  // remove parametred
  refNodes = parentNode[SR_PARAM_NODES];
  refNames = parentNode[SR_PARAM_NAMES];
  refRegexes = parentNode[SR_PARAM_REGEXES];
  results = [];
  while (true) {
    idx = refNodes.indexOf(node);
    if (idx === -1) {
      break;
    }
    refNodes.splice(idx, 1);
    refNames.splice(idx, 1);
    results.push(refRegexes.splice(idx, 1));
  }
  return results;
};

_checkHttpMethod = function(method) {
  if (typeof method !== 'string') {
    throw new Error('method expected string');
  }
  method = method.toUpperCase();
  if (indexOf.call(HTTP_METHODS, method) < 0) {
    throw new Error(`Illegal http method: ${method}`);
  }
  // return useful key
  return '_' + method;
};

// include other modules
/**
* find route by URL
* @param {string} path - find sub route based on that path
* @optional @param {string} method - http method @default GET
* @example
* /example/path		correct
* //example////path	correct (as /example/path, multiple slashes are ignored)
* /example/ (depends on app._settings.tailingSlash)
 */
Route.prototype.find = function(path, method) {
  var settings;
  if (typeof path !== 'string') {
    throw new Error('path expected string');
  }
  if (REJ_ROUTE_REGEX.test(route)) {
    throw new Error(`Illegal route: ${route}`);
  }
  // force to start by /
  if (!path.startsWith('/')) {
    path = '/' + path;
  }
  // trailing slash
  settings = this.app.settings;
  if (!settings.trailingSlash) {
    if (path.endsWith('/')) {
      path = path.slice(0, -1);
    }
  }
  // ignore case
  if (settings.routeIgnoreCase) {
    path = path.toLowerCase();
  }
  // use internal find
  return this._find(path, method || 'GET');
};

/**
* find route
* @private
* @param  {string} path - correct path to map to a route
* @param {string} method - method used lowercased and prefexed with "_", example: _get
* @return {RouteDescriptor}      descriptor to target route
* @throws {"notFound"} If route not found
 */
Route.prototype._find = function(path, method) {
  /*
  [] # ROUTE_MIDDLEWARE
  [] # ROUTE_HANDLER
  [] # ROUTE_PRE_PROCESS
  [] # ROUTE_POST_PROCESS
  [] # ROUTE_ERR_HANDLER
  */
  /* middlewares */
  /* error handlers */
  var currentNode, errorHandlerQueu, fx, i, j, k, l, len, len1, len2, m, methodeDescriptor, middlewareQueu, n, node, paramResolversQueu, params, pathLastIndex, q, ref, token, v;
  // empty middlewars queu tobe used again (for performance issue)
  middlewareQueu = [];
  errorHandlerQueu = [];
  paramResolversQueu = {};
  // method
  method = _checkHttpMethod(method);
  // split into tokens
  path = path.split('/');
  pathLastIndex = path.length;
  if (pathLastIndex > 2) { // ignore case of 2 because "/", see comment: "last node (if enabled)"
    --pathLastIndex;
  }
  // look for route node
  currentNode = this;
  params = {};
  if (path !== '/') { // not route
    for (i = j = 0, len = path.length; j < len; i = ++j) {
      token = path[i];
      if (token) {
        // check for static value
        node = currentNode[FIXED_SUB_ROUTE][token];
        if (node) {
          currentNode = node;
        } else {
          // check for parametred node
          ref = currentNode[SR_PARAM_REGEXES];
          k = ref.length;
          if (k) {
            while (true) {
              --k;
              n = ref[k];
              if (n.test(token)) {
                currentNode = currentNode[SR_PARAM_NODES][k];
                params[currentNode[SR_PARAM_NAMES][k]] = token;
                break;
              } else if (!k) {
                throw 404;
              }
            }
          } else {
            throw 404;
          }
        }
      } else if (!i) { // start node, do nothing

      } else if (i === pathLastIndex) { // last node (if enabled)
        currentNode = currentNode[FIXED_SUB_ROUTE][''];
        if (!currentNode) {
          throw 404; // some dupplicated slashes inside path, just ignore theme
        }
      } else {
        continue;
      }
      methodeDescriptor = currentNode[method];
      q = methodeDescriptor[ROUTE_MIDDLEWARE];
      if (q.length) {
        for (l = 0, len1 = q.length; l < len1; l++) {
          fx = q[l];
          middlewareQueu.push(fx);
        }
      }
      q = methodeDescriptor[ROUTE_ERR_HANDLER];
      if (q.length) {
        for (m = 0, len2 = q.length; m < len2; m++) {
          fx = q[m];
          errorHandlerQueu.push(fx);
        }
      }
      /* param resolvers */
      q = currentNode[ROUTE_PARAM];
      if (q) {
        for (k in q) {
          v = q[k];
          paramResolversQueu[k] = v;
        }
      }
    }
  }
  
  // if has no param resolver
  if (!Object.keys(paramResolversQueu).length) {
    paramResolversQueu = null;
  }
  if (!Object.keys(params).length) {
    params = null;
  }
  return {
    // return found node
    n: currentNode, // node
    p: params, // params
    m: middlewareQueu, // middlewares queu, sync mode only
    e: errorHandlerQueu.reverse(), // error handlers
    h: methodeDescriptor[ROUTE_HANDLER],
    pr: methodeDescriptor[ROUTE_PRE_PROCESS],
    ps: methodeDescriptor[ROUTE_POST_PROCESS],
    pm: paramResolversQueu // param resolvers
  };
};

ROUTE_PARAM = Symbol('Route params');

VOID_REGEX = {
  test: function() {
    return true;
  }
};

/**
* Add param
* @param {string} paramName - name of the parameter
* @optional @param {Regex} regex - regex or un object that contains a function "test"
* @param {function} handler - the function that will handle the param
* @example
* route.param( 'myParam', /^\d$/i, (data) => {return data} )
* route.param( 'myParam', (data) => {return data} )
 */
Route.prototype.param = function(paramName, regex, handler) {
  var params;
  if (typeof paramName !== 'string') {
    throw new Error('ParamName expected string');
  }
  params = this[ROUTE_PARAM] != null ? this[ROUTE_PARAM] : this[ROUTE_PARAM] = {};
  if (params[paramName] != null) {
    throw new Error(`Param <${paramName}> already set for this route`);
  }
  switch (arguments.length) {
    case 2:
      if (typeof regex !== 'function') {
        throw new Error('Handler required');
      }
      handler = regex;
      regex = VOID_REGEX;
      break;
    case 3:
      if (!(regex && typeof regex.test === 'function')) {
        throw new Error('Uncorrect regex');
      }
      if (typeof handler !== 'function') {
        throw new Error('Handler expected function');
      }
      break;
    default:
      throw new Error('Illegal arguments');
  }
  if (handler.length !== 2) {
    // add handler
    throw new Error('Handler expect exactly two parameters (ctx, data)');
  }
  params[paramName] = {
    r: regex,
    h: handler
  };
  return this;
};

/**
* Check if this route has param
* @param {string} paramName - param name
 */
Route.prototype.hasParam = function(paramName) {
  var params;
  if (arguments.length !== 1) {
    throw new Error('Illegal arguments');
  }
  if (typeof paramName !== 'string') {
    throw new Error('ParamName expected string');
  }
  params = this[ROUTE_PARAM];
  if (params) {
    return params.hasOwnProperty(paramName);
  } else {
    return false;
  }
};

/**
* Remove param handler from this route
* @param {string} paramName - param name
 */
Route.prototype.rmParam = function(paramName) {
  var params;
  if (arguments.length !== 1) {
    throw new Error('Illegal arguments');
  }
  if (typeof paramName !== 'string') {
    throw new Error('ParamName expected string');
  }
  params = this[ROUTE_PARAM];
  if (params) {
    delete params[paramName];
    if (!Object.keys(params).length) {
      return this[ROUTE_PARAM] = void 0;
    }
  }
};

/**
 * get regex related to a param
 * @private
 */
Route.prototype._paramToRegex = function(paramName) {
  var ref1, ref2;
  return ((ref1 = this[ROUTE_PARAM]) != null ? (ref2 = ref1[paramName]) != null ? ref2.r : void 0 : void 0) || VOID_REGEX;
};

/**
* build handler for "Router::on" method
* @private
* @example
* router.on('GET', '/route')
* 		.use(middleware)
* 		.then(handler)
* 		.then(handler, errHandler)
* 		.catch(errHandler)
* 		.finally(finalHandler)
* router.on('GET', '/route')
* 		.catch(errHandler)
* 		.finally()
 */
_OnHandlerBuilder = class _OnHandlerBuilder {
  /**
   * @constructor
   * @param  {Object} _parent - parent object (router)
   * @param  {[type]} cb  - callback, when route created
   */
  constructor(_parent, cb) {
    this._parent = _parent;
    this.cb = cb;
    // store promise handlers in case of promise architecture
    this.promiseQueu = [];
    // in case of global handlers (post process and error handler)
    this.postHandlers = [];
    this.preHandlers = [];
    this.errHandlers = [];
    // middlewares
    this.middlewares = [];
    // fire build if not explicitly called
    this._buildTimeout = setTimeout((() => {
      return this.build();
    }), 0);
    return;
  }

  /**
   * Build handler and returns to parent object
   * @return {Object} parent object
   */
  build() {
    // cancel auto build
    clearTimeout(this._buildTimeout);
    // send response to parent object
    this.cb(this);
    // return parent object
    return this._parent;
  }

  /**
   * then
   * @example
   * .then (ctx)->
   * .then ( (ctx)-> ), ( (ctx{error})-> )
   */
  then(handler, errHandler) {
    if (!(!handler || typeof handler === 'function')) {
      throw new Error('Handler expected function');
    }
    if (!(!errHandler || typeof errHandler === 'function')) {
      throw new Error('Error Handler expected function');
    }
    if (this.finally.length || this.catch.length) {
      // expect no global error handler or post handler is added
      throw new Error('Illegal use of promise handlers, please see documentation');
    }
    // append as promise or error handler
    this.promiseQueu.push([handler, errHandler]);
    return this;
  }

  /**
   * catch
   * Add "Promise catch" handler or "error handling" handler
   * @param {function} errHandler - Error handler
   * @example
   * .catch (ctx{error})->
   */
  catch(errHandler) {
    if (typeof handler !== 'function') {
      throw new Error('Handler expected function');
    }
    if (this.promise.length) {
      this.then(null, errHandler);
    } else {
      this.errHandlers.push(errHandler);
    }
    return this;
  }

  /**
   * finally
   * Add promise finally or post process handler
   * @param {function} handler - Promise finally or post process handler
   * @example
   * .finally (ctx)->
   */
  finally(handler) {
    if (typeof handler !== 'function') {
      throw new Error('Handler expected function');
    }
    if (this.promise.length) {
      this.then(handler, handler);
    } else {
      this.postHandlers.push(handler);
    }
    return this;
  }

  /**
   * middlewares
   * @example
   * .use (ctx)->
   * .use (ctx, res, next)-> # express compatible format, best to use it only with express middlewares
   * .use (err, ctx, res, next)-> # express error handler compatible format, best to use it only with express middlewares
   */
  use(middleware) {
    if (typeof middleware !== 'function') {
      throw new Error('middleware expected function');
    }
    // Gridfw format
    if (middleware.length === 1) {
      this.middlewares.push(middleware);
    // compatibility with express
    } else if (middleware.length === 3) {
      this.middlewares.push(function(ctx) {
        return new Promise(function(resolve, reject) {
          return middleware(ctx, ctx.res, function(err) {
            if (err) {
              return reject(err);
            } else {
              return resolve();
            }
          });
        });
      });
    // express error handler
    //TODO check if this error handler is compatible
    } else if (middleware.length === 4) {
      this.errHandlers.push(function(ctx) {
        return new Promise(function(resolve, reject) {
          return middleware(ctx.error, ctx, ctx.res, function(err) {
            if (err) {
              return reject(err);
            } else {
              return resolve();
            }
          });
        });
      });
    } else {
      // Uncknown format
      throw new Error('Illegal middleware format');
    }
    return this;
  }

  /**
   * preHandlers
   * @example
   * .filter (ctx)->
   */
  filter(handler) {
    if (typeof handler !== 'function') {
      throw new Error('Filter expected function');
    }
    this.preHandlers.push(handler);
    return this;
  }

};

/**
 * create route and return to parent object
 */
Object.defineProperty(_OnHandlerBuilder, 'end', {
  get: function() {
    return this.build();
  }
});

/**
 * Check all sub routes are compatible and optimized
 * use explicitly at production mode
 * We avoided to use a recursive function
 */
Route.checker = function() {
  var avoidCirc, currentNode, currentStep, errors, j, k, l, len, len1, nextNodes, nodeRegexes, pNodesNames, ref1, ref2, ref3, rgx, step, v;
  errors = [];
  nextNodes = [
    {
      node: this,
      path: []
    }
  ];
  avoidCirc = new Set(); // to avoid cyclic call
  step = 0;
  while (true) {
    // current node
    currentStep = nextNodes[step];
    if (!currentStep) {
      break;
    }
    currentNode = currentStep.node;
    if (avoidCirc.has(currentNode)) {
      continue;
    }
    avoidCirc.add(currentNode);
    // check all static values are not matched by a param regex
    nodeRegexes = currentNode[SR_PARAM_REGEXES];
    ref1 = currentNode[FIXED_SUB_ROUTE];
    for (k in ref1) {
      v = ref1[k];
      for (j = 0, len = nodeRegexes.length; j < len; j++) {
        rgx = nodeRegexes[j];
        if (rgx.test(k)) {
          errors.push({
            codeText: 'RegexMatchesKey',
            key: k,
            path: '/' + currentStep.path.concat(k).join('/'),
            message: `key <${k}> matched by param regex: ${rgx}`
          });
        }
      }
    }
    ref2 = currentNode[FIXED_SUB_ROUTE];
    //TODO: check two regexes arent equals, matches or infinit loop

    // add static sub nodes
    for (k in ref2) {
      v = ref2[k];
      nextNodes.push({
        node: v,
        path: currentStep.path.concat(k)
      });
    }
    // add parametred sub nodes
    pNodesNames = currentNode[SR_PARAM_NAMES];
    ref3 = currentNode[SR_PARAM_NODES];
    for (v = l = 0, len1 = ref3.length; l < len1; v = ++l) {
      k = ref3[v];
      nextNodes.push({
        node: v,
        path: currentStep.path.concat(pNodesNames[k])
      });
    }
    // next
    ++step;
  }
  // return errors
  return errors;
};

module.exports = Route;
