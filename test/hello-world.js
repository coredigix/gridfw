/*
Hello world
*/
var GridFw, app;

GridFw = require('..');

// create server
app = new GridFw();

// append Get route
app.get('/', function(ctx) {
  ctx.info('My service', '--- Path "/" called');
  return ctx.send('Hello world');
});

// test GET
app.get('/hello/world', function(ctx) {
  ctx.info('My service', `---- got ${ctx.path}`);
  return ctx.send('hello dear');
});

// run the server at port 3000
app.listen(3000).then(function() {
  return app.log('Main', `Server listening At: ${app.port}`);
}).catch(function(err) {
  return app.error('Main', "Got Error: ", err);
});
