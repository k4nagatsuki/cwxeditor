
module cwx.editor.gui.dwt.flagspane;

import cwx.summary;
import cwx.flag;
import cwx.utils;
import cwx.usecounter;
import cwx.path;
import cwx.types;
import cwx.menu;

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
public class FlagsPane {
private:
	Composite _comp;
	SplitPane _sash;
	Commons _comm;
	Props _prop;

	FlagDirTree _dirs;
	FlagTable _flags;

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

		_dirs.createControl(_sash);
		_flags.createControl(_sash, _sash);
		_flags.setDir(_dirs.current, true);

		_sash.setWeights([_prop.var.etc.flagSashL, _prop.var.etc.flagSashR]);
		_sdl = new DListener;
		_sash.addDisposeListener(_sdl);
	}
	private DListener _sdl;
	private class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refScenario.remove(&refScenario);
			_comm.refUndoMax.remove(&refUndoMax);
			_prop.var.etc.flagSashL = _sash.getWeights()[0];
			_prop.var.etc.flagSashR = _sash.getWeights()[1];
			_prop.var.etc.flagSashV = (_sash.getStyle() & SWT.VERTICAL) != 0;
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
		_sash.addDisposeListener(_sdl);
		_flags.updateIncSearchParent(_sash);
	}

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

	@property
	FlagDirTree dirs() { mixin(S_TRACE);
		return _dirs;
	}

	@property
	FlagTable flags() { mixin(S_TRACE);
		return _flags;
	}

	@property
	bool canUp() { mixin(S_TRACE);
		return _dirs.canUp;
	}
	@property
	bool canDown() { mixin(S_TRACE);
		return _dirs.canDown;
	}
	void up() { mixin(S_TRACE);
		_dirs.up();
	}
	void down() { mixin(S_TRACE);
		_dirs.down();
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
}
