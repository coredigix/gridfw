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
		# check has not already an 'all' method
		throw new Error "A controller alreay set to all http methods on this route: #{@route}" if attrs.c and @ALL?.c
		# check for node
		routeNode = @[method]
		if routeNode
			throw new Error "A controller already set to this route: #{method} #{@route}" if attrs.c and routeNode.c
		else
			routeNode = @[method] = new RouteNode @app, this
		# add handlers
		for k, v of attrs
			if typeof v is 'function'
				routeNode[k] = v
			else if Array.isArray v
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
			ref[k] = v
		# ends
		return

module.exports = RouteMapper