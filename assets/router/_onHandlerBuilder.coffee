###*
 * build handler for "Router::on" method
 * @example
 * router.on('GET', '/route')
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
		@promise = []
		# in case of global handlers (post process and error handler)
		@finally = []
		@catch = []
	###*
	 * then
	###
	then: (handler, errHandler)->
		throw new Error 'Handler expected function' unless !handler or typeof handler is 'function'
		throw new Error 'Error Handler expected function' unless !errHandler or typeof errHandler is 'function'
		# expect no global error handler or post handler is added
		throw new Error 'Illegal use of promise handlers, please see documentation' if @finally.length or @catch.length
		# append as promise or error handler
		@promise.push [handler, errHandler]
		# return "this" to enable chain
		this
	###*
	 * catch
	 * Add "Promise catch" handler or "error handling" handler
	 * @param {function} errHandler - Error handler
	###
	catch: (errHandler)->
		throw new Error 'Handler expected function' unless typeof handler is 'function'
		if @promise.length
			@then null, errHandler
		else
			@catch.push errHandler
	###*
	 * finally
	 * Add promise finally or post process handler
	 * @param {function} handler - Promise finally or post process handler
	###
	finally: (handler)->
		throw new Error 'Handler expected function' unless typeof handler is 'function'
		if @promise.length
			@then handler, handler
		else
			@finally.push handler

	###*
	 * Build handler and returns to parent object
	 * @return {Object} parent object
	###
	build: ->
		# return parent object
		@_parent
###*
 * create route and return to parent object
###
Object.defineProperty _OnHandlerBuilder, 'end', get: -> @build()