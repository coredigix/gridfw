
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
	settings = @settings
	useCache = settings.viewCache
	# resolve file content
	throw new Error 'path expected string' unless typeof templatePath is 'string'
	# check in cache
	renderFx	= useCache && @[VIEW_CACHE].get templatePath
	unless renderFx 
		# if add index
		filePath = if templatePath.endsWith '/' then templatePath += 'index' else templatePath 
			
		# get file string
		engines = settings.engines
		# absolute path
		if path.isAbsolute filePath
			template = _loadTemplateFileContent settings.engines, filePath
		# relative to views
		else
			for v in settings.views
				template = _loadTemplateFileContent settings.engines, (path.join v, filePath)
				if template.content?
					break
		unless template.content?
			throw 404 # page not found

		# compile template
		renderFx = template.module.compile template.content,
			pretty: settings.renderPretty
		# cache
		if useCache
			@[VIEW_CACHE].set templatePath, renderFx
	# compile render fx
	renderFx locals

###*
 * Load template file content
 * @type {[type]}
###
_loadTemplateFileContent= (engines, filePath) ->
	result=
		content: null
		module: null
	for ext, module of engines
		try
			result.content	= await fs.readFile if filePath.endsWith ext then filePath else filePath + ext
			result.module	= module
			break
		catch err
			if err and err.code is 'ENOENT'
				# file not found, go to next file
			else
				throw err	
	result