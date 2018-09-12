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




#=include _settings.coffee
#=include _render.coffee
#=include _handle-request.coffee
#=include _listen.coffee
#=include _errors.coffee
