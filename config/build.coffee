### build config file ###
data= require './settings'
fs = require 'fs'
path = require 'path'

# settings
appSettings = []

# replace settings with an array, with is faster at runtime
i=0
settings = data.settings
for k,v of settings
	settings[k] = i++
	appSettings.push v
# save build config
fnts = []
i=0
# stringify
appSettings = JSON.stringify appSettings, (k, v)->
	if typeof v is 'function'
		fnts.push v
		v = "__fx#{i}__"
		++i
	v
# replace with function expression
appSettings= appSettings.replace /"__fx(\d+)__"/g, (_, i)->
	fnts[i].toString()

appSettings = """
const path = require('path');
module.exports.config= #{appSettings}
module.exports.kies= #{JSON.stringify(settings)}
"""

# save
fs.writeFileSync path.join(__dirname, 'config.js') , appSettings

