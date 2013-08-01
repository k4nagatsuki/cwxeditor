
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

	MouseTrack _mTrack = null;
	Shell _toolWin = null;
	Shell _autoHideTools = null;
	TCListener _tcListener = null;
	Composite _comp;
	TreeViewWrapper _tree;
	Color _grayFont;

	int _readOnly = 0;
	Props _prop;
	Commons _comm;
	Summary _summ;
	EventTree _et;
	bool _toolWinVisible = false;
	bool _opened = false;
	Composite _contentsBoxArea;
	Menu _templMenu;
	ToolItem _templTI;

	auto _putMode = MenuID.PutSelect;
	bool _autoOpen;
	bool _insertFirst;
	MenuItem _putQuickMI;
	MenuItem _putSelectMI;
	MenuItem _putContinueMI;
	ToolItem _putModeTI;
	ToolItem _autoOpenTI;
	ToolItem _insertFirstTI;

	bool _arrowMode = true;
	CType _cType;
	ToolItem _arrowTI;
	ToolItem _evtTI = null;
	RadioGroup!(ToolItem) _radioGroup;

	void delegate(size_t[]) _forceSel;
	void delegate() _refreshTopStart;

	Cursor[] _cursors;
	Warning[] _warningRects;

	string _statusLine;

	Item _clickStart = null;
	bool _shiftDown = false;

	Skin _summSkin;
	@property
	Skin summSkin() {
		return _summSkin ? _summSkin : _comm.skin;
	}

	void autoOpen() {
		_autoOpen = _autoOpenTI.getSelection();
		_comm.selContentTool.call(this, _arrowMode, _cType, _putMode, _autoOpen, _insertFirst);
	}
	void updatePutMode() {
		if (!_constructTools) return;
		if (_putQuickMI.getSelection()) {
			_putMode = MenuID.PutQuick;
			arrow();
			foreach (ti; _radioGroup.set) {
				ti.setSelection(false);
			}
			_arrowTI.setSelection(false);
		} else if (_putSelectMI.getSelection()) {
			_putMode = MenuID.PutSelect;
			if (!_arrowTI.getEnabled()) arrow();
		} else if (_putContinueMI.getSelection()) {
			_putMode = MenuID.PutContinue;
			if (!_arrowTI.getEnabled()) arrow();
		}
		_arrowTI.setEnabled(_putMode !is MenuID.PutQuick);
		_putModeTI.setToolTipText(_prop.buildTool(_putMode));
		_putModeTI.setImage(_prop.images.menu(_putMode));
		_comm.selContentTool.call(this, _arrowMode, _cType, _putMode, _autoOpen, _insertFirst);
	}
	void insertFirst() {
		_insertFirst = _insertFirstTI.getSelection();
		_comm.selContentTool.call(this, _arrowMode, _cType, _putMode, _autoOpen, _insertFirst);
	}

	@property
	Item selection() {
		if (!_tree.control || _tree.control.isDisposed()) return null;
		auto sels = _tree.getSelection();
		if (sels.length > 0) {
			return sels[0];
		}
		return null;
	}

	class EditL : MouseAdapter, KeyListener {
		private void __edit() {
			if (_readOnly) return;
			edit();
		}
		override void keyPressed(KeyEvent e) {
			if (e.character == SWT.CR) {
				__edit();
			}
		}
		override void keyReleased(KeyEvent e) {}
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button == 1 && !_tree.control.getCursor()) {
				__edit();
			}
		}
		override void mouseUp(MouseEvent e) {
			if (e.button == 1 && _clickStart) {
				__edit();
			}
		}
	}
	class CreateL : MouseAdapter {
		override void mouseDown(MouseEvent e) {
			if (_readOnly) return;
			if (_putMode is MenuID.PutQuick) return;
			if (e.button == 1) {
				create(null);
			} else if (e.button == 2 && !_arrowMode) {
				auto itm = _tree.getItem(new Point(e.x, e.y));
				if (itm && CDetail.fromType(_cType).owner) {
					auto c = cast(Content) itm.getData();
					if (c.parent) {
						_tree.setSelection([itm]);
						create(itm);
						_comm.refreshToolBar();
					}
				}
			} else if (e.button == 3) {
				arrow();
				_comm.refreshToolBar();
			}
		}
	}
	class MouseMove : MouseTrackAdapter, MouseMoveListener {
		override void mouseMove(MouseEvent e) {
			_clickStart = null;
			if (!_readOnly && _arrowMode && _prop.var.etc.clickIconIsStartEdit) {
				auto itm = _tree.getItem(new Point(e.x, e.y));
				if (itm) {
					auto c = cast(Content)itm.getData();
					auto d = _tree.control.getDisplay();
					auto hand = d.getSystemCursor(SWT.CURSOR_HAND);
					if (_tree.getImageBounds(itm).contains(e.x, e.y) && hasDialog(c.type) && checkOpenDialog(c.type)) {
						_clickStart = itm;
						if (_tree.editor) {
							_tree.control.setCursor(hand);
						}
					} else {
						if (_tree.editor && _tree.control.getCursor() is hand) {
							_tree.control.setCursor(null);
						}
					}
				}
			}
			updateToolTip();
		}
		override void mouseExit(MouseEvent e) {
			clearClickStart();
		}
	}
	void clearClickStart() {
		auto d = _tree.control.getDisplay();
		auto hand = d.getSystemCursor(SWT.CURSOR_HAND);
		if (_clickStart && _tree.editor && _tree.editor && _tree.control.getCursor() is hand) {
			_tree.control.setCursor(null);
		}
	}
	void updateToolTip() {
		if (!_tree.tree) return;
		auto p = _tree.control.getDisplay().getCursorLocation();
		p = _tree.control.toControl(p);
		string toolTip = "";
		if (_tree.control.getClientArea().contains(p)) {
			foreach (warn; _warningRects) {
				if (warn.rect.contains(p)) {
					toolTip = std.string.join(warn.warnings, .newline);
					break;
				}
			}
		}
		if (_tree.control.getToolTipText() != toolTip) {
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
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et) {
			this.et = et;
			this.comm = comm;
			this.prop = prop;
			this.summ = summ;
			_etPath = et.areaPath;
			if (v) {
				auto sel = v.selection;
				_selPath = sel ? (cast(Content) sel.getData()).ctPath : null;
			}
		}
		void udb(EventTreeView v) {
			if (!v) return;
			.forceFocus(v._tree.control, false);
			v._forceSel(_etPath);
			auto sel = v.selection;
			_selPath2 = sel ? (cast(Content) sel.getData()).ctPath : null;
		}
		void uda(EventTreeView v) {
			scope (exit) comm.refreshToolBar();
			if (!v) return;
			if (_selPath) v._tree.select(v.fromPath(_selPath));
			_selPath = _selPath2;
			v.refreshStatusLine();
		}
		EventTreeView view() {
			return comm.eventTreeViewFrom(et.cwxPath(true), false);
		}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
	}
	private static void insertStart(EventTreeView v, Commons comm, EventTree et, int index, Content c) {
		if (v) v._tree.control.setRedraw(false);
		scope (exit) if (v) v._tree.control.setRedraw(true);
		bool empty = et.owner.isEmpty;
		scope (exit) {
			if (empty != et.owner.isEmpty) comm.refEventTree.call(et);
		}
		et.insert(index, c);
		if (v) {
			if (v._tree.tree) {
				auto itm = createTreeItem(v._tree.tree, c, c.name, v._prop.images.content(c.type), index);
				v.createChilds(itm, c);
				v._tree.setExpanded(itm, true);
			} else {
				v._tree.editor.updateEventTree();
			}
			v.refreshStatusLine();
			v._refreshTopStart();
			v._tree.control.redraw();
		}
		comm.refContent.call(c);
		comm.refUseCount.call();
	}
	static class UndoContent : ETVUndo {
		private size_t[][] _path;
		private Content[] _c;
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et, Content[] cs) {
			super (v, comm, prop, summ, et);
			foreach (c; cs) {
				_path ~= c.ctPath;
				_c ~= c.dup;
				_c[$ - 1].setUseCounter(summ.useCounter.sub);
			}
		}
		private void impl() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			bool empty = et.owner.isEmpty;
			scope (exit) {
				if (empty != et.owner.isEmpty) comm.refEventTree.call(et);
			}
			foreach (i, c; _c.dup) {
				int index = _path[i][$ - 1];
				auto tc = et.fromPath(_path[i]);
				_c[i] = tc.dup;
				_c[i].setUseCounter(summ.useCounter.sub);
				auto pc = tc.parent;
				string text;
				if (pc) {
					pc.insert(prop.parent, index, c);
					text = .eventText(comm, summ, pc, c, false);
				} else {
					et.insert(index, c);
					text = c.name;
				}
				if (v) v._tree.control.setRedraw(false);
				scope (exit) if (v) v._tree.control.setRedraw(true);
				if (v) {
					if (v._tree.tree) {
						auto now = cast(TreeItem)v.fromPath(_path[i]);
						auto par = now.getParentItem();
						TreeItem itm;
						if (par) {
							itm = createTreeItem(par, c, text, prop.images.content(c.type), index);
						} else {
							itm = createTreeItem(v._tree.tree, c, text, prop.images.content(c.type), index);
						}
						v.procTreeItem(itm);
						v.createChilds(itm, c);
						v._tree.setExpanded(itm, true);
					} else {
						v._tree.editor.updateEventTree();
					}
				}
				delImpl(v, comm, et, tc);
				if (v && !pc) {
					v._refreshTopStart();
				}
			}
			if (v) v.refreshStatusLine();
			comm.refUseCount.call();
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {
			foreach (c; _c) {
				c.removeUseCounter();
			}
		}
	}
	void store(Content[] evt ...) {
		_undo ~= new UndoContent(this, _comm, _prop, _summ, _et, evt);
	}
	static class UndoSwap : ETVUndo {
		private int _upIndex;
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et, int swapIndex1, int swapIndex2) {
			super (v, comm, prop, summ, et);
			_upIndex = swapIndex1 > swapIndex2 ? swapIndex1 : swapIndex2;
		}
		private void impl() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			udImpl!(-1)(v, comm, et, et.starts[_upIndex], false);
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {}
	}
	void storeSwap(int swapIndex1, int swapIndex2) {
		_undo ~= new UndoSwap(this, _comm, _prop, _summ, _et, swapIndex1, swapIndex2);
	}
	static class UndoInsert : ETVUndo {
		private int _index;
		private size_t _count;
		private Content[] _c;
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et, int index, size_t count) {
			super (v, comm, prop, summ, et);
			_index = index;
			_count = count;
		}
		override void undo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (v) v._tree.control.setRedraw(false);
			scope (exit) if (v) v._tree.control.setRedraw(true);
			for (size_t i = 0; i < _count; i++) {
				auto node = et.starts[_index].toNode(new XMLOption(prop.sys));
				auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
				auto c = Content.createFromNode(node, ver);
				c.setUseCounter(summ.useCounter.sub);
				_c ~= c;
				delImpl(v, comm, et, et.starts[_index]);
			}
			comm.refUseCount.call();
			if (v) {
				v.refreshStatusLine();
				v._refreshTopStart();
			}
		}
		override void redo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			foreach_reverse (c; _c) {
				insertStart(v, comm, et, _index, c);
			}
			_c = [];
		}
		override void dispose() {
			foreach (c; _c) {
				c.removeUseCounter();
			}
		}
	}
	void storeInsert(int insertIndex, size_t count = 1) {
		_undo ~= new UndoInsert(this, _comm, _prop, _summ, _et, insertIndex, count);
	}
	static class UndoDelete : ETVUndo {
		private int _index;
		private Content _c;
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et, int index, Content del) {
			super (v, comm, prop, summ, et);
			_index = index;
			auto node = del.toNode(new XMLOption(prop.sys));
			auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
			_c = Content.createFromNode(node, ver);
			_c.setUseCounter(summ.useCounter.sub);
		}
		override void undo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			insertStart(v, comm, et, _index, _c);
		}
		override void redo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (v) v._tree.control.setRedraw(false);
			scope (exit) if (v) v._tree.control.setRedraw(true);
			delImpl(v, comm, et, et.starts[_index]);
			comm.refUseCount.call();
			if (v) {
				v.refreshStatusLine();
				v._refreshTopStart();
			}
		}
		override void dispose() {
			_c.removeUseCounter();
		}
	}
	void storeDelete(int index, Content del) {
		_undo ~= new UndoDelete(this, _comm, _prop, _summ, _et, index, del);
	}
	private Item fromPath(string cwxPath) {
		return fromPathImpl(_tree, cwxPath);
	}
	private Item fromPathImpl(T)(T tree, string cwxPath) {
		if (cpempty(cwxPath)) return null;
		string cate = cpcategory(cwxPath);
		while ("" != cate) {
			cwxPath = cpbottom(cwxPath);
			if (cpempty(cwxPath)) return null;
			cate = cpcategory(cwxPath);
		}
		auto itm = _tree.getItem(tree, cpindex(cwxPath));
		cwxPath = cpbottom(cwxPath);
		if (cpempty(cwxPath)) return itm;
		return fromPathImpl(itm, cwxPath);
	}
	private Item fromPath(size_t[] path) {
		return fromPathImpl(_tree, path);
	}
	private Item fromPathImpl(T)(T tree, size_t[] path) {
		if (!path.length) return null;
		auto itm = _tree.getItem(tree, path[0]);
		if (path.length == 1) return itm;
		return fromPathImpl(itm, path[1 .. $]);
	}
	static class UndoCP : Undo {
		private UndoContent _undoC;
		private UndoDelete _undoD;
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et, Content[] conts, int index, Content start) {
			_undoC = new UndoContent(v, comm, prop, summ, et, conts);
			_undoD = new UndoDelete(v, comm, prop, summ, et, index, start);
		}
		override void undo() {
			_undoD.undo();
			_undoC.undo();
		}
		override void redo() {
			_undoC.redo();
			_undoD.redo();
		}
		override void dispose() {
			_undoC.dispose();
			_undoD.dispose();
		}
	}
	static class UndoContentAndInsert : ETVUndo {
		private UndoContent _undoC;
		private UndoInsert _undoI;
		this (EventTreeView v, Commons comm, Props prop, Summary summ, EventTree et, Content owner, int insertIndex, int count) {
			super (v, comm, prop, summ, et);
			_undoC = new UndoContent(v, comm, prop, summ, et, [owner]);
			_undoI = new UndoInsert(v, comm, prop, summ, et, insertIndex, count);
		}
		override void undo() {
			_undoI.undo();
			_undoC.undo();
		}
		override void redo() {
			_undoC.redo();
			_undoI.redo();
		}
		override void dispose() {
			_undoC.dispose();
			_undoI.dispose();
		}
	}
	void storeContentAndInsert(Content owner, int insertIndex, int count) {
		_undo ~= new UndoContentAndInsert(this, _comm, _prop, _summ, _et, owner, insertIndex, count);
	}

	private EventDialog[Content] _editDlgs;
	void appliedEdit(UndoContent undo, Content c) {
		_undo ~= undo;
		auto itm = fromPath(c.cwxPath(true));
		assert (c is itm.getData());
		foreach (childItm; _tree.getItems(itm)) {
			auto par = cast(Content)itm.getData();
			assert (par.detail.owner);
			childItm.setText(eventText(par, cast(Content) childItm.getData()));
			procTreeItem(childItm);
		}
		procTreeItem(itm);
		_tree.select(itm);
		.forceFocus(_tree.control, false);
		_tree.control.redraw();
		_comm.refContent.call(c);
		_comm.refUseCount.call();
		refreshStatusLine();
		_comm.refreshToolBar();
	}
	void editM() {edit();}
	EventDialog edit() {
		if (_readOnly) return null;
		auto sels = _tree.getSelection();
		if (sels.length > 0) {
			auto c = cast(Content) sels[0].getData();
			return edit(c);
		}
		return null;
	}
	void create(Item insertTo) {
		if (_readOnly) return;
		if (!_tree.getItemCount()) return;
		if (!_arrowMode || _putMode is MenuID.PutQuick) {
			_tree.control.setRedraw(false);
			scope (exit) _tree.control.setRedraw(true);
			if (_cType == CType.START) {
				if (insertTo) return;
				create(null, _cType, "", (Content evt) {
					assert (evt);
					bool empty = _et.owner.isEmpty;
					scope (exit) {
						if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
					}
					auto sel = selection;
					int index;
					if (sel) {
						index = _tree.indexOf(_tree.topItem(sel)) + 1;
					} else {
						index = -1;
					}
					storeInsert(index);
					_et.insert(index, cast(Content)evt);
					Item sItm;
					if (_tree.tree) {
						sItm = createTreeItem(_tree.tree, evt, evt.name, _prop.images.content(CType.START), index);
					} else {
						_tree.editor.updateEventTree();
						sItm = EventEditorItem.valueOf(_tree.editor, evt);
					}
					_tree.select(sItm);
					_tree.showSelection();
					.forceFocus(_tree.control, false);
					_tree.control.redraw();
					_comm.refContent.call(evt);
					refreshConvMenu();
					refreshStatusLine();
					if (_putMode !is MenuID.PutContinue) arrow();
					_comm.refreshToolBar();
				});
			} else {
				if (insertTo && !CDetail.fromType(_cType).owner) return;
				auto sels = _tree.getSelection();
				if (insertTo || (sels.length > 0 && (cast(Content) sels[0].getData()).detail.owner)) {
					Item oItm;
					int insertIndex = -1;
					if (insertTo) {
						oItm = _tree.getParentItem(insertTo);
						if (!oItm) return;
						insertIndex = _tree.indexOf(oItm, insertTo);
					} else {
						oItm = sels[0];
					}
					auto owner = cast(Content) oItm.getData();
					void applied(Content evt) {
						bool empty = _et.owner.isEmpty;
						scope (exit) {
							if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
						}
						store(owner);
						if (insertIndex == -1) {
							if (_insertFirst) {
								owner.insert(_prop.parent, 0, evt);
							} else {
								owner.add(_prop.parent, evt);
							}
						} else {
							owner.insert(_prop.parent, insertIndex, evt);
						}
						Item itm;
						if (_tree.tree) {
							itm = createTreeItem(cast(TreeItem)oItm, evt, eventText(owner, evt), _prop.images.content(evt.type), insertIndex);
							_tree.setExpanded(oItm, true);
						} else {
							_tree.editor.updateEventTree();
							itm = EventEditorItem.valueOf(_tree.editor, evt);
						}
						_tree.setSelection([itm]);
						if (insertTo) {
							auto ic = cast(Content) insertTo.getData();
							_comm.delContent.call(ic);
							ic.parent.remove(ic);
							if (_prop.var.etc.adjustContentName) {
								ic.setName(_prop.parent, "");
							}
							if (_insertFirst) {
								evt.insert(_prop.parent, 0, ic);
							} else {
								evt.add(_prop.parent, ic);
							}
							insertTo.dispose();
							createChilds(itm, evt);
							_tree.setExpanded(itm, true);
						}
						procTreeItem(itm);
						_tree.showSelection();
						.forceFocus(_tree.control, false);
						_tree.control.redraw();
						_comm.refContent.call(evt);
						_comm.refUseCount.call();
						refreshConvMenu();
						refreshStatusLine();
						if (_putMode !is MenuID.PutContinue) arrow();
						_comm.refreshToolBar();
					}
					if (insertTo) {
						create(owner, _cType, (cast(Content) insertTo.getData()).name, &applied);
					} else {
						create(owner, _cType, "", &applied);
					}
				}
			}
		}
	}
	void arrow() {
		if (_readOnly) return;
		constructTools();
		_arrowMode = true;
		_comp.setCursor(null);
		if (_toolWin && !_toolWin.isDisposed()) {
			_toolWin.setCursor(null);
		}
		if (_autoHideTools) {
			_autoHideTools.setCursor(null);
		}
		if (_radioGroup && _putMode !is MenuID.PutQuick) _radioGroup.select(_arrowTI);
		_comm.selContentTool.call(this, _arrowMode, _cType, _putMode, _autoOpen, _insertFirst);
	}
	void selContentTool(Object sender, bool arrowMode, CType cType, MenuID putMode, bool autoOpen, bool insertFirst) {
		if (_readOnly) return;
		if (!_prop.var.etc.connContentTools) return;
		if (sender is this) return;
		constructTools();
		if (!_arrowMode && arrowMode) {
			arrow();
		}
		if (((_arrowMode && !arrowMode) || (_cType != cType)) && MenuID.PutQuick !is putMode) {
			auto ce = _conts[cType];
			_radioGroup.select(ce.ti);
			ce.create(null);
		}
		if (_autoOpen != autoOpen) {
			_autoOpenTI.setSelection(autoOpen);
			this.autoOpen();
		}
		if (_putMode != putMode) {
			_putMode = putMode;
			_putQuickMI.setSelection(_putMode is MenuID.PutQuick);
			_putSelectMI.setSelection(_putMode is MenuID.PutSelect);
			_putContinueMI.setSelection(_putMode is MenuID.PutContinue);
			this.updatePutMode();
		}
		if (_insertFirst != insertFirst) {
			_insertFirstTI.setSelection(insertFirst);
			this.insertFirst();
		}
	}

	bool hasDialog(CType type) {
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
	bool checkOpenDialog(CType type) {
		if (_readOnly) return false;
		switch (type) {
		case CType.START_BATTLE: {
			return _summ.battles.length > 0;
		} case CType.CHANGE_AREA: {
			return _summ.areas.length > 0;
		} case CType.LINK_PACKAGE, CType.CALL_PACKAGE: {
			return _summ.packages.length > 0;
		} case CType.BRANCH_FLAG, CType.SET_FLAG, CType.REVERSE_FLAG, CType.CHECK_FLAG, CType.SUBSTITUTE_FLAG, CType.BRANCH_FLAG_CMP: {
			return _summ.flagDirRoot.allFlags.length > 0;
		} case CType.BRANCH_MULTI_STEP, CType.BRANCH_STEP, CType.SET_STEP, CType.SET_STEP_UP, CType.SET_STEP_DOWN, CType.SUBSTITUTE_STEP, CType.BRANCH_STEP_CMP: {
			return _summ.flagDirRoot.allSteps.length > 0;
		} case CType.BRANCH_CAST, CType.GET_CAST, CType.LOSE_CAST: {
			return _summ.casts.length > 0;
		} case CType.BRANCH_ITEM, CType.GET_ITEM, CType.LOSE_ITEM: {
			return _summ.items.length > 0;
		} case CType.BRANCH_SKILL, CType.GET_SKILL, CType.LOSE_SKILL: {
			return _summ.skills.length > 0;
		} case CType.BRANCH_INFO, CType.GET_INFO, CType.LOSE_INFO: {
			return _summ.infos.length > 0;
		} case CType.BRANCH_BEAST, CType.GET_BEAST, CType.LOSE_BEAST: {
			return _summ.beasts.length > 0;
		} case CType.REDISPLAY: {
			return !_summ.legacy;
		} default: {
			return true;
		}
		}
	}

	void create(Content parent, CType type, string name, void delegate(Content) applied) {
		if (_readOnly) return;
		assert (parent is null || parent.detail.owner);
		if (_putMode !is MenuID.PutContinue) {
			arrow();
			_comm.refreshToolBar();
		}
		void initial(Content c) {
			if (type is CType.CHANGE_BG_IMAGE) {
				c.backs = createBgImages(summSkin, _prop.var.etc.bgImagesDefault);
			} else if (type is CType.TALK_DIALOG) {
				c.dialogs = [new SDialog];
			} else if (type is CType.BRANCH_SKILL || type is CType.BRANCH_ITEM || type is CType.BRANCH_BEAST) {
				c.range = Range.FIELD;
			} else if (type is CType.LOSE_SKILL || type is CType.LOSE_ITEM || type is CType.LOSE_BEAST) {
				c.range = Range.FIELD;
			}
		}
		if (hasDialog(type)) {
			if (!_autoOpen || !checkOpenDialog(type)) {
				auto c = new Content(type, name);
				initial(c);
				applied(c);
				return;
			}
		} else {
			if (type is CType.START) {
				string startName = _prop.msgs.defaultStartName;
				auto sel = selection;
				if (_prop.var.etc.useCurrentStartName && sel) {
					if (auto s = (cast(Content)sel.getData()).parentStart) {
						startName = s.name;
					}
				}
				name = createNewName(startName, (string name) {
					foreach (start; _et.starts) {
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
		EventDialog dlg;
		switch (type) {
		case CType.START_BATTLE: {
			dlg = new AreaSelectDialog!(CType.START_BATTLE, Battle, "summary.battles")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.END: {
			dlg = new ClearEventDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CHANGE_AREA: {
			dlg = new AreaSelectDialog!(CType.CHANGE_AREA, Area, "summary.areas")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CHANGE_BG_IMAGE: {
			auto c = new Content(type, name);
			c.backs = createBgImages(summSkin, _prop.var.etc.bgImagesDefault);
			dlg = new BgImagesDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, c, refTarget);
			break;
		} case CType.EFFECT: {
			dlg = new EffectDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LINK_START: {
			dlg = new StartSelectDialog!(CType.LINK_START)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LINK_PACKAGE: {
			dlg = new AreaSelectDialog!(CType.LINK_PACKAGE, Package, "summary.packages")(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.TALK_MESSAGE: {
			dlg = new MessageDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.TALK_DIALOG: {
			dlg = new SpeakDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.PLAY_BGM: {
			dlg = new BgmDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.PLAY_SOUND: {
			dlg = new SeDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.WAIT: {
			dlg = new WaitEventDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CALL_START: {
			dlg = new StartSelectDialog!(CType.CALL_START)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CALL_PACKAGE: {
			dlg = new AreaSelectDialog!(CType.CALL_PACKAGE, Package, "summary.packages")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_FLAG: {
			dlg = new BrFlagDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_MULTI_STEP: {
			dlg = new BrStepNDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_STEP: {
			dlg = new BrStepULDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_SELECT: {
			dlg = new BrMemberDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_ABILITY: {
			dlg = new BrPowerDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_RANDOM: {
			dlg = new BrRandomEventDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_LEVEL: {
			dlg = new BrLevelDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_STATUS: {
			dlg = new BrStateDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_PARTY_NUMBER: {
			dlg = new BrNumEventDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_CAST: {
			dlg = new AreaSelectDialog!(CType.BRANCH_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_ITEM: {
			dlg = new BrItemDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_SKILL: {
			dlg = new BrSkillDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_INFO: {
			dlg = new AreaSelectDialog!(CType.BRANCH_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_BEAST: {
			dlg = new BrBeastDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_MONEY: {
			dlg = new MoneyEventDialog!(CType.BRANCH_MONEY)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_COUPON: {
			dlg = new BranchCouponDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_COMPLETE_STAMP: {
			dlg = new EndEventDialog!(CType.BRANCH_COMPLETE_STAMP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_GOSSIP: {
			dlg = new GossipEventDialog!(CType.BRANCH_GOSSIP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.SET_FLAG: {
			dlg = new FlagSetDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP: {
			dlg = new StepSetDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP_UP: {
			dlg = new StepPlusDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP_DOWN: {
			dlg = new StepMinusDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.REVERSE_FLAG: {
			dlg = new FlagRDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.CHECK_FLAG: {
			dlg = new FlagJudgeDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.GET_CAST: {
			dlg = new AreaSelectDialog!(CType.GET_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_ITEM: {
			dlg = new GetItemDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_SKILL: {
			dlg = new GetSkillDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_INFO: {
			dlg = new AreaSelectDialog!(CType.GET_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_BEAST: {
			dlg = new GetBeastDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_MONEY: {
			dlg = new MoneyEventDialog!(CType.GET_MONEY)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_COUPON: {
			dlg = new GetCouponDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_COMPLETE_STAMP: {
			dlg = new EndEventDialog!(CType.GET_COMPLETE_STAMP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_GOSSIP: {
			dlg = new GossipEventDialog!(CType.GET_GOSSIP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_CAST: {
			dlg = new AreaSelectDialog!(CType.LOSE_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_ITEM: {
			dlg = new LostItemDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_SKILL: {
			dlg = new LostSkillDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_INFO: {
			dlg = new AreaSelectDialog!(CType.LOSE_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_BEAST: {
			dlg = new LostBeastDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_MONEY: {
			dlg = new MoneyEventDialog!(CType.LOSE_MONEY)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_COUPON: {
			dlg = new LoseCouponDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_COMPLETE_STAMP: {
			dlg = new EndEventDialog!(CType.LOSE_COMPLETE_STAMP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_GOSSIP: {
			dlg = new GossipEventDialog!(CType.LOSE_GOSSIP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.REDISPLAY: {
			dlg = new RefreshDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.SUBSTITUTE_STEP: {
			dlg = new SubstituteStepDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SUBSTITUTE_FLAG: {
			dlg = new SubstituteFlagDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_STEP_CMP: {
			dlg = new BrStepCmpDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_FLAG_CMP: {
			dlg = new BrFlagCmpDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_RANDOM_SELECT: {
			dlg = new BrRandomSelectDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_KEY_CODE: {
			dlg = new BrKeyCodeDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CHECK_STEP: {
			dlg = new CheckStepDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_ROUND: {
			dlg = new BranchRoundDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} default: assert (0, to!string(type));
		}
		assert (applied);
		dlg.appliedEvent ~= {
			auto evt = dlg.event;
			applied(evt);

			auto undo = new UndoContent(this, _comm, _prop, _summ, _et, [evt]);
			dlg.appliedEvent.length = 0;
			dlg.appliedEvent ~= {
				appliedEdit(undo, evt);
				undo = new UndoContent(this, _comm, _prop, _summ, _et, [evt]);
			};
		};
		_editDlgs[evt] = dlg;
		dlg.closeEvent ~= {
			_editDlgs.remove(evt);
		};
		dlg.open();
	}

	@property
	bool canEdit() {
		if (_readOnly) return false;
		auto itm = selection;
		if (!itm) return false;
		auto evt = cast(Content) itm.getData();
		return hasDialog(evt.type) && checkOpenDialog(evt.type);
	}
	EventDialog edit(Content evt) {
		if (_readOnly) return null;
		if (!hasDialog(evt.type) || !checkOpenDialog(evt.type)) return null;
		auto p = evt in _editDlgs;
		if (p) {
			p.active();
			return *p;
		}
		EventDialog dlg;
		auto parent = evt.parent;
		switch (evt.type) {
		case CType.START_BATTLE: {
			dlg = new AreaSelectDialog!(CType.START_BATTLE, Battle, "summary.battles")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.END: {
			dlg = new ClearEventDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CHANGE_AREA: {
			dlg = new AreaSelectDialog!(CType.CHANGE_AREA, Area, "summary.areas")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CHANGE_BG_IMAGE: {
			dlg = new BgImagesDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, refTarget);
			break;
		} case CType.EFFECT: {
			dlg = new EffectDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LINK_START: {
			dlg = new StartSelectDialog!(CType.LINK_START)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LINK_PACKAGE: {
			dlg = new AreaSelectDialog!(CType.LINK_PACKAGE, Package, "summary.packages")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.TALK_MESSAGE: {
			dlg = new MessageDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.TALK_DIALOG: {
			dlg = new SpeakDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.PLAY_BGM: {
			dlg = new BgmDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.PLAY_SOUND: {
			dlg = new SeDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.WAIT: {
			dlg = new WaitEventDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CALL_START: {
			dlg = new StartSelectDialog!(CType.CALL_START)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CALL_PACKAGE: {
			dlg = new AreaSelectDialog!(CType.CALL_PACKAGE, Package, "summary.packages")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_FLAG: {
			dlg = new BrFlagDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_MULTI_STEP: {
			dlg = new BrStepNDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_STEP: {
			dlg = new BrStepULDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_SELECT: {
			dlg = new BrMemberDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_ABILITY: {
			dlg = new BrPowerDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_RANDOM: {
			dlg = new BrRandomEventDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_LEVEL: {
			dlg = new BrLevelDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_STATUS: {
			dlg = new BrStateDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_PARTY_NUMBER: {
			dlg = new BrNumEventDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_CAST: {
			dlg = new AreaSelectDialog!(CType.BRANCH_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_ITEM: {
			dlg = new BrItemDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_SKILL: {
			dlg = new BrSkillDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_INFO: {
			dlg = new AreaSelectDialog!(CType.BRANCH_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_BEAST: {
			dlg = new BrBeastDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_MONEY: {
			dlg = new MoneyEventDialog!(CType.BRANCH_MONEY)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_COUPON: {
			dlg = new BranchCouponDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_COMPLETE_STAMP: {
			dlg = new EndEventDialog!(CType.BRANCH_COMPLETE_STAMP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_GOSSIP: {
			dlg = new GossipEventDialog!(CType.BRANCH_GOSSIP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.SET_FLAG: {
			dlg = new FlagSetDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP: {
			dlg = new StepSetDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP_UP: {
			dlg = new StepPlusDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP_DOWN: {
			dlg = new StepMinusDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.REVERSE_FLAG: {
			dlg = new FlagRDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.CHECK_FLAG: {
			dlg = new FlagJudgeDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.GET_CAST: {
			dlg = new AreaSelectDialog!(CType.GET_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_ITEM: {
			dlg = new GetItemDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_SKILL: {
			dlg = new GetSkillDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_INFO: {
			dlg = new AreaSelectDialog!(CType.GET_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_BEAST: {
			dlg = new GetBeastDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_MONEY: {
			dlg = new MoneyEventDialog!(CType.GET_MONEY)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_COUPON: {
			dlg = new GetCouponDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_COMPLETE_STAMP: {
			dlg = new EndEventDialog!(CType.GET_COMPLETE_STAMP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.GET_GOSSIP: {
			dlg = new GossipEventDialog!(CType.GET_GOSSIP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_CAST: {
			dlg = new AreaSelectDialog!(CType.LOSE_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_ITEM: {
			dlg = new LostItemDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_SKILL: {
			dlg = new LostSkillDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_INFO: {
			dlg = new AreaSelectDialog!(CType.LOSE_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_BEAST: {
			dlg = new LostBeastDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_MONEY: {
			dlg = new MoneyEventDialog!(CType.LOSE_MONEY)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_COUPON: {
			dlg = new LoseCouponDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_COMPLETE_STAMP: {
			dlg = new EndEventDialog!(CType.LOSE_COMPLETE_STAMP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.LOSE_GOSSIP: {
			dlg = new GossipEventDialog!(CType.LOSE_GOSSIP)(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.REDISPLAY: {
			dlg = new RefreshDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.SUBSTITUTE_STEP: {
			dlg = new SubstituteStepDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SUBSTITUTE_FLAG: {
			dlg = new SubstituteFlagDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_STEP_CMP: {
			dlg = new BrStepCmpDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_FLAG_CMP: {
			dlg = new BrFlagCmpDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_RANDOM_SELECT: {
			dlg = new BrRandomSelectDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.BRANCH_KEY_CODE: {
			dlg = new BrKeyCodeDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} case CType.CHECK_STEP: {
			dlg = new CheckStepDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_ROUND: {
			dlg = new BranchRoundDialog(_comm, _prop, _tree.control.getShell(), _summ, parent, evt);
			break;
		} default: assert (0);
		}
		auto undo = new UndoContent(this, _comm, _prop, _summ, _et, [evt]);
		dlg.appliedEvent ~= {
			appliedEdit(undo, evt);
			undo = new UndoContent(this, _comm, _prop, _summ, _et, [evt]);
		};
		_editDlgs[evt] = dlg;
		dlg.closeEvent ~= {
			_editDlgs.remove(evt);
		};
		dlg.open();
		return dlg;
	}

	@property
	AbstractArea refTarget() {
		if (_et && _et.owner) {
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

	void refreshStatusLine() {
		auto itm = selection;
		if (itm) {
			_statusLine = .contentText(_comm, cast(Content) itm.getData());
		} else {
			_statusLine = "";
		}
		_comm.setStatusLine(_tree.control, _statusLine);
	}
	class TListener : TreeListener {
		override void treeCollapsed(TreeEvent e) {
			_comm.refreshToolBar();
		}
		override void treeExpanded(TreeEvent e) {
			_comm.refreshToolBar();
		}
	}
	class SListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			assert (cast(Content) e.item.getData());
			refreshConvMenu();
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
		override void dragStart(DragSourceEvent e) {
			auto itm = selection;
			e.doit = !_readOnly && itm && (cast(Content) itm.getData()).type != CType.START
				&& (cast(DragSource) e.getSource()).getControl().isFocusControl();
			if (e.doit) {
				_targ = itm;
				_parItm = _tree.getParentItem(itm);
				_dragItm = _targ;
			}
		}
		override void dragSetData(DragSourceEvent e) {
			auto itm = selection;
			if (itm && XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) {
				e.data = bytesFromXML(toXML((cast(Content)itm.getData())));
			}
		}
		override void dragFinished(DragSourceEvent e) {
			_dragItm = null;
			auto itm = _targ;
			if (itm && e.detail == DND.DROP_MOVE) {
				bool empty = _et.owner.isEmpty;
				scope (exit) {
					if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
				}
				auto c = cast(Content) itm.getData();
				_comm.delContent.call(c);
				if (_parItm) {
					assert (_parItm.getData());
					assert (itm.getData());
					assert ((cast(Content) _parItm.getData()).detail.owner);
					assert (cast(Content) itm.getData());
					(cast(Content) _parItm.getData()).remove(c);
				} else {
					_et.remove(c);
				}
				_tree.control.setRedraw(false);
				itm.dispose();
				if (_tree.editor) {
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
		void move(DropTargetEvent e) {
			if (_readOnly) {
				e.detail = DND.DROP_NONE;
				return;
			}
			if (_tree.tree) {
				e.detail = (e.item && e.item && (cast(Content)e.item.getData()).detail.owner)
					? DND.DROP_MOVE : DND.DROP_NONE;
			} else {
				auto p = _tree.editor.toControl(new Point(e.x, e.y));
				auto c = _tree.editor.getContent(p.x, p.y);
				_tree.editor.updateLightup();
				e.detail = (c && c.detail.owner) ? DND.DROP_MOVE : DND.DROP_NONE;
			}
		}
	public:
		override void dragEnter(DropTargetEvent e){
			move(e);
		}
		override void dragOver(DropTargetEvent e){
			move(e);
		}
		override void drop(DropTargetEvent e){
			if (_readOnly) return;
			e.detail = DND.DROP_NONE;
			if (!isXMLBytes(e.data)) return;
			if (!_tree.tree) {
				auto p = _tree.editor.toControl(new Point(e.x, e.y));
				auto c = _tree.editor.getContent(p.x, p.y);
				if (!c) return;
				e.item = EventEditorItem.valueOf(_tree.editor, c);
			}
			assert (cast(Item)e.item);
			if ((cast(Content)e.item.getData()).detail.owner) {
				try {
					auto node = XNode.parse(bytesToXML(e.data));
					bool samePane = _id == node.attr("paneId", false, "");
					string id = node.attr("contentId", false, "");
					string lastNextType = node.attr("lastNextType", false, "");
					auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
					auto evt = Content.createFromNode(node, ver);
					if (evt) {
						auto owner = cast(Content) e.item.getData();
						assert (owner.detail.owner);
						auto ti = cast(Item)e.item;
						auto sp = selParent(ti);
						if (!sp || sp.eventId != id) {
							// 転送先が自分の子コンテントではないなら転送成功
							bool empty = _et.owner.isEmpty;
							scope (exit) {
								if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
							}
							if (_dragItm) {
								auto top = _tree.topItem(ti);
								if (top == _tree.topItem(_dragItm)) {
									store(cast(Content)top.getData());
								} else {
									store(cast(Content)_tree.getParentItem(_dragItm).getData(), owner);
								}
							} else {
								store(owner);
							}
							if (cast(Content)_tree.getParentItem(_dragItm).getData() !is owner) {
								adjustText(owner, evt, lastNextType);
							}
							if (_insertFirst) {
								owner.insert(_prop.parent, 0, evt);
							} else {
								owner.add(_prop.parent, evt);
							}
							_tree.control.redraw();
							_comm.refContent.call(evt);
							_tree.control.setRedraw(false);
							Item itm;
							if (_tree.tree) {
								itm = createTreeItem(cast(TreeItem)ti, evt, eventText(owner, evt), _prop.images.content(evt.type));
							} else {
								_tree.editor.updateEventTree();
								itm = EventEditorItem.valueOf(_tree.editor, evt);
							}
							procTreeItem(itm);
							_tree.setSelection([itm]);
							refreshStatusLine();
							_comm.refUseCount.call();
							if (evt.detail.owner) {
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
		private Content selParent(Item targ) {
			auto itm = selection;
			if (itm) {
				while (targ) {
					if (itm == targ) {
						return cast(Content)itm.getData();
					}
					targ = _tree.getParentItem(targ);
				}
			}
			return null;
		}
	}
	private void adjustText(in Content owner, Content evt, string lastNextType) {
		if (_readOnly) return;
		if (!_prop.var.etc.adjustContentName) return;
		if (lastNextType != "" && owner.detail.nextType !is toCNextType(lastNextType)) {
			// 後続タイプが異なるので一端後続テキストをクリア
			evt.setName(_prop.parent, "");
		} else if (owner.detail.nextType !is CNextType.TEXT) {
			foreach (ct; owner.next) {
				if (ct.name == evt.name) {
					// すでに同じテキストの後続コンテントがいるので
					// 一端後続テキストをクリア
					evt.setName(_prop.parent, "");
					break;
				}
			}
		}
	}
	private CreateEvent[CType] _conts;
	private class CreateEvent {
		CType type;
		MenuItem convMenuItem;

		/* FIXME: インタフェース外の変数に触るとアクセス違反 */
		private EventTreeView _v;

		private ToolItem _itm;
		private Cursor _cursor;
		this (EventTreeView v, CType type, Cursor cursor) {
			this.type = type;
			_v = v;
			_cursor = cursor;
		}
		void create(SelectionEvent e) {
			if (_readOnly) return;
			if (_itm.getSelection()) {
				_v._comp.setCursor(_cursor);

				auto itm = _v.selection;
				if (_v._putMode is MenuID.PutQuick && itm) {
					_v._cType = type;
					_v._evtTI = _itm;
					this.outer.create(_v._shiftDown ? itm : null);
					_v.clearClickStart();
					_v.arrow();
					_itm.setSelection(false);
					if (e) e.doit = false;
					return;
				}

				if (_v._toolWin && !_v._toolWin.isDisposed()) {
					_v._toolWin.setCursor(_cursor);
				}
				if (_v._autoHideTools) {
					_v._autoHideTools.setCursor(_cursor);
				}
				_v.clearClickStart();
				_v._arrowMode = false;
				_v._cType = type;
				_v._evtTI = _itm;
				_v._comm.refreshToolBar();
				_v._comm.selContentTool.call(_v._arrowMode, _v._cType, _v._putMode, _v._autoOpen, _v._insertFirst);
			}
		}
		@property
		void ti(ToolItem ti) {
			_itm = ti;
		}
		@property
		ToolItem ti() {return _itm;}
		void convert() {
			if (_readOnly) return;
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
			if (newd.use(CArg.BG_IMAGES) && !oldd.use(CArg.BG_IMAGES)) {
				c.backs = createBgImages(summSkin, _prop.var.etc.bgImagesDefault);
			}
			if (newd.use(CArg.DIALOGS) && !oldd.use(CArg.DIALOGS)) {
				c.dialogs = [new SDialog];
			}
			sel.setImage(_prop.images.content(type));
			foreach (itm; _tree.getItems(sel)) {
				itm.setText(eventText(c, cast(Content) itm.getData()));
				procTreeItem(itm);
			}
			procTreeItem(sel);
			refreshConvMenu();
			refreshStatusLine();
			_comm.refUseCount.call();
			_comm.refreshToolBar();
			_tree.control.redraw();
		}
	}
	ToolItem createEI(CType type, ToolBar bar, RadioGroup!(ToolItem) g) {
		auto text = _prop.msgs.contentName(type);
		auto img = _prop.images.content(type);
		auto imgData = img.getImageData();
		auto cursor = new Cursor(Display.getCurrent(), imgData, imgData.width / 2, imgData.height / 2);
		_cursors ~= cursor;
		auto ce = new CreateEvent(this, type, cursor);
		auto itm = createToolItem2(_comm, bar, text, img, &ce.create, null, SWT.RADIO);
		ce.ti = itm;
		g.append(itm);
		_conts[type] = ce;
		return itm;
	}
	void initConvMenu() {
		if (_readOnly) return;
		if (!_conts.length) return;
		foreach (cGrp, cs; CTYPE_GROUP) {
			auto conv = convMenu(cGrp);
			foreach (cType; cs) {
				initConvMenu(cType, cType is CType.START ? _convM : conv);
			}
		}
	}
	void initConvMenu(CType type, Menu convMenu) {
		auto text = _prop.msgs.contentName(type);
		auto img = _prop.images.content(type);
		auto ce = _conts[type];
		if (type != CType.START) {
			ce.convMenuItem = createMenuItem2(_comm, convMenu, text, img, &ce.convert, null);
			ce.convMenuItem.setEnabled(false);
		}
	}
	class CDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto cbar = cast(CoolBar) e.widget;
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
	}
	class TDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			assert (_toolWin);
			if (_toolWin.isDisposed()) return;
			if (_toolWin.getVisible()) {
				saveToolWinPos();
			}
		}
	}
	class TCListener : ControlAdapter {
		override void controlMoved(ControlEvent e) {
			if (_autoHideTools) {
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
	class AHTCListener : ControlAdapter {
		override void controlResized(ControlEvent e) {
			if (!_autoHideTools.isVisible()) return;
			calcAutoHideSize();
		}
	}
	void calcAutoHideSize() {
		if (!_autoHideTools) return;
		auto tb = _tree.control.getBounds();
		auto ca1 = _contentsBoxArea.getBounds();
		int x = _tree.control.toDisplay(tb.x, tb.y).x;
		int y = _contentsBoxArea.toDisplay(0, ca1.y).y + ca1.height;
		auto size = _autoHideTools.computeSize(tb.width, SWT.DEFAULT);
		_autoHideTools.setBounds(new Rectangle(x, y, size.x, size.y));
	}
	class MouseTrack : Listener {
		override void handleEvent(Event e) {
			auto c = cast(Control) e.widget;
			if (!c || !_autoHideTools) return;
			if (!_et) {
				_autoHideTools.setVisible(false);
				return;
			}
			if (e.type is SWT.MouseMove && _contentsBoxArea.isVisible()) return;
			if (c !is _tree.control && !isDescendant(_autoHideTools, c) && !isDescendant(_contentsBoxArea, c)) {
				_autoHideTools.setVisible(false);
				return;
			}
			auto p = c.toDisplay(e.x, e.y);
			auto ca2 = _autoHideTools.getBounds();
			ca2.x = 0;
			ca2.y = 0;
			if (!_autoHideTools.isVisible()) {
				ca2.width = 0;
				ca2.height = 0;
			}
			auto p2 = _autoHideTools.toControl(p);
			auto ca1 = _contentsBoxArea.getBounds();
			ca1.x = 0;
			ca1.y = 0;
			if (0 == ca1.height) {
				ca1.height = _prop.var.etc.showContentsBoxHeightWhenNoToolBar;
			}
			auto p1 = _contentsBoxArea.toControl(p);
			if (ca1.contains(p1) || ca2.contains(p2)) {
				if (e.type is SWT.MouseDown && _autoHideTools.isVisible()) {
				_autoHideTools.setVisible(false);
 				} else if ((e.type is SWT.MouseDown || _tree.control.isFocusControl()) && !_autoHideTools.isVisible()) {
					calcAutoHideSize();
					_autoHideTools.setVisible(true);
				}
			} else {
				_autoHideTools.setVisible(false);
			}
		}
	}
	class PSListener : ShellAdapter {
		override void shellActivated(ShellEvent e) {
			assert (_toolWin);
			if (_toolWin.isDisposed()) return;
			auto oldAct = _comm.actToolWin;
			if (oldAct && !oldAct.isDisposed() && oldAct.isVisible()) {
				oldAct.setVisible(false);
			}
			_comm.actToolWin = _toolWin;
			_toolWin.setVisible(_toolWinVisible);
			_comm.refreshToolBar();
		}
	}
	void redraw() {
		_tree.control.redraw();
	}
	class TRDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			foreach (cur; _cursors) {
				cur.dispose();
			}
			if (!_readOnly) {
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
				_comm.refEventTemplates.remove(&refreshTemplates);
				_comm.selContentTool.remove(&selContentTool);
			}
			_comm.refTargetVersion.remove(&redraw);
			_comm.refEventTreeViewStyle.remove(&refEventTreeViewStyle);
			if (_grayFont) _grayFont.dispose();
			if (_toolWin) {
				saveToolWinPos();
				_toolWin.dispose();
			}
			if (_autoHideTools && _mTrack) {
				_autoHideTools.getDisplay().removeFilter(SWT.MouseDown, _mTrack);
				_autoHideTools.getDisplay().removeFilter(SWT.MouseEnter, _mTrack);
				_autoHideTools.getDisplay().removeFilter(SWT.MouseExit, _mTrack);
			}
			if (_tcListener) {
				_autoHideTools.getParent().removeControlListener(_tcListener);
			}
			if (_autoHideTools) {
				_autoHideTools.dispose();
			}
			foreach (dlg; _editDlgs.values) {
				dlg.forceCancel();
			}
			foreach (dlg; _commentDlgs.values) {
				dlg.forceCancel();
			}
		}
	}
	class TSListener : ShellAdapter {
		public override void shellClosed(ShellEvent e) {
			assert (_toolWin);
			if (_toolWin.isDisposed()) return;
			_toolWin.setVisible(false);
			e.doit = false;
		}
	}
	class TMListener : MouseAdapter {
		override void mouseDown(MouseEvent e) {
			if (e.button == 3) {
				arrow();
				_comm.refreshToolBar();
			}
		}
	}
	private class PutScript {
		private string _script;
		this (string script) {
			_script = script;
		}
		void put(SelectionEvent se) {
			pasteScript(_script, (se.stateMask & SWT.SHIFT) != 0);
		}
	}
	void refreshTemplates() {
		if (_readOnly) return;
		foreach (itm; _templMenu.getItems()) {
			itm.dispose();
		}
		foreach (t; _prop.var.etc.eventTemplates) {
			// 設定でコンパイルオプションが変化する可能性があるため事前コンパイルは行わない
			auto c = new PutScript(t.script);
			createMenuItem2(_comm, _templMenu, t.name, null, &c.put, () => _et !is null);
		}
		_templTI.setEnabled(0 < _templMenu.getItemCount());
	}

	/// 使用数とツリー毎の区切り線の描画。
	void drawStartInfo(PaintEvent e, Color lineColor, Color fontColor) {
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
		if (_prop.var.etc.drawCountOfUseOfStart) {
			foreach (i, itm; _tree.tree.getItems()) {
				auto c = cast(Content)itm.getData();
				assert (c);
				int count = suc.get(toStartId(c.name));
				if (0 == i) count++;
				counts[i] = .text(count);
				auto extent = e.gc.textExtent(counts[i]);
				maxW = max(maxW, extent.x);
			}
		}
		foreach (i, itm; _tree.tree.getItems()) {
			auto b = itm.getBounds();
			if (b.y + b.height <= ca.y) continue;
			if (ca.y + ca.height < b.y) break;
			if (_prop.var.etc.drawContentTreeLine && 0 < i) {
				e.gc.setForeground(lineColor);
				scope (exit) e.gc.setForeground(fore);
				e.gc.drawLine(0, b.y, ca.width, b.y);
			}
			if (_prop.var.etc.drawCountOfUseOfStart) {
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
	void drawComment(PaintEvent e, Color lineColor) {
		assert (_tree.tree !is null);
		auto fore = e.gc.getForeground();
		auto back = e.gc.getBackground();
		auto font = e.gc.getFont();
		auto fSize = font ? cast(uint)font.getFontData()[0].height : 0;
		e.gc.setFont(new Font(_tree.control.getDisplay(), dwtData(_prop.looks.textDlgFont(fSize))));
		scope (exit) e.gc.getFont().dispose();
		Rectangle[] boxes;
		TreeItem[] itms;
		void recurse(TreeItem itm) {
			boxes ~= itm.getBounds();
			itms ~= itm;
			if (_tree.getExpanded(itm)) {
				foreach (chld; itm.getItems()) {
					recurse(chld);
				}
			}
		}
		foreach (itm; _tree.tree.getItems()) {
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
		Image warningImage() {
			if (!wImg) {
				wImg = .warningImage(_prop, _tree.control.getDisplay());
			}
			return wImg;
		}
		auto dotExtent = e.gc.textExtent("...");
		foreach (i, itm; itms) {
			if (itm.getItemCount() && !itm.getExpanded()) {
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
			if (cm.length) {
				int dis = _prop.var.etc.commentBoxDistance;
				auto ib = itm.getBounds();
				cm = std.string.chomp(cm);
				auto te = e.gc.textExtent(cm);
				// 改行文字があると横幅がおかしくなるため
				// 測り直す
				te.x = 0;
				auto lines = splitLines!string(cm);
				foreach (line; lines) {
					te.x = max(e.gc.textExtent(line).x, te.x);
				}
				int tx = ib.x + ib.width + dis;
				int ty = ib.y + (ib.height - te.y) / 2;
				int bx = tx - MARGIN_L;
				int by = ty - MARGIN_T;
				int bw = te.x + MARGIN_L * 2;
				int bh = te.y + MARGIN_T * 2;
				if (by < mny) {
					ty += mny - by;
					by = ty - MARGIN_T;
				}
				if (mxy < by + bh) {
					ty -= by + bh - mxy;
					by = ty - MARGIN_T;
				}
				auto box = new Rectangle(bx, by, bw, bh);
				foreach (b; boxes) {
					if (b.intersects(box)) {
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
			if (_prop.var.etc.drawContentWarnings) {
				auto warnings = .warnings(_prop.parent, summSkin, _summ, c, _prop.var.etc.targetVersion);
				if (warnings.length) {
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
					if (wx < ca.width) {
						e.gc.drawImage(_prop.images.warning, wx, b.y + (itmH - bounds.height) / 2);
					}
					auto rect = new Rectangle(ix, b.y, _prop.var.etc.warningImageWidth, b.height);
					_warningRects ~= Warning(rect, warnings);
				}
			}
		}
		updateToolTip();
		foreach (i, lines; texts) {
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
			foreach (line; lines) {
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
		override void paintControl(PaintEvent e) {
			auto d = _tree.control.getDisplay();
			auto fore = e.gc.getForeground();
			auto back = e.gc.getBackground();
			auto lineColor = new Color(d, alphaColor(fore.getRGB(), back.getRGB(), 64));
			scope (exit) lineColor.dispose();

			drawStartInfo(e, lineColor, _grayFont);
			drawComment(e, lineColor);
		}
	}
public:
	this (Commons comm, Props prop, Summary summ, Composite parent, UndoManager undo,
			void delegate(size_t[]) forceSel,
			void delegate() refreshTopStart,
			Composite contentsBoxArea, bool readOnly) {
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
		if (!_readOnly) {
			if (_prop.var.etc.contentsFloat) {
				_toolWin = new Shell(parent.getShell(), SWT.TITLE | SWT.RESIZE | SWT.TOOL);
				_toolWin.setLayout(zeroGridLayout(1));
				_toolWin.setText(prop.msgs.tools);
				_toolWin.addShellListener(new TSListener);
				_toolWin.addMouseListener(new TMListener);
				_cbarPar = new Composite(_toolWin, SWT.NONE);
			} else if (_prop.var.etc.contentsAutoHide) {
				_autoHideTools = new Shell(parent.getShell(), SWT.NO_TRIM);
				_autoHideTools.setLayout(zeroGridLayout(1));
				_autoHideTools.addMouseListener(new TMListener);
				_cbarPar = new Composite(_autoHideTools, SWT.NONE);
				_mTrack = new MouseTrack;
				_autoHideTools.getDisplay().addFilter(SWT.MouseDown, _mTrack);
				_autoHideTools.getDisplay().addFilter(SWT.MouseEnter, _mTrack);
				_autoHideTools.getDisplay().addFilter(SWT.MouseExit, _mTrack);
			} else {
				_cbarPar = new Composite(_comp, SWT.NONE);
			}
		}
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
		if (_cbarPar) {
			_cbarPar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_cbarPar.setLayout(new FillLayout);
		}

		_comp.addDisposeListener(new TRDListener);
		refEventTreeViewStyle();

		if (!_readOnly) {
			auto shiftCaptcha = new class Listener {
				override void handleEvent(Event e) {
					if (e.type == SWT.KeyUp && e.keyCode == SWT.SHIFT) {
						_shiftDown = false;
					} else if (e.type == SWT.KeyDown && e.keyCode == SWT.SHIFT) {
						_shiftDown = true;
					}
				}
			};
			_comp.getDisplay().addFilter(SWT.KeyDown, shiftCaptcha);
			_comp.getDisplay().addFilter(SWT.KeyUp, shiftCaptcha);
			.listener(_comp, SWT.Dispose, {
				_comp.getDisplay().removeFilter(SWT.KeyDown, shiftCaptcha);
				_comp.getDisplay().removeFilter(SWT.KeyUp, shiftCaptcha);
			});
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
			_comm.refEventTemplates.add(&refreshTemplates);
			_comm.selContentTool.add(&selContentTool);
		}
		_comm.refTargetVersion.add(&redraw);
		_comm.refEventTreeViewStyle.add(&refEventTreeViewStyle);
	}
	private void refEventTreeViewStyle() {
		_comp.setRedraw(false);
		scope (exit) _comp.setRedraw(true);
		auto sel = selection;
		size_t[] ctPath = sel ? (cast(Content)sel.getData()).ctPath : [];
		auto et = _et;
		refresh(null);
		if (_tree.tree) {
			_tree.tree.dispose();
			_tree.tree = null;
		}
		if (_tree.editor) {
			_tree.editor.dispose();
			_tree.editor = null;
		}
		if (_prop.var.etc.straightEventTreeView) {
			_tree.editor = new EventEditor(_comm, _comp, SWT.BORDER | _readOnly, _summ, null);
			new EventEdit(_comm, _tree.editor, &editEnd, &createEditor);
		} else {
			_tree.tree = new Tree(_comp, SWT.SINGLE | SWT.BORDER | SWT.VIRTUAL);
			initTree(_comm, _tree.tree, true);
			if (!_readOnly) {
				new TreeEdit(_comm, _tree.tree, &editEnd, &createEditor);
			}
			_tree.tree.addPaintListener(new PaintTree);
			if (!_grayFont) {
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
		.listener(_tree.control, SWT.KeyUp, {
			_comm.refreshToolBar();
		});
		if (_mTrack) {
			_tree.control.addListener(SWT.MouseMove, _mTrack);
		}

		auto shell = _tree.control.getShell();
		{
			auto popup = new Menu(shell, SWT.POP_UP);
			createMenuItem(_comm, popup, MenuID.EditProp, &editM, &canEdit);
			new MenuItem(popup, SWT.SEPARATOR);
			createMenuItem(_comm, popup, MenuID.Comment, &writeComment, &canWriteComment);
			new MenuItem(popup, SWT.SEPARATOR);
			createMenuItem(_comm, popup, MenuID.Undo, &this.undo, () => !_readOnly && _undo.canUndo);
			createMenuItem(_comm, popup, MenuID.Redo, &this.redo, () => !_readOnly && _undo.canRedo);
			new MenuItem(popup, SWT.SEPARATOR);
			appendMenuTCPD(_comm, popup, this, true, true, true, true, true);
			new MenuItem(popup, SWT.SEPARATOR);
			createMenuItem(_comm, popup, MenuID.Cut1Content, &cut1Content, () => canDoT && _tree.getParentItem(selection));
			createMenuItem(_comm, popup, MenuID.Copy1Content, &copy1Content, &canDoC);
			createMenuItem(_comm, popup, MenuID.Delete1Content, &del1Content, () => canDoD && _tree.getParentItem(selection));
			new MenuItem(popup, SWT.SEPARATOR);
			createMenuItem(_comm, popup, MenuID.PasteInsert, &pasteInsert, &canDoP);
			new MenuItem(popup, SWT.SEPARATOR);
			createMenuItem(_comm, popup, MenuID.SwapToParent, &swapToParent, &canSwapToParent);
			createMenuItem(_comm, popup, MenuID.SwapToChild, &swapToChild, &canSwapToChild);
			new MenuItem(popup, SWT.SEPARATOR);
			createMenuItem(_comm, popup, MenuID.Expand, &expand, &canExpand);
			createMenuItem(_comm, popup, MenuID.Collapse, &collapse, &canCollapse);
			new MenuItem(popup, SWT.SEPARATOR);
			createMenuItem(_comm, popup, MenuID.ToScript, &toScript, &canToScript);
			createMenuItem(_comm, popup, MenuID.ToScriptAll, &toScriptAll, &canToScriptAll);
			new MenuItem(popup, SWT.SEPARATOR);
			createMenuItem(_comm, popup, MenuID.StartToPackage, &startToPackage, () => !_readOnly && 1 < _tree.getItemCount() && selection !is null);
			void delegate() dlg = null;
			auto convMI = createMenuItem(_comm, popup, MenuID.ConvertContent, dlg, {
				if (_readOnly) return false;
				auto itm = selection;
				if (!itm) return false;
				auto evt = cast(Content) itm.getData();
				return evt.type !is CType.START;
			}, SWT.CASCADE);
			_convM = new Menu(_tree.control.getShell(), SWT.DROP_DOWN);
/+			debug {
				new MenuItem(popup, SWT.SEPARATOR);
				createMenuItem2(_comm, popup, "debug: Create CWX &Path", null, &createCWXPath, () => selection !is null);
			}
+/			convMI.setMenu(_convM);
			initConvMenu();

			_tree.control.setMenu(popup);
		}

		if (!_readOnly) {
			auto dt = new DropTarget(_tree.control, DND.DROP_DEFAULT | DND.DROP_MOVE);
			dt.setTransfer([XMLBytesTransfer.getInstance()]);
			dt.addDropListener(new EventDropTarget);
		}
		auto ds = new DragSource(_tree.control, DND.DROP_MOVE);
		ds.setTransfer([XMLBytesTransfer.getInstance()]);
		ds.addDragListener(new EventDragSource);

		_comp.layout();
		refresh(et);
		if (ctPath.length) {
			sel = fromPath(ctPath);
			_tree.setSelection([sel]);
			_tree.showSelection();
		}
	}
	private int _parX, _parY;
	private void saveToolWinPos() {
		if (!_constructTools) return;
		assert (_toolWin);
		if (_toolWin.isDisposed()) return;
		_prop.var.contentsWin.x = _toolWin.getBounds().x - _toolWin.getParent().getBounds().x;
		_prop.var.contentsWin.y = _toolWin.getBounds().y - _toolWin.getParent().getBounds().y;
	}
	private Composite _cbarPar = null;
	private Menu _convM;
	private bool _constructTools = false;
	private bool canConvTerminal() {
		auto itm = selection;
		if (!itm) return false;
		auto evt = cast(Content) itm.getData();
		return !evt.next.length;
	}
	private Menu convMenu(CTypeGroup g) {
		void delegate() dlg = null;
		auto mi = createMenuItem(_comm, _convM, cTypeGroupToMenuID(g), dlg, g is CTypeGroup.Terminal ? &canConvTerminal : null, SWT.CASCADE);
		auto m = new Menu(_tree.control.getShell(), SWT.DROP_DOWN);
		mi.setMenu(m);
		return m;
	}
	private void constructTools() {
		if (_tree.control.isDisposed() || _constructTools) return;
		_constructTools = true;
		if (!_cbarPar) return;
		auto cbar = createCoolBar!("contents")(_comm, _cbarPar, (CoolBar cbar) {
			void createCoolItem(CoolBar cbar, ToolBar tbar, int index = -1) {
				.createCoolItem(cbar, tbar, index);
			}
			if (!_prop.var.etc.contentsFloat || _autoHideTools) {
				cbar.addMouseListener(new TMListener);
			}
			auto g = new RadioGroup!(ToolItem);
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
			_templTI = createDropDownItem(_comm, mode, MenuID.EvTemplates, null, _templMenu, () => _et && _prop.var.etc.eventTemplates.length > 0);

			_putQuickMI.setSelection(_putMode is MenuID.PutQuick);
			_putSelectMI.setSelection(_putMode is MenuID.PutSelect);
			_putContinueMI.setSelection(_putMode is MenuID.PutContinue);
			updatePutMode();
			refreshTemplates();
			createCoolItem(cbar, mode);

			auto tml = new TMListener;
			foreach (cGrp, cs; CTYPE_GROUP) {
				auto eBar = new ToolBar(cbar, SWT.FLAT);
				eBar.addMouseListener(tml);
				foreach (cType; cs) {
					createEI(cType, eBar, g);
				}
				if (cGrp is CTypeGroup.Visual) {
					createCoolItem(cbar, eBar, 2);
				} else {
					createCoolItem(cbar, eBar);
				}
			}
			initConvMenu();

			cbar.addDisposeListener(new CDListener);
		});
		if (_toolWin) {
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
			_tree.control.getShell().addShellListener(new PSListener);
		} else if (_cbarPar) {
			_cbarPar.getParent().layout(true);
			if (_autoHideTools) {
				cbar.addControlListener(new AHTCListener);
				_tcListener = new TCListener;
				_autoHideTools.getParent().addControlListener(_tcListener);
			}
		}
	}

	@property
	Control widget() {return _comp;}

	@property
	string statusLine() {return _statusLine;}

	void undo() {
		if (_readOnly) return;
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() {
		if (_readOnly) return;
		_undo.redo();
		_comm.refreshToolBar();
	}
	debug {
		void createCWXPath() {
			auto itm = selection;
			if (itm) {
				auto c = cast(Content) itm.getData();
				_comm.clipboard.setContents([new ArrayWrapperString(c.cwxPath(true))], [TextTransfer.getInstance()]);
				_comm.refreshToolBar();
			}
		}
	}
	@property
	bool canToScript() {
		return selection !is null;
	}
	@property
	bool canToScriptAll() {
		return _et !is null;
	}
	void toScript() {
		auto itm = selection;
		if (!itm) return;
		auto c = cast(Content) itm.getData();
		auto script = new CWXScript(_prop.parent, _summ);
		auto text = script.toScript([c], summSkin.evtChildOK, _summ.legacy, "\t");
		text = std.array.replace(text ~ "\n", "\n", .newline);
		_comm.clipboard.setContents([new ArrayWrapperString(text)], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}
	void toScriptAll() {
		if (!_et) return;
		auto script = new CWXScript(_prop.parent, _summ);
		auto text = script.toScript(_et.starts, summSkin.evtChildOK, _summ.legacy, "\t");
		text = std.array.replace(text ~ "\n", "\n", .newline);
		_comm.clipboard.setContents([new ArrayWrapperString(text)], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}
	private ContentCommentDialog[Content] _commentDlgs;
	@property
	bool canWriteComment() {
		if (_readOnly) return false;
		return selection !is null;
	}
	void writeComment() {
		if (_readOnly) return;
		auto itm = selection;
		if (!itm) return;
		.forceFocus(_tree.control, false);
		auto c = cast(Content) itm.getData();
		auto p = c in _commentDlgs;
		if (p) {
			p.active();
			return;
		}
		auto dlg = new ContentCommentDialog(_comm, _prop, _tree.control.getShell(), c.parent, c);
		dlg.appliedEvent ~= &redraw;
		auto undo = new UndoContent(this, _comm, _prop, _summ, _et, [c]);
		dlg.appliedEvent ~= {
			_undo ~= undo;
			undo = new UndoContent(this, _comm, _prop, _summ, _et, [c]);
			redraw();
		};
		_commentDlgs[c] = dlg;
		dlg.closeEvent ~= {
			_commentDlgs.remove(c);
		};
		dlg.open();
	}

	private void refreshConvMenu() {
		if (_readOnly) return;
		if (!_et || !selection) {
			foreach (ce; _conts.values) {
				if (ce.convMenuItem) ce.convMenuItem.setEnabled(false);
			}
		} else {
			auto c = cast(Content) selection.getData();
			foreach (ce; _conts.values) {
				if (ce.convMenuItem) ce.convMenuItem.setEnabled(c.canConvert(ce.type));
			}
		}
	}
	private void startToPackage() {
		if (_readOnly) return;
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
		void find(Item itm) {
			if (itm == startItm) return;
			auto c = cast(Content)itm.getData();
			if (c.start == start.name) {
				users ~= itm;
				conts ~= c;
			}
			foreach (cld; _tree.getItems(itm)) find(cld);
		}
		foreach (itm; _tree.getItems()) find(itm);
		auto ucp = new UndoCP(this, _comm, _prop, _summ, _et, conts, index, start);
		auto id = _comm.createPackage(start, false);
		if (id == 0) {
			ucp.dispose();
			return;
		}
		_undo ~= ucp;
		delImpl(startItm, false);
		foreach (itm; users) {
			auto c = cast(Content) itm.getData();
			switch (c.type) {
			case CType.LINK_START: {
				c.convertType(CType.LINK_PACKAGE, _prop.parent);
				c.packages = id;
			} break;
			case CType.CALL_START: {
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

	void refresh(EventTree et) {
		_comm.setStatusLine(_tree.control, "");
		_statusLine = "";
		if (_et !is et) {
			foreach (dlg; _editDlgs.values) {
				dlg.forceCancel();
			}
			foreach (dlg; _commentDlgs.values) {
				dlg.forceCancel();
			}
			_et = et;
			_tree.control.setRedraw(false);
			scope (exit) _tree.control.setRedraw(true);
			if (_tree.tree) {
				_tree.tree.removeAll();
				if (et) {
					foreach (start; et.starts) {
						auto itm = createTreeItem(_tree.tree, start, start.name, _prop.images.content(CType.START));
						createChilds(itm, start);
						_tree.setExpanded(itm, true);
					}
				}
			} else {
				_tree.editor.eventTree = _et;
			}
			if (0 < _tree.getItemCount()) {
				_tree.setSelection([_tree.getItem(0)]);
				_tree.showSelection();
			}
			if (et) {
				openToolWindow();
			} else {
				closeToolWindow();
				if (_autoHideTools) _autoHideTools.setVisible(false);
			}
			refreshStatusLine();
			_comm.refreshToolBar();
		}
	}
	void treeOpen() {
		_tree.treeExpandedAll();
		_comm.refreshToolBar();
	}
	void treeClose() {
		foreach (itm; _tree.getItems()) {
			_tree.setExpanded(itm, false);
		}
		_comm.refreshToolBar();
	}
	@property
	bool canExpandTree() {
		foreach (itm; _tree.getItems()) {
			if (_tree.getItems(itm).length && !_tree.getExpanded(itm)) {
				return true;
			}
		}
		return false;
	}
	@property
	bool canFoldTree() {
		foreach (itm; _tree.getItems()) {
			if (_tree.getItems(itm).length && _tree.getExpanded(itm)) {
				return true;
			}
		}
		return false;
	}
	@property
	bool canExpand() {
		auto itm = selection;
		if (!itm) return false;
		auto c = cast(Content)itm.getData();
		return c.next.length && !_tree.getExpanded(itm);
	}
	@property
	bool canCollapse() {
		auto itm = selection;
		if (!itm) return false;
		auto c = cast(Content)itm.getData();
		return c.next.length && _tree.getExpanded(itm);
	}
	void expand() {
		if (!canExpand) return;
		auto itm = selection;
		if (!itm) return;
		_tree.setExpanded(itm, true);
	}
	void collapse() {
		if (!canCollapse) return;
		auto itm = selection;
		if (!itm) return;
		_tree.setExpanded(itm, false);
	}
	private void editEnd(TreeItem itm, Control c) {
		editEnd(cast(Item)itm, c);
	}
	private void editEnd(EventEditorItem itm, Control c) {
		editEnd(cast(Item)itm, c);
	}
	private void editEnd(Item itm, Control c) {
		if (_readOnly) return;
		auto t = cast(Text) c;
		auto evt = (cast(Content) itm.getData());
		if (t) {
			auto text = t.getText();
			if (!text) text = "";
			if (text == evt.name) return;
			store(evt);
			if (evt.type == CType.START) {
				evt.setName(_prop.parent, createNewName(text, (string name) {
					foreach (s; _et.starts) {
						if (s !is evt && icmp(s.name, name) == 0) {
							return false;
						}
					}
					return true;
				}, true));
				itm.setText(evt.name);
			} else {
				evt.setName(_prop.parent, text);
				itm.setText(eventText(evt.parent, evt));
			}
			if (evt.type == CType.START && _tree.indexOf(itm) == 0) {
				_refreshTopStart();
			}
		} else {
			auto combo = cast(Combo) c;
			int index = combo.getSelectionIndex();
			auto data = cast(Content)_tree.getParentItem(itm).getData();
			string name;
			switch (data.type) {
			case CType.BRANCH_MULTI_STEP: {
				if (index + 1 < combo.getItemCount()) {
					name = to!(string)(index);
				} else {
					assert (index + 1 == combo.getItemCount());
					name = _prop.sys.evtChildDefault;
				}
				break;
			} case CType.BRANCH_AREA: {
				if (index < _summ.areas.length) {
					name = to!(string)(_summ.areas[index].id);
				} else {
					assert (index == _summ.areas.length);
					name = _prop.sys.evtChildDefault;
				}
				break;
			} case CType.BRANCH_BATTLE: {
				if (index < _summ.battles.length) {
					name = to!(string)(_summ.battles[index].id);
				} else {
					assert (index == _summ.battles.length);
					name = _prop.sys.evtChildDefault;
				}
				break;
			} case CType.BRANCH_STEP_CMP: {
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
		_tree.control.redraw();
		_comm.refContent.call(evt);
		refreshStatusLine();
		_comm.refreshToolBar();
		_comm.refUseCount.call();
	}
	private Combo createBoolEditor(string Create)(Content evt, Content child) {
		if (_readOnly) return null;
		string[] vals;
		vals.length = 2;
		string name = _prop.sys.evtChildTrue;
		vals[0] = mixin (Create);
		name = _prop.sys.evtChildFalse;
		vals[1] = mixin (Create);
		return createComboEditor(_comm, _prop, _tree.control, vals, vals[child.name == _prop.sys.evtChildTrue ? 0 : 1]);
	}
	private Combo createBoolEditor2(string Create)(Content evt, Content child) {
		if (_readOnly) return null;
		string[] vals;
		vals.length = 2;
		string name = _prop.sys.evtChildTrue;
		vals[0] = mixin (Create);
		name = _prop.sys.evtChildFalse;
		vals[1] = mixin (Create);
		return createComboEditor(_comm, _prop, _tree.control, vals, vals[child.name == _prop.sys.evtChildTrue ? 0 : 1]);
	}
	private Combo createNumEditor(string Create)(Content evt, Content child, ulong[] nums) {
		if (_readOnly) return null;
		string[] vals;
		vals.length = nums.length + 1;
		int index = nums.length;
		foreach (i, n; nums) {
			string name = to!(string)(n);
			vals[i] = mixin (Create);
			if (name == child.name) {
				index = i;
			}
		}
		string name = _prop.sys.evtChildDefault;
		vals[$ - 1] = mixin (Create);
		return createComboEditor(_comm, _prop, _tree.control, vals, vals[index]);
	}
	private Combo createAreaSelectEditor(string Create, A)(Content evt, Content child, A[] areas) {
		if (_readOnly) return null;
		ulong[] nums;
		nums.length = areas.length;
		foreach (i, area; areas) {
			nums[i] = area.id;
		}
		return createNumEditor!(Create)(evt, child, nums);
	}
	private Combo createTrioEditor(string Create)(Content evt, Content child) {
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
		if (child.name == _prop.sys.evtChildEq) {
			index = 2;
		} else if (child.name == _prop.sys.evtChildLesser) {
			index = 1;
		} else {
			index = 0;
		}
		return createComboEditor(_comm, _prop, _tree.control, vals, vals[index]);
	}
	private Control createEditor(TreeItem itm) {
		return createEditor(cast(Item)itm);
	}
	private Control createEditor(EventEditorItem itm) {
		return createEditor(cast(Item)itm);
	}
	private Control createEditor(Item itm) {
		if (_readOnly) return null;
		auto parent = _tree.getParentItem(itm);
		if (parent) {
			if ((cast(Content)parent.getData()).detail.nextType == CNextType.TEXT) {
				return createTextEditor(_comm, _prop, _tree.control, (cast(Content)itm.getData()).name);
			}
		} else {
			return createTextEditor(_comm, _prop, _tree.control, (cast(Content)itm.getData()).name);
		}
		auto data = cast(Content)parent.getData();
		auto c = cast(Content)itm.getData();
		switch (data.type) {
		case CType.BRANCH_FLAG: {
			return createBoolEditor!("evtChildBrFlag(_prop, _summ, evt.flag, name)")(data, c);
		} case CType.BRANCH_MULTI_STEP: {
			Step step = _summ.flagDirRoot.findStep(data.step);
			ulong[] nums;
			ulong count = step is null ? _prop.looks.stepMaxCount : step.count;
			for (ulong i = 0; i < count; i++) {
				nums ~= i;
			}
			return createNumEditor!("evtChildBrStepN(_prop, _summ, evt.step, name)")(data, c, nums);
		} case CType.BRANCH_STEP: {
			return createBoolEditor!("evtChildBrStepUL(_prop, _summ, evt.step, evt.stepValue, name)")(data, c);
		} case CType.BRANCH_SELECT: {
			return createBoolEditor!("evtChildBrMember(_prop, evt.targetAll, evt.random, name)")(data, c);
		} case CType.BRANCH_ABILITY: {
			return createBoolEditor!("evtChildBrPower(_prop, evt.targetS, evt.physical, evt.mental, evt.signedLevel, name)")(data, c);
		} case CType.BRANCH_RANDOM: {
			return createBoolEditor!("evtChildBrRandom(_prop, evt.percent, name)")(data, c);
		} case CType.BRANCH_LEVEL: {
			return createBoolEditor!("evtChildBrLevel(_prop, evt.unsignedLevel, evt.average, name)")(data, c);
		} case CType.BRANCH_STATUS: {
			return createBoolEditor!("evtChildBrState(_prop, evt.targetNS, evt.status, name)")(data, c);
		} case CType.BRANCH_PARTY_NUMBER: {
			return createBoolEditor!("evtChildBrNum(_prop, evt.partyNumber, name)")(data, c);
		} case CType.BRANCH_AREA: {
			return createAreaSelectEditor!("evtChildBrArea(_prop, _summ.areas, name)")(data, c, _summ.areas);
		} case CType.BRANCH_BATTLE: {
			return createAreaSelectEditor!("evtChildBrBattle(_prop, _summ.battles, name)")(data, c, _summ.battles);
		} case CType.BRANCH_IS_BATTLE: {
			return createBoolEditor!("evtChildBrOnBattle(_prop, name)")(data, c);
		} case CType.BRANCH_CAST: {
			return createBoolEditor!("evtChildBrCast(_prop, _summ, evt.casts, name)")(data, c);
		} case CType.BRANCH_ITEM: {
			return createBoolEditor!("evtChildBrItem(_prop, _summ, evt.item, evt.range, evt.cardNumber, name)")(data, c);
		} case CType.BRANCH_SKILL: {
			return createBoolEditor!("evtChildBrSkill(_prop,  _summ, evt.skill, evt.range, evt.cardNumber, name)")(data, c);
		} case CType.BRANCH_BEAST: {
			return createBoolEditor!("evtChildBrBeast(_prop, _summ, evt.beast, evt.range, evt.cardNumber, name)")(data, c);
		} case CType.BRANCH_INFO: {
			return createBoolEditor!("evtChildBrInfo(_prop, _summ, evt.info, name)")(data, c);
		} case CType.BRANCH_MONEY: {
			return createBoolEditor!("evtChildBrMoney(_prop, evt.money, name)")(data, c);
		} case CType.BRANCH_COUPON: {
			return createBoolEditor!("evtChildBrCoupon(_prop, evt.range, evt.coupon, name)")(data, c);
		} case CType.BRANCH_COMPLETE_STAMP: {
			return createBoolEditor!("evtChildBrEnd(_prop, evt.completeStamp, name)")(data, c);
		} case CType.BRANCH_GOSSIP: {
			return createBoolEditor!("evtChildBrGossip(_prop, evt.gossip, name)")(data, c);
		} case CType.BRANCH_STEP_CMP: {
			return createTrioEditor!("evtChildBrStepCmp(_prop, _summ, evt.step, evt.step2, name)")(data, c);
		} case CType.BRANCH_FLAG_CMP: {
			return createBoolEditor!("evtChildBrFlagCmp(_prop, _summ, evt.flag, evt.flag2, name)")(data, c);
		} case CType.BRANCH_RANDOM_SELECT: {
			return createBoolEditor!("evtChildBrRandomSelect(_prop, evt, name)")(data, c);
		} case CType.BRANCH_KEY_CODE: {
			return createBoolEditor!("evtChildBrKeyCode(_prop, evt, name)")(data, c);
		} case CType.BRANCH_ROUND: {
			return createBoolEditor!("evtChildBrRound(_prop, evt, name)")(data, c);
		} default:
		}
		return null;
	}
	/// Params:
	/// parent = 親イベント。
	/// e = イベント。名称が書き換えられる。
	/// Returns: テキスト。
	private string eventText(Content parent, Content e) {
		return .eventText(_comm, _summ, parent, e, _readOnly != SWT.NONE);
	}
	/// 空のテキストは入力ガイドを代わりに表示。
	private void procTreeItem(Item targ) {
		auto itm = cast(TreeItem)targ;
		if (!itm) return;
		auto c = cast(Content) itm.getData();
		assert (c !is null);
		if (c.parent && c.parent.detail.nextType == CNextType.TEXT) {
			if (c.name.length) {
				itm.setForeground(_tree.control.getForeground());
			} else {
				itm.setForeground(_grayFont);
				if (_prop.var.etc.showInputGuide) {
					itm.setText(summSkin.evtChildOK);
				} else {
					itm.setText(" ");
				}
			}
		}
	}
	/// 末尾のアイテムを返す。
	private Item createChilds(Item parentItm, Content evt) {
		if (!evt.detail.owner) return parentItm;
		if (auto parent = cast(TreeItem)parentItm) {
			parent.removeAll();
			Item itm = parent;
			foreach (c; evt.next) {
				auto itm2 = createTreeItem(parent, c, eventText(evt, c), _prop.images.content(c.type));
				itm = itm2;
				if (c.detail.owner) {
					itm = createChilds(itm2, c);
				}
				procTreeItem(itm2);
				_tree.setExpanded(itm2, true);
			}
			return itm;
		} else {
			_tree.editor.updateEventTree();
			while (evt.next.length) {
				evt = evt.next[$ - 1];
			}
			return EventEditorItem.valueOf(_tree.editor, evt);
		}
	}

	@property
	EventTree eventTree() {
		return _et;
	}
	@property
	bool isFocusControl() {
		return _tree.control.isFocusControl();
	}

	private static void udImpl(int To)(EventTreeView v, Commons comm, EventTree et, Content c, bool store) {
		if (!et) return;
		if (v) v._tree.control.setRedraw(false);
		scope (exit) if (v) v._tree.control.setRedraw(true);
		auto pc = c.parent;
		int i, j;
		auto path = c.ctPath;
		if (pc) {
			i = cCountUntil!("a is b")(pc.next, c);
			j = i + To;
			if (j < 0 || pc.next.length <= j) return;
			if (v && store) {
				v.store(pc);
			}
			comm.delContent.call(pc.next[i]);
			comm.delContent.call(pc.next[j]);
			pc.swapContent(i, j);
		} else {
			i = cCountUntil!("a is b")(et.starts, c);
			j = i + To;
			if (j < 0 || et.starts.length <= j) return;
			if (v && store) {
				v.storeSwap(i, j);
			}
			comm.delContent.call(et.starts[i]);
			comm.delContent.call(et.starts[j]);
			et.swapStart(i, j);
		}
		if (v) {
			if (v._tree.tree) {
				static if (To == -1) {
					treeItemUp(cast(TreeItem)v.fromPath(path));
				} else static if (To == 1) {
					treeItemDown(cast(TreeItem)v.fromPath(path));
				} else static assert (0);
			} else {
				v._tree.editor.updateEventTree();
			}
			v._tree.showSelection();
			if (!pc && (i == 0 || j == 0)) {
				v._refreshTopStart();
			}
		}
	}
	@property
	bool canUp() {
		return canUpImpl(true);
	}
	@property
	bool canDown() {
		return canDownImpl(true);
	}
	private bool canUpImpl(bool swapPC) {
		if (_readOnly) return false;
		auto itm = selection;
		if (!itm) return false;
		auto par = _tree.getParentItem(itm);
		if (par) {
			if (0 < _tree.indexOf(par, itm)) return true;
		} else {
			if (0 < _tree.indexOf(itm)) return true;
		}
		if (!swapPC) return false;
		if (!_tree.editor) return false;
		// 垂直表示時は上下移動に加えて親子の入れ替えも試みる
		return canSwapToParent;
	}
	private bool canDownImpl(bool swapPC) {
		if (_readOnly) return false;
		auto itm = selection;
		if (!itm) return false;
		auto par = _tree.getParentItem(itm);
		if (par) {
			if (_tree.indexOf(par, itm) + 1 < _tree.getItemCount(par)) return true;
		} else {
			if (_tree.indexOf(itm) + 1 < _tree.getItemCount()) return true;
		}
		if (!swapPC) return false;
		if (!_tree.editor) return false;
		// 垂直表示時は上下移動に加えて親子の入れ替えも試みる
		return canSwapToChild;
	}
	private void up(Item itm, bool store) {
		if (_readOnly) return;
		if (!itm) return;
		udImpl!(-1)(this, _comm, _et, cast(Content) itm.getData(), store);
		_comm.refreshToolBar();
	}
	void up() {
		if (!canUpImpl(false)) {
			if (canSwapToParent) {
				swapToParent();
			}
			return;
		}
		auto itm = selection;
		if (itm) up(itm, true);
	}
	private void down(Item itm, bool store) {
		if (_readOnly) return;
		if (!itm) return;
		udImpl!(1)(this, _comm, _et, cast(Content) itm.getData(), store);
		_comm.refreshToolBar();
	}
	void down() {
		if (!canDownImpl(false)) {
			if (canSwapToChild) {
				swapToChild();
			}
			return;
		}
		auto itm = selection;
		if (itm) down(itm, true);
	}

	@property
	bool canSwapToParent() {
		if (_readOnly) return false;
		auto itm = selection;
		auto c = cast(Content)itm.getData();
		if (!c.parent) return false;
		if (c.parent.type == CType.START) return false;
		if (c.parent.next.length != 1) return false;
		if (!c.detail.owner) return false;
		return true;
	}
	@property
	bool canSwapToChild() {
		if (_readOnly) return false;
		auto itm = selection;
		auto c = cast(Content)itm.getData();
		if (c.type == CType.START) return false;
		if (c.next.length != 1) return false;
		if (!c.next[0].detail.owner) return false;
		return true;
	}
	/// イベントコンテントの親子を入れ替える。
	private void swapToPCImpl(Item parent, Item child, Item selTarg) {
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
		foreach (c; next.next.dup) {
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
		if (_tree.tree) {
			parent.setText(eventText(parPar, next));
			child.setText(eventText(next, par));
			parent.setData(next);
			child.setData(par);
			parent.setImage(_prop.images.content(next.type));
			child.setImage(_prop.images.content(par.type));
			procTreeItem(parent);
			procTreeItem(child);
			foreach (cc; _tree.getItems(child)) {
				cc.setText(eventText(par, cast(Content)cc.getData()));
				procTreeItem(cc);
			}
			_tree.setSelection([selTarg]);
		} else {
			_tree.editor.updateEventTree();
		}
		_tree.showSelection();
	}
	private void swapToParent() {
		if (_readOnly) return;
		if (!canSwapToParent) return;
		auto itm = selection;
		auto par = _tree.getParentItem(itm);
		swapToPCImpl(par, itm, par);
	}
	private void swapToChild() {
		if (_readOnly) return;
		if (!canSwapToChild) return;
		auto par = selection;
		auto itm = _tree.getItem(par, 0);
		swapToPCImpl(par, itm, itm);
	}

	void openToolWindow() {
		constructTools();
		if (_readOnly) return;
		if (_toolWin) {
			if (_toolWin.isDisposed()) return;
			if (_et) {
				if (_opened) {
					_toolWin.setVisible(true);
					_toolWinVisible = true;
				} else {
					_opened = true;
					_toolWin.setVisible(true);
					_toolWinVisible = true;
				}
			} else {
				_toolWinVisible = true;
			}
			_comm.refreshToolBar();
		}
	}
	void closeToolWindow() {
		if (_readOnly) return;
		if (_toolWin) {
			if (_toolWin.isDisposed()) return;
			_toolWin.setVisible(false);
			_toolWinVisible = false;
		}
	}

	void refreshTreeName() {
		_tree.getItems()[0].setText(_et.name);
		_tree.control.redraw();
		refreshStatusLine();
	}

	@property
	private Content insertOwner(bool tryInsert) {
		auto itm = selection;
		if (!itm) return null;
		auto owner = cast(Content) itm.getData();
		assert (owner);
		if (tryInsert || owner.detail.owner) return owner;
		return null;
	}
	private void addContents(bool stored, Content[] cs, Content[] refCS, bool tryInsert, string lastNextType = "") {
		if (_readOnly) return;
		auto itm = selection;
		if (!itm) return;
		auto owner = insertOwner(tryInsert);
		if (!owner) return;
		bool empty = _et.owner.isEmpty;
		scope (exit) {
			if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
		}
		Content[] cs2;
		foreach (ct; cs) {
			if (ct.type is CType.START) continue;
			cs2 ~= ct;
		}
		if (!cs2.length) return;

		Content last = null, allLast = null;
		int index = -1;
		if (tryInsert && owner.parent) {
			// cs2内に子コンテントを持てるコンテントが
			// 含まれている場合は挿入する
			void recurse(Content c) {
				if (c.detail.owner) {
					last = c;
				}
				allLast = c;
				foreach (cc; c.next) {
					recurse(cc);
				}
			}
			foreach (c; cs2) {
				recurse(c);
			}
		}
		if (!last && !owner.detail.owner) return;

		_tree.control.setRedraw(false);
		scope (exit) _tree.control.setRedraw(true);
		if (stored) store(owner);
		if (last) {
			cs2[0].setName(_prop.parent, owner.name);
			auto parent = owner.parent;
			index = parent.next.countUntil(owner);
			parent.remove(owner);
			if (_prop.var.etc.adjustContentName) {
				owner.setName(_prop.parent, "");
			}
			last.add(_prop.parent, owner);
			owner = parent;
			itm = _tree.getParentItem(itm);
		}
		bool insertFirst = (index == -1 && _insertFirst);
		Content lastCt = null;
		int i = 0;
		foreach (ct; cs2) {
			if (index == -1) {
				adjustText(owner, ct, lastNextType);
				if (insertFirst) {
					owner.insert(_prop.parent, i, ct);
					lastCt = ct;
					i++;
				} else {
					owner.add(_prop.parent, ct);
				}
			} else {
				owner.insert(_prop.parent, index, ct);
				index = -1;
			}
			_comm.refContent.call(ct);
		}
		auto lastItm = createChilds(itm, owner);
		if (lastCt) {
			while (lastCt.next.length) {
				lastCt = lastCt.next[$ - 1];
			}
			Item find(Item itm) {
				if (lastCt is itm.getData()) {
					return itm;
				} else {
					foreach (child; _tree.getItems(itm)) {
						auto f = find(child);
						if (f) return f;
					}
					return null;
				}
			}
			lastItm = find(itm);
		} else if (last) {
			Item findLast(Item itm) {
				if (allLast is itm.getData()) {
					return itm;
				} else {
					foreach (child; _tree.getItems(itm)) {
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
		_tree.control.redraw();
		_comm.refUseCount.call();
		refreshStatusLine();
		_comm.refreshToolBar();
	}
	@property
	private int insertStartIndex() {
		auto sel = selection;
		if (sel) {
			return _tree.indexOf(_tree.topItem(sel)) + 1;
		} else {
			return 1;
		}
	}
	private void addStarts(bool stored, Content[] cs, Content[] refCS = []) {
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
		foreach (ct; cs) {
			if (ct.type !is CType.START) continue;
			cs2 ~= ct;
		}
		if (!cs2.length) return;

		auto top = _tree.getTopItem();
		if (stored) storeInsert(index, cs2.length);
		Item sItm = null, lastItm = null;
		foreach (i, c; cs2) {
			if (!c.type is CType.START) continue;
			auto oldName = c.name;
			c.setName(_prop.parent, createNewName(c.name, (string name) {
				foreach (s; _et.starts) {
					if (icmp(s.name, name) == 0) {
						return false;
					}
				}
				foreach (s; cs2) {
					if (s is c) continue;
					if (icmp(s.name, name) == 0) {
						return false;
					}
				}
				return true;
			}, true));
			if (c.name != oldName) {
				void recurse(Content[] cs) {
					foreach (ct; cs) {
						if (ct.start == oldName) {
							ct.start = c.name;
						}
						recurse(ct.next);
					}
				}
				recurse(refCS);
			}
			_et.insert(index + i, c);
			if (_tree.tree) {
				sItm = createTreeItem(_tree.tree, c, c.name, _prop.images.content(c.type), index + i);
			} else {
				sItm = EventEditorItem.valueOf(_tree.editor, c);
			}
			lastItm = createChilds(sItm, c);
			_tree.setExpanded(sItm, true);
			_comm.refContent.call(c);
		}
		if (!sItm) return;
		if (lastItm) _tree.setSelection([lastItm]);
		_tree.showSelection();
		_tree.control.redraw();
		_comm.refUseCount.call();
		refreshStatusLine();
		_comm.refreshToolBar();
	}

	override {
		void cut(SelectionEvent se) {
			if (_readOnly) return;
			auto itm = selection;
			if (itm && itm !is _tree.getItems()[0]) {
				copy(se);
				del(se);
			}
		}
		void copy(SelectionEvent se) {
			auto itm = selection;
			if (itm) {
				auto c = cast(Content)itm.getData();
				XMLtoCB(_prop, _comm.clipboard, toXML(c));
				_comm.refreshToolBar();
			}
		}
		void paste(SelectionEvent se) {
			if (_readOnly) return;
			pasteImpl(false);
		}
		void del(SelectionEvent se) {
			if (_readOnly) return;
			auto itm = selection;
			if (itm && itm !is _tree.getItems()[0]) {
				_tree.control.setRedraw(false);
				scope(exit) _tree.control.setRedraw(true);
				delImpl(itm, true);
				_comm.refUseCount.call();
				_comm.refreshToolBar();
			}
		}
		void clone(SelectionEvent se) {
			if (_readOnly) return;
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			auto itm = selection;
			auto parItm = _tree.getParentItem(itm);
			if (parItm) {
				_tree.setSelection([parItm]);
			}
			paste(se);
		}
		@property
		bool canDoTCPD() {
			return !_readOnly && _et !is null && _tree.control.isFocusControl();
		}
		@property
		bool canDoT() {
			auto itm = selection;
			return !_readOnly && itm && itm !is _tree.getItems()[0];
		}
		@property
		bool canDoC() {
			return selection !is null;
		}
		@property
		bool canDoP() {
			return !_readOnly && _et !is null && (CBisXML(_comm.clipboard) || CBisText(_comm.clipboard));
		}
		@property
		bool canDoD() {
			return !_readOnly && canDoT;
		}
		@property
		bool canDoClone() {
			return !_readOnly && canDoC;
		}
	}
	private string toXML(in Content c, bool shallow = false) {
		auto opt = new XMLOption(_prop.sys);
		opt.shallow = shallow;
		auto node = c.toNode(opt);
		CNextType next;
		if (c.parent) {
			next = c.parent.detail.nextType;
		} else {
			assert (c.type is CType.START);
			next = CNextType.TEXT;
		}
		node.newAttr("lastNextType", fromCNextType(next));
		node.newAttr("paneId", _id);
		return node.text;
	}
	private void cut1Content() {
		if (_readOnly) return;
		auto itm = selection;
		if (itm && _tree.getParentItem(itm)) {
			copy1Content();
			del1Content();
		}
	}
	private void copy1Content() {
		if (_readOnly) return;
		auto itm = selection;
		if (itm) {
			auto c = cast(Content)itm.getData();
			XMLtoCB(_prop, _comm.clipboard, toXML(c, true));
			_comm.refreshToolBar();
		}
	}
	private void pasteInsert() {
		if (_readOnly) return;
		pasteImpl(true);
	}
	private void del1Content() {
		if (_readOnly) return;
		auto itm = selection;
		if (itm && _tree.getParentItem(itm)) {
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
			foreach (i, next; c.next) {
				if (_prop.var.etc.adjustContentName) {
					if (c.next.length == 1 && lastNextType == fromCNextType(next.detail.nextType)) {
						next.setName(_prop.parent, c.name);
					}
				}
				adjustText(owner, next, lastNextType);
				owner.insert(_prop.parent, insertIndex + i, next);
			}
			createChilds(ownerItm, owner);
			_comm.refUseCount.call();
			_comm.refreshToolBar();
		}
	}
	private void pasteImpl(bool tryInsert) {
		if (_readOnly) return;
		if (!_et) return;
		string c;
		try {
			c = CBtoXML(_comm.clipboard);
		} catch (Exception e) {
			// たまにアクセス違反が起こる
			debugln(e);
			return;
		}
		if (c) {
			try {
				auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
				auto node = XNode.parse(c);
				string id = node.attr("contentId", false);
				string lastNextType = node.attr("lastNextType", false, "");
				auto evt = Content.createFromNode(node, ver);
				if (!evt) return;
				if (evt.type == CType.START) {
					addStarts(true, [evt]);
				} else {
					addContents(true, [evt], [], tryInsert, lastNextType);
				}
				_comm.refreshToolBar();
				return;
			} catch (Exception e) {
				debugln(e);
			}
		}
		auto script = cast(ArrayWrapperString) _comm.clipboard.getContents(TextTransfer.getInstance());
		if (script) {
			pasteScript(script.array.idup, tryInsert);
		}
	}
	void pasteScript(string script, bool tryInsert) {
		if (_readOnly) return;
		if (!_et) return;
		string base = script;
		CompileOption opt;
		try {
			try {
				opt.linkId = _prop.var.etc.linkCard;

				auto compiler = new CWXScript(_prop.parent, _summ);
				auto vars = compiler.eatEmptyVars(script, opt);
				if (vars.length) {
					auto dlg = new ScriptVarSetDialog(_comm, _summ, _tree.control.getShell(), vars, script, base, opt);
					dlg.appliedEvent ~= {
						putContents(dlg.contents, tryInsert);
					};
					dlg.open();
				} else {
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
	void putContents(Content[] cs, bool tryInsert) {
		if (_readOnly) return;
		if (!_et) return;
		if (!cs.length) return;
		Content[] starts;
		Content[] contents;
		foreach (c; cs) {
			if (c.type is CType.START) {
				starts ~= c;
			} else {
				contents ~= c;
			}
		}
		int si = insertStartIndex;
		bool s = starts.length > 0;
		if (s) tryInsert = false;
		auto owner = insertOwner(tryInsert);
		bool c = contents.length && owner;
		if (s && c) {
			storeContentAndInsert(owner, si, starts.length);
			addContents(false, contents, cs, tryInsert);
			addStarts(false, starts, cs);
		} else if (s) {
			addStarts(true, starts);
		} else if (c) {
			addContents(true, contents, [], tryInsert);
		} else {
			return;
		}
		_comm.refreshToolBar();
	}
	private void delImpl(Item itm, bool store) {
		if (_readOnly) return;
		bool empty = _et.owner.isEmpty;
		scope (exit) {
			if (empty != _et.owner.isEmpty) _comm.refEventTree.call(_et);
		}
		auto ownerItm = _tree.getParentItem(itm);
		auto c = cast(Content) itm.getData();
		_comm.delContent.call(c);
		if (ownerItm) {
			auto owner = cast(Content) ownerItm.getData();
			if (store) this.store(owner);
			owner.remove(c);
		} else {
			if (store) this.storeDelete(.cCountUntil!("a is b")(_et.starts, c), c);
			_et.remove(c);
		}
		itm.dispose();
		if (_tree.editor) {
			_tree.editor.updateEventTree();
		}
	}
	private static void delImpl(EventTreeView v, Commons comm, EventTree et, Content c) {
		if (v) {
			v.delImpl(v.fromPath(c.ctPath), false);
		} else {
			bool empty = et.owner.isEmpty;
			scope (exit) {
				if (empty != et.owner.isEmpty) comm.refEventTree.call(et);
			}
			comm.delContent.call(c);
			if (c.parent) {
				c.parent.remove(c);
			} else {
				et.remove(c);
			}
		}
	}
	private void __refreshCardImpl(Item evt) {
		foreach (childItm; _tree.getItems(evt)) {
			auto child = cast(Content) childItm.getData();
			childItm.setText(eventText(cast(Content) evt.getData(), child));
			if (child.detail.owner) {
				__refreshCardImpl(childItm);
			}
			procTreeItem(childItm);
		}
	}
	private void __refreshCard() {
		if (_tree.control.isDisposed()) return;
		if (_et) {
			if (_tree.editor) {
				_tree.editor.updateEventTree();
				return;
			}
			foreach (itm; _tree.getItems()) {
				__refreshCardImpl(itm);
			}
			refreshStatusLine();
		}
	}
	private void __refreshEventTextImpl(Content par, Item itm) in {
		assert (par.detail.owner);
	} body {
		auto e = cast(Content) itm.getData();
		itm.setText(eventText(par, e));
		if (e.detail.owner) {
			foreach (child; _tree.getItems(itm)) {
				__refreshEventTextImpl(e, child);
			}
		} else {
			assert (!_tree.getItems(itm).length);
		}
		procTreeItem(itm);
	}
	private void __refreshEventText() {
		if (_et) {
			if (_tree.editor) {
				_tree.editor.updateEventTree();
				return;
			}
			foreach (itm; _tree.getItems()) {
				auto start = cast(Content) itm.getData();
				assert (start.type == CType.START);
				itm.setText(start.name);
				foreach (child; _tree.getItems(itm)) {
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
	private void __refreshFlagAndStep(Flag[] flags, Step[] steps) {
		if (flags.length || steps.length) {
			__refreshCard();
			if (_prop.var.etc.showVariableValuesInEventText) {
				__refreshEventText();
			}
		}
	}
	private void __refreshPath(string from, string to, bool isDir) {refreshStatusLine();}
	private void __refreshPaths(string path) {refreshStatusLine();}
	private void __deletePaths() {refreshStatusLine();}
	private void __replacePaths(string from, string to) {refreshStatusLine();}

	private bool openCWXPathImpl(T)(T itm, string path, bool shellActivate) {
		auto cate = cpcategory(path);
		if (cate == "") {
			auto index = cpindex(path);
			if (index >= _tree.getItemCount(itm)) return false;
			auto child = _tree.getItem(itm, index);
			path = cpbottom(path);
			if (cpempty(path) || cpcategory(path) != "") {
				forceFocus(_tree.control, shellActivate);
				_tree.select(child);
				_tree.showSelection();
				refreshStatusLine();
				if (cphasattr(path, "opendialog")) {
					auto d = edit();
					if (d) {
						// ダイアログ無し、もしくは開けない状態のコンテント
						_comm.refreshToolBar();
						return true;
					}
					if (!cpempty(path)) {
						return d.openCWXPath(path, shellActivate);
					}
				}
				_comm.refreshToolBar();
				return true;
			} else {
				return openCWXPathImpl(child, path, shellActivate);
			}
		}
		return false;
	}
	bool openCWXPath(string path, bool shellActivate) {
		return openCWXPathImpl(_tree, path, shellActivate);
	}
	@property
	string[] openedCWXPath() {
		string[] r;
		if (_et) {
			auto e = selection;
			if (e) {
				auto c = cast(Content) e.getData();
				assert (c);
				r ~= c.cwxPath(true);
			} else {
				r ~= _et.cwxPath(true);
			}
		}
		return r;
	}
}

string eventText(Commons comm, Summary summ, Content parent, Content e, bool readOnly) in {
	assert (!parent || parent.detail.owner);
} body {
	if (!parent) return e.name;
	auto prop = comm.prop;
	if (parent.detail.nextType == CNextType.TEXT) {
		if (prop.var.etc.showVariableValuesInEventText) {
			string[string] flags;
			string[string] steps;
			string[char] names;
			getPreviewValues(prop, summ, SPCHAR_TEXT, names, flags, steps);
			return simpleFormatMsg(e.name, flags, steps, names);
		} else {
			return e.name;
		}
	}
	string name = e.name;
	string r;
	switch (parent.type) {
	case CType.BRANCH_FLAG: {
		r = evtChildBrFlag(prop, summ, parent.flag, name);
		break;
	} case CType.BRANCH_MULTI_STEP: {
		r = evtChildBrStepN(prop, summ, parent.step, name);
		break;
	} case CType.BRANCH_STEP: {
		r = evtChildBrStepUL(prop, summ, parent.step, parent.stepValue, name);
		break;
	} case CType.BRANCH_SELECT: {
		r = evtChildBrMember(prop, parent.targetAll, parent.random, name);
		break;
	} case CType.BRANCH_ABILITY: {
		r = evtChildBrPower(prop, parent.targetS, parent.physical, parent.mental, parent.signedLevel, name);
		break;
	} case CType.BRANCH_RANDOM: {
		r = evtChildBrRandom(prop, parent.percent, name);
		break;
	} case CType.BRANCH_LEVEL: {
		r = evtChildBrLevel(prop, parent.unsignedLevel, parent.average, name);
		break;
	} case CType.BRANCH_STATUS: {
		r = evtChildBrState(prop, parent.targetNS, parent.status, name);
		break;
	} case CType.BRANCH_PARTY_NUMBER: {
		r = evtChildBrNum(prop, parent.partyNumber, name);
		break;
	} case CType.BRANCH_AREA: {
		r = evtChildBrArea(prop, summ.areas, name);
		break;
	} case CType.BRANCH_BATTLE: {
		r = evtChildBrBattle(prop, summ.battles, name);
		break;
	} case CType.BRANCH_IS_BATTLE: {
		r = evtChildBrOnBattle(prop, name);
		break;
	} case CType.BRANCH_CAST: {
		r = evtChildBrCast(prop, summ, parent.casts, name);
		break;
	} case CType.BRANCH_ITEM: {
		r = evtChildBrItem(prop, summ, parent.item, parent.range, parent.cardNumber, name);
		break;
	} case CType.BRANCH_SKILL: {
		r = evtChildBrSkill(prop, summ, parent.skill, parent.range, parent.cardNumber, name);
		break;
	} case CType.BRANCH_BEAST: {
		r = evtChildBrBeast(prop, summ, parent.beast, parent.range, parent.cardNumber, name);
		break;
	} case CType.BRANCH_INFO: {
		r = evtChildBrInfo(prop, summ, parent.info, name);
		break;
	} case CType.BRANCH_MONEY: {
		r = evtChildBrMoney(prop, parent.money, name);
		break;
	} case CType.BRANCH_COUPON: {
		r = evtChildBrCoupon(prop, parent.range, parent.coupon, name);
		break;
	} case CType.BRANCH_COMPLETE_STAMP: {
		r = evtChildBrEnd(prop, parent.completeStamp, name);
		break;
	} case CType.BRANCH_GOSSIP: {
		r = evtChildBrGossip(prop, parent.gossip, name);
		break;
	} case CType.BRANCH_STEP_CMP: {
		r = evtChildBrStepCmp(prop, summ, parent.step, parent.step2, name);
		break;
	} case CType.BRANCH_FLAG_CMP: {
		r = evtChildBrFlagCmp(prop, summ, parent.flag, parent.flag2, name);
		break;
	} case CType.BRANCH_RANDOM_SELECT: {
		r = evtChildBrRandomSelect(prop, parent, name);
		break;
	} case CType.BRANCH_KEY_CODE: {
		r = evtChildBrKeyCode(prop, parent, name);
		break;
	} case CType.BRANCH_ROUND: {
		r = evtChildBrRound(prop, parent, name);
		break;
	} default:
		name = "";
		r = "";
	}
	if (e.name != name && !readOnly) {
		e.setName(prop.parent, name);
		comm.refContent.call(e);
	}
	return r;
}

private string evtChildBrFlag(in Props prop, in Summary summ, string path, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string name = prop.msgs.noSelectFlag;
	string on = prop.msgs.flagOn;
	string off = prop.msgs.flagOff;
	if (path.length) {
		auto o = summ.flagDirRoot.findFlag(path);
		if (o) {
			name = path;
			on = o.on;
			off = o.off;
		} else {
			name = .tryFormat(prop.msgs.noFlag, path);
		}
	}
	return .tryFormat(prop.msgs.evtChildBrVar, name, (val ? on : off));
}
private string evtChildBrStepN(in Props prop, in Summary summ, string path, ref string text) {
	int val = -1;
	try {
		val = text == prop.sys.evtChildDefault ? -1 : (isNumeric(text) ? to!(int)(text) : -1);
	} catch {
		// Nothing
	}
	string name = prop.msgs.noSelectStep;
	string value = val >= 0 ? .tryFormat(prop.msgs.dlgLblStep, val) : prop.msgs.etc;
	if (path.length) {
		auto o = summ.flagDirRoot.findStep(path);
		if (o) {
			if (o.count <= val) {
				val = -1;
				text = prop.sys.evtChildDefault;
			}
			name = path;
			if (0 <= val) value = o.getValue(val);
		} else {
			name = .tryFormat(prop.msgs.noStep, path);
		}
	}
	return .tryFormat(prop.msgs.evtChildBrVar, name, value);
}
private string evtChildBrStepUL(in Props prop, in Summary summ, string path, int num, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string name = prop.msgs.noSelectStep;
	string value = .tryFormat(prop.msgs.dlgLblStep, num);
	if (path.length) {
		auto o = summ.flagDirRoot.findStep(path);
		if (o) {
			name = path;
			if (0 <= num && num < o.count) value = o.getValue(num);
		} else {
			name = .tryFormat(prop.msgs.noStep, path);
		}
	}
	if (val) {
		return .tryFormat(prop.msgs.stepMoreThan, path, value);
	} else {
		return .tryFormat(prop.msgs.stepLessThan, path, value);
	}
}
private string evtChildBrMember(in Props prop, bool all, bool random, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string mem = all ? prop.msgs.partyAll : prop.msgs.partyActive;
	string am = random ? prop.msgs.autoSelect : prop.msgs.manualSelect;
	if (val) {
		return .tryFormat(prop.msgs.selectMemberSuccess, mem, am);
	} else {
		return .tryFormat(prop.msgs.selectMemberFailure, mem, am);
	}
}
private string evtChildBrPower(in Props prop, Target targ, Physical p, Mental m, int lev, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string tt = prop.msgs.targetName(targ.m);
	string tp = prop.msgs.physicalName(p);
	string tm = prop.msgs.mentalName(m);
	if (val) {
		return .tryFormat(prop.msgs.branchAbilitySuccess, tt, lev, tp, tm);
	} else {
		return .tryFormat(prop.msgs.branchAbilityFailure, tt, lev, tp, tm);
	}
}
private string evtChildBrRandom(in Props prop, int percent, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (val) {
		return .tryFormat(prop.msgs.branchRandomSuccess, percent);
	} else {
		return .tryFormat(prop.msgs.branchRandomFailure, percent);
	}
}
private string evtChildBrLevel(in Props prop, int lev, bool avg, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string ta = avg  ? prop.msgs.levelAverage : prop.msgs.levelSelected;
	if (val) {
		return .tryFormat(prop.msgs.branchLevelSuccess, ta, lev);
	} else {
		return .tryFormat(prop.msgs.branchLevelFailure, ta, lev);
	}
}
private string evtChildBrState(in Props prop, Target targ, Status stat, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string tt = prop.msgs.targetName(targ.m);
	string ts = prop.msgs.statusName(stat);
	if (val) {
		return .tryFormat(prop.msgs.branchStatusSuccess, tt, ts);
	} else {
		return .tryFormat(prop.msgs.branchStatusFailure, tt, ts);
	}
}
private string evtChildBrNum(in Props prop, int num, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (val) {
		return .tryFormat(prop.msgs.branchNumberSuccess, num);
	} else {
		return .tryFormat(prop.msgs.branchNumberFailure, num);
	}
}
private string evtChildBrArea(in Props prop, in Area[] areas, ref string text) {
	if (text.length > 0) {
		try {
			long val = text == prop.sys.evtChildDefault ? -1 : (isNumeric(text) ? to!(long)(text) : -1);
			if (val >= 0) {
				foreach (a; areas) {
					if (a.id == val) {
						return .tryFormat(prop.msgs.branchArea, a.name);
					}
				}
			}
		} catch {}
	}
	text = prop.sys.evtChildDefault;
	return .tryFormat(prop.msgs.branchArea, prop.msgs.etc);
}
private string evtChildBrBattle(in Props prop, in Battle[] btls, ref string text) {
	if (text.length > 0) {
		try {
			long val = text == prop.sys.evtChildDefault ? -1 : (isNumeric(text) ? to!(long)(text) : -1);
			if (val >= 0) {
				foreach (b; btls) {
					if (b.id == val) {
						return .tryFormat(prop.msgs.branchBattle, b.name);
					}
				}
			}
		} catch {}
	}
	text = prop.sys.evtChildDefault;
	return .tryFormat(prop.msgs.branchBattle, prop.msgs.etc);
}
private string evtChildBrOnBattle(in Props prop, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (val) {
		return prop.msgs.branchOnBattleSuccess;
	} else {
		return prop.msgs.branchOnBattleFailure;
	}
}
private string evtChildBrCast(in Props prop, in Summary summ, ulong id, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string name = prop.msgs.noSelectCast;
	if (0 != id) {
		auto c = summ.cwCast(id);
		name = c ? c.name : .tryFormat(prop.msgs.noCast, id);
	}
	if (val) {
		return .tryFormat(prop.msgs.branchCastSuccess, name);
	} else {
		return .tryFormat(prop.msgs.branchCastFailure, name);
	}
}
private string evtChildBrItem(in Props prop, in Summary summ, ulong id, Range r, uint num, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string tr = prop.msgs.rangeName(r);
	string name = prop.msgs.noSelectItem;
	if (0 != id) {
		auto c = summ.item(id);
		name = c ? c.name : .tryFormat(prop.msgs.noItem, id);
	}
	if (val) {
		return .tryFormat(prop.msgs.branchEffectCardSuccess, tr, name);
	} else {
		return .tryFormat(prop.msgs.branchEffectCardFailure, tr, name);
	}
}
private string evtChildBrSkill(in Props prop, in Summary summ, ulong id, Range r, uint num, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string tr = prop.msgs.rangeName(r);
	string name = prop.msgs.noSelectSkill;
	if (0 != id) {
		auto c = summ.skill(id);
		name = c ? c.name : .tryFormat(prop.msgs.noSkill, id);
	}
	if (val) {
		return .tryFormat(prop.msgs.branchEffectCardSuccess, tr, name);
	} else {
		return .tryFormat(prop.msgs.branchEffectCardFailure, tr, name);
	}
}
private string evtChildBrBeast(in Props prop, in Summary summ, ulong id, Range r, uint num, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string tr = prop.msgs.rangeName(r);
	string name = prop.msgs.noSelectBeast;
	if (0 != id) {
		auto c = summ.beast(id);
		name = c ? c.name : .tryFormat(prop.msgs.noBeast, id);
	}
	if (val) {
		return .tryFormat(prop.msgs.branchEffectCardSuccess, tr, name);
	} else {
		return .tryFormat(prop.msgs.branchEffectCardFailure, tr, name);
	}
}
private string evtChildBrInfo(in Props prop, in Summary summ, ulong id, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string name = prop.msgs.noSelectInfo;
	if (0 != id) {
		auto c = summ.info(id);
		name = c ? c.name : .tryFormat(prop.msgs.noInfo, id);
	}
	if (val) {
		return .tryFormat(prop.msgs.branchInfoSuccess, name);
	} else {
		return .tryFormat(prop.msgs.branchInfoFailure, name);
	}
}
private string evtChildBrMoney(in Props prop, uint sp, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (val) {
		return .tryFormat(prop.msgs.branchMoneySuccess, sp);
	} else {
		return .tryFormat(prop.msgs.branchMoneyFailure, sp);
	}
}
private string evtChildBrCoupon(in Props prop, Range r, string coupon, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (!coupon || !coupon.length) coupon = prop.msgs.noSelectCoupon;
	string tr = prop.msgs.rangeName(r);
	if (val) {
		return .tryFormat(prop.msgs.branchCouponSuccess, tr, coupon);
	} else {
		return .tryFormat(prop.msgs.branchCouponFailure, tr, coupon);
	}
}
private string evtChildBrEnd(in Props prop, string scenario, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (!scenario || !scenario.length) scenario = prop.msgs.noSelectCompleteStamp;
	if (val) {
		return .tryFormat(prop.msgs.branchCompleteSuccess, scenario);
	} else {
		return .tryFormat(prop.msgs.branchCompleteFailure, scenario);
	}
}
private string evtChildBrGossip(in Props prop, string gossip, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	if (!gossip || !gossip.length) gossip = prop.msgs.noSelectGossip;
	if (val) {
		return .tryFormat(prop.msgs.branchGossipSuccess, gossip);
	} else {
		return .tryFormat(prop.msgs.branchGossipFailure, gossip);
	}
}
private string evtChildBrStepCmp(in Props prop, in Summary summ, string step1, string step2, ref string text) {
	int index;
	if (text == prop.sys.evtChildEq) {
		index = 2;
		text = prop.sys.evtChildEq;
	} else if (text == prop.sys.evtChildLesser) {
		index = 1;
		text = prop.sys.evtChildLesser;
	} else {
		index = 0;
		text = prop.sys.evtChildGreater;
	}
	string nameFrom(string path) {
		string name = prop.msgs.noSelectStep;
		if (path.length) {
			auto o = summ.flagDirRoot.findStep(path);
			if (o) {
				name = path;
			} else {
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
private string evtChildBrFlagCmp(in Props prop, in Summary summ, string flag1, string flag2, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;
	string nameFrom(string path) {
		string name = prop.msgs.noSelectFlag;
		if (path.length) {
			auto o = summ.flagDirRoot.findFlag(path);
			if (o) {
				name = path;
			} else {
				name = .tryFormat(prop.msgs.noFlag, path);
			}
		}
		return name;
	}
	flag1 = nameFrom(flag1);
	flag2 = nameFrom(flag2);
	if (val) {
		return .tryFormat(prop.msgs.branchFlagCmpEq, flag1, flag2);
	} else {
		return .tryFormat(prop.msgs.branchFlagCmpNotEq, flag1, flag2);
	}
}
private string evtChildBrRandomSelect(in Props prop, in Content evt, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;

	string r = castRangesName(prop, evt.castRange);
	bool hasLevel = 0 < evt.levelMax;
	bool hasStatus = evt.status !is Status.NONE;
	if (hasLevel || hasStatus) {
		string s = prop.msgs.statusName(evt.status);
		auto l1 = evt.levelMin, l2 = evt.levelMax;
		string cond;
		if (hasLevel && hasStatus) {
			cond = .tryFormat(prop.msgs.randomSelectCondition3, l1, l2, s);
		} else if (hasLevel) {
			cond = .tryFormat(prop.msgs.randomSelectCondition1, l1, l2);
		} else if (hasStatus) {
			cond = .tryFormat(prop.msgs.randomSelectCondition2, s);
		} else assert (0);
		if (val) {
			return .tryFormat(prop.msgs.branchRandomSelectSuccess, r, cond);
		} else {
			return .tryFormat(prop.msgs.branchRandomSelectFailure, r, cond);
		}
	} else {
		if (val) {
			return .tryFormat(prop.msgs.branchRandomSelectSuccessN, r);
		} else {
			return .tryFormat(prop.msgs.branchRandomSelectFailureN, r);
		}
	}
}
private string evtChildBrKeyCode(in Props prop, in Content evt, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;

	string range = prop.msgs.rangeName(evt.keyCodeRange);
	if (evt.effectCardType is EffectCardType.ALL) {
		if (val) {
			return .tryFormat(prop.msgs.branchKeyCodeAllTypeSuccess, evt.keyCode, range);
		} else {
			return .tryFormat(prop.msgs.branchKeyCodeAllTypeFailure, evt.keyCode, range);
		}
	} else {
		string type = prop.msgs.effectCardTypeName(evt.effectCardType);
		if (val) {
			return .tryFormat(prop.msgs.branchKeyCodeSuccess, evt.keyCode, type, range);
		} else {
			return .tryFormat(prop.msgs.branchKeyCodeFailure, evt.keyCode, type, range);
		}
	}
}
private string evtChildBrRound(in Props prop, in Content evt, ref string text) {
	bool val = (text != prop.sys.evtChildFalse);
	text = val ? prop.sys.evtChildTrue : prop.sys.evtChildFalse;

	string cmp;
	if (val) {
		cmp = prop.msgs.comparison3Name(evt.comparison3);
	} else {
		cmp = prop.msgs.comparison3FalseName(evt.comparison3);
	}
	return .tryFormat(prop.msgs.branchRound, evt.round, cmp);
}

Image warningImage(Props prop, Display d) {
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
	foreach (i, ref b; alphas) {
		b = cast(byte)(cast(real)i / prop.var.etc.warningImageWidth * alpha);
	}
	alphas = std.array.replicate(alphas, height);
	assert (alphas.length == prop.var.etc.warningImageWidth * height);
	auto imgData = buf.getImageData();
	imgData.setAlphas(0, 0, prop.var.etc.warningImageWidth * height, alphas, 0);
	return new Image(d, imgData);
}
