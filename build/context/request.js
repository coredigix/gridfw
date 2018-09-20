'use strict';
/* commons with Context */
var Context, Request, fresh, gettersOnce, http, parseRange, props, proxyaddr;

http = require('http');

Context = require('.');

parseRange = require('range-parser');

proxyaddr = require('proxy-addr');

fresh = require('fresh');

({gettersOnce} = require('../lib/define-getter-once.coffee'));

/* response */
Request = class Request extends http.IncomingMessage {
  constructor(socket) {
    super(socket);
  }

  /**
  * Parse Range header field, capping to the given `size`.
  *
  * Unspecified ranges such as "0-" require knowledge of your resource length. In
  * the case of a byte range this is of course the total number of bytes. If the
  * Range header field is not given `undefined` is returned, `-1` when unsatisfiable,
  * and `-2` when syntactically invalid.
  *
  * When ranges are returned, the array has a "type" property which is the type of
  * range that is required (most commonly, "bytes"). Each array element is an object
  * with a "start" and "end" property for the portion of the range.
  *
  * The "combine" option can be set to `true` and overlapping & adjacent ranges
  * will be combined into a single range.
  *
  * NOTE: remember that ranges are inclusive, so for example "Range: users=0-3"
  * should respond with 4 users when available, not 3.
  *
  * @param {number} size
  * @param {object} [options]
  * @param {boolean} [options.combine=false]
  * @return {number|array}
  * @public
   */
  range(size, options) {
    var range;
    range = this.getHeader('Range');
    if (range) {
      return parseRange(size, range, options);
    }
  }

  /*
  @deprecated use "getHeader" instead
  used only to keep compatibility with expressjs
  */
  header(name) {
    return this.getHeader(name);
  }

  get(name) {
    return this.getHeader(name);
  }

};

module.exports = Request;

gettersOnce(Request.prototype, {
  /* accept */
  _accepts: function() {
    return accepts(this);
  },
  /* protocol */
  protocol: function() {
    var h, i, protocol;
    //Check for HTTP2
    protocol = this.connection.encrypted ? 'https' : 'http';
    // if trust immediate proxy headers
    if (this.app.settings.trustProxyFx(this, 0)) {
      h = this.getHeader('X-Forwarded-Proto');
      if (h) {
        i = h.indexOf(',');
        protocol = (i >= 0 ? h.substr(0, i) : h).trim();
      }
    }
    return protocol;
  },
  /* if we are using https */
  secure: function() {
    var ref;
    return (ref = this.protocol) === 'https' || ref === 'http2'; //TODO check for this
  },
  /* client IP */
  ip: proxyaddr(this, this.app.settings.trustProxyFx),
  /**
   * When "trust proxy" is set, trusted proxy addresses + client.
   *
   * For example if the value were "client, proxy1, proxy2"
   * you would receive the array `["client", "proxy1", "proxy2"]`
   * where "proxy2" is the furthest down-stream and "proxy1" and
   * "proxy2" were trusted.
   *
   * @return {Array}
   * @public
   */
  ips: function() {
    var addrs;
    addrs = proxyaddr(this, this.app.settings.trustProxyFx);
    addrs.reverse().pop();
    return addrs;
  },
  /**
   * Parse the "Host" header field to a hostname.
   *
   * When the "trust proxy" setting trusts the socket
   * address, the "X-Forwarded-Host" header field will
   * be trusted.
   *
   * @return {String}
   */
  hostname: function() {
    var host, trust;
    trust = this.app.settings.trustProxyFx;
    host = this.getHeader('X-Forwarded-Host');
    if (host && trust(this.connection.remoteAddress, 0)) {
      return host; //TODO check for IPv6 lateral support
    } else {
      return this.getHeader('host');
    }
  },
  /**
   * Check if the request is fresh, aka
   * Last-Modified and/or the ETag
   * still match.
   * @return {boolean}
   */
  fresh: function() {
    var method, res, status;
    method = this.method;
    res = this.res;
    status = res.statusCode;
    // only for "get" and "head"
    if ((method === 'GET' || method === 'HEAD') && ((200 <= status && status < 300) || status === 304)) {
      return fresh(this.headers, {
        etag: res.getHeader('ETag'),
        'last-modified': res.getHeader('Last-Modified')
      });
    } else {
      //TODO check for this it works
      return false;
    }
  },
  /*
   * Check if the request is stale, aka
   * "Last-Modified" and / or the "ETag" for the
   * resource has changed.
   * @return {boolean}
   */
  stale: function() {
    return !this.fresh;
  },
  xhr: function() {
    var ref;
    return ((ref = this.getHeader('X-Requested-With')) != null ? ref.toLowerCase() : void 0) === 'xmlhttprequest';
  }
});

props = {
  /* request: return first accepted type based on accept header */
  accepts: {
    value: function() {
      var acc;
      acc = this._accepts;
      return acc.encodings.apply(acc, arguments);
    }
  },
  /* Request: Check if the given `encoding`s are accepted.*/
  acceptsEncodings: {
    value: function() {
      var acc;
      acc = this._accepts;
      return acc.types.apply(acc, arguments);
    }
  },
  /* Check if the given `charset`s are acceptable */
  acceptsCharsets: {
    value: function() {
      var acc;
      acc = this._accepts;
      return acc.charsets.apply(acc, arguments);
    }
  },
  /* Check if the given `lang`s are acceptable, */
  acceptsLanguages: {
    value: function() {
      var acc;
      acc = this._accepts;
      return acc.languages.apply(acc, arguments);
    }
  }
};

Object.defineProperties(Context.prototype, props);

Object.defineProperties(Request.prototype, props);
