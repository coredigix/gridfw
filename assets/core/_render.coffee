
###*
 * Render HTML template
 * @param {string} path path to template
 * @param {Object} Locals [description]
 * @return {Promise<string>} will return the rendered HTML
###
GridFW::render= (templatePath, locals)->
	Object.setPrototypeOf locals, @locals
	@_render path, locals

###*
 * Execute render
 * @private
 * @param  {srting} path - path to resolve template
 * @param  {Object} locals   - locals
 * @return {Promise<html>}          return compiled HTML
###
GridFW::_render = (templatePath, locals)->
	settings = @_settings
	engines = settings.engines
	# resolve file content
	throw new Error 'path expected string' unless typeof templatePath is 'string'
	# check in cache
	renderFx	= @_viewCache[templatePath]
	unless renderFx 
		# if add index
		if templatePath.endsWith '/'
			templatePath += 'index'
		# if absolute path
		if path.isAbsolute templatePath
			# extentions
			for ext, module of settings.engines
				try
					renderFx = module.compileFile (if templatePath.endsWith ext then templatePath else templatePath + ext),
						pretty: settings.renderPretty
				catch e
					# ...
				
				unless templatePath.endsWith ext
					templatePath

		# else if 
		for v in settings.views
			p = path.join v, templatePath
			for k in 
			try

				fileContent = fs.readFile path.
			catch err
				ctx.log 'app.render', err
			
			p = path.join v, templatePath

	# compile render fx

