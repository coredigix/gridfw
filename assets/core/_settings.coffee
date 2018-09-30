###*
 * App default settings
###
DEFAULT_SETTINGS = [
	####<========================== App Id =============================>####
	###*
	 * Author
	 * @key settings.author
	###
	'GridFW'
	###*
	 * Admin Email
	 * @key settings.email
	###
	'contact@coredigix.com'

	####<========================== LOG =============================>####
	###*
	 * log level
	 * @default prod: 'info', dev: 'debug'
	 * @key settings.logLevel
	###
	'debug'

	####<========================== Router =============================>####
	###*
	 * Route cache
	 * @key settings.routeCacheMax
	###
	50
	###*
	 * Ignore trailing slashes
	 * 		off	: ignore
	 * 		0	: ignore, make redirect when someone asks for this URL
	 * 		on	: 'keep it'
	 *	@key settings.trailingSlash
	###
	0

	####<========================== Render and output =============================>####
	###*
	 * trust proxy
	 * @key settings.trustProxyFunction
	###
	(app, mode)->
		#TODO
		(req, proxyLevel)-> on
	####<========================== Render and output =============================>####
	###*
	 * Render JSON as pretty
	 * @default  false when prod mode
	 * @key settings.outPutPretty
	###
	(app, mode)-> mode is <?= app.DEV ?>
	###*
	 * Etag function generator
	 * generate ETag for responses
	 * @key settings.etagFunction
	###
	(app, mode)->
		(data)-> '' 
]
