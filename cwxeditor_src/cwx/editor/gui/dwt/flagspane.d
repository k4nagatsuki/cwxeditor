
module cwx.editor.gui.dwt.flagspane;

import cwx.summary;
import cwx.flag;
import cwx.utils;
import cwx.usecounter;
import cwx.path;
import cwx.types;
import cwx.menu;
import cwx.importutils;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.flagtable;
import cwx.editor.gui.dwt.flagdirtree;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;

import std.conv;

import org.eclipse.swt.all;

import java.lang.all;

/// 状態変数インスペクタ。
/// このコントロールを用いてフラグとステップの編集を行う。
public class FlagsPane : TCPD {
private:
	void storeAll() {
		_undo ~= new UndoAllVariables(_flags, _comm, _dirs.current, _dirs.rootDir);
	}

	Composite _comp;
	SplitPane _sash;
	Commons _comm;
	Props _prop;

	FlagDirTree _dirs;
	FlagTable _flags;
	TCPD _lastFocusTCPD = null;

	UndoManager _undo;

	void refScenario(Summary summ) { mixin(S_TRACE);
		_undo.reset();
	}
	void refUndoMax() { mixin(S_TRACE);
		_undo.max = _prop.var.etc.undoMaxMainView;
	}
public:
	this(Commons comm, Props prop) { mixin(S_TRACE);
		_comm = comm;
		_prop = prop;

		_undo = new UndoManager(_prop.var.etc.undoMaxMainView);
		_flags = new FlagTable(comm, prop, _undo);
		_dirs = new FlagDirTree(comm, prop, _flags, _undo);
	}

	void construct(Composite parent) { mixin(S_TRACE);
		_undo.reset();
		_comm.refScenario.add(&refScenario);
		_comm.refUndoMax.add(&refUndoMax);

		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout(new FillLayout);
		_sash = new SplitPane(_comp, _prop.var.etc.flagSashV ? SWT.VERTICAL : SWT.HORIZONTAL);

		_dirs.createControl(_sash, { mixin(S_TRACE);
			_lastFocusTCPD = _dirs;
		});
		_flags.createControl(_sash, _sash, { mixin(S_TRACE);
			_lastFocusTCPD = _flags;
		});
		_flags.setDir(_dirs.current, true);
		_lastFocusTCPD = _dirs;

		.setupWeights(_sash, _prop.var.etc.flagSashL, _prop.var.etc.flagSashR);
		_sdl = new DListener;
		_sash.addDisposeListener(_sdl);
	}
	private DListener _sdl;
	private class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refScenario.remove(&refScenario);
			_comm.refUndoMax.remove(&refUndoMax);
		}
	}
	void setupTLP(TopLevelPanel tlp) { mixin(S_TRACE);
		tlp.putMenuAction(MenuID.ChangeVH, &changeVHSide, null);
	}

	@property
	Control widget() { mixin(S_TRACE);
		return _comp;
	}

	@property
	string statusLine() {return _flags.statusLine;}

	void changeVHSide() { mixin(S_TRACE);
		_sash.removeDisposeListener(_sdl);
		_sash = .changeVHSide(_sash);
		.setupWeights(_sash, _prop.var.etc.flagSashL, _prop.var.etc.flagSashR);
		_sash.addDisposeListener(_sdl);
		_flags.updateIncSearchParent(_sash);
		_prop.var.etc.flagSashV = (_sash.getStyle() & SWT.VERTICAL) != 0;
	}

	/// 状態変数のパスをコピーする。
	@property
	bool canCopyVariablePath() { return _flags.canCopyVariablePath; }
	/// ditto
	void copyVariablePath() { _flags.copyVariablePath(); }

	/// フラグのディレクトリツリーを設定し、各コンポーネントに
	/// 指定されたツリーのデータを表示させる。
	/// Params:
	/// root = ツリーのルートディレクトリ。
	/// uc = 使用回数カウンタ。
	void setFlagDirTree(FlagDir root, UseCounter uc) { mixin(S_TRACE);
		_flags.useCounter = uc;
		_dirs.useCounter = uc;
		_dirs.rootDir = root;
	}

	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		return _dirs.openCWXPath(path, shellActivate);
	}
	@property
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		r ~= _dirs.openedCWXPath;
		r ~= _flags.openedCWXPath;
		return r;
	}

	void edit() { mixin(S_TRACE);
		_flags.edit();
	}
	@property
	bool canEdit() { mixin(S_TRACE);
		return _flags.canEdit;
	}

	@property
	FlagDirTree dirs() { mixin(S_TRACE);
		return _dirs;
	}

	@property
	FlagTable flags() { mixin(S_TRACE);
		return _flags;
	}

	/// 外部から状態変数を追加する。
	/// 重複するパスのものがあれば、上書きする。
	void addFlagsAndSteps(ImportFlag[][string] flags, ImportStep[][string]steps) { mixin(S_TRACE);
		if (!flags.length && !steps.length) return;
		storeAll();
		Flag[] fr;
		Step[] sr;
		FlagDir lastDir = null;
		foreach (path, fs; steps) { mixin(S_TRACE);
			auto dir = _dirs.rootDir.findPath(path, true);
			lastDir = dir;
			foreach (f; fs) { mixin(S_TRACE);
				auto f2 = dir.getStep(f.name);
				if (f2) { mixin(S_TRACE);
					f2.copyFrom(f);
					sr ~= f2;
				} else { mixin(S_TRACE);
					dir.add(f);
					sr ~= f;
				}
			}
		}
		foreach (path, fs; flags) { mixin(S_TRACE);
			auto dir = _dirs.rootDir.findPath(path, true);
			lastDir = dir;
			foreach (f; fs) { mixin(S_TRACE);
				auto f2 = dir.getFlag(f.name);
				if (f2) { mixin(S_TRACE);
					f2.copyFrom(f);
					fr ~= f2;
				} else { mixin(S_TRACE);
					dir.add(f);
					fr ~= f;
				}
			}
		}
		if (lastDir) { mixin(S_TRACE);
			_dirs.refresh(lastDir.path);
			_flags.deselectAll();
			foreach (f; fr) _flags.select(f, false);
			foreach (f; sr) _flags.select(f, false);
		} else { mixin(S_TRACE);
			_dirs.refresh();
		}
		_comm.refUseCount.call();
		_comm.refreshToolBar();
	}

	@property
	bool canUndo() { mixin(S_TRACE);
		return _undo.canUndo();
	}
	@property
	bool canRedo() { mixin(S_TRACE);
		return _undo.canRedo();
	}
	void undo() { mixin(S_TRACE);
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() { mixin(S_TRACE);
		_undo.redo();
		_comm.refreshToolBar();
	}

	void replaceID() {
		_flags.replaceID();
	}
	@property
	bool canReplaceID() {
		return _flags.canReplaceID;
	}

	@property
	bool canDoTCPD() { mixin(S_TRACE);
		return _lastFocusTCPD && _lastFocusTCPD.canDoTCPD;
	}
	@property
	bool canDoT() { mixin(S_TRACE);
		return _lastFocusTCPD && _lastFocusTCPD.canDoT;
	}
	@property
	bool canDoC() { mixin(S_TRACE);
		return _lastFocusTCPD && _lastFocusTCPD.canDoC;
	}
	@property
	bool canDoP() { mixin(S_TRACE);
		return _lastFocusTCPD && _lastFocusTCPD.canDoP;
	}
	@property
	bool canDoD() { mixin(S_TRACE);
		return _lastFocusTCPD && _lastFocusTCPD.canDoD;
	}
	@property
	bool canDoClone() { mixin(S_TRACE);
		return _lastFocusTCPD && _lastFocusTCPD.canDoClone;
	}
	void cut(SelectionEvent se) { mixin(S_TRACE);
		if (_lastFocusTCPD) _lastFocusTCPD.cut(se);
	}
	void copy(SelectionEvent se) { mixin(S_TRACE);
		if (_lastFocusTCPD) _lastFocusTCPD.copy(se);
	}
	void paste(SelectionEvent se) { mixin(S_TRACE);
		if (_lastFocusTCPD) _lastFocusTCPD.paste(se);
	}
	void del(SelectionEvent se) { mixin(S_TRACE);
		if (_lastFocusTCPD) _lastFocusTCPD.del(se);
	}
	void clone(SelectionEvent se) { mixin(S_TRACE);
		if (_lastFocusTCPD) _lastFocusTCPD.clone(se);
	}
}
