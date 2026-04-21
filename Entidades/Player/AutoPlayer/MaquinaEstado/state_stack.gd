class_name StateStack
extends RefCounted

var _stack: Array[BaseState] = []

func push(state: BaseState) -> void:
	if not _stack.is_empty():
		_stack.back().on_suspend()
	_stack.append(state)
	state.on_enter()

func pop() -> void:
	if _stack.is_empty(): return
	_stack.back().on_exit()
	_stack.pop_back()
	if not _stack.is_empty():
		_stack.back().on_resume()

func replace(state: BaseState) -> void:
	if not _stack.is_empty():
		_stack.back().on_exit()
		_stack.pop_back()
	push(state)

func peek() -> BaseState:
	return _stack.back() if not _stack.is_empty() else null

# Llama physics_process en TODOS los estados apilados (de abajo a arriba)
# Útil para que turbo/nitro se ejecuten sobre driving/air
func process_all(delta: float) -> void:
	for state in _stack:
		state.physics_process(delta)
