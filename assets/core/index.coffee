'use strict'

http = require 'http'
path = require 'path'
fs	 = require 'mz/fs'
LRUCache	= require 'lru-cache'

PKG			= require '../../package.json'
Context		= require '../context'
LoggerFactory= require '../lib/logger'
GError		= require '../lib/error'

RouteMapper	= require '../router/route-mapper'
RouteNode	= require '../router/route-node'

fastDecode	= require 'fast-decode-uri-component'
encodeurl	= require 'encodeurl'

compareVersion = require 'compare-versions'

# default config
CONFIG = require './config'
DEFAULT_SETTINGS = cfg.config
DEFAULT_SETTINGS_KIES= cfg.kies
CHECK_SETTINGS= cfg.check


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
PLUGINS			= Symbol 'Plugins'

# flags
IS_ENABLED				= Symbol 'is enabled'
IS_LOADED				= Symbol 'is loaded' # is app loaded (all settings are set)
APP_STARTING_PROMISE	= Symbol 'app starting promise' # loading promise
REQ_HANDLER				= Symbol 'request handler'


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
		# locals
		locals = Object.create null,
			app: value: app
		# create context
		#TODO clone context and response
		# define properties
		Object.defineProperties app,
			# flags
			[REQ_HANDLER]: UNDEFINED
			[IS_ENABLED]: UNDEFINED
			[IS_LOADED]: UNDEFINED
			[APP_STARTING_PROMISE]: UNDEFINED
			# mode
			mode: get: -> @s[<%= settings.mode ?>]
			### App connection ###
			server: UNDEFINED
			protocol: UNDEFINED
			host: UNDEFINED
			port: UNDEFINED
			path: UNDEFINED
			# settings
			s: value: Array DEFAULT_SETTINGS.length
			# locals
			locals: value: locals
			data: value: locals
			# root RouteMapper
			m: value: new RouteMapper app, '/'
			# global param resolvers
			$: value: Object.create null
			# view cache
			[VIEW_CACHE]: UNDEFINED
			# Routes
			[ALL_ROUTES]: value: Object.create null
			[STATIC_ROUTES]: value: Object.create null
			[DYNAMIC_ROUTES]: value: Object.create null
			#TODO check if app cache optimise performance for 20 routes
			# [CACHED_ROUTES]: new LRUCache max: options.routeCache || DEFAULT_SETTINGS.routeCacheMax
			# plugins
			[PLUGINS]: value: Object.create null
		# process off listener
		exitCb = app._exitCb = (code)=> _exitingProcess app, code
		process.on 'SIGINT', exitCb
		process.on 'SIGTERM', exitCb
		process.on 'beforeExit', exitCb
		# enable settings
		await @reload options
		# print welcome message
		_console_welcome this
		return


# getters
Object.defineProperties GridFW.prototype,
	### if the server is listening ###
	listening: get: -> @server?.listening || false
	# framework version
	version: value: PKG.version

# consts
Object.defineProperties GridFW,
	# consts
	DEV_MODE: value: <%= app.DEV %>
	PROD_MODE: value: <%= app.PROD %>
	# param
	PATH_PARAM : value: <%= app.PATH_PARAM %>
	QUERY_PARAM: value: <%= app.QUERY_PARAM %>
	# framework version
	version: value: PKG.version

#=include index/_errors.coffee
#=include index/_log_welcome.coffee
#=include router/_index.coffee
#=include index/_handle-request.coffee
#=include index/_uncaught-request-error.coffee
#=include index/_render.coffee
#=include index/_listen.coffee
#=include index/_close.coffee
#=include index/_query-parser.coffee
#=include index/_plugin.coffee
#=include index/_reload.coffee

# exports
module.exports = GridFW