'use strict';
/* response */
var Buffer, CONTENT_TYPE_MAP, Context, DEFAULT_ENCODING, GError, LoggerFactory, Request, contentDisposition, encodeurl, fastDecode, gettersOnce, http, mimeType, onFinishLib, sendFile;

http = require('http');

fastDecode = require('fast-decode-uri-component');

Buffer = require('safe-buffer').Buffer;

encodeurl = require('encodeurl');

sendFile = require('send');

onFinishLib = require('on-finished');

contentDisposition = require('content-disposition');

mimeType = require('mime-types');

Request = require('./request');

LoggerFactory = require('../lib/logger');

({gettersOnce} = require('../lib/define-getter-once.coffee'));

GError = require('../lib/error');

DEFAULT_ENCODING = 'utf8';

Context = (function() {
  class Context extends http.ServerResponse {
    constructor(socket) {
      super(socket);
    }

    /**
     * redirect to this URL
     * @param {string} url - target URL
     * @param {boolean} isPermanent - If this is a permanent or temp redirect
     * (use this.redirectPermanent(url) in case of permanent redirect)
     */
    redirect(url, isPermanent) {
      // set location header
      this.setHeader('location', encodeurl(url));
      //TODO add some response (depending on "accept" header: text, html, json, ...)
      // status code
      this.statusCode(isPermanent ? 302 : 301);
      // end request
      return this.end();
    }

    /**
     * Permanent redirect to this URL
     */
    redirectPermanent(url) {
      return this.redirect(url, true);
    }

    /**
     * Redirect back (go back to referer)
     */
    redirectBack() {
      return this.redirect(this.req.getHeader('Referrer') || '/');
    }

    /**
     * Render page
     * @param  {[type]} path [description]
     * @return {[type]}      [description]
     */
    render(path, locals) {
      if (locals) {
        Object.setPrototypeOf(locals, this.locals);
      }
      return this.app._render(path, locals).then((html) => {
        this.setHeader('content-type', 'text/html');
        return this.end(html);
      });
    }

    /**
     * end request
     */
    end(data) {
      return new Promise(function(resolve, reject) {
        return super.end(data, function(err) {
          if (err) {
            return reject(err);
          } else {
            return resolve();
          }
        });
      });
    }

    /* response.write(chunk[, encoding], cb) */
    write(chunk, encoding) {
      return new Promise(function(res, rej) {
        return super.write(chunk, encoding || DEFAULT_ENCODING, function(err) {
          if (err) {
            return rej(err);
          } else {
            return res();
          }
        });
      });
    }

    /* content type */
    type(type) {
      if (typeof type !== 'string') {
        throw new Error('type expected string');
      }
      this.contentType = type;
      return this;
    }

    // 	switch arguments.length
    // 		when 1
    // 			@_type = type
    // 			this
    // 		when 0
    // 			@_type
    // switch arguments.length
    // 	when 1, 2
    // 		if type is 'bin'
    // 			@setHeader 'content-type', 'application/octet-stream'
    // 		else
    // 			@setHeader 'content-type', (CONTENT_TYPE_MAP[type] || type).concat '; charset=', encoding || DEFAULT_ENCODING
    // 		this
    // 	when 0
    // 		@getHeader 'content-type'
    // 	when 2
    // 		@setHeader 'content-type', type
    // 		this
    // 	else
    // 		throw new Error 'Illegal arguments'
    /* has type */
    hasType() {
      return this.hasHeader('content-type');
    }

  };

  // request class
  Context.Request = Request;

  return Context;

}).call(this);

module.exports = Context;

// add log support
LoggerFactory(Context.prototype);

Object.defineProperties(Context.prototype, {
  /**

   * parse query

   * enable user to define an other query parser,

   * by simply overriding this one

   * @param {string} rawQuery - query to parse

   * @return {Object} Map of all params

   * @example

   * ctx.QueryParser('param=value&param2=value2')

   */
  queryParser: {
    value: function(rawQuery) {
      var alreadyValue, i, idx, len, name, part, query, raw, value;
      query = {};
      raw = this.rawQuery;
      if (raw) {
        raw = raw.split('&');
        for (i = 0, len = raw.length; i < len; i++) {
          part = raw[i];
          // parse
          idx = part.indexOf('=');
          if (idx !== -1) {
            name = fastDecode(part.substr(0, idx));
            value = fastDecode(part.substr(idx + 1));
          } else {
            name = fastDecode(part);
            value = '';
          }
          // fix __proto__
          if (name === '__proto__') {
            this.warn('query-parser', 'Received param with illegal name: __proto__');
            name = '__proto';
          }
          // append to object
          alreadyValue = query[name];
          if (alreadyValue === void 0) {
            query[name] = value;
          } else if (typeof alreadyValue === 'string') {
            query[name] = [alreadyValue, value];
          } else {
            alreadyValue.push(value);
          }
        }
      }
      // return
      return query;
    }
  }
});

Object.defineProperties(Context.prototype, {
  /**
   * set status code
   */
  status: {
    value: function(status) {
      if (typeof status === 'number') {
        this.statusCode = status;
      } else if (typeof status === 'string') {
        this.statusMessage = status;
      } else {
        throw new Error('status expected number or string');
      }
      return this;
    }
  },
  /**
   * Send JSON
   * @param {Object} data - data to parse
   */
  json: {
    value: function(data) {
      // stringify data
      if (this.app.settings.pretty) {
        data = JSON.stringify(data, null, "\t");
      } else {
        data = JSON.stringify(data);
      }
      // send data
      if (this.contentType == null) {
        this.contentType = 'application/json';
      }
      return this.send(data);
    }
  },
  //TODO jsonp
  /**
   * Send response
   * @param {string | buffer | object} data - data to send
   */
  send: {
    value: function(data) { //TODO support user to specify if he wants JSON, Text, XML, ...
      var contentType, encoding, etag, ref, req, settings;
      settings = this.app.settings;
      encoding = this.encoding;
      // native request
      req = this.req;
      switch (typeof data) {
        case 'string':
          if (this.contentType == null) {
            this.contentType = 'text/html';
          }
          data = Buffer.from(data, encoding);
          break;
        case 'object':
          if (Buffer.isBuffer(data)) {
            if (this.contentType == null) {
              this.contentType = 'application/octet-stream';
            }
          } else {
            //TODO check accept header if we wants json or xml
            return this.json(data);
          }
          break;
        case 'undefined':
          if (this.contentType == null) {
            this.contentType = 'text/plain';
          }
          data = '';
          break;
        default:
          if (this.contentType == null) {
            this.contentType = 'text/plain';
          }
          data = data.toString();
      }
      
      // ETag
      if (!this.hasHeader('ETag')) {
        etag = settings.etag(data);
        if (etag) {
          this.setHeader('ETag', etag);
        }
      }
      if (this.statusCode !== 304 && req.fresh) {
        
        // freshness
        this.statusCode = 304;
      }
      // strip irrelevant headers
      if ((ref = this.statusCode) === 204 || ref === 304) {
        this.removeHeader('Content-Type');
        this.removeHeader('Content-Length');
        this.removeHeader('Transfer-Encoding');
        data = '';
      } else {
        // populate Content-Length
        this.setHeader('Content-Length', data.length);
        // set content type
        contentType = this.contentType;
        if (typeof contentType === 'string') {
          // fix content type
          if (contentType.indexOf('/') === -1) {
            contentType = mimeType.lookup(contentType);
            if (!contentType) {
              contentType = 'application/octet-stream';
            }
          }
          // add encoding
          contentType = contentType.concat('; charset=', encoding);
        } else {
          contentType = 'application/octet-stream';
        }
        // set as header
        this.setHeader('Content-Type', contentType);
      }
      
      // send
      if (req.method === 'HEAD') {
        this.end();
      } else {
        this.end(data, encoding);
      }
      return this;
    }
  },
  /**
   * Send file
   * @param {string} path - file path
   * @param {object} options - options
   */
  sendFile: {
    value: function(path, options) {
      return new Promise(function(resolve, reject) {
        var file, streaming;
        if (typeof path !== 'string') {
          // control
          throw new Error('path expected string');
        }
        path = encodeurl(path);
        // Prepare file streaming
        file = sendFile(this.req, path, options || {});
        // flags
        streaming = false;
        // done = no
        // Add callbacks
        file.on('directory', function() {
          return reject(new GError('EISDIR', 'EISDIR, read'));
        });
        file.on('stream', function() {
          return streaming = true;
        });
        file.on('file', function() {
          return streaming = false;
        });
        file.on('error', function() {
          return reject;
        });
        file.on('end', function() {
          return resolve;
        });
        // Execute a callback when a HTTP request closes, finishes, or errors.
        onFinishLib(this, function(err) {
          if (err) {
            // err.code = 'ECONNRESET'
            reject(err);
          }
          return setImmediate(function() {
            if (streaming) {
              return reject(new GError('ECONNABORTED', 'Request aborted'));
            } else {
              return resolve();
            }
          });
        });
        // add headers
        if (options.headers) {
          file.on('headers', function(res) {
            var k, ref, results, v;
            ref = options.headers;
            results = [];
            for (k in ref) {
              v = ref[k];
              results.push(res.setHeader(k, v));
            }
            return results;
          });
        }
        // pipe file
        return file.pipe(this);
      });
    }
  },
  /**
   * Download file
   * @param {string} path - file path
   * @optional @param {string} options.fileName - file name
   */
  download: {
    value: function(path, options) {
      // set headers
      if (options == null) {
        options = {};
      }
      if (options.headers == null) {
        options.headers = {};
      }
      options.headers['Content-Disposition'] = contentDisposition(options.fileName || path);
      // send
      return this.sendFile(path, options);
    }
  }
});

CONTENT_TYPE_MAP = {
  text: 'text/plain',
  html: 'text/html',
  js: 'text/javascript',
  javascript: 'text/javascript',
  css: 'text/css'
};

Object.defineProperties(Context.prototype, {
  /**
   * 
   */
  clearCookie: {
    value: function(name, options) {
      throw new Error('No cookie parser is found');
    }
  },
  cookie: {
    value: function(name, value, options) {
      throw new Error('No cookie parser is found');
    }
  }
});

gettersOnce(Context.prototype, {
  /* if the request is aborted */
  aborted: function() {
    return this.req.aborted;
  },
  /**
   * Key-value pairs of request header names and values. Header names are lower-cased.
   */
  reqHeaders: function() {
    return this.req.headers;
  },
  /**
   * HTTP version of th request
   */
  httpVersion: function() {
    return this.req.httpVersion;
  },
  /**
   * Used method
   */
  method: function() {
    return this.req.method;
  },
  /* protocol */
  protocol: function() {
    return this.req.protocol;
  },
  /* is https or http2 */
  secure: function() {
    return this.req.secure;
  },
  ip: function() {
    return this.req.ip;
  },
  hostname: function() {
    return this.req.hostname;
  },
  fresh: function() {
    return this.req.fresh;
  },
  /* if request made using xhr */
  xhr: function() {
    return this.req.xhr;
  },
  /* accept */
  _accepts: function() {
    return this.req._accepts;
  }
});

/* default values */
Object.defineProperties(Context.prototype, {
  encoding: {
    value: DEFAULT_ENCODING
  },
  contentType: {
    value: void 0
  }
});
