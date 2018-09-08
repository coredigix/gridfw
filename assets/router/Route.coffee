###*
 * Route
 * @todo add route.path to get full descriptor path of this route
###

fastDecode = require 'fast-decode-uri-component'

class Route
	###*
	 * [constructor description]
	 * @param {Route} parent - parent Route object
	 * @param {boolean} attached - if the node is attached, when false, lazy attach, ie: attach when some operation and has parent(add handler, ...)
	 * @type {[type]}
	###
	constructor: (@parent, @attached) ->
		# init attributes with undefined value
		undefined_ =
			value: undefined
			configurable: true
			writable: true
		# sub routes
		Object.defineProperties this,
			### static name sub routes ###
			[FIXED_SUB_ROUTE]:		value: {}
			### parametred sub routes ###
			[PARAMETRED_SUB_ROUTE]:	value: []
			###*
			 * param handlers
			 * @example
			 * # Add handler
			 * 		route.params.paramName = function(ctx){}
			 * 		route.params.paramName = async function(ctx){}
			 * # remove param hander
			 * 		delete route.params.paramName
			 * # check if route has param handler
			 * 		if route.params.paramName
			 * 		if route.params.hasOwnProperrty('paramName')
			###
			params: value: {}
			### name of the route, undefined when it a parametred route ###
			name: undefined_
			### param name (case of parametred route )###
			paramName: undefined_

	###*
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
	###
	on: (method, handler, extra)->
		switch arguments.length
			# route.on('GET')
			when 1
				_buildHandler this, method
			# route.on('GET', '/subroute')
			# route.on('GET', ['/subroute'])
			# route.on('GET', handler)
			when 2
				# handler
				if typeof handler is 'function'
					_routeAppendHandler this, method, ROUTE_HANDLER, handler
					this # return "this" for chain
				# subRoute
				else
					# return _buildHandler currentRoute, method, subRoutes
					_buildHandler this, method, handler
			# route.on('GET', '/route', handler)
			# route.on('GET', ['/route'], handler)
			when 3
				if Array.isArray handler
					for v in handler
						@route v
							.on method, extra
				else
					@route handler
						.on method, extra
				# return "this" for chain
				this
			else
				throw new Error 'Illegal arguments'

	###*
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
	###
	off: (method, type, handler)->
		switch arguments.length
			# remove all handlers
			when 0
				# off()
				@off HTTP_METHODS, ROUTE_ALL
			when 1
				# off(Route.MIDDLEWARE)
				if typeof method is 'number'
					@off HTTP_METHODS, ROUTE_ALL, method
				# off(handler)
				else if typeof method is 'function'
					@off HTTP_METHODS, ROUTE_ALL, method
				# off('GET')
				# off(['GET'])
				else if typeof method is 'string' or Array.isArray method
					@off method, ROUTE_ALL
				else throw new Error "Illegal Argument #{method}"
			when 2
				if typeof type is 'function'
					# off(Route.MIDDLEWARE, hander)
					if typeof method is 'number'
						@off HTTP_METHODS, method, type
					# off('GET', handler)
					else
						@off method, ROUTE_ALL, type
				# off('GET', Route.MIDDLEWARE)
				else if typeof type is 'number'
					throw new Error "Illegal type: #{type}" unless typeof type is 'number'
					_rmRouteHandlers this, method, type
				else throw new Error "Illegal arguments: #{arguments}"
			when 3
				throw new Error "Illegal type: #{type}" unless typeof type is 'number'
				throw new Error "Illegal handler: #{handler}" unless typeof handler is 'function'
				# off('GET', Route.MIDDLEWARE, handler)
				_rmRouteHandlers this, method, type, handler
		# chain
		this

	###*
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
	###
	all: (subRoute, handler)->
		switch arguments.length
			# all()
			when 0
				@on HTTP_METHODS
			# all('/subRoute')
			# all(handler)
			when 1
				@on HTTP_METHODS, subRoute
			# all('/subroute', handler)
			when 2
				@on HTTP_METHODS, subRoute, handler
			else
				throw new Error 'Illegal arguments count'

	###*
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
	###
	route: (route)->
		throw new Error "Route expected string, found: #{route}" unless typeof route is 'string'
		settings = @app.settings
		# remove end spaces and starting slash
		route = route.trimRight()
		if route.startsWith '/'
			route = route.substr 1
		# if ends with "/" is ignored, removeit
		unless settings.trailingSlash
			if route.endsWith '/'
				route = route.slice 0, -1
		# if empty, keep current node
		currentRouteNode = this
		if route
			# split into tokens
			route = route.split '/'
			# find route
			for token in route
				# <!> param names are case sensitive!
				# param
				cRoute = null
				if token.startsWith ':'
					for rout in currentRouteNode[PARAMETRED_SUB_ROUTE]
						if rout.param is token
							cRoute = rout
							break
					# found
					if cRoute
						currentRouteNode = cRoute
					else
						currentRouteNode = new Route currentRouteNode, false
						currentRouteNode.paramName = token
				# fixed name
				else
					# replace "\:" with ":"
					if token.startsWith '\\:'
						token = token.substr 1
					# when route isn't case sensitive
					if settings.routeIgnoreCase
						token = token.toLowerCase()
					# decode token
					token = fastDecode token
					# find route
					cRoute = currentRouteNode[FIXED_SUB_ROUTE][token]
					# create route if not exist
					if cRoute
						currentRouteNode = cRoute
					else
						currentRouteNode = new Route currentRouteNode, false
						currentRouteNode.name = token
		# return route node
		currentRouteNode

	###*
	 * find route by URL
	 * @param {string} path find sub route based on that path
	###
	find: (path)->
		#TODO

	###*
	 * Attach route
	 * case of lazy add, or attach this node to other parent node
	 * when node has multiple parents, it will has "parent" as array of all parent node
	 * and "path" to null
	 * @optional @param {Route} parent - node to attach to
	###
	attach: (parent)->
		#TODO
		# enable chain
		this
	###*
	 * detach node from parent
	 * when no parent is specified, detach from all parents
	 * @optional @param  {Route} parent - node to detach from
	###
	detach: (parent)->
		#TODO
		# enable chain
		this



### Route Prototype ###
HTTP_METHODS = http.METHODS

### Route handlers ###
ROUTE_PROTO.HANDLER		= ROUTE_HANDLER		= 0
ROUTE_PROTO.MIDDLEWARE	= ROUTE_MIDDLEWARE	= 1
ROUTE_PROTO.PRE_PROCESS	= ROUTE_PRE_PROCESS	= 2
ROUTE_PROTO.POST_PROCESS= ROUTE_POST_PROCESS= 3
ROUTE_PROTO.ERR_HANDLER	= ROUTE_ERR_HANDLER	= 4
ROUTE_PROTO.ALL			= ROUTE_ALL = -1

### sub routes ###
FIXED_SUB_ROUTE			= Symbol 'static routes'
PARAMETRED_SUB_ROUTE	= Symbol 'parameted routes'
PARAM_HANDLERS			= Symbol 'param handlers'

### others ###
ROUTE_PROTO = Route.prototype

###*
 * build handler
 * @param {Object} route current route
 * @param {string | list<string>} [varname] [description]
###
_buildHandler= (currentRoute, method, subroutes)->
	# affected routes
	if subroutes
		if typeof subroutes is 'string'
			subroutes = currentRoute.route subroutes
		else
			subroutes = subroutes.map (route)-> currentRoute.route route
	else
		subroutes = currentRoute
	# return builder
	new _OnHandlerBuilder currentRoute, ({promiseQueu, middlewares, preHandlers, postHandlers, errHandlers})=>
		# add simple handler
		if promiseQueu.length is 1
			_routeAppendHandler subroutes, method, ROUTE_HANDLER, promiseQueu[0]
		# multiple handlers
		else if promiseQueu.length > 1
			# check if add handlers separated or use promise generator
			usePromise = false
			for v in promiseQueu
				if v[1]
					usePromise = true
					break
			# if use promise
			if usePromise
				_routeAppendHandler subroutes, method, ROUTE_HANDLER, (ctx)->
					promiseQueu.reduce ( (p, fx)->
						p.then fx[0], fx[1]
					), Promise.resolve(ctx)
			else
				for v in promiseQueu
					_routeAppendHandler subroutes, method, ROUTE_HANDLER, v[0]
		# add middlewares
		if middlewares.length
			for handler in middlewares
				_routeAppendHandler subroutes, method, ROUTE_MIDDLEWARE, handler
		# add preHandlers
		if preHandlers.length
			for handler in preHandlers
				_routeAppendHandler subroutes, method, ROUTE_PRE_PROCESS, handler
		# add postHandlers
		if postHandlers.length
			for handler in postHandlers
				_routeAppendHandler subroutes, method, ROUTE_POST_PROCESS, handler
		# add error handlers
		if errHandlers.length
			for handler in errHandlers
				_routeAppendHandler subroutes, method, ROUTE_ERR_HANDLER, handler
		return
###*
 * Append handler to a route
 * @private
 * @param {Object} route - route Object
 * @param {string | list<strin>} method - http method or list of http methods
 * @param {string} type - typeof handler in [h, m, p, e], see bellow
 * @param {function} handler - the handler to add
###
_routeAppendHandler = (route, method, type, handler)->
	if Array.isArray route
		for v in route
			_routeAppendHandler v, method, type, handler
	else if Array.isArray method
		for v in method
			_routeAppendHandler route, v, type, handler
	else
		throw new Error "Illegal http method #{method}" unless typeof method is 'string' and method in HTTP_METHODS
		# method key
		method = '_' + method.toUpperCase()
		# create method object if not already
		methodObj = route[method] ?=[
			[] # ROUTE_HANDLER
			[] # ROUTE_MIDDLEWARE
			[] # ROUTE_PRE_PROCESS
			[] # ROUTE_POST_PROCESS
			[] # ROUTE_ERR_HANDLER
		]
		# add handler
		arr = methodObj[type]
		throw new Error "Illegal type: #{type}" unless arr?
		arr.push handler
	return

###*
 * remove route handlers
###
_rmRouteHandlers = (currentRoute, method, type, handler)->
	if Array.isArray method
		for v in method
			_rmRouteHandlers currentRoute, v, type, handler
	else
		throw new Error "Illegal http method #{method}" unless typeof method is 'string' and method in HTTP_METHODS
		# method key
		method = '_' + method.toUpperCase()
		methodObj = currentRoute[method]
		if methodObj
			# remover
			remover = (arr)=>
				# remove handler only
				if handler
					loop
						idx = arr.indexOf handler
						if idx is -1
							break
						arr.splice idx, 1
				# remove all handlers
				else
					arr.length = 0
			# remove
			if type is ROUTE_ALL
				for arr in methodObj
					remover arr
			else
				arr= methodObj[type]
				throw new Error "Illegal type: #{type}" unless arr?
				remover arr
	return


###*
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
###
HTTP_METHODS.forEach (method)->
	Object.defineProperty ROUTE_PROTO, method,
		value: (route, handler)->
			switch arguments.length
				when 0
					@on method
				when 1
					@on method, route
				when 2
					@on method, route, handler
				else
					throw new Error 'Illegal arguments count'

# 
# 
# 
# Add param hand