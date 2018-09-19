###*
 * Error
 * -----------------
 * 404 : Page or file not found
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
	constructor: (code, message)->
		super message
		@code = code

module.exports = GError