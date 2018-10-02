/* build config file */
var appSettings, data, fnts, fs, i, k, path, settings, v;

data = require('./settings');

fs = require('fs');

path = require('path');

// settings
appSettings = [];

// replace settings with an array, with is faster at runtime
i = 0;

settings = data.settings;

for (k in settings) {
  v = settings[k];
  settings[k] = i++;
  appSettings.push(v);
}

// save build config
fnts = [];

i = 0;

// stringify
appSettings = JSON.stringify(appSettings, function(k, v) {
  if (typeof v === 'function') {
    fnts.push(v);
    v = `__fx${i}__`;
    ++i;
  }
  return v;
});

// replace with function expression
appSettings = appSettings.replace(/"__fx(\d+)__"/g, function(_, i) {
  return fnts[i].toString();
});

appSettings = `const path = require('path');\nmodule.exports.config= ${appSettings}\nmodule.exports.kies= ${JSON.stringify(settings)}`;

// save
fs.writeFileSync(path.join(__dirname, 'config.js'), appSettings);
