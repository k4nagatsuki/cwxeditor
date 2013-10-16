/// イベントを編集するためのビュー。
/// 左側にイベントと発火条件を設定するビューを、右側にEventTreeViewを配置する。
module cwx.editor.gui.dwt.eventview;

import cwx.area;
import cwx.event;
import cwx.summary;
import cwx.card;
import cwx.utils;
import cwx.skin;
import cwx.usecounter;
import cwx.path;
import cwx.script;
import cwx.system;
import cwx.menu;
import cwx.types;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.messageutils;
import cwx.editor.gui.dwt.eventtreeview;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.scripterrordialog;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.smalldialogs;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.areaviewutils;
import cwx.editor.gui.dwt.images;

import std.algorithm : max;
import std.string;
import std.exception;
import std.conv;

import org.eclipse.swt.all;

import java.lang.all;

public:

alias ArrayWrapperString KeyCodeObj;
alias Integer RoundObj;

class EventView(A : EventTreeOwner, C, bool UseFire) : Composite, TCPD {
private:
	int _readOnly = 0;
	Commons _comm;
	Props _prop;
	Summary _summ;
	A _area;
	UndoManager _undo;

	SplitPane _sash;
	Tree _cards;
	TreeEdit _edit;
	EventTreeView _etree;

	ToolBar _toolbar;
	CCombo _treeKind;
	ToolItem _fireItm;
	static if (is (A == Area) || is (A == Battle)) {
		CCombo _keyCodeTim;
	}

	TCPD[] _tcpd;
	TreeItem _oldSelP = null;
	TreeItem _selItm = null;

	static if (!is(C:void)) {
		Preview _preview;
		C _previewC = null;
		PileImage _previewI = null;
		void closePreview() { mixin(S_TRACE);
			if (_previewI) { mixin(S_TRACE);
				_preview.close();
				_previewC = null;
				_previewI.dispose();
			}
		}
		void previewTrigger(int x, int y) { mixin(S_TRACE);
			auto itm = _cards.getItem(new Point(x, y));
			if (!itm) { mixin(S_TRACE);
				closePreview();
				return;
			}
			auto c = cast(C)itm.getData();
			if (!c) { mixin(S_TRACE);
				closePreview();
				return;
			}
			if (c is _previewC) { mixin(S_TRACE);
				return;
			}
			closePreview();
			_previewC = c;
			_previewI = createCardImage(c);

			auto b = itm.getBounds();
			auto p = _cards.toDisplay(b.x, b.y + b.height);
			_preview.image(_previewI, p.x, p.y, b.height);
			_preview.show();
		}
		PileImage createCardImage(in C card) { mixin(S_TRACE);
			static if (is(C:MenuCard)) {
				auto path = _comm.skin.findImagePath(card.path, _summ.scenarioPath);
				return createMenuCardImage!PileImage(_prop, _comm.skin, card.name,
					path, 0, 0, 1.0, _prop.var.etc.smoothingCard, card.pcNumber);
			} else static if (is(C:EnemyCard)) {
				auto skin = _comm.skin;
				auto castCard = _summ.cwCast(card.id);
				auto areaView = _comm.areaViewFrom!(A, C, true, is(typeof(_area.backs)))(_area.cwxPath(true), false);
				bool dbgMode = areaView ? areaView.debugMode : _prop.var.etc.viewEnemyCardDebug;
				if (castCard) { mixin(S_TRACE);
					return createCastCardImage!PileImage(_prop, skin, castCard, _summ.scenarioPath,
						0, 0, 1.0, _prop.var.etc.smoothingCard, dbgMode);
				} else { mixin(S_TRACE);
					return createCastCardImage!PileImage(_prop, skin, null, _summ.scenarioPath,
						0, 0, 1.0, _prop.var.etc.smoothingCard, dbgMode);
				}
			} else static assert (0, C);
		}
		class ClosePreview : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				closePreview();
			}
		}
		class PreviewTrigger : MouseTrackAdapter, MouseMoveListener {
			override void mouseExit(MouseEvent e) { mixin(S_TRACE);
				closePreview();
			}
			override void mouseMove(MouseEvent e) { mixin(S_TRACE);
				previewTrigger(e.x, e.y);
			}
		}
	}

	static EventTreeOwner[] etos(A area) { mixin(S_TRACE);
		EventTreeOwner[] r;
		r ~= area;
		static if (is(A : Area) || is(A : Battle)) {
			foreach (c; area.cards) { mixin(S_TRACE);
				r ~= c;
			}
		}
		return r;
	}

	abstract static class EVUndo : Undo {
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
		protected Commons comm;
		protected A area;
		private int[] _selPath, _selPath2;
		private int[] getSelPath(EventView v) { mixin(S_TRACE);
			if (!v) return null;
			auto itm = v.selection;
			if (itm) { mixin(S_TRACE);
				int[] selPath;
				while (itm.getParentItem()) { mixin(S_TRACE);
					selPath = [itm.getParentItem().indexOf(itm)] ~ selPath;
					itm = itm.getParentItem();
				}
				return [v._cards.indexOf(itm)] ~ selPath;
			} else { mixin(S_TRACE);
				return null;
			}
		}
		this (EventView v, Commons comm, A area) { mixin(S_TRACE);
			this.comm = comm;
			this.area = area;
			_selPath = getSelPath(v);
		}
		protected void udb(EventView v) { mixin(S_TRACE);
			if (!v) return;
			.forceFocus(v._cards, false);
			_selPath2 = getSelPath(v);
		}
		protected void uda(EventView v) { mixin(S_TRACE);
			scope (exit) comm.refreshToolBar();
			if (!v) return;
			if (_selPath) { mixin(S_TRACE);
				auto itm = v._cards.getItem(_selPath[0]);
				_selPath = _selPath[1 .. $];
				while (_selPath.length) { mixin(S_TRACE);
					itm = itm.getItem(_selPath[0]);
					_selPath = _selPath[1 .. $];
				}
				auto eti = v.selectionEventTree;
				v._cards.select(itm);
				auto eti2 = v.selectionEventTree;
				if (eti !is eti2) { mixin(S_TRACE);
					if (eti2) { mixin(S_TRACE);
						v.__select(eti2);
					} else if (!eti) { mixin(S_TRACE);
						v._etree.refresh(null);
					}
				}
				_selPath = _selPath2;
			} else { mixin(S_TRACE);
				v._cards.deselectAll();
			}
		}
		protected EventView view() { mixin(S_TRACE);
			return comm.eventViewFrom!(A, C, UseFire)(area.cwxPath(true), false);
		}
	}
	static class UndoTreeData : EVUndo {
		private int _ownerIndex;
		private int _index;
		private static struct Vals {
			bool expand = true;
			string name;
			bool enter;
			bool escape;
			bool lose;
			bool everyRound;
			bool round0;
			FKeyCode[] keyCodes;
			KeyCodeMatchingType keyCodeMatchingType;
			uint[] rounds;
		}
		private Vals _vals;
		this (EventView v, Commons comm, A area, EventTree tree) { mixin(S_TRACE);
			super (v, comm, area);
			auto eto = tree.owner;
			_index = .cCountUntil!("a is b")(tree.owner.trees, tree);
			_ownerIndex = .cCountUntil!("a is b")(etos(area), eto);
			save(v, tree);
		}
		private void save(EventView v, EventTree tree) { mixin(S_TRACE);
			if (v) _vals.expand = getItem(v).getExpanded();
			_vals.name = tree.name;
			_vals.enter = tree.fireEnter;
			_vals.escape = tree.fireEscape;
			_vals.lose = tree.fireLose;
			_vals.everyRound = tree.fireEveryRound;
			_vals.round0 = tree.fireRound0;
			_vals.keyCodes = tree.keyCodes.dup;
			_vals.keyCodeMatchingType = tree.keyCodeMatchingType;
			_vals.rounds = tree.rounds.dup;
		}
		private TreeItem getItem(EventView v) { mixin(S_TRACE);
			enforce(v);
			return v._cards.getItem(_ownerIndex).getItem(_index);
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			auto tree = etos(area)[_ownerIndex].trees[_index];
			auto vals = _vals;
			save(v, tree);
			tree.name = vals.name;
			tree.enter = vals.enter;
			tree.escape = vals.escape;
			tree.lose = vals.lose;
			tree.everyRound = vals.everyRound;
			tree.round0 = vals.round0;
			tree.removeKeyCodesAll();
			foreach (kc; vals.keyCodes) tree.addKeyCode(kc);
			tree.keyCodeMatchingType = vals.keyCodeMatchingType;
			tree.removeRoundsAll();
			foreach (rnd; vals.rounds) tree.addRound(rnd);
			if (v) { mixin(S_TRACE);
				auto itm = getItem(v);
				itm.setExpanded(vals.expand);
				itm.setText(vals.name);
				itm.setImage(v.etImage(tree));
				v._etree.refreshTreeName();
				static if (UseFire) {
					v.refreshFires(itm);
				}
			}
			comm.refEventTree.call(tree);
			comm.refKeyCodes.call();
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {}
	}
	void store(EventTree tree) { mixin(S_TRACE);
		_undo ~= new UndoTreeData(this, _comm, _area, tree);
	}
	static class UndoInsert : EVUndo {
		private int _ownerIndex;
		private int _insertIndex;
		private UndoDelete _delUndo = null;
		private Summary _summ;
		this (EventView v, Commons comm, A area, Summary summ, int ownerIndex, int insertIndex) { mixin(S_TRACE);
			super (v, comm, area);
			_ownerIndex = ownerIndex;
			_insertIndex = insertIndex;
			_summ = summ;
		}
		override void undo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			undoImpl(v);
		}
		void undoImpl(EventView v) { mixin(S_TRACE);
			auto owner = etos(area)[_ownerIndex];
			auto tree = owner.trees[_insertIndex];
			_delUndo = new UndoDelete(v, comm, area, _summ, tree);
			owner.removeEvent(_insertIndex);
			if (v) { mixin(S_TRACE);
				if (v._etree.eventTree && v._etree.eventTree.areaPath == tree.areaPath) { mixin(S_TRACE);
					v._etree.refresh(null);
				}
				auto ownItm = v._cards.getItem(_ownerIndex);
				auto itm = ownItm.getItem(_insertIndex);
				if (v._selItm is itm) v._selItm = null;
				itm.dispose();
			}
			comm.delEventTree.call(tree);
			comm.refUseCount.call();
		}
		override void redo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			_delUndo.undoImpl(v);
			_delUndo = null;
		}
		override void dispose() { mixin(S_TRACE);
			if (_delUndo) _delUndo.dispose();
		}
	}
	void storeI(int ownerIndex, int insertIndex) { mixin(S_TRACE);
		_undo ~= new UndoInsert(this, _comm, _area, _summ, ownerIndex, insertIndex);
	}
	static class UndoDelete : EVUndo {
		private int _ownerIndex;
		private int _treeIndex;
		private EventTree _tree;
		private UndoInsert _istUndo = null;
		private Summary _summ;
		this (EventView v, Commons comm, A area, Summary summ, EventTree tree) { mixin(S_TRACE);
			super (v, comm, area);
			_summ = summ;
			auto owner = tree.owner;
			_ownerIndex = .cCountUntil!("a is b")(etos(area), owner);
			_treeIndex = .cCountUntil!("a is b")(owner.trees, tree);
			_tree = tree.dup;
			_tree.setUseCounter(summ.useCounter.sub);
		}
		override void undo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			undoImpl(v);
		}
		void undoImpl(EventView v) { mixin(S_TRACE);
			_istUndo = new UndoInsert(v, comm, area, _summ, _ownerIndex, _treeIndex);
			if (v) { mixin(S_TRACE);
				auto parItm = v._cards.getItem(_ownerIndex);
				v.appendTree(parItm, _tree, _treeIndex, null, false);
			} else { mixin(S_TRACE);
				auto eto = etos(area)[_ownerIndex];
				appendTreeImpl(comm, eto, _tree, _treeIndex);
			}
		}
		override void redo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			_istUndo.undoImpl(v);
			_istUndo = null;
		}
		override void dispose() { mixin(S_TRACE);
			_tree.removeUseCounter();
			if (_istUndo) _istUndo.dispose();
		}
	}
	void storeD(EventTree tree) { mixin(S_TRACE);
		_undo ~= new UndoDelete(this, _comm, _area, _summ, tree);
	}
	static class UndoSwap : EVUndo {
		private int _ownerIndex;
		private int _swapIndex1;
		private int _swapIndex2;
		this (EventView v, Commons comm, A area, int ownerIndex, int swapIndex1, int swapIndex2) { mixin(S_TRACE);
			super (v, comm, area);
			_ownerIndex = ownerIndex;
			_swapIndex1 = swapIndex1;
			_swapIndex2 = swapIndex2;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (v) { mixin(S_TRACE);
				v.up(v._cards.getItem(_ownerIndex).getItem(max(_swapIndex1, _swapIndex2)), false);
			} else { mixin(S_TRACE);
				staticUDImpl(comm, etos(area)[_ownerIndex], _swapIndex1, _swapIndex2);
			}
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {}
	}
	void store(int ownerIndex, int swapIndex1, int swapIndex2) { mixin(S_TRACE);
		_undo ~= new UndoSwap(this, _comm, _area, ownerIndex, swapIndex1, swapIndex2);
	}

	void forceSel(size_t[] etAreaPath) { mixin(S_TRACE);
		auto eet = _etree.eventTree;
		if (eet && eet.areaPath == etAreaPath) return;
		auto eta = _area.etFromPath(etAreaPath).areaPath;
		foreach (i, itm; _cards.getItems()) { mixin(S_TRACE);
			foreach (j, tItm; itm.getItems()) { mixin(S_TRACE);
				auto cet = cast(EventTree) tItm.getData();
				assert (cet);
				if (cet.areaPath == eta) { mixin(S_TRACE);
					__select(tItm);
					return;
				}
			}
		}
		assert (0);
	}

	void __select(TreeItem itm, bool sel = true) { mixin(S_TRACE);
		if (sel) _cards.setSelection([itm]);
		if (cast(EventTree)itm.getData()) { mixin(S_TRACE);
			_selItm = itm;
			_etree.refresh(cast(EventTree) itm.getData());
		}
		static if (UseFire) {
			if (_fireItm) { mixin(S_TRACE);
				auto parItm = selectionParent;
				if (parItm && (!_oldSelP || _oldSelP != parItm) && _treeKind.getSelectionIndex() == 0) { mixin(S_TRACE);
					auto c = cast(CCombo)_fireItm.getControl();
					c.removeAll();
					string[] vals;
					if (cast(EventTreeOwner)parItm.getData()) { mixin(S_TRACE);
						vals = startDefVals;
					}
					foreach (i, v; vals) { mixin(S_TRACE);
						c.add(v);
						if (i == 0) c.setText(v);
					}
				}
			}
		}
		_comm.refreshToolBar();
	}

	void refreshTopStart() { mixin(S_TRACE);
		assert (_selItm);
		assert (_selItm.getData() is _etree.eventTree);
		_selItm.setText(_etree.eventTree.name);
	}
	class SListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			__select(cast(TreeItem) e.item, false);
		}
	}
	static int before(T)(T parent, int index) { mixin(S_TRACE);
		if (index > 0) { mixin(S_TRACE);
			return index - 1;
		}
		return -1;
	}
	static int after(T)(T parent, int index) { mixin(S_TRACE);
		if (index + 1 < parent.getItemCount()) { mixin(S_TRACE);
			return index + 1;
		}
		return -1;
	}
	@property
	TreeItem selection() { mixin(S_TRACE);
		auto sels = _cards.getSelection();
		if (sels.length > 0) { mixin(S_TRACE);
			return sels[0];
		}
		return null;
	}
	@property
	void selection(int index) { mixin(S_TRACE);
		__select(_cards.getItems()[index]);
	}
	@property
	private TreeItem selectionParent() { mixin(S_TRACE);
		auto itm = selection;
		if (!itm) return null;
		auto data = itm.getData();
		if (cast(EventTreeOwner) data) return itm;
		if (cast(EventTree) data) { mixin(S_TRACE);
			return itm.getParentItem();
		} else { mixin(S_TRACE);
			return itm.getParentItem().getParentItem();
		}
	}
	@property
	private TreeItem selectionEventTree() { mixin(S_TRACE);
		auto itm = selection;
		if (!itm) return null;
		auto data = itm.getData();
		if (cast(EventTreeOwner) data) return null;
		if (cast(EventTree) data) { mixin(S_TRACE);
			return itm;
		} else { mixin(S_TRACE);
			return itm.getParentItem();
		}
	}
	static if (is(A : Area) || is(A : Battle)) {
		@property
		private TreeItem selectionKeyCode() { mixin(S_TRACE);
			auto itm = selection;
			if (!itm) return null;
			auto data = itm.getData();
			return cast(KeyCodeObj) data ? itm : null;
		}
	}
	void createEventTree() { mixin(S_TRACE);
		createEventTree([]);
	}
	void createEventTree(Content[] starts) { mixin(S_TRACE);
		if (_readOnly) return;
		foreach (s; starts) { mixin(S_TRACE);
			if (s.type !is CType.START) return;
		}
		auto parItm = selectionParent;
		if (!parItm) return;
		string treeName;
		static if (UseFire) {
			auto fire = addingFire(parItm.getData());
			if (!fire) return;
			if (fire is ENTER) { mixin(S_TRACE);
				if (cast(A) parItm.getData()) { mixin(S_TRACE);
					static if (is (A == Area)) {
						treeName = _prop.msgs.enterTree;
					} else static if (is (A == Battle)) {
						treeName = _prop.msgs.victoryTree;
					} else static if (is (A == Package)) {
						treeName = _prop.msgs.packageTree;
					} else { mixin(S_TRACE);
						treeName = _prop.msgs.useTree;
					}
				} else { mixin(S_TRACE);
					static if (is (C == MenuCard)) {
						assert (cast(C) parItm.getData());
						treeName = _prop.msgs.selectTree;
					} else static if (is (C == EnemyCard)) {
						assert (cast(C) parItm.getData());
						treeName = _prop.msgs.deadTree;
					}
				}
			} else if (fire is ESCAPE) { mixin(S_TRACE);
				treeName = _prop.msgs.escapeTree;
			} else if (fire is LOSE) { mixin(S_TRACE);
				treeName = _prop.msgs.loseTree;
			} else if (fire is EVERY_ROUND) { mixin(S_TRACE);
				treeName = _prop.msgs.everyRoundTree;
			} else if (fire is ROUND_0) { mixin(S_TRACE);
				treeName = _prop.msgs.round0Tree;
			} else if (cast(KeyCodeObj) fire) { mixin(S_TRACE);
				treeName = .tryFormat(_prop.msgs.keyCodeTree, (cast(KeyCodeObj) fire).array.idup);
			} else { mixin(S_TRACE);
				assert (cast(RoundObj) fire);
				treeName = .tryFormat(_prop.msgs.roundTree, (cast(RoundObj) fire).intValue());
			}
		} else { mixin(S_TRACE);
			Object fire = null;
			static if (is (A == Package)) {
				treeName = _prop.msgs.packageTree;
			} else { mixin(S_TRACE);
				treeName = _prop.msgs.useTree;
			}
		}
		auto owner = cast(EventTreeOwner) parItm.getData();
		EventTree tree;
		if (starts.length) { mixin(S_TRACE);
			tree = new EventTree(starts[0]);
			foreach (s; starts[1 .. $]) { mixin(S_TRACE);
				tree.add(s);
			}
		} else { mixin(S_TRACE);
			tree = new EventTree(treeName);
		}
		appendTree(parItm, tree, owner.trees.length, fire, true);
		if (starts.length) { mixin(S_TRACE);
			_comm.refUseCount.call();
		}
		_comm.refreshToolBar();
	}
	private static void appendTreeImpl(Commons comm, EventTreeOwner eto, EventTree tree, int index) { mixin(S_TRACE);
		eto.insert(index, tree);
		comm.refEventTree.call(tree);
		comm.refUseCount.call();
	}
	void appendTree(TreeItem parItm, EventTree tree, int index, Object defFire, bool store) { mixin(S_TRACE);
		if (_readOnly) return;
		auto eto = cast(EventTreeOwner) parItm.getData();
		if (store) storeI(_cards.indexOf(parItm), eto.trees.length);
		appendTreeImpl(_comm, eto, tree, index);
		auto treeItm = appendTreeItem(parItm, index, defFire);
		__select(treeItm);
	}
	void refreshTrees(TreeItem parItm) { mixin(S_TRACE);
		auto par = cast(EventTreeOwner) parItm.getData();
		parItm.removeAll();
		foreach (index, tree; par.trees) { mixin(S_TRACE);
			appendTreeItem(parItm, index, null);
		}
		parItm.setExpanded(true);
		_comm.refreshToolBar();
	}
	Image etImage(in EventTree tree) { mixin(S_TRACE);
		final switch (tree.keyCodeMatchingType) {
		case KeyCodeMatchingType.Or: return _prop.images.eventTree;
		case KeyCodeMatchingType.And: return _prop.images.eventTreeAnd;
		}
	}
	TreeItem appendTreeItem(TreeItem parItm, int index, Object defFire) { mixin(S_TRACE);
		auto par = cast(EventTreeOwner) parItm.getData();
		auto tree = par.trees[index];
		auto treeItm = createTreeItem(parItm, tree, tree.name, etImage(tree), index);
		static if (UseFire) {
			if (defFire) addFire(treeItm, defFire);
			refreshFires(treeItm);
		}
		return treeItm;
	}
	Control createEditor(TreeItem itm) { mixin(S_TRACE);
		if (_readOnly) return null;
		static if (UseFire) {
			if (cast(EventTree) itm.getData() || cast(KeyCodeObj) itm.getData()) { mixin(S_TRACE);
				return createTextEditor(_comm, _prop, _cards, itm.getText());
			}
		} else { mixin(S_TRACE);
			if (cast(EventTree) itm.getData()) { mixin(S_TRACE);
				return createTextEditor(_comm, _prop, _cards, itm.getText());
			}
		}
		return null;
	}
	void editEnd(TreeItem itm, Control c) { mixin(S_TRACE);
		if (_readOnly) return;
		string text = (cast(Text) c).getText();
		if (!text) text = "";
		auto tree = cast(EventTree) itm.getData();
		if (tree) { mixin(S_TRACE);
			if (text == tree.name) return;
			store(tree);
			text = createNewName(text, (string name) { mixin(S_TRACE);
				if (!tree.starts.length) return true;
				foreach (s; tree.starts[1..$]) { mixin(S_TRACE);
					if (icmp(s.name, name) == 0) { mixin(S_TRACE);
						return false;
					}
				}
				return true;
			}, true);
			itm.setText(text);
			tree.name = text;
			_etree.refreshTreeName();
			_comm.refEventTree.call(tree);
			_comm.refreshToolBar();
			return;
		}
		static if (UseFire) {
			if ("" == text) return;
			auto obj = cast(KeyCodeObj) itm.getData();
			assert (obj);
			auto p = itm.getParentItem();
			foreach (child; p.getItems()) { mixin(S_TRACE);
				if (itm is child) continue;
				auto kco = cast(KeyCodeObj) child.getData();
				if (!kco) continue;
				if (kco.array == text) { mixin(S_TRACE);
					_cards.setSelection([child]);
					return;
				}
			}
			tree = cast(EventTree) p.getData();
			auto kcIndex = p.indexOf(itm) - keyCodesIndex(p);
			auto old = tree.keyCodes[kcIndex];
			if (_prop.sys.convFireKeyCode(old.keyCode, old.kind) == text) return;
			store(tree);
			tree.setKeyCode(kcIndex, _prop.sys.toFKeyCode(text));
			itm.setImage(keyCodeImage(text));
			itm.setText(text);
			obj.array = text.dup;
			_comm.refEventTree.call(tree);
			_comm.refKeyCodes.call();
			_comm.refreshToolBar();
		}
	}
	static if (UseFire) {
		void refreshFires(TreeItem eItm, Object sel = null) { mixin(S_TRACE);
			auto t = cast(EventTree) eItm.getData();
			bool expand = eItm.getExpanded();
			scope (exit) {
				if (!sel) {
					eItm.setExpanded(expand);
				}
				_comm.refreshToolBar();
			}
			eItm.removeAll();
			static if (is (A == Area)) {
				if (t.fireEnter) { mixin(S_TRACE);
					if (cast(A) eItm.getParentItem().getData()) { mixin(S_TRACE);
						createTreeItem(eItm, ENTER, _prop.msgs.startEnter, _prop.images.defStart);
					} else { mixin(S_TRACE);
						assert (cast(C) eItm.getParentItem().getData());
						createTreeItem(eItm, ENTER, _prop.msgs.startSelect, _prop.images.defStart);
					}
				}
				createKeyCodeItem(eItm, t);
			} else static if (is (A == Battle)) {
				if (cast(A) eItm.getParentItem().getData()) { mixin(S_TRACE);
					if (t.fireEnter) { mixin(S_TRACE);
						createTreeItem(eItm, ENTER, _prop.msgs.startVictory, _prop.images.defStart);
					}
					if (t.fireEscape) { mixin(S_TRACE);
						createTreeItem(eItm, ESCAPE, _prop.msgs.startEscape, _prop.images.defStart);
					}
					if (t.fireLose) { mixin(S_TRACE);
						createTreeItem(eItm, LOSE, _prop.msgs.startLose, _prop.images.defStart);
					}
					if (t.fireEveryRound) { mixin(S_TRACE);
						createTreeItem(eItm, EVERY_ROUND, _prop.msgs.startEveryRound, _prop.images.defStart);
					}
					if (t.fireRound0) { mixin(S_TRACE);
						createTreeItem(eItm, ROUND_0, _prop.msgs.startRound0, _prop.images.defStart);
					}
				} else { mixin(S_TRACE);
					assert (cast(C) eItm.getParentItem().getData());
					if (t.fireEnter) { mixin(S_TRACE);
						createTreeItem(eItm, ENTER, _prop.msgs.startDead, _prop.images.defStart);
					}
				}
				createKeyCodeItem(eItm, t);
				if (cast(A) eItm.getParentItem().getData()) { mixin(S_TRACE);
					foreach (r; t.rounds) { mixin(S_TRACE);
						createTreeItem(eItm, new RoundObj(r), .tryFormat(_prop.msgs.startRound, r), _prop.images.round);
					}
				}
			} else static if (is (A == Package)) {
				if (t.fireEnter) { mixin(S_TRACE);
					createTreeItem(eItm, ENTER, _prop.msgs.startPackage, _prop.images.defStart);
				}
			} else { mixin(S_TRACE);
				auto eItm = createTreeItem(aItm, t, t.name, etImage(t));
				if (t.fireEnter) { mixin(S_TRACE);
					createTreeItem(eItm, ENTER, _prop.msgs.startUse, _prop.images.defStart);
				}
			}
			if (sel) { mixin(S_TRACE);
				foreach (itm; eItm.getItems()) { mixin(S_TRACE);
					auto data = itm.getData();
					if (cast(KeyCodeObj) data && cast(KeyCodeObj) sel) { mixin(S_TRACE);
						if ((cast(KeyCodeObj) data).array == (cast(KeyCodeObj) sel).array) { mixin(S_TRACE);
							_cards.setSelection([itm]);
							break;
						}
					} else if (cast(RoundObj) data && cast(RoundObj) sel) { mixin(S_TRACE);
						if ((cast(RoundObj) data).intValue() == (cast(RoundObj) sel).intValue()) { mixin(S_TRACE);
							_cards.setSelection([itm]);
							break;
						}
					} else if (data is sel) { mixin(S_TRACE);
						assert (data is ENTER || data is LOSE || data is ESCAPE || data is EVERY_ROUND || data is ROUND_0);
						_cards.setSelection([itm]);
						break;
					}
				}
				eItm.setExpanded(true);
			}
		}
		Object addingFire(Object areaOrCard) { mixin(S_TRACE);
			if (_readOnly) return null;
			static if (!is (C == void)) {
				Object addKeyCodes() { mixin(S_TRACE);
					auto kc = (cast(CCombo) _fireItm.getControl()).getText();
					final switch (_keyCodeTim.getSelectionIndex()) {
					case 0:
						// 入力値をそのまま使用
						break;
					case 1:
						kc = _prop.sys.convFireKeyCode(kc, FKCKind.Success);
						break;
					case 2:
						kc = _prop.sys.convFireKeyCode(kc, FKCKind.Failure);
						break;
					case 3:
						kc = _prop.sys.convFireKeyCode(kc, FKCKind.HasNot);
						break;
					}
					return kc.length > 0 ? new KeyCodeObj(kc) : null;
				}
				Object addAreaAndEtc() { mixin(S_TRACE);
					switch (_treeKind.getSelectionIndex()) {
					case 0:
						return ENTER;
					case 1:
						return addKeyCodes();
					default:
						return null;
					}
				}
			}
			if (cast(A) areaOrCard) { mixin(S_TRACE);
				static if (is (A == Area)) {
					return addAreaAndEtc();
				} else static if (is (A == Battle)) {
					switch (_treeKind.getSelectionIndex()) {
					case 0:
						switch ((cast(CCombo) _fireItm.getControl()).getSelectionIndex()) {
						case 0:
							return ENTER;
						case 1:
							return ESCAPE;
						case 2:
							return LOSE;
						case 3:
							return EVERY_ROUND;
						case 4:
							return ROUND_0;
						default: assert (0);
						}
					case 1:
						return addKeyCodes();
					case 2:
						int round = (cast(Spinner) _fireItm.getControl()).getSelection();
						return new RoundObj(round);
					default: assert (0);
					}
				} else { mixin(S_TRACE);
					return ENTER;
				}
			} else { mixin(S_TRACE);
				static if (!is (C == void)) {
					assert (cast(C) areaOrCard);
					return addAreaAndEtc();
				}
			}
			return null;
		}
		void createEventFire() { mixin(S_TRACE);
			if (_readOnly) return;
			auto treeItm = selectionEventTree;
			if (!treeItm) return;
			auto tree = cast(EventTree) treeItm.getData();
			auto fire = addingFire(treeItm.getParentItem().getData());
			if (!fire) return;
			store(tree);
			addFire(treeItm, fire);
			refreshFires(treeItm, fire);
			_comm.refreshToolBar();
		}
		void addFire(TreeItem treeItm, Object fire) { mixin(S_TRACE);
			auto tree = cast(EventTree) treeItm.getData();
			if (fire is ENTER) { mixin(S_TRACE);
				tree.enter = true;
			} else if (fire is ESCAPE) { mixin(S_TRACE);
				tree.escape = true;
			} else if (fire is LOSE) { mixin(S_TRACE);
				tree.lose = true;
			} else if (fire is EVERY_ROUND) { mixin(S_TRACE);
				tree.everyRound = true;
			} else if (fire is ROUND_0) { mixin(S_TRACE);
				tree.round0 = true;
			} else if (cast(KeyCodeObj) fire) { mixin(S_TRACE);
				tree.addKeyCode(_prop.sys.toFKeyCode((cast(KeyCodeObj) fire).array.idup));
			} else { mixin(S_TRACE);
				assert (cast(RoundObj) fire);
				tree.addRound((cast(RoundObj) fire).intValue());
			}
			_comm.refEventTree.call(tree);
		}
		static __gshared Object ENTER;
		static __gshared Object ESCAPE;
		static __gshared Object LOSE;
		static __gshared Object EVERY_ROUND;
		static __gshared Object ROUND_0;
		shared static this () { mixin(S_TRACE);
			ENTER = new Object;
			ESCAPE = new Object;
			LOSE = new Object;
			EVERY_ROUND = new Object;
			ROUND_0 = new Object;
		}
		int keyCodesIndex(TreeItem itm) { mixin(S_TRACE);
			assert (cast(EventTree) itm.getData());
			auto o = itm.getParentItem().getData();
			if (cast(A) o) { mixin(S_TRACE);
				auto tree = cast(EventTree) itm.getData();
				static if (is (A == Battle)) {
					int r = 0;
					if (tree.fireEnter) r++;
					if (tree.fireLose) r++;
					if (tree.fireEscape) r++;
					if (tree.fireEveryRound) r++;
					if (tree.fireRound0) r++;
					return r;
				} else { mixin(S_TRACE);
					return (cast(EventTree) itm.getData()).fireEnter ? 1 : 0;
				}
			} else { mixin(S_TRACE);
				static if (!is (C == void)) {
					assert (cast(C) o);
					return (cast(EventTree) itm.getData()).fireEnter ? 1 : 0;
				} else { mixin(S_TRACE);
					assert (0);
				}
			}
		}
		Image keyCodeImage(string keyCode) { mixin(S_TRACE);
			final switch (_prop.sys.fireKeyCodeKind(keyCode)) {
			case FKCKind.Use: return _prop.images.keyCode;
			case FKCKind.Success: return _prop.images.menu(MenuID.KeyCodeTimingSuccess);
			case FKCKind.Failure: return _prop.images.menu(MenuID.KeyCodeTimingFailure);
			case FKCKind.HasNot:  return _prop.images.menu(MenuID.KeyCodeTimingHasNot);
			}
		}
		void createKeyCodeItem(T)(TreeItem parent, T a) { mixin(S_TRACE);
			foreach (keyCode; a.keyCodes) { mixin(S_TRACE);
				string kc = _prop.sys.convFireKeyCode(keyCode.keyCode, keyCode.kind);
				createTreeItem(parent, new KeyCodeObj(kc), kc, keyCodeImage(kc));
			}
		}
	}
	void replText() { mixin(S_TRACE);
		if (_readOnly) return;
		foreach (itm; _cards.getItems()) { mixin(S_TRACE);
			auto data = itm.getData();
			if (cast(A) data) { mixin(S_TRACE);
				itm.setText((cast(A) data).name);
			}
			static if (!is (C == void)) {
				if (cast(C) data) { mixin(S_TRACE);
					static if (is (C == MenuCard)) {
						itm.setText((cast(C) data).name);
					} else static if (is (C == EnemyCard)) {
						auto castCard = _summ.cwCast((cast(C) data).id);
						itm.setText(castCard ? castCard.name : "");
					} else { mixin(S_TRACE);
						static assert (0);
					}
				}
			}
			foreach (itm2; itm.getItems()) { mixin(S_TRACE);
				auto et = cast(EventTree) itm2.getData();
				bool chg = false;
				if (itm2.getText() != et.name) { mixin(S_TRACE);
					itm2.setText(et.name);
					chg = true;
				}
				static if (UseFire && (is (A == Area) || is (A == Battle))) {
					int startKC = -1;
					foreach (i, itm3; itm2.getItems()) { mixin(S_TRACE);
						auto kc = cast(KeyCodeObj) itm3.getData();
						if (kc && startKC <= 0) startKC = i;
						if (startKC >= 0 && itm3.getText() != _prop.sys.convFireKeyCode(et.keyCodes[i - startKC])) { mixin(S_TRACE);
							itm3.setText(_prop.sys.convFireKeyCode(et.keyCodes[i - startKC]));
							chg = true;
						}
					}
				}
				if (chg) { mixin(S_TRACE);
					_comm.refEventTree.call(et);
					_comm.refKeyCodes.call();
				}
			}
		}
	}
	static if (UseFire) {
		void addManyRounds() { mixin(S_TRACE);
			if (_readOnly) return;
			auto etItm = selectionEventTree;
			if (!etItm) return;
			auto parItm = selectionParent;
			if (!parItm || !(cast(Battle) parItm.getData())) return;
			auto dlg = new ManyRoundsDialog(_prop, _cards.getShell());
			if (dlg.open()) { mixin(S_TRACE);
				auto et = cast(EventTree) etItm.getData();
				store(et);
				assert (et);
				et.addRounds(dlg.rounds);
				refreshFires(etItm);
				etItm.setExpanded(true);
				_comm.refEventTree.call(et);
				_comm.refreshToolBar();
			}
		}
	}
	static if (is(A : Area) || is(A : Battle)) {
		void keyCodeTimImpl(FKCKind kind) { mixin(S_TRACE);
			if (_readOnly) return;
			auto itm = selection;
			if (!itm) return;
			auto kc = cast(KeyCodeObj) itm.getData();
			if (!kc) return;
			auto old = _prop.sys.toFKeyCode(kc.array.idup);
			string keyCode = _prop.sys.convFireKeyCode(old.keyCode, kind);
			kc.array = keyCode.dup;
			auto etItm = selectionEventTree;
			assert (etItm);
			auto et = cast(EventTree) etItm.getData();
			assert (et);
			store(et);
			int i = cCountUntil(et.keyCodes, old);
			assert (-1 != i);
			et.setKeyCode(i, _prop.sys.toFKeyCode(keyCode));
			itm.setText(keyCode);
			itm.setImage(keyCodeImage(keyCode));
			_comm.refKeyCodes.call();
			_comm.refreshToolBar();
		}
		void keyCodeTimUse() { mixin(S_TRACE);
			keyCodeTimImpl(FKCKind.Use);
		}
		void keyCodeTimSuccess() { mixin(S_TRACE);
			keyCodeTimImpl(FKCKind.Success);
		}
		void keyCodeTimFailure() { mixin(S_TRACE);
			keyCodeTimImpl(FKCKind.Failure);
		}
		void keyCodeTimHasNot() { mixin(S_TRACE);
			keyCodeTimImpl(FKCKind.HasNot);
		}
	}
	bool canConvKeyCode(FKCKind Kind)() { mixin(S_TRACE);
		if (_readOnly) return false;
		auto itm = selectionKeyCode;
		if (!itm) return false;
		auto keyCode = (cast(KeyCodeObj) itm.getData()).array.idup;
		if (Kind is _prop.sys.fireKeyCodeKind(keyCode)) { mixin(S_TRACE);
			return false;
		}
		auto parItm = itm.getParentItem();
		auto conv = _prop.sys.convFireKeyCode(keyCode, Kind);
		foreach (child; parItm.getItems()) { mixin(S_TRACE);
			if (child is itm) continue;
			auto kco = cast(KeyCodeObj) child.getData();
			if (!kco) continue;
			if (conv == kco.array) { mixin(S_TRACE);
				return false;
			}
		}
		return true;
	}
	void setKeyCodeCond(KeyCodeMatchingType Type)() { mixin(S_TRACE);
		if (_readOnly) return;
		auto eItm = selectionEventTree;
		if (!eItm) return;
		auto et = cast(EventTree) eItm.getData();
		assert (et !is null);
		store(et);
		et.keyCodeMatchingType = Type;
		eItm.setImage(etImage(et));
	}
	bool canSetKeyCodeCond(KeyCodeMatchingType Type)() { mixin(S_TRACE);
		if (_readOnly) return false;
		auto eItm = selectionEventTree;
		if (!eItm) return false;
		auto et = cast(EventTree) eItm.getData();
		assert (et !is null);
		return et.keyCodeMatchingType !is Type;
	}

	void refShowToolBar() { mixin(S_TRACE);
		if (!_comm.singleWindowMode(_prop)) return;
		auto gl = windowGridLayout(1, true);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		if (!_prop.var.etc.showEventToolBar) { mixin(S_TRACE);
			gl.verticalSpacing = 0;
			gd.heightHint = 0;
		}
		setLayout(gl);
		_toolbar.setVisible(_prop.var.etc.showEventToolBar);
		_toolbar.setLayoutData(gd);
		layout();
	}
public:
	this (Commons comm, Props prop, Summary summ, A area, Composite parent, UndoManager undo, bool readOnly) { mixin(S_TRACE);
		super (parent, SWT.NONE);
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_area = area;
		_undo = undo;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;

		_toolbar = new ToolBar(this, SWT.FLAT);
		_comm.put(_toolbar);

		_sash = new SplitPane(this, SWT.HORIZONTAL);
		_comm.refShowToolBar.add(&refShowToolBar);
		if (!_readOnly) { mixin(S_TRACE);
			_comm.replText.add(&replText);
			_comm.replID.add(&replText);
			static if (!is(C == void)) {
				_comm.addMenuCard.add(&addCard);
				_comm.refMenuCard.add(&refCard);
				_comm.delMenuCard.add(&delCard);
				_comm.upMenuCard.add(&upCard);
				_comm.downMenuCard.add(&downCard);
			}
			static if (is (A == Area)) {
				_comm.refArea.add(&refreshTitleA);
			} else static if (is (A == Battle)) {
				_comm.refBattle.add(&refreshTitleA);
			} else static if (is (A == Package)) {
				_comm.refPackage.add(&refreshTitleA);
			} else static if (is (A == SkillCard)) {
				_comm.refSkill.add(&refreshTitleA);
			} else static if (is (A == ItemCard)) {
				_comm.refItem.add(&refreshTitleA);
			} else static if (is (A == BeastCard)) {
				_comm.refBeast.add(&refreshTitleA);
			} else static assert (0);
		}
		_sash.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				static if (!is(C:void)) {
					closePreview();
					_preview.dispose();
				}

				int[] ws = _sash.getWeights();
				static if (is (A == Area)) {
					_prop.var.areaWin.eventSashL = ws[0];
					_prop.var.areaWin.eventSashR = ws[1];
				} else static if (is (A == Battle)) {
					_prop.var.battleWin.eventSashL = ws[0];
					_prop.var.battleWin.eventSashR = ws[1];
				} else static if (is (A == Package)) {
					_prop.var.packageWin.eventSashL = ws[0];
					_prop.var.packageWin.eventSashR = ws[1];
				} else static if (is (A : EffectCard)) {
					_prop.var.cardEventWin.eventSashL = ws[0];
					_prop.var.cardEventWin.eventSashR = ws[1];
				} else { mixin(S_TRACE);
					static assert (0);
				}
				_comm.refShowToolBar.remove(&refShowToolBar);
				if (!_readOnly) { mixin(S_TRACE);
					_comm.replText.remove(&replText);
					_comm.replID.remove(&replText);
					static if (!is(C == void)) {
						_comm.addMenuCard.remove(&addCard);
						_comm.refMenuCard.remove(&refCard);
						_comm.delMenuCard.remove(&delCard);
						_comm.upMenuCard.remove(&upCard);
						_comm.downMenuCard.remove(&downCard);
					}
					static if (is (A == Area)) {
						_comm.refArea.remove(&refreshTitleA);
					} else static if (is (A == Battle)) {
						_comm.refBattle.remove(&refreshTitleA);
					} else static if (is (A == Package)) {
						_comm.refPackage.remove(&refreshTitleA);
					} else static if (is (A == SkillCard)) {
						_comm.refSkill.remove(&refreshTitleA);
					} else static if (is (A == ItemCard)) {
						_comm.refItem.remove(&refreshTitleA);
					} else static if (is (A == BeastCard)) {
						_comm.refBeast.remove(&refreshTitleA);
					} else static assert (0);
				}
			}
		});
		_sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		{ mixin(S_TRACE);
			_cards = new Tree(_sash, SWT.SINGLE | SWT.BORDER);
			initTree(_comm, _cards, false);
			_cards.addSelectionListener(new SListener);

			auto shell = _cards.getShell();
			auto menu = new Menu(shell, SWT.POP_UP);
			if (!_readOnly) { mixin (S_TRACE);
				createMenuItem(_comm, menu, MenuID.Undo, &this.undo, () => _undo.canUndo && !_readOnly);
				createMenuItem(_comm, menu, MenuID.Redo, &this.redo, () => _undo.canRedo && !_readOnly);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, this, true, true, true, true, true);
				static if (is(A : Area) || is(A : Battle)) {
					new MenuItem(menu, SWT.SEPARATOR);
					void delegate() dlg = null;
					auto cascade = createMenuItem(_comm, menu, MenuID.KeyCodeTiming, dlg, () => !_readOnly && selectionKeyCode !is null, SWT.CASCADE);
					auto sub = new Menu(parent.getShell(), SWT.DROP_DOWN);
					cascade.setMenu(sub);
					createMenuItem(_comm, sub, MenuID.KeyCodeTimingUse, &keyCodeTimUse, &canConvKeyCode!(FKCKind.Use));
					createMenuItem(_comm, sub, MenuID.KeyCodeTimingSuccess, &keyCodeTimSuccess, &canConvKeyCode!(FKCKind.Success));
					createMenuItem(_comm, sub, MenuID.KeyCodeTimingFailure, &keyCodeTimFailure, &canConvKeyCode!(FKCKind.Failure));
					createMenuItem(_comm, sub, MenuID.KeyCodeTimingHasNot, &keyCodeTimHasNot, &canConvKeyCode!(FKCKind.HasNot));

					auto cascade2 = createMenuItem(_comm, menu, MenuID.KeyCodeCond, dlg, () => !_readOnly && selectionEventTree !is null, SWT.CASCADE);
					auto sub2 = new Menu(parent.getShell(), SWT.DROP_DOWN);
					cascade2.setMenu(sub2);
					createMenuItem(_comm, sub2, MenuID.KeyCodeCondOr, &setKeyCodeCond!(KeyCodeMatchingType.Or), &canSetKeyCodeCond!(KeyCodeMatchingType.Or));
					createMenuItem(_comm, sub2, MenuID.KeyCodeCondAnd, &setKeyCodeCond!(KeyCodeMatchingType.And), &canSetKeyCodeCond!(KeyCodeMatchingType.And));
				}
				new MenuItem(menu, SWT.SEPARATOR);
			} else { mixin (S_TRACE);
				appendMenuTCPD(_comm, menu, this, false, true, false, false, false);
				new MenuItem(menu, SWT.SEPARATOR);
			}
			createMenuItem(_comm, menu, MenuID.ToScript, &toScript, &canToScript);
			createMenuItem(_comm, menu, MenuID.ToScriptAll, &toScriptAll, &canToScriptAll);
			static if (is (A == Battle)) {
				if (!_readOnly) { mixin (S_TRACE);
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.AddRangeOfRound, &addManyRounds, { mixin(S_TRACE);
						if (_readOnly) return false;
						auto etItm = selectionEventTree;
						if (!etItm) return false;
						return (cast(EventTree) etItm.getData()).owner is _area;
					});
				}
			}
			_cards.setMenu(menu);

			static if (!is(C:void)) {
				_preview = new Preview(_prop, _cards.getShell());
				auto closePreview = new ClosePreview;
				_cards.getVerticalBar().addSelectionListener(closePreview);
				_cards.getHorizontalBar().addSelectionListener(closePreview);
				auto prevTrig = new PreviewTrigger;
				_cards.addMouseTrackListener(prevTrig);
				_cards.addMouseMoveListener(prevTrig);
			}
		}
		{ mixin(S_TRACE);
			_etree = new EventTreeView(comm, prop, summ, _sash, _undo, &forceSel, &refreshTopStart, _toolbar, _readOnly != SWT.NONE);
			if (!_readOnly) { mixin(S_TRACE);
				auto _edit = new TreeEdit(_comm, _cards, &editEnd, &createEditor);
			}
			// 遅延実行
			auto initTools = new class PaintListener {
				override void paintControl(PaintEvent e) { mixin(S_TRACE);
					_cards.removePaintListener(this);
					_toolbar.setRedraw(false);
					scope (exit) _toolbar.setRedraw(true);
					setupToolBar();
				}
			};
			_cards.addPaintListener(initTools);
		}
		static if (is (A == Area)) {
			_sash.setWeights([_prop.var.areaWin.eventSashL, _prop.var.areaWin.eventSashR]);
		} else static if (is (A == Battle)) {
			_sash.setWeights([_prop.var.battleWin.eventSashL, _prop.var.battleWin.eventSashR]);
		} else static if (is (A == Package)) {
			_sash.setWeights([_prop.var.packageWin.eventSashL, _prop.var.packageWin.eventSashR]);
		} else static if (is (A : EffectCard)) {
			_sash.setWeights([_prop.var.cardEventWin.eventSashL, _prop.var.cardEventWin.eventSashR]);
		} else { mixin(S_TRACE);
			static assert (0);
		}
		refShowToolBar();

		auto track = new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				if (_prop.var.etc.contentsAutoHide || _prop.var.etc.contentsFloat) {
					auto c = cast(Control)e.widget;
					if (c && .isDescendant(this.outer, c)) {
						_etree.openToolWindow(true);
					}
				}
			}
		};
		auto d = getDisplay();
		d.addFilter(SWT.MouseEnter, track);
		.listener(this, SWT.Dispose, {
			d.removeFilter(SWT.MouseEnter, track);
		});
	}
	@property
	EventTreeView eventTreeView() { mixin(S_TRACE);
		return _etree;
	}

	/// エリアの名称表示を更新する。
	void refreshTitle() { mixin(S_TRACE);
		initial();
		_cards.getItems()[0].setText(_area.name);
	}
	private void refreshTitleA(A area) { mixin(S_TRACE);
		initial();
		if (area is _area) { mixin(S_TRACE);
			_cards.getItems()[0].setText(_area.name);
		}
	}
	static if (!is (C == void)) {
		private string cardName(C c) { mixin(S_TRACE);
			static if (is (C == MenuCard)) {
				return c.name;
			} else { mixin(S_TRACE);
				static assert (is (C == EnemyCard));
				auto castCard = _summ.cwCast(c.id);
				return castCard ? castCard.name : "";
			}
		}
		private void addCard(string cwxPath) { mixin(S_TRACE);
			if (!cpeq(_area.cwxPath(true), cpparent(cwxPath))) return;
			size_t i = cpindex(cpbottom(cwxPath));
			appendCard(i, _area.cards[i]);
		}
		private void refCard(string cwxPath) { mixin(S_TRACE);
			if (!cpeq(_area.cwxPath(true), cpparent(cwxPath))) return;
			size_t i = cpindex(cpbottom(cwxPath));
			renameCard(i);
		}
		private void delCard(string cwxPath) { mixin(S_TRACE);
			if (!cpeq(_area.cwxPath(true), cpparent(cwxPath))) return;
			size_t i = cpindex(cpbottom(cwxPath));
			removeCard(i);
		}
		private void upCard(string cwxPath, int[] indices, int count) { mixin(S_TRACE);
			if (!cpeq(_area.cwxPath(true), cwxPath)) return;
			upCard(indices, count);
		}
		private void downCard(string cwxPath, int[] indices, int count) { mixin(S_TRACE);
			if (!cpeq(_area.cwxPath(true), cwxPath)) return;
			downCard(indices, count);
		}
		private void appendCard(int index, C c) { mixin(S_TRACE);
			initial();
			Image imgCard;
			static if (is (C == MenuCard)) {
				imgCard = _prop.images.cards;
			} else static if (is (C == EnemyCard)) {
				imgCard = _prop.images.cards;
			}
			auto itm = createTreeItem(_cards, c, cardName(c), imgCard, index + 1);
			refreshTrees(itm);
		}
		private void removeCard(int index) { mixin(S_TRACE);
			initial();
			if (_selItm && !_selItm.isDisposed()
					&& _selItm.getParentItem() is _cards.getItems()[index + 1]) { mixin(S_TRACE);
				_etree.refresh(null);
				_selItm = null;
			}
			_cards.getItems()[index + 1].dispose();
		}
		private void renameCard(int index) { mixin(S_TRACE);
			initial();
			auto itm = _cards.getItems()[index + 1];
			itm.setText(cardName(cast(C) itm.getData()));
		}
		private void __udCard(int[] indices, int function(TreeItem) ud, int udVal, int count) { mixin(S_TRACE);
			foreach (j; 0 .. count) { mixin(S_TRACE);
				foreach (i; indices) { mixin(S_TRACE);
					i += udVal * j;
					if (_selItm && _selItm.getParentItem() is _cards.getItems()[i + 1]) { mixin(S_TRACE);
						int s = _selItm.getParentItem().indexOf(_selItm);
						int newI = ud(_cards.getItems()[i + 1]) + udVal;
						__select(_cards.getItems()[newI].getItems()[s]);
					} else { mixin(S_TRACE);
						ud(_cards.getItems()[i + 1]);
					}
				}
			}
		}
		private void upCard(int[] indices, int count) { mixin(S_TRACE);
			initial();
			__udCard(indices, &treeItemUp, -1, count);
		}
		private void downCard(int[] indices, int count) { mixin(S_TRACE);
			initial();
			__udCard(indices, &treeItemDown, 1, count);
		}
	}
	private bool _initialed = false;
	bool initial() { mixin(S_TRACE);
		if (!_initialed) { mixin(S_TRACE);
			refresh();
			return true;
		}
		return false;
	}
	void refresh() { mixin(S_TRACE);
		_initialed = true;
		_cards.removeAll();
		{ mixin(S_TRACE);
			Image imgArea;
			static if (is (A == Area)) {
				imgArea = _prop.images.area;
			} else static if (is (A == Battle)) {
				imgArea = _prop.images.battle;
			} else static if (is (A == Package)) {
				imgArea = _prop.images.packages;
			} else static if (is (A == SkillCard)) {
				imgArea = _prop.images.skill;
			} else static if (is (A == ItemCard)) {
				imgArea = _prop.images.item;
			} else static if (is (A == BeastCard)) {
				imgArea = _prop.images.beast;
			} else { mixin(S_TRACE);
				static assert (0);
			}
			auto aItm = createTreeItem(_cards, _area, _area.name, imgArea);
			foreach (i, t; _area.trees) { mixin(S_TRACE);
				auto eItm = createTreeItem(aItm, t, t.name, etImage(t));
				static if (UseFire) {
					refreshFires(eItm);
				}
				if (i == 0) { mixin(S_TRACE);
					__select(eItm);
				}
			}
			if (_area.trees.length == 0) { mixin(S_TRACE);
				__select(aItm);
			}
			aItm.setExpanded(true);
		}
		static if (!is (C == void)) {
			foreach (c; _area.cards) { mixin(S_TRACE);
				Image imgCard;
				static if (is (C == MenuCard)) {
					imgCard = _prop.images.cards;
				} else static if (is (C == EnemyCard)) {
					imgCard = _prop.images.cards;
				}
				auto cItm = createTreeItem(_cards, c, cardName(c), imgCard);
				foreach (t; c.trees) { mixin(S_TRACE);
					auto eItm = createTreeItem(cItm, t, t.name, etImage(t));
					static if (UseFire) {
						refreshFires(eItm);
					}
				}
				cItm.setExpanded(true);
			}
		}
		_comm.refreshToolBar();
	}
	private bool canUdImpl(string BeforeAfter, string CanSwapKeyCode)(TreeItem itm) { mixin(S_TRACE);
		if (_readOnly) return false;
		if (itm && itm.getParentItem()) { mixin(S_TRACE);
			auto data = itm.getData();
			auto parent = itm.getParentItem();
			int from = parent.indexOf(itm);
			int to = mixin (BeforeAfter);
			if (to >= 0) { mixin(S_TRACE);
				if (cast(EventTree) data) { mixin(S_TRACE);
					return true;
				} else { mixin(S_TRACE);
					static if (UseFire) {
						if (cast(KeyCodeObj) data) { mixin(S_TRACE);
							// キーコード
							auto tree = cast(EventTree) parent.getData();
							int keyCodeLen = tree.keyCodes.length;
							from -= keyCodesIndex(parent);
							to -= keyCodesIndex(parent);
							return mixin (CanSwapKeyCode);
						}
					}
				}
			}
		}
		return false;
	}
	private void udImpl(string BeforeAfter, string CanSwapKeyCode)
			(TreeItem itm, int function(TreeItem) treeSwap, bool store) { mixin(S_TRACE);
		if (_readOnly) return;
		if (itm && itm.getParentItem()) { mixin(S_TRACE);
			auto data = itm.getData();
			auto parent = itm.getParentItem();
			int from = parent.indexOf(itm);
			int to = mixin (BeforeAfter);
			if (to >= 0) { mixin(S_TRACE);
				if (cast(EventTree) data) { mixin(S_TRACE);
					_cards.setRedraw(false);
					scope (exit) _cards.setRedraw(true);
					if (store) this.store(_cards.indexOf(parent), from, to);
					// イベントツリー
					auto eto = (cast(EventTreeOwner) parent.getData());
					eto.swapEventTree(from, to);
					treeSwap(itm);
					_selItm = selection;
					_cards.showSelection();
					_comm.refEventTree.call(eto.trees[from]);
					_comm.refEventTree.call(eto.trees[to]);
				} else { mixin(S_TRACE);
					static if (UseFire) {
						if (cast(KeyCodeObj) data) { mixin(S_TRACE);
							_cards.setRedraw(false);
							scope (exit) _cards.setRedraw(true);
							// キーコード
							auto tree = cast(EventTree) parent.getData();
							if (store) this.store(tree);
							int keyCodeLen = tree.keyCodes.length;
							from -= keyCodesIndex(parent);
							to -= keyCodesIndex(parent);
							if (mixin (CanSwapKeyCode)) { mixin(S_TRACE);
								tree.swapKeyCode(from, to);
								treeSwap(itm);
								_cards.showSelection();
							}
							_comm.refEventTree.call(tree);
						}
					}
				}
			}
		}
	}
	private static void staticUDImpl(Commons comm, EventTreeOwner eto, int from, int to) { mixin(S_TRACE);
		eto.swapEventTree(from, to);
		comm.refEventTree.call(eto.trees[from]);
		comm.refEventTree.call(eto.trees[to]);
	}
	@property
	bool canUp() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (_etree.isFocusControl()) { mixin(S_TRACE);
			return _etree.canUp();
		} else if (_cards.isFocusControl()) { mixin(S_TRACE);
			return canUdImpl!("before(parent, from)", "to >= 0")(selection);
		}
		return false;
	}
	@property
	bool canDown() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (_etree.isFocusControl()) { mixin(S_TRACE);
			return _etree.canDown();
		} else if (_cards.isFocusControl()) { mixin(S_TRACE);
			return canUdImpl!("after(parent, from)", "to < keyCodeLen")(selection);
		}
		return false;
	}
	void up() { mixin(S_TRACE);
		initial();
		up(selection, true);
	}
	private void up(TreeItem itm, bool store) { mixin(S_TRACE);
		if (_readOnly) return;
		if (_etree.isFocusControl()) { mixin(S_TRACE);
			_etree.up();
		} else if (_cards.isFocusControl()) { mixin(S_TRACE);
			udImpl!("before(parent, from)", "to >= 0")(itm, &treeItemUp, store);
			_comm.refreshToolBar();
		}
	}
	void down() { mixin(S_TRACE);
		initial();
		down(selection, true);
	}
	private void down(TreeItem itm, bool store) { mixin(S_TRACE);
		if (_readOnly) return;
		if (_etree.isFocusControl()) { mixin(S_TRACE);
			_etree.down();
		} else if (_cards.isFocusControl()) { mixin(S_TRACE);
			udImpl!("after(parent, from)", "to < keyCodeLen")(itm, &treeItemDown, store);
			_comm.refreshToolBar();
		}
	}

	static if (is(A : Area) || is(A : Battle)) {
		private void openScene() { mixin(S_TRACE);
			_comm.openAreaScene(_prop, _summ, _area, true);
		}
	}

	private void setupToolBar() { mixin(S_TRACE);
		auto bar = _toolbar;
		static if (is(A : Area)) {
			if (cast(AreaEventWindow) tlpData(this).tlp) { mixin(S_TRACE);
				createToolItem(_comm, bar, MenuID.EditScene, &openScene, null);
				new ToolItem(bar, SWT.SEPARATOR);
			}
		} else static if (is(A : Battle)) {
			if (cast(BattleEventWindow) tlpData(this).tlp) { mixin(S_TRACE);
				auto itm = createToolItem(_comm, bar, MenuID.EditScene, &openScene, null);
				itm.setImage(_prop.images.editSceneBattle);
				new ToolItem(bar, SWT.SEPARATOR);
			}
		}
		if (!_readOnly && !_comm.singleWindowMode(_prop)) { mixin(S_TRACE);
			createToolItem(_comm, bar, MenuID.Undo, &undo, () => !_readOnly && _undo.canUndo);
			createToolItem(_comm, bar, MenuID.Redo, &redo, () => !_readOnly && _undo.canRedo);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.Up, &up, &canUp);
			createToolItem(_comm, bar, MenuID.Down, &down, &canDown);
			new ToolItem(bar, SWT.SEPARATOR);
		}
		if (!_readOnly) { mixin(S_TRACE);
			auto treeKindItm = new ToolItem(bar, SWT.SEPARATOR);
			_treeKind = new CCombo(bar, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			_treeKind.setEnabled(!_readOnly);
			createTextMenu!CCombo(_comm, _prop, _treeKind, null);
			_treeKind.add(_prop.msgs.eventTreeKindSystem);
			_treeKind.setText(_prop.msgs.eventTreeKindSystem);
			static if (is (A == Area) || is (A == Battle)) {
				_treeKind.add(_prop.msgs.eventTreeKindKeyCode);
			}
			static if (is (A == Battle)) {
				_treeKind.add(_prop.msgs.eventTreeKindRound);
			}
			treeKindItm.setControl(_treeKind);
			treeKindItm.setWidth(_treeKind.computeSize(SWT.DEFAULT, SWT.DEFAULT).x);
			_treeKind.addSelectionListener(new KSListener);
			new ToolItem(bar, SWT.SEPARATOR);
		}
		if (!_readOnly) { mixin(S_TRACE);
			_fireItm = new ToolItem(bar, SWT.SEPARATOR);
			_fireItm.setWidth(_prop.var.etc.firesWidth);
			createCombo(true, areaDefVals);
			static if (is (A == Area) || is (A == Battle)) {
				new ToolItem(bar, SWT.SEPARATOR);
				{ mixin(S_TRACE);
					auto keyCodeTimItm = new ToolItem(bar, SWT.SEPARATOR);
					_keyCodeTim = new CCombo(bar, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
					createTextMenu!CCombo(_comm, _prop, _keyCodeTim, null);
					_keyCodeTim.setEnabled(false);
					_keyCodeTim.add(_prop.msgs.keyCodeTimingUse);
					_keyCodeTim.add(_prop.msgs.keyCodeTimingSuccess);
					_keyCodeTim.add(_prop.msgs.keyCodeTimingFailure);
					_keyCodeTim.add(_prop.msgs.keyCodeTimingHasNot);
					_keyCodeTim.select(0);
					keyCodeTimItm.setControl(_keyCodeTim);
					keyCodeTimItm.setWidth(_keyCodeTim.computeSize(SWT.DEFAULT, SWT.DEFAULT).x);
				}
			}
			new ToolItem(bar, SWT.SEPARATOR);
		}
		if (!_readOnly) { mixin(S_TRACE);
			createToolItem2(_comm, bar, _prop.msgs.newEvent, _prop.images.newEvent, &createEventTree, { mixin(S_TRACE);
				if (_readOnly) return false;
				auto par = selectionParent;
				if (!par) return false;
				static if (is(A:Battle)) {
					auto eto = cast(EventTreeOwner) par.getData();
					assert (eto !is null);
					if (cast(C) eto && 2 == _treeKind.getSelectionIndex()) { mixin(S_TRACE);
						// エネミーカード選択中、かつラウンド条件選択中
						return false;
					}
				}
				return true;
			});
			static if (UseFire) {
				createToolItem2(_comm, bar, _prop.msgs.newIgnition, _prop.images.newIgnition, &createEventFire, { mixin(S_TRACE);
					if (_readOnly) return false;
					if (selectionEventTree is null) return false;
					static if (is(A:Battle)) {
						auto par = selectionParent;
						assert (par !is null);
						auto eto = cast(EventTreeOwner) par.getData();
						assert (eto !is null);
						if (cast(C) eto && 2 == _treeKind.getSelectionIndex()) { mixin(S_TRACE);
							// エネミーカード選択中、かつラウンド条件選択中
							return false;
						}
					}
					return true;
				});
			}
			new ToolItem(bar, SWT.SEPARATOR);
		}
		createToolItem2(_comm, bar, _prop.msgs.expandTree, _prop.images.expandTree, &_etree.treeOpen, &_etree.canExpandTree);
		createToolItem2(_comm, bar,_prop.msgs.foldTree,  _prop.images.foldTree, &_etree.treeClose, &_etree.canFoldTree);
	}
	private void setFireControl(Control c) { mixin(S_TRACE);
		if (_readOnly) return;
		if (_fireItm.getControl()) _fireItm.getControl().dispose();
		_fireItm.setControl(c);
		_comm.refreshToolBar();
	}
	@property
	private string[] areaDefVals() { mixin(S_TRACE);
		static if (is (A == Area)) {
			return [_prop.msgs.startEnter];
		} else static if (is (A == Battle)) {
			return [_prop.msgs.startVictory, _prop.msgs.startEscape, _prop.msgs.startLose, _prop.msgs.startEveryRound, _prop.msgs.startRound0];
		} else static if (is (A == Package)) {
			return [_prop.msgs.startPackage];
		} else { mixin(S_TRACE);
			return [_prop.msgs.startUse];
		}
	}
	@property
	private string[] startDefVals() { mixin(S_TRACE);
		auto itm = selectionParent;
		if (!itm) return [];
		auto data = itm.getData();
		string[] vals;
		if (cast(A) data) { mixin(S_TRACE);
			return areaDefVals;
		} else { mixin(S_TRACE);
			static if (!is (C == void)) {
				assert (cast(C) data);
				static if (is (C == MenuCard)) {
					return [_prop.msgs.startSelect];
				} else { mixin(S_TRACE);
					assert (is (C == EnemyCard));
					return [_prop.msgs.startDead];
				}
			} else { mixin(S_TRACE);
				assert (0);
			}
		}
	}
	private void createCombo(bool readOnly, string[] vals, bool visLong = false) { mixin(S_TRACE);
		int style = SWT.BORDER | SWT.DROP_DOWN;
		if (readOnly) style |= SWT.READ_ONLY;
		auto c = new CCombo(_toolbar, style);
		if (visLong) c.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		c.setEnabled(!_readOnly);
		foreach (i, v; vals) { mixin(S_TRACE);
			c.add(v);
			if (i == 0) c.setText(v);
		}
		createTextMenu!CCombo(_comm, _prop, c, null);
		setFireControl(c);
	}
	private void createKCCombo() { mixin(S_TRACE);
		auto combo = createKeyCodeCombo!CCombo(_comm, _summ, _toolbar, null);
		combo.setEnabled(!_readOnly);
		setFireControl(combo);
		if (combo.getItemCount()) { mixin(S_TRACE);
			combo.select(0);
		}
	}
	private class KSListener : SelectionAdapter {
	public:
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			static if (is (A == Area)) {
				switch (_treeKind.getSelectionIndex()) {
				case 0:
					createCombo(true, startDefVals);
					_keyCodeTim.setEnabled(false);
					break;
				case 1:
					createKCCombo();
					_keyCodeTim.setEnabled(!_readOnly);
					break;
				default: assert (0);
				}
			} else static if (is (A == Battle)) {
				switch (_treeKind.getSelectionIndex()) {
				case 0:
					createCombo(true, startDefVals);
					_keyCodeTim.setEnabled(false);
					break;
				case 1:
					createKCCombo();
					_keyCodeTim.setEnabled(!_readOnly);
					break;
				case 2:
					auto spn = new Spinner(_toolbar, SWT.BORDER);
					initSpinner(spn);
					spn.setMaximum(9999);
					spn.setMinimum(1);
					spn.setSelection(1);
					setFireControl(spn);
					_keyCodeTim.setEnabled(false);
					break;
				default: assert (0);
				}
			}
		}
	}

	void openToolWindow() { mixin(S_TRACE);
		auto fc = this.getDisplay().getFocusControl();
		bool focusInEventView = this.isDescendant(fc);
		_etree.openToolWindow(focusInEventView);
	}
	void closeToolWindow() { mixin(S_TRACE);
		_etree.closeToolWindow();
	}

	@property
	string statusLine() { mixin(S_TRACE);
		return _etree.statusLine;
	}

	void edit() { mixin(S_TRACE);
		_etree.edit();
	}
	@property
	bool canEdit() { mixin(S_TRACE);
		return _etree.canEdit();
	}

	@property
	bool canCut1Content() { return _etree.canCut1Content; }
	@property
	bool canDel1Content() { return _etree.canDel1Content; }
	@property
	bool canCopy1Content() { return _etree.canCopy1Content; }
	@property
	bool canPasteInsert() { return _etree.canPasteInsert; }
	@property
	bool canSwapToParent() { return _etree.canSwapToParent; }
	@property
	bool canSwapToChild() { return _etree.canSwapToChild; }
	void cut1Content() { _etree.cut1Content(); }
	void copy1Content() { _etree.copy1Content(); }
	void pasteInsert() { _etree.pasteInsert(); }
	void del1Content() { _etree.del1Content(); }
	void swapToParent() { _etree.swapToParent(); }
	void swapToChild() { _etree.swapToChild(); }

	void toScript() { mixin(S_TRACE);
		_etree.toScript();
	}
	void toScript1Content() { mixin(S_TRACE);
		_etree.toScript1Content();
	}
	void toScriptAll() { mixin(S_TRACE);
		_etree.toScriptAll();
	}
	@property
	bool canToScript() { mixin(S_TRACE);
		return _etree.canToScript();
	}
	@property
	bool canToScriptAll() { mixin(S_TRACE);
		return _etree.canToScriptAll();
	}
	@property
	bool canWriteComment() { mixin(S_TRACE);
		return _etree.canWriteComment;
	}
	void writeComment() { mixin(S_TRACE);
		_etree.writeComment();
	}
	@property
	bool canStartToPackage() { mixin(S_TRACE);
		return _etree.canStartToPackage();
	}
	void startToPackage() { mixin(S_TRACE);
		return _etree.startToPackage();
	}
	@property
	bool canWrapTree() { mixin(S_TRACE);
		return _etree.canWrapTree();
	}
	void wrapTree() { mixin(S_TRACE);
		return _etree.wrapTree();
	}

	private void pasteScript(Clipboard cb) { mixin(S_TRACE);
		if (_readOnly) return;
		auto array = cast(ArrayWrapperString) cb.getContents(TextTransfer.getInstance());
		if (!array) return;
		CompileOption opt;
		string script = array.array.idup;
		string base = script;
		try { mixin(S_TRACE);
			opt.linkId = _prop.var.etc.linkCard;

			void put(Content[] cs) { mixin(S_TRACE);
				if (!cs.length) return;
				if (cs[0].type !is CType.START) return;
				createEventTree(cs);
			}
			auto compiler = new CWXScript(_prop.parent, _summ);
			auto vars = compiler.eatEmptyVars(script, opt);
			if (vars.length) { mixin(S_TRACE);
				auto dlg = new ScriptVarSetDialog(_comm, _summ, _cards.getShell(), vars, script, base, opt);
				dlg.appliedEvent ~= { mixin(S_TRACE);
					put(dlg.contents);
				};
				dlg.open();
			} else { mixin(S_TRACE);
				put(cwx.script.compile(_prop.parent, _summ, script, opt));
			}
		} catch (CWXScriptException e) {
			auto dlg = new ScriptErrorDialog(_comm, _prop, _cards, e, base, opt);
			dlg.open();
		}
	}
	override void cut(SelectionEvent se) { mixin(S_TRACE);
		if (_readOnly) return;
		initial();
		if (_etree.isFocusControl) { mixin(S_TRACE);
			_etree.cut(se);
		} else { mixin(S_TRACE);
			copy(se);
			del(se);
		}
	}
	override void copy(SelectionEvent se) { mixin(S_TRACE);
		copyImpl(se, true);
	}
	private void copyImpl(SelectionEvent se, bool canFire) { mixin(S_TRACE);
		initial();
		if (_etree.isFocusControl) { mixin(S_TRACE);
			_etree.copy(se);
		} else { mixin(S_TRACE);
			auto itm = selection;
			if (!itm) return;
			auto parItm = itm.getParentItem();
			if (!parItm) return;
			auto par = parItm.getData();
			auto data = itm.getData();
			string xml;
			if (cast(EventTree) data) { mixin(S_TRACE);
				xml = (cast(EventTree) data).toXML(new XMLOption(_prop.sys));
			} else if (!canFire) { mixin(S_TRACE);
				assert (cast(EventTree) par !is null);
				xml = (cast(EventTree) par).toXML(new XMLOption(_prop.sys));
			} else { mixin(S_TRACE);
				static if (UseFire) {
					if (ENTER is data) { mixin(S_TRACE);
						xml = EventTree.enterToXML();
					} else if (ESCAPE is data) { mixin(S_TRACE);
						xml = EventTree.escapeToXML();
					} else if (LOSE is data) { mixin(S_TRACE);
						xml = EventTree.loseToXML();
					} else if (EVERY_ROUND is data) { mixin(S_TRACE);
						xml = EventTree.everyRoundToXML();
					} else if (ROUND_0 is data) { mixin(S_TRACE);
						xml = EventTree.round0ToXML();
					} else if (cast(KeyCodeObj) data) { mixin(S_TRACE);
						xml = EventTree.keyCodeToXML(_prop.sys.toFKeyCode((cast(KeyCodeObj) data).array.idup), _prop.sys);
					} else if (cast(RoundObj) data) { mixin(S_TRACE);
						xml = EventTree.roundToXML((cast(RoundObj) data).intValue());
					} else { mixin(S_TRACE);
						assert (0);
					}
				} else { mixin(S_TRACE);
					assert (0);
				}
			}
			XMLtoCB(_prop, _comm.clipboard, xml);
			_comm.refreshToolBar();
		}
	}
	override void paste(SelectionEvent se) { mixin(S_TRACE);
		if (_readOnly) return;
		initial();
		if (_etree.isFocusControl) { mixin(S_TRACE);
			_etree.paste(se);
		} else { mixin(S_TRACE);
			auto itm = selection;
			if (!itm) return;
			auto xml = CBtoXML(_comm.clipboard);
			if (!xml) { mixin(S_TRACE);
				pasteScript(_comm.clipboard);
				return;
			}
			auto parItm = selectionParent;
			if (parItm) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto par = cast(EventTreeOwner) parItm.getData();
					auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
					EventTree tree = EventTree.fromXML(xml, ver);
					if (tree) { mixin(S_TRACE);
						storeI(_cards.indexOf(parItm), par.trees.length);
						// イベントツリー
						par.add(tree);
						auto treeItm = createTreeItem(parItm, tree, tree.name, etImage(tree));
						__select(treeItm);
						static if (UseFire) {
							refreshFires(treeItm);
						}
						_comm.refEventTree.call(tree);
					} else { mixin(S_TRACE);
						static if (UseFire) {
							if (!(cast(EventTreeOwner) itm.getData())) { mixin(S_TRACE);
								// 開始条件
								auto treeItm = cast(EventTree) itm.getData() ? itm : itm.getParentItem();
								tree = cast(EventTree) treeItm.getData();
								store(tree);
								if (tree.enterFromXML(par, xml)) { mixin(S_TRACE);
									refreshFires(treeItm, ENTER);
								} else if (tree.escapeFromXML(par, xml)) { mixin(S_TRACE);
									refreshFires(treeItm, ESCAPE);
								} else if (tree.loseFromXML(par, xml)) { mixin(S_TRACE);
									refreshFires(treeItm, LOSE);
								} else if (tree.everyRoundFromXML(par, xml)) { mixin(S_TRACE);
									refreshFires(treeItm, EVERY_ROUND);
								} else if (tree.round0FromXML(par, xml)) { mixin(S_TRACE);
									refreshFires(treeItm, ROUND_0);
								} else { mixin(S_TRACE);
									int round = tree.roundFromXML(par, xml);
									if (round >= 0) { mixin(S_TRACE);
										refreshFires(treeItm, new RoundObj(round));
									} else { mixin(S_TRACE);
										string keyCode = tree.keyCodeFromXML(par, xml, _prop.sys);
										if (keyCode) { mixin(S_TRACE);
											refreshFires(treeItm, new KeyCodeObj(keyCode));
										}
									}
								}
								_comm.refEventTree.call(tree);
								_comm.refKeyCodes.call();
							}
						}
					}
					_comm.refUseCount.call();
					_comm.refreshToolBar();
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
	}
	override void del(SelectionEvent se) { mixin(S_TRACE);
		if (_readOnly) return;
		initial();
		if (_etree.isFocusControl) { mixin(S_TRACE);
			_etree.del(se);
		} else { mixin(S_TRACE);
			auto itm = selection;
			if (!itm) return;
			auto parItm = itm.getParentItem();
			if (!parItm) return;
			auto par = parItm.getData();
			auto data = itm.getData();
			auto tree = cast(EventTree) data;
			if (tree) { mixin(S_TRACE);
				storeD(tree);
				(cast(EventTreeOwner) par).remove(tree);
				if (_selItm is itm) { mixin(S_TRACE);
					_selItm = null;
					_etree.refresh(null);
				}
				_comm.delEventTree.call(tree);
			} else { mixin(S_TRACE);
				static if (UseFire) {
					tree = cast(EventTree) par;
					store(tree);
					if (ENTER is data) { mixin(S_TRACE);
						tree.enter = false;
					} else if (ESCAPE is data) { mixin(S_TRACE);
						tree.escape = false;
					} else if (LOSE is data) { mixin(S_TRACE);
						tree.lose = false;
					} else if (EVERY_ROUND is data) { mixin(S_TRACE);
						tree.everyRound = false;
					} else if (ROUND_0 is data) { mixin(S_TRACE);
						tree.round0 = false;
					} else if (cast(KeyCodeObj) data) { mixin(S_TRACE);
						tree.removeKeyCode(_prop.sys.toFKeyCode((cast(KeyCodeObj) data).array.idup));
					} else if (cast(RoundObj) data) { mixin(S_TRACE);
						tree.removeRound((cast(RoundObj) data).intValue());
					} else { mixin(S_TRACE);
						assert (0);
					}
					_comm.refEventTree.call(tree);
				}
			}
			itm.dispose();
			_comm.refUseCount.call();
			_comm.refreshToolBar();
		}
	}
	override void clone(SelectionEvent se) { mixin(S_TRACE);
		if (_readOnly) return;
		if (_etree.isFocusControl) { mixin(S_TRACE);
			_etree.clone(se);
		} else { mixin(S_TRACE);
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copyImpl(se, false);
			paste(se);
		}
	}
	@property
	override bool canDoTCPD() { mixin(S_TRACE);
		if (_readOnly) return false;
		return _cards.isFocusControl() || _etree.isFocusControl();
	}
	@property
	override bool canDoT() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (_cards.isFocusControl()) { mixin(S_TRACE);
			return selection && selection.getParentItem();
		} else if (_etree.isFocusControl()) { mixin(S_TRACE);
			return _etree.canDoT;
		}
		return false;
	}
	@property
	override bool canDoC() { mixin(S_TRACE);
		if (_cards.isFocusControl()) { mixin(S_TRACE);
			return selection && selection.getParentItem();
		} else if (_etree.isFocusControl()) { mixin(S_TRACE);
			return _etree.canDoC;
		}
		return false;
	}
	@property
	override bool canDoP() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (_cards.isFocusControl()) { mixin(S_TRACE);
			return CBisXML(_comm.clipboard) || CBisText(_comm.clipboard);
		} else if (_etree.isFocusControl()) { mixin(S_TRACE);
			return _etree.canDoP;
		}
		return false;
	}
	@property
	override bool canDoD() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (_cards.isFocusControl()) { mixin(S_TRACE);
			return canDoT;
		} else if (_etree.isFocusControl()) { mixin(S_TRACE);
			return _etree.canDoD;
		}
		return false;
	}
	@property
	override bool canDoClone() { mixin(S_TRACE);
		if (_readOnly) return false;
		return canDoC;
	}
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

	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		initial();
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		bool open(TreeItem itm) { mixin(S_TRACE);
			if (index >= itm.getItemCount()) { mixin(S_TRACE);
				return false;
			}
			__select(itm.getItem(index));
			return _etree.openCWXPath(cpbottom(path), shellActivate);
		}
		static if (is(C : MenuCard) || is(C : EnemyCard)) {
			bool card() { mixin(S_TRACE);
				if (index + 1 >= _cards.getItemCount()) { mixin(S_TRACE);
					return false;
				}
				auto itm = _cards.getItem(index + 1);
				path = cpbottom(path);
				if (cpempty(path)) { mixin(S_TRACE);
					if (!cphasattr(path, "nofocus")) .forceFocus(_cards, shellActivate);
					__select(itm);
					return true;
				} else { mixin(S_TRACE);
					cate = cpcategory(path);
					index = cpindex(path);
					return open(itm);
				}
			}
		}
		switch (cate) {
		case "event": { mixin(S_TRACE);
			return open(_cards.getItem(0));
		} break;
		case "menucard": { mixin(S_TRACE);
			static if (is(C : MenuCard)) {
				return card();
			}
		} break;
		case "enemycard": { mixin(S_TRACE);
			static if (is(C : EnemyCard)) {
				return card();
			}
		} break;
		case "": { mixin(S_TRACE);
			.forceFocus(_cards, shellActivate);
			_comm.refreshToolBar();
			return true;
		} break;
		default: break;
		}
		return false;
	}
	@property
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		auto etItm = selectionEventTree;
		if (!etItm) { mixin(S_TRACE);
			auto cardItm = selectionParent;
			if (cardItm) { mixin(S_TRACE);
				auto d = cardItm.getData();
				auto area = cast(A) d;
				if (area) { mixin(S_TRACE);
					r ~= cpaddattr(area.cwxPath(true), "eventview");
				}
				static if (!is(C : void)) {
					auto card = cast(C) d;
					if (card) { mixin(S_TRACE);
						r ~= cpaddattr(card.cwxPath(true), "eventview");
					}
				}
			} else { mixin(S_TRACE);
				r ~= cpaddattr(_area.cwxPath(true), "eventview");
			}
		}
		r ~= _etree.openedCWXPath;
		return r;
	}
}

private class ManyRoundsDialog : AbsDialog {
private:
	Props _prop;

	Spinner _from;
	Spinner _to;

	uint[] _rounds;
public:
	this (Props prop, Shell shell) { mixin(S_TRACE);
		_prop = prop;
		super (prop, shell, prop.msgs.dlgTitAddManyRounds, prop.images.menu(MenuID.AddRangeOfRound), false);
		enterClose = true;
	}

	@property
	uint[] rounds() { mixin(S_TRACE);
		return _rounds;
	}
protected:
	private class SelMin : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			int f = _from.getSelection();
			if (f >= _to.getSelection()) { mixin(S_TRACE);
				_to.setSelection(f);
			}
		}
	}
	private class SelMax : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			int t = _to.getSelection();
			if (t <= _from.getSelection()) { mixin(S_TRACE);
				_from.setSelection(t);
			}
		}
	}
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(new GridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(_prop.msgs.manyRounds);
			grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(new GridLayout(4, false));
			_from = new Spinner(comp, SWT.BORDER);
			initSpinner(_from);
			_from.setMinimum(1);
			_from.setMaximum(_prop.var.etc.roundMax);
			_from.addSelectionListener(new SelMin);
			auto l1 = new Label(comp, SWT.NONE);
			l1.setText(_prop.msgs.roundSep);
			_to = new Spinner(comp, SWT.BORDER);
			initSpinner(_to);
			_to.setMinimum(1);
			_to.setMaximum(_prop.var.etc.roundMax);
			_to.addSelectionListener(new SelMax);
			auto l2 = new Label(comp, SWT.NONE);
			l2.setText(.tryFormat(_prop.msgs.rangeHint, 1, _prop.var.etc.roundMax));
		}
	}
	override bool close(bool ok) { mixin(S_TRACE);
		if (ok) { mixin(S_TRACE);
			for (uint i = _from.getSelection(); i <= _to.getSelection(); i++) { mixin(S_TRACE);
				_rounds ~= i;
			}
		}
		return ok;
	}
}
