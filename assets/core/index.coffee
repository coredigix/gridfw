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

# 
APP_MODES = [
	'DEV' # developpement
	'PROD' # production
]

# create empty attribute for performance
UNDEFINED=
	value: undefined
	configurable: true
	writable: true

# View cache
VIEW_CACHE = Symbol 'View cache'
# Routes
ALL_ROUTES	= Symbol 'All routes'
STATIC_ROUTES	= Symbol 'Fixed routes'
CACHED_ROUTES	= Symbol 'Cached_routes'
REGEX_ROUTES	= Symbol 'Regex routes'


# consts
HTTP_METHODS = http.METHODS

class GridFW
	###*
	 * 
	 * @param  {string} options.mode - execution mode: dev or prod
	 * @param  {number} options.routeCache - Route cache size
	 * @param  {[type]} options [description]
	 * @return {[type]}         [description]
	###
	constructor: (options)->
		# 
		throw new Error "Illegal mode: #{options.mode}, please use: dev or prod" if options.mode and options.mode not in ['dev', 'prod']
		throw new Errir 'options.routeCache expected number' if options.routeCache and not Number.isSafeInteger options.routeCache
		# mode
		mode = if options.mode is 'prod' then <?= app.DEV ?> else <?= app.PROD ?>
		# locals
		locals = Object.create null,
			_app: value: this
		# settings
		settings = DEFAULT_SETTINGS.slice 0
		# define properties
		Object.defineProperties this,
			# mode
			mode: value: mode
			### App connection ###
			server: UNDEFINED_
			protocol: UNDEFINED_
			host: UNDEFINED_
			port: UNDEFINED_
			path: UNDEFINED_
			# settings
			s: value: settings
			# locals
			locals: value: locals
			data: value: locals
			# param handlers
			$: value: Object.create null
			# view cache
			[VIEW_CACHE]: UNDEFINED
			# Routes
			[ALL_ROUTES]: Object.create null
			[STATIC_ROUTES]: Object.create null
			#TODO check if this cache optimise performance for 20 routes
			# [CACHED_ROUTES]: new LRUCache max: options.routeCache || DEFAULT_SETTINGS.routeCacheMax
			[REGEX_ROUTES]: []
		# resolve settings based on current mode
		for v, k in settings
			if typeof v is 'function'
				settings[k] = v this, mode
		# add log support
		logOptions = level: @s.logLevel
		LoggerFactory GridFW.prototype, logOptions
		LoggerFactory Context.prototype, logOptions


# getters
Object.defineProperties GridFW.prototype,
	### if the server is listening ###
	listening: get: -> @server?.listening || false

# default mode (developpement)
GridFW::mode = 'dev'

#=include _settings.coffee
#=include _log_welcome.coffee
#=include router/_index.coffee

# exports
module.exports = GridFW