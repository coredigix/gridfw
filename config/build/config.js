module.exports=["GridFW","contact@coredigix.com","debug",50,0,function(app, mode) {
    //TODO
    return function(req, proxyLevel) {
      return true;
    };
  },function(app, mode) {
    return mode === 0; // true if dev mode
  },function(app, mode) {
    return function(data) {
      return '';
    };
  }]