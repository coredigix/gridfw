###
Hello world
###

GridFw = require '..'

# create server
app = new GridFw()

# append Get route
app.get '/', (ctx)->
	ctx.info 'My service', '--- Path "/" called'
	ctx.send 'Hello world'

# test GET
app.get '/hello/world', (ctx)->
	ctx.info 'My service', "---- got #{ctx.path}"
	ctx.send 'hello dear'

app.get '/hello world', (ctx)->
	ctx.info 'My service', "---- got #{ctx.path}"
	ctx.send 'hi'


# run the server at port 3000
app.listen 3000
	.then -> app.log 'Main', "Server listening At: #{app.port}"
	.catch (err)-> app.error 'Main', "Got Error: ", err
