# App consts
exports.app = app =
	DEV: 0
	PROD: 1
### this file contains app default settings ###
exports.settings=
	####<========================== App Id =============================>####
	###* Author ###
	author: 'GridFW'
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
	 * when true, ignore path case
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
	 * Render JSON as pretty
	 * @default  false when prod mode
	###
	outPutPretty: (app, mode)-> mode is 0 # true if dev mode
	###*
	 * Etag function generator
	 * generate ETag for responses
	###
	etagFunction: (app, mode)->
		(data)-> '' 

