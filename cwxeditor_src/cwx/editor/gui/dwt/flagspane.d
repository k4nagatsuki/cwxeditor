
module cwx.editor.gui.dwt.flagspane;

import cwx.flag;
import cwx.usecounter;

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
	SplitPane _sash;
	Props _prop;

	FlagDirTree _dirs;
	FlagTable _flags;

public:
	this(Commons comm, Props prop, Composite parent) {
		_sash = new SplitPane(parent, DWT.HORIZONTAL);
		_prop = prop;

		_flags = new FlagTable(comm, prop);
		_dirs = new FlagDirTree(comm, prop, _flags);

		_sash.setControl1 = _dirs.createControl(_sash);
		_sash.setControl2 = _flags.createControl(_sash);

		_sash.setWeights([_prop.var.etc.flagSashL, _prop.var.etc.flagSashR]);
		_sash.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_prop.var.etc.flagSashL = _sash.getWeights[0];
				_prop.var.etc.flagSashR = _sash.getWeights[1];
			}
		});
	}

	SplitPane widget() {
		return _sash;
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

	FlagDirTree dirs() {
		return _dirs;
	}

	FlagTable flags() {
		return _flags;
	}
}
