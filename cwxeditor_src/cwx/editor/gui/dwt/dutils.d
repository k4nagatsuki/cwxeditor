
module cwx.editor.gui.dwt.dutils;

import cwx.cwl;
import cwx.card;
import cwx.types;
import cwx.utils;
import cwx.features;
import cwx.archive;
import cwx.summary;
import cwx.usecounter;
import cwx.props;
import cwx.imagesize;
import cwx.skin;
import cwx.cab;
import cwx.structs;
import cwx.event;

import cwx.editor.gui.sound;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.jpyimage;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.variables;

import core.thread;

import std.algorithm : lastIndexOf;
import std.array;
import std.conv;
import std.utf;
import std.ascii;
import std.zip;
import std.file;
import std.datetime;
import std.path;
import std.process;

import org.eclipse.swt.SWTException;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.CoolBar;
import org.eclipse.swt.widgets.CoolItem;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Scale;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.TabFolder;
import org.eclipse.swt.widgets.Sash;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.swt.custom.CLabel;
import org.eclipse.swt.custom.CCombo;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.TreeEditor;
import org.eclipse.swt.custom.TableEditor;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.MouseTrackAdapter;
import org.eclipse.swt.events.MouseWheelListener;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.FocusListener;
import org.eclipse.swt.events.FocusEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.ControlAdapter;
import org.eclipse.swt.events.ControlEvent;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.PaletteData;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.graphics.Cursor;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.program.Program;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.FileTransfer;
import java.lang.all;
import java.io.ByteArrayInputStream;

public:

bool dwtImageSize(Skin skin, string path, out uint width, out uint height) {
	auto ext = cwx.utils.getExt(path);
	if (cfnmatch(ext, "jpy1")
			|| cfnmatch(ext, "jptx")
			|| cfnmatch(ext, "jpdc")) {
		auto img = loadJPYImage(skin, path, []);
		if (img) {
			width = img.width;
			height = img.height;
			return true;
		}
		return false;
	}
	return imageSize(path, width, height);
}

ImageData loadImage(string path, bool mask = true, int maskX = 0, int maskY = 0) {
	return loadImage(null, path, mask, maskX, maskY);
}
ImageData loadImage(Skin skin, string path, bool mask = true, int maskX = 0, int maskY = 0, string[] stratum = []) {
	if (!isBinImg(path) && contains(stratum, nabs(path))) {
		// 無限再帰を回避
		return blankImage;
	}
	if (path !is null && path.length > 0) {
		string ext = cwx.utils.getExt(path);
		if (cfnmatch(ext, "jpy1")
				|| cfnmatch(ext, "jptx")
				|| cfnmatch(ext, "jpdc")) {
			auto data = loadJPYImage(skin, path, stratum);
			if (mask) data.transparentPixel = data.getPixel(maskX, maskY);
			return data;
		}
		try {
			byte[] bytes;
			if (isBinImg(path)) {
				bytes = cast(byte[]) strToBImg(path);
			} else {
				if (!.exists(path)) return blankImage;
				bytes = cast(byte[]) std.file.read(path);
			}
			auto s = new ByteArrayInputStream(bytes);
			scope (exit) s.close();
			auto data = new ImageData(s);
			if (mask) data.transparentPixel = data.getPixel(maskX, maskY);
			return data;
		} catch (SWTException e) {
			debugln(e);
		}
	}
	return blankImage;
}

@property
ImageData blankImage() {
	auto data = new ImageData(1, 1, 8, new PaletteData(0, 0, 0));
	data.transparentPixel = data.getPixel(0, 0);
	return data;
}

alias ArrayWrapperString PathString;
alias ArrayWrapperString2 FileNames;

string wrapReturnCode(string str) {
	version (Windows) {
		return std.array.replace(str, "\r\n", "\n");
	} else {
		return str;
	}
}

GridLayout zeroGridLayout(int col, bool eqWid = false) {
	auto gl = new GridLayout(col, eqWid);
	gl.horizontalSpacing = 0;
	gl.verticalSpacing = 0;
	gl.marginWidth = 0;
	gl.marginHeight = 0;
	return gl;
}

GridLayout zeroMarginGridLayout(int col, bool eqWid) {
	auto gl = new GridLayout(col, eqWid);
	gl.marginWidth = 0;
	gl.marginHeight = 0;
	return gl;
}

const WGL_SPACING = 2;

GridLayout windowGridLayout(int col, bool eqWid = false) {
	auto gl = new GridLayout(col, eqWid);
	gl.horizontalSpacing = WGL_SPACING;
	gl.verticalSpacing = WGL_SPACING;
	gl.marginWidth = WGL_SPACING;
	gl.marginHeight = WGL_SPACING;
	return gl;
}

void setGridMinW(Control c, int minW, int gridStyle = SWT.NULL) {
	auto gd = new GridData(gridStyle);
	int w = c.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
	gd.widthHint = w > minW ? w : minW;
	c.setLayoutData(gd);
}

Composite centerGroup(Composite parent, string text, bool fillH = true, bool fillV = false, Object layoutData = null) {
	auto grp = new Group(parent, SWT.NONE);
	grp.setLayoutData(layoutData);
	auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
	cl.fillHorizontal = fillH;
	cl.fillVertical = fillV;
	grp.setLayout(cl);
	grp.setText(text);
	auto comp = new Composite(grp, SWT.NONE);
	return comp;
}

class SpinnerEdit {
private:
	Spinner _spn;
	int _oldVal;
	void delegate(int value) _edit;
	void delegate(int value) _enter;
	int delegate(int oldVal) _cancel;
	bool _noEdit = false;
	void enter() {
		if (_spn.getText().length > 0 && _oldVal != _spn.getSelection()) {
			_enter(_spn.getSelection());
		} else {
			_noEdit = true;
			scope (exit) _noEdit = false;
			_spn.setSelection(_cancel !is null ? _cancel(_oldVal) : _oldVal);
		}
		_oldVal = _spn.getSelection();
	}
	class KListener : KeyAdapter {
		public override void keyPressed(KeyEvent e) {
			if (e.character == SWT.CR) {
				enter();
			} else if (e.character == SWT.ESC) {
				_noEdit = true;
				scope (exit) _noEdit = false;
				_spn.setSelection(_cancel !is null ? _cancel(_oldVal) : _oldVal);
				_oldVal = _spn.getSelection();
			}
		}
	}
	class MSListener : FocusListener {
		void focusGained(FocusEvent e) {
			_oldVal = _spn.getSelection();
		}
		void focusLost(FocusEvent e) {
			enter();
		}
	}
	class MDListener : ModifyListener {
		public override void modifyText(ModifyEvent e) {
			if (_spn.isFocusControl() && _edit !is null && !_noEdit) {
				_edit(_spn.getSelection());
			}
		}
	}
public:
	this(Spinner spn, void delegate(int value) enter,
			void delegate(int value) edit = null, int delegate(int oldVal) cancel = null) {
		_spn = spn;
		_enter = enter;
		_edit = edit;
		_cancel = cancel;
		spn.addKeyListener(new KListener);
		spn.addFocusListener(new MSListener);
		spn.addModifyListener(new MDListener);
	}
}

private class TextEditMFListener : MouseAdapter, SelectionListener {
private:
	Object _itm = null;
	SysTime _time;
	Item delegate() _selection;
	Item delegate(int x, int y) _selectionM;
	void delegate(Item itm) _startEdit;
	bool _dClick;
public:
	/// Params:
	/// startEdit = 編集開始時に呼出される。
	/// selection = 編集対象を返す。
	/// selectionM = 位置に応じて編集対象を返す。
	/// dClick = trueなら編集開始条件はダブルクリックと既選択後のシングルクリック、
	///          falseならダブルクリックにならない速度の2回クリック。
	this (void delegate(Item itm) startEdit,
			Item delegate() selection, Item delegate(int x, int y) selectionM,
			bool dClick = true) {
		try {
			_startEdit = startEdit;
			_selection = selection;
			_selectionM = selectionM;
			_dClick = dClick;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
/+	void mouseDoubleClick(MouseEvent e) {
		if (_dClick) {
			auto itm = _selectionM(e.x, e.y);
			if (e.button == 1 && itm !is null) {
				_startEdit(itm);
			}
		}
	}
+/	override void widgetSelected(SelectionEvent e) {
		try {
			if (_dClick) {
				_itm = _selection();
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	override void widgetDefaultSelected(SelectionEvent e) {}
	override void mouseDown(MouseEvent e) {
		try {
			auto itm = _selectionM(e.x, e.y);
			if (_dClick) {
				if (e.button == 1 && itm !is null && itm == _itm) {
					_startEdit(itm);
				}
			} else {
				synchronized {
					if (e.button == 1 && itm !is null) {
						if (_itm !is null && itm == _itm && _time <= Clock.currTime()) {
							_itm = null;
							_startEdit(itm);
						} else {
							_itm = itm;
							_time = Clock.currTime() + dur!"msecs"(Display.getCurrent().getDoubleClickTime());
						}
					}
				}
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
}
private class TextEditKListener : KeyAdapter {
private:
	Item delegate() _selection;
	void delegate(Item itm) _startEdit;
public:
	this (void delegate(Item itm) startEdit, Item delegate() selection) {
		try {
			_startEdit = startEdit;
			_selection = selection;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	override void keyPressed(KeyEvent e) {
		try {
			if (e.keyCode == SWT.F2) {
				auto itm = _selection();
				if (itm !is null) {
					_startEdit(itm);
				}
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
}

private class EditEnd : KeyAdapter, FocusListener {
private:
	Control ctrl;
	void delegate(Control) end;

public:
	this(Composite parent, Control ctrl, void delegate(Control) end) {
		try {
			this.end = end;
			this.ctrl = ctrl;
			ctrl.addFocusListener(this);
			ctrl.addKeyListener(this);
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void setFocus() {
		try {
			ctrl.setFocus();
			auto combo = cast(Combo) ctrl;
			if (combo) combo.setListVisible(true);
			auto ccombo = cast(CCombo) ctrl;
			if (ccombo) ccombo.setListVisible(true);
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	@property
	Control editor() {
		try {
			return ctrl;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	override void focusGained(FocusEvent e) {}
	override void focusLost(FocusEvent e) {
		try {
			enter();
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	override void keyPressed(KeyEvent e) {
		try {
			if (e.character == SWT.CR) {
				enter();
			} else if (e.keyCode == SWT.ESC) {
				ctrl.dispose();
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	@property
	bool isExit() {
		try {
			return ctrl.isDisposed();
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void enter() {
		try {
			try {
				end(ctrl);
			} catch (Exception e) {
				debugln(e);
			}
			ctrl.dispose();
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
}

Text createTextEditor(Commons comm, Props prop, Composite parent, string str) {
	try {
		auto text = new Text(parent, SWT.BORDER);
		text.setText(str ? str : "");
		text.selectAll();
		createTextMenu!Text(comm, prop, text, null);
		return text;
	} catch (Exception e) {
		throw new Exception(e.msg, __FILE__, __LINE__);
	}
}

C createComboEditor(C = CCombo)(Commons comm, Props prop, Composite parent, string[] strs, string str) {
	try {
		auto combo = new C(parent, SWT.BORDER | SWT.READ_ONLY);
		combo.setVisibleItemCount(20);
		static if (is(C : CCombo)) {
			createTextMenu!C(comm, prop, combo, null);
		}
		foreach (s; strs) {
			if (s) {
				combo.add(s);
			}
		}
		combo.setText(str ? str : "");
		return combo;
	} catch (Exception e) {
		throw new Exception(e.msg, __FILE__, __LINE__);
	}
}

/// テーブルを編集可能にする。
/// ダブルクリック、またはF2キーの押下で編集開始。
abstract class AbstractTableEdit {
private:
	Table table;
	TableEditor editor;
	EditEnd _tee = null;
	int editC;
	bool delegate(TableItem itm, int column) canEdit = null;

	Item selectionM(int x, int y) {
		try {
			if (table.getSelectionCount() == 1) {
				auto itm = table.getSelection()[0];
				if (itm.getBounds(editC).contains(x, y)) {
					if (!itm.getImage() || !itm.getImageBounds(editC).contains(x, y)) {
						return itm;
					}
				}
			}
			return null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	Item selectionK() {
		try {
			if (table.getSelectionCount() == 1) {
				return table.getSelection()[0];
			}
			return null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	void startEdit(Item itm) {
		try {
			startEdit(cast(TableItem) itm);
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void endImpl(Control c) {
		try {
			end(c);
			_tee = null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
public:
	/// Params:
	/// table = テキスト編集対象のテーブル。
	/// editC = 編集対象の列。
	/// canEdit = テーブルアイテムが編集可能か否かを判定する関数。nullを指定した場合、
	///           すべてのセルが編集可能になる。
	this(Table table, int editC,
			bool delegate(TableItem itm, int column) canEdit = null) {
		try {
			this.table = table;
			this.editC = editC;
			this.canEdit = canEdit;
			editor = new TableEditor(table);
			editor.grabHorizontal = true;

			auto mf = new TextEditMFListener(&startEdit, &selectionK, &selectionM);
			table.addMouseListener(mf);
			table.addSelectionListener(mf);
			table.addKeyListener(new TextEditKListener(&startEdit, &selectionK));
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	/// 選択されているセルの編集を開始する。
	void startEdit() {
		try {
			auto sels = table.getSelection();
			if (sels.length == 1) {
				startEdit(sels[0]);
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void startEdit(TableItem itm) {
		try {
			if (!itm.getParent().isFocusControl()) return;
			if (_tee !is null && !_tee.isExit) _tee.enter();
			auto sel = itm;
			if (canEdit is null || canEdit(sel, editC)) {
				_tee = new EditEnd(table, createEditor(sel, editC), &endImpl);
				editor.setEditor(_tee.editor, sel, editC);
				_tee.setFocus();
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	@property
	bool isEditing() {
		try {
			return _tee !is null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	protected Control createEditor(TableItem itm, int editC);
	protected void end(Control c);
}
/// ditto
class TableTextEdit : AbstractTableEdit {
private:
	Commons _comm;
	Props _prop;
	void delegate(TableItem itm, int column, string newText) editEnd = null;

public:
	/// Params:
	/// table = テキスト編集対象のテーブル。
	/// editC = 編集対象の列。
	/// editEnd = 編集終了時に実行される関数。nullを指定した場合、
	///           単にテーブルアイテムのテキストを編集後のテキストで置換する。
	/// canEdit = テーブルアイテムが編集可能か否かを判定する関数。nullを指定した場合、
	///           すべてのセルが編集可能になる。
	this(Commons comm, Props prop, Table table, int editC,
			void delegate(TableItem itm, int column, string text) editEnd = null,
			bool delegate(TableItem itm, int column) canEdit = null) {
		try {
			super (table, editC, canEdit);
			_comm = comm;
			_prop = prop;
			this.editEnd = editEnd;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	protected override Control createEditor(TableItem itm, int editC) {
		return createTextEditor(_comm, _prop, itm.getParent(), itm.getText(editC));
	}
	protected override void end(Control c) {
		try {
			auto newText = (cast(Text) c).getText();
			if (!newText) newText = "";
			if (editEnd is null) {
				if (newText.length > 0) {
					editor.getItem().setText(editC, newText);
				}
			} else {
				editEnd(editor.getItem(), editC, newText);
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
}
/// ditto
class TableComboEdit(C = CCombo) : AbstractTableEdit {
private:
	Commons _comm;
	Props _prop;
	void delegate(TableItem itm, int column, out string[] strs, out string str) createCombo;
	void delegate(TableItem itm, int column, C combo) editEnd = null;

public:
	/// Params:
	/// table = テキスト編集対象のテーブル。
	/// editC = 編集対象の列。
	/// createCombo = 編集に使用するコンボボックスの内容を返す。
	/// editEnd = 編集終了時に実行される関数。nullを指定した場合、
	///           単にテーブルアイテムのテキストを編集後のテキストで置換する。
	/// canEdit = テーブルアイテムが編集可能か否かを判定する関数。nullを指定した場合、
	///           すべてのセルが編集可能になる。
	this(Commons comm, Props prop, Table table, int editC,
			void delegate(TableItem itm, int column, out string[] strs, out string str) createCombo,
			void delegate(TableItem itm, int column, C combo) editEnd = null,
			bool delegate(TableItem itm, int column) canEdit = null) {
		try {
			super (table, editC, canEdit);
			_comm = comm;
			_prop = prop;
			this.createCombo = createCombo;
			this.editEnd = editEnd;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	protected override Control createEditor(TableItem itm, int editC) {
		string[] strs;
		string str;
		createCombo(itm, editC, strs, str);
		return createComboEditor!C(_comm, _prop, itm.getParent(), strs, str);
	}
	protected override void end(Control c) {
		try {
			auto combo = cast(C) c;
			if (editEnd is null) {
				editor.getItem().setText(editC, combo.getText());
			} else {
				editEnd(editor.getItem(), editC, combo);
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
}

/// ditto
class TableTCEdit : AbstractTableEdit {
private:
	Control delegate(TableItem itm, int editC) _createEditor;
	void delegate(TableItem itm, int column, Control ctrl) editEnd = null;

public:
	this(Table table, int editC,
			Control delegate(TableItem itm, int editC) createEditor,
			void delegate(TableItem itm, int column, Control ctrl) editEnd = null,
			bool delegate(TableItem itm, int column) canEdit = null) {
		try {
			super (table, editC, canEdit);
			_createEditor = createEditor;
			this.editEnd = editEnd;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	protected override Control createEditor(TableItem itm, int editC) {
		return _createEditor(itm, editC);
	}
	protected override void end(Control c) {
		try {
			void set(string text) {
				if (editEnd is null) {
					editor.getItem().setText(editC, text);
				} else {
					editEnd(editor.getItem(), editC, c);
				}
			}
			auto spinner = cast(Spinner) c;
			if (spinner) set(spinner.getText());
			auto text = cast(Text) c;
			if (text) set(text.getText());
			auto combo = cast(Combo) c;
			if (combo) set(combo.getText());
			auto ccombo = cast(CCombo) c;
			if (ccombo) set(ccombo.getText());
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
}
/// ツリーのテキストを編集可能にする。
/// ダブルクリック、またはF2キーの押下で編集開始。
class TreeEdit {
private:
	Tree tree;
	TreeEditor editor;
	EditEnd _tee;

	void delegate(TreeItem itm, Control ctrl) editEnd;
	Control delegate(TreeItem itm) createEditor;

	Item selectionM(int x, int y) {
		try {
			if (tree.getSelectionCount() == 1) {
				auto itm = tree.getSelection()[0];
				if (itm.getBounds().contains(x, y)) {
					return itm;
				}
			}
			return null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	Item selectionK() {
		try {
			if (tree.getSelectionCount() == 1) {
				return tree.getSelection()[0];
			}
			return null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	void end(Control ctrl) {
		try {
			editEnd(editor.getItem(), ctrl);
			_tee = null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	void startEdit(Item itm) {
		try {
			if (_tee !is null && !_tee.isExit) _tee.enter();
			auto sel = cast(TreeItem) itm;
			auto c = createEditor(sel);
			if (c) {
				_tee = new EditEnd(tree, c, &end);
				editor.setEditor(_tee.editor, sel);
				_tee.setFocus();
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
public:
	/// tree = テキスト編集対象のツリー。
	/// editEnd = 編集終了時に実行される関数。
	/// createEditor = ツリーアイテムが編集するコンポーネントを生成する関数。
	///                nullを返した場合、編集は開始されない。
	this(Tree tree, void delegate(TreeItem itm, Control ctrl) editEnd,
			Control delegate(TreeItem itm) createEditor = null) {
		try {
			this.tree = tree;
			this.editEnd = editEnd;
			this.createEditor = createEditor;
			editor = new TreeEditor(tree);
			editor.grabHorizontal = true;

			auto mf = new TextEditMFListener(&startEdit, &selectionK, &selectionM);
			tree.addMouseListener(mf);
			tree.addSelectionListener(mf);
			tree.addKeyListener(new TextEditKListener(&startEdit, &selectionK));
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	/// 選択されているセルの編集を開始する。
	void startEdit() {
		try {
			auto sels = tree.getSelection();
			if (sels.length == 1) {
				startEdit(sels[0]);
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	bool isEditing() {
		try {
			return _tee !is null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
}

interface TCPD {
public:
	void cut(SelectionEvent se);
	void copy(SelectionEvent se);
	void paste(SelectionEvent se);
	void del(SelectionEvent se);
	@property
	bool canDoTCPD();
}

private class InTCPD {
	TCPD tcpd;
	void cut(SelectionEvent se) {
		auto fc = Display.getCurrent().getFocusControl();
		bool ro = !(fc.getStyle() & SWT.READ_ONLY);
		if (ro && cast(Text) fc) {
			(cast(Text) fc).cut();
		} else if (ro && cast(Combo) fc) {
			(cast(Combo) fc).cut();
		} else if (ro && cast(CCombo) fc) {
			(cast(CCombo) fc).cut();
		} else {
			tcpd.cut(se);
		}
	}
	void copy(SelectionEvent se) {
		auto fc = Display.getCurrent().getFocusControl();
		bool ro = !(fc.getStyle() & SWT.READ_ONLY);
		if (ro && cast(Text) fc) {
			(cast(Text) fc).copy();
		} else if (ro && cast(Combo) fc) {
			(cast(Combo) fc).copy();
		} else if (ro && cast(CCombo) fc) {
			(cast(CCombo) fc).copy();
		} else {
			tcpd.copy(se);
		}
	}
	void paste(SelectionEvent se) {
		auto fc = Display.getCurrent().getFocusControl();
		bool ro = !(fc.getStyle() & SWT.READ_ONLY);
		if (ro && cast(Text) fc) {
			(cast(Text) fc).paste();
		} else if (ro && cast(Combo) fc) {
			(cast(Combo) fc).paste();
		} else if (ro && cast(CCombo) fc) {
			(cast(CCombo) fc).paste();
		} else {
			tcpd.paste(se);
		}
	}
	void del(SelectionEvent se) {
		auto fc = Display.getCurrent().getFocusControl();
		bool ro = !(fc.getStyle() & SWT.READ_ONLY);
		if (ro && cast(Text) fc) {
			(cast(Text) fc).insert("");
		} else {
			tcpd.del(se);
		}
	}
}
void appendMenuTCPD(Props prop, TopLevelPanel tlp, TCPD tcpd,
		bool t = true, bool c = true, bool p = true, bool d = false) {
	auto itcpd = new InTCPD;
	itcpd.tcpd = tcpd;
	if (t) tlp.putMenuAction(MenuID.Cut, &itcpd.cut);
	if (c) tlp.putMenuAction(MenuID.Copy, &itcpd.copy);
	if (p) tlp.putMenuAction(MenuID.Paste, &itcpd.paste);
	if (d) tlp.putMenuAction(MenuID.Del, &itcpd.del);
}
void appendMenuTCPD(Props prop, Menu me, TCPD tcpd,
		bool t = true, bool c = true, bool p = true, bool d = false) {
	auto itcpd = new InTCPD;
	itcpd.tcpd = tcpd;
	if (t) createMenuItem(me, prop.msgs.menuCut, prop.images.menuCut, &itcpd.cut);
	if (c) createMenuItem(me, prop.msgs.menuCopy, prop.images.menuCopy, &itcpd.copy);
	if (p) createMenuItem(me, prop.msgs.menuPaste, prop.images.menuPaste, &itcpd.paste);
	if (d) createMenuItem(me, prop.msgs.menuDel, prop.images.menuDel, &itcpd.del);
}

bool eqAcc(int acc, int keyCode, wchar character, int stateMask) {
	if ((acc & SWT.MODIFIER_MASK) == acc) {
		return (keyCode | stateMask) == acc;
	} else if (toUpper(keyCode) == toUpper(character)) {
		return (toUpper(keyCode) | stateMask) == acc
			|| (toLower(keyCode) | stateMask) == acc;
	} else {
		return (toUpper(keyCode) | stateMask) == acc
			|| (toLower(keyCode) | stateMask) == acc
			|| (toUpper(character) | (stateMask ^ SWT.SHIFT)) == acc
			|| (toLower(character) | (stateMask ^ SWT.SHIFT)) == acc
			|| (toUpper(character) | stateMask) == acc
			|| (toLower(character) | stateMask) == acc;
	}
}

int convertAccelerator(string text) {
	int t_index = std.string.lastIndexOf(text, '\t');
	if (t_index >= 0 && t_index < text.length - 1) {
		string acc_text = text[t_index + 1 .. $];
		int acc = 0;
		string kc;
		int mod(string s) {
			switch (toLower(s)) {
			case "control", "ctrl": return SWT.CONTROL;
			case "shift": return SWT.SHIFT;
			case "alt": return SWT.ALT;
			case "command": return SWT.COMMAND;
			default: return 0;
			}
		}
		while (true) {
			int p_index = .cCountUntil(acc_text, '+');
			if (p_index >= 0 && p_index < acc_text.length - 1) {
				acc |= mod(acc_text[0 .. p_index]);
				acc_text = acc_text[p_index + 1 .. $];
			} else {
				kc = acc_text;
				break;
			}
		}
		int ek(string s) {
			switch (toLower(s)) {
			case "backspace": return SWT.BS;
			case "enter", "return": return SWT.CR;
			case "delete": return SWT.DEL;
			case "escape", "esc": return SWT.ESC;
			case "tab": return SWT.TAB;
			case "space": return ' ';
			case "arrow_up": return SWT.ARROW_UP;
			case "arrow_down": return SWT.ARROW_DOWN;
			case "arrow_left": return SWT.ARROW_LEFT;
			case "arrow_right": return SWT.ARROW_RIGHT;
			case "page_up": return SWT.PAGE_UP;
			case "page_down": return SWT.PAGE_DOWN;
			case "home": return SWT.HOME;
			case "end": return SWT.END;
			case "insert": return SWT.INSERT;
			case "f1": return SWT.F1;
			case "f2": return SWT.F2;
			case "f3": return SWT.F3;
			case "f4": return SWT.F4;
			case "f5": return SWT.F5;
			case "f6": return SWT.F6;
			case "f7": return SWT.F7;
			case "f8": return SWT.F8;
			case "f9": return SWT.F9;
			case "f10": return SWT.F10;
			case "f11": return SWT.F11;
			case "f12": return SWT.F12;
			case "f13": return SWT.F13;
			case "f14": return SWT.F14;
			case "f15": return SWT.F15;
			default: return 0;
			}
		}
		if (kc.length > 1) {
			auto k = ek(kc);
			if (k != 0) {
				acc |= k;
			} else {
				acc |= mod(kc);
			}
		} else {
			acc |= kc[0];
		}
		return acc;
	}
	return 0;
} unittest {
	assert (convertAccelerator("test\tCTRL+ARROW_UP") == (SWT.ARROW_UP | SWT.CTRL));
	assert (convertAccelerator("test\tShift+A") == (SWT.SHIFT | 'A'));
}
private class MenuSel(Dlg) : SelectionAdapter {
	private Dlg _func;
	public this(Dlg func) {_func = func;}
	public override void widgetSelected(SelectionEvent e) {
		static if (is(Dlg == void delegate(SelectionEvent))) {
			_func(e);
		} else static if (is(Dlg == void delegate())) {
			_func();
		} else static assert (0);
	}
}
private MenuItem createMenuItemImpl(Dlg)(Menu sub, string text, Image img,
		Dlg func, int style = SWT.PUSH) {
	auto itm = new MenuItem(sub, style);
	itm.setText(text);
	if (func) {
		itm.addSelectionListener(new MenuSel!(Dlg)(func));
	}
	if (img) itm.setImage(img);
	return itm;
}
MenuItem createMenuItem(Menu sub, string text, Image img,
		void delegate(SelectionEvent se) func, int style = SWT.PUSH) {
	return createMenuItemImpl(sub, text, img, func, style);
}
MenuItem createMenuItem(Menu sub, string text, Image img,
		void delegate() func, int style = SWT.PUSH) {
	return createMenuItemImpl(sub, text, img, func, style);
}
Menu createMenu(Menu bar, string text) {
	auto menu = new Menu(bar.getShell(), SWT.DROP_DOWN);
	auto mi = new MenuItem(bar, SWT.CASCADE);
	mi.setText(text);
	mi.setMenu(menu);
	return menu;
}

ToolItem createDropDownItem(ToolBar bar, string text, Image img, void delegate() func, out Menu menu) {
	auto ti = new ToolItem(bar, SWT.DROP_DOWN);
	ti.setToolTipText(text);
	ti.setImage(img);
	menu = new Menu(bar.getShell());
	class Push : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			if (SWT.ARROW == e.detail && 0 < menu.getItemCount()) {
				auto b = ti.getBounds();
				auto pt = bar.toDisplay(b.x, b.y + b.height);
				menu.setLocation(pt);
				menu.setVisible(true);
			} else {
				func();
			}
		}
	}
	ti.addSelectionListener(new Push);
	return ti;
}
ToolItem createToolItemImpl(Dlg)(ToolBar bar, string tip, string text, Image img,
		Dlg func, int style = SWT.PUSH) {
	auto itm = new ToolItem(bar, style);
	itm.setText(text);
	itm.setToolTipText(tip);
	itm.setImage(img);
	if (func) {
		itm.addSelectionListener(new MenuSel!(Dlg)(func));
	}
	return itm;
}
ToolItem createToolItem(ToolBar bar, string tip, string text, Image img,
		void delegate(SelectionEvent se) func, int style = SWT.PUSH) {
	return createToolItemImpl(bar, tip, text, img, func, style);
}
ToolItem createToolItem(ToolBar bar, string tip, string text, Image img,
		void delegate() func, int style = SWT.PUSH) {
	return createToolItemImpl(bar, tip, text, img, func, style);
}
ToolItem createToolItem(ToolBar bar, string text, Image img,
		void delegate(SelectionEvent se) func, int style = SWT.PUSH) {
	return createToolItemImpl!(void delegate(SelectionEvent))(bar, text, null, img, func, style);
}
ToolItem createToolItem(ToolBar bar, string text, Image img,
		void delegate() func, int style = SWT.PUSH) {
	return createToolItemImpl!(void delegate())(bar, text, null, img, func, style);
}
private class ToolSel : SelectionAdapter {
	private void delegate(ToolItem) _func;
	public this(void delegate(ToolItem) func) {_func = func;}
	public override void widgetSelected(SelectionEvent e) {_func(cast(ToolItem) e.widget);}
}
ToolItem createToolItem(ToolBar bar, string tip, string text, Image img,
		void delegate(ToolItem) func, int style = SWT.PUSH) {
	auto itm = new ToolItem(bar, style);
	itm.setText(text);
	itm.setToolTipText(tip);
	itm.setImage(img);
	if (func) {
		itm.addSelectionListener(new ToolSel(func));
	}
	return itm;
}

ToolItem createToolItem(ToolBar bar, string text, Image img,
		void delegate(ToolItem) func, int style = SWT.PUSH) {
	return createToolItem(bar, text, null, img, func, style);
}

bool hasFocus(Control c) {
	auto ctrl = Display.getCurrent().getFocusControl();
	if (c is ctrl) return true;
	auto parent = ctrl.getParent();
	while (parent) {
		if (c is parent) return true;
		parent = parent.getParent();
	}
	return false;
}
Shell topShell(Shell shell) {
	auto parent = cast(Shell) shell.getParent();
	if (!parent) return shell;
	while (parent.getParent()) {
		parent = cast(Shell) parent.getParent();
	}
	return parent;
}
bool isDescendant(Shell shell1, Shell shell2) {
	while (shell1 !is shell2) {
		if (!shell2) return false;
		shell2 = cast(Shell) shell2.getParent();
	}
	return true;
}
bool isDescendant(Composite comp, Control ctrl) {
	while (comp !is ctrl) {
		if (!ctrl) return false;
		ctrl = ctrl.getParent();
	}
	return true;
}
class CloseRemover(Window) : DisposeListener {
	private HashSet!(Window) _ws;
	private Window _w;
	public this (HashSet!(Window) ws, Window w) {
		_ws = ws;
		_w = w;
	}
	public override void widgetDisposed(DisposeEvent e) {
		foreach (w; _ws) {
			if (_w is w) {
				_ws.remove(_w);
				return;
			}
		}
		assert(0);
	}
}

abstract class FileDropTarget {
private:
	Control _c;
	class DListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){
			e.detail = canDrop ? DND.DROP_COPY : DND.DROP_NONE;
		}
		override void drop(DropTargetEvent e) {
			auto arr = cast(FileNames) e.data;
			string[] paths = arr.array.dup;
			paths = doAll(paths);
			string[] r;
			foreach (fname; paths) {
				try {
					scope p = _c.toControl(e.x, e.y);
					if (!doFile(fname, p.x, p.y)) {
						break;
					}
					r ~= fname;
				} catch (SWTException e) {
				}
			}
			if (paths.length > 0) {
				doExit();
			}
		}
	}
public:
	this(Control c) {
		_c = c;
		auto target = new DropTarget(c, DND.DROP_DEFAULT | DND.DROP_COPY);
		target.setTransfer([FileTransfer.getInstance()]);
		target.addDropListener(new DListener);
	}
	@property
	Control control() {
		return _c;
	}
	@property
	protected bool canDrop() {
		return true;
	}
	protected string[] doAll(string[] files) {
		return files;
	}
	protected void doExit() {
		// Nothing
	}
	protected abstract bool doFile(string path, int x, int y);
}

class RadioGroup(B : Widget) {
public:
	this () {
		_set = new HashSet!(B);
		_l = new L;
	}
	void select(B b) {
		if (_sel !is b) {
			_sel.setSelection(false);
			b.setSelection(true);
			_sel = b;
		}
	}
	bool contains(B b) {
		return _set.contains(b);
	}
	HashSet!(B) set() {return _set;}
	void append(B b) {
		_set.add(b);
		assert ((b.getStyle() & SWT.RADIO) != 0);
		if (_sel is null){
			if (b.getSelection()) {
				_sel = b;
			}
		} else {
			b.setSelection(false);
		}
		b.addListener(SWT.Selection, _l);
	}
private:
	HashSet!(B) _set;
	B _sel = null;
	Listener _l;
	class L : Listener {
		public override void handleEvent(Event e) {
			auto b = cast(B) e.widget;
			if (_sel is null) {
				_sel = b;
			} else if (b !is _sel) {
				_sel.setSelection(false);
				_sel = b;
			}
		}
	}
}

TreeItem createTreeItem(T)(T parent, Object data, string text, Image img, int index = -1) {
	TreeItem r;
	if (index >= 0) {
		r = new TreeItem(parent, SWT.NONE, index);
	} else {
		r = new TreeItem(parent, SWT.NONE);
	}
	r.setData(data);
	r.setText(text);
	r.setImage(img);
	return r;
}

TreeItem topItem(TreeItem itm) {
	if (!itm) return null;
	if (itm.getParentItem()) {
		return topItem(itm.getParentItem());
	}
	return itm;
}
int treeItemUp(TreeItem itm) {
	return __treeItemUD!("i > 0", "i - 1")(itm);
}
int treeItemDown(TreeItem itm) {
	return __treeItemUD!("i + 1 < parent.getItemCount()", "i + 2")(itm);
}
private int __treeItemUD(string SwapOK, string ToIndex)(TreeItem itm) {
	auto tree = itm.getParent();
	auto p = itm.getParentItem();
	if (p is null) {
		return __treeItemUD2!(Tree, SwapOK, ToIndex)(tree, itm);
	} else {
		return __treeItemUD2!(TreeItem, SwapOK, ToIndex)(p, itm);
	}
}
private int __treeItemUD2(T, string SwapOK, string ToIndex)(T parent, TreeItem itm) {
	int i = parent.indexOf(itm);
	auto tree = itm.getParent();
	if (mixin (SwapOK)) {
		auto ti = cloneItem!(T)(parent, itm, mixin (ToIndex));
		foreach (sel; tree.getSelection()) {
			if (sel is itm) {
				tree.setSelection(ti);
				break;
			}
		}
		itm.dispose();
		return i;
	}
	return -1;
}
private TreeItem cloneItem(T)(T parent, TreeItem old, int index) {
	auto ti = new TreeItem(parent, old.getStyle(), index);
	ti.setData(old.getData());
	ti.setChecked(old.getChecked());
	ti.setForeground(old.getForeground());
	ti.setBackground(old.getBackground());
	ti.setGrayed(old.getGrayed());
	ti.setFont(old.getFont());
	int imgCount = old.getParent().getColumnCount() + 1;
	for (int i = 0; i < imgCount; i++) {
		ti.setText(i, old.getText(i));
		ti.setImage(i, old.getImage(i));
	}
	foreach (i, itm; old.getItems()) {
		cloneItem(ti, itm, i);
	}
	ti.setExpanded(old.getExpanded());
	return ti;
}

void treeExpandedAll(TreeItem tree) {
	foreach (itm; tree.getItems()) {
		treeExpandedAll(itm);
	}
	tree.setExpanded(true);
}
void treeExpandedAll(Tree tree) {
	tree.setRedraw(false);
	foreach (itm; tree.getItems()) {
		treeExpandedAll(itm);
	}
	tree.setRedraw(true);
}
void treeUnexpandedAll(TreeItem tree) {
	foreach (itm; tree.getItems()) {
		treeUnexpandedAll(itm);
	}
	tree.setExpanded(false);
}
void treeUnexpandedAll(Tree tree) {
	tree.setRedraw(false);
	foreach (itm; tree.getItems()) {
		treeUnexpandedAll(itm);
	}
	tree.setRedraw(true);
}

version (Windows) {} else {
	import org.eclipse.swt.program.Program;
}
bool openFolder(string path) {
	path = nabs(path);
	version (Windows) {
		return exec("explorer " ~ path, path);
	} else {
		return Program.launch(path);
	}
}

void hemming(GC gc, string s, int tx, int ty, Color color) {
	auto d = Display.getCurrent();
	gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
	gc.drawText(s, tx - 1, ty, true);
	gc.drawText(s, tx, ty - 1, true);
	gc.drawText(s, tx + 1, ty, true);
	gc.drawText(s, tx, ty + 1, true);
	gc.drawText(s, tx - 1, ty - 1, true);
	gc.drawText(s, tx - 1, ty + 1, true);
	gc.drawText(s, tx + 1, ty - 1, true);
	gc.drawText(s, tx + 1, ty + 1, true);
	gc.setForeground(color);
	gc.drawText(s, tx, ty, true);
}
ImageData castCardImage(Props prop, Skin skin, CastCard c, string sPath, bool dbgMode) {
	auto cardSize = prop.looks.cardSize;
	auto matPad = prop.looks.castCardInsets;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	ImageData id;
	if (c.life == 0) {
		id = castCardFaint(skin);
	} else if (c.paralyze > prop.looks.stoneBorder) {
		id = castCardPetrif(skin);
	} else if (c.paralyze > 0) {
		id = castCardParaly(skin);
	} else if (c.bindRound > 0) {
		id = castCardBind(skin);
	} else if (c.mentality == Mentality.SLEEP && c.mentalityRound > 0) {
		id = castCardSleep(skin);
	} else if (c.life <= c.lifeMax / 5) {
		id = castCardDanger(skin);
	} else if (c.life < c.lifeMax) {
		id = castCardInjury(skin);
	} else {
		id = castCard(skin);
	}
	scope r = new PileImage(id, w, h);
	auto stp = prop.looks.castLifeBarPoint;
	if (dbgMode || c.faceUpRound > 0) {
		r.append(to!(string)(c.level),
			prop.looks.castCardLevelInsets,
			prop.looks.castCardLevelFont(skin.legacy),
			prop.looks.castCardLevelColor,
			PileImage.TPos.RIGHT);
	}
	r.append(skin.findImagePath(c.path, sPath), matPad, true);
	int stMax = prop.looks.statusVerMax;
	if (dbgMode || c.faceUpRound > 0) {
		auto d = Display.getCurrent();
		auto lgid = lifeGuage(skin);
		int lgw = lgid.width;
		int lgh = lgid.height;
		if (lgw > 1 && lgh > 1) {
			try {
				lgid.transparentPixel = lgid.getPixel(lgw / 2, lgh / 2);
				auto lgi = new Image(d, lgid);
				scope (exit) lgi.dispose();
				auto lbid = lifeBar(skin);
				auto lbi = new Image(d, lbid);
				scope (exit) lbi.dispose();
				auto bmp = new Image(d, lgw, lgh);
				scope (exit) bmp.dispose();
				auto gc = new GC(bmp);
				scope (exit) gc.dispose();
				int lbh = lbid.height;
				auto ln = cast(real) c.life / c.lifeMax;
				gc.drawImage(lbi, lgw, 0, lgw, lbh, 0, (lgh - lbh) / 2, lgw, lbh);
				gc.drawImage(lbi, 0, 0, cast(int) (lgw * ln), lbh, 0, (lgh - lbh) / 2, cast(int) (lgw * ln), lbh);
				gc.drawImage(lgi, 0, 0);
				auto life = bmp.getImageData();
				life.transparentPixel = life.getPixel(0, 0);
				r.append(life, stp);
				stp.y -= lgh + 2;
				stMax--;
			} catch (SWTException e) {
				debugln(e);
			}
		}
	}
	stp.x = prop.looks.statusX;
	stp.y -= 3;
	int styf = stp.y;
	int stc = 0;
	void status(ImageData id) {
		r.append(id, stp);
		stc++;
		if (stc >= stMax) {
			stp.x += id.width + 1;
			stp.y = styf;
			stc = 0;
		} else {
			stp.y -= id.height + 1;
		}
	}
	if (c.mentalityRound > 0) {
		switch (c.mentality) {
		case Mentality.NORMAL: break;
		case Mentality.SLEEP: break;
		case Mentality.CONFUSE, Mentality.OVERHEAT, Mentality.BRAVE, Mentality.PANIC: {
			status(mentality(skin, c.mentality));
		} break;
		default: assert (0);
		}
	}
	if (c.poison > 0) status(poison(skin));
	if (c.silenceRound > 0) status(silence(skin));
	if (c.faceUpRound > 0) status(faceUp(skin));
	if (c.antiMagicRound > 0) status(antiMagic(skin));
	void enh(Enhance enh) {
		if (c.enhance(enh) > 0 && c.enhanceRound(enh) > 0) {
			status(enhanceUp(skin, enh));
		} else if (c.enhance(enh) < 0 && c.enhanceRound(enh) > 0) {
			status(enhanceDown(skin, enh));
		}
	}
	enh(Enhance.ACTION);
	enh(Enhance.AVOID);
	enh(Enhance.RESIST);
	enh(Enhance.DEFENSE);
	int beastCountMax = prop.looks.beastCardMaxNum(c.level);
	int beastCount = 0;
	foreach (b; c.beasts) {
		if (b.useLimit > 0) {
			beastCount++;
			if (beastCount >= beastCountMax) break;
		}
	}
	if (beastCount > 0) {
		auto d = Display.getCurrent();
		auto bid = summon(skin);
		auto bmp = new Image(d, bid.width, bid.height);
		scope (exit) bmp.dispose();
		auto gc = new GC(bmp);
		scope (exit) gc.dispose();
		auto bi = new Image(d, bid);
		scope (exit) bi.dispose();
		gc.drawImage(bi, 0, 0);
		auto bff = new Font(d, dwtData(prop.looks.beastNumFont(skin.legacy)));
		scope (exit) bff.dispose();
		gc.setFont(bff);
		string s = to!(string)(beastCount);
		auto cw = gc.textExtent(s).x;
		auto mt = gc.getFontMetrics();
		auto tx = bid.width - cw - 1;
		auto ty = bid.height - mt.getAscent() - 2;
		hemming(gc, s, tx, ty, d.getSystemColor(SWT.COLOR_WHITE));
		r.append(bmp.getImageData(), stp);
	}
	r.setTitle(c.name, dwtData(prop.looks.castCardNameFont(skin.legacy)), dwtData(prop.looks.castCardNamePoint));
	return r.createImageData();
}
ImageData cardImage(C)(Props prop, Skin skin, C c, string sPath, CastCard owner = null) {
	static if (is (C == SkillCard)) {
		auto card = skillCard(skin);
	} else static if (is (C == ItemCard)) {
		auto card = itemCard(skin);
	} else static if (is (C == BeastCard)) {
		auto card = beastCard(skin);
	} else static if (is (C == InfoCard)) {
		auto card = infoCard(skin);
	} else {
		static assert (0);
	}
	auto cardSize = prop.looks.cardSize;
	auto matPad = prop.looks.cardInsets;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	scope r = new PileImage(card, w, h);
	static if (!is (C == InfoCard)) {
		final switch (c.premium) {
		case Premium.PREMIUM, Premium.RARE:
			scope pp = prop.looks.premiumXY;
			auto img = c.premium == Premium.PREMIUM
			? premier(skin) : rare(skin);
			r.append(img, CInsets(pp.y, pp.x, h - pp.y - img.height, w - pp.x - img.width));
			r.append(img, CInsets(h - pp.y - img.height, w - pp.x - img.width, pp.y, pp.x));
			break;
		case Premium.NORMAL:
			break;
		}
	}
	r.append(skin.findImagePath(c.path, sPath), matPad, true);
	static if (!is(C == InfoCard)) {
		if (prop.sys.isPenalty(c)) {
			auto pid = cardPenalty(skin);
			pid.transparentPixel = pid.getPixel(pid.width / 2, pid.height / 2);
			r.append(pid, CPoint(0, 0));
		}
		static if (is(typeof(c.hold))) {
			if (c.hold) {
				auto hid = cardHold(skin);
				hid.transparentPixel = hid.getPixel(hid.width / 2, hid.height / 2);
				r.append(hid, CPoint(0, 0));
			}
		}
		if (owner) {
			int apt = owner.aptitude(c.physical, c.mental);
			ImageData aimg;
			if (prop.looks.aptVeryHigh <= apt) {
				aimg = aptVeryHigh(skin);
			} else if (prop.looks.aptHigh <= apt) {
				aimg = aptHigh(skin);
			} else if (prop.looks.aptNormal <= apt) {
				aimg = aptNormal(skin);
			} else {
				aimg = aptLow(skin);
			}
			auto ap = prop.looks.aptStoneXY;
			r.append(aimg, CInsets(ap.y, w - ap.x - aimg.width, h - ap.y - aimg.height, ap.x));
			static if (is (C == SkillCard)) {
				auto uimg = use4(skin);
				auto up = prop.looks.useStoneXY;
				r.append(uimg, CInsets(up.y, w - up.x - uimg.width, h - up.y - uimg.height, up.x));
			}
		}
	}
	r.setTitle(c.name, dwtData(prop.looks.cardNameFont(skin.legacy)), dwtData(prop.looks.cardNamePoint));
	static if (is(C : ItemCard) || is(C : BeastCard)) {
		static if (is(C : ItemCard)) {
			auto ul = c.useLimitMax;
		} else static if (is(C : BeastCard)) {
			auto ul = c.useLimit;
		} else static assert (0);
		if (ul > 0) {
			auto d = Display.getCurrent();
			auto imgData = r.createImageData();
			auto img = new Image(d, imgData);
			scope (exit) img.dispose();
			auto gc = new GC(img);
			scope (exit) gc.dispose();
			auto font = new Font(d, dwtData(prop.looks.useCountFont(skin.legacy)));
			scope (exit) font.dispose();
			gc.setFont(font);
			bool res = prop.sys.isRecycle(c);
			int alpha;
			auto color = res
				? new Color(d, dwtData(prop.looks.recycleNumColor, alpha))
				: d.getSystemColor(SWT.COLOR_WHITE);
			scope (exit) {
				if (res) color.dispose();
			}
			auto p = prop.looks.useCountPoint;
			string s = to!(string)(c.useLimit);
			hemming(gc, s, p.x, p.y, color);
			return img.getImageData();
		}
	}
	return r.createImageData();
}

void addCastCoupons(Combo combo, Props prop, bool talker, string legacyName) {
	if (!talker) {
		foreach (c; prop.var.etc.standardCoupons) {
			combo.add(c);
		}
	}
	foreach (e; SEX_ALL) {
		combo.add(prop.sys.sexCoupon(e, legacyName));
	}
	foreach (e; PERIOD_ALL) {
		combo.add(prop.sys.periodCoupon(e, legacyName));
	}
	foreach (e; NATURE_DEF) {
		combo.add(prop.sys.natureCoupon(e, legacyName));
	}
	foreach (e; MAKINGS_LEFT) {
		combo.add(prop.sys.makingsCoupon(e, legacyName));
		combo.add(prop.sys.makingsCoupon(reverseMakings(e), legacyName));
	}
}

bool qMaterialCopy(Props prop, Skin skin, Shell shell,
		UseCounter uc, string toSPath, string fromSPath, out bool copy, bool toIsLegacy) {
	copy = false;
	string[] paths;
	foreach (key; uc.path.keys) {
		string path = cast(string) key;
		if (key.isBinImg) {
			paths ~= path;
		} else if (exists(std.path.buildPath(fromSPath, path))) {
			paths ~= path;
		}
	}
	if (paths.length == 0) return true;
	auto copyM = new MessageBox(shell, SWT.YES | SWT.NO | SWT.CANCEL | SWT.ICON_QUESTION);
	copyM.setText(prop.msgs.dlgTitQuestion);
	uint bin = 0u;
	string[] msgPaths;
	foreach (p; paths) {
		if (isBinImg(p)) {
			bin++;
		} else {
			msgPaths ~= std.path.buildPath(fromSPath, p);
		}
	}
	copyM.setMessage(prop.msgs.dlgMsgCopyMaterial(msgPaths, bin));
	switch (copyM.open()) {
	case SWT.YES:
		bool err = false;
		foreach (i, key; paths) {
			string path = isBinImg(key) ? key : std.path.buildPath(fromSPath, key);
			try {
				auto newp = copyTo(toSPath, path, skin.materialPath);
				uc.change(toPathId(key), toPathId(newp));
				copy = true;
			} catch (Exception e) {
				debugln("copy error: " ~ e.msg);
				err = true;
			}
		}
		if (err) {
			MessageBox.showWarning(prop.msgs.dlgMsgCopyError, prop.msgs.dlgTitWarning, shell);
		}
		return true;
	case SWT.NO:
		if (!toIsLegacy) {
			foreach (key; uc.path.keys) {
				if (key.isBinImg) {
					uc.change(key, toPathId(""), true);
				}
			}
		}
		return true;
	case SWT.CANCEL:
		return false;
	default: assert (0);
	}
}

void saveColumnWidth(string Value)(Props prop, TableColumn col) {
	col.setWidth(mixin (Value));
	static if (is (typeof(mixin(Value ~ " = 0")) == void)) {
		static class SaveColumnWidth : DisposeListener {
			Props prop;
			this(Props prop) {
				this.prop = prop;
			}
			override void widgetDisposed(DisposeEvent e) {
				int width = (cast(TableColumn) e.widget).getWidth();
				mixin (Value ~ " = width;");
			}
		}
		col.addDisposeListener(new SaveColumnWidth(prop));
	}
}

void intoDisplay(ref int x, ref int y, int w, int h) {
	auto pb = Display.getCurrent().getClientArea();
	if (pb.x + pb.width < x + w) x = pb.x + pb.width - w;
	if (pb.y + pb.height < y + h) y = pb.y + pb.height - h;
	if (x < pb.x) x = pb.x;
	if (y < pb.y) y = pb.y;
}

class StopBGM : SelectionAdapter, DisposeListener {
	override void widgetSelected(SelectionEvent e) {
		stopSE();
	}
	override void widgetDisposed(DisposeEvent e) {
		stopBGM();
	}
}
class StopSE : SelectionAdapter, DisposeListener {
	override void widgetSelected(SelectionEvent e) {
		stopSE();
	}
	override void widgetDisposed(DisposeEvent e) {
		stopSE();
	}
}

Image skeletonImage(Image src, bool mask = true) {
	auto data = src.getImageData();
	auto img = new Image(Display.getCurrent(), data.width, data.height);
	scope gc = new GC(img);
	gc.setAlpha(0x7F);
	scope (exit) gc.dispose();
	gc.drawImage(src, 0, 0);
	if (!mask) return img;
	scope (exit) img.dispose();
	data = img.getImageData();
	data.transparentPixel = data.getPixel(0, 0);
	return new Image(Display.getCurrent(), data);
}

Composite createDefSoundCombo(Commons comm, Props prop, Summary summ, Composite parent, out Combo combo, string title = null) {
	static class PlaySE : SelectionAdapter {
		private Commons _comm;
		private Summary _summ;
		private Props _prop;
		private Combo _combo;
		this(Commons comm, Summary summ, Props prop, Combo combo) {
			_comm = comm;
			_summ = summ;
			_prop = prop;
			_combo = combo;
		}
		override void widgetSelected(SelectionEvent e) {
			if (_combo.getSelectionIndex() > 0) {
				playSECW(_prop, std.path.buildPath(_comm.skin.seDir, _combo.getText()), _summ.legacy);
			}
		}
	}
	auto comp2 = new Composite(parent, SWT.NONE);
	if (title) {
		comp2.setLayout(zeroMarginGridLayout(2, true));
		auto l = new CLabel(comp2, SWT.NONE);
		auto gdl = new GridData(GridData.FILL_HORIZONTAL);
		gdl.horizontalSpan = 2;
		l.setLayoutData(gdl);
		l.setImage(prop.images.sound);
		l.setText(title);
	} else {
		comp2.setLayout(zeroMarginGridLayout(3, false));
	}
	combo = new Combo(comp2, SWT.BORDER | SWT.READ_ONLY | SWT.DROP_DOWN);
	combo.setVisibleItemCount(20);
	auto gdc = new GridData(GridData.FILL_HORIZONTAL);
	if (title) {
		gdc.horizontalSpan = 2;
	}
	combo.setLayoutData(gdc);
	void refSkin() {
		string se = combo.getText();
		setComboItems(combo, prop.msgs.soundNone ~ comm.skin.sounds());
		se = comm.skin.findPath(se, comm.skin.extSound, comm.skin.seDir, null);
		se = abs2rel(comm.skin.seDir, se);
		int i = combo.indexOf(se);
		combo.select = -1 == i ? 0 : i;
	}
	refSkin();
	comm.refSkin.add(&refSkin);
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			comm.refSkin.remove(&refSkin);
		}
	}
	combo.addDisposeListener(new Dispose);
	auto stop = new Button(comp2, SWT.PUSH);
	if (title) {
		stop.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
	}
	stop.setImage(prop.images.stopSound);
	stop.setToolTipText(prop.msgs.stopSound);
	auto sse = new StopSE;
	stop.addSelectionListener(sse);
	stop.addDisposeListener(sse);
	auto play = new Button(comp2, SWT.PUSH);
	if (title) {
		play.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
	}
	play.setImage(prop.images.playSound);
	play.setToolTipText(prop.msgs.playSound);
	play.addSelectionListener(new PlaySE(comm, summ, prop, combo));
	return comp2;
}
Composite createSuccessRateScale(Props prop, Composite parent, out Scale sucRate) {
	auto grp = new Group(parent, SWT.NONE);
	auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
	cl.fillHorizontal = true;
	grp.setLayout(cl);
	grp.setText(prop.msgs.successRate);
	auto comp = new Composite(grp, SWT.NONE);
	comp.setLayout(new GridLayout(3, false));
	auto allf = new Label(comp, SWT.CENTER);
	allf.setText(prop.msgs.allFail);
	sucRate = new Scale(comp, SWT.NONE);
	sucRate.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
	// 0以上でないといけないらしい
	sucRate.setMinimum(0);
	sucRate.setMaximum(Content.successRate_max - Content.successRate_min);
	sucRate.setPageIncrement(Content.successRate_max);
	auto alls = new Label(comp, SWT.CENTER);
	alls.setText(prop.msgs.allSuccess);
	return grp;
}

void putRadioValue(E)(Button[E] radios, void delegate(E) set) {
	set(getRadioValue!(E)(radios));
}

E getRadioValue(E)(Button[E] radios) {
	foreach (e, radio; radios) {
		if (radio.getSelection()) {
			return e;
		}
	}
	assert (0);
}

void forceFocus(Widget widget, bool shellActivate) {
	auto d = Display.getCurrent();
	if (widget is d.getFocusControl()) return;
	forceFocusImpl(widget, null, shellActivate);
}

private void forceFocusImpl(Widget widget, Widget child, bool shellActivate) {
	if (!widget || widget.isDisposed()) return;
	auto d = Display.getCurrent();
	auto ti = cast(TableItem) widget;
	if (ti) {
		auto tbl = ti.getParent();
		forceFocusImpl(tbl, null, shellActivate);
		tbl.setSelection(ti);
		tbl.showSelection();
		return;
	}
	auto tri = cast(TreeItem) widget;
	if (tri) {
		auto tree = tri.getParent();
		forceFocusImpl(tree, null, shellActivate);
		tree.select(tri);
		tree.showSelection();
		return;
	}
	auto sh = cast(Shell) widget;
	if (sh) {
		if (shellActivate) {
			sh.setActive();
		}
		return;
	}
	auto tf = cast(TabFolder) widget;
	if (tf) {
		foreach (i; tf.getItems()) {
			if (i.getControl() is child) {
				forceFocusImpl(tf.getParent(), tf, shellActivate);
				tf.setSelection(i);
				return;
			}
		}
		assert (0);
	}
	auto ctf = cast(CTabFolder) widget;
	if (ctf) {
		foreach (i; ctf.getItems()) {
			if (i.getControl() is child) {
				forceFocusImpl(ctf.getParent(), ctf, shellActivate);
				ctf.setSelection(i);
				return;
			}
		}
		assert (0);
	}
	auto ctl = cast(Control) widget;
	if (ctl) {
		forceFocusImpl(ctl.getParent(), ctl, shellActivate);
		if (!shellActivate) {
			if (ctl.getShell() is d.getActiveShell()) {
				ctl.setFocus();
			}
		} else {
			ctl.setFocus();
		}
		return;
	}
	assert (0);
}

/// Controlの階層構造を表示する。
void writeRec(Control c, string tab = "") {
	std.stdio.writef(tab ~ c.toString());
	std.stdio.writefln(c.isDisposed() ? " disposed" : "");
	if (cast(Composite) c) {
		foreach (cc; (cast(Composite) c).getChildren()) {
			writeRec(cc, tab ~ "  ");
		}
	}
}

private class CBarListener(string Name) : ControlAdapter, DisposeListener {
	private Props _prop;
	private CoolBar _cbar;
	MenuItem _lock;
	this (Props prop, CoolBar cbar) {
		_prop = prop;
		_cbar = cbar;
	}
	override void widgetDisposed(DisposeEvent e) {
		auto cbar = cast(CoolBar) e.widget;
		int[] ixs;
		for (int i = 0; i < _cbar.getItemCount(); i++) {
			ixs ~= i;
		}
		mixin ("_prop.var.etc." ~ Name ~ "Lock = cbar.getLocked();");
		if (ixs == cbar.getItemOrder()) {
			mixin ("_prop.var.etc." ~ Name ~ "Order = [];");
		} else {
			mixin ("_prop.var.etc." ~ Name ~ "Order = cbar.getItemOrder();");
		}
		mixin ("_prop.var.etc." ~ Name ~ "WrapIndices = cbar.getWrapIndices();");
	}
	override void controlResized(ControlEvent e) {
		auto cbar = cast(CoolBar) e.widget;
		cbar.getShell().layout(true, true);
	}
	void reset() {
		int[] ixs;
		for (int i = 0; i < _cbar.getItemCount(); i++) {
			ixs ~= i;
		}
		_cbar.setItemOrder(ixs);
		_cbar.setWrapIndices(mixin ("_prop.var.etc." ~ Name ~ "WrapIndices_init.dup"));
		foreach_reverse (i; _cbar.getItemOrder()) {
			resetCISize(_cbar.getItem(i));
		}
	}
	void lock() {
		_cbar.setLocked(!_cbar.getLocked());
		if (_lock) _lock.setSelection(_cbar.getLocked());
		foreach_reverse (i; _cbar.getItemOrder()) {
			resetCISize(_cbar.getItem(i));
		}
	}
}
CoolBar createCoolBar(string Name)(Props prop, Composite parent,
		void delegate(CoolBar) setupItems) {
	auto cbar = new CoolBar(parent, SWT.NONE);

	setupItems(cbar);

	auto ls = new CBarListener!(Name)(prop, cbar);
	cbar.addControlListener(ls);
	cbar.addDisposeListener(ls);

	auto menu = new Menu(parent.getShell(), SWT.POP_UP);
	ls._lock = createMenuItem(menu, prop.msgs.menuLockBar, prop.images.menuLockBar, &ls.lock, SWT.CHECK);
	new MenuItem(menu, SWT.SEPARATOR);
	createMenuItem(menu, prop.msgs.menuResetBar,  prop.images.menuResetBar, &ls.reset);
	cbar.setMenu(menu);

	foreach (itm; cbar.getItems()) {
		itm.getControl().setMenu(menu);
	}
	if (mixin ("prop.var.etc." ~ Name ~ "Order.length") == cbar.getItemCount()) {
		cbar.setItemOrder(mixin ("prop.var.etc." ~ Name ~ "Order.dup"));
	}
	int[] wi;
	foreach (i; mixin ("prop.var.etc." ~ Name ~ "WrapIndices")) {
		if (i > 0 && i < cbar.getItemCount()) wi ~= i;
	}
	if (wi != cbar.getWrapIndices()) cbar.setWrapIndices(wi);
	cbar.setLocked(mixin ("prop.var.etc." ~ Name ~ "Lock"));
	ls._lock.setSelection(cbar.getLocked());
	return cbar;
}

void resetCISize(CoolItem itm) {
	auto p = itm.getControl().computeSize(SWT.DEFAULT, SWT.DEFAULT);
	auto p2 = itm.computeSize(p.x, p.y);
	itm.setMinimumSize(p.x, p.y);
	itm.setPreferredSize(p2.x, p2.y);
}

CoolItem createCoolItem(CoolBar cbar, ToolBar tbar, int index = -1) {
	CoolItem itm;
	if (index >= 0) {
		itm = new CoolItem(cbar, SWT.PUSH, index);
	} else {
		itm = new CoolItem(cbar, SWT.PUSH);
	}
	itm.setControl(tbar);
	resetCISize(itm);
	return itm;
}

SplitPane changeVHSide(SplitPane sash) {
	auto style = sash.getStyle() & !SWT.HORIZONTAL & !SWT.VERTICAL;
	assert (!(style & SWT.HORIZONTAL));
	assert (!(style & SWT.VERTICAL));
	auto vh = (sash.getStyle() & SWT.VERTICAL) ? SWT.HORIZONTAL : SWT.VERTICAL;
	auto sp = new SplitPane(sash.getParent(), style | vh);
	assert ((sash.getStyle() & SWT.VERTICAL)
		? ((sp.getStyle() & SWT.HORIZONTAL) && !(sp.getStyle() & SWT.VERTICAL))
		: ((sp.getStyle() & SWT.VERTICAL) && !(sp.getStyle() & SWT.HORIZONTAL)));
	auto ws = sash.getWeights();
	foreach (c; sash.getChildren()) {
		if (!(cast(Sash) c)) {
			c.setParent(sp);
		}
	}
	sp.setLayoutData(sash.getLayoutData());
	sp.setWeights(ws);
	sash.dispose();
	sp.getParent().layout(true);
	sp.layout(true);
	return sp;
}

void drawTileImage(GC gc, Image img, Rectangle rect) {
	auto data = img.getBounds();
	for (int x = 0; x < rect.width; x += data.width) {
		for (int y = 0; y < rect.height; y += data.height) {
			int xi = rect.x + x;
			int yi = rect.y + y;
			int wi = x + data.width >= rect.width ? rect.width - x : data.width;
			int hi = y + data.height >= rect.height ? rect.height - y : data.height;
			gc.drawImage(img, 0, 0, wi, hi, xi, yi, wi, hi);
		}
	}
}

bool playBGMCW(Props prop, string path, bool legacy) {
	switch (prop.var.etc.soundPlayType) {
	case SOUND_TYPE_SDL: playBGM(path, false); return true;
	case SOUND_TYPE_MCI:
		version (Windows) {
			playBGM(path, true);
			return true;
		} else {
			goto default;
		}
	case SOUND_TYPE_APP: Program.launch(path); return false;
	default: playBGM(path, legacy); return true;
	}
}

void playSECW(Props prop, string path, bool legacy) {
	switch (prop.var.etc.soundPlayType) {
	case SOUND_TYPE_SDL: playSE(path, false); break;
	case SOUND_TYPE_MCI:
		version (Windows) {
			playSE(path, true);
			break;
		} else {
			goto default;
		}
	case SOUND_TYPE_APP: Program.launch(path); break;
	default: playSE(path, legacy); break;
	}
}

/// 文字列の見た目の長さを測る。
int textWidth(Props prop, Control c, string text) {
	auto gc = new GC(c);
	scope (exit) gc.dispose();
	auto mono = new Font(Display.getCurrent(), new FontData(prop.looks.monospace, 10, SWT.NORMAL));
	scope (exit) mono.dispose();
	gc.setFont(mono);
	return gc.textExtent(text).x / gc.textExtent(" ").x;
}

Cursor[Shell] setWaitCursors(Shell shell) {
	auto cWait = shell.getDisplay().getSystemCursor(SWT.CURSOR_WAIT);
	Cursor[Shell] cursors;
	void put(Shell cShl) {
		if (cShl.getCursor() !is cWait) {
			cursors[cShl] = cShl.getCursor();
			cShl.setCursor(cWait);
		}
	}
	put(shell);
	foreach (chld; shell.getShells()) {
		if (chld.isDisposed()) continue;
		put(chld);
	}
	return cursors;
}
void resetCursors(Cursor[Shell] cursors) {
	foreach (shl, cur; cursors) {
		if (shl.isDisposed()) continue;
		shl.setCursor(cur);
	}
}

/// 前景色cを背景色bに対して透明度aで描画した時の色を返す。
RGB alphaColor(in RGB c, in RGB b, int a) {
	if (a < 0) a = 0;
	if (255 < a) a = 255;
	int oc(int c, int b) {
		if (c == b) return c;
		int mx = std.algorithm.max(c, b);
		int mn = std.algorithm.min(c, b);
		return mn + (mx - mn) - cast(int) ((mx - mn) * (a / 255.0));
	}
	return new RGB(oc(c.red, b.red), oc(c.green, b.green), oc(c.blue, b.blue));
}

/// 押されたキーに該当するアクセラレータを持つメニューを探す。
MenuItem findMenu(Shell shell, int keyCode, wchar character, int stateMask) {
	auto menu = shell.getMenuBar();
	if (!menu) return null;
	return findMenu(menu, keyCode, character, stateMask);
}
/// ditto
MenuItem findMenu(Menu menu, int keyCode, wchar character, int stateMask) {
	foreach (itm; menu.getItems()) {
		if (eqAcc(convertAccelerator(itm.getText()), keyCode, character, stateMask)) {
			return itm;
		}
		if (itm.getStyle() & SWT.CASCADE) {
			auto r = findMenu(itm.getMenu(), keyCode, character, stateMask);
			if (r) return r;
		}
	}
	return null;
}

/// FIXME: Combo#setItems()がエラーになることがあるため
void setComboItems(C)(C combo, string[] items) {
	combo.removeAll();
	foreach (item; items) {
		if (item is null) item = "";
		combo.add(item);
	}
}

/// Text/Combo/CComboに、アンドゥ・リドゥ及び
/// 切り取り・コピー・貼り付け・削除のメニューをつける。
TextMenuModify createTextMenu(T = Text)(Commons comm, Props prop, T text, bool delegate() canSaveHistory, UndoManager undo = null, TMAppendData apd = TMAppendData()) {
	bool readOnly = (text.getStyle() & SWT.READ_ONLY) != 0;
	if (!readOnly && !undo) {
		undo = new UndoManager(prop.var.etc.undoMaxEtc);
		void refUndoMax() {
			undo.max = prop.var.etc.undoMaxEtc;
		}
		comm.refUndoMax.add(&refUndoMax);
		text.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				comm.refUndoMax.remove(&refUndoMax);
			}
		});
	}
	TextMenuModify ml = null;
	if (!readOnly) {
		ml = new TextMenuModify(TMM(text), canSaveHistory, undo, apd);
		text.addModifyListener(ml);
	}

	auto menu = new Menu(text.getShell(), SWT.POP_UP);
	auto u = createMenuItem(menu, prop.msgs.menuUndo, prop.images.menuUndo, {undo.undo();});
	auto r = createMenuItem(menu, prop.msgs.menuRedo, prop.images.menuRedo, {undo.redo();});
	new MenuItem(menu, SWT.SEPARATOR);
	auto t = createMenuItem(menu, prop.msgs.menuCut, prop.images.menuCut, &text.cut);
	auto c = createMenuItem(menu, prop.msgs.menuCopy, prop.images.menuCopy, &text.copy);
	auto p = createMenuItem(menu, prop.msgs.menuPaste, prop.images.menuPaste, &text.paste);
	auto d = createMenuItem(menu, prop.msgs.menuDel, prop.images.menuDel, {
		auto p = text.getSelection();
		auto t = to!dstring(text.getText());
		if (t.length <= p.x) return;
		if (p.x != p.y) {
			text.setText(to!string(t[0 .. p.x] ~ t[p.y .. $]));
		} else {
			text.setText(to!string(t[0 .. p.x] ~ t[p.y + 1 .. $]));
		}
		text.setSelection(new Point(p.x, p.x));
	});
	new MenuItem(menu, SWT.SEPARATOR);
	auto a = createMenuItem(menu, prop.msgs.menuSelectAll, prop.images.menuSelectAll, {
		text.setSelection(new Point(0, text.getText().length));
	});
	u.setEnabled(!readOnly);
	r.setEnabled(!readOnly);
	t.setEnabled(!readOnly);
	p.setEnabled(!readOnly);
	d.setEnabled(!readOnly);
	text.setMenu(menu);

	return ml;
}
