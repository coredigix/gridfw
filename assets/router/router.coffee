###*
 * Router
###

class Router
	###*
	 * Init router
	 * @see Router.settings for more infos about settings
	 * @param  {Object} @settings Router settings
	###
	constructor: (@settings)->

	###*
	 * Add a new route
	 * @Alias Router::route
	 * @param {string} type - HTTP.mathod
	 * @param {string} route - route where insert this handler
	 * @optional @param {function} handler - handler, could returns Promise or static value
	 * @example
	 * router.on('GET', '/example', async function(ctx){...})
	 * router.on(['POST', 'PUT'], '/example', async function(ctx){...})
	 * router.on('GET', ['/example', '/example2/*'], function(ctx){...})
	 *
	 * router.on('GET', '/example')
	 * 		.then(myHandler)
	 * router.on(['GET'], ['/example'])
	 * 		.then(myHandler)
	 * 		.then(myHandler2, errHandler)
	 * 		.end
	 *
	 * router.on('GET')
	 * 		.get('/route', handler)
	 * 		.get('/route').then(handler)
	###
	on: (type, route, handler)->
		# when type is an array of methods, recall for each method
		if Array.isArray type
			for v in type
				@on v, route, handler
		else if Array.isArray route
			for v in route
				@on type, v, handler
		# call "on" to add route
		else switch arguments.length
			# router.on(type, route, handler)
			when 3
				_AppendHandler this, type, route, handler
			# router.on(type, route)
			# router.on('GET', '/example').then(handler).end
			when 2
				new _OnHandlerBuilder this, (options)->
					# add handlers
					if options.promise
			# default: error
			else
				throw new Error 'Illegal arguments length'
			
		

		

		# router.on
		# return "this" to enable chain
		this

	###*
	 * Remove this handler from route
	 * @param  {string} type    - http method
	 * @param  {string|list<string>} route   route or list of routes
	 * @param  {function} handler - handler to remove
	 *
	 * @example
	 * router.off() # remove all routes
	 * router.off('GET') # remove all GET routes
	 * router.off('GET', '/example') remove "get /example" route
	 * router.off('GET', '/example', myHandler) # remove my handler from this route, this will not remove the route event it's not empty
	 * router.off('/example', myhander) # remove my handler from this routes
	 * router.off(myhander) # remove my handler from all routes
	###
	off: (type, route, handler)->

	###*
	 * get route object
	 * @example
	 * router.route('/user')
	 * 		.get(handler)
	 * 		.get()
	 * 			.then(handler)
	 * 			.catch(errHandler) # local cycle handler (this promise)
	 * 			.finally(finalHandler) # local cycle handler (this promise)
	 * 			.end
	 * 		.get()
	 * 			.catch(errHandler) # global route error handler (GET)
	 * 			.finally(finalHandler) # global route finalHandler (GET)
	 * 		.post(handler)
	 * 		.catch(errorHandler) # global route error handler
	 * 		.finally(postProcessHandler) # global route finalHandler
	###
	route: (route)->
	###*
	 * add listener to all routes
	 * @example
	 * router.all('/example', handler)
	 * router.all(['/example'], handler)
	 * router.all('/example)
	 * 		.then(handler)
	###
	all: (route, handler)->
		if arguments.length is 1
			@on http.METHODS, route
		else if arguments.length is 2
			@on http.METHODS, route, handler
		else
			throw new Error 'Illegal arguments count'
# Router prototype
_RouterProto = Router.prototype

###*
 * shorthand routes
 * @example
 * router.get('/route', handler)
 * router.get(['/route', '/route2'], handler)
 * router.get('/route')
 * 		.then(async fx)
 * router.get('/route')
 * 		.use(async fx)
 * router.get('/route')
 * 		.use(fx)
 * 		.then(asyc fx)
 * 		.then(asyc fx)
 * 		.catch(asyc fx)
 * 		.finally(async fx)
 * 		.end
###
http.METHODS.forEach (method)->
	Object.defineProperty _RouterProto, method,
		value: (route, handler)->
			if arguments.length is 1
				@on method, route
			else if arguments.length is 2
				@on method, route, handler
			else
				throw new Error 'Illegal arguments count'

