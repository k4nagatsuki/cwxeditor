
module cwx.editor.gui.dwt.undo;

import cwx.perf;

interface Undo {
	void undo();
	void redo();
	void dispose();
}

/// 最も簡易なUndoの実装。
class TUndo(T) : Undo {
	private T _old;
	private T _new;
	private void delegate(T) _set;
	T delegate(T) _copy;
	this (T old, T n, void delegate(T) set, T delegate(T) copy = null) { mixin(S_TRACE);
		_old = old;
		_new = n;
		_set = set;
		_copy = copy;
	}
	void undo() { mixin(S_TRACE);
		if (_copy) _old = _copy(_old);
		_set(_old);
	}
	void redo() { mixin(S_TRACE);
		if (_copy) _new = _copy(_new);
		_set(_new);
	}
	void dispose() { mixin(S_TRACE);
		// Nothing
	}
}
/// ditto
class StrUndo : TUndo!(string) {
	this (string old, string n, void delegate(string) set) { mixin(S_TRACE);
		super (old, n, set, null);
	}
}
/// ditto
class StrArrUndo : TUndo!(string[]) {
	this (string[] old, string[] n, void delegate(string[]) set) { mixin(S_TRACE);
		super (old.dup, n.dup, set, (string[] v) { return v.dup; });
	}
}

class UndoArr : Undo {
	private Undo[] _array;
	private bool _rev;
	private void delegate() _after;
	this (Undo[] array, bool rev = true, void delegate() after = null) { mixin(S_TRACE);
		_array = array;
		_rev = rev;
		_after = after;
	}
	void undo() { mixin(S_TRACE);
		if (_rev) { mixin(S_TRACE);
			foreach_reverse (u; _array) u.undo();
		} else { mixin(S_TRACE);
			foreach (u; _array) u.undo();
		}
		if (_after) _after();
	}
	void redo() { mixin(S_TRACE);
		foreach (u; _array) u.redo();
		if (_after) _after();
	}
	void dispose() { mixin(S_TRACE);
		foreach (u; _array) u.dispose();
	}
}

class UndoManager {
	private Undo[] _undos;
	private size_t _max;
	private size_t _pointer;
	this (size_t max) { mixin(S_TRACE);
		_max = max;
	}
	void opOpAssign(string op)(Undo undo) if (op == "~") { mixin(S_TRACE);
		add(undo);
	}
	@property
	void max(size_t v) { mixin(S_TRACE);
		_max = v;
		cut();
	}
	private void cut() { mixin(S_TRACE);
		if (_max < _pointer) { mixin(S_TRACE);
			_undos = _undos[_pointer - _max .. $];
			_pointer = _max;
		}
	}
	@property
	size_t pointer() { return _pointer; }
	void add(Undo undo) { mixin(S_TRACE);
		if (_max == 0) return;
		if (_undos.length && _pointer < _undos.length) { mixin(S_TRACE);
			foreach (u; _undos[_pointer .. $]) { mixin(S_TRACE);
				u.dispose();
			}
			_undos = _undos[0 .. _pointer];
		}
		if (_undos.length >= _max) { mixin(S_TRACE);
			size_t i = _undos.length - _max + 1;
			for (size_t j = 0; j < i; j++) { mixin(S_TRACE);
				_undos[j].dispose();
			}
			_undos = _undos[i .. $];
		}
		_undos ~= undo;
		_pointer = _undos.length;
	}
	@property
	bool canUndo() { return _pointer > 0; }
	bool undo() { mixin(S_TRACE);
		if (!canUndo) return false;
		// 例外対策のため_pointer--を後に
		_undos[_pointer - 1].undo();
		_pointer--;
		return true;
	}
	@property
	bool canRedo() { return _pointer < _undos.length; }
	bool redo() { mixin(S_TRACE);
		if (!canRedo) return false;
		_undos[_pointer].redo();
		_pointer++;
		cut();
		return true;
	}
	void reset() { mixin(S_TRACE);
		if (!_undos.length) return;
		dispose();
	}
	void dispose() { mixin(S_TRACE);
		if (!_undos.length) return;
		foreach (u; _undos) u.dispose();
		_undos.length = 0;
		_pointer = 0;
	}
}
