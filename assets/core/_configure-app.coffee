### configure application ###
_configApp= (app, options)->
	# mode
	mode = DEFAULT_SETTINGS_KIES[options.mode] || <%= app.DEV %>
	# locals
	locals = Object.create null,
		app: value: app
	# settings
	settings = DEFAULT_SETTINGS.slice 0
	# define properties
	Object.defineProperties app,
		# mode
		mode: value: mode
		### App connection ###
		server: UNDEFINED
		protocol: UNDEFINED
		host: UNDEFINED
		port: UNDEFINED
		path: UNDEFINED
		# settings
		s: value: settings
		# locals
		locals: value: locals
		data: value: locals
		# root RouteMapper
		m: value: new RouteMapper app, '/'
		# global param resolvers
		$: value: Object.create null
		# view cache
		[VIEW_CACHE]: UNDEFINED
		# Routes
		[ALL_ROUTES]: value: Object.create null
		[STATIC_ROUTES]: value: Object.create null
		[DYNAMIC_ROUTES]: value: Object.create null
		#TODO check if app cache optimise performance for 20 routes
		# [CACHED_ROUTES]: new LRUCache max: options.routeCache || DEFAULT_SETTINGS.routeCacheMax
		# plugins
		[PLUGINS]: value: Object.create null
	# resolve settings based on current mode
	for v, k in settings
		if typeof v is 'function'
			settings[k] = v app, mode
	# add log support
	logOptions = level: app.s.logLevel
	LoggerFactory GridFW.prototype, logOptions
	LoggerFactory Context.prototype, logOptions
	# if use view cache
	if settings[<%= settings.viewCache %>]
		app[VIEW_CACHE] = new LRUCache
			max: settings[<%= settings.viewCacheMax %>]
	# do some process before exiting process
	# process off listener
	exitCb = app._exitCb = (code)=> _exitingProcess app, code
	process.on 'SIGINT', exitCb
	process.on 'SIGTERM', exitCb
	process.on 'beforeExit', exitCb
	