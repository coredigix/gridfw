'use strict'

RouteNode = require './route-node'

###*
 * Route Mapper
 * map each http method to some RouteNode
###
class RouteMapper
	constructor: (@app, @route)->
		# create Regex
	# append new node
	append: (method, attrs)->
		# check for node
		routeNode = @[method]
		if routeNode
			throw new Error "A controller already set to this route: #{method} #{@route}" if attrs.c and routeNode.c
		else
			routeNode = @[method] = new RouteNode @app, this, method
		# add controler
		if attrs.c
			throw new Error 'The controller expected function' unless typeof attrs.c is 'function'
			throw new Error 'The controller expect exactly one argument' if attrs.c.length > 1
			routeNode.c = attrs.c
		# add handlers
		for k, v of attrs
			if typeof v is 'function'
				routeNode[k].push v
			else if Array.isArray v
				# check is array of functions
				for a in v
					throw new Error 'Handler expected function' unless typeof a is 'function'
				# add
				ref= routeNode[k]
				# append handlers
				if ref
					for a in v
						ref.push a
				# add the whole array
				else
					routeNode[k] = v
			else
				throw new Error "Illegal node attribute: #{k}"
		# param resolvers
		ref = routeNode.$
		for k,v of nodeAttrs.$
			throw new Error "Param [#{k}] already set to route #{method} #{@route}" if ref[k]
			unless Array.isArray(v) and v.length is 2 and (v[0] instanceof RegExp) and (typeof v[1] is 'function')
				throw new Error "Illegal param format"
			ref[k] = v
		# chain
		this

module.exports = RouteMapper