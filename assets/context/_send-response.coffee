
Object.defineProperties Context.prototype,
	###*
	 * set status code
	###
	status:		value: (status)->
		@statusCode = status
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

