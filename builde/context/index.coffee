'use strict'

http		= require 'http'
fastDecode	= require 'fast-decode-uri-component'
Buffer		= require('safe-buffer').Buffer
encodeurl	= require 'encodeurl'
sendFile	= require 'send'
onFinishLib	= require 'on-finished'
contentDisposition = require 'content-disposition'
mimeType	= require 'mime-types'

Request = require './request'

LoggerFactory= require '../lib/logger'
{gettersOnce} = require '../lib/define-getter-once.coffee'
GError			= require '../lib/error'

DEFAULT_ENCODING = 'utf8'

### response ###
class Context extends http.ServerResponse
	constructor: (socket)->
		super socket

	# request class
	@Request: Request

	###*
	 * redirect to this URL
	 * @param {string} url - target URL
	 * @param {boolean} isPermanent - If this is a permanent or temp redirect
	 * (use this.redirectPermanent(url) in case of permanent redirect)
	###
	redirect: (url, isPermanent)->
		# set location header
		@setHeader 'location', encodeurl url
		#TODO add some response (depending on "accept" header: text, html, json, ...)
		# status code
		@statusCode if isPermanent then 302 else 301
		# end request
		@end()
	###*
	 * Permanent redirect to this URL
	###
	redirectPermanent: (url)-> @redirect url, true
	###*
	 * Redirect back (go back to referer)
	###
	redirectBack: -> @redirect @req.getHeader('Referrer') || '/'

	###*
	 * Render page
	 * @param  {[type]} path [description]
	 * @return {[type]}      [description]
	###
	render: (path, locals)->
		if locals
			Object.setPrototypeOf locals, @locals
		@app._render path, locals
		.then (html)=>
			@setHeader 'content-type', 'text/html'
			@end html

	###*
	 * end request
	###
	end: (data)->
		new Promise (resolve, reject)->
			# send
			super.end data, (err)->
				if err then reject err
				else resolve()
	### response.write(chunk[, encoding], cb) ###
	write: (chunk, encoding)->
		new Promise (res, rej)->
			super.write chunk, encoding || DEFAULT_ENCODING, (err)->
				if err then rej err
				else res()
	### content type ###
	type: (type)->
		throw new Error 'type expected string' unless typeof type is 'string'
		@contentType = type
		this
	# 	switch arguments.length
	# 		when 1
	# 			@_type = type
	# 			this
	# 		when 0
	# 			@_type
		# switch arguments.length
		# 	when 1, 2
		# 		if type is 'bin'
		# 			@setHeader 'content-type', 'application/octet-stream'
		# 		else
		# 			@setHeader 'content-type', (CONTENT_TYPE_MAP[type] || type).concat '; charset=', encoding || DEFAULT_ENCODING
		# 		this
		# 	when 0
		# 		@getHeader 'content-type'
		# 	when 2
		# 		@setHeader 'content-type', type
		# 		this
		# 	else
		# 		throw new Error 'Illegal arguments'
	### has type ###
	hasType: ->
		@hasHeader 'content-type'

module.exports = Context


# add log support
LoggerFactory Context.prototype







Object.defineProperties Context.prototype,

	###*

	 * parse query

	 * enable user to define an other query parser,

	 * by simply overriding this one

	 * @param {string} rawQuery - query to parse

	 * @return {Object} Map of all params

	 * @example

	 * ctx.QueryParser('param=value&param2=value2')

	###

	queryParser: value: (rawQuery)->

		query = {}

		raw = @rawQuery

		if raw

			raw = raw.split '&'

			for part in raw

				# parse

				idx = part.indexOf '='

				if idx isnt -1

					name = fastDecode part.substr 0, idx

					value= fastDecode part.substr idx + 1

				else

					name = fastDecode part

					value = ''

				# fix __proto__

				if name is '__proto__'

					@warn 'query-parser', 'Received param with illegal name: __proto__'

					name = '__proto'

				# append to object

				alreadyValue = query[name]

				if alreadyValue is undefined

					query[name] = value

				else if typeof alreadyValue is 'string'

					query[name] = [alreadyValue, value]

				else

					alreadyValue.push value

		# return

		query

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
				@contentType ?= 'text/html'
				data = Buffer.from data, encoding
			when 'object'
				if Buffer.isBuffer data
					@contentType ?= 'application/octet-stream'
				else
					#TODO check accept header if we wants json or xml
					return @json data
			when 'undefined'
				@contentType ?= 'text/plain'
				data = ''
			else
				@contentType ?= 'text/plain'
				data = data.toString()
			
		# ETag
		unless @hasHeader 'ETag'
			etag = settings.etag data
			@setHeader 'ETag', etag if etag
		
		# freshness
		@statusCode = 304 if @statusCode isnt 304 and req.fresh

		# strip irrelevant headers
		if @statusCode in [204, 304]
			@removeHeader 'Content-Type'
			@removeHeader 'Content-Length'
			@removeHeader 'Transfer-Encoding'
			data = ''
		else
			# populate Content-Length
			@setHeader 'Content-Length', data.length
			# set content type
			contentType = @contentType
			if typeof contentType is 'string'
				# fix content type
				if contentType.indexOf('/') is -1
					contentType = mimeType.lookup contentType
					contentType = 'application/octet-stream' unless contentType
				# add encoding
				contentType = contentType.concat '; charset=', encoding
			else
				contentType = 'application/octet-stream'
			# set as header
			@setHeader 'Content-Type', contentType


		
		# send
		if req.method is 'HEAD'
			@end()
		else
			@end data, encoding

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



CONTENT_TYPE_MAP = 
	text: 'text/plain'
	html: 'text/html'
	js  : 'text/javascript'
	javascript: 'text/javascript'
	css : 'text/css'

Object.defineProperties Context.prototype,
	###*
	 * 
	###
	clearCookie: value: (name, options)->
		throw new Error 'No cookie parser is found'

	cookie: value: (name, value, options)->
		throw new Error 'No cookie parser is found'
		

gettersOnce Context.prototype,
	### if the request is aborted ###
	aborted: -> @req.aborted
	###*
	 * Key-value pairs of request header names and values. Header names are lower-cased.
	###
	reqHeaders: -> @req.headers
	###*
	 * HTTP version of th request
	###
	httpVersion: -> @req.httpVersion
	###*
	 * Used method
	###
	method: -> @req.method

	### protocol ###
	protocol: -> @req.protocol

	### is https or http2 ###
	secure: -> @req.secure
	ip: -> @req.ip
	hostname: -> @req.hostname
	fresh: -> @req.fresh
	### if request made using xhr ###
	xhr: -> @req.xhr

	### accept ###
	_accepts: -> @req._accepts


### default values ###
Object.defineProperties Context.prototype,
	encoding: value: DEFAULT_ENCODING
	contentType: value: undefined