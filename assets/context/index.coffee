
http = require 'http'
fastDecode	= require 'fast-decode-uri-component'
Buffer = require('safe-buffer').Buffer

accepts= require 'accepts'

Request = require './request'

LoggerFactory= require '../lib/logger'

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

module.exports = Context


# add log support
LoggerFactory Context.prototype

#= include _context-param-resolvers.coffee
#= include _send-response.coffee

Object.defineProperties Context.prototype,
	### user IP ###
	ip: get: ->
		if @socket
			#TODO, add IP via trast proxy
			@socket.remoteAddress
	port: get: ->
		if @socket
			#TODO add port via proxy header
			@socket.remotePort
	### if the request is aborted ###
	aborted: get: -> @req.aborted
	###*
	 * Key-value pairs of request header names and values. Header names are lower-cased.
	###
	reqHeaders: get: -> @req.headers
	###*
	 * HTTP version of th request
	###
	httpVersion: get: -> @req.httpVersion
	###*
	 * Used method
	###
	method: get: -> @req.method

	### accept ###
	_accepts: get: ->
		acc = accepts @req
		Object.defineProperties this, '_accepts', value: acc
		acc

