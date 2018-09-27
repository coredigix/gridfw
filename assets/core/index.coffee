'use strict'

http = require 'http'
path = require 'path'
fs	 = require 'mz/fs'
LRUCache	= require 'lru-cache'

Context		= require '../context'
LoggerFactory= require '../lib/logger'
GError		= require '../lib/error'

VIEW_CACHE = Symbol 'view cache'
ROUTE_CACHE = Symbol 'route cache'

Route		= require '../router/route'

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

# view cache
VIEW_CACHE = Symbol 'View cache'

class GridFW
	constructor: (options)->
		# 
		throw new Error "Illegal mode: #{options.mode}" if options.mode and options.mode not in ['dev', 'prod']
		# settings
		settings = Object.create DEFAULT_SETTINGS
		# locals
		locals =
			_app: this
		# define properties
		Object.defineProperties
			# mode
			mode: value: options.mode || 'dev'
			### App connection ###
			server: UNDEFINED_
			protocol: UNDEFINED_
			host: UNDEFINED_
			port: UNDEFINED_
			path: UNDEFINED_
			# settings
			s: value: settings
			settings: value: settings
			# locals
			locals: value: locals
			data: value: locals
			# view cache
			[VIEW_CACHE]: UNDEFINED
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
#=include log_welcome.coffee

# exports
module.exports = GridFW