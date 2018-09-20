/*
this function will add a getter with a called once function
the result value will be cached in the object
*/
var _getterProxy;

module.exports = {
  // define one getter one
  getterOnce: function(proto, name, genFx) {
    return Object.defineProperty(proto, name, {
      get: function() {
        var value;
        value = genFx.call(this);
        Object.defineProperty(this, name, {
          value: value
        });
        return value;
      }
    });
  },
  // define multiple getters
  getterOnce: function(proto, descriptor) {
    var k, v;
// init descriptor
    for (k in descriptor) {
      v = descriptor[k];
      if (typeof v !== 'function') {
        throw new Error(`Illegal getter of ${k}`);
      }
      descriptor[k] = _getterProxy(k, v);
    }
    // define
    return proto.defineProperties(proto, descriptor);
  }
};

_getterProxy = function(k, v) {
  return function() {
    var value;
    value = v.call(this);
    Object.defineProperty(this, k, {
      value: value
    });
    return value;
  };
};
