
module cwx.editor.gui.dwt.flagspane;

import cwx.flag;
import cwx.utils;
import cwx.usecounter;
import cwx.path;

import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.flagtable;
import cwx.editor.gui.dwt.flagdirtree;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.xmlbytestransfer;

import dwt.DWT;
import dwt.DWTException;
import dwt.widgets.Shell;
import dwt.widgets.Control;
import dwt.widgets.Display;
import dwt.layout.FillLayout;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.custom.SashForm;
import dwt.widgets.Composite;
import dwt.widgets.Tree;
import dwt.widgets.TreeItem;
import dwt.custom.TreeEditor;
import dwt.widgets.Table;
import dwt.widgets.TableColumn;
import dwt.widgets.TableItem;
import dwt.widgets.Text;
import dwt.widgets.Label;
import dwt.widgets.Combo;
import dwt.widgets.Table;
import dwt.widgets.ToolBar;
import dwt.widgets.ToolItem;
import dwt.events.SelectionEvent;
import dwt.events.SelectionAdapter;
import dwt.events.FocusEvent;
import dwt.events.FocusListener;
import dwt.events.DisposeEvent;
import dwt.events.DisposeListener;
import dwt.events.KeyAdapter;
import dwt.events.KeyEvent;
import dwt.events.MouseListener;
import dwt.events.MouseAdapter;
import dwt.events.MouseEvent;
import dwt.events.ModifyListener;
import dwt.events.ModifyEvent;
import dwt.graphics.Image;
import dwt.graphics.ImageData;
import dwt.dwthelper.utils;
import dwt.dnd.DND;
import dwt.dnd.Transfer;
import dwt.dnd.TransferData;
import dwt.dnd.DragSource;
import dwt.dnd.DragSourceListener;
import dwt.dnd.DragSourceEvent;
import dwt.dnd.ByteArrayTransfer;
import dwt.dnd.DropTargetAdapter;
import dwt.dnd.DropTargetEvent;
import dwt.dnd.DropTarget;

/// 状態変数インスペクタ。
/// このコントロールを用いてフラグとステップの編集を行う。
public class FlagsPane {
private:
	Composite _comp;
	SplitPane _sash;
	Props _prop;

	FlagDirTree _dirs;
	FlagTable _flags;

public:
	this(Commons comm, Props prop, Composite parent, bool chgVH) {
		_prop = prop;

		_comp = new Composite(parent, DWT.NONE);
		_comp.setLayout = new FillLayout;
		_sash = new SplitPane(_comp, _prop.var.etc.flagSashV ? DWT.VERTICAL : DWT.HORIZONTAL);

		_flags = new FlagTable(comm, prop);
		_dirs = new FlagDirTree(comm, prop, _flags);

		if (chgVH) {
			auto left = new Composite(_sash, DWT.NONE);
			left.setLayout = zeroGridLayout(1, true);
			_sash.setControl1 = left;
			auto bar = new ToolBar(left, DWT.FLAT);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			createToolItem(bar, _prop.msgs.ttChangeVH, _prop.images.menuChangeVH, &changeVHSide);
			_dirs.createControl(left);
			_dirs.widget.setLayoutData = new GridData(GridData.FILL_BOTH);
		} else {
			_sash.setControl1 = _dirs.createControl(_sash);
		}
		_sash.setControl2 = _flags.createControl(_sash);

		_sash.setWeights([_prop.var.etc.flagSashL, _prop.var.etc.flagSashR]);
		_sdl = new DListener;
		_sash.addDisposeListener(_sdl);
	}
	private DListener _sdl;
	private class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_prop.var.etc.flagSashL = _sash.getWeights[0];
			_prop.var.etc.flagSashR = _sash.getWeights[1];
			_prop.var.etc.flagSashV = (_sash.getStyle & DWT.VERTICAL) != 0;
		}
	}

	Control widget() {
		return _comp;
	}

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

	bool openCWXPath(string path) {
		return _dirs.openCWXPath(path);
	}

	FlagDirTree dirs() {
		return _dirs;
	}

	FlagTable flags() {
		return _flags;
	}
}
