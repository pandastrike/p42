{include} = require "fairmont"
module.exports = (args...) -> throw include (new Error), info: args
