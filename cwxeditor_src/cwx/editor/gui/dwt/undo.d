
module cwx.editor.gui.dwt.undo;

import cwx.utils;

interface Undo {
	void undo();
	void redo();
	void dispose();
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
		dispose();
	}
	void dispose() {
		foreach (u; _undos) u.dispose();
		_undos.length = 0;
		_pointer = 0;
	}
}
