
Object.defineProperties Context.prototype,
	###*
	 * 
	###
	clearCookie: value: (name, options)->
		throw new Error 'No cookie parser is found'

	cookie: value: (name, value, options)->
		throw new Error 'No cookie parser is found'
		