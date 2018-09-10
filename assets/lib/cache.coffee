###*
 * memory cache lib
 * @constructor ({ttl, interval})
 * @method get(key)	- get object by key
 * @method set(key, value) - set value
 *
 * TODO: check if this cache is performant
 * create cache on first insert of data
 * remove to whol cache if no data inserted for a while
 * possibility to change TTL
###
module.exports = require 'memory-cache-ttl'