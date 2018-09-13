


Object.defineProperties Context.prototype,
	###*
	 * parse query
	 * enable user to define an other query parser,
	 * by simply overriding this one
	 * @param {string} rawQuery - query to parse
	 * @return {Object} Map of all params
	 * @example
	 * ctx.QueryParser('param=value&param2=value2')
	###
	queryParser: value: (rawQuery)->
		query = {}
		raw = @rawQuery
		if raw
			raw = raw.split '&'
			for part in raw
				# parse
				idx = part.indexOf '='
				if idx isnt -1
					name = fastDecode part.substr 0, idx
					value= fastDecode part.substr idx + 1
				else
					name = fastDecode part
					value = ''
				# fix __proto__
				if name is '__proto__'
					@warn 'query-parser', 'Received param with illegal name: __proto__'
					name = '__proto'
				# append to object
				alreadyValue = query[name]
				if alreadyValue is undefined
					query[name] = value
				else if typeof alreadyValue is 'string'
					query[name] = [alreadyValue, value]
				else
					alreadyValue.push value
		# return
		query