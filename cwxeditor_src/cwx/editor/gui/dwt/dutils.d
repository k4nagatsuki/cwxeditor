
module cwx.editor.gui.dwt.dutils;

import cwx.archive;
import cwx.area;
import cwx.background;
import cwx.cab;
import cwx.card;
import cwx.cwl;
import cwx.event;
import cwx.features;
import cwx.flag;
import cwx.graphics;
import cwx.imagesize;
import cwx.jpy;
import cwx.menu;
import cwx.motion;
import cwx.path;
import cwx.props;
import cwx.settings;
import cwx.skin;
import cwx.structs;
import cwx.summary;
import cwx.textholder;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.variables;
import cwx.warning;

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
import cwx.editor.gui.dwt.absdialog;

import core.thread;

static import std.algorithm;
import std.algorithm : max, min;
import std.array;
import std.conv;
import std.utf;
import std.ascii;
import std.file;
import std.datetime;
import std.path;
import std.process;
import std.functional;
import std.typecons : Rebindable, Tuple;
import std.stdio;
import std.string;
import std.math;

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
			byte* ptr = null;
			byte[] bytes;
			if (isBinImg(path)) { mixin(S_TRACE);
				bytes = cast(byte[])strToBImg(path);
			} else { mixin(S_TRACE);
				if (!.exists(path) || !.isFile(path)) return blankImage;
				bytes = readBinaryFrom!byte(path, ptr);
			}
			scope (exit) {
				if (!isBinImg(path) && ptr) {
					bytes[] = 0;
					freeAll(ptr);
				}
			}
			ImageData data = null;
			try { mixin(S_TRACE);
				auto s = new ByteArrayInputStream(bytes);
				scope (exit) s.close();
				data = new ImageData(s);
			} catch (Throwable e) {
				// 壊れたビットマップとして再読込を試みる
				printStackTrace();
				debugln(e);
				debugln("Image loading failure. Tries patch to the broken bitmap.");
				.fixCWNext16BitBitmap(bytes);
				auto s = new ByteArrayInputStream(bytes);
				scope (exit) s.close();
				data = new ImageData(s);
			}
			if (32 == data.depth && 'B' == bytes[0] && 'M' == bytes[1]) { mixin(S_TRACE);
				// CardWirthのデコーダは予備色をアルファ値として扱うが、
				// 1件も0以外の数値が無い場合は扱わない
				foreach (y; 0 .. data.height) { mixin(S_TRACE);
					foreach (x; 0 .. data.width) { mixin(S_TRACE);
						auto b = cast(ubyte)data.data[y * data.bytesPerLine + x * 4 + 3];
						if (b != 0) { mixin(S_TRACE);
							if (!data.alphaData) data.alphaData = new byte[data.width * data.height];
							data.alphaData[y * data.width + x] = b;
						}
					}
				}
			}
			if (mask && (!data.alphaData || !data.alphaData.length)) { mixin(S_TRACE);
				if (data.palette !is null) { mixin(S_TRACE);
					// パレットを使用しているイメージは透過色と同一の色が
					// 別に存在する時にその色が透過されない
					auto d = Display.getCurrent();
					auto canvas = new Image(d, data.width, data.height);
					scope (exit) canvas.dispose();
					auto gc = new GC(canvas);
					scope (exit) gc.dispose();
					auto image = new Image(d, data);
					scope (exit) image.dispose();
					gc.drawImage(image, 0, 0);
					data = canvas.getImageData();
				}
				data.transparentPixel = data.getPixel(maskX, maskY);
			}
			return data;
		} catch (core.exception.AssertError e) {
			printStackTrace();
			debugln(e);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		} catch (core.exception.RangeError e) {
			printStackTrace();
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
			if (_enter) _enter(_spn.getSelection());
		} else { mixin(S_TRACE);
			_noEdit = true;
			scope (exit) _noEdit = false;
			_spn.setSelection(_cancel !is null ? _cancel(_oldVal) : _oldVal);
		}
		_oldVal = _spn.getSelection();
	}
	class KListener : KeyAdapter {
		public override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			if (.isEnterKey(e.keyCode)) { mixin(S_TRACE);
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
	this (Spinner spn, void delegate(int value) enter,
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
	bool _quickStart = false;
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
	/// アイテム選択時、即座に編集を開始する。
	@property
	void quickStart(bool v) { _quickStart = v; }
	/// ditto
	@property
	const
	bool quickStart() { return _quickStart; }

	override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
		if (_quickStart) { mixin(S_TRACE);
			auto itm = _selection();
			if (itm) { mixin(S_TRACE);
				_startEdit(itm);
			}
			return;
		}
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
		auto selected = false;
		if (quickStart) { mixin(S_TRACE);
			if (auto table = cast(Table)e.widget) {
				if (-1 == table.getSelectionIndex() && table.getItemCount()) { mixin(S_TRACE);
					table.select(0);
					selected = true;
				}
			}
			if (auto tree = cast(Tree)e.widget) {
				if (!tree.getSelection() && tree.getItemCount()) { mixin(S_TRACE);
					tree.setSelection(tree.getItem(0));
					selected = true;
				}
			}
		}
		if (_comm.prop.var.etc.editTriggerType is EditTrigger.Quick) { mixin(S_TRACE);
			_itm = _selection();
		}
		if (selected) { mixin(S_TRACE);
			.asyncExec(_display, { mixin(S_TRACE);
				auto se = new Event;
				se.type = SWT.Selection;
				se.widget = e.widget;
				se.time = e.time;
				se.stateMask = SWT.NONE;
				se.doit = true;
				e.widget.notifyListeners(SWT.Selection, se);
			});
		} else if (quickStart) { mixin(S_TRACE);
			.asyncExec(_display, { mixin(S_TRACE);
				auto itm = _selection();
				if (itm) { mixin(S_TRACE);
					_startEdit(itm);
				}
			});
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
			printStackTrace();
			debugln(e);
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
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
}

class EditEnd : KeyAdapter, FocusListener {
	void delegate(bool cancel)[] exitEvent;

private:
	Commons _comm;
	Control ctrl;
	void delegate(Control) end;
	bool _canOpenCombo = false;

public:
	this(Commons comm, Composite parent, Control ctrl, void delegate(Control) end, bool canOpenCombo = true) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			_comm = comm;
			this.end = end;
			this.ctrl = ctrl;
			_canOpenCombo = canOpenCombo;
			ctrl.addFocusListener(this);
			ctrl.addKeyListener(this);

			auto focusIn = new class Listener {
				override void handleEvent(Event e) { mixin(S_TRACE);
					focusOut();
				}
			};
			ctrl.getDisplay().addFilter(SWT.FocusIn, focusIn);
			ctrl.getDisplay().addFilter(SWT.Deactivate, focusIn);
			.listener(ctrl, SWT.Dispose, { mixin(S_TRACE);
				ctrl.getDisplay().removeFilter(SWT.FocusIn, focusIn);
				ctrl.getDisplay().removeFilter(SWT.Deactivate, focusIn);
			});
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void setFocus() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			ctrl.setFocus();
			if (_canOpenCombo && _comm.prop.var.etc.comboListVisible) { mixin(S_TRACE);
				auto combo = cast(Combo) ctrl;
				if (combo) combo.setListVisible(true);
				auto ccombo = cast(CCombo) ctrl;
				if (ccombo) ccombo.setListVisible(true);
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	@property
	Control editor() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			return ctrl;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	override void focusGained(FocusEvent e) { }
	override void focusLost(FocusEvent e) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			focusOut();
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
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
			if (.isEnterKey(e.keyCode)) { mixin(S_TRACE);
				enter();
			} else if (e.keyCode == SWT.ESC) { mixin(S_TRACE);
				cancel();
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	@property
	bool isExit() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			return ctrl.isDisposed();
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
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
			if (!ctrl.isDisposed()) { mixin(S_TRACE);
				auto hasFocus = ctrl.isFocusControl();
				auto par = ctrl.getParent();
				ctrl.dispose();
				if (hasFocus && par) { mixin(S_TRACE);
					par.setFocus();
				}
			}
			foreach (dlg; exitEvent) dlg(false);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void cancel() { mixin(S_TRACE);
		if (ctrl && !ctrl.isDisposed()) { mixin(S_TRACE);
			ctrl.dispose();
			foreach (dlg; exitEvent) dlg(true);
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
		printStackTrace();
		debugln(e);
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
			combo.add(s);
		}
		combo.setText(str ? str : "");
		return combo;
	} catch (Exception e) {
		printStackTrace();
		debugln(e);
		throw new Exception(e.msg, __FILE__, __LINE__);
	}
}

/// テーブルを編集可能にする。
/// ダブルクリック、またはF2キーの押下で編集開始。
abstract class AbstractTableEdit {
private:
	Commons _comm;
	Table table;
	TableEditor _editor;
	EditEnd _tee = null;
	int editC;
	bool delegate(TableItem itm, int column) canEdit = null;
	TextEditMFListener _mf = null;

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
			printStackTrace();
			debugln(e);
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
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	void startEdit(Item itm) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			startEdit(cast(TableItem) itm);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void endImpl(Control c) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			end(c);
			_tee = null;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
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
			_editor = new TableEditor(table);
			_editor.grabHorizontal = true;

			_mf = new TextEditMFListener(comm, table, &startEdit, &selectionK, &selectionM);
			table.addMouseListener(_mf);
			table.addSelectionListener(_mf);
			table.addFocusListener(_mf);
			table.addKeyListener(new TextEditKListener(&startEdit, &selectionK));
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
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
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	/// trueの場合はアイテム選択後即座に編集を開始する。
	@property
	void quickStart(bool v) { _mf.quickStart = v; }
	/// ditto
	@property
	const
	bool quickStart() { return _mf.quickStart; }

	void startEdit(TableItem itm) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (!itm.getParent().isFocusControl()) return;
			if (_tee !is null && !_tee.isExit) _tee.enter();
			auto sel = itm;
			if (canEdit is null || canEdit(sel, editC)) { mixin(S_TRACE);
				table.showSelection();
				auto editor = createEditor(sel, editC);
				if (auto t = cast(Text)editor && _mf.quickStart) { mixin(S_TRACE);
					.listener(editor, SWT.KeyDown, (e) { mixin(S_TRACE);
						auto selected = false;
						if (e.keyCode is SWT.ARROW_UP) { mixin(S_TRACE);
							auto index = table.indexOf(sel);
							if (0 < index) { mixin(S_TRACE);
								table.deselectAll();
								table.select(index - 1);
								selected = true;
							}
						} else if (e.keyCode is SWT.ARROW_DOWN) { mixin(S_TRACE);
							auto index = table.indexOf(sel);
							if (index + 1 < table.getItemCount()) { mixin(S_TRACE);
								table.deselectAll();
								table.select(index + 1);
								selected = true;
							}
						}
						if (selected) { mixin(S_TRACE);
							e.doit = false;
							enter();
							auto se = new Event;
							se.type = SWT.Selection;
							se.widget = table;
							se.time = e.time;
							se.stateMask = e.stateMask;
							se.doit = true;
							table.notifyListeners(SWT.Selection, se);
						}
					});
				}
				_tee = new EditEnd(_comm, table, editor, &endImpl, !quickStart);
				_editor.setEditor(_tee.editor, sel, editC);
				_tee.exitEvent ~= exitEvent;
				_tee.setFocus();
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	@property
	bool isEditing() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			return _tee !is null;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	@property
	Control editor() { mixin(S_TRACE);
		return _tee ? _tee.editor : null;
	}
	void enter() { mixin(S_TRACE);
		if (!isEditing) return;
		_tee.enter();
	}
	void cancel() { mixin(S_TRACE);
		if (!isEditing) return;
		_tee.cancel();
	}
	protected Control createEditor(TableItem itm, int editC);
	protected void end(Control c);

	void delegate(bool cancel)[] exitEvent;
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
			printStackTrace();
			debugln(e);
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
			if (auto t = cast(Text)c) { mixin(S_TRACE);
				newText = t.getText();
			} else if (auto t = cast(StyledText)c) { mixin(S_TRACE);
				newText = t.getText();
			} else if (auto t = cast(Combo)c) { mixin(S_TRACE);
				newText = t.getText();
			} else if (auto t = cast(CCombo)c) { mixin(S_TRACE);
				newText = t.getText();
			}
			if (!newText) newText = "";
			if (editEnd is null) { mixin(S_TRACE);
				if (newText.length > 0) { mixin(S_TRACE);
					_editor.getItem().setText(editC, newText);
				}
			} else { mixin(S_TRACE);
				editEnd(_editor.getItem(), editC, newText);
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
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
			printStackTrace();
			debugln(e);
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
				_editor.getItem().setText(editC, combo.getText());
			} else { mixin(S_TRACE);
				editEnd(_editor.getItem(), editC, combo);
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
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
			printStackTrace();
			debugln(e);
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
					_editor.getItem().setText(editC, text);
				} else { mixin(S_TRACE);
					editEnd(_editor.getItem(), editC, c);
				}
			}
			auto spinner = cast(Spinner) c;
			if (spinner) set(spinner.getText());
			auto text = cast(Text)c;
			if (text) set(text.getText());
			auto stext = cast(StyledText)c;
			if (stext) set(stext.getText());
			auto combo = cast(Combo)c;
			if (combo) set(combo.getText());
			auto ccombo = cast(CCombo)c;
			if (ccombo) set(ccombo.getText());
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
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
			printStackTrace();
			debugln(e);
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
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}

	void end(Control ctrl) { mixin(S_TRACE);
		if (!ctrl || ctrl.isDisposed()) return;
		try { mixin(S_TRACE);
			editEnd(editor.getItem(), ctrl);
			_tee = null;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
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
			printStackTrace();
			debugln(e);
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
			printStackTrace();
			debugln(e);
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
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	@property
	bool isEditing() { mixin(S_TRACE);
		try { mixin(S_TRACE);
			return _tee !is null;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			throw new Exception(e.msg, __FILE__, __LINE__);
		}
	}
	void cancel() { mixin(S_TRACE);
		if (!isEditing) return;
		_tee.cancel();
	}
	void enter() { mixin(S_TRACE);
		if (!isEditing) return;
		_tee.enter();
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
	int _vbarPos = -1;
	int _hbarPos = -1;

	void delegate(C card, Control ctrl) _editEnd;
	Control delegate(in C card) _createEditor;

	Item selectionM(int x, int y) { mixin(S_TRACE);
		auto sel = _list.selection;
		if (0 <= sel && _list.getTitleBounds(sel).contains(x, y)) { mixin(S_TRACE);
			return _list.getItem(sel);
		}
		return null;
	}
	Item selectionK() { mixin(S_TRACE);
		auto sel = _list.selection;
		if (0 <= sel) { mixin(S_TRACE);
			return _list.getItem(sel);
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
			_vbarPos = -1;
			_hbarPos = -1;
			layout();
			_tee.setFocus();
		}
	}
	void layout() { mixin(S_TRACE);
		if (!_edit) return;
		auto vbar = _list.getVerticalBar();
		auto hbar = _list.getHorizontalBar();
		auto vPos = vbar ? vbar.getSelection() : -2;
		auto hPos = hbar ? hbar.getSelection() : -2;
		if (_vbarPos == vPos && _hbarPos == hPos) return;
		_vbarPos = vPos;
		_hbarPos = hPos;
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
		auto sel = _list.selection;
		if (0 <= sel) { mixin(S_TRACE);
			startEdit(_list.getItem(sel));
		}
	}
	bool isEditing() { mixin(S_TRACE);
		return _tee !is null;
	}
	void enter() { mixin(S_TRACE);
		if (!isEditing) return;
		_tee.enter();
	}
	void cancel() { mixin(S_TRACE);
		if (!isEditing) return;
		_tee.cancel();
	}
}

bool hasFocus(Control c) { mixin(S_TRACE);
	auto ctrl = Display.getCurrent().getFocusControl();
	if (!ctrl) return false;
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
	void delegate()[] modEvent;

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
			auto b = cast(B)e.widget;
			if (!b.getSelection()) return;
			if (_sel is null) { mixin(S_TRACE);
				_sel = b;
			} else if (b !is _sel) { mixin(S_TRACE);
				_sel.setSelection(false);
				_sel = b;
			}
			foreach (dlg; modEvent) dlg();
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
	return treeItemUD!("i > 0", "i - 1")(itm);
}
int treeItemDown(TreeItem itm) { mixin(S_TRACE);
	return treeItemUD!("i + 1 < parent.getItemCount()", "i + 2")(itm);
}
private int treeItemUD(string SwapOK, string ToIndex)(TreeItem itm) { mixin(S_TRACE);
	auto tree = itm.getParent();
	auto p = itm.getParentItem();
	if (p is null) { mixin(S_TRACE);
		return treeItemUD2!(Tree, SwapOK, ToIndex)(tree, itm);
	} else { mixin(S_TRACE);
		return treeItemUD2!(TreeItem, SwapOK, ToIndex)(p, itm);
	}
}
private int treeItemUD2(T, string SwapOK, string ToIndex)(T parent, TreeItem itm) { mixin(S_TRACE);
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
		cloneItem(ti, itm, cast(int)i);
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

TreeItem anotherTreeItem(Tree anotherTree, TreeItem itm) { mixin(S_TRACE);
	if (anotherTree is itm.getParent()) return itm;
	return fromTreePath(anotherTree, toTreePath(itm));
}

int[] toTreePath(TreeItem itm) { mixin(S_TRACE);
	int[] r;
	while (itm.getParentItem()) { mixin(S_TRACE);
		auto par = itm.getParentItem();
		r ~= par.indexOf(itm);
		itm = par;
	}
	r ~= itm.getParent().indexOf(itm);
	std.algorithm.reverse(r);
	return r;
}

TreeItem fromTreePath(Tree tree, in int[] path) { mixin(S_TRACE);
	if (!path) return null;
	auto itm = tree.getItem(path[0]);
	foreach (index; path[1 .. $]) { mixin(S_TRACE);
		itm = itm.getItem(index);
	}
	return itm;
}

/// cを配置したTreeItemを生成する。
ToolItem createToolItemC(ToolBar bar, Control c, int rightSpace = 0) { mixin(S_TRACE);
	auto ti = new ToolItem(bar, SWT.SEPARATOR);
	ti.setControl(c);
	ti.setWidth(c.computeSize(SWT.DEFAULT, SWT.DEFAULT).x + rightSpace);
	return ti;
}

/// ツールバー上のラベルを生成する。
Label createLabel(ToolBar bar, string label, int rightSpace = 0) { mixin(S_TRACE);
	auto comp = new Composite(bar, SWT.NONE);
	comp.setLayout(new CenterLayout(SWT.VERTICAL, 0));
	auto lbl = new Label(comp, SWT.NONE);
	lbl.setText(label);
	createToolItemC(bar, comp, rightSpace);
	return lbl;
}

/// ツールバー上のスピナを生成する。
Spinner createSpinner(ToolBar bar, string label, int max, int min, int sel,
		void delegate(int value) edit, void delegate(int value) enter, int delegate(int oldVal) cancel, int readOnly) { mixin(S_TRACE);
	createLabel(bar, label ~ ":");
	auto spn = new Spinner(bar, SWT.BORDER | readOnly);
	initSpinner(spn);
	spn.setEnabled(false);
	spn.setMaximum(max);
	spn.setMinimum(min);
	spn.setSelection(sel);
	createToolItemC(bar, spn);
	auto editL = new SpinnerEdit(spn, enter, edit, cancel);
	return spn;
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
	auto font = new Font(Display.getCurrent(), fontData);
	scope (exit) font.dispose();
	.drawCenterTextImpl(font, gc, ca, str);
}
void drawCenterText(in CFont fontData, GC gc, Rectangle ca, string str) { mixin(S_TRACE);
	auto font = .createFontFromPixels(fontData);
	scope (exit) font.dispose();
	.drawCenterTextImpl(font, gc, ca, str);
}
private void drawCenterTextImpl(Font font, GC gc, Rectangle ca, string str) { mixin(S_TRACE);
	auto oldFont = gc.getFont();
	scope (exit) gc.setFont(oldFont);
	gc.setFont(font);
	auto te = gc.wTextExtent(str);
	int x = ca.x + (ca.width - te.x) / 2;
	int y = ca.y + (ca.height - te.y) / 2;
	gc.wDrawText(str, x, y, true);
}

void hemming(GC gc, string s, int tx, int ty, Color color) { mixin(S_TRACE);
	auto d = Display.getCurrent();
	gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
	gc.wDrawText(s, tx - 1, ty, true);
	gc.wDrawText(s, tx, ty - 1, true);
	gc.wDrawText(s, tx + 1, ty, true);
	gc.wDrawText(s, tx, ty + 1, true);
	gc.wDrawText(s, tx - 1, ty - 1, true);
	gc.wDrawText(s, tx - 1, ty + 1, true);
	gc.wDrawText(s, tx + 1, ty - 1, true);
	gc.wDrawText(s, tx + 1, ty + 1, true);
	gc.setForeground(color);
	gc.wDrawText(s, tx, ty, true);
}
ImageData castCardImage(Props prop, Skin skin, in Summary summ, in CastCard c, string sPath, string wsnVer, bool dbgMode) { mixin(S_TRACE);
	auto d = Display.getCurrent();
	auto cardSize = prop.looks.cardSize;
	auto matPad = prop.looks.castCardInsets;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	bool whiteName = false;
	ImageData id;
	if (c.life == 0) { mixin(S_TRACE);
		id = castCardFaint(skin);
		whiteName = true;
	} else if (c.paralyze > prop.looks.stoneBorder) { mixin(S_TRACE);
		id = castCardPetrif(skin);
		whiteName = true;
	} else if (c.paralyze > 0) { mixin(S_TRACE);
		id = castCardParaly(skin);
		whiteName = false;
	} else if (c.bindRound > 0) { mixin(S_TRACE);
		id = castCardBind(skin);
		whiteName = true;
	} else if (c.mentality == Mentality.SLEEP && c.mentalityRound > 0) { mixin(S_TRACE);
		id = castCardSleep(skin);
		whiteName = true;
	} else if (c.life <= c.lifeMax / 5) { mixin(S_TRACE);
		id = castCardDanger(skin);
		whiteName = false;
	} else if (c.life < c.lifeMax) { mixin(S_TRACE);
		id = castCardInjury(skin);
		whiteName = false;
	} else { mixin(S_TRACE);
		id = castCard(skin);
		whiteName = false;
	}
	auto r = new PileImage(id, w, h, true);
	auto stp = prop.looks.castLifeBarPoint;
	if (dbgMode || c.faceUpRound > 0) { mixin(S_TRACE);
		version (Windows) {
			auto levelColor = OS.VERSION(6, 0) <= OS.WIN32_VERSION ? prop.looks.castCardLevelColor : CRGB(128, 128, 128);
		} else {
			auto levelColor = prop.looks.castCardLevelColor;
		}
		r.append(to!(string)(c.level),
			prop.looks.castCardLevelInsets,
			prop.looks.castCardLevelFont(skin.legacy),
			levelColor,
			PileImage.TPos.RIGHT);
	}
	foreach (path; c.paths) { mixin(S_TRACE);
		path.addToPileImage(r, prop, skin, sPath, wsnVer, matPad, ScaleType.Center);
	}
	int stMax = prop.looks.statusVerMax;
	if ((dbgMode || c.faceUpRound > 0) && 0 < c.life) { mixin(S_TRACE);
		auto lgid = lifeGuage(skin);
		int lgw = lgid.width;
		int lgh = lgid.height;
		if (lgw > 1 && lgh > 1) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				lgid.transparentPixel = lgid.getPixel(5, 5); // LIFEGEUAGEは(5, 5)が透過色
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
				printStackTrace();
				debugln(e);
			}
		}
	}
	stp.x = prop.looks.statusX;
	stp.y -= 3;
	int styf = stp.y;
	int stc = 0;
	auto showSleepAndBind = prop.var.etc.showStatusTime is ShowStatusTime.Always
		|| (prop.var.etc.showStatusTime is ShowStatusTime.WithSkin && !skin.legacy);
	auto showStatusTime = showSleepAndBind && (dbgMode || 0 < c.faceUpRound);

	ImageData putNumber(ImageData id, uint number, RGB backColor = null) { mixin(S_TRACE);
		auto bmp = new Image(d, id.width, id.height);
		scope (exit) bmp.dispose();
		auto gc = new GC(bmp);
		scope (exit) gc.dispose();
		auto img = new Image(d, id);
		scope (exit) img.dispose();
		if (backColor) { mixin(S_TRACE);
			auto color = new Color(d, backColor);
			scope (exit) color.dispose();
			gc.setBackground(color);
			gc.fillRectangle(0, 0, id.width, id.height);
		}
		gc.drawImage(img, 0, 0);
		auto font = .createFontFromPixels(prop.looks.statusTimeFont(skin.legacy, number));
		scope (exit) font.dispose();
		gc.setFont(font);
		string s = to!(string)(number);
		auto cw = gc.wTextExtent(s).x;
		auto mt = gc.getFontMetrics();
		auto tx = id.width - cw - 1;
		auto ty = id.height - mt.getAscent() - 2;
		hemming(gc, s, tx, ty, d.getSystemColor(SWT.COLOR_WHITE));
		return bmp.getImageData();
	}
	void status(ImageData id, uint number, RGB backColor = null) { mixin(S_TRACE);
		if (showStatusTime) { mixin(S_TRACE);
			id = putNumber(id, number, backColor);
		}
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
		case Mentality.SLEEP:
			if (showSleepAndBind) goto case Mentality.CONFUSE;
			break;
		case Mentality.CONFUSE, Mentality.OVERHEAT, Mentality.BRAVE, Mentality.PANIC: { mixin(S_TRACE);
			status(mentality(skin, c.mentality), c.mentalityRound);
		} break;
		default: assert (0);
		}
	}
	if (c.poison > 0) status(poison(skin), c.poison);
	if (c.paralyze > 0 && showSleepAndBind) status(paralyze(skin), c.paralyze);
	if (c.bindRound > 0 && showSleepAndBind) status(bind(skin), c.bindRound);
	if (c.silenceRound > 0) status(silence(skin), c.silenceRound);
	if (c.faceUpRound > 0) status(faceUp(skin), c.faceUpRound);
	if (c.antiMagicRound > 0) status(antiMagic(skin), c.antiMagicRound);
	void enh(Enhance enh) { mixin(S_TRACE);
		auto value = c.enhance(enh);
		auto round = c.enhanceRound(enh);
		void put(ImageData iData, in CRGB crgb) { mixin(S_TRACE);
			int alpha;
			auto rgb = .dwtData(crgb, alpha);
			if (showStatusTime) { mixin(S_TRACE);
				status(iData, round, rgb);
			} else { mixin(S_TRACE);
				auto id = new ImageData(iData.width, iData.height, 1, new PaletteData([rgb, new RGB(0, 0, 0)]));
				r.append(id, stp, ScaleType.Cut);
				status(iData, round);
			}
		}
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
			put(enhanceUp(skin, enh), back);
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
			put(enhanceDown(skin, enh), back);
		}
	}
	enh(Enhance.ACTION);
	enh(Enhance.AVOID);
	enh(Enhance.RESIST);
	enh(Enhance.DEFENSE);
	int beastCountMax = prop.looks.beastCardMaxNum(c.level);
	int beastCount = 0;
	foreach (b; c.beasts) { mixin(S_TRACE);
		uint useLimit;
		if (summ && 0 != b.linkId) { mixin(S_TRACE);
			auto b2 = summ.beast(b.linkId);
			if (!b2) continue;
			useLimit = b2.useLimit;
		} else { mixin(S_TRACE);
			useLimit = b.useLimit;
		}
		if (0 < useLimit) { mixin(S_TRACE);
			beastCount++;
			if (beastCount >= beastCountMax) break;
		}
	}
	if (beastCount > 0) { mixin(S_TRACE);
		auto bid = summon(skin);
		bid = putNumber(bid, beastCount);
		r.append(bid, stp, ScaleType.Cut);
	}
	auto x = prop.looks.castCardNamePoint.x;
	r.setTitle(c.name, prop.looks.castCardNameFont(skin.legacy), dwtData(prop.looks.castCardNamePoint),
		skin.legacy ? 0 : w - x * 2, !skin.legacy);
	if (skin.legacy) { mixin(S_TRACE);
		// 状態によって固定で文字が白くなる
		if (whiteName) { mixin(S_TRACE);
			r.titleColor = new RGB(255, 255, 255);
		}
	} else { mixin(S_TRACE);
		if (getRGBAverage(id, prop.looks.castCardNameArea) < prop.var.etc.negativeCardNameBorder) { mixin(S_TRACE);
			r.titleColor = new RGB(255, 255, 255);
		}
	}
	return r.createImageData();
}

void addToPileImage(in CardImage img, PileImage pile, Props prop, Skin skin, string sPath, string wsnVer, CInsets matPad, ScaleType type) { mixin(S_TRACE);
	final switch (img.type) {
	case CardImageType.PCNumber:
		if (0 < img.pcNumber) { mixin(S_TRACE);
			auto font = prop.looks.pcNumberFont(skin.legacy);
			font.point /= 2;
			pile.append(dwtData(font), .text(img.pcNumber), prop.looks.menuCardInsets);
		}
		break;
	case CardImageType.File:
		auto path = skin.findImagePath(img.path, sPath, wsnVer);
		if (path != "") { mixin(S_TRACE);
			final switch (img.positionType) {
			case CardImagePosition.Center:
				pile.append(path, matPad, ScaleType.Center, true);
				break;
			case CardImagePosition.TopLeft:
				pile.append(path, matPad, ScaleType.Cut, true);
				break;
			case CardImagePosition.Default:
				pile.append(path, matPad, type, true);
				break;
			}
		}
		break;
	case CardImageType.Talker:
		final switch (img.talker) {
		case Talker.SELECTED:
		case Talker.UNSELECTED:
		case Talker.RANDOM:
		case Talker.VALUED:
			pile.append(prop.images.talker(img.talker).getImageData(), matPad, type, true);
			break;
		case Talker.CARD:
			auto cRect = prop.looks.cardSize;
			auto tImg = menuCard(skin).scaledTo(cRect.width, cRect.height);
			pile.append(tImg, CInsets(0, 0, 0, 0), type, false);
			break;
		}
		break;
	}
}

ImageData cardImage(C)(Props prop, Skin skin, in C base, string sPath, string wsnVer, CastCard owner, const(C) delegate(ulong) get, bool detail, bool preview) { mixin(S_TRACE);
	static if (is (C == SkillCard)) {
		bool hold = base.hold;
		auto card = skillCard(skin);
	} else static if (is (C == ItemCard)) {
		bool hold = base.hold;
		auto card = itemCard(skin);
	} else static if (is (C == BeastCard)) {
		ImageData card;
		if (base.isOption) { mixin(S_TRACE);
			// 付帯能力
			card = optionCard(skin);
		} else { mixin(S_TRACE);
			// 一般の召喚獣カード
			card = beastCard(skin);
		}
	} else static if (is (C == InfoCard)) {
		auto card = infoCard(skin);
	} else { mixin(S_TRACE);
		static assert (0);
	}
	bool link = false;
	bool noData = false;
	Rebindable!(const(C)) c = base;
	static if (is(typeof(base.linkId))) {
		if (get && 0 != base.linkId) { mixin(S_TRACE);
			link = true;
			c = get(c.linkId);
			if (!c) { mixin(S_TRACE);
				c = new C(1UL, "", [], "");
				noData = true;
			}
		}
	}
	auto cardSize = prop.looks.cardSize;
	auto matPad = prop.looks.cardInsets;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	scope r = new PileImage(card, w, h, true);
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
		if (prop.var.etc.showSkillCardLevel && !noData) { mixin(S_TRACE);
			version (Windows) {
				auto levelColor = OS.VERSION(6, 0) <= OS.WIN32_VERSION ? prop.looks.skillCardLevelColor : CRGB(128, 128, 128);
			} else {
				auto levelColor = prop.looks.skillCardLevelColor;
			}
			r.append(to!(string)(c.level),
				prop.looks.skillCardLevelInsets,
				prop.looks.skillCardLevelFont(skin.legacy),
				levelColor,
				PileImage.TPos.RIGHT);
		}
	}
	foreach (path; c.paths) { mixin(S_TRACE);
		path.addToPileImage(r, prop, skin, sPath, wsnVer, matPad, ScaleType.Cut);
	}
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
	auto x = prop.looks.cardNamePoint.x;
	r.setTitle(c.name, prop.looks.cardNameFont(skin.legacy), dwtData(prop.looks.cardNamePoint),
		skin.legacy ? 0 : w - x * 2, !skin.legacy);
	if (!skin.legacy) { mixin(S_TRACE);
		if (getRGBAverage(card, prop.looks.cardNameArea) < prop.var.etc.negativeCardNameBorder) { mixin(S_TRACE);
			r.titleColor = new RGB(255, 255, 255);
		}
	}

	static if (is(C : ItemCard) || is(C : BeastCard)) {
		bool res = prop.sys.isRecycle(c.keyCodes);
		static if (is(C : ItemCard)) {
			auto ul = c.useLimitMax;
		} else static if (is(C : BeastCard)) {
			auto ul = c.useLimit;
		} else static assert (0);
		if (ul > 0 || res) { mixin(S_TRACE);
			auto d = Display.getCurrent();
			auto imgData = r.createImageData();
			auto img = new Image(d, imgData);
			scope (exit) img.dispose();
			auto gc = new GC(img);
			scope (exit) gc.dispose();
			auto font = .createFontFromPixels(prop.looks.useCountFont(skin.legacy));
			scope (exit) font.dispose();
			gc.setFont(font);
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

/// cardの指定領域のRGB平均値を返す。
ubyte getRGBAverage(ImageData card, CRect nameArea) { mixin(S_TRACE);
	ulong rgbs = 0;
	if (card.width < nameArea.x + nameArea.width || card.height < nameArea.y + nameArea.height) return 255;
	if (16 <= card.depth) { mixin(S_TRACE);
		auto px = Pixels(cast(ubyte[])card.data, [], card.width, card.height, card.depth, card.bytesPerLine, card.bytesPerLine / card.width);
		size_t i = 0;
		foreach (x; nameArea.x .. nameArea.x + nameArea.width) { mixin(S_TRACE);
			foreach (y; nameArea.y .. nameArea.y + nameArea.height) { mixin(S_TRACE);
				auto fc = px.get(x, y);
				rgbs += fc.r;
				rgbs += fc.g;
				rgbs += fc.b;
			}
		}
	} else { mixin(S_TRACE);
		auto pixels = new ubyte[nameArea.width];
		foreach (y; nameArea.y .. nameArea.y + nameArea.height) { mixin(S_TRACE);
			card.getPixels(nameArea.x, y, cast(int)pixels.length, cast(byte[])pixels, 0);
			foreach (i, pixel; pixels) { mixin(S_TRACE);
				auto rgb = card.palette.getRGB(pixel);
				rgbs += rgb.red;
				rgbs += rgb.green;
				rgbs += rgb.blue;
			}
		}
	}
	return cast(ubyte)(rgbs / (nameArea.width * nameArea.height * 3));
}

/// 使用時イベントのマークを描画する。
void putEventTree(C:EventTreeOwner)(Control canvas, GC gc, Props prop, in Summary summ, bool showMark, in C c, Rectangle bounds) { mixin(S_TRACE);
	if (!prop.var.etc.showEventTreeMark || !showMark) return;

	Rebindable!(const C) c2;
	if (c.linkId == 0) { mixin(S_TRACE);
		c2 = c;
	} else { mixin(S_TRACE);
		static if (is(C:SkillCard)) {
			auto c3 = summ.skill(c.linkId);
		} else static if (is(C:ItemCard)) {
			auto c3 = summ.item(c.linkId);
		} else static if (is(C:BeastCard)) {
			auto c3 = summ.beast(c.linkId);
		} else static assert (0);
		if (c3 is null) return;
		c2 = c3;
	}

	auto res = prop.sys.isRecycle(c2.keyCodes);
	static if (is(C:ItemCard)) {
		bool useCount = 0 < c2.useLimitMax || res;
	} else static if (is(C:BeastCard)) {
		bool useCount = 0 < c2.useLimit || res;
	} else { mixin(S_TRACE);
		bool useCount = false;
	}

	auto d = canvas.getDisplay();
	auto curPos = canvas.toControl(d.getCursorLocation());

	auto et = useCount ? prop.looks.eventTreeXYWithCount : prop.looks.eventTreeXY;
	auto hasEventTree = prop.var.etc.ignoreEmptyStart ? !c2.isEmpty : 0 < c2.trees.length;
	if ((prop.var.etc.showEventTreeMarkAlways && bounds.contains(curPos)) || hasEventTree) { mixin(S_TRACE);
		auto img = hasEventTree ? prop.images.eventTree : prop.images.eventTreeEmpty;
		gc.drawImage(img, bounds.x + prop.s(et.x), bounds.y + prop.s(et.y));
	}
}

Rectangle eventTreeMarkRect(C:EventTreeOwner)(Props prop, bool showMark, int left, int top, in Summary summ, in C c) { mixin(S_TRACE);
	if (!prop.var.etc.showEventTreeMark || !showMark) return null;

	Rebindable!(const C) c2;
	if (c.linkId == 0) { mixin(S_TRACE);
		c2 = c;
	} else { mixin(S_TRACE);
		static if (is(C:SkillCard)) {
			auto c3 = summ.skill(c.linkId);
		} else static if (is(C:ItemCard)) {
			auto c3 = summ.item(c.linkId);
		} else static if (is(C:BeastCard)) {
			auto c3 = summ.beast(c.linkId);
		} else static assert (0);
		if (c3 is null) return null;
		c2 = c3;
	}

	auto res = prop.sys.isRecycle(c2.keyCodes);
	static if (is(C:ItemCard)) {
		bool useCount = 0 < c2.useLimitMax || res;
	} else static if (is(C:BeastCard)) {
		bool useCount = 0 < c2.useLimit || res;
	} else { mixin(S_TRACE);
		bool useCount = false;
	}

	auto et = useCount ? prop.looks.eventTreeXYWithCount : prop.looks.eventTreeXY;
	if (prop.var.etc.showEventTreeMarkAlways || (prop.var.etc.ignoreEmptyStart ? !c2.isEmpty : 0 < c2.trees.length)) { mixin(S_TRACE);
		auto bounds = prop.images.eventTreeNoScale.getBounds();
		bounds.x = left + prop.s(et.x);
		bounds.y = top + prop.s(et.y);
		bounds.width = prop.s(bounds.width);
		bounds.height = prop.s(bounds.height);
		return bounds;
	}
	return null;
}

string[] castCoupons(Commons comm, bool talker, string legacyName, bool getLose, bool forValued) { mixin(S_TRACE);
	string[] r;
	if (!talker) { mixin(S_TRACE);
		if (!forValued && comm.prop.var.etc.standardCoupons.length) { mixin(S_TRACE);
			foreach (c; comm.prop.var.etc.standardCoupons) { mixin(S_TRACE);
				r ~= comm.skin.replaceSystemCouponName(comm.prop.sys, c);
			}
		}
		if (comm.prop.isTargetVersion(comm.summary, "2")) { mixin(S_TRACE);
			if (!getLose) { mixin(S_TRACE);
				r ~= comm.prop.sys.userCoupon;
				r ~= comm.prop.sys.eventTargetCoupon;
			}
			r ~= comm.prop.sys.effectTargetCoupon;
			if (!getLose) { mixin(S_TRACE);
				r ~= comm.prop.sys.effectOutOfTargetCoupon;
			}
		}
	}
	foreach (e; comm.skin.allSexes) { mixin(S_TRACE);
		r ~= comm.skin.sexCoupon(e);
	}
	foreach (e; comm.skin.allPeriods) { mixin(S_TRACE);
		r ~= comm.skin.periodCoupon(e);
	}
	if (comm.prop.var.etc.showSpNature) { mixin(S_TRACE);
		foreach (e; comm.skin.allNatures) { mixin(S_TRACE);
			r ~= comm.skin.natureCoupon(e);
		}
	} else { mixin(S_TRACE);
		foreach (e; comm.skin.normalNatures) { mixin(S_TRACE);
			r ~= comm.skin.natureCoupon(e);
		}
	}
	foreach (e; comm.skin.leftMakings) { mixin(S_TRACE);
		r ~= comm.skin.makingsCoupon(e);
		r ~= comm.skin.makingsCoupon(comm.skin.reverseMakings(e));
	}
	if (!talker && forValued && comm.prop.var.etc.standardCouponsForValued.length) { mixin(S_TRACE);
		foreach (c; comm.prop.var.etc.standardCouponsForValued) { mixin(S_TRACE);
			r ~= comm.skin.replaceSystemCouponName(comm.prop.sys, c);
		}
	}
	return r;
}

bool qMaterialCopy(Commons comm, Shell shell, UseCounter uc, string toSPath, string fromSPath,
		out bool copy, bool toIsLegacy, string delegate(in IPathUser) exportedImageName) { mixin(S_TRACE);
	auto prop = comm.prop;
	auto skin = comm.skin;
	copy = false;
	string[] paths;
	foreach (key; uc.path.keys) { mixin(S_TRACE);
		string path = cast(string)key;
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
	if (bin) { mixin(S_TRACE);
		if (!toIsLegacy || prop.var.etc.saveInnerImagePath) { mixin(S_TRACE);
			if (toIsLegacy) { mixin(S_TRACE);
				binImgToRef = question(prop.msgs.dlgMsgCopyMaterial1);
			} else { mixin(S_TRACE);
				binImgToRef = question(prop.msgs.dlgMsgExcludeImage);
			}
		} else { mixin(S_TRACE);
			binImgToRef = false;
		}
	}
	if (!cancel) { mixin(S_TRACE);
		if (msgPaths.length) { mixin(S_TRACE);
			if (1 == msgPaths.length) { mixin(S_TRACE);
				copyMates = question(.tryFormat(prop.msgs.dlgMsgCopyMaterial2, msgPaths[0]));
			} else { mixin(S_TRACE);
				copyMates = question(.tryFormat(prop.msgs.dlgMsgCopyMaterial3, msgPaths.length));
			}
		}
	}
	if (!cancel) { mixin(S_TRACE);
		bool err = false;
		foreach (i, key; paths) { mixin(S_TRACE);
			// ファイルのコピーと参照の更新
			if (!isBinImg(key) && !copyMates) continue;
			string path = isBinImg(key) ? key : std.path.buildPath(fromSPath, key);
			try { mixin(S_TRACE);
				auto users = uc.values(toPathId(key));
				auto exportedName = "";
				if (binImgToRef) { mixin(S_TRACE);
					if (1 < users.length) { mixin(S_TRACE);
						Tuple!(PathUser, "u", string[], "cwxPath")[] users2;
						foreach (u; users) { mixin(S_TRACE);
							users2 ~= typeof(users2[0])(u, .cpsplit(u.cwxPath(true)));
						}
						static bool pcmp(typeof(users2[0]) a, typeof(users2[0]) b) { mixin(S_TRACE);
							return .cpcmp(a.cwxPath, b.cwxPath) < 0;
						}
						foreach (u; std.algorithm.sort!pcmp(users2)) { mixin(S_TRACE);
							exportedName = exportedImageName(u.u);
							break;
						}
					} else { mixin(S_TRACE);
						exportedName = exportedImageName(users[0]);
					}
				}
				auto newp = copyTo(toSPath, path, skin.materialPath, binImgToRef, exportedName);
				if (!isBinImg(newp) && key != newp) { mixin(S_TRACE);
					uc.change(toPathId(key), toPathId(newp));
				}
				copy = true;
			} catch (Exception e) {
				printStackTrace();
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
		static class SaveColumnWidth : ControlAdapter {
			Props prop;
			this(Props prop) { mixin(S_TRACE);
				this.prop = prop;
			}
			override void controlResized(ControlEvent e) { mixin(S_TRACE);
				int width = (cast(TableColumn)e.widget).getWidth();
				mixin (Value ~ " = width;");
			}
		}
		col.addControlListener(new SaveColumnWidth(prop));
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
	comp.setLayout(normalGridLayout(3, false));
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
	sp.resizeControl1 = sash.resizeControl1;
	sp.canMinimized1 = sash.canMinimized1;
	sp.canMinimized2 = sash.canMinimized2;
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
			auto bdata = cast(ubyte[])data.data;
			auto alpha = cast(ubyte[])data.alphaData;
			data.data = cast(byte[])cwx.graphics.smoothResize(wi, hi, bdata, alpha,
				data.depth, data.width, data.height, data.bytesPerLine, bpl);
			data.alphaData = cast(byte[])alpha;
			data.width = wi;
			data.height = hi;
			data.bytesPerLine = cast(int)bpl;
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
void initTree(Commons comm, Tree tree, bool eventTree, bool hideRootLine = true, bool delegate() classicStyleTree = null) { mixin(S_TRACE);
	version (Windows) {
		if (eventTree) { mixin(S_TRACE);
			Listener keyDown = null, mouseDoubleClick = null, collapse = null;
			bool oldVal = classicStyleTree ? classicStyleTree() : comm.prop.var.etc.classicStyleTree;
			void updateTreeStyleImpl(bool newVal) { mixin(S_TRACE);
				auto style = OS.GetWindowLong(tree.handle, GWL_STYLE);
				style |= OS.TVS_HASLINES;
				oldVal = newVal;
				if (newVal) { mixin(S_TRACE);
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
			void updateTreeStyle() { mixin(S_TRACE);
				bool newVal = classicStyleTree ? classicStyleTree() : comm.prop.var.etc.classicStyleTree;
				if (oldVal is newVal) return;
				updateTreeStyleImpl(newVal);
			}
			comm.refEventTreeStyle.add(&updateTreeStyle);
			.listener(tree, SWT.Dispose, { mixin(S_TRACE);
				comm.refEventTreeStyle.remove(&updateTreeStyle);
			});
			updateTreeStyleImpl(oldVal);
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
					printStackTrace();
					debugln(e);
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

@property
int ppis(int value) { mixin(S_TRACE);
	return value * dpiMuls;
}
@property
int dpiMuls() { mixin(S_TRACE);
	auto d = Display.getCurrent();
	auto dpi = d.getDPI().x;
	immutable base = 96;
	auto exp = 2;
	while (base * exp <= dpi) { mixin(S_TRACE);
		exp *= 2;
	}
	return exp / 2;
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

GridLayout normalGridLayout(int col, bool eqWid = false) { mixin(S_TRACE);
	auto gl = new GridLayout(col, eqWid);
	auto spacing = gl.horizontalSpacing;
	gl.horizontalSpacing = spacing.ppis;
	gl.verticalSpacing = spacing.ppis;
	gl.marginWidth = spacing.ppis;
	gl.marginHeight = spacing.ppis;
	return gl;
}

const WGL_SPACING = 2;

GridLayout windowGridLayout(int col, bool eqWid = false) { mixin(S_TRACE);
	auto gl = new GridLayout(col, eqWid);
	gl.horizontalSpacing = WGL_SPACING.ppis;
	gl.verticalSpacing = WGL_SPACING.ppis;
	gl.marginWidth = WGL_SPACING.ppis;
	gl.marginHeight = WGL_SPACING.ppis;
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

bool playBGMCW(Props prop, string path, uint fadeIn, uint volume, uint loopCount, bool legacy) { mixin(S_TRACE);
	version (Windows) {} else {immutable SOUND_TYPE_MCI = -1;}
	.stopBGM();
	int playType = prop.var.etc.soundPlayType;
	.bgmVolume = (prop.var.etc.bgmVolume * volume) / 100;
	switch (playType) {
	case SOUND_TYPE_SDL: playBGM(path, fadeIn, loopCount, SOUND_TYPE_SDL, !legacy); return true;
	case SOUND_TYPE_MCI:
		version (Windows) {
			playBGM(path, fadeIn, loopCount, SOUND_TYPE_MCI, !legacy);
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
			version (Windows) {
				if (.canPlayBass(path)) { mixin(S_TRACE);
					type = SOUND_TYPE_BASS;
				}
			}
		}
		playBGM(path, fadeIn, loopCount, type, !legacy);
		return true;
	}
}

void playSECW(Props prop, string path, uint fadeIn, uint volume, uint loopCount, bool legacy) { mixin(S_TRACE);
	version (Windows) {} else {immutable SOUND_TYPE_MCI = -1;}
	.stopSE();
	int type = prop.var.etc.soundEffectPlayType;
	if (SOUND_TYPE_SAME_BGM == type) { mixin(S_TRACE);
		type = prop.var.etc.soundPlayType;
	}
	.seVolume = (prop.var.etc.seVolume * volume) / 100;
	switch (type) {
	case SOUND_TYPE_SDL: playSE(path, fadeIn, loopCount, SOUND_TYPE_SDL, !legacy); break;
	case SOUND_TYPE_MCI:
		version (Windows) {
			playSE(path, fadeIn, loopCount, SOUND_TYPE_MCI, !legacy);
			break;
		} else { mixin(S_TRACE);
			goto default;
		}
	case SOUND_TYPE_APP: Program.launch(path); break;
	default:
		// auto
		type = SOUND_TYPE_MCI;
		version (Windows) {
			if (.canPlayBass(path)) { mixin(S_TRACE);
				type = SOUND_TYPE_BASS;
			}
		}
		playSE(path, fadeIn, loopCount, type, !legacy);
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
	return gc.wTextExtent(text).x / gc.wTextExtent(" ").x;
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
		int mx = .max(c, b);
		int mn = .min(c, b);
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
	} else static if (is(A : cwx.flag.Flag)) {
		return prop.msgs.flag;
	} else static if (is(A : Step)) {
		return prop.msgs.step;
	} else static assert (0);
}

string objNameFrom(in Props prop, in CWXPath path) { mixin(S_TRACE);
	if (cast(Area)path) { mixin(S_TRACE);
		return prop.msgs.area;
	} else if (cast(Battle)path) { mixin(S_TRACE);
		return prop.msgs.battle;
	} else if (cast(Package)path) { mixin(S_TRACE);
		return prop.msgs.cwPackage;
	} else if (cast(CastCard)path) { mixin(S_TRACE);
		return prop.msgs.cwCast;
	} else if (cast(SkillCard)path) { mixin(S_TRACE);
		return prop.msgs.skill;
	} else if (cast(ItemCard)path) { mixin(S_TRACE);
		return prop.msgs.item;
	} else if (cast(BeastCard)path) { mixin(S_TRACE);
		return prop.msgs.beast;
	} else if (cast(InfoCard)path) { mixin(S_TRACE);
		return prop.msgs.info;
	} else if (cast(cwx.flag.Flag)path) { mixin(S_TRACE);
		return prop.msgs.flag;
	} else if (cast(Step)path) { mixin(S_TRACE);
		return prop.msgs.step;
	} else assert (0);
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
	CardImage,
	CardImages,
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
	static if (CIDKind.Area == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectArea;
		noID = comm.prop.msgs.noArea;
		use = 0 != id;
		auto a = summ ? summ.area(id) : null;
		find = () => a !is null;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Battle == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectBattle;
		noID = comm.prop.msgs.noBattle;
		use = 0 != id;
		auto a = summ ? summ.battle(id) : null;
		find = () => a !is null;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Package == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectPackage;
		noID = comm.prop.msgs.noPackage;
		use = 0 != id;
		auto a = summ ? summ.cwPackage(id) : null;
		find = () => a !is null;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Cast == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectCast;
		noID = comm.prop.msgs.noCast;
		use = 0 != id;
		auto a = summ ? summ.cwCast(id) : null;
		find = () => a !is null;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Skill == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectSkill;
		noID = comm.prop.msgs.noSkill;
		auto a = summ ? summ.skill(id) : null;
		find = () => a !is null;
		use = 0 != id;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Item == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectItem;
		noID = comm.prop.msgs.noItem;
		auto a = summ ? summ.item(id) : null;
		find = () => a !is null;
		use = 0 != id;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Beast == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectBeast;
		noID = comm.prop.msgs.noBeast;
		auto a = summ ? summ.beast(id) : null;
		find = () => a !is null;
		use = 0 != id;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Info == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectInfo;
		noID = comm.prop.msgs.noInfo;
		auto a = summ ? summ.info(id) : null;
		find = () => a !is null;
		use = 0 != id;
		name = a ? .tryFormat(comm.prop.msgs.nameWithID, id, a.name) : "";
	} else static if (CIDKind.Image == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectImage;
		noID = comm.prop.msgs.noImage;
		find = { mixin(S_TRACE);
			if (summ) { mixin(S_TRACE);
				return comm.skin.findImagePath(id, summ.scenarioPath, summ.dataVersion).length > 0;
			} else { mixin(S_TRACE);
				return comm.skin.findImagePath(id, "", LATEST_VERSION).length > 0;
			}
		};
		use = id && id.length;
		name = id;
	} else static if (CIDKind.CardImage == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectImage;
		noID = comm.prop.msgs.noImage;
		final switch (id.type) {
		case CardImageType.File:
			name = contentTextUseID!(CIDKind.Image)(comm, summ, id.path, "%s", evt);
			use = id.path != "";
			find = { mixin(S_TRACE);
				if (summ) { mixin(S_TRACE);
					return comm.skin.findImagePath(id.path, summ.scenarioPath, summ.dataVersion).length > 0;
				} else { mixin(S_TRACE);
					return comm.skin.findImagePath(id.path, "", LATEST_VERSION).length > 0;
				}
			};
			break;
		case CardImageType.PCNumber:
			goto case CardImageType.File; // 非対応
		case CardImageType.Talker:
			final switch (id.talker) {
			case Talker.SELECTED:
			case Talker.UNSELECTED:
			case Talker.RANDOM:
			case Talker.CARD:
			case Talker.VALUED:
				name = comm.prop.msgs.talkerName(id.talker);
				use = true;
				find = () => true;
				break;
			}
			break;
		}
	} else static if (CIDKind.CardImages == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectImage;
		noID = comm.prop.msgs.noImage;
		string[] paths;
		use = false;
		if (id.length) { mixin(S_TRACE);
			foreach (path; id) { mixin(S_TRACE);
				paths ~= contentTextUseID!(CIDKind.CardImage)(comm, summ, path, "%s", evt);

				final switch (path.type) {
				case CardImageType.File:
					use |= path.path != "";
					break;
				case CardImageType.PCNumber:
					// 非対応
					break;
				case CardImageType.Talker:
					use = true;
					break;
				}
			}
		} else { mixin(S_TRACE);
			// 一件も指定が無い場合は話者無しメッセージ
			use = true;
		}
		find = { mixin(S_TRACE);
			foreach (path; id) { mixin(S_TRACE);
				final switch (path.type) {
				case CardImageType.File:
					if (summ) { mixin(S_TRACE);
						return comm.skin.findImagePath(path.path, summ.scenarioPath, summ.dataVersion).length > 0;
					} else { mixin(S_TRACE);
						return comm.skin.findImagePath(path.path, "", LATEST_VERSION).length > 0;
					}
				case CardImageType.PCNumber:
					// 非対応
					break;
				case CardImageType.Talker:
					return true;
				}
			}
			return false;
		};
		name = std.string.join(paths, " ");
	} else static if (CIDKind.BGM == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectBGM;
		noID = comm.prop.msgs.noBGM;
		find = { mixin(S_TRACE);
			if (summ) { mixin(S_TRACE);
				return comm.skin.findPath(id, comm.skin.extBgm, comm.skin.bgmDirs, summ.scenarioPath, summ.dataVersion, comm.skin.wsnMusicDirs(summ.dataVersion)).length > 0;
			} else { mixin(S_TRACE);
				return comm.skin.findPath(id, comm.skin.extBgm, comm.skin.bgmDirs, "", LATEST_VERSION, comm.skin.wsnMusicDirs(LATEST_VERSION)).length > 0;
			}
		};
		use = id && id.length;
		name = id;
	} else static if (CIDKind.SE == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectSE;
		noID = comm.prop.msgs.noSE;
		find = { mixin(S_TRACE);
			if (summ) { mixin(S_TRACE);
				return comm.skin.findPath(id, comm.skin.extSound, comm.skin.seDirs, summ.scenarioPath, summ.dataVersion, comm.skin.wsnSoundDirs(summ.dataVersion)).length > 0;
			} else { mixin(S_TRACE);
				return comm.skin.findPath(id, comm.skin.extSound, comm.skin.seDirs, "", LATEST_VERSION, comm.skin.wsnSoundDirs(LATEST_VERSION)).length > 0;
			}
		};
		use = id && id.length;
		name = id;
	} else static if (CIDKind.Flag == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectFlag;
		noID = comm.prop.msgs.noFlag;
		find = () => summ && summ.flagDirRoot.findFlag(id) !is null;
		use = id && id.length;
		name = id;
	} else static if (CIDKind.Step == Kind) { mixin(S_TRACE);
		noSelect = comm.prop.msgs.noSelectStep;
		noID = comm.prop.msgs.noStep;
		find = () => summ && summ.flagDirRoot.findStep(id) !is null;
		use = id && id.length;
		name = id;
	} else static if (CIDKind.Start == Kind) { mixin(S_TRACE);
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
		static if (CIDKind.CardImages == Kind) {
			// 配列なので個別の生成結果を統合したものを表示
			return .tryFormat(msg, name);
		} else static if (CIDKind.CardImage == Kind) {
			return .tryFormat(msg, .tryFormat(noID, .encodePath(id.path)));
		} else {
			return .tryFormat(msg, .tryFormat(noID, id));
		}
	}
}

string rangeName(in Props prop, Range range, string coupon) { mixin(S_TRACE);
	if (range is Range.COUPON_HOLDER) { mixin(S_TRACE);
		if (coupon == "") { mixin(S_TRACE);
			return prop.msgs.rangeWithNoCoupon;
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.rangeWithCoupon, coupon);
		}
	} else { mixin(S_TRACE);
		return prop.msgs.rangeName(range);
	}
}

string contentText(Commons comm, in Content evt, Summary summ) { mixin(S_TRACE);
	string loseCardCount() { mixin(S_TRACE);
		return evt.cardNumber == 0 ? comm.prop.msgs.ctLoseCardAll : .tryFormat(comm.prop.msgs.ctLoseCardCount, evt.cardNumber);
	}
	@property
	string bgImageString() { mixin(S_TRACE);
		if (!evt.backs.length) {
			return comm.prop.msgs.cellNoSet;
		}
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
		string tt = .rangeName(comm.prop, evt.range, evt.holdingCoupon);
		int tl = evt.signedLevel;
		string tet = comm.prop.msgs.effectTypeName(evt.effectType);
		string tr = comm.prop.msgs.resistName(evt.resist);
		string tsf = evt.successRate >= 0 ? "+" : "-";
		int ts = std.math.abs(evt.successRate);
		string tsnd = contentTextUseID!(CIDKind.SE)(comm, summ, evt.soundPath, comm.prop.msgs.ctEffectSound, evt);
		string tcv = comm.prop.msgs.cardVisualName(evt.cardVisual);
		string teff = evt.motions ? "" : comm.prop.msgs.noEffect;
		foreach (i, m; evt.motions) { mixin(S_TRACE);
			teff ~= .tryFormat(comm.prop.msgs.ctEffectMotion, comm.prop.msgs.motionName(m.type));
			if (i + 1 < evt.motions.length) teff ~= " ";
		}
		auto ignite = evt.ignite ? comm.prop.msgs.igniteTrue : comm.prop.msgs.igniteFalse;
		string keyCode;
		if (evt.keyCodes.length) { mixin(S_TRACE);
			string keyCodes = "";
			foreach (i, kc; evt.keyCodes) { mixin(S_TRACE);
				if (0 < i) keyCodes ~= " ";
				keyCodes ~= kc;
			}
			keyCode = .tryFormat(comm.prop.msgs.ctKeyCodes, keyCodes);
		} else {
			keyCode = comm.prop.msgs.ctNoKeyCode;
		}
		if (evt.refAbility) { mixin(S_TRACE);
			auto p = comm.prop.msgs.physicalName(evt.physical);
			auto m = comm.prop.msgs.mentalName(evt.mental);
			return .tryFormat(comm.prop.msgs.ctEffectRefAbility, tt, tet, tr, tsf, ts, tsnd, tcv, teff, m, p, ignite, keyCode);
		} else { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctEffect, tt, tl, tet, tr, tsf, ts, tsnd, tcv, teff, ignite, keyCode);
		}
	} case CType.EFFECT_BREAK: { mixin(S_TRACE);
		return evt.consumeCard ? comm.prop.msgs.ctEffectBreakConsumeCard : comm.prop.msgs.ctEffectBreakNoConsumeCard;
	} case CType.LINK_START: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Start)(comm, summ, evt.start, comm.prop.msgs.ctLinkStart, evt);
	} case CType.LINK_PACKAGE: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Package)(comm, summ, evt.packages, comm.prop.msgs.ctLinkPackage, evt);
	} case CType.TALK_MESSAGE: { mixin(S_TRACE);
		string text = evt.text;
		text = (text == "") ? comm.prop.msgs.noText : text.singleLine;
		if (evt.cardPaths.length) {
			auto t = contentTextUseID!(CIDKind.CardImages)(comm, summ, evt.cardPaths, comm.prop.msgs.ctTalkMessageImage, evt);
			auto attrs = .msgAttrText(comm.prop, evt);
			if (attrs == "") { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctTalkMessage, t, text);
			} else { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctTalkMessageWithAttrs, t, text, attrs);
			}
		} else {
			auto attrs = .msgAttrText(comm.prop, evt);
			if (attrs == "") { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctTalkMessageNarration, text);
			} else { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctTalkMessageNarrationWithAttrs, text, attrs);
			}
		}
	} case CType.TALK_DIALOG: { mixin(S_TRACE);
		string r(in SDialog sdlg) { mixin(S_TRACE);
			string tt = .tryFormat(comm.prop.msgs.ctTalkMessageImage, comm.prop.msgs.talkerName(evt.talkerNC));
			string t = sdlg.text.singleLine;
			t = (sdlg.text == "") ? comm.prop.msgs.noText : t.singleLine;
			if (sdlg.rCoupons.length) { mixin(S_TRACE);
				auto cp = std.string.join(sdlg.rCoupons.dup, " ");
				auto attrs = .msgAttrText(comm.prop, evt);
				if (attrs == "") { mixin(S_TRACE);
					return .tryFormat(comm.prop.msgs.ctTalkDialog, tt, cp, t);
				} else { mixin(S_TRACE);
					return .tryFormat(comm.prop.msgs.ctTalkDialogWithAttrs, tt, cp, t, attrs);
				}
			} else { mixin(S_TRACE);
				auto attrs = .msgAttrText(comm.prop, evt);
				if (attrs == "") { mixin(S_TRACE);
					return .tryFormat(comm.prop.msgs.ctTalkDialogNoCoupon, tt, t);
				} else { mixin(S_TRACE);
					return .tryFormat(comm.prop.msgs.ctTalkDialogNoCouponWithAttrs, tt, t, attrs);
				}
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
			auto channel = evt.bgmChannel == 0 ? comm.prop.msgs.mainChannel : comm.prop.msgs.subChannel;
			auto fadeIn = .formatReal(evt.bgmFadeIn / 100.0, 3); // ms -> 0.1s
			return  .tryFormat(comm.prop.msgs.ctStopBGM, channel, fadeIn);
		} else { mixin(S_TRACE);
			auto s = contentTextUseID!(CIDKind.BGM)(comm, summ, evt.bgmPath, "%s", evt);
			auto volume = evt.bgmVolume;
			auto loopCount = evt.bgmLoopCount == 0 ? comm.prop.msgs.infinity : .text(evt.bgmLoopCount);
			auto channel = evt.bgmChannel == 0 ? comm.prop.msgs.mainChannel : comm.prop.msgs.subChannel;
			auto fadeIn = .formatReal(evt.bgmFadeIn / 100.0, 3); // ms -> 0.1s
			return .tryFormat(comm.prop.msgs.ctPlayBGM, s, channel, fadeIn, volume, loopCount);
		}
	} case CType.PLAY_SOUND: { mixin(S_TRACE);
		auto s = contentTextUseID!(CIDKind.SE)(comm, summ, evt.soundPath, "%s", evt);
		auto volume = evt.soundVolume;
		auto loopCount = evt.soundLoopCount == 0 ? comm.prop.msgs.infinity : .text(evt.soundLoopCount);
		auto channel = evt.soundChannel == 0 ? comm.prop.msgs.mainChannel : comm.prop.msgs.subChannel;
		auto fadeIn = .formatReal(evt.soundFadeIn / 100.0, 3); // ms -> 0.1s
		return .tryFormat(comm.prop.msgs.ctPlaySound, s, channel, fadeIn, volume, loopCount);
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
		auto step = summ ? summ.flagDirRoot.findStep(evt.step) : null;
		string v = step ? getStepValue(comm.prop, step, evt.stepValue) : .parseDollarParams(comm.prop.var.etc.stepValueName, ['N':.to!string(evt.stepValue)]);
		return .tryFormat(comm.prop.msgs.ctBranchStep, s, v);
	} case CType.BRANCH_SELECT: { mixin(S_TRACE);
		string t = evt.targetAll ? comm.prop.msgs.ctBranchSelectAll : comm.prop.msgs.ctBranchSelectActive;
		string r;
		final switch (evt.selectionMethod) {
		case SelectionMethod.Manual:
			r = comm.prop.msgs.ctBranchSelectManual;
			break;
		case SelectionMethod.Random:
			r = comm.prop.msgs.ctBranchSelectAuto;
			break;
		case SelectionMethod.Valued:
			string[] values;
			values ~= .tryFormat(comm.prop.msgs.initialValue, evt.initValue);
			foreach (coupon; evt.coupons) { mixin(S_TRACE);
				values ~= .tryFormat(comm.prop.msgs.couponValues, coupon.name, coupon.value);
			}
			r = .tryFormat(comm.prop.msgs.ctBranchSelectValued, values.join(", "));
			break;
		}
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
		string t = .rangeName(comm.prop, evt.range, evt.holdingCoupon);
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
		if (evt.range is Range.SELECTED_CARD) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctBranchItemForSelectedCard, name);
		} else { mixin(S_TRACE);
			auto selectCard = evt.selectCard ? comm.prop.msgs.ctSelectFoundCard : comm.prop.msgs.noSelectFoundCard;
			return .tryFormat(comm.prop.msgs.ctBranchItem, name, .rangeName(comm.prop, evt.range, evt.holdingCoupon), evt.cardNumber, selectCard);
		}
	} case CType.BRANCH_SKILL: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Skill)(comm, summ, evt.skill, "%s", evt);
		if (evt.range is Range.SELECTED_CARD) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctBranchSkillForSelectedCard, name);
		} else { mixin(S_TRACE);
			auto selectCard = evt.selectCard ? comm.prop.msgs.ctSelectFoundCard : comm.prop.msgs.noSelectFoundCard;
			return .tryFormat(comm.prop.msgs.ctBranchSkill, name, .rangeName(comm.prop, evt.range, evt.holdingCoupon), evt.cardNumber, selectCard);
		}
	} case CType.BRANCH_INFO: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Info)(comm, summ, evt.info, comm.prop.msgs.ctBranchInfo, evt);
	} case CType.BRANCH_BEAST: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Beast)(comm, summ, evt.beast, "%s", evt);
		if (evt.range is Range.SELECTED_CARD) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctBranchBeastForSelectedCard, name);
		} else { mixin(S_TRACE);
			auto selectCard = evt.selectCard ? comm.prop.msgs.ctSelectFoundCard : comm.prop.msgs.noSelectFoundCard;
			return .tryFormat(comm.prop.msgs.ctBranchBeast, name, .rangeName(comm.prop, evt.range, evt.holdingCoupon), evt.cardNumber, selectCard);
		}
	} case CType.BRANCH_MONEY: { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.ctBranchMoney, evt.money);
	} case CType.BRANCH_COUPON: { mixin(S_TRACE);
		string rangeName = .rangeName(comm.prop, evt.range, evt.holdingCoupon);
		string[] c = evt.couponNames.dup;
		string r;
		if (!c || c.length < 2) { mixin(S_TRACE);
			string c2 = comm.prop.msgs.noSelectCoupon;
			if (c.length && c[0] != "") { mixin(S_TRACE);
				c2 = c[0];
			}
			r = .tryFormat(comm.prop.msgs.ctBranchCoupon, c2, rangeName);
		} else { mixin(S_TRACE);
			string[] names;
			foreach (name; c) { mixin(S_TRACE);
				names ~= .tryFormat(comm.prop.msgs.couponNames, name);
			}
			string type = comm.prop.msgs.matchingTypeAnd;
			if (evt.matchingType == MatchingType.Or) { mixin(S_TRACE);
				type = comm.prop.msgs.matchingTypeOr;
			}
			r = .tryFormat(comm.prop.msgs.ctBranchCouponMulti, names.join(comm.prop.msgs.couponNamesSeparator.value), type, rangeName);
		}
		return r;
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
		auto o = summ ? summ.flagDirRoot.findFlag(evt.flag) : null;
		if (o) { mixin(S_TRACE);
			on = o.on;
			off = o.off;
		}
		return .tryFormat(comm.prop.msgs.ctSetFlag, name, evt.flagValue ? on : off);
	} case CType.SET_STEP: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
		string value;
		auto o = summ ? summ.flagDirRoot.findStep(evt.step) : null;
		if (o) { mixin(S_TRACE);
			value = getStepValue(comm.prop, o, evt.stepValue);
		} else { mixin(S_TRACE);
			value = .parseDollarParams(comm.prop.var.etc.stepValueName, ['N':.to!string(evt.stepValue)]);
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
		auto o = summ ? summ.flagDirRoot.findFlag(evt.flag) : null;
		if (o) { mixin(S_TRACE);
			on = o.on;
		}
		return .tryFormat(comm.prop.msgs.ctCheckFlag, name, on);
	} case CType.GET_CAST: { mixin(S_TRACE);
		auto name = contentTextUseID!(CIDKind.Cast)(comm, summ, evt.casts, "%s", evt);
		auto startAction = comm.prop.msgs.startActionName(evt.startAction);
		return .tryFormat(comm.prop.msgs.ctGetCast, name, startAction);
	} case CType.GET_ITEM: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Item)(comm, summ, evt.item, "%s", evt);
		if (evt.range is Range.SELECTED_CARD) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctGetItemForSelectedCard, name);
		} else { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctGetItem, name, .rangeName(comm.prop, evt.range, evt.holdingCoupon), evt.cardNumber);
		}
	} case CType.GET_SKILL: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Skill)(comm, summ, evt.skill, "%s", evt);
		if (evt.range is Range.SELECTED_CARD) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctGetSkillForSelectedCard, name);
		} else { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctGetSkill, name, .rangeName(comm.prop, evt.range, evt.holdingCoupon), evt.cardNumber);
		}
	} case CType.GET_INFO: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Info)(comm, summ, evt.info, comm.prop.msgs.ctGetInfo, evt);
	} case CType.GET_BEAST: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Beast)(comm, summ, evt.beast, "%s", evt);
		if (evt.range is Range.SELECTED_CARD) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctGetBeastForSelectedCard, name);
		} else { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctGetBeast, name, .rangeName(comm.prop, evt.range, evt.holdingCoupon), evt.cardNumber);
		}
	} case CType.GET_MONEY: { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.ctGetMoney, evt.money);
	} case CType.GET_COUPON: { mixin(S_TRACE);
		string c = evt.coupon;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCoupon;
		string cvs = "";
		if (evt.couponValue < 0) { mixin(S_TRACE);
			cvs = .tryFormat("%d", evt.couponValue);
		} else { mixin(S_TRACE);
			cvs = .tryFormat("+%d", evt.couponValue);
		}
		return .tryFormat(comm.prop.msgs.ctGetCoupon, c, cvs, .rangeName(comm.prop, evt.range, evt.holdingCoupon));
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
		if (evt.range is Range.SELECTED_CARD) { mixin(S_TRACE);
			return comm.prop.msgs.ctLoseItemForSelectedCard;
		} else { mixin(S_TRACE);
			string name = contentTextUseID!(CIDKind.Item)(comm, summ, evt.item, "%s", evt);
			string count = loseCardCount();
			return .tryFormat(comm.prop.msgs.ctLoseItem, name, .rangeName(comm.prop, evt.range, evt.holdingCoupon), count);
		}
	} case CType.LOSE_SKILL: { mixin(S_TRACE);
		if (evt.range is Range.SELECTED_CARD) { mixin(S_TRACE);
			return comm.prop.msgs.ctLoseSkillForSelectedCard;
		} else { mixin(S_TRACE);
			string name = contentTextUseID!(CIDKind.Skill)(comm, summ, evt.skill, "%s", evt);
			string count = loseCardCount();
			return .tryFormat(comm.prop.msgs.ctLoseSkill, name, .rangeName(comm.prop, evt.range, evt.holdingCoupon), count);
		}
	} case CType.LOSE_INFO: { mixin(S_TRACE);
		return contentTextUseID!(CIDKind.Info)(comm, summ, evt.info, comm.prop.msgs.ctLoseInfo, evt);
	} case CType.LOSE_BEAST: { mixin(S_TRACE);
		if (evt.range is Range.SELECTED_CARD) { mixin(S_TRACE);
			return comm.prop.msgs.ctLoseBeastForSelectedCard;
		} else { mixin(S_TRACE);
			string name = contentTextUseID!(CIDKind.Beast)(comm, summ, evt.beast, "%s", evt);
			string count = loseCardCount();
			return .tryFormat(comm.prop.msgs.ctLoseBeast, name, .rangeName(comm.prop, evt.range, evt.holdingCoupon), count);
		}
	} case CType.LOSE_MONEY: { mixin(S_TRACE);
		return .tryFormat(comm.prop.msgs.ctLoseMoney, evt.money);
	} case CType.LOSE_COUPON: { mixin(S_TRACE);
		string c = evt.coupon;
		if (!c || !c.length) c = comm.prop.msgs.noSelectCoupon;
		return .tryFormat(comm.prop.msgs.ctLoseCoupon, c, .rangeName(comm.prop, evt.range, evt.holdingCoupon));
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
		auto notHas = summ && !summ.flagDirRoot.findStep(evt.step);
		if (notHas && .icmp(evt.step, comm.prop.sys.randomValue) == 0) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctSubstituteStepFromRandom, t2);
		} else if (notHas && .icmp(evt.step, comm.prop.sys.selectedPlayerCardNumber) == 0) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctSubstituteStepFromSelectedPlayer, t2);
		} else { mixin(S_TRACE);
			auto t1 = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
			return .tryFormat(comm.prop.msgs.ctSubstituteStep, t1, t2);
		}
	} case CType.SUBSTITUTE_FLAG: { mixin(S_TRACE);
		auto t2 = contentTextUseID!(CIDKind.Flag)(comm, summ, evt.flag2, "%s", evt);
		if (summ && !summ.flagDirRoot.findFlag(evt.flag) && .icmp(evt.flag, comm.prop.sys.randomValue) == 0) { mixin(S_TRACE);
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
		auto name = evt.keyCode == "" ? comm.prop.msgs.noKeyCode : evt.keyCode;
		auto selectCard = evt.selectCard ? comm.prop.msgs.ctSelectFoundCard : comm.prop.msgs.noSelectFoundCard;
		if (evt.targetIsSkill && evt.targetIsItem && evt.targetIsBeast && evt.targetIsHand) { mixin(S_TRACE);
			if (evt.keyCodeRange is Range.SELECTED_CARD) { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctBranchKeyCodeAllTypeForSelectedCard, name, selectCard);
			} else { mixin(S_TRACE);
				auto range = .rangeName(comm.prop, evt.keyCodeRange, evt.holdingCoupon);
				return .tryFormat(comm.prop.msgs.ctBranchKeyCodeAllType, name, range, selectCard);
			}
		} else { mixin(S_TRACE);
			string[] targets;
			if (evt.targetIsSkill) targets ~= comm.prop.msgs.targetIsSkill;
			if (evt.targetIsItem) targets ~= comm.prop.msgs.targetIsItem;
			if (evt.targetIsBeast) targets ~= comm.prop.msgs.targetIsBeast;
			if (evt.targetIsHand) targets ~= comm.prop.msgs.targetIsHand;
			string target = comm.prop.msgs.noSelectTarget;
			if (targets.length) { mixin(S_TRACE);
				target = targets.join(comm.prop.msgs.targetSeparator.value);
			}
			if (evt.keyCodeRange is Range.SELECTED_CARD) { mixin(S_TRACE);
				return .tryFormat(comm.prop.msgs.ctBranchKeyCodeForSelectedCard, name, target, selectCard);
			} else { mixin(S_TRACE);
				auto range = .rangeName(comm.prop, evt.keyCodeRange, evt.holdingCoupon);
				return .tryFormat(comm.prop.msgs.ctBranchKeyCode, name, target, range, selectCard);
			}
		}
	} case CType.CHECK_STEP: { mixin(S_TRACE);
		string name = contentTextUseID!(CIDKind.Step)(comm, summ, evt.step, "%s", evt);
		string value;
		auto o = summ ? summ.flagDirRoot.findStep(evt.step) : null;
		if (o) { mixin(S_TRACE);
			value = getStepValue(comm.prop, o, evt.stepValue);
		} else { mixin(S_TRACE);
			value = .parseDollarParams(comm.prop.var.etc.stepValueName, ['N':.to!string(evt.stepValue)]);
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
	} case CType.BRANCH_MULTI_COUPON: { mixin(S_TRACE);
		auto range = .rangeName(comm.prop, evt.range, evt.holdingCoupon);
		return .tryFormat(comm.prop.msgs.ctBranchMultiCoupon, range);
	} case CType.BRANCH_MULTI_RANDOM: { mixin(S_TRACE);
		return comm.prop.msgs.ctBranchMultiRandom;
	} case CType.MOVE_CARD: { mixin(S_TRACE);
		auto cardGroup = evt.cardGroup;
		if (!cardGroup || !cardGroup.length) cardGroup = comm.prop.msgs.noSelectCardGroup;
		auto posType = comm.prop.msgs.coordinateTypeName(evt.positionType);
		auto scale = evt.scale == -1 ? comm.prop.msgs.noChangeScale : .format("%s%%", evt.scale);
		auto layer = evt.layer == -1 ? comm.prop.msgs.noChangeLayer : .text(evt.layer);

		if (evt.positionType is CoordinateType.None) { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctMoveCardNoSet, cardGroup, scale, layer);
		} else { mixin(S_TRACE);
			return .tryFormat(comm.prop.msgs.ctMoveCard, cardGroup, posType, evt.x, evt.y, scale, layer);
		}
	}
	}
}

string msgAttrText(in Props prop, in Content evt) { mixin(S_TRACE);
	string[] attrs;
	if (evt.centeringX && evt.centeringY) { mixin(S_TRACE);
		if (prop.msgs.centeringXYOn != "") attrs ~= prop.msgs.centeringXYOn;
	} else if (evt.centeringX) { mixin(S_TRACE);
		if (prop.msgs.centeringXOn != "") attrs ~= prop.msgs.centeringXOn;
	} else if (evt.centeringY) { mixin(S_TRACE);
		if (prop.msgs.centeringYOn != "") attrs ~= prop.msgs.centeringYOn;
	}
	if (evt.boundaryCheck && prop.msgs.boundaryCheckOn != "") attrs ~= prop.msgs.boundaryCheckOn;
	if (evt.selectionColumns != 1 && prop.msgs.ctColumns != "") attrs ~= .tryFormat(prop.msgs.ctColumns, evt.selectionColumns);
	if (evt.selectTalker && hasCharacterTalker(evt) && prop.msgs.ctSelectTalker != "") attrs ~= prop.msgs.ctSelectTalker;
	return attrs.join(" ");
}

string getStepValue(in Props prop, in Step step, int value) { mixin(S_TRACE);
	if (0 <= value && value < step.count) { mixin(S_TRACE);
		return step.getValue(value);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.unknownStepValue, value);
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
	open.setToolTipText(comm.prop.msgs.menuText(dir ? MenuID.OpenDir : MenuID.OpenPlace));
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

bool updateChecked(Event)(Event e) { mixin(S_TRACE);
	if (e.detail == SWT.CHECK) { mixin(S_TRACE);
		bool r = false;
		if (auto itm = cast(TableItem)e.item) { mixin(S_TRACE);
			auto checked = itm.getChecked();
			auto tbl = itm.getParent();
			if (tbl.isSelected(tbl.indexOf(itm))) { mixin(S_TRACE);
				r = true;
				foreach (itm2; itm.getParent().getSelection()) { mixin(S_TRACE);
					if (checked != itm2.getChecked()) { mixin(S_TRACE);
						itm2.setChecked(checked);
					}
				}
			}
		} else if (auto itm = cast(TreeItem)e.item) { mixin(S_TRACE);
			auto checked = itm.getChecked();
			auto tree = itm.getParent();
			auto sels = tree.getSelection();
			if (sels.contains(itm)) { mixin(S_TRACE);
				r = true;
				foreach (itm2; sels) { mixin(S_TRACE);
					if (checked != itm2.getChecked()) { mixin(S_TRACE);
						itm2.setChecked(checked);
					}
				}
			}
		}
		return r;
	} else {
		return false;
	}
}

/// ツリーに含まれる全てのアイテム数を返す。
int getAllItemCount(Tree tree) { mixin(S_TRACE);
	int r = tree.getItemCount();
	void recurse(TreeItem itm) { mixin(S_TRACE);
		r += itm.getItemCount();
		foreach (child; itm.getItems()) { mixin(S_TRACE);
			recurse(child);
		}
	}
	foreach (itm; tree.getItems()) { mixin(S_TRACE);
		recurse(itm);
	}
	return r;
}

/// ファイルタイプ別のアイコン。
public static Image fimage(Props prop, string file, Skin skin) { mixin(S_TRACE);
	try { mixin(S_TRACE);
		if (.isBinImg(file)) { mixin(S_TRACE);
			if (skin.isCardImage(file, false)) { mixin(S_TRACE);
				return prop.images.cards;
			} else if (skin.isBgImage(file)) { mixin(S_TRACE);
				return prop.images.backs;
			}
		} else if (.exists(file)) { mixin(S_TRACE);
			if (.isDir(file)) { mixin(S_TRACE);
				return prop.images.folder;
			} else if (skin.isCardImage(file, false)) { mixin(S_TRACE);
				return prop.images.cards;
			} else if (skin.isBgImage(file)) { mixin(S_TRACE);
				return prop.images.backs;
			} else if (skin.isBGM(file)) { mixin(S_TRACE);
				return prop.images.bgm;
			} else if (skin.isSE(file)) { mixin(S_TRACE);
				return prop.images.se;
			}
		}
		auto ext = .extension(file);
		foreach (txtExt; prop.var.etc.plainTextFileExtensions) { mixin(S_TRACE);
			if (.cfnmatch(ext, txtExt)) { mixin(S_TRACE);
				return prop.images.text;
			}
		}
	} catch (Exception e) {
		printStackTrace();
		debugln(e);
	}
	return prop.images.unknown;
}

/// pathの内容を端的に表すアイコンとテキストを返す。
void getSymbols(Commons comm, Summary summ, CWXPath path, bool desc, out string text, out Image img) { mixin(S_TRACE);
	img = null;
	text = "*Error*";
	if (!path) return;

	auto prop = comm.prop;
	auto sum = cast(Summary)path;
	if (sum) { mixin(S_TRACE);
		img = prop.images.summary;
		text = desc ? .tryFormat(prop.msgs.searchResultSummary, sum.desc.singleLine) : sum.scenarioName;
	}
	auto bgi = cast(BgImage)path;
	if (bgi) { mixin(S_TRACE);
		auto ic = cast(ImageCell)bgi;
		if (ic) { mixin(S_TRACE);
			img = prop.images.backs;
			text = .tryFormat(prop.msgs.searchResultImageCell, ic.name(prop.parent));
		}
		auto tc = cast(TextCell)bgi;
		if (tc) { mixin(S_TRACE);
			img = prop.images.textCell;
			text = .tryFormat(prop.msgs.searchResultTextCell, tc.name(prop.parent));
		}
		auto cc = cast(ColorCell)bgi;
		if (cc) { mixin(S_TRACE);
			img = prop.images.colorCell;
			text = .tryFormat(prop.msgs.searchResultColorCell, cc.name(prop.parent));
		}
		auto pc = cast(PCCell)bgi;
		if (pc) { mixin(S_TRACE);
			img = prop.images.pcCell;
			text = .tryFormat(prop.msgs.searchResultPCCell, pc.name(prop.parent));
		}
	}
	auto are = cast(Area)path;
	if (are) { mixin(S_TRACE);
		img = prop.images.area;
		text = .tryFormat(prop.msgs.searchResultIds, prop.msgs.area, are.id, are.name);
	}
	auto bat = cast(Battle)path;
	if (bat) { mixin(S_TRACE);
		img = prop.images.battle;
		text = .tryFormat(prop.msgs.searchResultIds, prop.msgs.battle, bat.id, bat.name);
	}
	auto pac = cast(Package)path;
	if (pac) { mixin(S_TRACE);
		img = prop.images.packages;
		text = .tryFormat(prop.msgs.searchResultIds, prop.msgs.cwPackage, pac.id, pac.name);
	}
	auto pce = cast(PlayerCardEvents)path;
	if (pce) { mixin(S_TRACE);
		img = prop.images.playerCard;
		text = prop.msgs.playerCard;
	}
	auto cas = cast(CastCard)path;
	if (cas) { mixin(S_TRACE);
		img = prop.images.casts;
		text = .tryFormat(prop.msgs.searchResultIds, prop.msgs.cwCast, cas.id, cas.name);
	}
	auto ski = cast(SkillCard)path;
	if (ski) { mixin(S_TRACE);
		if (ski.linkId != 0) ski = summ.skill(ski.linkId);
		if (!ski) return;
		img = prop.images.skill;
		text = .tryFormat(prop.msgs.searchResultIds, prop.msgs.skill, ski.id, ski.name);
	}
	auto ite = cast(ItemCard)path;
	if (ite) { mixin(S_TRACE);
		if (ite.linkId != 0) ite = summ.item(ite.linkId);
		if (!ite) return;
		img = prop.images.item;
		text = .tryFormat(prop.msgs.searchResultIds, prop.msgs.item, ite.id, ite.name);
	}
	auto bea = cast(BeastCard)path;
	if (bea) { mixin(S_TRACE);
		if (bea.linkId != 0) bea = summ.beast(bea.linkId);
		if (!bea) return;
		img = prop.images.beast;
		text = .tryFormat(prop.msgs.searchResultIds, prop.msgs.beast, bea.id, bea.name);
	}
	auto inf = cast(InfoCard)path;
	if (inf) { mixin(S_TRACE);
		img = prop.images.info;
		text = .tryFormat(prop.msgs.searchResultIds, prop.msgs.info, inf.id, inf.name);
	}
	auto con = cast(Content)path;
	if (con) { mixin(S_TRACE);
		img = prop.images.content(con.type);
		text = .contentText(comm, con, summ);
	}
	auto tex = cast(SimpleTextHolder)path;
	if (tex) { mixin(S_TRACE);
		Content c = cast(Content)tex.owner;
		if (!c) { mixin(S_TRACE);
			auto dlg = cast(SDialog)tex.owner;
			if (dlg) path = dlg;
		}
		if (c) { mixin(S_TRACE);
			img = prop.images.content(c.type);
			text = .contentText(comm, c, summ);
		}
		if (auto tc = cast(TextCell)tex.owner) { mixin(S_TRACE);
			img = prop.images.textCell;
			text = .tryFormat(prop.msgs.searchResultTextCell, tc.name(prop.parent));
		}
	}
	auto sdlg = cast(SDialog)path;
	if (sdlg) { mixin(S_TRACE);
		con = sdlg.parent;
		assert (!con || con.type is CType.TALK_DIALOG);
		img = prop.images.content(CType.TALK_DIALOG);
		string t = sdlg.text.singleLine;
		if (sdlg.rCoupons.length) { mixin(S_TRACE);
			text = .tryFormat(prop.msgs.dialogText, t, std.string.join(sdlg.rCoupons.dup, " "));
		} else { mixin(S_TRACE);
			text = .tryFormat(prop.msgs.dialogTextNoCoupon, t);
		}
	}
	auto fla = cast(cwx.flag.Flag)path;
	if (fla) { mixin(S_TRACE);
		img = prop.images.flag;
		text = .tryFormat(prop.msgs.searchResultFlag, fla.path);
	}
	auto ste = cast(Step)path;
	if (ste) { mixin(S_TRACE);
		img = prop.images.step;
		text = .tryFormat(prop.msgs.searchResultStep, ste.path);
	}
	auto fld = cast(FlagDir)path;
	if (fld) { mixin(S_TRACE);
		img = prop.images.flagDir;
		string fldPath = fld.path;
		if ("" == fldPath) { mixin(S_TRACE);
			// Rootディレクトリ
			text = prop.msgs.flagsAndSteps;
		} else { mixin(S_TRACE);
			text = .tryFormat(prop.msgs.searchResultFlagDir, fldPath);
		}
	}
	auto eve = cast(EventTree)path;
	if (eve) { mixin(S_TRACE);
		img = prop.images.eventTree;
		text = .tryFormat(prop.msgs.searchResultEventTree, eve.name);
	}
	auto men = cast(MenuCard)path;
	if (men) { mixin(S_TRACE);
		img = prop.images.cards;
		if (!desc || men.desc == "") { mixin(S_TRACE);
			text = .tryFormat(prop.msgs.searchResultMenuCard, men.name);
		} else { mixin(S_TRACE);
			text = .tryFormat(prop.msgs.searchResultMenuCardWithDesc, men.name, .singleLine(men.desc));
		}
	}
	auto ene = cast(EnemyCard)path;
	if (ene) { mixin(S_TRACE);
		img = prop.images.cards;
		string cName = prop.msgs.noSelectCast;
		if (0 != ene.id) { mixin(S_TRACE);
			auto card = summ.cwCast(ene.id);
			cName = card ? card.name : .tryFormat(prop.msgs.noCast, ene.id);
		}
		text = .tryFormat(prop.msgs.searchResultEnemyCard, cName);
	}
	auto jpy1Sec = cast(Jpy1Sec)path;
	if (jpy1Sec) { mixin(S_TRACE);
		img = prop.images.backs;
		auto fPath = nabs(jpy1Sec.fPath).abs2rel(nabs(summ.scenarioPath));
		text = .tryFormat(prop.msgs.searchResultJpy1, encodePath(fPath));
	}
	auto jpdc = cast(Jpdc)path;
	if (jpdc) { mixin(S_TRACE);
		img = prop.images.backs;
		auto fPath = nabs(jpdc.jpdcPath).abs2rel(nabs(summ.scenarioPath));
		text = .tryFormat(prop.msgs.searchResultJpdc, encodePath(fPath));
	}
	auto motion = cast(Motion)path;
	if (motion) { mixin(S_TRACE);
		img = prop.images.motion(motion.type);
		text = prop.msgs.motionName(motion.type);
	}
	assert (img !is null, .text(path) ~ ", " ~ typeid(path).toString());
}

/// BUG: GDI+でOpenTypeフォントを使用しようとした時の問題を避ける
void wDrawText(GC gc, string text, int x, int y) { mixin(S_TRACE);
	version (Windows) {
		if (isEnableGdipAndNotTrueTypeFont(gc)) { mixin(S_TRACE);
			auto data = gc.getGCData();
			auto g = data.gdipGraphics;
			data.gdipGraphics = null;
			scope (exit) data.gdipGraphics = g;
			gc.drawText(text, x, y);
		} else { mixin(S_TRACE);
			gc.drawText(text, x, y);
		}
	} else { mixin(S_TRACE);
		gc.drawText(text, x, y);
	}
}
/// ditto
void wDrawText(GC gc, string text, int x, int y, bool isTransparent) { mixin(S_TRACE);
	version (Windows) {
		if (isEnableGdipAndNotTrueTypeFont(gc)) { mixin(S_TRACE);
			auto data = gc.getGCData();
			auto g = data.gdipGraphics;
			data.gdipGraphics = null;
			scope (exit) data.gdipGraphics = g;
			gc.drawText(text, x, y, isTransparent);
		} else { mixin(S_TRACE);
			gc.drawText(text, x, y, isTransparent);
		}
	} else { mixin(S_TRACE);
		gc.drawText(text, x, y, isTransparent);
	}
}
/// ditto
void wDrawText(GC gc, string text, int x, int y, int flags) { mixin(S_TRACE);
	version (Windows) {
		if (isEnableGdipAndNotTrueTypeFont(gc)) { mixin(S_TRACE);
			auto data = gc.getGCData();
			auto g = data.gdipGraphics;
			data.gdipGraphics = null;
			scope (exit) data.gdipGraphics = g;
			gc.drawText(text, x, y, flags);
		} else { mixin(S_TRACE);
			gc.drawText(text, x, y, flags);
		}
	} else { mixin(S_TRACE);
		gc.drawText(text, x, y, flags);
	}
}
/// ditto
Point wTextExtent(GC gc, string text) { mixin(S_TRACE);
	version (Windows) {
		if (isEnableGdipAndNotTrueTypeFont(gc) || OS.WIN32_VERSION < OS.VERSION(6, 0)) { mixin(S_TRACE);
			auto data = gc.getGCData();
			auto g = data.gdipGraphics;
			data.gdipGraphics = null;
			scope (exit) data.gdipGraphics = g;
			return gc.textExtent(text);
		} else { mixin(S_TRACE);
			return gc.textExtent(text);
		}
	} else { mixin(S_TRACE);
		return gc.textExtent(text);
	}
}
/// ditto
private bool isEnableGdipAndNotTrueTypeFont(GC gc) { mixin(S_TRACE);
	version (Windows) {
		if (!gc.getAdvanced()) return false;
		import org.eclipse.swt.internal.win32.WINTYPES;
		import org.eclipse.swt.internal.win32.OS;
		TEXTMETRIC tm;
		auto old = OS.SelectObject(gc.handle, gc.getFont().handle);
		scope (exit) OS.SelectObject(gc.handle, old);
		if (!OS.GetTextMetrics(gc.handle, &tm)) return false;
		return !(tm.tmPitchAndFamily & TMPF_TRUETYPE);
	} else {
		return false;
	}
}

/// titleをsizeまで縮めて描画する。
void shrinkDrawText(GC gc, string title, int x, int y, in Point size, bool smoothing) {
	auto d = gc.getDevice();
	auto extent = gc.wTextExtent(title);
	auto img = new Image(d, extent.x, extent.y);
	scope (exit) img.dispose();
	auto gc2 = new GC(img);
	scope (exit) gc2.dispose();
	gc2.setBackground(d.getSystemColor(SWT.COLOR_BLACK));
	gc2.setForeground(d.getSystemColor(SWT.COLOR_WHITE));
	gc2.setFont(gc.getFont());
	gc2.drawText(title, 0, 0, false);
	auto bmpData = img.getImageData();
	auto alphaData = cast(byte[])createAlphaDataFrom(cast(ubyte[])bmpData.data, bmpData.depth,
		bmpData.width, bmpData.height, bmpData.bytesPerLine);
	gc2.setBackground(gc.getForeground());
	gc2.fillRectangle(0, 0, extent.x, extent.y);
	bmpData = img.getImageData();
	bmpData.alphaData = alphaData;

	if (smoothing) { mixin(S_TRACE);
		auto data = cast(ubyte[])bmpData.data;
		auto alpha = cast(ubyte[])bmpData.alphaData;
		size_t bpl;
		bmpData.data = cast(byte[])smoothResize(size.x, size.y, data, alpha,
			bmpData.depth, bmpData.width, bmpData.height, bmpData.bytesPerLine, bpl);
		bmpData.alphaData = cast(byte[])alpha;
		bmpData.width = size.x;
		bmpData.height = size.y;
		bmpData.bytesPerLine = cast(int)bpl;
	} else { mixin(S_TRACE);
		bmpData = bmpData.scaledTo(size.x, size.y);
	}
	auto img2 = new Image(d, bmpData);
	scope (exit) img2.dispose();
	gc.drawImage(img2, x, y);
}

void asyncExec(Display d, void delegate() dlg) { mixin(S_TRACE);
	d.asyncExec(new class Runnable {
		override void run() { mixin(S_TRACE);
			dlg();
		}
	});
}

void setupWeights(SplitPane sash, ref Prop!(int, false) left, ref Prop!(int, false) right) { mixin(S_TRACE);
	sash.setWeights([left, right]);
	auto ad = cast(AbsDialog)sash.getShell().getData();
	sash.addSelectionListener(new class SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto ws = sash.getWeights();
			left.value = ws[0];
			right.value = ws[1];
			if (ad) ad.saveWin();
		}
	});
}

void setupToggle(Button toggle, ref Prop!(bool, false) value) { mixin(S_TRACE);
	toggle.setSelection(value);
	.listener(toggle, SWT.Selection, { mixin(S_TRACE);
		value.value = toggle.getSelection();
	});
}
void setupToggle(ToolItem toggle, ref Prop!(bool, false) value) { mixin(S_TRACE);
	toggle.setSelection(value);
	.listener(toggle, SWT.Selection, { mixin(S_TRACE);
		value.value = toggle.getSelection();
	});
}
void setupToggle(MenuItem toggle, ref Prop!(bool, false) value) { mixin(S_TRACE);
	toggle.setSelection(value);
	.listener(toggle, SWT.Selection, { mixin(S_TRACE);
		value.value = toggle.getSelection();
	});
}

void setupSpinner(Int)(Spinner spinner, ref Prop!(Int, false) value) { mixin(S_TRACE);
	spinner.setSelection(value);
	.listener(spinner, SWT.Selection, { mixin(S_TRACE);
		value.value = spinner.getSelection();
	});
	.listener(spinner, SWT.Modify, { mixin(S_TRACE);
		value.value = spinner.getSelection();
	});
}

Rectangle setupWindow(Shell shell, DSize winProps) { mixin(S_TRACE);
	void delegate(bool) dummy;
	return .setupWindow(shell, winProps, dummy, true, true);
}
Rectangle setupWindow(Shell shell, DSize winProps, out void delegate(bool save) clearSetup, bool setLocation, bool setSize) { mixin(S_TRACE);
	if (setLocation || setSize) { mixin(S_TRACE);
		auto wp = shell.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		auto cs = new Point(wp.x, wp.y);
		if (!setSize) { mixin(S_TRACE);
			cs.x = shell.getSize().x;
			cs.y = shell.getSize().y;
		} else if (winProps) { mixin(S_TRACE);
			if (winProps.width != SWT.DEFAULT) cs.x = winProps.width;
			if (winProps.height != SWT.DEFAULT) cs.y = winProps.height;
		}
		shell.setSize(cs);

		auto w = cast(WSize)winProps;
		if (w) { mixin(S_TRACE);
			shell.setMaximized(w.maximized);
		}

		auto parent = shell.getParent();
		auto parBounds = parent.getBounds();
		int width = !winProps || winProps.width == SWT.DEFAULT ? wp.x : winProps.width;
		int height = !winProps || winProps.height == SWT.DEFAULT ? wp.y : winProps.height;
		int x, y;
		if (!setLocation) { mixin(S_TRACE);
			x = shell.getLocation().x;
			y = shell.getLocation().y;
		} else if (parent) { mixin(S_TRACE);
			x = !w || w.x == SWT.DEFAULT ? (parBounds.x + (parBounds.width / 2 - width / 2)) : (w.x + parBounds.x);
			y = !w || w.y == SWT.DEFAULT ? (parBounds.y + (parBounds.height / 2 - height / 2)) : (w.y + parBounds.y);
		} else { mixin(S_TRACE);
			x = !w || w.x == SWT.DEFAULT ? shell.getBounds().x : w.x;
			y = !w || w.y == SWT.DEFAULT ? shell.getBounds().y : w.y;
		}
		
		intoDisplay(x, y, width, height);
		shell.setBounds(x, y, width, height);
	}
	auto removed = false;
	void saveWin(Event e) { mixin(S_TRACE);
		if (removed) return;
		auto w = cast(WSize)winProps;
		if (!shell.getMaximized()) { mixin(S_TRACE);
			.asyncExec(shell.getDisplay(), { mixin(S_TRACE);
				// SplitPaneのSash位置の記録処理は再レイアウト後に
				// 行う必要が有るため、実行を遅延する
				if (removed) return;
				if (shell.isDisposed()) return;
				auto s = shell.getSize();
				if (winProps.width != s.x || winProps.height != s.y) { mixin(S_TRACE);
					winProps.width = s.x;
					winProps.height = s.y;
					void recurse(Control ctrl) { mixin(S_TRACE);
						if (auto sash = cast(SplitPane)ctrl) { mixin(S_TRACE);
							if (e) sash.notifySelectionListeners(e);
						}
						if (auto comp = cast(Composite)ctrl) { mixin(S_TRACE);
							foreach (child; comp.getChildren()) recurse(child);
						}
					}
					recurse(shell);
				}
			});
			auto parent = shell.getParent();
			if (w) { mixin(S_TRACE);
				w.x = shell.getBounds().x - (parent ? shell.getParent().getBounds().x : 0);
				w.y = shell.getBounds().y - (parent ? shell.getParent().getBounds().y : 0);
			}
		}
		if (w) { mixin(S_TRACE);
			w.maximized = shell.getMaximized();
		}
	}
	if (winProps) { mixin(S_TRACE);
		auto ctrlL = new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				saveWin(e);
			}
		};
		shell.addListener(SWT.Move, ctrlL);
		shell.addListener(SWT.Resize, ctrlL);
		clearSetup = (save) { mixin(S_TRACE);
			removed = true;
			if (save) saveWin(null);
			shell.removeListener(SWT.Move, ctrlL);
			shell.removeListener(SWT.Resize, ctrlL);
		};
	}
	return shell.getBounds();
}

version (Windows) {
	static immutable DEFAULT_CHARSET = 0x1;
	static immutable OUT_DEFAULT_PRECIS = 0x0;
	static immutable CLIP_DEFAULT_PRECIS = 0x0;
	static immutable DEFAULT_QUALITY = 0x0;
	static immutable ANTIALIASED_QUALITY = 0x4;
	static immutable DEFAULT_PITCH = 0x0;
	static immutable FIXED_PITCH = 0x1;
	static immutable VARIABLE_PITCH = 0x2;
	static immutable FF_DONTCARE = (0x0 << 4);
	static immutable FF_ROMAN = (0x1 << 4);
	static immutable FF_MODERN = (0x3 << 4);
	extern (Windows) HFONT CreateFontW(INT, INT, INT, INT, INT, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, LPCWSTR);
}

/// ピクセルサイズを指定してフォントを生成する。
Font createFontFromPixels(in CFont font) { mixin(S_TRACE);
	return .createFontFromPixels(font.name, font.point, font.bold, font.italic);
}
/// ditto
Font createFontFromPixels(string face, int pixels, bool bold = false, bool italic = false, bool uline = false, bool strike = false, bool antialias = true) { mixin(S_TRACE);
	auto d = Display.getCurrent();
	version (Windows) {
		int fh = pixels;
		DWORD fwg = bold ? FW_BOLD : FW_NORMAL;
		DWORD fi = italic ? TRUE : FALSE;
		DWORD fu = uline ? TRUE : FALSE;
		DWORD fs = strike ? TRUE : FALSE;
		DWORD fc = DEFAULT_CHARSET;
		DWORD fop = OUT_DEFAULT_PRECIS;
		DWORD fclp = CLIP_DEFAULT_PRECIS;
		DWORD fq = antialias ? ANTIALIASED_QUALITY : DEFAULT_QUALITY;
		DWORD fp = DEFAULT_PITCH | FF_DONTCARE;
		HFONT hf;
		hf = CreateFontW(fh, 0, 0, 0, fwg, fi, fu, fs, fc, fop, fclp, fq,
			fp, toUTFz!(wchar*)(face));
		return Font.win32_new(d, hf);
	} else { mixin(S_TRACE);
		int fStyle = SWT.NORMAL;
		if (bold) fStyle |= SWT.BOLD;
		if (italic) fStyle |= SWT.ITALIC;
		auto h = cast(int) (pixels * (72.0 / d.getDPI().y) + 0.5);
		auto fontData = new FontData(face, h, fStyle);
		return new Font(d, fontData);
	}
}

bool isEnterKey(int keyCode) { mixin(S_TRACE);
	// BUG: テンキーのEnterを押すと0x1000050が発行される。
	return keyCode == SWT.CR || keyCode == 0x1000050;
}
