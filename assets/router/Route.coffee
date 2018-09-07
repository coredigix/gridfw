###*
 * Route
###

class Route
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
	 * route.on('GET', '/sub-route').then(handler)
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
	 * router.off('GET', handler) # remove this handler from 'GET' method
	 * router.off(handler) # remove this handler from all methods
	 * 
	 * router.off('GET', Route.MIDDLEWARE) remove all middlewares from get method
	 * router.off('GET', Route.MIDDLEWARE, handler) remove this middle ware
	 * router.off(Route.MIDDLEWARE) remove all middleware from this route
	 * router.off([Route.MIDDLEWARE, Route.PRE_PROCESS]) remove all middleware from this route
	 * router.off(Route.MIDDLEWARE, hander) remove this middleware from this route
	###
	off: (method, type, handler)->
		switch arguments.length
			# off()
			# remove all handlers
			when 0
				@off HTTP_METHODS
			# off('GET')
			# off(['GET'])
			# off(handler)
			# off([handler])
			# off(Route.MIDDLEWARE)
			# off([Route.MIDDLEWARE])
			when 1
				if typeof type is 'number'
					@off HTTP_METHODS, type
				else if typeof type is 'string'

				else if typeof type is 'function'
					@off HTTP_METHODS, ROUTE_HANDLER, type
				else if Array.isArray type
					for v in type
						@off v
			# off('GET', Route.MIDDLEWARE, handler)
			# off(['GET', 'POST'], [Route.MIDDLEWARE, Route.HANDLER], handler)
			when 2



		# chain
		this


ROUTE_PROTO = Route.prototype
###*
 * consts
###
ROUTE_PROTO.HANDLER		= ROUTE_HANDLER		= 0
ROUTE_PROTO.MIDDLEWARE	= ROUTE_MIDDLEWARE	= 1
ROUTE_PROTO.PRE_PROCESS	= ROUTE_PRE_PROCESS	= 2
ROUTE_PROTO.POST_PROCESS= ROUTE_POST_PROCESS= 3
ROUTE_PROTO.ERR_HANDLER	= ROUTE_ERR_HANDLER	= 4
ROUTE_PROTO.ALL			= -1

HTTP_METHODS = http.METHODS

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
		methodObj[type].push handler
	return


