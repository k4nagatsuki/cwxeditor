
module cwx.editor.gui.dwt.undo;

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
	this (T old, T n, void delegate(T) set, T delegate(T) copy = null) {
		_old = old;
		_new = n;
		_set = set;
		_copy = copy;
	}
	void undo() {
		if (_copy) _old = _copy(_old);
		_set(_old);
	}
	void redo() {
		if (_copy) _new = _copy(_new);
		_set(_new);
	}
	void dispose() {
		// Nothing
	}
}
/// ditto
class StrUndo : TUndo!(string) {
	this (string old, string n, void delegate(string) set) {
		super (old, n, set, null);
	}
}
/// ditto
class StrArrUndo : TUndo!(string[]) {
	this (string[] old, string[] n, void delegate(string[]) set) {
		super (old.dup, n.dup, set, (string[] v) {return v.dup;});
	}
}

class UndoArr : Undo {
	private Undo[] _array;
	private bool _rev;
	this (Undo[] array, bool rev = true) {
		_array = array;
		_rev = rev;
	}
	void undo() {
		if (_rev) {
			foreach_reverse (u; _array) u.undo();
		} else {
			foreach (u; _array) u.undo();
		}
	}
	void redo() {
		foreach (u; _array) u.redo();
	}
	void dispose() {
		foreach (u; _array) u.dispose();
	}
}

class UndoManager {
	private Undo[] _undos;
	private size_t _max;
	private size_t _pointer;
	this (size_t max) {
		_max = max;
	}
	void opCatAssign(Undo undo) {
		add(undo);
	}
	@property
	void max(size_t v) {
		_max = v;
		cut();
	}
	private void cut() {
		if (_max < _pointer) {
			_undos = _undos[_pointer - _max .. $];
			_pointer = _max;
		}
	}
	@property
	size_t pointer() {return _pointer;}
	void add(Undo undo) {
		if (_max == 0) return;
		if (_undos.length && _pointer < _undos.length) {
			foreach (u; _undos[_pointer .. $]) {
				u.dispose();
			}
			_undos = _undos[0 .. _pointer];
		}
		if (_undos.length >= _max) {
			size_t i = _undos.length - _max + 1;
			for (size_t j = 0; j < i; j++) {
				_undos[j].dispose();
			}
			_undos = _undos[i .. $];
		}
		_undos ~= undo;
		_pointer = _undos.length;
	}
	@property
	bool canUndo() {return _pointer > 0;}
	bool undo() {
		if (!canUndo) return false;
		// 例外対策のため_pointer--を後に
		_undos[_pointer - 1].undo();
		_pointer--;
		return true;
	}
	@property
	bool canRedo() {return _pointer < _undos.length;}
	bool redo() {
		if (!canRedo) return false;
		_undos[_pointer].redo();
		_pointer++;
		cut();
		return true;
	}
	void reset() {
		if (!_undos.length) return;
		dispose();
	}
	void dispose() {
		if (!_undos.length) return;
		foreach (u; _undos) u.dispose();
		_undos.length = 0;
		_pointer = 0;
	}
}
