var http, server;

console.log('test http server');

http = require('http');

server = http.createServer(function(req, res) {
  console.log('---- got response');
});

server.on('request', function() {
  return console.log('request: ', arguments);
});

server.listen(3000, function(err) {
  console.log('listingin: ', err);
});
