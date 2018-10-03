###
Add plugins to GridFW
###
Object.defineProperties GridFW.prototype,
	plugin: (plugin)->
		# flatten
		if arguments.length > 1
			for plugin in arguments
				@plugin plugin
			return
		# add plugin
		throw new Error 'Illegal arguments' unless plugin
		plugName = plugin.name
		# check it's correct GridFW plugin
		v = plugin.GridFWVersion
		throw new Error "Unsupported plugin #{plugName}" unless typeof v is 'string'
		# check plugin name
		throw new Error "Illegal plugin name: #{plugName}" unless typeof plugName is 'string' and plugName isnt '__proto__' and /^[\w@$%-]+$/.test plugName
		# check version
		if compareVersion(@version, v) is -1 # plugin needs newer version of GridFW
			throw new Error "Plugin #{plugName} needs GridFW version #{v} or newer"
		# add
		@info 'PLUGIN', "Add plugin #{plugName}"
		plugs = @[PLUGINS]
		throw new Error "Plugin #{plugName} already set. use \"app.plugin('#{plugName}').configure({...})\" to reconfigure it" if plugs[plugName]
		plugs[plugName] = plugin
		# call configure
		await plugin.configure? this
		# statup script
		#TODO
		# shutdown script
		#TODO
		# chain
		this