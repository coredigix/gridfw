
http = require 'http'

### response ###
class Request extends http.IncomingMessage
	constructor: (socket)->
		super socket

module.exports = Request