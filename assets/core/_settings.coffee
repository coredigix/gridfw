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
	 * @when number: cache last access timeout
	 * @type {boolean}
	 * @default 3,600,000 in production mode (keep it for one houre), false otherwise
	###
	viewCache: off
	###
	render pretty html
	@default on in production mode, off otherwise
	###
	renderPretty: on
	###*
	 * Trust proxy
	###
	trustProxy: on