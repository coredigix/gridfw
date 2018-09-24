'use strict'
http = require 'http'
path = require 'path'
fs	 = require 'mz/fs'
LRUCache	= require 'lru-cache'

Context		= require '../context'
LoggerFactory= require '../lib/logger'

VIEW_CACHE = Symbol 'view cache'
ROUTE_CACHE = Symbol 'route cache'

Route		= require '../router/route'

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
		Object.setPrototypeOf settings, DEFAULT_SETTINGS
		# view cache
		if settings.viewCache
			viewCache = new LRUCache
				max: settings.viewCacheMax
		# routing cache
		if settings.routeCache
			routeCache = new LRUCache
				max: settings.routeCacheMax
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
			### settings ###
			settings: value: settings
			### view cache, enable it depending  ###
			[VIEW_CACHE]: value: viewCache
			### route cache ###
			[ROUTE_CACHE]: value: routeCache

		# add log support
		logOptions = level: @settings.logLevel
		LoggerFactory GridFW.prototype, logOptions
		LoggerFactory Context.prototype, logOptions


#=include _settings.coffee
#=include _render.coffee
#=include _handle-request.coffee
#=include _listen.coffee
#=include _errors.coffee

# getters
Object.defineProperties GridFW.prototype,
	### if the server is listening ###
	listening: get: -> @server?.listening || false

# show welcome message if called directly
if require.main is module
	console.error "GridFW>> Could not be self run, See @Doc for more info, or run example"

# print console welcome message
_console_welcome = (app) ->
	console.log "\e[94m┌─────────────────────────────────────────────────────────────────────────────────────────┐"
	# if dev mode or procution
	if app.mode is 'prod'
		console.warn "GridFW>> ✔ Production Mode"
	else
		console.warn "\e[93GridFW>> Developpement Mode\n\t⚠ Do not forget to enable production mode to boost performance\e[0m\e[94m"
	# server params
	console.log """
	GridFW>> Running The server As:
	\t✔︎ Name: #{app.name}
	\t✔︎ Port: #{app.port}
	\t✔︎ Path: #{app.path}
	\t✔︎ Host: #{app.host}
	\t✔︎ Autor: #{app.settings.autor}
	\t✔︎ Admin Email: #{app.settings.adminEmail}
	"""
	console.log "└─────────────────────────────────────────────────────────────────────────────────────────┘\e[0m"

# exports
module.exports = GridFW