# Godot is being annoying with not allowing me to save an async function result to be awaited on later
# So I'm making a wrapper that lets me call an async function but await it later, for example, await multiple in parallel
class_name Promise
extends RefCounted

var _callable: Callable
var _is_finished: bool

signal finished

func _init(callable: Callable):
	_callable = callable
	_run()

func _run() -> void:
	_is_finished = false
	await _callable.call()
	_is_finished = true
	finished.emit()

static func all(promises: Array[Promise]):
	for p in promises:
		if not p._is_finished:
			await p.finished
