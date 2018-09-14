'use strict'

http = require 'http'
fastDecode	= require 'fast-decode-uri-component'
Buffer = require('safe-buffer').Buffer

Request = require './request'

LoggerFactory= require '../lib/logger'
{gettersOnce} = require '../lib/define-getter-once.coffee'

DEFAULT_ENCODING = 'utf8'

### response ###
class Context extends http.ServerResponse
	constructor: (socket)->
		super socket

	# request class
	@Request: Request

	###*
	 * redirect
	###
	redirect: (url)->
	###*
	 * Permanent redirect
	###
	permanentRedirect: (url)->


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

#=include _context-param-resolvers.coffee
#=include _send-response.coffee
#=include _context-content-types.coffee

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