/// FIXME: リンクエラーを避けるためdutils.dを分割
module cwx.editor.gui.dwt.dmenu;

import cwx.types;
import cwx.utils;
import cwx.menu;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.undo;

import core.thread;

import std.algorithm;
import std.exception;
import std.array;
import std.conv;
import std.uni;
import std.utf;
import std.ascii : isPrintable;
import std.file;
import std.datetime;
import std.path;
import std.process;
import std.string;

import org.eclipse.swt.all;

version (Windows) {
	import org.eclipse.swt.internal.win32.OS;
	import org.eclipse.swt.internal.win32.WINTYPES;
}

import java.lang.all;
import java.io.ByteArrayInputStream;

/// Text/Combo/CComboに、アンドゥ・リドゥ及び
/// 切り取り・コピー・貼り付け・削除のメニューをつける。
TextMenuModify createTextMenu(T = Text)(Commons comm, Props prop, T text, bool delegate() canSaveHistory, UndoManager undo = null, TMAppendData apd = TMAppendData()) { mixin(S_TRACE);
	static if (is(T:Text)) {
		text.setTabs(prop.var.etc.textTabs);
	}
	bool readOnly = (text.getStyle() & SWT.READ_ONLY) != 0;
	if (!readOnly && !undo) { mixin(S_TRACE);
		undo = new UndoManager(prop.var.etc.undoMaxEtc);
		void refUndoMax() { mixin(S_TRACE);
			undo.max = prop.var.etc.undoMaxEtc;
		}
		comm.refUndoMax.add(&refUndoMax);
		text.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				comm.refUndoMax.remove(&refUndoMax);
			}
		});
	}
	TextMenuModify ml = null;
	if (!readOnly) { mixin(S_TRACE);
		ml = new TextMenuModify(TMM(text), canSaveHistory, undo, apd);
		ml.selectChanged = &comm.refreshToolBar;
		text.addModifyListener(ml);
		class Modify : ModifyListener {
			override void modifyText(ModifyEvent e) { mixin(S_TRACE);
				comm.refreshToolBar();
			}
		}
		text.addModifyListener(new Modify);
	}

	auto menu = text.getMenu();
	if (!menu) menu = new Menu(text.getShell(), SWT.POP_UP);
	auto u = createMenuItem(comm, menu, MenuID.Undo, { undo.undo(); }, () => undo !is null && undo.canUndo);
	auto r = createMenuItem(comm, menu, MenuID.Redo, { undo.redo(); }, () => undo !is null && undo.canRedo);
	new MenuItem(menu, SWT.SEPARATOR);
	bool sel() { mixin(S_TRACE);
		auto p = text.getSelection();
		return p.y > p.x;
	}
	auto t = createMenuItem(comm, menu, MenuID.Cut, { mixin(S_TRACE);
		text.cut();
		comm.refreshToolBar();
	}, () => !readOnly && sel());
	auto c = createMenuItem(comm, menu, MenuID.Copy, { mixin(S_TRACE);
		text.copy();
		comm.refreshToolBar();
	}, &sel);
	auto p = createMenuItem(comm, menu, MenuID.Paste, { mixin(S_TRACE);
		text.paste();
		comm.refreshToolBar();
	}, () => !readOnly && CBisText(comm.clipboard));
	auto d = createMenuItem(comm, menu, MenuID.Delete, { mixin(S_TRACE);
		auto p = text.getSelection();
		auto t = to!dstring(text.getText());
		if (t.length <= p.x) return;
		if (p.x != p.y) { mixin(S_TRACE);
			text.setText(to!string(t[0 .. p.x] ~ t[p.y .. $]));
		} else { mixin(S_TRACE);
			text.setText(to!string(t[0 .. p.x] ~ t[p.y + 1 .. $]));
		}
		text.setSelection(new Point(p.x, p.x));
		comm.refreshToolBar();
	}, () => !readOnly && sel());
	new MenuItem(menu, SWT.SEPARATOR);
	auto a = createMenuItem(comm, menu, MenuID.SelectAll, { mixin(S_TRACE);
		text.setSelection(new Point(0, cast(int)text.getText().length));
	}, { mixin(S_TRACE);
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
	void clone(SelectionEvent se);
	@property bool canDoTCPD();
	@property bool canDoT();
	@property bool canDoC();
	@property bool canDoP();
	@property bool canDoD();
	@property bool canDoClone();
}

private class InTCPD {
	TCPD tcpd;
	void cut(SelectionEvent se) { mixin(S_TRACE);
		auto fc = Display.getCurrent().getFocusControl();
		if (!fc) { mixin(S_TRACE);
			tcpd.cut(se);
			return;
		}
		bool ro = !(fc.getStyle() & SWT.READ_ONLY);
		if (ro && cast(Text)fc) { mixin(S_TRACE);
			(cast(Text)fc).cut();
		} else if (ro && cast(StyledText)fc) { mixin(S_TRACE);
			(cast(StyledText)fc).cut();
		} else if (ro && cast(Combo)fc) { mixin(S_TRACE);
			(cast(Combo)fc).cut();
		} else if (ro && cast(CCombo)fc) { mixin(S_TRACE);
			(cast(CCombo)fc).cut();
		} else if (tcpd.canDoT) { mixin(S_TRACE);
			tcpd.cut(se);
		}
	}
	void copy(SelectionEvent se) { mixin(S_TRACE);
		auto fc = Display.getCurrent().getFocusControl();
		if (!fc) { mixin(S_TRACE);
			tcpd.copy(se);
			return;
		}
		bool ro = !(fc.getStyle() & SWT.READ_ONLY);
		if (ro && cast(Text)fc) { mixin(S_TRACE);
			(cast(Text)fc).copy();
		} else if (ro && cast(StyledText)fc) { mixin(S_TRACE);
			(cast(StyledText)fc).copy();
		} else if (ro && cast(StyledText)fc) { mixin(S_TRACE);
			(cast(StyledText)fc).copy();
		} else if (ro && cast(Combo)fc) { mixin(S_TRACE);
			(cast(Combo)fc).copy();
		} else if (ro && cast(CCombo)fc) { mixin(S_TRACE);
			(cast(CCombo)fc).copy();
		} else if (tcpd.canDoC) { mixin(S_TRACE);
			tcpd.copy(se);
		}
	}
	void paste(SelectionEvent se) { mixin(S_TRACE);
		auto fc = Display.getCurrent().getFocusControl();
		if (!fc) { mixin(S_TRACE);
			tcpd.paste(se);
			return;
		}
		bool ro = !(fc.getStyle() & SWT.READ_ONLY);
		if (ro && cast(Text)fc) { mixin(S_TRACE);
			(cast(Text)fc).paste();
		} else if (ro && cast(StyledText)fc) { mixin(S_TRACE);
			(cast(StyledText)fc).paste();
		} else if (ro && cast(StyledText)fc) { mixin(S_TRACE);
			(cast(StyledText)fc).paste();
		} else if (ro && cast(Combo)fc) { mixin(S_TRACE);
			(cast(Combo)fc).paste();
		} else if (ro && cast(CCombo)fc) { mixin(S_TRACE);
			(cast(CCombo)fc).paste();
		} else if (tcpd.canDoP) { mixin(S_TRACE);
			tcpd.paste(se);
		}
	}
	void del(SelectionEvent se) { mixin(S_TRACE);
		auto fc = Display.getCurrent().getFocusControl();
		if (!fc) { mixin(S_TRACE);
			tcpd.del(se);
			return;
		}
		bool ro = !(fc.getStyle() & SWT.READ_ONLY);
		if (ro && cast(Text)fc) { mixin(S_TRACE);
			(cast(Text)fc).insert("");
		} else if (ro && cast(StyledText)fc) { mixin(S_TRACE);
			(cast(StyledText)fc).insert("");
		} else if (ro && cast(StyledText)fc) { mixin(S_TRACE);
			(cast(StyledText)fc).insert("");
		} else if (tcpd.canDoD) { mixin(S_TRACE);
			tcpd.del(se);
		}
	}
	private void cloneImpl(T)(T fc) { mixin(S_TRACE);
		auto p = fc.getSelection();
		if (p.x == p.y) return;
		auto text = fc.getText();
		auto pt = text[p.x .. p.y];
		fc.setText(text[0 .. p.y] ~ pt ~ text[p.y .. $]);
		fc.setSelection(new Point(p.y, p.y + cast(int)pt.length));
	}
	void clone(SelectionEvent se) { mixin(S_TRACE);
		auto fc = Display.getCurrent().getFocusControl();
		if (!fc) { mixin(S_TRACE);
			tcpd.clone(se);
			return;
		}
		bool ro = !(fc.getStyle() & SWT.READ_ONLY);
		if (ro && cast(Text)fc) { mixin(S_TRACE);
			cloneImpl(cast(Text)fc);
		} else if (ro && cast(StyledText)fc) { mixin(S_TRACE);
			cloneImpl(cast(StyledText)fc);
		} else if (ro && cast(StyledText)fc) { mixin(S_TRACE);
			cloneImpl(cast(StyledText)fc);
		} else if (ro && cast(Combo)fc) { mixin(S_TRACE);
			cloneImpl(cast(Combo)fc);
		} else if (ro && cast(CCombo)fc) { mixin(S_TRACE);
			cloneImpl(cast(CCombo)fc);
		} else if (tcpd.canDoClone) { mixin(S_TRACE);
			tcpd.clone(se);
		}
	}
}
void appendMenuTCPD(Commons comm, TopLevelPanel tlp, TCPD tcpd, bool t, bool c, bool p, bool d, bool clone) { mixin(S_TRACE);
	auto itcpd = new InTCPD;
	itcpd.tcpd = tcpd;
	tlp.putMenuAction(MenuID.Cut, &itcpd.cut, &tcpd.canDoT);
	tlp.putMenuAction(MenuID.Copy, &itcpd.copy, &tcpd.canDoC);
	tlp.putMenuAction(MenuID.Paste, &itcpd.paste, &tcpd.canDoP);
	tlp.putMenuAction(MenuID.Delete, &itcpd.del, &tcpd.canDoD);
	tlp.putMenuAction(MenuID.Clone, &itcpd.clone, &tcpd.canDoClone);
}
void appendMenuTCPD(Commons comm, Menu me, TCPD tcpd, bool t, bool c, bool p, bool d, bool clone) { mixin(S_TRACE);
	auto itcpd = new InTCPD;
	itcpd.tcpd = tcpd;
	if (t) createMenuItem(comm, me, MenuID.Cut, &itcpd.cut, &tcpd.canDoT);
	if (c) createMenuItem(comm, me, MenuID.Copy, &itcpd.copy, &tcpd.canDoC);
	if (p) createMenuItem(comm, me, MenuID.Paste, &itcpd.paste, &tcpd.canDoP);
	if (d) createMenuItem(comm, me, MenuID.Delete, &itcpd.del, &tcpd.canDoD);
	if (clone) { mixin(S_TRACE);
		new MenuItem(me, SWT.SEPARATOR);
		createMenuItem(comm, me, MenuID.Clone, &itcpd.clone, &tcpd.canDoClone);
	}
}

interface IgnoreHotkey {
	// Nothing
}
class CIgnoreHotkey : IgnoreHotkey {
	// Nothing
}

bool eqAcc(int acc, int keyCode, wchar character, int stateMask) { mixin(S_TRACE);
	stateMask &= SWT.MODIFIER_MASK; // WindowsのスクリーンキーボードがCtrlと同時に0x80000を送ってくるので取り除く
	if (keyCode && (acc & SWT.MODIFIER_MASK) == acc) { mixin(S_TRACE);
		return (keyCode | stateMask) == acc;
	} else if (keyCode && toUpper(keyCode) == toUpper(character)) { mixin(S_TRACE);
		return (toUpper(keyCode) | stateMask) == acc
			|| (toLower(keyCode) | stateMask) == acc;
	} else { mixin(S_TRACE);
		return (keyCode && (toUpper(keyCode) | stateMask) == acc)
			|| (keyCode && (toLower(keyCode) | stateMask) == acc)
			|| (toUpper(character) | (stateMask ^ SWT.SHIFT)) == acc
			|| (toLower(character) | (stateMask ^ SWT.SHIFT)) == acc
			|| (toUpper(character) | stateMask) == acc
			|| (toLower(character) | stateMask) == acc;
	}
}

string acceleratorText(int character) { mixin(S_TRACE);
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
		if (.isPrintable(character)) { mixin(S_TRACE);
			return to!string(std.uni.toUpper(character));
		}
		break;
	}
	return "";
}

int convertAccelerator2(string acc_text) { mixin(S_TRACE);
	int acc = 0;
	string kc;
	int mod(string s) { mixin(S_TRACE);
		switch (std.string.toLower(s)) {
		case "control", "ctrl": return SWT.CONTROL;
		case "shift": return SWT.SHIFT;
		case "alt": return SWT.ALT;
		case "command": return SWT.COMMAND;
		default: return 0;
		}
	}
	while (true) { mixin(S_TRACE);
		auto p_index = .cCountUntil(acc_text, '+');
		if (p_index >= 0 && p_index < acc_text.length - 1) { mixin(S_TRACE);
			acc |= mod(acc_text[0 .. p_index]);
			acc_text = acc_text[p_index + 1 .. $];
		} else { mixin(S_TRACE);
			kc = acc_text;
			break;
		}
	}
	int ek(string s) { mixin(S_TRACE);
		switch (std.string.toLower(s)) {
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
	if (kc.length > 1) { mixin(S_TRACE);
		auto k = ek(kc);
		if (k != 0) { mixin(S_TRACE);
			acc |= k;
		} else { mixin(S_TRACE);
			acc |= mod(kc);
		}
	} else if (kc.length) { mixin(S_TRACE);
		acc |= kc[0];
	}
	return acc;
}
int convertAccelerator(string text) { mixin(S_TRACE);
	auto t_index = std.string.lastIndexOf(text, '\t');
	if (t_index >= 0 && t_index < text.length - 1) { mixin(S_TRACE);
		string acc_text = text[t_index + 1 .. $];
		return convertAccelerator2(acc_text);
	}
	return 0;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert (convertAccelerator("test\tCTRL+ARROW_UP") == (SWT.ARROW_UP | SWT.CTRL));
	assert (convertAccelerator("test\tShift+A") == (SWT.SHIFT | 'A'));
	assert (convertAccelerator("test\tCtrl+Shift+A") == (SWT.CTRL | SWT.SHIFT | 'A'));
}
private class MenuSel(Dlg) : SelectionAdapter {
	private Dlg _func;
	public this(Dlg func) { _func = func; }
	public override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
		static if (is(Dlg == void delegate(SelectionEvent))) {
			_func(e);
		} else static if (is(Dlg == void delegate())) {
			_func();
		} else static assert (0);
	}
}
private void addRefMenu(Commons comm, MenuItem itm) { mixin(S_TRACE);
	auto d = cast(MenuData)itm.getData();
	enforce(d);
	if (d.id == MenuID.None) return;

	void refMenu(MenuID id) { mixin(S_TRACE);
		auto d = cast(MenuData)itm.getData();
		enforce(d);
		enforce(d.id != MenuID.None);
		if (d.id != id) return;
		string t = comm.prop.buildMenu(d.id);
		if (d.format) t = d.format(t);
		itm.setText(t);
	}
	class RefMenu : DisposeListener {
		override void widgetDisposed(DisposeEvent d) { mixin(S_TRACE);
			comm.refMenu.remove(&refMenu);
		}
	}
	comm.refMenu.add(&refMenu);
	itm.addDisposeListener(new RefMenu);
}
class MenuShown : MenuAdapter {
	private MenuItem _itm;
	this (MenuItem itm) { mixin(S_TRACE);
		_itm = itm;
	}
	override void menuShown(MenuEvent e) { mixin(S_TRACE);
		auto d = cast(MenuData)_itm.getData();
		if (!d) return;
		if (!d.enabled) return;
		_itm.setEnabled(d.enabled());
	}
}
private MenuItem createMenuItemImpl(Dlg)(Commons comm, Menu sub, string text, Image img,
	Dlg func, int style, MenuID id, bool delegate() enabled, int index = -1) { mixin(S_TRACE);
	auto itm = 0 <= index ? new MenuItem(sub, style, index) : new MenuItem(sub, style);
	itm.setText(text);
	if (func) { mixin(S_TRACE);
		itm.addSelectionListener(new MenuSel!(Dlg)(func));
	}
	if (img) itm.setImage(img);
	auto d = new MenuData();
	d.id = id;
	d.enabled = enabled;
	if (enabled) { mixin(S_TRACE);
		auto menuShown = new MenuShown(itm);
		class Dispose : DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
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
		void delegate(SelectionEvent se) func, bool delegate() enabled, int style = SWT.PUSH, int index = -1) { mixin(S_TRACE);
	return createMenuItemImpl(comm, sub, text, img, func, style, MenuID.None, enabled, index);
}
MenuItem createMenuItem2(Commons comm, Menu sub, string text, Image img,
		void delegate() func, bool delegate() enabled, int style = SWT.PUSH, int index = -1) { mixin(S_TRACE);
	return createMenuItemImpl(comm, sub, text, img, func, style, MenuID.None, enabled, index);
}
MenuItem createMenuItem(Commons comm, Menu sub, MenuID id,
		void delegate(SelectionEvent se) func, bool delegate() enabled, int style = SWT.PUSH, int index = -1) { mixin(S_TRACE);
	auto mi = createMenuItemImpl(comm, sub, comm.prop.buildMenu(id), comm.prop.images.menu(id), func, style, id, enabled, index);
	addRefMenu(comm, mi);
	return mi;
}
MenuItem createMenuItem(Commons comm, Menu sub, MenuID id,
		void delegate() func, bool delegate() enabled, int style = SWT.PUSH, int index = -1) { mixin(S_TRACE);
	auto mi = createMenuItemImpl(comm, sub, comm.prop.buildMenu(id), comm.prop.images.menu(id), func, style, id, enabled, index);
	addRefMenu(comm, mi);
	return mi;
}
private Menu createMenu2(Commons comm, Menu bar, string text, out MenuItem mi) { mixin(S_TRACE);
	auto menu = new Menu(bar.getShell(), SWT.DROP_DOWN);
	mi = new MenuItem(bar, SWT.CASCADE);
	mi.setText(text);
	mi.setMenu(menu);
	auto d = new MenuData();
	d.id = MenuID.None;
	mi.setData(d);
	return menu;
}
Menu createMenu(Commons comm, Menu bar, MenuID id) { mixin(S_TRACE);
	MenuItem mi;
	auto m = createMenu2(comm, bar, comm.prop.buildMenu(id), mi);
	(cast(MenuData)mi.getData()).id = id;
	addRefMenu(comm, mi);
	return m;
}

ToolItem createDropDownItem(Commons comm, ToolBar bar, MenuID id, void delegate() func, out Menu menu, bool delegate() enabled) { mixin(S_TRACE);
	return createDropDownItem2(comm, bar, comm.prop.buildTool(id), comm.prop.images.menu(id), func, menu, id, enabled);
}
ToolItem createDropDownItem2(Commons comm, ToolBar bar, string text, Image img, void delegate() func, out Menu menu, MenuID id, bool delegate() enabled) { mixin(S_TRACE);
	auto ti = new ToolItem(bar, SWT.DROP_DOWN);
	ti.setToolTipText(text);
	ti.setImage(img);
	menu = new Menu(bar.getShell());
	auto menu2 = menu;
	class Push : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			if ((!func || SWT.ARROW == e.detail) && 0 < menu2.getItemCount()) { mixin(S_TRACE);
				auto b = ti.getBounds();
				auto pt = bar.toDisplay(b.x, b.y + b.height);
				menu2.setLocation(pt);
				menu2.setVisible(true);
			} else if (func) { mixin(S_TRACE);
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
void showDropDownMenu(ToolItem ti, Menu menu) {
	if (!menu.getItemCount()) return;
	auto b = ti.getBounds();
	auto pt = ti.getParent().toDisplay(b.x, b.y + b.height);
	menu.setLocation(pt);
	menu.setVisible(true);
}
private ToolItem createToolItemImpl(Dlg)(Commons comm, ToolBar bar, string tip, string text, Image img,
		Dlg func, int style, MenuID id, bool delegate() enabled) { mixin(S_TRACE);
	auto itm = new ToolItem(bar, style);
	itm.setText(text);
	itm.setToolTipText(tip);
	itm.setImage(img);
	if (func) { mixin(S_TRACE);
		itm.addSelectionListener(new MenuSel!(Dlg)(func));
	}
	auto d = new MenuData;
	d.id = id;
	d.enabled = enabled;
	itm.setData(d);
	return itm;
}
ToolItem createToolItem2(Commons comm, ToolBar bar, string tip, string text, Image img,
		void delegate(SelectionEvent se) func, bool delegate() enabled, int style = SWT.PUSH) { mixin(S_TRACE);
	return createToolItemImpl(comm, bar, tip, text, img, func, style, MenuID.None, enabled);
}
ToolItem createToolItem2(Commons comm, ToolBar bar, string tip, string text, Image img,
		void delegate() func, bool delegate() enabled, int style = SWT.PUSH) { mixin(S_TRACE);
	return createToolItemImpl(comm, bar, tip, text, img, func, style, MenuID.None, enabled);
}
ToolItem createToolItem2(Commons comm, ToolBar bar, string text, Image img,
		void delegate(SelectionEvent se) func, bool delegate() enabled, int style = SWT.PUSH) { mixin(S_TRACE);
	return createToolItemImpl!(void delegate(SelectionEvent))(comm, bar, text, null, img, func, style, MenuID.None, enabled);
}
ToolItem createToolItem2(Commons comm, ToolBar bar, string text, Image img,
		void delegate() func, bool delegate() enabled, int style = SWT.PUSH) { mixin(S_TRACE);
	return createToolItemImpl!(void delegate())(comm, bar, text, null, img, func, style, MenuID.None, enabled);
}
private class ToolSel : SelectionAdapter {
	private void delegate(ToolItem) _func;
	public this(void delegate(ToolItem) func) { _func = func; }
	public override void widgetSelected(SelectionEvent e) { _func(cast(ToolItem)e.widget); }
}
ToolItem createToolItem2(Commons comm, ToolBar bar, string tip, string text, Image img,
		void delegate(ToolItem) func, bool delegate() enabled, int style = SWT.PUSH) { mixin(S_TRACE);
	auto itm = new ToolItem(bar, style);
	itm.setText(text);
	itm.setToolTipText(tip);
	itm.setImage(img);
	if (func) { mixin(S_TRACE);
		itm.addSelectionListener(new ToolSel(func));
	}
	auto d = new MenuData;
	d.id = MenuID.None;
	d.enabled = enabled;
	itm.setData(d);
	return itm;
}

ToolItem createToolItem(Commons comm, ToolBar bar, MenuID id,
		void delegate(ToolItem) func, bool delegate() enabled, int style = SWT.PUSH) { mixin(S_TRACE);
	auto m = createToolItem2(comm, bar, comm.prop.buildTool(id), null, comm.prop.images.menu(id), func, enabled, style);
	(cast(MenuData)m.getData()).id = id;
	return m;
}
ToolItem createToolItem(Commons comm, ToolBar bar, MenuID id,
		void delegate(SelectionEvent se) func, bool delegate() enabled, int style = SWT.PUSH) { mixin(S_TRACE);
	return createToolItemImpl(comm, bar, comm.prop.buildTool(id), null, comm.prop.images.menu(id), func, style, id, enabled);
}
ToolItem createToolItem(Commons comm, ToolBar bar, MenuID id,
		void delegate() func, bool delegate() enabled, int style = SWT.PUSH) { mixin(S_TRACE);
	return createToolItemImpl(comm, bar, comm.prop.buildTool(id), null, comm.prop.images.menu(id), func, style, id, enabled);
}

/// マウスで配置を操作すると、たまに折り返し位置が
/// 外見と異なる位置になるので、外見と一致する位置を求める。
private int[] getWrapIndices2(CoolBar cbar) { mixin(S_TRACE);
	auto y = int.min;
	int[] wi;
	foreach (index, itm; cbar.getItems()) { mixin(S_TRACE);
		auto iy = itm.getControl().getLocation().y;
		if (y < iy) {
			wi ~= cast(int)index;
			y = iy;
		}
	}
	return wi;
}

private class CBarListener(string Name) : MouseMoveListener, DisposeListener {
	private Props _prop;
	private CoolBar _cbar;
	private MenuItem _lock;
	private int[] _wrapIndices;
	private bool _saveOrder;
	this (Props prop, CoolBar cbar, bool saveOrder) { mixin(S_TRACE);
		_prop = prop;
		_cbar = cbar;
		_wrapIndices = _cbar.getWrapIndices();
		_saveOrder = saveOrder;
	}
	override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
		auto cbar = cast(CoolBar)e.widget;
		int[] ixs;
		for (int i = 0; i < _cbar.getItemCount(); i++) { mixin(S_TRACE);
			ixs ~= i;
		}
		mixin("_prop.var.etc." ~ Name ~ "Lock = cbar.getLocked();");
		if (_saveOrder) { mixin(S_TRACE);
			if (ixs == cbar.getItemOrder()) { mixin(S_TRACE);
				mixin("_prop.var.etc." ~ Name ~ "Order = [];");
			} else { mixin(S_TRACE);
				mixin("_prop.var.etc." ~ Name ~ "Order = cbar.getItemOrder();");
			}
		}
		mixin("_prop.var.etc." ~ Name ~ "WrapIndices = getWrapIndices2(cbar);");
	}
	override void mouseMove(MouseEvent e) { mixin(S_TRACE);
		if (e.getSource() !is _cbar) return;
		if (_wrapIndices == _cbar.getWrapIndices()) return;
		_wrapIndices = _cbar.getWrapIndices();
		auto cbar = cast(CoolBar)e.widget;
		cbar.getShell().layout(true, true);
	}
	void reset() { mixin(S_TRACE);
		auto shell = _cbar.getShell();
		shell.setRedraw(false);
		scope (exit) shell.setRedraw(true);
		int[] ixs;
		for (int i = 0; i < _cbar.getItemCount(); i++) { mixin(S_TRACE);
			ixs ~= i;
		}
		_cbar.setItemOrder(ixs);
		_cbar.setWrapIndices(mixin("_prop.var.etc." ~ Name ~ "WrapIndices.INIT.dup"));
		foreach_reverse (i; _cbar.getItemOrder()) { mixin(S_TRACE);
			resetCISize(_cbar.getItem(i));
		}
		resizeAll();
		shell.layout(true, true);
	}
	void resizeAll() { mixin(S_TRACE);
		bool[int] wiTbl;
		foreach (i; _cbar.getWrapIndices()) wiTbl[i] = true;
		wiTbl[_cbar.getItemCount()] = true;
		foreach (i, itm; _cbar.getItems()) { mixin(S_TRACE);
			if (cast(int)i + 1 !in wiTbl) { mixin(S_TRACE);
				itm.setSize(itm.getMinimumSize());
			}
		}
	}
	void lock() { mixin(S_TRACE);
		_cbar.setLocked(!_cbar.getLocked());
		if (_lock) _lock.setSelection(_cbar.getLocked());
		foreach_reverse (i; _cbar.getItemOrder()) { mixin(S_TRACE);
			resetCISize(_cbar.getItem(i));
		}
	}
}
Composite createCoolBar(string Name)(Commons comm, Composite parent, bool saveOrder,
		void delegate(Composite) setupItems, void delegate(Menu) putMenu = null) { mixin(S_TRACE);
	if (!comm.prop.var.etc.useCoolBar) { mixin(S_TRACE);
		auto cbar = new Composite(parent, SWT.NONE);
		auto rl = new RowLayout(SWT.HORIZONTAL);
		rl.center = false;
		rl.wrap = true;
		rl.pack = true;
		rl.marginLeft = 1;
		rl.marginRight = 1;
		rl.marginTop = 1;
		rl.marginBottom = 1;
		rl.spacing = 3;
		cbar.setLayout(rl);
		setupItems(cbar);
		if (putMenu) { mixin(S_TRACE);
			auto menu = new Menu(parent.getShell(), SWT.POP_UP);
			putMenu(menu);
			cbar.setMenu(menu);
			foreach (itm; cbar.getChildren()) { mixin(S_TRACE);
				itm.setMenu(menu);
			}
		}
		.listener(cbar, SWT.Paint, (e) { mixin(S_TRACE);
			auto x = int.min;
			auto y = int.min;
			auto ca = cbar.getClientArea();
			e.gc.setForeground(cbar.getDisplay().getSystemColor(SWT.COLOR_WIDGET_NORMAL_SHADOW));
			foreach (itm; cbar.getChildren()) { mixin(S_TRACE);
				auto b = itm.getBounds();
				if (x != int.min && x < b.x) { mixin(S_TRACE);
					e.gc.drawLine(b.x - 2, b.y - 1, b.x - 2, b.y + b.height + 1);
				}
				x = b.x;
				if (y != int.min && y < b.y) { mixin(S_TRACE);
					e.gc.drawLine(ca.x, b.y - 2, ca.x + ca.width, b.y - 2);
					x = int.min;
				}
				y = b.y;
			}
		});
		return cbar;
	}
	auto cbar = new CoolBar(parent, SWT.NONE);

	setupItems(cbar);

	if (saveOrder) { mixin(S_TRACE);
		if (mixin("comm.prop.var.etc." ~ Name ~ "Order.length") == cbar.getItemCount()) { mixin(S_TRACE);
			cbar.setItemOrder(mixin("comm.prop.var.etc." ~ Name ~ "Order.dup"));
		}
	}
	int[] wi;
	foreach (i; mixin("comm.prop.var.etc." ~ Name ~ "WrapIndices")) { mixin(S_TRACE);
		if (i > 0 && i < cbar.getItemCount()) wi ~= i;
	}
	if (wi != cbar.getWrapIndices()) cbar.setWrapIndices(wi);
	cbar.setLocked(mixin("comm.prop.var.etc." ~ Name ~ "Lock"));

	auto ls = new CBarListener!(Name)(comm.prop, cbar, saveOrder);
	cbar.addMouseMoveListener(ls);
	cbar.addDisposeListener(ls);

	auto menu = new Menu(parent.getShell(), SWT.POP_UP);
	if (putMenu) { mixin(S_TRACE);
		putMenu(menu);
		if (menu.getItemCount()) new MenuItem(menu, SWT.SEPARATOR);
	}
	ls._lock = createMenuItem(comm, menu, MenuID.LockToolBar, &ls.lock, null, SWT.CHECK);
	new MenuItem(menu, SWT.SEPARATOR);
	createMenuItem(comm, menu, MenuID.ResetToolBar, &ls.reset, null);
	cbar.setMenu(menu);
	foreach (i, itm; cbar.getItems()) { mixin(S_TRACE);
		itm.getControl().setMenu(menu);
	}
	ls._lock.setSelection(cbar.getLocked());
	auto d = cbar.getDisplay();
	ls.resizeAll();

	return cbar;
}

void resetCISize(CoolItem itm) { mixin(S_TRACE);
	auto p = itm.getControl().computeSize(SWT.DEFAULT, SWT.DEFAULT);
	auto p2 = itm.computeSize(p.x, p.y);
	itm.setMinimumSize(p.x, p.y);
	itm.setPreferredSize(p2.x, p2.y);
}

CoolItem createCoolItem(CoolBar cbar, ToolBar tbar, int index = -1) { mixin(S_TRACE);
	CoolItem itm;
	if (index >= 0) { mixin(S_TRACE);
		itm = new CoolItem(cbar, SWT.PUSH, index);
	} else { mixin(S_TRACE);
		itm = new CoolItem(cbar, SWT.PUSH);
	}
	itm.setControl(tbar);
	resetCISize(itm);
	return itm;
}

/// 押されたキーに該当するアクセラレータを持つメニューを探す。
MenuItem findMenu(Shell shell, int keyCode, wchar character, int stateMask) { mixin(S_TRACE);
	auto menu = shell.getMenuBar();
	if (!menu) return null;
	return findMenu(menu, keyCode, character, stateMask);
}
/// ditto
MenuItem findMenu(Menu menu, int keyCode, wchar character, int stateMask) { mixin(S_TRACE);
	if (!menu) return null;
	foreach (itm; menu.getItems()) { mixin(S_TRACE);
		if (!menuEnabled(itm)) continue;
		if (eqAcc(convertAccelerator(itm.getText()), keyCode, character, stateMask)) { mixin(S_TRACE);
			return itm;
		}
		if (itm.getStyle() & SWT.CASCADE) { mixin(S_TRACE);
			auto r = findMenu(itm.getMenu(), keyCode, character, stateMask);
			if (r) return r;
		}
	}
	return null;
}

/// menuが有効状態か否かを返す。
/// MenuDataが登録されている場合は有効状態を更新する。
bool menuEnabled(MenuItem menu) {
	auto data = cast(MenuData)menu.getData();
	if (data && data.enabled) {
		menu.setEnabled(data.enabled());
	}
	return menu.getEnabled();
}

/// ToolItemが持つツールチップを独自描画のものに差し替える。
void setupToolTips(ToolBar bar, in Props prop) { mixin(S_TRACE);
	Shell toolTip = null;
	Font bFont = null;
	string[ToolItem] textTable;
	ToolItem lastItm = null;
	CLabel label1 = null;
	Label label2 = null;

	void putToolTip(ToolItem itm) { mixin(S_TRACE);
		if (itm.getToolTipText() != "") { mixin(S_TRACE);
			if (itm !in textTable) { mixin(S_TRACE);
				.listener(itm, SWT.Dispose, (e) { mixin(S_TRACE);
					textTable.remove(cast(ToolItem)e.widget);
				});
			}
			textTable[itm] = itm.getToolTipText();
			itm.setToolTipText("");
		}
	}

	foreach (itm; bar.getItems()) { mixin(S_TRACE);
		putToolTip(itm);
	}

	void release() { mixin(S_TRACE);
		if (!toolTip) return;
		toolTip.dispose();
		toolTip = null;
		bFont.dispose();
		bFont = null;
		lastItm = null;
		label1 = null;
		label2 = null;
	}
	void rebounds() { mixin(S_TRACE);
		auto d = bar.getDisplay();
		auto text = textTable[lastItm];
		auto index = std.string.indexOf(text, "\v");
		auto name = text[0 .. index];
		auto desc = text[index + 1 .. $];
		label1.setImage(lastItm.getImage());
		label1.setText(name);
		label2.setText(desc);
		auto gd = new GridData;
		auto gc = new GC(label2);
		scope (exit) gc.dispose();
		gd.widthHint = .min(gc.textExtent(desc).x, prop.var.etc.toolTipWidth);
		label2.setLayoutData(gd);
		auto size = toolTip.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		auto b = lastItm.getBounds();
		auto p2 = bar.toDisplay(b.x, b.y);
		auto da = d.getClientArea();
		if (p2.y + b.height + size.y < da.height) { mixin(S_TRACE);
			p2.y += b.height;
		} else { mixin(S_TRACE);
			p2.y -= size.y;
		}
		if (p2.x < 0) { mixin(S_TRACE);
			p2.x = 0;
		} else if (da.width <= p2.x + size.x) { mixin(S_TRACE);
			p2.x = da.width - size.x;
		}
		toolTip.layout();
		toolTip.setBounds(p2.x, p2.y,size.x, size.y);
		toolTip.setVisible(true);
	}
	void enter(int x, int y) { mixin(S_TRACE);
		auto p = new Point(x, y);
		auto itm = bar.getItem(p);
		if (!itm) { mixin(S_TRACE);
			release();
			return;
		}
		if (itm is lastItm) return;
		if (itm !in textTable) { mixin(S_TRACE);
			auto index = std.string.indexOf(itm.getToolTipText(), "\v");
			if (index == -1) { mixin(S_TRACE);
				release();
				return;
			}
		}
		putToolTip(itm);
		lastItm = itm;
		if (toolTip) { mixin(S_TRACE);
			rebounds();
			return;
		}
		auto d = bar.getDisplay();
		auto fore = d.getSystemColor(SWT.COLOR_INFO_FOREGROUND);
		auto back = d.getSystemColor(SWT.COLOR_INFO_BACKGROUND);
		toolTip = new Shell(bar.getShell(), SWT.ON_TOP);
		toolTip.setForeground(fore);
		toolTip.setBackground(back);
		auto gl = normalGridLayout(1, true);
		gl.verticalSpacing = 0;
		gl.marginHeight = WGL_SPACING.ppis;
		toolTip.setLayout(gl);
		label1 = new CLabel(toolTip, SWT.NONE);
		label1.setForeground(fore);
		label1.setBackground(back);
		auto font = label1.getFont();
		auto fontData = font.getFontData()[0];
		fontData.setStyle(fontData.getStyle() | SWT.BOLD);
		bFont = new Font(d, fontData);
		label1.setFont(bFont);
		label2 = new Label(toolTip, SWT.WRAP);
		label2.setForeground(fore);
		label2.setBackground(back);
		rebounds();
	}
	.listener(bar, SWT.MouseEnter, (e) { mixin(S_TRACE);
		enter(e.x, e.y);
	});
	.listener(bar, SWT.MouseHover, (e) { mixin(S_TRACE);
		enter(e.x, e.y);
	});
	.listener(bar, SWT.MouseMove, (e) { mixin(S_TRACE);
		enter(e.x, e.y);
	});
	.listener(bar, SWT.MouseExit, &release);
	.listener(bar, SWT.Dispose, &release);
}

void doMenu(E)(MenuItem menu, E e) { mixin(S_TRACE);
	auto se = new Event;
	se.type = SWT.Selection;
	se.widget = menu;
	se.time = e.time;
	se.stateMask = e.stateMask;
	se.doit = e.doit;
	menu.notifyListeners(SWT.Selection, se);
	e.doit = false;
}
