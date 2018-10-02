# App consts
exports.app = app =
	DEV: 0
	PROD: 1
### this file contains app default settings ###
exports.settings=
	####<========================== App Id =============================>####
	### name ###
	name: 'GridFW'
	###* Author ###
	author: 'GridFW@coredigix'
	###* Admin Email ###
	email: 'contact@coredigix.com'

	####<========================== LOG =============================>####
	###*
	 * log level
	 * @default prod: 'info', dev: 'debug'
	###
	logLevel: 'debug'

	####<========================== Router =============================>####
	###*
	 * Route cache
	###
	routeCacheMax: 50
	###*
	 * Ignore trailing slashes
	 * 		off	: ignore
	 * 		0	: ignore, make redirect when someone asks for this URL
	 * 		on	: 'keep it'
	###
	trailingSlash: 0

	###*
	 * when 1, ignore path case
	 * when on, ignore route static part case only (do not lowercase param values)
	 * when off, case sensitive
	 * @type {boolean}
	###
	routeIgnoreCase: on

	####<========================== Request =============================>####
	###*
	 * trust proxy
	###
	trustProxyFunction: (app, mode)->
		#TODO
		(req, proxyLevel)-> on
	####<========================== Render and output =============================>####
	###*
	 * Render pretty JSON, XML and HTML
	 * @default  false when prod mode
	###
	pretty: (app, mode)-> mode is 0 # true if dev mode
	###*
	 * Etag function generator
	 * generate ETag for responses
	###
	etagFunction: (app, mode)->
		(data)-> '' 
	###*
	 * render templates
	 * we do use function, so the require inside will be executed
	 * inside the app and not the compiler
	###
	engines: (app, mode)->
		'.pug': require 'pug'
	###*
	 * view Cache
	 * @when off: disable cache
	 * @when on: enable cache for ever
	 * @type {boolean}
	###
	viewCache: (app, mode) ->
		mode isnt 0 # false if dev mode
	viewCacheMax: 50 # view cache max entries
	views: [
		'views' # default folder
	]
	####<========================== Errors =============================>####
	# Error templates
	errorTemplates: ->
		'404': path.join __dirname, '../../build/views/errors/404'
		'500': path.join __dirname, '../../build/views/errors/500'
		# dev mode
		'd404': path.join __dirname, '../../build/views/errors/d404'
		'd500': path.join __dirname, '../../build/views/errors/d500'

