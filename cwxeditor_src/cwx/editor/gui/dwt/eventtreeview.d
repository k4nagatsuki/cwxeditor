
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

import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.eventdialog;
import cwx.editor.gui.dwt.message;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.properties;

import std.string;

import dwt.widgets.Control;
import dwt.widgets.Combo;
import dwt.widgets.Display;
import dwt.widgets.Shell;
import dwt.widgets.Composite;
import dwt.widgets.Tree;
import dwt.widgets.TreeItem;
import dwt.widgets.CoolBar;
import dwt.widgets.CoolItem;
import dwt.widgets.ToolBar;
import dwt.widgets.ToolItem;
import dwt.widgets.Text;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.custom.CCombo;
import dwt.layout.GridData;
import dwt.layout.GridLayout;
import dwt.graphics.Image;
import dwt.graphics.ImageData;
import dwt.graphics.PaletteData;
import dwt.graphics.RGB;
import dwt.graphics.Cursor;
import dwt.events.ControlAdapter;
import dwt.events.ControlEvent;
import dwt.events.KeyListener;
import dwt.events.KeyEvent;
import dwt.events.MouseAdapter;
import dwt.events.MouseEvent;
import dwt.events.ShellAdapter;
import dwt.events.ShellEvent;
import dwt.events.SelectionAdapter;
import dwt.events.SelectionEvent;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.dwthelper.utils;
import dwt.dnd.Clipboard;
import dwt.dnd.ByteArrayTransfer;
import dwt.dnd.TextTransfer;
import dwt.dnd.DND;
import dwt.dnd.DragSourceAdapter;
import dwt.dnd.DragSourceListener;
import dwt.dnd.DragSourceEvent;
import dwt.dnd.DragSource;
import dwt.dnd.DropTargetAdapter;
import dwt.dnd.DropTargetListener;
import dwt.dnd.DropTargetEvent;
import dwt.dnd.DropTarget;

public:

class EventTreeView : TCPD {
private:
	Shell _toolWin = null;
	Composite _comp;
	Tree _tree;

	Props _prop;
	Commons _comm;
	Summary _summ;
	EventTree _et;
	bool _toolWinVisible = false;
	bool _opened = false;

	bool _autoOpen;
	bool _conti;
	ToolItem _contiTI;
	ToolItem _autoOpenTI;

	bool _arrowMode = true;
	CType _cType;
	ToolItem _arrowTI;
	ToolItem _evtTI = null;
	RadioGroup!(ToolItem) _radioGroup;

	void delegate(size_t[]) _forceSel;
	void delegate() _refreshTopStart;

	Cursor[] _cursors;

	string _statusLine;

	void autoOpen() {
		_autoOpen = _autoOpenTI.getSelection;
	}
	void addContinue() {
		_conti = _contiTI.getSelection;
	}

	TreeItem selection() {
		auto sels = _tree.getSelection;
		if (sels.length > 0) {
			return sels[0];
		}
		return null;
	}

	class EditL : MouseAdapter, KeyListener {
		private void __edit() {
			edit;
		}
		override void keyPressed(KeyEvent e) {
			if (e.character == DWT.CR) {
				__edit;
			}
		}
		override void keyReleased(KeyEvent e) {}
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button == 1 && !_tree.getCursor) {
				__edit;
			}
		}
	}
	class CreateL : MouseAdapter {
		override void mouseDown(MouseEvent e) {
			if (e.button == 1) {
				create(null);
			} else if (e.button == 2 && !_arrowMode) {
				auto itm = _tree.getItem(new Point(e.x, e.y));
				if (itm) create(itm);
			} else if (e.button == 3) {
				arrow;
			}
		}
	}

	UndoManager _undo;
	abstract class ETVUndo : Undo {
		private size_t[] _etPath;
		private size_t[] _selPath, _selPath2;
		this () {
			_etPath = _et.areaPath;
			auto sel = selection;
			_selPath = sel ? (cast(Content) sel.getData).ctPath : null;
		}
		void udb() {
			.forceFocus(_tree);
			_forceSel(_etPath);
			auto sel = selection;
			_selPath2 = sel ? (cast(Content) sel.getData).ctPath : null;
		}
		void uda() {
			if (_selPath) _tree.select = fromPath(_selPath);
			_selPath = _selPath2;
		}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
	}
	private void insertStart(int index, Content c) {
		_tree.setRedraw = false;
		scope (exit) _tree.setRedraw = true;
		_et.insert(index, c);
		auto itm = createTreeItem(_tree, c, c.name, _prop.images.content(c.type), index);
		createChilds(itm, c, false);
		itm.setExpanded = true;
		refreshStatusLine;
		_comm.refUseCount.call;
		_refreshTopStart();
	}
	class UndoContent : ETVUndo {
		private size_t[][] _path;
		private Content[] _c;
		this (Content[] cs) {
			foreach (c; cs) {
				_path ~= c.ctPath;
				_c ~= Content.createFromNode(c.toNode, LATEST_VERSION);
				_c[$ - 1].setUseCounter(_summ.useCounter.sub);
			}
		}
		private void impl() {
			udb;
			scope (exit) uda;
			foreach (i, c; _c.dup) {
				_c[i] = Content.createFromNode(_et.fromPath(_path[i]).toNode, LATEST_VERSION);
				_c[i].setUseCounter(_summ.useCounter.sub);
				auto now = fromPath(_path[i]);
				_tree.setRedraw = false;
				scope (exit) _tree.setRedraw = true;
				auto par = now.getParentItem;
				TreeItem itm;
				int index = _path[i][$ - 1];
				if (par) {
					auto pc = cast(Content) par.getData;
					pc.insert(index, c);
					itm = createTreeItem(par, c, eventText(pc, c), _prop.images.content(c.type), index);
				} else {
					_et.insert(index, c);
					itm = createTreeItem(_tree, c, c.name, _prop.images.content(c.type), index);
				}
				createChilds(itm, c, false);
				itm.setExpanded = true;
				delImpl(now, false);
				if (!par) {
					_refreshTopStart();
				}
			}
			refreshStatusLine;
			_comm.refUseCount.call;
		}
		override void undo() {impl;}
		override void redo() {impl;}
		override void dispose() {
			foreach (c; _c) {
				c.removeUseCounter;
			}
		}
	}
	void store(Content[] evt ...) {
		_undo ~= new UndoContent(evt);
	}
	class UndoSwap : ETVUndo {
		private int _upIndex;
		this (int swapIndex1, int swapIndex2) {
			_upIndex = max(swapIndex1, swapIndex2);
		}
		private void impl() {
			udb;
			scope (exit) uda;
			up(_tree.getItem(_upIndex), false);
		}
		override void undo() {impl;}
		override void redo() {impl;}
		override void dispose() {}
	}
	void store(int swapIndex1, int swapIndex2) {
		_undo ~= new UndoSwap(swapIndex1, swapIndex2);
	}
	class UndoInsert : ETVUndo {
		private int _index;
		private Content _c;
		this (int index) {
			_index = index;
		}
		override void undo() {
			udb;
			scope (exit) uda;
			_tree.setRedraw = false;
			scope (exit) _tree.setRedraw = true;
			_c = Content.createFromNode(_et.starts[_index].toNode, LATEST_VERSION);
			_c.setUseCounter(_summ.useCounter.sub);
			delImpl(_tree.getItem(_index), false);
			refreshStatusLine;
			_comm.refUseCount.call;
			_refreshTopStart();
		}
		override void redo() {
			udb;
			scope (exit) uda;
			insertStart(_index, _c);
		}
		override void dispose() {
			if (_c) _c.removeUseCounter;
		}
	}
	void store(int insertIndex) {
		_undo ~= new UndoInsert(insertIndex);
	}
	class UndoDelete : ETVUndo {
		private int _index;
		private Content _c;
		this (int index, Content del) {
			_index = index;
			_c = Content.createFromNode(del.toNode, LATEST_VERSION);
			_c.setUseCounter(_summ.useCounter.sub);
		}
		override void undo() {
			udb;
			scope (exit) uda;
			insertStart(_index, _c);
		}
		override void redo() {
			udb;
			scope (exit) uda;
			_tree.setRedraw = false;
			scope (exit) _tree.setRedraw = true;
			delImpl(_tree.getItem(_index), false);
			refreshStatusLine;
			_comm.refUseCount.call;
			_refreshTopStart();
		}
		override void dispose() {
			_c.removeUseCounter;
		}
	}
	void store(int index, Content del) {
		_undo ~= new UndoDelete(index, del);
	}
	private TreeItem fromPath(size_t[] path) {
		return fromPathImpl(_tree, path);
	}
	private TreeItem fromPathImpl(T)(T tree, size_t[] path) {
		if (!path.length) return null;
		auto itm = tree.getItem(path[0]);
		if (path.length == 1) return itm;
		return fromPathImpl(itm, path[1 .. $]);
	}
	class UndoCP : Undo {
		private UndoContent _undoC;
		private UndoDelete _undoD;
		this (Content[] conts, int index, Content start) {
			_undoC = new UndoContent(conts);
			_undoD = new UndoDelete(index, start);
		}
		override void undo() {
			_undoD.undo;
			_undoC.undo;
		}
		override void redo() {
			_undoC.redo;
			_undoD.redo;
		}
		override void dispose() {
			_undoC.dispose;
			_undoD.dispose;
		}
	}

	void edit() {
		auto sels = _tree.getSelection;
		if (sels.length > 0) {
			auto c = cast(Content) sels[0].getData;
			auto undo = new UndoContent([c]);
			if (edit(c)) {
				_undo ~= undo;
				foreach (childItm; sels[0].getItems) {
					auto par = cast(Content) sels[0].getData;
					assert (par.detail.owner);
					childItm.setText = eventText(par, cast(Content) childItm.getData);
				}
				_comm.refUseCount.call;
				refreshStatusLine;
			}
		}
	}
	void create(TreeItem insertTo) {
		if (!_tree.getItems.length) return;
		if (!_arrowMode) {
			_tree.setRedraw = false;
			scope (exit) _tree.setRedraw = true;
			if (_cType == CType.START) {
				if (insertTo) return;
				auto evt = create(_cType, "");
				assert (evt);
				auto sel = selection;
				int index;
				if (sel) {
					index = _tree.indexOf(topItem(sel)) + 1;
				} else {
					index = -1;
				}
				store(index);
				_et.insert(index, cast(Content) evt);
				auto sItm = createTreeItem(_tree, evt, evt.name, _prop.images.content(CType.START), index);
				_tree.select = sItm;
				_tree.showSelection;
				refreshConvMenu;
				refreshStatusLine;
				if (!_conti) arrow;
			} else {
				if (insertTo && !CDetail.fromType(_cType).owner) return;
				auto sels = _tree.getSelection;
				if (insertTo || (sels.length > 0 && (cast(Content) sels[0].getData).detail.owner)) {
					TreeItem oItm;
					if (insertTo) {
						oItm = insertTo.getParentItem;
						if (!oItm) return;
					} else {
						oItm = sels[0];
					}
					auto owner = cast(Content) oItm.getData;
					Content evt;
					if (insertTo) {
						evt = create(_cType, (cast(Content) insertTo.getData).name);
					} else {
						evt = create(_cType, "");
					}
					if (evt) {
						store(owner);
						owner.add(evt);
						TreeItem itm = createTreeItem(oItm, evt, eventText(owner, evt), _prop.images.content(evt.type));
						oItm.setExpanded = true;
						_tree.setSelection = [itm];
						if (insertTo) {
							auto tcc = cast(Content) insertTo.getData;
							owner.remove(tcc);
							evt.add(tcc);
							insertTo.dispose;
							createChilds(itm, evt, false);
							itm.setExpanded = true;
						}
						_tree.showSelection;
						_comm.refUseCount.call;
					}
					refreshConvMenu;
					refreshStatusLine;
					if (!_conti) arrow;
				}
			}
		}
	}
	void arrow() {
		_arrowMode = true;
		_comp.setCursor = null;
		if (_toolWin) {
			_toolWin.setCursor = null;
		}
		_radioGroup.select = _arrowTI;
	}

	Content create(CType type, string name) {
		switch (type) {
		case CType.START: {
			return new Content(type, createNewName(_prop.msgs.defaultStartName, (string name) {
				foreach (start; _et.starts) {
					if (icmp(start.name, name) == 0) return false;
				}
				return true;
			}));
		} case CType.START_BATTLE: {
			if (_autoOpen && _summ.battles.length > 0) {
				auto dlg = new AreaSelectDialog!(CType.START_BATTLE, Battle, "summary.battles")
					(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.END: {
			if (_autoOpen) {
				auto dlg = new ClearEventDialog(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.END_BAD_END: {
			return new Content(type, name);
		} case CType.CHANGE_AREA: {
			if (_autoOpen && _summ.areas.length > 0) {
				auto dlg = new AreaSelectDialog!(CType.CHANGE_AREA, Area, "summary.areas")
					(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.CHANGE_BG_IMAGE: {
			auto c = new Content(type, name);
			c.backs = BgImageS.createBgImages(findSkin(_prop, _summ), _prop.var.etc.bgImagesDefault);
			if (_autoOpen) {
				auto dlg = new BgImagesDialog(_comm, _prop, _tree.getShell, _summ, c);
				return dlg.open ? dlg.event : null;
			} else {
				return c;
			}
		} case CType.EFFECT: {
			if (_autoOpen) {
				auto dlg = new EffectDialog(_comm, _prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.EFFECT_BREAK: {
			return new Content(type, name);
		} case CType.LINK_START: {
			if (_autoOpen) {
				auto dlg = new StartSelectDialog!(CType.LINK_START)(_prop, _tree.getShell, _et.starts, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.LINK_PACKAGE: {
			if (_autoOpen && _summ.packages.length > 0) {
				auto dlg = new AreaSelectDialog!(CType.LINK_PACKAGE, Package, "summary.packages")
					(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.TALK_MESSAGE: {
			if (_autoOpen) {
				auto dlg = new MessageDialog
					(_comm, _prop, _summ, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.TALK_DIALOG: {
			if (_autoOpen) {
				auto dlg = new SpeakDialog(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				auto r = new Content(type, name);
				r.dialogs = [new SDialog];
				return r;
			}
		} case CType.PLAY_BGM: {
			if (_autoOpen) {
				auto dlg = new BgmDialog(_comm, _prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.PLAY_SOUND: {
			if (_autoOpen) {
				auto dlg = new SeDialog(_comm, _prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.WAIT: {
			if (_autoOpen) {
				auto dlg = new WaitEventDialog(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.ELAPSE_TIME: {
			return new Content(type, name);
		} case CType.CALL_START: {
			if (_autoOpen) {
				auto dlg = new StartSelectDialog!(CType.CALL_START)(_prop, _tree.getShell, _et.starts, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.CALL_PACKAGE: {
			if (_autoOpen && _summ.packages.length > 0) {
				auto dlg = new AreaSelectDialog!(CType.CALL_PACKAGE, Package, "summary.packages")
					(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_FLAG: {
			if (_autoOpen && _summ.flagDirRoot.allFlags.length > 0) {
				auto dlg = new BrFlagDialog(_prop, _tree.getShell, _summ.flagDirRoot, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_MULTI_STEP: {
			if (_autoOpen && _summ.flagDirRoot.allSteps.length > 0) {
				auto dlg = new BrStepNDialog(_prop, _tree.getShell, _summ.flagDirRoot, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_STEP: {
			if (_autoOpen && _summ.flagDirRoot.allSteps.length > 0) {
				auto dlg = new BrStepULDialog(_prop, _tree.getShell, _summ.flagDirRoot, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_SELECT: {
			if (_autoOpen) {
				auto dlg = new BrMemberDialog(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_ABILITY: {
			if (_autoOpen) {
				auto dlg = new BrPowerDialog(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_RANDOM: {
			if (_autoOpen) {
				auto dlg = new BrRandomEventDialog(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_LEVEL: {
			if (_autoOpen) {
				auto dlg = new BrLevelDialog(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				auto r = new Content(type, name);
				r.level = 1;
				return r;
			}
		} case CType.BRANCH_STATUS: {
			if (_autoOpen) {
				auto dlg = new BrStateDialog(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_PARTY_NUMBER: {
			if (_autoOpen) {
				auto dlg = new BrNumEventDialog(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_AREA: {
			return new Content(type, name);
		} case CType.BRANCH_BATTLE: {
			return new Content(type, name);
		} case CType.BRANCH_IS_BATTLE: {
			return new Content(type, name);
		} case CType.BRANCH_CAST: {
			if (_autoOpen && _summ.casts.length > 0) {
				auto dlg = new AreaSelectDialog!(CType.BRANCH_CAST, CastCard, "summary.casts")
					(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_ITEM: {
			if (_autoOpen && _summ.items.length > 0) {
				auto dlg = new BrItemDialog(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				auto r = new Content(type, name);
				r.range = Range.FIELD;
				return r;
			}
		} case CType.BRANCH_SKILL: {
			if (_autoOpen && _summ.skills.length > 0) {
				auto dlg = new BrSkillDialog(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				auto r = new Content(type, name);
				r.range = Range.FIELD;
				return r;
			}
		} case CType.BRANCH_INFO: {
			if (_autoOpen && _summ.infos.length > 0) {
				auto dlg = new AreaSelectDialog!(CType.BRANCH_INFO, InfoCard, "summary.infos")
					(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_BEAST: {
			if (_autoOpen && _summ.beasts.length > 0) {
				auto dlg = new BrBeastDialog(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				auto r = new Content(type, name);
				r.range = Range.FIELD;
				return r;
			}
		} case CType.BRANCH_MONEY: {
			if (_autoOpen) {
				auto dlg = new MoneyEventDialog!(CType.BRANCH_MONEY)(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_COUPON: {
			if (_autoOpen) {
				auto dlg = new CouponEventDialog!(CType.BRANCH_COUPON, false)(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_COMPLETE_STAMP: {
			if (_autoOpen) {
				auto dlg = new EndEventDialog!(CType.BRANCH_COMPLETE_STAMP)(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.BRANCH_GOSSIP: {
			if (_autoOpen) {
				auto dlg = new GossipEventDialog!(CType.BRANCH_GOSSIP)(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.SET_FLAG: {
			if (_autoOpen && _summ.flagDirRoot.allFlags.length > 0) {
				auto dlg = new FlagSetDialog(_prop, _tree.getShell, _summ.flagDirRoot, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.SET_STEP: {
			if (_autoOpen && _summ.flagDirRoot.allSteps.length > 0) {
				auto dlg = new StepSetDialog(_prop, _tree.getShell, _summ.flagDirRoot, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.SET_STEP_UP: {
			if (_autoOpen && _summ.flagDirRoot.allSteps.length > 0) {
				auto dlg = new StepPlusDialog(_prop, _tree.getShell, _summ.flagDirRoot, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.SET_STEP_DOWN: {
			if (_autoOpen && _summ.flagDirRoot.allSteps.length > 0) {
				auto dlg = new StepMinusDialog(_prop, _tree.getShell, _summ.flagDirRoot, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.REVERSE_FLAG: {
			if (_autoOpen && _summ.flagDirRoot.allFlags.length > 0) {
				auto dlg = new FlagRDialog(_prop, _tree.getShell, _summ.flagDirRoot, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.CHECK_FLAG: {
			if (_autoOpen && _summ.flagDirRoot.allFlags.length > 0) {
				auto dlg = new FlagJudgeDialog(_prop, _tree.getShell, _summ.flagDirRoot, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.GET_CAST: {
			if (_autoOpen && _summ.casts.length > 0) {
				auto dlg = new AreaSelectDialog!(CType.GET_CAST, CastCard, "summary.casts")
					(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.GET_ITEM: {
			if (_autoOpen && _summ.items.length > 0) {
				auto dlg = new GetItemDialog(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.GET_SKILL: {
			if (_autoOpen && _summ.skills.length > 0) {
				auto dlg = new GetSkillDialog(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.GET_INFO: {
			if (_autoOpen && _summ.infos.length > 0) {
				auto dlg = new AreaSelectDialog!(CType.GET_INFO, InfoCard, "summary.infos")
					(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.GET_BEAST: {
			if (_autoOpen && _summ.beasts.length > 0) {
				auto dlg = new GetBeastDialog(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.GET_MONEY: {
			if (_autoOpen) {
				auto dlg = new MoneyEventDialog!(CType.GET_MONEY)(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.GET_COUPON: {
			if (_autoOpen) {
				auto dlg = new CouponEventDialog!(CType.GET_COUPON, true)(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.GET_COMPLETE_STAMP: {
			if (_autoOpen) {
				auto dlg = new EndEventDialog!(CType.GET_COMPLETE_STAMP)(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.GET_GOSSIP: {
			if (_autoOpen) {
				auto dlg = new GossipEventDialog!(CType.GET_GOSSIP)(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.LOSE_CAST: {
			if (_autoOpen && _summ.casts.length > 0) {
				auto dlg = new AreaSelectDialog!(CType.LOSE_CAST, CastCard, "summary.casts")
					(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.LOSE_ITEM: {
			if (_autoOpen && _summ.items.length > 0) {
				auto dlg = new LostItemDialog(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				auto r = new Content(type, name);
				r.range = Range.FIELD;
				return r;
			}
		} case CType.LOSE_SKILL: {
			if (_autoOpen && _summ.skills.length > 0) {
				auto dlg = new LostSkillDialog(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				auto r = new Content(type, name);
				r.range = Range.FIELD;
				return r;
			}
		} case CType.LOSE_INFO: {
			if (_autoOpen && _summ.infos.length > 0) {
				auto dlg = new AreaSelectDialog!(CType.LOSE_INFO, InfoCard, "summary.infos")
					(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.LOSE_BEAST: {
			if (_autoOpen && _summ.beasts.length > 0) {
				auto dlg = new LostBeastDialog(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				auto r = new Content(type, name);
				r.range = Range.FIELD;
				return r;
			}
		} case CType.LOSE_MONEY: {
			if (_autoOpen) {
				auto dlg = new MoneyEventDialog!(CType.LOSE_MONEY)(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.LOSE_COUPON: {
			if (_autoOpen) {
				auto dlg = new CouponEventDialog!(CType.LOSE_COUPON, false)(_prop, _tree.getShell, _summ, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.LOSE_COMPLETE_STAMP: {
			if (_autoOpen) {
				auto dlg = new EndEventDialog!(CType.LOSE_COMPLETE_STAMP)(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.LOSE_GOSSIP: {
			if (_autoOpen) {
				auto dlg = new GossipEventDialog!(CType.LOSE_GOSSIP)(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} case CType.SHOW_PARTY: {
			return new Content(type, name);
		} case CType.HIDE_PARTY: {
			return new Content(type, name);
		} case CType.REDISPLAY: {
			if (_autoOpen && !_summ.legacy) {
				auto dlg = new RefreshDialog(_prop, _tree.getShell, null);
				return dlg.open ? dlg.event : null;
			} else {
				return new Content(type, name);
			}
		} default: assert (0);
		}
	}

	bool edit(Content evt) {
		switch (evt.type) {
		case CType.START: {
			return false;
		} case CType.START_BATTLE: {
			if (_summ.battles.length == 0) return false;
			auto dlg = new AreaSelectDialog!(CType.START_BATTLE, Battle, "summary.battles")
				(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.END: {
			auto dlg = new ClearEventDialog(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.END_BAD_END: {
			return false;
		} case CType.CHANGE_AREA: {
			if (_summ.areas.length == 0) return false;
			auto dlg = new AreaSelectDialog!(CType.CHANGE_AREA, Area, "summary.areas")
				(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.CHANGE_BG_IMAGE: {
			auto dlg = new BgImagesDialog(_comm, _prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.EFFECT: {
			auto dlg = new EffectDialog(_comm, _prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.EFFECT_BREAK: {
			return false;
		} case CType.LINK_START: {
			auto dlg = new StartSelectDialog!(CType.LINK_START)(_prop, _tree.getShell, _et.starts, evt);
			return dlg.open;
		} case CType.LINK_PACKAGE: {
			if (_summ.packages.length == 0) return false;
			auto dlg = new AreaSelectDialog!(CType.LINK_PACKAGE, Package, "summary.packages")
				(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.TALK_MESSAGE: {
			auto dlg = new MessageDialog
				(_comm, _prop, _summ, _tree.getShell, evt);
			return dlg.open;
		} case CType.TALK_DIALOG: {
			auto dlg = new SpeakDialog(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.PLAY_BGM: {
			auto dlg = new BgmDialog(_comm, _prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.PLAY_SOUND: {
			auto dlg = new SeDialog(_comm, _prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.WAIT: {
			auto dlg = new WaitEventDialog(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.ELAPSE_TIME: {
			return false;
		} case CType.CALL_START: {
			auto dlg = new StartSelectDialog!(CType.CALL_START)(_prop, _tree.getShell, _et.starts, evt);
			return dlg.open;
		} case CType.CALL_PACKAGE: {
			if (_summ.packages.length == 0) return false;
			auto dlg = new AreaSelectDialog!(CType.CALL_PACKAGE, Package, "summary.packages")
				(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.BRANCH_FLAG: {
			if (_summ.flagDirRoot.allFlags.length == 0) return false;
			auto dlg = new BrFlagDialog(_prop, _tree.getShell, _summ.flagDirRoot, evt);
			return dlg.open;
		} case CType.BRANCH_MULTI_STEP: {
			if (_summ.flagDirRoot.allSteps.length == 0) return false;
			auto dlg = new BrStepNDialog(_prop, _tree.getShell, _summ.flagDirRoot, evt);
			return dlg.open;
		} case CType.BRANCH_STEP: {
			if (_summ.flagDirRoot.allSteps.length == 0) return false;
			auto dlg = new BrStepULDialog(_prop, _tree.getShell, _summ.flagDirRoot, evt);
			return dlg.open;
		} case CType.BRANCH_SELECT: {
			auto dlg = new BrMemberDialog(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.BRANCH_ABILITY: {
			auto dlg = new BrPowerDialog(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.BRANCH_RANDOM: {
			auto dlg = new BrRandomEventDialog(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.BRANCH_LEVEL: {
			auto dlg = new BrLevelDialog(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.BRANCH_STATUS: {
			auto dlg = new BrStateDialog(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.BRANCH_PARTY_NUMBER: {
			auto dlg = new BrNumEventDialog(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.BRANCH_AREA: {
			return false;
		} case CType.BRANCH_BATTLE: {
			return false;
		} case CType.BRANCH_IS_BATTLE: {
			return false;
		} case CType.BRANCH_CAST: {
			if (_summ.casts.length == 0) return false;
			auto dlg = new AreaSelectDialog!(CType.BRANCH_CAST, CastCard, "summary.casts")
				(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.BRANCH_ITEM: {
			if (_summ.items.length == 0) return false;
			auto dlg = new BrItemDialog(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.BRANCH_SKILL: {
			if (_summ.skills.length == 0) return false;
			auto dlg = new BrSkillDialog(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.BRANCH_INFO: {
			if (_summ.infos.length == 0) return false;
			auto dlg = new AreaSelectDialog!(CType.BRANCH_INFO, InfoCard, "summary.infos")
				(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.BRANCH_BEAST: {
			if (_summ.beasts.length == 0) return false;
			auto dlg = new BrBeastDialog(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.BRANCH_MONEY: {
			auto dlg = new MoneyEventDialog!(CType.BRANCH_MONEY)(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.BRANCH_COUPON: {
			auto dlg = new CouponEventDialog!(CType.BRANCH_COUPON, false)(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.BRANCH_COMPLETE_STAMP: {
			auto dlg = new EndEventDialog!(CType.BRANCH_COMPLETE_STAMP)(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.BRANCH_GOSSIP: {
			auto dlg = new GossipEventDialog!(CType.BRANCH_GOSSIP)(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.SET_FLAG: {
			if (_summ.flagDirRoot.allFlags.length == 0) return false;
			auto dlg = new FlagSetDialog(_prop, _tree.getShell, _summ.flagDirRoot, evt);
			return dlg.open;
		} case CType.SET_STEP: {
			if (_summ.flagDirRoot.allSteps.length == 0) return false;
			auto dlg = new StepSetDialog(_prop, _tree.getShell, _summ.flagDirRoot, evt);
			return dlg.open;
		} case CType.SET_STEP_UP: {
			if (_summ.flagDirRoot.allSteps.length == 0) return false;
			auto dlg = new StepPlusDialog(_prop, _tree.getShell, _summ.flagDirRoot, evt);
			return dlg.open;
		} case CType.SET_STEP_DOWN: {
			if (_summ.flagDirRoot.allSteps.length == 0) return false;
			auto dlg = new StepMinusDialog(_prop, _tree.getShell, _summ.flagDirRoot, evt);
			return dlg.open;
		} case CType.REVERSE_FLAG: {
			if (_summ.flagDirRoot.allFlags.length == 0) return false;
			auto dlg = new FlagRDialog(_prop, _tree.getShell, _summ.flagDirRoot, evt);
			return dlg.open;
		} case CType.CHECK_FLAG: {
			if (_summ.flagDirRoot.allFlags.length == 0) return false;
			auto dlg = new FlagJudgeDialog(_prop, _tree.getShell, _summ.flagDirRoot, evt);
			return dlg.open;
		} case CType.GET_CAST: {
			if (_summ.casts.length == 0) return false;
			auto dlg = new AreaSelectDialog!(CType.GET_CAST, CastCard, "summary.casts")
				(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.GET_ITEM: {
			if (_summ.items.length == 0) return false;
			auto dlg = new GetItemDialog(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.GET_SKILL: {
			if (_summ.skills.length == 0) return false;
			auto dlg = new GetSkillDialog(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.GET_INFO: {
			if (_summ.infos.length == 0) return false;
			auto dlg = new AreaSelectDialog!(CType.GET_INFO, InfoCard, "summary.infos")
				(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.GET_BEAST: {
			if (_summ.beasts.length == 0) return false;
			auto dlg = new GetBeastDialog(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.GET_MONEY: {
			auto dlg = new MoneyEventDialog!(CType.GET_MONEY)(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.GET_COUPON: {
			auto dlg = new CouponEventDialog!(CType.GET_COUPON, true)(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.GET_COMPLETE_STAMP: {
			auto dlg = new EndEventDialog!(CType.GET_COMPLETE_STAMP)(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.GET_GOSSIP: {
			auto dlg = new GossipEventDialog!(CType.GET_GOSSIP)(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.LOSE_CAST: {
			if (_summ.casts.length == 0) return false;
			auto dlg = new AreaSelectDialog!(CType.LOSE_CAST, CastCard, "summary.casts")
				(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.LOSE_ITEM: {
			if (_summ.items.length == 0) return false;
			auto dlg = new LostItemDialog(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.LOSE_SKILL: {
			if (_summ.skills.length == 0) return false;
			auto dlg = new LostSkillDialog(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.LOSE_INFO: {
			if (_summ.infos.length == 0) return false;
			auto dlg = new AreaSelectDialog!(CType.LOSE_INFO, InfoCard, "summary.infos")
				(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.LOSE_BEAST: {
			if (_summ.beasts.length == 0) return false;
			auto dlg = new LostBeastDialog(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.LOSE_MONEY: {
			auto dlg = new MoneyEventDialog!(CType.LOSE_MONEY)(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.LOSE_COUPON: {
			auto dlg = new CouponEventDialog!(CType.LOSE_COUPON, false)(_prop, _tree.getShell, _summ, evt);
			return dlg.open;
		} case CType.LOSE_COMPLETE_STAMP: {
			auto dlg = new EndEventDialog!(CType.LOSE_COMPLETE_STAMP)(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.LOSE_GOSSIP: {
			auto dlg = new GossipEventDialog!(CType.LOSE_GOSSIP)(_prop, _tree.getShell, evt);
			return dlg.open;
		} case CType.SHOW_PARTY: {
			return false;
		} case CType.HIDE_PARTY: {
			return false;
		} case CType.REDISPLAY: {
			if (_summ.legacy) return false;
			auto dlg = new RefreshDialog(_prop, _tree.getShell, evt);
			return dlg.open;
		} default: assert (0);
		}
	}

	void refreshStatusLine() {
		auto itm = selection;
		if (itm) {
			_statusLine = _prop.msgs.contentText(cast(Content) itm.getData, _summ);
		} else {
			_statusLine = "";
		}
		_comm.statusLine(_tree, _statusLine);
	}
	class SListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			assert (cast(Content) e.item.getData);
			refreshConvMenu;
			refreshStatusLine;
		}
	}
	private TreeItem _dragItm = null;
	class EventDragSource : DragSourceListener {
	private:
		TreeItem _parItm;
		TreeItem _targ;
	public:
		override void dragStart(DragSourceEvent e) {
			auto itm = selection;
			e.doit = itm && (cast(Content) itm.getData).type != CType.START
				&& (cast(DragSource) e.getSource).getControl.isFocusControl;
			if (e.doit) {
				_targ = itm;
				_parItm = itm.getParentItem;
				_dragItm = _targ;
			}
		}
		override void dragSetData(DragSourceEvent e) {
			auto itm = selection;
			if (itm && XMLBytesTransfer.getInstance.isSupportedType(e.dataType)) {
				e.data = bytesFromXML((cast(Content) itm.getData).toXML);
			}
		}
		override void dragFinished(DragSourceEvent e) {
			_dragItm = null;
			auto itm = _targ;
			if (itm && e.detail == DND.DROP_MOVE) {
				if (_parItm) {
					assert (_parItm.getData);
					assert (itm.getData);
					assert ((cast(Content) _parItm.getData).detail.owner);
					assert (cast(Content) itm.getData);
					(cast(Content) _parItm.getData).remove(cast(Content) itm.getData);
				} else {
					_et.remove(cast(Content) itm.getData);
				}
				_tree.setRedraw = false;
				itm.dispose;
				_tree.setRedraw = true;
				_comm.refUseCount.call;
			}
		}
	}
	class EventDropTarget : DropTargetAdapter {
	private:
		void move(DropTargetEvent e) {
			e.detail = (e.item && cast(TreeItem) e.item && (cast(Content) e.item.getData).detail.owner)
				? DND.DROP_MOVE : DND.DROP_NONE;
		}
	public:
		override void dragEnter(DropTargetEvent e){
			move(e);
		}
		override void dragOver(DropTargetEvent e){
			move(e);
		}
		override void drop(DropTargetEvent e){
			if (!isXMLBytes(e.data)) return;
			assert (cast(TreeItem) e.item);
			e.detail = DND.DROP_NONE;
			if ((cast(Content) e.item.getData).detail.owner) {
				string id;
				auto evt = Content.createFromXML(bytesToXML(e.data), LATEST_VERSION, id);
				if (evt) {
					auto owner = cast(Content) e.item.getData;
					assert (owner.detail.owner);
					auto ti = cast(TreeItem) e.item;
					auto sp = selParent(ti);
					if (!sp || sp.eventId != id) {
						if (_dragItm) {
							auto top = topItem(ti);
							if (top is topItem(_dragItm)) {
								store(cast(Content) top.getData);
							} else {
								store(cast(Content) _dragItm.getParentItem.getData, owner);
							}
						} else {
							store(owner);
						}
						// 転送先が自分の子コンテントではないなら転送成功
						owner.add(evt);
						_tree.setRedraw = false;
						auto itm = createTreeItem(ti, evt, eventText(owner, evt), _prop.images.content(evt.type));
						_tree.setSelection = [itm];
						refreshStatusLine;
						_comm.refUseCount.call;
						if (evt.detail.owner) {
							createChilds(itm, evt);
							itm.setExpanded = true;
						}
						_tree.setRedraw = true;
						refreshStatusLine;
						e.detail = DND.DROP_MOVE;
					}
				}
			}
		}
		private Content selParent(TreeItem targ) {
			auto itm = selection;
			if (itm) {
				while (targ) {
					if (itm is targ) {
						return cast(Content) itm.getData;
					}
					targ = targ.getParentItem;
				}
			}
			return null;
		}
	}
	private CreateEvent[] _conts;
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
		void create() {
			if (_itm.getSelection) {
				_v._comp.setCursor = _cursor;
				if (_v._toolWin) {
					_v._toolWin.setCursor = _cursor;
				}
				_v._arrowMode = false;
				_v._cType = type;
				_v._evtTI = _itm;
			}
		}
		void ti(ToolItem ti) {
			_itm = ti;
		}
		void convert() {
			auto sel = selection;
			if (!sel) return;
			auto c = cast(Content) sel.getData;
			store(c);
			assert (c.canConvert(type), "convert menu item enabled");
			auto oldd = c.detail;
			c.type(type, _prop.parent);
			auto newd = c.detail;
			if (newd.use(CArg.BG_IMAGES) && !oldd.use(CArg.BG_IMAGES)) {
				c.backs = BgImageS.createBgImages(findSkin(_prop, _summ), _prop.var.etc.bgImagesDefault);
			}
			if (newd.use(CArg.DIALOGS) && !oldd.use(CArg.DIALOGS)) {
				c.dialogs = [new SDialog];
			}
			sel.setImage = _prop.images.content(type);
			foreach (itm; sel.getItems) {
				itm.setText = eventText(c, cast(Content) itm.getData);
			}
			refreshConvMenu;
			refreshStatusLine;
			_comm.refUseCount.call;
		}
	}
	ToolItem createEI(CType type, ToolBar bar, RadioGroup!(ToolItem) g, Menu convMenu) {
		auto text = _prop.msgs.content(type);
		auto img = _prop.images.content(type);
		auto imgData = img.getImageData;
		auto cursor = new Cursor(Display.getCurrent, imgData, imgData.width / 2, imgData.height / 2);
		_cursors ~= cursor;
		auto ce = new CreateEvent(this, type, cursor);
		auto itm = createToolItem(bar, text, img, &ce.create, DWT.RADIO);
		ce.ti = itm;
		g.append(itm);
		if (type != CType.START) {
			ce.convMenuItem = createMenuItem(convMenu, text, img, &ce.convert);
			ce.convMenuItem.setEnabled = false;
			_conts ~= ce;
		}
		return itm;
	}
	class CDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto cbar = cast(CoolBar) e.widget;
			_prop.var.etc.contentsOrder = cbar.getItemOrder;
			_prop.var.etc.contentsWrapIndices = cbar.getWrapIndices;
			_prop.var.etc.contentsAutoOpen = _autoOpen;
			_prop.var.etc.contentsContinue = _conti;
		}
	}
	class CCListener : ControlAdapter {
		override void controlResized(ControlEvent e) {
			if (_toolWin) {
				_toolWin.layout;
			} else {
				_comp.layout;
			}
		}
	}
	class TDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			if (_toolWin.getVisible) {
				saveToolWinPos;
			}
		}
	}
	class TCListener : ControlAdapter {
		override void controlMoved(ControlEvent e) {
			auto pb = _toolWin.getParent.getBounds;
			auto tb = _toolWin.getBounds;
			_toolWin.setBounds(tb.x + pb.x - _parX, tb.y + pb.y - _parY, tb.width, tb.height);
			_parX = pb.x;
			_parY = pb.y;
		}
	}
	class PSListener : ShellAdapter {
		override void shellActivated(ShellEvent e) {
			auto oldAct = _comm.actToolWin;
			if (oldAct && !oldAct.isDisposed && oldAct.isVisible) {
				oldAct.setVisible = false;
			}
			_comm.actToolWin = _toolWin;
			_toolWin.setVisible = _toolWinVisible;
		}
	}
	class TRDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			foreach (cur; _cursors) {
				cur.dispose;
			}
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
		}
	}
	class TSListener : ShellAdapter {
		public override void shellClosed(ShellEvent e) {
			_toolWin.setVisible = false;
			e.doit = false;
		}
	}
	class TMListener : MouseAdapter {
		override void mouseDown(MouseEvent e) {
			if (e.button == 3) {
				arrow;
			}
		}
	}
public:
	this(Commons comm, Props prop, Summary summ, Composite parent, UndoManager undo,
			void delegate(size_t[]) forceSel,
			void delegate() refreshTopStart) {
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_undo = undo;
		_forceSel = forceSel;
		_refreshTopStart = refreshTopStart;

		_comp = new Composite(parent, DWT.NONE);
		_comp.setLayout = zeroGridLayout(1, false);
		if (_prop.var.etc.contentsFloat) {
			_toolWin = new Shell(parent.getShell, DWT.TITLE | DWT.RESIZE | DWT.TOOL);
			_toolWin.setLayout = zeroGridLayout(1);
			_toolWin.setText = prop.msgs.tools;
			_toolWin.addShellListener(new TSListener);
			_toolWin.addMouseListener(new TMListener);
		}
		auto popup = new Menu(parent.getShell, DWT.POP_UP);
		createMenuItem(popup, prop.msgs.menuCEdit, prop.images.menuCEdit, &edit);
		new MenuItem(popup, DWT.SEPARATOR);
		createMenuItem(popup, _prop.msgs.menuUndo, _prop.images.menuUndo, &this.undo);
		createMenuItem(popup, _prop.msgs.menuRedo, _prop.images.menuRedo, &this.redo);
		new MenuItem(popup, DWT.SEPARATOR);
		appendMenuTCPD(prop, popup, this, true, true, true, true);
		new MenuItem(popup, DWT.SEPARATOR);
		createMenuItem(popup, _prop.msgs.menuStartToPackage, _prop.images.menuStartToPackage, &startToPackage);
		auto convMI = createMenuItem(popup, _prop.msgs.menuConvertContent, _prop.images.menuConvertContent, null, DWT.CASCADE);
		auto conv = new Menu(parent.getShell, DWT.DROP_DOWN);
		convMI.setMenu = conv;
		debug {
			new MenuItem(popup, DWT.SEPARATOR);
			createMenuItem(popup, "debug: Create CWX &Path", null, &createCWXPath);
		}
		{
			_autoOpen = _prop.var.etc.contentsAutoOpen;
			_conti = _prop.var.etc.contentsContinue;

			CoolBar cbar;
			if (_prop.var.etc.contentsFloat) {
				cbar = new CoolBar(_toolWin, DWT.NONE);
			} else {
				cbar = new CoolBar(_comp, DWT.NONE);
				cbar.addMouseListener(new TMListener);
			}
			cbar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			auto g = new RadioGroup!(ToolItem);
			_radioGroup = g;
			Menu convMenu(string text, Image img) {
				auto mi = createMenuItem(conv, text, img, null, DWT.CASCADE);
				auto m = new Menu(parent.getShell, DWT.DROP_DOWN);
				mi.setMenu = m;
				return m;
			}

			auto atm = new ToolBar(cbar, DWT.FLAT);
			atm.addMouseListener(new TMListener);
			_arrowTI = createToolItem(atm, _prop.msgs.evtArrow, _prop.images.evtArrow, &arrow, DWT.RADIO);
			_arrowTI.setSelection = true;
			g.append(_arrowTI);
			createCoolItem(cbar, atm);

			auto mode = new ToolBar(cbar, DWT.FLAT);
			mode.addMouseListener(new TMListener);
			_contiTI = createToolItem(mode, _prop.msgs.evtAddContinue, _prop.images.evtAddContinue, &addContinue, DWT.CHECK);
			_contiTI.setSelection = _conti;
			_autoOpenTI = createToolItem(mode, _prop.msgs.evtAutoOpen, _prop.images.evtAutoOpen, &autoOpen, DWT.CHECK);
			_autoOpenTI.setSelection = _autoOpen;
			createCoolItem(cbar, mode);

			auto e1 = new ToolBar(cbar, DWT.FLAT);
			e1.addMouseListener(new TMListener);
			auto e1c = convMenu(_prop.msgs.menuEvtTerminal, _prop.images.menuEvtTerminal);
			createEI(CType.START, e1, g, conv);
			createEI(CType.START_BATTLE, e1, g, e1c);
			createEI(CType.END, e1, g, e1c);
			createEI(CType.END_BAD_END, e1, g, e1c);
			createEI(CType.CHANGE_AREA, e1, g, e1c);
			createEI(CType.EFFECT_BREAK, e1, g, e1c);
			createEI(CType.LINK_START, e1, g, e1c);
			createEI(CType.LINK_PACKAGE, e1, g, e1c);
			createCoolItem(cbar, e1);

			auto e2 = new ToolBar(cbar, DWT.FLAT);
			e2.addMouseListener(new TMListener);
			auto e2c = convMenu(_prop.msgs.menuEvtStandard, _prop.images.menuEvtStandard);
			createEI(CType.TALK_MESSAGE, e2, g, e2c);
			createEI(CType.TALK_DIALOG, e2, g, e2c);
			createEI(CType.PLAY_BGM, e2, g, e2c);
			createEI(CType.PLAY_SOUND, e2, g, e2c);
			createEI(CType.WAIT, e2, g, e2c);
			createEI(CType.ELAPSE_TIME, e2, g, e2c);
			createEI(CType.EFFECT, e2, g, e2c);
			createEI(CType.CALL_START, e2, g, e2c);
			createEI(CType.CALL_PACKAGE, e2, g, e2c);
			createCoolItem(cbar, e2);

			auto e3 = new ToolBar(cbar, DWT.FLAT);
			e3.addMouseListener(new TMListener);
			auto e3c = convMenu(_prop.msgs.menuEvtData, _prop.images.menuEvtData);
			createEI(CType.BRANCH_FLAG, e3, g, e3c);
			createEI(CType.SET_FLAG, e3, g, e3c);
			createEI(CType.REVERSE_FLAG, e3, g, e3c);
			createEI(CType.BRANCH_MULTI_STEP, e3, g, e3c);
			createEI(CType.BRANCH_STEP, e3, g, e3c);
			createEI(CType.SET_STEP, e3, g, e3c);
			createEI(CType.SET_STEP_UP, e3, g, e3c);
			createEI(CType.SET_STEP_DOWN, e3, g, e3c);
			createEI(CType.CHECK_FLAG, e3, g, e3c);
			createCoolItem(cbar, e3);

			auto e4 = new ToolBar(cbar, DWT.FLAT);
			e4.addMouseListener(new TMListener);
			auto e4c = convMenu(_prop.msgs.menuEvtUtility, _prop.images.menuEvtUtility);
			createEI(CType.BRANCH_SELECT, e4, g, e4c);
			createEI(CType.BRANCH_ABILITY, e4, g, e4c);
			createEI(CType.BRANCH_RANDOM, e4, g, e4c);
			createEI(CType.BRANCH_LEVEL, e4, g, e4c);
			createEI(CType.BRANCH_STATUS, e4, g, e4c);
			createEI(CType.BRANCH_PARTY_NUMBER, e4, g, e4c);
			createEI(CType.BRANCH_AREA, e4, g, e4c);
			createEI(CType.BRANCH_BATTLE, e4, g, e4c);
			createEI(CType.BRANCH_IS_BATTLE, e4, g, e4c);
			createCoolItem(cbar, e4);

			auto e5 = new ToolBar(cbar, DWT.FLAT);
			e5.addMouseListener(new TMListener);
			auto e5c = convMenu(_prop.msgs.menuEvtBranch, _prop.images.menuEvtBranch);
			createEI(CType.BRANCH_CAST, e5, g, e5c);
			createEI(CType.BRANCH_ITEM, e5, g, e5c);
			createEI(CType.BRANCH_SKILL, e5, g, e5c);
			createEI(CType.BRANCH_INFO, e5, g, e5c);
			createEI(CType.BRANCH_BEAST, e5, g, e5c);
			createEI(CType.BRANCH_MONEY, e5, g, e5c);
			createEI(CType.BRANCH_COUPON, e5, g, e5c);
			createEI(CType.BRANCH_COMPLETE_STAMP, e5, g, e5c);
			createEI(CType.BRANCH_GOSSIP, e5, g, e5c);
			createCoolItem(cbar, e5);

			auto e6 = new ToolBar(cbar, DWT.FLAT);
			e6.addMouseListener(new TMListener);
			auto e6c = convMenu(_prop.msgs.menuEvtGet, _prop.images.menuEvtGet);
			createEI(CType.GET_CAST, e6, g, e6c);
			createEI(CType.GET_ITEM, e6, g, e6c);
			createEI(CType.GET_SKILL, e6, g, e6c);
			createEI(CType.GET_INFO, e6, g, e6c);
			createEI(CType.GET_BEAST, e6, g, e6c);
			createEI(CType.GET_MONEY, e6, g, e6c);
			createEI(CType.GET_COUPON, e6, g, e6c);
			createEI(CType.GET_COMPLETE_STAMP, e6, g, e6c);
			createEI(CType.GET_GOSSIP, e6, g, e6c);
			createCoolItem(cbar, e6);

			auto e7 = new ToolBar(cbar, DWT.FLAT);
			e7.addMouseListener(new TMListener);
			auto e7c = convMenu(_prop.msgs.menuEvtLost, _prop.images.menuEvtLost);
			createEI(CType.LOSE_CAST, e7, g, e7c);
			createEI(CType.LOSE_ITEM, e7, g, e7c);
			createEI(CType.LOSE_SKILL, e7, g, e7c);
			createEI(CType.LOSE_INFO, e7, g, e7c);
			createEI(CType.LOSE_BEAST, e7, g, e7c);
			createEI(CType.LOSE_MONEY, e7, g, e7c);
			createEI(CType.LOSE_COUPON, e7, g, e7c);
			createEI(CType.LOSE_COMPLETE_STAMP, e7, g, e7c);
			createEI(CType.LOSE_GOSSIP, e7, g, e7c);
			createCoolItem(cbar, e7);

			auto e8 = new ToolBar(cbar, DWT.FLAT);
			e8.addMouseListener(new TMListener);
			auto e8c = convMenu(_prop.msgs.menuEvtVisual, _prop.images.menuEvtVisual);
			createEI(CType.SHOW_PARTY, e8, g, e8c);
			createEI(CType.HIDE_PARTY, e8, g, e8c);
			createEI(CType.CHANGE_BG_IMAGE, e8, g, e8c);
			createEI(CType.REDISPLAY, e8, g, e8c);
			createCoolItem(cbar, e8, 2);

			if (_prop.var.etc.contentsOrder.length == cbar.getItemCount) {
				cbar.setItemOrder(_prop.var.etc.contentsOrder);
			}
			int[] wi;
			foreach (i; _prop.var.etc.contentsWrapIndices) {
				if (i > 0 && i < cbar.getItemCount) wi ~= i;
			}
			cbar.setWrapIndices(wi);

			cbar.addControlListener(new CCListener);
			cbar.addDisposeListener(new CDListener);
		}
		if (_toolWin) {
			auto dummy = new Composite(_toolWin, DWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.heightHint = 0;
			dummy.setLayoutData = gd;
			_toolWin.setVisible = false;
			auto pb = _toolWin.getParent.getBounds;
			auto twb = _toolWin.getBounds;
			auto ts = _toolWin.computeSize(DWT.DEFAULT, DWT.DEFAULT);
			int tx = _prop.var.contentsWin.x == DWT.DEFAULT ? twb.x : pb.x + _prop.var.contentsWin.x;
			int ty = _prop.var.contentsWin.y == DWT.DEFAULT ? twb.y : pb.y + _prop.var.contentsWin.y;
			intoDisplay(tx, ty, ts.x, ts.y);
			_parX = pb.x;
			_parY = pb.y;
			_toolWin.setBounds(tx, ty, ts.x, ts.y);
			_toolWin.addDisposeListener(new TDListener);
			_toolWin.getParent.addControlListener(new TCListener);
			parent.getShell.addShellListener(new PSListener);
		}
		_tree = new Tree(_comp, DWT.SINGLE | DWT.BORDER);
		_tree.setLayoutData = new GridData(GridData.FILL_BOTH);
		new TreeEdit(_tree, &editEnd, &createEditor);
		_tree.addDisposeListener(new TRDListener);
		_tree.addMouseListener(new CreateL);
		auto editl = new EditL;
		_tree.addKeyListener(editl);
		_tree.addMouseListener(editl);
		{
			_tree.setMenu = popup;
		}
		_tree.addSelectionListener(new SListener);

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

		auto dt = new DropTarget(_tree, DND.DROP_DEFAULT | DND.DROP_MOVE);
		dt.setTransfer = [XMLBytesTransfer.getInstance];
		dt.addDropListener(new EventDropTarget);
		auto ds = new DragSource(_tree, DND.DROP_MOVE);
		ds.setTransfer = [XMLBytesTransfer.getInstance];
		ds.addDragListener(new EventDragSource);
	}
	private int _parX, _parY;
	private void saveToolWinPos() {
		assert (_toolWin);
		_prop.var.contentsWin.x = _toolWin.getBounds.x - _toolWin.getParent.getBounds.x;
		_prop.var.contentsWin.y = _toolWin.getBounds.y - _toolWin.getParent.getBounds.y;
	}

	Control widget() {return _comp;}

	string statusLine() {return _statusLine;}

	void undo() {_undo.undo;}
	void redo() {_undo.redo;}
	debug {
		void createCWXPath() {
			auto itm = selection;
			if (itm) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				auto c = cast(Content) itm.getData;
				cb.setContents([new ArrayWrapperString(c.cwxPath)], [TextTransfer.getInstance]);
			}
		}
	}

	private void refreshConvMenu() {
		if (!_et || !selection) {
			foreach (ce; _conts) {
				ce.convMenuItem.setEnabled = false;
			}
		} else {
			auto c = cast(Content) selection.getData;
			foreach (ce; _conts) {
				ce.convMenuItem.setEnabled = c.canConvert(ce.type);
			}
		}
	}
	private void startToPackage() {
		if (!_et || !selection) return;
		auto sel = selection;
		if (!sel) return;
		auto base = cast(Content) selection.getData;
		auto startItm = topItem(sel);
		auto start = base.parentStart;
		assert (start);
		assert (start is startItm.getData, start.name ~ " : " ~ startItm.getText);
		int index = _tree.indexOf(startItm);
		if (index == 0) return;
		TreeItem[] users;
		Content[] conts = [start];
		void find(TreeItem itm) {
			auto c = cast(Content) itm.getData;
			if (c.start == start.name) {
				users ~= itm;
				conts ~= c;
			}
			foreach (cld; itm.getItems) find(cld);
		}
		foreach (itm; _tree.getItems) find(itm);
		auto ucp = new UndoCP(conts, index, start);
		auto id = _comm.createPackage(start);
		if (id == 0) {
			ucp.dispose;
			return;
		}
		_undo ~= ucp;
		delImpl(startItm, false);
		foreach (itm; users) {
			auto c = cast(Content) itm.getData;
			switch (c.type) {
			case CType.LINK_START: {
				c.type(CType.LINK_PACKAGE, _prop.parent);
				c.packages = id;
			} break;
			case CType.CALL_START: {
				c.type(CType.CALL_PACKAGE, _prop.parent);
				c.packages = id;
			} break;
			default: assert (0);
			}
			itm.setImage = _prop.images.content(c.type);
		}
		refreshStatusLine;
		_comm.refUseCount.call;
	}

	void refresh(EventTree et) {
		_comm.statusLine(_tree, "");
		_statusLine = "";
		if (_et !is et) {
			_et = et;
			_tree.setRedraw = false;
			_tree.removeAll;
			if (et) {
				foreach (start; et.starts) {
					auto itm = createTreeItem(_tree, start, start.name, _prop.images.content(CType.START));
					createChilds(itm, start);
					itm.setExpanded = true;
				}
			} else {
				closeToolWindow;
			}
			_tree.setRedraw = true;
			refreshStatusLine;
		}
	}
	void treeOpen() {
		treeExpandedAll(_tree);
	}
	void treeClose() {
		treeUnexpandedAll(_tree);
	}
	private void editEnd(TreeItem itm, Control c) {
		auto t = cast(Text) c;
		auto evt = (cast(Content) itm.getData);
		if (t) {
			if (t.getText == evt.name) return;
			store(evt);
			if (evt.type == CType.START) {
				evt.name = createNewName(t.getText, (string name) {
					foreach (s; _et.starts) {
						if (s !is evt && icmp(s.name, name) == 0) {
							return false;
						}
					}
					return true;
				}, true);
			} else {
				evt.name = t.getText;
			}
			itm.setText = evt.name;
			if (evt.type == CType.START && _tree.indexOf(itm) == 0) {
				_refreshTopStart();
			}
		} else {
			auto combo = cast(CCombo) c;
			int index = combo.getSelectionIndex;
			auto data = cast(Content) itm.getParentItem.getData;
			string name;
			switch (data.type) {
			case CType.BRANCH_MULTI_STEP: {
				if (index + 1 < combo.getItemCount) {
					name = to!(string)(index);
				} else {
					assert (index + 1 == combo.getItemCount);
					name = _prop.msgs.evtChildDefault;
				}
				break;
			} case CType.BRANCH_AREA: {
				if (index < _summ.areas.length) {
					name = to!(string)(_summ.areas[index].id);
				} else {
					assert (index == _summ.areas.length);
					name = _prop.msgs.evtChildDefault;
				}
				break;
			} case CType.BRANCH_BATTLE: {
				if (index < _summ.battles.length) {
					name = to!(string)(_summ.battles[index].id);
				} else {
					assert (index == _summ.battles.length);
					name = _prop.msgs.evtChildDefault;
				}
				break;
			} default:
				assert (combo.getItemCount == 2);
				name = index == 0 ? _prop.msgs.evtChildTrue : _prop.msgs.evtChildFalse;
			}
			if (name == evt.name) return;
			store(evt);
			evt.name = name;
			itm.setText = combo.getText;
			_comm.refUseCount.call;
		}
		refreshStatusLine;
	}
	private CCombo createBoolEditor(string Create)(Content evt, Content child) {
		string[] vals;
		vals.length = 2;
		string name = _prop.msgs.evtChildTrue;
		vals[0] = mixin (Create);
		name = _prop.msgs.evtChildFalse;
		vals[1] = mixin (Create);
		return createComboEditor(_tree, vals, vals[child.name == _prop.msgs.evtChildTrue ? 0 : 1]);
	}
	private CCombo createBoolEditor2(string Create)(Content evt, Content child) {
		string[] vals;
		vals.length = 2;
		string name = _prop.msgs.evtChildTrue;
		vals[0] = mixin (Create);
		name = _prop.msgs.evtChildFalse;
		vals[1] = mixin (Create);
		return createComboEditor(_tree, vals, vals[child.name == _prop.msgs.evtChildTrue ? 0 : 1]);
	}
	private CCombo createNumEditor(string Create)(Content evt, Content child, ulong[] nums) {
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
		string name = _prop.msgs.evtChildDefault;
		vals[$ - 1] = mixin (Create);
		return createComboEditor(_tree, vals, vals[index]);
	}
	private CCombo createAreaSelectEditor(string Create, A)(Content evt, Content child, A[] areas) {
		ulong[] nums;
		nums.length = areas.length;
		foreach (i, area; areas) {
			nums[i] = area.id;
		}
		return createNumEditor!(Create)(evt, child, nums);
	}
	private Control createEditor(TreeItem itm) {
		auto parent = itm.getParentItem;
		if (parent) {
			if ((cast(Content) parent.getData).detail.nextType == CNextType.TEXT) {
				return createTextEditor(_tree, (cast(Content) itm.getData).name);
			}
		} else if (_tree.getItem(0) is itm) {
			return null;
		} else {
			return createTextEditor(_tree, (cast(Content) itm.getData).name);
		}
		auto data = cast(Content) parent.getData;
		auto c = cast(Content) itm.getData;
		switch (data.type) {
		case CType.BRANCH_FLAG: {
			return createBoolEditor!("_prop.msgs.evtChildBrFlag(_summ.flagDirRoot.findFlag(evt.flag), name)")(data, c);
		} case CType.BRANCH_MULTI_STEP: {
			Step step = _summ.flagDirRoot.findStep(data.step);
			ulong[] nums;
			ulong count = step is null ? _prop.looks.stepMaxCount : step.count;
			for (ulong i = 0; i < count; i++) {
				nums ~= i;
			}
			return createNumEditor!("_prop.msgs.evtChildBrStepN(_summ.flagDirRoot.findStep(evt.step), name)")(data, c, nums);
		} case CType.BRANCH_STEP: {
			return createBoolEditor!("_prop.msgs.evtChildBrStepUL(_summ.flagDirRoot.findStep(evt.step), evt.stepValue, name)")(data, c);
		} case CType.BRANCH_SELECT: {
			return createBoolEditor!("_prop.msgs.evtChildBrMember(evt.targetAll, evt.random, name)")(data, c);
		} case CType.BRANCH_ABILITY: {
			return createBoolEditor!("_prop.msgs.evtChildBrPower(evt.targetS, evt.physical, evt.mental, evt.level, name)")(data, c);
		} case CType.BRANCH_RANDOM: {
			return createBoolEditor!("_prop.msgs.evtChildBrRandom(evt.percent, name)")(data, c);
		} case CType.BRANCH_LEVEL: {
			return createBoolEditor!("_prop.msgs.evtChildBrLevel(evt.level, evt.average, name)")(data, c);
		} case CType.BRANCH_STATUS: {
			return createBoolEditor!("_prop.msgs.evtChildBrState(evt.targetNS, evt.status, name)")(data, c);
		} case CType.BRANCH_PARTY_NUMBER: {
			return createBoolEditor!("_prop.msgs.evtChildBrNum(evt.partyNumber, name)")(data, c);
		} case CType.BRANCH_AREA: {
			return createAreaSelectEditor!("_prop.msgs.evtChildBrArea(_summ.areas, name)")(data, c, _summ.areas);
		} case CType.BRANCH_BATTLE: {
			return createAreaSelectEditor!("_prop.msgs.evtChildBrBattle(_summ.battles, name)")(data, c, _summ.battles);
		} case CType.BRANCH_IS_BATTLE: {
			return createBoolEditor!("_prop.msgs.evtChildBrOnBattle(name)")(data, c);
		} case CType.BRANCH_CAST: {
			return createBoolEditor!("_prop.msgs.evtChildBrCast(_summ.casts(evt.casts), name)")(data, c);
		} case CType.BRANCH_ITEM: {
			return createBoolEditor!("_prop.msgs.evtChildBrItem(_summ.item(evt.item), evt.range, evt.cardNumber, name)")(data, c);
		} case CType.BRANCH_SKILL: {
			return createBoolEditor!("_prop.msgs.evtChildBrSkill( _summ.skill(evt.skill), evt.range, evt.cardNumber, name)")(data, c);
		} case CType.BRANCH_BEAST: {
			return createBoolEditor!("_prop.msgs.evtChildBrBeast(_summ.beast(evt.beast), evt.range, evt.cardNumber, name)")(data, c);
		} case CType.BRANCH_INFO: {
			return createBoolEditor!("_prop.msgs.evtChildBrInfo(_summ.info(evt.info), name)")(data, c);
		} case CType.BRANCH_MONEY: {
			return createBoolEditor!("_prop.msgs.evtChildBrMoney(evt.money, name)")(data, c);
		} case CType.BRANCH_COUPON: {
			return createBoolEditor!("_prop.msgs.evtChildBrCoupon(evt.range, evt.coupon, name)")(data, c);
		} case CType.BRANCH_COMPLETE_STAMP: {
			return createBoolEditor!("_prop.msgs.evtChildBrEnd(evt.completeStamp, name)")(data, c);
		} case CType.BRANCH_GOSSIP: {
			return createBoolEditor!("_prop.msgs.evtChildBrGossip(evt.gossip, name)")(data, c);
		} default:
		}
		return null;
	}
	/// Params:
	/// parent = 親イベント。
	/// e = イベント。名称が書き換えられる。
	/// Returns: テキスト。
	private string eventText(Content parent, Content e) in {
		assert (parent.detail.owner);
	} body {
		if (!parent) return e.name;
		if (parent.detail.nextType == CNextType.TEXT) {
			return e.name.length > 0 ? e.name : " ";
		}
		string name = e.name;
		string r;
		switch (parent.type) {
		case CType.BRANCH_FLAG: {
			r = _prop.msgs.evtChildBrFlag(_summ.flagDirRoot.findFlag(parent.flag), name);
			break;
		} case CType.BRANCH_MULTI_STEP: {
			r = _prop.msgs.evtChildBrStepN(_summ.flagDirRoot.findStep(parent.step), name);
			break;
		} case CType.BRANCH_STEP: {
			r = _prop.msgs.evtChildBrStepUL(_summ.flagDirRoot.findStep(parent.step), parent.stepValue, name);
			break;
		} case CType.BRANCH_SELECT: {
			r = _prop.msgs.evtChildBrMember(parent.targetAll, parent.random, name);
			break;
		} case CType.BRANCH_ABILITY: {
			r = _prop.msgs.evtChildBrPower(parent.targetS, parent.physical, parent.mental, parent.level, name);
			break;
		} case CType.BRANCH_RANDOM: {
			r = _prop.msgs.evtChildBrRandom(parent.percent, name);
			break;
		} case CType.BRANCH_LEVEL: {
			r = _prop.msgs.evtChildBrLevel(parent.level, parent.average, name);
			break;
		} case CType.BRANCH_STATUS: {
			r = _prop.msgs.evtChildBrState(parent.targetNS, parent.status, name);
			break;
		} case CType.BRANCH_PARTY_NUMBER: {
			r = _prop.msgs.evtChildBrNum(parent.partyNumber, name);
			break;
		} case CType.BRANCH_AREA: {
			r = _prop.msgs.evtChildBrArea(_summ.areas, name);
			break;
		} case CType.BRANCH_BATTLE: {
			r = _prop.msgs.evtChildBrBattle(_summ.battles, name);
			break;
		} case CType.BRANCH_IS_BATTLE: {
			r = _prop.msgs.evtChildBrOnBattle(name);
			break;
		} case CType.BRANCH_CAST: {
			r = _prop.msgs.evtChildBrCast(_summ.casts(parent.casts), name);
			break;
		} case CType.BRANCH_ITEM: {
			r = _prop.msgs.evtChildBrItem(_summ.item(parent.item), parent.range, parent.cardNumber, name);
			break;
		} case CType.BRANCH_SKILL: {
			r = _prop.msgs.evtChildBrSkill(_summ.skill(parent.skill), parent.range, parent.cardNumber, name);
			break;
		} case CType.BRANCH_BEAST: {
			r = _prop.msgs.evtChildBrBeast(_summ.beast(parent.beast), parent.range, parent.cardNumber, name);
			break;
		} case CType.BRANCH_INFO: {
			r = _prop.msgs.evtChildBrInfo(_summ.info(parent.info), name);
			break;
		} case CType.BRANCH_MONEY: {
			r = _prop.msgs.evtChildBrMoney(parent.money, name);
			break;
		} case CType.BRANCH_COUPON: {
			r = _prop.msgs.evtChildBrCoupon(parent.range, parent.coupon, name);
			break;
		} case CType.BRANCH_COMPLETE_STAMP: {
			r = _prop.msgs.evtChildBrEnd(parent.completeStamp, name);
			break;
		} case CType.BRANCH_GOSSIP: {
			r = _prop.msgs.evtChildBrGossip(parent.gossip, name);
			break;
		} default:
			name = "";
			r = "";
		}
		e.name = name;
		return r;
	}
	private void createChilds(TreeItem parent, Content evt, bool select = false) {
		if (!evt.detail.owner) return;
		parent.removeAll;
		foreach (c; evt.next) {
			auto itm = createTreeItem(parent, c, eventText(evt, c), _prop.images.content(c.type));
			if (select) {
				_tree.setSelection = [itm];
			}
			if (c.detail.owner) {
				createChilds(itm, c, select);
			}
			itm.setExpanded = true;
		}
	}

	EventTree eventTree() {
		return _et;
	}
	bool isFocusControl() {
		return _tree.isFocusControl;
	}

	private void __ud(string ToIndex)(TreeItem itm, int function(TreeItem) treeSwap, bool store) {
		if (!_et) return;
		if (itm) {
			_tree.setRedraw = false;
			scope (exit) _tree.setRedraw = true;
			if (itm.getParentItem) {
				auto p = cast(Content) itm.getParentItem.getData;
				int i = treeSwap(itm);
				if (i >= 0) {
					if (store) this.store(p);
					p.swapContent(i, mixin(ToIndex));
					_tree.showSelection;
				}
			} else {
				int i = treeSwap(itm);
				int j = mixin(ToIndex);
				if (i >= 0) {
					if (store) this.store(i, j);
					_et.swapStart(i, j);
					_tree.showSelection;
				}
				if (i == 0 || j == 0) {
					_refreshTopStart();
				}
			}
		}
	}
	private void up(TreeItem itm, bool store) {
		if (!itm) return;
		__ud!("i - 1")(itm, &treeItemUp, store);
	}
	void up() {
		up(selection, true);
	}
	private void down(TreeItem itm, bool store) {
		if (!itm) return;
		__ud!("i + 1")(itm, &treeItemDown, store);
	}
	void down() {
		down(selection, true);
	}

	void openToolWindow() {
		if (_toolWin) {
			if (_et) {
				if (_opened) {
					_toolWin.setVisible = true;
					_toolWinVisible = true;
				} else {
					_opened = true;
					_toolWin.open;
					_toolWinVisible = true;
				}
			} else {
				_toolWinVisible = true;
			}
		}
	}
	void closeToolWindow() {
		if (_toolWin) {
			_toolWin.setVisible = false;
			_toolWinVisible = false;
		}
	}
	void refreshTreeName() {
		_tree.getItems[0].setText = _et.name;
		refreshStatusLine;
	}

	override {
		void cut() {
			auto itm = selection;
			if (itm && itm !is _tree.getItems[0]) {
				copy;
				del;
			}
		}
		void copy() {
			auto itm = selection;
			if (itm) {
				string xml = (cast(Content) itm.getData).toXML;
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(_prop, cb, xml);
			}
		}
		void paste() {
			auto cb = new Clipboard(Display.getCurrent);
			scope (exit) cb.dispose;
			string c;
			try {
				c = CBtoXML(cb);
			} catch (Exception e) {
				// たまにアクセス違反が起こる
				debugln(e);
				return;
			}
			if (c) {
				string id;
				auto evt = Content.createFromXML(c, LATEST_VERSION, id);
				if (!evt) return;
				if (evt.type == CType.START) {
					_tree.setRedraw = false;
					evt.name = createNewName(evt.name, (string name) {
						foreach (s; _et.starts) {
							if (icmp(s.name, name) == 0) {
								return false;
							}
						}
						return true;
					}, true);
					auto sel = selection;
					int index;
					if (sel) {
						index = _tree.indexOf(topItem(sel)) + 1;
					} else {
						index = -1;
					}
					auto top = _tree.getTopItem;
					store(index);
					_et.insert(index, evt);
					auto sItm = createTreeItem(_tree, evt, evt.name, _prop.images.content(evt.type), index);
					_tree.select = sItm;
					createChilds(sItm, evt, true);
					sItm.setExpanded = true;
					_tree.showSelection;
					_tree.setRedraw = true;
				} else {
					auto itm = selection;
					if (itm && (cast(Content) itm.getData).detail.owner) {
						_tree.setRedraw = false;
						auto owner = cast(Content) itm.getData;
						store(owner);
						owner.add(evt);
						createChilds(itm, owner, true);
						_tree.setRedraw = true;
					} else {
						return;
					}
				}
				_comm.refUseCount.call;
				refreshStatusLine;
			}
		}
		void del() {
			auto itm = selection;
			if (itm && itm !is _tree.getItems[0]) {
				_tree.setRedraw = false;
				scope(exit) _tree.setRedraw = true;
				delImpl(itm, true);
				_comm.refUseCount.call;
			}
		}
		bool canDoTCPD() {
			return _tree.isFocusControl;
		}
	}
	private void delImpl(TreeItem itm, bool store) {
		auto ownerItm = itm.getParentItem;
		auto c = cast(Content) itm.getData;
		if (ownerItm) {
			auto owner = cast(Content) ownerItm.getData;
			if (store) this.store(owner);
			owner.remove(c);
		} else {
			if (store) this.store(cwx.utils.indexOf!("a is b")(_et.starts, c), c);
			_et.remove(c);
		}
		itm.dispose;
	}
	private void __refreshCard(TreeItem evt) {
		foreach (childItm; evt.getItems) {
			auto child = cast(Content) childItm.getData;
			childItm.setText = eventText(cast(Content) evt.getData, child);
			if (child.detail.owner) {
				__refreshCard(childItm);
			}
		}
	}
	private void __refreshCard() {
		if (_tree.isDisposed) return;
		if (_et) {
			foreach (itm; _tree.getItems) {
				__refreshCard(itm);
			}
			refreshStatusLine;
		}
	}
	private void __refreshEventTextImpl(Content par, TreeItem itm) in {
		assert (par.detail.owner);
	} body {
		auto e = cast(Content) itm.getData;
		itm.setText = eventText(par, e);
		if (e.detail.owner) {
			foreach (child; itm.getItems) {
				__refreshEventTextImpl(e, child);
			}
		} else {
			assert (!itm.getItems.length);
		}
	}
	private void __refreshEventText() {
		if (_et) {
			foreach (itm; _tree.getItems) {
				auto start = cast(Content) itm.getData;
				assert (start.type == CType.START);
				itm.setText = start.name;
				foreach (child; itm.getItems) {
					__refreshEventTextImpl(start, child);
				}
			}
			refreshStatusLine;
		}
	}
	private void __refreshCast(CastCard c) {__refreshCard;}
	private void __refreshSkill(SkillCard c) {__refreshCard;}
	private void __refreshItem(ItemCard c) {__refreshCard;}
	private void __refreshBeast(BeastCard c) {__refreshCard;}
	private void __refreshInfo(InfoCard c) {__refreshCard;}
	private void __refreshArea(Area c) {__refreshCard;}
	private void __refreshPackage(Package c) {__refreshCard;}
	private void __refreshBattle(Battle c) {__refreshCard;}
	private void __refreshFlagAndStep(Flag[] flags, Step[] steps) {
		if (flags.length > 0 || steps.length > 0) {
			__refreshCard;
		}
	}
	private void __refreshPath(string from, string to, bool isDir) {refreshStatusLine;}
	private void __refreshPaths(string path) {refreshStatusLine;}
	private void __deletePaths() {refreshStatusLine;}
	private void __replacePaths(string from, string to) {refreshStatusLine;}

	private bool openCWXPathImpl(T)(T itm, string path) {
		auto cate = cpcategory(path);
		if (cate == "") {
			auto index = cpindex(path);
			if (index >= itm.getItemCount) return false;
			auto child = itm.getItem(index);
			path = cpbottom(path);
			if (path == "" || cpcategory(path) != "") {
				forceFocus(_tree);
				_tree.select = child;
				refreshStatusLine;
				return true;
			} else {
				return openCWXPathImpl(child, path);
			}
		}
		return false;
	}
	bool openCWXPath(string path) {
		return openCWXPathImpl(_tree, path);
	}
}
