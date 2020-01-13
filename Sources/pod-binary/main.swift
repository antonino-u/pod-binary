import Commandant

let registry = CommandRegistry<CommandantError<()>>()
registry.register(VersionCommand())
registry.register(BuildCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)
registry.main(defaultVerb: helpCommand.verb) { error in
    print(error)
}

