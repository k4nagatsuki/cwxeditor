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

	static EventTreeOwner[] etos(A area) {
		EventTreeOwner[] r;
		r ~= area;
		static if (is(A : Area) || is(A : Battle)) {
			foreach (c; area.cards) {
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
		private int[] getSelPath(EventView v) {
			if (!v) return null;
			auto itm = v.selection;
			if (itm) {
				int[] selPath;
				while (itm.getParentItem()) {
					selPath = [itm.getParentItem().indexOf(itm)] ~ selPath;
					itm = itm.getParentItem();
				}
				return [v._cards.indexOf(itm)] ~ selPath;
			} else {
				return null;
			}
		}
		this (EventView v, Commons comm, A area) {
			this.comm = comm;
			this.area = area;
			_selPath = getSelPath(v);
		}
		protected void udb(EventView v) {
			if (!v) return;
			.forceFocus(v._cards, false);
			_selPath2 = getSelPath(v);
		}
		protected void uda(EventView v) {
			scope (exit) comm.refreshToolBar();
			if (!v) return;
			if (_selPath) {
				auto itm = v._cards.getItem(_selPath[0]);
				_selPath = _selPath[1 .. $];
				while (_selPath.length) {
					itm = itm.getItem(_selPath[0]);
					_selPath = _selPath[1 .. $];
				}
				auto eti = v.selectionEventTree;
				v._cards.select(itm);
				auto eti2 = v.selectionEventTree;
				if (eti !is eti2) {
					if (eti2) {
						v.__select(eti2);
					} else if (!eti) {
						v._etree.refresh(null);
					}
				}
				_selPath = _selPath2;
			} else {
				v._cards.deselectAll();
			}
		}
		protected EventView view() {
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
			string[] keyCodes;
			uint[] rounds;
		}
		private Vals _vals;
		this (EventView v, Commons comm, A area, EventTree tree) {
			super (v, comm, area);
			auto eto = tree.owner;
			_index = .cCountUntil!("a is b")(tree.owner.trees, tree);
			_ownerIndex = .cCountUntil!("a is b")(etos(area), eto);
			save(v, tree);
		}
		private void save(EventView v, EventTree tree) {
			if (v) _vals.expand = getItem(v).getExpanded();
			_vals.name = tree.name;
			_vals.enter = tree.fireEnter;
			_vals.escape = tree.fireEscape;
			_vals.lose = tree.fireLose;
			_vals.keyCodes = tree.keyCodes.dup;
			_vals.rounds = tree.rounds.dup;
		}
		private TreeItem getItem(EventView v) {
			enforce(v);
			return v._cards.getItem(_ownerIndex).getItem(_index);
		}
		private void impl() {
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
			tree.removeKeyCodesAll();
			foreach (kc; vals.keyCodes) tree.addKeyCode(kc);
			tree.removeRoundsAll();
			foreach (rnd; vals.rounds) tree.addRound(rnd);
			if (v) {
				auto itm = getItem(v);
				itm.setExpanded(vals.expand);
				itm.setText(vals.name);
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
	void store(EventTree tree) {
		_undo ~= new UndoTreeData(this, _comm, _area, tree);
	}
	static class UndoInsert : EVUndo {
		private int _ownerIndex;
		private int _insertIndex;
		private UndoDelete _delUndo = null;
		private Summary _summ;
		this (EventView v, Commons comm, A area, Summary summ, int ownerIndex, int insertIndex) {
			super (v, comm, area);
			_ownerIndex = ownerIndex;
			_insertIndex = insertIndex;
			_summ = summ;
		}
		override void undo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			undoImpl(v);
		}
		void undoImpl(EventView v) {
			auto owner = etos(area)[_ownerIndex];
			auto tree = owner.trees[_insertIndex];
			_delUndo = new UndoDelete(v, comm, area, _summ, tree);
			owner.removeEvent(_insertIndex);
			if (v) {
				if (v._etree.eventTree && v._etree.eventTree.areaPath == tree.areaPath) {
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
		override void redo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			_delUndo.undoImpl(v);
			_delUndo = null;
		}
		override void dispose() {
			if (_delUndo) _delUndo.dispose();
		}
	}
	void storeI(int ownerIndex, int insertIndex) {
		_undo ~= new UndoInsert(this, _comm, _area, _summ, ownerIndex, insertIndex);
	}
	static class UndoDelete : EVUndo {
		private int _ownerIndex;
		private int _treeIndex;
		private EventTree _tree;
		private UndoInsert _istUndo = null;
		private Summary _summ;
		this (EventView v, Commons comm, A area, Summary summ, EventTree tree) {
			super (v, comm, area);
			_summ = summ;
			auto owner = tree.owner;
			_ownerIndex = .cCountUntil!("a is b")(etos(area), owner);
			_treeIndex = .cCountUntil!("a is b")(owner.trees, tree);
			auto node = tree.toNode(null);
			_tree = EventTree.createFromNode(node, LATEST_VERSION);
			_tree.setUseCounter(summ.useCounter.sub);
		}
		override void undo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			undoImpl(v);
		}
		void undoImpl(EventView v) {
			_istUndo = new UndoInsert(v, comm, area, _summ, _ownerIndex, _treeIndex);
			if (v) {
				auto parItm = v._cards.getItem(_ownerIndex);
				v.appendTree(parItm, _tree, _treeIndex, null, false);
			} else {
				auto eto = etos(area)[_ownerIndex];
				appendTreeImpl(comm, eto, _tree, _treeIndex);
			}
		}
		override void redo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			_istUndo.undoImpl(v);
			_istUndo = null;
		}
		override void dispose() {
			_tree.removeUseCounter();
			if (_istUndo) _istUndo.dispose();
		}
	}
	void storeD(EventTree tree) {
		_undo ~= new UndoDelete(this, _comm, _area, _summ, tree);
	}
	static class UndoSwap : EVUndo {
		private int _ownerIndex;
		private int _swapIndex1;
		private int _swapIndex2;
		this (EventView v, Commons comm, A area, int ownerIndex, int swapIndex1, int swapIndex2) {
			super (v, comm, area);
			_ownerIndex = ownerIndex;
			_swapIndex1 = swapIndex1;
			_swapIndex2 = swapIndex2;
		}
		private void impl() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (v) {
				v.up(v._cards.getItem(_ownerIndex).getItem(max(_swapIndex1, _swapIndex2)), false);
			} else {
				staticUDImpl(comm, etos(area)[_ownerIndex], _swapIndex1, _swapIndex2);
			}
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {}
	}
	void store(int ownerIndex, int swapIndex1, int swapIndex2) {
		_undo ~= new UndoSwap(this, _comm, _area, ownerIndex, swapIndex1, swapIndex2);
	}

	void forceSel(size_t[] etAreaPath) {
		auto eet = _etree.eventTree;
		if (eet && eet.areaPath == etAreaPath) return;
		auto eta = _area.etFromPath(etAreaPath).areaPath;
		foreach (i, itm; _cards.getItems()) {
			foreach (j, tItm; itm.getItems()) {
				auto cet = cast(EventTree) tItm.getData();
				assert (cet);
				if (cet.areaPath == eta) {
					__select(tItm);
					return;
				}
			}
		}
		assert (0);
	}

	void __select(TreeItem itm, bool sel = true) {
		if (sel) _cards.setSelection([itm]);
		if (cast(EventTree) itm.getData()) {
			_selItm = itm;
			_etree.refresh(cast(EventTree) itm.getData());
		}
		static if (UseFire) {
			auto parItm = selectionParent;
			if (parItm && (!_oldSelP || _oldSelP != parItm) && _treeKind.getSelectionIndex() == 0) {
				auto c = cast(CCombo) _fireItm.getControl();
				c.removeAll();
				string[] vals;
				if (cast(EventTreeOwner) parItm.getData()) {
					vals = startDefVals;
				}
				foreach (i, v; vals) {
					c.add(v);
					if (i == 0) c.setText(v);
				}
			}
		}
		_comm.refreshToolBar();
	}

	void refreshTopStart() {
		assert (_selItm);
		assert (_selItm.getData() is _etree.eventTree);
		_selItm.setText(_etree.eventTree.name);
	}
	class SListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) {
			__select(cast(TreeItem) e.item, false);
		}
	}
	static int before(T)(T parent, int index) {
		if (index > 0) {
			return index - 1;
		}
		return -1;
	}
	static int after(T)(T parent, int index) {
		if (index + 1 < parent.getItemCount()) {
			return index + 1;
		}
		return -1;
	}
	@property
	TreeItem selection() {
		auto sels = _cards.getSelection();
		if (sels.length > 0) {
			return sels[0];
		}
		return null;
	}
	@property
	void selection(int index) {
		__select(_cards.getItems()[index]);
	}
	@property
	private TreeItem selectionParent() {
		auto itm = selection;
		if (!itm) return null;
		auto data = itm.getData();
		if (cast(EventTreeOwner) data) return itm;
		if (cast(EventTree) data) {
			return itm.getParentItem();
		} else {
			return itm.getParentItem().getParentItem();
		}
	}
	@property
	private TreeItem selectionEventTree() {
		auto itm = selection;
		if (!itm) return null;
		auto data = itm.getData();
		if (cast(EventTreeOwner) data) return null;
		if (cast(EventTree) data) {
			return itm;
		} else {
			return itm.getParentItem();
		}
	}
	static if (is(A : Area) || is(A : Battle)) {
		@property
		private TreeItem selectionKeyCode() {
			auto itm = selection;
			if (!itm) return null;
			auto data = itm.getData();
			return cast(KeyCodeObj) data ? itm : null;
		}
	}
	void createEventTree() {
		createEventTree([]);
	}
	void createEventTree(Content[] starts) {
		foreach (s; starts) {
			if (s.type !is CType.START) return;
		}
		auto parItm = selectionParent;
		if (!parItm) return;
		string treeName;
		static if (UseFire) {
			auto fire = addingFire(parItm.getData());
			if (!fire) return;
			if (fire is ENTER) {
				if (cast(A) parItm.getData()) {
					static if (is (A == Area)) {
						treeName = _prop.msgs.enterTree;
					} else static if (is (A == Battle)) {
						treeName = _prop.msgs.victoryTree;
					} else static if (is (A == Package)) {
						treeName = _prop.msgs.packageTree;
					} else {
						treeName = _prop.msgs.useTree;
					}
				} else {
					static if (is (C == MenuCard)) {
						assert (cast(C) parItm.getData());
						treeName = _prop.msgs.selectTree;
					} else static if (is (C == EnemyCard)) {
						assert (cast(C) parItm.getData());
						treeName = _prop.msgs.deadTree;
					}
				}
			} else if (fire is ESCAPE) {
				treeName = _prop.msgs.escapeTree;
			} else if (fire is LOSE) {
				treeName = _prop.msgs.loseTree;
			} else if (cast(KeyCodeObj) fire) {
				treeName = .tryFormat(_prop.msgs.keyCodeTree, (cast(KeyCodeObj) fire).array.idup);
			} else {
				assert (cast(RoundObj) fire);
				treeName = .tryFormat(_prop.msgs.roundTree, (cast(RoundObj) fire).intValue());
			}
		} else {
			Object fire = null;
			static if (is (A == Package)) {
				treeName = _prop.msgs.packageTree;
			} else {
				treeName = _prop.msgs.useTree;
			}
		}
		auto owner = cast(EventTreeOwner) parItm.getData();
		EventTree tree;
		if (starts.length) {
			tree = new EventTree(starts[0]);
			foreach (s; starts[1 .. $]) {
				tree.add(s);
			}
		} else {
			tree = new EventTree(treeName);
		}
		appendTree(parItm, tree, owner.trees.length, fire, true);
		if (starts.length) {
			_comm.refUseCount.call();
		}
		_comm.refreshToolBar();
	}
	private static void appendTreeImpl(Commons comm, EventTreeOwner eto, EventTree tree, int index) {
		eto.insert(index, tree);
		comm.refEventTree.call(tree);
		comm.refUseCount.call();
	}
	void appendTree(TreeItem parItm, EventTree tree, int index, Object defFire, bool store) {
		auto eto = cast(EventTreeOwner) parItm.getData();
		if (store) storeI(_cards.indexOf(parItm), eto.trees.length);
		appendTreeImpl(_comm, eto, tree, index);
		auto treeItm = appendTreeItem(parItm, index, defFire);
		__select(treeItm);
	}
	void refreshTrees(TreeItem parItm) {
		auto par = cast(EventTreeOwner) parItm.getData();
		parItm.removeAll();
		foreach (index, tree; par.trees) {
			appendTreeItem(parItm, index, null);
		}
		parItm.setExpanded(true);
		_comm.refreshToolBar();
	}
	TreeItem appendTreeItem(TreeItem parItm, int index, Object defFire) {
		auto par = cast(EventTreeOwner) parItm.getData();
		auto tree = par.trees[index];
		auto treeItm = createTreeItem(parItm, tree, tree.name, _prop.images.eventTree, index);
		static if (UseFire) {
			if (defFire) addFire(treeItm, defFire);
			refreshFires(treeItm);
		}
		return treeItm;
	}
	Control createEditor(TreeItem itm) {
		static if (UseFire) {
			if (cast(EventTree) itm.getData() || cast(KeyCodeObj) itm.getData()) {
				return createTextEditor(_comm, _prop, _cards, itm.getText());
			}
		} else {
			if (cast(EventTree) itm.getData()) {
				return createTextEditor(_comm, _prop, _cards, itm.getText());
			}
		}
		return null;
	}
	void editEnd(TreeItem itm, Control c) {
		string text = (cast(Text) c).getText();
		if (!text) text = "";
		auto tree = cast(EventTree) itm.getData();
		if (tree) {
			if (text == tree.name) return;
			store(tree);
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
			tree = cast(EventTree) p.getData();
			auto kcIndex = p.indexOf(itm) - keyCodesIndex(p);
			if (tree.keyCodes[kcIndex] == text) return;
			store(tree);
			tree.setKeyCode(kcIndex, text);
			itm.setImage(keyCodeImage(text));
			obj.array = text.dup;
			_comm.refEventTree.call(tree);
			_comm.refKeyCodes.call();
			_comm.refreshToolBar();
		}
	}
	static if (UseFire) {
		void refreshFires(TreeItem eItm, Object sel = null) {
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
				if (t.fireEnter) {
					if (cast(A) eItm.getParentItem().getData()) {
						createTreeItem(eItm, ENTER, _prop.msgs.startEnter, _prop.images.defStart);
					} else {
						assert (cast(C) eItm.getParentItem().getData());
						createTreeItem(eItm, ENTER, _prop.msgs.startSelect, _prop.images.defStart);
					}
				}
				createKeyCodeItem(eItm, t);
			} else static if (is (A == Battle)) {
				if (cast(A) eItm.getParentItem().getData()) {
					if (t.fireEnter) {
						createTreeItem(eItm, ENTER, _prop.msgs.startVictory, _prop.images.defStart);
					}
					if (t.fireEscape) {
						createTreeItem(eItm, ESCAPE, _prop.msgs.startEscape, _prop.images.defStart);
					}
					if (t.fireLose) {
						createTreeItem(eItm, LOSE, _prop.msgs.startLose, _prop.images.defStart);
					}
				} else {
					assert (cast(C) eItm.getParentItem().getData());
					if (t.fireEnter) {
						createTreeItem(eItm, ENTER, _prop.msgs.startDead, _prop.images.defStart);
					}
				}
				createKeyCodeItem(eItm, t);
				if (cast(A) eItm.getParentItem().getData()) {
					foreach (r; t.rounds) {
						createTreeItem(eItm, new RoundObj(r), .tryFormat(_prop.msgs.startRound, r), _prop.images.round);
					}
				}
			} else static if (is (A == Package)) {
				if (t.fireEnter) {
					createTreeItem(eItm, ENTER, _prop.msgs.startPackage, _prop.images.defStart);
				}
			} else {
				auto eItm = createTreeItem(aItm, t, t.name, _prop.images.eventTree);
				if (t.fireEnter) {
					createTreeItem(eItm, ENTER, _prop.msgs.startUse, _prop.images.defStart);
				}
			}
			if (sel) {
				foreach (itm; eItm.getItems()) {
					auto data = itm.getData();
					if (cast(KeyCodeObj) data && cast(KeyCodeObj) sel) {
						if ((cast(KeyCodeObj) data).array == (cast(KeyCodeObj) sel).array) {
							_cards.setSelection([itm]);
							break;
						}
					} else if (cast(RoundObj) data && cast(RoundObj) sel) {
						if ((cast(RoundObj) data).intValue() == (cast(RoundObj) sel).intValue()) {
							_cards.setSelection([itm]);
							break;
						}
					} else if (data is sel) {
						assert (data is ENTER || data is LOSE || data is ESCAPE);
						_cards.setSelection([itm]);
						break;
					}
				}
				eItm.setExpanded(true);
			}
		}
		Object addingFire(Object areaOrCard) {
			static if (!is (C == void)) {
				Object addKeyCodes() {
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
					}
					return kc.length > 0 ? new KeyCodeObj(kc) : null;
				}
				Object addAreaAndEtc() {
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
			if (cast(A) areaOrCard) {
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
						default: assert (0);
						}
					case 1:
						return addKeyCodes();
					case 2:
						int round = (cast(Spinner) _fireItm.getControl()).getSelection();
						return new RoundObj(round);
					default: assert (0);
					}
				} else {
					return ENTER;
				}
			} else {
				static if (!is (C == void)) {
					assert (cast(C) areaOrCard);
					return addAreaAndEtc();
				}
			}
			return null;
		}
		void createEventFire() {
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
		void addFire(TreeItem treeItm, Object fire) {
			auto tree = cast(EventTree) treeItm.getData();
			if (fire is ENTER) {
				tree.enter = true;
			} else if (fire is ESCAPE) {
				tree.escape = true;
			} else if (fire is LOSE) {
				tree.lose = true;
			} else if (cast(KeyCodeObj) fire) {
				tree.addKeyCode((cast(KeyCodeObj) fire).array.idup);
			} else {
				assert (cast(RoundObj) fire);
				tree.addRound((cast(RoundObj) fire).intValue());
			}
			_comm.refEventTree.call(tree);
		}
		static __gshared Object ENTER;
		static __gshared Object ESCAPE;
		static __gshared Object LOSE;
		shared static this () {
			ENTER = new Object;
			ESCAPE = new Object;
			LOSE = new Object;
		}
		int keyCodesIndex(TreeItem itm) {
			assert (cast(EventTree) itm.getData());
			auto o = itm.getParentItem().getData();
			if (cast(A) o) {
				auto tree = cast(EventTree) itm.getData();
				static if (is (A == Battle)) {
					int r = 0;
					if (tree.fireEnter) r++;
					if (tree.fireLose) r++;
					if (tree.fireEscape) r++;
					return r;
				} else {
					return (cast(EventTree) itm.getData()).fireEnter ? 1 : 0;
				}
			} else {
				static if (!is (C == void)) {
					assert (cast(C) o);
					return (cast(EventTree) itm.getData()).fireEnter ? 1 : 0;
				} else {
					assert (0);
				}
			}
		}
		Image keyCodeImage(string keyCode) {
			final switch (_prop.sys.fireKeyCodeKind(keyCode)) {
			case FKCKind.Use: return _prop.images.keyCode;
			case FKCKind.Success: return _prop.images.menu(MenuID.KeyCodeTimingSuccess);
			case FKCKind.Failure: return _prop.images.menu(MenuID.KeyCodeTimingFailure);
			}
		}
		void createKeyCodeItem(T)(TreeItem parent, T a) {
			foreach (kc; a.keyCodes) {
				createTreeItem(parent, new KeyCodeObj(kc), kc, keyCodeImage(kc));
			}
		}
	}
	void replText() {
		foreach (itm; _cards.getItems()) {
			auto data = itm.getData();
			if (cast(A) data) {
				itm.setText((cast(A) data).name);
			}
			static if (!is (C == void)) {
				if (cast(C) data) {
					static if (is (C == MenuCard)) {
						itm.setText((cast(C) data).name);
					} else static if (is (C == EnemyCard)) {
						auto castCard = _summ.cwCast((cast(C) data).id);
						itm.setText(castCard ? castCard.name : "");
					} else {
						static assert (0);
					}
				}
			}
			foreach (itm2; itm.getItems()) {
				auto et = cast(EventTree) itm2.getData();
				bool chg = false;
				if (itm2.getText() != et.name) {
					itm2.setText(et.name);
					chg = true;
				}
				static if (UseFire && (is (A == Area) || is (A == Battle))) {
					int startKC = -1;
					foreach (i, itm3; itm2.getItems()) {
						auto kc = cast(KeyCodeObj) itm3.getData();
						if (kc && startKC <= 0) startKC = i;
						if (startKC >= 0 && itm3.getText() != et.keyCodes[i - startKC]) {
							itm3.setText(et.keyCodes[i - startKC]);
							chg = true;
						}
					}
				}
				if (chg) {
					_comm.refEventTree.call(et);
					_comm.refKeyCodes.call();
				}
			}
		}
	}
	static if (UseFire) {
		void addManyRounds() {
			auto etItm = selectionEventTree;
			if (!etItm) return;
			auto parItm = selectionParent;
			if (!parItm || !(cast(Battle) parItm.getData())) return;
			auto dlg = new ManyRoundsDialog(_prop, _cards.getShell());
			if (dlg.open()) {
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
		void keyCodeTimImpl(FKCKind kind) {
			auto itm = selection;
			if (!itm) return;
			auto kc = cast(KeyCodeObj) itm.getData();
			if (!kc) return;
			string old = kc.array.idup;
			string keyCode = _prop.sys.convFireKeyCode(old, kind);
			kc.array = keyCode.dup;
			auto etItm = selectionEventTree;
			assert (etItm);
			auto et = cast(EventTree) etItm.getData();
			assert (et);
			int i = cCountUntil(et.keyCodes, old);
			assert (-1 != i);
			et.setKeyCode(i, keyCode);
			itm.setText(keyCode);
			itm.setImage(keyCodeImage(keyCode));
			_comm.refKeyCodes.call();
			_comm.refreshToolBar();
		}
		void keyCodeTimUse() {
			keyCodeTimImpl(FKCKind.Use);
		}
		void keyCodeTimSuccess() {
			keyCodeTimImpl(FKCKind.Success);
		}
		void keyCodeTimFailure() {
			keyCodeTimImpl(FKCKind.Failure);
		}
	}
	bool curIsKeyCode(FKCKind Kind)() {
		auto itm = selectionKeyCode;
		if (!itm) return false;
		return Kind !is _prop.sys.fireKeyCodeKind((cast(KeyCodeObj) selectionKeyCode.getData()).array.idup);
	}

	void refShowToolBar() {
		if (!_comm.singleWindowMode(_prop)) return;
		auto gl = windowGridLayout(1, true);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		if (!_prop.var.etc.showEventToolBar) {
			gl.verticalSpacing = 0;
			gd.heightHint = 0;
		}
		setLayout(gl);
		_toolbar.setVisible(_prop.var.etc.showEventToolBar);
		_toolbar.setLayoutData(gd);
		layout();
	}
public:
	this (Commons comm, Props prop, Summary summ, A area, Composite parent, UndoManager undo) {
		super (parent, SWT.NONE);
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_area = area;
		_undo = undo;

		_toolbar = new ToolBar(this, SWT.FLAT);
		_comm.put(_toolbar);

		_sash = new SplitPane(this, SWT.HORIZONTAL);
		static if (is (A == Area) || is (A == Battle)) {
			_comm.refStandardKeyCodes.add(&refKeyCodes);
			_comm.refKeyCodes.add(&refKeyCodes);
		}
		_comm.replText.add(&replText);
		_comm.replID.add(&replText);
		_comm.refShowToolBar.add(&refShowToolBar);
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
		_sash.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
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
				} else {
					static assert (0);
				}
				static if (is (A == Area) || is (A == Battle)) {
					_comm.refStandardKeyCodes.remove(&refKeyCodes);
					_comm.refKeyCodes.remove(&refKeyCodes);
				}
				_comm.replText.remove(&replText);
				_comm.replID.remove(&replText);
				_comm.refShowToolBar.remove(&refShowToolBar);
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
		});
		_sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		{
			_cards = new Tree(_sash, SWT.SINGLE | SWT.BORDER);
			initTree(_comm, _cards, false);
			_cards.addSelectionListener(new SListener);

			auto shell = _cards.getShell();
			uint retry = 0;
			while (true) {
				Menu menu = null;
				string dStr = .text(__LINE__); // ログ
				try {
					dStr ~= " - " ~ .text(__LINE__);
					menu = new Menu(shell, SWT.POP_UP);
					dStr ~= " - " ~ .text(__LINE__);
					createMenuItem(_comm, menu, MenuID.Undo, &this.undo, &_undo.canUndo);
					createMenuItem(_comm, menu, MenuID.Redo, &this.redo, &_undo.canRedo);
					new MenuItem(menu, SWT.SEPARATOR);
					appendMenuTCPD(_comm, menu, this, true, true, true, true, true);
					dStr ~= " - " ~ .text(__LINE__);
					static if (is(A : Area) || is(A : Battle)) {
						new MenuItem(menu, SWT.SEPARATOR);
						void delegate() dlg = null;
						auto cascade = createMenuItem(_comm, menu, MenuID.KeyCodeTiming, dlg, () => selectionKeyCode !is null, SWT.CASCADE);
						auto sub = new Menu(parent.getShell(), SWT.DROP_DOWN);
						cascade.setMenu(sub);
						createMenuItem(_comm, sub, MenuID.KeyCodeTimingUse, &keyCodeTimUse, &curIsKeyCode!(FKCKind.Use));
						createMenuItem(_comm, sub, MenuID.KeyCodeTimingSuccess, &keyCodeTimSuccess, &curIsKeyCode!(FKCKind.Success));
						createMenuItem(_comm, sub, MenuID.KeyCodeTimingFailure, &keyCodeTimFailure, &curIsKeyCode!(FKCKind.Failure));
					}
					dStr ~= " - " ~ .text(__LINE__);
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.ToScript, &toScript, &canToScript);
					createMenuItem(_comm, menu, MenuID.ToScriptAll, &toScriptAll, &canToScriptAll);
					dStr ~= " - " ~ .text(__LINE__);
					static if (is (A == Battle)) {
						new MenuItem(menu, SWT.SEPARATOR);
						createMenuItem(_comm, menu, MenuID.AddRangeOfRound, &addManyRounds, {
							auto etItm = selectionEventTree;
							if (!etItm) return false;
							return (cast(EventTree) etItm.getData()).owner is _area;
						});
					}
					dStr ~= " - " ~ .text(__LINE__);
					_cards.setMenu(menu);
					dStr ~= " - " ~ .text(__LINE__);
					break;
				} catch (Throwable e) {
					// 環境によってはMenuが異常な状態になり、
					// MenuItemの追加で落ちることがある模様
					debugln(dStr);
					debugln(e);
					try {
						if (menu) menu.dispose();
						menu = null;
					} catch {}
					retry++;
					if (retry > 128) {
						debugln("create menu failed (event view).");
						break;
					}
					debugln("create menu failed (event view). retry: ", retry);
				}
			}
		}
		{
			_etree = new EventTreeView(comm, prop, summ, _sash, _undo, &forceSel, &refreshTopStart, _toolbar);
			auto _edit = new TreeEdit(_comm, _cards, &editEnd, &createEditor);
			setupToolBar();
		}
		static if (is (A == Area)) {
			_sash.setWeights([_prop.var.areaWin.eventSashL, _prop.var.areaWin.eventSashR]);
		} else static if (is (A == Battle)) {
			_sash.setWeights([_prop.var.battleWin.eventSashL, _prop.var.battleWin.eventSashR]);
		} else static if (is (A == Package)) {
			_sash.setWeights([_prop.var.packageWin.eventSashL, _prop.var.packageWin.eventSashR]);
		} else static if (is (A : EffectCard)) {
			_sash.setWeights([_prop.var.cardEventWin.eventSashL, _prop.var.cardEventWin.eventSashR]);
		} else {
			static assert (0);
		}
		refShowToolBar();
	}
	@property
	EventTreeView eventTreeView() {
		return _etree;
	}

	/// エリアの名称表示を更新する。
	void refreshTitle() {
		if (!initial()) return;
		_cards.getItems()[0].setText(_area.name);
	}
	private void refreshTitleA(A area) {
		if (!initial()) return;
		if (area is _area) {
			_cards.getItems()[0].setText(_area.name);
		}
	}
	static if (!is (C == void)) {
		private string cardName(C c) {
			static if (is (C == MenuCard)) {
				return c.name;
			} else {
				static assert (is (C == EnemyCard));
				auto castCard = _summ.cwCast(c.id);
				return castCard ? castCard.name : "";
			}
		}
		private void addCard(string cwxPath) {
			if (!cpeq(_area.cwxPath(true), cpparent(cwxPath))) return;
			size_t i = cpindex(cpbottom(cwxPath));
			appendCard(i, _area.cards[i]);
		}
		private void refCard(string cwxPath) {
			if (!cpeq(_area.cwxPath(true), cpparent(cwxPath))) return;
			size_t i = cpindex(cpbottom(cwxPath));
			renameCard(i);
		}
		private void delCard(string cwxPath) {
			if (!cpeq(_area.cwxPath(true), cpparent(cwxPath))) return;
			size_t i = cpindex(cpbottom(cwxPath));
			removeCard(i);
		}
		private void upCard(string cwxPath, int[] indices, int count) {
			if (!cpeq(_area.cwxPath(true), cwxPath)) return;
			upCard(indices, count);
		}
		private void downCard(string cwxPath, int[] indices, int count) {
			if (!cpeq(_area.cwxPath(true), cwxPath)) return;
			downCard(indices, count);
		}
		private void appendCard(int index, C c) {
			if (initial()) return;
			Image imgCard;
			static if (is (C == MenuCard)) {
				imgCard = _prop.images.cards;
			} else static if (is (C == EnemyCard)) {
				imgCard = _prop.images.cards;
			}
			auto itm = createTreeItem(_cards, c, cardName(c), imgCard, index + 1);
			refreshTrees(itm);
		}
		private void removeCard(int index) {
			if (initial()) return;
			if (_selItm && !_selItm.isDisposed()
					&& _selItm.getParentItem() is _cards.getItems()[index + 1]) {
				_etree.refresh(null);
				_selItm = null;
			}
			_cards.getItems()[index + 1].dispose();
		}
		private void renameCard(int index) {
			if (initial()) return;
			auto itm = _cards.getItems()[index + 1];
			itm.setText(cardName(cast(C) itm.getData()));
		}
		private void __udCard(int[] indices, int function(TreeItem) ud, int udVal, int count) {
			foreach (j; 0 .. count) {
				foreach (i; indices) {
					i += udVal * j;
					if (_selItm && _selItm.getParentItem() is _cards.getItems()[i + 1]) {
						int s = _selItm.getParentItem().indexOf(_selItm);
						int newI = ud(_cards.getItems()[i + 1]) + udVal;
						__select(_cards.getItems()[newI].getItems()[s]);
					} else {
						ud(_cards.getItems()[i + 1]);
					}
				}
			}
		}
		private void upCard(int[] indices, int count) {
			if (initial()) return;
			__udCard(indices, &treeItemUp, -1, count);
		}
		private void downCard(int[] indices, int count) {
			if (initial()) return;
			__udCard(indices, &treeItemDown, 1, count);
		}
	}
	private bool _initialed = false;
	bool initial() {
		if (!_initialed) {
			refresh();
			return true;
		}
		return false;
	}
	void refresh() {
		_initialed = true;
		_cards.removeAll();
		{
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
			} else {
				static assert (0);
			}
			auto aItm = createTreeItem(_cards, _area, _area.name, imgArea);
			foreach (i, t; _area.trees) {
				auto eItm = createTreeItem(aItm, t, t.name, _prop.images.eventTree);
				static if (UseFire) {
					refreshFires(eItm);
				}
				if (i == 0) {
					__select(eItm);
				}
			}
			if (_area.trees.length == 0) {
				__select(aItm);
			}
			aItm.setExpanded(true);
		}
		static if (!is (C == void)) {
			foreach (c; _area.cards) {
				Image imgCard;
				static if (is (C == MenuCard)) {
					imgCard = _prop.images.cards;
				} else static if (is (C == EnemyCard)) {
					imgCard = _prop.images.cards;
				}
				auto cItm = createTreeItem(_cards, c, cardName(c), imgCard);
				foreach (t; c.trees) {
					auto eItm = createTreeItem(cItm, t, t.name, _prop.images.eventTree);
					static if (UseFire) {
						refreshFires(eItm);
					}
				}
				cItm.setExpanded(true);
			}
		}
		_comm.refreshToolBar();
	}
	private bool canUdImpl(string BeforeAfter, string CanSwapKeyCode)(TreeItem itm) {
		if (itm && itm.getParentItem()) {
			auto data = itm.getData();
			auto parent = itm.getParentItem();
			int from = parent.indexOf(itm);
			int to = mixin (BeforeAfter);
			if (to >= 0) {
				if (cast(EventTree) data) {
					return true;
				} else {
					static if (UseFire) {
						if (cast(KeyCodeObj) data) {
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
			(TreeItem itm, int function(TreeItem) treeSwap, bool store) {
		if (itm && itm.getParentItem()) {
			auto data = itm.getData();
			auto parent = itm.getParentItem();
			int from = parent.indexOf(itm);
			int to = mixin (BeforeAfter);
			if (to >= 0) {
				if (cast(EventTree) data) {
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
				} else {
					static if (UseFire) {
						if (cast(KeyCodeObj) data) {
							_cards.setRedraw(false);
							scope (exit) _cards.setRedraw(true);
							// キーコード
							auto tree = cast(EventTree) parent.getData();
							if (store) this.store(tree);
							int keyCodeLen = tree.keyCodes.length;
							from -= keyCodesIndex(parent);
							to -= keyCodesIndex(parent);
							if (mixin (CanSwapKeyCode)) {
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
	private static void staticUDImpl(Commons comm, EventTreeOwner eto, int from, int to) {
		eto.swapEventTree(from, to);
		comm.refEventTree.call(eto.trees[from]);
		comm.refEventTree.call(eto.trees[to]);
	}
	@property
	bool canUp() {
		if (_etree.isFocusControl()) {
			return _etree.canUp();
		} else if (_cards.isFocusControl()) {
			return canUdImpl!("before(parent, from)", "to >= 0")(selection);
		}
		return false;
	}
	@property
	bool canDown() {
		if (_etree.isFocusControl()) {
			return _etree.canDown();
		} else if (_cards.isFocusControl()) {
			return canUdImpl!("after(parent, from)", "to < keyCodeLen")(selection);
		}
		return false;
	}
	void up() {
		initial();
		up(selection, true);
	}
	private void up(TreeItem itm, bool store) {
		if (_etree.isFocusControl()) {
			_etree.up();
		} else if (_cards.isFocusControl()) {
			udImpl!("before(parent, from)", "to >= 0")(itm, &treeItemUp, store);
			_comm.refreshToolBar();
		}
	}
	void down() {
		initial();
		down(selection, true);
	}
	private void down(TreeItem itm, bool store) {
		if (_etree.isFocusControl()) {
			_etree.down();
		} else if (_cards.isFocusControl()) {
			udImpl!("after(parent, from)", "to < keyCodeLen")(itm, &treeItemDown, store);
			_comm.refreshToolBar();
		}
	}

	static if (is(A : Area) || is(A : Battle)) {
		private void openScene() {
			_comm.openAreaScene(_prop, _summ, _area, true);
		}
	}

	private void setupToolBar() {
		auto bar = _toolbar;
		static if (is(A : Area)) {
			if (cast(AreaEventWindow) tlpData(this).tlp) {
				createToolItem(_comm, bar, MenuID.EditScene, &openScene, null);
				new ToolItem(bar, SWT.SEPARATOR);
			}
		} else static if (is(A : Battle)) {
			if (cast(BattleEventWindow) tlpData(this).tlp) {
				auto itm = createToolItem(_comm, bar, MenuID.EditScene, &openScene, null);
				itm.setImage(_prop.images.editSceneBattle);
				new ToolItem(bar, SWT.SEPARATOR);
			}
		}
		if (!_comm.singleWindowMode(_prop)) {
			createToolItem(_comm, bar, MenuID.Undo, &undo, &_undo.canUndo);
			createToolItem(_comm, bar, MenuID.Redo, &redo, &_undo.canRedo);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.Up, &up, &canUp);
			createToolItem(_comm, bar, MenuID.Down, &down, &canDown);
			new ToolItem(bar, SWT.SEPARATOR);
		}
		{
			auto treeKindItm = new ToolItem(bar, SWT.SEPARATOR);
			_treeKind = new CCombo(bar, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
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
		}
		new ToolItem(bar, SWT.SEPARATOR);
		{
			_fireItm = new ToolItem(bar, SWT.SEPARATOR);
			_fireItm.setWidth(_prop.var.etc.firesWidth);
			createCombo(true, areaDefVals);
		}
		static if (is (A == Area) || is (A == Battle)) {
			new ToolItem(bar, SWT.SEPARATOR);
			{
				auto keyCodeTimItm = new ToolItem(bar, SWT.SEPARATOR);
				_keyCodeTim = new CCombo(bar, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
				createTextMenu!CCombo(_comm, _prop, _keyCodeTim, null);
				_keyCodeTim.setEnabled(false);
				_keyCodeTim.add(_prop.msgs.keyCodeTimingUse);
				_keyCodeTim.add(_prop.msgs.keyCodeTimingSuccess);
				_keyCodeTim.add(_prop.msgs.keyCodeTimingFailure);
				_keyCodeTim.select(0);
				keyCodeTimItm.setControl(_keyCodeTim);
				keyCodeTimItm.setWidth(_keyCodeTim.computeSize(SWT.DEFAULT, SWT.DEFAULT).x);
			}
		}
		new ToolItem(bar, SWT.SEPARATOR);
		createToolItem2(_comm, bar, _prop.msgs.newEvent, _prop.images.newEvent, &createEventTree, {
			auto par = selectionParent;
			if (!par) return false;
			static if (is(A:Battle)) {
				auto eto = cast(EventTreeOwner) par.getData();
				assert (eto !is null);
				if (cast(C) eto && 2 == _treeKind.getSelectionIndex()) {
					// エネミーカード選択中、かつラウンド条件選択中
					return false;
				}
			}
			return true;
		});
		static if (UseFire) {
			createToolItem2(_comm, bar, _prop.msgs.newIgnition, _prop.images.newIgnition, &createEventFire, {
				if (selectionEventTree is null) return false;
				static if (is(A:Battle)) {
					auto par = selectionParent;
					assert (par !is null);
					auto eto = cast(EventTreeOwner) par.getData();
					assert (eto !is null);
					if (cast(C) eto && 2 == _treeKind.getSelectionIndex()) {
						// エネミーカード選択中、かつラウンド条件選択中
						return false;
					}
				}
				return true;
			});
		}
		new ToolItem(bar, SWT.SEPARATOR);
		createToolItem2(_comm, bar, _prop.msgs.expandTree, _prop.images.expandTree, &_etree.treeOpen, &_etree.canExpandTree);
		createToolItem2(_comm, bar,_prop.msgs.foldTree,  _prop.images.foldTree, &_etree.treeClose, &_etree.canFoldTree);
	}
	private void setFireControl(Control c) {
		if (_fireItm.getControl()) _fireItm.getControl().dispose();
		_fireItm.setControl(c);
		_comm.refreshToolBar();
	}
	@property
	private string[] areaDefVals() {
		static if (is (A == Area)) {
			return [_prop.msgs.startEnter];
		} else static if (is (A == Battle)) {
			return [_prop.msgs.startVictory, _prop.msgs.startEscape, _prop.msgs.startLose];
		} else static if (is (A == Package)) {
			return [_prop.msgs.startPackage];
		} else {
			return [_prop.msgs.startUse];
		}
	}
	@property
	private string[] startDefVals() {
		auto itm = selectionParent;
		if (!itm) return [];
		auto data = itm.getData();
		string[] vals;
		if (cast(A) data) {
			return areaDefVals;
		} else {
			static if (!is (C == void)) {
				assert (cast(C) data);
				static if (is (C == MenuCard)) {
					return [_prop.msgs.startSelect];
				} else {
					assert (is (C == EnemyCard));
					return [_prop.msgs.startDead];
				}
			} else {
				assert (0);
			}
		}
	}
	private void createCombo(bool readOnly, string[] vals, bool visLong = false) {
		int style = SWT.BORDER | SWT.DROP_DOWN;
		if (readOnly) style |= SWT.READ_ONLY;
		auto c = new CCombo(_toolbar, style);
		if (visLong) c.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		foreach (i, v; vals) {
			c.add(v);
			if (i == 0) c.setText(v);
		}
		createTextMenu!CCombo(_comm, _prop, c, null);
		setFireControl(c);
	}
	static if (is (A == Area) || is (A == Battle)) {
		private void refKeyCodes() {
			if (_treeKind.getSelectionIndex() == 1) {
				auto combo = cast(CCombo) _fireItm.getControl();
				combo.removeAll();
				foreach (i, v; _prop.var.etc.standardKeyCodes) {
					combo.add(v);
					if (i == 0) combo.setText(v);
				}
			}
		}
	}
	private class KSListener : SelectionAdapter {
	public:
		override void widgetSelected(SelectionEvent e) {
			static if (is (A == Area)) {
				switch (_treeKind.getSelectionIndex()) {
				case 0:
					createCombo(true, startDefVals);
					_keyCodeTim.setEnabled(false);
					break;
				case 1:
					createCombo(false, [], true);
					refKeyCodes();
					_keyCodeTim.setEnabled(true);
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
					createCombo(false, [], true);
					refKeyCodes();
					_keyCodeTim.setEnabled(true);
					break;
				case 2:
					auto spn = new Spinner(_toolbar, SWT.BORDER);
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

	void openToolWindow() {
		_etree.openToolWindow();
	}
	void closeToolWindow() {
		_etree.closeToolWindow();
	}

	@property
	string statusLine() {
		return _etree.statusLine;
	}

	void toScript() {
		_etree.toScript();
	}
	void toScriptAll() {
		_etree.toScriptAll();
	}
	@property
	bool canToScript() {
		return _etree.canToScript();
	}
	@property
	bool canToScriptAll() {
		return _etree.canToScriptAll();
	}
	@property
	bool canWriteComment() {
		return _etree.canWriteComment;
	}
	void writeComment() {
		_etree.writeComment();
	}

	private void pasteScript(Clipboard cb) {
		auto array = cast(ArrayWrapperString) cb.getContents(TextTransfer.getInstance());
		if (!array) return;
		CompileOption opt;
		string script = array.array.idup;
		string base = script;
		try {
			opt.linkId = _prop.var.etc.linkCard;

			void put(Content[] cs) {
				if (!cs.length) return;
				if (cs[0].type !is CType.START) return;
				createEventTree(cs);
			}
			auto compiler = new CWXScript(_prop.parent, _summ);
			auto vars = compiler.eatEmptyVars(script, opt);
			if (vars.length) {
				auto dlg = new ScriptVarSetDialog(_comm, _summ, _cards.getShell(), vars, script, base, opt);
				dlg.appliedEvent ~= {
					put(dlg.contents);
				};
				dlg.open();
			} else {
				put(cwx.script.compile(_prop.parent, _summ, script, opt));
			}
		} catch (CWXScriptException e) {
			auto dlg = new ScriptErrorDialog(_comm, _prop, _cards, e, base, opt);
			dlg.open();
		}
	}
	override void cut(SelectionEvent se) {
		initial();
		if (_etree.isFocusControl) {
			_etree.cut(se);
		} else {
			copy(se);
			del(se);
		}
	}
	override void copy(SelectionEvent se) {
		copyImpl(se, true);
	}
	private void copyImpl(SelectionEvent se, bool canFire) {
		initial();
		if (_etree.isFocusControl) {
			_etree.copy(se);
		} else {
			auto itm = selection;
			if (!itm) return;
			auto parItm = itm.getParentItem();
			if (!parItm) return;
			auto par = parItm.getData();
			auto data = itm.getData();
			string xml;
			if (cast(EventTree) data) {
				xml = (cast(EventTree) data).toXML(null);
			} else if (!canFire) {
				assert (cast(EventTree) par !is null);
				xml = (cast(EventTree) par).toXML(null);
			} else {
				static if (UseFire) {
					if (ENTER is data) {
						xml = EventTree.enterToXML();
					} else if (ESCAPE is data) {
						xml = EventTree.escapeToXML();
					} else if (LOSE is data) {
						xml = EventTree.loseToXML();
					} else if (cast(KeyCodeObj) data) {
						xml = EventTree.keyCodeToXML((cast(KeyCodeObj) data).array.idup);
					} else if (cast(RoundObj) data) {
						xml = EventTree.roundToXML((cast(RoundObj) data).intValue());
					} else {
						assert (0);
					}
				} else {
					assert (0);
				}
			}
			XMLtoCB(_prop, _comm.clipboard, xml);
			_comm.refreshToolBar();
		}
	}
	override void paste(SelectionEvent se) {
		initial();
		if (_etree.isFocusControl) {
			_etree.paste(se);
		} else {
			auto itm = selection;
			if (!itm) return;
			auto xml = CBtoXML(_comm.clipboard);
			if (!xml) {
				pasteScript(_comm.clipboard);
				return;
			}
			auto parItm = selectionParent;
			if (parItm) {
				try {
					auto par = cast(EventTreeOwner) parItm.getData();
					EventTree tree = EventTree.fromXML(xml, LATEST_VERSION);
					if (tree) {
						storeI(_cards.indexOf(parItm), par.trees.length);
						// イベントツリー
						par.add(tree);
						auto treeItm = createTreeItem(parItm, tree, tree.name, _prop.images.eventTree);
						__select(treeItm);
						static if (UseFire) {
							refreshFires(treeItm);
						}
						_comm.refEventTree.call(tree);
					} else {
						static if (UseFire) {
							if (!(cast(EventTreeOwner) itm.getData())) {
								// 開始条件
								auto treeItm = cast(EventTree) itm.getData() ? itm : itm.getParentItem();
								tree = cast(EventTree) treeItm.getData();
								store(tree);
								if (tree.enterFromXML(par, xml)) {
									refreshFires(treeItm, ENTER);
								} else if (tree.escapeFromXML(par, xml)) {
									refreshFires(treeItm, ESCAPE);
								} else if (tree.loseFromXML(par, xml)) {
									refreshFires(treeItm, LOSE);
								} else {
									int round = tree.roundFromXML(par, xml);
									if (round >= 0) {
										refreshFires(treeItm, new RoundObj(round));
									} else {
										string keyCode = tree.keyCodeFromXML(par, xml);
										if (keyCode) {
											refreshFires(treeItm, new KeyCodeObj(keyCode));
										}
									}
								}
								_comm.refEventTree.call(tree);
								_comm.refKeyCodes.call();
							}
						}
					}
					_comm.refreshToolBar();
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
	}
	override void del(SelectionEvent se) {
		initial();
		if (_etree.isFocusControl) {
			_etree.del(se);
		} else {
			auto itm = selection;
			if (!itm) return;
			auto parItm = itm.getParentItem();
			if (!parItm) return;
			auto par = parItm.getData();
			auto data = itm.getData();
			auto tree = cast(EventTree) data;
			if (tree) {
				storeD(tree);
				(cast(EventTreeOwner) par).remove(tree);
				if (_selItm is itm) {
					_selItm = null;
					_etree.refresh(null);
				}
				_comm.delEventTree.call(tree);
			} else {
				static if (UseFire) {
					tree = cast(EventTree) par;
					store(tree);
					if (ENTER is data) {
						tree.enter = false;
					} else if (ESCAPE is data) {
						tree.escape = false;
					} else if (LOSE is data) {
						tree.lose = false;
					} else if (cast(KeyCodeObj) data) {
						tree.removeKeyCode((cast(KeyCodeObj) data).array.idup);
					} else if (cast(RoundObj) data) {
						tree.removeRound((cast(RoundObj) data).intValue());
					} else {
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
	override void clone(SelectionEvent se) {
		if (_etree.isFocusControl) {
			_etree.clone(se);
		} else {
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copyImpl(se, false);
			paste(se);
		}
	}
	@property
	override bool canDoTCPD() {
		return _cards.isFocusControl() || _etree.isFocusControl();
	}
	@property
	override bool canDoT() {
		if (_cards.isFocusControl()) {
			return selection && selection.getParentItem();
		} else if (_etree.isFocusControl()) {
			return _etree.canDoT;
		}
		return false;
	}
	@property
	override bool canDoC() {
		if (_cards.isFocusControl()) {
			return canDoT;
		} else if (_etree.isFocusControl()) {
			return _etree.canDoC;
		}
		return false;
	}
	@property
	override bool canDoP() {
		if (_cards.isFocusControl()) {
			return CBisXML(_comm.clipboard) || CBisText(_comm.clipboard);
		} else if (_etree.isFocusControl()) {
			return _etree.canDoP;
		}
		return false;
	}
	@property
	override bool canDoD() {
		if (_cards.isFocusControl()) {
			return canDoT;
		} else if (_etree.isFocusControl()) {
			return _etree.canDoD;
		}
		return false;
	}
	@property
	override bool canDoClone() {
		return canDoC;
	}
	void undo() {
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() {
		_undo.redo();
		_comm.refreshToolBar();
	}

	bool openCWXPath(string path, bool shellActivate) {
		initial();
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		bool open(TreeItem itm) {
			if (index >= itm.getItemCount()) {
				return false;
			}
			__select(itm.getItem(index));
			return _etree.openCWXPath(cpbottom(path), shellActivate);
		}
		static if (is(C : MenuCard) || is(C : EnemyCard)) {
			bool card() {
				if (index + 1 >= _cards.getItemCount()) {
					return false;
				}
				auto itm = _cards.getItem(index + 1);
				path = cpbottom(path);
				if (cpempty(path)) {
					.forceFocus(_cards, shellActivate);
					__select(itm);
					return true;
				} else {
					cate = cpcategory(path);
					index = cpindex(path);
					return open(itm);
				}
			}
		}
		switch (cate) {
		case "event": {
			return open(_cards.getItem(0));
		} break;
		case "menucard": {
			static if (is(C : MenuCard)) {
				return card();
			}
		} break;
		case "enemycard": {
			static if (is(C : EnemyCard)) {
				return card();
			}
		} break;
		case "": {
			.forceFocus(_cards, shellActivate);
			_comm.refreshToolBar();
			return true;
		} break;
		default: break;
		}
		return false;
	}
	@property
	string[] openedCWXPath() {
		string[] r;
		auto etItm = selectionEventTree;
		if (etItm) {
			auto et = cast(EventTree) etItm.getData();
			assert (et);
			r ~= et.cwxPath(true);
		} else {
			auto cardItm = selectionParent;
			if (cardItm) {
				auto d = cardItm.getData();
				auto area = cast(A) d;
				if (area) {
					r ~= cpaddattr(area.cwxPath(true), "eventview");
				}
				static if (!is(C : void)) {
					auto card = cast(C) d;
					if (card) {
						r ~= cpaddattr(card.cwxPath(true), "eventview");
					}
				}
			} else {
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
	this (Props prop, Shell shell) {
		_prop = prop;
		super (prop, shell, prop.msgs.dlgTitAddManyRounds, prop.images.menu(MenuID.AddRangeOfRound), false);
		enterClose = true;
	}

	@property
	uint[] rounds() {
		return _rounds;
	}
protected:
	private class SelMin : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int f = _from.getSelection();
			if (f >= _to.getSelection()) {
				_to.setSelection(f);
			}
		}
	}
	private class SelMax : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int t = _to.getSelection();
			if (t <= _from.getSelection()) {
				_from.setSelection(t);
			}
		}
	}
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(_prop.msgs.manyRounds);
			grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(new GridLayout(4, false));
			_from = new Spinner(comp, SWT.BORDER);
			_from.setMinimum(1);
			_from.setMaximum(_prop.var.etc.roundMax);
			_from.addSelectionListener(new SelMin);
			auto l1 = new Label(comp, SWT.NONE);
			l1.setText(_prop.msgs.roundSep);
			_to = new Spinner(comp, SWT.BORDER);
			_to.setMinimum(1);
			_to.setMaximum(_prop.var.etc.roundMax);
			_to.addSelectionListener(new SelMax);
			auto l2 = new Label(comp, SWT.NONE);
			l2.setText(.tryFormat(_prop.msgs.rangeHint, 1, _prop.var.etc.roundMax));
		}
	}
	override bool close(bool ok) {
		if (ok) {
			for (uint i = _from.getSelection(); i <= _to.getSelection(); i++) {
				_rounds ~= i;
			}
		}
		return ok;
	}
}
