# gridfw
grid is a fast http framework based on promises for node

## use
```javascript
const grid = require('gridfw');
const app = new grid();

app.get('/', function(ctx){ // could use promises and async functions
	ctx.send('Hellow world');
	});

app
	.listen(3000)// when port is missing, the system will generate a random one
	.then(function(server){
		console.info("Grid>> server is running on port 3000")
		})
	.catch(function(err){
		console.error("Grid>> Error caught: ", err)
		});
```
## general

### app locals
* add local variables withing the application
```javascript
// simple attribute
app.locals.myGlobalLocal = 'my value'
delete app.locals.myGlobalLocal = 'my value'

// getter
app.locals_getter('get_ip_as_example_name', function(ctx){
	return ctx.ip
})
// getter once for each request (the function will be called only once on each request)
app.locals_getter_once('param_name', function(ctx){
	return 'value cached for current request';
	})
```
* Default locals
	* _ctx: access to context variable
	* _res: access to current response context (ctx.res)
	* _req: access to current request context (ctx.req)
	* _app: access to current app
	* _ip: user ip (ctx.ip)
	* _engine: returns used engine (stupid! you already know the engine ;) 
*

### context locals
```javascript
app.use(function(ctx){
	ctx.locals
	});
```

### app.mountpath
get all paths where current app is mounted

### app.settings
	app settings
	* prod: true to enable production mode
	* trustProxy: true to enable proxy data
	* jsonpCb: contains name of query param that specify jsonp callback, default to 'callback'
	* resType: contains name of query param that specify wanted content-type, default to "type"

	* strictRouting: @default false, when true, routes will be case sensitive, the ending "/" will be counted

### render engines
```javascript
// render a file and return it's HTML
app.render('home', {locals}).then(function(html){})

app.render
	// add tempaltes directories
	.direname
		.add('path/to/dir/containing/templates')
		.delete('path') // remove a path to directory
		.clear() // remove all directories

	.add('pug', require('pug')) // add templating engine
	.delete('pug') // remove this template engine
	.deleteAll() // remove all template engines
	.clearCache() // clear templates cache (only in production mode)
	.clearCache('template.name')// clear specifique cache (only in production mode)
```

### param handler
used to change resolve params
```javascript
// params will be in
ctx.params.paramName
// raw params (origine form) will be in
ctx.raw.params.paramName

// resolve path param
app.param('param-name', async function(ctx, data){
	// do resolve logic, could be call to database
	result = await resolve(data);
	return result;
	})

// resolve query param
app.queryParam('paramName', (ctx, data) => resolvePromise(data) )

```

### list of parent app
the app could be mounted to a parent app. To get all parent apps, use:
app.parents : Array

### events
	app.on('eventName', listener(event){
		event.app // current app
		event.parentApp // app where current app is mounted
		})
	supported events:
	* mount: when app is mounted on other app
	* unmount: when app is unmounted on parent app

## router
the framework supports those http methods
- all: support all http methods
- get
- head
- post
- patch
- delete

### Examples
```javascript
app
	# add listener to GET method (and HEAD when no head listener is set)
	.get( '/path/to/resource', function(ctx){} )
	# add a second listener to GET method on the some route (the execution will follow declaration flow)
	.get( '/path/to/resource', function(ctx){} )
	# add listener to all http methods
	.all( '/path/to/resource', function(ctx){} )
	# add listener to HEAD method
	.head( '/path/to/resource', function(ctx){} )
	# add listener to POST method
	.post( '/path/to/resource', function(ctx){} )
```

##### add multiple methods to the some route
```javascript
// All method callbacks could return a static value or a promise
// Could use "function" or "async function"
// all callbacks got one argument that is "ctx" as "context"
app.route('some route')
	.get(function(ctx){}) // add GET listener
	.get(function(ctx){}) // add second step GET listener
	.post(function(ctx){}) // add POST listener
	// ...
	// use promise like forme to add multiple listeners
	.get()
		.then(function(ctx){})
		.then(function(ctx){})
		.catch(function(ctx){
			// handle error at this step and continue with next then callback
			// call "ctx.error" to get error data
			})
		.then(function(ctx){})
		.finally(function(ctx))
		.end // go back so we can add an other method
	.post()
		.then(function{})
	//sub route
	.route('/sub-route')
		.get()
		.end

// form 2:
app.get('route') // other methods are supported too
	.use(function(ctx){}) // add middleware on this route (NB: middleware will be executed for subroutes too)

	.then(function(ctx){})
	.then(function(ctx){})
	.catch(function(ctx){})
	.finally(function(ctx){})
```

#### add error and final handler to a route
```javascript
/**
 * 1: specific error handler
 * used in promise form, the handler will be used at the specified point only
 */
	app.get('route')
		.then(function(ctx){})
		.catch(function(ctx){}) // this handler will be called at this point only
		.then(function(ctx){})
		.finally(function(ctx){}) // this isn't a handler that we will call when request finish (see promises)

/**
 * 2: global error hander:
 * will be used to handle errors from this route and subroutes
 * (when not handled by a previous handler)
 */
app.route('route')
	// add handler to all methods
	.catch(function(ctx){ // or async function
		// logic
		})
	// add handler to GET method only
	// "then" must not be in the pipeline, otherwise the meanning of "catch" and "finally" will change (to be promise like declaration of listeners)
	.get()
		.catch(function(ctx){})
		.catch(function(ctx){}) // add a second global handler (this will handle previous handler errors)
		.finally(function(ctx){}) // this callback will be called when the request finish on this route
		.end // go back to add an other method
	.end // go back to add an other route
```

#### add middleware
```javascript
// use promise forme
app.use(async function(ctx){
	await someProcess();
	})

// use callback form (compatible with expressjs middlewares)
app.useCb(function(req, res, next){
	# logic
	})
app.useCb(expressjsMiddleware())

// add middleware to a specific route and its subroutes
app.use('/route', function(ctx){})
app.useCb('/route', function(req, res, next){})

app
	.all('/route') // add on all routes
		.use(function(ctx){})
		.useCb(function(req, res, next){})
		.end
	.get('/route2') // add middleware on this route and its subroutes
		.use(function(ctx){})
		.useCb(function(req, res, next){})
		.end
	// use none popular http method (other then: GET, HEAD and POST)
	.method('copy', 'route', function(ctx){})
// remove middleware
app.removeMiddleware(middleware)
```

#### add some listener depending on some http header or query param
```javascript
app
	.get('/route')
		 // has header "accepts: application/json" or query: "?type=json"
		.when('json', function(ctx){})
		// multipe choices
		.when(['json', 'xml'], function(ctx){})
		// could use promise like form
		.when('html')
			.then(function(ctx){})
			//...
			.end
		// test function
		.when(function(ctx){
				// filter logic
			}, function(ctx){
				// main logic
			})
		.when(function(ctx){
				// filter logic
			})
			.then(function(){
				// main logic
			})
			.end
		// default hander when no "when" instruction matched
		.default(function(ctx){})
		// or promise like form
		.default()
			.then(function(ctx){})
```
### routes
route are:
- string
- regex (will not be indexed)
- array of above types
```javascript
app
	// static path
	.get('/path/to/resource', cb)
	.get(['/multiple', '/paths'], cb)
	// use simple params
	.get('/users/:uid/books/:bookId')
	.get('/files/{category}/{filename}')
	.get('/articles/:category/{name:/^[a-z]+$/}-{id:/^[0-9]{2}$/}.html')
	.get('/articles/:category/{name:objectId}-{id:number}.html')
	// params using regex
	.get({
		path: '/users/:uid/books/:bookId',
		params:{
			uid: /^[a-z]$/i,
			bookId: /^[0-9]{10}$/,
			//-----
			uid:{
				check: /^[a-z0-9]+$/i, // Regex or function that returns true or false
				convert: function(uid){
					return UserModel.findOne({_id: uid})
				}
			},
			// use Model types
			uid: Model.required.ObjectId
		},
		// handler
		handler: function(ctx){}
	})
// Regex: will not be indexed!
	.get(/\/[0-9]{15}$/, function(){})

// remove route
	app.route('route').remove() // remove all listeners on this route
	app.get('route').remove() // remove all listeners on this route for GET method
	app.get('route').remove(listener) // remove this listener
```

### "ctx" param
this parameter contains all required properties to handle your requests
#### request
* ctx.method: string, contains the HTTP method name
* ctx.ip	: string, contains client ip
* ctx.port	: number, contains client port
* ctx.url	: URL, contains full URL
	* .href		: string, full URL
	* .protocol	: used protocol
	* .host		: used host
	* .searchParams: access raw query
	* @see URL library for more posibilities
* ctx.mappingURL: string, contains this route mapping URL (sub url)
* ctx.params: object, contains path params
* ctx.query: object, contains query params
* ctx.cookies: object, contains cookies params
* ctx.route: Route, get current matching route
* ctx.secure: boolean, if we're using https
* ctx.xhr: boolean, if the request is sent by an xhr
* ctx.headers: Object, request headers
* ctx.body: when "POST", contains data sent by the client

#### response
scoped locals:
```javascript
// add param
ctx.locals.myParam = 'my value'
// remove param
delete ctx.locals.myParam
```
```javascript
ctx
	/**
	 * locals scoped in this request
	 */
	.locals
		.some param
	/**
	 * send data to the client
	 * @param {string|buffer} data
	 */
	.send(data)
	/**
	 * Serialize response as json and send it to client
	 * @param {serializable data} data
	 */
	.json(data)
```
#### commons
```javascript
	ctx.app // alias to core app object
```
#### Alias (we recommond you use those functions instead of otherones)
```javascript
	ctx.res.send	-> ctx.send
	ctx.res.json	-> ctx.json
	ctx.res.jsonp	-> ctx.jsonp
```


# listen on a port

## defined port
```javascript
app.listen(3000) // returns promise
```

## random port
```javascript
app.listen()
	.then(function(app){
		app.port // contains current port
		})
```

## defined/undefined port on specific path (needs nginx to works)
```javascript
app.listen({ // could be exported to config file or env vars
	port: 3000, // @optional, we recommand let the system choose the port for more flexibility
	secure: true|false, // @optional, when true, use "https" instead of "http"
	path: '/my-service' // will be added as a new instance on this path
	host: 'example.com'
	})
```

## use a registry
```javascript
app.listen({
	path: '/my-service' // will be added as a new instance on this path
	registry: 'http://localhost/registry'
	secret: 'secret key to connect to the registry'
	})
```

## defined port
```javascript
```