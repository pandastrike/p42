{include} = require "fairmont"

module.exports = (args...) -> throw include (new Error), p42: args
