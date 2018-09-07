
###*
 * Add route
 * @private
 * @param  {[type]} type    [description]
 * @param  {[type]} route   [description]
 * @param  {[type]} handler [description]
 * @return {[type]}         [description]
###
_AppendHandler= (router, type, route, handler)->





###*
this function will compiles routes into usable format
@private
@param {string} route - usable route to compile
@param {function} cb - call this function for each pease of the route
@example
* '/test/:varname/cc' compiled to: ['test', {n:'varname'}, 'cc']
* '/path/{varname:/^[a-z]$/}/to.html' is compiled to ['path', { n: 'varname', c: ->/^[a-z]$/.test }, 'to.html']
* '/path/{varname:number}/cc' compiled to ['path', {n: 'varname', c: -> /^\d+$/.test}, 'cc']
###
_compileRoute = (route, cb)->


###*
@private
split route into levels or directories
###
_splitRoute = (route, cb)->
	# init
	len = route.length
	pos = lastPos = if route[0] is '/' then 1 else 0
	varExpression = false
	varExpPart2 = false
	regex = false
	# loop
	loop
		c= route[pos]
		# if we are inside var expression {varname:expression}
		if varExpression
			# after ":"
			if varExpPart2
				# regex
				if regex
					# escape next char
					if c is '\\'
						++pos
					# close regex
					else if c is '/'
						regex = false
				# open regex
				else if c is '/'
					regex = true
				# close var expression
				else if c is '}'
					varExpression = varExpPart2 = false
			# before ":"
			else if c is ':'
				varExpPart2 = true
			# ends
			else if c is '}'
				varExpression = varExpPart2 = false
		# var expression
		else if c is '{'
			varExpression = true
		# next peace
		else if c is '/'
			cb route.substring lastPos, pos
			lastPos = pos + 1
		# break loop when ends
		++pos
		if pos >= len
			break
	# last peace of string
	if lastPos < len
		cb route.substring lastPos