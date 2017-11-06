
module cwx.editor.gui.dwt.eventtreeview;

import cwx.event;
import cwx.summary;
import cwx.flag;
import cwx.area;
import cwx.card;
import cwx.utils;
import cwx.types;
import cwx.skin;
import cwx.usecounter;
import cwx.background;
import cwx.path;
import cwx.script;
import cwx.structs;
import cwx.menu;
import cwx.types;
import cwx.xml;
import cwx.msgutils;
import cwx.system;
import cwx.warning;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.eventdialog;
import cwx.editor.gui.dwt.messageutils;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.scripterrordialog;
import cwx.editor.gui.dwt.textdialog;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.smalldialogs;
import cwx.editor.gui.dwt.eventeditor;
import cwx.editor.gui.dwt.eventview;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.contentinitializer;

import std.algorithm;
import std.array : array, replace, replicate;
import std.ascii;
import std.conv;
import std.string;
import std.datetime;
import std.traits;

import org.eclipse.swt.all;

import java.lang.all;

public:

struct Warning {
	Rectangle rect;
	string[] warnings;
}

/// イベントコンテントツリー。
class EventTreeView : TCPD {
private:
	string _id = "";

	Composite _contentsBoxArea;
	Composite _comp;
	TreeViewWrapper _tree;
	Color _grayFont;

	int _readOnly = 0;
	Props _prop;
	Commons _comm;
	Summary _summ;
	CWXPath _area;
	EventTree _et;
	ContentsToolBox _box;
	Menu _createM = null;
	Menu _convM = null;
	Menu _evTemplM = null;
	Converter[CType] _conts;
	bool _showEventTreeDetail = false;
	bool _showLineNumber = false;
	EventEdit _ee = null;
	TreeEdit _te = null;

	void delegate(size_t[]) _forceSel;
	void delegate() _refreshTopStart;

	Warning[] _warningRects;

	string _statusLine;

	Item _clickStart = null;
	bool _arrowMode = true;
	CType _cType = CType.START;

	Skin _summSkin;
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	private void initConvMenu() { mixin(S_TRACE);
		if (!_conts.length) return;
		if (!_createM) return;
		if (!_convM) return;
		foreach (cGrp; EnumMembers!CTypeGroup) { mixin(S_TRACE);
			auto cs = CTYPE_GROUP[cGrp];
			auto create = cTypeGroupMenu(_createM, cGrp);
			auto conv = cTypeGroupMenu(_convM, cGrp);
			foreach (i, cType; cs) { mixin(S_TRACE);
				string mnemonic;
				if (i + 1 < 10) {
					mnemonic = .format("%s", i + 1);
				} else {
					mnemonic = .format("%s", cast(char)('A' + (i + 1 - 10)));
				}
				auto text = MenuProps.buildMenu(_prop.msgs.contentName(cType), mnemonic, "", false);
				auto img = _prop.images.content(cType);
				initCreateMenu(cType, create, text, img);
				initConvMenu(cType, cType is CType.START ? _convM : conv, text, img);
			}
		}
		refreshConvMenu();
	}
	private void initCreateMenu(CType type, Menu menu, string text, Image img) { mixin(S_TRACE);
		createMenuItem2(_comm, menu, text, img, {
			if (!_box) return;
			auto itm = selection;
			bool insert = _box && _box.isInsert;
			auto oldType = _box._cType;
			_box._cType = type;
			scope (exit) _box._cType = oldType;
			auto oldMode = _box._putMode;
			_box._putMode = MenuID.PutQuick;
			scope (exit) _box._putMode = oldMode;
			create(insert ? itm : null);
		}, () => _et !is null && (!_summ || !_summ.legacy || !type.isWsnContent));
	}
	private void initConvMenu(CType type, Menu convMenu, string text, Image img) { mixin(S_TRACE);
		auto ce = _conts[type];
		if (type != CType.START) { mixin(S_TRACE);
			ce.convMenuItem = createMenuItem2(_comm, convMenu, text, img, &ce.convert, () => selection && (!_summ || !_summ.legacy || !type.isWsnContent));
			ce.convMenuItem.setEnabled(false);
		}
	}
	private bool canConvTerminal() { mixin(S_TRACE);
		auto itm = selection;
		if (!itm) return false;
		auto evt = cast(Content)itm.getData();
		return !evt.next.length;
	}
	private Menu cTypeGroupMenu(Menu menu, CTypeGroup g) { mixin(S_TRACE);
		void delegate() dlg = null;
		auto mi = createMenuItem(_comm, menu, cTypeGroupToMenuID(g), dlg, g is CTypeGroup.Terminal ? &canConvTerminal : null, SWT.CASCADE);
		auto m = new Menu(_tree.control.getShell(), SWT.DROP_DOWN);
		mi.setMenu(m);
		return m;
	}
	private void refreshConvMenu() { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_et || !selection) { mixin(S_TRACE);
			foreach (ce; _conts.values) { mixin(S_TRACE);
				if (ce.convMenuItem) ce.convMenuItem.setEnabled(false);
			}
		} else { mixin(S_TRACE);
			auto c = cast(Content) selection.getData();
			foreach (ce; _conts.values) { mixin(S_TRACE);
				if (ce.convMenuItem) ce.convMenuItem.setEnabled(c.canConvert(ce.type));
			}
		}
	}

	private class Converter {
		CType type;
		MenuItem convMenuItem;
		Cursor cursor;
		this (CType type) { mixin(S_TRACE);
			this.type = type;
			this.cursor = _prop.images.cursor(type);
		}
		void convert() { mixin(S_TRACE);
			auto sel = selection;
			if (!sel) return;
			auto c = cast(Content)sel.getData();
			if (c.type == type) return;
			store(c);
			_comm.delContent.call(c);
			assert (c.canConvert(type), "convert menu item enabled");
			auto oldd = c.detail;
			auto init = new Content(type, "");
			initial(init);
			c.convertType(type, init, _prop.parent, .toDialogStatus(_prop.var.etc.dialogStatus));
			auto newd = c.detail;
			if (newd.use(CArg.BG_IMAGES) && !oldd.use(CArg.BG_IMAGES)) { mixin(S_TRACE);
				c.backs = createBgImages(summSkin, _prop.var.etc.bgImagesDefault);
			}
			if (newd.use(CArg.DIALOGS) && !c.dialogs.length) { mixin(S_TRACE);
				c.dialogs = [new SDialog];
			}
			auto img = _prop.images.content(type);
			foreach (v; views()) { mixin(S_TRACE);
				if (v._tree.tree) { mixin(S_TRACE);
					assert (cast(TreeItem)sel !is null);
					auto sel2 = .anotherTreeItem(v._tree.tree, cast(TreeItem)sel);
					sel2.setImage(img);
					foreach (itm; v._tree.getItems(sel2)) { mixin(S_TRACE);
						itm.setText(v.eventText(c, cast(Content)itm.getData()));
						v.procTreeItem(itm);
					}
					v.procTreeItem(sel2);
				} else { mixin(S_TRACE);
					v._tree.editor.updatePosOne(c);
				}
				v.refreshStatusLine();
				v.redraw();
			}
			_comm.refUseCount.call();
			_comm.refreshToolBar();
		}
	}

	@property
	Item selection() { mixin(S_TRACE);
		if (!_tree.control || _tree.control.isDisposed()) return null;
		auto sels = _tree.getSelection();
		if (sels.length > 0) { mixin(S_TRACE);
			assert (cast(Content)sels[0].getData() !is null);
			assert ((cast(Content)sels[0].getData()).tree is _et);
			return sels[0];
		}
		return null;
	}

	class EditL : MouseAdapter, KeyListener {
		private void edit() { mixin(S_TRACE);
			if (_readOnly) return;
			this.outer.edit();
		}
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			if (e.keyCode == SWT.CR) { mixin(S_TRACE);
				edit();
			}
		}
		override void keyReleased(KeyEvent e) {}
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (e.button == 1 && !_tree.control.getCursor()) { mixin(S_TRACE);
				edit();
			}
		}
		override void mouseUp(MouseEvent e) { mixin(S_TRACE);
			if (e.button == 1 && _clickStart) { mixin(S_TRACE);
				edit();
			}
		}
	}
	class CreateL : MouseAdapter {
		override void mouseUp(MouseEvent e) { mixin(S_TRACE);
			if (!_box) return;
			if (_readOnly) return;
			if (_box._putMode is MenuID.PutQuick) return;
			if (e.button == 1) { mixin(S_TRACE);
				create(null);
			} else if (e.button == 2 && !_box._arrowMode) { mixin(S_TRACE);
				auto itm = _tree.getItem(new Point(e.x, e.y));
				if (itm && CDetail.fromType(_box._cType).owner) { mixin(S_TRACE);
					auto c = cast(Content) itm.getData();
					if (c.parent) { mixin(S_TRACE);
						_tree.setSelection([itm]);
						create(itm);
						_comm.refreshToolBar();
					}
				}
			} else if (e.button == 3) { mixin(S_TRACE);
				_box.arrow();
				_comm.refreshToolBar();
			}
		}
	}
	class MouseMove : MouseTrackAdapter, MouseMoveListener {
		override void mouseMove(MouseEvent e) { mixin(S_TRACE);
			if (!_box) return;
			_clickStart = null;
			if (!_readOnly && _box._arrowMode && _prop.var.etc.clickIconIsStartEdit) { mixin(S_TRACE);
				auto itm = _tree.getItem(new Point(e.x, e.y));
				if (itm) { mixin(S_TRACE);
					auto c = cast(Content)itm.getData();
					auto d = _tree.control.getDisplay();
					auto hand = d.getSystemCursor(SWT.CURSOR_HAND);
					if (_tree.getImageBounds(itm).contains(e.x, e.y) && hasDialog(c.type) && checkOpenDialog(c.type)) { mixin(S_TRACE);
						_clickStart = itm;
						if (_tree.editor) { mixin(S_TRACE);
							_tree.control.setCursor(hand);
						}
					} else { mixin(S_TRACE);
						if (_tree.editor && _tree.control.getCursor() is hand) { mixin(S_TRACE);
							_tree.control.setCursor(null);
						}
					}
				}
			}
			updateToolTip();
		}
		override void mouseExit(MouseEvent e) { mixin(S_TRACE);
			clearClickStart();
		}
	}
	void clearClickStart() { mixin(S_TRACE);
		auto d = _tree.control.getDisplay();
		auto hand = d.getSystemCursor(SWT.CURSOR_HAND);
		if (_clickStart && _tree.editor && _tree.editor && _tree.control.getCursor() is hand) { mixin(S_TRACE);
			_tree.control.setCursor(null);
		}
	}
	void updateToolTip() { mixin(S_TRACE);
		if (!_tree.tree) return;
		auto p = _tree.control.getDisplay().getCursorLocation();
		p = _tree.control.toControl(p);
		string toolTip = "";
		if (_tree.control.getClientArea().contains(p)) { mixin(S_TRACE);
			foreach (warn; _warningRects) { mixin(S_TRACE);
				if (warn.rect.contains(p)) { mixin(S_TRACE);
					toolTip = std.string.join(warn.warnings, .newline);
					break;
				}
			}
		}
		toolTip = .replace(toolTip, "&", "&&");
		if (_tree.control.getToolTipText() != toolTip) { mixin(S_TRACE);
			_tree.control.setToolTipText(toolTip);
		}
	}

	static EventTreeView mainEventTreeView(EventTreeView[] vs) { mixin(S_TRACE);
		if (!vs.length) return null;
		auto ct = Display.getCurrent().getFocusControl();
		if (!ct) return null;
		foreach (v; vs) { mixin(S_TRACE);
			while (ct.getParent()) { mixin(S_TRACE);
				if (ct is v) { mixin(S_TRACE);
					return v;
				}
				ct = ct.getParent();
			}
		}
		return vs[0];
	}

	UndoManager _undo;
	abstract static class ETVUndo : Undo {
		private size_t[] _etPath;
		private size_t[] _selPath = null, _selPath2 = null;
		private CWXPath _area;
		private string _etCWXPath;
		protected Commons comm;
		protected Props prop;
		protected Summary summ;
		this (Commons comm, Props prop, Summary summ, EventTree et, CWXPath area) { mixin(S_TRACE);
			_area = area;
			_etCWXPath = .cprel(et.cwxPath(true), _area.cwxPath(true));
			this.comm = comm;
			this.prop = prop;
			this.summ = summ;
			_etPath = et.areaPath;
			auto vs = views();
			if (vs.length) { mixin(S_TRACE);
				auto mainV = mainEventTreeView(vs);
				auto sel = mainV ? mainV.selection : null;
				_selPath = sel ? (cast(Content)sel.getData()).ctPath : null;
			}
		}
		@property
		protected EventTree et() { mixin(S_TRACE);
			return cast(EventTree)_area.findCWXPath(_etCWXPath);
		}
		void udb(EventTreeView[] vs) { mixin(S_TRACE);
			if (!vs.length) return;
			auto mainV = mainEventTreeView(vs);
			auto ct = Display.getCurrent().getFocusControl();
			foreach (v; vs) { mixin(S_TRACE);
				v.editCancel();
				v._forceSel(_etPath);
			}
			auto sel = mainV ? mainV.selection : null;
			_selPath2 = sel ? (cast(Content)sel.getData()).ctPath : null;
			if (ct && !ct.isDisposed()) { mixin(S_TRACE);
				foreach (v; vs) { mixin(S_TRACE);
					while (ct.getParent()) { mixin(S_TRACE);
						if (ct is v) { mixin(S_TRACE);
							return;
						}
						ct = ct.getParent();
					}
				}
			}
			if (mainV) .forceFocus(mainV._tree.control, false);
		}
		void uda(EventTreeView[] vs) { mixin(S_TRACE);
			scope (exit) comm.refreshToolBar();
			foreach (v; vs) { mixin(S_TRACE);
				if (_selPath) v._tree.select(v.fromPath(_selPath));
				v.refreshStatusLine();
			}
			_selPath = _selPath2;
		}
		EventTreeView[] views() { mixin(S_TRACE);
			return comm.eventTreeViewFrom(_area, et, false);
		}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
	}
	private static void insertStart(EventTreeView[] vs, Commons comm, EventTree et, int index, Content c) { mixin(S_TRACE);
		foreach (v; vs) v._tree.control.setRedraw(false);
		scope (exit) foreach (v; vs) v._tree.control.setRedraw(true);
		bool empty = et.owner.isEmpty;
		scope (exit) {
			if (empty != et.owner.isEmpty) comm.refEventTree.call(et);
		}
		et.insert(index, c);
		foreach (v; vs) { mixin(S_TRACE);
			if (v._tree.tree) { mixin(S_TRACE);
				auto itm = createTreeItem(v._tree.tree, c, c.name, v._prop.images.content(c.type), index);
				v.createChilds(itm, c);
				v._tree.setExpanded(itm, true);
			} else { mixin(S_TRACE);
				v._tree.editor.updatePosOne(c);
			}
			v.refreshStatusLine();
			v._refreshTopStart();
			v.redraw();
		}
		comm.refContent.call(c);
		comm.refUseCount.call();
	}
	static class UndoContent : ETVUndo {
		private size_t[][] _path;
		private Content[] _c;
		this (Commons comm, Props prop, Summary summ, EventTree et, CWXPath area, Content[] cs) { mixin(S_TRACE);
			super (comm, prop, summ, et, area);
			foreach (c; cs) { mixin(S_TRACE);
				_path ~= c.ctPath;
				_c ~= c.dup;
				_c[$ - 1].setUseCounter(summ.useCounter.sub);
			}
		}
		private void impl() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			auto et = this.et;
			assert (et !is null);
			bool empty = et.owner.isEmpty;
			scope (exit) {
				if (empty != et.owner.isEmpty) comm.refEventTree.call(et);
			}
			foreach (i, c; _c.dup) { mixin(S_TRACE);
				auto index = _path[i][$ - 1];
				auto tc = et.fromPath(_path[i]);
				assert (tc !is null);
				auto pc = tc.parent;
				_c[i] = tc.dup;
				if (!pc) { mixin(S_TRACE);
					// スタートコンテントは名前被りを避けるため
					// 予めここで名前を変更しておく
					tc.setName(prop.parent, createNewName("*Temporary_Start_Name*", (name) { mixin(S_TRACE);
						return !et.hasStart(name) && c.name != name;
					}));
					et.startUseCounter.change(tc.name, c.name);
				}
				_c[i].setUseCounter(summ.useCounter.sub);
				string text;
				if (pc) { mixin(S_TRACE);
					pc.insert(prop.parent, index, c);
					text = .eventText(comm, summ, pc, c, false);
				} else { mixin(S_TRACE);
					et.insert(index, c);
					text = c.name;
				}
				foreach (v; vs) v._tree.control.setRedraw(false);
				scope (exit) foreach (v; vs) v._tree.control.setRedraw(true);
				foreach (v; vs) { mixin(S_TRACE);
					if (v._tree.tree) { mixin(S_TRACE);
						auto now = cast(TreeItem)v.fromPath(_path[i]);
						auto par = now.getParentItem();
						TreeItem itm;
						if (par) { mixin(S_TRACE);
							itm = createTreeItem(par, c, text, prop.images.content(c.type), cast(int)index);
						} else { mixin(S_TRACE);
							itm = createTreeItem(v._tree.tree, c, text, prop.images.content(c.type), cast(int)index);
						}
						v.procTreeItem(itm);
						v.createChilds(itm, c);
						v._tree.setExpanded(itm, true);
					} else { mixin(S_TRACE);
						v._tree.editor.updatePosOne(c);
					}
				}
				delImpl(vs, comm, et, tc);
				if (!pc) { mixin(S_TRACE);
					foreach (v; vs) { mixin(S_TRACE);
						v._refreshTopStart();
					}
				}
			}
			comm.refUseCount.call();
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { mixin(S_TRACE);
			foreach (c; _c) { mixin(S_TRACE);
				c.removeUseCounter();
			}
		}
	}
	void store(Content[] evt ...) { mixin(S_TRACE);
		_undo ~= new UndoContent(_comm, _prop, _summ, _et, _area, evt);
	}
	static class UndoSwap : ETVUndo {
		private int _upIndex;
		this (Commons comm, Props prop, Summary summ, EventTree et, CWXPath area, int swapIndex1, int swapIndex2) { mixin(S_TRACE);
			super (comm, prop, summ, et, area);
			_upIndex = swapIndex1 > swapIndex2 ? swapIndex1 : swapIndex2;
		}
		private void impl() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			udImpl!(-1)(vs, comm, et, et.starts[_upIndex], false);
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() {}
	}
	void storeSwap(int swapIndex1, int swapIndex2) { mixin(S_TRACE);
		_undo ~= new UndoSwap(_comm, _prop, _summ, _et, _area, swapIndex1, swapIndex2);
	}
	static class UndoInsert : ETVUndo {
		private int _index;
		private size_t _count;
		private Content[] _c;
		this (Commons comm, Props prop, Summary summ, EventTree et, CWXPath area, int index, size_t count) { mixin(S_TRACE);
			super (comm, prop, summ, et, area);
			_index = index;
			_count = count;
		}
		override void undo() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			foreach (v; vs) v._tree.control.setRedraw(false);
			scope (exit) foreach (v; vs) v._tree.control.setRedraw(true);
			for (size_t i = 0; i < _count; i++) { mixin(S_TRACE);
				auto c = et.starts[_index].dup;
				c.setUseCounter(summ.useCounter.sub);
				_c ~= c;
				delImpl(vs, comm, et, et.starts[_index]);
			}
			comm.refUseCount.call();
			foreach (v; vs) { mixin(S_TRACE);
				v.refreshStatusLine();
				v._refreshTopStart();
			}
		}
		override void redo() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			foreach_reverse (c; _c) { mixin(S_TRACE);
				insertStart(vs, comm, et, _index, c.dup);
			}
			_c = [];
		}
		override void dispose() { mixin(S_TRACE);
			foreach (c; _c) { mixin(S_TRACE);
				c.removeUseCounter();
			}
		}
	}
	void storeInsert(int insertIndex, size_t count = 1) { mixin(S_TRACE);
		_undo ~= new UndoInsert(_comm, _prop, _summ, _et, _area, insertIndex, count);
	}
	static class UndoDelete : ETVUndo {
		private int _index;
		private Content _c;
		this (Commons comm, Props prop, Summary summ, EventTree et, CWXPath area, int index, Content del) { mixin(S_TRACE);
			super (comm, prop, summ, et, area);
			_index = index;
			_c = del.dup;
			_c.setUseCounter(summ.useCounter.sub);
		}
		override void undo() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			insertStart(vs, comm, et, _index, _c.dup);
		}
		override void redo() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			foreach (v; vs) v._tree.control.setRedraw(false);
			scope (exit) foreach (v; vs) v._tree.control.setRedraw(true);
			delImpl(vs, comm, et, et.starts[_index]);
			comm.refUseCount.call();
			foreach (v; vs) { mixin(S_TRACE);
				v.refreshStatusLine();
				v._refreshTopStart();
			}
		}
		override void dispose() { mixin(S_TRACE);
			_c.removeUseCounter();
		}
	}
	void storeDelete(int index, Content del) { mixin(S_TRACE);
		_undo ~= new UndoDelete(_comm, _prop, _summ, _et, _area, index, del);
	}
	private Item fromPath(string cwxPath) { mixin(S_TRACE);
		return fromPathImpl(_tree, cwxPath);
	}
	private Item fromPathImpl(T)(T tree, string cwxPath) { mixin(S_TRACE);
		if (cpempty(cwxPath)) return null;
		string cate = cpcategory(cwxPath);
		while ("" != cate) { mixin(S_TRACE);
			cwxPath = cpbottom(cwxPath);
			if (cpempty(cwxPath)) return null;
			cate = cpcategory(cwxPath);
		}
		auto itm = _tree.getItem(tree, cast(int)cpindex(cwxPath));
		cwxPath = cpbottom(cwxPath);
		if (cpempty(cwxPath)) return itm;
		return fromPathImpl(itm, cwxPath);
	}
	private Item fromPath(size_t[] path) { mixin(S_TRACE);
		return fromPathImpl(_tree, path);
	}
	private Item fromPathImpl(T)(T tree, size_t[] path) { mixin(S_TRACE);
		if (!path.length) return null;
		auto itm = _tree.getItem(tree, cast(int)path[0]);
		if (path.length == 1) return itm;
		return fromPathImpl(itm, path[1 .. $]);
	}
	static class UndoCP : Undo {
		private UndoContent _undoC;
		private UndoDelete _undoD = null;
		this (Commons comm, Props prop, Summary summ, EventTree et, CWXPath area, Content[] conts, int index, Content start) { mixin(S_TRACE);
			_undoC = new UndoContent(comm, prop, summ, et, area, conts);
			if (start) _undoD = new UndoDelete(comm, prop, summ, et, area, index, start);
		}
		override void undo() { mixin(S_TRACE);
			if (_undoD) _undoD.undo();
			_undoC.undo();
		}
		override void redo() { mixin(S_TRACE);
			_undoC.redo();
			if (_undoD) _undoD.redo();
		}
		override void dispose() { mixin(S_TRACE);
			_undoC.dispose();
			if (_undoD) _undoD.dispose();
		}
	}
	static class UndoContentAndInsert : ETVUndo {
		private UndoContent _undoC;
		private UndoInsert _undoI;
		this (Commons comm, Props prop, Summary summ, EventTree et, CWXPath area, Content owner, int insertIndex, int count) { mixin(S_TRACE);
			super (comm, prop, summ, et, area);
			_undoC = new UndoContent(comm, prop, summ, et, area, [owner]);
			_undoI = new UndoInsert(comm, prop, summ, et, area, insertIndex, count);
		}
		override void undo() { mixin(S_TRACE);
			_undoI.undo();
			_undoC.undo();
		}
		override void redo() { mixin(S_TRACE);
			_undoC.redo();
			_undoI.redo();
		}
		override void dispose() { mixin(S_TRACE);
			_undoC.dispose();
			_undoI.dispose();
		}
	}
	void storeContentAndInsert(Content owner, int insertIndex, int count) { mixin(S_TRACE);
		_undo ~= new UndoContentAndInsert(_comm, _prop, _summ, _et, _area, owner, insertIndex, count);
	}

	private EventTreeView[] views() { mixin(S_TRACE);
		return _comm.eventTreeViewFrom(_area, _et, false);
	}

	private EventDialog[string] _editDlgs;
	void appliedEdit(UndoContent undo, Content c, bool focus) { mixin(S_TRACE);
		_undo ~= undo;
		auto cwxPath = c.cwxPath(true);
		foreach (v; views()) { mixin(S_TRACE);
			auto itm = v.fromPath(cwxPath);
			assert (c is itm.getData());
			foreach (childItm; v._tree.getItems(itm)) { mixin(S_TRACE);
				auto par = cast(Content)itm.getData();
				assert (par.detail.owner);
				childItm.setText(v.eventText(par, cast(Content)childItm.getData()));
				v.procTreeItem(childItm);
			}
			v.procTreeItem(itm);
			if (v is this) v._tree.select(itm);
			if (v._tree.editor) { mixin(S_TRACE);
				v._tree.editor.updatePosOne(c);
			} else { mixin(S_TRACE);
				v.redraw();
			}
			v.refreshStatusLine();
		}
		if (focus) .forceFocus(_tree.control, false);
		_comm.refContent.call(c);
		_comm.refUseCount.call();
		_comm.refreshToolBar();
	}
	void editM() { edit(); }
	public EventDialog edit() { mixin(S_TRACE);
		if (_readOnly) return null;
		auto sels = _tree.getSelection();
		if (sels.length > 0) { mixin(S_TRACE);
			auto c = cast(Content)sels[0].getData();
			return edit(c);
		}
		return null;
	}
	void create(Item insertTo) { mixin(S_TRACE);
		if (!_box) return;
		if (_readOnly) return;
		if (!_tree.getItemCount()) return;
		if (!_box._arrowMode || _box._putMode is MenuID.PutQuick) { mixin(S_TRACE);
			_tree.control.setRedraw(false);
			scope (exit) _tree.control.setRedraw(true);
			foreach (v; views()) v.editEnter();
			if (_box._cType == CType.START) { mixin(S_TRACE);
				if (insertTo) return;
				create(null, _box._cType, "", (Content evt) { mixin(S_TRACE);
					assert (evt);
					bool empty = _et.owner.isEmpty;
					scope (exit) {
						if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
					}
					auto sel = selection;
					int index;
					if (sel) { mixin(S_TRACE);
						index = _tree.indexOf(_tree.topItem(sel)) + 1;
					} else { mixin(S_TRACE);
						index = -1;
					}
					storeInsert(index);
					_et.insert(index, cast(Content)evt);
					auto img = _prop.images.content(CType.START);
					foreach (v; views()) { mixin(S_TRACE);
						Item sItm;
						if (v._tree.tree) { mixin(S_TRACE);
							sItm = createTreeItem(v._tree.tree, evt, evt.name, img, index);
						} else { mixin(S_TRACE);
							v._tree.editor.updatePosOne(evt);
							sItm = EventEditorItem.valueOf(v._tree.editor, evt);
						}
						if (v is this) v._tree.select(sItm);
						if (v is this) v._tree.showSelection();
						v.refreshStatusLine();
						if (v._box && v._box._putMode !is MenuID.PutContinue) v._box.arrow();
					}
					.forceFocus(_tree.control, false);
					_comm.refContent.call(evt);
					_comm.refreshToolBar();
				});
			} else { mixin(S_TRACE);
				if (insertTo && !CDetail.fromType(_box._cType).owner) return;
				auto sel = selection;
				if (!sel) return;
				if (!insertTo && sel && !(cast(Content)sel.getData()).detail.owner) { mixin(S_TRACE);
					sel = _tree.getParentItem(sel);
					if (!sel) return;
				}
				if (insertTo || (sel && (cast(Content)sel.getData()).detail.owner)) { mixin(S_TRACE);
					Item oItm;
					int insertIndex = -1;
					if (insertTo) { mixin(S_TRACE);
						oItm = _tree.getParentItem(insertTo);
						if (!oItm) return;
						insertIndex = _tree.indexOf(oItm, insertTo);
					} else { mixin(S_TRACE);
						oItm = sel;
					}
					auto owner = cast(Content) oItm.getData();
					auto isInsertFirst = _box.isInsertFirst;
					void applied(Content evt) { mixin(S_TRACE);
						bool empty = _et.owner.isEmpty;
						scope (exit) {
							if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
						}
						store(owner);
						if (insertIndex == -1) { mixin(S_TRACE);
							if (isInsertFirst) { mixin(S_TRACE);
								insertIndex = 0;
								owner.insert(_prop.parent, 0, evt);
							} else { mixin(S_TRACE);
								owner.add(_prop.parent, evt);
							}
						} else { mixin(S_TRACE);
							owner.insert(_prop.parent, insertIndex, evt);
						}
						auto vs = views();
						auto text = eventText(owner, evt);
						auto img = _prop.images.content(evt.type);
						Item[] itms;
						foreach (v; vs) { mixin(S_TRACE);
							Item itm;
							if (v._tree.tree) { mixin(S_TRACE);
								assert (cast(TreeItem)oItm !is null);
								auto oItm2 = .anotherTreeItem(v._tree.tree, cast(TreeItem)oItm);
								itm = createTreeItem(cast(TreeItem)oItm2, evt, text, img, insertIndex);
								v._tree.setExpanded(oItm2, true);
							} else { mixin(S_TRACE);
								v._tree.editor.updatePosOne(evt);
								itm = EventEditorItem.valueOf(v._tree.editor, evt);
							}
							if (v is this) v._tree.setSelection([itm]);
							itms ~= itm;
						}
						if (insertTo) { mixin(S_TRACE);
							auto ic = cast(Content)insertTo.getData();
							_comm.delContent.call(ic);
							ic.parent.remove(ic);
							if (_prop.var.etc.adjustContentName) { mixin(S_TRACE);
								ic.setName(_prop.parent, "");
							}
							if (isInsertFirst) { mixin(S_TRACE);
								evt.insert(_prop.parent, 0, ic);
							} else { mixin(S_TRACE);
								evt.add(_prop.parent, ic);
							}
							foreach (i, v; vs) { mixin(S_TRACE);
								auto itm = itms[i];
								if (v._tree.tree) { mixin(S_TRACE);
									assert (cast(TreeItem)insertTo !is null);
									auto insertTo2 = .anotherTreeItem(v._tree.tree, cast(TreeItem)insertTo);
									insertTo2.dispose();
									v.createChilds(itm, evt);
								}
								v._tree.setExpanded(itm, true);
							}
						}
						foreach (i, v; vs) { mixin(S_TRACE);
							procTreeItem(itms[i]);
							if (v is this) v._tree.showSelection();
							v.refreshStatusLine();
							if (v._box && v._box._putMode !is MenuID.PutContinue) v._box.arrow();
						}
						.forceFocus(_tree.control, false);
						_comm.refContent.call(evt);
						_comm.refUseCount.call();
						_comm.refreshToolBar();
					}
					if (insertTo) { mixin(S_TRACE);
						create(owner, _box._cType, (cast(Content) insertTo.getData()).name, &applied);
					} else { mixin(S_TRACE);
						create(owner, _box._cType, "", &applied);
					}
				}
			}
		}
	}

	bool checkOpenDialog(CType type) { mixin(S_TRACE);
		if (_readOnly) return false;
		switch (type) {
		case CType.START_BATTLE: { mixin(S_TRACE);
			return _summ.battles.length > 0;
		} case CType.CHANGE_AREA: { mixin(S_TRACE);
			return _summ.areas.length > 0;
		} case CType.LINK_PACKAGE, CType.CALL_PACKAGE: { mixin(S_TRACE);
			return _summ.packages.length > 0;
		} case CType.BRANCH_FLAG, CType.SET_FLAG, CType.REVERSE_FLAG, CType.CHECK_FLAG, CType.SUBSTITUTE_FLAG, CType.BRANCH_FLAG_CMP: { mixin(S_TRACE);
			return _summ.flagDirRoot.allFlags.length > 0;
		} case CType.BRANCH_MULTI_STEP, CType.BRANCH_STEP, CType.SET_STEP, CType.SET_STEP_UP, CType.SET_STEP_DOWN, CType.SUBSTITUTE_STEP, CType.BRANCH_STEP_CMP: { mixin(S_TRACE);
			return 0 < _summ.flagDirRoot.allSteps.length;
		} case CType.BRANCH_CAST, CType.GET_CAST, CType.LOSE_CAST: { mixin(S_TRACE);
			return _summ.casts.length > 0;
		} case CType.BRANCH_ITEM, CType.GET_ITEM, CType.LOSE_ITEM: { mixin(S_TRACE);
			return _summ.items.length > 0;
		} case CType.BRANCH_SKILL, CType.GET_SKILL, CType.LOSE_SKILL: { mixin(S_TRACE);
			return _summ.skills.length > 0;
		} case CType.BRANCH_INFO, CType.GET_INFO, CType.LOSE_INFO: { mixin(S_TRACE);
			return _summ.infos.length > 0;
		} case CType.BRANCH_BEAST, CType.GET_BEAST, CType.LOSE_BEAST: { mixin(S_TRACE);
			return _summ.beasts.length > 0;
		} case CType.REDISPLAY: { mixin(S_TRACE);
			return !_summ.legacy;
		} case CType.CHECK_STEP: { mixin(S_TRACE);
			return 0 < _summ.flagDirRoot.allSteps.length;
		} default: { mixin(S_TRACE);
			return true;
		}
		}
	}

	void updateSkinMaterialsExtension(Content c) { mixin(S_TRACE);
		auto uc = c.useCounter;
		c.setUseCounter(new UseCounter);
		scope (exit) {
			if (uc) {
				c.setUseCounter(uc);
			} else {
				c.removeUseCounter();
			}
		}
		_comm.updateSkinMaterialsExtension(c.useCounter, null, summSkin);
	}

	void initial(Content c) { mixin(S_TRACE);
		auto ver = (_summ && _summ.legacy) ? "Classic" : _summ.dataVersion;
		foreach (ref initializer; _prop.var.etc.contentInitializers) { mixin(S_TRACE);
			if (initializer.dataVersion == "Basic") continue;
			if (initializer.dataVersion == ver) { mixin(S_TRACE);
				if (c.type in initializer.initializer) {
					c.shallowCopy(initializer.initializer[c.type]);
					updateSkinMaterialsExtension(c);
					return;
				}
			}
		}
		foreach (ref initializer; _prop.var.etc.contentInitializers) { mixin(S_TRACE);
			if (initializer.dataVersion == "Basic") { mixin(S_TRACE);
				if (c.type in initializer.initializer) { mixin(S_TRACE);
					c.shallowCopy(initializer.initializer[c.type]);
					updateSkinMaterialsExtension(c);
					return;
				}
			}
		}

		.initial(_comm, summSkin, _summ && _summ.legacy, _summ.dataVersion, _prop.var.etc.bgImagesDefault, c);
		updateSkinMaterialsExtension(c);
	}

	void create(Content parent, CType type, string name, void delegate(Content) applied) { mixin(S_TRACE);
		if (!_box) return;
		if (_readOnly) return;
		assert (parent is null || parent.detail.owner);
		foreach (v; views()) v.editEnter();
		if (_box && _box._putMode !is MenuID.PutContinue) { mixin(S_TRACE);
			_box.arrow();
			_comm.refreshToolBar();
		}
		if (hasDialog(type)) { mixin(S_TRACE);
			if (!_box.isAutoOpen || !checkOpenDialog(type)) { mixin(S_TRACE);
				auto c = new Content(type, name);
				initial(c);
				applied(c);
				return;
			}
		} else { mixin(S_TRACE);
			if (type is CType.START) { mixin(S_TRACE);
				string startName = _prop.msgs.defaultStartName;
				auto sel = selection;
				if (_prop.var.etc.useCurrentStartName && sel) { mixin(S_TRACE);
					if (auto s = (cast(Content)sel.getData()).parentStart) { mixin(S_TRACE);
						startName = s.name;
					}
				}
				name = createNewName(startName, (string name) { mixin(S_TRACE);
					return !_et.hasStart(name);
				}, true, EventView.eventTreeNames(_prop, _et));
			}
			applied(new Content(type, name));
			return;
		}
		auto evt = new Content(type, name);
		initial(evt);
		auto dlg = createEventDialog(evt, parent, true);
		assert (applied);
		dlg.appliedEvent ~= { mixin(S_TRACE);
			auto evt = dlg.event;
			applied(evt);

			auto undo = new UndoContent(_comm, _prop, _summ, _et, _area, [evt]);
			dlg.appliedEvent.length = 0;
			dlg.appliedEvent ~= { mixin(S_TRACE);
				appliedEdit(undo, evt, true);
				undo = new UndoContent(_comm, _prop, _summ, _et, _area, [evt]);
			};
		};
		_editDlgs[evt.eventId] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgs.remove(evt.eventId);
		};
		dlg.open();
	}

	@property
	public bool canEdit() { mixin(S_TRACE);
		if (_readOnly) return false;
		auto itm = selection;
		if (!itm) return false;
		auto evt = cast(Content) itm.getData();
		return hasDialog(evt.type) && checkOpenDialog(evt.type);
	}
	EventDialog edit(Content evt) { mixin(S_TRACE);
		if (_readOnly) return null;
		if (!hasDialog(evt.type) || !checkOpenDialog(evt.type)) return null;
		foreach (v; views()) v.editEnter();
		auto p = evt.eventId in _editDlgs;
		if (p) { mixin(S_TRACE);
			p.active();
			return *p;
		}
		auto dlg = createEventDialog(evt, evt.parent, false);
		auto undo = new UndoContent(_comm, _prop, _summ, _et, _area, [evt]);
		dlg.appliedEvent ~= { mixin(S_TRACE);
			appliedEdit(undo, evt, false);
			undo = new UndoContent(_comm, _prop, _summ, _et, _area, [evt]);
		};
		_editDlgs[evt.eventId] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgs.remove(evt.eventId);
		};
		dlg.open();
		return dlg;
	}

	EventDialog createEventDialog(Content evt, Content parent, bool create) { mixin(S_TRACE);
		return .createEventDialog(_comm, _summ, _tree.control.getShell(), evt, parent, create);
	}

	@property
	AbstractArea refTarget() { mixin(S_TRACE);
		if (_et && _et.owner) { mixin(S_TRACE);
			auto a = cast(Area) _et.owner;
			if (a) return a;
			auto b = cast(Battle) _et.owner;
			if (b) return b;
			auto m = cast(MenuCard) _et.owner;
			if (m) return m.owner;
			auto e = cast(EnemyCard) _et.owner;
			if (e) return e.owner;
		}
		return null;
	}

	void refreshStatusLine() { mixin(S_TRACE);
		if (!_summ) return;
		auto itm = selection;
		if (itm && cast(Content)itm.getData()) { mixin(S_TRACE);
			_statusLine = .contentText(_comm, cast(Content)itm.getData(), _summ);
		} else { mixin(S_TRACE);
			_statusLine = "";
		}
		_comm.setStatusLine(_tree.control, _statusLine);
	}
	class TListener : TreeListener {
		override void treeCollapsed(TreeEvent e) { mixin(S_TRACE);
			_comm.refreshToolBar();
		}
		override void treeExpanded(TreeEvent e) { mixin(S_TRACE);
			_comm.refreshToolBar();
		}
	}
	class SListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			assert (cast(Content) e.item.getData());
			refreshStatusLine();
			_comm.refreshToolBar();
		}
	}
	private Item _dragItm = null;
	class EventDragSource : DragSourceListener {
	private:
		Item _parItm;
		Item _targ;
	public:
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			auto itm = selection;
			e.doit = !_readOnly && itm && (cast(Content) itm.getData()).type != CType.START
				&& (cast(DragSource) e.getSource()).getControl().isFocusControl();
			if (e.doit) { mixin(S_TRACE);
				_targ = itm;
				_parItm = _tree.getParentItem(itm);
				_dragItm = _targ;
			}
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			auto itm = selection;
			if (itm && XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				e.data = bytesFromXML(toXML((cast(Content)itm.getData())));
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			_dragItm = null;
			auto itm = _targ;
			if (itm && e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				bool empty = _et.owner.isEmpty;
				scope (exit) {
					if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
				}
				auto c = cast(Content)itm.getData();
				auto parentStart = c.parentStart;
				_comm.delContent.call(c);
				if (_parItm) { mixin(S_TRACE);
					assert (_parItm.getData());
					assert (itm.getData());
					assert ((cast(Content)_parItm.getData()).detail.owner);
					assert (cast(Content)itm.getData());
					(cast(Content)_parItm.getData()).remove(c);
				} else { mixin(S_TRACE);
					_et.remove(c);
				}
				auto tPath = _tree.tree ? .toTreePath(cast(TreeItem)itm) : [];
				foreach (v; views()) { mixin(S_TRACE);
					v._tree.control.setRedraw(false);
					scope (exit) v._tree.control.setRedraw(true);
					if (v._tree.tree) { mixin(S_TRACE);
						.fromTreePath(v._tree.tree, tPath).dispose();
					} else {
						v._tree.editor.updatePosOne(parentStart);
					}
				}
				_comm.refUseCount.call();
				_comm.refreshToolBar();
			}
		}
	}
	class EventDropTarget : DropTargetAdapter {
	private:
		void move(DropTargetEvent e) { mixin(S_TRACE);
			if (_readOnly) { mixin(S_TRACE);
				e.detail = DND.DROP_NONE;
				return;
			}
			if (_tree.tree) { mixin(S_TRACE);
				e.detail = e.item ? DND.DROP_MOVE : DND.DROP_NONE;
			} else { mixin(S_TRACE);
				auto p = _tree.editor.toControl(new Point(e.x, e.y));
				auto c = _tree.editor.getContent(p.x, p.y);
				_tree.editor.updateLightup();
				e.detail = c ? DND.DROP_MOVE : DND.DROP_NONE;
			}
		}
	public:
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			if (_readOnly) return;
			e.detail = DND.DROP_NONE;
			if (!isXMLBytes(e.data)) return;
			if (!_tree.tree) { mixin(S_TRACE);
				auto p = _tree.editor.toControl(new Point(e.x, e.y));
				auto c = _tree.editor.getContent(p.x, p.y);
				if (!c) return;
				e.item = EventEditorItem.valueOf(_tree.editor, c);
			}
			assert (cast(Item)e.item);
			auto ti = cast(Item)e.item;
			if (!(cast(Content)ti.getData()).detail.owner) { mixin(S_TRACE);
				ti = _tree.getParentItem(ti);
				if (!ti) return;
			}
			if ((cast(Content)ti.getData()).detail.owner) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto node = XNode.parse(bytesToXML(e.data));
					bool samePane = _id == node.attr("paneId", false, "");
					string id = node.attr("contentId", false, "");
					string lastNextType = node.attr("lastNextType", false, "");
					auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
					auto evt = Content.createFromNode(node, ver);
					if (evt) { mixin(S_TRACE);
						auto owner = cast(Content)ti.getData();
						assert (owner.detail.owner);
						auto sp = selParent(ti);
						if (!sp || sp.eventId != id) { mixin(S_TRACE);
							// 転送先が自分の子コンテントではないなら転送成功
							foreach (v; views()) v.editEnter();
							bool empty = _et.owner.isEmpty;
							scope (exit) {
								if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
							}
							if (_dragItm) { mixin(S_TRACE);
								auto top = _tree.topItem(ti);
								if (top == _tree.topItem(_dragItm)) { mixin(S_TRACE);
									store(cast(Content)top.getData());
								} else { mixin(S_TRACE);
									store(cast(Content)_tree.getParentItem(_dragItm).getData(), owner);
								}
								if (cast(Content)_tree.getParentItem(_dragItm).getData() !is owner) { mixin(S_TRACE);
									adjustText(owner, evt, lastNextType);
								}
							} else { mixin(S_TRACE);
								store(owner);
							}
							int insertIndex = -1;
							if (_box.isInsertFirst) { mixin(S_TRACE);
								owner.insert(_prop.parent, 0, evt);
								insertIndex = 0;
							} else { mixin(S_TRACE);
								owner.add(_prop.parent, evt);
							}
							_comm.refContent.call(evt);
							foreach (v; views()) {
								v._tree.control.setRedraw(false);
								scope (exit) v._tree.control.setRedraw(true);
								Item itm;
								if (v._tree.tree) { mixin(S_TRACE);
									assert (cast(TreeItem)ti !is null);
									auto ti2 = .anotherTreeItem(v._tree.tree, cast(TreeItem)ti);
									itm = createTreeItem(ti2, evt, v.eventText(owner, evt), _prop.images.content(evt.type), insertIndex);
								} else { mixin(S_TRACE);
									v._tree.editor.updatePosOne(evt);
									itm = EventEditorItem.valueOf(v._tree.editor, evt);
								}
								v.procTreeItem(itm);
								if (v is this) v._tree.setSelection([itm]);
								v.refreshStatusLine();
								if (evt.detail.owner) { mixin(S_TRACE);
									v.createChilds(itm, evt);
									v._tree.setExpanded(itm, true);
									auto parItm = v._tree.getParentItem(itm);
									if (parItm) v._tree.setExpanded(parItm, true);
								}
								v.refreshStatusLine();
							}
							_comm.refUseCount.call();
							e.detail = samePane ? DND.DROP_MOVE : DND.DROP_COPY;
							_comm.refreshToolBar();
						}
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
		private Content selParent(Item targ) { mixin(S_TRACE);
			auto itm = selection;
			if (itm) { mixin(S_TRACE);
				while (targ) { mixin(S_TRACE);
					if (itm == targ) { mixin(S_TRACE);
						return cast(Content)itm.getData();
					}
					targ = _tree.getParentItem(targ);
				}
			}
			return null;
		}
	}
	private bool nTypeIsText(CNextType type) { mixin(S_TRACE);
		return type is CNextType.TEXT || type is CNextType.COUPON;
	}
	private void adjustText(in Content owner, Content evt, string lastNextType) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_prop.var.etc.adjustContentName) return;
		if (lastNextType != "" && owner.detail.nextType !is toCNextType(lastNextType)
				&& !(nTypeIsText(owner.detail.nextType) && nTypeIsText(toCNextType(lastNextType)))) { mixin(S_TRACE);
			// 後続タイプが異なるので一端後続テキストをクリア
			evt.setName(_prop.parent, "");
		} else if (owner.detail.nextType !is CNextType.TEXT && owner.detail.nextType !is CNextType.COUPON) { mixin(S_TRACE);
			foreach (ct; owner.next) { mixin(S_TRACE);
				if (ct.name == evt.name) { mixin(S_TRACE);
					// すでに同じテキストの後続コンテントがいるので
					// 一端後続テキストをクリア
					evt.setName(_prop.parent, "");
					break;
				}
			}
		}
	}
	void redraw() { mixin(S_TRACE);
		if (_tree.editor) { mixin(S_TRACE);
			_tree.editor.redraw();
		} else { mixin(S_TRACE);
			_tree.control.redraw();
		}
	}
	class TRDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			if (!_readOnly) { mixin(S_TRACE);
				_comm.refSkin.remove(&refSkin);
				_comm.refDataVersion.remove(&refDataVersion);
				_comm.refCast.remove(&refreshCast);
				_comm.delCast.remove(&refreshCast);
				_comm.refSkill.remove(&refreshSkill);
				_comm.delSkill.remove(&delSkill);
				_comm.refItem.remove(&refreshItem);
				_comm.delItem.remove(&delItem);
				_comm.refBeast.remove(&refreshBeast);
				_comm.delBeast.remove(&delBeast);
				_comm.refInfo.remove(&refreshInfo);
				_comm.delInfo.remove(&refreshInfo);
				_comm.refArea.remove(&refreshArea);
				_comm.delArea.remove(&refreshArea);
				_comm.refBattle.remove(&refreshBattle);
				_comm.delBattle.remove(&refreshBattle);
				_comm.refPackage.remove(&refreshPackage);
				_comm.delPackage.remove(&refreshPackage);
				_comm.refFlagAndStep.remove(&refreshFlagAndStep);
				_comm.delFlagAndStep.remove(&refreshFlagAndStep);
				_comm.refPath.remove(&refreshPath);
				_comm.refPaths.remove(&refreshPaths);
				_comm.delPaths.remove(&deletePaths);
				_comm.replPath.remove(&replacePaths);
				_comm.replText.remove(&refreshCard);
				_comm.replText.remove(&refreshEventText);
				_comm.replID.remove(&refreshCard);
				_comm.refContentText.remove(&refreshEventText);
				_comm.refPreviewValues.remove(&refreshEventText);
				_comm.selContentTool.remove(&selContentTool);
				_comm.refEventTemplates.remove(&refreshTemplates);
			}
			_comm.refTargetVersion.remove(&redraw);
			if (_summ) { mixin(S_TRACE);
				_comm.refEventTreeViewStyle.remove(&refEventTreeViewStyle);
			}
			if (_grayFont) _grayFont.dispose();
			foreach (dlg; _editDlgs.values) { mixin(S_TRACE);
				dlg.forceCancel();
			}
			foreach (dlg; _commentDlgs.values) { mixin(S_TRACE);
				dlg.forceCancel();
			}
		}
	}

	/// 使用数とツリー毎の区切り線の描画。
	void drawStartInfo(PaintEvent e, Color lineColor, Color fontColor) { mixin(S_TRACE);
		if (!_et) return;
		assert (_tree.tree !is null);
		if (_summ) { mixin(S_TRACE);
			if (!_prop.var.etc.drawCountOfUseOfStart && !_prop.var.etc.drawContentTreeLine) return;
		} else { mixin(S_TRACE);
			if (!drawCountOfUseOfStart && !drawContentTreeLine) return;
		}
		auto d = _tree.control.getDisplay();
		auto ca = _tree.control.getClientArea();
		auto suc = _et.startUseCounter;
		auto fore = e.gc.getForeground();
		auto back = e.gc.getBackground();
		auto counts = new string[_tree.getItemCount()];
		auto ucExtent = e.gc.wTextExtent(_prop.msgs.startUseCount);
		int maxW = 0;
		int h = e.gc.getFontMetrics().getHeight();
		if (_summ ? _prop.var.etc.drawCountOfUseOfStart : drawCountOfUseOfStart) { mixin(S_TRACE);
			foreach (i, itm; _tree.tree.getItems()) { mixin(S_TRACE);
				auto c = cast(Content)itm.getData();
				assert (c);
				int count = suc.get(toStartId(c.name));
				if (0 == i) count++;
				counts[i] = .text(count);
				auto extent = e.gc.wTextExtent(counts[i]);
				maxW = max(maxW, extent.x);
			}
		}
		foreach (i, itm; _tree.tree.getItems()) { mixin(S_TRACE);
			auto b = itm.getBounds();
			if (b.y + b.height <= ca.y) continue;
			if (ca.y + ca.height < b.y) break;
			if ((_summ ? _prop.var.etc.drawContentTreeLine : drawContentTreeLine) && 0 < i) { mixin(S_TRACE);
				e.gc.setForeground(lineColor);
				scope (exit) e.gc.setForeground(fore);
				e.gc.drawLine(0, b.y, ca.width, b.y);
			}
			if ((_summ ? _prop.var.etc.drawCountOfUseOfStart : drawCountOfUseOfStart)) { mixin(S_TRACE);
				string t = counts[i];
				int tx = ca.width - maxW - 5.ppis;
				int ty = b.y + (b.height - h) / 2;
				e.gc.wDrawText(t, tx, ty);
				e.gc.setForeground(fontColor);
				scope (exit) e.gc.setForeground(fore);
				e.gc.wDrawText(_prop.msgs.startUseCount, tx - ucExtent.x - 5.ppis, ty);
			}
		}
	}
	/// コメントと警告の描画。
	void drawComment(PaintEvent e, Color lineColor) { mixin(S_TRACE);
		assert (_tree.tree !is null);
		auto fore = e.gc.getForeground();
		auto back = e.gc.getBackground();
		auto font = e.gc.getFont();
		auto fSize = font ? cast(uint)font.getFontData()[0].height : 0;
		e.gc.setFont(new Font(_tree.control.getDisplay(), dwtData(_prop.looks.textDlgFont(fSize))));
		scope (exit) e.gc.getFont().dispose();
		Rectangle[] boxes;
		TreeItem[] itms;
		void recurse(TreeItem itm) { mixin(S_TRACE);
			boxes ~= itm.getBounds();
			itms ~= itm;
			if (_tree.getExpanded(itm)) { mixin(S_TRACE);
				foreach (chld; itm.getItems()) { mixin(S_TRACE);
					recurse(chld);
				}
			}
		}
		foreach (itm; _tree.tree.getItems()) { mixin(S_TRACE);
			recurse(itm);
		}
		if (!itms.length) return;
		auto ca = _tree.control.getClientArea();
		auto itmBounds = itms[0].getBounds();
		int itmH = itmBounds.height;
		int mny = itmBounds.y;
		auto bb = itms[$ - 1].getBounds();
		int mxy = bb.y + bb.height;
		int alpha = e.gc.getAlpha();
		auto lineHeight = e.gc.getFontMetrics().getHeight();
		Rectangle[] bs;
		string[][] texts;
		const MARGIN_L = 5.ppis;
		const MARGIN_T = 4.ppis;
		Image wImg = null;
		scope (exit) {
			if (wImg) wImg.dispose();
		}
		_warningRects = [];
		Image warningImage() { mixin(S_TRACE);
			if (!wImg) { mixin(S_TRACE);
				wImg = .warningImage(_prop, _tree.control.getDisplay());
			}
			return wImg;
		}
		auto dotExtent = e.gc.wTextExtent("...");

		void setAntialias(int antialias) { mixin(S_TRACE);
			version (Windows) {
				alias org.eclipse.swt.internal.win32.OS.OS OS;
				if (OS.VERSION(6, 0) <= OS.WIN32_VERSION) e.gc.setAntialias(antialias);
			} else {
				e.gc.setAntialias(antialias);
			}
		}
		void setAlpha(int alpha) {mixin(S_TRACE);
			version (Windows) {
				alias org.eclipse.swt.internal.win32.OS.OS OS;
				if (OS.VERSION(6, 0) <= OS.WIN32_VERSION) e.gc.setAlpha(alpha);
			} else {
				e.gc.setAlpha(alpha);
			}
		}

		foreach (i, itm; itms) { mixin(S_TRACE);
			if (itm.getItemCount() && !itm.getExpanded()) { mixin(S_TRACE);
				// アイテムを畳んでいる場合は明示する
				setAlpha(128);
				scope (exit) setAlpha(255);
				auto bounds = itm.getBounds();
				int dotX = bounds.x + bounds.width + 2.ppis;
				bounds.x = dotX + 10.ppis;
				bounds.width = dotExtent.x + 10.ppis;
				e.gc.wDrawText("...", bounds.x + 5.ppis, bounds.y + (bounds.height - dotExtent.y) / 2, true);
				auto lineY = bounds.y + bounds.height / 2;
				e.gc.drawLine(dotX, lineY, bounds.x, lineY);
				setAntialias(SWT.ON);
				scope (exit) setAntialias(SWT.OFF);
				e.gc.drawRoundRectangle(bounds.x, bounds.y, bounds.width, bounds.height, 10.ppis, 10.ppis);
			}
			auto c = cast(Content) itm.getData();
			string cm = c.comment;
			if (cm.length) { mixin(S_TRACE);
				int dis = _prop.var.etc.commentBoxDistance;
				auto ib = itm.getBounds();
				cm = std.string.chomp(.lastRet(cm));
				auto te = e.gc.wTextExtent(cm);
				// 改行文字があると横幅がおかしくなるため
				// 測り直す
				te.x = 0;
				auto lines = splitLines!string(cm);
				foreach (line; lines) { mixin(S_TRACE);
					te.x = max(e.gc.wTextExtent(line).x, te.x);
				}
				int tx = ib.x + ib.width + dis;
				int ty = ib.y + (ib.height - te.y) / 2;
				int bx = tx - MARGIN_L;
				int by = ty - MARGIN_T;
				int bw = te.x + MARGIN_L * 2;
				int bh = te.y + MARGIN_T * 2;
				if (by < mny) { mixin(S_TRACE);
					ty += mny - by;
					by = ty - MARGIN_T;
				}
				if (mxy < by + bh) { mixin(S_TRACE);
					ty -= by + bh - mxy;
					by = ty - MARGIN_T;
				}
				auto box = new Rectangle(bx, by, bw, bh);
				foreach (b; boxes) { mixin(S_TRACE);
					if (b.intersects(box)) { mixin(S_TRACE);
						bx = b.x + b.width + MARGIN_L;
						box.x = bx;
						tx = bx + MARGIN_L;
						dis = tx - ib.x - ib.width;
					}
				}

				/// ラインのみを先行描画
				e.gc.setBackground(lineColor);
				scope (exit) e.gc.setBackground(back);
				int px = ib.x + ib.width + 2.ppis;
				int py = ib.y + ib.height / 2 - 1;
				e.gc.fillRectangle(px, py, dis - MARGIN_L - 2, 1);

				boxes ~= box;
				bs ~= box;
				texts ~= lines;
			}
			if ((_summ ? _prop.var.etc.drawContentWarnings : drawContentWarnings)) { mixin(S_TRACE);
				auto warnings = .warnings(_prop.parent, summSkin, _summ, c, _prop.var.etc.targetVersion);
				if (warnings.length) { mixin(S_TRACE);
					warnings = warnings.sort().uniq().array();
					auto b = itm.getBounds();
					if (b.y + b.height <= ca.y) continue;
					if (ca.y + ca.height < b.y) continue;
					auto ib = itm.getImageBounds(0);
					if (ca.width <= ib.x) continue;
					auto img = warningImage();
					int ix = .max(ib.x, ca.width - _prop.var.etc.warningImageWidth);
					e.gc.drawImage(img, 0, 0, _prop.var.etc.warningImageWidth, 1, ix, b.y, ca.width - ix, itmH);
					auto bounds = _prop.images.warning.getBounds();
					int wx = .max(b.x + b.width, ca.width - bounds.width - 1);
					if (wx < ca.width) { mixin(S_TRACE);
						e.gc.drawImage(_prop.images.warning, wx, b.y + (itmH - bounds.height) / 2);
					}
					auto rect = new Rectangle(ix, b.y, _prop.var.etc.warningImageWidth, b.height);
					_warningRects ~= Warning(rect, warnings);
				}
			}
		}
		updateToolTip();
		foreach (i, lines; texts) { mixin(S_TRACE);
			auto b = bs[i];
			int bx = b.x;
			int by = b.y;
			int bw = b.width;
			int bh = b.height;
			int tx = b.x + MARGIN_L;
			int ty = b.y + MARGIN_T;

			setAlpha(128);
			e.gc.fillRectangle(bx, by, bw, bh);
			setAlpha(alpha);

			// FIXME: 場合によって改行が反映されない
//			e.gc.wDrawText(cm, tx, ty, true);
			foreach (line; lines) { mixin(S_TRACE);
				e.gc.wDrawText(line, tx, ty, true);
				ty += lineHeight;
			}
			// FIXME: 一度でもsetAlpha()を呼び出すと描画されなくなる
			e.gc.setBackground(lineColor);
			scope (exit) e.gc.setBackground(back);
//			e.gc.drawRectangle(bx, by, bw, bh);
//			e.gc.drawLine(px, py, px + dis - MARGIN_L - 2, py);
			e.gc.fillRectangle(bx, by, bw, 1);
			e.gc.fillRectangle(bx, by + bh - 1, bw, 1);
			e.gc.fillRectangle(bx, by + 1, 1, bh - 2);
			e.gc.fillRectangle(bx + bw - 1, by + 1, 1, bh - 2);
		}
	}
	class PaintTree : PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			auto d = _tree.control.getDisplay();
			auto fore = e.gc.getForeground();
			auto back = e.gc.getBackground();
			auto lineColor = new Color(d, alphaColor(fore.getRGB(), back.getRGB(), 64));
			scope (exit) lineColor.dispose();

			drawStartInfo(e, lineColor, _grayFont);
			drawComment(e, lineColor);
		}
	}
	private void selContentTool(bool arrowMode, CType cType, MenuID putMode, bool autoOpen, bool insertFirst) {
		Cursor cursor = null;
		if (!arrowMode) {
			cursor = _conts[cType].cursor;
		}
		_comp.setCursor(cursor);
		_arrowMode = arrowMode;
		_cType = cType;
	}
	private void refreshTemplates() { mixin(S_TRACE);
		if (!_evTemplM) return;
		ContentsToolBox.refreshTemplates(_comm, _prop, _summ, _evTemplM, widget.getShell(), () => _et !is null, &pasteScript);
	}
public:
	this (Commons comm, Props prop, Summary summ, CWXPath area, Composite parent, UndoManager undo,
			void delegate(size_t[]) forceSel,
			void delegate() refreshTopStart,
			Composite contentsBoxArea, bool readOnly) { mixin(S_TRACE);
		auto o = this;
		_id = format("%08X", &o) ~ "-" ~ to!(string)(Clock.currTime());

		_comm = comm;
		_prop = prop;
		_summ = summ;
		_area = area;
		_undo = undo;
		_readOnly = (readOnly || !_summ) ? SWT.READ_ONLY : SWT.NONE;
		if (_readOnly || !_summ || _summ.scenarioPath == "") { mixin(S_TRACE);
			_summSkin = findSkin(_comm, _prop, _summ);
		}
		_forceSel = forceSel;
		_refreshTopStart = refreshTopStart;
		_contentsBoxArea = contentsBoxArea;

		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout(zeroGridLayout(1, false));

		_comp.addDisposeListener(new TRDListener);
		_showEventTreeDetail = _prop.var.etc.showEventTreeDetail;
		_showLineNumber = _prop.var.etc.showEventTreeLineNumber;

		if (!_readOnly) { mixin(S_TRACE);
			_cbarPar = new Composite(_comp, SWT.NONE);

			_comm.refSkin.add(&refSkin);
			_comm.refDataVersion.add(&refDataVersion);
			_comm.refCast.add(&refreshCast);
			_comm.delCast.add(&refreshCast);
			_comm.refSkill.add(&refreshSkill);
			_comm.delSkill.add(&delSkill);
			_comm.refItem.add(&refreshItem);
			_comm.delItem.add(&delItem);
			_comm.refBeast.add(&refreshBeast);
			_comm.delBeast.add(&delBeast);
			_comm.refInfo.add(&refreshInfo);
			_comm.delInfo.add(&refreshInfo);
			_comm.refArea.add(&refreshArea);
			_comm.delArea.add(&refreshArea);
			_comm.refBattle.add(&refreshBattle);
			_comm.delBattle.add(&refreshBattle);
			_comm.refPackage.add(&refreshPackage);
			_comm.delPackage.add(&refreshPackage);
			_comm.refFlagAndStep.add(&refreshFlagAndStep);
			_comm.delFlagAndStep.add(&refreshFlagAndStep);
			_comm.refPath.add(&refreshPath);
			_comm.refPaths.add(&refreshPaths);
			_comm.delPaths.add(&deletePaths);
			_comm.replPath.add(&replacePaths);
			_comm.replText.add(&refreshCard);
			_comm.replText.add(&refreshEventText);
			_comm.replID.add(&refreshCard);
			_comm.refContentText.add(&refreshEventText);
			_comm.refPreviewValues.add(&refreshEventText);
			_comm.selContentTool.add(&selContentTool);
			_comm.refEventTemplates.add(&refreshTemplates);
		}
		_comm.refTargetVersion.add(&redraw);
		if (_summ) { mixin(S_TRACE);
			_comm.refEventTreeViewStyle.add(&refEventTreeViewStyle);
		}

		foreach (cGrp; EnumMembers!CTypeGroup) { mixin(S_TRACE);
			auto cs = CTYPE_GROUP[cGrp];
			foreach (cType; cs) { mixin(S_TRACE);
				_conts[cType] = new Converter(cType);
			}
		}
		refEventTreeViewStyle();
	}
	private void refEventTreeViewStyle() { mixin(S_TRACE);
		_comp.setRedraw(false);
		scope (exit) _comp.setRedraw(true);
		auto sel = selection;
		size_t[] ctPath = sel ? (cast(Content)sel.getData()).ctPath : [];
		auto et = _et;
		refresh(null);
		if (_tree.tree) { mixin(S_TRACE);
			_tree.tree.dispose();
			_tree.tree = null;
		}
		if (_tree.editor) { mixin(S_TRACE);
			_tree.editor.dispose();
			_tree.editor = null;
		}
		if ((_summ ? _prop.var.etc.straightEventTreeView : straightEventTreeView)) { mixin(S_TRACE);
			_tree.editor = new EventEditor(_comm, _comp, SWT.BORDER | _readOnly, _summ, null);
			_tree.editor.showEventTreeDetail = _showEventTreeDetail;
			_tree.editor.showLineNumber = _showLineNumber;
			_tree.editor.slope = _prop.var.etc.eventTreeSlope;
			_ee = new EventEdit(_comm, _tree.editor, &editEnd, &createEditor);
		} else { mixin(S_TRACE);
			_tree.tree = new Tree(_comp, SWT.SINGLE | SWT.BORDER);
			initTree(_comm, _tree.tree, true, true, () => _summ ? _prop.var.etc.classicStyleTree.value : classicStyleTree);
			if (!_readOnly) { mixin(S_TRACE);
				_te = new TreeEdit(_comm, _tree.tree, &editEnd, &createEditor);
			}
			_tree.tree.addPaintListener(new PaintTree);
			if (!_grayFont) { mixin(S_TRACE);
				_grayFont = new Color(_tree.control.getDisplay(), alphaColor(_tree.tree.getForeground().getRGB(), _tree.tree.getBackground().getRGB(), 128));
			}
		}
		_tree.control.setLayoutData(new GridData(GridData.FILL_BOTH));
		_tree.control.addMouseListener(new CreateL);
		auto mml = new MouseMove;
		_tree.control.addMouseMoveListener(mml);
		_tree.control.addMouseTrackListener(mml);
		auto editl = new EditL;
		_tree.control.addKeyListener(editl);
		_tree.control.addMouseListener(editl);
		_tree.addTreeListener(new TListener);
		_tree.addSelectionListener(new SListener);
		.listener(_tree.control, SWT.KeyUp, { mixin(S_TRACE);
			_comm.refreshToolBar();
		});

		void initMenu() { mixin(S_TRACE);
			auto shell = _tree.control.getShell();
			auto popup = new Menu(shell, SWT.POP_UP);
			if (!_readOnly) { mixin (S_TRACE);
				createMenuItem(_comm, popup, MenuID.EditProp, &editM, &canEdit);
				new MenuItem(popup, SWT.SEPARATOR);
				createMenuItem(_comm, popup, MenuID.Comment, &writeComment, &canWriteComment);
				new MenuItem(popup, SWT.SEPARATOR);
				createMenuItem(_comm, popup, MenuID.Undo, &this.undo, () => !_readOnly && _undo.canUndo);
				createMenuItem(_comm, popup, MenuID.Redo, &this.redo, () => !_readOnly && _undo.canRedo);
				new MenuItem(popup, SWT.SEPARATOR);
				appendMenuTCPD(_comm, popup, this, true, true, true, true, true);
				new MenuItem(popup, SWT.SEPARATOR);
				createMenuItem(_comm, popup, MenuID.Cut1Content, &cut1Content, &canCut1Content);
			} else {
				appendMenuTCPD(_comm, popup, this, false, true, false, false, false);
				new MenuItem(popup, SWT.SEPARATOR);
			}
			createMenuItem(_comm, popup, MenuID.Copy1Content, &copy1Content, &canCopy1Content);
			if (!_readOnly) { mixin (S_TRACE);
				createMenuItem(_comm, popup, MenuID.Delete1Content, &del1Content, &canDel1Content);
				new MenuItem(popup, SWT.SEPARATOR);
				createMenuItem(_comm, popup, MenuID.PasteInsert, &pasteInsert, &canPasteInsert);
				new MenuItem(popup, SWT.SEPARATOR);
				createMenuItem(_comm, popup, MenuID.SwapToParent, &swapToParent, &canSwapToParent);
				createMenuItem(_comm, popup, MenuID.SwapToChild, &swapToChild, &canSwapToChild);
			}
			new MenuItem(popup, SWT.SEPARATOR);
			createMenuItem(_comm, popup, MenuID.Expand, &expand, &canExpand);
			createMenuItem(_comm, popup, MenuID.Collapse, &collapse, &canCollapse);
			new MenuItem(popup, SWT.SEPARATOR);
			createMenuItem(_comm, popup, MenuID.ToScript, &toScript, &canToScript);
			createMenuItem(_comm, popup, MenuID.ToScript1Content, &toScript1Content, &canToScript);
			createMenuItem(_comm, popup, MenuID.ToScriptAll, &toScriptAll, &canToScriptAll);
			if (!_readOnly) { mixin (S_TRACE);
				new MenuItem(popup, SWT.SEPARATOR);
				createMenuItem(_comm, popup, MenuID.StartToPackage, &startToPackage, &canStartToPackage);
				createMenuItem(_comm, popup, MenuID.WrapTree, &wrapTree, &canWrapTree);
				new MenuItem(popup, SWT.SEPARATOR);
				createMenuItem(_comm, popup, MenuID.SelectConnectedResource, &selectConnectedResource, &canSelectConnectedResource);
				new MenuItem(popup, SWT.SEPARATOR);
				createMenuItem(_comm, popup, MenuID.FindID, &findStartUsers, &canFindStartUsers);
				new MenuItem(popup, SWT.SEPARATOR);
				void delegate() dlg = null;
				auto createMI = createMenuItem(_comm, popup, MenuID.CreateContent, dlg, () => _et !is null, SWT.CASCADE);
				_createM = new Menu(_tree.control.getShell(), SWT.DROP_DOWN);
				createMI.setMenu(_createM);
				auto convMI = createMenuItem(_comm, popup, MenuID.ConvertContent, dlg, { mixin(S_TRACE);
					if (_readOnly) return false;
					auto itm = selection;
					if (!itm) return false;
					auto evt = cast(Content) itm.getData();
					return evt.type !is CType.START;
				}, SWT.CASCADE);
				_convM = new Menu(_tree.control.getShell(), SWT.DROP_DOWN);
				convMI.setMenu(_convM);
				new MenuItem(popup, SWT.SEPARATOR);
				auto evTemplMI = createMenuItem(_comm, popup, MenuID.EvTemplates, dlg, () => _summ && _et && (_prop.var.etc.eventTemplates.length || _summ.eventTemplates.length), SWT.CASCADE);
				_evTemplM = new Menu(_tree.control.getShell(), SWT.DROP_DOWN);
				evTemplMI.setMenu(_evTemplM);

				// initConvMenu()の処理に時間がかかるため遅延実行
				auto shown = new class MenuAdapter {
					override void menuShown(MenuEvent e) { mixin(S_TRACE);
						initConvMenu();
						_createM.removeMenuListener(this);
						_convM.removeMenuListener(this);
					}
				};
				_createM.addMenuListener(shown);
				_convM.addMenuListener(shown);
				.listener(_convM, SWT.Show, &refreshConvMenu);

				refreshTemplates();
			}
/+			debug {
				new MenuItem(popup, SWT.SEPARATOR);
				createMenuItem2(_comm, popup, "debug: Create CWX &Path", null, &createCWXPath, () => selection !is null);
			}
+/
			_tree.control.setMenu(popup);
		}
		if (_summ) { mixin(S_TRACE);
			auto im = new class PaintListener {
				override void paintControl(PaintEvent e) { mixin(S_TRACE);
					_tree.control.removePaintListener(this);
					initMenu();
				}
			};
			_tree.control.addPaintListener(im);
		}

		if (!_readOnly) { mixin(S_TRACE);
			auto dt = new DropTarget(_tree.control, DND.DROP_DEFAULT | DND.DROP_MOVE);
			dt.setTransfer([XMLBytesTransfer.getInstance()]);
			dt.addDropListener(new EventDropTarget);
		}
		auto ds = new DragSource(_tree.control, DND.DROP_MOVE);
		ds.setTransfer([XMLBytesTransfer.getInstance()]);
		ds.addDragListener(new EventDragSource);

		if (!_readOnly) { mixin(S_TRACE);
			.listener(widget, SWT.Paint, { mixin(S_TRACE);
				if (!(_prop.var.etc.contentsFloat || _prop.var.etc.contentsAutoHide)) getContentsBox();
			});
		}
		_comp.layout();
		refresh(et);
		if (ctPath.length) { mixin(S_TRACE);
			sel = fromPath(ctPath);
			_tree.setSelection([sel]);
			_tree.showSelection();
		}
	}
	private Composite _cbarPar = null;

	@property
	Composite widget() { return _comp; }

	@property
	ContentsToolBox contentsToolBox() { return _box; }

	@property
	private Composite boxOwner() { return _cbarPar; }

	@property
	const
	bool readOnly() { return _readOnly != 0; }

	@property
	string statusLine() { return _statusLine; }

	void undo() { mixin(S_TRACE);
		if (_readOnly) return;
		foreach (v; views()) v.editCancel();
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() { mixin(S_TRACE);
		if (_readOnly) return;
		foreach (v; views()) v.editCancel();
		_undo.redo();
		_comm.refreshToolBar();
	}
	debug {
		void createCWXPath() { mixin(S_TRACE);
			auto itm = selection;
			if (itm) { mixin(S_TRACE);
				auto c = cast(Content) itm.getData();
				_comm.clipboard.setContents([new ArrayWrapperString(c.cwxPath(true))], [TextTransfer.getInstance()]);
				_comm.refreshToolBar();
			}
		}
	}
	@property
	bool canToScript() { mixin(S_TRACE);
		return selection !is null;
	}
	@property
	bool canToScriptAll() { mixin(S_TRACE);
		return _et !is null;
	}
	void toScript() { mixin(S_TRACE);
		auto itm = selection;
		if (!itm) return;
		foreach (v; views()) v.editEnter();
		auto c = cast(Content) itm.getData();
		auto script = new CWXScript(_prop.parent, _summ);
		auto text = script.toScript([c], summSkin.evtChildOK, _summ ? _summ.legacy : false, "\t");
		text = .replace(text ~ "\n", "\n", .newline);
		_comm.clipboard.setContents([new ArrayWrapperString(text)], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}
	void toScriptAll() { mixin(S_TRACE);
		if (!_et) return;
		foreach (v; views()) v.editEnter();
		auto script = new CWXScript(_prop.parent, _summ);
		auto text = script.toScript(_et.starts, summSkin.evtChildOK, _summ ? _summ.legacy : false, "\t");
		text = .replace(text ~ "\n", "\n", .newline);
		_comm.clipboard.setContents([new ArrayWrapperString(text)], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}
	void toScript1Content() { mixin(S_TRACE);
		auto itm = selection;
		if (!itm) return;
		foreach (v; views()) v.editEnter();
		auto c = cast(Content) itm.getData();
		auto script = new CWXScript(_prop.parent, _summ);
		auto c2 = new Content(c.type, c.name);
		c2.shallowCopy(c);
		auto text = script.toScript([c2], summSkin.evtChildOK, _summ ? _summ.legacy : false, "\t");
		text = .replace(text ~ "\n", "\n", .newline);
		_comm.clipboard.setContents([new ArrayWrapperString(text)], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}
	private ContentCommentDialog[string] _commentDlgs;
	@property
	bool canWriteComment() { mixin(S_TRACE);
		if (_readOnly) return false;
		return selection !is null;
	}
	void writeComment() { mixin(S_TRACE);
		if (_readOnly) return;
		auto itm = selection;
		if (!itm) return;
		foreach (v; views()) v.editEnter();
		.forceFocus(_tree.control, false);
		auto c = cast(Content)itm.getData();
		auto p = c.eventId in _commentDlgs;
		if (p) { mixin(S_TRACE);
			p.active();
			return;
		}
		auto dlg = new ContentCommentDialog(_comm, _prop, _tree.control.getShell(), c.parent, c);
		auto undo = new UndoContent(_comm, _prop, _summ, _et, _area, [c]);
		dlg.appliedEvent ~= { mixin(S_TRACE);
			_undo ~= undo;
			undo = new UndoContent(_comm, _prop, _summ, _et, _area, [c]);
			foreach (v; views()) { mixin(S_TRACE);
				if (v._tree.editor) { mixin(S_TRACE);
					v._tree.editor.updateContentInfo(c);
				} else { mixin(S_TRACE);
					v.redraw();
				}
			}
		};
		_commentDlgs[c.eventId] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_commentDlgs.remove(c.eventId);
		};
		dlg.open();
	}

	@property
	bool canStartToPackage() { mixin(S_TRACE);
		return !_readOnly && 1 <= _tree.getItemCount() && selection !is null;
	}
	void startToPackage() { mixin(S_TRACE);
		if (!canStartToPackage) return;
		if (!_et || !selection) return;
		if (_tree.getItemCount() < 1) return;
		auto sel = selection;
		if (!sel) return;
		foreach (v; views()) v.editEnter();
		auto base = cast(Content)selection.getData();
		auto startItm = _tree.topItem(sel);
		auto start = base.parentStart;
		assert (start);
		assert (start is startItm.getData(), start.name ~ " : " ~ startItm.getText());
		int index = _tree.indexOf(startItm);
		Item[] users;
		Content[] conts = [start];
		void find(Item itm) { mixin(S_TRACE);
			if (itm == startItm) return;
			while (true) { mixin(S_TRACE);
				auto c = cast(Content)itm.getData();
				if (c.detail.use(CArg.START) && c.start == start.name) { mixin(S_TRACE);
					users ~= itm;
					conts ~= c;
				}
				auto itms = _tree.getItems(itm);
				if (itms.length == 1) { mixin(S_TRACE);
					itm = itms[0];
				} else { mixin(S_TRACE);
					foreach (cld; itms) find(cld);
					break;
				}
			}
		}
		foreach (i; 0 .. _tree.getItemCount()) { mixin(S_TRACE);
			find(_tree.getItem(i));
		}
		auto isTopStart = start is _et.starts[0];
		auto ucp = new UndoCP(_comm, _prop, _summ, _et, _area, conts, index, isTopStart ? null : start);
		auto id = _comm.createPackage(start, start.name, false);
		if (id == 0) { mixin(S_TRACE);
			ucp.dispose();
			return;
		}
		_undo ~= ucp;
		if (isTopStart) { mixin(S_TRACE);
			foreach_reverse (child; _tree.getItems(startItm)) { mixin(S_TRACE);
				delImpl(child, start, false, false, true);
			}
			auto evt = new Content(CType.LINK_PACKAGE, "");
			start.add(_prop.parent, evt);
			evt.packages = id;
			auto img = _prop.images.content(CType.LINK_PACKAGE);
			foreach (v; views()) { mixin(S_TRACE);
				Item evtItm;
				if (v._tree.tree) { mixin(S_TRACE);
					assert (cast(TreeItem)startItm !is null);
					auto ti = .anotherTreeItem(v._tree.tree, cast(TreeItem)startItm);
					evtItm = createTreeItem(ti, evt, v.eventText(start, evt), img);
				} else { mixin(S_TRACE);
					v._tree.editor.updatePosOne(evt);
					evtItm = EventEditorItem.valueOf(v._tree.editor, evt);
				}
				if (v is this) v._tree.select(evtItm);
				if (v is this) v._tree.showSelection();
			}
		} else { mixin(S_TRACE);
			delImpl(startItm, start, false, false, true);
		}
		auto vs = views();
		foreach (itm; users) { mixin(S_TRACE);
			auto c = cast(Content)itm.getData();
			switch (c.type) {
			case CType.LINK_START: { mixin(S_TRACE);
				_comm.delContent.call(c);
				c.convertType(CType.LINK_PACKAGE, null, _prop.parent, .toDialogStatus(_prop.var.etc.dialogStatus));
				c.packages = id;
			} break;
			case CType.CALL_START: { mixin(S_TRACE);
				_comm.delContent.call(c);
				c.convertType(CType.CALL_PACKAGE, null, _prop.parent, .toDialogStatus(_prop.var.etc.dialogStatus));
				c.packages = id;
			} break;
			default: assert (0, .text(c.type));
			}
			foreach (v; vs) { mixin(S_TRACE);
				if (v._tree.tree) { mixin(S_TRACE);
					.anotherTreeItem(v._tree.tree, cast(TreeItem)itm).setImage(_prop.images.content(c.type));
				}
			}
		}
		foreach (v; vs) { mixin(S_TRACE);
			v.refreshStatusLine();
		}
		_comm.refUseCount.call();
		_comm.refreshToolBar();
	}

	@property
	bool canFindStartUsers() { mixin(S_TRACE);
		return !_readOnly && selection && cast(Content)selection.getData() && (cast(Content)selection.getData()).type is CType.START;
	}
	void findStartUsers() { mixin(S_TRACE);
		if (!selection) return;
		auto start = cast(Content)selection.getData();
		if (!start) return;
		if (start.type !is CType.START) return;
		auto replWin = _comm.mainWin.openReplWin();
		CWXPath[] arr;
		foreach (s; start.tree.startUseCounter.values(start.name)) { mixin(S_TRACE);
			arr ~= cast(Content)s;
		}
		replWin.setFindResult(.cwxPlace(_et), arr, _prop.msgs.replStartUsers);
	}
	@property
	bool canSelectConnectedResource() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!selection) return false;
		auto c = cast(Content)selection.getData();
		if (!c) return false;
		return c.connectedResource(_summ) || _summ.hasMaterial(c.connectedFile, _prop.var.etc.ignorePaths)
			|| c.connectedCoupons.length || c.connectedGossips.length
			|| c.connectedCompleteStamps.length
			|| c.connectedKeyCodes.length || c.connectedCellNames.length;
	}
	void selectConnectedResource() { mixin(S_TRACE);
		if (_readOnly) return;
		if (!selection) return;
		auto c = cast(Content)selection.getData();
		if (!c) return;
		if (auto path = c.connectedResource(_summ)) { mixin(S_TRACE);
			_comm.openCWXPath(cpaddattr(cpaddattr(path.cwxPath(true), "shallow"), "only"), false);
			return;
		}
		auto file = c.connectedFile;
		if (_summ.hasMaterial(file, _prop.var.etc.ignorePaths)) { mixin(S_TRACE);
			_comm.openFilePath(file, false, true);
			return;
		}
		_comm.selectIDName(c.connectedCoupons, false);
		_comm.selectIDName(c.connectedGossips, false);
		_comm.selectIDName(c.connectedCompleteStamps, false);
		_comm.selectIDName(c.connectedKeyCodes, false);
		_comm.selectIDName(c.connectedCellNames, false);
	}

	@property
	bool canWrapTree() { mixin(S_TRACE);
		return !_readOnly && selection && (cast(Content)selection.getData()).parent;
	}
	void wrapTree() { mixin(S_TRACE);
		if (!canWrapTree) return;
		foreach (v; views()) v.editEnter();
		auto sel = selection;
		assert (sel !is null);
		auto c = cast(Content)sel.getData();
		auto parentStart = c.parentStart;
		auto si = c.tree.starts.cCountUntil(parentStart) + 1;
		storeContentAndInsert(c.parent, cast(int)si, 1);

		auto start = new Content(CType.START, createNewName(parentStart.name, (string name) { mixin(S_TRACE);
			return !_et.hasStart(name);
		}, true, EventView.eventTreeNames(_prop, _et)));
		_et.insert(si, start);
		auto link = new Content(CType.LINK_START, c.name);
		link.start = start.name;
		c.parent.insert(_prop.parent, c.parent.next.cCountUntil(c), link);

		c.parent.remove(c);
		start.add(_prop.parent, c);
		_comm.delContent.call(c);

		foreach (v; views()) { mixin(S_TRACE);
			Item sItm;
			if (v._tree.tree) { mixin(S_TRACE);
				sItm = createTreeItem(v._tree.tree, start, start.name, _prop.images.content(CType.START), cast(int)si);
				v.createChilds(sItm, start);
			} else { mixin(S_TRACE);
				v._tree.editor.updatePosOne(parentStart);
				v._tree.editor.updatePosOne(start);
				sItm = EventEditorItem.valueOf(v._tree.editor, start);
			}
			if (v is this) { mixin(S_TRACE);
				v._tree.select(sItm);
				v._tree.showSelection();
			}
			v.refreshStatusLine();
		}
		_comm.refContent.call(c);
		_comm.refContent.call(link);
		_comm.refUseCount.call();
		_comm.refreshToolBar();
	}

	void refresh(EventTree et) { mixin(S_TRACE);
		editCancel();
		_comm.setStatusLine(_tree.control, "");
		_statusLine = "";
		if (_et !is et) { mixin(S_TRACE);
			if (_et) { mixin(S_TRACE);
				foreach (v; views()) v.editEnter();
			}
			foreach (dlg; _editDlgs.values) { mixin(S_TRACE);
				dlg.forceCancel();
			}
			foreach (dlg; _commentDlgs.values) { mixin(S_TRACE);
				dlg.forceCancel();
			}
			_et = et;
			_tree.control.setRedraw(false);
			scope (exit) _tree.control.setRedraw(true);
			if (_tree.tree) { mixin(S_TRACE);
				_tree.tree.removeAll();
				if (et) { mixin(S_TRACE);
					foreach (start; et.starts) { mixin(S_TRACE);
						auto itm = createTreeItem(_tree.tree, start, start.name, _prop.images.content(CType.START));
						createChilds(itm, start);
						_tree.setExpanded(itm, true);
					}
				}
			} else { mixin(S_TRACE);
				_tree.editor.eventTree = _et;
			}
			if (0 < _tree.getItemCount()) { mixin(S_TRACE);
				_tree.setSelection([_tree.getItem(0)]);
				_tree.showSelection();
			}
			if (et) { mixin(S_TRACE);
				openToolWindow(true);
			} else { mixin(S_TRACE);
				closeToolWindow();
			}
			refreshStatusLine();
			_comm.refreshToolBar();
		}
	}
	void treeOpen() { mixin(S_TRACE);
		_tree.treeExpandedAll();
		_comm.refreshToolBar();
	}
	void treeClose() { mixin(S_TRACE);
		if (_tree.editor) { mixin(S_TRACE);
			_tree.editor.foldAll();
		} else {
			_tree.control.setRedraw(false);
			scope (exit) _tree.control.setRedraw(true);
			foreach (itm; _tree.getItems()) { mixin(S_TRACE);
				_tree.setExpanded(itm, false);
			}
		}
		_comm.refreshToolBar();
	}
	@property
	bool canExpandTree() { mixin(S_TRACE);
		if (_tree.editor) return _tree.editor.canAllExpand;
		foreach (itm; _tree.getItems()) { mixin(S_TRACE);
			if (_tree.getItems(itm).length && !_tree.getExpanded(itm)) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	}
	@property
	bool canFoldTree() { mixin(S_TRACE);
		if (_tree.editor) return _tree.editor.canAllFoldStart;
		foreach (itm; _tree.getItems()) { mixin(S_TRACE);
			if (_tree.getItems(itm).length && _tree.getExpanded(itm)) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	}
	@property
	bool canExpand() { mixin(S_TRACE);
		auto itm = selection;
		if (!itm) return false;
		auto c = cast(Content)itm.getData();
		return c.next.length && !_tree.getExpanded(itm);
	}
	@property
	bool canCollapse() { mixin(S_TRACE);
		auto itm = selection;
		if (!itm) return false;
		auto c = cast(Content)itm.getData();
		return c.next.length && _tree.getExpanded(itm);
	}
	void expand() { mixin(S_TRACE);
		if (!canExpand) return;
		auto itm = selection;
		if (!itm) return;
		_tree.setExpanded(itm, true);
		_comm.refreshToolBar();
	}
	void collapse() { mixin(S_TRACE);
		if (!canCollapse) return;
		auto itm = selection;
		if (!itm) return;
		_tree.setExpanded(itm, false);
		_comm.refreshToolBar();
	}
	private void editEnd(TreeItem itm, Control c) { mixin(S_TRACE);
		editEnd(cast(Item)itm, c);
	}
	private void editEnd(EventEditorItem itm, Control c) { mixin(S_TRACE);
		editEnd(cast(Item)itm, c);
	}
	private void editEnd(Item itm, Control c) { mixin(S_TRACE);
		if (_readOnly) return;
		if (_ee) _ee.minimumWidth = SWT.DEFAULT;
		auto t = cast(Text)c;
		auto evt = (cast(Content)itm.getData());
		auto vs = views();
		if (t) { mixin(S_TRACE);
			auto text = t.getText();
			if (!text) text = "";
			if (text == evt.name) return;
			store(evt);
			if (evt.type == CType.START) { mixin(S_TRACE);
				evt.setName(_prop.parent, createNewName(text, (string name) { mixin(S_TRACE);
					auto s = _et.start(name);
					return !(s && s !is evt);
				}, true, EventView.eventTreeNames(_prop, _et)));
				text = evt.name;
			} else { mixin(S_TRACE);
				evt.setName(_prop.parent, text);
				text = eventText(evt.parent, evt);
			}
			auto isTop = evt.type == CType.START && _tree.indexOf(itm) == 0;
			foreach (v; vs) { mixin(S_TRACE);
				if (v._tree.tree) {
					assert (cast(TreeItem)itm !is null);
					.anotherTreeItem(v._tree.tree, cast(TreeItem)itm).setText(text);
				} else {
					v._tree.editor.updateContentInfo(evt);
				}
				if (isTop) { mixin(S_TRACE);
					v._refreshTopStart();
				}
				v._refreshTopStart();
			}
		} else { mixin(S_TRACE);
			auto combo = cast(Combo)c;
			int index = combo.getSelectionIndex();
			auto data = cast(Content)_tree.getParentItem(itm).getData();
			string name;
			switch (data.type) {
			case CType.TALK_MESSAGE:
			case CType.TALK_DIALOG:
				name = combo.getText();
				break;
			case CType.BRANCH_MULTI_STEP: { mixin(S_TRACE);
				if (index + 1 < combo.getItemCount()) { mixin(S_TRACE);
					name = to!(string)(index);
				} else { mixin(S_TRACE);
					assert (index + 1 == combo.getItemCount());
					name = _prop.sys.evtChildDefault;
				}
				break;
			} case CType.BRANCH_AREA: { mixin(S_TRACE);
				if (index < _summ.areas.length) { mixin(S_TRACE);
					name = to!(string)(_summ.areas[index].id);
				} else { mixin(S_TRACE);
					assert (index == _summ.areas.length);
					name = _prop.sys.evtChildDefault;
				}
				break;
			} case CType.BRANCH_BATTLE: { mixin(S_TRACE);
				if (index < _summ.battles.length) { mixin(S_TRACE);
					name = to!(string)(_summ.battles[index].id);
				} else { mixin(S_TRACE);
					assert (index == _summ.battles.length);
					name = _prop.sys.evtChildDefault;
				}
				break;
			} case CType.BRANCH_STEP_CMP: { mixin(S_TRACE);
				switch (combo.getSelectionIndex()) {
				case 0:
					name = _prop.sys.evtChildGreater;
					break;
				case 1:
					name = _prop.sys.evtChildLesser;
					break;
				case 2:
					name = _prop.sys.evtChildEq;
					break;
				default:
					assert (0);
				}
				break;
			} case CType.BRANCH_MULTI_COUPON: { mixin(S_TRACE);
				name = combo.getText();
				break;
			} default:
				assert (combo.getItemCount() == 2);
				name = index == 0 ? _prop.sys.evtChildTrue : _prop.sys.evtChildFalse;
			}
			if (name == evt.name) return;
			store(evt);
			evt.setName(_prop.parent, name);
			foreach (v; vs) { mixin(S_TRACE);
				if (v._tree.tree) {
					assert (cast(TreeItem)itm !is null);
					.anotherTreeItem(v._tree.tree, cast(TreeItem)itm).setText(combo.getText());
				} else {
					v._tree.editor.updateContentInfo(evt);
				}
			}
		}
		foreach (v; vs) { mixin(S_TRACE);
			if (v._tree.tree) {
				assert (cast(TreeItem)itm !is null);
				v.procTreeItem(.anotherTreeItem(v._tree.tree, cast(TreeItem)itm));
			}
			v.redraw();
			v.refreshStatusLine();
		}
		_comm.refContent.call(evt);
		_comm.refreshToolBar();
		_comm.refUseCount.call();
	}
	private Combo createBoolEditor(string Create)(Content evt, Content child) { mixin(S_TRACE);
		if (_readOnly) return null;
		string[] vals;
		vals.length = 2;
		string name = _prop.sys.evtChildTrue;
		vals[0] = mixin (Create);
		name = _prop.sys.evtChildFalse;
		vals[1] = mixin (Create);
		return createComboEditor(_comm, _prop, _tree.control, vals, vals[child.name == _prop.sys.evtChildTrue ? 0 : 1]);
	}
	private Combo createBoolEditor2(string Create)(Content evt, Content child) { mixin(S_TRACE);
		if (_readOnly) return null;
		string[] vals;
		vals.length = 2;
		string name = _prop.sys.evtChildTrue;
		vals[0] = mixin (Create);
		name = _prop.sys.evtChildFalse;
		vals[1] = mixin (Create);
		return createComboEditor(_comm, _prop, _tree.control, vals, vals[child.name == _prop.sys.evtChildTrue ? 0 : 1]);
	}
	private Combo createNumEditor(string Create)(Content evt, Content child, ulong[] nums) { mixin(S_TRACE);
		if (_readOnly) return null;
		string[] vals;
		vals.length = nums.length + 1;
		size_t index = nums.length;
		foreach (i, n; nums) { mixin(S_TRACE);
			string name = to!(string)(n);
			vals[i] = mixin (Create);
			if (name == child.name) { mixin(S_TRACE);
				index = i;
			}
		}
		string name = _prop.sys.evtChildDefault;
		vals[$ - 1] = mixin (Create);
		return createComboEditor(_comm, _prop, _tree.control, vals, vals[index]);
	}
	private Combo createAreaSelectEditor(string Create, A)(Content evt, Content child, A[] areas) { mixin(S_TRACE);
		if (_readOnly) return null;
		ulong[] nums;
		nums.length = areas.length;
		foreach (i, area; areas) { mixin(S_TRACE);
			nums[i] = area.id;
		}
		return createNumEditor!(Create)(evt, child, nums);
	}
	private Combo createTrioEditor(string Create)(Content evt, Content child) { mixin(S_TRACE);
		if (_readOnly) return null;
		string[] vals;
		vals.length = 3;
		string name = _prop.sys.evtChildGreater;
		vals[0] = mixin (Create);
		name = _prop.sys.evtChildLesser;
		vals[1] = mixin (Create);
		name = _prop.sys.evtChildEq;
		vals[2] = mixin (Create);
		size_t index;
		if (child.name == _prop.sys.evtChildEq) { mixin(S_TRACE);
			index = 2;
		} else if (child.name == _prop.sys.evtChildLesser) { mixin(S_TRACE);
			index = 1;
		} else { mixin(S_TRACE);
			index = 0;
		}
		return createComboEditor(_comm, _prop, _tree.control, vals, vals[index]);
	}
	private Combo createCouponEditor(string coupon) { mixin(S_TRACE);
		if (_readOnly) return null;
		if (_ee) _ee.minimumWidth = _prop.var.etc.couponWidth;
		return createCouponCombo!Combo(_comm, _summ, _tree.control, null, CouponComboType.AllCoupons, coupon);
	}
	private Control createEditor(TreeItem itm) { mixin(S_TRACE);
		return createEditor(cast(Item)itm);
	}
	private Control createEditor(EventEditorItem itm) { mixin(S_TRACE);
		return createEditor(cast(Item)itm);
	}
	private Control createEditor(Item itm) { mixin(S_TRACE);
		if (_readOnly) return null;
		auto parent = _tree.getParentItem(itm);
		if (parent) { mixin(S_TRACE);
			if ((cast(Content)parent.getData()).detail.nextType == CNextType.TEXT) { mixin(S_TRACE);
				if (_prop.var.etc.editSelectionWithCombo) { mixin(S_TRACE);
					if (_ee) _ee.minimumWidth = _prop.var.etc.selectionWidth;
					return createSelectionCombo(_comm, _tree.control, null, (cast(Content)itm.getData()).name);
				} else { mixin(S_TRACE);
					return createTextEditor(_comm, _prop, _tree.control, (cast(Content)itm.getData()).name);
				}
			}
		} else { mixin(S_TRACE);
			assert ((cast(Content)itm.getData()).type is CType.START);
			return createTextEditor(_comm, _prop, _tree.control, (cast(Content)itm.getData()).name);
		}
		auto data = cast(Content)parent.getData();
		auto c = cast(Content)itm.getData();
		switch (data.type) {
		case CType.BRANCH_FLAG: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrFlag(_prop, _summ, evt.flag, name)")(data, c);
		} case CType.BRANCH_MULTI_STEP: { mixin(S_TRACE);
			Step step = _summ.flagDirRoot.findStep(data.step);
			ulong[] nums;
			ulong count = step is null ? _prop.looks.stepMaxCount : step.count;
			for (ulong i = 0; i < count; i++) { mixin(S_TRACE);
				nums ~= i;
			}
			return createNumEditor!("evtChildBrStepN(_prop, _summ, evt.step, name)")(data, c, nums);
		} case CType.BRANCH_STEP: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrStepUL(_prop, _summ, evt.step, evt.stepValue, name)")(data, c);
		} case CType.BRANCH_SELECT: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrMember(_prop, evt, name)")(data, c);
		} case CType.BRANCH_ABILITY: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrPower(_prop, evt.targetS, evt.physical, evt.mental, evt.signedLevel, name)")(data, c);
		} case CType.BRANCH_RANDOM: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrRandom(_prop, evt.percent, name)")(data, c);
		} case CType.BRANCH_LEVEL: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrLevel(_prop, evt.unsignedLevel, evt.average, name)")(data, c);
		} case CType.BRANCH_STATUS: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrState(_prop, evt.range, evt.holdingCoupon, evt.status, name)")(data, c);
		} case CType.BRANCH_PARTY_NUMBER: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrNum(_prop, evt.partyNumber, name)")(data, c);
		} case CType.BRANCH_AREA: { mixin(S_TRACE);
			return createAreaSelectEditor!("evtChildBrArea(_prop, _summ.areas, name)")(data, c, _summ.areas);
		} case CType.BRANCH_BATTLE: { mixin(S_TRACE);
			return createAreaSelectEditor!("evtChildBrBattle(_prop, _summ.battles, name)")(data, c, _summ.battles);
		} case CType.BRANCH_IS_BATTLE: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrOnBattle(_prop, name)")(data, c);
		} case CType.BRANCH_CAST: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrCast(_prop, _summ, evt.casts, name)")(data, c);
		} case CType.BRANCH_ITEM: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrItem(_prop, _summ, evt.item, evt.range, evt.cardNumber, name)")(data, c);
		} case CType.BRANCH_SKILL: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrSkill(_prop,  _summ, evt.skill, evt.range, evt.cardNumber, name)")(data, c);
		} case CType.BRANCH_BEAST: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrBeast(_prop, _summ, evt.beast, evt.range, evt.cardNumber, name)")(data, c);
		} case CType.BRANCH_INFO: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrInfo(_prop, _summ, evt.info, name)")(data, c);
		} case CType.BRANCH_MONEY: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrMoney(_prop, evt.money, name)")(data, c);
		} case CType.BRANCH_COUPON: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrCoupon(_prop, evt.range, evt.couponNames.dup, evt.matchingType, name)")(data, c);
		} case CType.BRANCH_COMPLETE_STAMP: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrEnd(_prop, evt.completeStamp, name)")(data, c);
		} case CType.BRANCH_GOSSIP: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrGossip(_prop, evt.gossip, name)")(data, c);
		} case CType.BRANCH_STEP_CMP: { mixin(S_TRACE);
			return createTrioEditor!("evtChildBrStepCmp(_prop, _summ, evt.step, evt.step2, name)")(data, c);
		} case CType.BRANCH_FLAG_CMP: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrFlagCmp(_prop, _summ, evt.flag, evt.flag2, name)")(data, c);
		} case CType.BRANCH_RANDOM_SELECT: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrRandomSelect(_prop, evt, name)")(data, c);
		} case CType.BRANCH_KEY_CODE: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrKeyCode(_prop, evt, name)")(data, c);
		} case CType.BRANCH_ROUND: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrRound(_prop, evt, name)")(data, c);
		} case CType.BRANCH_MULTI_COUPON: { mixin(S_TRACE);
			return createCouponEditor(c.name);
		} default:
		}
		return null;
	}
	/// Params:
	/// parent = 親イベント。
	/// e = イベント。名称が書き換えられる。
	/// Returns: テキスト。
	private string eventText(Content parent, Content e) { mixin(S_TRACE);
		return .eventText(_comm, _summ, parent, e, _readOnly != SWT.NONE);
	}
	/// 空のテキストは入力ガイドを代わりに表示。
	private void procTreeItem(Item targ) { mixin(S_TRACE);
		auto itm = cast(TreeItem)targ;
		if (!itm) return;
		auto c = cast(Content) itm.getData();
		assert (c !is null);
		if (c.parent && c.parent.detail.nextType == CNextType.TEXT) { mixin(S_TRACE);
			if (c.name.length) { mixin(S_TRACE);
				itm.setForeground(_tree.control.getForeground());
			} else { mixin(S_TRACE);
				itm.setForeground(_grayFont);
				if (_prop.var.etc.showInputGuide) { mixin(S_TRACE);
					itm.setText(summSkin.evtChildOK);
				} else { mixin(S_TRACE);
					itm.setText(" ");
				}
			}
		}
	}
	/// 末尾のアイテムを返す。
	private Item createChilds(Item parentItm, Content evt) { mixin(S_TRACE);
		if (!evt.detail.owner) return parentItm;
		if (auto parent = cast(TreeItem)parentItm) { mixin(S_TRACE);
			parent.removeAll();
			Item itm = parent;
			foreach (c; evt.next) { mixin(S_TRACE);
				auto itm2 = createTreeItem(parent, c, eventText(evt, c), _prop.images.content(c.type));
				itm = itm2;
				if (c.detail.owner) { mixin(S_TRACE);
					itm = createChilds(itm2, c);
				}
				procTreeItem(itm2);
				_tree.setExpanded(itm2, true);
			}
			return itm;
		} else { mixin(S_TRACE);
			_tree.editor.updatePosOne(evt);
			while (evt.next.length) { mixin(S_TRACE);
				evt = evt.next[$ - 1];
			}
			return EventEditorItem.valueOf(_tree.editor, evt);
		}
	}

	@property
	EventTree eventTree() { mixin(S_TRACE);
		return _et;
	}
	@property
	bool isFocusControl() { mixin(S_TRACE);
		return _tree.control.isFocusControl();
	}

	private static void udImpl(int To)(EventTreeView[] vs, Commons comm, EventTree et, Content c, bool store) { mixin(S_TRACE);
		if (!et) return;
		foreach (v; vs) v._tree.control.setRedraw(false);
		scope (exit) foreach (v; vs) v._tree.control.setRedraw(true);
		foreach (v; vs) v.editEnter();
		auto pc = c.parent;
		size_t i, j;
		auto path = c.ctPath;
		Content[] updateContents;
		if (pc) { mixin(S_TRACE);
			i = cCountUntil!("a is b")(pc.next, c);
			j = i + To;
			if (j < 0 || pc.next.length <= j) return;
			if (vs.length && store) { mixin(S_TRACE);
				vs[0].store(pc);
			}
			comm.delContent.call(pc.next[i]);
			comm.delContent.call(pc.next[j]);
			pc.swapContent(i, j);
			updateContents ~= pc;
		} else { mixin(S_TRACE);
			i = cCountUntil!("a is b")(et.starts, c);
			j = i + To;
			if (j < 0 || et.starts.length <= j) return;
			if (vs.length && store) { mixin(S_TRACE);
				vs[0].storeSwap(cast(int)i, cast(int)j);
			}
			comm.delContent.call(et.starts[i]);
			comm.delContent.call(et.starts[j]);
			updateContents ~= et.starts[i];
			updateContents ~= et.starts[j];
			et.swapStart(i, j);
		}
		foreach (v; vs) { mixin(S_TRACE);
			if (v._tree.tree) { mixin(S_TRACE);
				static if (To == -1) {
					treeItemUp(cast(TreeItem)v.fromPath(path));
				} else static if (To == 1) {
					treeItemDown(cast(TreeItem)v.fromPath(path));
				} else static assert (0);
			} else { mixin(S_TRACE);
				foreach (upc; updateContents) { mixin(S_TRACE);
					v._tree.editor.updatePosOne(upc);
				}
			}
			if (!pc && (i == 0 || j == 0)) { mixin(S_TRACE);
				v._refreshTopStart();
			}
		}
		auto mainV = mainEventTreeView(vs);
		if (mainV) mainV._tree.showSelection();
	}
	@property
	bool canUp() { mixin(S_TRACE);
		return canUpImpl(true);
	}
	@property
	bool canDown() { mixin(S_TRACE);
		return canDownImpl(true);
	}
	private bool canUpImpl(bool swapPC) { mixin(S_TRACE);
		if (_readOnly) return false;
		auto itm = selection;
		if (!itm) return false;
		auto par = _tree.getParentItem(itm);
		if (par) { mixin(S_TRACE);
			if (0 < _tree.indexOf(par, itm)) return true;
		} else { mixin(S_TRACE);
			if (0 < _tree.indexOf(itm)) return true;
		}
		if (!swapPC) return false;
		if (!_tree.editor) return false;
		// 垂直表示時は上下移動に加えて親子の入れ替えも試みる
		return canSwapToParent;
	}
	private bool canDownImpl(bool swapPC) { mixin(S_TRACE);
		if (_readOnly) return false;
		auto itm = selection;
		if (!itm) return false;
		auto par = _tree.getParentItem(itm);
		if (par) { mixin(S_TRACE);
			if (_tree.indexOf(par, itm) + 1 < _tree.getItemCount(par)) return true;
		} else { mixin(S_TRACE);
			if (_tree.indexOf(itm) + 1 < _tree.getItemCount()) return true;
		}
		if (!swapPC) return false;
		if (!_tree.editor) return false;
		// 垂直表示時は上下移動に加えて親子の入れ替えも試みる
		return canSwapToChild;
	}
	private void up(Item itm, bool store) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!itm) return;
		udImpl!(-1)([this], _comm, _et, cast(Content) itm.getData(), store);
		_comm.refreshToolBar();
	}
	void up() { mixin(S_TRACE);
		if (!canUpImpl(false)) { mixin(S_TRACE);
			if (canSwapToParent) { mixin(S_TRACE);
				swapToParent();
			}
			return;
		}
		auto itm = selection;
		if (itm) up(itm, true);
	}
	private void down(Item itm, bool store) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!itm) return;
		udImpl!(1)([this], _comm, _et, cast(Content) itm.getData(), store);
		_comm.refreshToolBar();
	}
	void down() { mixin(S_TRACE);
		if (!canDownImpl(false)) { mixin(S_TRACE);
			if (canSwapToChild) { mixin(S_TRACE);
				swapToChild();
			}
			return;
		}
		auto itm = selection;
		if (itm) down(itm, true);
	}

	void reverseShowEventTreeDetail() { mixin(S_TRACE);
		showEventTreeDetail = !_showEventTreeDetail;
	}
	@property
	void showEventTreeDetail(bool v) { mixin(S_TRACE);
		_showEventTreeDetail = v;
		if (_tree.editor) { mixin(S_TRACE);
			_tree.editor.showEventTreeDetail = v;
		}
		_prop.var.etc.showEventTreeDetail = _showEventTreeDetail;
	}

	void reverseShowLineNumber() { mixin(S_TRACE);
		showLineNumber = !_showLineNumber;
	}
	@property
	void showLineNumber(bool v) { mixin(S_TRACE);
		_showLineNumber = v;
		if (_tree.editor) { mixin(S_TRACE);
			_tree.editor.showLineNumber = v;
		}
		_prop.var.etc.showEventTreeLineNumber = _showLineNumber;
	}

	@property
	void eventTreeSlope(int value) { mixin(S_TRACE);
		if (_tree.editor) { mixin(S_TRACE);
			_tree.editor.slope = value;
		}
	}

	@property
	bool canSwapToParent() { mixin(S_TRACE);
		if (_readOnly) return false;
		auto itm = selection;
		if (!itm) return false;
		auto c = cast(Content)itm.getData();
		if (!c.parent) return false;
		if (c.parent.type == CType.START) return false;
		if (c.parent.next.length != 1) return false;
		if (!c.detail.owner) return false;
		return true;
	}
	@property
	bool canSwapToChild() { mixin(S_TRACE);
		if (_readOnly) return false;
		auto itm = selection;
		if (!itm) return false;
		auto c = cast(Content)itm.getData();
		if (c.type == CType.START) return false;
		if (c.next.length != 1) return false;
		if (!c.next[0].detail.owner) return false;
		return true;
	}
	/// イベントコンテントの親子を入れ替える。
	private void swapToPCImpl(Item parent, Item child, Item selTarg) { mixin(S_TRACE);
		if (_readOnly) return;
		auto par = cast(Content)parent.getData();
		auto next = cast(Content)child.getData();
		auto parPar = par.parent;
		auto parName = par.name;
		auto nextName = next.name;
		auto parNType = fromCNextType(par.detail.nextType);
		auto nextNType = fromCNextType(next.detail.nextType);
		auto parParNType = fromCNextType(parPar.detail.nextType);
		auto parIndex = parPar.next.cCountUntil!"a is b"(par);

		auto vs = views();
		foreach (v; vs) v.editEnter();
		store(parPar);

		// 入れ替え
		parPar.remove(par);
		par.remove(next);
		foreach (c; next.next.dup) { mixin(S_TRACE);
			next.remove(c);
			adjustText(par, c, nextNType);
			par.add(_prop.parent, c);
		}
		par.setName(_prop.parent, nextName);
		next.setName(_prop.parent, parName);
		adjustText(parPar, next, parParNType); // すでに名前を入れ替えているためlastNextTypeも入れ替わる
		parPar.insert(_prop.parent, parIndex, next);
		adjustText(next, par, parNType);
		next.add(_prop.parent, par);

		// 表示の更新
		foreach (v; vs) { mixin(S_TRACE);
			if (_tree.tree) { mixin(S_TRACE);
				assert (cast(TreeItem)parent !is null);
				auto parent2 = .anotherTreeItem(v._tree.tree, cast(TreeItem)parent);
				auto child2 = parent2.getItem(_tree.indexOf(parent, child));
				assert (parent2.getData() is parent.getData());
				assert (child2.getData() is child.getData());
				parent2.setText(v.eventText(parPar, next));
				child2.setText(v.eventText(next, par));
				parent2.setData(next);
				child2.setData(par);
				parent2.setImage(_prop.images.content(next.type));
				child2.setImage(_prop.images.content(par.type));
				v.procTreeItem(parent2);
				v.procTreeItem(child2);
				foreach (cc; v._tree.getItems(child2)) { mixin(S_TRACE);
					cc.setText(v.eventText(par, cast(Content)cc.getData()));
					v.procTreeItem(cc);
				}
				if (v is this) v._tree.setSelection([selTarg]);
			} else { mixin(S_TRACE);
				v._tree.editor.updatePosOne(parPar);
			}
		}
		_tree.showSelection();
	}
	void swapToParent() { mixin(S_TRACE);
		if (_readOnly) return;
		if (!canSwapToParent) return;
		auto itm = selection;
		auto par = _tree.getParentItem(itm);
		swapToPCImpl(par, itm, par);
	}
	void swapToChild() { mixin(S_TRACE);
		if (_readOnly) return;
		if (!canSwapToChild) return;
		auto par = selection;
		auto itm = _tree.getItem(par, 0);
		swapToPCImpl(par, itm, itm);
	}

	private void getContentsBox() { mixin(S_TRACE);
		if (_box) return;
		_comp.setRedraw(false);
		scope (exit) _comp.setRedraw(true);
		_comm.getContentsToolBox(this);
	}

	/// 所属するShellの変更を通知する。
	void moveShell() { mixin(S_TRACE);
		if (!_box) return;
		if (_box.isSingleton) { mixin(S_TRACE);
			if (!_comm.poolContentsToolBox(_box)) { mixin(S_TRACE);
				_box.dispose();
			}
			_box = _comm.getContentsToolBox(this);
			_box.openToolWindow();
		}
	}

	void refreshTreeName() { mixin(S_TRACE);
		if (!_tree.getItemCount()) return;
		if (_tree.tree) { mixin(S_TRACE);
			_tree.getItem(0).setText(_et.name);
		} else { mixin(S_TRACE);
			_tree.editor.updateContentInfo(_et.starts[0]);
		}
		redraw();
		refreshStatusLine();
	}

	void openToolWindow(bool focusInEventView) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!(_prop.var.etc.contentsFloat || _prop.var.etc.contentsAutoHide)) return;
		_comp.setRedraw(false);
		scope (exit) _comp.setRedraw(true);
		if (focusInEventView || (widget.isVisible() && !(_prop.var.etc.contentsFloat || _prop.var.etc.contentsAutoHide))) { mixin(S_TRACE);
			getContentsBox();
		}
		if (_box) { mixin(S_TRACE);
			_box.openToolWindow();
		}
	}
	void closeToolWindow() { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_box) return;
		_box.closeToolWindow();
	}

	@property
	private Content insertOwner(bool tryInsert, ref Item itm) { mixin(S_TRACE);
		if (!itm) return null;
		auto owner = cast(Content)itm.getData();
		assert (owner);
		if (tryInsert || owner.detail.owner) return owner;
		itm = _tree.getParentItem(itm);
		return owner.parent;
	}
	private void addContents(bool stored, Content[] cs, Content[] refCS, bool tryInsert, string lastNextType = "") { mixin(S_TRACE);
		if (!_box) return;
		if (_readOnly) return;
		auto itm = selection;
		if (!itm) return;
		auto owner = insertOwner(tryInsert, itm);
		if (!owner) return;
		bool empty = _et.owner.isEmpty;
		scope (exit) {
			if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
		}
		Content[] cs2;
		bool[string] cs2Table;
		foreach (ct; cs) { mixin(S_TRACE);
			if (ct.type is CType.START) continue;
			cs2 ~= ct;
			cs2Table[ct.eventId] = true;
		}
		if (!cs2.length) return;

		Content last = null, allLast = null;
		ptrdiff_t index = -1;
		if (tryInsert && owner.parent) { mixin(S_TRACE);
			// cs2内に子コンテントを持てるコンテントが
			// 含まれている場合は挿入する
			void recurse(Content c) { mixin(S_TRACE);
				if (c.detail.owner) { mixin(S_TRACE);
					last = c;
				}
				allLast = c;
				foreach (cc; c.next) { mixin(S_TRACE);
					recurse(cc);
				}
			}
			foreach (c; cs2) { mixin(S_TRACE);
				recurse(c);
			}
		}
		if (!last && !owner.detail.owner) return;

		auto vs = views();
		foreach (v; vs) v._tree.control.setRedraw(false);
		scope (exit) foreach (v; vs) v._tree.control.setRedraw(true);
		foreach (v; vs) v.editEnter();
		if (stored) store(owner);
		if (last) { mixin(S_TRACE);
			cs2[0].setName(_prop.parent, owner.name);
			auto parent = owner.parent;
			index = parent.next.countUntil(owner);
			parent.remove(owner);
			if (_prop.var.etc.adjustContentName) { mixin(S_TRACE);
				owner.setName(_prop.parent, "");
			}
			last.add(_prop.parent, owner);
			auto o = owner;
			owner = parent;
			while (o !is cs2[0]) { mixin(S_TRACE);
				// 分岐の直後に1つ以上のコンテントと終端が含まれており、
				// 最初の分岐の直後に挿入先のイベントが来る場合
				itm = _tree.getParentItem(itm);
				o = o.parent;
			}
			assert (!_tree.editor || cs2[0] is itm.getData());
		}
		bool insertFirst = (index == -1 && _box.isInsertFirst);
		Content lastCt = null;
		int i = 0;
		foreach (ct; cs2) { mixin(S_TRACE);
			if (index == -1) { mixin(S_TRACE);
				adjustText(owner, ct, lastNextType);
				if (insertFirst) { mixin(S_TRACE);
					owner.insert(_prop.parent, i, ct);
					lastCt = ct;
					i++;
				} else { mixin(S_TRACE);
					owner.add(_prop.parent, ct);
				}
			} else { mixin(S_TRACE);
				owner.insert(_prop.parent, index, ct);
				index = -1;
			}
			_comm.refContent.call(ct);
		}
		auto lastItm = createChilds(itm, owner);
		foreach (v; vs) { mixin(S_TRACE);
			if (v is this) continue;
			if (v._tree.tree) { mixin(S_TRACE);
				assert (cast(TreeItem)itm !is null);
				auto parItm = .anotherTreeItem(v._tree.tree, cast(TreeItem)itm);
				v.createChilds(parItm, owner);
				parItm.setExpanded(true);
			} else { mixin(S_TRACE);
				v._tree.editor.updatePosOne(owner);
			}
		}
		if (lastCt) { mixin(S_TRACE);
			while (lastCt.next.length) { mixin(S_TRACE);
				lastCt = lastCt.next[$ - 1];
			}
			Item find(Item itm) { mixin(S_TRACE);
				if (lastCt is itm.getData()) { mixin(S_TRACE);
					return itm;
				} else { mixin(S_TRACE);
					foreach (child; _tree.getItems(itm)) { mixin(S_TRACE);
						auto f = find(child);
						if (f) return f;
					}
					return null;
				}
			}
			lastItm = find(itm);
		} else if (last) { mixin(S_TRACE);
			Item findLast(Item itm) { mixin(S_TRACE);
				if (allLast is itm.getData()) { mixin(S_TRACE);
					return itm;
				} else { mixin(S_TRACE);
					foreach (child; _tree.getItems(itm)) { mixin(S_TRACE);
						auto f = findLast(child);
						if (f) return f;
					}
					return null;
				}
			}
			lastItm = findLast(itm);
			assert (lastItm !is null);
		}
		_tree.setSelection([lastItm]);
		_tree.showSelection();
		foreach (v; vs) v.refreshStatusLine();
		_comm.refUseCount.call();
		_comm.refreshToolBar();
	}
	@property
	private int insertStartIndex() { mixin(S_TRACE);
		auto sel = selection;
		if (sel) { mixin(S_TRACE);
			return _tree.indexOf(_tree.topItem(sel)) + 1;
		} else { mixin(S_TRACE);
			return 1;
		}
	}
	private void addStarts(bool stored, Content[] cs, Content[] refCS = []) { mixin(S_TRACE);
		if (_readOnly) return;
		_tree.control.setRedraw(false);
		scope (exit) _tree.control.setRedraw(true);
		bool empty = _et.owner.isEmpty;
		scope (exit) {
			if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
		}
		auto sel = selection;
		int index = insertStartIndex;
		Content[] cs2;
		foreach (ct; cs) { mixin(S_TRACE);
			if (ct.type !is CType.START) continue;
			cs2 ~= ct;
		}
		if (!cs2.length) return;

		auto top = _tree.getTopItem();
		auto vs = views();
		foreach (v; vs) v.editEnter();
		if (stored) storeInsert(index, cs2.length);
		Item sItm = null, lastItm = null;
		foreach (i, c; cs2) { mixin(S_TRACE);
			if (!c.type is CType.START) continue;
			auto oldName = c.name;
			c.setName(_prop.parent, createNewName(c.name, (string name) { mixin(S_TRACE);
				if (_et.hasStart(name)) return false;
				foreach (s; cs2) { mixin(S_TRACE);
					if (s is c) continue;
					if (s.name == name) { mixin(S_TRACE);
						return false;
					}
				}
				return true;
			}, true, EventView.eventTreeNames(_prop, _et)));
			if (c.name != oldName) { mixin(S_TRACE);
				void recurse(Content[] cs) { mixin(S_TRACE);
					foreach (ct; cs) { mixin(S_TRACE);
						if (ct.start == oldName) { mixin(S_TRACE);
							ct.start = c.name;
						}
						recurse(ct.next);
					}
				}
				recurse(refCS);
			}
			_et.insert(index + i, c);
			foreach (v; vs) { mixin(S_TRACE);
				Item sItm2;
				if (v._tree.tree) { mixin(S_TRACE);
					sItm2 = createTreeItem(v._tree.tree, c, c.name, _prop.images.content(c.type), cast(int)(index + i));
				} else { mixin(S_TRACE);
					sItm2 = EventEditorItem.valueOf(v._tree.editor, c);
				}
				auto lastItm2 = v.createChilds(sItm2, c);
				if (v._tree.editor) { mixin(S_TRACE);
					v._tree.editor.updatePosOne(c);
				} else { mixin(S_TRACE);
					v._tree.setExpanded(sItm2, true);
				}
				if (v is this) { mixin(S_TRACE);
					sItm = sItm2;
					lastItm = lastItm2;
				}
			}
			_comm.refContent.call(c);
		}
		if (!sItm) return;
		if (lastItm) _tree.setSelection([lastItm]);
		_tree.showSelection();
		foreach (v; vs) v.refreshStatusLine();
		_comm.refUseCount.call();
		_comm.refreshToolBar();
	}

	void editCancel() { mixin(S_TRACE);
		if (_ee) _ee.cancel();
		if (_te) _te.cancel();
	}
	void editEnter() { mixin(S_TRACE);
		if (_ee) _ee.enter();
		if (_te) _te.enter();
	}

	override {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			if (_readOnly) return;
			if (!_tree.getItemCount()) return;
			auto itm = selection;
			if (itm && itm !is _tree.getItem(0)) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			auto itm = selection;
			if (itm) { mixin(S_TRACE);
				foreach (v; views()) v.editEnter();
				auto c = cast(Content)itm.getData();
				XMLtoCB(_prop, _comm.clipboard, toXML(c));
				_comm.refreshToolBar();
			}
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
			if (_readOnly) return;
			pasteImpl(false);
		}
		void del(SelectionEvent se) { mixin(S_TRACE);
			if (_readOnly) return;
			if (!_tree.getItemCount()) return;
			auto itm = selection;
			if (itm && itm !is _tree.getItem(0)) { mixin(S_TRACE);
				_tree.control.setRedraw(false);
				scope(exit) _tree.control.setRedraw(true);
				delImpl(itm, (cast(Content)itm.getData()).parentStart, true, false, true);
				_comm.refUseCount.call();
				_comm.refreshToolBar();
			}
		}
		void clone(SelectionEvent se) { mixin(S_TRACE);
			if (_readOnly) return;
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			auto itm = selection;
			auto parItm = _tree.getParentItem(itm);
			if (parItm) { mixin(S_TRACE);
				_tree.setSelection([parItm]);
			}
			paste(se);
		}
		@property
		bool canDoTCPD() { mixin(S_TRACE);
			return !_readOnly && _et !is null;
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			if (!_tree.getItemCount()) return false;
			auto itm = selection;
			return !_readOnly && itm && itm !is _tree.getItem(0);
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			return selection !is null;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			return !_readOnly && _et !is null && (CBisXML(_comm.clipboard) || CBisText(_comm.clipboard));
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			return !_readOnly && canDoT;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			return !_readOnly && canDoC;
		}
	}
	private string toXML(in Content c, bool shallow = false) { mixin(S_TRACE);
		auto opt = new XMLOption(_prop.sys, LATEST_VERSION);
		opt.shallow = shallow;
		auto node = c.toNode(opt);
		CNextType next;
		if (c.parent) { mixin(S_TRACE);
			next = c.parent.detail.nextType;
		} else { mixin(S_TRACE);
			assert (c.type is CType.START, to!string(c.type));
			next = CNextType.TEXT;
		}
		node.newAttr("lastNextType", fromCNextType(next));
		node.newAttr("paneId", _id);
		return node.text;
	}
	@property
	bool canCut1Content() { return canDoT && _tree.getParentItem(selection); }
	@property
	bool canDel1Content() { return canDoD && _tree.getParentItem(selection); }
	alias canDoC canCopy1Content;
	alias canDoP canPasteInsert;
	void cut1Content() { mixin(S_TRACE);
		if (_readOnly) return;
		auto itm = selection;
		if (itm && _tree.getParentItem(itm)) { mixin(S_TRACE);
			foreach (v; views()) v.editEnter();
			copy1Content();
			del1Content();
		}
	}
	void copy1Content() { mixin(S_TRACE);
		auto itm = selection;
		if (itm) { mixin(S_TRACE);
			foreach (v; views()) v.editEnter();
			auto c = cast(Content)itm.getData();
			XMLtoCB(_prop, _comm.clipboard, toXML(c, true));
			_comm.refreshToolBar();
		}
	}
	void pasteInsert() { mixin(S_TRACE);
		if (_readOnly) return;
		pasteImpl(true);
	}
	void del1Content() { mixin(S_TRACE);
		if (_readOnly) return;
		auto itm = selection;
		if (itm && _tree.getParentItem(itm)) { mixin(S_TRACE);
			_tree.control.setRedraw(false);
			scope(exit) _tree.control.setRedraw(true);
			foreach (v; views()) v.editEnter();

			auto ownerItm = _tree.getParentItem(itm);
			auto c = cast(Content)itm.getData();
			auto parentStart = c.parentStart;
			_comm.delContent.call(c);
			auto owner = cast(Content)ownerItm.getData();
			this.store(owner);
			auto insertIndex = owner.next.countUntil(c);
			auto cName = c.name;
			owner.remove(c);
			auto lastNextType = fromCNextType(c.detail.nextType);
			foreach (i, next; c.next.dup) { mixin(S_TRACE);
				c.remove(next);
				if (_prop.var.etc.adjustContentName) { mixin(S_TRACE);
					if (i == 0 && lastNextType != fromCNextType(owner.detail.nextType)) { mixin(S_TRACE);
						next.setName(_prop.parent, cName);
					} else { mixin(S_TRACE);
						adjustText(owner, next, lastNextType);
					}
				} else { mixin(S_TRACE);
					adjustText(owner, next, lastNextType);
				}
				owner.insert(_prop.parent, insertIndex + i, next);
			}
			foreach (v; views()) { mixin(S_TRACE);
				if (v._tree.tree) { mixin(S_TRACE);
					assert (cast(TreeItem)ownerItm !is null);
					v.createChilds(.anotherTreeItem(v._tree.tree, cast(TreeItem)ownerItm), owner);
				} else { mixin(S_TRACE);
					v._tree.editor.updatePosOne(parentStart);
				}
			}
			_comm.refUseCount.call();
			_comm.refreshToolBar();
		}
	}
	private void pasteImpl(bool tryInsert) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_et) return;
		string c;
		try { mixin(S_TRACE);
			c = CBtoXML(_comm.clipboard);
		} catch (Exception e) {
			// たまにアクセス違反が起こる
			printStackTrace();
			debugln(e);
			return;
		}
		if (c) { mixin(S_TRACE);
			foreach (v; views()) v.editEnter();
			try { mixin(S_TRACE);
				auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
				auto node = XNode.parse(c);
				string id = node.attr("contentId", false);
				string lastNextType = node.attr("lastNextType", false, "");
				auto evt = Content.createFromNode(node, ver);
				if (!evt) return;
				if (evt.type == CType.START) { mixin(S_TRACE);
					addStarts(true, [evt]);
				} else { mixin(S_TRACE);
					addContents(true, [evt], [], tryInsert, lastNextType);
				}
				redraw();
				_comm.refreshToolBar();
				return;
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
		auto script = cast(ArrayWrapperString) _comm.clipboard.getContents(TextTransfer.getInstance());
		if (script) { mixin(S_TRACE);
			pasteScript(script.array.idup, tryInsert);
		}
	}
	void pasteScript(string script, bool tryInsert) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_et) return;
		string base = script;
		CompileOption opt;
		try { mixin(S_TRACE);
			try { mixin(S_TRACE);
				opt.linkId = (_prop.var.etc.linkCard || !_summ || !_summ.legacy);

				auto compiler = new CWXScript(_prop.parent, _summ);
				auto vars = compiler.eatEmptyVars(script, opt);
				if (vars.length) { mixin(S_TRACE);
					auto dlg = new ScriptVarSetDialog(_comm, _summ, _tree.control.getShell(), vars, script, base, opt);
					dlg.appliedEvent ~= { mixin(S_TRACE);
						putContents(dlg.contents, tryInsert);
					};
					dlg.open();
				} else { mixin(S_TRACE);
					auto cs = cwx.script.compile(_prop.parent, _summ, script, opt);
					putContents(cs, tryInsert);
				}
			} catch (CWXScriptException e) {
				throw e;
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
				throw e;
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
				throw new CWXScriptException(__FILE__, __LINE__, "", [CWXSError(_prop.msgs.scriptErrorSystem, 0, 0, __FILE__, __LINE__)], false);
			}
		} catch (CWXScriptException e) {
			auto dlg = new ScriptErrorDialog(_comm, _prop, _tree.control, e, base, opt);
			dlg.open();
		}
	}
	void putContents(Content[] cs, bool tryInsert) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_et) return;
		if (!cs.length) return;
		foreach (v; views()) v.editEnter();
		Content[] starts;
		Content[] contents;
		foreach (c; cs) { mixin(S_TRACE);
			if (c.type is CType.START) { mixin(S_TRACE);
				starts ~= c;
			} else { mixin(S_TRACE);
				contents ~= c;
			}
		}
		int si = insertStartIndex;
		bool s = starts.length > 0;
		if (s) tryInsert = false;
		auto sel = selection;
		auto owner = insertOwner(tryInsert, sel);
		bool c = contents.length && owner;
		if (s && c) { mixin(S_TRACE);
			storeContentAndInsert(owner, si, cast(int)starts.length);
			addContents(false, contents, cs, tryInsert);
			addStarts(false, starts, cs);
		} else if (s) { mixin(S_TRACE);
			addStarts(true, starts);
		} else if (c) { mixin(S_TRACE);
			addContents(true, contents, [], tryInsert);
		} else { mixin(S_TRACE);
			return;
		}
		foreach (v; views()) v.redraw();
		_comm.refreshToolBar();
	}
	private void delImpl(Item itm, Content parentStart, bool store, bool viewOnly = false, bool refOtherView = false) { mixin(S_TRACE);
		if (_readOnly) return;
		auto vs = [this];
		if (refOtherView) vs = views();
		foreach (v; vs) v.editEnter();
		auto tPath = _tree.tree ? .toTreePath(cast(TreeItem)itm) : [];
		bool empty = _et.owner.isEmpty;
		scope (exit) {
			if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
		}
		auto ownerItm = _tree.getParentItem(itm);
		auto c = cast(Content)itm.getData();
		if (!viewOnly) { mixin(S_TRACE);
			_comm.delContent.call(c);
			if (ownerItm) { mixin(S_TRACE);
				auto owner = cast(Content) ownerItm.getData();
				if (store) this.store(owner);
				owner.remove(c);
			} else { mixin(S_TRACE);
				if (store) this.storeDelete(cast(int).cCountUntil!("a is b")(_et.starts, c), c);
				_et.remove(c);
			}
		}
		foreach (v; vs) { mixin(S_TRACE);
			if (v._tree.tree) { mixin(S_TRACE);
				.fromTreePath(v._tree.tree, tPath).dispose();
			} else { mixin(S_TRACE);
				v._tree.editor.updatePosOne(parentStart);
			}
		}
	}
	private static void delImpl(EventTreeView[] vs, Commons comm, EventTree et, Content c) { mixin(S_TRACE);
		if (vs.length) { mixin(S_TRACE);
			Item[] itms;
			foreach (v; vs) itms ~= v.fromPath(c.ctPath);
			auto parentStart = c.parentStart;
			foreach (i, v; vs) { mixin(S_TRACE);
				v.delImpl(itms[i], parentStart, false, 0 < i);
			}
		} else { mixin(S_TRACE);
			bool empty = et.owner.isEmpty;
			scope (exit) {
				if (empty != et.owner.isEmpty) comm.refEventTree.call(et);
			}
			comm.delContent.call(c);
			if (c.parent) { mixin(S_TRACE);
				c.parent.remove(c);
			} else { mixin(S_TRACE);
				et.remove(c);
			}
		}
	}
	private void refreshCardImpl(Item evt) { mixin(S_TRACE);
		foreach (childItm; _tree.getItems(evt)) { mixin(S_TRACE);
			auto child = cast(Content) childItm.getData();
			childItm.setText(eventText(cast(Content) evt.getData(), child));
			if (child.detail.owner) { mixin(S_TRACE);
				refreshCardImpl(childItm);
			}
			procTreeItem(childItm);
		}
	}
	private void refreshCard() { mixin(S_TRACE);
		if (_tree.control.isDisposed()) return;
		if (_et) { mixin(S_TRACE);
			if (_tree.editor) { mixin(S_TRACE);
				_tree.editor.updateEventText();
			} else { mixin(S_TRACE);
				foreach (itm; _tree.getItems()) { mixin(S_TRACE);
					refreshCardImpl(itm);
				}
			}
			refreshStatusLine();
		}
	}
	private void refreshEventTextImpl(Content par, Item itm) in { mixin(S_TRACE);
		assert (par.detail.owner);
	} body { mixin(S_TRACE);
		auto e = cast(Content) itm.getData();
		itm.setText(eventText(par, e));
		if (e.detail.owner) { mixin(S_TRACE);
			foreach (child; _tree.getItems(itm)) { mixin(S_TRACE);
				refreshEventTextImpl(e, child);
			}
		} else { mixin(S_TRACE);
			assert (!_tree.getItems(itm).length);
		}
		procTreeItem(itm);
	}
	private void refreshEventText() { mixin(S_TRACE);
		if (_et) { mixin(S_TRACE);
			if (_tree.editor) { mixin(S_TRACE);
				_tree.editor.updateEventText();
			} else { mixin(S_TRACE);
				foreach (itm; _tree.getItems()) { mixin(S_TRACE);
					auto start = cast(Content) itm.getData();
					assert (start.type == CType.START);
					itm.setText(start.name);
					foreach (child; _tree.getItems(itm)) { mixin(S_TRACE);
						refreshEventTextImpl(start, child);
					}
				}
			}
			refreshStatusLine();
		}
	}
	private void refSkin() { refreshCard(); }
	private void refDataVersion() { mixin(S_TRACE);
		refreshCard();
		if (_summ ? _prop.var.etc.showVariableValuesInEventText : showVariableValuesInEventText) { mixin(S_TRACE);
			refreshEventText();
		}
	}
	private void refreshCast(CastCard c) { refreshCard(); }
	private void refreshSkill(SkillCard c) { refreshCard(); }
	private void refreshItem(ItemCard c) { refreshCard(); }
	private void refreshBeast(BeastCard c) { refreshCard(); }
	private void delSkill(CWXPath owner, SkillCard c) { refreshCard(); }
	private void delItem(CWXPath owner, ItemCard c) { refreshCard(); }
	private void delBeast(CWXPath owner, BeastCard c) { refreshCard(); }
	private void refreshInfo(InfoCard c) { refreshCard(); }
	private void refreshArea(Area c) { refreshCard(); }
	private void refreshPackage(Package c) { refreshCard(); }
	private void refreshBattle(Battle c) { refreshCard(); }
	private void refreshFlagAndStep(cwx.flag.Flag[] flags, Step[] steps) { mixin(S_TRACE);
		if (flags.length || steps.length) { mixin(S_TRACE);
			refreshCard();
			if (_summ ? _prop.var.etc.showVariableValuesInEventText : showVariableValuesInEventText) { mixin(S_TRACE);
				refreshEventText();
			}
		}
	}
	private void refreshPath(string from, string to, bool isDir) { refreshStatusLine(); }
	private void refreshPaths(string path) { refreshStatusLine(); }
	private void deletePaths() { refreshStatusLine(); }
	private void replacePaths(string from, string to) { refreshStatusLine(); }

	private bool _straightEventTreeView = false;
	private bool _showVariableValuesInEventText = false;
	private bool _classicStyleTree = false;

	private bool _showTerminalMark = false;
	private bool _forceIndentBranchContent = false;
	private bool _drawContentTreeLine = false;
	private bool _drawCountOfUseOfStart = false;
	private bool _drawContentWarnings = false;

	/// 表示オプション。
	/// シナリオ編集中であればCommons#propの値が、
	/// 表示テスト中であればここで設定された値が採用される。
	@property
	const
	bool straightEventTreeView() { return _straightEventTreeView; }
	/// ditto
	@property
	void straightEventTreeView(bool v) { mixin(S_TRACE);
		_straightEventTreeView = v;
		refEventTreeViewStyle();
	}
	/// ditto
	@property
	const
	bool showVariableValuesInEventText() { return _showVariableValuesInEventText; }
	/// ditto
	@property
	void showVariableValuesInEventText(bool v) { mixin(S_TRACE);
		_showVariableValuesInEventText = v;
		refreshEventText();
	}
	/// ditto
	@property
	const
	bool classicStyleTree() { return _classicStyleTree; }
	/// ditto
	@property
	void classicStyleTree(bool v) { mixin(S_TRACE);
		_classicStyleTree = v;
		_comm.refEventTreeStyle.call();
	}

	/// ditto
	@property
	const
	bool showTerminalMark() { return _showTerminalMark; }
	/// ditto
	@property
	void showTerminalMark(bool v) { mixin(S_TRACE);
		_showTerminalMark = v;
		if (_tree.editor) _tree.editor.showTerminalMark = v;
	}
	/// ditto
	@property
	const
	bool forceIndentBranchContent() { return _forceIndentBranchContent; }
	/// ditto
	@property
	void forceIndentBranchContent(bool v) { mixin(S_TRACE);
		_forceIndentBranchContent = v;
		if (_tree.editor) _tree.editor.forceIndentBranchContent = v;
	}
	/// ditto
	@property
	const
	bool drawContentTreeLine() { return _drawContentTreeLine; }
	/// ditto
	@property
	void drawContentTreeLine(bool v) { mixin(S_TRACE);
		_drawContentTreeLine = v;
		if (_tree.editor) { mixin(S_TRACE);
			_tree.editor.drawContentTreeLine = v;
		} else { mixin(S_TRACE);
			redraw();
		}
	}
	/// ditto
	@property
	const
	bool drawCountOfUseOfStart() { return _drawCountOfUseOfStart; }
	/// ditto
	@property
	void drawCountOfUseOfStart(bool v) { mixin(S_TRACE);
		_drawCountOfUseOfStart = v;
		if (_tree.editor) { mixin(S_TRACE);
			_tree.editor.drawCountOfUseOfStart = v;
		} else { mixin(S_TRACE);
			redraw();
		}
	}
	/// ditto
	@property
	const
	bool drawContentWarnings() { return _drawContentWarnings; }
	/// ditto
	@property
	void drawContentWarnings(bool v) { mixin(S_TRACE);
		_drawContentWarnings = v;
		if (_tree.editor) { mixin(S_TRACE);
			_tree.editor.drawContentWarnings = v;
		} else { mixin(S_TRACE);
			redraw();
		}
	}

	private bool openCWXPathImpl(string path, bool shellActivate) { mixin(S_TRACE);
		Item itm = null;
		while (true) { mixin(S_TRACE);
			auto cate = cpcategory(path);
			if (cate == "") { mixin(S_TRACE);
				auto index = cpindex(path);
				auto count = itm ? _tree.getItemCount(itm) : _tree.getItemCount();
				if (count <= index) return false;
				itm = itm ? _tree.getItem(itm, cast(int)index) : _tree.getItem(cast(int)index);
				path = cpbottom(path);
				if (cpempty(path) || cpcategory(path) != "") { mixin(S_TRACE);
					if (!cphasattr(path, "nofocus")) .forceFocus(_tree.control, shellActivate);
					_tree.select(itm);
					_tree.showSelection();
					refreshStatusLine();
					if (cpcategory(path) != "name" && (cphasattr(path, "opendialog") || (!cpempty(path) && cpcategory(path) != "dialog" && cpcategory(path) != "text"))) { mixin(S_TRACE);
						auto d = edit();
						if (!d) { mixin(S_TRACE);
							// ダイアログ無し、もしくは開けない状態のコンテント
							_comm.refreshToolBar();
							return true;
						}
						if (!cpempty(path)) { mixin(S_TRACE);
							return d.openCWXPath(path, shellActivate);
						}
					}
					_comm.refreshToolBar();
					return true;
				} else { mixin(S_TRACE);
					continue;
				}
			}
			break;
		}
		return false;
	}
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		return openCWXPathImpl(path, shellActivate);
	}
	@property
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		if (_et) { mixin(S_TRACE);
			auto e = selection;
			if (e) { mixin(S_TRACE);
				auto c = cast(Content) e.getData();
				assert (c);
				r ~= c.cwxPath(true);
			} else { mixin(S_TRACE);
				r ~= _et.cwxPath(true);
			}
		}
		return r;
	}
}

string eventText(Commons comm, Summary summ, Content parent, Content e, bool readOnly) in { mixin(S_TRACE);
	assert (!parent || parent.detail.owner);
} body { mixin(S_TRACE);
	if (!parent) return e.name;
	auto prop = comm.prop;
	if (parent.detail.nextType == CNextType.TEXT) { mixin(S_TRACE);
		if (prop.var.etc.showVariableValuesInEventText) { mixin(S_TRACE);
			VarValue[string] flags;
			VarValue[string] steps;
			VarValue[string] sysSteps;
			string[char] names;
			getPreviewValues(prop, summ, SPCHAR_TEXT, names, flags, steps, sysSteps);
			return simpleFormatMsg(e.name, flags, steps, sysSteps, names, ver => comm.prop.isTargetVersion(summ, ver),
				comm.prop.sys.prefixSystemVarName);
		} else { mixin(S_TRACE);
			return e.name;
		}
	}
	string name = e.name;
	string r;
	switch (parent.type) {
	case CType.BRANCH_FLAG: { mixin(S_TRACE);
		r = evtChildBrFlag(prop, summ, parent.flag, name);
		break;
	} case CType.BRANCH_MULTI_STEP: { mixin(S_TRACE);
		r = evtChildBrStepN(prop, summ, parent.step, name);
		break;
	} case CType.BRANCH_STEP: { mixin(S_TRACE);
		r = evtChildBrStepUL(prop, summ, parent.step, parent.stepValue, name);
		break;
	} case CType.BRANCH_SELECT: { mixin(S_TRACE);
		r = evtChildBrMember(prop, parent, name);
		break;
	} case CType.BRANCH_ABILITY: { mixin(S_TRACE);
		r = evtChildBrPower(prop, parent.targetS, parent.physical, parent.mental, parent.signedLevel, name);
		break;
	} case CType.BRANCH_RANDOM: { mixin(S_TRACE);
		r = evtChildBrRandom(prop, parent.percent, name);
		break;
	} case CType.BRANCH_LEVEL: { mixin(S_TRACE);
		r = evtChildBrLevel(prop, parent.unsignedLevel, parent.average, name);
		break;
	} case CType.BRANCH_STATUS: { mixin(S_TRACE);
		r = evtChildBrState(prop, parent.range, parent.holdingCoupon, parent.status, name);
		break;
	} case CType.BRANCH_PARTY_NUMBER: { mixin(S_TRACE);
		r = evtChildBrNum(prop, parent.partyNumber, name);
		break;
	} case CType.BRANCH_AREA: { mixin(S_TRACE);
		r = evtChildBrArea(prop, summ ? summ.areas : [], name);
		break;
	} case CType.BRANCH_BATTLE: { mixin(S_TRACE);
		r = evtChildBrBattle(prop, summ ? summ.battles : [], name);
		break;
	} case CType.BRANCH_IS_BATTLE: { mixin(S_TRACE);
		r = evtChildBrOnBattle(prop, name);
		break;
	} case CType.BRANCH_CAST: { mixin(S_TRACE);
		r = evtChildBrCast(prop, summ, parent.casts, name);
		break;
	} case CType.BRANCH_ITEM: { mixin(S_TRACE);
		r = evtChildBrItem(prop, summ, parent.item, parent.range, parent.cardNumber, name);
		break;
	} case CType.BRANCH_SKILL: { mixin(S_TRACE);
		r = evtChildBrSkill(prop, summ, parent.skill, parent.range, parent.cardNumber, name);
		break;
	} case CType.BRANCH_BEAST: { mixin(S_TRACE);
		r = evtChildBrBeast(prop, summ, parent.beast, parent.range, parent.cardNumber, name);
		break;
	} case CType.BRANCH_INFO: { mixin(S_TRACE);
		r = evtChildBrInfo(prop, summ, parent.info, name);
		break;
	} case CType.BRANCH_MONEY: { mixin(S_TRACE);
		r = evtChildBrMoney(prop, parent.money, name);
		break;
	} case CType.BRANCH_COUPON: { mixin(S_TRACE);
		r = evtChildBrCoupon(prop, parent.range, parent.couponNames.dup, parent.matchingType, name);
		break;
	} case CType.BRANCH_COMPLETE_STAMP: { mixin(S_TRACE);
		r = evtChildBrEnd(prop, parent.completeStamp, name);
		break;
	} case CType.BRANCH_GOSSIP: { mixin(S_TRACE);
		r = evtChildBrGossip(prop, parent.gossip, name);
		break;
	} case CType.BRANCH_STEP_CMP: { mixin(S_TRACE);
		r = evtChildBrStepCmp(prop, summ, parent.step, parent.step2, name);
		break;
	} case CType.BRANCH_FLAG_CMP: { mixin(S_TRACE);
		r = evtChildBrFlagCmp(prop, summ, parent.flag, parent.flag2, name);
		break;
	} case CType.BRANCH_RANDOM_SELECT: { mixin(S_TRACE);
		r = evtChildBrRandomSelect(prop, parent, name);
		break;
	} case CType.BRANCH_KEY_CODE: { mixin(S_TRACE);
		r = evtChildBrKeyCode(prop, parent, name);
		break;
	} case CType.BRANCH_ROUND: { mixin(S_TRACE);
		r = evtChildBrRound(prop, parent, name);
		break;
	} case CType.BRANCH_MULTI_COUPON: { mixin(S_TRACE);
		auto range = .rangeName(prop, parent.range, parent.holdingCoupon);
		if (e.name == "") { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchMultiCouponFailure, range);
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchMultiCouponSuccess, range, e.name);
		}
		break;
	} default:
		name = "";
		r = "";
	}
	if (e.name != name && !readOnly) { mixin(S_TRACE);
		e.setName(prop.parent, name);
		comm.refContent.call(e);
	}
	return r;
}

private string evtChildBrFlag(in Props prop, in Summary summ, string path, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string name = prop.msgs.noSelectFlag;
	string on = prop.msgs.flagOn;
	string off = prop.msgs.flagOff;
	if (path.length && summ) { mixin(S_TRACE);
		auto o = summ.flagDirRoot.findFlag(path);
		if (o) { mixin(S_TRACE);
			name = path;
			on = o.on;
			off = o.off;
		} else { mixin(S_TRACE);
			name = .tryFormat(prop.msgs.noFlag, path);
		}
	}
	return .tryFormat(prop.msgs.evtChildBrVar, name, (val ? on : off));
}
private string evtChildBrStepN(in Props prop, in Summary summ, string path, ref string text) { mixin(S_TRACE);
	int val = -1;
	try { mixin(S_TRACE);
		val = text == prop.sys.evtChildDefault ? -1 : (isNumeric(text) ? to!(int)(text) : -1);
	} catch (Exception e) { mixin(S_TRACE);
		printStackTrace();
		debugln(e);
	}
	string name = prop.msgs.noSelectStep;
	string value = val >= 0 ? .parseDollarParams(prop.var.etc.stepValueName, ['N':.to!string(val)]) : prop.msgs.etc;
	if (path.length && summ) { mixin(S_TRACE);
		auto o = summ.flagDirRoot.findStep(path);
		if (o) { mixin(S_TRACE);
			name = path;
			if (0 <= val) value = getStepValue(prop, o, val);
		} else { mixin(S_TRACE);
			name = .tryFormat(prop.msgs.noStep, path);
		}
	}
	return .tryFormat(prop.msgs.evtChildBrVar, name, value);
}
private string evtChildBrStepUL(in Props prop, in Summary summ, string path, int num, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string name = prop.msgs.noSelectStep;
	string value = .parseDollarParams(prop.var.etc.stepValueName, ['N':.to!string(num)]);
	if (path.length && summ) { mixin(S_TRACE);
		auto o = summ.flagDirRoot.findStep(path);
		if (o) { mixin(S_TRACE);
			name = path;
			value = getStepValue(prop, o, num);
		} else { mixin(S_TRACE);
			name = .tryFormat(prop.msgs.noStep, path);
		}
	}
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.stepMoreThan, name, value);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.stepLessThan, name, value);
	}
}
private string evtChildBrMember(in Props prop, in Content evt, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string mem = evt.targetAll ? prop.msgs.partyAll : prop.msgs.partyActive;
	string am;
	final switch (evt.selectionMethod) {
	case SelectionMethod.Manual:
		am = prop.msgs.manualSelect;
		break;
	case SelectionMethod.Random:
		am = prop.msgs.autoSelect;
		break;
	case SelectionMethod.Valued:
		am = prop.msgs.valuedSelect;
		break;
	}
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.selectMemberSuccess, mem, am);
	} else { mixin(S_TRACE);
		if (evt.selectionMethod is SelectionMethod.Manual) { mixin(S_TRACE);
			return .tryFormat(prop.msgs.selectMemberCancel, mem, am);
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.selectMemberFailure, mem, am);
		}
	}
}
private string evtChildBrPower(in Props prop, Target targ, Physical p, Mental m, int lev, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string tt = prop.msgs.targetName(targ.m);
	string tp = prop.msgs.physicalName(p);
	string tm = prop.msgs.mentalName(m);
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchAbilitySuccess, tt, lev, tp, tm);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchAbilityFailure, tt, lev, tp, tm);
	}
}
private string evtChildBrRandom(in Props prop, int percent, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchRandomSuccess, percent);
	} else { mixin(S_TRACE);
		if (prop.var.etc.branchRandomFailureFormat) { mixin(S_TRACE);
			percent = 100 - percent;
		}
		return .tryFormat(prop.msgs.branchRandomFailure, percent);
	}
}
private string evtChildBrLevel(in Props prop, int lev, bool avg, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string ta = avg  ? prop.msgs.levelAverage : prop.msgs.levelSelected;
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchLevelSuccess, ta, lev);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchLevelFailure, ta, lev);
	}
}
private string evtChildBrState(in Props prop, Range range, string holdingCoupon, Status stat, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string tt = .rangeName(prop, range, holdingCoupon);
	string ts = prop.msgs.statusName(stat);
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchStatusSuccess, tt, ts);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchStatusFailure, tt, ts);
	}
}
private string evtChildBrNum(in Props prop, int num, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchNumberSuccess, num);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchNumberFailure, num);
	}
}
private string evtChildBrArea(in Props prop, in Area[] areas, ref string text) { mixin(S_TRACE);
	if (text.length > 0) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			long val = text == prop.sys.evtChildDefault ? -1 : (isNumeric(text) ? to!(long)(text) : -1);
			if (val >= 0) { mixin(S_TRACE);
				foreach (a; areas) { mixin(S_TRACE);
					if (a.id == val) { mixin(S_TRACE);
						return .tryFormat(prop.msgs.branchAreaWithId, a.id, a.name);
					}
				}
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	text = prop.sys.evtChildDefault;
	return .tryFormat(prop.msgs.branchArea, prop.msgs.etc);
}
private string evtChildBrBattle(in Props prop, in Battle[] btls, ref string text) { mixin(S_TRACE);
	if (text.length > 0) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			long val = text == prop.sys.evtChildDefault ? -1 : (isNumeric(text) ? to!(long)(text) : -1);
			if (val >= 0) { mixin(S_TRACE);
				foreach (b; btls) { mixin(S_TRACE);
					if (b.id == val) { mixin(S_TRACE);
						return .tryFormat(prop.msgs.branchBattleWithId, b.id, b.name);
					}
				}
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	text = prop.sys.evtChildDefault;
	return .tryFormat(prop.msgs.branchBattle, prop.msgs.etc);
}
private string evtChildBrOnBattle(in Props prop, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (val) { mixin(S_TRACE);
		return prop.msgs.branchOnBattleSuccess;
	} else { mixin(S_TRACE);
		return prop.msgs.branchOnBattleFailure;
	}
}
private string evtChildBrCast(in Props prop, in Summary summ, ulong id, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string name = prop.msgs.noSelectCast;
	if (0 != id && summ) { mixin(S_TRACE);
		auto c = summ.cwCast(id);
		name = c ? .format(prop.msgs.nameWithID, c.id, c.name) : .tryFormat(prop.msgs.noCast, id);
	}
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchCastSuccess, name);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchCastFailure, name);
	}
}
private string evtChildBrItem(in Props prop, in Summary summ, ulong id, Range r, uint num, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string tr = prop.msgs.rangeName(r);
	string name = prop.msgs.noSelectItem;
	if (0 != id && summ) { mixin(S_TRACE);
		auto c = summ.item(id);
		name = c ? .format(prop.msgs.nameWithID, c.id, c.name) : .tryFormat(prop.msgs.noItem, id);
	}
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchEffectCardSuccess, tr, name);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchEffectCardFailure, tr, name);
	}
}
private string evtChildBrSkill(in Props prop, in Summary summ, ulong id, Range r, uint num, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string tr = prop.msgs.rangeName(r);
	string name = prop.msgs.noSelectSkill;
	if (0 != id && summ) { mixin(S_TRACE);
		auto c = summ.skill(id);
		name = c ? .format(prop.msgs.nameWithID, c.id, c.name) : .tryFormat(prop.msgs.noSkill, id);
	}
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchEffectCardSuccess, tr, name);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchEffectCardFailure, tr, name);
	}
}
private string evtChildBrBeast(in Props prop, in Summary summ, ulong id, Range r, uint num, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string tr = prop.msgs.rangeName(r);
	string name = prop.msgs.noSelectBeast;
	if (0 != id && summ) { mixin(S_TRACE);
		auto c = summ.beast(id);
		name = c ? .format(prop.msgs.nameWithID, c.id, c.name) : .tryFormat(prop.msgs.noBeast, id);
	}
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchEffectCardSuccess, tr, name);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchEffectCardFailure, tr, name);
	}
}
private string evtChildBrInfo(in Props prop, in Summary summ, ulong id, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string name = prop.msgs.noSelectInfo;
	if (0 != id && summ) { mixin(S_TRACE);
		auto c = summ.info(id);
		name = c ? .format(prop.msgs.nameWithID, c.id, c.name) : .tryFormat(prop.msgs.noInfo, id);
	}
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchInfoSuccess, name);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchInfoFailure, name);
	}
}
private string evtChildBrMoney(in Props prop, uint sp, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchMoneySuccess, sp);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchMoneyFailure, sp);
	}
}
private string evtChildBrCoupon(in Props prop, Range r, string[] couponNames, MatchingType matchingType, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string coupon = prop.msgs.noSelectCoupon;
	string s;
	string[] names;
	if (couponNames.length == 1 && couponNames[0]) { mixin(S_TRACE);
		coupon = couponNames[0];
	} else if (couponNames.length > 1) {
		foreach (name; couponNames) { mixin(S_TRACE);
			names ~= .tryFormat(prop.msgs.couponNames, name);
		}
	}
	string tr = prop.msgs.rangeName(r);
	string type = prop.msgs.matchingTypeAnd;
	if (matchingType == MatchingType.Or) { mixin(S_TRACE);
		type = prop.msgs.matchingTypeOr;
	}
	if (val) { mixin(S_TRACE);
		if (couponNames.length < 2) { mixin(S_TRACE);
			s ~= .tryFormat(prop.msgs.branchCouponSuccess, tr, coupon);
		} else {
			s ~= .tryFormat(prop.msgs.branchCouponMultiSuccess, tr, names.join(prop.msgs.couponNamesSeparator.value), type);
		}
	} else { mixin(S_TRACE);
		if (couponNames.length < 2) { mixin(S_TRACE);
			s ~= .tryFormat(prop.msgs.branchCouponFailure, tr, coupon);
		} else {
			s ~= .tryFormat(prop.msgs.branchCouponMultiFailure, tr, names.join(prop.msgs.couponNamesSeparator.value), type);
		}
	}
	return s;
}
private string evtChildBrEnd(in Props prop, string scenario, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (!scenario || !scenario.length) scenario = prop.msgs.noSelectCompleteStamp;
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchCompleteSuccess, scenario);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchCompleteFailure, scenario);
	}
}
private string evtChildBrGossip(in Props prop, string gossip, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (!gossip || !gossip.length) gossip = prop.msgs.noSelectGossip;
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchGossipSuccess, gossip);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchGossipFailure, gossip);
	}
}
private string evtChildBrStepCmp(in Props prop, in Summary summ, string step1, string step2, ref string text) { mixin(S_TRACE);
	int index;
	if (text == prop.sys.evtChildEq) { mixin(S_TRACE);
		index = 2;
		text = prop.sys.evtChildEq;
	} else if (text == prop.sys.evtChildLesser) { mixin(S_TRACE);
		index = 1;
		text = prop.sys.evtChildLesser;
	} else { mixin(S_TRACE);
		index = 0;
		text = prop.sys.evtChildGreater;
	}
	string nameFrom(string path) { mixin(S_TRACE);
		string name = prop.msgs.noSelectStep;
		if (path.length && summ) { mixin(S_TRACE);
			auto o = summ.flagDirRoot.findStep(path);
			if (o) { mixin(S_TRACE);
				name = path;
			} else { mixin(S_TRACE);
				name = .tryFormat(prop.msgs.noStep, path);
			}
		}
		return name;
	}
	step1 = nameFrom(step1);
	step2 = nameFrom(step2);
	switch (index) {
	case 0:
		return .tryFormat(prop.msgs.branchStepCmpGreater, step1, step2);
	case 1:
		return .tryFormat(prop.msgs.branchStepCmpLesser, step1, step2);
	case 2:
		return .tryFormat(prop.msgs.branchStepCmpEq, step1, step2);
	default:
		assert (0);
	}
}
private string evtChildBrFlagCmp(in Props prop, in Summary summ, string flag1, string flag2, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string nameFrom(string path) { mixin(S_TRACE);
		string name = prop.msgs.noSelectFlag;
		if (path.length && summ) { mixin(S_TRACE);
			auto o = summ.flagDirRoot.findFlag(path);
			if (o) { mixin(S_TRACE);
				name = path;
			} else { mixin(S_TRACE);
				name = .tryFormat(prop.msgs.noFlag, path);
			}
		}
		return name;
	}
	flag1 = nameFrom(flag1);
	flag2 = nameFrom(flag2);
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchFlagCmpEq, flag1, flag2);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchFlagCmpNotEq, flag1, flag2);
	}
}
private string evtChildBrRandomSelect(in Props prop, in Content evt, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;

	string r = castRangesName(prop, evt.castRange);
	bool hasLevel = 0 < evt.levelMax;
	bool hasStatus = evt.status !is Status.NONE;
	if (hasLevel || hasStatus) { mixin(S_TRACE);
		string s = prop.msgs.statusName(evt.status);
		auto l1 = evt.levelMin, l2 = evt.levelMax;
		string cond;
		if (hasLevel && hasStatus) { mixin(S_TRACE);
			cond = .tryFormat(prop.msgs.randomSelectCondition3, l1, l2, s);
		} else if (hasLevel) { mixin(S_TRACE);
			cond = .tryFormat(prop.msgs.randomSelectCondition1, l1, l2);
		} else if (hasStatus) { mixin(S_TRACE);
			cond = .tryFormat(prop.msgs.randomSelectCondition2, s);
		} else assert (0);
		if (val) { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchRandomSelectSuccess, r, cond);
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchRandomSelectFailure, r, cond);
		}
	} else { mixin(S_TRACE);
		if (val) { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchRandomSelectSuccessN, r);
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchRandomSelectFailureN, r);
		}
	}
}
private string evtChildBrKeyCode(in Props prop, in Content evt, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	auto name = evt.keyCode == "" ? prop.msgs.noKeyCode : evt.keyCode;

	string range = prop.msgs.rangeName(evt.keyCodeRange);
	if (evt.targetIsSkill && evt.targetIsItem && evt.targetIsBeast && evt.targetIsHand) { mixin(S_TRACE);
		if (val) { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchKeyCodeAllTypeSuccess, name, range);
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchKeyCodeAllTypeFailure, name, range);
		}
	} else { mixin(S_TRACE);
		string[] targets;
		if (evt.targetIsSkill) targets ~= prop.msgs.targetIsSkill;
		if (evt.targetIsItem) targets ~= prop.msgs.targetIsItem;
		if (evt.targetIsBeast) targets ~= prop.msgs.targetIsBeast;
		if (evt.targetIsHand) targets ~= prop.msgs.targetIsHand;
		string target = prop.msgs.noSelectTarget;
		if (targets.length) { mixin(S_TRACE);
			target = targets.join(prop.msgs.targetSeparator.value);
		}
		if (val) { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchKeyCodeSuccess, name, target, range);
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchKeyCodeFailure, name, target, range);
		}
	}
}
private string evtChildBrRound(in Props prop, in Content evt, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;

	string cmp;
	if (val) { mixin(S_TRACE);
		cmp = prop.msgs.comparison3Name(evt.comparison3);
	} else { mixin(S_TRACE);
		cmp = prop.msgs.comparison3FalseName(evt.comparison3);
	}
	return .tryFormat(prop.msgs.branchRound, evt.round, cmp);
}

Image warningImage(Props prop, Display d, int warningImageWidth = -1) { mixin(S_TRACE);
	if (warningImageWidth < 0) warningImageWidth = prop.var.etc.warningImageWidth;
	auto height = 1;
	auto buf = new Image(d, warningImageWidth, height);
	scope (exit) buf.dispose();
	auto gc = new GC(buf);
	scope (exit) gc.dispose();
	int alpha;
	auto rgb = dwtData(prop.var.etc.warningImageColor, alpha);
	auto color = new Color(d, rgb);
	scope (exit) color.dispose();
	gc.setForeground(color);
	gc.setBackground(color);
	gc.fillRectangle(0, 0, warningImageWidth, height);
	auto alphas = new byte[warningImageWidth];
	foreach (i, ref b; alphas) { mixin(S_TRACE);
		b = cast(byte)(cast(real)i / warningImageWidth * alpha);
	}
	alphas = .replicate(alphas, height);
	assert (alphas.length == warningImageWidth * height);
	auto imgData = buf.getImageData();
	imgData.setAlphas(0, 0, warningImageWidth * height, alphas, 0);
	return new Image(d, imgData);
}

class ContentsToolBox {
	private Commons _comm;
	private Props _prop;
	private Summary _summ;
	private EventTreeView _parent = null;
	private CoolBar _cbar;

	private Menu _templMenu;
	private ToolItem _templTI;

	private auto _putMode = MenuID.PutSelect;
	private bool _autoOpen;
	private bool _insertFirst;
	private MenuItem _putQuickMI;
	private MenuItem _putSelectMI;
	private MenuItem _putContinueMI;
	private ToolItem _putModeTI;
	private ToolItem _autoOpenTI;
	private ToolItem _insertFirstTI;

	private bool _arrowMode = true;

	private CType _cType;
	private ToolItem _arrowTI;
	private ToolItem _evtTI = null;
	private ToolItemGroup _radioGroup;

	private Cursor[] _cursors;

	private CreateEvent[CType] _conts;
	private bool _shiftDown = false;
	private bool _ctrlDown = false;
	private bool _altDown = false;

	private MouseTrack _mTrack = null;
	private Shell _toolWin = null;
	private Shell _autoHideTools = null;
	private TCListener _tcListener = null;
	private bool _opened = false;
	private int _parX, _parY;
	private DisposeListener _disposeParent = null;
	private AHTCListener _autoResize = null;

	private void autoOpen() { mixin(S_TRACE);
		_autoOpen = _autoOpenTI.getSelection();
		_comm.selContentTool.call(this, _arrowMode, _cType, _putMode, _autoOpen, _insertFirst);
	}
	private void updatePutMode() { mixin(S_TRACE);
		if (_putQuickMI.getSelection()) { mixin(S_TRACE);
			_putMode = MenuID.PutQuick;
			arrow();
			foreach (ti; _radioGroup.set) { mixin(S_TRACE);
				ti.setSelection(false);
			}
			_arrowTI.setSelection(false);
		} else if (_putSelectMI.getSelection()) { mixin(S_TRACE);
			_putMode = MenuID.PutSelect;
			if (!_arrowTI.getEnabled()) arrow();
		} else if (_putContinueMI.getSelection()) { mixin(S_TRACE);
			_putMode = MenuID.PutContinue;
			if (!_arrowTI.getEnabled()) arrow();
		}
		_arrowTI.setEnabled(_putMode !is MenuID.PutQuick);
		_putModeTI.setToolTipText(_prop.msgs.menuText(_putMode));
		_putModeTI.setImage(_prop.images.menu(_putMode));
		_comm.selContentTool.call(this, _arrowMode, _cType, _putMode, _autoOpen, _insertFirst);
	}
	private void insertFirst() { mixin(S_TRACE);
		_insertFirst = _insertFirstTI.getSelection();
		_comm.selContentTool.call(this, _arrowMode, _cType, _putMode, _autoOpen, _insertFirst);
	}
	@property
	bool isInsert() { mixin(S_TRACE);
		return _shiftDown && !(_comm.isMenuAccelerating & SWT.SHIFT);
	}
	@property
	bool isInsertFirst() { mixin(S_TRACE);
		return (_ctrlDown && !(_comm.isMenuAccelerating & SWT.CTRL)) ? !_prop.var.etc.contentsInsertFirst : _prop.var.etc.contentsInsertFirst;
	}
	@property
	bool isAutoOpen() { mixin(S_TRACE);
		return (_altDown && !(_comm.isMenuAccelerating & SWT.ALT)) ? !_prop.var.etc.contentsAutoOpen : _prop.var.etc.contentsAutoOpen;
	}

	private void arrow() { mixin(S_TRACE);
		_arrowMode = true;
		if (_radioGroup && _putMode !is MenuID.PutQuick) _radioGroup.select(_arrowTI);
		_comm.selContentTool.call(this, _arrowMode, _cType, _putMode, _autoOpen, _insertFirst);
	}
	private void updateCursor() {
		auto cursor = _arrowMode ? null : _conts[_cType]._cursor;
		if (_toolWin && !_toolWin.isDisposed()) { mixin(S_TRACE);
			_toolWin.setCursor(cursor);
		}
		if (_autoHideTools) { mixin(S_TRACE);
			_autoHideTools.setCursor(cursor);
		}
	}
	private void selContentTool(Object sender, bool arrowMode, CType cType, MenuID putMode, bool autoOpen, bool insertFirst) { mixin(S_TRACE);
		scope (exit) {
			updateCursor();

			_prop.var.etc.contentsAutoOpen = _autoOpen;
			switch (_putMode) {
			case MenuID.PutQuick:
				_prop.var.etc.contentsPutMode = 0;
				break;
			case MenuID.PutSelect:
				_prop.var.etc.contentsPutMode = 1;
				break;
			case MenuID.PutContinue:
				_prop.var.etc.contentsPutMode = 1;
				break;
			default:
				assert (0);
			}
			_prop.var.etc.contentsInsertFirst = _insertFirst;
		}

		if (sender is this) return;

		if (!_arrowMode && arrowMode) { mixin(S_TRACE);
			arrow();
		}
		if (((_arrowMode && !arrowMode) || (_cType != cType)) && MenuID.PutQuick !is putMode) { mixin(S_TRACE);
			assert (cType in _conts, .format("%s, putMode", cType));
			auto ce = _conts[cType];
			_radioGroup.select(ce.ti);
			ce.create(null);
		}
		if (_autoOpen != autoOpen) { mixin(S_TRACE);
			_autoOpenTI.setSelection(autoOpen);
			this.autoOpen();
		}
		if (_putMode != putMode) { mixin(S_TRACE);
			_putMode = putMode;
			_putQuickMI.setSelection(_putMode is MenuID.PutQuick);
			_putSelectMI.setSelection(_putMode is MenuID.PutSelect);
			_putContinueMI.setSelection(_putMode is MenuID.PutContinue);
			this.updatePutMode();
		}
		if (_insertFirst != insertFirst) { mixin(S_TRACE);
			_insertFirstTI.setSelection(insertFirst);
			this.insertFirst();
		}
	}

	private class CreateEvent {
		CType type;

		private ToolItem _itm;
		private Cursor _cursor;
		this (CType type, Cursor cursor) { mixin(S_TRACE);
			this.type = type;
			_cursor = cursor;
		}
		void create(SelectionEvent e) { mixin(S_TRACE);
			if (_itm.getSelection()) { mixin(S_TRACE);
				auto itm = _parent.selection;
				if (_putMode is MenuID.PutQuick) { mixin(S_TRACE);
					putQuick(isInsert);
					if (e) e.doit = false;
					return;
				}

				_parent.clearClickStart();
				_arrowMode = false;
				_cType = type;
				_evtTI = _itm;

				_comm.refreshToolBar();
				_comm.selContentTool.call(_arrowMode, _cType, _putMode, _autoOpen, _insertFirst);
			}
		}
		void middleClick() { putQuick(true); }
		private void putQuick(bool insert) { mixin(S_TRACE);
			auto itm = _parent.selection;
			if (_putMode !is MenuID.PutQuick || !itm) { mixin(S_TRACE);
				arrow();
				_itm.setSelection(false);
				return;
			}
			_cType = type;
			_evtTI = _itm;
			_parent.create(insert ? itm : null);
			_parent.clearClickStart();
			arrow();
			_itm.setSelection(false);
		}
		@property
		void ti(ToolItem ti) { mixin(S_TRACE);
			_itm = ti;
			auto listener = new class MouseAdapter {
				override void mouseUp(MouseEvent e) { mixin(S_TRACE);
					if (e.button != 2) return;
					auto itm = _itm.getParent().getItem(new Point(e.x, e.y));
					if (itm is _itm) { mixin(S_TRACE);
						middleClick();
					}
				}
			};
			_itm.getParent().addMouseListener(listener);
			.listener(_itm, SWT.Dispose, { mixin(S_TRACE);
				_itm.getParent().removeMouseListener(listener);
			});
		}
		@property
		ToolItem ti() {return _itm;}
	}
	private ToolItem createEI(CType type, ToolBar bar, ToolItemGroup g) { mixin(S_TRACE);
		auto img = _prop.images.content(type);
		auto cursor = _prop.images.cursor(type);
		_cursors ~= cursor;
		auto ce = new CreateEvent(type, cursor);
		auto itm = createToolItem2(_comm, bar, _prop.msgs.contentName(type), img, &ce.create, () => _parent.selection !is null && (!_summ || !_summ.legacy || !type.isWsnContent), SWT.RADIO);
		ce.ti = itm;
		g.append(itm);
		_conts[type] = ce;

		if (_prop.var.etc.showEventContentDescription) { mixin(S_TRACE);
			void refDataVersion() { mixin(S_TRACE);
				string desc;
				with (CType) switch (type) {
				case MOVE_BG_IMAGE:
				case REPLACE_BG_IMAGE:
				case LOSE_BG_IMAGE:
					if (!_summ.legacy) goto default;
					desc = .tryFormat(_prop.msgs.contentDescWsnN, _prop.msgs.contentDesc(type), "1");
					break;
				default:
					desc = _prop.msgs.contentDesc(type);
					break;
				}
				itm.setToolTipText(.format("%s\v%s", _prop.msgs.contentName(type), desc));
			}
			_comm.refDataVersion.add(&refDataVersion);
			.listener(itm, SWT.Dispose, { mixin(S_TRACE);
				_comm.refDataVersion.remove(&refDataVersion);
			});
			refDataVersion();
		}

		return itm;
	}

	private class TRDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			if (_comm.poolContentsToolBox(this.outer)) { mixin(S_TRACE);
				return;
			}
			disposeParent();
		}
	}
	private void disposeParent() {
		_comm.refEventTemplates.remove(&refreshTemplatesM);
		_comm.selContentTool.remove(&selContentTool);

		if (_toolWin) { mixin(S_TRACE);
			_toolWin.dispose();
		}
		if (_autoHideTools && !_autoHideTools.isDisposed()) { mixin(S_TRACE);
			if (_tcListener) { mixin(S_TRACE);
				_autoHideTools.getParent().removeControlListener(_tcListener);
			}
			_autoHideTools.dispose();
		}
	}

	private class TMListener : MouseAdapter {
		override void mouseUp(MouseEvent e) { mixin(S_TRACE);
			if (e.button == 3) { mixin(S_TRACE);
				arrow();
				_comm.refreshToolBar();
			}
		}
	}
	private static class PutScript {
		private string _script;
		private void delegate(string, bool) _pasteScript;
		private Image _img = null;
		this (Props prop, in Summary summ, string script, void delegate(string, bool) pasteScript) { mixin(S_TRACE);
			_script = script;
			_pasteScript = pasteScript;
			auto type = cwx.script.firstContentType(prop.parent, summ, _script);
			if (type != -1) { mixin(S_TRACE);
				_img = prop.images.content(type);
			}
		}
		void put(SelectionEvent se) { mixin(S_TRACE);
			_pasteScript(_script, (se.stateMask & SWT.SHIFT) != 0);
		}
		@property
		Image image() { mixin(S_TRACE);
			return _img;
		}
	}
	static void refreshTemplates(Commons comm, Props prop, Summary summ, Menu menu, Shell shell, bool delegate() enabled, void delegate(string, bool) pasteScript) { mixin(S_TRACE);
		foreach (itm; menu.getItems()) { mixin(S_TRACE);
			itm.dispose();
		}
		// 設定でコンパイルオプションが変化する可能性があるため事前コンパイルは行わない
		foreach (t; summ.eventTemplates) { mixin(S_TRACE);
			auto c = new PutScript(prop, summ, t.script, pasteScript);
			auto text = MenuProps.buildMenu(t.name, t.mnemonic, t.hotkey, false);
			createMenuItem2(comm, menu, text, c.image, &c.put, enabled);
		}
		if (prop.var.etc.eventTemplates.length && summ.eventTemplates.length) { mixin(S_TRACE);
			new MenuItem(menu, SWT.SEPARATOR);
		}
		foreach (t; prop.var.etc.eventTemplates) { mixin(S_TRACE);
			auto c = new PutScript(prop, summ, t.script, pasteScript);
			auto text = MenuProps.buildMenu(t.name, t.mnemonic, t.hotkey, false);
			createMenuItem2(comm, menu, text, c.image, &c.put, enabled);
		}
		if (prop.var.etc.eventTemplates.length || summ.eventTemplates.length) { mixin(S_TRACE);
			new MenuItem(menu, SWT.SEPARATOR);
		}
		createMenuItem(comm, menu, MenuID.EvTemplatesOfScenario, { comm.editScEventTemplate(shell); }, () => true);
	}
	private void refreshTemplatesM() { mixin(S_TRACE);
		refreshTemplates(_comm, _prop, _summ, _templMenu, _parent.widget.getShell(), () => _parent._et !is null, (string script, bool tryInsert) {
			_parent.pasteScript(script, tryInsert);
		});
		_templTI.setEnabled(0 < _templMenu.getItemCount());
	}

	private class TCListener : ControlAdapter {
		override void controlMoved(ControlEvent e) { mixin(S_TRACE);
			if (_autoHideTools) { mixin(S_TRACE);
				calcAutoHideSize();
				return;
			}
			assert (_toolWin);
			if (!_toolWin || _toolWin.isDisposed()) return;
			auto pb = _toolWin.getParent().getBounds();
			auto tb = _toolWin.getBounds();
			_toolWin.setBounds(tb.x + pb.x - _parX, tb.y + pb.y - _parY, tb.width, tb.height);
			_parX = pb.x;
			_parY = pb.y;
			saveToolWinPos();
		}
	}
	private class TWCListener : ControlAdapter {
		override void controlMoved(ControlEvent e) { mixin(S_TRACE);
			assert (_toolWin);
			if (!_toolWin || _toolWin.isDisposed()) return;
			saveToolWinPos();
		}
	}
	private class AHTCListener : ControlAdapter {
		override void controlResized(ControlEvent e) { mixin(S_TRACE);
			if (_autoHideTools.isDisposed()) return;
			if (!_autoHideTools.isVisible()) return;
			calcAutoHideSize();
		}
	}
	private class MouseTrack : Listener {
		override void handleEvent(Event e) { mixin(S_TRACE);
			auto c = cast(Control) e.widget;
			if (!c || !_autoHideTools) return;
			if (!_parent._et) { mixin(S_TRACE);
				_autoHideTools.setVisible(false);
				return;
			}
			if (e.type is SWT.MouseMove && _parent._contentsBoxArea.isVisible()) return;
			if (c !is _parent._tree.control && !isDescendant(_autoHideTools, c) && !isDescendant(_parent._contentsBoxArea, c)) { mixin(S_TRACE);
				_autoHideTools.setVisible(false);
				return;
			}
			auto p = c.toDisplay(e.x, e.y);
			auto ca2 = _autoHideTools.getBounds();
			ca2.x = 0;
			ca2.y = 0;
			if (!_autoHideTools.isVisible()) { mixin(S_TRACE);
				ca2.width = 0;
				ca2.height = 0;
			}
			auto p2 = _autoHideTools.toControl(p);
			auto ca1 = _parent._contentsBoxArea.getBounds();
			ca1.x = 0;
			ca1.y = 0;
			if (0 == ca1.height) { mixin(S_TRACE);
				ca1.height = _prop.var.etc.showContentsBoxHeightWhenNoToolBar;
			}
			auto p1 = _parent._contentsBoxArea.toControl(p);
			if (ca1.contains(p1) || ca2.contains(p2)) { mixin(S_TRACE);
				if (e.type is SWT.MouseUp && _autoHideTools.isVisible()) { mixin(S_TRACE);
				_autoHideTools.setVisible(false);
 				} else if ((e.type is SWT.MouseUp || _parent._tree.control.isFocusControl()) && !_autoHideTools.isVisible()) { mixin(S_TRACE);
					calcAutoHideSize();
					_autoHideTools.setVisible(true);
				}
			} else { mixin(S_TRACE);
				_autoHideTools.setVisible(false);
			}
		}
	}
	private class TSListener : ShellAdapter {
		public override void shellClosed(ShellEvent e) { mixin(S_TRACE);
			assert (_toolWin);
			if (_toolWin.isDisposed()) return;
			_toolWin.setVisible(false);
			e.doit = false;
		}
	}

	this (EventTreeView parent) {
		_comm = parent._comm;
		_prop = parent._prop;
		_summ = parent._summ;
		_parent = parent;

		Composite cbarPar;
		if (_prop.var.etc.contentsFloat) { mixin(S_TRACE);
			_toolWin = new Shell(parent.widget.getShell(), SWT.TITLE | SWT.RESIZE | SWT.TOOL);
			_toolWin.setLayout(zeroGridLayout(1));
			_toolWin.setText(_prop.msgs.tools);
			_toolWin.addShellListener(new TSListener);
			cbarPar = new Composite(_toolWin, SWT.NONE);
			cbarPar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		} else if (_prop.var.etc.contentsAutoHide) { mixin(S_TRACE);
			_autoHideTools = new Shell(parent.widget.getShell(), SWT.NO_TRIM);
			_autoHideTools.setLayout(zeroGridLayout(1));
			cbarPar = new Composite(_autoHideTools, SWT.NONE);
			cbarPar.setLayoutData(new GridData(GridData.FILL_BOTH));
			_mTrack = new MouseTrack;
			_autoHideTools.getDisplay().addFilter(SWT.MouseUp, _mTrack);
			_autoHideTools.getDisplay().addFilter(SWT.MouseEnter, _mTrack);
			_autoHideTools.getDisplay().addFilter(SWT.MouseExit, _mTrack);
			.listener(_autoHideTools, SWT.Dispose, {
				_autoHideTools.getDisplay().removeFilter(SWT.MouseUp, _mTrack);
				_autoHideTools.getDisplay().removeFilter(SWT.MouseEnter, _mTrack);
				_autoHideTools.getDisplay().removeFilter(SWT.MouseExit, _mTrack);
			});
		} else {
			cbarPar = _parent.boxOwner;
		}
		cbarPar.setLayout(new FillLayout);
		_disposeParent = new TRDListener;

		_arrowMode = _parent._arrowMode;
		_cType = _parent._cType;

		_autoOpen = _prop.var.etc.contentsAutoOpen;
		switch (_prop.var.etc.contentsPutMode.value) {
		case 0:
			_putMode = MenuID.PutQuick;
			break;
		case 1:
			_putMode = MenuID.PutSelect;
			break;
		case 2:
			_putMode = MenuID.PutContinue;
			break;
		default:
			_putMode = MenuID.PutSelect;
		}
		_insertFirst = _prop.var.etc.contentsInsertFirst;

		auto shiftCaptcha = new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				if (e.type == SWT.KeyUp && e.keyCode == SWT.SHIFT) { mixin(S_TRACE);
					_shiftDown = false;
				} else if (e.type == SWT.KeyDown && e.keyCode == SWT.SHIFT) { mixin(S_TRACE);
					_shiftDown = true;
				} else if (e.type == SWT.KeyUp && e.keyCode == SWT.CTRL) { mixin(S_TRACE);
					_ctrlDown = false;
				} else if (e.type == SWT.KeyDown && e.keyCode == SWT.CTRL) { mixin(S_TRACE);
					_ctrlDown = true;
				} else if (e.type == SWT.KeyUp && e.keyCode == SWT.ALT) { mixin(S_TRACE);
					_altDown = false;
				} else if (e.type == SWT.KeyDown && e.keyCode == SWT.ALT) { mixin(S_TRACE);
					_altDown = true;
				}
			}
		};
		_comm.refEventTemplates.add(&refreshTemplatesM);
		_comm.selContentTool.add(&selContentTool);

		Label[] labels;
		_cbar = createCoolBar!("contents")(_comm, cbarPar, (CoolBar cbar) { mixin(S_TRACE);
			void createCoolItem(CoolBar cbar, ToolBar tbar, int index = -1) { mixin(S_TRACE);
				.createCoolItem(cbar, tbar, index);
			}
			if (!_prop.var.etc.contentsFloat || _autoHideTools) { mixin(S_TRACE);
				cbar.addMouseListener(new TMListener);
			}
			auto g = new ToolItemGroup;
			_radioGroup = g;

			auto atm = new ToolBar(cbar, SWT.FLAT);
			atm.addMouseListener(new TMListener);
			_arrowTI = createToolItem2(_comm, atm, _prop.msgs.evtArrow, _prop.images.evtArrow, &arrow, null, SWT.RADIO);
			if (_putMode !is MenuID.PutQuick) _arrowTI.setSelection(true);
			g.append(_arrowTI);
			createCoolItem(cbar, atm);

			auto mode = new ToolBar(cbar, SWT.FLAT);
			mode.addMouseListener(new TMListener);
			Menu putModeMenu;
			void delegate() dlg = null;
			_putModeTI = createDropDownItem2(_comm, mode, _prop.msgs.menuText(_putMode), _prop.images.menu(_putMode), dlg, putModeMenu, MenuID.None, null);
			_putQuickMI = createMenuItem(_comm, putModeMenu, MenuID.PutQuick, &updatePutMode, null, SWT.RADIO);
			_putSelectMI = createMenuItem(_comm, putModeMenu, MenuID.PutSelect, &updatePutMode, null, SWT.RADIO);
			_putContinueMI = createMenuItem(_comm, putModeMenu, MenuID.PutContinue, &updatePutMode, null, SWT.RADIO);
			_autoOpenTI = createToolItem2(_comm, mode, _prop.msgs.evtAutoOpen, _prop.images.evtAutoOpen, &autoOpen, null, SWT.CHECK);
			_autoOpenTI.setSelection(_autoOpen);
			_insertFirstTI = createToolItem2(_comm, mode, _prop.msgs.evtInsertFirst, _prop.images.evtInsertFirst, &insertFirst, null, SWT.CHECK);
			_insertFirstTI.setSelection(_insertFirst);
			new ToolItem(mode, SWT.SEPARATOR);
			_templTI = createDropDownItem(_comm, mode, MenuID.EvTemplates, null, _templMenu, () => _summ && _parent._et && (_prop.var.etc.eventTemplates.length || _summ.eventTemplates.length));

			_putQuickMI.setSelection(_putMode is MenuID.PutQuick);
			_putSelectMI.setSelection(_putMode is MenuID.PutSelect);
			_putContinueMI.setSelection(_putMode is MenuID.PutContinue);
			refreshTemplatesM();
			createCoolItem(cbar, mode);

			auto tml = new TMListener;
			foreach (cGrp; EnumMembers!CTypeGroup) { mixin(S_TRACE);
				auto cs = CTYPE_GROUP[cGrp];
				auto eBar = new ToolBar(cbar, SWT.FLAT);
				eBar.addMouseListener(tml);
				if (_prop.var.etc.showContentsGroupName) { mixin(S_TRACE);
					auto menuID = cTypeGroupToMenuID(cGrp);
					labels ~= createLabel(eBar, _prop.msgs.menuText(menuID), WGL_SPACING.ppis);
				}
				foreach (cType; cs) { mixin(S_TRACE);
					createEI(cType, eBar, g);
				}
				if (cGrp is CTypeGroup.Visual) { mixin(S_TRACE);
					createCoolItem(cbar, eBar, 3);
				} else { mixin(S_TRACE);
					createCoolItem(cbar, eBar);
				}
				if (_prop.var.etc.showEventContentDescription) { mixin(S_TRACE);
					.setupToolTips(eBar, _prop);
				}
				_comm.put(eBar);
			}
			updatePutMode();
		}, (menu) { mixin(S_TRACE);
			foreach (l; labels) { mixin(S_TRACE);
				l.setMenu(menu);
			}
		});
		_cbar.addMouseListener(new TMListener);
		_cbar.getDisplay().addFilter(SWT.KeyDown, shiftCaptcha);
		_cbar.getDisplay().addFilter(SWT.KeyUp, shiftCaptcha);
		.listener(_cbar, SWT.Dispose, { mixin(S_TRACE);
			_cbar.getDisplay().removeFilter(SWT.KeyDown, shiftCaptcha);
			_cbar.getDisplay().removeFilter(SWT.KeyUp, shiftCaptcha);
		});

		if (_toolWin) { mixin(S_TRACE);
			auto dummy = new Composite(_toolWin, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.heightHint = 0;
			dummy.setLayoutData(gd);
			_toolWin.setVisible(false);
			auto sb = _parent.boxOwner.getShell().toDisplay(0, 0);
			auto eParent = _parent._contentsBoxArea;
			while (!cast(TLPData)eParent.getData()) eParent = eParent.getParent();
			eParent = eParent.getParent();
			auto tb = eParent.toDisplay(0, 0);
			auto pb = _parent.boxOwner.getShell().getLocation();
			pb.x += tb.x - sb.x;
			pb.y += tb.y - sb.y;

			auto size = _toolWin.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			auto ts = _toolWin.getBounds();
			int tx = _prop.var.contentsWin.x == SWT.DEFAULT ? ts.x : pb.x + _prop.var.contentsWin.x;
			int ty = _prop.var.contentsWin.y == SWT.DEFAULT ? ts.y : pb.y + _prop.var.contentsWin.y;
			intoDisplay(tx, ty, size.x, size.y);
			auto tpb = _toolWin.getParent().getBounds();
			_parX = tpb.x;
			_parY = tpb.y;
			_toolWin.setBounds(tx, ty, size.x, size.y);
			_toolWin.getParent().addControlListener(new TCListener);
			_toolWin.addControlListener(new TWCListener);
		} else if (cbarPar) { mixin(S_TRACE);
			if (_autoHideTools) { mixin(S_TRACE);
				_autoResize = new AHTCListener;
				_tcListener = new TCListener;
				_autoHideTools.getParent().addControlListener(_tcListener);
			}
		}

		updateCursor();
		if (!_arrowMode) {
			_evtTI = _conts[_cType].ti;
			_radioGroup.select(_evtTI);
		}
		_parent._box = this;
		addListenersToOwner();
		relayout();
	}

	void dispose() { mixin(S_TRACE);
		removeListenersToOwner();
		_cbar.dispose();
		disposeParent();
		_parent._box = null;
	}

	private void addListenersToOwner() { mixin(S_TRACE);
		if (_autoHideTools) {
			owner.boxOwner.addControlListener(_autoResize);
		}
		owner.boxOwner.addDisposeListener(_disposeParent);
	}
	private void removeListenersToOwner() { mixin(S_TRACE);
		if (_autoHideTools) {
			owner.boxOwner.removeControlListener(_autoResize);
		}
		owner.boxOwner.removeDisposeListener(_disposeParent);
	}
	private void relayout() { mixin(S_TRACE);
		if (isSingleton) { mixin(S_TRACE);
			auto parGd = new GridData(GridData.FILL_HORIZONTAL);
			parGd.heightHint = 0;
			_parent.boxOwner.setLayoutData(parGd);
			_parent.boxOwner.getParent().layout();
		} else {
			_cbar.setParent(_parent.boxOwner);
			_parent.boxOwner.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_parent.boxOwner.getParent().layout();
			_parent.boxOwner.layout();
		}
	}

	@property
	void owner(EventTreeView owner) { mixin(S_TRACE);
		auto shell1 = _parent.widget.getShell();
		auto shell2 = owner.widget.getShell();
		removeListenersToOwner();
		_parent._box = null;
		_parent = owner;
		owner._box = this;
		relayout();
		addListenersToOwner();
	}
	@property
	EventTreeView owner() { return _parent; }

	@property
	const
	bool isSingleton() {
		return _prop.var.etc.contentsAutoHide || _prop.var.etc.contentsFloat;
	}

	private void calcAutoHideSize() { mixin(S_TRACE);
		if (!_autoHideTools) return;
		auto tb = _parent._tree.control.getBounds();
		auto ca1 =_parent. _contentsBoxArea.getBounds();
		int x = _parent._tree.control.toDisplay(tb.x, tb.y).x;
		int y = _parent._contentsBoxArea.toDisplay(0, ca1.y).y + ca1.height;
		auto size = _autoHideTools.computeSize(tb.width, SWT.DEFAULT);
		_autoHideTools.setBounds(new Rectangle(x, y, size.x, size.y));
	}
	private void saveToolWinPos() { mixin(S_TRACE);
		assert (_toolWin);
		if (_toolWin.isDisposed()) return;
		auto sb = _parent.boxOwner.getShell().toDisplay(0, 0);
		auto eParent = _parent._contentsBoxArea;
		while (!cast(TLPData)eParent.getData()) eParent = eParent.getParent();
		eParent = eParent.getParent();
		auto tb = eParent.toDisplay(0, 0);
		auto pb = _parent.boxOwner.getShell().getLocation();
		pb.x += tb.x - sb.x;
		pb.y += tb.y - sb.y;
		_prop.var.contentsWin.x = _toolWin.getBounds().x - pb.x;
		_prop.var.contentsWin.y = _toolWin.getBounds().y - pb.y;
	}
	private void openToolWindow() { mixin(S_TRACE);
		if (_toolWin) { mixin(S_TRACE);
			if (_toolWin.isDisposed()) return;
			if (_parent._et) { mixin(S_TRACE);
				if (_opened) { mixin(S_TRACE);
					_toolWin.setVisible(true);
				} else { mixin(S_TRACE);
					_opened = true;
					_toolWin.setVisible(true);
				}
			} else {
				closeToolWindow();
			}
		}
		_comm.refreshToolBar();
	}
	private void closeToolWindow() { mixin(S_TRACE);
		// 別ウィンドウで表示している場合は閉じない
		if (_autoHideTools) { mixin(S_TRACE);
			_autoHideTools.setVisible(false);
		}
	}
}
