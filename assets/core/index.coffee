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
PLUGINS			= Symbol 'Plugins'


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
		# configure
		_configApp this, options
		# print welcome message
		_console_welcome this


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

#=include _errors.coffee
#=include _log_welcome.coffee
#=include router/_index.coffee
#=include _handle-request.coffee
#=include _uncaught-request-error.coffee
#=include _render.coffee
#=include _listen.coffee
#=include _close.coffee
#=include _query-parser.coffee
#=include _plugin.coffee
#=include _configure-app.coffee

# exports
module.exports = GridFW