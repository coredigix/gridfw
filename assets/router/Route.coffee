'use strict'
###*
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
###

fastDecode	= require 'fast-decode-uri-component'
Context		= require '../context'
http		= require 'http'

class Route
	###*
	 * [constructor description]
	 * @param {Route} parent - parent Route object
	 * @type {[type]}
	###
	constructor: (parent, lazyName, lazyParam) ->
		# init attributes with undefined value
		undefined_ =
			value: undefined
			configurable: true
			writable: true
		# sub routes
		Object.defineProperties this,
			### parent route node ###
			parent:
				value: parent
				configurable: true
				writable: true
			### app ###
			app:
				value: parent && parent.app
				configurable: true
				writable: true
			### @private static name sub routes ###
			[FIXED_SUB_ROUTE]:	value: {}
			### @private parametred sub routes ###
			[SR_PARAM_NAMES]:	value: []
			[SR_PARAM_NODES]:	value: []
			[SR_PARAM_REGEXES]:	value: []
			### name of the route, undefined when it a parametred route ###
			name: undefined_
			### param name (case of parametred route )###
			paramName: undefined_
			### parents: in case node is attached to multiple parents ###
			parents: value: if parent then [parent] else []
			### lazy append ###
			lazyAttach: undefined_
			###
			param manger for this route and it's subroutes
			@private
			###
			[ROUTE_PARAM]: undefined_

		# Route lazy add
		if lazyName or lazyParam
			throw new Error 'Lazy mode needs parent node' unless parent
			# check
			if lazyName
				throw new Error 'Route name expected string' unless typeof lazyName is 'string'
				throw new Error 'Could not set route name and param at the same time' if lazyParam
			else
				throw new Error 'Route param name expected string' unless typeof lazyParam is 'string'
			# add as lazy
			@lazyAttach= [parent, lazyName, lazyParam]
		return

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
		throw new Error "Illegal route: #{route}" if REJ_ROUTE_REGEX.test route
		settings = @app.settings
		routeIgnoreCase = settings.routeIgnoreCase
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
		# check for uniqueness of path params
		routeParams = new Set()
		if route
			# split into tokens
			routeTokens = route.split '/'
			# find route
			for token in routeTokens
				# <!> param names are case sensitive!
				# param
				if token.startsWith ':'
					token = token.substr 1
					# check it's not named __proto__
					throw new Error '__proto__ Could not be used as param name' if token is '__proto__'
					# check for uniqueness
					throw new Error "Duplicated path param <#{token}> at: #{route}" if routeParams.has token
					routeParams.add token

					# relations are stored as array (for performance)
					# [0]: contains param name
					# [1]: contains reference to route object
					idx = currentRouteNode[SR_PARAM_NAMES].indexOf token
					if idx is -1
						currentRouteNode = new Route currentRouteNode, null, token
					else
						currentRouteNode = currentRouteNode[SR_PARAM_NODES][idx]
				# fixed name
				else
					# replace "\:" with ":"
					if token.startsWith '\\:'
						token = token.substr 1
					# when route isn't case sensitive
					if routeIgnoreCase
						token = token.toLowerCase()
					# decode token
					token = fastDecode token
					# find route
					cRoute = currentRouteNode[FIXED_SUB_ROUTE][token]
					# create route if not exist
					if cRoute
						currentRouteNode = cRoute
					else
						currentRouteNode = new Route currentRouteNode, token
		# return route node
		currentRouteNode

	###*
	 * Attach route
	 * case of lazy add, or attach this node to other parent node
	 * @optional @param {Route node} parent - node to attach to
	 * @optional @param {string} name - node name
	 * @optional @param {string} paramName - node param name (in case of parametred route)
	 * @example
	 * attach(parent)  # if node is lazy, the attachement will be when node change state to active
	 * attach()	# if node is lazy, change it state to active, and index it inside all parents
	 * this will propagate to lazy parents to (will change to active too)
	###
	attach: (parent, nodeName, nodeParamName)->
		# attach lazy nodes, use this algo to avoid recursive calls
		currentNodes = [this]
		nextStepNodes = []
		# loop
		while currentNodes.length
			# nextStepNodes.length = 0
			for currentNode in currentNodes
				lz = currentNode.lazyAttach
				if lz
					# [parent, lazyName, lazyParam]
					_attachNode currentNode, lz[0], lz[1], lz[2]
					currentNode.lazyAttach = null
					# add parents if lazy
					for n in currentNode.parents
						nextStepNodes.push n if n.lazyAttach
			# next step
			a = currentNodes
			currentNodes = nextStepNodes
			nextStepNodes = a
			a.length = 0

			break unless nextStepNodes.length

		# attach to other parent
		if parent
			# check
			throw new Error 'Expected Route object as argument' unless parent instanceof Route
			if nodeName
				throw new Error 'Route name expected string' unless typeof nodeName is 'string'
				throw new Error 'Could not set route name and param at the same time' if nodeParamName
			else
				throw new Error 'Route param name expected string' unless typeof nodeParamName is 'string'
			# add
			@parent = null
			@parents.push parent
			# attach
			_attachNode this, parent, nodeName, nodeParamName

		# enable chain
		this
	###*
	 * detach node from parent
	 * when no parent is specified, detach from all parents
	 * @optional @param  {Route} parent - node to detach from
	 * @example
	 * detach(parentNode)	# detach from this parent node
	 * detach()				# detach from all parent nodes
	###
	detach: (parent)->
		# remove from list
		parents = @parents
		switch arguments.length
			# detach from all parents
			when 0
				for parent in parents
					_detachNode this, parent
				@parents.length = 0
				@parent = undefined
			# detach from this parent
			when 1
				idx = parents.indexOf parent
				if idx >= 0
					parents.splice idx, 1
					if parents.length is 1
						@parent = parents[0]
					_detachNode this, parent
			# Illegal
			else
				throw new Error 'Illegal arguments'
		# enable chain
		this

	###*
	 * Use a handler
	###
	use: (middleware)->
		@all()
			.use middleware
			.end

### Route Prototype ###
HTTP_METHODS = http.METHODS
### others ###
ROUTE_PROTO = Route.prototype

### Route handlers ###
ROUTE_PROTO.HANDLER		= ROUTE_HANDLER		= 0
ROUTE_PROTO.MIDDLEWARE	= ROUTE_MIDDLEWARE	= 1
ROUTE_PROTO.PRE_PROCESS	= ROUTE_PRE_PROCESS	= 2
ROUTE_PROTO.POST_PROCESS= ROUTE_POST_PROCESS= 3
ROUTE_PROTO.ERR_HANDLER	= ROUTE_ERR_HANDLER	= 4
ROUTE_PROTO.ALL			= ROUTE_ALL = -1

### sub routes ###
FIXED_SUB_ROUTE			= Symbol 'static routes'
PARAM_HANDLERS			= Symbol 'param handlers'

SR_PARAM_NAMES			= Symbol 'param names'
SR_PARAM_REGEXES		= Symbol 'param regexes'
SR_PARAM_NODES			= Symbol 'param nodes'


### route to be rejected ###
REJ_ROUTE_REGEX = /\/\/|\?/



###*
 * get app, called once for performance
###
Object.defineProperty Route, 'app',
	get: ->
		for parent in @parents
			app = parent.app
			break if app
		# save app (to not call this getter again)
		if app
			Object.defineProperty this, 'app', value: app
		# return app
		app

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
		method = _checkHttpMethod method
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
		# attach this route if not already attached
		route.attach() if route.lazyAttach
	return

###*
 * remove route handlers
###
_rmRouteHandlers = (currentRoute, method, type, handler)->
	if Array.isArray method
		for v in method
			_rmRouteHandlers currentRoute, v, type, handler
	else
		# method key
		method = _checkHttpMethod method
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
 * shorthand routes, support basic methods only
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
[
	'get'
	'post'
	'delete'
	'head'
	'patch'
	'put'
].forEach (method, i)->
	# mehtod
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


###*
 * Attach node to an other
 * @private
 * @example
 * _attachNode node, [parentNode, 'nodeName', 'nodeParamName']
###
_attachNode = (node, parentNode, nodeName, nodeParamName)->
	# as static name
	if nodeName
		# convert to lower case if ignore case is active
		if node.app.settings.routeIgnoreCase
			nodeName = nodeName.toLowerCase()
		nodeName = fastDecode nodeName
		# attach
		ref = parentNode[FIXED_SUB_ROUTE]
		if ref.hasOwnProperty nodeName
			throw new Error 'Route already set' if ref[nodeName] isnt node
		else
			ref[nodeName] = node
	# as param
	if nodeParamName
		idx = parentNode[SR_PARAM_NAMES].indexOf nodeParamName
		if idx is -1
			parentNode[SR_PARAM_NAMES].push nodeName
			parentNode[SR_PARAM_NODES].push node
			parentNode[SR_PARAM_REGEXES].push parentNode._paramToRegex nodeParamName
		else
			throw new Error 'Route already set' if parentNode[SR_PARAM_NODES][idx] isnt node

###*
 * Detach node from parent
 * @private
###
_detachNode = (node, parentNode)->
	# remove static
	ref = parentNode[FIXED_SUB_ROUTE]
	for k, v of ref
		if v is node
			delete ref[k]
	# remove parametred
	refNodes = parentNode[SR_PARAM_NODES]
	refNames = parentNode[SR_PARAM_NAMES]
	refRegexes = parentNode[SR_PARAM_REGEXES]
	loop
		idx = refNodes.indexOf node
		if idx is -1
			break
		refNodes.splice idx, 1
		refNames.splice idx, 1
		refRegexes.splice idx, 1

###*
 * check http method
 * @return {string} useful key to access method data
###
_checkHttpMethod = (method)->
	throw new Error 'method expected string' unless typeof method is 'string'
	method = method.toUpperCase()
	throw new Error "Illegal http method: #{method}" unless method in HTTP_METHODS
	# return useful key
	'_' + method


# include other modules
#=include _route-find-path.coffee
#=include _route-params.coffee
#=include _route-onHandlerBuilder.coffee
#=include _route-checker.coffee


module.exports = Route