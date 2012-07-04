/// FIXME: リンクエラーを避けるためdutils.dを分割
module cwx.editor.gui.dwt.dmenu;

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
import cwx.graphics;
import cwx.path;
import cwx.msgs;
import cwx.menu;
import cwx.variables;

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
import cwx.editor.gui.dwt.dutils;

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
import org.eclipse.swt.events.MenuAdapter;
import org.eclipse.swt.events.MenuEvent;
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

version (Windows) {
	import org.eclipse.swt.internal.win32.OS;
	import org.eclipse.swt.internal.win32.WINTYPES;
}

import java.lang.all;
import java.io.ByteArrayInputStream;

/// Text/Combo/CComboに、アンドゥ・リドゥ及び
/// 切り取り・コピー・貼り付け・削除のメニューをつける。
TextMenuModify createTextMenu(T = Text)(Commons comm, Props prop, T text, bool delegate() canSaveHistory, UndoManager undo = null, TMAppendData apd = TMAppendData()) {
	static if (is(T:Text)) {
		text.setTabs(prop.var.etc.textTabs);
	}
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
		ml.selectChanged = &comm.refreshToolBar;
		text.addModifyListener(ml);
		class Modify : ModifyListener {
			override void modifyText(ModifyEvent e) {
				comm.refreshToolBar();
			}
		}
		text.addModifyListener(new Modify);
	}

	auto menu = new Menu(text.getShell(), SWT.POP_UP);
	auto u = createMenuItem(comm, menu, MenuID.Undo, {undo.undo();}, () => undo !is null && undo.canUndo);
	auto r = createMenuItem(comm, menu, MenuID.Redo, {undo.redo();}, () => undo !is null && undo.canRedo);
	new MenuItem(menu, SWT.SEPARATOR);
	bool sel() {
		auto p = text.getSelection();
		return p.y > p.x;
	}
	auto t = createMenuItem(comm, menu, MenuID.Cut, {
		text.cut();
		comm.refreshToolBar();
	}, () => !readOnly && sel());
	auto c = createMenuItem(comm, menu, MenuID.Copy, {
		text.copy();
		comm.refreshToolBar();
	}, &sel);
	auto p = createMenuItem(comm, menu, MenuID.Paste, {
		text.paste();
		comm.refreshToolBar();
	}, () => !readOnly && CBisText(comm.clipboard));
	auto d = createMenuItem(comm, menu, MenuID.Delete, {
		auto p = text.getSelection();
		auto t = to!dstring(text.getText());
		if (t.length <= p.x) return;
		if (p.x != p.y) {
			text.setText(to!string(t[0 .. p.x] ~ t[p.y .. $]));
		} else {
			text.setText(to!string(t[0 .. p.x] ~ t[p.y + 1 .. $]));
		}
		text.setSelection(new Point(p.x, p.x));
		comm.refreshToolBar();
	}, () => !readOnly && sel());
	new MenuItem(menu, SWT.SEPARATOR);
	auto a = createMenuItem(comm, menu, MenuID.SelectAll, {
		text.setSelection(new Point(0, text.getText().length));
	}, {
		auto t = text.getText();
		if (t.length == 0) return false;
		auto p = text.getSelection();
		return p.x != 0 || p.y != to!dstring(text.getText()).length;
	});
	u.setEnabled(!readOnly);
	r.setEnabled(!readOnly);
	t.setEnabled(!readOnly);
	p.setEnabled(!readOnly);
	d.setEnabled(!readOnly);
	text.setMenu(menu);

	return ml;
}

interface TCPD {
public:
	void cut(SelectionEvent se);
	void copy(SelectionEvent se);
	void paste(SelectionEvent se);
	void del(SelectionEvent se);
	@property bool canDoTCPD();
	@property bool canDoT();
	@property bool canDoC();
	@property bool canDoP();
	@property bool canDoD();
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
void appendMenuTCPD(Commons comm, TopLevelPanel tlp, TCPD tcpd,
		bool t = true, bool c = true, bool p = true, bool d = false) {
	auto itcpd = new InTCPD;
	itcpd.tcpd = tcpd;
	if (t) tlp.putMenuAction(MenuID.Cut, &itcpd.cut, &tcpd.canDoT);
	if (c) tlp.putMenuAction(MenuID.Copy, &itcpd.copy, &tcpd.canDoC);
	if (p) tlp.putMenuAction(MenuID.Paste, &itcpd.paste, &tcpd.canDoP);
	if (d) tlp.putMenuAction(MenuID.Delete, &itcpd.del, &tcpd.canDoD);
}
void appendMenuTCPD(Commons comm, Menu me, TCPD tcpd,
		bool t = true, bool c = true, bool p = true, bool d = false) {
	auto itcpd = new InTCPD;
	itcpd.tcpd = tcpd;
	if (t) createMenuItem(comm, me, MenuID.Cut, &itcpd.cut, &tcpd.canDoT);
	if (c) createMenuItem(comm, me, MenuID.Copy, &itcpd.copy, &tcpd.canDoC);
	if (p) createMenuItem(comm, me, MenuID.Paste, &itcpd.paste, &tcpd.canDoP);
	if (d) createMenuItem(comm, me, MenuID.Delete, &itcpd.del, &tcpd.canDoD);
}

interface IgnoreHotkey {
	// Nothing
}
class CIgnoreHotkey : IgnoreHotkey {
	// Nothing
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

string acceleratorText(int character) {
	switch (character) {
	case SWT.BS: return "Backspace";
	case SWT.CR: return "Enter";
	case SWT.DEL: return "Delete";
	case SWT.ESC: return "Esc";
	case SWT.TAB: return "Tab";
	case ' ': return "Space";
	case SWT.ARROW_UP: return "Arrow_Up";
	case SWT.ARROW_DOWN: return "Arrow_Down";
	case SWT.ARROW_LEFT: return "Arrow_Left";
	case SWT.ARROW_RIGHT: return "Arrow_Right";
	case SWT.PAGE_UP: return "Page_Up";
	case SWT.PAGE_DOWN: return "Page_Down";
	case SWT.HOME: return "Home";
	case SWT.END: return "End";
	case SWT.INSERT: return "Insert";
	case SWT.F1: return "F1";
	case SWT.F2: return "F2";
	case SWT.F3: return "F3";
	case SWT.F4: return "F4";
	case SWT.F5: return "F5";
	case SWT.F6: return "F6";
	case SWT.F7: return "F7";
	case SWT.F8: return "F8";
	case SWT.F9: return "F9";
	case SWT.F10: return "F10";
	case SWT.F11: return "F11";
	case SWT.F12: return "F12";
	case SWT.F13: return "F13";
	case SWT.F14: return "F14";
	case SWT.F15: return "F15";
	default:
		if (.isPrintable(character)) {
			return to!string(std.uni.toUpper(character));
		}
		break;
	}
	return "";
}

int convertAccelerator2(string acc_text) {
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
		case "arrow_up", "arrowup", "up": return SWT.ARROW_UP;
		case "arrow_down", "arrowdown", "down": return SWT.ARROW_DOWN;
		case "arrow_left", "arrowleft", "left": return SWT.ARROW_LEFT;
		case "arrow_right", "arrowright", "right": return SWT.ARROW_RIGHT;
		case "page_up", "pageup": return SWT.PAGE_UP;
		case "page_down", "pagedown": return SWT.PAGE_DOWN;
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
	} else if (kc.length) {
		acc |= kc[0];
	}
	return acc;
}
int convertAccelerator(string text) {
	int t_index = std.string.lastIndexOf(text, '\t');
	if (t_index >= 0 && t_index < text.length - 1) {
		string acc_text = text[t_index + 1 .. $];
		return convertAccelerator2(acc_text);
	}
	return 0;
} unittest {
	debug mixin(UTPerf);
	assert (convertAccelerator("test\tCTRL+ARROW_UP") == (SWT.ARROW_UP | SWT.CTRL));
	assert (convertAccelerator("test\tShift+A") == (SWT.SHIFT | 'A'));
	assert (convertAccelerator("test\tCtrl+Shift+A") == (SWT.CTRL | SWT.SHIFT | 'A'));
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
private void addRefMenu(Commons comm, MenuItem itm) {
	auto d = cast(MenuData) itm.getData();
	enforce(d);
	if (d.id == MenuID.None) return;

	void refMenu(MenuID id) {
		auto d = cast(MenuData) itm.getData();
		enforce(d);
		enforce(d.id != MenuID.None);
		if (d.id != id) return;
		string t = comm.prop.buildMenu(d.id);
		if (d.format) t = d.format(t);
		itm.setText(t);
	}
	class RefMenu : DisposeListener {
		override void widgetDisposed(DisposeEvent d) {
			comm.refMenu.remove(&refMenu);
		}
	}
	comm.refMenu.add(&refMenu);
	itm.addDisposeListener(new RefMenu);
}
class MenuShown : MenuAdapter {
	private MenuItem _itm;
	this (MenuItem itm) {
		_itm = itm;
	}
	override void menuShown(MenuEvent e) {
		auto d = cast(MenuData) _itm.getData();
		if (!d) return;
		if (!d.enabled) return;
		_itm.setEnabled(d.enabled());
	}
}
private MenuItem createMenuItemImpl(Dlg)(Commons comm, Menu sub, string text, Image img,
	Dlg func, int style, MenuID id, bool delegate() enabled) {
	auto itm = new MenuItem(sub, style);
	itm.setText(text);
	if (func) {
		itm.addSelectionListener(new MenuSel!(Dlg)(func));
	}
	if (img) itm.setImage(img);
	auto d = new MenuData();
	d.id = id;
	d.enabled = enabled;
	if (enabled) {
		auto menuShown = new MenuShown(itm);
		class Dispose : DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				sub.removeMenuListener(menuShown);
			}
		}
		sub.addMenuListener(menuShown);
		itm.addDisposeListener(new Dispose);
	}
	itm.setData(d);
	return itm;
}
MenuItem createMenuItem2(Commons comm, Menu sub, string text, Image img,
		void delegate(SelectionEvent se) func, bool delegate() enabled, int style = SWT.PUSH) {
	return createMenuItemImpl(comm, sub, text, img, func, style, MenuID.None, enabled);
}
MenuItem createMenuItem2(Commons comm, Menu sub, string text, Image img,
		void delegate() func, bool delegate() enabled, int style = SWT.PUSH) {
	return createMenuItemImpl(comm, sub, text, img, func, style, MenuID.None, enabled);
}
MenuItem createMenuItem(Commons comm, Menu sub, MenuID id,
		void delegate(SelectionEvent se) func, bool delegate() enabled, int style = SWT.PUSH) {
	auto mi = createMenuItemImpl(comm, sub, comm.prop.buildMenu(id), comm.prop.images.menu(id), func, style, id, enabled);
	addRefMenu(comm, mi);
	return mi;
}
MenuItem createMenuItem(Commons comm, Menu sub, MenuID id,
		void delegate() func, bool delegate() enabled, int style = SWT.PUSH) {
	auto mi = createMenuItemImpl(comm, sub, comm.prop.buildMenu(id), comm.prop.images.menu(id), func, style, id, enabled);
	addRefMenu(comm, mi);
	return mi;
}
private Menu createMenu2(Commons comm, Menu bar, string text, out MenuItem mi) {
	auto menu = new Menu(bar.getShell(), SWT.DROP_DOWN);
	mi = new MenuItem(bar, SWT.CASCADE);
	mi.setText(text);
	mi.setMenu(menu);
	auto d = new MenuData();
	d.id = MenuID.None;
	mi.setData(d);
	return menu;
}
Menu createMenu(Commons comm, Menu bar, MenuID id) {
	MenuItem mi;
	auto m = createMenu2(comm, bar, comm.prop.buildMenu(id), mi);
	(cast(MenuData) mi.getData()).id = id;
	addRefMenu(comm, mi);
	return m;
}

ToolItem createDropDownItem(Commons comm, ToolBar bar, MenuID id, void delegate() func, out Menu menu, bool delegate() enabled) {
	return createDropDownItem2(comm, bar, comm.prop.buildTool(id), comm.prop.images.menu(id), func, menu, id, enabled);
}
private ToolItem createDropDownItem2(Commons comm, ToolBar bar, string text, Image img, void delegate() func, out Menu menu, MenuID id, bool delegate() enabled) {
	auto ti = new ToolItem(bar, SWT.DROP_DOWN);
	ti.setToolTipText(text);
	ti.setImage(img);
	menu = new Menu(bar.getShell());
	class Push : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			if ((!func || SWT.ARROW == e.detail) && 0 < menu.getItemCount()) {
				auto b = ti.getBounds();
				auto pt = bar.toDisplay(b.x, b.y + b.height);
				menu.setLocation(pt);
				menu.setVisible(true);
			} else if (func) {
				func();
			}
		}
	}
	ti.addSelectionListener(new Push);
	auto d = new MenuData;
	d.id = id;
	d.enabled = enabled;
	ti.setData(d);
	return ti;
}
private ToolItem createToolItemImpl(Dlg)(Commons comm, ToolBar bar, string tip, string text, Image img,
		Dlg func, int style, MenuID id, bool delegate() enabled) {
	auto itm = new ToolItem(bar, style);
	itm.setText(text);
	itm.setToolTipText(tip);
	itm.setImage(img);
	if (func) {
		itm.addSelectionListener(new MenuSel!(Dlg)(func));
	}
	auto d = new MenuData;
	d.id = id;
	d.enabled = enabled;
	itm.setData(d);
	return itm;
}
ToolItem createToolItem2(Commons comm, ToolBar bar, string tip, string text, Image img,
		void delegate(SelectionEvent se) func, bool delegate() enabled, int style = SWT.PUSH) {
	return createToolItemImpl(comm, bar, tip, text, img, func, style, MenuID.None, enabled);
}
ToolItem createToolItem2(Commons comm, ToolBar bar, string tip, string text, Image img,
		void delegate() func, bool delegate() enabled, int style = SWT.PUSH) {
	return createToolItemImpl(comm, bar, tip, text, img, func, style, MenuID.None, enabled);
}
ToolItem createToolItem2(Commons comm, ToolBar bar, string text, Image img,
		void delegate(SelectionEvent se) func, bool delegate() enabled, int style = SWT.PUSH) {
	return createToolItemImpl!(void delegate(SelectionEvent))(comm, bar, text, null, img, func, style, MenuID.None, enabled);
}
ToolItem createToolItem2(Commons comm, ToolBar bar, string text, Image img,
		void delegate() func, bool delegate() enabled, int style = SWT.PUSH) {
	return createToolItemImpl!(void delegate())(comm, bar, text, null, img, func, style, MenuID.None, enabled);
}
private class ToolSel : SelectionAdapter {
	private void delegate(ToolItem) _func;
	public this(void delegate(ToolItem) func) {_func = func;}
	public override void widgetSelected(SelectionEvent e) {_func(cast(ToolItem) e.widget);}
}
ToolItem createToolItem2(Commons comm, ToolBar bar, string tip, string text, Image img,
		void delegate(ToolItem) func, bool delegate() enabled, int style = SWT.PUSH) {
	auto itm = new ToolItem(bar, style);
	itm.setText(text);
	itm.setToolTipText(tip);
	itm.setImage(img);
	if (func) {
		itm.addSelectionListener(new ToolSel(func));
	}
	auto d = new MenuData;
	d.id = MenuID.None;
	d.enabled = enabled;
	itm.setData(d);
	return itm;
}

ToolItem createToolItem(Commons comm, ToolBar bar, MenuID id,
		void delegate(ToolItem) func, bool delegate() enabled, int style = SWT.PUSH) {
	auto m = createToolItem2(comm, bar, comm.prop.buildTool(id), null, comm.prop.images.menu(id), func, enabled, style);
	(cast(MenuData) m.getData()).id = id;
	return m;
}
ToolItem createToolItem(Commons comm, ToolBar bar, MenuID id,
		void delegate(SelectionEvent se) func, bool delegate() enabled, int style = SWT.PUSH) {
	return createToolItemImpl(comm, bar, comm.prop.buildTool(id), null, comm.prop.images.menu(id), func, style, id, enabled);
}
ToolItem createToolItem(Commons comm, ToolBar bar, MenuID id,
		void delegate() func, bool delegate() enabled, int style = SWT.PUSH) {
	return createToolItemImpl(comm, bar, comm.prop.buildTool(id), null, comm.prop.images.menu(id), func, style, id, enabled);
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
CoolBar createCoolBar(string Name)(Commons comm, Composite parent,
		void delegate(CoolBar) setupItems) {
	auto cbar = new CoolBar(parent, SWT.NONE);

	setupItems(cbar);

	auto ls = new CBarListener!(Name)(comm.prop, cbar);
	cbar.addControlListener(ls);
	cbar.addDisposeListener(ls);

	auto menu = new Menu(parent.getShell(), SWT.POP_UP);
	ls._lock = createMenuItem(comm, menu, MenuID.LockToolBar, &ls.lock, null, SWT.CHECK);
	new MenuItem(menu, SWT.SEPARATOR);
	createMenuItem(comm, menu, MenuID.ResetToolBar, &ls.reset, null);
	cbar.setMenu(menu);

	foreach (itm; cbar.getItems()) {
		itm.getControl().setMenu(menu);
	}
	if (mixin ("comm.prop.var.etc." ~ Name ~ "Order.length") == cbar.getItemCount()) {
		cbar.setItemOrder(mixin ("comm.prop.var.etc." ~ Name ~ "Order.dup"));
	}
	int[] wi;
	foreach (i; mixin ("comm.prop.var.etc." ~ Name ~ "WrapIndices")) {
		if (i > 0 && i < cbar.getItemCount()) wi ~= i;
	}
	if (wi != cbar.getWrapIndices()) cbar.setWrapIndices(wi);
	cbar.setLocked(mixin ("comm.prop.var.etc." ~ Name ~ "Lock"));
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
