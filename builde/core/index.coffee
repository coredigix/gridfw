http = require 'http'
path = require 'path'
fs	 = require 'mz/fs'
LRUCache	= require 'lru-native'

Context		= require '../context'
LoggerFactory= require '../lib/logger'

VIEW_CACHE = Symbol 'view cache'
ROUTE_CACHE = Symbol 'route cache'

# create empty attribute for performance
UNDEFINED_=
	value: undefined
	configurable: true
	writable: true

###*
 * framework core
###

class GridFW extends Route
	###*
	 * @param  {number} settings [description]
	 * @return {[type]}          [description]
	###
	constructor: (settings)->
		# super
		super()
		# settings
		settings ?= {}
		Object.setPrototypeOf settings, GridFW::_settings
		# view cache
		if settings.viewCache
			viewCache = new LRUCache
				maxElements: settings.viewCacheMax
		# routing cache
		if settings.routeCache
			routeCache = new LRUCache
				maxElements: settings.routeCacheMax
		# attributes
		Object.defineProperties this,
			### auto reference ###
			app: value: this
			### app port ###
			port: UNDEFINED_
			host: UNDEFINED_
			### app basic path ###
			path: UNDEFINED_
			### underline server###
			server: UNDEFINED_
			### locals ###
			locals: value: {}
			### render function ###
			render: value: renderTemplates
			### settings ###
			_settings: value: settings
			### view cache, enable it depending  ###
			[VIEW_CACHE]: value: viewCache
			### route cache ###
			[ROUTE_CACHE]: value: routeCache


# add log support
LoggerFactory GridFW.prototype




###*




 *




 * Events




 * 		- routeAdded




 * 		- routeRemoved




 * 		- routeHandlerOn




 * 		- routeHandlerOff




###









###*




 * default settings




###




GridFW::_settings =




	###




	use cache for routes, this make it faster




	to not look for a route each time




	(route lookup is already optimized by using tree access)




	@default on in production mode




	###




	routeCache: off




	routeCacheMax: 50 # route cache max entries




	###*




	 * Ignore trailing slashes




	 * 		off	: ignore




	 * 		0	: ignore, make redirect when someone ask this URL




	 * 		on	: 'keep it'




	###




	trailingSlash: 0




	###*




	 * when true, ignore path case




	 * @type {boolean}




	###




	routeIgnoreCase: on




	###*




	 * render templates




	###




	engines:




		'.pug': require 'pug'




	### view folders ###




	views: ['views']




	###*




	 * view Cache




	 * @when off: disable cache




	 * @when on: enable cache for ever




	 * @type {boolean}




	###




	viewCache: off




	viewCacheMax: 50 # view cache max entries




	###




	render pretty html




	@default on in production mode, off otherwise




	###




	renderPretty: on




	###*




	 * Trust proxy




	###




	trustProxy: on




	trustProxyFx: -> on # compiled version




	###*




	 * Render JSON and XML




	 * @default off on production mode




	###




	jsonPretty: on









	###




	Cache: generate ETag




	@param {Buffer} data - data to generate ETag




	###




	etag: (data) ->




		#TODO




		''

###*
 * Render HTML template
 * @param {string} path path to template
 * @param {Object} Locals [description]
 * @return {Promise<string>} will return the rendered HTML
###
GridFW::render= (templatePath, locals)->
	Object.setPrototypeOf locals, @locals
	@_render path, locals

###*
 * Execute render
 * @private
 * @param  {srting} path - path to resolve template
 * @param  {Object} locals   - locals
 * @return {Promise<html>}          return compiled HTML
###
GridFW::_render = (templatePath, locals)->
	settings = @_settings
	useCache = settings.viewCache
	# resolve file content
	throw new Error 'path expected string' unless typeof templatePath is 'string'
	# check in cache
	renderFx	= useCache && @[VIEW_CACHE].get templatePath
	unless renderFx 
		# if add index
		filePath = if templatePath.endsWith '/' then templatePath += 'index' else templatePath 
			
		# get file string
		engines = settings.engines
		# absolute path
		if path.isAbsolute filePath
			template = _loadTemplateFileContent settings.engines, filePath
		# relative to views
		else
			for v in settings.views
				template = _loadTemplateFileContent settings.engines, (path.join v, filePath)
				if template.content?
					break
		unless template.content?
			throw 404 # page not found

		# compile template
		renderFx = template.module.compile template.content,
			pretty: settings.renderPretty
		# cache
		if useCache
			@[VIEW_CACHE].set templatePath, renderFx
	# compile render fx
	renderFx locals

###*
 * Load template file content
 * @type {[type]}
###
_loadTemplateFileContent= (engines, filePath) ->
	result=
		content: null
		module: null
	for ext, module of engines
		try
			result.content	= await fs.readFile if filePath.endsWith ext then filePath else filePath + ext
			result.module	= module
			break
		catch err
			if err and err.code is 'ENOENT'
				# file not found, go to next file
			else
				throw err	
	result
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
			routeDescriptor = @_find rawPath
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
		#TODO resolve values
		# add to current object for future use
		Object.defineProperty this, 'query', value: query
		# return value
		query
		# add to context
		Object.defineProperties ctx,
			app: value: this
			req: value: req
			res: value: ctx
			url: value: req.url
			# url
			path: value: rawPath
			rawQuery: value: rawUrlQuery
			query: value: queryParams
			# current route
			route: value: routeDescriptor.n
			rawParams: value: rawParams
			params: value: params
			# posible error
			error: UNDEFINED_
		# add to request
		Object.defineProperties req,
			res: value: ctx
			ctx: value: ctx
			req: value: req
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
			if resp isnt undefined
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
	return
	

# default used protocol when non specified, in [http, https, http2]
DEFAULT_PROTOCOL = 'http'

###*
 * Listen([port], options)
 * @optional @param {number} options.port - listening port @default to arbitrary generated one
 * @optional @param {string} options.protocol - if use 'http' or 'https' or 'http2' @default to http
 * @example
 * listen() # listen on arbitrary port
 * listen(3000) # listen on port 3000
 * listen
 * 		port: 3000
 * 		protocol: 'http' or 'https' or 'http2'
###
GridFW::listen= (options)->
	new Promise (res, rej)->
		# options
		unless options
			options = {}
		else if typeof options is 'number'
			options= port: options
		else if typeof options isnt 'object'
			throw new Error 'Illegal argument'
		# get server factory
		servFacto = options.protocol
		if servFacto
			throw new Error "Protocol expected string" unless typeof servFacto is 'string'
			servFacto = SERVER_LISTENING_PROTOCOLS[servFacto.toLowerCase()]
			throw new Error "Unsupported protocol: #{options.protocol}" unless servFacto
		else
			servFacto = SERVER_LISTENING_PROTOCOLS[DEFAULT_PROTOCOL]
		# create server
		server = servFacto options, this


### make server listening depending on the used protocol ###
SERVER_LISTENING_PROTOCOLS=
	http: (options, app)->
		server = app.server = http.createServer
			IncomingMessage : Context.Request
			ServerResponse : Context
			,
			app.handle.bind app
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
# 404: not found

_processUncaughtRequestErrors = (app, ctx, error)->
	console.error 'Error>> Error handling isn\'t implemented!'
	if typeof error is 'number'
		switch error
			# page not found
			when 404
				console.error '404>> page not found!'
			else
				console.error 'Error>> ', error
	else
		console.error 'Error>> ', error
