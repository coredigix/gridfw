###
this function will add a getter with a called once function
the result value will be cached in the object
###
module.exports =
	getterOnce: (proto, name, genFx)->
		Object.defineProperty proto, name,
			get: ->
				value = genFx.call this
				Object.defineProperty this, name, value: value