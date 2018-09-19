
Object.defineProperties Context.prototype,
	###*
	 * set status code
	###
	status:		value: (status)->
		if typeof status is 'number'
			@statusCode = status
		else if typeof status is 'string'
			@statusMessage = status
		else
			throw new Error 'status expected number or string'
		this
	###*
	 * Send JSON
	 * @param {Object} data - data to parse
	###
	json: value: (data)->
		# stringify data
		if @app.settings.pretty
			data = JSON.stringify data, null, "\t"
		else
			data = JSON.stringify data
		# send data
		@contentType ?= 'application/json'
		@send data
	#TODO jsonp
	###*
	 * Send response
	 * @param {string | buffer | object} data - data to send
	###
	send:		value: (data)-> #TODO support user to specify if he wants JSON, Text, XML, ...
		settings = @app.settings
		encoding = @encoding
		# native request
		req = @req
		switch typeof data
			when 'string'
				data = Buffer.from data, encoding
				@contentType ?= 'html'
			when 'object'
				if Buffer.isBuffer data
					@contentType ?= 'bin'
				else
					return @json data, encoding # check accept header if we wants json or xml
			when 'undefined'
				data = ''
				@contentType = 'text'
			else
				data = data.toString()
				@contentType = 'text'
		
		# populate Content-Length


		# chain
		this
	###*
	 * Send file
	 * @param {string} path - file path
	 * @param {object} options - options
	###
	sendFile:	value: (path, options)->
		new Promise (resolve, reject)->
			# control
			throw new Error 'path expected string' unless typeof path is 'string'
			path = encodeurl path

			# Prepare file streaming
			file = sendFile @req, path, options || {}
			# flags
			streaming = off
			# done = no
			# Add callbacks
			file.on 'directory', -> reject new GError 'EISDIR', 'EISDIR, read'
			file.on 'stream', -> streaming = on
			file.on 'file', -> streaming = off
			file.on 'error', -> reject
			file.on 'end', -> resolve
			# Execute a callback when a HTTP request closes, finishes, or errors.
			onFinishLib this, (err)->
				# err.code = 'ECONNRESET'
				reject err if err
				setImmediate ->
					if streaming
						reject new GError 'ECONNABORTED', 'Request aborted'
					else
						resolve()
			# add headers
			if options.headers
				file.on 'headers', (res)->
					for k,v of options.headers
						res.setHeader k, v
			# pipe file
			file.pipe this
	###*
	 * Download file
	 * @param {string} path - file path
	 * @optional @param {string} options.fileName - file name
	###
	download:	value: (path, options)->
		# set headers
		options ?= {}
		options.headers ?= {}
		options.headers['Content-Disposition'] = contentDisposition options.fileName || path
		# send
		@sendFile path, options

