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