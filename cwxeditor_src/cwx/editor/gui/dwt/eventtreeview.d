
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

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.eventdialog;
import cwx.editor.gui.dwt.message;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.scripterrordialog;

import std.algorithm;
import std.conv;
import std.string;

import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;
import org.eclipse.swt.widgets.CoolBar;
import org.eclipse.swt.widgets.CoolItem;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.custom.CCombo;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.PaletteData;
import org.eclipse.swt.graphics.RGB;
import org.eclipse.swt.graphics.Cursor;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.events.ControlAdapter;
import org.eclipse.swt.events.ControlEvent;
import org.eclipse.swt.events.KeyListener;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.graphics.RGB;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.dnd.Clipboard;
import org.eclipse.swt.dnd.ByteArrayTransfer;
import org.eclipse.swt.dnd.TextTransfer;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.DragSourceAdapter;
import org.eclipse.swt.dnd.DragSourceListener;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetListener;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTarget;

import java.lang.all;

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
			if (e.character == SWT.CR) {
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
		_comm.refContent.call(c);
		_comm.refUseCount.call;
		_refreshTopStart();
	}
	class UndoContent : ETVUndo {
		private size_t[][] _path;
		private Content[] _c;
		this (Content[] cs) {
			foreach (c; cs) {
				_path ~= c.ctPath;
				auto node = c.toNode;
				_c ~= Content.createFromNode(node, LATEST_VERSION);
				_c[$ - 1].setUseCounter(_summ.useCounter.sub);
			}
		}
		private void impl() {
			udb;
			scope (exit) uda;
			foreach (i, c; _c.dup) {
				auto node = _et.fromPath(_path[i]).toNode;
				_c[i] = Content.createFromNode(node, LATEST_VERSION);
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
			_upIndex = swapIndex1 > swapIndex2 ? swapIndex1 : swapIndex2;
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
	void storeSwap(int swapIndex1, int swapIndex2) {
		_undo ~= new UndoSwap(swapIndex1, swapIndex2);
	}
	class UndoInsert : ETVUndo {
		private int _index;
		private size_t _count;
		private Content[] _c;
		this (int index, size_t count) {
			_index = index;
			_count = count;
		}
		override void undo() {
			udb;
			scope (exit) uda;
			_tree.setRedraw = false;
			scope (exit) _tree.setRedraw = true;
			for (size_t i = 0; i < _count; i++) {
				auto node = _et.starts[_index].toNode;
				auto c = Content.createFromNode(node, LATEST_VERSION);
				c.setUseCounter(_summ.useCounter.sub);
				_c ~= c;
				delImpl(_tree.getItem(_index), false);
			}
			refreshStatusLine;
			_comm.refUseCount.call;
			_refreshTopStart();
		}
		override void redo() {
			udb;
			scope (exit) uda;
			foreach_reverse (c; _c) {
				insertStart(_index, c);
			}
			_c = [];
		}
		override void dispose() {
			foreach (c; _c) {
				c.removeUseCounter;
			}
		}
	}
	void storeInsert(int insertIndex, size_t count = 1) {
		_undo ~= new UndoInsert(insertIndex, count);
	}
	class UndoDelete : ETVUndo {
		private int _index;
		private Content _c;
		this (int index, Content del) {
			_index = index;
			auto node = del.toNode;
			_c = Content.createFromNode(node, LATEST_VERSION);
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
	void storeDelete(int index, Content del) {
		_undo ~= new UndoDelete(index, del);
	}
	private TreeItem fromPath(string cwxPath) {
		return fromPathImpl(_tree, cwxPath);
	}
	private TreeItem fromPathImpl(T)(T tree, string cwxPath) {
		if ("" == cwxPath) return null;
		string cate = cpcategory(cwxPath);
		while ("" != cate) {
			cwxPath = cpbottom(cwxPath);
			if ("" == cwxPath) return null;
			cate = cpcategory(cwxPath);
		}
		auto itm = tree.getItem(cpindex(cwxPath));
		cwxPath = cpbottom(cwxPath);
		if ("" == cwxPath) return itm;
		return fromPathImpl(itm, cwxPath);
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

	private EventDialog[Content] _editDlgs;
	void appliedEdit(UndoContent undo, Content c) {
		_undo ~= undo;
		auto itm = fromPath(c.cwxPath);
		assert (c is itm.getData);
		foreach (childItm; itm.getItems) {
			auto par = cast(Content) itm.getData;
			assert (par.detail.owner);
			childItm.setText = eventText(par, cast(Content) childItm.getData);
		}
		_comm.refContent.call(c);
		_comm.refUseCount.call;
		refreshStatusLine;
	}
	void edit() {
		auto sels = _tree.getSelection;
		if (sels.length > 0) {
			auto c = cast(Content) sels[0].getData;
			edit(c);
		}
	}
	void create(TreeItem insertTo) {
		if (!_tree.getItems.length) return;
		if (!_arrowMode) {
			_tree.setRedraw = false;
			scope (exit) _tree.setRedraw = true;
			if (_cType == CType.START) {
				if (insertTo) return;
				create(null, _cType, "", (Content evt) {
					assert (evt);
					auto sel = selection;
					int index;
					if (sel) {
						index = _tree.indexOf(topItem(sel)) + 1;
					} else {
						index = -1;
					}
					storeInsert(index);
					_et.insert(index, cast(Content) evt);
					auto sItm = createTreeItem(_tree, evt, evt.name, _prop.images.content(CType.START), index);
					_tree.select = sItm;
					_tree.showSelection;
					_comm.refContent.call(evt);
					refreshConvMenu;
					refreshStatusLine;
					if (!_conti) arrow;
				});
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
					void applied(Content evt) {
						store(owner);
						owner.add(evt);
						TreeItem itm = createTreeItem(oItm, evt, eventText(owner, evt), _prop.images.content(evt.type));
						oItm.setExpanded = true;
						_tree.setSelection = [itm];
						if (insertTo) {
							auto ic = cast(Content) insertTo.getData;
							_comm.delContent.call(ic);
							evt.add(ic);
							insertTo.dispose;
							createChilds(itm, evt, false);
							itm.setExpanded = true;
						}
						_tree.showSelection;
						_comm.refContent.call(evt);
						_comm.refUseCount.call;
						refreshConvMenu;
						refreshStatusLine;
						if (!_conti) arrow;
					}
					if (insertTo) {
						create(owner, _cType, (cast(Content) insertTo.getData).name, &applied);
					} else {
						create(owner, _cType, "", &applied);
					}
				}
			}
		}
	}
	void arrow() {
		_arrowMode = true;
		_comp.setCursor = null;
		if (_toolWin && !_toolWin.isDisposed) {
			_toolWin.setCursor = null;
		}
		_radioGroup.select = _arrowTI;
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
		switch (type) {
		case CType.START_BATTLE: {
			return _summ.battles.length > 0;
		} case CType.CHANGE_AREA: {
			return _summ.areas.length > 0;
		} case CType.LINK_PACKAGE, CType.CALL_PACKAGE: {
			return _summ.packages.length > 0;
		} case CType.BRANCH_FLAG, CType.SET_FLAG, CType.REVERSE_FLAG, CType.CHECK_FLAG: {
			return _summ.flagDirRoot.allFlags.length > 0;
		} case CType.BRANCH_MULTI_STEP, CType.BRANCH_STEP, CType.SET_STEP, CType.SET_STEP_UP, CType.SET_STEP_DOWN: {
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
		assert (parent.detail.owner);
		if (!_conti) arrow;
		void initial(Content c) {
			if (type is CType.CHANGE_BG_IMAGE) {
				c.backs = BgImageS.createBgImages(_comm.skin, _prop.var.etc.bgImagesDefault);
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
				name = createNewName(_prop.msgs.defaultStartName, (string name) {
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
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.END: {
			dlg = new ClearEventDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.CHANGE_AREA: {
			dlg = new AreaSelectDialog!(CType.CHANGE_AREA, Area, "summary.areas")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.CHANGE_BG_IMAGE: {
			auto c = new Content(type, name);
			c.backs = BgImageS.createBgImages(_comm.skin, _prop.var.etc.bgImagesDefault);
			dlg = new BgImagesDialog(_comm, _prop, _tree.getShell, _summ, parent, c, refTarget);
			break;
		} case CType.EFFECT: {
			dlg = new EffectDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LINK_START: {
			dlg = new StartSelectDialog!(CType.LINK_START)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LINK_PACKAGE: {
			dlg = new AreaSelectDialog!(CType.LINK_PACKAGE, Package, "summary.packages")(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.TALK_MESSAGE: {
			dlg = new MessageDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.TALK_DIALOG: {
			dlg = new SpeakDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.PLAY_BGM: {
			dlg = new BgmDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.PLAY_SOUND: {
			dlg = new SeDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.WAIT: {
			dlg = new WaitEventDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.CALL_START: {
			dlg = new StartSelectDialog!(CType.CALL_START)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.CALL_PACKAGE: {
			dlg = new AreaSelectDialog!(CType.CALL_PACKAGE, Package, "summary.packages")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_FLAG: {
			dlg = new BrFlagDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_MULTI_STEP: {
			dlg = new BrStepNDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_STEP: {
			dlg = new BrStepULDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_SELECT: {
			dlg = new BrMemberDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_ABILITY: {
			dlg = new BrPowerDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_RANDOM: {
			dlg = new BrRandomEventDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_LEVEL: {
			dlg = new BrLevelDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_STATUS: {
			dlg = new BrStateDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_PARTY_NUMBER: {
			dlg = new BrNumEventDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_CAST: {
			dlg = new AreaSelectDialog!(CType.BRANCH_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_ITEM: {
			dlg = new BrItemDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_SKILL: {
			dlg = new BrSkillDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_INFO: {
			dlg = new AreaSelectDialog!(CType.BRANCH_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_BEAST: {
			dlg = new BrBeastDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_MONEY: {
			dlg = new MoneyEventDialog!(CType.BRANCH_MONEY)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_COUPON: {
			dlg = new CouponEventDialog!(CType.BRANCH_COUPON, false)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_COMPLETE_STAMP: {
			dlg = new EndEventDialog!(CType.BRANCH_COMPLETE_STAMP)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_GOSSIP: {
			dlg = new GossipEventDialog!(CType.BRANCH_GOSSIP)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.SET_FLAG: {
			dlg = new FlagSetDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP: {
			dlg = new StepSetDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP_UP: {
			dlg = new StepPlusDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP_DOWN: {
			dlg = new StepMinusDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.REVERSE_FLAG: {
			dlg = new FlagRDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.CHECK_FLAG: {
			dlg = new FlagJudgeDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.GET_CAST: {
			dlg = new AreaSelectDialog!(CType.GET_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_ITEM: {
			dlg = new GetItemDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_SKILL: {
			dlg = new GetSkillDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_INFO: {
			dlg = new AreaSelectDialog!(CType.GET_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_BEAST: {
			dlg = new GetBeastDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_MONEY: {
			dlg = new MoneyEventDialog!(CType.GET_MONEY)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_COUPON: {
			dlg = new CouponEventDialog!(CType.GET_COUPON, true)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_COMPLETE_STAMP: {
			dlg = new EndEventDialog!(CType.GET_COMPLETE_STAMP)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_GOSSIP: {
			dlg = new GossipEventDialog!(CType.GET_GOSSIP)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_CAST: {
			dlg = new AreaSelectDialog!(CType.LOSE_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_ITEM: {
			dlg = new LostItemDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_SKILL: {
			dlg = new LostSkillDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_INFO: {
			dlg = new AreaSelectDialog!(CType.LOSE_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_BEAST: {
			dlg = new LostBeastDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_MONEY: {
			dlg = new MoneyEventDialog!(CType.LOSE_MONEY)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_COUPON: {
			dlg = new CouponEventDialog!(CType.LOSE_COUPON, false)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_COMPLETE_STAMP: {
			dlg = new EndEventDialog!(CType.LOSE_COMPLETE_STAMP)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_GOSSIP: {
			dlg = new GossipEventDialog!(CType.LOSE_GOSSIP)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.REDISPLAY: {
			dlg = new RefreshDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} default: assert (0, to!string(type));
		}
		assert (applied);
		dlg.appliedEvent ~= {
			auto evt = dlg.event;
			applied(evt);

			auto undo = new UndoContent([evt]);
			dlg.appliedEvent.length = 0;
			dlg.appliedEvent ~= {
				appliedEdit(undo, evt);
				undo = new UndoContent([evt]);
			};
		};
		_editDlgs[evt] = dlg;
		dlg.closeEvent ~= {
			_editDlgs.remove(evt);
		};
		dlg.open();
	}

	void edit(Content evt) {
		if (!hasDialog(evt.type) || !checkOpenDialog(evt.type)) return;
		auto p = evt in _editDlgs;
		if (p) {
			p.active();
			return;
		}
		EventDialog dlg;
		auto parent = evt.parent;
		switch (evt.type) {
		case CType.START_BATTLE: {
			dlg = new AreaSelectDialog!(CType.START_BATTLE, Battle, "summary.battles")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.END: {
			dlg = new ClearEventDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.CHANGE_AREA: {
			dlg = new AreaSelectDialog!(CType.CHANGE_AREA, Area, "summary.areas")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.CHANGE_BG_IMAGE: {
			dlg = new BgImagesDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, refTarget);
			break;
		} case CType.EFFECT: {
			dlg = new EffectDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LINK_START: {
			dlg = new StartSelectDialog!(CType.LINK_START)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LINK_PACKAGE: {
			dlg = new AreaSelectDialog!(CType.LINK_PACKAGE, Package, "summary.packages")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.TALK_MESSAGE: {
			dlg = new MessageDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.TALK_DIALOG: {
			dlg = new SpeakDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.PLAY_BGM: {
			dlg = new BgmDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.PLAY_SOUND: {
			dlg = new SeDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.WAIT: {
			dlg = new WaitEventDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.CALL_START: {
			dlg = new StartSelectDialog!(CType.CALL_START)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.CALL_PACKAGE: {
			dlg = new AreaSelectDialog!(CType.CALL_PACKAGE, Package, "summary.packages")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_FLAG: {
			dlg = new BrFlagDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_MULTI_STEP: {
			dlg = new BrStepNDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_STEP: {
			dlg = new BrStepULDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.BRANCH_SELECT: {
			dlg = new BrMemberDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_ABILITY: {
			dlg = new BrPowerDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_RANDOM: {
			dlg = new BrRandomEventDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_LEVEL: {
			dlg = new BrLevelDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_STATUS: {
			dlg = new BrStateDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_PARTY_NUMBER: {
			dlg = new BrNumEventDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_CAST: {
			dlg = new AreaSelectDialog!(CType.BRANCH_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_ITEM: {
			dlg = new BrItemDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_SKILL: {
			dlg = new BrSkillDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_INFO: {
			dlg = new AreaSelectDialog!(CType.BRANCH_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_BEAST: {
			dlg = new BrBeastDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_MONEY: {
			dlg = new MoneyEventDialog!(CType.BRANCH_MONEY)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_COUPON: {
			dlg = new CouponEventDialog!(CType.BRANCH_COUPON, false)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_COMPLETE_STAMP: {
			dlg = new EndEventDialog!(CType.BRANCH_COMPLETE_STAMP)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.BRANCH_GOSSIP: {
			dlg = new GossipEventDialog!(CType.BRANCH_GOSSIP)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.SET_FLAG: {
			dlg = new FlagSetDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP: {
			dlg = new StepSetDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP_UP: {
			dlg = new StepPlusDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.SET_STEP_DOWN: {
			dlg = new StepMinusDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.REVERSE_FLAG: {
			dlg = new FlagRDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.CHECK_FLAG: {
			dlg = new FlagJudgeDialog(_comm, _prop, _tree.getShell, _summ, parent, evt, _summ.flagDirRoot);
			break;
		} case CType.GET_CAST: {
			dlg = new AreaSelectDialog!(CType.GET_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_ITEM: {
			dlg = new GetItemDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_SKILL: {
			dlg = new GetSkillDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_INFO: {
			dlg = new AreaSelectDialog!(CType.GET_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_BEAST: {
			dlg = new GetBeastDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_MONEY: {
			dlg = new MoneyEventDialog!(CType.GET_MONEY)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_COUPON: {
			dlg = new CouponEventDialog!(CType.GET_COUPON, true)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_COMPLETE_STAMP: {
			dlg = new EndEventDialog!(CType.GET_COMPLETE_STAMP)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.GET_GOSSIP: {
			dlg = new GossipEventDialog!(CType.GET_GOSSIP)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_CAST: {
			dlg = new AreaSelectDialog!(CType.LOSE_CAST, CastCard, "summary.casts")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_ITEM: {
			dlg = new LostItemDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_SKILL: {
			dlg = new LostSkillDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_INFO: {
			dlg = new AreaSelectDialog!(CType.LOSE_INFO, InfoCard, "summary.infos")
				(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_BEAST: {
			dlg = new LostBeastDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_MONEY: {
			dlg = new MoneyEventDialog!(CType.LOSE_MONEY)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_COUPON: {
			dlg = new CouponEventDialog!(CType.LOSE_COUPON, false)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_COMPLETE_STAMP: {
			dlg = new EndEventDialog!(CType.LOSE_COMPLETE_STAMP)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.LOSE_GOSSIP: {
			dlg = new GossipEventDialog!(CType.LOSE_GOSSIP)(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} case CType.REDISPLAY: {
			dlg = new RefreshDialog(_comm, _prop, _tree.getShell, _summ, parent, evt);
			break;
		} default: assert (0);
		}
		auto undo = new UndoContent([evt]);
		dlg.appliedEvent ~= {
			appliedEdit(undo, evt);
			undo = new UndoContent([evt]);
		};
		_editDlgs[evt] = dlg;
		dlg.closeEvent ~= {
			_editDlgs.remove(evt);
		};
		dlg.open();
	}

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
				auto c = cast(Content) itm.getData;
				_comm.delContent.call(c);
				if (_parItm) {
					assert (_parItm.getData);
					assert (itm.getData);
					assert ((cast(Content) _parItm.getData).detail.owner);
					assert (cast(Content) itm.getData);
					(cast(Content) _parItm.getData).remove(c);
				} else {
					_et.remove(c);
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
						_comm.refContent.call(evt);
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
				if (_v._toolWin && !_v._toolWin.isDisposed) {
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
			if (c.type == type) return;
			store(c);
			_comm.delContent.call(c);
			assert (c.canConvert(type), "convert menu item enabled");
			auto oldd = c.detail;
			c.type(type, _prop.parent);
			auto newd = c.detail;
			if (newd.use(CArg.BG_IMAGES) && !oldd.use(CArg.BG_IMAGES)) {
				c.backs = BgImageS.createBgImages(_comm.skin, _prop.var.etc.bgImagesDefault);
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
		auto itm = createToolItem(bar, text, img, &ce.create, SWT.RADIO);
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
			_prop.var.etc.contentsAutoOpen = _autoOpen;
			_prop.var.etc.contentsContinue = _conti;
		}
	}
	class TDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			assert (_toolWin);
			if (_toolWin.isDisposed) return;
			if (_toolWin.getVisible) {
				saveToolWinPos;
			}
		}
	}
	class TCListener : ControlAdapter {
		override void controlMoved(ControlEvent e) {
			assert (_toolWin);
			if (_toolWin.isDisposed) return;
			auto pb = _toolWin.getParent.getBounds;
			auto tb = _toolWin.getBounds;
			_toolWin.setBounds(tb.x + pb.x - _parX, tb.y + pb.y - _parY, tb.width, tb.height);
			_parX = pb.x;
			_parY = pb.y;
		}
	}
	class PSListener : ShellAdapter {
		override void shellActivated(ShellEvent e) {
			assert (_toolWin);
			if (_toolWin.isDisposed) return;
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
			if (_toolWin) {
				saveToolWinPos;
				_toolWin.dispose;
			}
			foreach (dlg; _editDlgs.values) {
				dlg.forceCancel();
			}
		}
	}
	class TSListener : ShellAdapter {
		public override void shellClosed(ShellEvent e) {
			assert (_toolWin);
			if (_toolWin.isDisposed) return;
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
	void drawStartInfo(PaintEvent e) {
		if (!_et) return;
		if (!_prop.var.etc.drawCountOfUseOfStart && !_prop.var.etc.drawContentTreeLine) return;
		auto d = _tree.getDisplay;
		auto ca = _tree.getClientArea;
		auto suc = _et.startUseCounter;
		auto fore = e.gc.getForeground;
		auto back = e.gc.getBackground;
		auto counts = new string[_tree.getItemCount];
		auto ucExtent = e.gc.textExtent(_prop.msgs.startUseCount);
		int maxW = 0;
		int h = e.gc.getFontMetrics.getHeight;
		if (_prop.var.etc.drawCountOfUseOfStart) {
			foreach (i, itm; _tree.getItems) {
				auto c = cast(Content) itm.getData;
				assert (c);
				int count = suc.get(toStartId(c.name));
				if (0 == i) count++;
				counts[i] = .text(count);
				auto extent = e.gc.textExtent(counts[i]);
				maxW = max(maxW, extent.x);
			}
		}
		foreach (i, itm; _tree.getItems) {
			auto b = itm.getBounds;
			if (b.y + b.height <= ca.y) continue;
			if (ca.y + ca.height < b.y) break;
			if (_prop.var.etc.drawContentTreeLine && 0 < i) {
				e.gc.setAlpha = 64;
				e.gc.setBackground = fore;
				scope (exit) {
					e.gc.setAlpha = 255;
					e.gc.setBackground = back;
				}
				e.gc.fillRectangle(0, b.y, ca.width, 1);
			}
			if (_prop.var.etc.drawCountOfUseOfStart) {
				string t = counts[i];
				int tx = ca.width - maxW - 5;
				int ty = b.y + (b.height - h) / 2;
				e.gc.drawString(t, tx, ty);
				e.gc.setAlpha = 128;
				e.gc.drawString(_prop.msgs.startUseCount, tx - ucExtent.x - 5, ty);
				e.gc.setAlpha = 255;
			}
		}
	}
	void drawComment(PaintEvent e) {
		// TODO
	}
	class PaintTree : PaintListener {
		override void paintControl(PaintEvent e) {
			drawStartInfo(e);
			drawComment(e);
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

		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout = zeroGridLayout(1, false);
		if (_prop.var.etc.contentsFloat) {
			_toolWin = new Shell(parent.getShell, SWT.TITLE | SWT.RESIZE | SWT.TOOL);
			_toolWin.setLayout = zeroGridLayout(1);
			_toolWin.setText = prop.msgs.tools;
			_toolWin.addShellListener(new TSListener);
			_toolWin.addMouseListener(new TMListener);
		}
		_autoOpen = _prop.var.etc.contentsAutoOpen;
		_conti = _prop.var.etc.contentsContinue;
		_cbarPar = new Composite(_prop.var.etc.contentsFloat ? _toolWin : _comp, SWT.NONE);
		_cbarPar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		_cbarPar.setLayout = new FillLayout;
		_tree = new Tree(_comp, SWT.SINGLE | SWT.BORDER | SWT.VIRTUAL);
		_tree.setLayoutData = new GridData(GridData.FILL_BOTH);
		_tree.addPaintListener(new PaintTree);
		new TreeEdit(_tree, &editEnd, &createEditor);
		_tree.addDisposeListener(new TRDListener);
		_tree.addMouseListener(new CreateL);
		auto editl = new EditL;
		_tree.addKeyListener(editl);
		_tree.addMouseListener(editl);
		{
			uint retry = 0;
			while (true) {
				Menu popup = null;
				try {
					popup = new Menu(parent.getShell, SWT.POP_UP);
					createMenuItem(popup, _prop.msgs.menuCEdit, _prop.images.menuCEdit, &edit);
					new MenuItem(popup, SWT.SEPARATOR);
					createMenuItem(popup, _prop.msgs.menuUndo, _prop.images.menuUndo, &this.undo);
					createMenuItem(popup, _prop.msgs.menuRedo, _prop.images.menuRedo, &this.redo);
					new MenuItem(popup, SWT.SEPARATOR);
					appendMenuTCPD(_prop, popup, this, true, true, true, true);
					new MenuItem(popup, SWT.SEPARATOR);
					createMenuItem(popup, _prop.msgs.menuToScript, _prop.images.menuToScript, &toScript);
					createMenuItem(popup, _prop.msgs.menuToScriptAll, _prop.images.menuToScriptAll, &toScriptAll);
					new MenuItem(popup, SWT.SEPARATOR);
					createMenuItem(popup, _prop.msgs.menuStartToPackage, _prop.images.menuStartToPackage, &startToPackage);
					void delegate() dlg = null;
					auto convMI = createMenuItem(popup, _prop.msgs.menuConvertContent, _prop.images.menuConvertContent, dlg, SWT.CASCADE);
					_convM = new Menu(_tree.getShell, SWT.DROP_DOWN);
					debug {
						new MenuItem(popup, SWT.SEPARATOR);
						createMenuItem(popup, "debug: Create CWX &Path", null, &createCWXPath);
					}
					convMI.setMenu = _convM;

					_tree.setMenu = popup;
					break;
				} catch (Throwable e) {
					// 環境によってはMenuが異常な状態になり、
					// MenuItemの追加で落ちることがある模様
					debugln(e);
					try {
						if (popup) popup.dispose();
						popup = null;
					} catch {}
					retry++;
					if (retry > 128) {
						debugln("create menu failed (tree view).");
						break;
					}
					debugln("create menu failed (tree view). retry: ", retry);
				}
			}
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
		if (_toolWin.isDisposed) return;
		_prop.var.contentsWin.x = _toolWin.getBounds.x - _toolWin.getParent.getBounds.x;
		_prop.var.contentsWin.y = _toolWin.getBounds.y - _toolWin.getParent.getBounds.y;
	}
	private Composite _cbarPar;
	private Menu _convM;
	private bool _constructTools = false;
	void constructTools() {
		if (_tree.isDisposed || _constructTools) return;
		_constructTools = true;
		auto cbar = createCoolBar!("contents")(_prop, _cbarPar, (CoolBar cbar) {
			if (!_prop.var.etc.contentsFloat) {
				cbar.addMouseListener(new TMListener);
			}
			auto g = new RadioGroup!(ToolItem);
			_radioGroup = g;
			void delegate() dlg = null;
			Menu convMenu(string text, Image img) {
				auto mi = createMenuItem(_convM, text, img, dlg, SWT.CASCADE);
				auto m = new Menu(_tree.getShell, SWT.DROP_DOWN);
				mi.setMenu = m;
				return m;
			}

			auto atm = new ToolBar(cbar, SWT.FLAT);
			atm.addMouseListener(new TMListener);
			_arrowTI = createToolItem(atm, _prop.msgs.evtArrow, _prop.images.evtArrow, &arrow, SWT.RADIO);
			_arrowTI.setSelection = true;
			g.append(_arrowTI);
			createCoolItem(cbar, atm);

			auto mode = new ToolBar(cbar, SWT.FLAT);
			mode.addMouseListener(new TMListener);
			_contiTI = createToolItem(mode, _prop.msgs.evtAddContinue, _prop.images.evtAddContinue, &addContinue, SWT.CHECK);
			_contiTI.setSelection = _conti;
			_autoOpenTI = createToolItem(mode, _prop.msgs.evtAutoOpen, _prop.images.evtAutoOpen, &autoOpen, SWT.CHECK);
			_autoOpenTI.setSelection = _autoOpen;
			createCoolItem(cbar, mode);

			auto e1 = new ToolBar(cbar, SWT.FLAT);
			e1.addMouseListener(new TMListener);
			auto e1c = convMenu(_prop.msgs.menuEvtTerminal, _prop.images.menuEvtTerminal);
			createEI(CType.START, e1, g, _convM);
			createEI(CType.START_BATTLE, e1, g, e1c);
			createEI(CType.END, e1, g, e1c);
			createEI(CType.END_BAD_END, e1, g, e1c);
			createEI(CType.CHANGE_AREA, e1, g, e1c);
			createEI(CType.EFFECT_BREAK, e1, g, e1c);
			createEI(CType.LINK_START, e1, g, e1c);
			createEI(CType.LINK_PACKAGE, e1, g, e1c);
			createCoolItem(cbar, e1);

			auto e2 = new ToolBar(cbar, SWT.FLAT);
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

			auto e3 = new ToolBar(cbar, SWT.FLAT);
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

			auto e4 = new ToolBar(cbar, SWT.FLAT);
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

			auto e5 = new ToolBar(cbar, SWT.FLAT);
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

			auto e6 = new ToolBar(cbar, SWT.FLAT);
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

			auto e7 = new ToolBar(cbar, SWT.FLAT);
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

			auto e8 = new ToolBar(cbar, SWT.FLAT);
			e8.addMouseListener(new TMListener);
			auto e8c = convMenu(_prop.msgs.menuEvtVisual, _prop.images.menuEvtVisual);
			createEI(CType.SHOW_PARTY, e8, g, e8c);
			createEI(CType.HIDE_PARTY, e8, g, e8c);
			createEI(CType.CHANGE_BG_IMAGE, e8, g, e8c);
			createEI(CType.REDISPLAY, e8, g, e8c);
			createCoolItem(cbar, e8, 2);

			cbar.addDisposeListener(new CDListener);
		});
		if (_toolWin) {
			auto dummy = new Composite(_toolWin, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.heightHint = 0;
			dummy.setLayoutData = gd;
			_toolWin.setVisible = false;
			auto pb = _toolWin.getParent.getBounds;
			auto size = _toolWin.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			auto ts = _toolWin.getBounds;
			int tx = _prop.var.contentsWin.x == SWT.DEFAULT ? ts.x : pb.x + _prop.var.contentsWin.x;
			int ty = _prop.var.contentsWin.y == SWT.DEFAULT ? ts.y : pb.y + _prop.var.contentsWin.y;
			intoDisplay(tx, ty, size.x, size.y);
			_parX = pb.x;
			_parY = pb.y;
			_toolWin.setBounds(tx, ty, size.x, size.y);
			_toolWin.addDisposeListener(new TDListener);
			_toolWin.getParent.addControlListener(new TCListener);
			_tree.getShell.addShellListener(new PSListener);
		} else {
			_cbarPar.getParent.layout(true);
		}
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
	void toScript() {
		auto itm = selection;
		if (!itm) return;
		auto c = cast(Content) itm.getData;
		auto script = new CWXScript(_prop.parent, _summ);
		auto text = script.toScript([c], _summ.legacy, "\t");
		text = std.array.replace(text, "\n", std.path.linesep);
		auto cb = new Clipboard(Display.getCurrent);
		scope (exit) cb.dispose;
		cb.setContents([new ArrayWrapperString(text ~ "\n")], [TextTransfer.getInstance]);
	}
	void toScriptAll() {
		if (!_et) return;
		auto script = new CWXScript(_prop.parent, _summ);
		auto text = script.toScript(_et.starts, _summ.legacy, "\t");
		text = std.array.replace(text, "\n", std.path.linesep);
		auto cb = new Clipboard(Display.getCurrent);
		scope (exit) cb.dispose;
		cb.setContents([new ArrayWrapperString(text ~ "\n")], [TextTransfer.getInstance]);
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
			foreach (dlg; _editDlgs.values) {
				dlg.forceCancel();
			}
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
			if (0 < _tree.getItemCount) {
				_tree.setSelection = [_tree.getItem(0)];
			}
			_tree.setRedraw = true;
			refreshStatusLine;
		}
	}
	void treeOpen() {
		treeExpandedAll(_tree);
	}
	void treeClose() {
		foreach (itm; _tree.getItems) {
			itm.setExpanded = false;
		}
	}
	private void editEnd(TreeItem itm, Control c) {
		auto t = cast(Text) c;
		auto evt = (cast(Content) itm.getData);
		if (t) {
			auto text = t.getText;
			if (!text) text = "";
			if (text == evt.name) return;
			store(evt);
			if (evt.type == CType.START) {
				evt.name = createNewName(text, (string name) {
					foreach (s; _et.starts) {
						if (s !is evt && icmp(s.name, name) == 0) {
							return false;
						}
					}
					return true;
				}, true);
			} else {
				evt.name = text;
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
		_comm.refContent.call(evt);
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
			return createBoolEditor!("_prop.msgs.evtChildBrPower(evt.targetS, evt.physical, evt.mental, evt.signedLevel, name)")(data, c);
		} case CType.BRANCH_RANDOM: {
			return createBoolEditor!("_prop.msgs.evtChildBrRandom(evt.percent, name)")(data, c);
		} case CType.BRANCH_LEVEL: {
			return createBoolEditor!("_prop.msgs.evtChildBrLevel(evt.unsignedLevel, evt.average, name)")(data, c);
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
			r = _prop.msgs.evtChildBrPower(parent.targetS, parent.physical, parent.mental, parent.signedLevel, name);
			break;
		} case CType.BRANCH_RANDOM: {
			r = _prop.msgs.evtChildBrRandom(parent.percent, name);
			break;
		} case CType.BRANCH_LEVEL: {
			r = _prop.msgs.evtChildBrLevel(parent.unsignedLevel, parent.average, name);
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
		_comm.refContent.call(e);
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
					int j = mixin(ToIndex);
					_comm.delContent.call(p.next[i]);
					_comm.delContent.call(p.next[j]);
					p.swapContent(i, j);
					_tree.showSelection;
				}
			} else {
				int i = treeSwap(itm);
				int j = mixin(ToIndex);
				if (i >= 0) {
					if (store) this.storeSwap(i, j);
					_comm.delContent.call(_et.starts[i]);
					_comm.delContent.call(_et.starts[j]);
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
			if (_toolWin.isDisposed) return;
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
			if (_toolWin.isDisposed) return;
			_toolWin.setVisible = false;
			_toolWinVisible = false;
		}
	}
	void refreshTreeName() {
		_tree.getItems[0].setText = _et.name;
		refreshStatusLine;
	}

	private void addContents(Content[] cs ...) {
		auto itm = selection;
		if (!itm) return;
		auto owner = cast(Content) itm.getData;
		assert (owner);
		if (!owner.detail.owner) return;
		_tree.setRedraw = false;
		scope (exit) _tree.setRedraw = true;
		store(owner);
		foreach (ct; cs) {
			owner.add(ct);
			_comm.refContent.call(ct);
		}
		createChilds(itm, owner, true);
		_comm.refUseCount.call;
		refreshStatusLine;
	}
	private void addStarts(Content[] cs ...) {
		_tree.setRedraw = false;
		scope (exit) _tree.setRedraw = true;
		auto sel = selection;
		int index;
		if (sel) {
			index = _tree.indexOf(topItem(sel)) + 1;
		} else {
			index = 1;
		}
		auto top = _tree.getTopItem;
		storeInsert(index, cs.length);
		TreeItem sItm = null;
		foreach (i, c; cs) {
			c.name = createNewName(c.name, (string name) {
				foreach (s; _et.starts) {
					if (icmp(s.name, name) == 0) {
						return false;
					}
				}
				return true;
			}, true);
			_et.insert(index + i, c);
			sItm = createTreeItem(_tree, c, c.name, _prop.images.content(c.type), index + i);
			createChilds(sItm, c, true);
			sItm.setExpanded = true;
			_comm.refContent.call(c);
		}
		if (!sItm) return;
		_tree.select = sItm;
		_tree.showSelection;
		_comm.refUseCount.call;
		refreshStatusLine;
	}

	override {
		void cut(SelectionEvent se) {
			auto itm = selection;
			if (itm && itm !is _tree.getItems[0]) {
				copy(se);
				del(se);
			}
		}
		void copy(SelectionEvent se) {
			auto itm = selection;
			if (itm) {
				string xml = (cast(Content) itm.getData).toXML;
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(_prop, cb, xml);
			}
		}
		void paste(SelectionEvent se) {
			if (!_et) return;
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
				try {
					string id;
					auto evt = Content.createFromXML(c, LATEST_VERSION, id);
					if (!evt) return;
					if (evt.type == CType.START) {
						addStarts(evt);
					} else {
						addContents(evt);
					}
					return;
				} catch (Exception e) {
					debugln(e);
				}
			}
			auto script = cast(ArrayWrapperString) cb.getContents(TextTransfer.getInstance);
			if (script) {
				try {
					auto cs = cwx.script.compile(_prop.parent, _summ, script.array.idup);
					if (!cs.length) return;
					if (cs[0].type is CType.START) {
						addStarts(cs);
					} else {
						addContents(cs);
					}
				} catch (CWXScriptException e) {
					auto dlg = new ScriptErrorDialog(_prop, _tree, e);
					dlg.open();
				}
			}
		}
		void del(SelectionEvent se) {
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
		_comm.delContent.call(c);
		if (ownerItm) {
			auto owner = cast(Content) ownerItm.getData;
			if (store) this.store(owner);
			owner.remove(c);
		} else {
			if (store) this.storeDelete(.cCountUntil!("a is b")(_et.starts, c), c);
			_et.remove(c);
		}
		itm.dispose;
	}
	private void __refreshCardImpl(TreeItem evt) {
		foreach (childItm; evt.getItems) {
			auto child = cast(Content) childItm.getData;
			childItm.setText = eventText(cast(Content) evt.getData, child);
			if (child.detail.owner) {
				__refreshCardImpl(childItm);
			}
		}
	}
	private void __refreshCard() {
		if (_tree.isDisposed) return;
		if (_et) {
			foreach (itm; _tree.getItems) {
				__refreshCardImpl(itm);
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
