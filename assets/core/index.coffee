
path = require 'path'
fs	 = require 'mz/fs'
cache = require '../lib/cache'

VIEW_CACHE = Symbol 'view cache'

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
		# attributes
		Object.defineProperties this,
			### locals ###
			locals: value: {}
			### render function ###
			render: value: renderTemplates
			### settings ###
			_settings: value: settings
			### view cache ###
			[VIEW_CACHE]: value: new cache
				ttl: settings.viewCacheTTL
				maxLength: settings.viewCacheMax



#=include _settings.coffee
#=include _render.coffee