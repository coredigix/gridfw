
# default used protocol when non specified, in [http, https, http2]
DEFAULT_PROTOCOL = 'http'

###*
 * Listen([port], options)
 * @optional @param {number} options.port - listening port @default to arbitrary generated one
 * @optional @param {string} options.protocol - if use 'http' or 'https' or 'http2' @default to http
 * @example
 * listen() # listen on arbitrary port
 * listen(3000) # listen on port 3000
 * listen
 * 		port: 3000
 * 		protocol: 'http' or 'https' or 'http2'
###
GridFW::listen= (options)->
	new Promise (res, rej)->
		# options
		unless options
			options = {}
		else if typeof options is 'number'
			options= port: options
		else if typeof options isnt 'object'
			throw new Error 'Illegal argument'
		# get server factory
		servFacto = options.protocol
		if servFacto
			throw new Error "Protocol expected string" unless typeof servFacto is 'string'
			servFacto = SERVER_LISTENING_PROTOCOLS[servFacto.toLowerCase()]
			throw new Error "Unsupported protocol: #{options.protocol}" unless servFacto
		else
			servFacto = SERVER_LISTENING_PROTOCOLS[DEFAULT_PROTOCOL]
		# create server
		server = servFacto options, this


### make server listening depending on the used protocol ###
SERVER_LISTENING_PROTOCOLS=
	http: (options, app)->
		server = app.server = http.createServer
			IncomingMessage : Context.Request
			ServerResponse : Context
			,
			app.handle.bind app