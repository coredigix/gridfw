
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
	###
	sendFile:	value: ()->

	###*
	 * Download file
	###
	download:	value: ()->
