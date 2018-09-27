###*
 * Route
 * map each http method to some RouteNode
###
class Route
	constructor: (@key)->
		# create Regex
		#TODO
		@regex = routeToRegex @key