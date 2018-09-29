###*
 * Add routes
 * Supported routes
 **** static routes
 * /path/to/static/route
 * /path/containing/*stars/is-supported
 **** to escape "*" and ":" use "*?" and ":?"
 * /wildcard/in/the/last/mast/be/escaped/*?
 * /semi/:?colone/mast/be/escaped:if:after:slash:only
 **** dynamic path
 * /dynamic/:param1/path/:param2
 * /dynamic/:param/* # the rest of path will be stored inside param called "*"
 * /dynamic/:param/:rest* # the rest of path will be stored in the param "rest"
###
Object.defineProperties GridFW.prototype,
	###*
	 * Add a route
	 * @example
	 * Route.on('GET', '/path/to/resource', handler)
	 * .on(['GET', 'HEAD'], ['/path/to/resource', '/path2/to/src'], handler)
	 * .on('GET', '/path/to/resource')
	 * 		.then(handler)
	 * 		.end # go back to route
	 * .on('GET', '/path/to/resource')
	 * 		.use(middleware) # use a middleware
	 * 		#Add filters
	 * 		.filter(function(ctx){})
	 * 		.filter(Filters.isAuthenticated)
	 * 		# user promise like processing
	 * 		.then(handler)
	 * 		.then(handler2)
	 * 		.catch(err => {})
	 * 		.then(handler3)
	 * 		.finally(handler)
	 * 		.then(handler)
	 * 		# add param handler (we suggest to use global params as possible to avoid complexe code)
	 * 		.param('paramName', function(ctx){})
	 ****
	 * Add Global error handling and post process
	 * <!> do not confuse with promise like expression
	 * there is no "then" method
	 ****
	 * Route.on('GET', 'path/to/resource')
	 * 		.catch(err=>{}) # Global error check
	 * 		.finally(ctx =>{}) # post process
	 * 		
	###
	on: value: (method, route, handler)->
		# Add handlers
		switch arguments.length
			# .on 'GET', '/route', handler
			when 3
				throw new Error 'handler expected function' unless typeof handler is 'function'
				throw new Error 'handler could take only one argument' if handler.length > 1
				_createRouteNode this, method, route, c: handler
				# chain
				this
			# .on 'GET', '/route'
			# create new node only if controller is specified, add handler to other routes otherwise
			when 2
				# do builder
				return new _RouteBuiler this, (node)-> _createRouteNode this, method, route, node
			else
				throw new Error 'Illegal arguments'
	###*
	 * Remove route
	 * @example
	 * .off('alll', '/route', hander) # remove this handler (as controller, preprocess, postprocess, errorHander, ...)
	 * 									from this route for all http methods
	 * .off('GET', '/route') # remove this route
	###
	#TODO remove route, post process or any handler
	off: value: (method, route, handler)->
		# check method
		throw new Error 'method expected string' unless typeof method is 'string'
		method = method.toUpperCase()
		throw new Error "Unknown http method [#{method}]" unless method in HTTP_METHODS
		# exec
		switch arguments.length
			# off(method, route)
			when 2:
				if method


###*
 * Create route node or add handlers to other routes
###
_createRouteNode = (app, method, route, nodeAttrs)->
	# flatten method
	if Array.isArray method
		for v in method
			_createRouteNode app, v, route, nodeAttrs
		return
	# check method
	throw new Error 'method expected string' unless typeof method is 'string'
	method = method.toUpperCase()
	throw new Error "Unknown http method [#{method}]" unless method is 'ALL' || method in HTTP_METHODS
	# flatten route
	if Array.isArray route
		for v in route
			_createRouteNode app, method, v, nodeAttrs
		return
	# check route
	throw new Error 'route expected string' unless typeof route is 'string'
	throw new Error "Incorrect route: #{route}" if /^\?|[^:*]\?/.test route
	# check if it is a static or dynamic route
	isDynamic = /\/:[^?]|*$/.test route
	# route key
	routeKey = if isDynamic then route.replace(/([:*])/g, '$1?') else route.replace /([:*])\?/g, '$1'
	# get some already created node if exists
	allRoutes = app[ALL_ROUTES]
	routeMapper = allRoutes[routeKey]
	# if dynamic route
	if isDynamic
		# if has controller, create the route
		if nodeAttrs.c
			# create mapper if not exists
			unless routeMapper
				routeMapper= allRoutes[routeKey] = new RouteMapper app, route
			# add handlers to route
			routeMapper.append method, nodeAttrs
		# else add handler to any route or future route that matches
		else
			@_registerRouteHandlers app, route, nodeAttrs
	# if static route, create node even no controller is specified
	else
		# create route mapper if not exists
		unless routeMapper
			routeMapper= allRoutes[routeKey] = new RouteMapper app, route
		# add handler to node
		routeMapper.append method, nodeAttrs
	# ends
	return

