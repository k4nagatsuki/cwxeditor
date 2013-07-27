
module cwx.editor.gui.dwt.dutils;

import cwx.cwl;
import cwx.area;
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
import cwx.graphics;
import cwx.path;
import cwx.menu;
import cwx.variables;
import cwx.flag;
import cwx.background;

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
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.cardlist;

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
import std.functional;
import std.typecons : Rebindable;

import org.eclipse.swt.all;

version (Windows) {
	import org.eclipse.swt.internal.win32.OS;
	import org.eclipse.swt.internal.win32.WINTYPES;
}

import java.lang.all;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;

bool dwtImageSize(Props prop, in Skin skin, in Summary summ, string path, out uint width, out uint height) {
	auto ext = .extension(path);
	if (cfnmatch(ext, ".jpy1")
			|| cfnmatch(ext, ".jptx")
			|| cfnmatch(ext, ".jpdc")) {
		bool resizable;
		auto img = loadJPYImage(prop, skin, summ, path, [], width, height, resizable);
		return img !is null;
	}
	return imageSize(path, width, height);
}

ImageData loadImage(string path, bool mask = true, int maskX = 0, int maskY = 0) {
	return loadImage(null, null, null, path, mask, maskX, maskY);
}
ImageData loadImage(Props prop, in Skin skin, in Summary summ, string path, bool mask = true, int maskX = 0, int maskY = 0, string[] stratum = []) {
	if (!isBinImg(path) && contains(stratum, nabs(path))) {
		// 無限再帰を回避
		return blankImage;
	}
	if (path !is null && path.length > 0) {
		string ext = .extension(path);
		if (cfnmatch(ext, ".jpy1")
				|| cfnmatch(ext, ".jptx")
				|| cfnmatch(ext, ".jpdc")) {
			bool resizable;
			auto data = loadJPYImage(prop, skin, summ, path, stratum, resizable);
			if (mask) data.transparentPixel = data.getPixel(maskX, maskY);
			return data;
		}
		try {
			byte[] bytes;
			if (isBinImg(path)) {
				bytes = cast(byte[])strToBImg(path);
			} else {
				if (!.exists(path)) return blankImage;
				bytes = cast(byte[])readBinary(path);
			}
			scope (exit) {
				if (!isBinImg(path)) delete bytes;
			}
			auto s = new ByteArrayInputStream(bytes);
			scope (exit) s.close();
			auto data = new ImageData(s);
			if (32 == data.depth && 'B' == bytes[0] && 'M' == bytes[1]) {
				// アルファ値を正しく取れないので補完しておく
				data.alphaData = new byte[data.width * data.height];
				foreach (y; 0 .. data.height) {
					foreach (x; 0 .. data.width) {
						data.alphaData[y * data.width + x] = cast(ubyte) data.data[y * data.bytesPerLine + x * 4 + 3];
					}
				}
			}
			if (mask && (!data.alphaData || !data.alphaData.length)) {
				data.transparentPixel = data.getPixel(maskX, maskY);
			}
			return data;
		} catch (SWTException e) {
			debugln(e);
		}
	}
	return blankImage;
}

@property
ImageData blankImage(int width = 1, int height = 1) {
	auto data = new ImageData(width, height, 32, new PaletteData(0xFF000000, 0xFF0000, 0xFF00));
	data.transparentPixel = data.getPixel(0, 0);
	return data;
}

Listener listener(Widget w, int type, void delegate(Event) l) {
	auto listener = .listener(l);
	w.addListener(type, listener);
	return listener;
}
Listener listener(Widget w, int type, void delegate() l) {
	auto listener = .listener(l);
	w.addListener(type, listener);
	return listener;
}
Listener listener(void delegate(Event) l) {
	return new class Listener {
		override void handleEvent(Event e) {
			l(e);
		}
	};
}
Listener listener(void delegate() l) {
	return new class Listener {
		override void handleEvent(Event e) {
			l();
		}
	};
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

class TextEditMFListener : MouseAdapter, SelectionListener, FocusListener {
private:
	Commons _comm;
	Display _display;
	Widget _oldFocusOut = null;
	Item _itm = null;
	Item _oldSel = null;
	bool _hasFocus = false;
	bool _start = false;
	Item delegate() _selection;
	Item delegate(int x, int y) _selectionM;
	void delegate(Item itm) _startEdit;

	class StartEdit : Runnable {
		private Item _itm;
		this (Item itm) { _itm = itm; }
		override void run() {
			if (_comm.prop.var.etc.editTriggerType is EditTrigger.Slow) {
				if (_start && !_itm.isDisposed() && _hasFocus && _itm == _selection()) {
					_startEdit(_itm);
				}
			}
			_start = false;
		}
	}
	class Starter {
		private Item _itm;
		private SysTime _time;
		this () {
			_time = Clock.currTime() + dur!"msecs"(_display.getDoubleClickTime());
			_itm = _selection();
			_start = true;
		}
		void run() {
			while (_start && Clock.currTime() <= _time) {
				core.thread.Thread.sleep(dur!("msecs")(1));
			}
			if (_start) {
				_display.asyncExec(new StartEdit(_itm));
			}
		}
	}
public:
	/// Params:
	/// startEdit = 編集開始時に呼出される。
	/// selection = 編集対象を返す。
	/// selectionM = 位置に応じて編集対象を返す。
	this (Commons comm, Control ctrl, void delegate(Item itm) startEdit,
			Item delegate() selection, Item delegate(int x, int y) selectionM) {
		_comm = comm;
		_display = Display.getCurrent();
		_startEdit = startEdit;
		_selection = selection;
		_selectionM = selectionM;
		auto filter = new class Listener {
			override void handleEvent(Event e) {
				_oldFocusOut = e.widget;
			}
		};
		_display.addFilter(SWT.FocusOut, filter);
		.listener(ctrl, SWT.Dispose, {
			_display.removeFilter(SWT.FocusOut, filter);
		});
	}
	override void widgetSelected(SelectionEvent e) {
		if (_comm.prop.var.etc.editTriggerType is EditTrigger.Quick) {
			_itm = _selection();
		}
		_oldSel = _selection();
	}
	override void widgetDefaultSelected(SelectionEvent e) {
		// 処理無し
	}
	override void focusGained(FocusEvent e) {
		_hasFocus = true;
		if (_comm.prop.var.etc.editTriggerType is EditTrigger.Quick) {
			_itm = _selection();
		}
	}
	override void focusLost(FocusEvent e) {
		_hasFocus = false;
		_start = false;
		_oldSel = null;
	}
	override void mouseDown(MouseEvent e) {
		auto itm = _selectionM(e.x, e.y);
		if (!itm) return;
		if (e.button != 1) return;
		if (_comm.prop.var.etc.editTriggerType is EditTrigger.Quick) {
			if (itm == _itm) {
				_startEdit(itm);
			}
		} else {
			if (2 <= e.count) {
				return;
			}
			if (_oldSel == _selection()) {
				(new core.thread.Thread(&(new Starter).run)).start();
			}
		}
	}
}
class TextEditKListener : KeyAdapter {
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

class EditEnd : KeyAdapter, FocusListener {
private:
	Commons _comm;
	Control ctrl;
	void delegate(Control) end;

public:
	this(Commons comm, Composite parent, Control ctrl, void delegate(Control) end) {
		try {
			_comm = comm;
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
			if (_comm.prop.var.etc.comboListVisible) {
				auto combo = cast(Combo) ctrl;
				if (combo) combo.setListVisible(true);
				auto ccombo = cast(CCombo) ctrl;
				if (ccombo) ccombo.setListVisible(true);
			}
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
	void cancel() {
		ctrl.dispose();
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

C createComboEditor(C = Combo)(Commons comm, Props prop, Composite parent, string[] strs, string str, bool readOnly = true) {
	try {
		int style = SWT.BORDER;
		if (readOnly) style |= SWT.READ_ONLY;
		auto combo = new C(parent, style);
		combo.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
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
	Commons _comm;
	Table table;
	TableEditor editor;
	EditEnd _tee = null;
	int editC;
	bool delegate(TableItem itm, int column) canEdit = null;

	Item selectionM(int x, int y) {
		try {
			if (table.getSelectionCount()) {
				auto itm = table.getItem(table.getSelectionIndex());
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
			if (table.getSelectionCount()) {
				return table.getItem(table.getSelectionIndex());
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
	this (Commons comm, Table table, int editC,
			bool delegate(TableItem itm, int column) canEdit = null) {
		try {
			_comm = comm;
			this.table = table;
			this.editC = editC;
			this.canEdit = canEdit;
			editor = new TableEditor(table);
			editor.grabHorizontal = true;

			auto mf = new TextEditMFListener(comm, table, &startEdit, &selectionK, &selectionM);
			table.addMouseListener(mf);
			table.addSelectionListener(mf);
			table.addFocusListener(mf);
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
				table.showSelection();
				_tee = new EditEnd(_comm, table, createEditor(sel, editC), &endImpl);
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
	void cancel() {
		if (!isEditing) return;
		_tee.cancel();
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
	Control delegate(TableItem itm, int editC) _createEditor = null;

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
			bool delegate(TableItem itm, int column) canEdit = null,
			Control delegate(TableItem itm, int editC) createEditor = null) {
		try {
			super (comm, table, editC, canEdit);
			_comm = comm;
			_prop = prop;
			this.editEnd = editEnd;
			_createEditor = createEditor;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	protected override Control createEditor(TableItem itm, int editC) {
		if (_createEditor) {
			return _createEditor(itm, editC);
		} else {
			return createTextEditor(_comm, _prop, itm.getParent(), itm.getText(editC));
		}
	}
	protected override void end(Control c) {
		try {
			string newText = null;
			if (auto t = cast(Text) c) {
				newText = t.getText();
			} else if (auto t = cast(Combo) c) {
				newText = t.getText();
			} else if (auto t = cast(CCombo) c) {
				newText = t.getText();
			}
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
			super (comm, table, editC, canEdit);
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
	this(Commons comm, Table table, int editC,
			Control delegate(TableItem itm, int editC) createEditor,
			void delegate(TableItem itm, int column, Control ctrl) editEnd = null,
			bool delegate(TableItem itm, int column) canEdit = null) {
		try {
			super (comm, table, editC, canEdit);
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
	Commons _comm;
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
				tree.showSelection();
				_tee = new EditEnd(_comm, tree, c, &end);
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
	/// createEditor = ツリーアイテムを編集するコンポーネントを生成する関数。
	///                nullを返した場合、編集は開始されない。
	this(Commons comm, Tree tree, void delegate(TreeItem itm, Control ctrl) editEnd,
			Control delegate(TreeItem itm) createEditor = null) {
		try {
			_comm = comm;
			this.tree = tree;
			this.editEnd = editEnd;
			this.createEditor = createEditor;
			editor = new TreeEditor(tree);
			editor.grabHorizontal = true;

			auto mf = new TextEditMFListener(comm, tree, &startEdit, &selectionK, &selectionM);
			tree.addMouseListener(mf);
			tree.addSelectionListener(mf);
			tree.addFocusListener(mf);
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

/// CardListのテキストを編集可能にする。
/// ダブルクリック、またはF2キーの押下で編集開始。
class CardListEdit(C) {
private:
	Commons _comm;
	CardList!C _list;
	EditEnd _tee;
	Control _editor = null;
	Item _edit = null;

	void delegate(C card, Control ctrl) _editEnd;
	Control delegate(in C card) _createEditor;

	Item selectionM(int x, int y) {
		auto sels = _list.selectionIndices();
		if (1 == sels.length && _list.getTitleBounds(sels[0]).contains(x, y)) {
			return _list.getItem(sels[0]);
		}
		return null;
	}
	Item selectionK() {
		auto sels = _list.selectionIndices();
		if (1 == sels.length) {
			return _list.getItem(sels[0]);
		}
		return null;
	}

	void end(Control ctrl) {
		assert (_edit !is null);
		_editEnd(cast(C)_edit.getData(), ctrl);
		_tee = null;
		_edit = null;
		_editor = null;
	}

	void startEdit(Item itm) {
		if (_tee !is null && !_tee.isExit) _tee.enter();
		auto sel = cast(C)itm.getData();
		_editor = _createEditor(sel);
		if (_editor) {
			_edit = itm;
			_list.scroll(_list.indexOf(sel));
			_tee = new EditEnd(_comm, _list, _editor, &end);
			layout();
			_tee.setFocus();
		}
	}
	void layout() {
		if (!_edit) return;
		auto cItm = _list.indexOf(_edit);
		auto ib = _list.getImageBounds(cItm);
		auto tb = _list.getTitleBounds(cItm);
		auto size = _editor.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		int x = ib.x;
		int y = tb.y + (tb.height - size.y) / 2;
		int w = ib.width;
		int h = size.y;
		_editor.setBounds(x, y, w, h);
	}
public:
	/// list = テキスト編集対象のリスト。
	/// editEnd = 編集終了時に実行される関数。
	/// createEditor = アイテムを編集するコンポーネントを生成する関数。
	///                nullを返した場合、編集は開始されない。
	this(Commons comm, CardList!C list, void delegate(C card, Control ctrl) editEnd,
			Control delegate(in C card) createEditor = null) {
		_comm = comm;
		_list = list;
		_editEnd = editEnd;
		_createEditor = createEditor;

		auto mf = new TextEditMFListener(comm, list, &startEdit, &selectionK, &selectionM);
		list.addMouseListener(mf);
		list.addSelectionListener(mf);
		list.addFocusListener(mf);
		list.addKeyListener(new TextEditKListener(&startEdit, &selectionK));
		.listener(list, SWT.Paint, &layout);
	}
	/// 選択されているセルの編集を開始する。
	void startEdit() {
		auto sels = _list.selectionIndices();
		if (sels.length == 1) {
			startEdit(_list.getItem(sels[0]));
		}
	}
	bool isEditing() {
		return _tee !is null;
	}
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

void drawCenterText(FontData fontData, GC gc, Rectangle ca, string str) {
	auto oldFont = gc.getFont();
	scope (exit) gc.setFont(oldFont);
	auto font = new Font(Display.getCurrent(), fontData);
	scope (exit) font.dispose();
	gc.setFont(font);
	auto te = gc.textExtent(str);
	int x = ca.x + (ca.width - te.x) / 2;
	int y = ca.y + (ca.height - te.y) / 2;
	gc.drawText(str, x, y, true);
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
ImageData castCardImage(Props prop, Skin skin, in CastCard c, string sPath, bool dbgMode) {
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
	r.append(skin.findImagePath(c.path, sPath), matPad, ScaleType.Center, true);
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
				r.append(life, stp, ScaleType.Cut);
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
		r.append(id, stp, ScaleType.Cut);
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
		void colorBlock(ImageData iData, CRGB rgb) {
			auto id = new ImageData(iData.width, iData.height, 1, new PaletteData([new RGB(rgb.r, rgb.g, rgb.b), new RGB(0, 0, 0)]));
			r.append(id, stp, ScaleType.Cut);
		}
		auto value = c.enhance(enh);
		auto round = c.enhanceRound(enh);
		if (value > 0 && round > 0) {
			CRGB back;
			if (prop.var.etc.enhanceMaxVal <= value) {
				back = prop.var.etc.enhanceColorMax;
			} else if (prop.var.etc.enhanceHighVal <= value) {
				back = prop.var.etc.enhanceColorHigh;
			} else if (prop.var.etc.enhanceMiddleVal <= value) {
				back = prop.var.etc.enhanceColorMiddle;
			} else if (1 <= value) {
				back = prop.var.etc.enhanceColorLow;
			}
			auto iData = enhanceUp(skin, enh);
			colorBlock(iData, back);
			status(iData);
		} else if (value < 0 && round > 0) {
			CRGB back;
			if (-(cast(int) prop.var.etc.enhanceMaxVal) >= value) {
				back = prop.var.etc.penaltyColorMax;
			} else if (-(cast(int) prop.var.etc.enhanceHighVal) >= value) {
				back = prop.var.etc.penaltyColorHigh;
			} else if (-(cast(int) prop.var.etc.enhanceMiddleVal) >= value) {
				back = prop.var.etc.penaltyColorMiddle;
			} else if (-1 >= value) {
				back = prop.var.etc.penaltyColorLow;
			}
			auto iData = enhanceDown(skin, enh);
			colorBlock(iData, back);
			status(iData);
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
		r.append(bmp.getImageData(), stp, ScaleType.Cut);
	}
	r.setTitle(c.name, dwtData(prop.looks.castCardNameFont(skin.legacy)), dwtData(prop.looks.castCardNamePoint));
	return r.createImageData();
}
ImageData cardImage(C)(Props prop, Skin skin, in C base, string sPath, CastCard owner, C delegate(ulong) get, bool detail, bool preview) {
	static if (is (C == SkillCard)) {
		bool hold = base.hold;
		auto card = skillCard(skin);
	} else static if (is (C == ItemCard)) {
		bool hold = base.hold;
		auto card = itemCard(skin);
	} else static if (is (C == BeastCard)) {
		auto card = beastCard(skin);
	} else static if (is (C == InfoCard)) {
		auto card = infoCard(skin);
	} else {
		static assert (0);
	}
	bool link = false;
	Rebindable!(const(C)) c = base;
	static if (is(typeof(base.linkId))) {
		if (get && 0 != base.linkId) {
			link = true;
			c = get(c.linkId);
			if (!c) c = new C(1UL, "", "", "");
		}
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
			r.append(img, CInsets(pp.y, pp.x, h - pp.y - img.height, w - pp.x - img.width), ScaleType.Cut);
			r.append(img, CInsets(h - pp.y - img.height, w - pp.x - img.width, pp.y, pp.x), ScaleType.Cut);
			break;
		case Premium.NORMAL:
			break;
		}
	}
	static if (is(C:SkillCard)) {
		if (prop.var.etc.showSkillCardLevel) {
			r.append(to!(string)(c.level),
				prop.looks.skillCardLevelInsets,
				prop.looks.skillCardLevelFont(skin.legacy),
				prop.looks.skillCardLevelColor,
				PileImage.TPos.RIGHT);
		}
	}
	r.append(skin.findImagePath(c.path, sPath), matPad, ScaleType.Cut, true);
	static if (is(typeof(c.linkId))) {
		if (link) {
			auto mc = prop.var.etc.linkCardMaskColor;
			r.colorMask(mc.r, mc.g, mc.b, mc.a);
		}
	}
	static if (!is(C == InfoCard)) {
		if (prop.sys.isPenalty(c.keyCodes)) {
			auto pid = cardPenalty(skin);
			pid.transparentPixel = pid.getPixel(pid.width / 2, pid.height / 2);
			r.append(pid, CPoint(0, 0), ScaleType.Cut);
		}
		static if (is(typeof(c.hold))) {
			if (hold) {
				auto hid = cardHold(skin);
				hid.transparentPixel = hid.getPixel(hid.width / 2, hid.height / 2);
				r.append(hid, CPoint(0, 0), ScaleType.Cut);
			}
		}
		if (detail && owner) {
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
			r.append(aimg, CInsets(ap.y, w - ap.x - aimg.width, h - ap.y - aimg.height, ap.x), ScaleType.Cut);
			static if (is (C == SkillCard)) {
				auto uimg = use4(skin);
				auto up = prop.looks.useStoneXY;
				r.append(uimg, CInsets(up.y, w - up.x - uimg.width, h - up.y - uimg.height, up.x), ScaleType.Cut);
			}
		}
	}
	r.setTitle(c.name, dwtData(prop.looks.cardNameFont(skin.legacy)), dwtData(prop.looks.cardNamePoint));
	void putEventTree(bool useCount) {
		static if (is(C:EventTreeOwner)) {
			if (preview || !prop.var.etc.showEventTreeMark) return;
			auto et = useCount ? prop.looks.eventTreeXYWithCount : prop.looks.eventTreeXY;
			if (detail && (prop.var.etc.ignoreEmptyStart ? !c.isEmpty : 0 < c.trees.length)) {
				auto iData = prop.images.eventTree.getImageData();
				r.append(iData, CInsets(et.y, w - et.x - iData.width, h - et.y - iData.height, et.x), ScaleType.Cut);
			}
		}
	}
	static if (is(C : ItemCard) || is(C : BeastCard)) {
		static if (is(C : ItemCard)) {
			auto ul = c.useLimitMax;
		} else static if (is(C : BeastCard)) {
			auto ul = c.useLimit;
		} else static assert (0);
		if (ul > 0) {
			putEventTree(true);

			auto d = Display.getCurrent();
			auto imgData = r.createImageData();
			auto img = new Image(d, imgData);
			scope (exit) img.dispose();
			auto gc = new GC(img);
			scope (exit) gc.dispose();
			auto font = new Font(d, dwtData(prop.looks.useCountFont(skin.legacy)));
			scope (exit) font.dispose();
			gc.setFont(font);
			bool res = prop.sys.isRecycle(c.keyCodes);
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
	putEventTree(false);
	return r.createImageData();
}

Rectangle eventTreeMarkRect(C:EventTreeOwner)(Props prop, int left, int top, in C c) {
	if (!prop.var.etc.showEventTreeMark) return null;

	static if (is(C:ItemCard)) {
		bool useCount = 0 < c.useLimitMax;
	} else static if (is(C:BeastCard)) {
		bool useCount = 0 < c.useLimit;
	} else {
		bool useCount = false;
	}

	auto et = useCount ? prop.looks.eventTreeXYWithCount : prop.looks.eventTreeXY;
	if (prop.var.etc.ignoreEmptyStart ? !c.isEmpty : 0 < c.trees.length) {
		auto bounds = prop.images.eventTree.getBounds();
		bounds.x = left + et.x;
		bounds.y = top + et.y;
		return bounds;
	}
	return null;
}

string[] castCoupons(Commons comm, bool talker, string legacyName) {
	string[] r;
	if (!talker) {
		foreach (c; comm.prop.var.etc.standardCoupons) {
			r ~= c;
		}
	}
	foreach (e; SEX_ALL) {
		r ~= comm.skin.sexCoupon(e);
	}
	foreach (e; PERIOD_ALL) {
		r ~= comm.skin.periodCoupon(e);
	}
	foreach (e; comm.prop.var.etc.showSpNature ? (NATURE_DEF ~ NATURE_EXT) : NATURE_DEF) {
		r ~= comm.skin.natureCoupon(e);
	}
	foreach (e; MAKINGS_LEFT) {
		r ~= comm.skin.makingsCoupon(e);
		r ~= comm.skin.makingsCoupon(reverseMakings(e));
	}
	return r;
}

bool qMaterialCopy(Commons comm, Shell shell,
		UseCounter uc, string toSPath, string fromSPath, out bool copy, bool toIsLegacy) {
	auto prop = comm.prop;
	auto skin = comm.skin;
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
	uint bin = 0u;
	string[] msgPaths;
	foreach (p; paths) {
		if (isBinImg(p)) {
			bin++;
		} else {
			msgPaths ~= std.path.buildPath(fromSPath, p);
		}
	}
	bool cancel = false;
	bool question(string msg) {
		auto copyM = new MessageBox(shell, SWT.YES | SWT.NO | SWT.CANCEL | SWT.ICON_QUESTION);
		copyM.setText(prop.msgs.dlgTitQuestion);
		copyM.setMessage(msg);
		switch (copyM.open()) {
		case SWT.YES:
			cancel = false;
			return true;
		case SWT.NO:
			cancel = false;
			return false;
		case SWT.CANCEL:
			cancel = true;
			return false;
		default:
			assert (0);
		}
	}
	bool copyMates = false;
	bool binImgToRef = false;
	if (!msgPaths.length && bin) {
		copyMates = true;
		if (!toIsLegacy || prop.var.etc.saveInnerImagePath) {
			binImgToRef = question(prop.msgs.dlgMsgCopyMaterial1);
		} else {
			binImgToRef = false;
		}
	} else if (msgPaths.length && !bin) {
		binImgToRef = false; // 格納イメージは存在しない
		if (1 == msgPaths.length) {
			copyMates = question(.tryFormat(prop.msgs.dlgMsgCopyMaterial2, msgPaths[0]));
		} else {
			copyMates = question(.tryFormat(prop.msgs.dlgMsgCopyMaterial3, msgPaths.length));
		}
	} else {
		binImgToRef = !toIsLegacy || prop.var.etc.saveInnerImagePath;
		copyMates = question(.tryFormat(prop.msgs.dlgMsgCopyMaterial4, msgPaths.length, bin));
	}
	if (copyMates && !cancel) {
		bool err = false;
		foreach (i, key; paths) {
			// ファイルのコピーと参照の更新
			string path = isBinImg(key) ? key : std.path.buildPath(fromSPath, key);
			try {
				auto newp = copyTo(toSPath, path, skin.materialPath, binImgToRef);
				if (!isBinImg(newp) && key != newp) {
					uc.change(toPathId(key), toPathId(newp));
				}
				copy = true;
			} catch (Exception e) {
				debugln("copy error: " ~ e.msg);
				err = true;
			}
		}
		if (!toIsLegacy) {
			// 転送先は格納イメージ無効
			foreach (key; uc.path.keys) {
				if (key.isBinImg) {
					uc.change(key, toPathId(""), true);
				}
			}
		}
		if (err) {
			MessageBox.showWarning(prop.msgs.dlgMsgCopyError, prop.msgs.dlgTitWarning, shell);
		}
		return true;
	} else {
		return !cancel;
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

void drawWallpaper(GC gc, Image img, Rectangle rect, WallpaperStyle style) {
	final switch (style) {
	case WallpaperStyle.Center:
		auto data = img.getBounds();
		int xi, yi, wi, hi;
		int xw, yw, ww, hw;
		void cen(int rectX, int rectW, int dataW, out int xi, out int wi, out int xw, out int ww) {
			xw = (rectW - dataW) / 2;
			if (xw >= 0) {
				xi = 0;
				wi = dataW;
				ww = dataW;
			} else {
				xi = -xw;
				wi = rectW;
				xw = 0;
				ww = rectW;
			}
			xw += rectX;
		}
		cen(rect.x, rect.width, data.width, xi, wi, xw, ww);
		cen(rect.y, rect.height, data.height, yi, hi, yw, hw);
		gc.drawImage(img, xi, yi, wi, hi, xw, yw, ww, hw);
		break;
	case WallpaperStyle.Tile:
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
		break;
	case WallpaperStyle.ExpandFull, WallpaperStyle.Expand:
		auto data = img.getImageData();
		real scW = cast(real) rect.width / data.width;
		real scH = cast(real) rect.height / data.height;
		int wi, hi;
		if ((style == WallpaperStyle.ExpandFull) ? (scW < scH) : (scW >= scH)) {
			wi = cast(int) (data.width * scH);
			hi = rect.height;
		} else {
			wi = rect.width;
			hi = cast(int) (data.height * scW);
		}
		if (data.width != wi || data.height != hi) {
			auto d = Display.getCurrent();
			if (!data.palette.isDirect || data.depth < 16 || 24 < data.depth) {
				auto buf = new Image(d, data.width, data.height);
				scope (exit) buf.dispose();
				auto igc = new GC(buf);
				scope (exit) igc.dispose();
				igc.drawImage(img, 0, 0);
				auto data2 = buf.getImageData();
				if (24 < data.depth) data2.alphaData = data.alphaData;
				data = data2;
			}
			size_t bpl;
			auto bdata = cast(ubyte[]) data.data;
			auto alpha = cast(ubyte[]) data.alphaData;
			data.data = cast(byte[]) cwx.graphics.smoothResize(wi, hi, bdata, alpha,
				data.depth, data.width, data.height, data.bytesPerLine, bpl);
			data.alphaData = cast(byte[]) alpha;
			data.width = wi;
			data.height = hi;
			data.bytesPerLine = bpl;
			auto img2 = new Image(d, data);
			scope (exit) img2.dispose();
			drawWallpaper(gc, img2, rect, WallpaperStyle.Center);
		} else {
			drawWallpaper(gc, img, rect, WallpaperStyle.Center);
		}
		break;
	}
}

/// FIXME: Combo#setItems()がエラーになることがあるため
void setComboItems(C)(C combo, string[] items) {
	combo.removeAll();
	foreach (item; items) {
		if (item is null) item = "";
		combo.add(item);
	}
}

/// Windows Vista以降で、Treeに点線を表示する。
void initTree(Commons comm, Tree tree, bool eventTree) {
	version (Windows) {
		if (eventTree) {
			Listener keyDown = null, mouseDoubleClick = null, collapse = null;
			void updateTreeStyle() {
				auto style = OS.GetWindowLong(tree.handle, GWL_STYLE);
				style |= OS.TVS_HASLINES;
				if (comm.prop.var.etc.classicStyleTree) {
					style &= ~OS.TVS_HASBUTTONS;
					style &= ~OS.TVS_LINESATROOT;
					if (!keyDown) {
						keyDown = new class Listener {
							override void handleEvent(Event e) {
								auto itms = tree.getSelection();
								if (!itms.length) return;
								if (SWT.ARROW_LEFT is e.keyCode) {
									auto par = itms[0].getParentItem();
									if (par) {
										tree.setSelection(par);
										comm.refreshToolBar();
										e.doit = false;
										return;
									}
								}
							}
						};
						mouseDoubleClick = new class Listener {
							override void handleEvent(Event e) {
								if (1 != e.button) return;
								auto itm = tree.getItem(new Point(e.x, e.y));
								if (!itm) return;
								if (!itm.getParentItem()) {
									itm.setExpanded(!itm.getExpanded());
									tree.redraw();
									comm.refreshToolBar();
								}
							}
						};
						collapse = new class Listener {
							override void handleEvent(Event e) {
								auto itm = cast(TreeItem)e.item;
								if (!itm) return;
								if (itm.getParentItem()) {
									itm.getDisplay().asyncExec(new class Runnable {
										override void run() {
											if (!itm.isDisposed()) {
												itm.setExpanded(true);
											}
										}
									});
								}
							}
						};
						tree.addListener(SWT.KeyDown, keyDown);
						tree.addListener(SWT.MouseDoubleClick, mouseDoubleClick);
						tree.addListener(SWT.Collapse, collapse);
					}
					void recurse(TreeItem itm) {
						if (itm.getParentItem()) {
							itm.setExpanded(true);
						}
						foreach (c; itm.getItems()) {
							recurse(c);
						}
					}
					foreach (itm; tree.getItems()) {
						recurse(itm);
					}
				} else {
					style |= OS.TVS_HASBUTTONS;
					style |= OS.TVS_LINESATROOT;
					if (keyDown) {
						tree.removeListener(SWT.KeyDown, keyDown);
						tree.removeListener(SWT.MouseDoubleClick, mouseDoubleClick);
						tree.removeListener(SWT.Collapse, collapse);
						keyDown = null;
						mouseDoubleClick = null;
						collapse = null;
					}
				}
				style = OS.SetWindowLong(tree.handle, GWL_STYLE, style);
				OS.SetWindowPos(tree.handle, null, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
			}
			comm.refEventTreeStyle.add(&updateTreeStyle);
			.listener(tree, SWT.Dispose, {
				comm.refEventTreeStyle.remove(&updateTreeStyle);
			});
			updateTreeStyle();
		} else {
			auto style = OS.GetWindowLong(tree.handle, GWL_STYLE);
			style |= OS.TVS_HASLINES;
			style &= ~OS.TVS_LINESATROOT;
			style = OS.SetWindowLong(tree.handle, GWL_STYLE, style);
			OS.SetWindowPos(tree.handle, null, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
		}
	}
}

class CloseRemover(Window) : DisposeListener {
	private HashSet!(Window) _ws;
	private Window _w;
	public this (HashSet!(Window) ws, Window w) {
		_ws = ws;
		_w = w;
	}
	public override void widgetDisposed(DisposeEvent e) {
		if (_ws.contains(_w)) {
			_ws.remove(_w);
		} else assert (0);
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

class StopBGM : SelectionAdapter, DisposeListener {
	override void widgetSelected(SelectionEvent e) {
		stopBGM();
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

bool playBGMCW(Props prop, string path, bool legacy) {
    version (Windows) {} else {immutable SOUND_TYPE_MCI = -1;}
	int playType = prop.var.etc.soundPlayType;
	switch (playType) {
	case SOUND_TYPE_SDL: playBGM(path, SOUND_TYPE_SDL); return true;
	case SOUND_TYPE_MCI:
		version (Windows) {
			playBGM(path, SOUND_TYPE_MCI);
			return true;
		} else {
			goto default;
		}
	case SOUND_TYPE_APP: Program.launch(path); return false;
	default:
		// auto
		int type;
		if (legacy) {
			type = SOUND_TYPE_MCI;
			version (Windows) {
				if (.canPlayBass(path)) {
					type = SOUND_TYPE_BASS;
				}
			}
		} else {
			type = SOUND_TYPE_SDL;
		}
		playBGM(path, type);
		return true;
	}
}

void playSECW(Props prop, string path, bool legacy) {
    version (Windows) {} else {immutable SOUND_TYPE_MCI = -1;}
	int type = prop.var.etc.soundEffectPlayType;
	if (SOUND_TYPE_SAME_BGM == type) {
		type = prop.var.etc.soundPlayType;
	}
	switch (type) {
	case SOUND_TYPE_SDL: playSE(path, SOUND_TYPE_SDL); break;
	case SOUND_TYPE_MCI:
		version (Windows) {
			playSE(path, SOUND_TYPE_MCI);
			break;
		} else {
			goto default;
		}
	case SOUND_TYPE_APP: Program.launch(path); break;
	default:
		// auto
		if (legacy) {
			type = SOUND_TYPE_MCI;
			version (Windows) {
				if (.canPlayBass(path)) {
					type = SOUND_TYPE_BASS;
				}
			}
		} else {
			type = SOUND_TYPE_SDL;
		}
		playSE(path, type);
		break;
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

string objName(A)(in Props prop) {
	static if (is(A : Area)) {
		return prop.msgs.area;
	} else static if (is(A : Battle)) {
		return prop.msgs.battle;
	} else static if (is(A : Package)) {
		return prop.msgs.cwPackage;
	} else static if (is(A : CastCard)) {
		return prop.msgs.cwCast;
	} else static if (is(A : SkillCard)) {
		return prop.msgs.skill;
	} else static if (is(A : ItemCard)) {
		return prop.msgs.item;
	} else static if (is(A : BeastCard)) {
		return prop.msgs.beast;
	} else static if (is(A : InfoCard)) {
		return prop.msgs.info;
	} else static if (is(A : Flag)) {
		return prop.msgs.flag;
	} else static if (is(A : Step)) {
		return prop.msgs.step;
	} else static assert (0);
}

enum CIDKind {
	Area,
	Battle,
	Package,
	Cast,
	Skill,
	Item,
	Beast,
	Info,
	Image,
	BGM,
	SE,
	Flag,
	Step,
	Start,
}
string contentTextUseID(CIDKind Kind, ID)(Commons comm, Summary summ, ID id, string msg, in Content evt) {
	string noSelect;
	string noID;
	bool use;
	bool delegate() find;
	string name;
	static if (CIDKind.Area == Kind) {
		noSelect = comm.prop.msgs.noSelectArea;
		noID = comm.prop.msgs.noArea;
		use = 0 != id;
		auto a = summ.area(id);
		find = () => a !is null;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Battle == Kind) {
		noSelect = comm.prop.msgs.noSelectBattle;
		noID = comm.prop.msgs.noBattle;
		use = 0 != id;
		auto a = summ.battle(id);
		find = () => a !is null;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Package == Kind) {
		noSelect = comm.prop.msgs.noSelectPackage;
		noID = comm.prop.msgs.noPackage;
		use = 0 != id;
		auto a = summ.cwPackage(id);
		find = () => a !is null;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Cast == Kind) {
		noSelect = comm.prop.msgs.noSelectCast;
		noID = comm.prop.msgs.noCast;
		use = 0 != id;
		auto a = summ.cwCast(id);
		find = () => a !is null;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Skill == Kind) {
		noSelect = comm.prop.msgs.noSelectSkill;
		noID = comm.prop.msgs.noSkill;
		auto a = summ.skill(id);
		find = () => a !is null;
		use = 0 != id;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Item == Kind) {
		noSelect = comm.prop.msgs.noSelectItem;
		noID = comm.prop.msgs.noItem;
		auto a = summ.item(id);
		find = () => a !is null;
		use = 0 != id;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Beast == Kind) {
		noSelect = comm.prop.msgs.noSelectBeast;
		noID = comm.prop.msgs.noBeast;
		auto a = summ.beast(id);
		find = () => a !is null;
		use = 0 != id;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Info == Kind) {
		noSelect = comm.prop.msgs.noSelectInfo;
		noID = comm.prop.msgs.noInfo;
		auto a = summ.info(id);
		find = () => a !is null;
		use = 0 != id;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Image == Kind) {
		noSelect = comm.prop.msgs.noSelectImage;
		noID = comm.prop.msgs.noImage;
		find = () => comm.skin.findImagePath(id, summ.scenarioPath).length > 0;
		use = id && id.length;
		name = id;
	} else static if (CIDKind.BGM == Kind) {
		noSelect = comm.prop.msgs.noSelectBGM;
		noID = comm.prop.msgs.noBGM;
		find = () => comm.skin.findPath(id, comm.skin.extBgm, comm.skin.bgmDir, summ.scenarioPath).length > 0;
		use = id && id.length;
		name = id;
	} else static if (CIDKind.SE == Kind) {
		noSelect = comm.prop.msgs.noSelectSE;
		noID = comm.prop.msgs.noSE;
		find = () => comm.skin.findPath(id, comm.skin.extSound, comm.skin.seDir, summ.scenarioPath).length > 0;
		use = id && id.length;
		name = id;
	} else static if (CIDKind.Flag == Kind) {
		noSelect = comm.prop.msgs.noSelectFlag;
		noID = comm.prop.msgs.noFlag;
		find = () => summ.flagDirRoot.findFlag(id) !is null;
		use = id && id.length;
		name = id;
	} else static if (CIDKind.Step == Kind) {
		noSelect = comm.prop.msgs.noSelectStep;
		noID = comm.prop.msgs.noStep;
		find = () => summ.flagDirRoot.findStep(id) !is null;
		use = id && id.length;
		name = id;
	} else static if (CIDKind.Start == Kind) {
		noSelect = comm.prop.msgs.noSelectStart;
		noID = comm.prop.msgs.noStart;
		find = () => evt.tree.hasStart(id);
		use = id && id.length;
		if ("" == id && evt) {
			foreach (s; evt.tree.starts) {
				if (!s.name.length) {
					use = true;
					break;
				}
			}
		}
		name = id;
	} else static assert (0);
	if (!use) return .tryFormat(msg, noSelect);
	bool exists = find();
	static if (CIDKind.Image == Kind || CIDKind.BGM == Kind || CIDKind.SE == Kind) {
		name = .encodePath(name);
		id = name;
	}
	if (exists) {
		return .tryFormat(msg, name);
	} else {
		return .tryFormat(msg, .tryFormat(noID, id));
	}
}

string contentText(Commons comm, in Content evt, Summary summ = null) {
	if (!summ) summ = comm.summary;
	string loseCardCount() {
		return evt.cardNumber == 0 ? comm.prop.msgs.ctLoseCardAll : .tryFormat(comm.prop.msgs.ctLoseCardCount, evt.cardNumber);
	}
	final switch (evt.type) {
	case CType.START: {
		return .tryFormat(comm.prop.msgs.ctStart, evt.name);
	} case CType.START_BATTLE: {
		return contentTextUseID!(CIDKind.Battle)(comm, summ, evt.battle, comm.prop.msgs.ctStartBattle, evt);
	} case CType.END: {
		return evt.complete ? comm.prop.msgs.ctEndComplete : comm.prop.msgs.ctEndNoComplete;
	} case CType.END_BAD_END: {
		return comm.prop.msgs.ctGameOver;
	} case CType.CHANGE_AREA: {
		if (summ && summ.legacy) {
			return contentTextUseID!(CIDKind.Area)(comm, summ, evt.area, comm.prop.msgs.ctChangeAreaClassic, evt);
		} else {
			string a = contentTextUseID!(CIDKind.Area)(comm, summ, evt.area, "%s", evt);
			string v = comm.prop.msgs.transitionName(evt.transition);
			return .tryFormat(comm.prop.msgs.ctChangeArea, a, v, evt.transitionSpeed);
		}
	} case CType.CHANGE_BG_IMAGE: {
		string buf;
		foreach (i, b; evt.backs) {
			auto ic = cast(ImageCell) b;
			if (ic) {
				buf ~= contentTextUseID!(CIDKind.Image)(comm, summ, ic.path, comm.prop.msgs.ctChangeBgImageFile, null);
			} else {
				buf ~= .tryFormat(comm.prop.msgs.ctChangeBgImageFile, b.name);
			}
			if (i + 1 < evt.backs.length) buf ~= " ";
		}
		if (summ && summ.legacy) {
			return .tryFormat(comm.prop.msgs.ctChangeBgImageClassic, buf);
		} else {
			string v = comm.prop.msgs.transitionName(evt.transition);
			return .tryFormat(comm.prop.msgs.ctChangeBgImage, buf, v, evt.transitionSpeed);
		}
	} case CType.EFFECT: {
		string tt = comm.prop.msgs.targetName(evt.targetNS.m);
		int tl = evt.signedLevel;
		string tet = comm.prop.msgs.effectTypeName(evt.effectType);
		string tr = comm.prop.msgs.resistName(evt.resist);
		string tsf = evt.successRate >= 0 ? "+" : "-";
		int ts = std.math.abs(evt.successRate);
		string tsnd = contentTextUseID!(CIDKind.SE)(comm, summ, evt.soundPath, comm.prop.msgs.ctEffectSound, evt);
		string tcv = comm.prop.msgs.cardVisualName(evt.cardVisual);
		string teff = "";
		foreach (i, m; evt.motions) {
			teff ~= .tryFormat(comm.prop.msgs.ctEffectMotion, comm.prop.msgs.motionName(m.type));
			if (i + 1 < evt.motions.length) teff ~= " ";
		}
		return .tryFormat(comm.prop.msgs.ctEffect, tt, tl, tet, tr, tsf, ts, tsnd, tcv, teff);
	} case CType.EFFECT_BREAK: {
		return comm.prop.msgs.ctEffectBreak;
	} case CType.LINK_START: {
		return contentTextUseID!(CIDKind.Start)(comm, summ, evt.start, comm.prop.msgs.ctLinkStart, evt);
	} case CType.LINK_PACKAGE: {
		return contentTextUseID!(CIDKind.Package)(comm, summ, evt.packages, comm.prop.msgs.ctLinkPackage, evt);
	} case CType.TALK_MESSAGE: {
		string text = evt.text;
		text = text.singleLine;
		final switch (evt.talkerC) {
		case Talker.NARRATION:
			return text;
		case Talker.SELECTED:
		case Talker.UNSELECTED:
		case Talker.RANDOM:
		case Talker.CARD:
		case Talker.VALUED:
			return .tryFormat(comm.prop.msgs.ctTalkMessage, comm.prop.msgs.talkerName(evt.talkerC), text);
		case Talker.IMAGE:
			string t = contentTextUseID!(CIDKind.Image)(comm, summ, evt.cardPath, comm.prop.msgs.ctTalkMessageImage, evt);
			return .tryFormat(comm.prop.msgs.ctTalkMessage, t, text);
		}
	} case CType.TALK_DIALOG: {
		string r(in SDialog sdlg) {
			string tt = comm.prop.msgs.talkerName(evt.talkerNC);
			string t = sdlg.text.singleLine;
			if (sdlg.rCoupons.length) {
				return .tryFormat(comm.prop.msgs.ctTalkDialog, tt, std.string.join(sdlg.rCoupons.dup, " "), t);
			} else {
				return .tryFormat(comm.prop.msgs.ctTalkDialogNoCoupon, tt, t);
			}
		}
		assert (evt.dialogs.length);
		int status = comm.prop.var.etc.dialogStatus;
		switch (status) {
		case DialogStatus.Top:
			return r(evt.dialogs[0]);
		case DialogStatus.Under:
			return r(evt.dialogs[$ - 1]);
		case DialogStatus.UnderWithCoupon:
			foreach_reverse (dlg; evt.dialogs) {
				if (dlg.rCoupons.length) {
					return r(dlg);
				}
			}
			return r(evt.dialogs[$ - 1]);
		default:
			return r(evt.dialogs[0]);
		}
	} case CType.PLAY_BGM: {
		if ("" == evt.bgmPath) {
			return  comm.prop.msgs.ctStopBGM;
		} else {
			return contentTextUseID!(CIDKind.BGM)(comm, summ, evt.bgmPath, comm.prop.msgs.ctPlayBGM, evt);
		}
	} case CType.PLAY_SOUND: {
		return contentTextUseID!(CIDKind.SE)(comm, summ, evt.soundPath, comm.prop.msgs.ctPlaySound, evt);
	} case CType.WAIT: {
		return .tryFormat(comm.prop.msgs.ctWait, evt.wait);
	} case CType.ELAPSE_TIME: {
		return comm.prop.msgs.ctElapseTime;
	} case CType.CALL_START: {
		return contentTextUseID!(CIDKind.Start)(comm, summ, evt.start, comm.prop.msgs.ctCallStart, evt);
	} case CType.CALL_PACKAGE: {
		return contentTextUseID!(CIDKind.Package)(comm, summ, evt.packages, comm.prop.msgs.ctCallPackage, evt);
	} case CType.BRANCH_FLAG: {
		return contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag, comm.prop.msgs.ctBranchFlag, evt);
	} case CType.BRANCH_MULTI_STEP: {
		return contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, comm.prop.msgs.ctBranchMultiStep, evt);
	} case CType.BRANCH_STEP: {
		string s = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
		auto step = summ.flagDirRoot.findStep(evt.step);
		string v = step ? step.getValue(evt.stepValue) : .tryFormat(comm.prop.msgs.dlgLblStep, evt.stepValue);
		return .tryFormat(comm.prop.msgs.ctBranchStep, s, v);
	} case CType.BRANCH_SELECT: {
		string t = evt.targetAll ? comm.prop.msgs.ctBranchSelectAll : comm.prop.msgs.ctBranchSelectActive;
		string r = evt.random ? comm.prop.msgs.ctBranchSelectAuto : comm.prop.msgs.ctBranchSelectManual;
		return .tryFormat(comm.prop.msgs.ctBranchSelect, t, r);
	} case CType.BRANCH_ABILITY: {
		string t = comm.prop.msgs.targetName(evt.targetS.m);
		string p = comm.prop.msgs.physicalName(evt.physical);
		string m = comm.prop.msgs.mentalName(evt.mental);
		string s = evt.targetS.sleep ? comm.prop.msgs.sleepEnabled : comm.prop.msgs.sleepDisabled;
		auto l = evt.signedLevel;
		return .tryFormat(comm.prop.msgs.ctBranchAbility, t, s, p, m, l);
	} case CType.BRANCH_RANDOM: {
		return .tryFormat(comm.prop.msgs.ctBranchRandom, evt.percent);
	} case CType.BRANCH_LEVEL: {
		string a = evt.average ? comm.prop.msgs.ctBranchLevelAverage : comm.prop.msgs.ctBranchLevelSelected;
		auto l = evt.unsignedLevel;
		return .tryFormat(comm.prop.msgs.ctBranchLevel, a, l);
	} case CType.BRANCH_STATUS: {
		string t = comm.prop.msgs.targetName(evt.targetNS.m);
		string s = comm.prop.msgs.statusName(evt.status);
		return .tryFormat(comm.prop.msgs.ctBranchStatus, t, s);
	} case CType.BRANCH_PARTY_NUMBER: {
		return .tryFormat(comm.prop.msgs.ctBranchPartyNumber, evt.partyNumber);
	} case CType.BRANCH_AREA: {
		return comm.prop.msgs.ctBranchArea;
	} case CType.BRANCH_BATTLE: {
		return comm.prop.msgs.ctBranchBattle;
	} case CType.BRANCH_IS_BATTLE: {
		return comm.prop.msgs.ctBranchIsBattle;
	} case CType.BRANCH_CAST: {
		return contentTextUseID!(CIDKind.Cast)(comm, summ, evt.casts, comm.prop.msgs.ctBranchCast, evt);
	} case CType.BRANCH_ITEM: {
		string name = contentTextUseID!(CIDKind.Item)(comm, summ, evt.item, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctBranchItem, name, comm.prop.msgs.rangeName(evt.range), evt.cardNumber);
	} case CType.BRANCH_SKILL: {
		string name = contentTextUseID!(CIDKind.Skill)(comm, summ, evt.skill, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctBranchSkill, name, comm.prop.msgs.rangeName(evt.range), evt.cardNumber);
	} case CType.BRANCH_INFO: {
		return contentTextUseID!(CIDKind.Info)(comm, summ, evt.info, comm.prop.msgs.ctBranchInfo, evt);
	} case CType.BRANCH_BEAST: {
		string name = contentTextUseID!(CIDKind.Beast)(comm, summ, evt.beast, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctBranchBeast, name, comm.prop.msgs.rangeName(evt.range), evt.cardNumber);
	} case CType.BRANCH_MONEY: {
		return .tryFormat(comm.prop.msgs.ctBranchMoney, evt.money);
	} case CType.BRANCH_COUPON: {
		string c = evt.coupon;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCoupon;
		return .tryFormat(comm.prop.msgs.ctBranchCoupon, c, comm.prop.msgs.rangeName(evt.range));
	} case CType.BRANCH_COMPLETE_STAMP: {
		string c = evt.completeStamp;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCompleteStamp;
		return .tryFormat(comm.prop.msgs.ctBranchCompleteStamp, c);
	} case CType.BRANCH_GOSSIP: {
		string c = evt.gossip;
		if (!c || !c.length) c = comm.prop.msgs.noSelectGossip;
		return .tryFormat(comm.prop.msgs.ctBranchGossip, c);
	} case CType.SET_FLAG: {
		string name = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag, "%s", evt);
		string on = comm.prop.msgs.flagOn;
		string off = comm.prop.msgs.flagOff;
		auto o = summ.flagDirRoot.findFlag(evt.flag);
		if (o) {
			on = o.on;
			off = o.off;
		}
		return .tryFormat(comm.prop.msgs.ctSetFlag, name, evt.flagValue ? on : off);
	} case CType.SET_STEP: {
		string name = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
		string value;
		auto o = summ.flagDirRoot.findStep(evt.step);
		if (o) {
			value = o.getValue(evt.stepValue);
		} else {
			value = .tryFormat(comm.prop.msgs.dlgLblStep, evt.stepValue);
		}
		return .tryFormat(comm.prop.msgs.ctSetStep, name, value);
	} case CType.SET_STEP_UP: {
		return contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, comm.prop.msgs.ctSetStepUp, evt);
	} case CType.SET_STEP_DOWN: {
		return contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, comm.prop.msgs.ctSetStepDown, evt);
	} case CType.REVERSE_FLAG: {
		return contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag, comm.prop.msgs.ctReverseFlag, evt);
	} case CType.CHECK_FLAG: {
		string name = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag, "%s", evt);
		string on = comm.prop.msgs.flagOn;
		auto o = summ.flagDirRoot.findFlag(evt.flag);
		if (o) {
			on = o.on;
		}
		return .tryFormat(comm.prop.msgs.ctCheckFlag, name, on);
	} case CType.GET_CAST: {
		return contentTextUseID!(CIDKind.Cast)(comm, summ, evt.casts, comm.prop.msgs.ctGetCast, evt);
	} case CType.GET_ITEM: {
		string name = contentTextUseID!(CIDKind.Item)(comm, summ, evt.item, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctGetItem, name, comm.prop.msgs.rangeName(evt.range), evt.cardNumber);
	} case CType.GET_SKILL: {
		string name = contentTextUseID!(CIDKind.Skill)(comm, summ, evt.skill, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctGetSkill, name, comm.prop.msgs.rangeName(evt.range), evt.cardNumber);
	} case CType.GET_INFO: {
		return contentTextUseID!(CIDKind.Info)(comm, summ, evt.info, comm.prop.msgs.ctGetInfo, evt);
	} case CType.GET_BEAST: {
		string name = contentTextUseID!(CIDKind.Beast)(comm, summ, evt.beast, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctGetBeast, name, comm.prop.msgs.rangeName(evt.range), evt.cardNumber);
	} case CType.GET_MONEY: {
		return .tryFormat(comm.prop.msgs.ctGetMoney, evt.money);
	} case CType.GET_COUPON: {
		string c = evt.coupon;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCoupon;
		return .tryFormat(comm.prop.msgs.ctGetCoupon, c, comm.prop.msgs.rangeName(evt.range));
	} case CType.GET_COMPLETE_STAMP: {
		string c = evt.completeStamp;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCompleteStamp;
		return .tryFormat(comm.prop.msgs.ctGetCompleteStamp, c);
	} case CType.GET_GOSSIP: {
		string c = evt.gossip;
		if (!c || !c.length) c = comm.prop.msgs.noSelectGossip;
		return .tryFormat(comm.prop.msgs.ctGetGossip, c);
	} case CType.LOSE_CAST: {
		return contentTextUseID!(CIDKind.Cast)(comm, summ, evt.casts, comm.prop.msgs.ctLoseCast, evt);
	} case CType.LOSE_ITEM: {
		string name = contentTextUseID!(CIDKind.Item)(comm, summ, evt.item, "%s", evt);
		string count = loseCardCount();
		return .tryFormat(comm.prop.msgs.ctLoseItem, name, comm.prop.msgs.rangeName(evt.range), count);
	} case CType.LOSE_SKILL: {
		string name = contentTextUseID!(CIDKind.Skill)(comm, summ, evt.skill, "%s", evt);
		string count = loseCardCount();
		return .tryFormat(comm.prop.msgs.ctLoseSkill, name, comm.prop.msgs.rangeName(evt.range), count);
	} case CType.LOSE_INFO: {
		return contentTextUseID!(CIDKind.Info)(comm, summ, evt.info, comm.prop.msgs.ctLoseInfo, evt);
	} case CType.LOSE_BEAST: {
		string name = contentTextUseID!(CIDKind.Beast)(comm, summ, evt.beast, "%s", evt);
		string count = loseCardCount();
		return .tryFormat(comm.prop.msgs.ctLoseBeast, name, comm.prop.msgs.rangeName(evt.range), count);
	} case CType.LOSE_MONEY: {
		return .tryFormat(comm.prop.msgs.ctLoseMoney, evt.money);
	} case CType.LOSE_COUPON: {
		string c = evt.coupon;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCoupon;
		return .tryFormat(comm.prop.msgs.ctLoseCoupon, c, comm.prop.msgs.rangeName(evt.range));
	} case CType.LOSE_COMPLETE_STAMP: {
		string c = evt.completeStamp;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCompleteStamp;
		return .tryFormat(comm.prop.msgs.ctLoseCompleteStamp, c);
	} case CType.LOSE_GOSSIP: {
		string c = evt.gossip;
		if (!c || !c.length) c = comm.prop.msgs.noSelectGossip;
		return .tryFormat(comm.prop.msgs.ctLoseGossip, c);
	} case CType.SHOW_PARTY: {
		return comm.prop.msgs.ctShowParty;
	} case CType.HIDE_PARTY: {
		return comm.prop.msgs.ctHideParty;
	} case CType.REDISPLAY: {
		if (summ && summ.legacy) {
			return comm.prop.msgs.ctRedisplayClassic;
		} else {
			string v = comm.prop.msgs.transitionName(evt.transition);
			return .tryFormat(comm.prop.msgs.ctRedisplay, v, evt.transitionSpeed);
		}
	} case CType.SUBSTITUTE_STEP: {
		auto t2 = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step2, "%s", evt);
		if (evt.step == comm.prop.sys.randomValue) {
			return .tryFormat(comm.prop.msgs.ctSubstituteStepFromRandom, t2);
		} else {
			auto t1 = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
			return .tryFormat(comm.prop.msgs.ctSubstituteStep, t1, t2);
		}
	} case CType.SUBSTITUTE_FLAG: {
		auto t2 = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag2, "%s", evt);
		if (evt.flag == comm.prop.sys.randomValue) {
			return .tryFormat(comm.prop.msgs.ctSubstituteFlagFromRandom, t2);
		} else {
			auto t1 = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag, "%s", evt);
			return .tryFormat(comm.prop.msgs.ctSubstituteFlag, t1, t2);
		}
	} case CType.BRANCH_STEP_CMP: {
		auto t1 = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
		auto t2 = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step2, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctBranchStepCmp, t1, t2);
	} case CType.BRANCH_FLAG_CMP: {
		auto t1 = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag, "%s", evt);
		auto t2 = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag2, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctBranchFlagCmp, t1, t2);
	} case CType.BRANCH_RANDOM_SELECT: {
		string r = castRangesName(comm.prop, evt.castRange);
		bool hasLevel = 0 < evt.levelMax;
		bool hasStatus = evt.status !is Status.NONE;
		if (hasLevel || hasStatus) {
			string s = comm.prop.msgs.statusName(evt.status);
			auto l1 = evt.levelMin, l2 = evt.levelMax;
			string cond;
			if (hasLevel && hasStatus) {
				cond = .tryFormat(comm.prop.msgs.randomSelectCondition3, l1, l2, s);
			} else if (hasLevel) {
				cond = .tryFormat(comm.prop.msgs.randomSelectCondition1, l1, l2);
			} else if (hasStatus) {
				cond = .tryFormat(comm.prop.msgs.randomSelectCondition2, s);
			} else assert (0);
			return .tryFormat(comm.prop.msgs.ctRandomSelect, r, cond);
		} else {
			return .tryFormat(comm.prop.msgs.ctRandomSelectN, r);
		}
	} case CType.BRANCH_KEY_CODE: {
		string range = comm.prop.msgs.rangeName(evt.keyCodeRange);
		if (evt.effectCardType is EffectCardType.ALL) {
			return .tryFormat(comm.prop.msgs.ctBranchKeyCodeAllType, evt.keyCode, range);
		} else {
			string type = comm.prop.msgs.effectCardTypeName(evt.effectCardType);
			return .tryFormat(comm.prop.msgs.ctBranchKeyCode, evt.keyCode, type, range);
		}
	} case CType.CHECK_STEP: {
		string name = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
		string value;
		auto o = summ.flagDirRoot.findStep(evt.step);
		if (o) {
			value = o.getValue(evt.stepValue);
		} else {
			value = .tryFormat(comm.prop.msgs.dlgLblStep, evt.stepValue);
		}
		string cmp = comm.prop.msgs.comparison4Name(evt.comparison4);
		return .tryFormat(comm.prop.msgs.ctCheckStep, name, value, cmp);
	} case CType.BRANCH_ROUND: {
		string cmp = comm.prop.msgs.comparison3Name(evt.comparison3);
		return .tryFormat(comm.prop.msgs.ctBranchRound, evt.round, cmp);
	}
	}
}

string castRangesName(in Props prop, in CastRange[] r) {
	string cr(CastRange r) {
		return prop.msgs.castRangeName(r);
	}
	if (3 <= r.length) {
		return .tryFormat(prop.msgs.castRange3, cr(r[0]), cr(r[1]), cr(r[2]));
	} else if (2 == r.length) {
		return .tryFormat(prop.msgs.castRange2, cr(r[0]), cr(r[1]));
	} else if (1 == r.length) {
		return .tryFormat(prop.msgs.castRange1, cr(r[0]));
	} else {
		return prop.msgs.castRange0;
	}
}

bool CBisText(Clipboard cb) {
	auto t = TextTransfer.getInstance();
	foreach (data; cb.getAvailableTypes()) {
		if (t.isSupportedType(data)) return true;
	}
	return false;
}
bool CBisFile(Clipboard cb) {
	auto t = FileTransfer.getInstance();
	foreach (data; cb.getAvailableTypes()) {
		if (t.isSupportedType(data)) return true;
	}
	return false;
}

private class DropFiles : DropTargetAdapter {
	private Text _text;
	private string delegate(string[] files) _drop;
	private void delegate(string) _dropPath;
	this (Text text, string delegate(string[] files) drop, void delegate(string) dropPath = null) {
		_text = text;
		_drop = drop;
		_dropPath = dropPath;
	}
	override void dragEnter(DropTargetEvent e){
		if (_text.getEnabled()) {
			e.detail = DND.DROP_LINK;
		}
	}
	override void dragOver(DropTargetEvent e){
		if (_text.getEnabled()) {
			e.detail = DND.DROP_LINK;
		}
	}
	override void drop(DropTargetEvent e){
		e.detail = DND.DROP_NONE;
		auto str = _drop((cast(FileNames) e.data).array);
		if (_text.getEnabled() && str.length && str != _text.getText()) {
			_text.setText(str);
			_text.selectAll();
			e.detail = DND.DROP_LINK;
			if (_dropPath) _dropPath(str);
		}
	}
}
/// cにファイルやディレクトリがドロップされるのを受け付ける。
void setupDropFile(Control c, Text text, string delegate(string[] files) drop, void delegate(string) dropPath = null) {
	auto dropt = new DropTarget(c, DND.DROP_DEFAULT | DND.DROP_LINK);
	dropt.setTransfer([FileTransfer.getInstance()]);
	if (!drop) drop = toDelegate(&dropDefault);
	dropt.addDropListener(new DropFiles(text, drop, dropPath));
}
/// filesの最初の値を返す。配列の内容が無ければ""を返す。
/// 値がファイルであれば、その上位のディレクトリを返す。
string dropDir(string[] files) {
	if (!files.length) return "";
	string file = files[0];
	if (!.exists(file)) return "";
	if (.isDir(file)) {
		return file;
	} else {
		return dirName(file);
	}
}
/// filesの最初の値を返す。配列の内容が無ければ""を返す。
string dropDefault(string[] files) {
	return files.length ? files[0] : "";
}
/// ファイルの選択を行う。
string selectFile(Text file, string[] name, string[] ext, string fileName, string title, string p) {
	auto dlg = new FileDialog(file.getShell(), SWT.PRIMARY_MODAL | SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.OPEN);
	dlg.setFilterExtensions(ext);
	dlg.setFilterNames(name);
	dlg.setText(title);
	dlg.setFilterPath(dirName(nabs(p)));
	dlg.setFileName(fileName);
	string fname = dlg.open();
	if (fname) {
		file.setText(fname);
	}
	return fname;
}
/// ディレクトリの選択を行う。
string selectDir(T)(Props prop, T dir, string title, string msg, string p, bool appPath = true) {
	auto dlg = new DirectoryDialog(dir.getShell());
	dlg.setText(title);
	dlg.setMessage(msg);
	string path = p;
	if (appPath) {
		auto d = dir.getText();
		if (!isAbsolute(d)) {
			d = std.path.buildPath(std.path.dirName(prop.parent.appPath), d);
		}
		path = d;
	}
	dlg.setFilterPath(nabs(path));
	string fname = dlg.open();
	if (fname) {
		dir.setText(fname);
	}
	return fname;
}
/// ファイルやディレクトリを開くボタンを作成する。
Button createOpenButton(Commons comm, Composite parent, string delegate() getText, bool dir) {
	auto open = new Button(parent, SWT.PUSH);
	open.setToolTipText(comm.prop.buildTool(dir ? MenuID.OpenDir : MenuID.OpenPlace));
	open.setImage(comm.prop.images.menu(MenuID.OpenDir));
	open.addSelectionListener(new OpenDir(comm, getText));
	comm.put(open, () => getText().length > 0);
	return open;
}
private class OpenDir : SelectionAdapter {
	private Commons _comm;
	private string delegate() _text;
	this (Commons comm, string delegate() text) {
		_comm = comm;
		_text = text;
	}
	override void widgetSelected(SelectionEvent e) {
		string file = _text();
		if (!isAbsolute(file)) {
			file = std.path.buildPath(_comm.prop.parent.appPath.dirName(), file);
		}
		if (!.exists(file) || !isDir(file)) {
			file = file.dirName();
		}
		if (!.exists(file)) return;
		openFolder(file);
	}
}

/// これを実装している場合はIME設定を無視するべきという
/// マーカインタフェース。
interface NoIME {
	// Nothing
}

void updateChecked(Event)(Event e) {
	if (e.detail == SWT.CHECK) {
		auto itm = cast(TableItem)e.item;
		auto tbl = itm.getParent();
		if (tbl.isSelected(tbl.indexOf(itm))) {
			foreach (itm2; itm.getParent().getSelection()) {
				itm2.setChecked(itm.getChecked());
			}
		}
	}
}
