###*
 * Param manager
 * (Affect both Path params and query params)
 * @author COREDIGIX
###

ROUTE_PARAM = Symbol 'Route params'

VOID_REGEX =
	test: -> true

###*
 * Add param
 * @param {string} paramName - name of the parameter
 * @optional @param {Regex} regex - regex or un object that contains a function "test"
 * @param {function} handler - the function that will handle the param
 * @example
 * route.param( 'myParam', /^\d$/i, (data) => {return data} )
 * route.param( 'myParam', (data) => {return data} )
###
Route::param= (paramName, regex, handler)->
	throw new Error 'ParamName expected string' unless typeof paramName is 'string'
	params	= @[ROUTE_PARAM] ?= {}
	throw new Error "Param <#{paramName}> already set for this route" if params[paramName]?
	switch arguments.length
		when 2
			throw new Error 'Handler required' unless typeof regex is 'function'
			handler = regex
			regex	= VOID_REGEX
		when 3
			throw new Error 'Uncorrect regex' unless regex and typeof regex.test is 'function'
			throw new Error 'Handler expected function' unless typeof handler is 'function'
		else
			throw new Error 'Illegal arguments'
	# add handler
	throw new Error 'Handler expect exactly two parameters (ctx, data)' unless handler.length is 2
	params[paramName] =
		r: regex
		h: handler
	# chain
	this
###*
 * Check if this route has param
 * @param {string} paramName - param name
###
Route::hasParam = (paramName)->
	throw new Error 'Illegal arguments' if arguments.length isnt 1
	throw new Error 'ParamName expected string' unless typeof paramName is 'string'
	params = @[ROUTE_PARAM]
	if params then params.hasOwnProperty(paramName) else false

###*
 * Remove param handler from this route
 * @param {string} paramName - param name
###
Route::rmParam = (paramName)->
	throw new Error 'Illegal arguments' if arguments.length isnt 1
	throw new Error 'ParamName expected string' unless typeof paramName is 'string'
	params = @[ROUTE_PARAM]
	if params
		delete params[paramName]
		unless Object.keys(params).length
			@[ROUTE_PARAM]	= undefined


###*
 * get regex related to a param
 * @private
###
Route::_paramToRegex= (paramName)->
	@[ROUTE_PARAM]?[paramName]?.r || VOID_REGEX
