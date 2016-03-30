{isString, isObject, fromJSON, toJSON, Method} = require "fairmont"
YAML = require "js-yaml"

toYAML = (data) -> YAML.safeDump data
fromYAML = (yaml) -> YAML.safeLoad yaml

yaml = Method.create()

Method.define yaml, isString, fromYAML
Method.define yaml, isObject, toYAML

yaml.from = fromYAML
yaml.to = toYAML

json = Method.create()

Method.define json, isString, fromJSON
Method.define json, isObject, toJSON

json.from = fromJSON
json.to = toJSON

module.exports = {json, yaml}
