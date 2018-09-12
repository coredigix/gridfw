
http = require 'http'
fastDecode	= require 'fast-decode-uri-component'

Request = require './request'

LoggerFactory= require '../lib/logger'

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



module.exports = Context


# add log support
LoggerFactory Context.prototype

#= include _context-param-resolvers.coffee