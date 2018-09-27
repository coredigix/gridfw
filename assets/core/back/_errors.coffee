# ###
# App Errors
# We didnt extends "Error" for performance
# ###

# class GridError
# 	constructor: (code= -1, message)->
# 		if arguments.length is 1
# 			message = _mapCodes[code]
# 		super message
# 		Object.defineProperties this,
# 			code: value: code

# 	# const
# 	@NOT_FOUND: 404

# ### get message from code ###
# _mapCodes=
# 	'404': 'Not found'


# ### not found eror ###
# class NotFoundError extends GridError
# 	constructor: (path, message)->
# 		super GridError.NOT_FOUND, message
# 		Object.defineProperties this,
# 			path: value: path
# ------------------
# 

_processUncaughtRequestErrors = (app, ctx, error)->
	console.error 'Error>> Error handling isn\'t implemented!'
	errorSettings = app.settings.errors


	# log this error
	if error is 404 # path not found
		ctx.debug 'Page not found', ctx.url
		tempate = errorSettings[404]
		status = 404
	else
		# error
		unless error
			error = new GError 520, 'Unknown Error!'
		else unless typeof error is 'object'
			error= new GError 500, error
		ctx.fatalError 'UNCAUGHT_ERROR', error
		status = error.code || 500
		tempate = errorSettings[status] || errorSettings[500]


	# render view
	unless ctx.finished
		ctx.statusCode = error.code or 500
		await ctx.render tempate, error

	# send response
	unless ctx.headersSent
		ctx.statusCode = 500
	# ctx.send 'Internal error'
	ctx.end()
