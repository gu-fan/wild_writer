class_name CommandManager
extends Node

signal command_executed(command: Command)

var commands: Dictionary = {}
var command_history: Array[Command]

class Command:
    var id: String
    var execute: Callable
    var undo: Callable
    var args: Array

func register_command(id: String, execute: Callable, undo: Callable = Callable()):
    commands[id] = {
        "execute": execute,
        "undo": undo
    }

func execute_command(id: String, args: Array = []):
    if commands.has(id):
        var cmd = Command.new()
        cmd.id = id
        cmd.args = args
        commands[id].execute.callv(args)
        command_history.append(cmd)
        emit_signal("command_executed", cmd)
