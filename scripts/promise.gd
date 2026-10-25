# Godot is being annoying with not allowing me to save an async function result to be awaited on later
# So I'm making a wrapper that lets me call an async function but await it later, for example, await multiple in parallel
class_name Promise
extends RefCounted

var _callable: Callable

signal finished

func _init(callable: Callable):
	_callable = callable
	_run()

func _run() -> void:
	await _callable.call()
	finished.emit()

static func all(promises: Array[Promise]):
	for p in promises:
		await p.finished
