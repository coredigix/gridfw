###*
 * Add routes
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
	on: (method, route, handler)->
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
				return new _RouteBuiler this, (node)->
					if node.c
						_createRouteNode this, method, route, node
					else
						#TODO
						throw new Error 'Add handlers to other routes not yeat implemented!'
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
	off: (method, route, handler)->
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
 * Create route node
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
	throw new Error 'route expected string or regex' unless typeof route is 'string' or route instanceof RegExp
	# create route
	routeKey = route.toString()
	routeObj = app[ALL_ROUTES][routeKey]
	if routeObj
		# check has not already an 'all' method
		if nodeAttrs.c and routeObj.ALL?.c
			throw new Error "A controller alreay set to all http methods on this route: #{route}"
	else
		routeObj = app[ALL_ROUTES][routeKey] = new Route key: route
	# create route node
	routeNode = routeObj[method]
	if routeNode
		if nodeAttrs.c and routeNode.c
			throw new Error "A controller already set to this route: #{method} #{route}"
	else
		routeNode = routeObj[method] = new RouteNode this, routeObj
	# add handlers
	for k, v of nodeAttrs
		if typeof v is 'function'
			routeNode[k] = v
		else if Array.isArray v
			ref= routeNode[k]
			# append handlers
			if ref
				for a in v
					ref.push a
			# add the whole array
			else
				routeNode[k] = v
		else
			throw new Error 'Enexpected nodeAttrs'
	# param resolvers
		ref = routeNode.pm
		for k,v of nodeAttrs.pm
			throw new Error "Param [#{k}] already set to route #{method} #{route}" if ref[k]
			ref[k] = v
	return

