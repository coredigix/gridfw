
###*
 * find route by URL
 * @param {string} path - find sub route based on that path
 * @optional @param {string} method - http method @default GET
 * @example
 * /example/path		correct
 * //example////path	correct (as /example/path, multiple slashes are ignored)
 * /example/ (depends on app._settings.tailingSlash)
###
Route::find: (path, method)->
	throw new Error 'path expected string' unless typeof path is 'string'
	throw new Error "Illegal route: #{route}" if REJ_ROUTE_REGEX.test route
	# force to start by /
	unless path.startsWith '/'
		path = '/' + path
	# trailing slash
	settings = @app.settings
	unless settings.trailingSlash
		if path.endsWith '/'
			path = path.slice 0, -1
	# ignore case
	if settings.routeIgnoreCase
		path = path.toLowerCase()
	# use internal find
	@_find path, method || 'GET'

###*
 * find route
 * @private
 * @param  {string} path - correct path to map to a route
 * @param {string} method - method used lowercased and prefexed with "_", example: _get
 * @return {RouteDescriptor}      descriptor to target route
 * @throws {"notFound"} If route not found
###
Route::_find: (path, method)->
	# empty middlewars queu tobe used again (for performance issue)
	middlewareQueu= []
	errorHandlerQueu= []
	# method
	method = _checkHttpMethod method
	# split into tokens
	path = path.split '/'
	pathLastIndex= path.length
	if pathLastIndex > 2 # ignore case of 2 because "/", see comment: "last node (if enabled)"
		--pathLastIndex

	# look for route node
	currentNode = this
	params	= {}

	unless path is '/' # not route
		for token, i in path
			if token
				# check for static value
				node = currentNode[FIXED_SUB_ROUTE][token]
				if node
					currentNode = node
				# check for parametred node
				else
					ref = currentNode[SR_PARAM_REGEXES]
					k = ref.length
					if k
						loop
							--k
							n = ref[k]
							if n.test token
								currentNode = currentNode[SR_PARAM_NODES][k]
								params[currentNode[SR_PARAM_NAMES][k]] = token
								break
							else unless k
								throw 404
					else
						throw 404
			else unless i # start node, do nothing
			else if i is pathLastIndex # last node (if enabled)
				currentNode = currentNode[FIXED_SUB_ROUTE]['']
				unless currentNode
					throw 404
			else # some dupplicated slashes inside path, just ignore theme
				continue
				
			###
			[] # ROUTE_MIDDLEWARE
			[] # ROUTE_HANDLER
			[] # ROUTE_PRE_PROCESS
			[] # ROUTE_POST_PROCESS
			[] # ROUTE_ERR_HANDLER
			###
			### middlewares ###
			methodeDescriptor = currentNode[method]
			q= methodeDescriptor[ROUTE_MIDDLEWARE]
			if q.length
				for fx in q
					middlewareQueu.push fx
			### error handlers ###
			q= methodeDescriptor[ROUTE_ERR_HANDLER]
			if q.length
				for fx in q
					errorHandlerQueu.push fx
			
	# return found node
	n: currentNode # node
	p: params # params
	m: middlewareQueu # middlewares queu, sync mode only
	e: errorHandlerQueu.reverse() # error handlers
	h: methodeDescriptor[ROUTE_HANDLER] # handlers
	pr: methodeDescriptor[ROUTE_PRE_PROCESS] # pre-process
	ps:methodeDescriptor[ROUTE_POST_PROCESS] # post-process