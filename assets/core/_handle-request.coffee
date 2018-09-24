###*
 * Handle requests
 * @param {HTTP_REQUEST} req - request
 * @param {HTTP_RESPONSE} ctx - the app context
 * @example
 * app.handle(req, res)
###
EMPTY_OBJ = Object.freeze {} # for performance reason, use this for empty params and query
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
		# add to context
		Object.defineProperties ctx,
			app: value: this
			req: value: req
			res: value: ctx
			url: value: req.url
			# url
			path: value: rawPath
			rawQuery: value: rawUrlQuery
		# add to request
		Object.defineProperties req,
			res: value: ctx
			ctx: value: ctx
			req: value: req
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
			 * pm: param resolvers
			###
			routeDescriptor = @_find rawPath, req.method
			# put in cache (production mode)
			routeCache.set rawPath, routeDescriptor if routeCache?
		# resolve params
		rawParams		= routeDescriptor.p
		paramResolvers	= routeDescriptor.pm
		if rawParams
			params = Object.create rawParams
			if paramResolvers
				for k, v of rawParams
					if typeof paramResolvers[k] is 'function'
						params[k] = await paramResolvers[k] this, v
		else
			rawParams = params = EMPTY_OBJ
		# resolve query params
		if rawUrlQuery
			queryParams = @queryParser rawUrlQuery
			if paramResolvers
				for k, v of queryParams
					if typeof paramResolvers[k] is 'function'
						queryParams[k] = await paramResolvers[k] this, v
		else
			queryParams = EMPTY_OBJ
		# # add to context
		Object.defineProperties ctx,
			query: value: queryParams
			# current route
			route: value: routeDescriptor.n
			rawParams: value: rawParams
			params: value: params
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
			resp = await handler ctx
			# if a value is returned
			unless ctx.finished or resp in [undefined, ctx]
				# if view resolver
				if typeof resp is 'string'
					ctx.render resp
				else
					ctx.send resp
		# execute post handlers
		if routeDescriptor.ps.length
			for handler in routeDescriptor.ps
				await handler ctx
	catch e
		try
			# user defined error handlers
			if routeDescriptor and routeDescriptor.e.length
				for handler in routeDescriptor.e
					await handler ctx, e
			# else
			else
				_processUncaughtRequestErrors this, ctx, e
		catch err
			_processUncaughtRequestErrors this, ctx, err
	return
	