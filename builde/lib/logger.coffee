###*
 * Add Logging service to an object
 * we didn't use closure to uncrease performance
 * @example
 * app.log('title', ...args)
###
LEVELS= ['debug', 'log', 'warn', 'info', 'error', 'fatalError']
_VOID = ->
module.exports = (obj, options)->
	# set log level
	Object.defineProperty obj, 'logLevel',
		value: _setLogLevel
		configurable: true # enable to change this default logger
	# options
	if options
		level = LEVELS.indexOf options.level
	else
		level = 0

_setLogLevel = (level)->
	#TODO use console.log in dev mode
	#TODO use performante logger in 
	throw new Error "Usupported level: #{level}, supported are: #{LEVELS}" unless level in LEVELS
	for logMethod in LEVELS
		_createConsoleLogMethod level, this, logMethod
	return

CONSOLE_COLORS=
	log: ''
	warn: "\x1b[33m"
	info: "\x1b[34m"
	error: "\x1b[31m"
	fatalError: "\x1b[31m"

_createConsoleLogMethod = (level, obj, method)->
	color = CONSOLE_COLORS[method]
	mt = "\x1b[7m" + color + method.toUpperCase() + " \x1b[0m" + color
	# fatalError: add blink
	if method is 'fatalError'
		mt = "\x1b[5m" + mt
	# Add
	Object.defineProperty obj, method,
			value: if LEVELS.indexOf(method) < level then _VOID else (value, ...args)->
				console.log mt, value, '>> ', args, "\x1b[0m"
			configurable: true
	return