###
Enable
disable
reload
###

Object.defineProperties GridFW.prototype,
	###*
	 * Is app enabled
	 * @return {boolean}
	###
	enabled:
		get: -> @[IS_ENABLED]
		set: (v)-> throw new Error 'Please use app.enable or app.disable instead.'
	###*
	 * Enable app
	 * @async
	###
	enable: value: ->
		return if @[IS_ENABLED]
		throw new Error 'Server not yeat set' unless @server
		# waiting for app to starts
		unless @[IS_LOADED] and not @[APP_STARTING_PROMISE]
			await @reload()
		# listen into server
		@server.on 'request', @[REQ_HANDLER] = @handle.bind this
		# return
		return
	###*
	 * Disable app
	 * @async
	###
	disable: value: ->
		return unless @[IS_ENABLED]
		# remove listener
		if @[REQ_HANDLER]
			@server.off 'request', @[REQ_HANDLER]
		# return
		return
	###*
	 * reload app
	 * @async
	 * @optional @param  {object} options - new options
	###
	reload: value: (options)->
		if @[APP_STARTING_PROMISE]
			await @[APP_STARTING_PROMISE]
		else
			@[APP_STARTING_PROMISE] = _reloadSettings this, options
			.then =>
				@[APP_STARTING_PROMISE] = null
				@[IS_LOADED] = true
		return @[APP_STARTING_PROMISE]

### reload settings ###
_reloadSettings = (app, options)->
	# load options from file
	unless options
		try
			options = path.join process.cwd , 'gridfw-config'
			options = require options
		catch err
			console.warn "GridFW>> Could not find config file at: #{options}\n", err
			options = null
	else if typeof options is 'string'
		try
			options = require options
		catch err
			console.err "GridFW>> Could not find config file at: #{options}\n"
			throw err
	# load default settings
	appSettings = app.s
	configKies = CONFIG.kies
	for v, k in CONFIG.config
		appSettings[k] = v
	# check and default options
	if options
		# check options
		for k in Object.kies options
			v = options[k]
			throw new Error "Illegal option: #{k}" unless CHECK_SETTINGS[k]
			CHECK_SETTINGS[k] v
			# copy to settings
			appSettings[configKies[k]] = v
	# resolve default settings based on mode
	mode = appSettings[<%= settings.mode %>]
	for k,v of CONFIG.default
		unless Reflect.has options, k
			appSettings[configKies[k]] = v app, mode
	# plugins settings
	if options.plugins
		Object.setPrototypeOf options.plugins, CONFIG.kies[<%= settings.plugins %>]
	# if use view cache
	if settings[<%= settings.viewCache %>]
		if app[VIEW_CACHE]
			app[VIEW_CACHE].clear()
		else
			app[VIEW_CACHE] = new LRUCache
				max: settings[<%= settings.viewCacheMax %>]
	else
		app[VIEW_CACHE] = null
	# reload all plugins
	reloadPlusPromise = []
	for k,v of app[PLUGINS]
		reloadPlusPromise.push v.reload? appSettings[<%= settings.plugins %>][k] || {}
	# waiting for all plugs to be reloaded
	await Promise.all reloadPlusPromise
	return


	