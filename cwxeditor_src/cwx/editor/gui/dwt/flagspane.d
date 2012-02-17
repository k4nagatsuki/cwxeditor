
module cwx.editor.gui.dwt.flagspane;

import cwx.summary;
import cwx.flag;
import cwx.utils;
import cwx.usecounter;
import cwx.path;
import cwx.msgs;
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

import org.eclipse.swt.SWT;
import org.eclipse.swt.SWTException;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.custom.SashForm;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;
import org.eclipse.swt.custom.TreeEditor;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.FocusEvent;
import org.eclipse.swt.events.FocusListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.MouseListener;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import java.lang.all;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.Transfer;
import org.eclipse.swt.dnd.TransferData;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DragSourceListener;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.ByteArrayTransfer;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTarget;

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

	void refScenario(Summary summ) {
		_undo.reset();
	}
	void refUndoMax() {
		_undo.max = _prop.var.etc.undoMaxMainView;
	}
public:
	this(Commons comm, Props prop) {
		_comm = comm;
		_prop = prop;

		_undo = new UndoManager(_prop.var.etc.undoMaxMainView);
		_flags = new FlagTable(comm, prop, _undo);
		_dirs = new FlagDirTree(comm, prop, _flags, _undo);
	}

	void construct(Composite parent) {
		_undo.reset();
		_comm.refScenario.add(&refScenario);
		_comm.refUndoMax.add(&refUndoMax);

		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout(new FillLayout);
		_sash = new SplitPane(_comp, _prop.var.etc.flagSashV ? SWT.VERTICAL : SWT.HORIZONTAL);

		_dirs.createControl(_sash);
		_flags.createControl(_sash);
		_flags.setDir(_dirs.current, true);

		_sash.setWeights([_prop.var.etc.flagSashL, _prop.var.etc.flagSashR]);
		_sdl = new DListener;
		_sash.addDisposeListener(_sdl);
	}
	private DListener _sdl;
	private class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refScenario.remove(&refScenario);
			_comm.refUndoMax.remove(&refUndoMax);
			_prop.var.etc.flagSashL = _sash.getWeights()[0];
			_prop.var.etc.flagSashR = _sash.getWeights()[1];
			_prop.var.etc.flagSashV = (_sash.getStyle() & SWT.VERTICAL) != 0;
		}
	}
	void setupTLP(TopLevelPanel tlp) {
		tlp.putMenuAction(MenuID.ChangeVH, &changeVHSide);
	}

	@property
	Control widget() {
		return _comp;
	}

	@property
	string statusLine() {return _flags.statusLine;}

	void changeVHSide() {
		_sash.removeDisposeListener(_sdl);
		_sash = .changeVHSide(_sash);
		_sash.addDisposeListener(_sdl);
	}

	/// フラグのディレクトリツリーを設定し、各コンポーネントに
	/// 指定されたツリーのデータを表示させる。
	/// Params:
	/// root = ツリーのルートディレクトリ。
	/// uc = 使用回数カウンタ。
	void setFlagDirTree(FlagDir root, UseCounter uc) {
		_flags.useCounter = uc;
		_dirs.useCounter = uc;
		_dirs.rootDir = root;
	}

	bool openCWXPath(string path, bool shellActivate) {
		return _dirs.openCWXPath(path, shellActivate);
	}
	@property
	string[] openedCWXPath() {
		string[] r;
		r ~= _dirs.openedCWXPath;
		r ~= _flags.openedCWXPath;
		return r;
	}

	@property
	FlagDirTree dirs() {
		return _dirs;
	}

	@property
	FlagTable flags() {
		return _flags;
	}

	@property
	bool canUp() {
		return _dirs.canUp;
	}
	@property
	bool canDown() {
		return _dirs.canDown;
	}
	void up() {
		_dirs.up();
	}
	void down() {
		_dirs.down();
	}

	@property
	bool canUndo() {
		return _undo.canUndo();
	}
	@property
	bool canRedo() {
		return _undo.canRedo();
	}
	void undo() {
		_undo.undo();
	}
	void redo() {
		_undo.redo();
	}
}
