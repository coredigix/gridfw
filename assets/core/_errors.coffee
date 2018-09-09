# ###
# App Errors
# We didnt extends "Error" for performance
# ###

# class GridError
# 	constructor: (code= -1, message)->
# 		if arguments.length is 1
# 			message = _mapCodes[code]
# 		super message
# 		Object.defineProperties this,
# 			code: value: code

# 	# const
# 	@NOT_FOUND: 404

# ### get message from code ###
# _mapCodes=
# 	'404': 'Not found'


# ### not found eror ###
# class NotFoundError extends GridError
# 	constructor: (path, message)->
# 		super GridError.NOT_FOUND, message
# 		Object.defineProperties this,
# 			path: value: path
# ------------------
# 404: not found