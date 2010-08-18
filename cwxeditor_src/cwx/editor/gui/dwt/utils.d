
module cwx.editor.gui.dwt.utils;

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

import cwx.editor.gui.sound;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.xmlbytestransfer;

import std.utf;
import std.ctype;
import std.zip;
import std.file;
import std.date;
import std.path;
import std.thread;
import std.process;

import dwt.all;

import dwtx.jface.action.Action;

public:

ImageData loadImage(string path, bool mask = true, int maskX = 0, int maskY = 0) {
	mixin FileCache!(byte[]);

	if (path !is null && path.length > 0) {
		string ext = std.path.getExt(path);
		if (std.path.fnmatch(ext, "jpy1")
				|| std.path.fnmatch(ext, "jptx")
				|| std.path.fnmatch(ext, "jpdc")) {
			auto data = new ImageData(632, 420, 8, new PaletteData(0, 0, 0));
			data.transparentPixel = data.getPixel(0, 0);
			return data;
		}
		try {
			byte[] bytes;
			if (isBinImg(path)) {
				bytes = strToBImg(path);
			} else {
				if (!.exists(path)) return blankImage;
				auto ca = cache(path);
				if (ca) {
					bytes = ca.value;
				} else {
					bytes = cast(byte[]) std.file.read(path);
					putCache(path, bytes);
				}
			}
			auto s = new ByteArrayInputStream(bytes);
			scope (exit) s.close;
			auto data = new ImageData(s);
			if (mask) data.transparentPixel = data.getPixel(maskX, maskY);
			return data;
		} catch (DWTException e) {
			debugln(e);
		}
	}
	return blankImage;
}

ImageData blankImage() {
	auto data = new ImageData(1, 1, 8, new PaletteData(0, 0, 0));
	data.transparentPixel = data.getPixel(0, 0);
	return data;
}

alias ArrayWrapperString2 FileNames;

string wrapReturnCode(string str) {
	version (Windows) {
		return std.string.replace(str, "\r\n", "\n");
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

GridLayout windowGridLayout(int col, bool eqWid = false) {
	auto gl = new GridLayout(col, eqWid);
	gl.horizontalSpacing = 2;
	gl.verticalSpacing = 2;
	gl.marginWidth = 2;
	gl.marginHeight = 2;
	return gl;
}

void setGridMinW(Control c, int minW, int gridStyle = DWT.NULL) {
	auto gd = new GridData(gridStyle);
	int w = c.computeSize(DWT.DEFAULT, DWT.DEFAULT).x;
	gd.widthHint = w > minW ? w : minW;
	c.setLayoutData(gd);
}

class SpinnerEdit {
private:
	Spinner _spn;
	int _oldVal;
	void delegate(int value) _edit;
	void delegate(int value) _enter;
	int delegate(int oldVal) _cancel;
	void enter() {
		if (_spn.getText.length > 0 && _oldVal != _spn.getSelection) {
			_enter(_spn.getSelection);
		} else {
			_spn.setSelection = _cancel !is null ? _cancel(_oldVal) : _oldVal;
		}
		_oldVal = _spn.getSelection;
	}
	class KListener : KeyAdapter {
		public override void keyPressed(KeyEvent e) {
			if (e.character == DWT.CR) {
				enter;
			} else if (e.character == DWT.ESC) {
				_spn.setSelection = _cancel !is null ? _cancel(_oldVal) : _oldVal;
				_oldVal = _spn.getSelection;
			}
		}
	}
	class MSListener : FocusListener {
		void focusGained(FocusEvent e) {
			_oldVal = _spn.getSelection;
		}
		void focusLost(FocusEvent e) {
			enter;
		}
	}
	class MDListener : ModifyListener {
		public override void modifyText(ModifyEvent e) {
			if (_spn.isFocusControl && _edit !is null) {
				_edit(_spn.getSelection);
			}
		}
	}
public override:
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
	d_time _time;
	Item delegate() _selection;
	Item delegate(int x, int y) _selectionM;
	void delegate(Item itm) _startEdit;
	bool _dClick;
public override:
	/// Params:
	/// startEdit = 編集開始時に呼出される。
	/// selection = 編集対象を返す。
	/// selectionM = 位置に応じて編集対象を返す。
	/// dClick = trueなら編集開始条件はダブルクリックと既選択後のシングルクリック、
	///          falseならダブルクリックにならない速度の2回クリック。
	this (void delegate(Item itm) startEdit,
			Item delegate() selection, Item delegate(int x, int y) selectionM,
			bool dClick = true) {
		_startEdit = startEdit;
		_selection = selection;
		_selectionM = selectionM;
		_dClick = dClick;
	}
/+	void mouseDoubleClick(MouseEvent e) {
		if (_dClick) {
			auto itm = _selectionM(e.x, e.y);
			if (e.button == 1 && itm !is null) {
				_startEdit(itm);
			}
		}
	}
+/	void widgetSelected(SelectionEvent e) {
		if (_dClick) {
			_itm = _selection();
		}
	}
	void widgetDefaultSelected(SelectionEvent e) {}
	void mouseDown(MouseEvent e) {
		auto itm = _selectionM(e.x, e.y);
		if (_dClick) {
			if (e.button == 1 && itm !is null && itm == _itm) {
				_startEdit(itm);
			}
		} else {
			synchronized {
				if (e.button == 1 && itm !is null) {
					if (_itm !is null && itm == _itm && _time <= getUTCtime) {
						_itm = null;
						_startEdit(itm);
					} else {
						_itm = itm;
						_time = getUTCtime + Display.getCurrent.getDoubleClickTime * (TicksPerSecond / 1000);
					}
				}
			}
		}
	}
}
private class TextEditKListener : KeyAdapter {
private:
	Item delegate() _selection;
	void delegate(Item itm) _startEdit;
public:
	this (void delegate(Item itm) startEdit, Item delegate() selection) {
		_startEdit = startEdit;
		_selection = selection;
	}
	override void keyPressed(KeyEvent e) {
		if (e.keyCode == DWT.F2) {
			auto itm = _selection();
			if (itm !is null) {
				_startEdit(itm);
			}
		}
	}
}

private class EditEnd : KeyAdapter, FocusListener {
private:
	Control ctrl;
	void delegate(Control) end;

public:
	this(Composite parent, Control ctrl, void delegate(Control) end) {
		this.end = end;
		this.ctrl = ctrl;
		ctrl.addFocusListener(this);
		ctrl.addKeyListener(this);
	}
	void setFocus() {
		ctrl.setFocus;
	}
	Control editor() {
		return ctrl;
	}
	override void focusGained(FocusEvent e) {}
	override void focusLost(FocusEvent e) {
		enter();
	}
	override void keyPressed(KeyEvent e) {
		if (e.character == DWT.CR) {
			enter();
		} else if (e.keyCode == DWT.ESC) {
			ctrl.dispose;
		}
	}
	bool isExit() {
		return ctrl.isDisposed;
	}
	void enter() {
		end(ctrl);
		ctrl.dispose;
	}
}

Text createTextEditor(Composite parent, string str) {
	auto text = new Text(parent, DWT.BORDER);
	text.setText(str);
	text.selectAll();
	return text;
}

CCombo createComboEditor(Composite parent, string[] strs, string str) {
	auto combo = new CCombo(parent, DWT.BORDER | DWT.READ_ONLY);
	combo.setVisibleItemCount = 20;
	foreach (s; strs) {
		combo.add(s);
	}
	combo.setText(str);
	return combo;
}


/// テーブルを編集可能にする。
/// ダブルクリック、またはF2キーの押下で編集開始。
class TableTextEdit {
private:
	Table table;
	TableEditor editor;
	EditEnd _tee = null;
	int editC;
	void delegate(TableItem itm, int column, string newText) editEnd = null;
	bool delegate(TableItem itm, int column) canEdit = null;

	Item selectionM(int x, int y) {
		if (table.getSelectionCount == 1) {
			auto itm = table.getSelection[0];
			if (itm.getBounds(editC).contains(x, y)) {
				if (!itm.getImage || !itm.getImageBounds(editC).contains(x, y)) {
					return itm;
				}
			}
		}
		return null;
	}
	Item selectionK() {
		if (table.getSelectionCount == 1) {
			return table.getSelection[0];
		}
		return null;
	}

	void end(Control c) {
		auto newText = (cast(Text) c).getText;
		if (editEnd is null) {
			if (newText.length > 0) {
				editor.getItem.setText(editC, newText);
			}
		} else {
			editEnd(editor.getItem, editC, newText);
		}
	}

	void startEdit(Item itm) {
		startEdit(cast(TableItem) itm);
	}
public:
	/// table = テキスト編集対象のテーブル。
	/// editC = 編集対象の列。
	/// editEnd = 編集終了時に実行される関数。nullを指定した場合、
	///           単にテーブルアイテムのテキストを編集後のテキストで置換する。
	/// canEdit = テーブルアイテムが編集可能か否かを判定する関数。nullを指定した場合、
	///           すべてのセルが編集可能になる。
	this(Table table, int editC,
			void delegate(TableItem itm, int column, string text) editEnd = null,
			bool delegate(TableItem itm, int column) canEdit = null) {
		this.table = table;
		this.editC = editC;
		this.editEnd = editEnd;
		this.canEdit = canEdit;
		editor = new TableEditor(table);
		editor.grabHorizontal = true;

		auto mf = new TextEditMFListener(&startEdit, &selectionK, &selectionM);
		table.addMouseListener(mf);
		table.addSelectionListener(mf);
		table.addKeyListener(new TextEditKListener(&startEdit, &selectionK));
	}
	/// 選択されているセルの編集を開始する。
	void startEdit() {
		auto sels = table.getSelection;
		if (sels.length == 1) {
			startEdit(sels[0]);
		}
	}
	void startEdit(TableItem itm) {
		if (_tee !is null && !_tee.isExit) _tee.enter;
		auto sel = itm;
		if (canEdit is null || canEdit(sel, editC)) {
			_tee = new EditEnd(table, createTextEditor(table, sel.getText(editC)), &end);
			editor.setEditor(_tee.editor, sel, editC);
			_tee.setFocus;
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
		if (tree.getSelectionCount == 1) {
			auto itm = tree.getSelection[0];
			if (itm.getBounds.contains(x, y)) {
				return itm;
			}
		}
		return null;
	}
	Item selectionK() {
		if (tree.getSelectionCount == 1) {
			return tree.getSelection[0];
		}
		return null;
	}

	void end(Control ctrl) {
		editEnd(editor.getItem, ctrl);
	}

	void startEdit(Item itm) {
		if (_tee !is null && !_tee.isExit) _tee.enter;
		auto sel = cast(TreeItem) itm;
		auto c = createEditor(sel);
		if (c) {
			_tee = new EditEnd(tree, c, &end);
			editor.setEditor(_tee.editor, sel);
			_tee.setFocus;
		}
	}
public:
	/// tree = テキスト編集対象のツリー。
	/// editEnd = 編集終了時に実行される関数。
	/// createEditor = ツリーアイテムが編集するコンポーネントを生成する関数。
	///                nullを返した場合、編集は開始されない。
	this(Tree tree, void delegate(TreeItem itm, Control ctrl) editEnd,
			Control delegate(TreeItem itm) createEditor = null) {
		this.tree = tree;
		this.editEnd = editEnd;
		this.createEditor = createEditor;
		editor = new TreeEditor(tree);
		editor.grabHorizontal = true;

		auto mf = new TextEditMFListener(&startEdit, &selectionK, &selectionM);
		tree.addMouseListener(mf);
		tree.addSelectionListener(mf);
		tree.addKeyListener(new TextEditKListener(&startEdit, &selectionK));
	}
	/// 選択されているセルの編集を開始する。
	void startEdit() {
		auto sels = tree.getSelection;
		if (sels.length == 1) {
			startEdit(sels[0]);
		}
	}
}

interface TCPD {
public:
	void cut();
	void copy();
	void paste();
	void del();
	bool canDoTCPD();
}

void appendMenuTCPD(Props prop, Menu me, TCPD tcpd, bool t = true, bool c = true, bool p = true, bool d = false) {
	class InTCPD {
		TCPD tcpd;
		void cut() {
			if (cast(Text) Display.getCurrent.getFocusControl) {
				(cast(Text) Display.getCurrent.getFocusControl).cut;
			} else if (cast(Combo) Display.getCurrent.getFocusControl) {
				(cast(Combo) Display.getCurrent.getFocusControl).cut;
			} else if (cast(CCombo) Display.getCurrent.getFocusControl) {
				(cast(CCombo) Display.getCurrent.getFocusControl).cut;
			} else {
				tcpd.cut;
			}
		}
		void copy() {
			if (cast(Text) Display.getCurrent.getFocusControl) {
				(cast(Text) Display.getCurrent.getFocusControl).copy;
			} else if (cast(Combo) Display.getCurrent.getFocusControl) {
				(cast(Combo) Display.getCurrent.getFocusControl).copy;
			} else if (cast(CCombo) Display.getCurrent.getFocusControl) {
				(cast(CCombo) Display.getCurrent.getFocusControl).copy;
			} else {
				tcpd.copy;
			}
		}
		void paste() {
			if (cast(Text) Display.getCurrent.getFocusControl) {
				(cast(Text) Display.getCurrent.getFocusControl).paste;
			} else if (cast(Combo) Display.getCurrent.getFocusControl) {
				(cast(Combo) Display.getCurrent.getFocusControl).paste;
			} else if (cast(CCombo) Display.getCurrent.getFocusControl) {
				(cast(CCombo) Display.getCurrent.getFocusControl).paste;
			} else {
				tcpd.paste;
			}
		}
		void del() {
			if (cast(Text) Display.getCurrent.getFocusControl) {
				(cast(Text) Display.getCurrent.getFocusControl).insert("");
			} else {
				tcpd.del;
			}
		}
	}
	auto itcpd = new InTCPD;
	itcpd.tcpd = tcpd;
	if (t) createMenuItem(me, prop.msgs.menuCut, prop.images.menuCut, &itcpd.cut);
	if (c) createMenuItem(me, prop.msgs.menuCopy, prop.images.menuCopy, &itcpd.copy);
	if (p) createMenuItem(me, prop.msgs.menuPaste, prop.images.menuPaste, &itcpd.paste);
	if (d) createMenuItem(me, prop.msgs.menuDel, prop.images.menuDel, &itcpd.del);
}

void usingPopupMenuAccelerator(Control c) {
	static int toAccelerator(MenuItem mi) {
		if (mi.getAccelerator != 0) {
			return mi.getAccelerator;
		}
		int acc = convertAccelerator(mi.getText);
		mi.setAccelerator = acc;
		return acc;
	}
	c.addKeyListener(new class KeyAdapter {
		private static bool doMenu(KeyEvent e, Menu menu) {
			if (menu) {
				foreach (mi; menu.getItems) {
					int acc = toAccelerator(mi);
					bool eqAcc() {
						if ((acc & DWT.MODIFIER_MASK) == acc) {
							return (e.keyCode | e.stateMask) == acc;
						} else if (toupper(e.keyCode) == toupper(e.character)) {
							return (toupper(e.keyCode) | e.stateMask) == acc
								|| (tolower(e.keyCode) | e.stateMask) == acc;
						} else {
							return (toupper(e.keyCode) | e.stateMask) == acc
								|| (tolower(e.keyCode) | e.stateMask) == acc
								|| (toupper(e.character) | (e.stateMask ^ DWT.SHIFT)) == acc
								|| (tolower(e.character) | (e.stateMask ^ DWT.SHIFT)) == acc
								|| (toupper(e.character) | e.stateMask) == acc
								|| (tolower(e.character) | e.stateMask) == acc;
						}
					}
					if (eqAcc) {
						scope evt = new Event;
						evt.widget = e.widget;
						mi.notifyListeners(DWT.Selection, evt);
						e.doit = false;
						return true;
					}
				}
				foreach (mi; menu.getItems) {
					if (doMenu(e, mi.getMenu)) return true;
				}
			}
			return false;
		}
		override void keyPressed(KeyEvent e) {
			doMenu(e, (cast(Control) e.widget).getMenu);
		}
	});
}

int convertAccelerator(string text) {
	int t_index = lastIndexOf(text, '\t');
	if (t_index >= 0 && t_index < text.length - 1) {
		string acc_text = text[t_index + 1 .. $];
		int acc = 0;
		string kc;
		while (true) {
			int p_index = dwt.dwthelper.utils.indexOf(acc_text, '+');
			if (p_index >= 0 && p_index < acc_text.length - 1) {
				acc |= Action.findModifier(acc_text[0 .. p_index]);
				acc_text = acc_text[p_index + 1 .. $];
			} else {
				kc = acc_text;
				break;
			}
		}
		if (kc.length > 1) {
			try {
				acc |= Action.findKeyCode(kc);
			} catch {
				acc |= Action.findModifier(kc);
			}
		} else {
			acc |= kc[0];
		}
		return acc;
	}
	return 0;
}

MenuItem createMenuItem(Menu sub, string text, Image img,
		void delegate() func, int style = DWT.PUSH) {
	auto itm = new MenuItem(sub, style);
	itm.setText = text;
	int accr = convertAccelerator(text);
	if (accr > -1) {
		itm.setAccelerator = accr;
	}
	itm.addSelectionListener(new class SelectionAdapter {
		private void delegate() _func;
		public this() {_func = func;}
		public override void widgetSelected(SelectionEvent e) {
			_func();
		}
	});
	if (img) itm.setImage = img;
	return itm;
}
Menu createMenu(Menu bar, string text) {
	auto menu = new Menu(bar.getShell, DWT.DROP_DOWN);
	auto mi = new MenuItem(bar, DWT.CASCADE);
	mi.setText = text;
	mi.setMenu = menu;
	return menu;
}

ToolItem createToolItem(ToolBar bar, string tip, string text, Image img,
		void delegate() func, int style = DWT.PUSH) {
	auto itm = new ToolItem(bar, style);
	itm.setText = text;
	itm.setToolTipText = tip;
	itm.setImage = img;
	itm.addSelectionListener(new class SelectionAdapter {
		private void delegate() _func;
		public this() {_func = func;}
		public override void widgetSelected(SelectionEvent e) {_func();}
	});
	return itm;
}

ToolItem createToolItem(ToolBar bar, string text, Image img,
		void delegate() func, int style = DWT.PUSH) {
	return createToolItem(bar, text, null, img, func, style);
}

ToolItem createToolItem(ToolBar bar, string tip, string text, Image img,
		void delegate(ToolItem) func, int style = DWT.PUSH) {
	auto itm = new ToolItem(bar, style);
	itm.setText = text;
	itm.setToolTipText = tip;
	itm.setImage = img;
	itm.addSelectionListener(new class SelectionAdapter {
		private void delegate(ToolItem) _func;
		public this() {_func = func;}
		public override void widgetSelected(SelectionEvent e) {_func(cast(ToolItem) e.widget);}
	});
	return itm;
}

ToolItem createToolItem(ToolBar bar, string text, Image img,
		void delegate(ToolItem) func, int style = DWT.PUSH) {
	return createToolItem(bar, text, null, img, func, style);
}

Shell topShell(Shell shell) {
	auto parent = cast(Shell) shell.getParent;
	while (parent.getParent) {
		parent = cast(Shell) parent.getParent;
	}
	return parent;
}
class CloseRemover(Window) : ShellAdapter {
	private HashSet!(Window) _ws;
	private Window _w;
	public this(HashSet!(Window) ws, Window w) {
		_ws = ws;
		_w = w;
	}
	public override void shellClosed(ShellEvent e) {
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
			e.detail = DND.DROP_COPY;
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
				} catch (DWTException e) {
				}
			}
			if (paths.length > 0) {
				doExit;
			}
		}
	}
public:
	this(Control c) {
		_c = c;
		auto target = new DropTarget(c, DND.DROP_DEFAULT | DND.DROP_COPY);
		target.setTransfer([FileTransfer.getInstance]);
		target.addDropListener(new DListener);
	}
	Control control() {
		return _c;
	}
	protected string[] doAll(string[] files) {
		return files;
	}
	protected void doExit() {
	}
	protected abstract bool doFile(string path, int x, int y);
}

class RadioGroup(B : Widget) {
public:
	this() {
		_l = new L;
	}
	void select(B b) {
		if (_sel !is b) {
			_sel.setSelection = false;
			b.setSelection = true;
			_sel = b;
		}
	}
	void append(B b) {
		assert ((b.getStyle & DWT.RADIO) != 0);
		if (_sel is null){
			if (b.getSelection) {
				_sel = b;
			}
		} else {
			b.setSelection = false;
		}
		b.addListener(DWT.Selection, _l);
	}
private:
	B _sel = null;
	Listener _l;
	class L : Listener {
		public override void handleEvent(Event e) {
			auto b = cast(B) e.widget;
			if (_sel is null) {
				_sel = b;
			} else if (b !is _sel) {
				_sel.setSelection = false;
				_sel = b;
			}
		}
	}
}

TreeItem createTreeItem(T)(T parent, Object data, string text, Image img, int index = -1) {
	TreeItem r;
	if (index >= 0) {
		r = new TreeItem(parent, DWT.NONE, index);
	} else {
		r = new TreeItem(parent, DWT.NONE);
	}
	r.setData = data;
	r.setText = text;
	r.setImage = img;
	return r;
}

TreeItem topItem(TreeItem itm) {
	if (!itm) return null;
	if (itm.getParentItem) {
		return topItem(itm.getParentItem);
	}
	return itm;
}
int treeItemUp(TreeItem itm) {
	return __treeItemUD!("i > 0", "i - 1")(itm);
}
int treeItemDown(TreeItem itm) {
	return __treeItemUD!("i + 1 < parent.getItemCount", "i + 2")(itm);
}
private int __treeItemUD(string SwapOK, string ToIndex)(TreeItem itm) {
	auto tree = itm.getParent;
	auto p = itm.getParentItem;
	if (p is null) {
		return __treeItemUD2!(Tree, SwapOK, ToIndex)(tree, itm);
	} else {
		return __treeItemUD2!(TreeItem, SwapOK, ToIndex)(p, itm);
	}
}
private int __treeItemUD2(T, string SwapOK, string ToIndex)(T parent, TreeItem itm) {
	int i = parent.indexOf(itm);
	auto tree = itm.getParent;
	if (mixin (SwapOK)) {
		auto ti = cloneItem!(T)(parent, itm, mixin (ToIndex));
		foreach (sel; tree.getSelection) {
			if (sel is itm) {
				tree.setSelection(ti);
				break;
			}
		}
		itm.dispose;
		return i;
	}
	return -1;
}
private TreeItem cloneItem(T)(T parent, TreeItem old, int index) {
	auto ti = new TreeItem(parent, old.getStyle, index);
	ti.setData = old.getData;
	ti.setChecked = old.getChecked;
	ti.setForeground = old.getForeground;
	ti.setBackground = old.getBackground;
	ti.setGrayed = old.getGrayed;
	ti.setFont = old.getFont;
	int imgCount = old.getParent.getColumnCount + 1;
	for (int i = 0; i < imgCount; i++) {
		ti.setText(i, old.getText(i));
		ti.setImage(i, old.getImage(i));
	}
	foreach (i, itm; old.getItems) {
		cloneItem(ti, itm, i);
	}
	ti.setExpanded = old.getExpanded;
	return ti;
}

void treeExpandedAll(TreeItem tree) {
	foreach (itm; tree.getItems) {
		treeExpandedAll(itm);
	}
	tree.setExpanded = true;
}
void treeExpandedAll(Tree tree) {
	tree.setRedraw = false;
	foreach (itm; tree.getItems) {
		treeExpandedAll(itm);
	}
	tree.setRedraw = true;
}
void treeUnexpandedAll(TreeItem tree) {
	foreach (itm; tree.getItems) {
		treeUnexpandedAll(itm);
	}
	tree.setExpanded = false;
}
void treeUnexpandedAll(Tree tree) {
	tree.setRedraw = false;
	foreach (itm; tree.getItems) {
		treeUnexpandedAll(itm);
	}
	tree.setRedraw = true;
}

bool openFolder(string path) {
	path = nabs(path);
	version (Windows) {
		return exec("explorer " ~ path, path);
	} else {
		return Program.launch(path);
	}
}

ImageData castCardImage(Props prop, Skin skin, CastCard c, string sPath) {
	auto cardSize = prop.looks.cardSize;
	auto matPad = prop.looks.castCardInsets;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	scope r = new PileImage(castCard(skin), w, h);
	r.append(skin.findImagePath(c.path, sPath), matPad, true);
	r.setTitle(c.name, dwtData(prop.looks.castCardNameFont), dwtData(prop.looks.castCardNamePoint));
	return r.createImageData;
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
		switch (c.premium) {
		case Premium.PREMIUM, Premium.RARE:
			scope pp = prop.looks.premiumXY;
			auto img = c.premium == Premium.PREMIUM
			? premier(skin) : rare(skin);
			r.append(img, CInsets(pp.y, pp.x, h - pp.y - img.height, w - pp.x - img.width));
			r.append(img, CInsets(h - pp.y - img.height, w - pp.x - img.width, pp.y, pp.x));
		case Premium.NORMAL:
		}
	}
	r.append(skin.findImagePath(c.path, sPath), matPad, true);
	static if (!is (C == InfoCard)) {
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
	r.setTitle(c.name, dwtData(prop.looks.cardNameFont), dwtData(prop.looks.cardNamePoint));
	return r.createImageData;
}

void addCastCoupons(Combo combo, Props prop, bool talker) {
	if (!talker) {
		foreach (c; prop.var.etc.standardCoupons) {
			combo.add(c);
		}
	}
	foreach (e; SEX_ALL) {
		combo.add(prop.sys.sexCoupon(e));
	}
	foreach (e; PERIOD_ALL) {
		combo.add(prop.sys.periodCoupon(e));
	}
	foreach (e; NATURE_DEF) {
		combo.add(prop.sys.natureCoupon(e));
	}
	foreach (e; MAKINGS_LEFT) {
		combo.add(prop.sys.makingsCoupon(e));
		combo.add(prop.sys.makingsCoupon(reverseMakings(e)));
	}
}

S[] loadScenarios(S)(Props prop, Shell w, bool expandXMLs, string dlgTitle, void delegate (S[]) loaded = null, bool oThr = true) {
	auto dlg = new FileDialog(w, DWT.PRIMARY_MODAL | DWT.APPLICATION_MODAL | DWT.MULTI | DWT.OPEN);
	scope (exit) dlg.dispose;
	dlg.setFilterExtensions = ["*.wsn;Summary.xml;Summary.wsm"];
	dlg.setFilterNames = [prop.msgs.filterScenario];
	dlg.setText = dlgTitle;
	dlg.setFilterPath = scenarioFilterPath(prop);
	string fname = dlg.open;
	if (fname) {
		auto put = new class Object {
			Props prop;
			string filterPath;
			void delegate (S[]) loaded;
			void put(S[] r) {
				if (r.length) {
					filterPath = nabs(filterPath);
					prop.var.etc.scenarioPath = r[0u].useTemp ? filterPath : getDirName(filterPath);
				}
				if (loaded) loaded(r);
			}
		};
		put.prop = prop;
		put.filterPath = dlg.getFilterPath;
		put.loaded = loaded;
		string[] files;
		foreach (file; dlg.getFileNames) {
			files ~= std.path.join(dlg.getFilterPath, file);
		}
		S[] r = loadScenariosFromFile!(S)(prop, w, expandXMLs, files, &put.put, oThr);
		if (!oThr && r.length) put.put(r);
		return r;
	}
	return [];
}

S[] loadScenariosFromFile(S)(Props prop, Shell w, bool expandXMLs, string[] files, void delegate (S[]) loaded = null, bool oThr = true) {
	auto display = Display.getCurrent;
	if (oThr && loaded) {
		auto thr = new class Object {
			Display display;
			Props prop;
			Shell w;
			bool expandXMLs;
			string[] files;
			void delegate (S[]) loaded;
			string oldTit;
			int run() {
				string[] temps;
				void clear() {
					foreach (temp; temps) {
						delAll(temp);
					}
				}
				scope (exit) {
					display.syncExec(new class Runnable {
						void run() {
							try {
								w.setCursor = null;
								w.setEnabled = true;
							} catch {
								clear;
							}
						}
					});
				}
				string fname;
				uint max;
				uint worked;
				auto setWorked = new class Runnable {
					void run() {
						try {
							w.setText = prop.msgs.loadProgress(fname, max, worked);
						} catch {
							clear;
						}
					}
				};
				S[] r;
				foreach (i, path; files) {
					fname = path;
					S s = loadScenarioFromFileImpl!(S)(prop, w, expandXMLs, null, path, null, false, display,
						(uint maxv) {
							max = maxv;
							display.syncExec(setWorked);
						}, (uint workedv) {
							worked = workedv;
							display.asyncExec(setWorked);
						});
					if (s) {
						r ~= s;
						if (s.useTemp) temps ~= s.scenarioPath;
					} else {
						break;
					}
				}
				if (r.length) {
					display.syncExec(new class Runnable {
						void run() {
							try {
								w.setText = oldTit;
								loaded(r);
								return;
							} catch (Exception e) {
								debugln(e);
								MessageBox.showWarning(e.msg, prop.msgs.dlgTitWarning, w);
								clear;
							} catch {
								clear;
							}
						}
					});
				}
				return 0;
			}
		};
		thr.display = display;
		thr.prop = prop;
		thr.w = w;
		thr.expandXMLs = expandXMLs;
		thr.files = files;
		thr.loaded = loaded;
		thr.oldTit = w.getText;
		w.setCursor = display.getSystemCursor(DWT.CURSOR_WAIT);
		scope (exit) w.setCursor = null;
		auto t = new Thread(&thr.run);
		t.start;
		return [];
	} else {
		w.setCursor = Display.getCurrent.getSystemCursor(DWT.CURSOR_WAIT);
		scope (exit) w.setCursor = null;
		S[] r;
		foreach (i, path; files) {
			S s = loadScenarioFromFileImpl!(S)(prop, w, expandXMLs, null, path, null, false, display);
			if (s) {
				r ~= s;
			} else {
				break;
			}
		}
		return r;
	}
}

string scenarioFilterPath(Props prop) {
	if (prop.var.etc.scenarioPath.length == 0) {
		return nabs(std.path.join(getDirName(prop.var.etc.enginePath), "Scenario"));
	} else {
		return nabs(prop.var.etc.scenarioPath);
	}
}

S loadScenario(S)(Props prop, Shell w, bool expandXMLs, S old, string dlgTitle, void delegate (S) loaded = null, bool oThr = true) {
	auto dlg = new FileDialog(w, DWT.PRIMARY_MODAL | DWT.APPLICATION_MODAL | DWT.SINGLE | DWT.OPEN);
	scope (exit) dlg.dispose;
	dlg.setFilterExtensions = ["*.wsn;Summary.xml;Summary.wsm"];
	dlg.setFilterNames = [prop.msgs.filterScenario];
	dlg.setText = dlgTitle;
	dlg.setFilterPath = scenarioFilterPath(prop);
	string fname = dlg.open;
	if (fname) {
		auto put = new class Object {
			Props prop;
			string filterPath;
			void delegate (S) loaded;
			void put(S r) {
				if (r) {
					filterPath = nabs(filterPath);
					prop.var.etc.scenarioPath = r.useTemp ? filterPath : getDirName(filterPath);
				}
				if (loaded) loaded(r);
			}
		};
		put.prop = prop;
		put.filterPath = dlg.getFilterPath;
		put.loaded = loaded;
		S r = loadScenarioFromFile!(S)(prop, w, expandXMLs, old, fname, &put.put, oThr);
		if (!oThr && r) put.put(r);
		return r;
	}
	return null;
}

S loadScenarioFromFile(S)(Props prop, Shell w, bool expandXMLs, S old, string fname, void delegate (S) loaded = null, bool oThr = true) {
	return loadScenarioFromFileImpl!(S)(prop, w, expandXMLs, old, fname, loaded, oThr, null);
}
private S loadScenarioFromFileImpl(S)(Props prop, Shell w, bool expandXMLs, S old, string fname, void delegate (S) loaded = null, bool oThr = true, Display current = null,
		void delegate (uint) setMax = null, void delegate (uint) worked = null) {
	if (oThr && loaded) {
		auto thr = new class Object {
			Display display;
			Display current;
			Props prop;
			Shell w;
			bool expandXMLs;
			S old;
			string fname;
			void delegate (S) loaded;
			string oldTit;
			int run() {
				string temp = "";
				void clear() {
					if (temp.length) delAll(temp);
				}
				scope (exit) {
					if (!current) {
						display.syncExec(new class Runnable {
							void run() {
								try {
									w.setCursor = null;
									w.setEnabled = true;
								} catch {
									clear;
								}
							}
						});
					}
				}
				uint worked = 0u;
				uint max;
				auto setWorked = new class Runnable {
					void run() {
						try {
							w.setText = prop.msgs.loadProgress(fname, max, worked);
						} catch {
							clear;
						}
					}
				};
				try {
					S r = S.loadScenarioFromFile(prop.parent, fname, prop.var.etc.expandXMLs, prop.tempPath, old,
						(uint maxv) {
							max = maxv;
							display.syncExec(setWorked);
						}, (uint workedv) {
							worked = workedv;
							display.asyncExec(setWorked);
						});
					temp = r.useTemp ? r.scenarioPath : "";
					if (r) {
						display.syncExec(new class Runnable {
							void run() {
								try {
									w.setText = oldTit;
									loaded(r);
								} catch (Exception e) {
									debugln(e);
									MessageBox.showWarning(e.msg, prop.msgs.dlgTitWarning, w);
								} catch {
									clear;
								}
							}
						});
					}
				} catch (SummaryException e) {
					display.asyncExec(new class Runnable {
						void run() {
							try {
								MessageBox.showWarning(e.msg, prop.msgs.dlgTitWarning, w);
							} catch {
								clear;
							}
						}
					});
				}
				return 0;
			}
		};
		thr.display = current ? current : Display.getCurrent;
		thr.current = current;
		thr.prop = prop;
		thr.w = w;
		thr.expandXMLs = expandXMLs;
		thr.old = old;
		thr.fname = fname;
		thr.loaded = loaded;
		if (!current) {
			w.setCursor = Display.getCurrent.getSystemCursor(DWT.CURSOR_WAIT);
			w.setEnabled = false;
			thr.oldTit = w.getText;
		}
		auto t = new Thread(&thr.run);
		t.start;
		return null;
	} else {
		if (!current) w.setCursor = Display.getCurrent.getSystemCursor(DWT.CURSOR_WAIT);
		scope (exit) {
			if (!current) w.setCursor = null;
		}
		try {
			return S.loadScenarioFromFile(prop.parent, fname, prop.var.etc.expandXMLs, prop.tempPath, old, setMax, worked);
		} catch (SummaryException e) {
			MessageBox.showWarning(e.msg, prop.msgs.dlgTitWarning, w);
		}
	}
	return null;
}

bool qMaterialCopy(Props prop, Skin skin, Shell shell,
		UseCounter uc, string toSPath, string fromSPath, out bool copy, bool toIsLegacy) {
	copy = false;
	string[] paths;
	foreach (key; uc.path.keys) {
		string path = cast(string) key;
		if (key.isBinImg) {
			paths ~= path;
		} else if (exists(std.path.join(fromSPath, path))) {
			paths ~= path;
		}
	}
	if (paths.length == 0) return true;
	auto copyM = new MessageBox(shell, DWT.YES | DWT.NO | DWT.CANCEL | DWT.ICON_QUESTION);
	scope (exit) copyM.dispose;
	copyM.setText = prop.msgs.dlgTitQuestion;
	uint bin = 0u;
	string[] msgPaths;
	foreach (p; paths) {
		if (isBinImg(p)) {
			bin++;
		} else {
			msgPaths ~= std.path.join(fromSPath, p);
		}
	}
	copyM.setMessage = prop.msgs.dlgMsgCopyMaterial(msgPaths, bin);
	switch (copyM.open) {
	case DWT.YES:
		bool err = false;
		foreach (i, key; paths) {
			string path = isBinImg(key) ? key : std.path.join(fromSPath, key);
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
	case DWT.NO:
		if (!toIsLegacy) {
			foreach (key; uc.path.keys) {
				if (key.isBinImg) {
					uc.change(key, toPathId(""), true);
				}
			}
		}
		return true;
	case DWT.CANCEL:
		return false;
	}
}

void saveColumnWidth(string Value)(Props prop, TableColumn col) {
	col.setWidth = mixin (Value);
	static if (is (typeof(mixin(Value ~ " = 0")) == void)) {
		static class SaveColumnWidth : DisposeListener {
			Props prop;
			this(Props prop) {
				this.prop = prop;
			}
			override void widgetDisposed(DisposeEvent e) {
				int width = (cast(TableColumn) e.widget).getWidth;
				mixin (Value ~ " = width;");
			}
		}
		col.addDisposeListener(new SaveColumnWidth(prop));
	}
}

void intoDisplay(ref int x, ref int y, int w, int h) {
	auto pb = Display.getCurrent.getClientArea;
	if (pb.x + pb.width < x + w) x = pb.x + pb.width - w;
	if (pb.y + pb.height < y + h) y = pb.y + pb.height - h;
	if (x < pb.x) x = pb.x;
	if (y < pb.y) y = pb.y;
}

class StopBGM : SelectionAdapter, DisposeListener {
	override void widgetSelected(SelectionEvent e) {
		stopSE;
	}
	override void widgetDisposed(DisposeEvent e) {
		stopBGM;
	}
}
class StopSE : SelectionAdapter, DisposeListener {
	override void widgetSelected(SelectionEvent e) {
		stopSE;
	}
	override void widgetDisposed(DisposeEvent e) {
		stopSE;
	}
}

Image skeletonImage(Image src, bool mask = true) {
	auto data = src.getImageData;
	auto img = new Image(Display.getCurrent, data.width, data.height);
	scope gc = new GC(img);
	gc.setAlpha = 0x7F;
	scope (exit) gc.dispose;
	gc.drawImage(src, 0, 0);
	if (!mask) return img;
	scope (exit) img.dispose;
	data = img.getImageData;
	data.transparentPixel = data.getPixel(0, 0);
	return new Image(Display.getCurrent, data);
}

Composite createDefSoundCombo(Props prop, Skin skin, Composite parent, out Combo combo, string title = null) {
	static class PlaySE : SelectionAdapter {
		private Skin _skin;
		private Combo _combo;
		this(Skin skin, Combo combo) {
			_skin = skin;
			_combo = combo;
		}
		override void widgetSelected(SelectionEvent e) {
			if (_combo.getSelectionIndex > 0) {
				playSE(std.path.join(_skin.seDir, _combo.getText));
			}
		}
	}
	auto comp2 = new Composite(parent, DWT.NONE);
	if (title) {
		comp2.setLayout = zeroMarginGridLayout(2, true);
		auto l = new CLabel(comp2, DWT.NONE);
		auto gdl = new GridData(GridData.FILL_HORIZONTAL);
		gdl.horizontalSpan = 2;
		l.setLayoutData = gdl;
		l.setImage = prop.images.sound;
		l.setText = title;
	} else {
		comp2.setLayout = zeroMarginGridLayout(3, false);
	}
	combo = new Combo(comp2, DWT.BORDER | DWT.READ_ONLY | DWT.DROP_DOWN);
	combo.setVisibleItemCount = 20;
	auto gdc = new GridData(GridData.FILL_HORIZONTAL);
	if (title) {
		gdc.horizontalSpan = 2;
	}
	combo.setLayoutData = gdc;
	combo.setItems = prop.msgs.soundNone ~ skin.sounds;
	auto stop = new Button(comp2, DWT.PUSH);
	if (title) {
		stop.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
	}
	stop.setImage = prop.images.stopSound;
	stop.setToolTipText = prop.msgs.stopSound;
	auto sse = new StopSE;
	stop.addSelectionListener(sse);
	stop.addDisposeListener(sse);
	auto play = new Button(comp2, DWT.PUSH);
	if (title) {
		play.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
	}
	play.setImage = prop.images.playSound;
	play.setToolTipText = prop.msgs.playSound;
	play.addSelectionListener(new PlaySE(skin, combo));
	return comp2;
}
Composite createSuccessRateScale(Props prop, Composite parent, out Scale sucRate) {
	auto grp = new Group(parent, DWT.NONE);
	grp.setText = prop.msgs.successRate;
	grp.setLayout = new GridLayout(3, false);
	auto allf = new Label(grp, DWT.CENTER);
	allf.setText = prop.msgs.allFail;
	sucRate = new Scale(grp, DWT.NONE);
	sucRate.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
	// 0以上でないといけないらしい
	sucRate.setMinimum = 0;
	sucRate.setMaximum = prop.looks.successRateMax * 2;
	sucRate.setPageIncrement = prop.looks.successRateMax;
	auto alls = new Label(grp, DWT.CENTER);
	alls.setText = prop.msgs.allSuccess;
	return grp;
}

void putRadioValue(E)(Button[E] radios, void delegate(E) set) {
	set(getRadioValue!(E)(radios));
}

E getRadioValue(E)(Button[E] radios) {
	foreach (e, radio; radios) {
		if (radio.getSelection) {
			return e;
		}
	}
	assert (0);
}

void forceFocus(Widget widget) {
	forceFocusImpl(widget, null);
}

private void forceFocusImpl(Widget widget, Widget child) {
	auto ti = cast(TableItem) widget;
	if (ti) {
		auto tbl = ti.getParent;
		forceFocusImpl(tbl, null);
		tbl.setSelection = ti;
		tbl.showSelection;
		return;
	}
	auto tri = cast(TreeItem) widget;
	if (tri) {
		auto tree = tri.getParent;
		forceFocusImpl(tree, null);
		tree.select = tri;
		tree.showSelection;
		return;
	}
	auto sh = cast(Shell) widget;
	if (sh) {
		sh.setActive;
		return;
	}
	auto tf = cast(TabFolder) widget;
	if (tf) {
		foreach (i; tf.getItems) {
			if (i.getControl is child) {
				forceFocusImpl(tf.getParent, tf);
				tf.setSelection = i;
				return;
			}
		}
		assert (0);
	}
	auto ctf = cast(CTabFolder) widget;
	if (ctf) {
		foreach (i; ctf.getItems) {
			if (i.getControl is child) {
				forceFocusImpl(ctf.getParent, ctf);
				ctf.setSelection = i;
				return;
			}
		}
		assert (0);
	}
	auto ctl = cast(Control) widget;
	if (ctl) {
		forceFocusImpl(ctl.getParent, ctl);
		ctl.setFocus;
		return;
	}
	assert (0);
}
