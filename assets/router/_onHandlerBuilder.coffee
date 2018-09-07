###*
 * build handler for "Router::on" method
 * @private
 * @example
 * router.on('GET', '/route')
 * 		.use(middleware)
 * 		.then(handler)
 * 		.then(handler, errHandler)
 * 		.catch(errHandler)
 * 		.finally(finalHandler)
 * router.on('GET', '/route')
 * 		.catch(errHandler)
 * 		.finally()
###
class _OnHandlerBuilder
	###*
	 * @constructor
	 * @param  {Object} _parent - parent object (router)
	 * @param  {[type]} cb  - callback, when route created
	###
	constructor: (@_parent ,@cb)->
		# store promise handlers in case of promise architecture
		@promiseQueu = []
		# in case of global handlers (post process and error handler)
		@postHandlers	= []
		@preHandlers	= []
		@errHandlers	= []
		# middlewares
		@middlewares	= []
		# fire build if not explicitly called
		@_buildTimeout = setTimeout (=> do @build), 0
		return
	###*
	 * Build handler and returns to parent object
	 * @return {Object} parent object
	###
	build: ->
		# cancel auto build
		clearTimeout @_buildTimeout
		# send response to parent object
		@cb this
		# return parent object
		@_parent
	###*
	 * then
	 * @example
	 * .then (ctx)->
	 * .then ( (ctx)-> ), ( (ctx{error})-> )
	###
	then: (handler, errHandler)->
		throw new Error 'Handler expected function' unless !handler or typeof handler is 'function'
		throw new Error 'Error Handler expected function' unless !errHandler or typeof errHandler is 'function'
		# expect no global error handler or post handler is added
		throw new Error 'Illegal use of promise handlers, please see documentation' if @finally.length or @catch.length
		# append as promise or error handler
		@promiseQueu.push [handler, errHandler]
		# return "this" to enable chain
		this
	###*
	 * catch
	 * Add "Promise catch" handler or "error handling" handler
	 * @param {function} errHandler - Error handler
	 * @example
	 * .catch (ctx{error})->
	###
	catch: (errHandler)->
		throw new Error 'Handler expected function' unless typeof handler is 'function'
		if @promise.length
			@then null, errHandler
		else
			@errHandlers.push errHandler
		# return "this" for chain
		this
	###*
	 * finally
	 * Add promise finally or post process handler
	 * @param {function} handler - Promise finally or post process handler
	 * @example
	 * .finally (ctx)->
	###
	finally: (handler)->
		throw new Error 'Handler expected function' unless typeof handler is 'function'
		if @promise.length
			@then handler, handler
		else
			@postHandlers.push handler
		# return "this" for chain
		this
	###*
	 * middlewares
	 * @example
	 * .use (ctx)->
	 * .use (ctx, res, next)-> # express compatible format, best to use it only with express middlewares
	 * .use (err, ctx, res, next)-> # express error handler compatible format, best to use it only with express middlewares
	###
	use: (middleware)->
		throw new Error 'middleware expected function' unless typeof middleware is 'function'
		# Gridfw format
		if middleware.length is 1
			@middlewares.push middleware
		# compatibility with express
		else if middleware.length is 3
			@middlewares.push (ctx)->
				new Promise (resolve, reject)->
					middleware ctx, ctx.res, (err)->
						if err then reject err
						else resolve()
		# express error handler
		#TODO check if this error handler is compatible
		else if middleware.length is 4
			@errHandlers.push (ctx)->
				new Promise (resolve, reject)->
					middleware ctx.error, ctx, ctx.res, (err)->
						if err then reject err
						else resolve()
		# Uncknown format
		else
			throw new Error 'Illegal middleware format'
		# return "this" for chain
		this
	###*
	 * preHandlers
	 * @example
	 * .filter (ctx)->
	###
	filter: (handler)->
		throw new Error 'Filter expected function' unless typeof handler is 'function'
		@preHandlers.push handler
		# return "this" for chain
		this

###*
 * create route and return to parent object
###
Object.defineProperty _OnHandlerBuilder, 'end', get: -> @build()