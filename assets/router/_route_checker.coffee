###*
 * Check all sub routes are compatible and optimized
 * use explicitly at production mode
 * We avoided to use a recursive function
###

Route.checker = ->
	errors = []
	nextNodes = [
		node: this
		path: []
	]
	avoidCirc = new Set() # to avoid cyclic call
	step = 0
	loop
		# current node
		currentStep = nextNodes[step]
		unless currentStep
			break
		currentNode = currentStep.node
		if avoidCirc.has currentNode
			continue
		avoidCirc.add currentNode
		# check all static values are not matched by a param regex
		nodeRegexes = currentNode[SR_PARAM_REGEXES]
		for k,v of currentNode[FIXED_SUB_ROUTE]
			for rgx in nodeRegexes
				if rgx.test k
					errors.push
						codeText: 'RegexMatchesKey'
						key: k
						path: '/' + currentStep.path.concat(k).join('/')
						message: "key <#{k}> matched by param regex: #{rgx}"
		#TODO: check two regexes arent equals, matches or infinit loop

		# add static sub nodes
		for k,v of currentNode[FIXED_SUB_ROUTE]
			nextNodes.push
				node: v
				path: currentStep.path.concat k
		# add parametred sub nodes
		pNodesNames = currentNode[SR_PARAM_NAMES]
		for k,v in currentNode[SR_PARAM_NODES]
			nextNodes.push
				node: v
				path: currentStep.path.concat pNodesNames[k]
		# next
		++step
	# return errors
	errors