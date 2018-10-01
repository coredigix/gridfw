
# show welcome message if called directly
if require.main is module
	console.error "GridFW>>\tCould not be self run, See @Doc for more info, or run example"

# print console welcome message
_console_welcome = (app) ->
	console.log "\e[94m┌─────────────────────────────────────────────────────────────────────────────────────────┐"
	# if dev mode or procution
	if app.mode is 'prod'
		console.warn "GridFW>> ✔ Production Mode"
	else
		console.warn "\e[93GridFW>> Developpement Mode\n\t⚠ Do not forget to enable production mode to boost performance\e[0m\e[94m"
	# server params
	console.log """
	GridFW>> Running The server As:
	\t✔︎ Name: #{app.name}
	\t✔︎ Port: #{app.port}
	\t✔︎ Path: #{app.path}
	\t✔︎ Host: #{app.host}
	\t✔︎ Autor: #{app.s[<%=settings.author %>]}
	\t✔︎ Admin Email: #{app.s[<%=settings.email %>]}
	"""
	console.log "└─────────────────────────────────────────────────────────────────────────────────────────┘\e[0m"