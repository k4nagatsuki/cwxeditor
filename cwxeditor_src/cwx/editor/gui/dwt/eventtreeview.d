
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

import std.ascii;
import std.algorithm;
import std.conv;
import std.string;
import std.datetime;

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
	EventTree _et;
	ContentsToolBox _box;
	Menu _createM = null;
	Menu _convM = null;
	Menu _evTemplM = null;
	Converter[CType] _conts;

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
		foreach (cGrp, cs; CTYPE_GROUP) { mixin(S_TRACE);
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
	private void initCreateMenu(CType type, Menu menu, string text, Image img) {
		createMenuItem2(_comm, menu, text, img, {
			if (!_box) return;
			auto itm = selection;
			bool insert = _box && _box._shiftDown;
			auto oldType = _box._cType;
			_box._cType = type;
			scope (exit) _box._cType = oldType;
			auto oldMode = _box._putMode;
			_box._putMode = MenuID.PutQuick;
			scope (exit) _box._putMode = oldMode;
			create(insert ? itm : null);
		}, () => _et !is null);
	}
	private void initConvMenu(CType type, Menu convMenu, string text, Image img) { mixin(S_TRACE);
		auto ce = _conts[type];
		if (type != CType.START) { mixin(S_TRACE);
			ce.convMenuItem = createMenuItem2(_comm, convMenu, text, img, &ce.convert, null);
			ce.convMenuItem.setEnabled(false);
		}
	}
	private bool canConvTerminal() { mixin(S_TRACE);
		auto itm = selection;
		if (!itm) return false;
		auto evt = cast(Content) itm.getData();
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
			auto c = cast(Content) sel.getData();
			if (c.type == type) return;
			store(c);
			_comm.delContent.call(c);
			assert (c.canConvert(type), "convert menu item enabled");
			auto oldd = c.detail;
			c.convertType(type, _prop.parent);
			auto newd = c.detail;
			if (newd.use(CArg.BG_IMAGES) && !oldd.use(CArg.BG_IMAGES)) { mixin(S_TRACE);
				c.backs = createBgImages(summSkin, _prop.var.etc.bgImagesDefault);
			}
			if (newd.use(CArg.DIALOGS) && !oldd.use(CArg.DIALOGS)) { mixin(S_TRACE);
				c.dialogs = [new SDialog];
			}
			sel.setImage(_prop.images.content(type));
			foreach (itm; _tree.getItems(sel)) { mixin(S_TRACE);
				itm.setText(eventText(c, cast(Content) itm.getData()));
				procTreeItem(itm);
			}
			procTreeItem(sel);
			refreshStatusLine();
			redraw();
			_comm.refUseCount.call();
			_comm.refreshToolBar();
		}
	}

	@property
	Item selection() { mixin(S_TRACE);
		if (!_tree.control || _tree.control.isDisposed()) return null;
		auto sels = _tree.getSelection();
		if (sels.length > 0) { mixin(S_TRACE);
			return sels[0];
		}
		return null;
	}

	class EditL : MouseAdapter, KeyListener {
		private void __edit() { mixin(S_TRACE);
			if (_readOnly) return;
			edit();
		}
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			if (e.character == SWT.CR) { mixin(S_TRACE);
				__edit();
			}
		}
		override void keyReleased(KeyEvent e) {}
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (e.button == 1 && !_tree.control.getCursor()) { mixin(S_TRACE);
				__edit();
			}
		}
		override void mouseUp(MouseEvent e) { mixin(S_TRACE);
			if (e.button == 1 && _clickStart) { mixin(S_TRACE);
				__edit();
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
		if (_tree.control.getToolTipText() != toolTip) { mixin(S_TRACE);
			_tree.control.setToolTipText(toolTip);
		}
	}

	UndoManager _undo;
	abstract static class ETVUndo : Undo {
		private size_t[] _etPath;
		private size_t[] _selPath = null, _selPath2 = null;
		protected EventTree et;
		protected Commons comm;
		protected Props prop;
		protected Summary summ;
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et) { mixin(S_TRACE);
			this.et = et;
			this.comm = comm;
			this.prop = prop;
			this.summ = summ;
			_etPath = et.areaPath;
			if (v) { mixin(S_TRACE);
				auto sel = v.selection;
				_selPath = sel ? (cast(Content) sel.getData()).ctPath : null;
			}
		}
		void udb(EventTreeView v) { mixin(S_TRACE);
			if (!v) return;
			.forceFocus(v._tree.control, false);
			v._forceSel(_etPath);
			auto sel = v.selection;
			_selPath2 = sel ? (cast(Content) sel.getData()).ctPath : null;
		}
		void uda(EventTreeView v) { mixin(S_TRACE);
			scope (exit) comm.refreshToolBar();
			if (!v) return;
			if (_selPath) v._tree.select(v.fromPath(_selPath));
			_selPath = _selPath2;
			v.refreshStatusLine();
		}
		EventTreeView view() { mixin(S_TRACE);
			return comm.eventTreeViewFrom(et.cwxPath(true), false);
		}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
	}
	private static void insertStart(EventTreeView v, Commons comm, EventTree et, int index, Content c) { mixin(S_TRACE);
		if (v) v._tree.control.setRedraw(false);
		scope (exit) if (v) v._tree.control.setRedraw(true);
		bool empty = et.owner.isEmpty;
		scope (exit) {
			if (empty != et.owner.isEmpty) comm.refEventTree.call(et);
		}
		et.insert(index, c);
		if (v) { mixin(S_TRACE);
			if (v._tree.tree) { mixin(S_TRACE);
				auto itm = createTreeItem(v._tree.tree, c, c.name, v._prop.images.content(c.type), index);
				v.createChilds(itm, c);
				v._tree.setExpanded(itm, true);
			} else { mixin(S_TRACE);
				v._tree.editor.updateEventTree();
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
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et, Content[] cs) { mixin(S_TRACE);
			super (v, comm, prop, summ, et);
			foreach (c; cs) { mixin(S_TRACE);
				_path ~= c.ctPath;
				_c ~= c.dup;
				_c[$ - 1].setUseCounter(summ.useCounter.sub);
			}
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			bool empty = et.owner.isEmpty;
			scope (exit) {
				if (empty != et.owner.isEmpty) comm.refEventTree.call(et);
			}
			foreach (i, c; _c.dup) { mixin(S_TRACE);
				int index = _path[i][$ - 1];
				auto tc = et.fromPath(_path[i]);
				if (c.type == CType.START) { mixin(S_TRACE);
					et.startUseCounter.change(tc.name, c.name);
				}
				_c[i] = tc.dup;
				_c[i].setUseCounter(summ.useCounter.sub);
				auto pc = tc.parent;
				string text;
				if (pc) { mixin(S_TRACE);
					pc.insert(prop.parent, index, c);
					text = .eventText(comm, summ, pc, c, false);
				} else { mixin(S_TRACE);
					et.insert(index, c);
					text = c.name;
				}
				if (v) v._tree.control.setRedraw(false);
				scope (exit) if (v) v._tree.control.setRedraw(true);
				if (v) { mixin(S_TRACE);
					if (v._tree.tree) { mixin(S_TRACE);
						auto now = cast(TreeItem)v.fromPath(_path[i]);
						auto par = now.getParentItem();
						TreeItem itm;
						if (par) { mixin(S_TRACE);
							itm = createTreeItem(par, c, text, prop.images.content(c.type), index);
						} else { mixin(S_TRACE);
							itm = createTreeItem(v._tree.tree, c, text, prop.images.content(c.type), index);
						}
						v.procTreeItem(itm);
						v.createChilds(itm, c);
						v._tree.setExpanded(itm, true);
					} else { mixin(S_TRACE);
						v._tree.editor.updateEventTree();
					}
				}
				delImpl(v, comm, et, tc);
				if (v && !pc) { mixin(S_TRACE);
					v._refreshTopStart();
				}
			}
			if (v) v.refreshStatusLine();
			comm.refUseCount.call();
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() { mixin(S_TRACE);
			foreach (c; _c) { mixin(S_TRACE);
				c.removeUseCounter();
			}
		}
	}
	void store(Content[] evt ...) { mixin(S_TRACE);
		_undo ~= new UndoContent(this, _comm, _prop, _summ, _et, evt);
	}
	static class UndoSwap : ETVUndo {
		private int _upIndex;
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et, int swapIndex1, int swapIndex2) { mixin(S_TRACE);
			super (v, comm, prop, summ, et);
			_upIndex = swapIndex1 > swapIndex2 ? swapIndex1 : swapIndex2;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			udImpl!(-1)(v, comm, et, et.starts[_upIndex], false);
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {}
	}
	void storeSwap(int swapIndex1, int swapIndex2) { mixin(S_TRACE);
		_undo ~= new UndoSwap(this, _comm, _prop, _summ, _et, swapIndex1, swapIndex2);
	}
	static class UndoInsert : ETVUndo {
		private int _index;
		private size_t _count;
		private Content[] _c;
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et, int index, size_t count) { mixin(S_TRACE);
			super (v, comm, prop, summ, et);
			_index = index;
			_count = count;
		}
		override void undo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (v) v._tree.control.setRedraw(false);
			scope (exit) if (v) v._tree.control.setRedraw(true);
			for (size_t i = 0; i < _count; i++) { mixin(S_TRACE);
				auto node = et.starts[_index].toNode(new XMLOption(prop.sys));
				auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
				auto c = Content.createFromNode(node, ver);
				c.setUseCounter(summ.useCounter.sub);
				_c ~= c;
				delImpl(v, comm, et, et.starts[_index]);
			}
			comm.refUseCount.call();
			if (v) { mixin(S_TRACE);
				v.refreshStatusLine();
				v._refreshTopStart();
			}
		}
		override void redo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			foreach_reverse (c; _c) { mixin(S_TRACE);
				insertStart(v, comm, et, _index, c);
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
		_undo ~= new UndoInsert(this, _comm, _prop, _summ, _et, insertIndex, count);
	}
	static class UndoDelete : ETVUndo {
		private int _index;
		private Content _c;
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et, int index, Content del) { mixin(S_TRACE);
			super (v, comm, prop, summ, et);
			_index = index;
			auto node = del.toNode(new XMLOption(prop.sys));
			auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
			_c = Content.createFromNode(node, ver);
			_c.setUseCounter(summ.useCounter.sub);
		}
		override void undo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			insertStart(v, comm, et, _index, _c);
		}
		override void redo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (v) v._tree.control.setRedraw(false);
			scope (exit) if (v) v._tree.control.setRedraw(true);
			delImpl(v, comm, et, et.starts[_index]);
			comm.refUseCount.call();
			if (v) { mixin(S_TRACE);
				v.refreshStatusLine();
				v._refreshTopStart();
			}
		}
		override void dispose() { mixin(S_TRACE);
			_c.removeUseCounter();
		}
	}
	void storeDelete(int index, Content del) { mixin(S_TRACE);
		_undo ~= new UndoDelete(this, _comm, _prop, _summ, _et, index, del);
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
		auto itm = _tree.getItem(tree, cpindex(cwxPath));
		cwxPath = cpbottom(cwxPath);
		if (cpempty(cwxPath)) return itm;
		return fromPathImpl(itm, cwxPath);
	}
	private Item fromPath(size_t[] path) { mixin(S_TRACE);
		return fromPathImpl(_tree, path);
	}
	private Item fromPathImpl(T)(T tree, size_t[] path) { mixin(S_TRACE);
		if (!path.length) return null;
		auto itm = _tree.getItem(tree, path[0]);
		if (path.length == 1) return itm;
		return fromPathImpl(itm, path[1 .. $]);
	}
	static class UndoCP : Undo {
		private UndoContent _undoC;
		private UndoDelete _undoD;
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et, Content[] conts, int index, Content start) { mixin(S_TRACE);
			_undoC = new UndoContent(v, comm, prop, summ, et, conts);
			_undoD = new UndoDelete(v, comm, prop, summ, et, index, start);
		}
		override void undo() { mixin(S_TRACE);
			_undoD.undo();
			_undoC.undo();
		}
		override void redo() { mixin(S_TRACE);
			_undoC.redo();
			_undoD.redo();
		}
		override void dispose() { mixin(S_TRACE);
			_undoC.dispose();
			_undoD.dispose();
		}
	}
	static class UndoContentAndInsert : ETVUndo {
		private UndoContent _undoC;
		private UndoInsert _undoI;
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et, Content owner, int insertIndex, int count) { mixin(S_TRACE);
			super (v, comm, prop, summ, et);
			_undoC = new UndoContent(v, comm, prop, summ, et, [owner]);
			_undoI = new UndoInsert(v, comm, prop, summ, et, insertIndex, count);
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
		_undo ~= new UndoContentAndInsert(this, _comm, _prop, _summ, _et, owner, insertIndex, count);
	}

	private EventDialog[Content] _editDlgs;
	void appliedEdit(UndoContent undo, Content c) { mixin(S_TRACE);
		_undo ~= undo;
		auto itm = fromPath(c.cwxPath(true));
		assert (c is itm.getData());
		foreach (childItm; _tree.getItems(itm)) { mixin(S_TRACE);
			auto par = cast(Content)itm.getData();
			assert (par.detail.owner);
			childItm.setText(eventText(par, cast(Content) childItm.getData()));
			procTreeItem(childItm);
		}
		procTreeItem(itm);
		_tree.select(itm);
		.forceFocus(_tree.control, false);
		redraw();
		_comm.refContent.call(c);
		_comm.refUseCount.call();
		refreshStatusLine();
		_comm.refreshToolBar();
	}
	void editM() {edit();}
	public EventDialog edit() { mixin(S_TRACE);
		if (_readOnly) return null;
		auto sels = _tree.getSelection();
		if (sels.length > 0) { mixin(S_TRACE);
			auto c = cast(Content) sels[0].getData();
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
					Item sItm;
					if (_tree.tree) { mixin(S_TRACE);
						sItm = createTreeItem(_tree.tree, evt, evt.name, _prop.images.content(CType.START), index);
					} else { mixin(S_TRACE);
						_tree.editor.updateEventTree();
						sItm = EventEditorItem.valueOf(_tree.editor, evt);
					}
					_tree.select(sItm);
					_tree.showSelection();
					.forceFocus(_tree.control, false);
					_comm.refContent.call(evt);
					refreshStatusLine();
					if (_box._putMode !is MenuID.PutContinue) _box.arrow();
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
					void applied(Content evt) { mixin(S_TRACE);
						bool empty = _et.owner.isEmpty;
						scope (exit) {
							if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
						}
						store(owner);
						if (insertIndex == -1) { mixin(S_TRACE);
							if (_box._insertFirst) { mixin(S_TRACE);
								owner.insert(_prop.parent, 0, evt);
							} else { mixin(S_TRACE);
								owner.add(_prop.parent, evt);
							}
						} else { mixin(S_TRACE);
							owner.insert(_prop.parent, insertIndex, evt);
						}
						Item itm;
						if (_tree.tree) { mixin(S_TRACE);
							itm = createTreeItem(cast(TreeItem)oItm, evt, eventText(owner, evt), _prop.images.content(evt.type), insertIndex);
							_tree.setExpanded(oItm, true);
						} else { mixin(S_TRACE);
							_tree.editor.updateEventTree();
							itm = EventEditorItem.valueOf(_tree.editor, evt);
						}
						_tree.setSelection([itm]);
						if (insertTo) { mixin(S_TRACE);
							auto ic = cast(Content) insertTo.getData();
							_comm.delContent.call(ic);
							ic.parent.remove(ic);
							if (_prop.var.etc.adjustContentName) { mixin(S_TRACE);
								ic.setName(_prop.parent, "");
							}
							if (_box._insertFirst) { mixin(S_TRACE);
								evt.insert(_prop.parent, 0, ic);
							} else { mixin(S_TRACE);
								evt.add(_prop.parent, ic);
							}
							insertTo.dispose();
							createChilds(itm, evt);
							_tree.setExpanded(itm, true);
						}
						procTreeItem(itm);
						_tree.showSelection();
						.forceFocus(_tree.control, false);
						_comm.refContent.call(evt);
						_comm.refUseCount.call();
						refreshStatusLine();
						if (_box._putMode !is MenuID.PutContinue) _box.arrow();
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

	bool hasDialog(CType type) { mixin(S_TRACE);
		switch (type) {
		case CType.START:
		case CType.END_BAD_END:
		case CType.EFFECT_BREAK:
		case CType.ELAPSE_TIME:
		case CType.BRANCH_AREA:
		case CType.BRANCH_BATTLE:
		case CType.BRANCH_IS_BATTLE:
		case CType.SHOW_PARTY:
		case CType.HIDE_PARTY:
			return false;
		default:
			return true;
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
			return _summ.flagDirRoot.allSteps.length > 0;
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
		} default: { mixin(S_TRACE);
			return true;
		}
		}
	}

	void create(Content parent, CType type, string name, void delegate(Content) applied) { mixin(S_TRACE);
		if (!_box) return;
		if (_readOnly) return;
		assert (parent is null || parent.detail.owner);
		if (_box._putMode !is MenuID.PutContinue) { mixin(S_TRACE);
			_box.arrow();
			_comm.refreshToolBar();
		}
		void initial(Content c) { mixin(S_TRACE);
			if (type is CType.CHANGE_BG_IMAGE) { mixin(S_TRACE);
				c.backs = createBgImages(summSkin, _prop.var.etc.bgImagesDefault);
			} else if (type is CType.TALK_DIALOG) { mixin(S_TRACE);
				c.dialogs = [new SDialog];
			} else if (type is CType.BRANCH_SKILL || type is CType.BRANCH_ITEM || type is CType.BRANCH_BEAST) { mixin(S_TRACE);
				c.range = Range.FIELD;
			} else if (type is CType.LOSE_SKILL || type is CType.LOSE_ITEM || type is CType.LOSE_BEAST) { mixin(S_TRACE);
				c.range = Range.FIELD;
			}
		}
		if (hasDialog(type)) { mixin(S_TRACE);
			if (!_box._autoOpen || !checkOpenDialog(type)) { mixin(S_TRACE);
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
					foreach (start; _et.starts) { mixin(S_TRACE);
						if (icmp(start.name, name) == 0) return false;
					}
					return true;
				});
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

			auto undo = new UndoContent(this, _comm, _prop, _summ, _et, [evt]);
			dlg.appliedEvent.length = 0;
			dlg.appliedEvent ~= { mixin(S_TRACE);
				appliedEdit(undo, evt);
				undo = new UndoContent(this, _comm, _prop, _summ, _et, [evt]);
			};
		};
		_editDlgs[evt] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgs.remove(evt);
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
		auto p = evt in _editDlgs;
		if (p) { mixin(S_TRACE);
			p.active();
			return *p;
		}
		auto dlg = createEventDialog(evt, evt.parent, false);
		auto undo = new UndoContent(this, _comm, _prop, _summ, _et, [evt]);
		dlg.appliedEvent ~= { mixin(S_TRACE);
			appliedEdit(undo, evt);
			undo = new UndoContent(this, _comm, _prop, _summ, _et, [evt]);
		};
		_editDlgs[evt] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgs.remove(evt);
		};
		dlg.open();
		return dlg;
	}

	EventDialog createEventDialog(Content evt, Content parent, bool create) {
		EventDialog dlg;
		switch (evt.type) {
		case CType.START_BATTLE: { mixin(S_TRACE);
			dlg = new AreaSelectDialog!(CType.START_BATTLE, Battle, "summary.battles")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.END: { mixin(S_TRACE);
			dlg = new ClearEventDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CHANGE_AREA: { mixin(S_TRACE);
			dlg = new AreaSelectDialog!(CType.CHANGE_AREA, Area, "summary.areas")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CHANGE_BG_IMAGE: { mixin(S_TRACE);
			if (create) { mixin(S_TRACE);
				evt.backs = createBgImages(summSkin, _prop.var.etc.bgImagesDefault);
			}
			dlg = new BgImagesDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, refTarget, CType.CHANGE_BG_IMAGE);
			break;
		} case CType.EFFECT: { mixin(S_TRACE);
			dlg = new EffectDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LINK_START: { mixin(S_TRACE);
			dlg = new StartSelectDialog!(CType.LINK_START)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LINK_PACKAGE: { mixin(S_TRACE);
			dlg = new AreaSelectDialog!(CType.LINK_PACKAGE, Package, "summary.packages")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.TALK_MESSAGE: { mixin(S_TRACE);
			dlg = new MessageDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.TALK_DIALOG: { mixin(S_TRACE);
			dlg = new SpeakDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.PLAY_BGM: { mixin(S_TRACE);
			dlg = new BgmDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.PLAY_SOUND: { mixin(S_TRACE);
			dlg = new SeDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.WAIT: { mixin(S_TRACE);
			dlg = new WaitEventDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CALL_START: { mixin(S_TRACE);
			dlg = new StartSelectDialog!(CType.CALL_START)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CALL_PACKAGE: { mixin(S_TRACE);
			dlg = new AreaSelectDialog!(CType.CALL_PACKAGE, Package, "summary.packages")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_FLAG: { mixin(S_TRACE);
			dlg = new BrFlagDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_MULTI_STEP: { mixin(S_TRACE);
			dlg = new BrStepNDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_STEP: { mixin(S_TRACE);
			dlg = new BrStepULDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_SELECT: { mixin(S_TRACE);
			dlg = new BrMemberDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_ABILITY: { mixin(S_TRACE);
			dlg = new BrPowerDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_RANDOM: { mixin(S_TRACE);
			dlg = new BrRandomEventDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_LEVEL: { mixin(S_TRACE);
			dlg = new BrLevelDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_STATUS: { mixin(S_TRACE);
			dlg = new BrStateDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_PARTY_NUMBER: { mixin(S_TRACE);
			dlg = new BrNumEventDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_CAST: { mixin(S_TRACE);
			dlg = new AreaSelectDialog!(CType.BRANCH_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_ITEM: { mixin(S_TRACE);
			dlg = new BrItemDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_SKILL: { mixin(S_TRACE);
			dlg = new BrSkillDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_INFO: { mixin(S_TRACE);
			dlg = new AreaSelectDialog!(CType.BRANCH_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_BEAST: { mixin(S_TRACE);
			dlg = new BrBeastDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_MONEY: { mixin(S_TRACE);
			dlg = new MoneyEventDialog!(CType.BRANCH_MONEY)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_COUPON: { mixin(S_TRACE);
			dlg = new BranchCouponDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_COMPLETE_STAMP: { mixin(S_TRACE);
			dlg = new EndEventDialog!(CType.BRANCH_COMPLETE_STAMP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_GOSSIP: { mixin(S_TRACE);
			dlg = new GossipEventDialog!(CType.BRANCH_GOSSIP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.SET_FLAG: { mixin(S_TRACE);
			dlg = new FlagSetDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP: { mixin(S_TRACE);
			dlg = new StepSetDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP_UP: { mixin(S_TRACE);
			dlg = new StepPlusDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP_DOWN: { mixin(S_TRACE);
			dlg = new StepMinusDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.REVERSE_FLAG: { mixin(S_TRACE);
			dlg = new FlagRDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.CHECK_FLAG: { mixin(S_TRACE);
			dlg = new FlagJudgeDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.GET_CAST: { mixin(S_TRACE);
			dlg = new AreaSelectDialog!(CType.GET_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_ITEM: { mixin(S_TRACE);
			dlg = new GetItemDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_SKILL: { mixin(S_TRACE);
			dlg = new GetSkillDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_INFO: { mixin(S_TRACE);
			dlg = new AreaSelectDialog!(CType.GET_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_BEAST: { mixin(S_TRACE);
			dlg = new GetBeastDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_MONEY: { mixin(S_TRACE);
			dlg = new MoneyEventDialog!(CType.GET_MONEY)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_COUPON: { mixin(S_TRACE);
			dlg = new GetCouponDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_COMPLETE_STAMP: { mixin(S_TRACE);
			dlg = new EndEventDialog!(CType.GET_COMPLETE_STAMP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_GOSSIP: { mixin(S_TRACE);
			dlg = new GossipEventDialog!(CType.GET_GOSSIP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_CAST: { mixin(S_TRACE);
			dlg = new AreaSelectDialog!(CType.LOSE_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_ITEM: { mixin(S_TRACE);
			dlg = new LostItemDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_SKILL: { mixin(S_TRACE);
			dlg = new LostSkillDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_INFO: { mixin(S_TRACE);
			dlg = new AreaSelectDialog!(CType.LOSE_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_BEAST: { mixin(S_TRACE);
			dlg = new LostBeastDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_MONEY: { mixin(S_TRACE);
			dlg = new MoneyEventDialog!(CType.LOSE_MONEY)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_COUPON: { mixin(S_TRACE);
			dlg = new LoseCouponDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_COMPLETE_STAMP: { mixin(S_TRACE);
			dlg = new EndEventDialog!(CType.LOSE_COMPLETE_STAMP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_GOSSIP: { mixin(S_TRACE);
			dlg = new GossipEventDialog!(CType.LOSE_GOSSIP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.REDISPLAY: { mixin(S_TRACE);
			dlg = new RefreshDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.SUBSTITUTE_STEP: { mixin(S_TRACE);
			dlg = new SubstituteStepDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SUBSTITUTE_FLAG: { mixin(S_TRACE);
			dlg = new SubstituteFlagDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_STEP_CMP: { mixin(S_TRACE);
			dlg = new BrStepCmpDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_FLAG_CMP: { mixin(S_TRACE);
			dlg = new BrFlagCmpDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_RANDOM_SELECT: { mixin(S_TRACE);
			dlg = new BrRandomSelectDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_KEY_CODE: { mixin(S_TRACE);
			dlg = new BrKeyCodeDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CHECK_STEP: { mixin(S_TRACE);
			dlg = new CheckStepDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_ROUND: { mixin(S_TRACE);
			dlg = new BranchRoundDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.MOVE_BG_IMAGE: { mixin(S_TRACE);
			dlg = new MoveBgImageDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.REPLACE_BG_IMAGE: { mixin(S_TRACE);
			dlg = new BgImagesDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, refTarget, CType.REPLACE_BG_IMAGE);
			break;
		} case CType.LOSE_BG_IMAGE: { mixin(S_TRACE);
			dlg = new LoseBgImageDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} default: assert (0);
		}
		return dlg;
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
		auto itm = selection;
		if (itm) { mixin(S_TRACE);
			_statusLine = .contentText(_comm, cast(Content) itm.getData());
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
				auto c = cast(Content) itm.getData();
				_comm.delContent.call(c);
				if (_parItm) { mixin(S_TRACE);
					assert (_parItm.getData());
					assert (itm.getData());
					assert ((cast(Content) _parItm.getData()).detail.owner);
					assert (cast(Content) itm.getData());
					(cast(Content) _parItm.getData()).remove(c);
				} else { mixin(S_TRACE);
					_et.remove(c);
				}
				_tree.control.setRedraw(false);
				itm.dispose();
				if (_tree.editor) { mixin(S_TRACE);
					_tree.editor.updateEventTree();
				}
				_tree.control.setRedraw(true);
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
							} else { mixin(S_TRACE);
								store(owner);
							}
							if (cast(Content)_tree.getParentItem(_dragItm).getData() !is owner) { mixin(S_TRACE);
								adjustText(owner, evt, lastNextType);
							}
							if (_box._insertFirst) { mixin(S_TRACE);
								owner.insert(_prop.parent, 0, evt);
							} else { mixin(S_TRACE);
								owner.add(_prop.parent, evt);
							}
							_comm.refContent.call(evt);
							_tree.control.setRedraw(false);
							Item itm;
							if (_tree.tree) { mixin(S_TRACE);
								itm = createTreeItem(cast(TreeItem)ti, evt, eventText(owner, evt), _prop.images.content(evt.type));
							} else { mixin(S_TRACE);
								_tree.editor.updateEventTree();
								itm = EventEditorItem.valueOf(_tree.editor, evt);
							}
							procTreeItem(itm);
							_tree.setSelection([itm]);
							refreshStatusLine();
							_comm.refUseCount.call();
							if (evt.detail.owner) { mixin(S_TRACE);
								createChilds(itm, evt);
								_tree.setExpanded(itm, true);
							}
							_tree.control.setRedraw(true);
							refreshStatusLine();
							e.detail = samePane ? DND.DROP_MOVE : DND.DROP_COPY;
							_comm.refreshToolBar();
						}
					}
				} catch (Exception e) {
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
	private void adjustText(in Content owner, Content evt, string lastNextType) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_prop.var.etc.adjustContentName) return;
		if (lastNextType != "" && owner.detail.nextType !is toCNextType(lastNextType)) { mixin(S_TRACE);
			// 後続タイプが異なるので一端後続テキストをクリア
			evt.setName(_prop.parent, "");
		} else if (owner.detail.nextType !is CNextType.TEXT) { mixin(S_TRACE);
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
			_tree.editor.updateEventTree();
		} else { mixin(S_TRACE);
			_tree.control.redraw();
		}
	}
	class TRDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			if (!_readOnly) { mixin(S_TRACE);
				_comm.refSkin.remove(&refSkin);
				_comm.refCast.remove(&__refreshCast);
				_comm.delCast.remove(&__refreshCast);
				_comm.refSkill.remove(&__refreshSkill);
				_comm.delSkill.remove(&__refreshSkill);
				_comm.refItem.remove(&__refreshItem);
				_comm.delItem.remove(&__refreshItem);
				_comm.refBeast.remove(&__refreshBeast);
				_comm.delBeast.remove(&__refreshBeast);
				_comm.refInfo.remove(&__refreshInfo);
				_comm.delInfo.remove(&__refreshInfo);
				_comm.refArea.remove(&__refreshArea);
				_comm.delArea.remove(&__refreshArea);
				_comm.refBattle.remove(&__refreshBattle);
				_comm.delBattle.remove(&__refreshBattle);
				_comm.refPackage.remove(&__refreshPackage);
				_comm.delPackage.remove(&__refreshPackage);
				_comm.refFlagAndStep.remove(&__refreshFlagAndStep);
				_comm.delFlagAndStep.remove(&__refreshFlagAndStep);
				_comm.refPath.remove(&__refreshPath);
				_comm.refPaths.remove(&__refreshPaths);
				_comm.delPaths.remove(&__deletePaths);
				_comm.replPath.remove(&__replacePaths);
				_comm.replText.remove(&__refreshCard);
				_comm.replText.remove(&__refreshEventText);
				_comm.replID.remove(&__refreshCard);
				_comm.refContentText.remove(&refreshStatusLine);
				_comm.refPreviewValues.remove(&__refreshEventText);
				_comm.selContentTool.remove(&selContentTool);
				_comm.refEventTemplates.remove(&refreshTemplates);
			}
			_comm.refTargetVersion.remove(&redraw);
			_comm.refEventTreeViewStyle.remove(&refEventTreeViewStyle);
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
		if (!_prop.var.etc.drawCountOfUseOfStart && !_prop.var.etc.drawContentTreeLine) return;
		auto d = _tree.control.getDisplay();
		auto ca = _tree.control.getClientArea();
		auto suc = _et.startUseCounter;
		auto fore = e.gc.getForeground();
		auto back = e.gc.getBackground();
		auto counts = new string[_tree.getItemCount()];
		auto ucExtent = e.gc.textExtent(_prop.msgs.startUseCount);
		int maxW = 0;
		int h = e.gc.getFontMetrics().getHeight();
		if (_prop.var.etc.drawCountOfUseOfStart) { mixin(S_TRACE);
			foreach (i, itm; _tree.tree.getItems()) { mixin(S_TRACE);
				auto c = cast(Content)itm.getData();
				assert (c);
				int count = suc.get(toStartId(c.name));
				if (0 == i) count++;
				counts[i] = .text(count);
				auto extent = e.gc.textExtent(counts[i]);
				maxW = max(maxW, extent.x);
			}
		}
		foreach (i, itm; _tree.tree.getItems()) { mixin(S_TRACE);
			auto b = itm.getBounds();
			if (b.y + b.height <= ca.y) continue;
			if (ca.y + ca.height < b.y) break;
			if (_prop.var.etc.drawContentTreeLine && 0 < i) { mixin(S_TRACE);
				e.gc.setForeground(lineColor);
				scope (exit) e.gc.setForeground(fore);
				e.gc.drawLine(0, b.y, ca.width, b.y);
			}
			if (_prop.var.etc.drawCountOfUseOfStart) { mixin(S_TRACE);
				string t = counts[i];
				int tx = ca.width - maxW - 5;
				int ty = b.y + (b.height - h) / 2;
				e.gc.drawString(t, tx, ty);
				e.gc.setForeground(fontColor);
				scope (exit) e.gc.setForeground(fore);
				e.gc.drawString(_prop.msgs.startUseCount, tx - ucExtent.x - 5, ty);
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
		static const MARGIN_L = 5;
		static const MARGIN_T = 4;
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
		auto dotExtent = e.gc.textExtent("...");
		foreach (i, itm; itms) { mixin(S_TRACE);
			if (itm.getItemCount() && !itm.getExpanded()) { mixin(S_TRACE);
				// アイテムを畳んでいる場合は明示する
				e.gc.setAlpha(128);
				scope (exit) e.gc.setAlpha(255);
				auto bounds = itm.getBounds();
				int dotX = bounds.x + bounds.width + 2;
				bounds.x = dotX + 10;
				bounds.width = dotExtent.x + 10;
				e.gc.drawString("...", bounds.x + 5, bounds.y + (bounds.height - dotExtent.y) / 2, true);
				auto lineY = bounds.y + bounds.height / 2;
				e.gc.drawLine(dotX, lineY, bounds.x, lineY);
				e.gc.setAntialias(SWT.ON);
				scope (exit) e.gc.setAntialias(SWT.OFF);
				e.gc.drawRoundRectangle(bounds.x, bounds.y, bounds.width, bounds.height, 10, 10);
			}
			auto c = cast(Content) itm.getData();
			string cm = c.comment;
			if (cm.length) { mixin(S_TRACE);
				int dis = _prop.var.etc.commentBoxDistance;
				auto ib = itm.getBounds();
				cm = std.string.chomp(cm);
				auto te = e.gc.textExtent(cm);
				// 改行文字があると横幅がおかしくなるため
				// 測り直す
				te.x = 0;
				auto lines = splitLines!string(cm);
				foreach (line; lines) { mixin(S_TRACE);
					te.x = max(e.gc.textExtent(line).x, te.x);
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
				int px = ib.x + ib.width + 2;
				int py = ib.y + ib.height / 2 - 1;
				e.gc.fillRectangle(px, py, dis - MARGIN_L - 2, 1);

				boxes ~= box;
				bs ~= box;
				texts ~= lines;
			}
			if (_prop.var.etc.drawContentWarnings) { mixin(S_TRACE);
				auto warnings = .warnings(_prop.parent, summSkin, _summ, c, _prop.var.etc.targetVersion);
				if (warnings.length) { mixin(S_TRACE);
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

			e.gc.setAlpha(128);
			e.gc.fillRectangle(bx, by, bw, bh);
			e.gc.setAlpha(alpha);

			// FIXME: 場合によって改行が反映されない
//			e.gc.drawString(cm, tx, ty, true);
			foreach (line; lines) { mixin(S_TRACE);
				e.gc.drawString(line, tx, ty, true);
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
	this (Commons comm, Props prop, Summary summ, Composite parent, UndoManager undo,
			void delegate(size_t[]) forceSel,
			void delegate() refreshTopStart,
			Composite contentsBoxArea, bool readOnly) { mixin(S_TRACE);
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime());

		_comm = comm;
		_prop = prop;
		_summ = summ;
		_undo = undo;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		if (_readOnly) _summSkin = findSkin(_comm, _prop, _summ);
		_forceSel = forceSel;
		_refreshTopStart = refreshTopStart;
		_contentsBoxArea = contentsBoxArea;

		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout(zeroGridLayout(1, false));

		_comp.addDisposeListener(new TRDListener);

		if (!_readOnly) { mixin(S_TRACE);
			_cbarPar = new Composite(_comp, SWT.NONE);

			_comm.refSkin.add(&refSkin);
			_comm.refCast.add(&__refreshCast);
			_comm.delCast.add(&__refreshCast);
			_comm.refSkill.add(&__refreshSkill);
			_comm.delSkill.add(&__refreshSkill);
			_comm.refItem.add(&__refreshItem);
			_comm.delItem.add(&__refreshItem);
			_comm.refBeast.add(&__refreshBeast);
			_comm.delBeast.add(&__refreshBeast);
			_comm.refInfo.add(&__refreshInfo);
			_comm.delInfo.add(&__refreshInfo);
			_comm.refArea.add(&__refreshArea);
			_comm.delArea.add(&__refreshArea);
			_comm.refBattle.add(&__refreshBattle);
			_comm.delBattle.add(&__refreshBattle);
			_comm.refPackage.add(&__refreshPackage);
			_comm.delPackage.add(&__refreshPackage);
			_comm.refFlagAndStep.add(&__refreshFlagAndStep);
			_comm.delFlagAndStep.add(&__refreshFlagAndStep);
			_comm.refPath.add(&__refreshPath);
			_comm.refPaths.add(&__refreshPaths);
			_comm.delPaths.add(&__deletePaths);
			_comm.replPath.add(&__replacePaths);
			_comm.replText.add(&__refreshCard);
			_comm.replText.add(&__refreshEventText);
			_comm.replID.add(&__refreshCard);
			_comm.refContentText.add(&refreshStatusLine);
			_comm.refPreviewValues.add(&__refreshEventText);
			_comm.selContentTool.add(&selContentTool);
			_comm.refEventTemplates.add(&refreshTemplates);
		}
		_comm.refTargetVersion.add(&redraw);
		_comm.refEventTreeViewStyle.add(&refEventTreeViewStyle);

		foreach (cGrp, cs; CTYPE_GROUP) { mixin(S_TRACE);
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
		if (_prop.var.etc.straightEventTreeView) { mixin(S_TRACE);
			_tree.editor = new EventEditor(_comm, _comp, SWT.BORDER | _readOnly, _summ, null);
			new EventEdit(_comm, _tree.editor, &editEnd, &createEditor);
		} else { mixin(S_TRACE);
			_tree.tree = new Tree(_comp, SWT.SINGLE | SWT.BORDER | SWT.VIRTUAL);
			initTree(_comm, _tree.tree, true);
			if (!_readOnly) { mixin(S_TRACE);
				new TreeEdit(_comm, _tree.tree, &editEnd, &createEditor);
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
		auto im = new class PaintListener {
			override void paintControl(PaintEvent e) { mixin(S_TRACE);
				_tree.control.removePaintListener(this);
				initMenu();
			}
		};
		_tree.control.addPaintListener(im);

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
	Control widget() {return _comp;}

	@property
	ContentsToolBox contentsToolBox() { return _box; }

	@property
	private Composite boxOwner() { return _cbarPar; }

	@property
	string statusLine() {return _statusLine;}

	void undo() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() { mixin(S_TRACE);
		if (_readOnly) return;
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
		auto c = cast(Content) itm.getData();
		auto script = new CWXScript(_prop.parent, _summ);
		auto text = script.toScript([c], summSkin.evtChildOK, _summ.legacy, "\t");
		text = std.array.replace(text ~ "\n", "\n", .newline);
		_comm.clipboard.setContents([new ArrayWrapperString(text)], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}
	void toScriptAll() { mixin(S_TRACE);
		if (!_et) return;
		auto script = new CWXScript(_prop.parent, _summ);
		auto text = script.toScript(_et.starts, summSkin.evtChildOK, _summ.legacy, "\t");
		text = std.array.replace(text ~ "\n", "\n", .newline);
		_comm.clipboard.setContents([new ArrayWrapperString(text)], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}
	void toScript1Content() { mixin(S_TRACE);
		auto itm = selection;
		if (!itm) return;
		auto c = cast(Content) itm.getData();
		auto script = new CWXScript(_prop.parent, _summ);
		auto c2 = new Content(c.type, c.name);
		c2.shallowCopy(c);
		auto text = script.toScript([c2], summSkin.evtChildOK, _summ.legacy, "\t");
		text = std.array.replace(text ~ "\n", "\n", .newline);
		_comm.clipboard.setContents([new ArrayWrapperString(text)], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}
	private ContentCommentDialog[Content] _commentDlgs;
	@property
	bool canWriteComment() { mixin(S_TRACE);
		if (_readOnly) return false;
		return selection !is null;
	}
	void writeComment() { mixin(S_TRACE);
		if (_readOnly) return;
		auto itm = selection;
		if (!itm) return;
		.forceFocus(_tree.control, false);
		auto c = cast(Content) itm.getData();
		auto p = c in _commentDlgs;
		if (p) { mixin(S_TRACE);
			p.active();
			return;
		}
		auto dlg = new ContentCommentDialog(_comm, _prop, _tree.control.getShell(), c.parent, c);
		auto undo = new UndoContent(this, _comm, _prop, _summ, _et, [c]);
		dlg.appliedEvent ~= { mixin(S_TRACE);
			_undo ~= undo;
			undo = new UndoContent(this, _comm, _prop, _summ, _et, [c]);
			redraw();
		};
		_commentDlgs[c] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_commentDlgs.remove(c);
		};
		dlg.open();
	}

	@property
	bool canStartToPackage() { mixin(S_TRACE);
		return !_readOnly && 1 < _tree.getItemCount() && selection !is null;
	}
	void startToPackage() { mixin(S_TRACE);
		if (!canStartToPackage) return;
		if (!_et || !selection) return;
		if (_tree.getItemCount() <= 1) return;
		auto sel = selection;
		if (!sel) return;
		auto base = cast(Content) selection.getData();
		auto startItm = _tree.topItem(sel);
		auto start = base.parentStart;
		assert (start);
		assert (start is startItm.getData(), start.name ~ " : " ~ startItm.getText());
		int index = _tree.indexOf(startItm);
		Item[] users;
		Content[] conts = [start];
		void find(Item itm) { mixin(S_TRACE);
			if (itm == startItm) return;
			auto c = cast(Content)itm.getData();
			if (c.start == start.name) { mixin(S_TRACE);
				users ~= itm;
				conts ~= c;
			}
			foreach (cld; _tree.getItems(itm)) find(cld);
		}
		foreach (itm; _tree.getItems()) find(itm);
		auto ucp = new UndoCP(this, _comm, _prop, _summ, _et, conts, index, start);
		auto id = _comm.createPackage(start, false);
		if (id == 0) { mixin(S_TRACE);
			ucp.dispose();
			return;
		}
		_undo ~= ucp;
		delImpl(startItm, false);
		foreach (itm; users) { mixin(S_TRACE);
			auto c = cast(Content) itm.getData();
			switch (c.type) {
			case CType.LINK_START: { mixin(S_TRACE);
				c.convertType(CType.LINK_PACKAGE, _prop.parent);
				c.packages = id;
			} break;
			case CType.CALL_START: { mixin(S_TRACE);
				c.convertType(CType.CALL_PACKAGE, _prop.parent);
				c.packages = id;
			} break;
			default: assert (0);
			}
			itm.setImage(_prop.images.content(c.type));
		}
		refreshStatusLine();
		_comm.refUseCount.call();
		_comm.refreshToolBar();
	}
	@property
	bool canWrapTree() { mixin(S_TRACE);
		return !_readOnly && selection && (cast(Content)selection.getData()).parent;
	}
	void wrapTree() { mixin(S_TRACE);
		if (!canWrapTree) return;
		auto sel = selection;
		assert (sel !is null);
		auto c = cast(Content)sel.getData();
		auto parentStart = c.parentStart;
		auto si = c.tree.starts.cCountUntil(parentStart) + 1;
		storeContentAndInsert(c.parent, si, 1);

		auto start = new Content(CType.START, createNewName(parentStart.name, (string name) { mixin(S_TRACE);
			foreach (s; _et.starts) { mixin(S_TRACE);
				if (icmp(s.name, name) == 0) { mixin(S_TRACE);
					return false;
				}
			}
			return true;
		}, true));
		_et.insert(si, start);
		auto link = new Content(CType.LINK_START, c.name);
		link.start = start.name;
		c.parent.insert(_prop.parent, c.parent.next.cCountUntil(c), link);

		c.parent.remove(c);
		start.add(_prop.parent, c);
		_comm.delContent.call(c);

		Item sItm;
		if (_tree.tree) { mixin(S_TRACE);
			sItm = createTreeItem(_tree.tree, start, start.name, _prop.images.content(CType.START), si);
			createChilds(sItm, start);
		} else { mixin(S_TRACE);
			_tree.editor.updateEventTree();
			sItm = EventEditorItem.valueOf(_tree.editor, start);
		}
		_tree.select(sItm);
		_tree.showSelection();
		_comm.refContent.call(c);
		_comm.refContent.call(link);

		refreshStatusLine();
		_comm.refUseCount.call();
		_comm.refreshToolBar();
	}

	void refresh(EventTree et) { mixin(S_TRACE);
		_comm.setStatusLine(_tree.control, "");
		_statusLine = "";
		if (_et !is et) { mixin(S_TRACE);
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
		foreach (itm; _tree.getItems()) { mixin(S_TRACE);
			_tree.setExpanded(itm, false);
		}
		_comm.refreshToolBar();
	}
	@property
	bool canExpandTree() { mixin(S_TRACE);
		foreach (itm; _tree.getItems()) { mixin(S_TRACE);
			if (_tree.getItems(itm).length && !_tree.getExpanded(itm)) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	}
	@property
	bool canFoldTree() { mixin(S_TRACE);
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
	}
	void collapse() { mixin(S_TRACE);
		if (!canCollapse) return;
		auto itm = selection;
		if (!itm) return;
		_tree.setExpanded(itm, false);
	}
	private void editEnd(TreeItem itm, Control c) { mixin(S_TRACE);
		editEnd(cast(Item)itm, c);
	}
	private void editEnd(EventEditorItem itm, Control c) { mixin(S_TRACE);
		editEnd(cast(Item)itm, c);
	}
	private void editEnd(Item itm, Control c) { mixin(S_TRACE);
		if (_readOnly) return;
		auto t = cast(Text) c;
		auto evt = (cast(Content) itm.getData());
		if (t) { mixin(S_TRACE);
			auto text = t.getText();
			if (!text) text = "";
			if (text == evt.name) return;
			store(evt);
			if (evt.type == CType.START) { mixin(S_TRACE);
				evt.setName(_prop.parent, createNewName(text, (string name) { mixin(S_TRACE);
					foreach (s; _et.starts) { mixin(S_TRACE);
						if (s !is evt && icmp(s.name, name) == 0) { mixin(S_TRACE);
							return false;
						}
					}
					return true;
				}, true));
				itm.setText(evt.name);
			} else { mixin(S_TRACE);
				evt.setName(_prop.parent, text);
				itm.setText(eventText(evt.parent, evt));
			}
			if (evt.type == CType.START && _tree.indexOf(itm) == 0) { mixin(S_TRACE);
				_refreshTopStart();
			}
		} else { mixin(S_TRACE);
			auto combo = cast(Combo) c;
			int index = combo.getSelectionIndex();
			auto data = cast(Content)_tree.getParentItem(itm).getData();
			string name;
			switch (data.type) {
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
			} default:
				assert (combo.getItemCount() == 2);
				name = index == 0 ? _prop.sys.evtChildTrue : _prop.sys.evtChildFalse;
			}
			if (name == evt.name) return;
			store(evt);
			evt.setName(_prop.parent, name);
			itm.setText(combo.getText());
		}
		procTreeItem(itm);
		redraw();
		_comm.refContent.call(evt);
		refreshStatusLine();
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
		int index = nums.length;
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
				return createTextEditor(_comm, _prop, _tree.control, (cast(Content)itm.getData()).name);
			}
		} else { mixin(S_TRACE);
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
			return createBoolEditor!("evtChildBrMember(_prop, evt.targetAll, evt.random, name)")(data, c);
		} case CType.BRANCH_ABILITY: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrPower(_prop, evt.targetS, evt.physical, evt.mental, evt.signedLevel, name)")(data, c);
		} case CType.BRANCH_RANDOM: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrRandom(_prop, evt.percent, name)")(data, c);
		} case CType.BRANCH_LEVEL: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrLevel(_prop, evt.unsignedLevel, evt.average, name)")(data, c);
		} case CType.BRANCH_STATUS: { mixin(S_TRACE);
			return createBoolEditor!("evtChildBrState(_prop, evt.targetNS, evt.status, name)")(data, c);
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
			return createBoolEditor!("evtChildBrCoupon(_prop, evt.range, evt.coupon, name)")(data, c);
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
			_tree.editor.updateEventTree();
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

	private static void udImpl(int To)(EventTreeView v, Commons comm, EventTree et, Content c, bool store) { mixin(S_TRACE);
		if (!et) return;
		if (v) v._tree.control.setRedraw(false);
		scope (exit) if (v) v._tree.control.setRedraw(true);
		auto pc = c.parent;
		int i, j;
		auto path = c.ctPath;
		if (pc) { mixin(S_TRACE);
			i = cCountUntil!("a is b")(pc.next, c);
			j = i + To;
			if (j < 0 || pc.next.length <= j) return;
			if (v && store) { mixin(S_TRACE);
				v.store(pc);
			}
			comm.delContent.call(pc.next[i]);
			comm.delContent.call(pc.next[j]);
			pc.swapContent(i, j);
		} else { mixin(S_TRACE);
			i = cCountUntil!("a is b")(et.starts, c);
			j = i + To;
			if (j < 0 || et.starts.length <= j) return;
			if (v && store) { mixin(S_TRACE);
				v.storeSwap(i, j);
			}
			comm.delContent.call(et.starts[i]);
			comm.delContent.call(et.starts[j]);
			et.swapStart(i, j);
		}
		if (v) { mixin(S_TRACE);
			if (v._tree.tree) { mixin(S_TRACE);
				static if (To == -1) {
					treeItemUp(cast(TreeItem)v.fromPath(path));
				} else static if (To == 1) {
					treeItemDown(cast(TreeItem)v.fromPath(path));
				} else static assert (0);
			} else { mixin(S_TRACE);
				v._tree.editor.updateEventTree();
			}
			v._tree.showSelection();
			if (!pc && (i == 0 || j == 0)) { mixin(S_TRACE);
				v._refreshTopStart();
			}
		}
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
		udImpl!(-1)(this, _comm, _et, cast(Content) itm.getData(), store);
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
		udImpl!(1)(this, _comm, _et, cast(Content) itm.getData(), store);
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
		if (_tree.tree) { mixin(S_TRACE);
			parent.setText(eventText(parPar, next));
			child.setText(eventText(next, par));
			parent.setData(next);
			child.setData(par);
			parent.setImage(_prop.images.content(next.type));
			child.setImage(_prop.images.content(par.type));
			procTreeItem(parent);
			procTreeItem(child);
			foreach (cc; _tree.getItems(child)) { mixin(S_TRACE);
				cc.setText(eventText(par, cast(Content)cc.getData()));
				procTreeItem(cc);
			}
			_tree.setSelection([selTarg]);
		} else { mixin(S_TRACE);
			_tree.editor.updateEventTree();
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

	void refreshTreeName() { mixin(S_TRACE);
		_tree.getItems()[0].setText(_et.name);
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
		foreach (ct; cs) { mixin(S_TRACE);
			if (ct.type is CType.START) continue;
			cs2 ~= ct;
		}
		if (!cs2.length) return;

		Content last = null, allLast = null;
		int index = -1;
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

		_tree.control.setRedraw(false);
		scope (exit) _tree.control.setRedraw(true);
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
			owner = parent;
			itm = _tree.getParentItem(itm);
		}
		bool insertFirst = (index == -1 && _box._insertFirst);
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
		_comm.refUseCount.call();
		refreshStatusLine();
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
		if (stored) storeInsert(index, cs2.length);
		Item sItm = null, lastItm = null;
		foreach (i, c; cs2) { mixin(S_TRACE);
			if (!c.type is CType.START) continue;
			auto oldName = c.name;
			c.setName(_prop.parent, createNewName(c.name, (string name) { mixin(S_TRACE);
				foreach (s; _et.starts) { mixin(S_TRACE);
					if (icmp(s.name, name) == 0) { mixin(S_TRACE);
						return false;
					}
				}
				foreach (s; cs2) { mixin(S_TRACE);
					if (s is c) continue;
					if (icmp(s.name, name) == 0) { mixin(S_TRACE);
						return false;
					}
				}
				return true;
			}, true));
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
			if (_tree.tree) { mixin(S_TRACE);
				sItm = createTreeItem(_tree.tree, c, c.name, _prop.images.content(c.type), index + i);
			} else { mixin(S_TRACE);
				sItm = EventEditorItem.valueOf(_tree.editor, c);
			}
			lastItm = createChilds(sItm, c);
			_tree.setExpanded(sItm, true);
			_comm.refContent.call(c);
		}
		if (!sItm) return;
		if (lastItm) _tree.setSelection([lastItm]);
		_tree.showSelection();
		_comm.refUseCount.call();
		refreshStatusLine();
		_comm.refreshToolBar();
	}

	override {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			if (_readOnly) return;
			auto itm = selection;
			if (itm && itm !is _tree.getItems()[0]) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			auto itm = selection;
			if (itm) { mixin(S_TRACE);
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
			auto itm = selection;
			if (itm && itm !is _tree.getItems()[0]) { mixin(S_TRACE);
				_tree.control.setRedraw(false);
				scope(exit) _tree.control.setRedraw(true);
				delImpl(itm, true);
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
			return !_readOnly && _et !is null && _tree.control.isFocusControl();
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			auto itm = selection;
			return !_readOnly && itm && itm !is _tree.getItems()[0];
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
		auto opt = new XMLOption(_prop.sys);
		opt.shallow = shallow;
		auto node = c.toNode(opt);
		CNextType next;
		if (c.parent) { mixin(S_TRACE);
			next = c.parent.detail.nextType;
		} else { mixin(S_TRACE);
			assert (c.type is CType.START);
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
			copy1Content();
			del1Content();
		}
	}
	void copy1Content() { mixin(S_TRACE);
		if (_readOnly) return;
		auto itm = selection;
		if (itm) { mixin(S_TRACE);
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

			auto ownerItm = _tree.getParentItem(itm);
			auto c = cast(Content)itm.getData();
			_comm.delContent.call(c);
			auto owner = cast(Content)ownerItm.getData();
			this.store(owner);
			int insertIndex = owner.next.countUntil(c);
			owner.remove(c);
			auto lastNextType = fromCNextType(c.detail.nextType);
			foreach (i, next; c.next.dup) { mixin(S_TRACE);
				c.remove(next);
				if (_prop.var.etc.adjustContentName) { mixin(S_TRACE);
					if (i == 0 && lastNextType != fromCNextType(owner.detail.nextType)) { mixin(S_TRACE);
						next.setName(_prop.parent, c.name);
					} else { mixin(S_TRACE);
						adjustText(owner, next, lastNextType);
					}
				} else { mixin(S_TRACE);
					adjustText(owner, next, lastNextType);
				}
				owner.insert(_prop.parent, insertIndex + i, next);
			}
			createChilds(ownerItm, owner);
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
			debugln(e);
			return;
		}
		if (c) { mixin(S_TRACE);
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
				opt.linkId = _prop.var.etc.linkCard;

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
				debugln(e);
				throw e;
			} catch (Throwable e) {
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
			storeContentAndInsert(owner, si, starts.length);
			addContents(false, contents, cs, tryInsert);
			addStarts(false, starts, cs);
		} else if (s) { mixin(S_TRACE);
			addStarts(true, starts);
		} else if (c) { mixin(S_TRACE);
			addContents(true, contents, [], tryInsert);
		} else { mixin(S_TRACE);
			return;
		}
		redraw();
		_comm.refreshToolBar();
	}
	private void delImpl(Item itm, bool store) { mixin(S_TRACE);
		if (_readOnly) return;
		bool empty = _et.owner.isEmpty;
		scope (exit) {
			if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
		}
		auto ownerItm = _tree.getParentItem(itm);
		auto c = cast(Content) itm.getData();
		_comm.delContent.call(c);
		if (ownerItm) { mixin(S_TRACE);
			auto owner = cast(Content) ownerItm.getData();
			if (store) this.store(owner);
			owner.remove(c);
		} else { mixin(S_TRACE);
			if (store) this.storeDelete(.cCountUntil!("a is b")(_et.starts, c), c);
			_et.remove(c);
		}
		itm.dispose();
		if (_tree.editor) { mixin(S_TRACE);
			_tree.editor.updateEventTree();
		}
	}
	private static void delImpl(EventTreeView v, Commons comm, EventTree et, Content c) { mixin(S_TRACE);
		if (v) { mixin(S_TRACE);
			v.delImpl(v.fromPath(c.ctPath), false);
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
	private void __refreshCardImpl(Item evt) { mixin(S_TRACE);
		foreach (childItm; _tree.getItems(evt)) { mixin(S_TRACE);
			auto child = cast(Content) childItm.getData();
			childItm.setText(eventText(cast(Content) evt.getData(), child));
			if (child.detail.owner) { mixin(S_TRACE);
				__refreshCardImpl(childItm);
			}
			procTreeItem(childItm);
		}
	}
	private void __refreshCard() { mixin(S_TRACE);
		if (_tree.control.isDisposed()) return;
		if (_et) { mixin(S_TRACE);
			if (_tree.editor) { mixin(S_TRACE);
				_tree.editor.updateEventTree();
				return;
			}
			foreach (itm; _tree.getItems()) { mixin(S_TRACE);
				__refreshCardImpl(itm);
			}
			refreshStatusLine();
		}
	}
	private void __refreshEventTextImpl(Content par, Item itm) in { mixin(S_TRACE);
		assert (par.detail.owner);
	} body { mixin(S_TRACE);
		auto e = cast(Content) itm.getData();
		itm.setText(eventText(par, e));
		if (e.detail.owner) { mixin(S_TRACE);
			foreach (child; _tree.getItems(itm)) { mixin(S_TRACE);
				__refreshEventTextImpl(e, child);
			}
		} else { mixin(S_TRACE);
			assert (!_tree.getItems(itm).length);
		}
		procTreeItem(itm);
	}
	private void __refreshEventText() { mixin(S_TRACE);
		if (_et) { mixin(S_TRACE);
			if (_tree.editor) { mixin(S_TRACE);
				_tree.editor.updateEventTree();
				return;
			}
			foreach (itm; _tree.getItems()) { mixin(S_TRACE);
				auto start = cast(Content) itm.getData();
				assert (start.type == CType.START);
				itm.setText(start.name);
				foreach (child; _tree.getItems(itm)) { mixin(S_TRACE);
					__refreshEventTextImpl(start, child);
				}
			}
			refreshStatusLine();
		}
	}
	private void refSkin() {__refreshCard();}
	private void __refreshCast(CastCard c) {__refreshCard();}
	private void __refreshSkill(SkillCard c) {__refreshCard();}
	private void __refreshItem(ItemCard c) {__refreshCard();}
	private void __refreshBeast(BeastCard c) {__refreshCard();}
	private void __refreshInfo(InfoCard c) {__refreshCard();}
	private void __refreshArea(Area c) {__refreshCard();}
	private void __refreshPackage(Package c) {__refreshCard();}
	private void __refreshBattle(Battle c) {__refreshCard();}
	private void __refreshFlagAndStep(Flag[] flags, Step[] steps) { mixin(S_TRACE);
		if (flags.length || steps.length) { mixin(S_TRACE);
			__refreshCard();
			if (_prop.var.etc.showVariableValuesInEventText) { mixin(S_TRACE);
				__refreshEventText();
			}
		}
	}
	private void __refreshPath(string from, string to, bool isDir) {refreshStatusLine();}
	private void __refreshPaths(string path) {refreshStatusLine();}
	private void __deletePaths() {refreshStatusLine();}
	private void __replacePaths(string from, string to) {refreshStatusLine();}

	private bool openCWXPathImpl(T)(T itm, string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = cpcategory(path);
		if (cate == "") { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= _tree.getItemCount(itm)) return false;
			auto child = _tree.getItem(itm, index);
			path = cpbottom(path);
			if (cpempty(path) || cpcategory(path) != "") { mixin(S_TRACE);
				if (!cphasattr(path, "nofocus")) .forceFocus(_tree.control, shellActivate);
				_tree.select(child);
				_tree.showSelection();
				refreshStatusLine();
				if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
					auto d = edit();
					if (d) { mixin(S_TRACE);
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
				return openCWXPathImpl(child, path, shellActivate);
			}
		}
		return false;
	}
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		return openCWXPathImpl(_tree, path, shellActivate);
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
			string[string] flags;
			string[string] steps;
			string[char] names;
			getPreviewValues(prop, summ, SPCHAR_TEXT, names, flags, steps);
			return simpleFormatMsg(e.name, flags, steps, names);
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
		r = evtChildBrMember(prop, parent.targetAll, parent.random, name);
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
		r = evtChildBrState(prop, parent.targetNS, parent.status, name);
		break;
	} case CType.BRANCH_PARTY_NUMBER: { mixin(S_TRACE);
		r = evtChildBrNum(prop, parent.partyNumber, name);
		break;
	} case CType.BRANCH_AREA: { mixin(S_TRACE);
		r = evtChildBrArea(prop, summ.areas, name);
		break;
	} case CType.BRANCH_BATTLE: { mixin(S_TRACE);
		r = evtChildBrBattle(prop, summ.battles, name);
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
		r = evtChildBrCoupon(prop, parent.range, parent.coupon, name);
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
	if (path.length) { mixin(S_TRACE);
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
	} catch { mixin(S_TRACE);
		// Nothing
	}
	string name = prop.msgs.noSelectStep;
	string value = val >= 0 ? .tryFormat(prop.msgs.dlgLblStep, val) : prop.msgs.etc;
	if (path.length) { mixin(S_TRACE);
		auto o = summ.flagDirRoot.findStep(path);
		if (o) { mixin(S_TRACE);
			if (o.count <= val) { mixin(S_TRACE);
				val = -1;
				text = prop.sys.evtChildDefault;
			}
			name = path;
			if (0 <= val) value = o.getValue(val);
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
	string value = .tryFormat(prop.msgs.dlgLblStep, num);
	if (path.length) { mixin(S_TRACE);
		auto o = summ.flagDirRoot.findStep(path);
		if (o) { mixin(S_TRACE);
			name = path;
			if (0 <= num && num < o.count) value = o.getValue(num);
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
private string evtChildBrMember(in Props prop, bool all, bool random, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string mem = all ? prop.msgs.partyAll : prop.msgs.partyActive;
	string am = random ? prop.msgs.autoSelect : prop.msgs.manualSelect;
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.selectMemberSuccess, mem, am);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.selectMemberFailure, mem, am);
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
private string evtChildBrState(in Props prop, Target targ, Status stat, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string tt = prop.msgs.targetName(targ.m);
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
						return .tryFormat(prop.msgs.branchArea, a.name);
					}
				}
			}
		} catch {}
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
						return .tryFormat(prop.msgs.branchBattle, b.name);
					}
				}
			}
		} catch {}
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
	if (0 != id) { mixin(S_TRACE);
		auto c = summ.cwCast(id);
		name = c ? c.name : .tryFormat(prop.msgs.noCast, id);
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
	if (0 != id) { mixin(S_TRACE);
		auto c = summ.item(id);
		name = c ? c.name : .tryFormat(prop.msgs.noItem, id);
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
	if (0 != id) { mixin(S_TRACE);
		auto c = summ.skill(id);
		name = c ? c.name : .tryFormat(prop.msgs.noSkill, id);
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
	if (0 != id) { mixin(S_TRACE);
		auto c = summ.beast(id);
		name = c ? c.name : .tryFormat(prop.msgs.noBeast, id);
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
	if (0 != id) { mixin(S_TRACE);
		auto c = summ.info(id);
		name = c ? c.name : .tryFormat(prop.msgs.noInfo, id);
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
private string evtChildBrCoupon(in Props prop, Range r, string coupon, ref string text) { mixin(S_TRACE);
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (!coupon || !coupon.length) coupon = prop.msgs.noSelectCoupon;
	string tr = prop.msgs.rangeName(r);
	if (val) { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchCouponSuccess, tr, coupon);
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.branchCouponFailure, tr, coupon);
	}
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
		if (path.length) { mixin(S_TRACE);
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
		if (path.length) { mixin(S_TRACE);
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

	string range = prop.msgs.rangeName(evt.keyCodeRange);
	if (evt.effectCardType is EffectCardType.ALL) { mixin(S_TRACE);
		if (val) { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchKeyCodeAllTypeSuccess, evt.keyCode, range);
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchKeyCodeAllTypeFailure, evt.keyCode, range);
		}
	} else { mixin(S_TRACE);
		string type = prop.msgs.effectCardTypeName(evt.effectCardType);
		if (val) { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchKeyCodeSuccess, evt.keyCode, type, range);
		} else { mixin(S_TRACE);
			return .tryFormat(prop.msgs.branchKeyCodeFailure, evt.keyCode, type, range);
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

Image warningImage(Props prop, Display d) { mixin(S_TRACE);
	auto height = 1;
	auto buf = new Image(d, prop.var.etc.warningImageWidth, height);
	scope (exit) buf.dispose();
	auto gc = new GC(buf);
	scope (exit) gc.dispose();
	int alpha;
	auto rgb = dwtData(prop.var.etc.warningImageColor, alpha);
	auto color = new Color(d, rgb);
	scope (exit) color.dispose();
	gc.setForeground(color);
	gc.setBackground(color);
	gc.fillRectangle(0, 0, prop.var.etc.warningImageWidth, height);
	auto alphas = new byte[prop.var.etc.warningImageWidth];
	foreach (i, ref b; alphas) { mixin(S_TRACE);
		b = cast(byte)(cast(real)i / prop.var.etc.warningImageWidth * alpha);
	}
	alphas = std.array.replicate(alphas, height);
	assert (alphas.length == prop.var.etc.warningImageWidth * height);
	auto imgData = buf.getImageData();
	imgData.setAlphas(0, 0, prop.var.etc.warningImageWidth * height, alphas, 0);
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
		_putModeTI.setToolTipText(_prop.buildTool(_putMode));
		_putModeTI.setImage(_prop.images.menu(_putMode));
		_comm.selContentTool.call(this, _arrowMode, _cType, _putMode, _autoOpen, _insertFirst);
	}
	private void insertFirst() { mixin(S_TRACE);
		_insertFirst = _insertFirstTI.getSelection();
		_comm.selContentTool.call(this, _arrowMode, _cType, _putMode, _autoOpen, _insertFirst);
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
					putQuick(_shiftDown);
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
		auto text = _prop.msgs.contentName(type);
		auto img = _prop.images.content(type);
		auto cursor = _prop.images.cursor(type);
		_cursors ~= cursor;
		auto ce = new CreateEvent(type, cursor);
		auto itm = createToolItem2(_comm, bar, text, img, &ce.create, () => _parent.selection !is null, SWT.RADIO);
		ce.ti = itm;
		g.append(itm);
		_conts[type] = ce;
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
			saveToolWinPos();
			_toolWin.dispose();
		}
		if (_tcListener) { mixin(S_TRACE);
			_autoHideTools.getParent().removeControlListener(_tcListener);
		}
		if (_autoHideTools) { mixin(S_TRACE);
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
		void editScEvTemplate() { mixin(S_TRACE);
			auto dlg = new EventTemplateDialog(comm, prop, summ, shell, summ.eventTemplates);
			dlg.appliedEvent ~= { mixin(S_TRACE);
				summ.eventTemplates = dlg.eventTemplates;
				comm.refEventTemplates.call();
			};
			dlg.open();
		}
		createMenuItem(comm, menu, MenuID.EvTemplatesOfScenario, &editScEvTemplate, enabled);
	}
	private void refreshTemplatesM() { mixin(S_TRACE);
		refreshTemplates(_comm, _prop, _summ, _templMenu, _parent.widget.getShell(), () => _parent._et !is null, (string script, bool tryInsert) {
			_parent.pasteScript(script, tryInsert);
		});
		_templTI.setEnabled(0 < _templMenu.getItemCount());
	}

	private class TDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			assert (_toolWin);
			if (_toolWin.isDisposed()) return;
			if (_toolWin.getVisible()) { mixin(S_TRACE);
				saveToolWinPos();
			}
		}
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
		}
	}
	private class AHTCListener : ControlAdapter {
		override void controlResized(ControlEvent e) { mixin(S_TRACE);
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
			cbarPar.setLayoutData(new GridData(GridData.FILL_BOTH));
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
				}
			}
		};
		_comm.refEventTemplates.add(&refreshTemplatesM);
		_comm.selContentTool.add(&selContentTool);

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
			_putModeTI = createDropDownItem2(_comm, mode, _prop.buildTool(_putMode), _prop.images.menu(_putMode), dlg, putModeMenu, MenuID.None, null);
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
			foreach (cGrp, cs; CTYPE_GROUP) { mixin(S_TRACE);
				auto eBar = new ToolBar(cbar, SWT.FLAT);
				eBar.addMouseListener(tml);
				foreach (cType; cs) { mixin(S_TRACE);
					createEI(cType, eBar, g);
				}
				if (cGrp is CTypeGroup.Visual) { mixin(S_TRACE);
					createCoolItem(cbar, eBar, 2);
				} else { mixin(S_TRACE);
					createCoolItem(cbar, eBar);
				}
				_comm.put(eBar);
			}
			updatePutMode();
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
			auto pb = _toolWin.getParent().getBounds();
			auto size = _toolWin.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			auto ts = _toolWin.getBounds();
			int tx = _prop.var.contentsWin.x == SWT.DEFAULT ? ts.x : pb.x + _prop.var.contentsWin.x;
			int ty = _prop.var.contentsWin.y == SWT.DEFAULT ? ts.y : pb.y + _prop.var.contentsWin.y;
			intoDisplay(tx, ty, size.x, size.y);
			_parX = pb.x;
			_parY = pb.y;
			_toolWin.setBounds(tx, ty, size.x, size.y);
			_toolWin.addDisposeListener(new TDListener);
			_toolWin.getParent().addControlListener(new TCListener);
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
		_prop.var.contentsWin.x = _toolWin.getBounds().x - _toolWin.getParent().getBounds().x;
		_prop.var.contentsWin.y = _toolWin.getBounds().y - _toolWin.getParent().getBounds().y;
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
