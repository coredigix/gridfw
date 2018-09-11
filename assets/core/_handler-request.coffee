###*
 * Handle requests
 * @param {HTTP_REQUEST} req - request
 * @param {HTTP_RESPONSE} ctx - the app context
 * @example
 * app.handle(req, res)
###
GridFW::handle= (req, ctx)->
	try
		# settings
		settings = @settings
		useCache = settings.routeCache
		# path
		url = req.url
		idx = url.indexOf '?'
		if idx is -1
			rawPath = url
			rawUrlQuery = null
		else
			rawPath = url.substr 0, idx
			rawUrlQuery = url.substr idx + 1
		# get the route
		# trailing slash
		unless rawPath is '/'
			switch settings.trailingSlash
				# redirect
				when 0
					if rawPath.endsWith '/'
						rawPath = rawPath.slice 0, -1
						rawPath += '?' + rawUrlQuery if rawUrlQuery
						ctx.permanentRedirect rawPath
						return # ends request
				# ignore
				when off
					if rawPath.endsWith '/'
						rawPath = rawPath.slice 0, -1
				# when on: keep it
			# ignore case
			if settings.routeIgnoreCase
				rawPath = rawPath.toLowerCase()
		# get from cache
		routeCache = @[ROUTE_CACHE]
		routeDescriptor = routeCache and routeCache.get rawPath
		# lookup for route
		unless routeDescriptor
			###*
			 * @throws {404} If route not found
			 * n: node
			 * p: params
			 * m: middlewares queu, sync mode only
			 * e: error handlers
			 * h: handlers
			 * pr:pre-process
			 * ps:post-process
			###
			routeDescriptor = @_find rawPath
			# put in cache (production mode)
			routeCache.set rawPath, routeDescriptor if routeCache?
		# add to context
		Object.defineProperties ctx,
			app: value: this
			req: value: req
			res: value: ctx
			# url
			path: value: rawPath
			rawQuery: value: rawUrlQuery
			# current route
			route: routeDescriptor.n
			rawParams: routeDescriptor.p
			# posible error
			error: UNDEFINED_
		# execute middlewares
		if routeDescriptor.m.length
			for handler in routeDescriptor.m
				await handler ctx
		# execute pre-processes
		if routeDescriptor.pr.length
			for handler in routeDescriptor.pr
				await handler ctx
		# execute handlers
		for handler in routeDescriptor.h
			await handler ctx
		# execute post handlers
		if routeDescriptor.ps.length
			for handler in routeDescriptor.ps
				await handler ctx
	catch e
		try
			ctx.error = e
			# user defined error handlers
			if routeDescriptor and routeDescriptor.e.length
				for handler in routeDescriptor.e
					await handler ctx
			# else
			else
				_processUncaughtRequestErrors this, ctx, e
		catch err
			_processUncaughtRequestErrors this, ctx, err
	