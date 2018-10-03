'use strict'

http = require 'http'
path = require 'path'
fs	 = require 'mz/fs'
LRUCache	= require 'lru-cache'

Context		= require '../context'
LoggerFactory= require '../lib/logger'
GError		= require '../lib/error'

RouteMapper	= require '../router/route-mapper'
RouteNode	= require '../router/route-node'

fastDecode	= require 'fast-decode-uri-component'
encodeurl	= require 'encodeurl'

# default config
cfg = require './config'
DEFAULT_SETTINGS = cfg.config
DEFAULT_SETTINGS_KIES= cfg.kies


# create empty attribute for performance
UNDEFINED=
	value: undefined
	configurable: true
	writable: true
EMPTY_OBJ = Object.freeze Object.create null
# void function (do not change)
# VOID_FX = ->

# View cache
VIEW_CACHE = Symbol 'View cache'
# Routes
ALL_ROUTES	= Symbol 'All routes'
STATIC_ROUTES	= Symbol 'Static routes'
DYNAMIC_ROUTES	= Symbol 'Dynamic routes'
CACHED_ROUTES	= Symbol 'Cached_routes'


# default used protocol when non specified, in [http, https, http2]
DEFAULT_PROTOCOL = 'http'

# consts
HTTP_METHODS = http.METHODS
HTTP_SUPPORTED_METHODS= [
	'all' # all methods
	'get'
	'head'
	'post'
	'put'
	'patch'
	'delete'
]

class GridFW
	###*
	 * 
	 * @param  {string} options.mode - execution mode: dev or prod
	 * @param  {number} options.routeCache - Route cache size
	 * @param  {[type]} options [description]
	 * @return {[type]}         [description]
	###
	constructor: (options)->
		# load options from file path
		unless options
			options = Object.create null
		else if typeof options is 'string'
			options = require options
		# check
		throw new Error "Illegal mode: #{options.mode}, please use: dev or prod" if options.mode and options.mode not in ['dev', 'prod']
		throw new Error 'options.routeCache expected number' if options.routeCache and not Number.isSafeInteger options.routeCache
		# mode
		mode = DEFAULT_SETTINGS_KIES[options.mode] || <%= app.DEV %>
		# locals
		locals = Object.create null,
			app: value: this
		# settings
		settings = DEFAULT_SETTINGS.slice 0
		# define properties
		Object.defineProperties this,
			# mode
			mode: value: mode
			### App connection ###
			server: UNDEFINED
			protocol: UNDEFINED
			host: UNDEFINED
			port: UNDEFINED
			path: UNDEFINED
			# settings
			s: value: settings
			# locals
			locals: value: locals
			data: value: locals
			# root RouteMapper
			m: value: new RouteMapper this, '/'
			# global param resolvers
			$: value: Object.create null
			# view cache
			[VIEW_CACHE]: UNDEFINED
			# Routes
			[ALL_ROUTES]: value: Object.create null
			[STATIC_ROUTES]: value: Object.create null
			[DYNAMIC_ROUTES]: value: Object.create null
			#TODO check if this cache optimise performance for 20 routes
			# [CACHED_ROUTES]: new LRUCache max: options.routeCache || DEFAULT_SETTINGS.routeCacheMax
		# resolve settings based on current mode
		for v, k in settings
			if typeof v is 'function'
				settings[k] = v this, mode
		# add log support
		logOptions = level: @s.logLevel
		LoggerFactory GridFW.prototype, logOptions
		LoggerFactory Context.prototype, logOptions
		# if use view cache
		if settings[<%= settings.viewCache %>]
			@[VIEW_CACHE] = new LRUCache
				max: settings[<%= settings.viewCacheMax %>]
		# do some process before exiting process
		# process off listener
		exitCb = @_exitCb = (code)=> _exitingProcess this, code
		process.on 'SIGINT', exitCb
		process.on 'SIGTERM', exitCb
		process.on 'beforeExit', exitCb
		
		# print welcome message
		_console_welcome this


# getters
Object.defineProperties GridFW.prototype,
	### if the server is listening ###
	listening: get: -> @server?.listening || false
	DEV_MODE: value: <%= app.DEV %>
	PROD_MODE: value: <%= app.PROD %>

#=include _errors.coffee
#=include _log_welcome.coffee
#=include router/_index.coffee
#=include _handle-request.coffee
#=include _uncaught-request-error.coffee
#=include _render.coffee
#=include _listen.coffee
#=include _close.coffee
#=include _query-parser.coffee

# exports
module.exports = GridFW