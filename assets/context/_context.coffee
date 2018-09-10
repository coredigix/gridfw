

renderTemplate = require '../lib/render-templates'

###*
 * context var
###

class Context #extends Response
	constructor: (app) ->
		# locals
		Object.defineProperties this,
			### app ###
			app: value: app
			### locals ###
			locals: value: Object.create app.locals
			### status code ###
			statusCode:
				value: 200
				writable: true

	###*
	 * Render page
	 * @param  {[type]} path [description]
	 * @return {[type]}      [description]
	###
	render: (path, locals)->
		if locals
			Object.setPrototypeOf locals, @locals
		@app._render path, locals
		.then (html)=>
			#TODO add headers
			@type 'html'
			@end html