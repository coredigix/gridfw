
http = require 'http'
fastDecode	= require 'fast-decode-uri-component'

### response ###
class Context extends http.ServerResponse
	constructor: (socket)->
		super socket

	###*
	 * redirect
	###
	redirect: (url)->
	###*
	 * Permanent redirect
	###
	permanentRedirect: (url)->



module.exports = Context

#= include _context-param-resolvers.coffee