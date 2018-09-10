
path = require 'path'
fs	 = require 'mz/fs'

###*
 * framework core
###

class GridFW extends Route
	constructor: ()->
		# attributes
		Object.defineProperties this,
			### locals ###
			locals: value: {}
			### render function ###
			render: value: renderTemplates
			### settings ###
			_settings: value: Object.create GridFW::_settings
			### view cache ###
			_viewCache: value: {}



#=include _settings.coffee
#=include _render.coffee