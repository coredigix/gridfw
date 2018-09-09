###*
 * Param manager
 * (Affect both Path params and query params)
 * @author COREDIGIX
###

ROUTE_PARAM_REGEXES = Symbol 'Route params'
ROUTE_PARAM_HANDLERS = Symbol 'Route params'

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
	paramRegexes = @[ROUTE_PARAM_REGEXES] ?= {}
	paramHandlers = @[ROUTE_PARAM_HANDLERS] ?= {}
	throw new Error "Param <#{paramName}> already set for this route" if paramRegexes[paramName]?
	switch arguments.length
		when 2
			throw new Error 'Handler required' unless typeof regex is 'function'
			handler = regex
			paramRegexes[paramName] = VOID_REGEX
		when 3
			throw new Error 'Uncorrect regex' unless regex and typeof regex.test is 'function'
			throw new Error 'Handler expected function' unless typeof handler is 'function'
			paramRegexes[paramName] = regex
		else
			throw new Error 'Illegal arguments'
	# add handler
	throw new Error 'Handler expect exactly two parameters (ctx, data)' unless handler.length is 2
	paramHandlers[paramName] = handler
	# chain
	this
###*
 * Check if this route has param
 * @param {string} paramName - param name
###
Route::hasParam = (paramName)->
	throw new Error 'Illegal arguments' if arguments.length isnt 1
	throw new Error 'ParamName expected string' unless typeof paramName is 'string'
	params = @[ROUTE_PARAM_REGEXES]
	if params then params.hasOwnProperty(paramName) else false

###*
 * Remove param handler from this route
 * @param {string} paramName - param name
###
Route::rmParam = (paramName)->
	throw new Error 'Illegal arguments' if arguments.length isnt 1
	throw new Error 'ParamName expected string' unless typeof paramName is 'string'
	paramRegexes = @[ROUTE_PARAM_REGEXES]
	paramHandlers = @[ROUTE_PARAM_HANDLERS]
	if paramRegexes
		delete paramRegexes[paramName]
		delete paramHandlers[paramName]
		unless Object.keys(paramRegexes).length
			@[ROUTE_PARAM_REGEXES]	= undefined
			@[ROUTE_PARAM_HANDLERS]	= undefined


###*
 * get regex related to a param
 * @private
###
Route::_paramToRegex= (paramName)->
	@[ROUTE_PARAM_REGEXES]?[paramName] || VOID_REGEX
