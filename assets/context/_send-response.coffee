
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
	 * set content type
	###
	sendType:		value: (contentType)->
		@sendHeader 'content-type', contentType
	###*
	 * Send response
	 * @param {string | buffer} data - data to send
	###
	send:		value: (data)->
		settings = @app.settings
		# native request
		req = @req

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
