###*
 * Error
 * -----------------
 * 404 : Page or file not found
 *
 * 500 : internal server error
 *
 *
 * EISDIR: Directory error
###
class GError extends Error
	###*
	 * Error
	 * @param  {number|string} code - error code
	 * @param  {string} message - error message
	###
	constructor: (code, message, extra)->
		super message
		Object.defineProperties this,
			code: value: code
			extra: value: extra
	### convert to JSON ###
	toJSON: ->
		code: @code
		message: @message
		stack: @stack
		extra: @extra

module.exports = GError