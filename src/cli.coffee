{usage} = require "./messages"
Commands = require "./commands"

[_, _, name, argv...] = process.argv

if (command = Commands[name]?)
  # Options.parse "cluster-#{name}", argv
  command argv # options?
else
  usage "bad-command", {name}
