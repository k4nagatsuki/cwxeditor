
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
import cwx.editor.gui.dwt.incsearch;

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

bool dwtImageSize(Props prop, in Skin skin, in Summary summ, string path, out uint width, out uint height) { mixin(S_TRACE);
	auto ext = .extension(path);
	if (cfnmatch(ext, ".jpy1")
			|| cfnmatch(ext, ".jptx")
			|| cfnmatch(ext, ".jpdc")) { mixin(S_TRACE);
		bool resizable;
		auto img = loadJPYImage(prop, skin, summ, path, [], width, height, resizable);
		return img !is null;
	}
	return imageSize(path, width, height);
}

ImageData loadImage(string path, bool mask = true, int maskX = 0, int maskY = 0) { mixin(S_TRACE);
	return loadImage(null, null, null, path, mask, maskX, maskY);
}
ImageData loadImage(Props prop, in Skin skin, in Summary summ, string path, bool mask = true, int maskX = 0, int maskY = 0, string[] stratum = []) { mixin(S_TRACE);
	if (!isBinImg(path) && contains(stratum, nabs(path))) { mixin(S_TRACE);
		// 無限再帰を回避
		return blankImage;
	}
	if (path !is null && path.length > 0) { mixin(S_TRACE);
		string ext = .extension(path);
		if (cfnmatch(ext, ".jpy1")
				|| cfnmatch(ext, ".jptx")
				|| cfnmatch(ext, ".jpdc")) { mixin(S_TRACE);
			bool resizable;
			auto data = loadJPYImage(prop, skin, summ, path, stratum, resizable);
			if (mask) data.transparentPixel = data.getPixel(maskX, maskY);
			return data;
		}
		try { mixin(S_TRACE);
			byte[] bytes;
			if (isBinImg(path)) { mixin(S_TRACE);
				bytes = cast(byte[])strToBImg(path);
			} else { mixin(S_TRACE);
				if (!.exists(path)) return blankImage;
				bytes = cast(byte[])readBinary(path);
			}
			scope (exit) {
				if (!isBinImg(path)) {
					bytes[] = 0;
					delete bytes;
				}
			}
			auto s = new ByteArrayInputStream(bytes);
			scope (exit) s.close();
			auto data = new ImageData(s);
			if (32 == data.depth && 'B' == bytes[0] && 'M' == bytes[1]) { mixin(S_TRACE);
				// アルファ値を正しく取れないので補完しておく
				data.alphaData = new byte[data.width * data.height];
				foreach (y; 0 .. data.height) { mixin(S_TRACE);
					foreach (x; 0 .. data.width) { mixin(S_TRACE);
						data.alphaData[y * data.width + x] = cast(ubyte) data.data[y * data.bytesPerLine + x * 4 + 3];
					}
				}
			}
			if (mask && (!data.alphaData || !data.alphaData.length)) { mixin(S_TRACE);
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
ImageData blankImage(int width = 1, int height = 1) { mixin(S_TRACE);
	auto data = new ImageData(width, height, 32, new PaletteData(0xFF000000, 0xFF0000, 0xFF00));
	data.transparentPixel = data.getPixel(0, 0);
	return data;
}

Listener listener(Widget w, int type, void delegate(Event) l) { mixin(S_TRACE);
	auto listener = .listener(l);
	w.addListener(type, listener);
	return listener;
}
Listener listener(Widget w, int type, void delegate() l) { mixin(S_TRACE);
	auto listener = .listener(l);
	w.addListener(type, listener);
	return listener;
}
Listener listener(void delegate(Event) l) { mixin(S_TRACE);
	return new class Listener {
		override void handleEvent(Event e) { mixin(S_TRACE);
			l(e);
		}
	};
}
Listener listener(void delegate() l) { mixin(S_TRACE);
	return new class Listener {
		override void handleEvent(Event e) { mixin(S_TRACE);
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
	void enter() { mixin(S_TRACE);
		if (_spn.getText().length > 0 && _oldVal != _spn.getSelection()) { mixin(S_TRACE);
			_enter(_spn.getSelection());
		} else { mixin(S_TRACE);
			_noEdit = true;
			scope (exit) _noEdit = false;
			_spn.setSelection(_cancel !is null ? _cancel(_oldVal) : _oldVal);
		}
		_oldVal = _spn.getSelection();
	}
	class KListener : KeyAdapter {
		public override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			if (e.character == SWT.CR) { mixin(S_TRACE);
				enter();
			} else if (e.character == SWT.ESC) { mixin(S_TRACE);
				_noEdit = true;
				scope (exit) _noEdit = false;
				_spn.setSelection(_cancel !is null ? _cancel(_oldVal) : _oldVal);
				_oldVal = _spn.getSelection();
			}
		}
	}
	class MSListener : FocusListener {
		void focusGained(FocusEvent e) { mixin(S_TRACE);
			_oldVal = _spn.getSelection();
		}
		void focusLost(FocusEvent e) { mixin(S_TRACE);
			enter();
		}
	}
	class MDListener : ModifyListener {
		public override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			if (_spn.isFocusControl() && _edit !is null && !_noEdit) { mixin(S_TRACE);
				_edit(_spn.getSelection());
			}
		}
	}
public:
	this(Spinner spn, void delegate(int value) enter,
			void delegate(int value) edit = null, int delegate(int oldVal) cancel = null) { mixin(S_TRACE);
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
	Control _control;
	bool _isEditorFocusOut = false;
	Item _itm = null;
	Item _oldSel = null, _oldSel2 = null;
	bool _hasFocus = false;
	bool _start = false;
	Item delegate() _selection;
	Item delegate(int x, int y) _selectionM;
	void delegate(Item itm) _startEdit;

	class StartEdit : Runnable {
		private Item _itm;
		this (Item itm) { _itm = itm; }
		override void run() { mixin(S_TRACE);
			if (_comm.prop.var.etc.editTriggerType is EditTrigger.Slow) { mixin(S_TRACE);
				if (_start && !_itm.isDisposed() && _hasFocus && _itm == _selection()) { mixin(S_TRACE);
					_startEdit(_itm);
				}
			}
			_start = false;
		}
	}
	class Starter {
		private Item _itm;
		private SysTime _time;
		this () { mixin(S_TRACE);
			_time = Clock.currTime() + dur!"msecs"(_display.getDoubleClickTime());
			_itm = _selection();
			_start = true;
		}
		void run() { mixin(S_TRACE);
			while (_start && Clock.currTime() <= _time) { mixin(S_TRACE);
				core.thread.Thread.sleep(dur!("msecs")(1));
			}
			if (_start) { mixin(S_TRACE);
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
			Item delegate() selection, Item delegate(int x, int y) selectionM) { mixin(S_TRACE);
		_comm = comm;
		_display = ctrl.getDisplay();
		_control = ctrl;
		_startEdit = startEdit;
		_selection = selection;
		_selectionM = selectionM;
		auto filter = new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				if (auto comp = cast(Composite)_control) { mixin(S_TRACE);
					if (auto ctrl = cast(Control)e.widget) { mixin(S_TRACE);
						_isEditorFocusOut = isDescendant(comp, ctrl);
					}
				}
			}
		};
		_display.addFilter(SWT.FocusOut, filter);
		.listener(ctrl, SWT.Dispose, { mixin(S_TRACE);
			_display.removeFilter(SWT.FocusOut, filter);
		});
	}
	override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
		if (_comm.prop.var.etc.editTriggerType is EditTrigger.Quick) { mixin(S_TRACE);
			_itm = _selection();
		}
		_oldSel2 = _oldSel;
		_oldSel = _selection();
		if (_oldSel != _oldSel2) { mixin(S_TRACE);
			_oldSel2 = null;
		}
	}
	override void widgetDefaultSelected(SelectionEvent e) { mixin(S_TRACE);
		// 処理無し
	}
	override void focusGained(FocusEvent e) { mixin(S_TRACE);
		_hasFocus = true;
		if (_comm.prop.var.etc.editTriggerType is EditTrigger.Quick) { mixin(S_TRACE);
			_itm = _selection();
		}
	}
	override void focusLost(FocusEvent e) { mixin(S_TRACE);
		_hasFocus = false;
		_start = false;
		_oldSel = null;
		_oldSel2 = null;
	}
	override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
		_start = false;
	}
	override void mouseUp(MouseEvent e) { mixin(S_TRACE);
		auto itm = _selectionM(e.x, e.y);
		if (!itm) return;
		if (e.button != 1) return;
		if (_comm.prop.var.etc.editTriggerType is EditTrigger.Quick) { mixin(S_TRACE);
			if (itm == _itm) { mixin(S_TRACE);
				_startEdit(itm);
			}
		} else { mixin(S_TRACE);
			if (2 <= e.count) { mixin(S_TRACE);
				return;
			}
			if (_oldSel2 == itm) { mixin(S_TRACE);
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
	this (void delegate(Item itm) startEdit, Item delegate() selection) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			_startEdit = startEdit;
			_selection = selection;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	override void keyPressed(KeyEvent e) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (e.keyCode == SWT.F2) { mixin(S_TRACE);
				auto itm = _selection();
				if (itm !is null) { mixin(S_TRACE);
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
	this(Commons comm, Composite parent, Control ctrl, void delegate(Control) end) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			_comm = comm;
			this.end = end;
			this.ctrl = ctrl;
			ctrl.addFocusListener(this);
			ctrl.addKeyListener(this);

			auto focusIn = new class Listener {
				override void handleEvent(Event e) {
					focusOut();
				}
			};
			ctrl.getDisplay().addFilter(SWT.FocusIn, focusIn);
			.listener(ctrl, SWT.Dispose, {
				ctrl.getDisplay().removeFilter(SWT.FocusIn, focusIn);
			});
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void setFocus() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			ctrl.setFocus();
			if (_comm.prop.var.etc.comboListVisible) { mixin(S_TRACE);
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
	Control editor() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			return ctrl;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	override void focusGained(FocusEvent e) {}
	override void focusLost(FocusEvent e) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			focusOut();
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	private void focusOut() {
		auto fc = ctrl.getDisplay().getFocusControl();
		if (fc is ctrl) return;
		if (fc && cast(IncSearch)fc.getShell().getData()) return;
		enter();
	}
	override void keyPressed(KeyEvent e) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (e.character == SWT.CR) { mixin(S_TRACE);
				enter();
			} else if (e.keyCode == SWT.ESC) { mixin(S_TRACE);
				ctrl.dispose();
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	@property
	bool isExit() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			return ctrl.isDisposed();
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void enter() { mixin(S_TRACE);
		if (!ctrl || ctrl.isDisposed()) return;
		try { mixin(S_TRACE);
			try { mixin(S_TRACE);
				end(ctrl);
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
			ctrl.dispose();
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void cancel() { mixin(S_TRACE);
		if (ctrl && !ctrl.isDisposed()) { mixin(S_TRACE);
			ctrl.dispose();
		}
	}
}

Text createTextEditor(Commons comm, Props prop, Composite parent, string str) { mixin(S_TRACE);
	try { mixin(S_TRACE);
		auto text = new Text(parent, SWT.BORDER);
		text.setText(str ? str : "");
		text.selectAll();
		createTextMenu!Text(comm, prop, text, null);
		return text;
	} catch (Exception e) {
		throw new Exception(e.msg, __FILE__, __LINE__);
	}
}

C createComboEditor(C = Combo)(Commons comm, Props prop, Composite parent, string[] strs, string str, bool readOnly = true, string[] delegate(IncSearch) filter = null) { mixin(S_TRACE);
	try { mixin(S_TRACE);
		int style = SWT.BORDER;
		if (readOnly) style |= SWT.READ_ONLY;
		auto combo = new C(parent, style);
		combo.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
		if (filter) {
			auto menu = new Menu(combo.getShell(), SWT.POP_UP);
			auto incSearch = new IncSearch(comm, combo);
			incSearch.modEvent ~= { mixin(S_TRACE);
				auto t = combo.getText();
				combo.removeAll();
				bool hasStr = false;
				foreach (s; filter(incSearch)) { mixin(S_TRACE);
					if (s == str) hasStr = true;
					combo.add(s);
					if (s == t) { mixin(S_TRACE);
						combo.setText(t);
					}
				}
				if (hasStr && combo.getText() == "") combo.setText(str);
			};
			createMenuItem(comm, menu, MenuID.IncSearch, {
				incSearch.startIncSearch();
			}, () => 0 < strs.length);
			combo.setMenu(menu);
			static if (is(C : CCombo)) {
				new MenuItem(menu, SWT.SEPARATOR);
			}
		}
		static if (is(C : CCombo)) {
			createTextMenu!C(comm, prop, combo, null);
		}
		foreach (s; strs) { mixin(S_TRACE);
			if (s) { mixin(S_TRACE);
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

	Item selectionM(int x, int y) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (table.getSelectionCount()) { mixin(S_TRACE);
				auto itm = table.getItem(table.getSelectionIndex());
				if (itm.getBounds(editC).contains(x, y)) { mixin(S_TRACE);
					if (!itm.getImage() || !itm.getImageBounds(editC).contains(x, y)) { mixin(S_TRACE);
						return itm;
					}
				}
			}
			return null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	Item selectionK() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (table.getSelectionCount()) { mixin(S_TRACE);
				return table.getItem(table.getSelectionIndex());
			}
			return null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	void startEdit(Item itm) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			startEdit(cast(TableItem) itm);
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void endImpl(Control c) { mixin(S_TRACE);
		try { mixin(S_TRACE);
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
			bool delegate(TableItem itm, int column) canEdit = null) { mixin(S_TRACE);
		try { mixin(S_TRACE);
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
	void startEdit() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			auto sels = table.getSelection();
			if (sels.length == 1) { mixin(S_TRACE);
				startEdit(sels[0]);
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void startEdit(TableItem itm) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (!itm.getParent().isFocusControl()) return;
			if (_tee !is null && !_tee.isExit) _tee.enter();
			auto sel = itm;
			if (canEdit is null || canEdit(sel, editC)) { mixin(S_TRACE);
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
	bool isEditing() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			return _tee !is null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void cancel() { mixin(S_TRACE);
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
			Control delegate(TableItem itm, int editC) createEditor = null) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			super (comm, table, editC, canEdit);
			_comm = comm;
			_prop = prop;
			this.editEnd = editEnd;
			_createEditor = createEditor;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	protected override Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
		if (_createEditor) { mixin(S_TRACE);
			return _createEditor(itm, editC);
		} else { mixin(S_TRACE);
			return createTextEditor(_comm, _prop, itm.getParent(), itm.getText(editC));
		}
	}
	protected override void end(Control c) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			string newText = null;
			if (auto t = cast(Text) c) { mixin(S_TRACE);
				newText = t.getText();
			} else if (auto t = cast(Combo) c) { mixin(S_TRACE);
				newText = t.getText();
			} else if (auto t = cast(CCombo) c) { mixin(S_TRACE);
				newText = t.getText();
			}
			if (!newText) newText = "";
			if (editEnd is null) { mixin(S_TRACE);
				if (newText.length > 0) { mixin(S_TRACE);
					editor.getItem().setText(editC, newText);
				}
			} else { mixin(S_TRACE);
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
	void delegate(TableItem itm, int column, out string[] strs, out string str, out bool canIncSearch) createCombo;
	void delegate(TableItem itm, int column, C combo) editEnd = null;
	string[] delegate(IncSearch) _filter = null;

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
			void delegate(TableItem itm, int column, out string[] strs, out string str, out bool canIncSearch) createCombo,
			void delegate(TableItem itm, int column, C combo) editEnd = null,
			bool delegate(TableItem itm, int column) canEdit = null,
			string[] delegate(IncSearch) filter = null) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			super (comm, table, editC, canEdit);
			_comm = comm;
			_prop = prop;
			this.createCombo = createCombo;
			this.editEnd = editEnd;
			_filter = filter;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	/// ditto
	this(Commons comm, Props prop, Table table, int editC,
			void delegate(TableItem itm, int column, out string[] strs, out string str) createCombo,
			void delegate(TableItem itm, int column, C combo) editEnd = null,
			bool delegate(TableItem itm, int column) canEdit = null,
			string[] delegate(IncSearch) filter = null) { mixin(S_TRACE);
		this (comm, prop, table, editC, (itm, column, out strs, out str, out canIncSearch) => createCombo(itm, column, strs, str), editEnd, canEdit, filter);
	}

	protected override Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
		string[] strs;
		string str;
		bool canIncSearch;
		createCombo(itm, editC, strs, str, canIncSearch);
		return createComboEditor!C(_comm, _prop, itm.getParent(), strs, str, true, canIncSearch ? _filter : null);
	}
	protected override void end(Control c) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			auto combo = cast(C) c;
			if (editEnd is null) { mixin(S_TRACE);
				editor.getItem().setText(editC, combo.getText());
			} else { mixin(S_TRACE);
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
			bool delegate(TableItem itm, int column) canEdit = null) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			super (comm, table, editC, canEdit);
			_createEditor = createEditor;
			this.editEnd = editEnd;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	protected override Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
		return _createEditor(itm, editC);
	}
	protected override void end(Control c) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			void set(string text) { mixin(S_TRACE);
				if (editEnd is null) { mixin(S_TRACE);
					editor.getItem().setText(editC, text);
				} else { mixin(S_TRACE);
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

	Item selectionM(int x, int y) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (tree.getSelectionCount() == 1) { mixin(S_TRACE);
				auto itm = tree.getSelection()[0];
				if (itm.getBounds().contains(x, y)) { mixin(S_TRACE);
					return itm;
				}
			}
			return null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	Item selectionK() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (tree.getSelectionCount() == 1) { mixin(S_TRACE);
				return tree.getSelection()[0];
			}
			return null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	void end(Control ctrl) { mixin(S_TRACE);
		if (!ctrl || ctrl.isDisposed()) return;
		try { mixin(S_TRACE);
			editEnd(editor.getItem(), ctrl);
			_tee = null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	void startEdit(Item itm) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (_tee !is null && !_tee.isExit) _tee.enter();
			auto sel = cast(TreeItem) itm;
			auto c = createEditor(sel);
			if (c) { mixin(S_TRACE);
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
			Control delegate(TreeItem itm) createEditor = null) { mixin(S_TRACE);
		try { mixin(S_TRACE);
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
	void startEdit() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			auto sels = tree.getSelection();
			if (sels.length == 1) { mixin(S_TRACE);
				startEdit(sels[0]);
			}
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	@property
	bool isEditing() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			return _tee !is null;
		} catch (Exception e) {
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void cancel() { mixin(S_TRACE);
		if (!isEditing) return;
		_tee.cancel();
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

	Item selectionM(int x, int y) { mixin(S_TRACE);
		auto sels = _list.selectionIndices();
		if (1 == sels.length && _list.getTitleBounds(sels[0]).contains(x, y)) { mixin(S_TRACE);
			return _list.getItem(sels[0]);
		}
		return null;
	}
	Item selectionK() { mixin(S_TRACE);
		auto sels = _list.selectionIndices();
		if (1 == sels.length) { mixin(S_TRACE);
			return _list.getItem(sels[0]);
		}
		return null;
	}

	void end(Control ctrl) { mixin(S_TRACE);
		assert (_edit !is null);
		_editEnd(cast(C)_edit.getData(), ctrl);
		_tee = null;
		_edit = null;
		_editor = null;
	}

	void startEdit(Item itm) { mixin(S_TRACE);
		if (_tee !is null && !_tee.isExit) _tee.enter();
		auto sel = cast(C)itm.getData();
		_editor = _createEditor(sel);
		if (_editor) { mixin(S_TRACE);
			_edit = itm;
			_list.scroll(_list.indexOf(sel));
			_tee = new EditEnd(_comm, _list, _editor, &end);
			layout();
			_tee.setFocus();
		}
	}
	void layout() { mixin(S_TRACE);
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
			Control delegate(in C card) createEditor = null) { mixin(S_TRACE);
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
	void startEdit() { mixin(S_TRACE);
		auto sels = _list.selectionIndices();
		if (sels.length == 1) { mixin(S_TRACE);
			startEdit(_list.getItem(sels[0]));
		}
	}
	bool isEditing() { mixin(S_TRACE);
		return _tee !is null;
	}
}

bool hasFocus(Control c) { mixin(S_TRACE);
	auto ctrl = Display.getCurrent().getFocusControl();
	if (c is ctrl) return true;
	auto parent = ctrl.getParent();
	while (parent) { mixin(S_TRACE);
		if (c is parent) return true;
		parent = parent.getParent();
	}
	return false;
}
Shell topShell(Shell shell) { mixin(S_TRACE);
	auto parent = cast(Shell) shell.getParent();
	if (!parent) return shell;
	while (parent.getParent()) { mixin(S_TRACE);
		parent = cast(Shell) parent.getParent();
	}
	return parent;
}
bool isDescendant(Shell shell1, Shell shell2) { mixin(S_TRACE);
	while (shell1 !is shell2) { mixin(S_TRACE);
		if (!shell2) return false;
		shell2 = cast(Shell) shell2.getParent();
	}
	return true;
}
bool isDescendant(Composite comp, Control ctrl) { mixin(S_TRACE);
	while (comp !is ctrl) { mixin(S_TRACE);
		if (!ctrl) return false;
		ctrl = ctrl.getParent();
	}
	return true;
}

class RadioGroup(B : Widget) {
public:
	this () { mixin(S_TRACE);
		_set = new HashSet!(B);
		_l = new L;
	}
	void select(B b) { mixin(S_TRACE);
		if (_sel !is b) { mixin(S_TRACE);
			if (_sel) _sel.setSelection(false);
			if (b) b.setSelection(true);
			_sel = b;
		}
	}
	bool contains(B b) { mixin(S_TRACE);
		return _set.contains(b);
	}
	@property
	HashSet!(B) set() {return _set;}
	void append(B b) { mixin(S_TRACE);
		_set.add(b);
		assert ((b.getStyle() & SWT.RADIO) != 0);
		if (_sel is null) { mixin(S_TRACE);
			if (b.getSelection()) { mixin(S_TRACE);
				_sel = b;
			}
		} else { mixin(S_TRACE);
			b.setSelection(false);
		}
		b.addListener(SWT.Selection, _l);
	}
private:
	HashSet!(B) _set;
	B _sel = null;
	Listener _l;
	class L : Listener {
		public override void handleEvent(Event e) { mixin(S_TRACE);
			auto b = cast(B) e.widget;
			if (_sel is null) { mixin(S_TRACE);
				_sel = b;
			} else if (b !is _sel) { mixin(S_TRACE);
				_sel.setSelection(false);
				_sel = b;
			}
		}
	}
}

alias RadioGroup!ToolItem ToolItemGroup;

TreeItem createTreeItem(T)(T parent, Object data, string text, Image img, int index = -1) { mixin(S_TRACE);
	TreeItem r;
	if (index >= 0) { mixin(S_TRACE);
		r = new TreeItem(parent, SWT.NONE, index);
	} else { mixin(S_TRACE);
		r = new TreeItem(parent, SWT.NONE);
	}
	r.setData(data);
	r.setText(text);
	r.setImage(img);
	return r;
}

TreeItem topItem(TreeItem itm) { mixin(S_TRACE);
	if (!itm) return null;
	if (itm.getParentItem()) { mixin(S_TRACE);
		return topItem(itm.getParentItem());
	}
	return itm;
}
int treeItemUp(TreeItem itm) { mixin(S_TRACE);
	return __treeItemUD!("i > 0", "i - 1")(itm);
}
int treeItemDown(TreeItem itm) { mixin(S_TRACE);
	return __treeItemUD!("i + 1 < parent.getItemCount()", "i + 2")(itm);
}
private int __treeItemUD(string SwapOK, string ToIndex)(TreeItem itm) { mixin(S_TRACE);
	auto tree = itm.getParent();
	auto p = itm.getParentItem();
	if (p is null) { mixin(S_TRACE);
		return __treeItemUD2!(Tree, SwapOK, ToIndex)(tree, itm);
	} else { mixin(S_TRACE);
		return __treeItemUD2!(TreeItem, SwapOK, ToIndex)(p, itm);
	}
}
private int __treeItemUD2(T, string SwapOK, string ToIndex)(T parent, TreeItem itm) { mixin(S_TRACE);
	int i = parent.indexOf(itm);
	auto tree = itm.getParent();
	if (mixin (SwapOK)) { mixin(S_TRACE);
		auto ti = cloneItem!(T)(parent, itm, mixin (ToIndex));
		foreach (sel; tree.getSelection()) { mixin(S_TRACE);
			if (sel is itm) { mixin(S_TRACE);
				tree.setSelection(ti);
				break;
			}
		}
		itm.dispose();
		return i;
	}
	return -1;
}
private TreeItem cloneItem(T)(T parent, TreeItem old, int index) { mixin(S_TRACE);
	auto ti = new TreeItem(parent, old.getStyle(), index);
	ti.setData(old.getData());
	ti.setChecked(old.getChecked());
	ti.setForeground(old.getForeground());
	ti.setBackground(old.getBackground());
	ti.setGrayed(old.getGrayed());
	ti.setFont(old.getFont());
	int imgCount = old.getParent().getColumnCount() + 1;
	for (int i = 0; i < imgCount; i++) { mixin(S_TRACE);
		ti.setText(i, old.getText(i));
		ti.setImage(i, old.getImage(i));
	}
	foreach (i, itm; old.getItems()) { mixin(S_TRACE);
		cloneItem(ti, itm, i);
	}
	ti.setExpanded(old.getExpanded());
	return ti;
}

void treeExpandedAll(TreeItem tree) { mixin(S_TRACE);
	foreach (itm; tree.getItems()) { mixin(S_TRACE);
		treeExpandedAll(itm);
	}
	tree.setExpanded(true);
}
void treeExpandedAll(Tree tree) { mixin(S_TRACE);
	tree.setRedraw(false);
	foreach (itm; tree.getItems()) { mixin(S_TRACE);
		treeExpandedAll(itm);
	}
	tree.setRedraw(true);
}
void treeUnexpandedAll(TreeItem tree) { mixin(S_TRACE);
	foreach (itm; tree.getItems()) { mixin(S_TRACE);
		treeUnexpandedAll(itm);
	}
	tree.setExpanded(false);
}
void treeUnexpandedAll(Tree tree) { mixin(S_TRACE);
	tree.setRedraw(false);
	foreach (itm; tree.getItems()) { mixin(S_TRACE);
		treeUnexpandedAll(itm);
	}
	tree.setRedraw(true);
}

version (Windows) {} else {
	import org.eclipse.swt.program.Program;
}
bool openFolder(string path) { mixin(S_TRACE);
	path = nabs(path);
	version (Windows) {
		return exec("explorer " ~ path, path);
	} else { mixin(S_TRACE);
		return Program.launch(path);
	}
}

void drawCenterText(FontData fontData, GC gc, Rectangle ca, string str) { mixin(S_TRACE);
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

void hemming(GC gc, string s, int tx, int ty, Color color) { mixin(S_TRACE);
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
ImageData castCardImage(Props prop, Skin skin, in CastCard c, string sPath, bool dbgMode) { mixin(S_TRACE);
	auto cardSize = prop.looks.cardSize;
	auto matPad = prop.looks.castCardInsets;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	ImageData id;
	if (c.life == 0) { mixin(S_TRACE);
		id = castCardFaint(skin);
	} else if (c.paralyze > prop.looks.stoneBorder) { mixin(S_TRACE);
		id = castCardPetrif(skin);
	} else if (c.paralyze > 0) { mixin(S_TRACE);
		id = castCardParaly(skin);
	} else if (c.bindRound > 0) { mixin(S_TRACE);
		id = castCardBind(skin);
	} else if (c.mentality == Mentality.SLEEP && c.mentalityRound > 0) { mixin(S_TRACE);
		id = castCardSleep(skin);
	} else if (c.life <= c.lifeMax / 5) { mixin(S_TRACE);
		id = castCardDanger(skin);
	} else if (c.life < c.lifeMax) { mixin(S_TRACE);
		id = castCardInjury(skin);
	} else { mixin(S_TRACE);
		id = castCard(skin);
	}
	auto r = new PileImage(id, w, h);
	auto stp = prop.looks.castLifeBarPoint;
	if (dbgMode || c.faceUpRound > 0) { mixin(S_TRACE);
		r.append(to!(string)(c.level),
			prop.looks.castCardLevelInsets,
			prop.looks.castCardLevelFont(skin.legacy),
			prop.looks.castCardLevelColor,
			PileImage.TPos.RIGHT);
	}
	r.append(skin.findImagePath(c.path, sPath), matPad, ScaleType.Center, true);
	int stMax = prop.looks.statusVerMax;
	if (dbgMode || c.faceUpRound > 0) { mixin(S_TRACE);
		auto d = Display.getCurrent();
		auto lgid = lifeGuage(skin);
		int lgw = lgid.width;
		int lgh = lgid.height;
		if (lgw > 1 && lgh > 1) { mixin(S_TRACE);
			try { mixin(S_TRACE);
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
	void status(ImageData id) { mixin(S_TRACE);
		r.append(id, stp, ScaleType.Cut);
		stc++;
		if (stc >= stMax) { mixin(S_TRACE);
			stp.x += id.width + 1;
			stp.y = styf;
			stc = 0;
		} else { mixin(S_TRACE);
			stp.y -= id.height + 1;
		}
	}
	if (c.mentalityRound > 0) { mixin(S_TRACE);
		switch (c.mentality) {
		case Mentality.NORMAL: break;
		case Mentality.SLEEP: break;
		case Mentality.CONFUSE, Mentality.OVERHEAT, Mentality.BRAVE, Mentality.PANIC: { mixin(S_TRACE);
			status(mentality(skin, c.mentality));
		} break;
		default: assert (0);
		}
	}
	if (c.poison > 0) status(poison(skin));
	if (c.silenceRound > 0) status(silence(skin));
	if (c.faceUpRound > 0) status(faceUp(skin));
	if (c.antiMagicRound > 0) status(antiMagic(skin));
	void enh(Enhance enh) { mixin(S_TRACE);
		void colorBlock(ImageData iData, CRGB rgb) { mixin(S_TRACE);
			auto id = new ImageData(iData.width, iData.height, 1, new PaletteData([new RGB(rgb.r, rgb.g, rgb.b), new RGB(0, 0, 0)]));
			r.append(id, stp, ScaleType.Cut);
		}
		auto value = c.enhance(enh);
		auto round = c.enhanceRound(enh);
		if (value > 0 && round > 0) { mixin(S_TRACE);
			CRGB back;
			if (prop.var.etc.enhanceMaxVal <= value) { mixin(S_TRACE);
				back = prop.var.etc.enhanceColorMax;
			} else if (prop.var.etc.enhanceHighVal <= value) { mixin(S_TRACE);
				back = prop.var.etc.enhanceColorHigh;
			} else if (prop.var.etc.enhanceMiddleVal <= value) { mixin(S_TRACE);
				back = prop.var.etc.enhanceColorMiddle;
			} else if (1 <= value) { mixin(S_TRACE);
				back = prop.var.etc.enhanceColorLow;
			}
			auto iData = enhanceUp(skin, enh);
			colorBlock(iData, back);
			status(iData);
		} else if (value < 0 && round > 0) { mixin(S_TRACE);
			CRGB back;
			if (-(cast(int) prop.var.etc.enhanceMaxVal) >= value) { mixin(S_TRACE);
				back = prop.var.etc.penaltyColorMax;
			} else if (-(cast(int) prop.var.etc.enhanceHighVal) >= value) { mixin(S_TRACE);
				back = prop.var.etc.penaltyColorHigh;
			} else if (-(cast(int) prop.var.etc.enhanceMiddleVal) >= value) { mixin(S_TRACE);
				back = prop.var.etc.penaltyColorMiddle;
			} else if (-1 >= value) { mixin(S_TRACE);
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
	foreach (b; c.beasts) { mixin(S_TRACE);
		if (b.useLimit > 0) { mixin(S_TRACE);
			beastCount++;
			if (beastCount >= beastCountMax) break;
		}
	}
	if (beastCount > 0) { mixin(S_TRACE);
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
ImageData cardImage(C)(Props prop, Skin skin, in C base, string sPath, CastCard owner, C delegate(ulong) get, bool detail, bool preview) { mixin(S_TRACE);
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
	} else { mixin(S_TRACE);
		static assert (0);
	}
	bool link = false;
	Rebindable!(const(C)) c = base;
	static if (is(typeof(base.linkId))) {
		if (get && 0 != base.linkId) { mixin(S_TRACE);
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
		if (prop.var.etc.showSkillCardLevel) { mixin(S_TRACE);
			r.append(to!(string)(c.level),
				prop.looks.skillCardLevelInsets,
				prop.looks.skillCardLevelFont(skin.legacy),
				prop.looks.skillCardLevelColor,
				PileImage.TPos.RIGHT);
		}
	}
	r.append(skin.findImagePath(c.path, sPath), matPad, ScaleType.Cut, true);
	static if (is(typeof(c.linkId))) {
		if (link) { mixin(S_TRACE);
			auto mc = prop.var.etc.linkCardMaskColor;
			r.colorMask(mc.r, mc.g, mc.b, mc.a);
		}
	}
	static if (!is(C == InfoCard)) {
		if (prop.sys.isPenalty(c.keyCodes)) { mixin(S_TRACE);
			auto pid = cardPenalty(skin);
			pid.transparentPixel = pid.getPixel(pid.width / 2, pid.height / 2);
			r.append(pid, CPoint(0, 0), ScaleType.Cut);
		}
		static if (is(typeof(c.hold))) {
			if (hold) { mixin(S_TRACE);
				auto hid = cardHold(skin);
				hid.transparentPixel = hid.getPixel(hid.width / 2, hid.height / 2);
				r.append(hid, CPoint(0, 0), ScaleType.Cut);
			}
		}
		if (detail && owner) { mixin(S_TRACE);
			int apt = owner.aptitude(c.physical, c.mental);
			ImageData aimg;
			if (prop.looks.aptVeryHigh <= apt) { mixin(S_TRACE);
				aimg = aptVeryHigh(skin);
			} else if (prop.looks.aptHigh <= apt) { mixin(S_TRACE);
				aimg = aptHigh(skin);
			} else if (prop.looks.aptNormal <= apt) { mixin(S_TRACE);
				aimg = aptNormal(skin);
			} else { mixin(S_TRACE);
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
	void putEventTree(bool useCount) { mixin(S_TRACE);
		static if (is(C:EventTreeOwner)) {
			if (preview || !prop.var.etc.showEventTreeMark) return;
			auto et = useCount ? prop.looks.eventTreeXYWithCount : prop.looks.eventTreeXY;
			if (detail && (prop.var.etc.ignoreEmptyStart ? !c.isEmpty : 0 < c.trees.length)) { mixin(S_TRACE);
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
		if (ul > 0) { mixin(S_TRACE);
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

Rectangle eventTreeMarkRect(C:EventTreeOwner)(Props prop, int left, int top, in C c) { mixin(S_TRACE);
	if (!prop.var.etc.showEventTreeMark) return null;

	static if (is(C:ItemCard)) {
		bool useCount = 0 < c.useLimitMax;
	} else static if (is(C:BeastCard)) {
		bool useCount = 0 < c.useLimit;
	} else { mixin(S_TRACE);
		bool useCount = false;
	}

	auto et = useCount ? prop.looks.eventTreeXYWithCount : prop.looks.eventTreeXY;
	if (prop.var.etc.ignoreEmptyStart ? !c.isEmpty : 0 < c.trees.length) { mixin(S_TRACE);
		auto bounds = prop.images.eventTree.getBounds();
		bounds.x = left + et.x;
		bounds.y = top + et.y;
		return bounds;
	}
	return null;
}

string[] castCoupons(Commons comm, bool talker, string legacyName) { mixin(S_TRACE);
	string[] r;
	if (!talker) { mixin(S_TRACE);
		foreach (c; comm.prop.var.etc.standardCoupons) { mixin(S_TRACE);
			r ~= c;
		}
	}
	foreach (e; SEX_ALL) { mixin(S_TRACE);
		r ~= comm.skin.sexCoupon(e);
	}
	foreach (e; PERIOD_ALL) { mixin(S_TRACE);
		r ~= comm.skin.periodCoupon(e);
	}
	foreach (e; comm.prop.var.etc.showSpNature ? (NATURE_DEF ~ NATURE_EXT) : NATURE_DEF) { mixin(S_TRACE);
		r ~= comm.skin.natureCoupon(e);
	}
	foreach (e; MAKINGS_LEFT) { mixin(S_TRACE);
		r ~= comm.skin.makingsCoupon(e);
		r ~= comm.skin.makingsCoupon(reverseMakings(e));
	}
	return r;
}

bool qMaterialCopy(Commons comm, Shell shell,
		UseCounter uc, string toSPath, string fromSPath, out bool copy, bool toIsLegacy) { mixin(S_TRACE);
	auto prop = comm.prop;
	auto skin = comm.skin;
	copy = false;
	string[] paths;
	foreach (key; uc.path.keys) { mixin(S_TRACE);
		string path = cast(string) key;
		if (key.isBinImg) { mixin(S_TRACE);
			paths ~= path;
		} else if (exists(std.path.buildPath(fromSPath, path))) { mixin(S_TRACE);
			paths ~= path;
		}
	}
	if (paths.length == 0) return true;
	uint bin = 0u;
	string[] msgPaths;
	foreach (p; paths) { mixin(S_TRACE);
		if (isBinImg(p)) { mixin(S_TRACE);
			bin++;
		} else { mixin(S_TRACE);
			msgPaths ~= std.path.buildPath(fromSPath, p);
		}
	}
	bool cancel = false;
	bool question(string msg) { mixin(S_TRACE);
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
	if (!msgPaths.length && bin) { mixin(S_TRACE);
		copyMates = true;
		if (!toIsLegacy || prop.var.etc.saveInnerImagePath) { mixin(S_TRACE);
			binImgToRef = question(prop.msgs.dlgMsgCopyMaterial1);
		} else { mixin(S_TRACE);
			binImgToRef = false;
		}
	} else if (msgPaths.length && !bin) { mixin(S_TRACE);
		binImgToRef = false; // 格納イメージは存在しない
		if (1 == msgPaths.length) { mixin(S_TRACE);
			copyMates = question(.tryFormat(prop.msgs.dlgMsgCopyMaterial2, msgPaths[0]));
		} else { mixin(S_TRACE);
			copyMates = question(.tryFormat(prop.msgs.dlgMsgCopyMaterial3, msgPaths.length));
		}
	} else { mixin(S_TRACE);
		binImgToRef = !toIsLegacy || prop.var.etc.saveInnerImagePath;
		copyMates = question(.tryFormat(prop.msgs.dlgMsgCopyMaterial4, msgPaths.length, bin));
	}
	if (copyMates && !cancel) { mixin(S_TRACE);
		bool err = false;
		foreach (i, key; paths) { mixin(S_TRACE);
			// ファイルのコピーと参照の更新
			string path = isBinImg(key) ? key : std.path.buildPath(fromSPath, key);
			try { mixin(S_TRACE);
				auto newp = copyTo(toSPath, path, skin.materialPath, binImgToRef);
				if (!isBinImg(newp) && key != newp) { mixin(S_TRACE);
					uc.change(toPathId(key), toPathId(newp));
				}
				copy = true;
			} catch (Exception e) {
				debugln("copy error: " ~ e.msg);
				err = true;
			}
		}
		if (!toIsLegacy) { mixin(S_TRACE);
			// 転送先は格納イメージ無効
			foreach (key; uc.path.keys) { mixin(S_TRACE);
				if (key.isBinImg) { mixin(S_TRACE);
					uc.change(key, toPathId(""), true);
				}
			}
		}
		if (err) { mixin(S_TRACE);
			MessageBox.showWarning(prop.msgs.dlgMsgCopyError, prop.msgs.dlgTitWarning, shell);
		}
		return true;
	} else { mixin(S_TRACE);
		return !cancel;
	}
}

void saveColumnWidth(string Value)(Props prop, TableColumn col) { mixin(S_TRACE);
	col.setWidth(mixin (Value));
	static if (is (typeof(mixin(Value ~ " = 0")) == void)) {
		static class SaveColumnWidth : DisposeListener {
			Props prop;
			this(Props prop) { mixin(S_TRACE);
				this.prop = prop;
			}
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				int width = (cast(TableColumn) e.widget).getWidth();
				mixin (Value ~ " = width;");
			}
		}
		col.addDisposeListener(new SaveColumnWidth(prop));
	}
}

void intoDisplay(ref int x, ref int y, int w, int h) { mixin(S_TRACE);
	auto pb = Display.getCurrent().getClientArea();
	if (pb.x + pb.width < x + w) x = pb.x + pb.width - w;
	if (pb.y + pb.height < y + h) y = pb.y + pb.height - h;
	if (x < pb.x) x = pb.x;
	if (y < pb.y) y = pb.y;
}

Image skeletonImage(Image src, bool mask = true) { mixin(S_TRACE);
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

Composite createSuccessRateScale(Props prop, Composite parent, out Scale sucRate) { mixin(S_TRACE);
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

void putRadioValue(E)(Button[E] radios, void delegate(E) set) { mixin(S_TRACE);
	set(getRadioValue!(E)(radios));
}

E getRadioValue(E)(Button[E] radios) { mixin(S_TRACE);
	foreach (e, radio; radios) { mixin(S_TRACE);
		if (radio.getSelection()) { mixin(S_TRACE);
			return e;
		}
	}
	assert (0);
}

void forceFocus(Widget widget, bool shellActivate) { mixin(S_TRACE);
	auto d = Display.getCurrent();
	if (widget is d.getFocusControl()) return;
	forceFocusImpl(widget, null, shellActivate);
}

private void forceFocusImpl(Widget widget, Widget child, bool shellActivate) { mixin(S_TRACE);
	if (!widget || widget.isDisposed()) return;
	auto d = Display.getCurrent();
	auto ti = cast(TableItem) widget;
	if (ti) { mixin(S_TRACE);
		auto tbl = ti.getParent();
		forceFocusImpl(tbl, null, shellActivate);
		tbl.setSelection(ti);
		tbl.showSelection();
		return;
	}
	auto tri = cast(TreeItem) widget;
	if (tri) { mixin(S_TRACE);
		auto tree = tri.getParent();
		forceFocusImpl(tree, null, shellActivate);
		tree.select(tri);
		tree.showSelection();
		return;
	}
	auto sh = cast(Shell) widget;
	if (sh) { mixin(S_TRACE);
		if (shellActivate) { mixin(S_TRACE);
			sh.setActive();
		}
		return;
	}
	auto tf = cast(TabFolder) widget;
	if (tf) { mixin(S_TRACE);
		foreach (i; tf.getItems()) { mixin(S_TRACE);
			if (i.getControl() is child) { mixin(S_TRACE);
				forceFocusImpl(tf.getParent(), tf, shellActivate);
				tf.setSelection(i);
				return;
			}
		}
		assert (0);
	}
	auto ctf = cast(CTabFolder) widget;
	if (ctf) { mixin(S_TRACE);
		foreach (i; ctf.getItems()) { mixin(S_TRACE);
			if (i.getControl() is child) { mixin(S_TRACE);
				forceFocusImpl(ctf.getParent(), ctf, shellActivate);
				ctf.setSelection(i);
				return;
			}
		}
		assert (0);
	}
	auto ctl = cast(Control) widget;
	if (ctl) { mixin(S_TRACE);
		forceFocusImpl(ctl.getParent(), ctl, shellActivate);
		if (ctl.isDisposed()) return;
		if (!shellActivate) { mixin(S_TRACE);
			if (ctl.getShell() is d.getActiveShell()) { mixin(S_TRACE);
				ctl.setFocus();
			}
		} else { mixin(S_TRACE);
			ctl.setFocus();
		}
		return;
	}
	assert (0);
}

/// Controlの階層構造を表示する。
void writeRec(Control c, string tab = "") { mixin(S_TRACE);
	std.stdio.writef(tab ~ c.toString());
	std.stdio.writefln(c.isDisposed() ? " disposed" : "");
	if (cast(Composite) c) { mixin(S_TRACE);
		foreach (cc; (cast(Composite) c).getChildren()) { mixin(S_TRACE);
			writeRec(cc, tab ~ "  ");
		}
	}
}

SplitPane changeVHSide(SplitPane sash) { mixin(S_TRACE);
	auto style = sash.getStyle() & !SWT.HORIZONTAL & !SWT.VERTICAL;
	assert (!(style & SWT.HORIZONTAL));
	assert (!(style & SWT.VERTICAL));
	auto vh = (sash.getStyle() & SWT.VERTICAL) ? SWT.HORIZONTAL : SWT.VERTICAL;
	auto sp = new SplitPane(sash.getParent(), style | vh);
	assert ((sash.getStyle() & SWT.VERTICAL)
		? ((sp.getStyle() & SWT.HORIZONTAL) && !(sp.getStyle() & SWT.VERTICAL))
		: ((sp.getStyle() & SWT.VERTICAL) && !(sp.getStyle() & SWT.HORIZONTAL)));
	auto ws = sash.getWeights();
	foreach (c; sash.getChildren()) { mixin(S_TRACE);
		if (!(cast(Sash) c)) { mixin(S_TRACE);
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

void drawWallpaper(GC gc, Image img, Rectangle rect, WallpaperStyle style) { mixin(S_TRACE);
	final switch (style) {
	case WallpaperStyle.Center:
		auto data = img.getBounds();
		int xi, yi, wi, hi;
		int xw, yw, ww, hw;
		void cen(int rectX, int rectW, int dataW, out int xi, out int wi, out int xw, out int ww) { mixin(S_TRACE);
			xw = (rectW - dataW) / 2;
			if (xw >= 0) { mixin(S_TRACE);
				xi = 0;
				wi = dataW;
				ww = dataW;
			} else { mixin(S_TRACE);
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
		for (int x = 0; x < rect.width; x += data.width) { mixin(S_TRACE);
			for (int y = 0; y < rect.height; y += data.height) { mixin(S_TRACE);
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
		if ((style == WallpaperStyle.ExpandFull) ? (scW < scH) : (scW >= scH)) { mixin(S_TRACE);
			wi = cast(int) (data.width * scH);
			hi = rect.height;
		} else { mixin(S_TRACE);
			wi = rect.width;
			hi = cast(int) (data.height * scW);
		}
		if (data.width != wi || data.height != hi) { mixin(S_TRACE);
			auto d = Display.getCurrent();
			if (!data.palette.isDirect || data.depth < 16 || 24 < data.depth) { mixin(S_TRACE);
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
		} else { mixin(S_TRACE);
			drawWallpaper(gc, img, rect, WallpaperStyle.Center);
		}
		break;
	}
}

/// FIXME: Combo#setItems()がエラーになることがあるため
void setComboItems(C)(C combo, string[] items) { mixin(S_TRACE);
	combo.removeAll();
	foreach (item; items) { mixin(S_TRACE);
		if (item is null) item = "";
		combo.add(item);
	}
}

/// Windows Vista以降で、Treeに点線を表示する。
void initTree(Commons comm, Tree tree, bool eventTree, bool hideRootLine = true) { mixin(S_TRACE);
	version (Windows) {
		if (eventTree) { mixin(S_TRACE);
			Listener keyDown = null, mouseDoubleClick = null, collapse = null;
			void updateTreeStyle() { mixin(S_TRACE);
				auto style = OS.GetWindowLong(tree.handle, GWL_STYLE);
				style |= OS.TVS_HASLINES;
				if (comm.prop.var.etc.classicStyleTree) { mixin(S_TRACE);
					style &= ~OS.TVS_HASBUTTONS;
					style &= ~OS.TVS_LINESATROOT;
					if (!keyDown) { mixin(S_TRACE);
						keyDown = new class Listener {
							override void handleEvent(Event e) { mixin(S_TRACE);
								auto itms = tree.getSelection();
								if (!itms.length) return;
								if (SWT.ARROW_LEFT is e.keyCode) { mixin(S_TRACE);
									auto par = itms[0].getParentItem();
									if (par) { mixin(S_TRACE);
										tree.setSelection(par);
										comm.refreshToolBar();
										e.doit = false;
										return;
									}
								}
							}
						};
						mouseDoubleClick = new class Listener {
							override void handleEvent(Event e) { mixin(S_TRACE);
								if (1 != e.button) return;
								auto itm = tree.getItem(new Point(e.x, e.y));
								if (!itm) return;
								if (!itm.getParentItem()) { mixin(S_TRACE);
									itm.setExpanded(!itm.getExpanded());
									tree.redraw();
									comm.refreshToolBar();
								}
							}
						};
						collapse = new class Listener {
							override void handleEvent(Event e) { mixin(S_TRACE);
								auto itm = cast(TreeItem)e.item;
								if (!itm) return;
								if (itm.getParentItem()) { mixin(S_TRACE);
									itm.getDisplay().asyncExec(new class Runnable {
										override void run() { mixin(S_TRACE);
											if (!itm.isDisposed()) { mixin(S_TRACE);
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
					void recurse(TreeItem itm) { mixin(S_TRACE);
						if (itm.getParentItem()) { mixin(S_TRACE);
							itm.setExpanded(true);
						}
						foreach (c; itm.getItems()) { mixin(S_TRACE);
							recurse(c);
						}
					}
					foreach (itm; tree.getItems()) { mixin(S_TRACE);
						recurse(itm);
					}
				} else { mixin(S_TRACE);
					style |= OS.TVS_HASBUTTONS;
					style |= OS.TVS_LINESATROOT;
					if (keyDown) { mixin(S_TRACE);
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
			.listener(tree, SWT.Dispose, { mixin(S_TRACE);
				comm.refEventTreeStyle.remove(&updateTreeStyle);
			});
			updateTreeStyle();
		} else { mixin(S_TRACE);
			auto style = OS.GetWindowLong(tree.handle, GWL_STYLE);
			style |= OS.TVS_HASLINES;
			if (hideRootLine) style &= ~OS.TVS_LINESATROOT;
			style = OS.SetWindowLong(tree.handle, GWL_STYLE, style);
			OS.SetWindowPos(tree.handle, null, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
		}
	}
}
void initSpinner(Spinner spn) { mixin(S_TRACE);
	assert (spn !is null);
	if (spn.getStyle() & SWT.READ_ONLY) { mixin(S_TRACE);
		spn.setEnabled(false);
	}
}

class CloseRemover(Window) : DisposeListener {
	private HashSet!(Window) _ws;
	private Window _w;
	public this (HashSet!(Window) ws, Window w) { mixin(S_TRACE);
		_ws = ws;
		_w = w;
	}
	public override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
		if (_ws.contains(_w)) { mixin(S_TRACE);
			_ws.remove(_w);
		} else assert (0);
	}
}

abstract class FileDropTarget {
private:
	Control _c;
	class DListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = canDrop ? DND.DROP_COPY : DND.DROP_NONE;
		}
		override void drop(DropTargetEvent e) { mixin(S_TRACE);
			auto arr = cast(FileNames) e.data;
			string[] paths = arr.array.dup;
			paths = doAll(paths);
			string[] r;
			foreach (fname; paths) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					scope p = _c.toControl(e.x, e.y);
					if (!doFile(fname, p.x, p.y)) { mixin(S_TRACE);
						break;
					}
					r ~= fname;
				} catch (SWTException e) {
				}
			}
			if (paths.length > 0) { mixin(S_TRACE);
				doExit();
			}
		}
	}
public:
	this(Control c) { mixin(S_TRACE);
		_c = c;
		auto target = new DropTarget(c, DND.DROP_DEFAULT | DND.DROP_COPY);
		target.setTransfer([FileTransfer.getInstance()]);
		target.addDropListener(new DListener);
	}
	@property
	Control control() { mixin(S_TRACE);
		return _c;
	}
	@property
	protected bool canDrop() { mixin(S_TRACE);
		return true;
	}
	protected string[] doAll(string[] files) { mixin(S_TRACE);
		return files;
	}
	protected void doExit() { mixin(S_TRACE);
		// Nothing
	}
	protected abstract bool doFile(string path, int x, int y);
}

alias ArrayWrapperString PathString;
alias ArrayWrapperString2 FileNames;

string wrapReturnCode(string str) { mixin(S_TRACE);
	version (Windows) {
		return std.array.replace(str, "\r\n", "\n");
	} else { mixin(S_TRACE);
		return str;
	}
}

GridLayout zeroGridLayout(int col, bool eqWid = false) { mixin(S_TRACE);
	auto gl = new GridLayout(col, eqWid);
	gl.horizontalSpacing = 0;
	gl.verticalSpacing = 0;
	gl.marginWidth = 0;
	gl.marginHeight = 0;
	return gl;
}

GridLayout zeroMarginGridLayout(int col, bool eqWid) { mixin(S_TRACE);
	auto gl = new GridLayout(col, eqWid);
	gl.marginWidth = 0;
	gl.marginHeight = 0;
	return gl;
}

const WGL_SPACING = 2;

GridLayout windowGridLayout(int col, bool eqWid = false) { mixin(S_TRACE);
	auto gl = new GridLayout(col, eqWid);
	gl.horizontalSpacing = WGL_SPACING;
	gl.verticalSpacing = WGL_SPACING;
	gl.marginWidth = WGL_SPACING;
	gl.marginHeight = WGL_SPACING;
	return gl;
}

void setGridMinW(Control c, int minW, int gridStyle = SWT.NULL) { mixin(S_TRACE);
	auto gd = new GridData(gridStyle);
	int w = c.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
	gd.widthHint = w > minW ? w : minW;
	c.setLayoutData(gd);
}

Composite centerGroup(Composite parent, string text, bool fillH = true, bool fillV = false, Object layoutData = null) { mixin(S_TRACE);
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
	override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
		stopBGM();
	}
	override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
		stopBGM();
	}
}
class StopSE : SelectionAdapter, DisposeListener {
	override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
		stopSE();
	}
	override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
		stopSE();
	}
}

bool playBGMCW(Props prop, string path, bool legacy) { mixin(S_TRACE);
    version (Windows) {} else {immutable SOUND_TYPE_MCI = -1;}
	int playType = prop.var.etc.soundPlayType;
	switch (playType) {
	case SOUND_TYPE_SDL: playBGM(path, SOUND_TYPE_SDL); return true;
	case SOUND_TYPE_MCI:
		version (Windows) {
			playBGM(path, SOUND_TYPE_MCI);
			return true;
		} else { mixin(S_TRACE);
			goto default;
		}
	case SOUND_TYPE_APP: Program.launch(path); return false;
	default:
		// auto
		int type;
		if (legacy) { mixin(S_TRACE);
			type = SOUND_TYPE_MCI;
			version (Windows) {
				if (.canPlayBass(path)) { mixin(S_TRACE);
					type = SOUND_TYPE_BASS;
				}
			}
		} else { mixin(S_TRACE);
			type = SOUND_TYPE_SDL;
		}
		playBGM(path, type);
		return true;
	}
}

void playSECW(Props prop, string path, bool legacy) { mixin(S_TRACE);
    version (Windows) {} else {immutable SOUND_TYPE_MCI = -1;}
	int type = prop.var.etc.soundEffectPlayType;
	if (SOUND_TYPE_SAME_BGM == type) { mixin(S_TRACE);
		type = prop.var.etc.soundPlayType;
	}
	switch (type) {
	case SOUND_TYPE_SDL: playSE(path, SOUND_TYPE_SDL); break;
	case SOUND_TYPE_MCI:
		version (Windows) {
			playSE(path, SOUND_TYPE_MCI);
			break;
		} else { mixin(S_TRACE);
			goto default;
		}
	case SOUND_TYPE_APP: Program.launch(path); break;
	default:
		// auto
		if (legacy) { mixin(S_TRACE);
			type = SOUND_TYPE_MCI;
			version (Windows) {
				if (.canPlayBass(path)) { mixin(S_TRACE);
					type = SOUND_TYPE_BASS;
				}
			}
		} else { mixin(S_TRACE);
			type = SOUND_TYPE_SDL;
		}
		playSE(path, type);
		break;
	}
}

/// 文字列の見た目の長さを測る。
int textWidth(Props prop, Control c, string text) { mixin(S_TRACE);
	auto gc = new GC(c);
	scope (exit) gc.dispose();
	auto mono = new Font(Display.getCurrent(), new FontData(prop.looks.monospace, 10, SWT.NORMAL));
	scope (exit) mono.dispose();
	gc.setFont(mono);
	return gc.textExtent(text).x / gc.textExtent(" ").x;
}

Cursor[Shell] setWaitCursors(Shell shell) { mixin(S_TRACE);
	auto cWait = shell.getDisplay().getSystemCursor(SWT.CURSOR_WAIT);
	Cursor[Shell] cursors;
	void put(Shell cShl) { mixin(S_TRACE);
		if (cShl.getCursor() !is cWait) { mixin(S_TRACE);
			cursors[cShl] = cShl.getCursor();
			cShl.setCursor(cWait);
		}
	}
	put(shell);
	foreach (chld; shell.getShells()) { mixin(S_TRACE);
		if (chld.isDisposed()) continue;
		put(chld);
	}
	return cursors;
}
void resetCursors(Cursor[Shell] cursors) { mixin(S_TRACE);
	foreach (shl, cur; cursors) { mixin(S_TRACE);
		if (shl.isDisposed()) continue;
		shl.setCursor(cur);
	}
}

/// 前景色cを背景色bに対して透明度aで描画した時の色を返す。
RGB alphaColor(in RGB c, in RGB b, int a) { mixin(S_TRACE);
	if (a < 0) a = 0;
	if (255 < a) a = 255;
	int oc(int c, int b) { mixin(S_TRACE);
		if (c == b) return c;
		int mx = std.algorithm.max(c, b);
		int mn = std.algorithm.min(c, b);
		return mn + (mx - mn) - cast(int) ((mx - mn) * (a / 255.0));
	}
	return new RGB(oc(c.red, b.red), oc(c.green, b.green), oc(c.blue, b.blue));
}

string objName(A)(in Props prop) { mixin(S_TRACE);
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
string contentTextUseID(CIDKind Kind, ID)(Commons comm, Summary summ, ID id, string msg, in Content evt) { mixin(S_TRACE);
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
		if ("" == id && evt) { mixin(S_TRACE);
			foreach (s; evt.tree.starts) { mixin(S_TRACE);
				if (!s.name.length) { mixin(S_TRACE);
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
	if (exists) { mixin(S_TRACE);
		return .tryFormat(msg, name);
	} else { mixin(S_TRACE);
		return .tryFormat(msg, .tryFormat(noID, id));
	}
}

string contentText(Commons comm, in Content evt, Summary summ = null) { mixin(S_TRACE);
	if (!summ) summ = comm.summary;
	string loseCardCount() { mixin(S_TRACE);
		return evt.cardNumber == 0 ? comm.prop.msgs.ctLoseCardAll : .tryFormat(comm.prop.msgs.ctLoseCardCount, evt.cardNumber);
	}
	@property
	string bgImageString() { mixin(S_TRACE);
		string buf;
		foreach (i, b; evt.backs) { mixin(S_TRACE);
			auto ic = cast(ImageCell) b;
			if (ic) { mixin(S_TRACE);
				buf ~= contentTextUseID!(CIDKind.Image)(comm, summ, ic.path, comm.prop.msgs.ctChangeBgImageFile, null);
			} else { mixin(S_TRACE);
				buf ~= .tryFormat(comm.prop.msgs.ctChangeBgImageFile, b.name(comm.prop.parent));
			}
			if (i + 1 < evt.backs.length) buf ~= " ";
		}
		return buf;
	}
	final switch (evt.type) {
	case CType.START: { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.ctStart, evt.name);
	} case CType.START_BATTLE: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Battle)(comm, summ, evt.battle, comm.prop.msgs.ctStartBattle, evt);
	} case CType.END: { mixin(S_TRACE);
		return evt.complete ? comm.prop.msgs.ctEndComplete : comm.prop.msgs.ctEndNoComplete;
	} case CType.END_BAD_END: { mixin(S_TRACE);
		return comm.prop.msgs.ctGameOver;
	} case CType.CHANGE_AREA: { mixin(S_TRACE);
		if (summ && summ.legacy) { mixin(S_TRACE);
			return contentTextUseID!(CIDKind.Area)(comm, summ, evt.area, comm.prop.msgs.ctChangeAreaClassic, evt);
		} else { mixin(S_TRACE);
			string a = contentTextUseID!(CIDKind.Area)(comm, summ, evt.area, "%s", evt);
			string v = comm.prop.msgs.transitionName(evt.transition);
			return .tryFormat(comm.prop.msgs.ctChangeArea, a, v, evt.transitionSpeed);
		}
	} case CType.CHANGE_BG_IMAGE: { mixin(S_TRACE);
		if (summ && summ.legacy) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctChangeBgImageClassic, bgImageString);
		} else { mixin(S_TRACE);
			string v = comm.prop.msgs.transitionName(evt.transition);
			return .tryFormat(comm.prop.msgs.ctChangeBgImage, bgImageString, v, evt.transitionSpeed);
		}
	} case CType.EFFECT: { mixin(S_TRACE);
		string tt = comm.prop.msgs.targetName(evt.targetNS.m);
		int tl = evt.signedLevel;
		string tet = comm.prop.msgs.effectTypeName(evt.effectType);
		string tr = comm.prop.msgs.resistName(evt.resist);
		string tsf = evt.successRate >= 0 ? "+" : "-";
		int ts = std.math.abs(evt.successRate);
		string tsnd = contentTextUseID!(CIDKind.SE)(comm, summ, evt.soundPath, comm.prop.msgs.ctEffectSound, evt);
		string tcv = comm.prop.msgs.cardVisualName(evt.cardVisual);
		string teff = "";
		foreach (i, m; evt.motions) { mixin(S_TRACE);
			teff ~= .tryFormat(comm.prop.msgs.ctEffectMotion, comm.prop.msgs.motionName(m.type));
			if (i + 1 < evt.motions.length) teff ~= " ";
		}
		return .tryFormat(comm.prop.msgs.ctEffect, tt, tl, tet, tr, tsf, ts, tsnd, tcv, teff);
	} case CType.EFFECT_BREAK: { mixin(S_TRACE);
		return comm.prop.msgs.ctEffectBreak;
	} case CType.LINK_START: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Start)(comm, summ, evt.start, comm.prop.msgs.ctLinkStart, evt);
	} case CType.LINK_PACKAGE: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Package)(comm, summ, evt.packages, comm.prop.msgs.ctLinkPackage, evt);
	} case CType.TALK_MESSAGE: { mixin(S_TRACE);
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
	} case CType.TALK_DIALOG: { mixin(S_TRACE);
		string r(in SDialog sdlg) { mixin(S_TRACE);
			string tt = comm.prop.msgs.talkerName(evt.talkerNC);
			string t = sdlg.text.singleLine;
			if (sdlg.rCoupons.length) { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctTalkDialog, tt, std.string.join(sdlg.rCoupons.dup, " "), t);
			} else { mixin(S_TRACE);
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
			foreach_reverse (dlg; evt.dialogs) { mixin(S_TRACE);
				if (dlg.rCoupons.length) { mixin(S_TRACE);
					return r(dlg);
				}
			}
			return r(evt.dialogs[$ - 1]);
		default:
			return r(evt.dialogs[0]);
		}
	} case CType.PLAY_BGM: { mixin(S_TRACE);
		if ("" == evt.bgmPath) { mixin(S_TRACE);
			return  comm.prop.msgs.ctStopBGM;
		} else { mixin(S_TRACE);
			return contentTextUseID!(CIDKind.BGM)(comm, summ, evt.bgmPath, comm.prop.msgs.ctPlayBGM, evt);
		}
	} case CType.PLAY_SOUND: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.SE)(comm, summ, evt.soundPath, comm.prop.msgs.ctPlaySound, evt);
	} case CType.WAIT: { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.ctWait, evt.wait);
	} case CType.ELAPSE_TIME: { mixin(S_TRACE);
		return comm.prop.msgs.ctElapseTime;
	} case CType.CALL_START: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Start)(comm, summ, evt.start, comm.prop.msgs.ctCallStart, evt);
	} case CType.CALL_PACKAGE: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Package)(comm, summ, evt.packages, comm.prop.msgs.ctCallPackage, evt);
	} case CType.BRANCH_FLAG: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag, comm.prop.msgs.ctBranchFlag, evt);
	} case CType.BRANCH_MULTI_STEP: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, comm.prop.msgs.ctBranchMultiStep, evt);
	} case CType.BRANCH_STEP: { mixin(S_TRACE);
		string s = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
		auto step = summ.flagDirRoot.findStep(evt.step);
		string v = step ? step.getValue(evt.stepValue) : .tryFormat(comm.prop.msgs.dlgLblStep, evt.stepValue);
		return .tryFormat(comm.prop.msgs.ctBranchStep, s, v);
	} case CType.BRANCH_SELECT: { mixin(S_TRACE);
		string t = evt.targetAll ? comm.prop.msgs.ctBranchSelectAll : comm.prop.msgs.ctBranchSelectActive;
		string r = evt.random ? comm.prop.msgs.ctBranchSelectAuto : comm.prop.msgs.ctBranchSelectManual;
		return .tryFormat(comm.prop.msgs.ctBranchSelect, t, r);
	} case CType.BRANCH_ABILITY: { mixin(S_TRACE);
		string t = comm.prop.msgs.targetName(evt.targetS.m);
		string p = comm.prop.msgs.physicalName(evt.physical);
		string m = comm.prop.msgs.mentalName(evt.mental);
		string s = evt.targetS.sleep ? comm.prop.msgs.sleepEnabled : comm.prop.msgs.sleepDisabled;
		auto l = evt.signedLevel;
		return .tryFormat(comm.prop.msgs.ctBranchAbility, t, s, p, m, l);
	} case CType.BRANCH_RANDOM: { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.ctBranchRandom, evt.percent);
	} case CType.BRANCH_LEVEL: { mixin(S_TRACE);
		string a = evt.average ? comm.prop.msgs.ctBranchLevelAverage : comm.prop.msgs.ctBranchLevelSelected;
		auto l = evt.unsignedLevel;
		return .tryFormat(comm.prop.msgs.ctBranchLevel, a, l);
	} case CType.BRANCH_STATUS: { mixin(S_TRACE);
		string t = comm.prop.msgs.targetName(evt.targetNS.m);
		string s = comm.prop.msgs.statusName(evt.status);
		return .tryFormat(comm.prop.msgs.ctBranchStatus, t, s);
	} case CType.BRANCH_PARTY_NUMBER: { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.ctBranchPartyNumber, evt.partyNumber);
	} case CType.BRANCH_AREA: { mixin(S_TRACE);
		return comm.prop.msgs.ctBranchArea;
	} case CType.BRANCH_BATTLE: { mixin(S_TRACE);
		return comm.prop.msgs.ctBranchBattle;
	} case CType.BRANCH_IS_BATTLE: { mixin(S_TRACE);
		return comm.prop.msgs.ctBranchIsBattle;
	} case CType.BRANCH_CAST: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Cast)(comm, summ, evt.casts, comm.prop.msgs.ctBranchCast, evt);
	} case CType.BRANCH_ITEM: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Item)(comm, summ, evt.item, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctBranchItem, name, comm.prop.msgs.rangeName(evt.range), evt.cardNumber);
	} case CType.BRANCH_SKILL: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Skill)(comm, summ, evt.skill, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctBranchSkill, name, comm.prop.msgs.rangeName(evt.range), evt.cardNumber);
	} case CType.BRANCH_INFO: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Info)(comm, summ, evt.info, comm.prop.msgs.ctBranchInfo, evt);
	} case CType.BRANCH_BEAST: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Beast)(comm, summ, evt.beast, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctBranchBeast, name, comm.prop.msgs.rangeName(evt.range), evt.cardNumber);
	} case CType.BRANCH_MONEY: { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.ctBranchMoney, evt.money);
	} case CType.BRANCH_COUPON: { mixin(S_TRACE);
		string c = evt.coupon;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCoupon;
		return .tryFormat(comm.prop.msgs.ctBranchCoupon, c, comm.prop.msgs.rangeName(evt.range));
	} case CType.BRANCH_COMPLETE_STAMP: { mixin(S_TRACE);
		string c = evt.completeStamp;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCompleteStamp;
		return .tryFormat(comm.prop.msgs.ctBranchCompleteStamp, c);
	} case CType.BRANCH_GOSSIP: { mixin(S_TRACE);
		string c = evt.gossip;
		if (!c || !c.length) c = comm.prop.msgs.noSelectGossip;
		return .tryFormat(comm.prop.msgs.ctBranchGossip, c);
	} case CType.SET_FLAG: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag, "%s", evt);
		string on = comm.prop.msgs.flagOn;
		string off = comm.prop.msgs.flagOff;
		auto o = summ.flagDirRoot.findFlag(evt.flag);
		if (o) { mixin(S_TRACE);
			on = o.on;
			off = o.off;
		}
		return .tryFormat(comm.prop.msgs.ctSetFlag, name, evt.flagValue ? on : off);
	} case CType.SET_STEP: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
		string value;
		auto o = summ.flagDirRoot.findStep(evt.step);
		if (o) { mixin(S_TRACE);
			value = o.getValue(evt.stepValue);
		} else { mixin(S_TRACE);
			value = .tryFormat(comm.prop.msgs.dlgLblStep, evt.stepValue);
		}
		return .tryFormat(comm.prop.msgs.ctSetStep, name, value);
	} case CType.SET_STEP_UP: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, comm.prop.msgs.ctSetStepUp, evt);
	} case CType.SET_STEP_DOWN: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, comm.prop.msgs.ctSetStepDown, evt);
	} case CType.REVERSE_FLAG: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag, comm.prop.msgs.ctReverseFlag, evt);
	} case CType.CHECK_FLAG: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag, "%s", evt);
		string on = comm.prop.msgs.flagOn;
		auto o = summ.flagDirRoot.findFlag(evt.flag);
		if (o) { mixin(S_TRACE);
			on = o.on;
		}
		return .tryFormat(comm.prop.msgs.ctCheckFlag, name, on);
	} case CType.GET_CAST: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Cast)(comm, summ, evt.casts, comm.prop.msgs.ctGetCast, evt);
	} case CType.GET_ITEM: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Item)(comm, summ, evt.item, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctGetItem, name, comm.prop.msgs.rangeName(evt.range), evt.cardNumber);
	} case CType.GET_SKILL: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Skill)(comm, summ, evt.skill, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctGetSkill, name, comm.prop.msgs.rangeName(evt.range), evt.cardNumber);
	} case CType.GET_INFO: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Info)(comm, summ, evt.info, comm.prop.msgs.ctGetInfo, evt);
	} case CType.GET_BEAST: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Beast)(comm, summ, evt.beast, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctGetBeast, name, comm.prop.msgs.rangeName(evt.range), evt.cardNumber);
	} case CType.GET_MONEY: { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.ctGetMoney, evt.money);
	} case CType.GET_COUPON: { mixin(S_TRACE);
		string c = evt.coupon;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCoupon;
		return .tryFormat(comm.prop.msgs.ctGetCoupon, c, comm.prop.msgs.rangeName(evt.range));
	} case CType.GET_COMPLETE_STAMP: { mixin(S_TRACE);
		string c = evt.completeStamp;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCompleteStamp;
		return .tryFormat(comm.prop.msgs.ctGetCompleteStamp, c);
	} case CType.GET_GOSSIP: { mixin(S_TRACE);
		string c = evt.gossip;
		if (!c || !c.length) c = comm.prop.msgs.noSelectGossip;
		return .tryFormat(comm.prop.msgs.ctGetGossip, c);
	} case CType.LOSE_CAST: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Cast)(comm, summ, evt.casts, comm.prop.msgs.ctLoseCast, evt);
	} case CType.LOSE_ITEM: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Item)(comm, summ, evt.item, "%s", evt);
		string count = loseCardCount();
		return .tryFormat(comm.prop.msgs.ctLoseItem, name, comm.prop.msgs.rangeName(evt.range), count);
	} case CType.LOSE_SKILL: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Skill)(comm, summ, evt.skill, "%s", evt);
		string count = loseCardCount();
		return .tryFormat(comm.prop.msgs.ctLoseSkill, name, comm.prop.msgs.rangeName(evt.range), count);
	} case CType.LOSE_INFO: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Info)(comm, summ, evt.info, comm.prop.msgs.ctLoseInfo, evt);
	} case CType.LOSE_BEAST: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Beast)(comm, summ, evt.beast, "%s", evt);
		string count = loseCardCount();
		return .tryFormat(comm.prop.msgs.ctLoseBeast, name, comm.prop.msgs.rangeName(evt.range), count);
	} case CType.LOSE_MONEY: { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.ctLoseMoney, evt.money);
	} case CType.LOSE_COUPON: { mixin(S_TRACE);
		string c = evt.coupon;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCoupon;
		return .tryFormat(comm.prop.msgs.ctLoseCoupon, c, comm.prop.msgs.rangeName(evt.range));
	} case CType.LOSE_COMPLETE_STAMP: { mixin(S_TRACE);
		string c = evt.completeStamp;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCompleteStamp;
		return .tryFormat(comm.prop.msgs.ctLoseCompleteStamp, c);
	} case CType.LOSE_GOSSIP: { mixin(S_TRACE);
		string c = evt.gossip;
		if (!c || !c.length) c = comm.prop.msgs.noSelectGossip;
		return .tryFormat(comm.prop.msgs.ctLoseGossip, c);
	} case CType.SHOW_PARTY: { mixin(S_TRACE);
		return comm.prop.msgs.ctShowParty;
	} case CType.HIDE_PARTY: { mixin(S_TRACE);
		return comm.prop.msgs.ctHideParty;
	} case CType.REDISPLAY: { mixin(S_TRACE);
		if (summ && summ.legacy) { mixin(S_TRACE);
			return comm.prop.msgs.ctRedisplayClassic;
		} else { mixin(S_TRACE);
			string v = comm.prop.msgs.transitionName(evt.transition);
			return .tryFormat(comm.prop.msgs.ctRedisplay, v, evt.transitionSpeed);
		}
	} case CType.SUBSTITUTE_STEP: { mixin(S_TRACE);
		auto t2 = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step2, "%s", evt);
		if (evt.step == comm.prop.sys.randomValue) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctSubstituteStepFromRandom, t2);
		} else { mixin(S_TRACE);
			auto t1 = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
			return .tryFormat(comm.prop.msgs.ctSubstituteStep, t1, t2);
		}
	} case CType.SUBSTITUTE_FLAG: { mixin(S_TRACE);
		auto t2 = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag2, "%s", evt);
		if (evt.flag == comm.prop.sys.randomValue) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctSubstituteFlagFromRandom, t2);
		} else { mixin(S_TRACE);
			auto t1 = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag, "%s", evt);
			return .tryFormat(comm.prop.msgs.ctSubstituteFlag, t1, t2);
		}
	} case CType.BRANCH_STEP_CMP: { mixin(S_TRACE);
		auto t1 = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
		auto t2 = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step2, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctBranchStepCmp, t1, t2);
	} case CType.BRANCH_FLAG_CMP: { mixin(S_TRACE);
		auto t1 = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag, "%s", evt);
		auto t2 = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag2, "%s", evt);
		return .tryFormat(comm.prop.msgs.ctBranchFlagCmp, t1, t2);
	} case CType.BRANCH_RANDOM_SELECT: { mixin(S_TRACE);
		string r = castRangesName(comm.prop, evt.castRange);
		bool hasLevel = 0 < evt.levelMax;
		bool hasStatus = evt.status !is Status.NONE;
		if (hasLevel || hasStatus) { mixin(S_TRACE);
			string s = comm.prop.msgs.statusName(evt.status);
			auto l1 = evt.levelMin, l2 = evt.levelMax;
			string cond;
			if (hasLevel && hasStatus) { mixin(S_TRACE);
				cond = .tryFormat(comm.prop.msgs.randomSelectCondition3, l1, l2, s);
			} else if (hasLevel) { mixin(S_TRACE);
				cond = .tryFormat(comm.prop.msgs.randomSelectCondition1, l1, l2);
			} else if (hasStatus) { mixin(S_TRACE);
				cond = .tryFormat(comm.prop.msgs.randomSelectCondition2, s);
			} else assert (0);
			return .tryFormat(comm.prop.msgs.ctRandomSelect, r, cond);
		} else { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctRandomSelectN, r);
		}
	} case CType.BRANCH_KEY_CODE: { mixin(S_TRACE);
		string range = comm.prop.msgs.rangeName(evt.keyCodeRange);
		if (evt.effectCardType is EffectCardType.ALL) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctBranchKeyCodeAllType, evt.keyCode, range);
		} else { mixin(S_TRACE);
			string type = comm.prop.msgs.effectCardTypeName(evt.effectCardType);
			return .tryFormat(comm.prop.msgs.ctBranchKeyCode, evt.keyCode, type, range);
		}
	} case CType.CHECK_STEP: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
		string value;
		auto o = summ.flagDirRoot.findStep(evt.step);
		if (o) { mixin(S_TRACE);
			value = o.getValue(evt.stepValue);
		} else { mixin(S_TRACE);
			value = .tryFormat(comm.prop.msgs.dlgLblStep, evt.stepValue);
		}
		string cmp = comm.prop.msgs.comparison4Name(evt.comparison4);
		return .tryFormat(comm.prop.msgs.ctCheckStep, name, value, cmp);
	} case CType.BRANCH_ROUND: { mixin(S_TRACE);
		string cmp = comm.prop.msgs.comparison3Name(evt.comparison3);
		return .tryFormat(comm.prop.msgs.ctBranchRound, evt.round, cmp);
	} case CType.MOVE_BG_IMAGE: { mixin(S_TRACE);
		string cellName = evt.cellName;
		if (!cellName || !cellName.length) cellName = comm.prop.msgs.noSelectCellName;
		string posType = comm.prop.msgs.coordinateTypeName(evt.positionType);
		string sizeType = comm.prop.msgs.coordinateTypeName(evt.sizeType);
		string ts = comm.prop.msgs.transitionName(evt.transition);
		if (evt.positionType !is CoordinateType.None && evt.sizeType !is CoordinateType.None) {
			if (summ && summ.legacy) { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctMoveAndResizeBgImageClassic, cellName, posType, evt.x, evt.y, sizeType, evt.width, evt.height);
			} else { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctMoveAndResizeBgImage, cellName, posType, evt.x, evt.y, sizeType, evt.width, evt.height, ts, evt.transitionSpeed);
			}
		} else if (evt.positionType !is CoordinateType.None) { mixin(S_TRACE);
			if (summ && summ.legacy) { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctMoveBgImageClassic, cellName, posType, evt.x, evt.y);
			} else { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctMoveBgImage, cellName, posType, evt.x, evt.y, ts, evt.transitionSpeed);
			}
		} else if (evt.sizeType !is CoordinateType.None) { mixin(S_TRACE);
			if (summ && summ.legacy) { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctResizeBgImageClassic, cellName, sizeType, evt.width, evt.height);
			} else { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctResizeBgImage, cellName, sizeType, evt.width, evt.height, ts, evt.transitionSpeed);
			}
		} else { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctMoveBgImageNoSet, cellName);
		}
	} case CType.REPLACE_BG_IMAGE: { mixin(S_TRACE);
		string cellName = evt.cellName;
		if (!cellName || !cellName.length) cellName = comm.prop.msgs.noSelectCellName;
		if (summ && summ.legacy) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctReplaceBgImageClassic, cellName, bgImageString);
		} else { mixin(S_TRACE);
			string ts = comm.prop.msgs.transitionName(evt.transition);
			return .tryFormat(comm.prop.msgs.ctReplaceBgImage, cellName, bgImageString, ts, evt.transitionSpeed);
		}
	} case CType.LOSE_BG_IMAGE: { mixin(S_TRACE);
		string cellName = evt.cellName;
		if (!cellName || !cellName.length) cellName = comm.prop.msgs.noSelectCellName;
		if (summ && summ.legacy) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctLoseBgImageClassic, cellName);
		} else { mixin(S_TRACE);
			string ts = comm.prop.msgs.transitionName(evt.transition);
			return .tryFormat(comm.prop.msgs.ctLoseBgImage, cellName, ts, evt.transitionSpeed);
		}
	}
	}
}

string castRangesName(in Props prop, in CastRange[] r) { mixin(S_TRACE);
	string cr(CastRange r) { mixin(S_TRACE);
		return prop.msgs.castRangeName(r);
	}
	if (3 <= r.length) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.castRange3, cr(r[0]), cr(r[1]), cr(r[2]));
	} else if (2 == r.length) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.castRange2, cr(r[0]), cr(r[1]));
	} else if (1 == r.length) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.castRange1, cr(r[0]));
	} else { mixin(S_TRACE);
		return prop.msgs.castRange0;
	}
}

bool CBisText(Clipboard cb) { mixin(S_TRACE);
	auto t = TextTransfer.getInstance();
	foreach (data; cb.getAvailableTypes()) { mixin(S_TRACE);
		if (t.isSupportedType(data)) return true;
	}
	return false;
}
bool CBisFile(Clipboard cb) { mixin(S_TRACE);
	auto t = FileTransfer.getInstance();
	foreach (data; cb.getAvailableTypes()) { mixin(S_TRACE);
		if (t.isSupportedType(data)) return true;
	}
	return false;
}

private class DropFiles : DropTargetAdapter {
	private Text _text;
	private string delegate(string[] files) _drop;
	private void delegate(string) _dropPath;
	this (Text text, string delegate(string[] files) drop, void delegate(string) dropPath = null) { mixin(S_TRACE);
		_text = text;
		_drop = drop;
		_dropPath = dropPath;
	}
	override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
		if (_text.getEnabled()) { mixin(S_TRACE);
			e.detail = DND.DROP_LINK;
		}
	}
	override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
		if (_text.getEnabled()) { mixin(S_TRACE);
			e.detail = DND.DROP_LINK;
		}
	}
	override void drop(DropTargetEvent e){ mixin(S_TRACE);
		e.detail = DND.DROP_NONE;
		auto str = _drop((cast(FileNames) e.data).array);
		if (_text.getEnabled() && str.length && str != _text.getText()) { mixin(S_TRACE);
			_text.setText(str);
			_text.selectAll();
			e.detail = DND.DROP_LINK;
			if (_dropPath) _dropPath(str);
		}
	}
}
/// cにファイルやディレクトリがドロップされるのを受け付ける。
void setupDropFile(Control c, Text text, string delegate(string[] files) drop, void delegate(string) dropPath = null) { mixin(S_TRACE);
	auto dropt = new DropTarget(c, DND.DROP_DEFAULT | DND.DROP_LINK);
	dropt.setTransfer([FileTransfer.getInstance()]);
	if (!drop) drop = toDelegate(&dropDefault);
	dropt.addDropListener(new DropFiles(text, drop, dropPath));
}
/// filesの最初の値を返す。配列の内容が無ければ""を返す。
/// 値がファイルであれば、その上位のディレクトリを返す。
string dropDir(string[] files) { mixin(S_TRACE);
	if (!files.length) return "";
	string file = files[0];
	if (!.exists(file)) return "";
	if (.isDir(file)) { mixin(S_TRACE);
		return file;
	} else { mixin(S_TRACE);
		return dirName(file);
	}
}
/// filesの最初の値を返す。配列の内容が無ければ""を返す。
string dropDefault(string[] files) { mixin(S_TRACE);
	return files.length ? files[0] : "";
}
/// ファイルの選択を行う。
string selectFile(Text file, string[] name, string[] ext, string fileName, string title, string p) { mixin(S_TRACE);
	auto dlg = new FileDialog(file.getShell(), SWT.PRIMARY_MODAL | SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.OPEN);
	dlg.setFilterExtensions(ext);
	dlg.setFilterNames(name);
	dlg.setText(title);
	dlg.setFilterPath(dirName(nabs(p)));
	dlg.setFileName(fileName);
	string fname = dlg.open();
	if (fname) { mixin(S_TRACE);
		file.setText(fname);
	}
	return fname;
}
/// ディレクトリの選択を行う。
string selectDir(T)(Props prop, T dir, string title, string msg, string p, bool appPath = true) { mixin(S_TRACE);
	auto dlg = new DirectoryDialog(dir.getShell());
	dlg.setText(title);
	dlg.setMessage(msg);
	string path = p;
	if (appPath) { mixin(S_TRACE);
		auto d = dir.getText();
		if (!isAbsolute(d)) { mixin(S_TRACE);
			d = std.path.buildPath(std.path.dirName(prop.parent.appPath), d);
		}
		path = d;
	}
	dlg.setFilterPath(nabs(path));
	string fname = dlg.open();
	if (fname) { mixin(S_TRACE);
		dir.setText(fname);
	}
	return fname;
}
/// ファイルやディレクトリを開くボタンを作成する。
Button createOpenButton(Commons comm, Composite parent, string delegate() getText, bool dir) { mixin(S_TRACE);
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
	this (Commons comm, string delegate() text) { mixin(S_TRACE);
		_comm = comm;
		_text = text;
	}
	override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
		string file = _text();
		if (!isAbsolute(file)) { mixin(S_TRACE);
			file = std.path.buildPath(_comm.prop.parent.appPath.dirName(), file);
		}
		if (!.exists(file) || !isDir(file)) { mixin(S_TRACE);
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

void updateChecked(Event)(Event e) { mixin(S_TRACE);
	if (e.detail == SWT.CHECK) { mixin(S_TRACE);
		auto itm = cast(TableItem)e.item;
		auto tbl = itm.getParent();
		if (tbl.isSelected(tbl.indexOf(itm))) { mixin(S_TRACE);
			foreach (itm2; itm.getParent().getSelection()) { mixin(S_TRACE);
				itm2.setChecked(itm.getChecked());
			}
		}
	}
}
