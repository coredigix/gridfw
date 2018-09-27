'use strict'

fastDecode	= require 'fast-decode-uri-component'
Context		= require '../context'
http		= require 'http'

###*
 * Route node
###
UNDEFINED =
	value: undefined
	writable: true
	configurable: true

class RouteNode
	constructor: (app, routeObj)->
		Object.defineProperties this,
			app: value: app
			route: value: routeObj
			# settings
			s: value: app.s
			settings: value: app.s
			# middlewares (list of or undefined)
			m: UNDEFINED
			# filters (list of handlers or undefined)
			f: UNDEFINED
			# controller (only one handler)
			c: UNDEFINED
			# post process (undefined or list of handlers)
			p: UNDEFINED
			# Error handlers (undefined or list of handlers)
			e: UNDEFINED
			# path and query params (object)
			pm: value: Object.create app.pm
