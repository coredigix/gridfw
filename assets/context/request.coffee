
http = require 'http'
Context = require '.'
parseRange = require 'range-parser'

### response ###
class Request extends http.IncomingMessage
	constructor: (socket)->
		super socket
	###*
	 * Parse Range header field, capping to the given `size`.
	 *
	 * Unspecified ranges such as "0-" require knowledge of your resource length. In
	 * the case of a byte range this is of course the total number of bytes. If the
	 * Range header field is not given `undefined` is returned, `-1` when unsatisfiable,
	 * and `-2` when syntactically invalid.
	 *
	 * When ranges are returned, the array has a "type" property which is the type of
	 * range that is required (most commonly, "bytes"). Each array element is an object
	 * with a "start" and "end" property for the portion of the range.
	 *
	 * The "combine" option can be set to `true` and overlapping & adjacent ranges
	 * will be combined into a single range.
	 *
	 * NOTE: remember that ranges are inclusive, so for example "Range: users=0-3"
	 * should respond with 4 users when available, not 3.
	 *
	 * @param {number} size
	 * @param {object} [options]
	 * @param {boolean} [options.combine=false]
	 * @return {number|array}
	 * @public
	 ###
	range: (size, options) ->
		range = @getHeader 'Range'
		if range
			parseRange size, range, options

module.exports = Request

Object.defineProperties Request.prototype,
	### accept ###
	_accepts: get: ->
		acc = accepts this
		Object.defineProperties this, '_accepts', value: acc
		acc
	### protocol ###
	protocol: get: ->
		#Check for HTTP2
		protocol = if @connection.encrypted then 'https' else 'http'



### commons with Context ###
props=
	### request: return first accepted type based on accept header ###
	accepts: ->
		acc = @_accepts
		acc.encodings.apply acc, arguments
	### Request: Check if the given `encoding`s are accepted.###
	acceptsEncodings: ->
		acc = @_accepts
		acc.types.apply acc, arguments
	### Check if the given `charset`s are acceptable ###
	acceptsCharsets: ->
		acc = @_accepts
		acc.charsets.apply acc, arguments
	### Check if the given `lang`s are acceptable, ###
	acceptsLanguages: ->
		acc = @_accepts
		acc.languages.apply acc, arguments

Object.defineProperties Context.prototype, props
Object.defineProperties Request.prototype, props