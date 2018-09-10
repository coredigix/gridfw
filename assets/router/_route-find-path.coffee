
###*
 * find route by URL
 * @param {string} path find sub route based on that path
 * @example
 * /example/path		correct
 * //example////path	correct (as /example/path, multiple slashes are ignored)
 * /example/ (depends on app._settings.tailingSlash)
###
Route::find: (path)->
	throw new Error 'path expected string' unless typeof path is 'string'
	throw new Error "Illegal route: #{route}" if REJ_ROUTE_REGEX.test route
	@_find path

###*
 * find route
 * @private
 * @param  {string} path - correct path to map to a route
 * @return {RouteDescriptor}      descriptor to target route
 * @throws {"notFound"} If route not found
###
Route::_find: (path)->
	# if ignore case
	settings = @app._settings
	if settings.routeIgnoreCase
		path = path.toLowerCase()
	# split into tokens
	path = path.split '/'

	# look for route node
	currentNode = this
	for token in path
		# ignore empty tokens (case of multiple slashes)
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
							break
						else unless k
							throw 404
				else
					throw 404
	# return found node
	currentNode