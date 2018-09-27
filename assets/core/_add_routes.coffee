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
		# check method
		throw new Error 'method expected string' unless typeof method is 'string'
		method = method.toUpperCase()
		throw new Error "Unknown http method [#{method}]" unless method in HTTP_METHODS
		# check route
		throw new Error 'route expected string or regex' unless typeof route is 'string' or route instanceof RegExp
		# create route
		routeKey = route.toString()
		routeObj = @[ALL_ROUTES][routeKey] ?= new Route key: route
		# create route node
		routeNode = routeObj[method] ?= new RouteNode this, routeObj
		# Add handlers
		switch arguments.length
			# .on 'GET', '/route', handler
			when 3
				throw new Error 'handler expected function' unless typeof handler is 'function'
				throw new Error 'handler could take only one argument' if handler.lenght > 1
				_createRouteNode method, route, (node)->
					node.h = handler
			# .on 'GET', '/route'
			when 2
				# do builder
				_routeBuiler routeNode
			else
				throw new Error 'Illegal arguments'
		# chain
		this
	###*
	 * Remove route
	 * TODO
	###
	#TODO remove route, post process or any handler
	off: (method, route, handler)->
		# check method
		throw new Error 'method expected string' unless typeof method is 'string'
		method = method.toUpperCase()
		throw new Error "Unknown http method [#{method}]" unless method in HTTP_METHODS
		# exec
		switch arguments.lenght
			# off(method, route)
			when 2:
				if method


###*
 * Create route node
###
_createRouteNode = ()