###
# Uncaugth Request Errors
###

_uncaughtRequestErrorHandler = (err, ctx, app)->
	settings = app.s

	if err
		if typeof err.code is 'number'
		else 
			err = new GError 500, err.message, err
	else
		err = new GError 520, 'Unknown Error!'

	# everything isnt 404 is a fatal error
	ctx.fatalError 'UNCAUGHT_ERROR', err unless err.code is 404

	# render error
	unless ctx.finished
		# keys
		if app.mode is <%= app.DEV %>
			errorKey  =  'd' + err.code
			defErrKey = 'd500'
		else
			errorKey  = err.code
			defErrKey = '500'
		# render
		ctx.statusCode = err.code unless ctx.headersSent
		errorTemplates = settings[<%= settings.errorTemplates %>]
		ctx.send errorTemplates[errorKey] || errorTemplates[defErrKey], ctx
	return
